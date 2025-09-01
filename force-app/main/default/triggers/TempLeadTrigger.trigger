trigger TempLeadTrigger on Temp_Lead__c (after insert) {

    if (Trigger.isAfter && Trigger.isInsert) {
        //make a copy of the map, the one from the Trigger is read-only
        TempLeadTrigger_Handler.onAfterInsert(Trigger.newMap.deepClone());
    }

    // This small hack allows us to easily reprocess Temp Leads when things go wrong, and after correction.
    // todo: this would be better done in a helper method. We want the functionality, not the trigger code. Make this
    //    into a tool and it will be more valuable. On-demand reprocessing.
//    if (Trigger.isAfter && Trigger.isUpdate) {
//        Map<Id, Temp_Lead__c> reprocessedTempLeadById = new Map<Id, Temp_Lead__c>();
//        for (Temp_Lead__c tempLead : Trigger.new) {
//            Temp_Lead__c oldTempLead = Trigger.oldMap.get(tempLead.Id);
//            if (tempLead.Processed__c && !oldTempLead.Processed__c) {
//                reprocessedTempLeadById.put(tempLead.Id, tempLead);
//            }
//        }
//        TempLeadTrigger_Handler.onAfterInsert(reprocessedTempLeadById);
//    }
}