public with sharing class LeadConversionDataMapper implements TriggerAction.AfterUpdate {

    public void afterUpdate(List<Lead> newLeads, List<Lead> oldLeads) {
        Set<Id> convertedLeadIds = new Set<Id>();
        for (Integer i = 0; i < newLeads.size(); i++) {
            Lead newLead = newLeads[i];
            Lead oldLead = oldLeads[i];
            if (newLead.IsConverted && !oldLead.IsConverted) {
                convertedLeadIds.add(newLead.Id);
            }
        }

        if (!convertedLeadIds.isEmpty()) {
            remapDataForConvertedLeads(convertedLeadIds);
        }
    }

    //@test: should_map_data_from_Converted_Lead_to_related_records
    public static void remapDataForConvertedLeads(Set<Id> convertedLeadIds) {

        List<Account> updatedAccounts = new List<Account>();
        List<Opportunity> updatedOpportunities = new List<Opportunity>();
        List<Park_Tour__c> toursForUpdate = new List<Park_Tour__c>();
        List<Park_Of_Interest__c> poiForUpdate = new List<Park_Of_Interest__c>();
        for (Lead lead : [
            SELECT Id, ConvertedAccountId, ConvertedContactId, ConvertedOpportunityId, Vendor_Segment_Id__c,
                LastName, Phone, MobilePhone, Email, Adventure_Timeframe__c, Household_Income__c,
            (SELECT Id, Lead__c, Adventure_Park__c FROM Park_Tour__r WHERE Lead__c IN :convertedLeadIds ORDER BY Id),
            (SELECT Id, Lead__c FROM Parks_Of_Interest__r WHERE Lead__c IN :convertedLeadIds)
            FROM Lead
            WHERE Id IN :convertedLeadIds
        ]) {

            Id accountIdFromConversion = lead.ConvertedAccountId;
            if (accountIdFromConversion != null) {
                Account updatedAccount = updateAccountContactInfo(lead);
                updatedAccounts.add(updatedAccount);
            }

            Id opportunityFromConversion = lead.ConvertedOpportunityId;
            if (opportunityFromConversion != null) {
                Opportunity updatedOpportunity = mapOpportunityFromConvertedLead(lead);

                if (!updatedOpportunities.contains(updatedOpportunity)) {
                    updatedOpportunities.add(updatedOpportunity);
                }
            }

            toursForUpdate.addAll(mapParkToursFromConvertedLead(lead));
            poiForUpdate.addAll(mapPOIsFromConvertedLead(lead));
        }

        if (!updatedAccounts.isEmpty()) {
            update updatedAccounts;
        }

        if (!updatedOpportunities.isEmpty()) {
            update updatedOpportunities;
        }

        if (!toursForUpdate.isEmpty()) {
            update toursForUpdate;
        }

        if (!poiForUpdate.isEmpty()) {
            update poiForUpdate;
        }

        List<OpportunityContactRole> updatedOCRs = mapOCRs(updatedOpportunities);
        if (!updatedOCRs.isEmpty()) {
            update updatedOCRs;
        }
    }

    private static Account updateAccountContactInfo(Lead convertedLead) {
        return new Account(
            Id = convertedLead.ConvertedAccountId,
            Phone = convertedLead.Phone,
            Email__c = convertedLead.Email
        );
    }

    private static Opportunity mapOpportunityFromConvertedLead(Lead convertedLead) {
        return new Opportunity(
            Id = convertedLead.ConvertedOpportunityId,
            Adventure_Timeframe__c = convertedLead.Adventure_Timeframe__c,
            Household_Income__c = convertedLead.Household_Income__c,
            Vendor_Segment_Id__c = convertedLead.Vendor_Segment_Id__c,
            Created_From_Lead__c = true
        );
    }

    private static List<Park_Tour__c> mapParkToursFromConvertedLead(Lead convertedLead) {
        List<Park_Tour__c> remappedTours = new List<Park_Tour__c>();
        for (Park_Tour__c tour : convertedLead.Park_Tour__r) {
            tour.Lead__c = null;
            tour.Contact__c = convertedLead.ConvertedContactId;
            tour.Opportunity__c = convertedLead.ConvertedOpportunityId;
            remappedTours.add(tour);
        }
        return remappedTours;
    }

    private static List<Park_Of_Interest__c> mapPOIsFromConvertedLead(Lead convertedLead) {
        List<Park_Of_Interest__c> remappedPOIs = new List<Park_Of_Interest__c>();
        for (Park_Of_Interest__c poi : convertedLead.Parks_Of_Interest__r) {
            poi.Lead__c = null;
            poi.Contact__c = convertedLead.ConvertedContactId;
            remappedPOIs.add(poi);
        }
        return remappedPOIs;
    }

    private static List<OpportunityContactRole> mapOCRs(List<Opportunity> opportunities) {
        List<OpportunityContactRole> mappedOCRs = new List<OpportunityContactRole>();
        for (OpportunityContactRole ocr : [
            SELECT Id, OpportunityId
            FROM OpportunityContactRole
            WHERE OpportunityId IN :opportunities
        ]) {
            ocr.Role = 'Buyer';
            ocr.IsPrimary = true;
            mappedOCRs.add(ocr);
        }
        return mappedOCRs;
    }
}
