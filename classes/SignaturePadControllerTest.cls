@isTest
private class SignaturePadControllerTest {
    private static testMethod void test() {
        Company_Setup__c setup = TestDataUtil.CompanySetupRecord;
        TM__c tm = TestDataUtil.TMRecord;
        
        test.startTest();
        
        //signature request <<
        //Signature__c sig = new Signature__c(Name='customer_signature', Related_To_Object_Name__c='TM__c', Related_To_Id__c=tm.Id, Print_Name__c='Smith', Signature_Date__c=DateTime.now(), Customer_Not_Available__c = true, Accept_Terms_and_Conditions__c=true, Email__c='abc@abc.com');
        //String data = 'blob value';
        //SignaturePadController.SignatureWrapper wrapper = new SignaturePadController.SignatureWrapper(sig);
        Signature__c sig = new Signature__c(Name='customer_signature', TM__c=tm.Id, Print_Name__c='Smith', Signer_Role__c='Customer A', Signature_Date__c=DateTime.now(), Customer_Not_Available__c = true, Accept_Terms_and_Conditions__c=true, Email__c='abc@abc.com');
        String data = 'blob value';
        SignatureWrapper wrapper = new SignatureWrapper(sig);
        //signature request >>

        String JSONData = JSON.serialize(wrapper);        
        
        //SignaturePadController.uploadSignature(null, 'blob value string', 'TM__c', tm.Id, tm.Id, 'Smith', true, DateTime.now(), false, 'abc@abc.com'); 
        SignaturePadController.saveSignature(JSONData);

        //signature request <<
        //JSONData = SignaturePadController.getSignature(tm.Id, 'customer_signature');
        //wrapper = (SignaturePadController.SignatureWrapper)JSON.deserialize(JSONData, SignaturePadController.SignatureWrapper.class);
        JSONData = SignaturePadController.getSignature(tm.Id, 'Customer A');

        //ticket 21113 <<
        Signature__c signature = [SELECT Id FROM Signature__c WHERE TM__c = :tm.Id LIMIT 1];
        signature.Customer_Not_Available__c = true;
        update signature;
        JSONData = SignaturePadController.getSignature(tm.Id, 'Customer A');
        JSONData = SignaturePadController.getSignature(tm.Id, 'Customer B');
        //ticket 21113 >>

        wrapper = (SignatureWrapper)JSON.deserialize(JSONData, SignatureWrapper.class);

        //ticket 21113 <<
        wrapper.SignatureData = EncodingUtil.base64Encode(Blob.valueOf('image data'));
        SignaturePadController.saveSignature(JSON.serialize(wrapper));
        //ticket 21113 >>
        //signature request >>

        wrapper.SignatureData = null;
        JSONData = JSON.serialize(wrapper); 
        
        //SignaturePadController.uploadSignature(wrapper.Id, 'blob value string', 'TM__c', tm.Id, tm.Id, 'Smith', true, DateTime.now(), false, 'abc@abc.com'); 
        SignaturePadController.saveSignature(JSONData);

        //ticket 21113 <<
        wrapper.RequestSignature = true;
        SignaturePadController.requestSignature(wrapper);

        ApexPages.StandardController standardController = new ApexPages.StandardController(tm);
        SignatureRequestController controller = new SignatureRequestController(standardController);
        controller.sendSignatureRequestEmail();


        Sales_Order__c quote = TestDataUtil.SalesOrderRecord;
        Contact quoteContact = TestDataUtil.Contact2Record;
        quote.Document_Type__c = 'Sales Quote';
        quote.Quote_Contact__c = quoteContact.Id;
        quote.Payment_Term__c = TestDataUtil.PaymentTermRecord.Id;
        update quote;
        Signature__c signature2 = (Signature__c)JSON.deserialize(SignatureRequestController.createQuoteSignatureRequest(quote.Id), Signature__c.class);
        signature2.Request_Signature__c = true;
        signature2.Signed__c = false;
        signature2.TM__c = tm.Id; //force the signature to link to the TM for testing
        signature2.Signer_Role__c = 'Customer A';
        update signature2;

        Signature_Request__c signatureRequest = [SELECT Id FROM Signature_Request__c WHERE Id = :signature2.Signature_Request__c LIMIT 1];
        signatureRequest.Signature_Pending__c = true;
        signatureRequest.Signed__c = true;
        update signatureRequest;

        Attachment attachment =  new Attachment();
        attachment.Body = Blob.valueOf('test');
        attachment.ParentId = signatureRequest.Id;
        attachment.Name = 'customer signature';
        attachment.IsPrivate = false;
        insert attachment;

        controller.processSignatureAndEmail();
        SignatureRequestController.processSignature(tm);
        SignatureRequestController.UpdateSignatureRequest(JSON.serialize(signature2));

        ApexPages.currentPage().getParameters().put('id', quote.Id);
        SignatureProcessController processController = new SignatureProcessController();
        processController.processSignatures();
        SignatureProcessController.sendUnansweredSignatureRequestReminderEmail(new List<Signature_Request__c>{ signatureRequest });
            SignatureProcessController.getUnansweredSignatureRequests(quote.Id);
        processController.cancel();

        //ticket 21113 >>
                        
        test.stopTest();
    }
    //test123
}