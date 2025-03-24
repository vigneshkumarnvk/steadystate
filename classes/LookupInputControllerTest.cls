@isTest
private class LookupInputControllerTest {
    private static testMethod void test() {
    
        List<Account> accts = new List<Account>();
        
        Account parent = new Account(Name = 'Parent', AccountNumber = 'PARENT', Type='Corporate');
        insert parent;
        
        Account child = new Account(Name = 'Child', AccountNumber ='CHILD', ParentId = parent.Id, Type='Customer');
        insert child;
        
        String[] fields = new String[] { 'Id', 'Name', 'AccountNumber' };
        String[] fieldsToSearch = new String[] { 'Name', 'Parent.Name' };
        String[] keyFields = new String[] { 'AccountNumber' };
            String[] filter = new String[] {'Name=\'Parent\''};
        String sorting = 'Name ASC';
        String keyword = 'parent';
        Integer fetchLimit = 5;
        LookupInputController.fetchRecords('Account', fields, fieldsToSearch, keyFields, filter, sorting, keyword, fetchLimit);
        

    }
    private static testMethod void testgetRecords() {
        NewTestData.createTestData();
        
        Test.startTest();        
        TM__c tm = [SELECT Id,Service_Center__c,Service_Center__r.Name,Service_Center__r.Description__c FROM TM__c Limit 1];
        
        String[] fields = new String[] { 'Id', 'Name', 'Description__c','Temporary__c' };
        String[] fieldsToSearch = new String[] { 'Name'};
        String[] keyFields = new String[] { 'Name' };
        String[] filter = new String[]{'Name = \'02\''};
        String sorting = 'Name ASC';
        String keyword = tm.Service_Center__r.Name;
        Integer fetchLimit = 5;
        try{
        LookupInputController.getRecords('Service_Center__c', fields, fieldsToSearch, keyFields, filter, sorting, keyword, fetchLimit,tm.Id);
        }Catch(Exception e){
            
        }
        Test.stopTest();
    }

}