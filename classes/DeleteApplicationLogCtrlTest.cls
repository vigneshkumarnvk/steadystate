/*************************************************************************************************
* Name         :  DeleteApplicationLogCtrlTest
* Description  :  Schedule the DeleteApplicationLogCtrl Batch class.
* class   :  DeleteApplicationLogCtrl

* Modification Log :
* Developer                   Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* 
*************************************************************************************************/
@istest
public class DeleteApplicationLogCtrlTest {
    
    @istest
    static void testMethodForBatch(){
        
        list<Application_Debug_Log__c> listOfApplication = new list<Application_Debug_Log__c>();
        for (Integer i = 0; i < 10; i++) {  
            Application_Debug_Log__c log = new Application_Debug_Log__c(Class_Name__c = 'testclass'+i,CreatedDate = system.Today().addDays(-40)); 
            listOfApplication.add(log);
            system.debug('log--->'+log);
        }
        insert listOfApplication;
        
        Test.startTest();
        DeleteApplicationLogCtrl batchJob = new DeleteApplicationLogCtrl();
        Database.executeBatch(batchJob, 10);   
        Test.stopTest();
        map<Id,Application_Debug_Log__c> listTOmap = new map<Id,Application_Debug_Log__c>(listOfApplication);
        list<Application_Debug_Log__c> toDelete =[SELECT id FROM Application_Debug_Log__c WHERE Id in:listTOmap.keyset()];
        system.debug('toDelete---->'+toDelete);
        Assert.areEqual(toDelete.isEmpty(), true);
    }
}