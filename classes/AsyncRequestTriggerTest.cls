@isTest
private class AsyncRequestTriggerTest {
    private static testMethod void test() {
        try {
            AsyncRequest__c asyncRequest = new AsyncRequest__c();
            asyncRequest.Name = 'TEST';
            asyncRequest.Params1__c = 'param1';
            insert asyncRequest;
        }
        catch(exception ex) {

        }
    }
}