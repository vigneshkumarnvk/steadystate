@IsTest
private class ContractsTest {
    @TestSetup
    static void setup(){
        //Init numbering series
        //Test.startTest();
       /* Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
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
        tm.Status__c = 'Open';
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
        insert tmLines;*/
        //Test.stopTest();

    }

    @IsTest
    static void testUpdateSurchargeOnContractBehavior() {
        Test.startTest();
        Account account = TestDataUtil.customerAccountRecord;
        Contract contract = new Contract();
        contract.Name = 'Contract of the day ' + Date.today();
        contract.AccountId = account.Id;
        contract.StartDate = Date.today();
        contract.Surcharge_Pct__c = 30;
        contract.Surcharge_Type__c = 'Energy and Environmental Compliance Fee';
        contract.Status = 'Draft';
        contract.Subsidiary__c ='1-REPUBLIC SERVICES';
        insert contract;
        //Contract contract = [SELECT Id, Surcharge_Type__c, Surcharge_Pct__c FROM Contract LIMIT 1];
        //Account account = [SELECT Id FROM Account WHERE AccountNumber = '01-00000001' LIMIT 1];
        
        //contract.Surcharge_Type__c = 'Energy and Environmental Compliance Fee';
        //contract.Surcharge_Pct__c = 30;
        //contract.AccountId = account.Id;
        //update contract;
        
        //contract.Surcharge_Pct__c = 0;
        //update contract;

        //contract.AccountId = account.Id;
        //update contract;
        Test.stopTest();
    }

    @IsTest
    static void testUpdateSurchargeOnContractBehavior2() {
        Test.startTest();
        Account account = TestDataUtil.customerAccountRecord;
        Contract contract = new Contract();
        contract.Name = 'Contract of the day ' + Date.today();
        contract.AccountId = account.Id;
        contract.StartDate = Date.today();
        contract.Surcharge_Pct__c = 0;
        contract.Surcharge_Type__c = 'Fuel Surcharge';
        contract.Status = 'Draft';
        contract.Subsidiary__c ='1-REPUBLIC SERVICES';
        insert contract;
        //Contract contract = [SELECT Id, Surcharge_Type__c, Surcharge_Pct__c FROM Contract LIMIT 1];
        //Account account = [SELECT Id FROM Account WHERE AccountNumber = '01-00000001' LIMIT 1];
        
        //contract.Surcharge_Type__c = 'Fuel Surcharge';
        //contract.Surcharge_Pct__c = 0;
        //contract.AccountId = account.Id;
        //update contract;
        
         contract.Surcharge_Pct__c = 0;
         update contract;

        //contract.AccountId = account.Id;
        //update contract;
        Test.stopTest();
    }

    @IsTest
    static void testUpdateSurchargeOnContractBehavior3() {
        Test.startTest();
        Account account = TestDataUtil.customerAccountRecord;
        Contract contract = new Contract();
        contract.Name = 'Contract of the day ' + Date.today();
        contract.AccountId = account.Id;
        contract.StartDate = Date.today();
        contract.Surcharge_Pct__c = 0;
        contract.Surcharge_Type__c = 'Fuel Surcharge';
        contract.Status = 'Draft';
        contract.Subsidiary__c ='1-REPUBLIC SERVICES';
        insert contract;
        /*Contract contract = [SELECT Id, Surcharge_Type__c, Surcharge_Pct__c FROM Contract LIMIT 1];
        Account account = [SELECT Id FROM Account WHERE AccountNumber = '01-00000001' LIMIT 1];
        
        contract.Surcharge_Type__c = 'Fuel Surcharge';
        contract.Surcharge_Pct__c = 0;
        contract.AccountId = account.Id;
        update contract;*/
        
        // contract.Surcharge_Pct__c = 0;
        // update contract;

        //contract.AccountId = account.Id;
        //update contract;
        Test.stopTest();
    }

    @IsTest
    static void testUpdateSurchargeOnContractBehavior4() {
        Test.startTest();
        /*Contract contract = [SELECT Id, Surcharge_Type__c, Surcharge_Pct__c FROM Contract LIMIT 1];
        Account account = [SELECT Id FROM Account WHERE AccountNumber = '01-00000001' LIMIT 1];
        
        contract.Surcharge_Type__c = null;
        contract.Surcharge_Pct__c = 0;
        contract.AccountId = account.Id;
        update contract;*/

        //contract.AccountId = account.Id;
        //update contract;
        Account account = TestDataUtil.customerAccountRecord;
        Contract contract = new Contract();
        contract.Name = 'Contract of the day ' + Date.today();
        contract.AccountId = account.Id;
        contract.StartDate = Date.today();
        contract.Surcharge_Pct__c = 0;
        contract.Surcharge_Type__c = 'Fuel Surcharge';
        contract.Status = 'Draft';
        contract.Subsidiary__c ='1-REPUBLIC SERVICES';
        insert contract;
        
        contract.Surcharge_Type__c = null;
        contract.Surcharge_Pct__c = 0;
        contract.AccountId = account.Id;
        update contract;
        Test.stopTest();
    }

    @IsTest
    static void testUpdateSurchargeOnContractBehavior5() {
        Test.startTest();
        Account account = TestDataUtil.customerAccountRecord;
        Contract contract = new Contract();
        contract.Name = 'Contract of the day ' + Date.today();
        contract.AccountId = TestDataUtil.customerAccountRecord.Id;
        contract.StartDate = Date.today();
        contract.Surcharge_Pct__c = 0;
        contract.Surcharge_Type__c = 'Fuel Surcharge';
        contract.Status = 'Draft';
        contract.Subsidiary__c ='1-REPUBLIC SERVICES';
        insert contract;
        /*Contract contract = [SELECT Id, Surcharge_Type__c, Surcharge_Pct__c FROM Contract LIMIT 1];
        Account account = [SELECT Id FROM Account WHERE AccountNumber = '01-00000001' LIMIT 1];*/
        
        contract.Surcharge_Type__c = '';
        contract.Surcharge_Pct__c = 5;
        update contract;

        //contract.AccountId = account.Id;
        //update contract;
        Test.stopTest();
    }

    @IsTest
    static void testUpdateSurchargeOnContractBehavior6() {
        /*Test.startTest();
        Account account = TestDataUtil.customerAccountRecord;
        Contract contract = new Contract();
        contract.Name = 'Contract of the day ' + Date.today();
        contract.AccountId = TestDataUtil.customerAccountRecord.Id;
        contract.StartDate = Date.today();
        contract.Surcharge_Pct__c = 0;
        contract.Surcharge_Type__c = 'Energy and Environmental Compliance Fee';
        contract.Status = 'Draft';
        contract.Subsidiary__c ='1-REPUBLIC SERVICES';
        insert contract;
        //Contract contract = [SELECT Id, Surcharge_Type__c, Surcharge_Pct__c FROM Contract LIMIT 1];
        //Account account = [SELECT Id FROM Account WHERE AccountNumber = '01-00000001' LIMIT 1];
        Sales_Order__C salesOrder = [SELECT Id FROM Sales_Order__c LIMIT 1];
        Service_Center__c sc = [SELECT Id FROM Service_Center__c LIMIT 1];

        Subsidiary_Company__c subC = new Subsidiary_Company__c(
            Name = '1-REPUBLIC SERVICES',
            Display_Name__c = 'SO'
        );
        insert subC;

        //sc.Energy_Environmental_Compliance_Pct__c = 5;
        //update sc;


        
        /*contract.Surcharge_Type__c = 'Energy and Environmental Compliance Fee';
        contract.Surcharge_Pct__c = 0;
        contract.AccountId = account.Id;
        update contract;

        //contract.AccountId = account.Id;
        //update contract;
        Test.stopTest();*/
        
        
        
        //Init numbering series
        Test.startTest();
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
        
        Sales_Order_Job_Task__c jobTask1 = new Sales_Order_Job_Task__c();
        jobTask1.Sales_Order__c = salesOrder.Id;
        jobTask1.Billing_Type__c = 'Fixed Price';
        jobTask1.Fixed_Price_Surcharge_Option__c = 'Fixed Price Does Not Include Surcharge';
        jobTask1.Line_No__c = 1;
        jobTask1.Task_No__c = 1;
        jobTask1.Name = 'Field Service';
        //jobTasks.add(jobTask1);
        insert jobTask1;

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
        salesLineLabor.Sales_Order_Job_Task__c = jobTask1.Id;
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
        salesLineMaterial.Sales_Order_Job_Task__c = jobTask1.Id;
        salesLines.add(salesLineMaterial);
        insert salesLines;

        /*TM__c tm = new TM__c();
        tm.Bill_to_Customer__c = salesOrder.Bill_to_Customer_No__c;
        tm.Project_Coordinator__c = salesOrder.Project_Coordinator__c;
        tm.Account_Executive__c = salesOrder.Account_Executives__c;
        tm.Subsidiary_Company__c = salesOrder.Subsidiary_Company__c;
        tm.Service_Center__c = salesOrder.Service_Center__c;
        tm.Tax_Area__c = salesOrder.Tax_Area__c;
        tm.Tax_Liable__c = true;
        tm.Sales_Order__c = salesOrder.Id;
        tm.Scheduled_Date__c = Date.today().addDays(1);
        tm.Status__c = 'Open';
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
        Test.StopTest();*/
        
        contract = [SELECT Id, Surcharge_Type__c, Surcharge_Pct__c FROM Contract LIMIT 1];
        Account account = [SELECT Id FROM Account WHERE AccountNumber = '01-00000001' LIMIT 1];
        salesOrder = [SELECT Id FROM Sales_Order__c LIMIT 1];
        Service_Center__c sc = [SELECT Id FROM Service_Center__c LIMIT 1];

        Subsidiary_Company__c subC = new Subsidiary_Company__c(
            Name = '1-REPUBLIC SERVICES',
            Display_Name__c = 'SO'
        );
        insert subC;

        sc.Energy_Environmental_Compliance_Pct__c = 5;
        update sc;


        
        contract.Surcharge_Type__c = 'Energy and Environmental Compliance Fee';
        contract.Surcharge_Pct__c = 0;
        contract.AccountId = account.Id;
        update contract;

        contract.AccountId = account.Id;
        update contract;
        Test.stopTest();
        

    }

    @IsTest
    static void testUpdateSurchargeOnContractBehavior7() {
        /*Test.startTest();
        Account account = TestDataUtil.customerAccountRecord;
        Contract contract = new Contract();
        contract.Name = 'Contract of the day ' + Date.today();
        contract.AccountId = TestDataUtil.customerAccountRecord.Id;
        contract.StartDate = Date.today();
        contract.Surcharge_Pct__c = 0;
        contract.Surcharge_Type__c = 'Fuel Surcharge';
        contract.Status = 'Draft';
        contract.Subsidiary__c ='1-REPUBLIC SERVICES';
        insert contract;
        
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
        //Contract contract = [SELECT Id, Surcharge_Type__c, Surcharge_Pct__c FROM Contract LIMIT 1];
        //Account account = [SELECT Id FROM Account WHERE AccountNumber = '01-00000001' LIMIT 1];
        //Sales_Order__C salesOrder = [SELECT Id FROM Sales_Order__c LIMIT 1];
        Service_Center__c sc = [SELECT Id FROM Service_Center__c LIMIT 1];

        Subsidiary_Company__c subC = new Subsidiary_Company__c(
            Name = '1-REPUBLIC SERVICES',
            Display_Name__c = 'SO'
        );
        insert subC;

        //sc.Fuel_Surcharge_Pct__c = 5;
        //update sc;


        
        /*contract.Surcharge_Type__c = 'Fuel Surcharge';
        contract.Surcharge_Pct__c = 0;
        contract.AccountId = account.Id;
        update contract;

        //contract.AccountId = account.Id;
        //update contract;
        Test.stopTest();*/
        
        
        
        //Init numbering series
        Test.startTest();
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
        
        Sales_Order_Job_Task__c jobTask1 = new Sales_Order_Job_Task__c();
        jobTask1.Sales_Order__c = salesOrder.Id;
        jobTask1.Billing_Type__c = 'Fixed Price';
        jobTask1.Fixed_Price_Surcharge_Option__c = 'Fixed Price Does Not Include Surcharge';
        jobTask1.Line_No__c = 1;
        jobTask1.Task_No__c = 1;
        jobTask1.Name = 'Field Service';
        //jobTasks.add(jobTask1);
        insert jobTask1;

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
        salesLineLabor.Sales_Order_Job_Task__c = jobTask1.Id;
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
        salesLineMaterial.Sales_Order_Job_Task__c = jobTask1.Id;
        salesLines.add(salesLineMaterial);
        insert salesLines;
        
        contract = [SELECT Id, Surcharge_Type__c, Surcharge_Pct__c FROM Contract LIMIT 1];
        Account account = [SELECT Id FROM Account WHERE AccountNumber = '01-00000001' LIMIT 1];
        salesOrder = [SELECT Id FROM Sales_Order__c LIMIT 1];
        Service_Center__c sc = [SELECT Id FROM Service_Center__c LIMIT 1];
        
        Subsidiary_Company__c subC = new Subsidiary_Company__c(
            Name = '1-REPUBLIC SERVICES',
            Display_Name__c = 'SO'
        );
        insert subC;

        sc.Fuel_Surcharge_Pct__c = 5;
        update sc;
		
        contract.Surcharge_Type__c = 'Fuel Surcharge';
        contract.Surcharge_Pct__c = 0;
        update contract;

        contract.AccountId = account.Id;
        update contract;
        Test.stopTest();
        
    }

    @IsTest
    static void testUpdateSurchargeOnContractBehavior8() {
        Test.startTest();
        
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
        
        Sales_Order_Job_Task__c jobTask1 = new Sales_Order_Job_Task__c();
        jobTask1.Sales_Order__c = salesOrder.Id;
        jobTask1.Billing_Type__c = 'Fixed Price';
        jobTask1.Fixed_Price_Surcharge_Option__c = 'Fixed Price Does Not Include Surcharge';
        jobTask1.Line_No__c = 1;
        jobTask1.Task_No__c = 1;
        jobTask1.Name = 'Field Service';
        //jobTasks.add(jobTask1);
        insert jobTask1;

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
        salesLineLabor.Sales_Order_Job_Task__c = jobTask1.Id;
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
        salesLineMaterial.Sales_Order_Job_Task__c = jobTask1.Id;
        salesLines.add(salesLineMaterial);
        insert salesLines;
        
        contract = [SELECT Id, Surcharge_Type__c, Surcharge_Pct__c FROM Contract LIMIT 1];
        Account account = [SELECT Id FROM Account WHERE AccountNumber = '01-00000001' LIMIT 1];
        salesOrder = [SELECT Id FROM Sales_Order__c LIMIT 1];
        Service_Center__c sc = [SELECT Id FROM Service_Center__c LIMIT 1];
        
        //Sales_Order__C salesOrder = [SELECT Id FROM Sales_Order__c LIMIT 1];
        //Service_Center__c sc = [SELECT Id FROM Service_Center__c LIMIT 1];
        Surcharge_Setup__c ss = [SELECT Id FROM Surcharge_Setup__c LIMIT 1];
		
        Subsidiary_Company__c subC = new Subsidiary_Company__c(
            Name = '1-REPUBLIC SERVICES',
            Display_Name__c = 'SO'
        );
        insert subC;
        

        sc.Fuel_Surcharge_Pct__c = 0;
        update sc;

        ss.Effective_Date__c = Date.newInstance(2024, 05, 03);
        update ss;
        salesOrder.Quote_Date__c = Date.newInstance(2024, 05, 20);
        update salesOrder;


        contract.Surcharge_Type__c = 'Fuel Surcharge';
        contract.Surcharge_Pct__c = 0;
        update contract;

        contract.AccountId = account.Id;
        update contract;
        Test.stopTest();
    }


    @IsTest
    static void testAccountContractAssociation(){
        Test.startTest();
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
        
        Sales_Order_Job_Task__c jobTask1 = new Sales_Order_Job_Task__c();
        jobTask1.Sales_Order__c = salesOrder.Id;
        jobTask1.Billing_Type__c = 'Fixed Price';
        jobTask1.Fixed_Price_Surcharge_Option__c = 'Fixed Price Does Not Include Surcharge';
        jobTask1.Line_No__c = 1;
        jobTask1.Task_No__c = 1;
        jobTask1.Name = 'Field Service';
        //jobTasks.add(jobTask1);
        insert jobTask1;

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
        salesLineLabor.Sales_Order_Job_Task__c = jobTask1.Id;
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
        salesLineMaterial.Sales_Order_Job_Task__c = jobTask1.Id;
        salesLines.add(salesLineMaterial);
        insert salesLines;
        
        contract = [SELECT Id, Subsidiary__c FROM Contract LIMIT 1];
        Account account = [SELECT Id FROM Account WHERE AccountNumber = '01-00000001' LIMIT 1];
        Account_Contract_Association__c accountContractAssociation = new Account_Contract_Association__c();
        accountContractAssociation.Contract__c = contract.Id;
        accountContractAssociation.Account__c = account.Id;
        insert accountContractAssociation;

        contract.Subsidiary__c = '5-RS-ES Gulf Coast';
        update contract;

        try{
            update accountContractAssociation;
        } catch (Exception ex){

        }
        Test.stopTest();
    }

    

    @IsTest
    static void testDeleteAccountContractAssociation(){
        Test.startTest();
        
        //Contract contract = [SELECT Id, Subsidiary__c FROM Contract LIMIT 1];
        Account account =TestDataUtil.customerAccountRecord; //[SELECT Id FROM Account WHERE AccountNumber = '01-00000001' LIMIT 1];
        Contract contract = new Contract();
        contract.Name = 'Contract of the day ' + Date.today();
        contract.AccountId = account.Id;//TestDataUtil.customerAccountRecord.Id;
        contract.StartDate = Date.today();
        contract.Status = 'Draft';
        contract.Subsidiary__c ='1-REPUBLIC SERVICES';
        insert contract;
        ContractUtil.deleteAccountContractAssociation(account.id, contract.id);

        Test.stopTest();

    }

    @IsTest
    static void testGenerateLineDescriptionWithCustomerItemNoAndDescription() {
        String lineDescription = 'Default Line Description';
        String customerItemNo = '12345';
        String customerDescription = 'Customer Description';

        String expected = customerItemNo + ' - ' + customerDescription;
        String actual = ContractUtil.generateLineDescription(lineDescription, customerItemNo, customerDescription);

        System.assertEquals(expected, actual);
    }

    //@IsTest
    static void testGenerateLineDescriptionWithCustomerItemNo() {
        String lineDescription = 'Default Line Description';
        String customerItemNo = '12345';
        String customerDescription = '';

        String expected = lineDescription + ' - ' + customerItemNo;
        String actual = ContractUtil.generateLineDescription(lineDescription, customerItemNo, customerDescription);

        System.assertEquals(expected, actual);
    }

    @IsTest
    static void testGenerateLineDescriptionWithCustomerDescription() {
        String lineDescription = 'Default Line Description';
        String customerItemNo = '';
        String customerDescription = 'Customer Description';

        String expected = customerDescription;
        String actual = ContractUtil.generateLineDescription(lineDescription, customerItemNo, customerDescription);

        System.assertEquals(expected, actual);
    }

    @IsTest
    static void testGenerateLineDescriptionWithEmptyInputs() {
        String lineDescription = '';
        String customerItemNo = '';
        String customerDescription = '';

        String expected = '';
        String actual = ContractUtil.generateLineDescription(lineDescription, customerItemNo, customerDescription);

        System.assertEquals(expected, actual);
    }

    //test

}
