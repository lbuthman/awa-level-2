public with sharing class AdventureParkTrigger_Helper {

    //@test: should_set_Inactivated_Date_and_deactivate_related_POIs()
    public static void deactivateRelatedParksOfInterest(Map<Id, Date> deactivatedDateByParkId) {
        List<Park_Of_Interest__c> parkOfInterests = new List<Park_Of_Interest__c>();
        for (Park_Of_Interest__c parkOfInterest: [
                SELECT Inactive__c, Adventure_Park__c
                FROM Park_Of_Interest__c
                WHERE Adventure_Park__c IN :deactivatedDateByParkId.keySet()
        ]) {
            parkOfInterest.Inactive__c = true;
            parkOfInterest.Inactivated_Date__c = deactivatedDateByParkId.get(parkOfInterest.Adventure_Park__c);
            parkOfInterests.add(parkOfInterest);
        }
        update parkOfInterests;
    }

    //@test: should_create_opening_appointment_In_Progress()
    //@test: should_create_opening_appointment_Scheduled
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