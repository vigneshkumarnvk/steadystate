public with sharing class RentalOrderMgmt {
    public static List <String> checkSave(Rental_Order__c theRO) {
        List<String> errorList = new List<String>();
        // Bypass checkings when allow data override
        if (companyMgmt.allowDataOverride()) {
            return errorList;
        }
        return errorList;
    }
    
    public static Rental_Order__c nullRelationshipFields(Rental_Order__c theRO) {
        theRO.Drop_Off_T_M__r = null;
        theRO.Drop_Off_T_M_Line__r = null;
        theRO.Pickup_T_M__r = null;
        theRO.Pickup_T_M_Line__r = null;
        theRO.Resource__r = null;
        theRO.Sales_Order__r = null;
        return theRO;
    }
}