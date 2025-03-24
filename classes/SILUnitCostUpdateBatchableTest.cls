@isTest
public class SILUnitCostUpdateBatchableTest {
    private static testMethod void Test() {
        Test.startTest();
        CompanyMgmt.byPassTrigger = true;
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        
        List<Sales_Invoice_Line__c> salesInvoiceLines = new List<Sales_Invoice_Line__c>();
        Sales_Invoice_Line__C SalesInvoiceLineRecord1 = new Sales_Invoice_Line__c(
                Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
                Resource_Type__c = TestDataUtil.ResourceTypeEquipmentRecord.Id,
                Resource__c = TestDataUtil.ResourceEquipmentRecord.Id,
                Category__c = 'Equipment',
                Description__c = 'Test',
                Line_No__c = 5,
                Quantity__c = 5,
                Unit_Price__c = 2,
                Line_Amount__c = 0,
                Line_Amt_Incl_Tax__c = 0,
                Tax__c = 0,
                Tax_Group__c = 'NT',
                Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
                TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
                TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord1;
        salesInvoiceLines.add(SalesInvoiceLineRecord1);

        Sales_Invoice_Line__C SalesInvoiceLineRecord2 = new Sales_Invoice_Line__c(
                Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
                Resource_Type__c = TestDataUtil.ResourceTypeEquipmentRecord.Id,
                Resource__c = TestDataUtil.ResourceLaborRecord.Id,
                Category__c = 'Labor',
                Description__c = 'Test',
                Line_No__c = 5,
                Quantity__c = 5,
                Cost_Qty__c = 5,
                Unit_Price__c = 2,
                Line_Amount__c = 0,
                Line_Amt_Incl_Tax__c = 0,
                Tax__c = 0,
                Tax_Group__c = 'NT',
                Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
                TM_Line__c = TestDataUtil.TMLineMaterialRecord.id,
                TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord2;
        salesInvoiceLines.add(SalesInvoiceLineRecord2);

        insert salesInvoiceLines;

        ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = new ResourceTypeUOMAssociation__c();
        resourceTypeUOMAssociation.Resource_Type__c = TestDataUtil.ResourceTypeEquipmentRecord.Id;
        resourceTypeUOMAssociation.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        resourceTypeUOMAssociation.Unit_Cost__c = 100;
        resourceTypeUOMAssociation.Unit_Price__c = 150;
        resourceTypeUOMAssociation.ER_Unit_Price__c = 150;
        insert resourceTypeUOMAssociation;

        SILUnitCostUpdateBatchable batchable = new SILUnitCostUpdateBatchable();
        Database.executeBatch(batchable, 200);
        CompanyMgmt.byPassTrigger = false;
        Test.stopTest();
    }

//    private static testMethod void Test2() {
//        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
//        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
//
//        List<Sales_Invoice_Line__c> salesInvoiceLines = new List<Sales_Invoice_Line__c>();
//        Sales_Invoice_Line__C SalesInvoiceLineRecord2 = new Sales_Invoice_Line__c(
//                Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
//                Resource__c = TestDataUtil.ResourceMaterialRecord.Id,
//                Category__c = 'Materials',
//                Description__c = 'Test',
//                Line_No__c = 5,
//                Quantity__c = 5,
//                Unit_Price__c = 2,
//                Line_Amount__c = 0,
//                Line_Amt_Incl_Tax__c = 0,
//                Tax__c = 0,
//                Tax_Group__c = 'NT',
//                Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
//                TM_Line__c = TestDataUtil.TMLineMaterialRecord.id,
//                TM__c = TestDataUtil.TMRecord.id
//        );
//        //insert SalesInvoiceLineRecord2;
//        salesInvoiceLines.add(SalesInvoiceLineRecord2);
//
//        insert salesInvoiceLines;
//
//        Test.startTest();
//        SILUnitCostUpdateBatchable batchable = new SILUnitCostUpdateBatchable();
//        Database.executeBatch(batchable, 200);
//        Test.stopTest();
//    }
}