public with sharing class RateSheetController {
    /*
     *  Ticket#19788
     *      -   Mass update default resource/resource type rate from selected rate sheet
     */
    @AuraEnabled
    public static String getSetupData() {
        try {
            User user = [SELECT Id, Name, Username, Super_User__c, Service_Center__c, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
            Map<String, Object> mapSetupData = new Map<String, Object>();
            mapSetupData.put('User', user);
            return JSON.serialize(mapSetupData);
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    /*
     *  Ticket#19788
     *      -   Mass update default resource/resource type rate from selected rate sheet
     */
    @AuraEnabled
    public static void updateDefaultResAndResTypePriceByRateSheet(Id rateSheetId){
        try{
            RateSheetService.updateDefaultResAndResTypePriceByRateSheet(rateSheetId);
        } catch (Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
}