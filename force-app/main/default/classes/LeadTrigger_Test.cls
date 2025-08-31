@IsTest
private class LeadTrigger_Test {

    @IsTest
    static void reprocessed_lead_should_be_assigned_to_Marketing_User_on_Insert() {
        Lead lead = creatLead();

        Test.startTest();
        lead.Status = 'Reprocessed';
        insert lead;
        Test.stopTest();

        Lead updatedLead = [SELECT Owner.Id FROM Lead WHERE Id = :lead.Id];
        Assert.isNotNull(updatedLead.OwnerId);
    }

    @IsTest
    static void reprocessed_lead_should_be_assigned_to_Marketing_User_on_Update() {
        Lead lead = creatLead();
        insert lead;

        Test.startTest();
        lead.Status = 'Reprocessed';
        update lead;
        Test.stopTest();

        Lead updatedLead = [SELECT Owner.Id FROM Lead WHERE Id = :lead.Id];
        Assert.isNotNull(updatedLead.OwnerId);
    }

    @IsTest
    static void should_capture_status_change_date() {
        Lead lead = new Lead(
                FirstName = 'Lhorie',
                LastName = 'Salvadory',
                Email = 'lhorie@launch.com',
                Company = 'Launch with Lhorie'
        );
        insert lead;

        Test.startTest();
        lead.Status = 'Committed';
        update lead;
        Test.stopTest();

        Lead updatedLead = [SELECT Committed__c FROM Lead WHERE Id = :lead.Id];
        Assert.areEqual(Date.today(), updatedLead.Committed__c);
    }

    @IsTest
    static void should_create_POI_and_nullify_Lead() {
        Adventure_Park__c park = createPark();
        insert park;

        Lead lead = creatLead();
        lead.Parks_Of_Interest__c = park.Id;

        Test.startTest();
        insert lead;
        Test.stopTest();

        List<Park_Of_Interest__c> poiList = [SELECT Id FROM Park_Of_Interest__c WHERE Adventure_Park__c = :park.Id];
        Assert.areEqual(1, poiList.size());

        Lead updatedLead = [SELECT Parks_Of_Interest__c FROM Lead WHERE Id = :lead.Id LIMIT 1];
        Assert.isNull(updatedLead.Parks_Of_Interest__c);
    }

    @IsTest
    static void should_reassign_accepted_lead_on_update() {
        Lead lead = creatLead();
        insert lead;

        User someoneElse = getAnotherUser();

        System.runAs(someoneElse) {
            Test.startTest();
            lead.Accept_Lead__c = true;
            update lead;
            Test.stopTest();
        }

        Lead newLead = [SELECT OwnerId FROM Lead WHERE Id = :lead.Id];
        Assert.areEqual(someoneElse.Id, newLead.OwnerId);
    }

    @IsTest
    static void should_set_status_to_Disinterested() {
        Lead lead = creatLead();
        insert lead;

        Test.startTest();
        lead.Disinterested_Reason__c = 'Does not like the climate';
        update lead;
        Test.stopTest();

        Lead updatedLead = [SELECT Disinterested_Reason__c, Status FROM Lead WHERE Id = :lead.Id LIMIT 1];
        Assert.areEqual('Disinterested', updatedLead.Status);
    }

    @IsTest
    static void should_set_status_to_Engaged() {
        Lead lead = creatLead();
        insert lead;

        Test.startTest();
        lead.Reprocessed_Reason__c = 'Different park theme';
        update lead;
        Test.stopTest();

        Lead updatedLead = [SELECT Status FROM Lead WHERE Id = :lead.Id LIMIT 1];
        Assert.areEqual('Engaged', updatedLead.Status);
    }

    @IsTest
    static void should_set_status_to_Reprocessed_and_reassign_to_Marketing_User() {
        Lead lead = creatLead();
        insert lead;

        Test.startTest();
        lead.Reprocessed_Reason__c = 'Lead went stale';
        update lead;
        Test.stopTest();

        Lead updatedLead = [SELECT Status, OwnerId FROM Lead WHERE Id = :lead.Id LIMIT 1];
        Assert.areEqual('Reprocessed', updatedLead.Status);

    }

    @IsTest
    static void should_map_data_from_Converted_Lead_to_related_records() {
        Adventure_Park__c firstPark = createPark();
        Adventure_Park__c secondPark = createPark();
        secondPark.Name = 'Another Park';
        secondPark.Park_Number__c = '000999111222';
        insert firstPark;
        insert secondPark;

        Lead lead = creatLead();
        lead.Email = 'original@email.com';
        lead.Phone = '555-555-1234';
        lead.Adventure_Timeframe__c = '6 months';
        lead.Household_Income__c = '250000';
        lead.Vendor_Segment_Id__c = '123456';
        insert lead;

        Park_Tour__c firstTour = createParkTour(firstPark, lead);
        Park_Tour__c secondTour = createParkTour(secondPark, lead);
        insert firstTour;
        insert secondTour;

        Park_Of_Interest__c firstPOI = createPOI(firstPark, lead);
        Park_Of_Interest__c secondPOI = createPOI(secondPark, lead);
        insert firstPOI;
        insert secondPOI;

        Test.startTest();
        LeadStatus convertStatus = [SELECT ApiName FROM LeadStatus WHERE IsConverted = TRUE LIMIT 1];
        Database.LeadConvert convert = new Database.LeadConvert();
        convert.setLeadId(lead.Id);
        convert.setConvertedStatus(convertStatus.ApiName);
        Database.LeadConvertResult convertResult = Database.convertLead(convert, true);
        Test.stopTest();

        Assert.isTrue(convertResult.isSuccess());

        List<Account> updatedAccounts = [SELECT Phone FROM Account WHERE Email__c = :lead.Email];
        Assert.areEqual(1, updatedAccounts.size());
        Assert.areEqual(lead.Phone, updatedAccounts[0].Phone);

        List<Opportunity> updatedOpportunities = [
                SELECT Adventure_Timeframe__c, Household_Income__c, Vendor_Segment_Id__c
                FROM Opportunity
                WHERE Created_From_Lead__c = TRUE
                LIMIT 1
        ];
        Assert.areEqual(1, updatedOpportunities.size());
        Assert.areEqual(lead.Adventure_Timeframe__c, updatedOpportunities[0].Adventure_Timeframe__c);
        Assert.areEqual(lead.Household_Income__c, updatedOpportunities[0].Household_Income__c);
        Assert.areEqual(lead.Vendor_Segment_Id__c, updatedOpportunities[0].Vendor_Segment_Id__c);

        List<Park_Tour__c> parkTours = [SELECT Lead__c, Opportunity__c, Contact__c FROM Park_Tour__c];
        Assert.areEqual(2, parkTours.size());
        for (Park_Tour__c tour : parkTours) {
            Assert.isNull(tour.Lead__c);
            Assert.isNotNull(tour.Opportunity__c);
            Assert.isNotNull(tour.Contact__c);
        }

        List<Park_Of_Interest__c> parksOfInterest = [SELECT Lead__c, Contact__c FROM Park_Of_Interest__c];
        Assert.areEqual(2, parksOfInterest.size());
        for (Park_Of_Interest__c poi : parksOfInterest) {
            Assert.isNull(poi.Lead__c);
            Assert.isNotNull(poi.Contact__c);
        }

        List<OpportunityContactRole> ocrRecords = [SELECT Role, IsPrimary FROM OpportunityContactRole];
        Assert.areEqual(1, ocrRecords.size());
        Assert.areEqual('Buyer', ocrRecords[0].Role);
        Assert.isTrue(ocrRecords[0].IsPrimary);
    }

    @IsTest
    static void should_create_POI_for_existing_lead() {
        Adventure_Park__c onePark = createPark();
        insert onePark;

        Lead lead = creatLead();
        lead.Parks_Of_Interest__c = onePark.Id;
        insert lead;

        Adventure_Park__c anotherPark = createPark();
        anotherPark.Park_Number__c = '919818717616';
        insert anotherPark;

        Test.startTest();
        lead.Parks_Of_Interest__c = anotherPark.Id;
        update lead;
        Test.stopTest();

        List<Park_Of_Interest__c> parksOfInterest = [SELECT Lead__c FROM Park_Of_Interest__c];
        Assert.areEqual(2, parksOfInterest.size());
        for (Park_Of_Interest__c poi : parksOfInterest) {
            Assert.areEqual(lead.Id, poi.Lead__c);
        }

        Lead updatedLead = [SELECT Parks_Of_Interest__c FROM Lead];
        Assert.isNull(updatedLead.Parks_Of_Interest__c);
    }

    @IsTest
    static void should_delete_related_POIs_on_lead_delete() {
        Adventure_Park__c park = createPark();
        insert park;

        Lead lead = creatLead();
        lead.Parks_Of_Interest__c = park.Id;
        insert lead;

        List<Park_Of_Interest__c> parksOfInterest = [SELECT Id FROM Park_Of_Interest__c];
        Assert.areEqual(1, parksOfInterest.size());

        Test.startTest();
        delete lead;
        Test.stopTest();

        parksOfInterest = [SELECT Id FROM Park_Of_Interest__c];
        Assert.areEqual(0, parksOfInterest.size());
    }

    /** @return TEST DATA AND SETUP *****/

    static Adventure_Park__c createPark() {
        return new Adventure_Park__c(
                Name = 'Test Park',
                Park_Number__c = '123412341234',
                Is_Active__c = true,
                Open_Date__c = Date.today()
        );
    }

    static Lead creatLead() {
        return new Lead(
                FirstName = 'Lhorie',
                LastName = 'Salvadory',
                Email = 'lhorie@launch.com',
                Company = 'Launch with Lhorie'
        );
    }

    static Park_Tour__c createParkTour(Adventure_Park__c park, Lead lead) {
        return new Park_Tour__c(
                Adventure_Park__c = park.Id,
                Lead__c = lead.Id
        );
    }

    static Park_Of_Interest__c createPOI(Adventure_Park__c park, Lead lead) {
        return new Park_Of_Interest__c(
                Adventure_Park__c = park.Id,
                Lead__c = lead.Id
        );
    }

    private static User getAnotherUser() {
        User someoneElse = [SELECT Id FROM User WHERE IsActive = TRUE AND Id != :UserInfo.getUserId() LIMIT 1];
        return someoneElse;
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