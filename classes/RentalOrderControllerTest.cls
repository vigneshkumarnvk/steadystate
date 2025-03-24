@isTest
public with sharing class RentalOrderControllerTest {

    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    @testSetup static void SetupData() {
        //Setup Data
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = : companySetup.Id];
        System.assertEquals(theCSList.size(), 1);
    }

    public static testMethod void test_RentalOrderController() {
        Test.startTest();
        Rental_Order__c RentalOrderRecord =TestDataUtil.RentalOrderRecord;

        PageReference pageRef = Page.RentalOrder;
        pageRef.getParameters().put('id',RentalOrderRecord.id);
        ApexPages.StandardController sc = new ApexPages.standardController(RentalOrderRecord);
        RentalOrderController RO = new RentalOrderController(sc);
        RO.ROId=RentalOrderRecord.id;
        RO.selectRO();
        String title=RO.title;
        Rental_Order__c ROR=RO.RO;
        Company_Setup__c CompanySetup=RO.CompanySetup;
        RO.save();
        RO.quickSave();
        RO.returnBack();
        Set<Id>selectedIds=New Set<Id>();
        selectedIds.add(RentalOrderRecord.Id);
        RO.selectedIds=selectedIds;
        RO.CreateInvoice();
        Test.stopTest();
    }

    public static testMethod void test_RentalOrderController2() {
        Test.startTest();
        Rental_Order__c RentalOrderRecord =TestDataUtil.RentalOrderRecord;
        List<Rental_Order__c>ROList=New List<Rental_Order__c>();
        ROList.add(RentalOrderRecord);

        PageReference pageRef = Page.RentalOrder;
//      pageRef.getParameters().put('id', RentalOrderRecord.id);
        ApexPages.StandardController sc = new ApexPages.standardController(RentalOrderRecord);
        RentalOrderController controller = new RentalOrderController(sc);

        ApexPages.StandardSetController  sSc = new ApexPages.StandardSetController(ROList);
        RentalOrderController sscontroller = new RentalOrderController(sSc);
        Test.stopTest();
    }

}