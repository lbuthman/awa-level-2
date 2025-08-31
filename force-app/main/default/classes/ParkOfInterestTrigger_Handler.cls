public with sharing class ParkOfInterestTrigger_Handler {
    public static Boolean avoidInsertRecursion = false;
    public static Boolean avoidDeleteRecursion = false;

    public static void onBeforeInsert(List<Park_Of_Interest__c> newPOIs) {
        Map<Id, Park_Of_Interest__c> poiByAccountId = new Map<Id, Park_Of_Interest__c>();
        Map<Id, Park_Of_Interest__c> poiByContactId = new Map<Id, Park_Of_Interest__c>();
        for (Park_Of_Interest__c newPOI : newPOIs) {
            if (newPOI.Account__c != null && newPOI.Contact__c == null) {
                poiByAccountId.put(newPOI.Account__c, newPOI);
            }

            if (newPOI.Account__c == null && newPOI.Contact__c != null) {
                poiByContactId.put(newPOI.Contact__c, newPOI);
            }
        }

        if (!poiByAccountId.isEmpty()) {
            ParkOfInterestTrigger_Helper.setMissingContactOnPOIs(poiByAccountId);
        }

        if (!poiByContactId.isEmpty()) {
            ParkOfInterestTrigger_Helper.addMissingAccountOnPOIs(poiByContactId);
        }
    }

    public static void onAfterInsert(Map<Id, Park_Of_Interest__c> newPOIMap) {
        if (avoidInsertRecursion) { return; }

        List<Park_Of_Interest__c> newPOIsNotCreatedFromSync = new List<Park_Of_Interest__c>();
        for (Park_Of_Interest__c poi : newPOIMap.values()) {
            //note: there are three possible outcomes from the condition below
            //  1) The POI is unique to the Contact, not created from the sync, and needs to be synced to related Contacts.
            //  2) The POI was already created from the sync, and be deleted as a duplicate.
            //  3) The POI is a duplicate, and be deleted as a duplicate.
            if (poi.Adventure_Park__c != null &&
                poi.Contact__c != null
            ) {
                newPOIsNotCreatedFromSync.add(poi);
            }
        }

        if (!newPOIsNotCreatedFromSync.isEmpty()) {
            ParkOfInterestTrigger_Helper.syncPOIsForContactsInRelatedAccount(newPOIsNotCreatedFromSync);
        }
    }

    public static void onBeforeUpdate(List<Park_Of_Interest__c> newPOIs, Map<Id, Park_Of_Interest__c> oldPOIMap) {

        Map<Id, Park_Of_Interest__c> poiByAccountId = new Map<Id, Park_Of_Interest__c>();
        for (Park_Of_Interest__c newPOI : newPOIs) {
            Park_Of_Interest__c oldPOI = oldPOIMap.get(newPOI.Id);

            if (newPOI.Account__c != oldPOI.Account__c) {
                if (newPOI.Account__c != null) {
                    poiByAccountId.put(newPOI.Account__c, newPOI);
                } else {
                    //@test: should_null_Contact_on_POI_when_Account_changes_to_null
                    newPOI.Contact__c = null;
                }
            }
        }

        if (!poiByAccountId.isEmpty()) {
            ParkOfInterestTrigger_Helper.setMissingContactOnPOIs(poiByAccountId);
        }
    }

    public static void onAfterDelete(List<Park_Of_Interest__c> deletedPOIs) {
        if (avoidDeleteRecursion) { return; }

        Map<String, Id> accountIdToParkId = new Map<String, Id>();
        List<String> parkContactCompositeKey = new List<String>();
        for (Park_Of_Interest__c poi : deletedPOIs) {
            if (poi.Contact__c != null && poi.Account__c != null) {
                accountIdToParkId.put(poi.Adventure_Park__c, poi.Account__c);
                parkContactCompositeKey.add(createCompositeKeyFromParkAndContact(poi));
            }
        }

        if (!accountIdToParkId.isEmpty()) {
            ParkOfInterestTrigger_Helper.cascadePOIDeleteToAccountContacts(accountIdToParkId, parkContactCompositeKey);
        }

        avoidDeleteRecursion = true;
    }

    public static String createCompositeKeyFromParkAndContact(Park_Of_Interest__c poi) {
        return poi.Adventure_Park__c + '-' + poi.Contact__c;
    }
}