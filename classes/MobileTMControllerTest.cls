@IsTest
private class MobileTMControllerTest {

    private static testMethod void test() {
        NewTestData.createTestData();

        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        tm.Status__c = 'Scheduled';
        CompanyMgmt.byPassTrigger = true;
        update tm;

        test.startTest();

        CompanySettingUtil.acvSetting.Mobile_TM_Version_No__c = '1.0';

        String JSONSalesOrder = MobileTMController.getSalesOrder(tm.Sales_Order__c);
        String JSONTMs = MobileTMController.getTMs('', System.today(), 'TM', '1.0');

        String JSONTM = MobileTMController.getTM(tm.Id);

        String JSONJobTaskWrappers = MobileTMController.getJobTaskWrappers(tm.Id);

        String JSONTMLines = MobileTMController.getTMLines(tm.Id, 'Labor');

        //ticket 19130 <<
        MobileTMController.getJobTaskTemplateQuestionLines([SELECT Id FROM Job_Task_Template__c LIMIT 1][0].Id);
        List<ACVTMJobTaskWrapper> jobTaskWrappersLabor = (List<ACVTMJobTaskWrapper>)JSON.deserialize(JSONTMLines, List<ACVTMJobTaskWrapper>.class);
        List<ACVTMJobTaskWrapper> jobTaskWrappersEquipment = (List<ACVTMJobTaskWrapper>)JSON.deserialize(MobileTMController.getTMLines(tm.Id, 'Equipment'), List<ACVTMJobTaskWrapper>.class);

        TM_Line__c laborLine = jobTaskWrappersLabor[0].TMLines[0];
        TM_Line__c equipmentLine = jobTaskWrappersEquipment[0].TMLines[0];
        equipmentLine.Linked_Line__c = laborLine.Id;
        update equipmentLine;
        //ticket 19130 >>


        List<ACVTMJobTaskWrapper> jobTaskWrappers = (List<ACVTMJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVTMJobTaskWrapper>.class);
        if (jobTaskWrappers.size() > 0) {
            if (jobTaskWrappers[0].TMLines.size() > 0) {
                TM_Line__c tmLine = jobTaskWrappers[0].TMLines[0];
                MobileTMController.validateResourceType(JSON.serialize(tmLine));
                //ticket 19130 <<
                MobileTMController.validateResource(JSON.serialize(tmLine));
                MobileTMController.validateUnitOfMeasure(JSON.serialize(tmLine));

                //insert a new line
                TM_Line__c newTMLine = laborLine.clone(false, true);
                newTMLine.Id = null;
                newTMLine.Line_No__c = 999;
                jobTaskWrappers[0].TMLines.add(newTMLine);
                //ticket 19130 >>
            }
        }

        MobileTMController.SaveTMHeader(JSONTM);

        MobileTMController.saveTM(JSONTM, 'Labor', JSON.serialize(jobTaskWrappers));

        MobileTMController.SaveTMAndLines(JSONTM, JSONJobTaskWrappers);

        String JSONRating = MobileTMController.getServiceRating(tm.Id);
        TM_Service_Rating__c serviceRating = new TM_Service_Rating__c();
        serviceRating.TM__c = tm.Id;
        serviceRating.Rating__c = 1;
        serviceRating.Customer_Review__c = 'test';
        MobileTMController.saveServiceRating(JSON.serialize(serviceRating));

        tm.Site_Email_Address__c = 'kchen@micro-datanet.com';
        tm.Customer_Not_Available__c = true;
        update tm;

        test.stopTest();
    }

    private static testMethod void test2() {
        NewTestData.createTestData();

        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        tm.Status__c = 'Scheduled';
        CompanyMgmt.byPassTrigger = true;
        update tm;

        test.startTest();

        CompanySettingUtil.acvSetting.Mobile_TM_Version_No__c = '1.0';

        String JSONSalesOrder = MobileTMController.getSalesOrder(tm.Sales_Order__c);
        String JSONTMs = MobileTMController.getTMs('', System.today(), 'TM', '1.0');

        String JSONTM = MobileTMController.getTM(tm.Id);

        String JSONJobTaskWrappers = MobileTMController.getJobTaskWrappers(tm.Id);

        String JSONTMLines = MobileTMController.getTMLines(tm.Id, 'Labor');

        List<Site_Access__c> accesses = new List<Site_Access__c>();
        accesses.add(SiteAccessController.createSiteAccess(tm.Id, 'TMSignature', Datetime.now().addHours(48)));
        accesses.add(SiteAccessController.createSiteAccess(tm.Id, 'TMSignature', Datetime.now().addHours(48)));

        List<Signature_Request__c> requests = new List<Signature_Request__c>();
        requests.add(new Signature_Request__c(Print_Name__c = 'Customer A', Email__c = 'kchen@micro-datanet.com', Request_Email_Sent__c = true, Request_Date__c = Datetime.now(), Site_Access__c = accesses[0].Id));
        requests.add(new Signature_Request__c(Print_Name__c = 'Customer B', Email__c = 'kchen@micro-datanet.com', Request_Email_Sent__c = true, Request_Date__c = Datetime.now(), Site_Access__c = accesses[1].Id));
        insert requests;

        List<Signature__c> signatures = new List<Signature__c>();
        signatures.add(new Signature__c(TM__c = tm.Id, Name = 'supervisor_signature', Signer_Role__c = 'Supervisor', Print_Name__c = 'Kevin', Email__c = 'kchen@micro-datanet.com'));
        signatures.add(new Signature__c(TM__c = tm.Id, Name = 'customer_signature', Signer_Role__c = 'Customer A', Customer_Not_Available__c = true, Request_Signature__C = true, Print_Name__c = 'Customer A', Email__c = 'kchen@micro-datanet.com', Signature_Request__c = requests[0].Id));
        signatures.add(new Signature__c(TM__c = tm.Id, Name = 'customer_signature', Signer_Role__c = 'Customer B', Customer_Not_Available__c = true, Request_Signature__C = true, Print_Name__c = 'Customer B', Email__c = 'kchen@micro-datanet.com', Signature_Request__c = requests[1].Id));
        insert signatures;
        //signature request >>


        MobileTMController.processPDF(tm.Id);


        //signature request <<
        List<Attachment> attachments = new List<Attachment>();
        attachments.add(new Attachment(ParentId = signatures[1].Id, Name = tm.Name + '.pdf', body = Blob.valueOf('test')));
        attachments.add(new Attachment(ParentId = signatures[2].Id, Name = tm.Name + '.pdf', body = Blob.valueOf('test')));
        insert attachments;


        ApexPages.StandardController standardController = new ApexPages.StandardController(tm);
        SignatureRequestController controller = new SignatureRequestController(standardController );
        controller.sendSignatureRequestEmail();

        try {
            controller.processSignatureAndEmail();
        }
        catch(exception ex) {

        }

        SignatureRequestController.processEmailAsync(tm.Id);


        for (Signature_Request__c request : requests) {
            request.Signed__c = true;
            request.Signature_Date__c = Datetime.now();
        }
        update requests;
        attachments = new List<Attachment>();
        attachments.add(new Attachment(ParentId = requests[0].Id, Name = tm.Name + '_signature_request.pdf', body = Blob.valueOf('test')));
        attachments.add(new Attachment(ParentId = requests[1].Id, Name = tm.Name + '_signature_request.pdf', body = Blob.valueOf('test')));
        insert attachments;
        SignatureRequestController.processSignature(tm);

        for (Integer i = 1; i < signatures.size(); i++) {
            signatures[i].Signed__c = true;
        }
        update signatures;
        MobileTMController.processPDF(tm.Id);
        //signature request <<


        CompanyMgmt.ByPassTrigger = true;
        tm.Status__c = 'Mobile Review';
        update tm;
        MobileTMController.changeToScheduled(tm.Id);

        MobileTMController.sendFieldTMPDF(tm, Blob.valueOf('test pdf'));

        test.stopTest();
    }

    private static testMethod void testFileUpload() {
        NewTestData.createTestData();

        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        tm.Status__c = 'Scheduled';
        CompanyMgmt.byPassTrigger = true;
        update tm;

        test.startTest();

        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'Test 12345';
        contentVersion.PathOnClient = 'c:\test.jpg';
        contentVersion.VersionData = Blob.valueOf('test');
        contentVersion.IsMajorVersion = true;
        contentVersion.Type_fileupload__c = 'Manifest_BOL';
        insert contentVersion;

        List<ContentDocument> contentDocuments = [SELECT Id FROM ContentDocument WHERE Title = 'Test 12345'];
        ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
        contentDocumentLink.ContentDocumentId = contentDocuments[0].Id;
        contentDocumentLink.LinkedEntityId = tm.Id;
        contentDocumentLink.ShareType = 'V';
        contentDocumentLink.Visibility = 'AllUsers';
        insert contentDocumentLink;

        Attachment attachment = new Attachment();
        attachment.ParentId = tm.Sales_Order__c;
        attachment.Body = Blob.valueOf('TEST');
        attachment.IsPrivate = false;
        attachment.Description = 'test';
        attachment.Name = 'Test';
        insert attachment;

        FileUploaderController.updateTitle(tm.Id, contentDocuments[0].Id);

        FileExplorerController.getFiles(tm.Sales_Order__c, 'Service_Orders__r');
        test.stopTest();
    }
    //test12
}