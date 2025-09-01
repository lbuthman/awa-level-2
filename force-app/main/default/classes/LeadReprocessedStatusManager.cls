public with sharing class LeadReprocessedStatusManager implements TriggerAction.BeforeUpdate {

    public void beforeUpdate(List<Lead> newLeads, List<Lead> oldLeads) {
        for (Integer i = 0; i < newLeads.size(); i++) {
            Lead newLead = newLeads[i];
            Lead oldLead = oldLeads[i];

            if (newLead.Reprocessed_Reason__c != null &&
                oldLead.Reprocessed_Reason__c != newLead.Reprocessed_Reason__c
            ) {
                processReprocessedLeads(newLead);
            }
        }
    }

    //@test: should_set_status_to_Engaged
    //@test: should_set_status_to_Reprocessed_and_reassign_to_Marketing_User
    public static void processReprocessedLeads(Lead newLead) {
        List<String> differentReasons = new List<String>{
            'Different park location', 'Different park price', 'Different park theme'
        };
        if (differentReasons.contains(newLead.Reprocessed_Reason__c)) {
            newLead.Status = 'Engaged';
        } else {
            newLead.Status = 'Reprocessed';
            User fakeMarketingUser = [SELECT Id FROM User WHERE Profile.Name = :System.Label.Fake_Marketing_User LIMIT 1];
            newLead.OwnerId = fakeMarketingUser.Id;
        }
    }
}