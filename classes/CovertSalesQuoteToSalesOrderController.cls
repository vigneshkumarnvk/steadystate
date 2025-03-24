/*************************************************************************************************
* Name         :  CovertSalesQuoteToSalesOrderController
* Description  :  controller used by Convert Quote to Order and related pages on Sales Order
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan      01-10-2024             78151: Salesforce - Customer PO Number value which entered during Quote to Order Conversion is Not available in the Order
* Vennila Paramasivam		02-19-2024			   78904: commented line 53 to 61
  Shahwaz Khan              02-20-2024             78352: Salesforce - When Choosing Facility on SQ vs SO
  Shahwaz Khan              03-11-2024             Bug80870:3rd Party Restriction Impact on Group B Service Centers
  Sanjana 					03-19-2024             Bug 81798: Added Error message when converting the sales quote after created the standalone sales order
  Sanjana 					04-17-2024			   Bug 84607: Worker Responsible Field Allowing Inactive Labor Resource to be assigned to Sales Order and Sales Quote
  Andrew                    05-09-2024             Bug 87234: Updated to check if worker responsible is null first so error does not display on Group B service center quotes
  Shahwaz Khan              02-14-2025             US141063:  Add D365 Project Lookup Functionality
* Vignesh      03/02/2025      US141018       LOA Reminder if Quote/Order is Over $30,000
*************************************************************************************************/
public with sharing class CovertSalesQuoteToSalesOrderController {

    private ApexPages.StandardController standardController = null;

    public Sales_Order__c theSO {get; set;}
    public Account billToCustomer {get; set;}

    //ticket 21113 <<
    public Boolean quoteSigned { set; get; }
    //ticket 21113 >>
    //Task#78352
    public Boolean is3rdPartFacility=false;
    //Task#81798
    public Boolean isEmergencySO = false;
    public Boolean isWarning {get; set;}

    public CovertSalesQuoteToSalesOrderController (ApexPages.StandardController controller){
        standardController = controller;
        theSO = SalesOrdersSelector.newInstance().selectConvertRelatedFieldsById(new Set<Id> {standardController.getRecord().Id})[0];
        if(String.isNotBlank(theSO.Bill_to_Customer_No__c)) {
            billToCustomer = AccountsSelector.newInstance().selectById(new Set<Id>{theSO.Bill_to_Customer_No__c})[0];
        }
        //ticket 21113 <<
        List<Signature__c> signatures = [SELECT Id FROM Signature__c WHERE Sales_Order__c = :controller.getId() AND Voided__c != TRUE AND Signed__c = TRUE];
        if (signatures.size() > 0) {
            this.quoteSigned = true;
        }
        //ticket 21113 >>
        //Bug#78321
        //theSO.Customer_PO_No__c = null;
        //job task <<
        List<String> errors = this.getConvertMessages();
        if (errors.size() > 0) {
            for (String error : errors) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, error));
            }
        }
        //job task >>
        this.isWarning = theSO.Order_Total_Amount_Incl_Tax__c > 30000 ? true : false;
    }
    
    public void setWarningResponse() { //US141018
        CovertSalesQuoteToSalesOrderController newController = 
            new CovertSalesQuoteToSalesOrderController(standardController); //Calling to validate again, if not validation not happens
        this.isWarning = false;    
    }
     //asynchronous method to perform a callout to EQAI - passes in newly created Sales Order
     @future(callout=true)
     public static void performWorkOrderQuoteHeaderInfoCallout(String newSOId) {
        // Sales_Order__c theSO = [SELECT Id, SO_sent_to_EQAI__c,SO_Submitted_to_EQAI__c FROM Sales_Order__c WHERE Id = :newSOId LIMIT 1];
         String Response = workOrderQuoteService.workOrderQuoteHeaderInfo(newSOId);
        /* if (Response == '200') {
            theSO.SO_sent_to_EQAI__c = true;
              //78904 
            theSO.SO_Submitted_to_EQAI__c = true;
        } else {
             //78904 
           theSO.SO_Submitted_to_EQAI__c = true;
        }
        update theSO;*/
     }
 
      public PageReference convertQuoteToOrder() {
       
        // Validation on PO number format
        try{
            if(billToCustomer != null && String.isNotBlank(billToCustomer.PO_Number_Type__c)){
                 if(String.isNotBlank(theSO.Customer_PO_No__c)){
                    AccountsService.validatePONumberFormat(billToCustomer, theSO.Customer_PO_No__c);
                }
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }

        // Updates Sales Order with PO Number entered on conversion page then creates new SO and passes to EQAI callout
        try {  
          
            theSO.Customer_PO_No__c = theSO.Customer_PO_No__c;
            update theSO;
            String newSOId = SalesOrdersService.convertQuoteToOrder(new Set<Id>{theSO.Id}); 
             // Perform the callout in a separate transaction
            performWorkOrderQuoteHeaderInfoCallout(newSOId);
            return new PageReference('/' + newSOId);
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'hehe'));
        } catch (Exception e) {
             //Database.rollback(sp);
             System.debug('Error: e.getStackTraceString ' + e.getStackTraceString());
             System.debug('Error: e ' + e.getMessage());
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return ApexPages.hasMessages() ? null : standardController.view();
    }

    public List<String> getConvertMessages() {
        List<String> str = new List<String>();
        List<Sales_Order__c> sales = New List<Sales_Order__c>();
        //Task#78352//Bug#80870
        List<Sales_Line__c> salesLines=New List<Sales_Line__c>();
        Date thrdPartyValDate = Date.valueOf(label.SO_3rd_Party_Facility_Check);
        salesLines = [Select Id from Sales_Line__c Where Sales_Order__c=:theSO.Id 
                      AND Sales_Order__r.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c=true 
                      AND Facility__r.Third_Party_Facility__c = true AND CreatedDate >= :thrdPartyValDate];
        Account acct = [Select Id,AccountNumber,Sage_Customer_No__c,Emergency__c,Customer_Status__c from Account where Id=:theSO.Bill_to_Customer_No__c limit 1];
        if((System.Label.Release_Flag =='true' && (String.isBlank(acct.AccountNumber) || String.isBlank(acct.Sage_Customer_No__c)) && System.Label.Account_Number_Validation =='false') ||(String.isBlank(acct.Sage_Customer_No__c) && System.Label.Account_Number_Validation =='true' && System.Label.Release_Flag =='true')){
            sales = [Select Id from Sales_Order__c where Document_Type__c = 'Sales Order' and Bill_to_Customer_No__c=:acct.Id];
        }
        else if(acct.Emergency__c == true && System.Label.Release_Flag =='false' && String.isBlank(acct.AccountNumber))
        {
            sales = [Select Id from Sales_Order__c where Document_Type__c = 'Sales Order' and Bill_to_Customer_No__c=:acct.Id]; 
        }
        else if(acct.Customer_Status__c == 'Inactive'){
            sales = [Select Id from Sales_Order__c where Document_Type__c = 'Sales Order' and Bill_to_Customer_No__c=:acct.Id]; 
        }
        if(sales.size()>0)
        {
          str.add('ERROR! You have exceeded the number of Emergency Sales Orders. This customer is not approved. Please contact Accounts Receivable.');  
		  isEmergencySO = true;
        }
        if (theSO.Document_Type__c == 'Sales Order') {
            str.add('ERROR! The sales document is a Sales Order already.');
        }
        //Ticket# AES-404
        if (theSO.Bill_to_Customer_No__r.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId()){
            str.add('ERROR! Cannot convert Quote to Sales Order because account is not approve yet!');
        }
        if (!theSO.Allow_Convert__c && theSO.Document_Type__c == 'Sales Quote'){
            str.add('ERROR! Cannot convert Quote to Sales Order because the Quote Type is One Time or the quote is expired!');
        }
        if(theSO.Approval_Status__c != EnumUtil.ApprovalStatus.APPROVED.name()){
            str.add('ERROR! Cannot convert quote to sales order because this quote is not approved yet!');
        }
        if(theSO.Bill_to_Customer_No__r.Emergency__c == true && theSO.Sales_Order_Type__r.Emergency_Response__c != true){
            str.add('ERROR! You cannot convert this document because the selected Account is not approved by the Accounts Receivable Department.');
        }
        if(theSO.Sales_Order_Type__r.Blocked__c == true){
            str.add('ERROR! You cannot convert this document because the Sales Order Type is blocked.');
        }
        //Ticket#20749 - Add Contract Status to the checking
        if(String.isNotBlank(theSO.Contract__c) && theSO.Contract__r.Status != 'Activated'){
            str.add('ERROR! You cannot convert this document because associated contract is not activated.');
        }
        //Ticket#25158
        if(theSO.Estimated_Job_Start_Date__c == null){
            str.add('ERROR! You cannot convert this document because "Estimated Job Start Date" field is blank.');
        }

        //Ticket#21908
        if(theSO.Blocked__c == true){
            str.add('Action is prevented. This Sales Quote has been blocked. Please create a new Sales Quote and submit for approval');
        }
        //Task#78352
        if(salesLines.size()>0 && System.Label.Release_Flag =='true')
        {
            str.add('ERROR! You cannot create a Sale Order, Your have a Waste Line referencing 3rd Party. You must select an approved facility.'); 
            is3rdPartFacility = true;
        }
        if(theSO.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c == true){
        if(theSO.Name_of_Worker_Responsible__r != null && theSO.Name_of_Worker_Responsible__r.status__c != 'Active' /*&& */){
            str.add('ERROR! The Worker Responsible currently selected in the Order Information Tab, contains an invalid Labor Resource. Please select another.'); 
        }
        if(theSO.Name_of_Worker_Responsible__c == null || theSO.Worker_Responsible__c == null) {
            str.add('ERROR! The Name of Worker Responsible and Worker Responsible fields must not be blank.');
        }
            //US141063
            if(!theSO.Is_New_D365_Project__c && String.isBlank(theSO.D365_Project_ID__c)){                
                str.add('ERROR! Please select "Create New" or choose a valid existing D365 Project ID from the D365 lookup.');
            }
        }
        return str;
    }

    /*
     *  Ticket#20749 - Add Contract Status to the checking
     *  Ticket#21908 - add block to the check
     *  Ticket#25158 - add Estimated Job Start Date != null
     *  Ticket#78352 - add Third Party Facility check
     *  Tickt#141063 - D365_Project Validation
     */
    public Boolean allowConvertToOrder  {
        get {
            if (theSO.Bill_to_Customer_No__r.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId() ||
                    theSO.Allow_Convert__c == false || theSO.Approval_Status__c != EnumUtil.ApprovalStatus.APPROVED.name() ||
                    theSO.Sales_Order_Type__r.Blocked__c == true || (String.isNotBlank(theSO.Contract__c) && theSO.Contract__r.Status != 'Activated') ||
                    theSO.Estimated_Job_Start_Date__c == null ||                    
                    theSO.Estimated_Job_Start_Date__c == null || (!theSO.Is_New_D365_Project__c && String.isBlank(theSO.D365_Project_ID__c)) ||                    
                    theSO.Blocked__c == true || is3rdPartFacility || isEmergencySO || ((theSO.Name_of_Worker_Responsible__c == null || theSO.Worker_Responsible__c == null) && theSO.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c == true)){
                return false;
            }
            return true;
        }
    }


}