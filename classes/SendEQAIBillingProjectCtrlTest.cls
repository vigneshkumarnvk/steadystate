@isTest
public class SendEQAIBillingProjectCtrlTest {

     private static testMethod void Test_SalesOrderMgmt() {
         
		Contact cont = new Contact();
		cont.FirstName = 'test';
		cont.LastName = 'test';
		cont.AccountId = TestDataUtil.customerAccountRecord.id;
		cont.Contact_Type__c = 'Billing';
		insert cont;
         
          Contract contractRecord = new Contract (
                Name = 'Test ContractRecord',
                AccountId = TestDataUtil.customerAccountRecord.id,
                StartDate = Date.today().addDays(-200),
                Subsidiary__c = '1-REPUBLIC SERVICES',
                Status = 'Draft'
        );
        insert contractRecord ;
         SendEQAIBillingProjectCtrl.sendBillingProjectToEQAI(contractRecord.Id);
     }
    
    private static testMethod void testContractServiceException(){
        
        Test.startTest();
        SendEQAIBillingProjectCtrl.insertErrorLog('TEST_ERROR','InvalidId_Erro',93,'prinstrace','Request');
        Test.stopTest(); //Test
        List<cwbtool__ErrorLog__c> errorlogs = [SELECT Id FROM cwbtool__ErrorLog__c];
        System.assertEquals(true,errorlogs.size()>0);
    }
}