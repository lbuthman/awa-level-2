@IsTest
private class ParkTourTrigger_Test {

    @IsTest
    static void should_mark_second_Park_Tour_for_Lead_as_Return_Visitor() {
        Adventure_Park__c park = TestUtils.createNewPark('The Slippery Slopes', '123123123123');
        insert park;

        Lead lead = createLead();
        insert lead;

        Park_Tour__c tour1 = createParkTourForLead(park, lead);
        insert tour1;

        Test.startTest();
        Park_Tour__c tour2 = createParkTourForLead(park, lead);
        insert tour2;
        Test.stopTest();

        Park_Tour__c updatedParTour2 = [SELECT Return_Visitor__c FROM Park_Tour__c WHERE Id = :tour2.Id];
        Assert.isTrue(updatedParTour2.Return_Visitor__c);
    }

    @IsTest
    static void should_handle_Lead_mixed_scenario_Park_Tour_insert() {
        Adventure_Park__c park = TestUtils.createNewPark('The Slippery Slopes', '123123123123');
        insert park;

        Lead lead1 = createLead();
        Lead lead2 = createLead();
        insert new List<Lead>{lead1, lead2};

        Park_Tour__c lead1Tour1 = createParkTourForLead(park, lead1);
        insert lead1Tour1;

        Test.startTest();
        Park_Tour__c lead1Tour2 = createParkTourForLead(park, lead1);
        Park_Tour__c lead2Tour1 = createParkTourForLead(park, lead2);
        insert new List<Park_Tour__c>{lead1Tour2, lead2Tour1};
        Test.stopTest();

        Park_Tour__c returnVisit = [SELECT Return_Visitor__c FROM Park_Tour__c WHERE Id = :lead1Tour2.Id];
        Assert.isTrue(returnVisit.Return_Visitor__c);

        Park_Tour__c notReturnVisit = [SELECT Return_Visitor__c FROM Park_Tour__c WHERE Id = :lead2Tour1.Id];
        Assert.isFalse(notReturnVisit.Return_Visitor__c);
    }

    @IsTest
    static void should_mark_second_Park_Tour_for_Contact_as_Return_Visitor() {
        Adventure_Park__c park = TestUtils.createNewPark('The Slippery Slopes', '123123123123');
        insert park;

        Contact contact = createContact();
        insert contact;

        Park_Tour__c tour = createParkTourForContact(park, contact);
        insert tour;

        Test.startTest();
        Park_Tour__c tour2 = createParkTourForContact(park, contact);
        insert tour2;
        Test.stopTest();

        Park_Tour__c updatedParTour2 = [SELECT Return_Visitor__c FROM Park_Tour__c WHERE Id = :tour2.Id];
        Assert.isTrue(updatedParTour2.Return_Visitor__c);
    }

    @IsTest
    static void should_handle_Contact_mixed_scenario_Park_Tour_insert() {
        Adventure_Park__c park1 = TestUtils.createNewPark('The Slippery Slopes', '123123123123');
        Adventure_Park__c park2 = TestUtils.createNewPark('The Craggy Cliffs', '234234234234');
        insert new List<Adventure_Park__c>{ park1, park2 };

        Contact contact = createContact();
        insert contact;

        Park_Tour__c tour = createParkTourForContact(park1, contact);
        insert tour;

        Test.startTest();
        Park_Tour__c tour2 = createParkTourForContact(park1, contact);
        Park_Tour__c newParkTour = createParkTourForContact(park2, contact);
        insert new List<Park_Tour__c>{tour2, newParkTour};
        Test.stopTest();

        Park_Tour__c returnVisit = [SELECT Return_Visitor__c FROM Park_Tour__c WHERE Id = :tour2.Id];
        Assert.isTrue(returnVisit.Return_Visitor__c);

        Park_Tour__c newTour = [SELECT Return_Visitor__c FROM Park_Tour__c WHERE Id = :newParkTour.Id];
        Assert.isFalse(newTour.Return_Visitor__c);
    }

    private static Lead createLead() {
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Last',
            Company = 'Acme'
        );
        return lead;
    }

    private static Contact createContact() {
        Account account = new Account(Name = 'Test Account');
        insert account;

        Contact contact = new Contact(
            AccountId = account.Id,
            FirstName = 'Test',
            LastName = 'Contact'
        );
        return contact;
    }

    private static Park_Tour__c createParkTourForLead(Adventure_Park__c adventurePark, Lead lead) {
        Park_Tour__c tour = new Park_Tour__c(
            Adventure_Park__c = adventurePark.Id,
            Lead__c = lead.Id
        );
        return tour;
    }

    private static Park_Tour__c createParkTourForContact(Adventure_Park__c park, Contact contact) {
        Park_Tour__c tour = new Park_Tour__c(
            Adventure_Park__c = park.Id,
            Contact__c = contact.Id
        );
        return tour;
    }
}