public with sharing class AdventureParkTrigger_Helper {

    //@test: should_set_Inactivated_Date_and_deactivate_related_POIs()
    public static void deactivateRelatedParksOfInterest(Map<Id, Date> deactivatedDateByParkId) {
        List<Park_Of_Interest__c> parkOfInterests = new List<Park_Of_Interest__c>();
        for (Park_Of_Interest__c parkOfInterest: [
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