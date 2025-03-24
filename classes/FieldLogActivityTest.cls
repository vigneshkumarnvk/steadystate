@IsTest
private class FieldLogActivityTest {

    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;

    @TestSetup
    static void SetupData(){
        CompanyMgmt.byPassTrigger = true;
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        TM__c TMRecord = TestDataUtil.TMRecord;
        TM_Line__c TMLineLaborRecord = TestDataUtil.TMLineLaborRecord;
        TM_Line__c TMLineEquipmentRecord = TestDataUtil.TMLineEquipmentRecord;
        Resource__c eqRes = TestDataUtil.ResourceEquipmentRecord;
        CompanyMgmt.byPassTrigger = false;
    }

    @IsTest
    static void testFieldLogActivityController() {
        TM__c tm = [SELECT Id FROM TM__c LIMIT 1];
        TM_Line__c tmLine = [SELECT Id FROM TM_Line__c WHERE Category__c = 'Labor' LIMIT 1];
        Resource__c equipmentRes = [SELECT Id FROM Resource__c WHERE Category__c = 'Equipment' LIMIT 1];

        Test.startTest();
        PageReference pageReference = Page.FieldLogEntry;
        Test.setCurrentPage(pageReference);
        pageReference.getParameters().put('tmId', tm.Id);
        pageReference.getParameters().put('tmlId', tmLine.Id);
        ApexPages.StandardController stdCon = new ApexPages.StandardController(tm);
        FieldLogActivityController fieldLogActivityController = new FieldLogActivityController(stdCon);
        fieldLogActivityController.addLine();

        pageReference.getParameters().put('fieldName', 'theEquipment');
        pageReference.getParameters().put('indexNo', '0');
        pageReference.getParameters().put('newFieldValue', equipmentRes.Id);
        fieldLogActivityController.validateField();

        pageReference.getParameters().put('fieldName', 'startTime');
        pageReference.getParameters().put('indexNo', '0');
        pageReference.getParameters().put('newFieldValue', '10:00');
        fieldLogActivityController.validateField();

        pageReference.getParameters().put('fieldName', 'endTime');
        pageReference.getParameters().put('indexNo', '0');
        pageReference.getParameters().put('newFieldValue', '11:00');
        fieldLogActivityController.validateField();

        fieldLogActivityController.save();

        pageReference.getParameters().put('displayId', '0');
        fieldLogActivityController.deleteLine();
        fieldLogActivityController.returnToTM();
        Test.stopTest();
    }
}