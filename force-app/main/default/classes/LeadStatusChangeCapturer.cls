public with sharing class LeadStatusChangeCapturer implements TriggerAction.BeforeUpdate {

    public void beforeUpdate(List<Lead> newLeads, List<Lead> oldLeads) {
        List<Lead> changedStatusLead = new List<Lead>();
        for (Integer i = 0; i < newLeads.size(); i++) {
            Lead newLead = newLeads[i];
            Lead oldLead = oldLeads[i];

            if (oldLead.Status != newLead.Status) {
                changedStatusLead.add(newLead);
            }
        }

        if (!changedStatusLead.isEmpty()) {
            captureStatusChangeDate(changedStatusLead);
        }
    }

    //@test: should_capture_status_change_date()
    public static void captureStatusChangeDate(List<Lead> leads) {
        Map<String, String> leadDatesByStatus = fetchLeadStatusDates();
        for (Lead lead : leads) {
            if (leadDatesByStatus.containsKey(lead.Status)) {
                lead.put(leadDatesByStatus.get(lead.Status), System.today());
            }
        }
    }

    private static Map<String, String> fetchLeadStatusDates() {
        Map<String, String> leadDatesByStatus = new Map<String, String>();
        for (Lead_and_Contact_Dates__mdt leadStatusDate : [
            SELECT Id, MasterLabel, Date_Field__c
            FROM Lead_and_Contact_Dates__mdt
            WHERE Object_Type__c = 'Lead'
        ]) {
            leadDatesByStatus.put(leadStatusDate.MasterLabel, leadStatusDate.Date_Field__c);
        }
        return leadDatesByStatus;
    }
}