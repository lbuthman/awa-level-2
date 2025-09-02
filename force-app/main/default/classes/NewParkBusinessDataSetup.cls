public with sharing class NewParkBusinessDataSetup implements TriggerAction.BeforeInsert, TriggerAction.AfterInsert {

    public void beforeInsert(List<Adventure_Park__c> newParks) {
        List<Adventure_Park__c> parksWithoutPricebooks = new List<Adventure_Park__c>();
        for (Adventure_Park__c newPark : newParks) {
            if (newPark.Price_Book__c == null) {
                parksWithoutPricebooks.add(newPark);
            }
        }
        setParkPricebooks(parksWithoutPricebooks);
    }

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

    public void afterInsert(List<Adventure_Park__c> newParks) {
        Map<Id, Account> accountsByParkId = new Map<Id, Account>();
        Map<Id, Product2> productByParkId = new Map<Id, Product2>();
        for (Adventure_Park__c newPark : newParks) {
            Account account = createParkAccount(newPark);
            accountsByParkId.put(newPark.Id, account);

            Product2 product = createParkProduct(newPark);
            productByParkId.put(newPark.Id, product);
        }

        insert accountsByParkId.values();
        insert productByParkId.values();

        Pricebook2 standardPriceBook = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = TRUE LIMIT 1];
        List<PricebookEntry> pbeList = new List<PricebookEntry>();
        List<Asset> assets = new List<Asset>();
        for (Adventure_Park__c newPark : newParks) {
            pbeList.addAll(createPricebookEntryPair(
                newPark, productByParkId.get(newPark.Id), standardPriceBook
            ));

            assets.add(createAsset(
                newPark, accountsByParkId.get(newPark.Id), productByParkId.get(newPark.Id)
            ));
        }

        insert pbeList;
        insert assets;
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
}