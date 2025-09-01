public with sharing class LeadDeletionHandler implements TriggerAction.BeforeDelete {

    public void beforeDelete(List<Lead> deletedLeads) {
        deleteRelatedPOIs(deletedLeads);
        deleteRelatedTours(deletedLeads);
    }

    //@test: should_delete_related_POIs_and_Park_Tours_on_lead_delete
    private static void deleteRelatedPOIs(List<Lead> deletedLeads) {
        List<Park_Of_Interest__c> relatedParksOfInterest = new List<Park_Of_Interest__c>([
            SELECT Id
            FROM Park_Of_Interest__c
            WHERE Lead__c IN :deletedLeads
        ]);

        if (!relatedParksOfInterest.isEmpty()) {
            delete relatedParksOfInterest;
        }
    }

    //@test: should_delete_related_POIs_and_Park_Tours_on_lead_delete
    private static void deleteRelatedTours(List<Lead> deletedLeads) {
        List<Park_Tour__c> relatedParkTours = new List<Park_Tour__c>([
            SELECT Id
            FROM Park_Tour__c
            WHERE Lead__c IN :deletedLeads
        ]);

        if (!relatedParkTours.isEmpty()) {
            delete relatedParkTours;
        }
    }
}