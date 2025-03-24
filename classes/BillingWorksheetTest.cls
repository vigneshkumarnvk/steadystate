@IsTest
private class BillingWorksheetTest {
    @IsTest
    static void testWorksheetController() {
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        BillingWorksheetController.getSetupData(salesOrder.Id);
        BillingWorksheetController.getSalesOrder(salesOrder.Id);
        BillingWorksheetController.getUnbilledTasks(salesOrder.Id);
        BillingWorksheetController.getBundleLines(salesOrderJobTask.Id);
        String billingWorksheetJSON = BillingWorksheetController.getWorksheet(salesOrder.Id, salesOrderJobTask.Id, false);
        /**
        BillingWorksheetWrapper billingWorksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(billingWorksheetJSON, BillingWorksheetWrapper.class);
        List<BillingWorksheetWrapper> billingWorksheetWrappers = new List<BillingWorksheetWrapper>();
        billingWorksheetWrappers.add(billingWorksheetWrapper);
         85225 commits commented*/
        BillingWorksheetController.calculateManifestFeeLines(salesOrder.Id, billingWorksheetJSON);
        Test.stopTest();
	
    }
	

    @IsTest
    static void testValidation(){
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        String billingWorksheetJSON = BillingWorksheetController.getWorksheet(salesOrder.Id, salesOrderJobTask.Id, false);
        BillingWorksheetWrapper billingWorksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(billingWorksheetJSON, BillingWorksheetWrapper.class);
        List<Billing_Worksheet_Line__c> billingWorksheetLines = billingWorksheetWrapper.WorksheetLines;
        BillingWorksheetService.initStaticVariables(salesOrder.Id, billingWorksheetWrapper);
        Billing_Worksheet_Line__c laborLine = new Billing_Worksheet_Line__c();
        Billing_Worksheet_Line__c wasteLine = new Billing_Worksheet_Line__c();
        Billing_Worksheet_Line__c materialLine = new Billing_Worksheet_Line__c();
        for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetLines){
            if(billingWorksheetLine.Category__c == ResourceService.LABOR_CATEGORY){
                if(laborLine.Id == null){
                    laborLine = billingWorksheetLine;
                }
            }
            if(billingWorksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY){
                if(wasteLine.Id == null){
                    wasteLine = billingWorksheetLine;
                }
            }
            if(billingWorksheetLine.Category__c == ResourceService.MATERIALS_CATEGORY){
                if(materialLine.Id == null){
                    materialLine = billingWorksheetLine;
                }
            }
        }
        BillingWorksheetService.validateResource(salesOrder.Id, wasteLine);
        BillingWorksheetService.validateResource(salesOrder.Id, materialLine);
        BillingWorksheetService.validateResourceType(salesOrder.Id, laborLine);
        BillingWorksheetService.calculateLaborHours(salesOrder.Id, laborLine);
	BillingWorksheetService.validateContractLine(salesOrder.Id, laborLine);
        List<Billing_Worksheet_Line__c> billingWorksheetLines2 = BillingWorksheetLinesSelector.newInstance().selectById(new Set<Id>{laborLine.Id});
        billingWorksheetLines2 = BillingWorksheetLinesSelector.newInstance().selectOpenLinesByTMIds(new Set<Id>{laborLine.TM__c});
        Test.stopTest();
    }

    private static testMethod void testValidateResourceType() {
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        String billingWorksheetJSON = BillingWorksheetController.getWorksheet(salesOrder.Id, salesOrderJobTask.Id, false);
        BillingWorksheetWrapper billingWorksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(billingWorksheetJSON, BillingWorksheetWrapper.class);
        List<Billing_Worksheet_Line__c> billingWorksheetLines = billingWorksheetWrapper.WorksheetLines;
        Billing_Worksheet_Line__c laborLine = new Billing_Worksheet_Line__c();
        for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetLines){
            if(billingWorksheetLine.Category__c == ResourceService.LABOR_CATEGORY){
                if(laborLine.Id == null){
                    laborLine = billingWorksheetLine;
                    break;
                }
            }
        }

        BillingWorksheetController.validateResourceType(salesOrder.Id, JSON.serialize(laborLine));
        //ticket 19130 <<
        //BillingWorksheetController.calculatePresumptiveChildLines(salesOrder.Id, JSON.serialize(laborLine), 1000);
        //ticket 19130 >>
        Test.stopTest();
    }


    private static testMethod void testValidateResource() {
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        String billingWorksheetJSON = BillingWorksheetController.getWorksheet(salesOrder.Id, salesOrderJobTask.Id, false);
        BillingWorksheetWrapper billingWorksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(billingWorksheetJSON, BillingWorksheetWrapper.class);
        List<Billing_Worksheet_Line__c> billingWorksheetLines = billingWorksheetWrapper.WorksheetLines;
        Billing_Worksheet_Line__c materialLine = new Billing_Worksheet_Line__c();
        for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetLines){
            if(billingWorksheetLine.Category__c == ResourceService.MATERIALS_CATEGORY){
                if(materialLine.Id == null){
                    materialLine = billingWorksheetLine;
                    break;
                }
            }
        }

        BillingWorksheetController.validateResource(salesOrder.Id, JSON.serialize(materialLine));
        Test.stopTest();
    }


    private static testMethod void testCalculateLaborHours() {
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        String billingWorksheetJSON = BillingWorksheetController.getWorksheet(salesOrder.Id, salesOrderJobTask.Id, false);
        BillingWorksheetWrapper billingWorksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(billingWorksheetJSON, BillingWorksheetWrapper.class);
        List<Billing_Worksheet_Line__c> billingWorksheetLines = billingWorksheetWrapper.WorksheetLines;
        Billing_Worksheet_Line__c laborLine = new Billing_Worksheet_Line__c();
        for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetLines){
            if(billingWorksheetLine.Category__c == ResourceService.LABOR_CATEGORY){
                if(laborLine.Id == null){
                    laborLine = billingWorksheetLine;
                    BillingWorksheetController.calculateLaborHours(salesOrder.Id, JSON.serialize(billingWorksheetLine));
                    BillingWorksheetController.calculateLineTotals(JSON.serialize(billingWorksheetLine));
                    break;
                }
            }
        }
        Test.stopTest();
    }

    @IsTest
    static void testBillingWorksheetServiceCalcPrinceAndCost(){
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        String billingWorksheetJSON = BillingWorksheetController.getWorksheet(salesOrder.Id, salesOrderJobTask.Id, false);
        BillingWorksheetWrapper billingWorksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(billingWorksheetJSON, BillingWorksheetWrapper.class);
        List<Billing_Worksheet_Line__c> billingWorksheetLines = billingWorksheetWrapper.WorksheetLines;
        BillingWorksheetService.initStaticVariables(salesOrder.Id, billingWorksheetWrapper);
        for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetLines){
            //String worksheetLineJSON = JSON.serialize(billingWorksheetLine);
            BillingWorksheetService.calculatePriceAndCost(salesOrder.Id, billingWorksheetLine);
            /*
            if(billingWorksheetLine.Category__c == ResourceService.LABOR_CATEGORY || billingWorksheetLine.Category__c == ResourceService.EQUIPMENT_CATEGORY){
                BillingWorksheetController.validateResourceType(salesOrder.Id, worksheetLineJSON);
                if(billingWorksheetLine.Category__c == ResourceService.LABOR_CATEGORY){
                    BillingWorksheetController.calculateLaborHours(salesOrder.Id, worksheetLineJSON);
                }
            }

            if(billingWorksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY){
                BillingWorksheetController.validateResource(salesOrder.Id, worksheetLineJSON);
            } */

            //BillingWorksheetController.calculateLineTotals(worksheetLineJSON);
        }
        Test.stopTest();
    }

    @IsTest
    static void testWorksheetControllerCalculatePriceAndCost(){
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        String billingWorksheetJSON = BillingWorksheetController.getWorksheet(salesOrder.Id, salesOrderJobTask.Id, false);
        BillingWorksheetWrapper billingWorksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(billingWorksheetJSON, BillingWorksheetWrapper.class);
        List<Billing_Worksheet_Line__c> billingWorksheetLines = billingWorksheetWrapper.WorksheetLines;
        for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetLines){
            String worksheetLineJSON = JSON.serialize(billingWorksheetLine);
            BillingWorksheetController.calculatePriceAndCost(salesOrder.Id, worksheetLineJSON);
        }
        Test.stopTest();
    }

    @IsTest
    static void testWorksheetControllerCalculatePriceInfo(){
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        String billingWorksheetJSON = BillingWorksheetController.getWorksheet(salesOrder.Id, salesOrderJobTask.Id, false);
        BillingWorksheetWrapper billingWorksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(billingWorksheetJSON, BillingWorksheetWrapper.class);
        List<BillingWorksheetWrapper> billingWorksheetWrappers = new List<BillingWorksheetWrapper>();

        List<TM__c> tms = [SELECT Id, Status__c FROM TM__c];
        for(TM__c tm : tms){
            tm.Status__c = TMsService.CONFIRMED_STATUS;
        }
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        update tms;
        CompanyMgmt.byPassTrigger = false;
        CompanyMgmt.byPassLineTrigger = false;
        //bundle line
        for (Integer i = 0; i < billingWorksheetWrapper.WorksheetLines.size(); i++) {
            Billing_Worksheet_Line__c worksheetLine = billingWorksheetWrapper.WorksheetLines[i];
            if (i == 1) {
                Billing_Worksheet_Line__c bundleLine = billingWorksheetWrapper.WorksheetLines[0];
                worksheetLine.Bundle_Line__c = bundleLine.Id;
                worksheetLine.Bundle_Line__r = new Billing_Worksheet_Line__c(Id = bundleLine.Id, Line_No__c = bundleLine.Line_No__c);
                worksheetLine.Bill_as_Lump_Sum__c = true;
                worksheetLine.Parent_Line__c = bundleLine.Id; //use bundle line for parent line also
                worksheetLine.Parent_Line__r = new Billing_Worksheet_Line__c(Id = bundleLine.Id, Line_No__c = bundleLine.Line_No__c);
                worksheetLine.xUnit_Price__c = worksheetLine.Unit_Price__c;
                worksheetLine.xUnit_Cost__c = worksheetLine.Unit_Cost__c;
                worksheetLine.xLine_Amount__c = worksheetLine.Line_Amount__c;
                worksheetLine.xLine_Cost__c = worksheetLine.Line_Cost__c;
                Unit_of_Measure__c unitOfMeasure = NewTestData.mapUnitOfMeasuresByName.get('HR');
                worksheetLine.Unit_of_Measure__c = unitOfMeasure.Id;
                worksheetLine.Unit_of_Measure__r = unitOfMeasure;
                break;
            }
        }
        BillingWorksheetService.rollupBundledLines(billingWorksheetWrapper.WorksheetLines);

        billingWorksheetWrappers.add(billingWorksheetWrapper);
        String billingWorksheetsJSON = JSON.serialize(billingWorksheetWrappers);
        BillingWorksheetController.calculatePriceInfo(salesOrder.Id, billingWorksheetsJSON);
        BillingWorksheetController.saveWorksheets(salesOrder.Id, billingWorksheetsJSON);
        Test.stopTest();
    }

    @IsTest
    static void testWorksheetControllerValidateTaxGroup(){
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        String billingWorksheetJSON = BillingWorksheetController.getWorksheet(salesOrder.Id, salesOrderJobTask.Id, false);
        BillingWorksheetWrapper billingWorksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(billingWorksheetJSON, BillingWorksheetWrapper.class);
        List<Billing_Worksheet_Line__c> billingWorksheetLines = billingWorksheetWrapper.WorksheetLines;
        for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetLines){
            String worksheetLineJSON = JSON.serialize(billingWorksheetLine);
            BillingWorksheetController.validateTaxGroup(salesOrder.Id, worksheetLineJSON);
        }
        Test.stopTest();
    }

    private static testMethod void testCalcUnitPrice() {
        NewTestData.createTestData();

        Resource_Type__c newResourceType = new Resource_Type__c();
        newResourceType.Name = 'New Resource Type';
        newResourceType.Category__c = 'Labor';
        newResourceType.Description__c = 'new labor';
        newResourceType.Unit_of_Measure__c = NewTestData.mapUnitOfMeasuresByName.get('EA').Id;
        insert newResourceType;

        List<Unit_of_Measure__c> unitOfMeasures = new List<Unit_of_Measure__c>();
        Unit_of_Measure__c newUnitOfMeasure = new Unit_of_Measure__c();
        newUnitOfMeasure.Name = 'HOUR';
        unitOfMeasures.add(newUnitOfMeasure);

        Unit_of_Measure__c newUnitOfMeasure2 = new Unit_of_Measure__c();
        newUnitOfMeasure2.Name = 'WEEK';
        unitOfMeasures.add(newUnitOfMeasure2);

        insert unitOfMeasures;

        List<ResourceTypeUOMAssociation__c> uomAssociations = new List<ResourceTypeUOMAssociation__c>();
        ResourceTypeUOMAssociation__c uomAssociation = new ResourceTypeUOMAssociation__c();
        uomAssociation.Resource_Type__c = newResourceType.Id;
        uomAssociation.Unit_of_Measure__c = newResourceType.Unit_of_Measure__c;
        uomAssociations.add(uomAssociation);

        uomAssociation = new ResourceTypeUOMAssociation__c();
        uomAssociation.Resource_Type__c = newResourceType.Id;
        uomAssociation.Unit_of_Measure__c = newUnitOfMeasure.Id;
        uomAssociations.add(uomAssociation);
        insert uomAssociations;

        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Id pwPayRuleId = NewTestData.mapPayRuleWrappersByName.get('Prevailing Wage').PayRule.Id;
        salesOrder.Pay_Rule__c = pwPayRuleId;
        update salesOrder;
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        String billingWorksheetJSON = BillingWorksheetController.getWorksheet(salesOrder.Id, salesOrderJobTask.Id, false);
        BillingWorksheetWrapper billingWorksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(billingWorksheetJSON, BillingWorksheetWrapper.class);
        List<BillingWorksheetWrapper> billingWorksheetWrappers = new List<BillingWorksheetWrapper>();
        billingWorksheetWrappers.add(billingWorksheetWrapper);

        Contract contract = NewTestData.mapContractWrappersByName.get('Contract').Contract;
        Contract_Line__c contractLine = new Contract_Line__c();
        contractLine.Contract__c = contract.Id;
        contractLine.Category__c = newResourceType.Category__c;
        contractLine.Resource_Type__c = newResourceType.Id;
        contractLine.Unit_of_Measure__c = newResourceType.Unit_of_Measure__c;
        insert contractLine;

        //contract pricing
        Billing_Worksheet_Line__c laborWorksheetLine = new Billing_Worksheet_Line__c();
        laborWorksheetLine.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
        laborWorksheetLine.Sales_Order__c = salesOrder.Id;
        laborWorksheetLine.Line_No__c = 100;
        laborWorksheetLine.Category__c = newResourceType.Category__c;
        laborWorksheetLine.Resource_Type__c = newResourceType.Id;
        laborWorksheetLine.Description__c = newResourceType.Description__c;
        laborWorksheetLine.Unit_of_Measure__c = newResourceType.Unit_of_Measure__c;
        laborWorksheetLine.Contract_Line__c = contractLine.Id;
        laborWorksheetLine.Quantity__c = 1;
        laborWorksheetLine.Unit_Price__c = 10;
        laborWorksheetLine.Unit_Cost__c = 10;
        laborWorksheetLine.TM__c = tm.Id;
        laborWorksheetLine.TM__r = tm;
        BillingWorksheetWrapper.WorksheetLines.add(laborWorksheetLine);
BillingWorksheetServiceImpl impl = new BillingWorksheetServiceImpl();
		impl.validateContractLine(salesOrder.Id,laborWorksheetLine);
        //sales pricing
        Sales_Line__c newSalesLine = new Sales_Line__c();
        newSalesLine.Line_No__c = 101;
        newSalesLine.Sales_Order__c = salesOrder.Id;
        newSalesLine.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
        newSalesLine.Category__c = 'Labor';
        newSalesLine.Resource_Type__c = newResourceType.Id;
        newSalesLine.Description__c = newResourceType.Description__c;
        newSalesLine.Unit_of_Measure__c = newUnitOfMeasure.Id;
        newSalesLine.Quantity__c = 1;
        newSalesLine.UOM_Qty__c = 8;
        newSalesLine.Number_of_Day__c = 1;
        newSalesLine.Unit_Price__c = 10;
        newSalesLine.Unit_Cost__c = 10;
        newSalesLine.Line_Amount__c = 100;
        newSalesLine.Line_Cost__c = 100;
        newSalesLine.Line_Amt_Incl_Tax__c = 100;
        newSalesLine.xLine_Amount__c = newSalesLine.xLine_Amount__c;
        newSalesLine.xLine_Cost__c = newSalesLine.xLine_Cost__c;

        insert newSalesLine;

        Billing_Worksheet_Line__c laborWorksheetLine2 = new Billing_Worksheet_Line__c();
        laborWorksheetLine2.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
        laborWorksheetLine2.Sales_Order__c = salesOrder.Id;
        laborWorksheetLine2.Line_No__c = 102;
        laborWorksheetLine2.Category__c = newResourceType.Category__c;
        laborWorksheetLine2.Resource_Type__c = newResourceType.Id;
        laborWorksheetLine2.Description__c = newResourceType.Description__c;
        laborWorksheetLine2.Unit_of_Measure__c = newUnitOfMeasure.Id;
        laborWorksheetLine2.TM__c = tm.Id;
        laborWorksheetLine2.TM__r = tm;
        laborWorksheetLine2.Quantity__c = 1;
        laborWorksheetLine.Unit_Price__c = 10;
        laborWorksheetLine.Unit_Cost__c = 10;
        BillingWorksheetWrapper.WorksheetLines.add(laborWorksheetLine2);

        Billing_Worksheet_Line__c laborWorksheetLine3 = new Billing_Worksheet_Line__c();
        laborWorksheetLine3.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
        laborWorksheetLine3.Sales_Order__c = salesOrder.Id;
        laborWorksheetLine3.Line_No__c = 103;
        laborWorksheetLine3.Category__c = newResourceType.Category__c;
        laborWorksheetLine3.Resource_Type__c = newResourceType.Id;
        laborWorksheetLine3.Description__c = newResourceType.Description__c;
        laborWorksheetLine3.Unit_of_Measure__c = newUnitOfMeasure2.Id;
        laborWorksheetLine3.TM__c = tm.Id;
        laborWorksheetLine3.TM__r = tm;
        laborWorksheetLine2.Quantity__c = 1;
        laborWorksheetLine.Unit_Price__c = 10;
        laborWorksheetLine.Unit_Cost__c = 10;
        BillingWorksheetWrapper.WorksheetLines.add(laborWorksheetLine3);

Billing_Worksheet_Line__c laborWorksheetLine4 = new Billing_Worksheet_Line__c();
        laborWorksheetLine4.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
        laborWorksheetLine4.Sales_Order__c = salesOrder.Id;
        laborWorksheetLine4.Line_No__c = 103;
        laborWorksheetLine4.Category__c = ResourceService.SUBCONTRACTORS_CATEGORY;
        laborWorksheetLine4.Resource_Type__c = newResourceType.Id;
        laborWorksheetLine4.Description__c = newResourceType.Description__c;
        laborWorksheetLine4.Unit_of_Measure__c = newUnitOfMeasure2.Id;
        laborWorksheetLine4.TM__c = tm.Id;
        laborWorksheetLine3.TM__r = tm;
        laborWorksheetLine2.Quantity__c = 1;
        laborWorksheetLine.Unit_Price__c = 10;
        laborWorksheetLine.Unit_Cost__c = 10;
        BillingWorksheetWrapper.WorksheetLines.add(laborWorksheetLine4);

        BillingWorksheetService.initStaticVariables(salesOrder.Id, billingWorksheetWrappers);

        //test contract pricing
        BillingWorksheetService.calculatePriceAndCost(salesOrder.Id, billingWorksheetWrappers);
        BillingWorksheetServiceImpl im = new BillingWorksheetServiceImpl();
        im.calcSubcontractorUnitCostAndPrice(laborWorksheetLine4);
      

        Test.stopTest();
    }

    @IsTest
    static void testWorksheetControllerPopulateLinesInfo(){
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        String billingWorksheetJSON = BillingWorksheetController.getWorksheet(salesOrder.Id, salesOrderJobTask.Id, false);
        BillingWorksheetWrapper billingWorksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(billingWorksheetJSON, BillingWorksheetWrapper.class);
        List<Billing_Worksheet_Line__c> billingWorksheetLines = billingWorksheetWrapper.WorksheetLines;
        String worksheetLinesJSON = JSON.serialize(billingWorksheetLines);
        BillingWorksheetController.populateLinesInfo(salesOrder.Id, worksheetLinesJSON);
        Test.stopTest();
    }

    //ticket 19130 <<
    /*
    @IsTest
    static void testWorksheetControllerPrepareWizardQuestions(){
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        String billingWorksheetJSON = BillingWorksheetController.getWorksheet(salesOrder.Id, salesOrderJobTask.Id, false);
        BillingWorksheetWrapper billingWorksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(billingWorksheetJSON, BillingWorksheetWrapper.class);
        List<BillingWorksheetWrapper> billingWorksheetWrappers = new List<BillingWorksheetWrapper>();
        billingWorksheetWrappers.add(billingWorksheetWrapper);
        String billingWorksheetsJSON = JSON.serialize(billingWorksheetWrappers);
        Integer nextLineNo = BillingWorksheetController.getNextWorksheetLineNo(salesOrder.Id);
        BillingWorksheetController.prepareWizardQuestions(salesOrder.Id, billingWorksheetsJSON, nextLineNo);
        Test.stopTest();
    }
    */
    //ticket 19130 >>

    @IsTest
    static void testWorksheetControllerCreateSalesInvoice(){
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        salesOrder.Bill_to_Customer_No__r.Sage_Customer_No__c = 'T12345';
        update salesOrder.Bill_to_Customer_No__r;
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        String billingWorksheetJSON = BillingWorksheetController.getWorksheet(salesOrder.Id, salesOrderJobTask.Id, false);
        BillingWorksheetWrapper billingWorksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(billingWorksheetJSON, BillingWorksheetWrapper.class);
        for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetWrapper.WorksheetLines){
            billingWorksheetLine.To_Invoice__c = true;
            if(billingWorksheetLine.Category__c == ResourceService.LABOR_CATEGORY){
                Unit_of_Measure__c unitOfMeasure = NewTestData.mapUnitOfMeasuresByName.get('HR');
                unitOfMeasure.Hours_UOM__c=true;
                update unitOfMeasure; 
                billingWorksheetLine.Unit_of_Measure__c = unitOfMeasure.Id;
                billingWorksheetLine.Unit_of_Measure__r = unitOfMeasure;
                billingWorksheetLine.Unit_Cost__c = 15;
                billingWorksheetLine.Unit_Price__c = 20;
                billingWorksheetLine.Regular_Rate__c = 20;
                billingWorksheetLine.Overtime_Rate__c = 30;
                billingWorksheetLine.Premium_Rate__c = 40;
                billingWorksheetLine.Regular_Hours__c = 4;
                billingWorksheetLine.Overtime_Hours__c = 2;
                billingWorksheetLine.Premium_Hours__c = 2;
                billingWorksheetLine.Hour__c = 8;
                billingWorksheetLine.Quantity__c = 8;
                billingWorksheetLine.Category__c = 'Labor';
            } else {
                billingWorksheetLine.Unit_Price__c = 30;
                billingWorksheetLine.Unit_Cost__c = 10;
                billingWorksheetLine.Quantity__c = 1;
                billingWorksheetLine.Category__c = 'Labor';
            }
            BillingWorksheetService.calculateLineTotals(billingWorksheetLine);
        }
        List<BillingWorksheetWrapper> billingWorksheetWrappers = new List<BillingWorksheetWrapper>();
        billingWorksheetWrappers.add(billingWorksheetWrapper);
        String billingWorksheetsJSON = JSON.serialize(billingWorksheetWrappers);
        try{
             Id salesInvoiceId = BillingWorksheetController.createSalesInvoice(salesOrder.Id, billingWorksheetsJSON);  
        }catch(Exception e){
            
        }
// BillingWorksheetController.sendSalesInvoiceToEQAI(salesOrder.Id);
        try{
           // BillingWorksheetController.createSalesInvoiceAsync(salesOrder.Id);
        }catch(Exception e){
            
        }
        Test.stopTest();
    }


    private static testMethod void testCreateFixedPriceInvoice() {
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        String billingWorksheetJSON = BillingWorksheetController.getWorksheet(salesOrder.Id, salesOrderJobTask.Id, false);
        BillingWorksheetWrapper billingWorksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(billingWorksheetJSON, BillingWorksheetWrapper.class);
        for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetWrapper.WorksheetLines){
            billingWorksheetLine.To_Invoice__c = true;
            if(billingWorksheetLine.Category__c == ResourceService.LABOR_CATEGORY){
                Unit_of_Measure__c unitOfMeasure = NewTestData.mapUnitOfMeasuresByName.get('HR');
                billingWorksheetLine.Unit_of_Measure__c = unitOfMeasure.Id;
                billingWorksheetLine.Unit_of_Measure__r = unitOfMeasure;
                billingWorksheetLine.Unit_Cost__c = 15;
                billingWorksheetLine.Unit_Price__c = 20;
                billingWorksheetLine.Regular_Rate__c = 20;
                billingWorksheetLine.Overtime_Rate__c = 30;
                billingWorksheetLine.Premium_Rate__c = 40;
                billingWorksheetLine.Regular_Hours__c = 4;
                billingWorksheetLine.Overtime_Hours__c = 2;
                billingWorksheetLine.Premium_Hours__c = 2;
                billingWorksheetLine.Hour__c = 8;
                billingWorksheetLine.Quantity__c = 8;
            } else {
                billingWorksheetLine.Unit_Price__c = 30;
                billingWorksheetLine.Unit_Cost__c = 10;
                billingWorksheetLine.Quantity__c = 1;
            }
            BillingWorksheetService.calculateLineTotals(billingWorksheetLine);
        }
        billingWorksheetWrapper.SalesOrderJobTask.Billing_Type__c = 'Fixed Price';
        billingWorksheetWrapper.SalesOrderJobTask.Amount_to_Bill__c = 100;
        billingWorksheetWrapper.SalesOrderJobTask.Tax_Pct__c = 1;
        billingWorksheetWrapper.SalesOrderJobTask.Tax_Group__c = 'NT';
        List<BillingWorksheetWrapper> billingWorksheetWrappers = new List<BillingWorksheetWrapper>();
        billingWorksheetWrappers.add(billingWorksheetWrapper);
        String billingWorksheetsJSON = JSON.serialize(billingWorksheetWrappers);
        //acvsetting before calling the function.
        CompanySettingUtil.acvSetting.Fixed_Price_Job_Resource__c = NewTestData.mapResourceWrappersByName.get('Fixed Price Job').Resource.Id;
        Id salesInvoiceId = BillingWorksheetController.createSalesInvoice(salesOrder.Id, billingWorksheetsJSON);
        Test.stopTest();
    }

    @IsTest
    static void testWorksheetControllerMisc(){
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        String idString = JSON.serialize(salesOrderJobTask.Id);
        try {
            BillingWorksheetController.getTMBillingPDFUrl(idString);
        } catch (Exception e){

        }
        Test.stopTest();
    }

    @IsTest
    static void testCalcWorksheetLinesPricing(){
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        try {
            BillingWorksheetService.calcWorksheetLinesPricing(salesOrder);
        } catch (Exception e){

        }
        Test.stopTest();
    }

    @IsTest
    static void testWorksheetControllerWithQueryFewerFields(){
        NewTestData.createTestData();
        Test.startTest();
Billing_Rule__c billingRule = NewTestData.mapBillingRuleWrappersByName.get('Company Default').BillingRule;
        billingRule.Enable_Weekly_Total_Calculation__c = true;
        update billingRule;
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
salesOrder.Contract__c = null;
        update salesOrder;
        
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        String billingWorksheetJSON = BillingWorksheetController.getWorksheet(salesOrder.Id, salesOrderJobTask.Id, true);
        BillingWorksheetWrapper billingWorksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(billingWorksheetJSON, BillingWorksheetWrapper.class);
        Set<Id> billingWorksheetLineIds = new Set<Id>();
        Set<Id> salesOrderJobTaskIds = new Set<Id>();
        salesOrderJobTaskIds.add(salesOrderJobTask.Id);
        Id tmId;
        for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetWrapper.WorksheetLines){
            billingWorksheetLineIds.add(billingWorksheetLine.Id);
            tmId = billingWorksheetLine.TM__c;
        }
        Map<Id, List<Billing_Worksheet_Line__c>> billingWorksheetLinesByTMIds = new Map<Id, List<Billing_Worksheet_Line__c>>();
        billingWorksheetLinesByTMIds.put(tmId, billingWorksheetWrapper.WorksheetLines);
        String worksheetLineJSON = BillingWorksheetController.getWorksheetLines(salesOrder.Id, salesOrderJobTask.Id, tmId, true);
        String JSONWorksheetLineIds = JSON.serialize(billingWorksheetLineIds);
        String JSONSalesOrderJobTaskIds = JSON.serialize(salesOrderJobTaskIds);
        for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetWrapper.WorksheetLines){
            billingWorksheetLine.To_Invoice__c = true;
            if(billingWorksheetLine.Category__c == ResourceService.LABOR_CATEGORY){
                Unit_of_Measure__c unitOfMeasure = NewTestData.mapUnitOfMeasuresByName.get('HR');
                unitOfMeasure.Hours_UOM__c=true;
                update unitOfMeasure;
                billingWorksheetLine.Unit_of_Measure__c = unitOfMeasure.Id;
                billingWorksheetLine.Unit_of_Measure__r = unitOfMeasure;
                billingWorksheetLine.Unit_Cost__c = 15;
                billingWorksheetLine.Unit_Price__c = 20;
                billingWorksheetLine.Regular_Rate__c = 20;
                billingWorksheetLine.Overtime_Rate__c = 30;
                billingWorksheetLine.Premium_Rate__c = 40;
                billingWorksheetLine.Regular_Hours__c = 4;
                billingWorksheetLine.Overtime_Hours__c = 2;
                billingWorksheetLine.Premium_Hours__c = 2;
                billingWorksheetLine.Hour__c = 8;
                billingWorksheetLine.Quantity__c = 8;
            } else {
                billingWorksheetLine.Unit_Price__c = 30;
                billingWorksheetLine.Unit_Cost__c = 10;
                billingWorksheetLine.Quantity__c = 1;
            }
            BillingWorksheetService.calculateLineTotals(billingWorksheetLine);
        }
        CompanyMgmt.byPassLineTrigger = true;
        CompanyMgmt.byPassTrigger = true;
        update billingWorksheetWrapper.WorksheetLines;
        List<BillingWorksheetWrapper> billingWorksheetWrappers = new List<BillingWorksheetWrapper>();
        billingWorksheetWrappers.add(billingWorksheetWrapper);
        String billingWorksheetsJSON = JSON.serialize(billingWorksheetWrappers);
        try{
            Id invoiceId = BillingWorksheetController.createSalesInvoiceFromWorksheetLines(salesOrder.Id, JSONSalesOrderJobTaskIds, JSONWorksheetLineIds);
        }catch(Exception e){
            
        }
        BillingWorksheetServiceImpl im = new BillingWorksheetServiceImpl();
        im.calcSubcontractorUnitCostAndPrice(billingWorksheetWrapper.WorksheetLines[0]);
         im.calculateLaborHours(salesOrder.Id, billingWorksheetWrapper.WorksheetLines,billingWorksheetWrapper.WorksheetLines[0]);
         im.validateContractLine(salesOrder.Id,billingWorksheetWrapper.WorksheetLines[0]);
         //im.testcoverage();
          im.getSalesLineByLineDesc('test');
        BillingWorksheetServiceImpl.calculateLunchHours('1/2 Hour');
         //*/
        // im.initBillingLine(salesOrder,null,billingWorksheetWrapper.WorksheetLines[0]);
        Sales_Invoice__c salesInvoice=new Sales_Invoice__c();
        Sales_Invoice_Job_Task__c salesInvoiceJobTask=new Sales_Invoice_Job_Task__c();
        List<Billing_Worksheet_Line__c> worksheetLines=new List<Billing_Worksheet_Line__c>();
        billingWorksheetWrapper.WorksheetLines[0].Category__c = 'Labor';
        update billingWorksheetWrapper.WorksheetLines[0]; 
        worksheetLines.add(billingWorksheetWrapper.WorksheetLines[0]);
        Id salesInvoiceId = NewTestData.mapSalesInvoicesByName.get('INVOICE01').Id;
        List<Sales_Invoice_Job_Task__c> salesInvoiceJobTasks = SalesInvoiceJobTasksSelector.newInstance().selectBySalesInvoiceId(new Set<Id>{salesInvoiceId});
        List<Sales_Invoice__c> salesInvoices = SalesInvoicesSelector.newInstance().selectById(new Set<Id>{salesInvoiceId});
        List<Sales_Invoice_Line__c> salesInvoiceLines = SalesInvoiceLinesSelector.newInstance().selectByInvoiceId(salesInvoiceId);
        BillingWorksheetServiceImpl.createSalesInvoiceLines(salesInvoices[0],salesInvoiceJobTasks[0],worksheetLines,1);
        Test.stopTest();
    }
    
    @IsTest
    static void testWorksheetControllerWithQueryFewerFields1(){
        NewTestData.createTestData();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        salesOrder.Contract__c = null;
        update salesOrder;
        Test.startTest();
       // BillingWorksheetServiceImpl im = new BillingWorksheetServiceImpl();
        BillingWorksheetServiceImpl.calculateLunchHours('1 Hour');
        Test.stopTest();
    }
    @IsTest
    static void testcalculateLineTax(){
        
        
        Test.startTest();
        List<Sales_Order__c> salesOrders = [SELECT Id FROM Sales_Order__c];     
        BillingWorksheetService.calculateLineTax(salesOrders);
        Test.stopTest();
    }
    
    @IsTest
    static void testcalculateUnitCost(){
        
        
        
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = NewTestData.mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        String billingWorksheetJSON = BillingWorksheetController.getWorksheet(salesOrder.Id, salesOrderJobTask.Id, false);
        BillingWorksheetWrapper billingWorksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(billingWorksheetJSON, BillingWorksheetWrapper.class);
        List<Billing_Worksheet_Line__c> billingWorksheetLines = billingWorksheetWrapper.WorksheetLines;
        Billing_Worksheet_Line__c billingWorksheetLine = billingWorksheetLines[0];
        Id pwPayRuleId = NewTestData.mapPayRuleWrappersByName.get('Prevailing Wage').PayRule.Id;
        
        BillingWorksheetService.calculateUnitCost(salesOrder.Id,billingWorksheetLine, true);
        BillingWorksheetService.calculateUnitCost(salesOrder.Id,billingWorksheetLines,true, pwPayRuleId, true);
        Test.stopTest();
        //
    }
}