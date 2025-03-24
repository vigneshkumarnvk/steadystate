@isTest
private class SendSalesOrderToEqaiControllerTest  {
  

    @isTest
    static void testSendSalesOrderToEqai() {
            // Create a test Service Center with Include_SO_in_EQAI_Invoice_Integration__c set to true
            Subsidiary_Company__c subsidiaryCompany = new Subsidiary_Company__c(Name='Subsidiary Company1');
            insert subsidiaryCompany;
            Service_Center__c serviceCenter = new Service_Center__c(Name='12', Code__c='12345', Subsidiary_Company__c=subsidiaryCompany.id, Include_SO_in_EQAI_Invoice_Integration__c = true);
            insert serviceCenter;
            Salesperson__c salesPerson = new SalesPerson__c(Name='Salesperson1', Salesperson_Code__c='1', Status__c='Active');
            insert salesPerson;
            Account acc = new Account(name ='Test Account',PO_Number_Type__c ='NUMERICAL', AccountNumber='123dfsa', Subsidiary_Company__c=subsidiaryCompany.id);
            insert acc;
            Resource__c resource = new Resource__c(Name='TEST Resource');
            insert resource;
    
            Sales_Order__c salesOrder = new Sales_Order__c(Name='Test1');
            salesOrder.Subsidiary_Company__c = subsidiaryCompany.id;
            salesOrder.Bill_to_Customer_No__c = acc.id;
            salesOrder.Project_Coordinator__c = salesPerson.id;
            salesOrder.Service_Center__c = serviceCenter.id;
            salesOrder.Surcharge_Type__c = 'EEC Fee';
            salesOrder.SO_sent_to_EQAI__c = false;
            salesOrder.Worker_Responsible__c = '456456456';
            salesOrder.Name_of_Worker_Responsible__c = resource.id;
            salesOrder.Estimated_Job_Start_Date__c = Date.newInstance(2024, 03, 09);
            insert salesOrder;

            String result = SendSalesOrderToEqaiController.sendSalesOrderToEQAI(salesOrder.Id);
    
        }

    @isTest
    static void testSendSalesOrderToEqaiSCfalse() {
            // Create a test Service Center with Include_SO_in_EQAI_Invoice_Integration__c set to false
            Subsidiary_Company__c subsidiaryCompany = new Subsidiary_Company__c(Name='Subsidiary Company1');
            insert subsidiaryCompany;
            Service_Center__c serviceCenter = new Service_Center__c(Name='12', Code__c='12345', Subsidiary_Company__c=subsidiaryCompany.id, Include_SO_in_EQAI_Invoice_Integration__c = false);
            insert serviceCenter;
            Salesperson__c salesPerson = new SalesPerson__c(Name='Salesperson1', Salesperson_Code__c='1', Status__c='Active');
            insert salesPerson;
            Account acc = new Account(name ='Test Account',PO_Number_Type__c ='NUMERICAL', AccountNumber='123dfsa', Subsidiary_Company__c=subsidiaryCompany.id);
            insert acc;
    
            Sales_Order__c salesOrder = new Sales_Order__c(Name='Test1');
            salesOrder.Subsidiary_Company__c = subsidiaryCompany.id;
            salesOrder.Bill_to_Customer_No__c = acc.id;
            salesOrder.Project_Coordinator__c = salesPerson.id;
            salesOrder.Service_Center__c = serviceCenter.id;
            salesOrder.Surcharge_Type__c = 'EEC Fee';
            insert salesOrder;
    
            Test.startTest();
            String result = SendSalesOrderToEqaiController.sendSalesOrderToEQAI(salesOrder.Id);
            Test.stopTest();
    
        }

     @isTest
    static void testSendSalesOrderToEqaiSOsentToEqaiTrue() {
            // Create a test Service Center with Include_SO_in_EQAI_Invoice_Integration__c set to true and SO_sent_to_EQAI__c = true
            Subsidiary_Company__c subsidiaryCompany = new Subsidiary_Company__c(Name='Subsidiary Company1');
            insert subsidiaryCompany;
            Service_Center__c serviceCenter = new Service_Center__c(Name='12', Code__c='12345', Subsidiary_Company__c=subsidiaryCompany.id, Include_SO_in_EQAI_Invoice_Integration__c = true);
            insert serviceCenter;
            Salesperson__c salesPerson = new SalesPerson__c(Name='Salesperson1', Salesperson_Code__c='1', Status__c='Active');
            insert salesPerson;
            Account acc = new Account(name ='Test Account',PO_Number_Type__c ='NUMERICAL', AccountNumber='123dfsa', Subsidiary_Company__c=subsidiaryCompany.id);
            insert acc;

            Sales_Order__c salesOrder = new Sales_Order__c(Name='Test1');
            salesOrder.Subsidiary_Company__c = subsidiaryCompany.id;
            salesOrder.Bill_to_Customer_No__c = acc.id;
            salesOrder.Project_Coordinator__c = salesPerson.id;
            salesOrder.Service_Center__c = serviceCenter.id;
            salesOrder.Surcharge_Type__c = 'EEC Fee';
            salesOrder.SO_sent_to_EQAI__c = true;
            insert salesOrder;

            Test.startTest();
            String result = SendSalesOrderToEqaiController.sendSalesOrderToEQAI(salesOrder.Id);
            Test.stopTest(); //test

        }

        @isTest
        static void testSendSalesOrderToEqaiRequiredFieldsAreNull() {
            // Create a test Service Center with Include_SO_in_EQAI_Invoice_Integration__c set to true and Worker Responsible is null
            Subsidiary_Company__c subsidiaryCompany = new Subsidiary_Company__c(Name='Subsidiary Company1');
            insert subsidiaryCompany;
            Service_Center__c serviceCenter = new Service_Center__c(Name='12', Code__c='12345', Subsidiary_Company__c=subsidiaryCompany.id, Include_SO_in_EQAI_Invoice_Integration__c = true);
            insert serviceCenter;
            Salesperson__c salesPerson = new SalesPerson__c(Name='Salesperson1', Salesperson_Code__c='1', Status__c='Active');
            insert salesPerson;
            Account acc = new Account(name ='Test Account',PO_Number_Type__c ='NUMERICAL', AccountNumber='123dfsa', Subsidiary_Company__c=subsidiaryCompany.id);
            insert acc;

            Sales_Order__c salesOrder = new Sales_Order__c(Name='Test1');
            salesOrder.Subsidiary_Company__c = subsidiaryCompany.id;
            salesOrder.Bill_to_Customer_No__c = acc.id;
            salesOrder.Project_Coordinator__c = salesPerson.id;
            salesOrder.Service_Center__c = serviceCenter.id;
            salesOrder.Surcharge_Type__c = 'EEC Fee';
            SalesOrder.Worker_Responsible__c = null;
            insert salesOrder;

            Test.startTest();
            String result = SendSalesOrderToEqaiController.sendSalesOrderToEQAI(salesOrder.Id);
            Test.stopTest();
    
            }

     
}