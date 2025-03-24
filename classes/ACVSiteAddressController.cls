/**
 * Created by Kevin on 9/25/2019.
 */

public with sharing class ACVSiteAddressController {

    @AuraEnabled
    public static Site_Address__c saveSiteAddress(String JSONSiteAddress) {
        try {
            Site_Address__c siteAddr = (Site_Address__c ) JSON.deserialize(JSONSiteAddress, Site_Address__c .class);
            upsert siteAddr;
            return siteAddr;
        }
        catch (exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}