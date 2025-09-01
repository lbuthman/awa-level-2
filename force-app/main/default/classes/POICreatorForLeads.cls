public with sharing class POICreatorForLeads implements TriggerAction.AfterInsert, TriggerAction.AfterUpdate {

    public void afterInsert(List<Lead> newLeads) {
        List<Lead> leadsForParkOfInterest = new List<Lead>();
        for (Lead lead : newLeads) {

            if (lead.Parks_Of_Interest__c != null) {
                leadsForParkOfInterest.add(lead);
            }
        }

        if (!leadsForParkOfInterest.isEmpty()) {
            createParkOfInterestForNewLeads(leadsForParkOfInterest);
        }
    }

    //@test: should_create_POI_and_nullify_Lead()
    public static void createParkOfInterestForNewLeads(List<Lead> leads) {
        Map<Id, Adventure_Park__c> parksById = fetchLeadsInterestedAdventureParks(leads);

        List<Lead> leadsForUpdate = new List<Lead>();
        List<Park_Of_Interest__c> poiForInsert = new List<Park_Of_Interest__c>();
        for (Lead lead : leads) {
            Id parkId = Id.valueOf(lead.Parks_Of_Interest__c);

            if (parksById.containsKey(parkId) && parksById.get(parkId).Is_Active__c) {
                Park_Of_Interest__c poi = createPOI(parkId, lead);
                if (!poiForInsert.contains(poi)) {
                    poiForInsert.add(poi);
                }
            }

            Lead updatedLead = nullifyLeadPOIData(lead);
            leadsForUpdate.add(updatedLead);
        }
        if (!poiForInsert.isEmpty()) {
            insert poiForInsert;
        }

        if (!leadsForUpdate.isEmpty()) {
            update leadsForUpdate;
        }
    }

    private static Map<Id, Adventure_Park__c> fetchLeadsInterestedAdventureParks(List<Lead> leads) {
        Set<Id> parkIdsFromLeads = new Set<Id>();
        for (Lead lead : leads) {
            parkIdsFromLeads.add(Id.valueOf(lead.Parks_Of_Interest__c));
        }
        return new Map<Id, Adventure_Park__c>([SELECT Id, Is_Active__c FROM Adventure_Park__c WHERE Id IN :parkIdsFromLeads]);
    }

    private static Park_Of_Interest__c createPOI(Id parkId, Lead lead) {
        Park_Of_Interest__c poi = new Park_Of_Interest__c(
            Adventure_Park__c = parkId,
            Lead__c = lead.Id,
            Rating__c = lead.Park_Of_Interest_Rating__c
        );
        return poi;
    }

    private static Lead nullifyLeadPOIData(Lead lead) {
        Lead updatedLead = new Lead(
            Id = lead.Id,
            Parks_Of_Interest__c = null,
            Park_Of_Interest_Rating__c = null
        );
        return updatedLead;
    }

    public void afterUpdate(List<Lead> newLeads, List<SObject> triggerOld) {
        Set<Id> leadsForPark = new Set<Id>();
        for (Lead newLead : newLeads) {
            if (newLead.Parks_Of_Interest__c != null &&
                !newLead.IsConverted
            ) {
                leadsForPark.add(newLead.Id);
            }
        }

        if (!leadsForPark.isEmpty()) {
            createParkOfInterestForExistingLeads(leadsForPark);
        }
    }

    //@test: should_create_POI_for_existing_lead
    public static void createParkOfInterestForExistingLeads(Set<Id> leadIds) {
        List<Lead> leads = fetchLeadsWithPOIData(leadIds);
        Map<Id, Adventure_Park__c> parksById = fetchLeadsInterestedAdventureParks(leads);

        List<Lead> leadsForUpdate = new List<Lead>();
        List<Park_Of_Interest__c> poiForInsert = new List<Park_Of_Interest__c>();
        for (Lead lead : leads) {
            Set<Id> existingParkIds = new Set<Id>();
            for (Park_Of_Interest__c poi : lead.Parks_Of_Interest__r) {
                existingParkIds.add(poi.Adventure_Park__c);
            }

            Id parkId = Id.valueOf(lead.Parks_Of_Interest__c);
            Boolean hasList = existingParkIds.contains(parkId);
            Boolean validId = parksById.containsKey(parkId) && parksById.get(parkId).Is_Active__c;

            if (hasList == false && validId == true) {
                Park_Of_Interest__c poi = createPOI(parkId, lead);
                if (!poiForInsert.contains(poi)) {
                    poiForInsert.add(poi);
                }
            }

            Lead updatedLead = nullifyLeadPOIData(lead);
            leadsForUpdate.add(updatedLead);
        }
        if (!poiForInsert.isEmpty()) {
            insert poiForInsert;
        }

        if (!leadsForUpdate.isEmpty()) {
            update leadsForUpdate;
        }
    }

    private static List<Lead> fetchLeadsWithPOIData(Set<Id> leadIds) {
        List<Lead> leads = [
            SELECT Id, Parks_Of_Interest__c, Park_Of_Interest_Rating__c, Name, Email, (
                SELECT Id, Adventure_Park__c, Lead__c
                FROM Parks_Of_Interest__r
                WHERE Lead__c IN :leadIds
            )
            FROM Lead
            WHERE Id IN :leadIds
        ];
        return leads;
    }
}