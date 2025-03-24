@isTest
private class ACVTMControllerTest {
       private static testMethod void testCreateTMFromSalesOrder() {
        NewTestData.createTestData();
        
        //test
        Test.startTest();
        List<Sales_Order__c> salesOrders = [SELECT Id FROM Sales_Order__c WHERE Name = 'SO1'];
        Sales_Order__c salesOrder = salesOrders[0];
        
        ACVTMController.getVariables();
        ACVTMController.getSalesOrderJobTasks(salesOrder.Id);
      
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        try{
        Id tmId = ACVTMController.createTMFromSalesOrder(salesOrder.Id, JSON.serialize(salesOrderWrapper.JobTaskWrappers));
        ACVTMController.getValidBillUnitCode('DM05');
        }Catch(Exception e){
            
        }
        Test.stopTest();
    }
    private static testMethod void testGetSalesOrderJobTasksWithError() {
        Test.startTest();
        try{
            String salesOrderJSON = ACVTMController.getSalesOrderJobTasks(null);
        }catch(Exception e){
            
        }
        
        Test.stopTest();
    }
    private static testMethod void testGetJobTaskTemplateWithError() {
        Test.startTest();
        try{
            String salesOrderJSON = ACVTMController.getJobTaskTemplateQuestionLines('0018H00000VkBUVQA3');
        }catch(Exception e){
            
        }
        
        Test.stopTest();
    }
    
    private static testMethod void testTM() {
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        String salesOrderJSON = ACVTMController.getSalesOrder(salesOrder.Id, salesOrderJobTask.Id);
        NewTestData.JobTaskTemplateWrapper jobTaskTemplateWrapper = NewTestData.mapJobTaskTemplateWrappersByName.get(NewTestData.JOB_TEMPLATE_NAME);
        String jobTaskTemplateLinesJSON = ACVTMController.getJobTaskTemplateQuestionLines(jobTaskTemplateWrapper.JobTaskTemplate.Id);
        Test.stopTest();
    }
    private static testMethod void testTMWithError1() {
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        salesOrder.Bill_to_Customer_No__c =  null;
        salesOrder.Bill_to_Contact__c = null;
        update salesOrder;
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        try{
            String salesOrderJSON = ACVTMController.getSalesOrder(salesOrder.Id, salesOrderJobTask.Id);
            
        }catch(Exception e){
            
        }
        NewTestData.JobTaskTemplateWrapper jobTaskTemplateWrapper = NewTestData.mapJobTaskTemplateWrappersByName.get(NewTestData.JOB_TEMPLATE_NAME);
        String jobTaskTemplateLinesJSON = ACVTMController.getJobTaskTemplateQuestionLines(jobTaskTemplateWrapper.JobTaskTemplate.Id);
        Test.stopTest();
    }
    private static testMethod void testTMWithError() {
        Test.startTest();
        try{
            String salesOrderJSON = ACVTMController.getSalesOrder(null, null);
        }catch(Exception e){
            
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testCreateTMJobTasksFromSalesOrder(){
        NewTestData.createTestData();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        
        String JSONTMWrapper = ACVTMController.getTM(tm.Id);
        ACVTMWrapper acvtmWrapper = (ACVTMWrapper)JSON.deserialize(JSONTMWrapper, ACVTMWrapper.class);
        
        Test.startTest();
        
        //ticket 19130 <<
        //String JSONTMJobTaskWrappers = ACVTMController.createTMJobTasksFromSalesOrder(JSON.serialize(tm), JSON.serialize(salesOrderWrapper.JobTaskWrappers), 10, 10);
        //acvtmWrapper.addJobTaskWrapper();
        String JSONTMJobTaskWrappers = ACVTMController.createTMJobTasksFromSalesOrder(JSON.serialize(tm), JSON.serialize(acvtmWrapper.JobTaskWrappers), JSON.serialize(salesOrderWrapper.JobTaskWrappers), 10, 10);
        //ticket 19130 >>
        
        List<ACVTMJobTaskWrapper> tmJobTaskWrappers = (List<ACVTMJobTaskWrapper>)JSON.deserialize(JSONTMJobTaskWrappers, List<ACVTMJobTaskWrapper>.class);
        
        String jsonTMJobTaskWrapper = JSON.serialize(tmJobTaskWrappers[0]);
        ACVTMController.createTMLinesFromSalesOrder(JSON.serialize(salesOrderWrapper.JobTaskWrappers[0]), JSON.serialize(tm), jsonTMJobTaskWrapper, 11, 11);
        
        ACVTMController.calculateTMJobTasks(JSON.serialize(tm), JSONTMJobTaskWrappers);
        //ACVTMController.calculateTMJobTask(JSON.serialize(tm), jsonTMJobTaskWrapper, 12);
        
        Test.stopTest();
    }
    @IsTest
    static void testCalculateTMJobTasksWithError(){
        try{
            ACVTMController.calculateTMJobTasks('stting', null);
            
        }catch(Exception e){
            
        }
    } 
    @IsTest
    static void testCreateTMJobTasksFromSalesOrderWithError(){
        try{
            ACVTMController.createTMJobTasksFromSalesOrder('stting', 'tets',null,null,null);
            
        }catch(Exception e){
            
        }
    } 
    @IsTest
    static void testCreateTMLinesFromSalesOrderWithError(){
        try{
            ACVTMController.createTMLinesFromSalesOrder('stting', 'tets',null,null,null);
            
        }catch(Exception e){
            
        }
    }
    @IsTest
    static void testValidateUnitOfMeasureWithError(){
        try{
            ACVTMController.validateUnitOfMeasure('stting', null);
            
        }catch(Exception e){
            
        }
    }
    @IsTest
    static void testGetTMWithError(){
        try{
            ACVTMController.getTM('0018H00000VkBUVQA3');
            
        }catch(Exception e){
            
        }
    }
    @IsTest
    static void testCreateTMFromSalesOrderWithError(){
        try{
            ACVTMController.createTMFromSalesOrder(null,'String');
            
        }catch(Exception e){
            
        }
    }
    @IsTest
    static void testValidateResourceTypeOrResourceWithError(){
        try{
            ACVTMController.validateResourceTypeOrResource('stting', null,null,null);
            
        }catch(Exception e){
            
        }
    }
    @IsTest
    static void testSaveTMHeaderWithError(){
        try{
            ACVTMController.saveTMHeader('stting');
            
        }catch(Exception e){
            
        }
    }
    @IsTest
    static void testValidateResourceTypeWithError(){
        try{
            ACVTMController.validateResourceType('String',null);
        }catch(Exception e){
            
        }
    }
    @IsTest
    static void testValidateResourceWithError(){
        try{
            ACVTMController.validateResource('String',null);
        }catch(Exception e){
            
        }
    }
    @IsTest
    static void testCalculateTMJobTaskWithError(){
        try{
            ACVTMController.calculateTMJobTask('stting', null,12);
            
        }catch(Exception e){
            
        }
    }
     @IsTest
    static void testPrepareWizardQuestionsWithError(){
        try{
            ACVTMController.prepareWizardQuestions('stting', null);
            
        }catch(Exception e){
            
        }
    }
      @IsTest
    static void testValidationWithError(){
        try{
            ACVTMController.validateSalesOrder('String',null);
        }catch(Exception e){
            
        }
               
    }
    
    @IsTest
    static void testSaveTM(){
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        
        //ticket 19130 <<
        //String JSONTMJobTaskWrappers = ACVTMController.createTMJobTasksFromSalesOrder(JSON.serialize(tm), JSON.serialize(salesOrderWrapper.JobTaskWrappers), 10, 10);
        //delete related records to retrieve only the TM header
        //delete [SELECT Id FROM TM_Line__c WHERE TM__c = :tm.Id];
        //delete [SELECT Id FROM TM_Job_Task__c WHERE TM__c = :tm.Id];
        String JSONTMWrapper = ACVTMController.getTM(tm.Id);
        TM_Line__c laborLine = NewTestData.mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.LABOR_CATEGORY);
        
        
        ACVTMWrapper acvtmWrapper = (ACVTMWrapper)JSON.deserialize(JSONTMWrapper, ACVTMWrapper.class);
        String JSONTMJobTaskWrappers = ACVTMController.createTMJobTasksFromSalesOrder(JSON.serialize(tm), JSON.serialize(acvtmWrapper.JobTaskWrappers), JSON.serialize(salesOrderWrapper.JobTaskWrappers), 10, 10);
        //ticket 19130 >>
        ACVTMController.saveTMHeader(JSON.serialize(tm));
        try{
            ACVTMController.saveTM(JSON.serialize(tm), JSONTMJobTaskWrappers);  
        }catch(Exception e){
            
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testSaveTM1(){
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        tm.Status__c = 'Confirmed';
        update tm;
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        
        
        String JSONTMWrapper = ACVTMController.getTM(tm.Id);
        TM_Line__c laborLine = NewTestData.mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.LABOR_CATEGORY);
        
        Resource_Flat_Pay__c resourceFlatPay = new Resource_Flat_Pay__c(
            Rate__c = 10,
            Rate_Type__c = 'PDL',
            T_M_Line__c = laborLine.Id,
            T_M__c = laborLine.TM__c
        );
        insert resourceFlatPay;
        ACVTMWrapper acvtmWrapper = (ACVTMWrapper)JSON.deserialize(JSONTMWrapper, ACVTMWrapper.class);
        String JSONTMJobTaskWrappers = ACVTMController.createTMJobTasksFromSalesOrder(JSON.serialize(tm), JSON.serialize(acvtmWrapper.JobTaskWrappers), JSON.serialize(salesOrderWrapper.JobTaskWrappers), 10, 10);
        
        try{
            ACVTMController.saveTM(JSON.serialize(tm), JSONTMJobTaskWrappers);  
        }catch(Exception e){
            
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testWizardQuestions(){
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        //ticket 19130 <<
        //String JSONTMJobTaskWrappers = ACVTMController.createTMJobTasksFromSalesOrder(JSON.serialize(tm), JSON.serialize(salesOrderWrapper.JobTaskWrappers), 10, 10);
        String JSONTMWrapper = ACVTMController.getTM(tm.Id);
        ACVTMWrapper acvtmWrapper = (ACVTMWrapper)JSON.deserialize(JSONTMWrapper, ACVTMWrapper.class);
        String JSONTMJobTaskWrappers = ACVTMController.createTMJobTasksFromSalesOrder(JSON.serialize(tm), JSON.serialize(acvtmWrapper.JobTaskWrappers), JSON.serialize(salesOrderWrapper.JobTaskWrappers), 10, 10);
        //ticket 19130 >>
        ACVTMController.prepareWizardQuestions(JSON.serialize(tm), JSONTMJobTaskWrappers);
        Test.stopTest();
    }
          @IsTest
    static void testQuestionMapTest(){
        TM_Line__c TMLineLaborRecord = new TM_Line__c(
            Line_No__c = 1,
            Description__c = 'Test item',
            Quantity__c = 1,
            Category__c = 'Labor',
            Total_Site_Hours__c = 1650,
            Regular_Hours__c = 550,
            Regular_Rate__c = 1,
            Overtime_Rate__c = 1,
            Overtime_Hours__c = 550,
            Premium_Hours__c = 550,
            Premium_Rate__c = 1,
            Unit_Price__c = 1,
            Hour__c = 1650,
            Tax_Group__c = 'TX',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            Job_Start_Time__c = system.now().addHours(-8).Time(),
            Job_End_Time__c = system.now().Time()
        );
        ACVTMController.questionMap(TMLineLaborRecord);
    }
     @IsTest
    static void testFormParentTMLineTest(){
        TM_Line__c TMLineLaborRecord = new TM_Line__c(
            Line_No__c = 1,
            Description__c = 'Test item',
            Quantity__c = 1,
            Category__c = 'Labor',
            Total_Site_Hours__c = 1650,
            Regular_Hours__c = 550,
            Regular_Rate__c = 1,
            Overtime_Rate__c = 1,
            Overtime_Hours__c = 550,
            Premium_Hours__c = 550,
            Premium_Rate__c = 1,
            Unit_Price__c = 1,
            Hour__c = 1650,
            Tax_Group__c = 'TX',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            Job_Start_Time__c = system.now().addHours(-8).Time(),
            Job_End_Time__c = system.now().Time()
        );
        ACVTMController.formParentTMLine(TMLineLaborRecord);
    }
    
    
    @IsTest
    static void testSortQuestions(){
        List<Map<String, Object>> questions = new List<Map<String, Object>> ();
        Map<String, Object> question = new Map<String, Object>();
        question.put('Line_No__c', '324');
                    question.put('Category__c', '3232');
        questions.add(question);
         question = new Map<String, Object>();
        question.put('Line_No__c', '3245');
                    question.put('Category__c', '32324');
         questions.add(question);
        ACVTMController.sortQuestions( questions);
    }
    @IsTest
    static void testValidation(){
        NewTestData.createTestData();
        Test.startTest();
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        List<ACVTMJobTaskWrapper> jobTaskWrappers = new List<ACVTMJobTaskWrapper>();
        ACVTMController.validateSalesOrder(JSON.serialize(tm), JSON.serialize(jobTaskWrappers));
        
        TM_Line__c laborLine = NewTestData.mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.LABOR_CATEGORY);
        ACVTMController.validateResourceType(JSON.serialize(tm), JSON.serialize(laborLine));
        ACVTMController.validateUnitOfMeasure(JSON.serialize(tm), JSON.serialize(laborLine));
        Test.stopTest();
    }
    
    @IsTest
    static void testValidation2(){
        NewTestData.createTestData();
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        TM_Line__c laborLine = NewTestData.mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.WASTE_DISPOSAL_CATEGORY);
        
        Test.startTest();
        
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        ACVTMController.validateResource(JSON.serialize(tm), JSON.serialize(laborLine));
        Test.stopTest();
    }
    
    @IsTest
    static void testValidation3(){
        NewTestData.createTestData();
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        TM_Line__c laborLine = NewTestData.mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.WASTE_DISPOSAL_CATEGORY);
        
        Test.startTest();
        
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        
        //ticket 19130 <<
        ACVTMWrapper tmWrapper = (ACVTMWrapper)JSON.deserialize(ACVTMController.getTM(tm.Id), ACVTMWrapper.class);
        String JSONTMJobTaskWrappers = ACVTMController.createTMJobTasksFromSalesOrder(JSON.serialize(tm), JSON.serialize(tmWrapper.JobTaskWrappers), JSON.serialize(salesOrderWrapper.JobTaskWrappers), 10, 10);
        List<ACVTMJobTaskWrapper> tmJobTaskWrappers = (List<ACVTMJobTaskWrapper>)JSON.deserialize(JSONTMJobTaskWrappers, List<ACVTMJobTaskWrapper>.class);
        ACVTMController.validateResourceTypeOrResource(JSON.serialize(tm), JSON.serialize(tmJobTaskWrappers[0]), JSON.serialize(laborLine), 13);
        //ticket 19130 >>
        Test.stopTest();
    }
    private static testMethod void testgetThirdFacility() {
        NewTestData.createTestData();
        Test.startTest();
        List<Sales_Order__c> salesOrders = [SELECT Id FROM Sales_Order__c WHERE Name = 'SO1'];
        ACVTMController.getThirdFacility(salesOrders[0].Id);
        test.stopTest();
    }

        @IsTest
    static void testCreateTMJobTasksFromSalesOrder1(){
        NewTestData.createTestData();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        
        String JSONTMWrapper = ACVTMController.getTM(tm.Id);
        ACVTMWrapper acvtmWrapper = (ACVTMWrapper)JSON.deserialize(JSONTMWrapper, ACVTMWrapper.class);
        
        Test.startTest();
        
        //ticket 19130 <<
        //String JSONTMJobTaskWrappers = ACVTMController.createTMJobTasksFromSalesOrder(JSON.serialize(tm), JSON.serialize(salesOrderWrapper.JobTaskWrappers), 10, 10);
        //acvtmWrapper.addJobTaskWrapper();
        String JSONTMJobTaskWrappers = ACVTMController.createTMJobTasksFromSalesOrder(JSON.serialize(tm), JSON.serialize(acvtmWrapper.JobTaskWrappers), JSON.serialize(salesOrderWrapper.JobTaskWrappers), 10, 10);
        //ticket 19130 >>
        
        List<ACVTMJobTaskWrapper> tmJobTaskWrappers = (List<ACVTMJobTaskWrapper>)JSON.deserialize(JSONTMJobTaskWrappers, List<ACVTMJobTaskWrapper>.class);
        
        String jsonTMJobTaskWrapper = JSON.serialize(tmJobTaskWrappers[0]);
        ACVTMController.createTMLinesFromSalesOrder(JSON.serialize(salesOrderWrapper.JobTaskWrappers[0]), JSON.serialize(tm), jsonTMJobTaskWrapper, 11, 11);
        
        ACVTMController.calculateTMJobTask(JSON.serialize(tm), jsonTMJobTaskWrapper, 12);
        
        Test.stopTest();
    }
     private static testMethod void testCreateTMFromSalesOrder1() {
        NewTestData.createTestData();
         Service_Center__c serviceCenter  = [SELECT Id, Name, Description__c, Subsidiary_Company__c, Subsidiary_Company__r.Name, Temporary__c FROM Service_Center__c Limit 1];
         serviceCenter.Temporary__c = true;
         update serviceCenter;
          User user = [SELECT Id, Name, Username, Super_User__c, Service_Center__c, profileId FROM User WHERE Id = :UserInfo.getUserId()];
           User usr = new User(LastName = 'LIVESTON',
                           FirstName='JASON',
                           Alias = 'jliv',
                           Email = 'ytest.livestons@republicservices.com',
                           Username = 'ytest.liveston@republicservices.com', 
                           ProfileId = user.profileId,
                           TimeZoneSidKey = 'GMT',
                           LanguageLocaleKey = 'en_US',
                           EmailEncodingKey = 'UTF-8',
                          LocaleSidKey = 'en_US',
                               Service_Center__c =serviceCenter.Name
                           );
         insert usr;
       
         Test.startTest();
         
        List<Sales_Order__c> salesOrders = [SELECT Id FROM Sales_Order__c WHERE Name = 'SO1'];
        Sales_Order__c salesOrder = salesOrders[0];
         System.runAs(usr){
               ACVTMController.getVariables();
         }        
      
        
       
        Test.stopTest();
    }
     private static testMethod void testCreateTMFromSalesOrder2() {
        NewTestData.createTestData();
        
        Test.startTest();
        List<Sales_Order__c> salesOrders = [SELECT Id,Bill_to_Customer_No__c FROM Sales_Order__c WHERE Name = 'SO1'];
        Sales_Order__c salesOrder = salesOrders[0];
        Account billTocustomer = new Account();
        billTocustomer.Id = salesOrder.Bill_to_Customer_No__c;   
         billTocustomer.Emergency__c = false;
         billTocustomer.Sage_Customer_No__c ='324';
         update billTocustomer;
        ACVTMController.getVariables();
        ACVTMController.getSalesOrderJobTasks(salesOrder.Id);
        //ACVTMController.getUnvoicedPicklist('TM__c');
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        try{
        Id tmId = ACVTMController.createTMFromSalesOrder(salesOrder.Id, JSON.serialize(salesOrderWrapper.JobTaskWrappers));
        }Catch(Exception e){
            
        }
        Test.stopTest();
    }
    //test2
}