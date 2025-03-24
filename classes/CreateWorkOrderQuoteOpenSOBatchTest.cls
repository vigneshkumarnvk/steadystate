@isTest
public class CreateWorkOrderQuoteOpenSOBatchTest {

    @isTest
    static void testBatchExecution() {
        // Create test data - Sales Order with Document_Status__c = 'Open'
        
        Subsidiary_Company__c subsidiaryCompany = new Subsidiary_Company__c(Name='Subsidiary Company1');
        insert subsidiaryCompany;
        Service_Center__c serviceCenter = new Service_Center__c(Name='12', Code__c='12345', Subsidiary_Company__c=subsidiaryCompany.id, Include_SO_in_EQAI_Invoice_Integration__c = true);
        insert serviceCenter;
        Salesperson__c salesPerson = new SalesPerson__c(Name='Salesperson1', Salesperson_Code__c='1', Status__c='Active');
        insert salesPerson;
        Account acc = new Account(name ='Test Account',PO_Number_Type__c ='NUMERICAL', AccountNumber='123dfsa', Subsidiary_Company__c=subsidiaryCompany.id);
        insert acc;

        Sales_Order__c salesOrder1 = new Sales_Order__c(Name='Test1');
        salesOrder1.Document_Status__c = 'Open';
        salesOrder1.Subsidiary_Company__c = subsidiaryCompany.id;
        salesOrder1.Bill_to_Customer_No__c = acc.id;
        salesOrder1.Project_Coordinator__c = salesPerson.id;
        salesOrder1.Service_Center__c = serviceCenter.id;
        salesOrder1.Surcharge_Type__c = 'EEC Fee';
        insert salesOrder1;

        // Start the batch
        Test.startTest();
        CreateWorkOrderQuoteOpenSOBatch batchClass = new CreateWorkOrderQuoteOpenSOBatch();
        Database.executeBatch(batchClass);
        Test.stopTest();

        // Perform assertions based on your expected outcomes
        // For example, check if the Queueable job has been enqueued successfully
        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable' LIMIT 1];
        System.assertNotEquals(0, jobs.size(), 'Queueable job should be enqueued');
    }
}
