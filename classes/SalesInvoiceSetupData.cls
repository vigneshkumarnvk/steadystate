public with sharing class SalesInvoiceSetupData {
    @AuraEnabled
    public Company_Setup__c CompanySetup { get; set; }

    @AuraEnabled
    public User User { get; set; }
}