@isTest
public class CompanyTriggerMgmtTest {

    @testSetup static void SetupData() {
        Company_Setup__c testCompanySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c testNumberSerRecord = TestDataUtil.NumberingSeriesRecord;
        GL_Batch__c testGLBatchRecord = TestDataUtil.GLBatchRecord;
        GL_Entry__c testGLEntryRecord = TestDataUtil.GLEntryRecord;
        GL_Account__c testGLAccountRecord = TestDataUtil.GLAccountRecord;
    }
    private static testMethod void Test_CompanyTriggerMgmt() {

        Company_Setup__c CompanySetup = [SELECT Id, Allow_Posting_From__c,Allow_Posting_To__c FROM Company_Setup__c Limit 1];
        List<Company_Setup__c>companySetupList=New List<Company_Setup__c>();
        companySetupList.add(companySetup);
        Map<Id, Company_Setup__c>companySetupMap=New Map<Id, Company_Setup__c>();
        companySetupMap.put(companySetup.id,companySetup);
        CompanyTriggerMgmt.CSInsertUpdate(companySetupList,True,companySetupMap);
        CompanyTriggerMgmt.CSInsertUpdate(companySetupList,False,companySetupMap);

        CompanyTriggerMgmt.CSDelete(companySetupList);

        GL_Batch__c GLBatchRecord =[SELECT Id, No_of_Lines__c, Sync_d__c, Closed__c FROM GL_Batch__c Limit 1];
        List<GL_Batch__c>GLBatchList=New List<GL_Batch__c>();
        GLBatchList.add(GLBatchRecord);
        CompanyTriggerMgmt.GLB_D(GLBatchList);
		GL_Entry__c testGLEntryRecord = [SELECT Id FROM GL_Entry__c Limit 1];
        List<GL_Entry__c>GLList=New List<GL_Entry__c>();
        GLList.add(testGLEntryRecord);
        CompanyTriggerMgmt.GL_I_U_Trigger(GLList);
        CompanyTriggerMgmt.GL_D_Trigger(GLList);
        try{
            CompanyMgmt.systemCall = false;
            for(GL_Entry__c gle:GLList){
                gle.Amount__c = 200;
                update gle;
                throw new myException('You are not allowed to modify General Ledger Entry.!');
            }
        } catch (Exception e){
            Boolean expectedResult = e.getMessage().contains('You are not allowed to modify General Ledger Entry.')?true:false;
            System.assertEquals(expectedResult, true);
        }
        GL_Account__c testGLAccountRecord = [SELECT Id, No_of_Lines__c FROM GL_Account__c Limit 1];
        List<GL_Account__c> theGLAList=New List<GL_Account__c>();
        theGLAList.add(testGLAccountRecord);
        CompanyTriggerMgmt.GLA_D(theGLAList);

    }

}