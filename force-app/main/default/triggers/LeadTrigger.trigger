trigger LeadTrigger on Lead (before insert, before update, before delete, after insert, after update, after delete) {

    if (Trigger.isBefore && Trigger.isInsert) {
        LeadTrigger_Handler.onBeforeInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isInsert) {
        LeadTrigger_Handler.onAfterInsert(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        LeadTrigger_Handler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        LeadTrigger_Handler.onAfterUpdate(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isDelete) {
        LeadTrigger_Handler.onBeforeDelete(Trigger.oldMap);
    }
}