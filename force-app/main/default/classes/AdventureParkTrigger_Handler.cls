public with sharing class AdventureParkTrigger_Handler {

    public static void onBeforeInsert(List<Adventure_Park__c> newParks) {
        List<Adventure_Park__c> parksWithoutPricebooks = new List<Adventure_Park__c>();
        for (Adventure_Park__c newPark : newParks) {
            if (newPark.Price_Book__c == null) {
                parksWithoutPricebooks.add(newPark);
            }
        }
        AdventureParkTrigger_Helper.setParkPricebooks(parksWithoutPricebooks);
    }

    public static void onAfterInsert(List<Adventure_Park__c> newParks) {

        Map<Id, Account> accountsByParkId = new Map<Id, Account>();
        Map<Id, Product2> productByParkId = new Map<Id, Product2>();
        List<Adventure_Park__c> activeParks = new List<Adventure_Park__c>();
        for (Adventure_Park__c newPark : newParks) {
            Account account = AdventureParkTrigger_Helper.createParkAccount(newPark);
            accountsByParkId.put(newPark.Id, account);

            Product2 product = AdventureParkTrigger_Helper.createParkProduct(newPark);
            productByParkId.put(newPark.Id, product);

            if (thisParkIsActive(newPark, null)) {
                activeParks.add(newPark);
            }
        }

        insert accountsByParkId.values();
        insert productByParkId.values();

        Pricebook2 standardPriceBook = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1];
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        List<Asset> assets = new List<Asset>();
        for (Adventure_Park__c newPark : newParks) {
            pbeList.addAll(AdventureParkTrigger_Helper.createPricebookEntryPair(
                    newPark, productByParkId.get(newPark.Id), standardPriceBook
            ));

            assets.add(AdventureParkTrigger_Helper.createAsset(
                    newPark, accountsByParkId.get(newPark.Id), productByParkId.get(newPark.Id)
            ));
        }

        insert pbeList;
        insert assets;

        if (!activeParks.isEmpty()) {
            AdventureParkTrigger_Helper.createOpeningAppointments(activeParks);
        }
    }

    private static Boolean thisParkIsActive(Adventure_Park__c newPark, Adventure_Park__c oldPark) {
        return newPark.Is_Active__c &&
                oldPark == null || oldPark?.Is_Active__c == false;
    }

    public static void onBeforeUpdate(List<Adventure_Park__c> newParks) {
        for (Adventure_Park__c newPark : newParks) {

            if (thisParkIsNowOpened(newPark)) {
                newPark.Is_Active__c = true;
            }

            //@Test: should_set_Inactivated_Date_and_deactivate_related_POIs
            if (thisParkIsNowClosed(newPark)) {
                newPark.Inactivated_Date__c = Date.today();
            }
        }
    }
    
    private static Boolean thisParkIsNowOpened(Adventure_Park__c newPark) {
        return newPark.Open_Date__c >= Date.today() && newPark.Is_Active__c == false;
    }
    
    private static Boolean thisParkIsNowClosed(Adventure_Park__c newPark) {
        return newPark.Open_Date__c < Date.today() && newPark.Is_Active__c == false;
    }

    public static void onAfterUpdate(List<Adventure_Park__c> newParks, Map<Id, Adventure_Park__c> oldMap) {
        Map<Id, Date> deactivatedDateByParkId = new Map<Id, Date>();
        List<Adventure_Park__c> activeParks = new List<Adventure_Park__c>();
        for (Adventure_Park__c newPark : newParks) {
            Adventure_Park__c oldPark = oldMap.get(newPark.Id);
            if (thisParkWasDeactivated(newPark, oldPark)) {
                deactivatedDateByParkId.put(newPark.Id, newPark.Inactivated_Date__c);
            }

            if (thisParkIsActive(newPark, oldPark)) {
                activeParks.add(newPark);
            }
        }

        if (!deactivatedDateByParkId.isEmpty()) {
            AdventureParkTrigger_Helper.deactivateRelatedParksOfInterest(deactivatedDateByParkId);
        }

        if (!activeParks.isEmpty()) {
            AdventureParkTrigger_Helper.createOpeningAppointments(activeParks);
        }
     }

    private static Boolean thisParkWasDeactivated(Adventure_Park__c newPark, Adventure_Park__c oldPark) {
        return thisParkIsNowClosed(newPark) &&
                newPark.Is_Active__c != oldPark.Is_Active__c &&
                newPark.Inactivated_Date__c != null;
    }
}