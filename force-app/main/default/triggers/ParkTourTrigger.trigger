trigger ParkTourTrigger on Park_Tour__c (before insert, before update, after insert, after update) {
    new MetadataTriggerHandler().run();
}