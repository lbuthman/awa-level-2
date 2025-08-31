@IsTest
private class ParkOfInterestTrigger_Test {

    @IsTest
    static void should_update_Contact_on_POI_when_Missing_at_Creation() {
        Adventure_Park__c park = createPark();
        insert park;

        Account account = new Account(Name = 'Account 1');
        insert account;

        Contact contact = createContact(account);
        insert contact;

        Test.startTest();
        Park_Of_Interest__c poi = createPOIFromAccount(park, account);
        insert poi;
        Test.stopTest();

        Park_Of_Interest__c updatedPOI = [SELECT Contact__c FROM Park_Of_Interest__c WHERE Id = :poi.Id LIMIT 1];
        Assert.areEqual(updatedPOI.Contact__c, contact.Id);
    }

    @IsTest
    static void should_update_Contact_on_POI_when_Account_changes() {
        Adventure_Park__c park = createPark();
        insert park;

        Account account1 = new Account(Name = 'Account 1');
        Account account2 = new Account(Name = 'Account 2');
        insert new List<Account>{account1, account2};

        Contact contact1 = createContact(account1);
        Contact contact2 = createContact(account2);
        contact2.Email = 'contact2@test.com';
        insert new List<Contact>{contact1, contact2};

        Park_Of_Interest__c poi = createPOIFromAccount(park, account1);
        insert poi;

        Test.startTest();
        poi.Account__c = account2.Id;
        update poi;
        Test.stopTest();

        Park_Of_Interest__c updatedPOI = [SELECT Contact__c FROM Park_Of_Interest__c WHERE Id = :poi.Id LIMIT 1];
        Assert.areEqual(updatedPOI.Contact__c, contact2.Id);
    }

    @IsTest
    static void should_null_Contact_on_POI_when_Account_changes_to_null() {
        Adventure_Park__c park = createPark();
        insert park;

        Account account = new Account(Name = 'Test Account');
        insert account;

        Contact contact = createContact(account);
        insert contact;

        Park_Of_Interest__c poi = createPOIFromAccount(park, account);
        insert poi;

        Test.startTest();
        poi.Account__c = null;
        update poi;
        Test.stopTest();

        Park_Of_Interest__c updatedPOI = [SELECT Contact__c FROM Park_Of_Interest__c WHERE Id = :poi.Id LIMIT 1];
        Assert.isNull(updatedPOI.Contact__c);
    }

    @IsTest
    static void should_update_Account_on_POI_when_Missing_at_Creation() {
        Adventure_Park__c park = createPark();
        insert park;

        Account account = new Account(Name = 'Account 1');
        insert account;

        Contact contact = createContact(account);
        insert contact;

        Test.startTest();
        Park_Of_Interest__c poi = createPOIFromContact(park, contact);
        insert poi;
        Test.stopTest();

        Park_Of_Interest__c updatedPOI = [SELECT Account__c FROM Park_Of_Interest__c WHERE Id = :poi.Id LIMIT 1];
        Assert.areEqual(updatedPOI.Account__c, account.Id);
    }

    @IsTest
    static void should_sync_POI_for_Contacts_from_related_Account() {
        Adventure_Park__c park =createPark();
        insert park;

        Account account = new Account(Name = 'Test Account');
        insert account;

        Contact contact1 = createContact(account);
        Contact contact2 = createContact(account);
        contact2.Email = 'contact2@test.com';
        insert new List<Contact>{contact1, contact2};

        Test.startTest();
        Park_Of_Interest__c poi = createPOIFromAccount(park, account);
        poi.Contact__c = contact1.Id;
        insert poi;
        Test.stopTest();

        List<Park_Of_Interest__c> resultPOIs = [SELECT Id, Account__c FROM Park_Of_Interest__c WHERE Account__c = :account.Id];
        Assert.areEqual(2, resultPOIs.size());
    }

    @IsTest
    static void should_NOT_sync_POI_for_Contacts_from_related_Account_if_already_existing() {
        Adventure_Park__c park =createPark();
        insert park;

        Account account = new Account(Name = 'Test Account');
        insert account;

        Contact contact1 = createContact(account);
        Contact contact2 = createContact(account);
        contact2.Email = 'contact2@test.com';
        insert new List<Contact>{contact1, contact2};

        Park_Of_Interest__c poi1 = createPOIFromAccount(park, account);
        poi1.Contact__c = contact1.Id;
        insert poi1;

        List<Park_Of_Interest__c> resultPOIs = [SELECT Id, Account__c FROM Park_Of_Interest__c WHERE Account__c = :account.Id];
        Assert.areEqual(2, resultPOIs.size(), 'Sanity check');

        Test.startTest();
        ParkOfInterestTrigger_Handler.avoidInsertRecursion = false;
        Park_Of_Interest__c poi2 = createPOIFromAccount(park, account);
        poi2.Contact__c = contact2.Id;
        insert poi2;
        Test.stopTest();

        resultPOIs = [SELECT Id, Account__c FROM Park_Of_Interest__c WHERE Account__c = :account.Id];
        Assert.areEqual(2, resultPOIs.size());
    }

    @IsTest
    static void should_delete_duplicate_POI_from_Contact_on_Insert() {
        Adventure_Park__c park = createPark();
        insert park;

        Account account = new Account(Name = 'Test Account');
        insert account;

        Contact contact = createContact(account);
        insert contact;

        Park_Of_Interest__c poi = createPOIFromContact(park, contact);
        insert poi;

        Test.startTest();
        Park_Of_Interest__c dupePOI = createPOIFromContact(park, contact);
        insert dupePOI;
        Test.stopTest();

        List<Park_Of_Interest__c> parksOfInterest = [SELECT Id FROM Park_Of_Interest__c];
        Assert.areEqual(1, parksOfInterest.size());
    }

    @IsTest
    static void should_cascade_delete_to_contacts_from_related_account() {
        Adventure_Park__c park = createPark();
        insert park;

        Account account = new Account(Name = 'Test Account');
        insert account;

        Contact contact1 = createContact(account);
        Contact contact2 = createContact(account);
        contact2.Email = 'contact2@test.com';
        insert new List<Contact>{contact1, contact2};

        Park_Of_Interest__c poi = createPOIFromContact(park, contact1);
        insert poi;

        List<Park_Of_Interest__c> parksOfInterest = [SELECT Id FROM Park_Of_Interest__c];
        Assert.areEqual(2, parksOfInterest.size());

        Test.startTest();
        delete poi;
        Test.stopTest();

        parksOfInterest = [SELECT Id FROM Park_Of_Interest__c];
        Assert.areEqual(0, parksOfInterest.size());
    }

    /** @return Data & Setup */

    static Adventure_Park__c createPark() {
        return new Adventure_Park__c(
                Name = 'The Piney Peaks',
                Open_Date__c = System.today() + 1,
                Is_Active__c = true,
                Park_Number__c = '918273645278'
        );
    }

    static Contact createContact(Account account) {
        return new Contact(
                FirstName = 'Test',
                LastName = 'Contact',
                AccountId = account.Id,
                Email = 'test@contact.com'
        );
    }

    static Park_Of_Interest__c createPOIFromAccount(Adventure_Park__c park, Account account) {
        return new Park_Of_Interest__c(
                Adventure_Park__c = park.Id,
                Account__c = account.Id,
                Rating__c = 'Warm'
        );
    }

    static Park_Of_Interest__c createPOIFromContact(Adventure_Park__c park, Contact contact) {
        return new Park_Of_Interest__c(
                Adventure_Park__c = park.Id,
                Contact__c = contact.Id,
                Rating__c = 'Warm'
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