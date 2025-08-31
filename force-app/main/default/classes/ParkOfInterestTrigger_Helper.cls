public without sharing class ParkOfInterestTrigger_Helper {

    //@test: should_update_Contact_on_POI_when_Missing_at_Creation
    //@test: should_update_Contact_on_POI_when_Account_changes
    public static void setMissingContactOnPOIs(Map<Id, Park_Of_Interest__c> poiByAccountId) {
        Map<Id, Id> contactIdByAccountId = new Map<Id, Id>();
        for (Contact contact : [
                SELECT AccountId
                FROM Contact
                WHERE AccountId IN :poiByAccountId.keySet()
                ORDER BY CreatedDate
        ]) {
            contactIdByAccountId.put(contact.AccountId, contact.Id);
        }

        if (!contactIdByAccountId.isEmpty()) {
            for (Park_Of_Interest__c poi : poiByAccountId.values()) {
                if (contactIdByAccountId.containsKey(poi.Account__c)) {
                    poi.Contact__c = contactIdByAccountId.get(poi.Account__c);
                }
            }
        }
    }

    //@test: should_update_Account_on_POI_when_Missing_at_Creation
    public static void addMissingAccountOnPOIs(Map<Id, Park_Of_Interest__c> poiByContactId) {
        for (Contact contact : [SELECT AccountId FROM Contact WHERE Id IN :poiByContactId.keySet()]) {
            Park_Of_Interest__c poi = poiByContactId.get(contact.Id);
            if (contact.Id == poi.Contact__c) {
                poi.Account__c = contact.AccountId;
            }
        }
    }

    //@test: should_sync_POI_for_Contacts_from_related_Account
    //@test: should_NOT_sync_POI_for_Contacts_from_related_Account_if_already_existing
    //@test: should_delete_duplicate_POI_from_Contact_on_Insert
    public static void syncPOIsForContactsInRelatedAccount(List<Park_Of_Interest__c> newPOIs) {
        List<Park_Of_Interest__c> nonDuplicateNewPOIs = deleteDuplicatePOIs(newPOIs);
        if (nonDuplicateNewPOIs.isEmpty()) { return; }


        List<Park_Of_Interest__c> syncedPOIs = instantiatePOIsToSyncContacts(nonDuplicateNewPOIs);
        if (!syncedPOIs.isEmpty()) {
            ParkOfInterestTrigger_Handler.avoidInsertRecursion = true;
            insert syncedPOIs;
        }
    }

    //helper to syncPOIsForContactsInRelatedAccount
    private static List<Park_Of_Interest__c> deleteDuplicatePOIs(List<Park_Of_Interest__c> newPOIs) {
        List<Park_Of_Interest__c> relatedPOIs = getAccountRelatedPOIs(newPOIs);
        List<Park_Of_Interest__c> duplicatePOIs = new List<Park_Of_Interest__c>();
        List<Park_Of_Interest__c> nonDuplicateNewPOIs = new List<Park_Of_Interest__c>();
        for (Park_Of_Interest__c newPOI : newPOIs) {
            Boolean noMatchFound = true;
            for (Park_Of_Interest__c relatedPOI : relatedPOIs) {
                if (thisIsADuplicatePOI(newPOI, relatedPOI)) {
                    noMatchFound = false;
                    duplicatePOIs.add(new Park_Of_Interest__c(
                        Id = newPOI.Id
                    ));
                }
            }

            if (noMatchFound) {
                nonDuplicateNewPOIs.add(newPOI);
            }
        }

        if (!duplicatePOIs.isEmpty()) {
            ParkOfInterestTrigger_Handler.avoidDeleteRecursion = true;
            delete duplicatePOIs;
        }

        return nonDuplicateNewPOIs;
    }

    //helper to deleteDuplicatePOIs
    private static List<Park_Of_Interest__c> getAccountRelatedPOIs(List<Park_Of_Interest__c> newPOIs) {
        Set<Id> accountIds = new Set<Id>();
        for (Park_Of_Interest__c poi : newPOIs) {
            accountIds.add(poi.Account__c);
        }

        return [
            SELECT Adventure_Park__c, Contact__c
            FROM Park_Of_Interest__c
            WHERE Id NOT IN :newPOIs
            AND Account__c IN :accountIds
        ];
    }

    //helper to deleteDuplicatePOIs
    private static Boolean thisIsADuplicatePOI(Park_Of_Interest__c newPOI, Park_Of_Interest__c existingPOI) {
        return newPOI.Id != existingPOI.Id &&
            newPOI.Adventure_Park__c == existingPOI.Adventure_Park__c &&
            newPOI.Contact__c == existingPOI.Contact__c;
    }

    private static List<Park_Of_Interest__c> instantiatePOIsToSyncContacts(List<Park_Of_Interest__c> newPOIs) {
        Map<Id, List<Contact>> relatedContactsByAccountId = getRelatedContactsByAccountId(newPOIs);

        List<Park_Of_Interest__c> syncedPOIs = new List<Park_Of_Interest__c>();
        for (Park_Of_Interest__c newPOI : newPOIs) {
            if (!relatedContactsByAccountId.containsKey(newPOI.Account__c)) { continue; }

            for (Contact contact : relatedContactsByAccountId.get(newPOI.Account__c)) {
                Boolean shouldSyncPOI = true;
                for (Park_Of_Interest__c existingPOI : contact.Parks_Of_Interest__r) {
                    if (newPOI.Account__c == existingPOI.Account__c &&
                        newPOI.Contact__c == existingPOI.Contact__c &&
                        newPOI.Adventure_Park__c == existingPOI.Adventure_Park__c
                    ) {
                        shouldSyncPOI = false;
                        break;
                    }
                }

                if (shouldSyncPOI) {
                    syncedPOIs.add(new Park_Of_Interest__c(
                        Account__c = contact.AccountId,
                        Contact__c = contact.Id,
                        Adventure_Park__c = newPOI.Adventure_Park__c,
                        Synced_From_Related_Contact__c = true
                    ));
                }
            }
        }

        return syncedPOIs;
    }

    //helper to createPOIsToSyncContacts
    private static Map<Id, List<Contact>> getRelatedContactsByAccountId(List<Park_Of_Interest__c> newPOIs) {
        Set<Id> accountIds = new Set<Id>();
        for (Park_Of_Interest__c poi : newPOIs) {
            accountIds.add(poi.Account__c);
        }

        Map<Id, List<Contact>> relatedContactsByAccountId = new Map<Id, List<Contact>>();
        for (Contact contact : [
                SELECT AccountId,
                (SELECT Account__c, Contact__c, Adventure_Park__c FROM Parks_Of_Interest__r)
                FROM Contact
                WHERE AccountId IN :accountIds
        ]) {
            if (!relatedContactsByAccountId.containsKey(contact.AccountId)) {
                relatedContactsByAccountId.put(contact.AccountId, new List<Contact>());
            }
            relatedContactsByAccountId.get(contact.AccountId).add(contact);
        }

        return relatedContactsByAccountId;
    }

    //@test: should_cascade_delete_to_contacts_from_related_account
    public static void cascadePOIDeleteToAccountContacts(Map<String, Id> parkToAccount, List<String> parkContactCompositeKey) {
        List<Park_Of_Interest__c> poiListToDelete = new List<Park_Of_Interest__c>();
        for (Park_Of_Interest__c poi: [
            SELECT Adventure_Park__c, Contact__c, Account__c
            FROM Park_Of_Interest__c
            WHERE Adventure_Park__c IN :parkToAccount.keySet()
            AND Account__c IN :parkToAccount.values()
        ]) {
            String compositeKey = ParkOfInterestTrigger_Handler.createCompositeKeyFromParkAndContact(poi);
            Id relatedAccountId = parkToAccount.get(poi.Adventure_Park__c);
            if (!parkContactCompositeKey.contains(compositeKey) &&
                relatedAccountId == poi.Account__c
            ) {
                poiListToDelete.add(poi);
            }
        }

        if (!poiListToDelete.isEmpty()) {
            delete poiListToDelete;
        }
    }
}