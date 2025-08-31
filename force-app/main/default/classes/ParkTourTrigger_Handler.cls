public without sharing class ParkTourTrigger_Handler {

    public static void onBeforeInsert(List<Park_Tour__c> newParkTours) {
        List<Id> leadIds = new List<Id>();
        List<Id> contactIds = new List<Id>();
        for (Park_Tour__c newTour : newParkTours) {
            if (String.isNotEmpty(newTour.Lead__c)) {
                leadIds.add(newTour.Lead__c);
            }

            if (String.isNotEmpty(newTour.Contact__c)) {
                contactIds.add(newTour.Contact__c);
            }
        }

        if (!leadIds.isEmpty()) {
            ParkTourTrigger_Helper.checkLeadForRepeatTour(newParkTours, leadIds);
        }

        if (!contactIds.isEmpty()) {
            ParkTourTrigger_Helper.checkContactForRepeatTour(newParkTours, contactIds);
        }
    }
}