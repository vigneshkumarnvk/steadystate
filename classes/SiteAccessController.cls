public class SiteAccessController {
    public static Site_Access__c getSiteAccess(String sitePage, String token) {
        List<Site_Access__c> siteAccesses = [SELECT Id, Record_Id__c, Site_Page__c, Token__c FROM Site_Access__c WHERE Site_Page__c = :sitePage AND Token__c = :token AND Expiration_Date__c >= :Datetime.now() ORDER BY Expiration_Date__c DESC];
        if (siteAccesses.size() > 0) {
            return siteAccesses[0];
        }
        return null;
    }

    public static Site_Access__c createSiteAccess(Id recordId, String sitePage, Datetime expirationDate) {
        Site_Access__c siteAccess = new Site_Access__c();
        siteAccess.Record_Id__c = recordId;
        siteAccess.Site_Page__c = sitePage;
        siteAccess.Expiration_Date__c = expirationDate;
        siteAccess.Token__c = generateToken();
        insert siteAccess;
        return siteAccess;
    }

    public static String generateToken() {
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        return guid;
    }
}