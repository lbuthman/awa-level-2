trigger ParkTourTrigger on Park_Tour__c (before insert, before update, after insert, after update) {

    ParkTourTrigger_Handler handler = new ParkTourTrigger_Handler();

    if (Trigger.isBefore && Trigger.isInsert) {
        ParkTourTrigger_Handler.onBeforeInsert(Trigger.new);
    }
}