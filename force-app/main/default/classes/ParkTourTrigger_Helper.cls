public without sharing class ParkTourTrigger_Helper {

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

    //@test: should_mark_second_Park_Tour_for_Contact_as_Return_Visitor
    //@test: should_handle_Contact_mixed_scenario_Park_Tour_insert
    public static void checkContactForRepeatTour(List<Park_Tour__c> newTours, List<Id> contactIds) {
        Map<Id, Contact> contactById = new Map<Id, Contact>([
            SELECT AccountId,
            (SELECT Adventure_Park__c FROM Park_Tour__r WHERE Adventure_Park__c != NULL)
            FROM Contact
            WHERE Id IN :contactIds
        ]);

        for (Park_Tour__c tour : newTours) {
            Contact contact = contactById.get(tour.Contact__c);
            if (contact == null || contact.Park_Tour__r.size() == 0) { continue; }

            if (contact.AccountId != null) {
                tour.Account__c = contact.AccountId;
            }

            for (Park_Tour__c existingTour : contact.Park_Tour__r) {
                if (existingTour.Adventure_Park__c == tour.Adventure_Park__c) {
                    tour.Return_Visitor__c = true;
                    break;
                }
            }
        }
    }
}