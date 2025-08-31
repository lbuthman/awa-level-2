public with sharing class NewParkBusinessDataSetupAction implements TriggerAction.BeforeInsert, TriggerAction.AfterInsert {
    private static String sharedData = '';

    public void beforeInsert(List<SObject> triggerNew) {
        sharedData = 'passing through before insert';
    }

    public void afterInsert(List<SObject> triggerNew) {
        System.debug(sharedData);
    }
}