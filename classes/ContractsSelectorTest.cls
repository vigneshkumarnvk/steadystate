@IsTest
private class ContractsSelectorTest {
    @TestSetup
    static void setup(){
        //Init numbering series
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
    }

    @IsTest
    private static void testSelectBillingInstructionsById() {
        //Test Data
        Account customer = TestDataUtil.customerAccountRecord;
        Contract contract = new Contract();
        contract.AccountId = customer.Id;
        contract.Status = 'Draft';
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        contract.Billing_Instructions__c = 'Contract Billing Instruction';
        contract.Internal_Comments__c = 'Contract Internal Comments';
        contract.Subsidiary__c = '1-REPUBLIC SERVICES';
        insert contract;

        //Query
        List<Contract> contracts = ContractsSelector.newInstance().selectBillingInstructionsById(new Set<Id>{contract.Id});

        //Assert
        System.assertEquals(contracts[0].Billing_Instructions__c, 'Contract Billing Instruction');
        System.assertEquals(contracts[0].Internal_Comments__c, 'Contract Internal Comments');
    }

    @IsTest
    private static void testSelectById(){
        //Test Data
        Account customer = TestDataUtil.customerAccountRecord;
        Contract contract = new Contract();
        contract.AccountId = customer.Id;
        contract.Status = 'Draft';
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        contract.Subsidiary__c = '1-REPUBLIC SERVICES';
        insert contract;

        //Query
        List<Contract> contracts = ContractsSelector.newInstance().selectById(new Set<Id>{contract.Id});

        //Assert
        System.assertEquals(customer.Id, contracts[0].AccountId);
    }

    @IsTest
    private static void testContractUtil() {
        // Test Data
        ResourceUOMAssociation__c resourceUOMAssociation = TestDataUtil.resourceUOMAssociationRec;
        ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = TestDataUtil.resourceTypeUOMAssociationRec;
        ResourceUOMAssociation__c materialResourceUOMAssociation = TestDataUtil.materialResourceUOMAssociationRec;
        ResourceUOMAssociation__c wasteResourceUOMAssociation = TestDataUtil.wasteResourceUOMAssociationRec;
        Facility__c facility = new Facility__c(Name = 'Test Facility');
        insert facility;

        Account customer = TestDataUtil.customerAccountRecord;
        Contract contract = new Contract();
        contract.AccountId = customer.Id;
        contract.Status = 'Draft';
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        contract.Subsidiary__c = '1-REPUBLIC SERVICES';
        insert contract;

        List<Contract_Line__c> contractLines = new List<Contract_Line__c>();
        Unit_of_Measure__c uom = TestDataUtil.UnitMeasureRecord;
        Resource_Type__c resourceType = TestDataUtil.ResourceTypeRecord;
        Contract_Line__c contractLine = new Contract_Line__c();
        contractLine.Contract__c = contract.Id;
        contractLine.Unit_of_Measure__c = uom.Id;
        contractLine.T_M_Description__c = 'Labor Line';
        contractLine.Resource_Type__c = resourceType.Id;
        contractLine.Regular_Rate__c = 100;
        contractLines.add(contractLine);

        contractLine = new Contract_Line__c();
        Resource__c res = TestDataUtil.ResourceMaterialRecord;
        contractLine = new Contract_Line__c();
        contractLine.Contract__c = contract.Id;
        contractLine.Unit_of_Measure__c = uom.Id;
        contractLine.T_M_Description__c = 'Material Line';
        contractLine.Resource__c = res.Id;
        contractLine.Regular_Rate__c = 50;
        contractLines.add(contractLine);

        contractLine = new Contract_Line__c();
        Resource__c wasteRes = TestDataUtil.ResourceWasteDisposalRecord;
        contractLine = new Contract_Line__c();
        contractLine.Contract__c = contract.Id;
        contractLine.Unit_of_Measure__c = uom.Id;
        contractLine.Facility__c = facility.Id;
        contractLine.T_M_Description__c = 'Waste Disposal Line';
        contractLine.Resource__c = wasteRes.Id;
        contractLine.Regular_Rate__c = 50;
        contractLine.Min_Sell_Qty_Container_Size__c = uom.Id;
        contractLines.add(contractLine);

        insert contractLines;

        ContractUtil.setContractLineByUOMIdsResOrTypeIdsByContractIdsMap(new Set<Id>{contract.Id}, Date.today());
        Contract_Line__c contractLine2 = ContractUtil.getContractLine(contractLines[0].Id);
        contractLine2 = ContractUtil.getContractLine(contract.Id, resourceType.Id, uom.Id);
        String costMethod = EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name();
        contractLine2 = ContractUtil.getContractLine(contract.Id, wasteRes.Id, uom.Id, costMethod, uom.Id, facility.Id);
        costMethod = EnumUtil.CostMethod.CONTAINER.name();
        contractLine2 = ContractUtil.getContractLine(contract.Id, wasteRes.Id, uom.Id, costMethod, uom.Id, facility.Id);
    }

    @IsTest
    private static void testContractUtil2() {
        // Test Data
        ResourceUOMAssociation__c resourceUOMAssociation = TestDataUtil.resourceUOMAssociationRec;
        ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = TestDataUtil.resourceTypeUOMAssociationRec;
        ResourceUOMAssociation__c materialResourceUOMAssociation = TestDataUtil.materialResourceUOMAssociationRec;
        ResourceUOMAssociation__c wasteResourceUOMAssociation = TestDataUtil.wasteResourceUOMAssociationRec;
        Facility__c facility = new Facility__c(Name = 'Test Facility');
        insert facility;

        Account customer = TestDataUtil.customerAccountRecord;
        Contract contract = new Contract();
        contract.AccountId = customer.Id;
        contract.Status = 'Draft';
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        contract.Subsidiary__c = '1-REPUBLIC SERVICES';
        insert contract;

        List<Contract_Line__c> contractLines = new List<Contract_Line__c>();
        Unit_of_Measure__c uom = TestDataUtil.UnitMeasureRecord;
        Resource_Type__c resourceType = TestDataUtil.ResourceTypeRecord;
        Contract_Line__c contractLine = new Contract_Line__c();
        contractLine.Contract__c = contract.Id;
        contractLine.Unit_of_Measure__c = uom.Id;
        contractLine.T_M_Description__c = 'Labor Line';
        contractLine.Resource_Type__c = resourceType.Id;
        contractLine.Regular_Rate__c = 100;
        contractLines.add(contractLine);

        contractLine = new Contract_Line__c();
        Resource__c res = TestDataUtil.ResourceMaterialRecord;
        contractLine = new Contract_Line__c();
        contractLine.Contract__c = contract.Id;
        contractLine.Unit_of_Measure__c = uom.Id;
        contractLine.T_M_Description__c = 'Material Line';
        contractLine.Resource__c = res.Id;
        contractLine.Regular_Rate__c = 50;
        contractLines.add(contractLine);

        contractLine = new Contract_Line__c();
        Resource__c wasteRes = TestDataUtil.ResourceWasteDisposalRecord;
        contractLine = new Contract_Line__c();
        contractLine.Contract__c = contract.Id;
        contractLine.Unit_of_Measure__c = uom.Id;
        contractLine.Facility__c = facility.Id;
        contractLine.T_M_Description__c = 'Waste Disposal Line';
        contractLine.Resource__c = wasteRes.Id;
        contractLine.Regular_Rate__c = 50;
        contractLine.Min_Sell_Qty_Container_Size__c = uom.Id;
        contractLines.add(contractLine);

        insert contractLines;

        ContractUtil.setContractLineByUOMIdsResOrTypeIdsByContractIdsMap(new Set<Id>{contract.Id}, Date.today());
        Contract_Line__c contractLine2 = ContractUtil.getContractLine(contractLines[0].Id);
        contractLine2 = ContractUtil.getContractLine(contract.Id, resourceType.Id, uom.Id, facility.id);
        String costMethod = EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name();
        contractLine2 = ContractUtil.getContractLine(contract.Id, wasteRes.Id, uom.Id, costMethod, uom.Id, facility.Id);
        costMethod = EnumUtil.CostMethod.CONTAINER.name();
        contractLine2 = ContractUtil.getContractLine(contract.Id, wasteRes.Id, uom.Id, costMethod, uom.Id, facility.Id);
    }

    //test1
}