@isTest
public class SalesOrderTriggersMgtTest {
    
    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    @testSetup static void SetupData() {
        //Setup Data
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = : companySetup.Id];
        System.assertEquals(theCSList.size(), 1);
    }
    
    private static testMethod void Test_SalesOrderTriggersMgt() {
        
        Sales_Order__c SalesOrderRecord=TestDataUtil.SalesOrderRecord;
        Account testAccount= New Account();//TestDataUtil.AccountRecord;
        List<Sales_Order__c>SalesOrderList=New List<Sales_Order__c>();
        testAccount.Id = SalesOrderRecord.Bill_to_Customer_No__c;
        testAccount.Inter_co_Account__c = true;
        testAccount.Tax_Liable__c = false;
        testAccount.Emergency__c = false;
        testAccount.AccountNumber = '123456';
        testAccount.Customer_Billing_Instructions__c = 'Some Billing Instructions';
        testAccount.Billing_Instructions__c = 'Some Billing Instructions';
        update testAccount;
        update SalesOrderRecord;
        SalesOrderList.add(SalesOrderRecord);
        Map<Id,Sales_Order__c>SalesOrderMap=New Map<Id,Sales_Order__c>();
        SalesOrderMap.put(SalesOrderRecord.Id,SalesOrderRecord);
        test.startTest();
        SalesOrderTriggersMgt.SOInsertUpdate(SalesOrderList,SalesOrderMap,True);
        test.stopTest();
        
    }
    private static testMethod void Test_SalesLine() {
        
        Sales_Line__c SalesLineRecord=TestDataUtil.SalesLineRecord;
        SalesLineRecord.Quote_Line__c = SalesLineRecord.Id;
        List<Sales_Line__c>SalesLineList=New List<Sales_Line__c>();
        SalesLineList.add(SalesLineRecord);
        Map<Id,Sales_Line__c>SalesOrderMap=New Map<Id,Sales_Line__c>();
        SalesOrderMap.put(SalesLineRecord.Id,SalesLineRecord);
        CompanyMgmt.byPassTrigger = false;
        SalesOrderTriggersMgt.SLInsertUpdate(SalesLineList,SalesOrderMap);
        
    }  
    private static testMethod void Test_SalesLine1() {
        Sales_Line__c SalesLineRecord = TestDataUtil.SalesEquipmentLineRecord;
        
        //Sales_Line__c SalesLineRecord=TestDataUtil.SalesLineRecord;
        SalesLineRecord.Quote_Line__c = SalesLineRecord.Id;
        List<Sales_Line__c>SalesLineList=New List<Sales_Line__c>();
        SalesLineList.add(SalesLineRecord);
        Map<Id,Sales_Line__c>SalesOrderMap=New Map<Id,Sales_Line__c>();
        SalesOrderMap.put(SalesLineRecord.Id,SalesLineRecord);
        CompanyMgmt.byPassTrigger = false;
        SalesOrderTriggersMgt.SLInsertUpdate(SalesLineList,SalesOrderMap);
        
    }  
    private static testMethod void Test_SalesLine2() {
        Sales_Line__c SalesLineRecord = TestDataUtil.SalesWasteLineRecord;
        
        //Sales_Line__c SalesLineRecord=TestDataUtil.SalesLineRecord;
        SalesLineRecord.Quote_Line__c = SalesLineRecord.Id;
        List<Sales_Line__c>SalesLineList=New List<Sales_Line__c>();
        SalesLineList.add(SalesLineRecord);
        Map<Id,Sales_Line__c>SalesOrderMap=New Map<Id,Sales_Line__c>();
        SalesOrderMap.put(SalesLineRecord.Id,SalesLineRecord);
        CompanyMgmt.byPassTrigger = false;
        SalesOrderTriggersMgt.SLInsertUpdate(SalesLineList,SalesOrderMap);
        
    }  
    
    private static testMethod void Test_SalesOrderTriggersMgt1() {
        
        Test.startTest();
        Sales_Order__c SalesOrderRecord=TestDataUtil.SalesOrderRecord;
        SalesOrderRecord.Name = null;
        Service_Center__c serviceCenter = new Service_Center__c();
        serviceCenter.Id = SalesOrderRecord.Service_Center__c;
        SalesOrderRecord.Service_Center__c = null;
        SalesOrderRecord.Include_Weekend__c = true;
        List<Sales_Order__c>SalesOrderList=New List<Sales_Order__c>();
        SalesOrderList.add(SalesOrderRecord);
        Map<Id,Sales_Order__c>SalesOrderMap=New Map<Id,Sales_Order__c>();
        SalesOrderMap.put(SalesOrderRecord.Id,SalesOrderRecord);
        try{
            SalesOrderTriggersMgt.SOInsertUpdate(SalesOrderList,SalesOrderMap,True);
            
        }catch(Exception e){
            
        }
        serviceCenter.Blocked__c = true;
        update serviceCenter;
        SalesOrderRecord.Service_Center__c = serviceCenter.Id;
        try{
            SalesOrderTriggersMgt.SOInsertUpdate(SalesOrderList,SalesOrderMap,True);
            
        }catch(Exception e){
            
        }
        serviceCenter.Blocked__c = false;
        //serviceCenter.Sales_Order_No_Series__c = null;
        update serviceCenter;
        try{
            SalesOrderTriggersMgt.SOInsertUpdate(SalesOrderList,SalesOrderMap,True);
            
        }catch(Exception e){
            
        }
        Test.stoptest();
    }
    private static testMethod void Test_SalesLineUOMQuantity() {
        Sales_Order__c obj=New Sales_Order__c(); 
        Sales_Line__c SalesLineRecord = TestDataUtil.SalesEquipmentLineRecord;
        obj.Id = SalesLineRecord.Sales_Order__c;
        obj.Document_Type__c = 'Sales Quote';
        obj.Is_New_D365_Project__c = false;
        update obj;
        obj.D365_Project_ID__c = 'P302.56112';
        update obj;
        SalesLineRecord.Quote_Line__c = SalesLineRecord.Id;
        SalesLineRecord.UOM_Qty__c = null;
        SalesLineRecord.Quantity__c = 0;
        SalesLineRecord.Unit_of_Measure__c = null;
        List<Sales_Line__c>SalesLineList=New List<Sales_Line__c>();
        SalesLineList.add(SalesLineRecord);
        Map<Id,Sales_Line__c>SalesOrderMap=New Map<Id,Sales_Line__c>();
        SalesOrderMap.put(SalesLineRecord.Id,SalesLineRecord);
        CompanyMgmt.byPassTrigger = false;
        SalesOrderTriggersMgt.SLInsertUpdate(SalesLineList,SalesOrderMap);
        try{
            delete obj; 
        }Catch(Exception e){}
    }
}