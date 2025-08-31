trigger TempLeadTrigger on Temp_Lead__c (after insert) {

    if(Trigger.isAfter && Trigger.isInsert){
        //make a copy of the map, the one from the Trigger is read-only
        TempLeadTrigger_Handler.onAfterInsert(Trigger.newMap.deepClone());
    }
}