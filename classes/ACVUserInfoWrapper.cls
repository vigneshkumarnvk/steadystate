public with sharing class ACVUserInfoWrapper {
    //contract specific resource <<
    /*
    //job task <<
    @AuraEnabled
    public Company_Setup__c CompanySetup { set; get; }
    //job task >>
    @AuraEnabled
    public User User { set; get; }
    @AuraEnabled
    public Service_Center__c ServiceCenter { set; get; }
    
    public ACVUserInfoWrapper() {
        //job task <<
        this.CompanySetup = CompanyMgmt.getCompanySetup();
        //job task >>
        this.User = [SELECT Id, Name, Username, Super_User__c, Service_Center__c, Profile.Name FROM User WHERE Id = :userInfo.getUserId()];
        this.ServiceCenter = new Service_Center__c();
        if (this.User.Service_Center__c != null) {
            List<Service_Center__c> scs = [SELECT Id, Name, Description__c, Subsidiary_Company__c, Subsidiary_Company__r.Name FROM Service_Center__c WHERE Name = :this.User.Service_Center__c LIMIT 1];
            this.ServiceCenter = scs[0];
        }
    }
    */
    //contract specific resource >>
}