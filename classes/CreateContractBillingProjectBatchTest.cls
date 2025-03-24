@isTest
private class CreateContractBillingProjectBatchTest {
     @testSetup
    static void setupTestData() {
        // Create test data for the Contract object
        Subsidiary_Company__c subsidiaryCompany = new Subsidiary_Company__c(Name='1-REPUBLIC SERVICES');
        insert subsidiaryCompany;
        Service_Center__c serviceCenter = new Service_Center__c(Name='12', Code__c='12345', Subsidiary_Company__c=subsidiaryCompany.id, Include_SO_in_EQAI_Invoice_Integration__c = true);
        insert serviceCenter;
        Salesperson__c salesPerson = new SalesPerson__c(Name='Salesperson1', Salesperson_Code__c='1', Status__c='Active');
        insert salesPerson;
        Account acc = new Account(name ='Test Account',PO_Number_Type__c ='NUMERICAL', AccountNumber='123dfsa', Subsidiary_Company__c=subsidiaryCompany.id);
        insert acc;

        List<Contract> testContracts = new List<Contract>();
        for(Integer i=0; i<1; i++) {
            testContracts.add(new Contract(
                Status = 'Draft',
                Name = 'Test '+i,
                StartDate = Date.newInstance(2024, 2, 28),
                Surcharge_Type__c = 'EEC Fee',
                AccountId = acc.id,
                Subsidiary__c = '1-REPUBLIC SERVICES'
            ));
        }
        insert testContracts;

        for (Contract c: testContracts) {
            c.Status = 'Activated';
        }
        update testContracts;

    }

    @isTest
    static void testBatchExecution() {
        // Start the batch job as a different user to avoid recursion
        Test.startTest();

        // Run the batch job as a specific user
        System.runAs(new User(Id = UserInfo.getUserId())) {
            CreateContractBillingProjectBatch batchJob = new CreateContractBillingProjectBatch();
            Database.executeBatch(batchJob);
        }

        Test.stopTest();

        // Add assertions or queries to verify the expected results
        // ... (existing assertions)
    }
}