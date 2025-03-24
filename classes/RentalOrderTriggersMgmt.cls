public with sharing class RentalOrderTriggersMgmt {
	public static Map<String,Numbering_Series__c> mapNumberSeries = new Map<String,Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;

    //Rental Order Header Insert Update
    public static void ROInsertUpdate(Rental_Order__c[] ROList, Map<Id, Rental_Order__c> oldROMap, Boolean isInsert) {
        //Map<String, Rental_Order__c> nameROMap = new Map<String, Rental_Order__c>();
        Set<string> setEquipmentIds = new Set<String>();
        List<Rental_Order__c> allEquipmentRO = new List<Rental_Order__c>();

        for (Rental_Order__c theRO : ROList) {
            if (IsInsert) {
                mapNumberSeries = companyMgmt.getNumber('Rental Order');
                theNumberingSeries = mapNumberSeries.get('Rental Order');
                theRO.Name = theNumberingSeries.Prefix__c + theNumberingSeries.Separator__c + String.valueOf(theNumberingSeries.Last_Number_Used__c);
            }

            if (theRO.Drop_Off_Date__c != null && theRO.Pick_Up_Date__c != null) {
                system.debug('***theRO.Drop_Off_Date__c' + theRO.Drop_Off_Date__c);
                system.debug('***theRO.Pick_Up_Date__c' + theRO.Pick_Up_Date__c);
                if (theRO.Drop_Off_Date__c >= theRO.Pick_Up_Date__c) {
                    theRO.addError('Pick Up Date must be later than Drop Off Date. Rental Order: ' + theRO.Name);
                }
            }

            if (theRO.Resource__c == null) {
                theRO.addError('Equipment Resource cannot be blank. Rental Order: ' + theRO.Name);
            }

            if (theRO.Drop_Off_Date__c == null) {
                theRO.addError('Equipment Drop Off Date cannot be blank. Rental Order: ' + theRO.Name);
            }

            if (!string.isEmpty(theRO.Resource__c) && !setEquipmentIds.contains(theRO.Resource__c)) {
                setEquipmentIds.add(theRO.Resource__c);
            }
        }

        if (setEquipmentIds != null && setEquipmentIds.size() > 0) {
            allEquipmentRO = [
                    SELECT Id,Name, Drop_Off_Date__c, Pick_Up_Date__c, Resource__c, Resource__r.Name
                    FROM Rental_Order__c
                    WHERE Resource__c IN:setEquipmentIds
            ];
        }

        Date theDropOffDate = date.newInstance(1900, 1, 1);
        Date otherDropOffDate = date.newInstance(1900, 1, 1);
        Date thePickupDate = date.newInstance(9999, 12, 31);
        Date otherPickupDate = date.newInstance(9999, 12, 31);

        for (Rental_Order__c theRO : ROList) {
            system.debug('scott51');
            if (theRO.Drop_Off_Date__c != null) theDropOffDate = theRO.Drop_Off_Date__c;
            if (theRO.Pick_Up_Date__c != null) thePickupDate = theRO.Pick_Up_Date__c;
            //if(theRO.Drop_Off_Date__c != null && theRO.Pick_Up_Date__c != null && !string.isEmpty(theRO.Resource__c)) {
            for (Rental_Order__c otherRO : allEquipmentRO) {
                system.debug('scott55');
                if (otherRO.Drop_Off_Date__c != null) otherDropOffDate = otherRO.Drop_Off_Date__c;
                if (otherRO.Pick_Up_Date__c != null) otherPickupDate = otherRO.Pick_Up_Date__c;
                //if (RO.Drop_Off_Date__c != null && RO.Pick_Up_Date__c != null && !string.isEmpty(RO.Resource__c)) {
                if (theRO.Resource__c == otherRO.Resource__c) {
                    system.debug('scott59/' + theDropOffDate + '/' + thePickupDate + '/' + otherDropOffDate + '/' + otherPickupDate);
                    if (theDropOffDate <= otherPickupDate
                        && otherDropOffDate <= thePickupDate &&(string.isEmpty(theRO.Id) || theRO.Id != otherRO.Id)) {
                        system.debug('scott60/' + theDropOffDate + '/' + thePickupDate + '/' + otherDropOffDate + '/' + otherPickupDate);
                        theRO.addError('Overlap of Equipment Drop Off Date and Pick Up date found for Resource: ' + otherRO.Resource__r.Name + ' on Rental Order: ' + otherRO.Name);
                    }
                }
                //}
            }
            //}
        }
        
        update mapNumberSeries.values();
    }
}