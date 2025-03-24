@IsTest
private class AccountsTest {

    @IsTest
    private static void test(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IAccounts domainAccountMock = new Mocks.Accounts(mocks);
        Account a = new Account(
                Id = fflib_IDGenerator.generate(Account.SObjectType),
                Name = 'Test'
        );
        IAccounts domainAccount = Accounts.newInstance(new List<Account>{a});
    }

    @IsTest
    private static void testSelectors(){
        Account customerAccount = TestDataUtil.customerAccountRecord;
        List<Account> accounts = AccountsSelector.newInstance().selectTaxAreaNameById(new Set<Id>{customerAccount.Id});
        accounts = AccountsSelector.newInstance().selectSubsidiaryCompInfoById(new Set<Id>{customerAccount.Id});
        accounts = AccountsSelector.newInstance().selectParentAccountById(new Set<Id>{customerAccount.Id});
        accounts = AccountsSelector.newInstance().selectById(new Set<Id>{customerAccount.Id});
        accounts = AccountsSelector.newInstance().selectBillingInstructionsById(new Set<Id>{customerAccount.Id});
    }

    @IsTest
    private static void testAccountService(){
        Account customerAccount = TestDataUtil.customerAccountRecord;
        customerAccount.PO_Number_Type__c = AccountsService.PO_FORMAT_ALPHANUMERICAL;
        customerAccount.Invoice_Backup_Documents__c = AccountsService.INVOICE_BACKUP_TYPE_INVOICE;
        customerAccount.Invoice_Email_Contact_Types__c = AccountsService.INVOICE_EMAIL_CONTACT_TYPE_AP;
        customerAccount.Invoice_Email_Contact_Types__c = AccountsService.INVOICE_EMAIL_CONTACT_TYPE_EXECUTIVE;
        customerAccount.Invoice_Email_Contact_Types__c = AccountsService.INVOICE_EMAIL_CONTACT_TYPE_PURCHASE;
        customerAccount.Invoice_Email_Contact_Types__c = AccountsService.INVOICE_EMAIL_CONTACT_TYPE_QUOTE;
        customerAccount.Invoice_Email_Contact_Types__c = AccountsService.INVOICE_EMAIL_CONTACT_TYPE_SALES;
        customerAccount.Invoice_Email_Contact_Types__c = AccountsService.INVOICE_EMAIL_CONTACT_TYPE_SITE;
        customerAccount.Invoice_Submission_Channels__c = AccountsService.INVOICE_SUBMISSION_CHANNEL_EMAIL;
        update customerAccount;

        String poNumber = 'ABC1234';
        try{
            AccountsService.validatePONumberFormat(customerAccount, poNumber);
        } catch (Exception e){

        }

        poNumber = 'ABC';
        try{
            AccountsService.validatePONumberFormat(customerAccount, poNumber);
        } catch (Exception e){

        }

        poNumber = 'ABCDEFGHI ';
        try{
            AccountsService.validatePONumberFormat(customerAccount, poNumber);
        } catch (Exception e){

        }

        customerAccount.PO_Number_Type__c = AccountsService.PO_FORMAT_NUMERICAL;
        try{
            AccountsService.validatePONumberFormat(customerAccount, poNumber);
        } catch (Exception e){

        }
        //test
        poNumber = '123-123';
        try{
            AccountsService.validatePONumberFormat(customerAccount, poNumber);
        } catch (Exception e){

        }

        customerAccount.PO_Number_Type__c = AccountsService.PO_FORMAT_NAME_OF_CONTACT;
        try{
            AccountsService.validatePONumberFormat(customerAccount, poNumber);
        } catch (Exception e){

        }

        poNumber = 'Test Name';
        try{
            AccountsService.validatePONumberFormat(customerAccount, poNumber);
        } catch (Exception e){

        }

        customerAccount.Invoice_Submission_Channels__c = AccountsService.INVOICE_SUBMISSION_CHANNEL_MAIL;
        customerAccount.Invoice_Backup_Documents__c = AccountsService.INVOICE_BACKUP_TYPE_CERTIFIED_PAYROLL;
        customerAccount.Invoice_Backup_Documents__c = AccountsService.INVOICE_BACKUP_TYPE_MANIFEST_WEIGHT_TICKET;
        customerAccount.Invoice_Backup_Documents__c = AccountsService.INVOICE_BACKUP_TYPE_MARK_UP_VENDOR_INVOICE_OR_RECEIPT;
        customerAccount.Invoice_Backup_Documents__c = AccountsService.INVOICE_BACKUP_TYPE_SPILL_REPORT_WITH_PICTURES;
        //customerAccount.Invoice_Backup_Documents__c = AccountsService.INVOICE_BACKUP_TYPE_TM;
        update customerAccount;
        customerAccount.Invoice_Submission_Channels__c = AccountsService.INVOICE_SUBMISSION_CHANNEL_INVOICE_PORTAL;
        customerAccount.Invoice_Portal__c = 'www.test.com';
        customerAccount.Invoice_Backup_Documents__c = AccountsService.INVOICE_BACKUP_TYPE_CUSTOMER_SPECIFIC_DOCUMENTATION;
        customerAccount.Customer_Specific_Documentation__c = 'Test Backup Type';
        String tempBillingDescription = AccountsService.generateCustomerBillingVerbose(
                customerAccount.PO_Number_Type__c,
                customerAccount.Invoice_Email_Contact_Types__c,
                customerAccount.Invoice_Submission_Channels__c,
                customerAccount.Invoice_Portal__c,
                customerAccount.Invoice_Backup_Documents__c,
                customerAccount.Customer_Specific_Documentation__c
        );

        customerAccount.Customer_Billing_Instructions__c = 'test customer billing instruction!';
        customerAccount.Billing_Instructions__c = 'test billing instruction!';
        String customerDescription = AccountsService.generateCustomerBillingInstructions(customerAccount);
        
        Account pros = new Account(Name = 'CORP', Type = 'Vendor');
        insert pros;
        
        Account prosp = new Account(Name = 'CORP', Type = 'Prospect');
        insert prosp;
        //test123
        Account cust = new Account(Name = 'CORP', Type = 'Customer', BillingStreet = 'Test Billing Street', Customer_Specific_Documentation__c = 'Test CSD',Billing_Instructions__c='Test BI');
        insert cust;
         
    }
    //test
}