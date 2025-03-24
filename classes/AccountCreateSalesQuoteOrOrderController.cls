/**
 * Controller shared by Create Sales Quote and Create Sales Order Custom Buttons (and related pages) on the Account
 */
public with sharing class AccountCreateSalesQuoteOrOrderController {

    private ApexPages.StandardController standardController = null;

    private ApexPages.StandardSetController standardSetController = null;

    public Account account {get; set;}

    public User user {get; set;}

    public List<SelectOption> contractOptions {get; set;}

    public String chosenContract {get; set;}

    public List<SelectOption> quoteOptions {get; set;}

    public String chosenQuote {get; set;}

    public Boolean isPlain {get;set;}

    public Boolean isAllowedToCreateSalesRecord{get; set;}

    public AccountCreateSalesQuoteOrOrderController(ApexPages.StandardController controller){
        standardController = controller;
        contractOptions = new List<SelectOption>();
        quoteOptions = new List<SelectOption>();
        initAccount();
        initUser();
        isPlain = true;
        isAllowedToCreateSalesRecord = true;
    }

    public AccountCreateSalesQuoteOrOrderController(ApexPages.StandardSetController controller) {
        standardSetController = controller;
    }

    public PageReference redirectToSalesOrderPage() {
        try {
            PageReference pageReference = Page.SalesOrder;
            pageReference.getParameters().put('billToCustomer', account.Id);
            pageReference.getParameters().put('serviceCenter', user.Service_Center__c);
            pageReference.getParameters().put('contract', chosenContract);
            pageReference.getParameters().put('quote', chosenQuote);
            if (CompanyMgmt.getVFPageName() == 'AccountCreateSalesQuote') {
                pageReference.getParameters().put('documentType', 'Sales Quote');
            } else {
                pageReference.getParameters().put('documentType', 'Sales Order');
            }
            return pageReference;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    public void initAccount(){
        List<Account> accounts = AccountsSelector.newInstance().selectParentAccountById(new Set<Id>{ ((Account)standardController.getRecord()).Id});
        account = accounts[0];
        Set<Id> accountIds = new Set<Id>();
        accountIds.add(account.Id);
        if (String.isNotEmpty(account.ParentId)) accountIds.add(account.ParentId);
        List<Contract> contracts = ContractsSelector.newInstance().selectByAccountId(accountIds);
        if (contracts.size() > 0){
            for (Contract contract : contracts) {
                contractOptions.add(new SelectOption(contract.Id, contract.Name + ' - ' + contract.ContractNumber));
            }
        }
        if (CompanyMgmt.getVFPageName() == 'AccountCreateSalesOrder' || Test.isRunningTest()){
            List<Sales_Order__c> salesQuotes = SalesOrdersSelector.newInstance().selectQuotesByBillToCustomer(account.Id);
            if (salesQuotes.size() > 0){
                for (Sales_Order__c so : salesQuotes){
                    quoteOptions.add(new SelectOption(so.Id, so.Order_Description__c + ' - ' + so.Name));
                }
            }
        }
    }

    public void initUser(){
        List<User> users = UsersSelector.newInstance().selectById(new Set<Id>{UserInfo.getUserId()});
        user = users[0];
    }

    public PageReference checkAccountContractBeforeRenderPage(){
        String docType = '';
        if (CompanyMgmt.getVFPageName() == 'AccountCreateSalesQuote') docType = 'Sales Quote';
        else docType = 'Sales Order';

        if(account.Subsidiary_Company__r.Name != '1-ACV ENVIRO'){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                    String.format('You can only create {0} from ACV Enviro customer!', new String[]{docType})));
            isAllowedToCreateSalesRecord = false;
            return null;
        }
        if (CompanyMgmt.getVFPageName() == 'AccountCreateSalesOrder'){
            if (contractOptions.size() == 0 && quoteOptions.size() == 0) return redirectToSalesOrderPage();
        } else {
            if (contractOptions.size() == 0 ) return redirectToSalesOrderPage();
        }
        return null;
    }
}