@isTest
public class DeleteGsLogsTest {
    
    @isTest
    public static void verifyDeleteLogs(){
        insert new rdnacadence__Logger__c(
            rdnacadence__Description__c = 'test'
        );

        Test.startTest();
        Database.executeBatch(new DeleteGsLogs(), 200);
        Test.stopTest();

        System.assertEquals(0, [SELECT count() FROM rdnacadence__Logger__c]);
    }   
}