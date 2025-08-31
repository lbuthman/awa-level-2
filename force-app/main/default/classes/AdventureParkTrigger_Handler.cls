public with sharing class AdventureParkTrigger_Handler {

    public static void onBeforeUpdate(List<Adventure_Park__c> newParks) {
        for (Adventure_Park__c newPark : newParks) {

            if (thisParkIsNowOpened(newPark)) {
                newPark.Is_Active__c = true;
            }

            //@Test: should_set_Inactivated_Date_and_deactivate_related_POIs
            if (thisParkIsNowClosed(newPark)) {
                newPark.Inactivated_Date__c = Date.today();
            }
        }
    }
    
    private static Boolean thisParkIsNowOpened(Adventure_Park__c newPark) {
        return newPark.Open_Date__c >= Date.today() && newPark.Is_Active__c == false;
    }
    
    private static Boolean thisParkIsNowClosed(Adventure_Park__c newPark) {
        return newPark.Open_Date__c < Date.today() && newPark.Is_Active__c == false;
    }

    public static void onAfterUpdate(List<Adventure_Park__c> newParks, Map<Id, Adventure_Park__c> oldMap) {
        Map<Id, Date> deactivatedDateByParkId = new Map<Id, Date>();
        for (Adventure_Park__c newPark : newParks) {
            Adventure_Park__c oldPark = oldMap.get(newPark.Id);
            if (thisParkWasDeactivated(newPark, oldPark)) {
                deactivatedDateByParkId.put(newPark.Id, newPark.Inactivated_Date__c);
            }
        }

        if (!deactivatedDateByParkId.isEmpty()) {
            AdventureParkTrigger_Helper.deactivateRelatedParksOfInterest(deactivatedDateByParkId);
        }
     }

    private static Boolean thisParkWasDeactivated(Adventure_Park__c newPark, Adventure_Park__c oldPark) {
        return thisParkIsNowClosed(newPark) &&
                newPark.Is_Active__c != oldPark.Is_Active__c &&
                newPark.Inactivated_Date__c != null;
    }
}