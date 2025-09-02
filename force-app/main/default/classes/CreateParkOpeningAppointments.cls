public with sharing class CreateParkOpeningAppointments implements TriggerAction.AfterInsert, TriggerAction.AfterUpdate {

    public void afterInsert(List<Adventure_Park__c> newParks) {
        List<Adventure_Park__c> activeParks = new List<Adventure_Park__c>();
        for (Adventure_Park__c newPark : newParks) {

            if (thisParkIsActive(newPark, null)) {
                Logger.info('CreateParkOpeningAppointments: found active park (after insert)');
                activeParks.add(newPark);
            }
        }

        if (!activeParks.isEmpty()) {
            createOpeningAppointments(activeParks);
            Logger.info('CreateParkOpeningAppointments: completed .createOpeningAppointments()');
        }
    }

    public void afterUpdate(List<Adventure_Park__c> newParks, List<Adventure_Park__c> oldParks) {
        List<Adventure_Park__c> activeParks = new List<Adventure_Park__c>();
        for (Integer i=0; i<newParks.size(); i++) {
            Adventure_Park__c newPark = newParks[i];
            Adventure_Park__c oldPark = oldParks[i];

            if (thisParkIsActive(newPark, oldPark)) {
                Logger.info('CreateParkOpeningAppointments: found active park (after update)');
                activeParks.add(newPark);
            }
        }

        if (!activeParks.isEmpty()) {
            createOpeningAppointments(activeParks);
            Logger.info('CreateParkOpeningAppointments: completed .createOpeningAppointments()');
        }
    }

    private static Boolean thisParkIsActive(Adventure_Park__c newPark, Adventure_Park__c oldPark) {
        return newPark.Is_Active__c &&
            oldPark == null || oldPark?.Is_Active__c == false;
    }

    //@test: should_create_opening_appointment_In_Progress
    //@test: should_create_opening_appointment_Scheduled
    //@test: should_update_opening_appointment_In_Progress
    public static void createOpeningAppointments(List<Adventure_Park__c> activeParks) {

        Map<Id, Account> accountByParkId = getAccountsByParkId(activeParks);
        Map<Id, Asset> assetsByAccount = getAssetsByAccountId(accountByParkId.values());
        List<ServiceAppointment> appointToInsert = new List<ServiceAppointment>();
        for (Adventure_Park__c activePark : activeParks) {
            Account account = accountByParkId.get(activePark.Id);
            appointToInsert.add(createAppointment(activePark, assetsByAccount.get(account.Id).Id));
        }

        if (!appointToInsert.isEmpty()) {
            insert appointToInsert;
        }
    }

    private static ServiceAppointment createAppointment(Adventure_Park__c park, Id assetId) {
        Datetime openDateAtNineAM = Datetime.newInstance(park.Open_Date__c, Time.newInstance(9, 0, 0, 0));
        Datetime sevenDaysFromTodayAtNineAM = openDateAtNineAM.addDays(7);
        return  new ServiceAppointment(
            Subject = 'Opening Day Party Kickoff!',
            ParentRecordId = assetId,
            Status = park.Open_Date__c == Date.today() ? 'In Progress' : 'Scheduled',
            EarliestStartTime = openDateAtNineAM,
            DueDate = sevenDaysFromTodayAtNineAM
        );
    }

    private static Map<Id, Account> getAccountsByParkId(List<Adventure_Park__c> newParks) {
        Map<Id, Account> accountByParkId = new Map<Id, Account>();
        for (Account account : [SELECT Adventure_Park__c FROM Account WHERE Adventure_Park__c IN :newParks]) {
            accountByParkId.put(account.Adventure_Park__c, account);
        }
        return accountByParkId;
    }

    private static Map<Id, Asset> getAssetsByAccountId(List<Account> accounts) {
        Map<Id, Asset> assetsByAccountId = new Map<Id, Asset>();
        for (Asset asset : [SELECT AccountId FROM Asset WHERE AccountId IN :accounts]) {
            assetsByAccountId.put(asset.AccountId, asset);
        }
        return assetsByAccountId;
    }
}