public with sharing class TempLeadTrigger_Handler {

    private static final Map<String, Temp_Lead__c> tempLeadByEmail = new Map<String, Temp_Lead__c>();
    private static final Map<String, Temp_Lead__c> tempLeadByPhone = new Map<String, Temp_Lead__c>();
    private static final List<String> tempParkNumbers = new List<String>();

    public static void onAfterInsert(Map<Id, Temp_Lead__c> tempLeadsById) {
        collectEmailsPhonesAndParkNumbers(tempLeadsById);
        Map<String, Id> parkIdByParkName = getParkIdByParkName(tempParkNumbers);
        List<Temp_Lead__c> processedTempLeads = new List<Temp_Lead__c>();

        processedTempLeads.addAll(
            handleTempLeadMatchingContact(tempLeadsById, parkIdByParkName)
        );

        if (!tempLeadsById.isEmpty()) {
            processedTempLeads.addAll(
                handleTempLeadMatchingLead(tempLeadsById, parkIdByParkName)
            );
        }

        if (!processedTempLeads.isEmpty()) {
            update processedTempLeads;
        }
    }

    private static void collectEmailsPhonesAndParkNumbers(Map<Id, Temp_Lead__c> tempLeadsById) {
        for (Temp_Lead__c tempLead : tempLeadsById.values()) {
            if (String.isNotBlank(tempLead.Lead_Email__c)) {
                tempLeadByEmail.put(tempLead.Lead_Email__c, tempLead);
            }

            if (String.isNotBlank(tempLead.Lead_Phone_Number__c)) {
                tempLeadByPhone.put(tempLead.Lead_Phone_Number__c, tempLead);
            }

            if (String.isNotBlank(tempLead.Park_Number__c)) {
                tempParkNumbers.add(tempLead.Park_Number__c);
            }
        }
    }

    private static Map<String, Id> getParkIdByParkName(List<String> parkNumbers) {
        Map<String, Id> parkIdByParkName = new Map<String, Id>();
        for (Adventure_Park__c park: [SELECT Id, Park_Number__c FROM Adventure_Park__c WHERE Park_Number__c IN :parkNumbers]) {
            parkIdByParkName.put(park.Park_Number__c, park.Id);
        }
        return parkIdByParkName;
    }

    private static List<Temp_Lead__c> handleTempLeadMatchingContact(Map<Id, Temp_Lead__c> tempLeadsById, Map<String, Id> parkIdByParkName) {
        List<Contact> existingContacts = new List<Contact>();
        List<Contact> newContacts = new List<Contact>();
        List<Temp_Lead__c> processedTempLeads = new List<Temp_Lead__c>();
        for (Contact contact: findForExistingContacts(tempLeadByEmail.keySet(), tempLeadByPhone.keySet())) {
            Temp_Lead__c tempLead = tempLeadByEmail.get(contact.Email);
            if (tempLead == null) {
                tempLead = tempLeadByPhone.get(contact.Phone);
            }
            if (tempLead == null) { continue; }

            if (tempLead.Lead_First_Name__c == contact.FirstName &&
                tempLead.Lead_Last_Name__c == contact.LastName
            ) {
                contact.Park_Of_Interest__c = parkIdByParkName.get(tempLead.Park_Number__c);
                existingContacts.add(contact);
            }
            else {
                Contact relatedContact = createRelatedContactFromTempLead(tempLead, contact);
                relatedContact.Park_Of_Interest__c = parkIdByParkName.get(tempLead.Park_Number__c);
                newContacts.add(relatedContact);
            }

            tempLeadByEmail.remove(tempLead.Lead_Email__c);
            tempLeadByPhone.remove(tempLead.Lead_Phone_Number__c);
            tempLeadsById.remove(tempLead.Id);
            processedTempLeads.add(new Temp_Lead__c(
                Id = tempLead.Id,
                Processed__c = true
            ));
        }

        if (!existingContacts.isEmpty()) {
            update existingContacts;
        }

        if (!newContacts.isEmpty()) {
            insert newContacts;
        }

        return processedTempLeads;
    }

    private static List<Contact> findForExistingContacts(Set<String> tempEmails, Set<String> tempPhones) {
        return [
            SELECT FirstName, LastName, Email, Phone, Park_Of_Interest__c
            FROM Contact
            WHERE Email IN :tempEmails
            OR Phone IN :tempPhones
            FOR UPDATE
        ];
    }

    private static Contact createRelatedContactFromTempLead(Temp_Lead__c tempLead, Contact contact) {
        /**
        * - true creates a full copy, all fields are duplicated in memory, including relationship fields. Consequently,
        *   if you change a field on the cloned SObject, the original SObject isn’t affected.
        * - false performs a shallow copy, all copied relationship fields reference the original. Consequently,
        *   if you change a relationship field, the corresponding field on the original is also affected, & vice versa.
        */
        Contact relatedContact = contact.clone(false, true);
        relatedContact.FirstName = tempLead.Lead_First_Name__c;
        relatedContact.LastName = tempLead.Lead_Last_Name__c;
        return relatedContact;
    }

    private static List<Temp_Lead__c> handleTempLeadMatchingLead(Map<Id, Temp_Lead__c> tempLeadsById, Map<String, Id> parkIdByParkName) {
        List<Lead> existingLeads = findExistingLeads(tempLeadByEmail.keySet(), tempLeadByPhone.keySet());

        List<Lead> newLeads = new List<Lead>();
        List<Lead> updatedLeads = new List<Lead>();
        List<Temp_Lead__c> processedTempLeads = new List<Temp_Lead__c>();
        if (existingLeads.isEmpty()) {
            for (Temp_Lead__c tempLead: tempLeadsById.values()) {
                newLeads.add(
                    createLeadFromTemp(tempLead)
                );

                processedTempLeads.add(new Temp_Lead__c(
                    Id = tempLead.Id,
                    Processed__c = true
                ));
            }
        } else {
            for (Lead lead: existingLeads) {
                Temp_Lead__c tempLead = tempLeadByEmail.get(lead.Email);
                if (tempLead == null) {
                    tempLead = tempLeadByPhone.get(lead.Phone);
                }

                if (tempLead == null) {
                    continue;
                }
                else if (tempLead.Lead_First_Name__c != lead.FirstName ||
                    tempLead.Lead_Last_Name__c != lead.LastName
                ) {
                    newLeads.add(createLeadFromTemp(tempLead));
                }
                else {
                    lead.Parks_Of_Interest__c = parkIdByParkName.get(tempLead.Park_Number__c);
                    updatedLeads.add(lead);
                }

                tempLeadByEmail.remove(tempLead.Lead_Email__c);
                tempLeadByPhone.remove(tempLead.Lead_Phone_Number__c);
                processedTempLeads.add(new Temp_Lead__c(
                    Id = tempLead.Id,
                    Processed__c = true
                ));
            }
        }

        if (!updatedLeads.isEmpty()) {
            update updatedLeads;
        }

        if (!newLeads.isEmpty()) {
            insert newLeads;
        }

        return processedTempLeads;
    }

    private static List<Lead> findExistingLeads(Set<String> tempEmails, Set<String> tempPhones) {
        return [
            SELECT FirstName, LastName, Email, Phone, Parks_Of_Interest__c
            FROM Lead
            WHERE Email IN :tempEmails
            OR Phone IN :tempPhones
            FOR UPDATE
        ];
    }

    private static Lead createLeadFromTemp(Temp_Lead__c tempLead) {
        return new Lead(
            FirstName = tempLead.Lead_First_Name__c,
            LastName = tempLead.Lead_Last_Name__c,
            Email = tempLead.Lead_Email__c,
            Phone = tempLead.Lead_Phone_Number__c,
            Vendor_Segment_Id__c = tempLead.Vendor_Segment_Id__c,
            Company = tempLead.Lead_Last_Name__c,
            Country = tempLead.Lead_Country_Code__c,
            State = tempLead.Lead_State__c,
            Street = tempLead.Lead_Street_Address__c,
            City = tempLead.Lead_City__c,
            PostalCode = tempLead.Lead_Postal_Code__c,
            Is_Agent__c = tempLead.Is_Agent__c,
            Household_Income__c = estimatedHouseHoldIncome(tempLead.Estimated_Household_Income__c),
            Adventure_Timeframe__c = adventureTimeFrame(tempLead.Lead_Adventure_Date__c),
            Most_Recent_Lead_Source__c = tempLead.Lead_Source__c
        );
    }

    @TestVisible
    private static String estimatedHouseHoldIncome(String inputIncome) {
        if (String.isBlank(inputIncome)) { return 'Under $64K';  }

        inputIncome = inputIncome.replace('$', '').replace(',', '').trim();
        if (inputIncome.split('-').size() == 1) {
            inputIncome = inputIncome.replace('+', '');
        } else {
            inputIncome = inputIncome.split('-').get(1);
        }

        Integer income;
        try {
            income = Integer.valueOf(inputIncome.trim());
        } catch (TypeException typeException) {
            return 'Under $64K';
        }

        if (income == null || income < 65000) { inputIncome = 'Under $64K'; }
        else if (income <= 99999) { inputIncome = '$65K-99K'; }
        else if (income <= 149999) { inputIncome = '$100K-149K'; }
        else if (income <= 199999) { inputIncome = '$150K-199K'; }
        else if (income <= 249999) { inputIncome = '$200K-249K'; }
        else if (income <= 299999) { inputIncome = '$250K-299K'; }
        else { inputIncome = '$300K+'; }

        return inputIncome;
    }

    @TestVisible
    private static String adventureTimeFrame(String inputTimeFrame) {
        if (inputTimeFrame == null) { return  null; }

        String[] dateParts = inputTimeFrame.trim().split('/');
        Integer year = Integer.valueOf(dateParts[1].trim());
        Integer month = Integer.valueOf(dateParts[0].trim());

        Date moveInDate = Date.newInstance(year, month, 01);
        Date today = Date.today();
        Integer monthDiff = today.monthsBetween(moveInDate);

        //Instructed to round down the month difference.
        if (monthDiff <= 2) { inputTimeFrame = '1 Month'; }
        else if (monthDiff <= 5) { inputTimeFrame = '3 Months'; }
        else if (monthDiff <= 8) { inputTimeFrame = '6 Months'; }
        else if (monthDiff <= 11) { inputTimeFrame = '9 Months'; }
        else { inputTimeFrame = '1 Year +'; }

        return inputTimeFrame;
    }
}