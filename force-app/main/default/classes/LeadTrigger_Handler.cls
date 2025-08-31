public with sharing class LeadTrigger_Handler {

    public static void onBeforeInsert(List<Lead> newLeads) {
        List<Lead> reprocessedLeads = new List<Lead>();
        for (Lead newLead : newLeads) {

            if (newLead.Status == 'Reprocessed') {
                reprocessedLeads.add(newLead);
            }
        }

        if (!reprocessedLeads.isEmpty()) {
            LeadTrigger_Helper.assignLeadsToMarkingUser(reprocessedLeads);
        }
    }

    public static void onAfterInsert(List<Lead> newLeads) {
        List<Lead> leadsForParkOfInterest = new List<Lead>();
        for (Lead lead : newLeads) {

            if (lead.Parks_Of_Interest__c != null) {
                leadsForParkOfInterest.add(lead);
            }
        }

        if (!leadsForParkOfInterest.isEmpty()) {
            LeadTrigger_Helper.createParkOfInterestForNewLeads(leadsForParkOfInterest);
        }
    }

    public static void onBeforeUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        List<Lead> acceptedLeads = new List<Lead>();
        List<Lead> changedStatusLead = new List<Lead>();
        List<Lead> reprocessedLeads = new List<Lead>();
        for (Lead newLead : newLeads) {
            Lead oldLead = oldLeadMap.get(newLead.Id);

            if (oldLead.Status != newLead.Status) {
                changedStatusLead.add(newLead);
            }

            if (newLead.Accept_Lead__c == true) {
                acceptedLeads.add(newLead);
            }

            if (newLead.Status == 'Reprocessed') {
                reprocessedLeads.add(newLead);
            }

            //@test: should_set_status_to_Disinterested
            if (newLead.Disinterested_Reason__c != null &&
                oldLead.Disinterested_Reason__c != newLead.Disinterested_Reason__c
            ) {
                newLead.Status = 'Disinterested';
            }

            if (newLead.Reprocessed_Reason__c != null &&
                oldLead.Reprocessed_Reason__c != newLead.Reprocessed_Reason__c
            ) {
                LeadTrigger_Helper.processReprocessedLeads(newLead);
            }
        }

        if (!changedStatusLead.isEmpty()) {
            LeadTrigger_Helper.captureStatusChangeDate(changedStatusLead);
        }

        if (!acceptedLeads.isEmpty()) {
            LeadTrigger_Helper.reassignLead(acceptedLeads);
        }

        if (!reprocessedLeads.isEmpty()) {
            LeadTrigger_Helper.assignLeadsToMarkingUser(reprocessedLeads);
        }
    }

    public static void onAfterUpdate(List<Lead> newLeads) {

        Set<Id> convertedLeadIds = new Set<Id>();
        Set<Id> leadsForPark = new Set<Id>();
        for (Lead newLead : newLeads) {
            if (newLead.IsConverted) {
                convertedLeadIds.add(newLead.Id);
            }

            if (newLead.Parks_Of_Interest__c != null &&
                !newLead.IsConverted
            ) {
                leadsForPark.add(newLead.Id);
            }
        }

        if (!convertedLeadIds.isEmpty()) {
            LeadTrigger_Helper.remapDataForConvertedLeads(convertedLeadIds);
        }

        if (!leadsForPark.isEmpty()) {
            LeadTrigger_Helper.createParkOfInterestForExistingLeads(leadsForPark);
        }
    }

    public static void onBeforeDelete(Map<Id, Lead> oldLeadMap) {
        List<Park_Of_Interest__c> relatedParksOfInterest = new List<Park_Of_Interest__c>([
            SELECT Id
            FROM Park_Of_Interest__c
            WHERE Lead__c IN :oldLeadMap.keySet()
        ]);
        //@test: should_delete_related_POIs_on_lead_delete
        if (!relatedParksOfInterest.isEmpty()) {
            delete relatedParksOfInterest;
        }
    }
}