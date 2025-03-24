@IsTest
private class TMsServiceTest {
    
    @IsTest
    private static void testCreateSalesInvoice(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
        ISalesOrders domainSalesOrderMock = new Mocks.SalesOrders(mocks);
        ITMs domainTMMock = new Mocks.TMs(mocks);
        ITMLines domainTMLMock = new Mocks.TMLines(mocks);
        ISalesOrdersSelector selectorSalesOrderMock = new Mocks.SalesOrdersSelector(mocks);
        ITMsSelector selectorTMMock = new Mocks.TMsSelector(mocks);
        ITMLinesSelector selectorTMLMock = new Mocks.TMLinesSelector(mocks);
        
        // Given
        mocks.startStubbing();
        Contract theContract = new Contract(
            Id = fflib_IDGenerator.generate(Contract.SObjectType)
        );        
        Sales_Order__c theSO = new Sales_Order__c(
            Id = fflib_IDGenerator.generate(Sales_Order__c.SObjectType),
            Surcharge_Type__c = 'Energy and Environmental Compliance Fee',
            Contract__c = theContract.Id
        );
        
        TM__c theTM = new TM__c(
            Id = fflib_IDGenerator.generate(TM__c.SObjectType),
            Sales_Order__c = theSO.Id
        );
        
        TM_Line__c theTML = new TM_Line__c(
            Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
            TM__c = theTM.Id,
            Quantity__c = 1,
            Unit_Price__c = 6.8,
            Line_Amount__c = 6.8
        );
        TM_Line__c theTML2 = new TM_Line__c(
            Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
            TM__c = theTM.Id,
            Quantity__c = 3,
            Hour__c = 3,
            Unit_Price__c = 3.8,
            Category__c = 'Labor',
            Regular_Rate__c = 1,
            Regular_Hours__c = 1,
            Overtime_Rate__c = 1,
            Overtime_Hours__c = 1,
            Premium_Rate__c = 1,
            Premium_Hours__c = 1
        );
        Resource__c r = new Resource__c(
            Id = fflib_IDGenerator.generate(Resource__c.SObjectType)
        );
        Company_Setup__c theCompanySetup = new Company_Setup__c(
            Id = fflib_IDGenerator.generate(Company_Setup__c.SObjectType),
            Review_Invoice_Async_No_of_Records__c = 1000
            //Default_Energy_Insurance_Resource__c = r.Id
        );
        
        mocks.when(domainSalesOrderMock.sObjectType()).thenReturn(Sales_Order__c.SObjectType);
        mocks.when(domainTMMock.sObjectType()).thenReturn(TM__c.SObjectType);
        mocks.when(domainTMLMock.sObjectType()).thenReturn(TM_Line__c.SObjectType);
        mocks.when(selectorSalesOrderMock.selectCreateInvoiceRequiredFieldsById(new Set<Id>{theSO.Id})).thenReturn(new List<Sales_Order__c>{theSO});
        mocks.when(selectorTMMock.selectCreateInvoiceRequiredFieldsById(new Set<Id>{theTM.Id})).thenReturn(new List<TM__c>{theTM});
        mocks.when(selectorTMLMock.selectCreateInvoiceRequiredFieldsById(new Set<Id>{theTML.Id, theTML2.Id})).thenReturn(new List<TM_Line__c>{theTML, theTML2});
        mocks.when(domainTMLMock.getRecords()).thenReturn(new List<TM_Line__c>{theTML,theTML2});
        mocks.when(domainSalesOrderMock.getRecords()).thenReturn(new List<Sales_Order__c>{theSO});
        mocks.when(domainTMMock.getRecords()).thenReturn(new List<TM__c>{theTM});
        TMsServiceImpl.theCompanySetupValue = theCompanySetup;
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(uowMock);
        Application.Domain.setMock(domainSalesOrderMock);
        Application.Domain.setMock(domainTMMock);
        Application.Domain.setMock(domainTMLMock);
        Application.Selector.setMock(selectorSalesOrderMock);
        Application.Selector.setMock(selectorTMMock);
        Application.Selector.setMock(selectorTMLMock);
        
        // When
        String str = TMsService.createSalesInvoice(theSO.Id, new Set<Id>{theTM.Id}, new Set<Id>{theTML.Id, theTML2.Id}, null);
        List<Sales_Order__c> lstSalesOrder= new List<Sales_Order__c>();
        lstSalesOrder.add(theSO);
        List<TM__c> lstTM= new List<TM__c>();
        lstTM.add(theTM);
        Date currentDate = System.today();
        String dateString = String.valueOf(currentDate);
        TMsService.updateTMDataWhenSalesOrderIsUpdated(lstSalesOrder);
        // Then
    }
    
    @IsTest
    private static void testCreateSalesInvoiceAsync(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
        ISalesOrders domainSalesOrderMock = new Mocks.SalesOrders(mocks);
        ISalesInvoices domainSalesInvoiceMock = new Mocks.SalesInvoices(mocks);
        ITMs domainTMMock = new Mocks.TMs(mocks);
        ITMLines domainTMLMock = new Mocks.TMLines(mocks);
        ISalesOrdersSelector selectorSalesOrderMock = new Mocks.SalesOrdersSelector(mocks);
        ITMsSelector selectorTMMock = new Mocks.TMsSelector(mocks);
        ITMLinesSelector selectorTMLMock = new Mocks.TMLinesSelector(mocks);
        ISalesInvoicesSelector selectorSalesInvoiceMock = new Mocks.SalesInvoicesSelector(mocks);
        
        // Given
        mocks.startStubbing();
        Sales_Order__c theSO = new Sales_Order__c(
            Id = fflib_IDGenerator.generate(Sales_Order__c.SObjectType),
            Surcharge_Type__c = 'Energy and Environmental Compliance Fee'
            
        );
        TM__c theTM = new TM__c(
            Id = fflib_IDGenerator.generate(TM__c.SObjectType)
        );
        
        TM_Line__c theTML = new TM_Line__c(
            Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
            TM__c = theTM.Id,
            Quantity__c = 1,
            Unit_Price__c = 6.8,
            Line_Amount__c = 6.8
        );
        TM_Line__c theTML2 = new TM_Line__c(
            Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
            TM__c = theTM.Id,
            Quantity__c = 3,
            Hour__c = 3,
            Unit_Price__c = 3.8,
            Category__c = 'Labor',
            Regular_Rate__c = 1,
            Regular_Hours__c = 1,
            Overtime_Rate__c = 1,
            Overtime_Hours__c = 1,
            Premium_Rate__c = 1,
            Premium_Hours__c = 1
        );
        
        TM_Line__c theTML3 = new TM_Line__c(
            Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
            TM__c = theTM.Id,
            Quantity__c = 3,
            Hour__c = 3,
            Unit_Price__c = 3.8,
            Category__c = 'Labor',
            Regular_Rate__c = 1,
            Regular_Hours__c = 1,
            Overtime_Rate__c = 1,
            Overtime_Hours__c = 1,
            Premium_Rate__c = 1,
            Premium_Hours__c = 1
        );
        Resource__c r = new Resource__c(
            Id = fflib_IDGenerator.generate(Resource__c.SObjectType)
        );
        Company_Setup__c theCompanySetup = new Company_Setup__c(
            Id = fflib_IDGenerator.generate(Company_Setup__c.SObjectType),
            Review_Invoice_Async_No_of_Records__c = 2
            //Default_Energy_Insurance_Resource__c = r.Id
        );
        Sales_Invoice__c theSI = new Sales_Invoice__c(
            Id = fflib_IDGenerator.generate(Sales_Invoice__c.SObjectType)
        );
        mocks.when(domainSalesOrderMock.sObjectType()).thenReturn(Sales_Order__c.SObjectType);
        mocks.when(domainTMMock.sObjectType()).thenReturn(TM__c.SObjectType);
        mocks.when(domainTMLMock.sObjectType()).thenReturn(TM_Line__c.SObjectType);
        mocks.when(domainSalesInvoiceMock.sObjectType()).thenReturn(Sales_Invoice__c.SObjectType);
        
        mocks.when(selectorSalesOrderMock.selectCreateInvoiceRequiredFieldsById(new Set<Id>{theSO.Id})).thenReturn(new List<Sales_Order__c>{theSO});
        mocks.when(selectorTMMock.selectCreateInvoiceRequiredFieldsById(new Set<Id>{theTM.Id})).thenReturn(new List<TM__c>{theTM});
        mocks.when(selectorTMLMock.selectCreateInvoiceRequiredFieldsById(new Set<Id>{theTML.Id, theTML2.Id, theTML3.Id})).thenReturn(new List<TM_Line__c>{theTML, theTML2, theTML3});
        mocks.when(selectorSalesInvoiceMock.selectByIdWithSILines(new Set<Id>{theSI.Id})).thenReturn(new List<Sales_Invoice__c>{theSI});
        
        mocks.when(domainTMLMock.getRecords()).thenReturn(new List<TM_Line__c>{theTML,theTML2, theTML3});
        mocks.when(domainSalesOrderMock.getRecords()).thenReturn(new List<Sales_Order__c>{theSO});
        mocks.when(domainTMMock.getRecords()).thenReturn(new List<TM__c>{theTM});
        mocks.when(domainSalesInvoiceMock.getRecords()).thenReturn(new List<Sales_Invoice__c>{theSI});
        
        TMsServiceImpl.theCompanySetupValue = theCompanySetup;
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(uowMock);
        Application.Domain.setMock(domainSalesOrderMock);
        Application.Domain.setMock(domainTMMock);
        Application.Domain.setMock(domainTMLMock);
        Application.Selector.setMock(selectorSalesOrderMock);
        Application.Selector.setMock(selectorTMMock);
        Application.Selector.setMock(selectorTMLMock);
        
        // When
        String str = TMsService.createSalesInvoice(theSO.Id, new Set<Id>{theTM.Id}, new Set<Id>{theTML.Id, theTML2.Id, theTML3.Id}, null);
        TMsService.addSurchargeLineToSalesInvoiceAsync(theSI.Id);
    }
    
    @IsTest
    private static void testRinseOutFee(){
        Company_Setup__c defaultCompanySetup = TestDataUtil.CompanySetupRecord;
        Resource__c resource = TestDataUtil.ResourceRecord;
        ResourceUOMAssociation__c resourceUOMAssociation = TestDataUtil.resourceUOMAssociationRec;
        List<TM_Line__c> tmLines = new List<TM_Line__c>();
        tmLines.add(TestDataUtil.TMLineEquipmentRecord);
        Test.startTest();
        TMsService.calcRinseOutFeeLine(TestDataUtil.TMRecord, tmLines);
        TM__c TMRecord = [SELECT Id,Billing_Instructions__c,Site_Scope__c,Internal_Comments__c, Sales_Order__r.Billing_Rule_Not_Required__c, Sales_Order__r.Manifest_And_Profile__c,Tax_Liable__c,Tax_Area__c,Sales_Order__r.Charge_Rinse_Out_Fee__c FROM TM__c LIMIT 1];
        TMsService.calcRinseOutFeeLine(TMRecord, tmLines);
        Test.stopTest();
    }
    
    @IsTest
    private static void testCreateWorksheet(){
        NewTestData.createTestData();
        Test.startTest();
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        TMsService.createBillingWorksheetLines(new Set<TM__c>{tm});
        TMsService.cloneAndSchedule(new List<TM__c>{tm},String.valueOf(System.today()));
        Test.stopTest();
    }
    @IsTest
    static void testupdateExistingBillingWorksheetLines(){
        NewTestData.createTestData();
        Test.startTest();
        /*Unit_of_Measure__c hourUnitOfMeasure = new Unit_of_Measure__c();
        hourUnitOfMeasure.Name = 'HR51';
        hourUnitOfMeasure.Hours_UOM__c = true;
        insert hourUnitOfMeasure;
        Resource_Type__c laborResourceType = new Resource_Type__c();
        laborResourceType.Category__c = 'Labor';
        laborResourceType.Name = 'Labor';
        laborResourceType.Inter_co_Cost__c = 39;
        laborResourceType.Unit_Cost__c = 39;
        laborResourceType.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        insert laborResourceType; */
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        String billingWorksheetJSON = BillingWorksheetController.getWorksheet(salesOrder.Id, salesOrderJobTask.Id, false);
        BillingWorksheetWrapper billingWorksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(billingWorksheetJSON, BillingWorksheetWrapper.class);
        List<Billing_Worksheet_Line__c> billingWorksheetLines = billingWorksheetWrapper.WorksheetLines;
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        TM_Line__c tmLine = NewTestData.mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.WASTE_DISPOSAL_CATEGORY);
        tmLine.Billing_Worksheet_Line__c = billingWorksheetLines[0].Id;
        //tmLine.Resource_Type__c =laborResourceType.Id;
        update tmLine;
        Map<Id, TM_Line__c> tmLinesByIds=new Map<Id, TM_Line__c>();
        tmLinesByIds.put(tmLine.Id,tmLine);
        //TMsService.updateExistingBillingWorksheetLines(tmLinesByIds);
        TMsService.deleteBillingWorksheetLines(new Set<TM__c>{tm});
        List<ACVSalesOrderJobTaskWrapper> ACVSalesOrderJobTaskWrapper=new List<ACVSalesOrderJobTaskWrapper>();
        Account obj=New Account();
        obj.Id = salesOrder.Bill_to_Customer_No__r.Id;
        obj.Sage_Customer_No__c = '12345';
        update obj;
        TMsService.createTMFromSalesOrder(salesOrder.Id,ACVSalesOrderJobTaskWrapper);
        TMsServiceImpl objTms=New TMsServiceImpl();
        objTms.createTMJobTaskFromSalesOrderJobTask(tm,salesOrderJobTask,5);
        Test.stopTest();
    }

    //test
}