public with sharing class LeadDisinterestedStatusManager implements TriggerAction.BeforeUpdate {

    public void beforeUpdate(List<Lead> newLeads, List<Lead> oldLeads) {
        for (Integer i = 0; i < newLeads.size(); i++) {
            Lead newLead = newLeads[i];
            Lead oldLead = oldLeads[i];

            //@test: should_set_status_to_Disinterested
            if (newLead.Disinterested_Reason__c != null &&
                oldLead.Disinterested_Reason__c != newLead.Disinterested_Reason__c
            ) {
                newLead.Status = 'Disinterested';
            }
        }
    }
}