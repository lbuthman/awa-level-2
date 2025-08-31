trigger ParkOfInterestTrigger on Park_Of_Interest__c (before insert, before update, before delete,
        after insert, after update, after delete, after undelete) {

    if (Trigger.isBefore && Trigger.isInsert) {
        ParkOfInterestTrigger_Handler.onBeforeInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        ParkOfInterestTrigger_Handler.onAfterInsert(Trigger.newMap);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        ParkOfInterestTrigger_Handler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isDelete) {
        ParkOfInterestTrigger_Handler.onAfterDelete(Trigger.old);
    }
}