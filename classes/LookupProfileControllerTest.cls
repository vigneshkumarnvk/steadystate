@IsTest
public class LookupProfileControllerTest { 
    @TestSetup
    static void setup(){
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = TestDataUtil.resourceTypeUOMAssociationRec;
        ResourceUOMAssociation__c resourceUOMAssociation = TestDataUtil.materialResourceUOMAssociationRec;
        
        List<Surcharge_Setup__c> surchargeSetups = new List<Surcharge_Setup__c>();
        Surcharge_Setup__c surchargeSetup = new Surcharge_Setup__c(
            Name = 'Default EI',
            Surcharge_Type__c = 'Energy and Environmental Compliance Fee',
            Surcharge_Pct__c = 10,
            Effective_Date__c = Date.today(),
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id
        );
        surchargeSetups.add(surchargeSetup);
        
        surchargeSetup = new Surcharge_Setup__c(
            Name = 'Default EI',
            Surcharge_Type__c = 'Fuel Surcharge',
            Surcharge_Pct__c = 20,
            Effective_Date__c = Date.today(),
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id
        );
        surchargeSetups.add(surchargeSetup);
        insert surchargeSetups;
        
        Contract contract = new Contract();
        contract.Name = 'Contract of the day ' + Date.today();
        contract.AccountId = TestDataUtil.customerAccountRecord.Id;
        contract.StartDate = Date.today();
        contract.Status = 'Draft';
        contract.Subsidiary__c ='1-REPUBLIC SERVICES';
        insert contract;
        
        List<Contract_Line__c> contractLines = new List<Contract_Line__c>();
        Contract_Line__c contractLaborLine = new Contract_Line__c();
        contractLaborLine.Contract__c = contract.Id;
        contractLaborLine.Name = 'Labor Contract';
        contractLaborLine.Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id;
        contractLaborLine.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        contractLaborLine.Regular_Rate__c = 100;
        contractLaborLine.Overtime_Rate__c = 150;
        contractLaborLine.Premium_Rate__c = 200;
        contractLines.add(contractLaborLine);
        
        Contract_Line__c contractMaterialLine = new Contract_Line__c();
        contractMaterialLine = new Contract_Line__c();
        contractMaterialLine.Contract__c = contract.Id;
        contractMaterialLine.Name = 'Material Contract';
        contractMaterialLine.Resource__c = TestDataUtil.ResourceMaterialRecord.Id;
        contractMaterialLine.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        contractMaterialLine.Regular_Rate__c = 500;
        contractLines.add(contractMaterialLine);
        insert contractLines;
        
        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Name = 'NJ57506-01-2080';
        salesOrder.Surcharge_Type__c = 'N/A';
        salesOrder.Document_Type__c = 'Sales Order';
        salesOrder.Bill_to_Customer_No__c = TestDataUtil.customerAccountRecord.Id;
        salesOrder.Service_Center__c = TestDataUtil.ServiceCenterRecord.Id;
        salesOrder.Sales_Order_Type__c = TestDataUtil.SalesOrdertypeRecord.Id;
        salesOrder.Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id;
        salesOrder.Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id;
        salesOrder.Tax_Area__c = TestDataUtil.TaxAreaRecord.Id;
        salesOrder.Estimated_Job_Start_Date__c = Date.today();
        salesOrder.Contract__c = contract.Id;
        insert salesOrder;
        
        List<Sales_Line__c> salesLines = new List<Sales_Line__c>();
        Sales_Line__c salesLineLabor = new Sales_Line__c();
        salesLineLabor.Line_No__c = 1;
        salesLineLabor.Category__c = 'Labor';
        salesLineLabor.Description__c = 'Labor Line';
        salesLineLabor.Quantity__c = 1;
        salesLineLabor.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        salesLineLabor.UOM_Qty__c = 1;
        salesLineLabor.Regular_Hours__c = 1;
        salesLineLabor.Overtime_Hours__c= 0;
        salesLineLabor.Premium_Hours__c = 0;
        salesLineLabor.Regular_Day__c = 1;
        salesLineLabor.Overtime_Day__c= 0;
        salesLineLabor.Premium_Day__c = 0;
        salesLineLabor.Number_of_Day__c = 1;
        salesLineLabor.Sales_Order__c = salesOrder.Id;
        salesLineLabor.Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id;
        salesLines.add(salesLineLabor);
        
        Sales_Line__c salesLineMaterial = new Sales_Line__c();
        salesLineMaterial.Line_No__c = 2;
        salesLineMaterial.Category__c = 'Materials';
        salesLineMaterial.Description__c = 'Material Line';
        salesLineMaterial.Quantity__c = 1;
        salesLineMaterial.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        salesLineMaterial.Sales_Order__c = salesOrder.Id;
        salesLineMaterial.Resource__c = TestDataUtil.ResourceMaterialRecord.Id;
        salesLines.add(salesLineMaterial);
        insert salesLines;
        
        TM__c tm = new TM__c();
        tm.Bill_to_Customer__c = salesOrder.Bill_to_Customer_No__c;
        tm.Project_Coordinator__c = salesOrder.Project_Coordinator__c;
        tm.Account_Executive__c = salesOrder.Account_Executives__c;
        tm.Subsidiary_Company__c = salesOrder.Subsidiary_Company__c;
        tm.Service_Center__c = salesOrder.Service_Center__c;
        tm.Tax_Area__c = salesOrder.Tax_Area__c;
        tm.Tax_Liable__c = true;
        tm.Sales_Order__c = salesOrder.Id;
        tm.Scheduled_Date__c = Date.today().addDays(1);
        tm.Status__c = 'Fully Invoiced';
        insert tm;
        
        List<TM_Line__c> tmLines = new List<TM_Line__c>();
        TM_Line__c tmLine = new TM_Line__c();
        tmLine.TM__c = tm.Id;
        tmLine.Line_No__c = 1;
        tmLine.Description__c = salesLineLabor.Description__c;
        tmLine.Quantity__c = 1;
        tmLine.Category__c = salesLineLabor.Category__c;
        tmLine.Resource_Type__c = salesLineLabor.Resource_Type__c;
        tmLine.Service_Center__c = tm.Service_Center__c;
        tmLine.Resource__c = TestDataUtil.ResourceLaborRecord.Id;
        tmLine.Regular_Hours__c = 8;
        tmLine.Hour__c = 8;
        tmLine.Tax_Group__c = 'TX';
        tmLine.Unit_of_Measure__c = salesLineLabor.Unit_of_Measure__c;
        tmLine.Job_Start_Time__c = System.now().addHours(-8).time();
        tmLine.Job_End_Time__c = System.now().time();
        tmLines.add(tmLine);
        
        tmLine = new TM_Line__c();
        tmLine.TM__c = tm.Id;
        tmLine.Line_No__c = 2;
        tmLine.Description__c = salesLineMaterial.Description__c;
        tmLine.Quantity__c = 10;
        tmLine.Category__c = salesLineMaterial.Category__c;
        tmLine.Resource__c = salesLineMaterial.Resource__c;
        tmLine.Unit_of_Measure__c = salesLineMaterial.Unit_of_Measure__c;
        tmLine.Tax_Group__c = 'TX';
        tmLines.add(tmLine);
        insert tmLines;
        
    }  
@IsTest
    static void testGetApprovedProfiles() {
        Test.startTest();
        TM__c tmline = [SELECT Id, Sales_Order__r.Alternate_Site_Address__r.Id,
                              Sales_Order__r.EqaiGeneratorId__c,
                              Sales_Order__r.Bill_to_Customer_No__r.Sage_Customer_No__c,
                              Sales_Order__r.Service_Center__r.Name
                         FROM TM__c LIMIT 1];        
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('[{"APPROVAL_CODE": "123", "id": "001", "waste_code": "WC123", "waste_desc": "Hazardous Waste", "expiration_date": "2025-12-31"}]');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        LookupProfileController.ApprovalRecords response = LookupProfileController.fetchRecords('TM_Line__c', 'TestKeyword', tmline.Id, '',String.valueOf(tmline.Sales_Order__r.EqaiGeneratorId__c), tmline.Sales_Order__r.Service_Center__c);
        Test.stopTest();
    }
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse response;
        
        public MockHttpResponseGenerator(HttpResponse response) {
            this.response = response;
        }        
        public HttpResponse respond(HttpRequest req) {
            return response;
        }
    }
  
}