public with sharing class HandleAdventureParkActivation implements TriggerAction.BeforeUpdate, TriggerAction.AfterUpdate {

    public void beforeUpdate(List<Adventure_Park__c> newParks, List<Adventure_Park__c> oldParks) {
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

    public void afterUpdate(List<Adventure_Park__c> newParks, List<Adventure_Park__c> oldParks) {
        Map<Id, Date> deactivatedDateByParkId = new Map<Id, Date>();
        for (Integer i = 0; i < newParks.size(); i++) {
            Adventure_Park__c newPark = newParks[i];
            Adventure_Park__c oldPark = oldParks[i];
            if (thisParkWasDeactivated(newPark, oldPark)) {
                deactivatedDateByParkId.put(newPark.Id, newPark.Inactivated_Date__c);
            }
        }

        if (!deactivatedDateByParkId.isEmpty()) {
            deactivateRelatedParksOfInterest(deactivatedDateByParkId);
        }
    }

    private static Boolean thisParkWasDeactivated(Adventure_Park__c newPark, Adventure_Park__c oldPark) {
        return thisParkIsNowClosed(newPark) &&
            newPark.Is_Active__c != oldPark.Is_Active__c &&
            newPark.Inactivated_Date__c != null;
    }

    //@test: should_set_Inactivated_Date_and_deactivate_related_POIs()
    public static void deactivateRelatedParksOfInterest(Map<Id, Date> deactivatedDateByParkId) {
        List<Park_Of_Interest__c> parkOfInterests = new List<Park_Of_Interest__c>();
        for (Park_Of_Interest__c parkOfInterest : [
            SELECT Inactive__c, Adventure_Park__c
            FROM Park_Of_Interest__c
            WHERE Adventure_Park__c IN :deactivatedDateByParkId.keySet()
        ]) {
            parkOfInterest.Inactive__c = true;
            parkOfInterest.Inactivated_Date__c = deactivatedDateByParkId.get(parkOfInterest.Adventure_Park__c);
            parkOfInterests.add(parkOfInterest);
        }
        update parkOfInterests;
    }
}