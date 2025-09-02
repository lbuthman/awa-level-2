@IsTest
private class AdventureParkTrigger_Test {
    @IsTest
    static void should_create_product_data_when_park_is_created() {
        Adventure_Park__c park = createPark();

        Test.startTest();
        insert park;
        Test.stopTest();

        Adventure_Park__c parkNow = [SELECT Price_Book__c FROM Adventure_Park__c WHERE Id = :park.Id];
        Assert.isNotNull(parkNow.Price_Book__c);

        List<Account> accounts = [SELECT Id FROM Account WHERE Adventure_Park__c = :park.Id];
        Assert.areEqual(1, accounts.size());

        List<Product2> products = [SELECT Id FROM Product2 WHERE Adventure_Park__c = :parkNow.Id];
        Assert.areEqual(1, products.size());

        List<PricebookEntry> pricebookEntries = [SELECT Id FROM PricebookEntry WHERE Product2Id IN :products];
        Assert.areEqual(2, pricebookEntries.size());

        List<Asset> assets = [SELECT Id FROM Asset WHERE Product2Id IN :products];
        Assert.areEqual(1, assets.size());
    }

    @IsTest
    static void should_set_Inactivated_Date_and_deactivate_related_POIs() {
        Adventure_Park__c park = createPark();
        insert park;

        Lead lead = new Lead(FirstName='Test', LastName='Lead', Company = 'Acme');
        insert lead;

        Park_Of_Interest__c poi = new Park_Of_Interest__c(
            Lead__c = lead.Id,
            Adventure_Park__c = park.Id,
            Inactive__c = false
        );
        insert poi;

        park.Open_Date__c = Date.today();
        update park;

        Adventure_Park__c nowPark = [SELECT Is_Active__c FROM Adventure_Park__c WHERE Id = :park.Id];
        //sanity check
        Assert.isTrue(nowPark.Is_Active__c, 'Opened park should be active.');

        Test.startTest();
        park.Is_Active__c = false;
        park.Open_Date__c = Date.today().addDays(-1);
        update park;
        Test.stopTest();

        nowPark = [SELECT Inactivated_Date__c FROM Adventure_Park__c WHERE Id = :park.Id];
        Assert.areEqual(Date.today(), nowPark.Inactivated_Date__c);

        Park_Of_Interest__c nowPOI = [SELECT Inactive__c, Inactivated_Date__c FROM Park_Of_Interest__c WHERE Id = :poi.Id];
        Assert.isTrue(nowPOI.Inactive__c);
        Assert.areEqual(nowPark.Inactivated_Date__c, nowPOI.Inactivated_Date__c);
    }

    @IsTest
    static void should_create_opening_appointment_In_Progress() {
        Adventure_Park__c park = createPark();

        Test.startTest();
        park.Is_Active__c = true;
        park.Open_Date__c = Date.today();
        insert park;
        Test.stopTest();

        List<ServiceAppointment> serviceAppointments = [SELECT Status FROM ServiceAppointment];
        Assert.areEqual(1, serviceAppointments.size());
        Assert.areEqual('In Progress', serviceAppointments[0].Status);
    }

    @IsTest
    static void should_create_opening_appointment_Scheduled() {
        Adventure_Park__c park = createPark();
        park.Open_Date__c = Date.today().addDays(-1);
        insert park;

        Test.startTest();
        park.Is_Active__c = true;
        update park;
        Test.stopTest();

        List<ServiceAppointment> serviceAppointments = [SELECT Id, Status FROM ServiceAppointment];
        Assert.areEqual(1, serviceAppointments.size());
        Assert.areEqual('Scheduled', serviceAppointments[0].Status);
    }

    @IsTest
    static void should_update_opening_appointment_In_Progress() {
        Adventure_Park__c park = createPark();
        park.Is_Active__c = true;
        park.Open_Date__c = Date.today().addDays(-1);
        insert park;

        Test.startTest();
        park.Open_Date__c = Date.today();
        update park;
        Test.stopTest();

        List<ServiceAppointment> serviceAppointments = [SELECT Status FROM ServiceAppointment];
        Assert.areEqual(1, serviceAppointments.size());
        Assert.areEqual('Scheduled', serviceAppointments[0].Status);
    }

    private static Adventure_Park__c createPark() {
        return new Adventure_Park__c(
            Name = 'Test Park',
            Park_Number__c = '123123123123'
        );
    }

    @TestSetup
    static void setup() {
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update standardPricebook;
    }
}