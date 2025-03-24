@IsTest
private class Mobile_TMControllerTest {

    @IsTest
    private static void test() {
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        TM_Line__c tmLine = NewTestData.mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.LABOR_CATEGORY);
        MobileTMController.getSalesOrder(tm.Sales_Order__c);
        String tmJobTaskWrapper = MobileTMController.getJobTaskWrappers(tm.Id);
        MobileTMController.validateResourceType(JSON.serialize(tmLine));
        MobileTMController.getVersion();
        //List<Job_Task_Template_Line__c> jobTaskTemplateLines = NewTestData.mapJobTaskTemplateWrappersByName.get(NewTestData.JOB_TEMPLATE_NAME).JobTaskTemplateLines;
        Job_Task_Template__c jobTaskTemplate = NewTestData.mapJobTaskTemplateWrappersByName.get(NewTestData.JOB_TEMPLATE_NAME).JobTaskTemplate;
        MobileTMController.getJobTaskTemplateQuestionLines(jobTaskTemplate.Id);
        /*
        tm = MobileTMController.GetData(tm.Id);
        tm = MobileTMController.GetTMDetail(tm.Id);
        Resource__c resource = MobileTMController.GetResource(sc.Id, resourceType.Id, equipment.Name);
        
        List<TM_Line__c> tmls = TMLinesSelector.newInstance().selectByTmId(new Set<Id>{tm.Id}, null);
        
        //Mobile_TMController.validateResourceType(JSON.serialize(tmls[0]));

        MobileTMController.GetTermsAndConditions(tm.Sales_Order__c);

        MobileTMController.SaveTM(JSON.serialize(tm));

        tm.Site_Email_Address__c = 'kchen@micro-datanet.com';        
        tm.Customer_Not_Available__c = true;
        update tm;
        
        //signature request <<
        //Signature__c sig = new Signature__c(Related_To_Object_Name__c = 'TM__c', Related_To_Id__c = tm.Id, Name = 'customer_signature', Customer_Not_Available__c = true);
        //insert sig;          
        
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


        MobileTMController.processPdf(tm.Id);
        
        
        //signature request <<        
        List<Attachment> attachments = new List<Attachment>();
        attachments.add(new Attachment(ParentId = signatures[1].Id, Name = tm.Name + '.pdf', body = Blob.valueOf('test')));
        attachments.add(new Attachment(ParentId = signatures[2].Id, Name = tm.Name + '.pdf', body = Blob.valueOf('test')));
        insert attachments;
        
        
        ApexPages.StandardController standardController = new ApexPages.StandardController(tm);
        SignatureRequestController controller = new SignatureRequestController(standardController );
        controller.sendSignatureRequestEmail();
        
        
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
        MobileTMController.processPdf(tm.Id);
        //signature request <<        
        
        
        CompanyMgmt.ByPassTrigger = true;
        tm.Status__c = 'Mobile Review';
        update tm;
        MobileTMController.ChangeToScheduled(tm.Id);
        
        tmls[0].Job_Start_Time__c = null; //set null to avoid time deserialization error. salesforce deserialization bug
        tmls[0].Job_End_Time__c = null;
        String data = JSON.serialize(tmls);
        MobileTMController.saveTMLines(data);

        MobileTMController.DeleteTMLine(equipmentLine.Id);
         */
        Test.stopTest();
    }

    @IsTest
    private static void testServiceRating(){
        NewTestData.createTestData();
        Test.startTest();
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        List<TM_Service_Rating__c> tmServiceRatings = new List<TM_Service_Rating__c>();
        TM_Service_Rating__c tmServiceRating = new TM_Service_Rating__c();
        tmServiceRating.TM__c = tm.Id;
        tmServiceRating.Customer_Review__c = 'ASDFASDFASDF';
        tmServiceRating.Customer_Name__c = 'Test Name';
        tmServiceRating.Customer_Email__c = 'test@test.com';
        tmServiceRating.Rating__c = 1;
        tmServiceRatings.add(tmServiceRating);
        insert tmServiceRatings;

        String jsonServiceRating = MobileTMController.getServiceRating(tm.Id);
        MobileTMController.saveServiceRating(jsonServiceRating);

        Test.stopTest();
    }
  
}