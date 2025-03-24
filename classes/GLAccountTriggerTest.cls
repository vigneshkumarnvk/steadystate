/**
 * Created by Steven on 6/15/2018.
 */
@IsTest
public with sharing class GLAccountTriggerTest {
    public static testMethod void test(){
        GL_Account__c gla = new GL_Account__c(Name='10000', Description__c='Test Account');
        insert gla;

        Subsidiary_Company__c sbc = new Subsidiary_Company__c(Name='Test Sub');
        insert sbc;

        GL_Batch__c glb = new GL_Batch__c(Description__c='Test Batch', Subsidiary_Company__c=sbc.Id);
        insert glb;

        GL_Entry__c gle2 = new GL_Entry__c(Account_Type__c='Customer', Document_Date__c=Date.today(), Document_No__c='Test Doc 1', Document_Type__c='Invoice',
                                            GL_Account__c = gla.Id, GL_Batch__c = glb.Id, Posting_Date__c=Date.today(), Amount__c = 1000);

        try{
            insert gle2;
            throw new myException('Excepting You are not allowed to modify General Ledger Entry.');
        } catch (Exception e){
            Boolean testResult = e.getMessage().contains('You are not allowed to modify General Ledger Entry.')?true:false;
            System.assertEquals(testResult, true);
        }

        GL_Entry__c gle = new GL_Entry__c(Account_Type__c='Customer', Document_Date__c=Date.today(), Document_No__c='Test Doc 1', Document_Type__c='Invoice',
                GL_Account__c = gla.Id, GL_Batch__c = glb.Id, Posting_Date__c=Date.today(), Amount__c = 1000);

        CompanyMgmt.systemCall = true;
        insert gle;

        try{
            delete glb;
            throw new myException('Excepting You cannot delete GL Batch because it is used on GL Entry! error message but was not');
        } catch (Exception e){
            Boolean testResult = e.getMessage().contains('You cannot delete GL Batch because it is used on GL Entry!')?true:false;
            System.assertEquals(testResult, true);
        }

        try{
            CompanyMgmt.allowToDeleteData = false;
            CompanyMgmt.systemCall = false;
            delete gle;
            throw  new myException('Excepting You are not allowed to delete General Ledger Entry. error message but was not');
        } catch (Exception e){
            Boolean testResult = e.getMessage().contains('You are not allowed to delete General Ledger Entry.')?true:false;
            System.assertEquals(testResult,true);
        }

        try {
            delete gla;
            throw new myException('You cannot delete GL Account because it is used on GL Entry! error message but was not!');
        } catch (Exception e){
            Boolean testResult = e.getMessage().contains('You cannot delete GL Account because it is used on GL Entry!')?true:false;
            System.assertEquals(testResult, true);
        }

        GL_Batch__c glb2 = new GL_Batch__c(Description__c='Test Batch 2', Subsidiary_Company__c=sbc.Id, Sync_d__c = true);
        insert glb2;
        try{
            delete glb2;
            throw new myException('You cannot delete GL Batch because it is Integrated! error message but was not');
        } catch (Exception e){
            Boolean testResult = e.getMessage().contains('You cannot delete GL Batch because it is Integrated!')?true:false;
            System.assertEquals(testResult, true);
        }

        GL_Batch__c glb3 = new GL_Batch__c(Description__c='Test Batch 3', Subsidiary_Company__c=sbc.Id, Closed__c = true);
        insert glb3;
        try{
            delete glb3;
            throw new myException('You cannot delete GL Batch because it is Closed! error message but was not');
        } catch (Exception e){
            Boolean testResult = e.getMessage().contains('You cannot delete GL Batch because it is Closed!')?true:false;
            System.assertEquals(testResult, true);
        }
    }
}