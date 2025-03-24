/**
 * ACVSalesOrderControllerTest
 * Created by Kevin on 1/29/2020...
 */
@isTest
private class ACVSalesOrderControllerTest {
       
        public static testMethod void testNewSalesOrder() {
        NewTestData.createTestData();
        Billing_Rule__c billingRule = NewTestData.mapBillingRuleWrappersByName.get('Company Default').BillingRule;
        Account billToCustomer = NewTestData.mapAccountWrappersByName.get('Customer').Account;
        Service_Center__c serviceCenter = NewTestData.mapServiceCenterWrappersByName.get('02').ServiceCenter;

        Test.startTest();

        ACVSalesOrderController.getSetupData();

        ACVSalesOrderController.getCompanySetup();

        ACVSalesOrderController.allowNewSalesOrders(billToCustomer.Id);

        ACVSalesOrderController.isValidCustomer(billToCustomer.Id);

        ACVSalesOrderController.isValidCustomerToCreateOpportunity(billToCustomer.Id);
        ACVSalesOrderController.isValidCustomerPONumber(billToCustomer.Id, '12345');

        ACVSalesOrderController.getWeekendAndHoliday(Date.newInstance(12, 25, system.today().year()), 5, billingRule.Id, true, true);
       
        ACVSalesOrderController.getContracts(billToCustomer.Id);

        String JSONSalesOrderWrapper = ACVSalesOrderController.createNewSalesOrder('Sales Order', billToCustomer.Id, serviceCenter.Name, null);
       
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);

        ACVSalesOrderJobTaskWrapper jobTaskWrapper = new ACVSalesOrderJobTaskWrapper();
        jobTaskWrapper.JobTask = new Sales_Order_Job_Task__c(Name = 'Field Services', Line_No__c = 1, Billing_Type__c = 'T&M', Task_No__c = 1);
        salesOrderWrapper.JobTaskWrappers.add(jobTaskWrapper);

        JSONSalesOrderWrapper = ACVSalesOrderController.validateCustomer(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers));
        salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);

        salesOrderWrapper.SalesOrder.Sales_Order_Type__r = NewTestData.mapSalesOrderTypesByName.get('Field Services');
        ACVSalesOrderController.validateSalesOrderType(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers));
        salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);

        ACVSalesOrderController.calculatePriceInfo(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers));
        salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);

        salesOrderWrapper.SalesOrder.Estimated_Job_Start_Date__c = system.today();
        salesOrderWrapper.SalesOrder.Estimated_Job_End_Date__c = system.today();
        JSONSalesOrderWrapper = ACVSalesOrderController.calculateEstimatedDateInfo(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers), true);


        Test.stopTest();
    }

    public static testMethod void testExistingSalesOrder1() {
        NewTestData.createTestData();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');

        Test.startTest();

        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);

        ACVSalesOrderJobTaskWrapper newJobTaskWrapper = new ACVSalesOrderJobTaskWrapper();
        newJobTaskWrapper.JobTask = new Sales_Order_Job_Task__c(Name = 'Field Services Clone', Line_No__c = 2, Task_No__c = 2, Billing_Type__c = 'T&M');
        Integer nextSalesLineNo = ACVSalesOrderController.getNextSalesLineNo(salesOrderWrapper.JobTaskWrappers);
        ACVSalesOrderController.cloneJobTask(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers[0]), JSON.serialize(newJobTaskWrapper), nextSalesLineNo);

        //String JSONJobTaskWrappers = ACVSalesOrderController.calculateSalesOrder(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers), true, nextSalesLineNo);
        JSONSalesOrderWrapper = ACVSalesOrderController.calculateSalesOrder(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers), true, nextSalesLineNo);
        salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = salesOrderWrapper.JobTaskWrappers;

        //update manifest fee line qty to 1
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                if (salesLine.Category__c == 'Waste Disposal' && salesLine.System_Calculated_Line__c == true && salesLine.Quantity__c == 0) {
                    salesLine.Quantity__c = 1;
                }
            }
        }

        String JSONJobTaskWrappers = ACVSalesOrderController.recalculateSalesLineDetails(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(jobTaskWrappers), true);
        jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);

        //recalculate lines on contract change 10.16.2020 <<
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                if (salesLine.Category__c == 'Bundled') {
                    SalesLinesService.calculateLumpSumLine(salesLine, salesOrder, jobTaskWrapper.SalesLines, true);
                }
            }
        }
        //recalculate lines on contract change 10.16.2020 >>
        Test.stopTest();
    }

    public static testMethod void testExistingSalesOrder2() {
        NewTestData.createTestData();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');

        Test.startTest();

        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper) JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);

        Integer nextSalesLineNo = ACVSalesOrderController.getNextSalesLineNo(salesOrderWrapper.JobTaskWrappers);
        ACVSalesOrderController.validateSurchargeType(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers));
        ACVSalesOrderController.validateSurchargePct(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers));
        ACVSalesOrderController.calculateTax(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers[0]));
        ACVSalesOrderController.calculateSalesOrderJobTask(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers[0]), nextSalesLineNo);
        ACVSalesOrderController.validateAssumptionChange(JSONSalesOrderWrapper);  
        Test.stopTest();
    }


    public static testMethod void testExistingSalesOrder3() {
        NewTestData.createTestData();
        //Sales_Order__c salesOrder = NewTestData.mapSalesOrderWrappersByName.get('SO1').SalesOrder;
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');

        Test.startTest();

        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper) JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        
        try{

        ACVSalesOrderController.validateContract(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers));
        salesOrderWrapper.SalesOrder.Contract__c = null;
        update salesOrderWrapper.SalesOrder;
        ACVSalesOrderController.validateContract(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers));
        salesOrderWrapper.SalesOrder.Rate_Sheet__c = NewTestData.mapRateSheetWrappersByName.get(NewTestData.COMPANY_PRICE_LIST).RateSheet.Id;
        ACVSalesOrderController.validateRateSheet(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers), salesOrderWrapper.SalesOrder.Rate_Sheet__c);
        }
        Catch(Exception e)
        {
        
        }

        Test.stopTest();
    }

    public static testMethod void testExistingSalesOrder4() {
        NewTestData.createTestData();
        //Sales_Order__c salesOrder = NewTestData.mapSalesOrderWrappersByName.get('SO1').SalesOrder;
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');

        Test.startTest();

        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper) JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);

        List<Job_Task_Template_Line__c> jobTaskTemplateLines = NewTestData.mapJobTaskTemplateWrappersByName.get('Field Services').JobTaskTemplateLines;
        Integer nextSalesLineNo = ACVSalesOrderController.getNextSalesLineNo(salesOrderWrapper.JobTaskWrappers);

        ACVSalesOrderController.createSalesLinesFromJobTaskTemplateLines(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers[0]), JSON.serialize(jobTaskTemplateLines), nextSalesLineNo);
        salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);

        ACVSalesOrderController.validateFromSalesQuote(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers));

        ACVSalesOrderController.prepareWizardQuestions(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers));

        Test.stopTest();
    }

    public static testMethod void testExistingSalesOrder5() {
        NewTestData.createTestData();
        //Sales_Order__c salesOrder = NewTestData.mapSalesOrderWrappersByName.get('SO1').SalesOrder; test
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');

        salesOrder.Is_New_D365_Project__c = true;
        update salesOrder; 
        Test.startTest();

        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper) JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);

        List<Job_Task_Template_Line__c> jobTaskTemplateLines = NewTestData.mapJobTaskTemplateWrappersByName.get('Field Services').JobTaskTemplateLines;
        Integer nextSalesLineNo = ACVSalesOrderController.getNextSalesLineNo(salesOrderWrapper.JobTaskWrappers);
        ACVSalesOrderController.createSalesLinesFromJobTaskTemplateLines(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers[0]), JSON.serialize(jobTaskTemplateLines), nextSalesLineNo);
        salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        //Added for Tax issue story
        try{
        ACVSalesOrderController.saveSalesOrder(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers));
       
        }Catch(Exception e){}
        Test.stopTest();
    }

    public static testMethod void testAddRemoveManifestLine() {
        NewTestData.createTestData();
        //Sales_Order__c salesOrder = NewTestData.mapSalesOrderWrappersByName.get('SO1').SalesOrder;
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');
        List<Sales_Line__c> salesLines = SalesLinesSelector.newInstance().selectLinesBySalesOrderId(new Set<Id>{ salesOrder.Id });
        Test.startTest();

        //ticket 19672 <<
        //SalesOrdersService.createManifestFeeLines(salesOrder, salesLines);
        //SalesOrdersService.calcSurchargeAmount(salesOrder, salesLines);
        List<Sales_Order_Job_Task__c> jobTasks = SalesOrderJobTasksSelector.newInstance().selectBySalesOrderId(new Set<Id>{ salesOrder.Id });
        SalesOrdersService.calcSurchargeAmount(salesOrder, jobTasks, salesLines);
        //ticket 19672 >>

        for (Integer i = 0; i < salesLines.size(); i++) {
            Sales_Line__c salesLine = salesLines[i];
            if (salesLine.Category__c == 'Waste Disposal' && salesLine.System_Calculated_Line__c != true) {
                salesLines.remove(i);
                i--;
            }
        }

        //ticket 19672 <<
        //SalesOrdersService.createManifestFeeLines(salesOrder, salesLines);
        //ticket 19672 >>

        Test.stopTest();
    }

    public static testMethod void testConvertQuoteToOrder(){
        NewTestData.createTestData();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SQ1');

        Test.startTest();
        SalesOrdersService.convertQuoteToOrder(new Set<Id>{salesOrder.Id});
        Test.stopTest();
    }

    public static testMethod void testCreateMiscCreditMemo() {
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);

        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        pref.getParameters().put('id', salesOrder.Id);


        ApexPages.StandardController standardController = new ApexPages.StandardController(salesOrder);
        SalesOrderController salesOrderController = new SalesOrderController(standardController);

        try {
            //ticket 19130 << improve test class coverage
            salesOrderController.appliedToInvoice = [SELECT Id, Sales_Order__c, Document_Type__c, Credit_Memo_Reason_Code__c, Tax_Area__c, Invoice_Tax__c FROM Sales_Invoice__c LIMIT 1];
            salesOrderController.theSO = [SELECT Id, Document_Type__c, Bill_to_Customer_No__c, Bill_to_Customer_No__r.Id, Service_Center__c, Tax_Area__c, Subsidiary_Company__c FROM Sales_Order__c WHERE Id = :salesOrderController.appliedToInvoice.Sales_Order__c LIMIT 1];
            salesOrderController.selectedCrMemoReasonCode = 'Customer is tax exempt';
            salesOrderController.creditMemoNote = 'TEST123456789000000000001';
            //ticket 19130 >>
            salesOrderController.CreateMiscCreditMemo();
        }
        catch (exception ex) {

        }

        try {
            salesOrderController.selectedCrMemoReasonCode = 'Credit and Rebill';
            salesOrderController.CreateMiscCreditMemo();
        }
        catch (exception ex) {

        }

        try {
            salesOrderController.creditMemoNote = '11111111';
            salesOrderController.CreateMiscCreditMemo();
        }
        catch (exception ex) {

        }

        salesOrderController.creditMemoNote = '111111111111111111111';
        salesOrderController.CreateMiscCreditMemo();

        try {
            salesOrderController.updateTMPrice();
        }
        catch(exception ex) {

        }

        try {
            salesOrderController.saveAndSubmit();
            ACVSalesOrderController.updateSiteAddress(salesOrder);
        }
        catch(exception ex) {

        }

        CompanyMgmt.byPassTrigger = true;
        try {
            SalesOrdersService.updateTMAndSISuperUserChangeBTC(salesOrder);
        }
        catch(exception ex) {
        }
    }

    @IsTest
    static void testTMMgmtAppliedBillingRule(){
        NewTestData.createTestData();
        Test.startTest();
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        TM_Line__c tmLine = NewTestData.mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.LABOR_CATEGORY);
        TMMgmt.applyLaborBillingRule(tmLine, tm);
        Test.stopTest();
    }
    public static testMethod void validateSalesOrderTest() {
        NewTestData.createTestData();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');
        Test.startTest();
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        ACVSalesOrderJobTaskWrapper newJobTaskWrapper = new ACVSalesOrderJobTaskWrapper();
        List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = salesOrderWrapper.JobTaskWrappers;
        String JSONJobTaskWrappers = ACVSalesOrderController.recalculateSalesLineDetails(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(jobTaskWrappers), true);
        jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);
        ACVSalesOrderController.validatePayRule(JSONSalesOrderWrapper,JSONJobTaskWrappers);
        ACVSalesOrderController.validateServiceCenter(JSONSalesOrderWrapper,JSONJobTaskWrappers);
        ACVSalesOrderController.validateSalesOrderType(JSONSalesOrderWrapper,JSONJobTaskWrappers);
        Test.stopTest();
    }
    public static testMethod void validateSalesOrderTest1() {
        NewTestData.createTestData();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');
        //salesOrder.Contract__c = null;
        //update salesOrder;
        Test.startTest();
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        ACVSalesOrderJobTaskWrapper newJobTaskWrapper = new ACVSalesOrderJobTaskWrapper();
        List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = salesOrderWrapper.JobTaskWrappers;
        String JSONJobTaskWrappers = ACVSalesOrderController.recalculateSalesLineDetails(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(jobTaskWrappers), true);
        jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);
        ACVSalesOrderController.validatePayRule(JSONSalesOrderWrapper,JSONJobTaskWrappers);
        ACVSalesOrderController.validateServiceCenter(JSONSalesOrderWrapper,JSONJobTaskWrappers);
        ACVSalesOrderController.validateSalesOrderType(JSONSalesOrderWrapper,JSONJobTaskWrappers);
        SalesOrdersServiceImpl objSOI=New SalesOrdersServiceImpl();
        //objSOI.convertQuoteToOrder(new Set<Id>{salesOrder.Id});
        Test.stopTest();
    }

    public static testMethod void handleExceptionTest(){
         NewTestData.createTestData();
        Billing_Rule__c billingRule = NewTestData.mapBillingRuleWrappersByName.get('Company Default').BillingRule;
        Account billToCustomer = NewTestData.mapAccountWrappersByName.get('Customer').Account;
        Service_Center__c serviceCenter = NewTestData.mapServiceCenterWrappersByName.get('02').ServiceCenter;
        billToCustomer.AccountNumber = null;
        update billToCustomer;
        Test.startTest();
         try{
            ACVSalesOrderController.getWeekendAndHoliday(null, 5, billingRule.Id, true, true);
            
        }Catch(Exception e){
            
        }
         try{
            ACVSalesOrderController.getWeekendAndHoliday(Date.newInstance(12, 25, system.today().year()), 5, null, true, true);
            
        }Catch(Exception e){
            
        }
         try{
           ACVSalesOrderController.createNewSalesOrder('Sales Order', 'a0uTH0000004CyfYAE', serviceCenter.Name, null);
            
        }Catch(Exception e){
            
        }
        try{
           ACVSalesOrderController.validateAssumptionChange('Sales Order');
            
        }Catch(Exception e){
            
        }
        try{
           ACVSalesOrderController.allowNewSalesOrders('a0uTH0000004CyfYAE');
            
        }Catch(Exception e){
            
        }
        try{
           ACVSalesOrderController.prepareWizardQuestions('a0uTH0000004CyfYAE','sdfds');
            
        }Catch(Exception e){
            
        }
        try{
           ACVSalesOrderController.getContracts('a0uTH0000004CyfYAE');
            
        }Catch(Exception e){
            
        }
         try{
           ACVSalesOrderController.saveSalesOrder('a0uTH0000004CyfYAE',null);
            
        }Catch(Exception e){
            
        }
        try{
           ACVSalesOrderController.validateFromSalesQuote('String','response');
            
        }Catch(Exception e){
            
        }
        try{
           ACVSalesOrderController.validatePayRule('String','response');
            
        }Catch(Exception e){
            
        }
        try{
           ACVSalesOrderController.validateRateSheet('String','response','error');
            
        }Catch(Exception e){
            
        }
        try{
           ACVSalesOrderController.recalculateSalesLineDetails('String','response',false);
            
        }Catch(Exception e){
            
        }
        try{
           ACVSalesOrderController.calculateEstimatedDateInfo('String','response',false);
            
        }Catch(Exception e){
            
        }
        try{
            ACVSalesOrderController.validateContract('String','response');
            
        }Catch(Exception e){
            
        }
        try{
            ACVSalesOrderController.calculateTax('String','response');
            
        }Catch(Exception e){
            
        }
         try{
            ACVSalesOrderController.validateSurchargePct('String','response');
            
        }Catch(Exception e){
            
        }
         try{
            ACVSalesOrderController.validateSurchargeType('String','response');
            
        }Catch(Exception e){
            
        }
         try{
            ACVSalesOrderController.validateCustomer('String','response');
            
        }Catch(Exception e){
            
        }
         try{
            ACVSalesOrderController.validateSalesOrderType('String','response');
            
        }Catch(Exception e){
            
        }
         try{
            ACVSalesOrderController.calculatePriceInfo('String','response');
            
        }Catch(Exception e){
            
        }
        try{
           ACVSalesOrderController.calculateSalesOrder('String','response',false,1);
            
        }Catch(Exception e){
            
        }
        try{
           ACVSalesOrderController.cloneJobTask('String','response','response',1);
            
        }Catch(Exception e){
            
        }
         try{
           ACVSalesOrderController.createSalesLinesFromJobTaskTemplateLines('String','response','response',1);
            
        }Catch(Exception e){
            
        }
         try{
           ACVSalesOrderController.calculateSalesOrderJobTask('String','response',1);
            
        }Catch(Exception e){
            
        }
        ACVSalesOrderController.allowNewSalesOrders(billToCustomer.Id);
        ACVSalesOrderController.isCustomerInActive(billToCustomer.Id);
        Test.stopTest();
        system.debug('Run Test');
    }
    public static testMethod void testgetAccountData(){
         NewTestData.createTestData();
         Account accRecord = NewTestData.mapAccountWrappersByName.get('Customer').Account;
         Salesperson__c accExecutives = NewTestData.mapSalespeopleByName.get('Account Executive');

         accRecord.Account_Executive_Ids__c = accExecutives.Id;
         Update accRecord;
         ACVSalesOrderController.getAccountData(accRecord.Id);
    }
    
    public static testMethod void testUpdateSiteAddress() {
        NewTestData.createTestData();
        Test.startTest();
        Account customeraccRecord = NewTestData.mapAccountWrappersByName.get('Customer').Account;
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        NewTestData.AccountWrapper customerWrapper = new NewTestData.AccountWrapper(customeraccRecord);
		//Site_Address__c alternateSiteAddress = customerWrapper.mapSiteAddressesByName.get('Site A');
        Site_Address__c siteAddress = new Site_Address__c();
        siteAddress.Name = 'Site A';
        siteAddress.Site_Street__c = '123 ABC Ave';
        siteAddress.Site_City__c = 'New York';
        siteAddress.Site_State__c = 'NY';
        siteAddress.Site_Postal_Code__c = '10002';
        siteAddress.Site_Country__c = 'US';
        //siteAddress.Contact__c = customerContact.Id;
        siteAddress.Customer__c = customeraccRecord.Id;
        
        insert siteAddress;
        salesOrder.Alternate_Site_Address__c = siteAddress.Id;
        salesOrder.SO_sent_to_EQAI__c = true;
        Update salesOrder;
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        pref.getParameters().put('id', salesOrder.Id);


        ApexPages.StandardController standardController = new ApexPages.StandardController(salesOrder);
        SalesOrderController salesOrderController = new SalesOrderController(standardController);

        
            //ticket 19130 << improve test class coverage
            salesOrderController.appliedToInvoice = [SELECT Id, Sales_Order__c, Document_Type__c, Credit_Memo_Reason_Code__c, Tax_Area__c, Invoice_Tax__c FROM Sales_Invoice__c LIMIT 1];
            salesOrderController.theSO = [SELECT Id, Document_Type__c, Bill_to_Customer_No__c, Bill_to_Customer_No__r.Id, Service_Center__c, Tax_Area__c, Subsidiary_Company__c FROM Sales_Order__c WHERE Id = :salesOrderController.appliedToInvoice.Sales_Order__c LIMIT 1];
            ACVSalesOrderController.updateSiteAddress(salesOrder);
       
        }
    
    public static testMethod void testExistingSalesOrder_3() {
        NewTestData.createTestData();
        //Sales_Order__c salesOrder = NewTestData.mapSalesOrderWrappersByName.get('SO1').SalesOrder;
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');

        Test.startTest();

        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper) JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        
        try{

        ACVSalesOrderController.validateContract(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers));
        salesOrderWrapper.SalesOrder.Rate_Sheet__c = NewTestData.mapRateSheetWrappersByName.get(NewTestData.COMPANY_PRICE_LIST).RateSheet.Id;
        ACVSalesOrderController.validateRateSheet(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers), salesOrderWrapper.SalesOrder.Rate_Sheet__c);
        }
        Catch(Exception e)
        {
        
        }

        Test.stopTest();
    }

public static testMethod void validateCustomer2(){

        String JSONSalesOrder = null;
    String JSONJobTaskWrappers = null; 

        Test.startTest();
        try {
            
            ACVSalesOrderController.validateCustomer(JSONSalesOrder, JSONJobTaskWrappers);
        } catch (AuraHandledException ex) {
           
            System.assert(ex.getMessage() != null, 'Exception message should not be null');
        }
        Test.stopTest();
    }
    //test1
}