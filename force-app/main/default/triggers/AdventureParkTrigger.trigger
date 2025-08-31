trigger AdventureParkTrigger on Adventure_Park__c (before insert, before update, before delete, after insert, after update, after delete) {

    if (Trigger.isBefore && Trigger.isInsert) {
        AdventureParkTrigger_Handler.onBeforeInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        AdventureParkTrigger_Handler.onAfterInsert(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        AdventureParkTrigger_Handler.onBeforeUpdate(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        AdventureParkTrigger_Handler.onAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}