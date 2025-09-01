//todo: this class should not exist, because we should have control on how POIs are created.
//  Even if users create them, we should have them create them correctly. This is wasteful automation.
public with sharing class PoorlyFormedPOIPatcher implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate {

    public void beforeInsert(List<Park_Of_Interest__c> newPOIs) {
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
            setMissingContactOnPOIs(poiByAccountId);
        }

        if (!poiByContactId.isEmpty()) {
            addMissingAccountOnPOIs(poiByContactId);
        }
    }

    public void beforeUpdate(List<Park_Of_Interest__c> newPOIs, List<Park_Of_Interest__c> oldPOIs) {
        Map<Id, Park_Of_Interest__c> poiByAccountId = new Map<Id, Park_Of_Interest__c>();
        for (Integer i = 0; i < newPOIs.size(); i++) {
            Park_Of_Interest__c newPOI = newPOIs[i];
            Park_Of_Interest__c oldPOI = oldPOIs[i];

            //todo: why would the POI be reparented? It shouldn't, the old should be deleted and a new one should be
            //  created. The POI is a junction object and should consider its relationships nontransferable.
            if (newPOI.Account__c != oldPOI.Account__c) {
                if (newPOI.Account__c != null) {
                    poiByAccountId.put(newPOI.Account__c, newPOI);
                } else {
                    //@test: should_null_Contact_on_POI_when_Account_changes_to_null
                    //todo: why would the Account become null? That invalidates the purpose of the POI, erasing its
                    //  foundational data. If Account is being nullified, the POI should be deleted.
                    newPOI.Contact__c = null;
                }
            }
        }

        if (!poiByAccountId.isEmpty()) {
            setMissingContactOnPOIs(poiByAccountId);
        }
    }

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
}