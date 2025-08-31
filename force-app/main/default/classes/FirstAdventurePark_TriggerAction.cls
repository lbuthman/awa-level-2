public with sharing class FirstAdventurePark_TriggerAction implements TriggerAction.BeforeInsert {

    public void beforeInsert(List<Adventure_Park__c> newParks) {
        for (Adventure_Park__c newPark : newParks) {
            System.debug(newPark.Name + '? ... Oh yeah, I have been there.');
        }
    }
}