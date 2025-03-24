/*
* Class Name: SalesOrders
* Summary  : 

* Modification Log :
* Developer                 Date                   Description
--------------------------------------------------------------------------------------------------------------               
Sathish Rosekumar           09/04/2024              79107 - Send SF Sales Order Close Date to EQAI job level billing project
Shahwaz Khan                09/04/2024              80447 - Reopen sales order & billing project
Prabhu Rathakrishnan      06-25-2024             US116303:Salesforce - Updates to Opportunities and Sales Quotes
Prabhu Rathakrishnan        08/17/2024           US116306:Updates to Opportunities and Sales Quotes - Post Group B
*************************************************************************************************************/
public class SalesOrders extends fflib_SObjectDomain implements ISalesOrders{

    public static Map<Id, Sales_Order__c> fromSalesQuoteByIds = new Map<Id, Sales_Order__c>(); //W-000405
    public static Map<Id, Contract> contractsByIds = new Map<Id, Contract>(); //W-000405
    //Ticket#15868 - Not allow to convert none-er quote for ER customer
    public static Map<Id, Sales_Order_Type__c> salesOrderTypesByIds = new Map<Id, Sales_Order_Type__c>();
    public static Map<Id, Account> billToCustomersByIds = new Map<Id, Account>();

    public static ISalesOrders newInstance(List<Sales_Order__c> sObjectList){
        return (ISalesOrders) Application.Domain.newInstance(sObjectList);
    }

    public SalesOrders(List<Sales_Order__c> sObjectList){
        super(sObjectList);
    }
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct (List<SObject> sObjectList){
            return new SalesOrders(sObjectList);
        }
    }

    public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
        List<Sales_Order__c> newList = (List<Sales_Order__c>) Records;
        Map<Id, Sales_Order__c> oldMap = (Map<Id, Sales_Order__c>) existingRecords;
        Set<Id> soIds = new Set<Id>();
        Set<Id> approvalSalesRecordIds = new Set<Id>();
        Set<Id> reOpenSaleOrderIds = new Set<Id>();
        Set<Id> saleOrderIds = new Set<Id>();
        Set<Id> salesRecordsApprovalRequestNeedToBeReassigned = new Set<Id>();
        Map<Id ,String> poToUpdateBySOIds = new Map<Id, String>();
        for (Sales_Order__c theSO : newList) {
            //Task#79107
            if (theSO.Document_Status__c != oldMap.get(theSO.Id).Document_Status__c && theSO.Document_Status__c =='Closed' && oldMap.get(theSO.Id).Document_Status__c == 'Open')
            {
                saleOrderIds.add(theSO.Id);
            }
            //Task#80447
            if (theSO.Document_Status__c != oldMap.get(theSO.Id).Document_Status__c && theSO.Document_Status__c =='Open' && oldMap.get(theSO.Id).Document_Status__c == 'Closed') 
            {
                reOpenSaleOrderIds.add(theSO.Id);
            }
            if (theSO.Customer_PO_No__c != oldMap.get(theSO.Id).Customer_PO_No__c) {
                soIds.add(theSO.Id);
                poToUpdateBySOIds.put(theSO.Id, theSO.Customer_PO_No__c);
            }

            if(theSO.Approval_Step_Completed__c == true && theSO.Approval_Status__c == EnumUtil.ApprovalStatus.PENDING_APPROVAL.name())
                approvalSalesRecordIds.add(theSO.Id);

            if(theSO.Approval_Status__c == EnumUtil.ApprovalStatus.PENDING_APPROVAL.name() && theSO.Get_Next_Approver__c == true){
                //System.debug('Info: salesRecordsApprovalRequestNeedToBeReassigned ' + salesRecordsApprovalRequestNeedToBeReassigned.size());
                salesRecordsApprovalRequestNeedToBeReassigned.add(theSO.Id);
            }
        }
        //Task#80447 //Task#79107
        if(saleOrderIds.size()>0){
            //SFJobBillingProjectService.updateCloseDateInSalesOrderInfo(saleOrderIds); 
        }
       /* if(reOpenSaleOrderIds.size()>0){
            SFJobBillingProjectService.reOpenSalesOrderInfo(reOpenSaleOrderIds); 
        }*/
        if(soIds.size() > 0 || approvalSalesRecordIds.size() > 0 || salesRecordsApprovalRequestNeedToBeReassigned.size() > 0){
            fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
            if(soIds.size() > 0){
                updateTMsAndSIsPONo(soIds, poToUpdateBySOIds, uow);
             }

            if((approvalSalesRecordIds.size() > 0 || salesRecordsApprovalRequestNeedToBeReassigned.size() > 0) && CompanyMgmt.approvalCall != true){
                CompanyMgmt.approvalCall = true;
                List<Sales_Order__c> salesRecordToUpdate = new List<Sales_Order__c>();
                if(approvalSalesRecordIds.size() > 0){
                    List<Sales_Order__c> salesRecords = SalesOrdersSelector.newInstance().selectById(approvalSalesRecordIds);
                    for(Sales_Order__c salesRecord:salesRecords){
                        //System.debug('Info: Trigger Approve Record!');
                        SalesRecordApprovalProcess salesRecordApprovalProcess = new SalesRecordApprovalProcess(salesRecord);
                        salesRecordApprovalProcess.approveRecord();
                            salesRecordToUpdate.add(salesRecord);
                    }
                }

                if(salesRecordsApprovalRequestNeedToBeReassigned.size() > 0){
                    //System.debug('Info: Reassign Process begin');
                    List<Sales_Order__c> salesRecordsNeedToReassign = SalesOrdersSelector.newInstance().selectById(salesRecordsApprovalRequestNeedToBeReassigned);
                    for(Sales_Order__c salesRecord : salesRecordsNeedToReassign){
                        SalesRecordApprovalProcess salesRecordApprovalProcess = new SalesRecordApprovalProcess(salesRecord);
                        salesRecordApprovalProcess.reassignApprovalRequest();
                        salesRecordToUpdate.add(salesRecord);
                    }
                }

                uow.registerDirty(salesRecordToUpdate);
            }
            // This should be call at last
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.byPassLineTrigger = true;
            uow.commitWork();
            CompanyMgmt.byPassTrigger = false;
            CompanyMgmt.byPassLineTrigger = false;
        }

    }
    public void updateTMsAndSIsPONo(Set<Id> idSet, Map<Id, String> poToUpdateBySOIds, fflib_ISObjectUnitOfWork uow){
        ITMs domainTM = TMs.newInstance(TMsSelector.newInstance().selectPOBySalesOrderId(idSet));
        domainTM.updateCustomerPONumber(poToUpdateBySOIds,uow);
        ISalesInvoices domainSI = SalesInvoices.newInstance(SalesInvoicesSelector.newInstance().selectPOBySalesOrderId(idSet));
        domainSI.updateCustomerPONumber(poToUpdateBySOIds,uow); 
    }

    public void updateConvertCountAndQuoteStatus(fflib_ISObjectUnitOfWork uow){
        for (Sales_Order__c theSO : (List<Sales_Order__c>) Records) {
            theSO.Convert_Count__c = theSO.Convert_Count__c == null ? 1 : theSO.Convert_Count__c + 1;
            theSO.Quote_Status__c = EnumUtil.QuoteStatus.WON.name();
            uow.registerDirty(theSO);
        }
    }

    //W-000405
    public void initStaticVariables(){
        Set<Id> fromSalesQuoteIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();
        Set<Id> salesOrderTypeIds = new Set<Id>(); //Ticket#15868
        Set<Id> billToCustIds = new Set<Id>(); //Ticket#15868

        for(Sales_Order__c salesRecord:(List<Sales_Order__c>) Records){
            if(salesRecord.Document_Type__c == 'Sales Order' && salesRecord.From_Sales_Quote__c != null) fromSalesQuoteIds.add(salesRecord.From_Sales_Quote__c);
            if(salesRecord.Contract__c != null) contractIds.add(salesRecord.Contract__c);
            if(salesRecord.Sales_Order_Type__c != null) salesOrderTypeIds.add(salesRecord.Sales_Order_Type__c); //Ticket#15868
            if(salesRecord.Bill_to_Customer_No__c != null) billToCustIds.add(salesRecord.Bill_to_Customer_No__c); //Ticket#15868
        }

        if(fromSalesQuoteIds.size() > 0){
            fromSalesQuoteByIds.putAll(SalesOrdersSelector.newInstance().selectById(fromSalesQuoteIds));
        }

        if(contractIds.size() > 0){
            contractsByIds.putAll(ContractsSelector.newInstance().selectById(contractIds));
        }

        if(salesOrderTypeIds.size() > 0){
            salesOrderTypesByIds = SalesOrderTypesSelector.newInstance().getSalesOrderTypesByIdsMap(salesOrderTypeIds);
        }

        if(billToCustIds.size() > 0){
            billToCustomersByIds.putAll(AccountsSelector.newInstance().selectById(billToCustIds));
        }
    }
    //W-000405 - depreciated
    /*
    public void checkBeforeClone(Id targetCustId){
        Set<Id> accountIds = new Set<Id>();
        Set<Id> accountIdsForAccountLookup = new Set<Id>();
        if(targetCustId != null){
            accountIdsForAccountLookup.add(targetCustId);
        }
        Boolean quoteExpired = false;
        Boolean contractExpired = false;
        Boolean contractDoesBelongToSelectedCust = false;
        for(Sales_Order__c salesRecord:(List<Sales_Order__c>) Records){
            String errorMsg = '';
            String htmlLineBreak = '<br />';

            if(salesRecord.Bill_to_Customer_No__c != null){
                accountIds.add(salesRecord.Bill_to_Customer_No__c);
                accountIdsForAccountLookup.add(salesRecord.Bill_to_Customer_No__c);
            }

            if(salesRecord.Bill_to_Customer_No__r.ParentId != null){
                accountIds.add(salesRecord.Bill_to_Customer_No__r.ParentId);
            }

            Map<Id, Account> accountsByIds = new Map<Id, Account>();
            if(accountIdsForAccountLookup.size() > 0){
                accountsByIds.putAll(AccountsSelector.newInstance().selectById(accountIdsForAccountLookup));
            }

            if(salesRecord.Approval_Status__c != EnumUtil.ApprovalStatus.APPROVED.name() && salesRecord.Document_Type__c != 'Sales Order'){
                errorMsg = errorMsg + 'You cannot clone this document because the selected record is not approved yet!' + htmlLineBreak;
            }

            if(salesRecord.Bill_to_Customer_No__r.Emergency__c == true && salesRecord.Sales_Order_Type__r.Emergency_Response__c != true){
                errorMsg = errorMsg + 'This customer is not approved. Only Emergency Response sales order are allowed!' + htmlLineBreak;
            }

            if(accountsByIds.containsKey(targetCustId)){
                Account targetCustomer = accountsByIds.get(targetCustId);
                if(targetCustomer.Emergency__c == true && salesRecord.Sales_Order_Type__r.Emergency_Response__c != true){
                    errorMsg = errorMsg + 'Target customer is not approved. Only Emergency Response sales order are allowed!' + htmlLineBreak;
                }
            }

            if(salesRecord.Document_Type__c == 'Sales Order') {
                if (salesRecord.From_Sales_Quote__c != null && fromSalesQuoteByIds.containsKey(salesRecord.From_Sales_Quote__c)) {
                    Sales_Order__c salesQuote = fromSalesQuoteByIds.get(salesRecord.From_Sales_Quote__c);
                    if (salesQuote.Allow_Convert__c != true) {
                        quoteExpired = true;
                    }
                }
            } else if(salesRecord.Document_Type__c == 'Sales Quote'){
                if(salesRecord.Allow_Convert__c != true){
                    quoteExpired = true;
                }
            }

            if(salesRecord.Contract__c != null && contractsByIds.containsKey(salesRecord.Contract__c)){
                Contract contract = contractsByIds.get(salesRecord.Contract__c);
                if(contract.EndDate < Date.today()){
                    contractExpired = true;
                }
                if(salesRecord.Bill_to_Customer_No__c != targetCustId) contractDoesBelongToSelectedCust = true;
            }

            String contractExpiredMsg = String.format('You cannot clone this {0} because the associated Contract has expired.',
                    new List<String>{salesRecord.Document_Type__c});

            String quoteExpiredMsg = '';
            if(salesRecord.Document_Type__c == 'Sales Order'){
                quoteExpiredMsg = 'You cannot clone this Sales Order because the associated Sales Quote has expired.';
            } else if (salesRecord.Document_Type__c == 'Sales Quote') {
                quoteExpiredMsg = 'You cannot clone this Sales Quote because it has expired.';
            }

            String contractBelongToOtherCustErrorMsg = String.format('You cannot clone this {0} because the related contract does not belong to the selected Bill To customer.',
                    new List<String>{salesRecord.Document_Type__c});

            String salesOrderTypeIsBlockedMsg = String.format('You cannot clone this {0} because the Sales Order Type is blocked.',
                    new List<String>{salesRecord.Document_Type__c});

            if(quoteExpired == true) errorMsg = errorMsg + quoteExpiredMsg + htmlLineBreak;
            if(contractExpired == true) errorMsg = errorMsg + contractExpiredMsg + htmlLineBreak;
            if(contractDoesBelongToSelectedCust == true) errorMsg = errorMsg + contractBelongToOtherCustErrorMsg + htmlLineBreak;

            if(salesRecord.Sales_Order_Type__r.Blocked__c == true) errorMsg = errorMsg + salesOrderTypeIsBlockedMsg + htmlLineBreak;

            if(errorMsg != '') throw new DataException(errorMsg);
        }

        Map<Id, Contract> activeContractByAccountId = new Map<Id, Contract>();
        for(Contract activeContract:ContractsSelector.newInstance().selectByAccountId(accountIds))
        {
            activeContractByAccountId.put(activeContract.AccountId, activeContract);
        }

        for(Sales_Order__c salesRecord:(List<Sales_Order__c>) Records){
            if(salesRecord.Contract__c == null){
                if(activeContractByAccountId.containsKey(salesRecord.Bill_to_Customer_No__c) ||
                        activeContractByAccountId.containsKey(salesRecord.Bill_to_Customer_No__r.ParentId)){
                    throw (Exception) new DataException(String.format('Customer has active contracts and this {0} is not linked to a contract.<br />Create a New Quote/Order using an active Contract.',
                                                            new List<String>{salesRecord.Document_Type__c}));
                }
            }
        }
    }
     */

    /*
     *  Ticket#17068
     *      - Remove active contracts checking when clone.
     *  Ticket#19962
     *      - Prospect(customer) validation when clone.
     */
    public void checkBeforeClone(Id targetCustId, String targetDocType){
        Set<Id> accountIds = new Set<Id>();
        Set<Id> accountIdsForAccountLookup = new Set<Id>();
        if(targetCustId != null){
            accountIdsForAccountLookup.add(targetCustId);
        }
        Boolean quoteExpired = false;
        Boolean contractExpired = false;
        Boolean contractDoesBelongToSelectedCust = false;
        for(Sales_Order__c salesRecord:(List<Sales_Order__c>) Records){
            String errorMsg = '';
            String htmlLineBreak = '<br />';

            Date lightningCutOffDate = date.newInstance(2021,2,1);
            if(salesRecord.CreatedDate < lightningCutOffDate){
                errorMsg = 'Cloning is disabled on this record due to incompatible data resulting from recent system improvements. Please create a new Sales ' + targetDocType;
                throw new DataException(errorMsg);
            }

            //Ticket#21357 >>
            if(salesRecord.Quote_Contact__c != null){
                if(salesRecord.Quote_Contact__r.Blocked__c == true){
                    errorMsg = errorMsg + 'You cannot clone this document because the quote contact ' + salesRecord.Quote_Contact__r.Name + ' has been blocked/inactive.' + htmlLineBreak;
                }
                /*
                if(salesRecord.Quote_Contact__r.Contact_Type__c.contains('Quote') == false){
                    errorMsg = errorMsg + 'You cannot clone this document because ' + salesRecord.Quote_Contact__r.Name + ' is no longer the quote contact for account: ' + salesRecord.Bill_to_Customer_No__r.Name + htmlLineBreak;
                }
                 */
            }
            //Ticket#21357 <<

            if(salesRecord.Bill_to_Customer_No__c != null){
                accountIds.add(salesRecord.Bill_to_Customer_No__c);
                accountIdsForAccountLookup.add(salesRecord.Bill_to_Customer_No__c);
            }

            if(salesRecord.Bill_to_Customer_No__r.ParentId != null){
                accountIds.add(salesRecord.Bill_to_Customer_No__r.ParentId);
            }

            Map<Id, Account> accountsByIds = new Map<Id, Account>();
            if(accountIdsForAccountLookup.size() > 0){
                accountsByIds.putAll(AccountsSelector.newInstance().selectById(accountIdsForAccountLookup));
            }

            //Ticket#21357 >>
            if(salesRecord.Bill_to_Contact__c != null) {
                if(salesRecord.Bill_to_Contact__r.Blocked__c == true){
                    errorMsg = errorMsg + 'You cannot clone this document because the billing contact ' + salesRecord.Bill_to_Contact__r.Name + ' has been blocked/inactive.' + htmlLineBreak;
                }
                /*
                if (accountsByIds.containsKey(salesRecord.Bill_to_Customer_No__c)) {
                    Account billToAccount = accountsByIds.get(salesRecord.Bill_to_Customer_No__c);
                    if (String.isNotBlank(billToAccount.Contact_Type_Filter__c)) {
                        if (billToAccount.Contact_Type_Filter__c.contains(salesRecord.Bill_to_Contact__r.Contact_Type__c) == false) {
                            errorMsg = errorMsg + 'You cannot clone this document because ' + salesRecord.Bill_to_Contact__r.Name + ' is no longer the billing contact for account: ' + salesRecord.Bill_to_Customer_No__r.Name + htmlLineBreak;
                        }
                    } else {
                        if (salesRecord.Bill_to_Contact__r.Contact_Type__c.contains('Billing') == false){
                            errorMsg = errorMsg + 'You cannot clone this document because ' + salesRecord.Bill_to_Contact__r.Name + ' is no longer the billing contact for account: ' + salesRecord.Bill_to_Customer_No__r.Name + htmlLineBreak;
                        }
                    }
                }
                 */
            }

            if(salesRecord.Site_Contact_2__c != null) {
                if(salesRecord.Site_Contact_2__r.Blocked__c == true){
                    errorMsg = errorMsg + 'You cannot clone this document because the site contact ' + salesRecord.Site_Contact_2__r.Name + ' has been blocked/inactive.' + htmlLineBreak;
                }
                /*
                if (salesRecord.Site_Contact_2__r.Contact_Type__c.contains('Site') == false){
                    errorMsg = errorMsg + 'You cannot clone this document because ' + salesRecord.Site_Contact_2__r.Name + ' is no longer the site contact for account: ' + salesRecord.Bill_to_Customer_No__r.Name + htmlLineBreak;
                }
                 */
            }
            //Ticket#21357 <<

            /* Ticket#22091 - remove the restriction that prevent unapproved SQ from being cloned.
            if(salesRecord.Document_Type__c != 'Sales Order'){
                if(salesRecord.Approval_Status__c != EnumUtil.ApprovalStatus.APPROVED.name() && salesRecord.Approval_Status__c != EnumUtil.ApprovalStatus.REJECTED.name()){
                    errorMsg = errorMsg + 'You cannot clone this document because the selected record is not approved yet.' + htmlLineBreak;
                }
            }
             */

            /*
            if(salesRecord.Approval_Status__c != EnumUtil.ApprovalStatus.APPROVED.name() && salesRecord.Document_Type__c != 'Sales Order'){
                errorMsg = errorMsg + 'You cannot clone this document because the selected record is not approved yet.' + htmlLineBreak;
            }
             */

            Account targetCustomer = new Account();
            Set<Id> targetAccIds = new Set<Id>{targetCustId};
            if(accountsByIds.containsKey(targetCustId)) {
                targetCustomer = accountsByIds.get(targetCustId);
                if(targetCustomer.Customer_Status__c != 'Active' && targetDocType == 'Order'){
                    errorMsg = errorMsg + 'You cannot clone this document because the selected customer is not active.' + htmlLineBreak;
                }
                if(String.isNotBlank(targetCustomer.ParentId)){
                    targetAccIds.add(targetCustomer.ParentId);
                }

                if(targetCustomer.Type == 'Prospect'){
                    SalesOrdersService.isValidCustomer(targetCustomer.Id);
                }
            }

			system.debug('nav decomm - targetCustomer**************'+targetCustomer.Sage_Customer_No__c);
            if(targetDocType == 'Order'){
                Boolean isERAccount = false;
                if(salesRecord.Bill_to_Customer_No__r.Emergency__c == true && salesRecord.Sales_Order_Type__r.Emergency_Response__c != true){
                    isERAccount = true;
                }

                //Ticket#24845 >>
                if(accountsByIds.containsKey(targetCustId)){
                    if(salesRecord.Bill_to_Customer_No__c != targetCustId){
                    //if(salesRecord.Bill_to_Customer_No__c != targetCustId && accountsByIds.containsKey(targetCustId)){
                        if(targetCustomer.Emergency__c == true && salesRecord.Sales_Order_Type__r.Emergency_Response__c != true){
                            isERAccount = true;
                        }
                    }
                    if(targetCustomer.Type == 'Prospect'){
                        isERAccount = true;
                    }
                    if(String.isBlank(targetCustomer.Sage_Customer_No__c) && salesRecord.Sales_Order_Type__r.Emergency_Response__c != true){
                        isERAccount = true;
                    }
                }
                //Ticket#24845 <<

                if(isERAccount == true){
                    errorMsg = errorMsg + 'You cannot clone this document because the selected Account is not approved by the Accounts Receivable Department.' + htmlLineBreak;
                }

                if(salesRecord.Document_Type__c == 'Sales Order') {
                    if (salesRecord.From_Sales_Quote__c != null && fromSalesQuoteByIds.containsKey(salesRecord.From_Sales_Quote__c)) {
                        Sales_Order__c salesQuote = fromSalesQuoteByIds.get(salesRecord.From_Sales_Quote__c);
                        if (salesQuote.Allow_Convert__c != true) {
                            quoteExpired = true;
                        }
                    }
                }
                else if(salesRecord.Document_Type__c == 'Sales Quote'){
                    if(salesRecord.Allow_Convert__c != true){
                        quoteExpired = true;
                    }
                }
            }

            if(salesRecord.Contract__c != null && contractsByIds.containsKey(salesRecord.Contract__c)){
                Contract contract = contractsByIds.get(salesRecord.Contract__c);
                if(contract.EndDate < Date.today() || contract.Status == 'Inactive'){
                    contractExpired = true;
                }

                List<Account_Contract_Association__c> accountContractAssociations = [ SELECT Id
                    FROM Account_Contract_Association__c WHERE Contract__c = :contract.Id AND Account__c IN :targetAccIds
                ];
                if(accountContractAssociations.size() == 0){
                    contractDoesBelongToSelectedCust = true;
                }
            }

            String contractExpiredMsg = String.format('You cannot clone this {0} because the associated Contract has expired.',
                    new List<String>{salesRecord.Document_Type__c});

            String quoteExpiredMsg = '';
            if(salesRecord.Document_Type__c == 'Sales Order'){
                quoteExpiredMsg = 'You cannot clone this Sales Order because the associated Sales Quote has expired.';
            } else if (salesRecord.Document_Type__c == 'Sales Quote') {
                quoteExpiredMsg = 'You cannot clone this Sales Quote because it has expired.';
            }

            String contractBelongToOtherCustErrorMsg = String.format('You cannot clone this {0} because the related contract does not belong to the selected Bill To customer.',
                    new List<String>{salesRecord.Document_Type__c});

            String salesOrderTypeIsBlockedMsg = String.format('You cannot clone this {0} because the Sales Order Type is blocked.',
                    new List<String>{salesRecord.Document_Type__c});

            if(quoteExpired == true) errorMsg = errorMsg + quoteExpiredMsg + htmlLineBreak;
            if(contractExpired == true) errorMsg = errorMsg + contractExpiredMsg + htmlLineBreak;
            if(contractDoesBelongToSelectedCust == true) errorMsg = errorMsg + contractBelongToOtherCustErrorMsg + htmlLineBreak;

            if(salesRecord.Sales_Order_Type__r.Blocked__c == true) errorMsg = errorMsg + salesOrderTypeIsBlockedMsg + htmlLineBreak;

            if(errorMsg != '') throw new DataException(errorMsg);
        }

        /*
        Map<Id, Contract> activeContractByAccountId = new Map<Id, Contract>();
        for(Contract activeContract:ContractsSelector.newInstance().selectByAccountId(accountIds))
        {
            activeContractByAccountId.put(activeContract.AccountId, activeContract);
        }

        for(Sales_Order__c salesRecord:(List<Sales_Order__c>) Records){
            if(salesRecord.Contract__c == null){
                if(activeContractByAccountId.containsKey(salesRecord.Bill_to_Customer_No__c) ||
                        activeContractByAccountId.containsKey(salesRecord.Bill_to_Customer_No__r.ParentId)){
                    throw (Exception) new DataException(String.format('Customer has active contracts and this {0} is not linked to a contract.<br />Create a New Quote/Order using an active Contract.',
                            new List<String>{salesRecord.Document_Type__c}));
                }
            }
        }
         */
    }

    public void checkBeforeConvert(){
        Set<Id> accountIds = new Set<Id>();
        for(Sales_Order__c salesRecord:(List<Sales_Order__c>) Records){
            if(salesRecord.Bill_to_Customer_No__c != null) {
                accountIds.add(salesRecord.Bill_to_Customer_No__c);
            }

            if(salesRecord.Bill_to_Customer_No__r.ParentId != null) {
                accountIds.add(salesRecord.Bill_to_Customer_No__r.ParentId);
            }

            //Ticket#21357 >>
            if(salesRecord.Bill_to_Contact__r.Blocked__c == true){
                throw new DataException('You cannot convert this document because the bill-to contact has been blocked/inactive.');
            }

            if(salesRecord.Site_Contact_2__r.Blocked__c == true){
                throw new DataException('You cannot convert this document because the site contact has been blocked/inactive.');
            }
            //Ticket#21357 <<

            if(salesRecord.Document_Type__c == 'Sales Quote') {
                if(billToCustomersByIds.containsKey(salesRecord.Bill_to_Customer_No__c)){
                    Account billToCust = billToCustomersByIds.get(salesRecord.Bill_to_Customer_No__c);
                    Sales_Order_Type__c salesOrderType = salesOrderTypesByIds.get(salesRecord.Sales_Order_Type__c);
                    /*if(billToCust.Emergency__c != true && String.isBlank(billToCust.AccountNumber)){
                        throw new DataException('If it an emergency order please make sure customer is flag as an emergency customer! ');
                    }*/

                    if(billToCust.Emergency__c == true && salesOrderType.Emergency_Response__c != true){
                        throw (Exception) new DataException('You cannot convert this Sales Quote because this customer is not approved and only Emergency Response sales order are allowed!');
                    }
                }

                if (salesRecord.Allow_Convert__c != true) {
                    throw (Exception) new DataException('You cannot convert this Sales Quote because it is expired.');
                }


                if (salesRecord.Contract__c != null && contractsByIds.containsKey(salesRecord.Contract__c)) {
                    Contract contract = contractsByIds.get(salesRecord.Contract__c);
                    if (contract.EndDate < Date.today()) {
                        throw (Exception) new DataException(String.format('You cannot covert this Sales Quote because the associated Contract has expired.',
                                new List<String>{
                                        salesRecord.Document_Type__c
                                }));
                    }
                }
            }
        }
    }
}