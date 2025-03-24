public class ReportsUtils {

    /******************* Method to return service center from the current user *********************/
    public static String getCurrentUserServiceCenter(){
        // Getting the current user's service center
        String serviceCenter = [SELECT Id, Service_Center__c
        FROM User
        WHERE Id = :UserInfo.getUserId()
        ][0].Service_Center__c;

        // Return service center
        return serviceCenter;
    }

    /******************* Service Center Wrapper class *********************/
    public class ServiceCenterWrapper{
        @AuraEnabled
        public String Id {get;set;}
        @AuraEnabled
        public String Name {get;set;}
        @AuraEnabled
        public String Description {get;set;}
        @AuraEnabled
        public Boolean isDefault {get;set;}
    }
}