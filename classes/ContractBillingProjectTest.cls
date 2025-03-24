@IsTest
public class ContractBillingProjectTest {
   
    @IsTest
    private static void testContractService1(){
        Subsidiary_Company__c subC = new Subsidiary_Company__c(
            Name = '1-ACV ENVIRO',
            Display_Name__c = '081223'
        );
        insert subC;
        Account corporate = TestDataUtil.corporateAccountRecord;
        corporate.Subsidiary_Company__c = subC.Id;
        corporate.Invoice_Submission_Channels__c ='EMAIL';
        update corporate;
        Contract contract = new Contract();
        contract.AccountId = corporate.Id;
        contract.Status = 'Draft';
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        contract.Subsidiary__c = '1-ACV ENVIRO';
        insert contract;
        contract.Surcharge_Type__c = 'EEC Fee';
        contract.Status ='Activated';
        Test.startTest();
          Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
         try{
         update contract;   
        }
        catch(Exception e){
            
        }
         
        Test.stopTest();
    }
      @IsTest
    private static void testContractService2(){
        Subsidiary_Company__c subC = new Subsidiary_Company__c(
            Name = '1-ACV ENVIRO',
            Display_Name__c = '081223'
        );
        insert subC;
        Account corporate = TestDataUtil.corporateAccountRecord;
        corporate.Subsidiary_Company__c = subC.Id;
        corporate.Invoice_Submission_Channels__c ='HARD_COPY_SUBMITTAL';
        corporate.PO_Number_Type__c = 'ALPHANUMERICAL';
        update corporate;
        Contract contract = new Contract();
        contract.AccountId = corporate.Id;
        contract.Status = 'Draft';
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        contract.Subsidiary__c = '1-ACV ENVIRO';
        insert contract;
        contract.Surcharge_Type__c = 'EEC Fee';
        contract.Status ='Activated';
        Test.startTest();
          Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
         try{
         update contract;   
        }
        catch(Exception e){
            
        }
         
        Test.stopTest();
    }
     @IsTest
    private static void testContractService5(){
        Subsidiary_Company__c subC = new Subsidiary_Company__c(
            Name = '1-ACV ENVIRO',
            Display_Name__c = '081223'
        );
        insert subC;
        Account corporate = TestDataUtil.corporateAccountRecord;
        corporate.Subsidiary_Company__c = subC.Id;
        corporate.Invoice_Submission_Channels__c ='INVOICE_PORTAL';
        update corporate;
        Contract contract = new Contract();
        contract.AccountId = corporate.Id;
        contract.Status = 'Draft';
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        contract.Subsidiary__c = '1-ACV ENVIRO';
        insert contract;
        contract.Surcharge_Type__c = 'EEC Fee';
        contract.Status ='Activated';
        Test.startTest();
          Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
         try{
         update contract;   
        }
        catch(Exception e){
            
        }
         
        Test.stopTest();
    }
    @IsTest
    private static void testContractServiceException(){
        
        Test.startTest();
        ContractBillingProjectServiceQueueable.insertErrorLog('TEST_ERROR','InvalidId_Erro',93,'prinstrace','Request');
        Test.stopTest();
        List<cwbtool__ErrorLog__c> errorlogs = [SELECT Id FROM cwbtool__ErrorLog__c];
        System.assertEquals(true,errorlogs.size()>0);//assertion
    }
    
    @IsTest
    private static void testCreateCaseWithParentId(){  
         Subsidiary_Company__c subC = new Subsidiary_Company__c(
            Name = '1-ACV ENVIRO',
            Display_Name__c = '081223'
        );
        insert subC;
        Account corporate = TestDataUtil.corporateAccountRecord;
        corporate.Subsidiary_Company__c = subC.Id;
        corporate.Invoice_Submission_Channels__c ='INVOICE_PORTAL';
        corporate.PO_Number_Type__c = 'ALPHANUMERICAL';
        update corporate;
        Contact testContact = TestDataUtil.Contact2Record;
        testContact.AccountId = corporate.Id;
        update testContact;
        Contract contract = new Contract();
        contract.AccountId = corporate.Id;
        contract.Status = 'Draft';
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        contract.Subsidiary__c = '1-ACV ENVIRO';
        contract.Internal_Comments__c = 'During UAT for billing project creation,several fields were found to be errors and also new requirements needed.';
        insert contract;
        
        Test.StartTest();
        Contract cotractRec = [SELECT Id,Name,Account.Invoice_Submission_Channels__c,Payment_Term__c,Payment_Term__r.EQAI_Terms_Code__c,Account.Sage_Customer_No__c,ContractNumber,CreatedDate,LastModifiedDate,Account.PO_Number_Type__c,Account.Account_Executive__c,Internal_Comments__c,Account.Salesperson__r.Territory_Code__c,
                               CreatedBy.Name,LastModifiedBy.Name,Account.Account_Executive__r.Internal_Contact__c,Account.Account_Executive__r.RSG_EIN__c,Account.Invoice_Portal__c FROM  Contract WHERE Id = :contract.Id];
        ContractBillingProjectJSON contractBillingJson = new ContractBillingProjectJSON(cotractRec,'12345678',testContact);
        ContractBillingProjectServiceQueueable.createCaseWithParentId(contract.Id,'Error','check','Request');
        ContractBillingProjectServiceQueueable.splitSuccessMessage('Error1;Error2');
        Test.StopTest();
    
    }
}