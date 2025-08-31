public with sharing class AdventureParkTrigger_Helper {

    //@test: should_create_product_data_when_park_is_created()
    public static void setParkPricebooks(List<Adventure_Park__c> parksThatNeedPricebooks) {
        Map<Id, Pricebook2> pricebookByParkId = createPriceBook(parksThatNeedPricebooks);
        for (Adventure_Park__c park : parksThatNeedPricebooks) {
            if (pricebookByParkId.containsKey(park.Id)) {
                park.Price_Book__c = pricebookByParkId.get(park.Id).Id;
            }
        }
    }

    //private helper for setParkPricebooks
    private static Map<Id, Pricebook2> createPriceBook(List<Adventure_Park__c> parks) {
        Map<Id, Pricebook2> pricebookByParkId = new Map<Id, Pricebook2>();
        for (Adventure_Park__c park : parks) {
            Pricebook2 pricebook = new Pricebook2(
                    Name = park.Name,
                    IsActive = true
            );
            pricebookByParkId.put(park.Id, pricebook);
        }

        insert pricebookByParkId.values();
        return pricebookByParkId;
    }

    //@test: should_create_product_data_when_park_is_created()
    public static Account createParkAccount(Adventure_Park__c park) {
        Account account = new Account(
                Name = park.Name + ' Account',
                Adventure_Park__c = park.Id,
                AccountSource = 'Automation'
        );
        return account;
    }

    //@test: should_create_product_data_when_park_is_created()
    public static Product2 createParkProduct(Adventure_Park__c park) {
        Product2 product = new Product2(
                Name = park.Name + ' Product',
                Adventure_Park__c = park.Id,
                IsActive = true
        );
        return product;
    }

    //@test: should_create_product_data_when_park_is_created()
    public static List<PricebookEntry> createPricebookEntryPair(
            Adventure_Park__c park, Product2 product, Pricebook2 standardPriceBook
    ) {
        List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
        PricebookEntry standardPBE = new PricebookEntry(
                Pricebook2Id = standardPriceBook.Id,
                Product2Id = product.Id,
                UnitPrice = park.Admission_Price__c,
                IsActive = true
        );
        pricebookEntries.add(standardPBE);
        PricebookEntry customPBE = new PricebookEntry(
                Pricebook2Id = park.Price_Book__c,
                Product2Id = product.Id,
                UnitPrice = park.Admission_Price__c,
                IsActive = true
        );
        pricebookEntries.add(customPBE);
        return pricebookEntries;
    }

    //@test: should_create_product_data_when_park_is_created()
    public static Asset createAsset(Adventure_Park__c park, Account account, Product2 product) {
        Asset asset = new Asset(
                Name = park.Name + ' Asset',
                Product2Id = product.Id,
                AccountId = account.Id
        );
        return asset;
    }

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