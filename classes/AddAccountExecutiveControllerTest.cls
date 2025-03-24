/*************************************************************************************************
* Name         :  AddAccountExecutiveControllerTest 
* Description  :  Test Class for AddAccountExecutiveController
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Pavithra P				08-21-2024             US124701 : [Continued] [Continued] [Unplanned] - Update - Salesforce Assign Multiple Salespeople to an Account and Sales Orders
*************************************************************************************************/

@isTest
public class AddAccountExecutiveControllerTest {
    // Test setup method to create test data
    @testSetup
    static void setupData() {
        List<Salesperson__c> salespersons = new List<Salesperson__c>();
        for (Integer i = 0; i < 3; i++) {
            // Generate a single character for Salesperson code
            String salespersonCode = String.fromCharArray(new List<Integer>{65 + i});
            salespersons.add(new Salesperson__c(Name = 'Salesperson ' + i,Salesperson_Code__c = salespersonCode ,Status__c='Active'));
        }
        insert salespersons;
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
    }
    
    // Test method to verify adding multiple Account Executives
    @isTest
    static void testAddMultipleAccountExecutives() {
        // Fetch the test Account and Salespersons created in testsetup
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<Salesperson__c> salespersons = [SELECT Id FROM Salesperson__c];
        
        // Prepare a string of salesperson IDs
        String salesPersonIds = String.join(new List<String> { salespersons[0].Id, salespersons[1].Id }, ',');
        Test.startTest();
        AddAccountExecutiveController.addMultipleAccountExecutives(testAccount.Id, salesPersonIds);
        Test.stopTest();
             
        Account updatedAccount = [SELECT Id, Account_Executives__c, Account_Executive_ids__c FROM Account WHERE Id = :testAccount.Id];
        System.assertNotEquals(null, updatedAccount.Account_Executives__c, 'Account Executives field should not be null');
        System.assertEquals(salesPersonIds, updatedAccount.Account_Executive_ids__c, 'Account Executive Ids should match the input');
    }
    
    // Test Method to verify when null value is provided for Account Executives
    @isTest
    static void testAddMultipleAccountExecutivesWithNull() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        AddAccountExecutiveController.addMultipleAccountExecutives(testAccount.Id, null);
        Test.stopTest();
        
        Account updatedAccount = [SELECT Id, Account_Executives__c, Account_Executive_ids__c FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(null, updatedAccount.Account_Executives__c, 'Account Executives field should be null');
        System.assertEquals(null, updatedAccount.Account_Executive_ids__c, 'Account Executive Ids should be null');
    }
    
    // Test Method to verify retrieving Account Executives
    @isTest
    static void testGetAccountExecutives() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<Salesperson__c> salespersons = [SELECT Id FROM Salesperson__c];
        
        // Set Account Executive IDs to the Account
        String salesPersonIds = String.join(new List<String> { salespersons[0].Id, salespersons[1].Id }, ',');
        testAccount.Account_Executive_ids__c = salesPersonIds;
        update testAccount;
        
        Test.startTest();
        List<Salesperson__c> accountExecutives = AddAccountExecutiveController.getAccountExecutives(testAccount.Id);
        Test.stopTest();
        
        System.assertEquals(2, accountExecutives.size(), 'There should be 2 Account Executives');
    }
    
    // Test method to verify when there are no Account Executives
    @isTest
    static void testGetAccountExecutivesWithNoExecutives() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        List<Salesperson__c> accountExecutives = AddAccountExecutiveController.getAccountExecutives(testAccount.Id);
        Test.stopTest();
        
        System.assertEquals(0, accountExecutives.size(), 'There should be no Account Executives');
    }
}