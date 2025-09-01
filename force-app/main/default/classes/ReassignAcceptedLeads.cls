public with sharing class ReassignAcceptedLeads implements TriggerAction.BeforeUpdate {

    public void beforeUpdate(List<Lead> newLeads, List<Lead> oldLeads) {
        List<Lead> acceptedLeads = new List<Lead>();
        for (Lead newLead : newLeads) {
            if (newLead.Accept_Lead__c == true) {
                acceptedLeads.add(newLead);
            }
        }

        if (!acceptedLeads.isEmpty()) {
            reassignLead(acceptedLeads);
        }
    }

    //@test: should_reassign_accepted_lead_on_update
    public static void reassignLead(List<Lead> leads) {
        for (Lead lead : leads) {
            lead.OwnerId = UserInfo.getUserId();
        }
    }
}