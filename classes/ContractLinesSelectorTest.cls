@IsTest
private class ContractLinesSelectorTest {
    @testSetup
    static void setup(){
        //Init numbering series
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
    }

    @IsTest
    private static void testSelectById() {
        // Test Data
        ResourceUOMAssociation__c resourceUOMAssociation = TestDataUtil.resourceUOMAssociationRec;
        ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = TestDataUtil.resourceTypeUOMAssociationRec;
        ResourceUOMAssociation__c materialResourceUOMAssociation = TestDataUtil.materialResourceUOMAssociationRec;
        Account customer = TestDataUtil.customerAccountRecord;
        Contract contract = new Contract();
        contract.AccountId = customer.Id;
        contract.Status = 'Draft';
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        contract.Subsidiary__c = '1-REPUBLIC SERVICES';
        insert contract;

        Unit_of_Measure__c uom = TestDataUtil.UnitMeasureRecord;
        Resource_Type__c resourceType = TestDataUtil.ResourceTypeRecord;
        Contract_Line__c contractLine = new Contract_Line__c();
        contractLine.Contract__c = contract.Id;
        contractLine.Unit_of_Measure__c = uom.Id;
        contractLine.T_M_Description__c = '';
        contractLine.Resource_Type__c = resourceType.Id;
        contractLine.Regular_Rate__c = 100;
        insert contractLine;

        // Query
        List<Contract_Line__c> contractLines = ContractLinesSelector.newInstance().selectById(new Set<Id>{contractLine.Id});

        // Assert
        System.assertEquals(contractLines[0].Id, contractLine.Id);
    }

    @IsTest
    private static void testSelectTMDescriptionById(){
        // Test Data
        ResourceUOMAssociation__c resourceUOMAssociation = TestDataUtil.resourceUOMAssociationRec;
        ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = TestDataUtil.resourceTypeUOMAssociationRec;
        ResourceUOMAssociation__c materialResourceUOMAssociation = TestDataUtil.materialResourceUOMAssociationRec;
        Account customer = TestDataUtil.customerAccountRecord;
        Contract contract = new Contract();
        contract.AccountId = customer.Id;
        contract.Status = 'Draft';
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        contract.Subsidiary__c = '1-REPUBLIC SERVICES';
        insert contract;

        Unit_of_Measure__c uom = TestDataUtil.UnitMeasureRecord;
        Resource_Type__c resourceType = TestDataUtil.ResourceTypeRecord;
        Contract_Line__c contractLine = new Contract_Line__c();
        contractLine.Contract__c = contract.Id;
        contractLine.Unit_of_Measure__c = uom.Id;
        contractLine.T_M_Description__c = 'This TM Description';
        contractLine.Resource_Type__c = resourceType.Id;
        contractLine.Regular_Rate__c = 100;
        insert contractLine;

        // Query
        Map<Id, Contract_Line__c> contractLinesByIds = ContractLinesSelector.newInstance().selectTMDescriptionById(new Set<Id>{contractLine.Id});

        // Assert
        System.assertEquals('This TM Description', contractLinesByIds.get(contractLine.Id).T_M_Description__c);
    }

    @IsTest
    private static void testSelectLinesByContractId(){
        // Test Data
        ResourceUOMAssociation__c resourceUOMAssociation = TestDataUtil.resourceUOMAssociationRec;
        ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = TestDataUtil.resourceTypeUOMAssociationRec;
        ResourceUOMAssociation__c materialResourceUOMAssociation = TestDataUtil.materialResourceUOMAssociationRec;
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

        insert contractLines;

        // Query
        List<Contract_Line__c> contractLines2 = ContractLinesSelector.newInstance().selectLinesByContractId(new Set<Id>{contract.Id});

        // Assert
        System.assertEquals(2, contractLines2.size());
    }

    @IsTest
    private static void testSelectLinesWithContractIdResTypeAndUOMByContractId() {
        // Test Data
        ResourceUOMAssociation__c resourceUOMAssociation = TestDataUtil.resourceUOMAssociationRec;
        ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = TestDataUtil.resourceTypeUOMAssociationRec;
        ResourceUOMAssociation__c materialResourceUOMAssociation = TestDataUtil.materialResourceUOMAssociationRec;
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

        insert contractLines;

        // Query
        Map<String, Contract_Line__c> contractByContractByResTypeByUOM = ContractLinesSelector.newInstance().selectLinesWithContractIdResTypeAndUOMByContractId(new Set<Id>{
                contract.Id
        });

        // Assert
        System.assertEquals(1, contractByContractByResTypeByUOM.size());
        System.assertEquals(true,
                contractByContractByResTypeByUOM.keySet().contains(contractLines[0].Contract__c + ':' + contractLines[0].Resource_Type__c + ':' + contractLines[0].Unit_of_Measure__c));
    }

    @IsTest
    private static void testSelectLinesWithContractIdResAndUOMByContractId() {
        // Test Data
        ResourceUOMAssociation__c resourceUOMAssociation = TestDataUtil.resourceUOMAssociationRec;
        ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = TestDataUtil.resourceTypeUOMAssociationRec;
        ResourceUOMAssociation__c materialResourceUOMAssociation = TestDataUtil.materialResourceUOMAssociationRec;
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

        insert contractLines;

        // Query
        Map<String, Contract_Line__c> contractByContractByResByUOM = ContractLinesSelector.newInstance().selectLinesWithContractIdResAndUOMByContractId(new Set<Id>{
                contract.Id
        });

        // Assert
        System.assertEquals(1, contractByContractByResByUOM.size());
        System.assertEquals(true,
                contractByContractByResByUOM.keySet().contains(contractLines[1].Contract__c + ':' + contractLines[1].Resource__c + ':' + contractLines[1].Unit_of_Measure__c));
    }

    @IsTest
    private static void testMapLineByContractResORResourceTypeAndUOM() {
        // Test Data
        ResourceUOMAssociation__c resourceUOMAssociation = TestDataUtil.resourceUOMAssociationRec;
        ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = TestDataUtil.resourceTypeUOMAssociationRec;
        ResourceUOMAssociation__c materialResourceUOMAssociation = TestDataUtil.materialResourceUOMAssociationRec;
        Set<String> keys = new Set<String>();
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
        keys.add(contractLine.Contract__c + ':' + contractLine.Resource_Type__c + ':' + contractLine.Unit_of_Measure__c);
        contractLines.add(contractLine);

        contractLine = new Contract_Line__c();
        Resource__c res = TestDataUtil.ResourceMaterialRecord;
        contractLine = new Contract_Line__c();
        contractLine.Contract__c = contract.Id;
        contractLine.Unit_of_Measure__c = uom.Id;
        contractLine.T_M_Description__c = 'Material Line';
        contractLine.Resource__c = res.Id;
        contractLine.Regular_Rate__c = 50;
        keys.add(contractLine.Contract__c + ':' + contractLine.Resource__c + ':' + contractLine.Unit_of_Measure__c);
        contractLines.add(contractLine);

        insert contractLines;

        // Query
        Map<String, Contract_Line__c> contractByContractByResByUOM = ContractLinesSelector.newInstance().mapLineByContractResORResourceTypeAndUOM(new Set<Id>{
                contract.Id
        });

        // Assert
        System.assertEquals(2, contractByContractByResByUOM.size());
        for(String key:contractByContractByResByUOM.keySet())
        {
            System.assertEquals(true, keys.contains(key));
        }
    }
    //test
}