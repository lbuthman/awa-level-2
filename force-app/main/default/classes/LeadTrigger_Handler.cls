public with sharing class LeadTrigger_Handler {

    public static void onBeforeUpdate(List<Lead> newLeads, Map<Id, Lead> oldLeadMap) {
        for (Lead newLead : newLeads) {
            Lead oldLead = oldLeadMap.get(newLead.Id);

            if (newLead.Reprocessed_Reason__c != null &&
                oldLead.Reprocessed_Reason__c != newLead.Reprocessed_Reason__c
            ) {
                LeadTrigger_Helper.processReprocessedLeads(newLead);
            }
        }
    }

    public static void onAfterUpdate(List<Lead> newLeads) {
        Set<Id> convertedLeadIds = new Set<Id>();

        for (Lead newLead : newLeads) {
            if (newLead.IsConverted) {
                convertedLeadIds.add(newLead.Id);
            }
        }

        if (!convertedLeadIds.isEmpty()) {
            LeadTrigger_Helper.remapDataForConvertedLeads(convertedLeadIds);
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