@IsTest
private class CustomLookupControllerTest {

    //Validating Lookup Positive
    @IsTest
    static void ValidateLookup() {
        Company_Setup__c CompanySetupRecord = TestDataUtil.CompanySetupRecord;
        Resource_Type__c ResourceTypeRecord = TestDataUtil.ResourceTypeRecord;

        PageReference pageRef = Page.CustomLookupPage;

        System.currentPageReference().getParameters().put('LookupObject', 'Account');
        System.currentPageReference().getParameters().put('LinkFieldName', 'Name');
        System.currentPageReference().getParameters().put('ElementId', 'ElementId');
        System.currentPageReference().getParameters().put('LookupNameId', 'LookupNameId');
        System.currentPageReference().getParameters().put('FieldSetName', 'AccountFieldSet');
        System.currentPageReference().getParameters().put('LookupType', 'ID');
        System.currentPageReference().getParameters().put('RunValidation', 'True');
        System.currentPageReference().getParameters().put('fltr1', 'True');
        System.currentPageReference().getParameters().put('fltr2', 'true');
        System.currentPageReference().getParameters().put('fltr3', 'true');
        System.currentPageReference().getParameters().put('fltr4', 'true');
        System.currentPageReference().getParameters().put('fltr5', 'true');
        System.currentPageReference().getParameters().put('fltr6', 'true');
        System.currentPageReference().getParameters().put('fltr7', 'true');
        System.currentPageReference().getParameters().put('Name', 'NULL');
        System.currentPageReference().getParameters().put('Name_Operation', '!=');
        System.currentPageReference().getParameters().put('Name_Type', 'String');
//      System.currentPageReference().getParameters().put('Billingcity', 'NULL');
//      System.currentPageReference().getParameters().put('Billingcity_Operation', '!=');
//      System.currentPageReference().getParameters().put('Billingcity_Type', 'Integer');

        CustomLookupController cl = new CustomLookupController();
        Test.setCurrentPageReference(pageRef);
        cl.search();
        List<SelectOption> options = cl.lstFilterOperator;
        options = cl.lstFilterField;
        cl.calledFrom = 'TM';
        cl.sObjectName='Resource__c';
        cl.FieldSetName='ResourceFieldSet';        
        cl.calledFor = 'EquipmentResourceLookup';
        List<Schema.FieldSetMember> fields =New List<Schema.FieldSetMember>();      
        Map<String, String> SpecialFieldValueMap=New Map<String, String>();
        SpecialFieldValueMap.Put('ScheduleDate_Special','09/05/2018');
        cl.SpecialFieldValueMap=SpecialFieldValueMap;        
        cl.fetchSpecialScenario(fields);
        cl.calledFor = 'LaborResourceLookup';
        cl.fetchSpecialScenario(fields);
        cl.calledFor = 'LUOMLookUp';
        cl.fetchSpecialScenario(fields);
        cl.calledFor = 'MUOMLookUp';
        cl.fetchSpecialScenario(fields);
        cl.calledFrom = 'SalesOrder';
        cl.calledFor = 'LLUOMLookUp';
        cl.fetchSpecialScenario(fields);
        cl.calledFrom = 'SalesOrder';
        cl.calledFor = 'MLUOMLookUp';
        cl.fetchSpecialScenario(fields);

        cl.selectLaborLookupOnTM(fields);
        SpecialFieldValueMap.put('ResourceType_Special',ResourceTypeRecord.Id);
        cl.selectResourceTypeUOMs(fields);

        List<Company_Setup__c> theCompanySetupList = [SELECT Id FROM Company_Setup__c WHERE Id = :CompanySetupRecord.Id];
        System.assertEquals(theCompanySetupList.size(), 1);

    }
}