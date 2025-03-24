@isTest
private class TMSiteControllerTest {
    
    @isTest
    static void testGetSignature() {
        Blob b = Crypto.GenerateAESKey(128);
        String h = EncodingUtil.ConvertTohex(b);
        String guid = h.SubString(0,8)+ '-' + h.SubString(8,12) + '-' + h.SubString(12,16) + '-' + h.SubString(16,20) + '-' + h.substring(20);
        Site_Access__c siteAccess = new Site_Access__c();
        //siteAccess.Record_Id__c = recordId;
        siteAccess.Site_Page__c = 'TMSignature';
        siteAccess.Expiration_Date__c = Datetime.now().addDays(5);
        siteAccess.Token__c = guid;
        insert siteAccess;
        Signature_Request__c signatureRequest = new Signature_Request__c(
            Site_Access__c = siteAccess.Id,
            Print_Name__c = 'Test Print Name',
            Email__c = 'test@example.com',
            Accept_Terms_and_Conditions__c = true,
            Signed__c = true,
            Signature_Date__c = Date.today()
        );
        insert signatureRequest;
        SignatureWrapper signatureWrapper = new SignatureWrapper();
        signatureWrapper.AcceptTerms = true;
        signatureWrapper.PrintName = 'Test Print Name';
        signatureWrapper.Email = 'test@example.com';
        signatureWrapper.SiteAccessToken = guid;
        signatureWrapper.Signed = true;
        signatureWrapper.SignatureDate = system.today();
        signatureWrapper.Declined = false;
        signatureWrapper.CustomerPONo = 'PO123';
        signatureWrapper.CustomerComment = 'Test Comment';
        signatureWrapper.SignatureData = 'Test';
        if(siteAccess.id !=null)
        {
            Test.startTest();
            String resultTest = TMSiteController.getSignature(siteAccess.Token__c);
            String result = TMSiteController.saveSignature(JSON.serialize(signatureWrapper));
            Test.stopTest();
            System.assert(resultTest != null, 'Result should not be null');
        }
    }
}