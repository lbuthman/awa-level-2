@IsTest
public class TempLeadTrigger_Test {
    private static final String PARK_NAME = 'The Craggy Cliffs';
    private static final String PARK_NUMBER = '123456789012';

    @IsTest
    private static void should_create_a_new_lead_on_Temp_Lead_insert() {
        Adventure_Park__c park = TestUtils.createNewPark(PARK_NAME, PARK_NUMBER);
        insert park;

        Test.startTest();
        Temp_Lead__c tempLead = creatTempLead();
        insert tempLead;
        Test.stopTest();

        Lead createdLead = [
            SELECT Id, Household_Income__c
            FROM Lead
            WHERE LastName = :tempLead.Lead_Last_Name__c
            AND Email = :tempLead.Lead_Email__c
        ];
        Assert.areEqual('$65K-99K', createdLead.Household_Income__c);

        Temp_Lead__c updatedTempLeap = [SELECT Processed__c FROM Temp_Lead__c WHERE Id = :tempLead.Id];
        Assert.isTrue(updatedTempLeap.Processed__c);
    }

    @IsTest
    private static void should_update_existing_contact_on_Temp_Lead_Insert() {
        Adventure_Park__c park = TestUtils.createNewPark(PARK_NAME, PARK_NUMBER);
        insert park;

        Account account = new Account(Name = 'Account');
        insert account;

        Contact contact = new Contact(
            AccountId = account.Id,
            FirstName = 'Holly',
            LastName = 'Hopeful',
            Email = 'holly.hopeful@test.com'
        );
        insert contact;

        Test.startTest();
        Temp_Lead__c tempLead = creatTempLead();
        insert tempLead;
        Test.stopTest();

        Contact updatedContact = [SELECT Park_Of_Interest__c FROM Contact WHERE Id = :contact.Id];
        Assert.areEqual(park.Id, updatedContact.Park_Of_Interest__c);

        Temp_Lead__c updatedTempLeap = [SELECT Processed__c FROM Temp_Lead__c WHERE Id = :tempLead.Id];
        Assert.isTrue(updatedTempLeap.Processed__c);
    }

    @IsTest
    private static void should_create_new_contact_when_Temp_Lead_Name_is_different() {
        Adventure_Park__c park = TestUtils.createNewPark(PARK_NAME, PARK_NUMBER);
        insert park;

        Account account = new Account(Name = 'Account');
        insert account;

        Contact contact = new Contact(
            AccountId = account.Id,
            FirstName = 'Holly',
            LastName = 'Hopeful',
            Email = 'holly.hopeful@test.com'
        );
        insert contact;

        Test.startTest();
        Temp_Lead__c tempLead = creatTempLead();
        tempLead.Lead_First_Name__c = 'Name of Husband';
        insert tempLead;
        Test.stopTest();

        List<Contact> existingContacts = [SELECT Park_Of_Interest__c FROM Contact];
        Assert.areEqual(2, existingContacts.size());

        for (Contact existingContact : existingContacts) {
            if (existingContact.Id == contact.Id) {
                Assert.isNull(existingContact.Park_Of_Interest__c);
            } else {
                Assert.areEqual(park.Id, existingContact.Park_Of_Interest__c);
            }
        }

        Temp_Lead__c updatedTempLeap = [SELECT Processed__c FROM Temp_Lead__c WHERE Id = :tempLead.Id];
        Assert.isTrue(updatedTempLeap.Processed__c);
    }

    @IsTest
    private static void should_only_update_existing_Lead_with_Full_Name_match() {
        Adventure_Park__c park = TestUtils.createNewPark(PARK_NAME, PARK_NUMBER);
        insert park;

        Lead lead = new Lead(
            FirstName = 'Holly',
            LastName = 'Hopeful',
            Email = 'holly.hopeful@test.com',
            Company = 'Unaffiliated'
        );
        insert lead;

        Lead duplicateLeadWithDifferentLastName = new Lead(
            FirstName = 'Holly1',
            LastName = 'Hopeful',
            Email = 'holly.hopeful@test.com',
            Company = 'Unaffiliated'
        );

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.duplicateRuleHeader.allowSave = true;
        Database.insert(duplicateLeadWithDifferentLastName, dml);

        Test.startTest();
        Temp_Lead__c tempLead = creatTempLead();
        insert tempLead;
        Test.stopTest();

        List<Park_Of_Interest__c> parksOfInterest = [SELECT Lead__c FROM Park_Of_Interest__c];
        Assert.areEqual(1, parksOfInterest.size());
        Assert.areEqual(lead.Id, parksOfInterest[0].Lead__c);
        Assert.areNotEqual(duplicateLeadWithDifferentLastName.Id, parksOfInterest[0].Lead__c);

        Temp_Lead__c updatedTempLeap = [SELECT Processed__c FROM Temp_Lead__c WHERE Id = :tempLead.Id];
        Assert.isTrue(updatedTempLeap.Processed__c);
    }

    @IsTest
    private static void should_create_new_Lead_with_Full_Name_mismatch() {
        Adventure_Park__c park = TestUtils.createNewPark(PARK_NAME, PARK_NUMBER);
        insert park;

        Lead lead = new Lead(
            FirstName = 'Holly',
            LastName = 'Hopeful',
            Email = 'holly.hopeful@test.com',
            Company = 'Unaffiliated'
        );
        insert lead;

        Test.startTest();
        Temp_Lead__c tempLead = creatTempLead();
        tempLead.Lead_First_Name__c = 'Name of Husband';
        insert tempLead;
        Test.stopTest();

        List<Lead> existingLeads = [SELECT FirstName, LastName FROM Lead];
        Assert.areEqual(2, existingLeads.size());

        Temp_Lead__c updatedTempLeap = [SELECT Processed__c FROM Temp_Lead__c WHERE Id = :tempLead.Id];
        Assert.isTrue(updatedTempLeap.Processed__c);
    }

    @IsTest
    private static void should_only_update_existing_Contact_with_Full_Name_match() {
        Adventure_Park__c park = TestUtils.createNewPark(PARK_NAME, PARK_NUMBER);
        insert park;

        Account account1 = new Account(Name = 'Account 1');
        Account account2 = new Account(Name = 'Account 2');
        insert new List<Account>{ account1, account2 };

        Contact contact1 = new Contact(
            FirstName = 'Holly',
            LastName = 'Hopeful',
            Email = 'holly.hopeful@test.com',
            AccountId = account1.Id
        );
        insert contact1;

        Contact contact2 = new Contact(
            FirstName = 'Holly1',
            LastName = 'Hopeful',
            Email = 'holly.hopeful@test.com',
            AccountId = account2.Id
        );

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.duplicateRuleHeader.allowSave = true;
        Database.insert(contact2, dml);

        Test.startTest();
        Temp_Lead__c tempLead = creatTempLead();
        insert tempLead;
        Test.stopTest();

        Contact updatedContact1 = [SELECT Park_Of_Interest__c FROM Contact WHERE Id = :contact1.Id];
        Assert.areEqual(park.Id, updatedContact1.Park_Of_Interest__c);

        Contact updatedContact2 = [SELECT Park_Of_Interest__c FROM Contact WHERE Id = :contact2.Id];
        Assert.isNull(updatedContact2.Park_Of_Interest__c);

        Temp_Lead__c updatedTempLeap = [SELECT Processed__c FROM Temp_Lead__c WHERE Id = :tempLead.Id];
        Assert.isTrue(updatedTempLeap.Processed__c);
    }

    @IsTest
    private static void should_prefer_existing_Contact_over_existing_Lead_when_Temp_Lead_inserted() {
        Adventure_Park__c park = TestUtils.createNewPark(PARK_NAME, PARK_NUMBER);
        insert park;

        Account account = new Account(Name = 'Account');
        insert account;

        Contact contact = new Contact(
            AccountId = account.Id,
            Email = 'holly.hopeful@test.com',
            LastName = 'Hopeful',
            FirstName = 'Holly'
        );
        insert contact;

        Lead lead = new Lead(
            Email = 'holly.hopeful@test.com',
            LastName = 'Hopeful',
            FirstName = 'Holly',
            Company = 'Unaffiliated'
        );

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.duplicateRuleHeader.allowSave = true;
        Database.insert(lead, dml);

        Test.startTest();
        Temp_Lead__c tempLead = creatTempLead();
        insert tempLead;
        Test.stopTest();

        Contact updatedContact = [SELECT Park_Of_Interest__c FROM Contact WHERE Id = :contact.Id];
        Assert.areEqual(park.Id, updatedContact.Park_Of_Interest__c);

        Lead updatedLead = [SELECT Vendor_Segment_Id__c FROM Lead WHERE Id = :lead.Id];
        Assert.areNotEqual(tempLead.Vendor_Segment_Id__c, updatedLead.Vendor_Segment_Id__c);

        Temp_Lead__c updatedTempLeap = [SELECT Processed__c FROM Temp_Lead__c WHERE Id = :tempLead.Id];
        Assert.isTrue(updatedTempLeap.Processed__c);
    }

    @IsTest
    private static void should_cover_Estimated_Household_Income_translation() {
        Assert.areEqual('Under $64K', TempLeadTrigger_Handler.estimatedHouseHoldIncome(null));
        Assert.areEqual('Under $64K', TempLeadTrigger_Handler.estimatedHouseHoldIncome('   '));
        Assert.areEqual('Under $64K', TempLeadTrigger_Handler.estimatedHouseHoldIncome('$20,000-64,000'));

        Assert.areEqual('$65K-99K', TempLeadTrigger_Handler.estimatedHouseHoldIncome('$65,000 - 99,999'));
        Assert.areEqual('$100K-149K', TempLeadTrigger_Handler.estimatedHouseHoldIncome('$100000-149999'));
        Assert.areEqual('$150K-199K', TempLeadTrigger_Handler.estimatedHouseHoldIncome('$150,000-$199,999'));
        Assert.areEqual('$200K-249K', TempLeadTrigger_Handler.estimatedHouseHoldIncome('$200000-$249999'));
        Assert.areEqual('$250K-299K', TempLeadTrigger_Handler.estimatedHouseHoldIncome('250000-$299999'));
        Assert.areEqual('$300K+', TempLeadTrigger_Handler.estimatedHouseHoldIncome('$300,000+'));
        Assert.areEqual('$300K+', TempLeadTrigger_Handler.estimatedHouseHoldIncome('305000+'));

        Assert.areEqual('$100K-149K', TempLeadTrigger_Handler.estimatedHouseHoldIncome('120000'));
        Assert.areEqual('Under $64K', TempLeadTrigger_Handler.estimatedHouseHoldIncome('approx ~ fifty grand'));
    }

    @IsTest
    private static void should_cover_Adventure_Timeframe_translation() {
        Date today = Date.today();
        Assert.areEqual(null, TempLeadTrigger_Handler.adventureTimeFrame(null));
        Assert.areEqual('1 Month', TempLeadTrigger_Handler.adventureTimeFrame(mmYYYY(today)));
        Assert.areEqual('3 Months', TempLeadTrigger_Handler.adventureTimeFrame(mmYYYY(today.addMonths(4))));
        Assert.areEqual('6 Months', TempLeadTrigger_Handler.adventureTimeFrame(mmYYYY(today.addMonths(7))));
        Assert.areEqual('9 Months', TempLeadTrigger_Handler.adventureTimeFrame(mmYYYY(today.addMonths(10))));
        Assert.areEqual('1 Year +', TempLeadTrigger_Handler.adventureTimeFrame(mmYYYY(today.addMonths(15))));
    }

    // Helper to produce "MM/YYYY" from a Date (matches method's expected input).
    static String mmYYYY(Date d) {
        return d.month() + '/' + d.year();
    }

    static Temp_Lead__c creatTempLead() {
        Datetime inFiveDays = Datetime.newInstance(System.today() + 5, Time.newInstance(0, 0, 0, 0));
        String inFiveDaysString = inFiveDays.format('dd/MM/yyyy');
        return new Temp_Lead__c(
            Lead_First_Name__c = 'Holly',
            Lead_Last_Name__c = 'Hopeful',
            Lead_Email__c = 'holly.hopeful@test.com',
            Lead_Phone_Number__c = '(555) 555-1234',
            Park_Number__c = PARK_NUMBER,
            Lead_Street_Address__c = '123 1st St',
            Lead_City__c = 'OKC',
            Lead_State__c = 'OK',
            Lead_Postal_Code__c = '73703',
            Lead_Country_Code__c = 'US',
            Lead_Source__c = 'DOG',
            Vendor_Segment_Id__c = '111',
            Estimated_Household_Income__c = '$ 50,000 - 74,999',
            Lead_Adventure_Date__c = inFiveDaysString
        );
    }
}