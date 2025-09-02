public with sharing class AssignReprocessedLeadsToMarketingUser implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate {

    public void beforeInsert(List<Lead> newLeads) {
        List<Lead> reprocessedLeads = new List<Lead>();
        for (Lead newLead : newLeads) {
            if (newLead.Status == 'Reprocessed') {
                Logger.info('AssignReprocessedLeadsToMarketingUser: found reprocessed Leads');
                reprocessedLeads.add(newLead);
            }
        }

        if (!reprocessedLeads.isEmpty()) {
            assignLeadsToMarketingUser(reprocessedLeads);
            Logger.info('AssignReprocessedLeadsToMarketingUser Completed: .assignLeadsToMarketingUser()');
        }
    }

    //@test: reprocessed_lead_should_be_assigned_to_Marketing_User_on_Insert
    //@test: reprocessed_lead_should_be_assigned_to_Marketing_User_on_Update
    public static void assignLeadsToMarketingUser(List<Lead> leads) {
        User fakeMarketingUser = [SELECT Id FROM User WHERE Profile.Name = :System.Label.Fake_Marketing_User LIMIT 1];
        for (Lead lead : leads) {
            lead.OwnerId = fakeMarketingUser.Id;
        }
    }

    public void beforeUpdate(List<Lead> newLeads, List<Lead> oldLeads) {
        Logger.info('AssignReprocessedLeadsToMarketingUser: before update context');
        beforeInsert(newLeads);
    }
}