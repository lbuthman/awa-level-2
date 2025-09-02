public with sharing class RepeatTourLeadChecker implements TriggerAction.BeforeInsert {

    public void beforeInsert(List<Park_Tour__c> newParkTours) {
        List<Id> leadIds = new List<Id>();
        for (Park_Tour__c newTour : newParkTours) {
            if (String.isNotEmpty(newTour.Lead__c)) {
                leadIds.add(newTour.Lead__c);
            }
        }

        if (!leadIds.isEmpty()) {
            checkLeadForRepeatTour(newParkTours, leadIds);
        }
    }

    //@test: should_mark_second_Park_Tour_for_Lead_as_Return_Visitor
    //@test: should_handle_Lead_mixed_scenario_Park_Tour_insert
    public static void checkLeadForRepeatTour(List<Park_Tour__c> newTours, List<Id> leadIds) {
        Map<Id, Lead> leadById = new Map<Id, Lead>([
            SELECT Id,
            (SELECT Id, Adventure_Park__c FROM Park_Tour__r)
            FROM Lead
            WHERE Id IN :leadIds
        ]);

        for (Park_Tour__c tour : newTours) {
            Lead lead = leadById.get(tour.Lead__c);
            if (lead == null || lead.Park_Tour__r.size() == 0) { continue; }

            for (Park_Tour__c existingTour : lead.Park_Tour__r) {
                if (existingTour.Adventure_Park__c == tour.Adventure_Park__c) {
                    tour.Return_Visitor__c = true;
                    break;
                }
            }
        }
    }
}