/*************************************************************************************************
* Name         :  CloneSalesOrderController
* Description  :  Controller used by clone button and related page on Sales Order
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
  Shahwaz Khan              02-20-2024             78352: Salesforce - When Choosing Facility on SQ vs SO
  Shahwaz Khan              03-11-2024             80870: Bug-3rd Party Restriction Impact on Group B Service Centers
  Prabhu Rathakrishnan      04-15-2024             84048: Character Limit Issue from Salesforce Job Description Field to EQAI Name Field
  Shahwaz Khan              05-27-2024             88502: Bug-User is able to clone the sales Quote/order if the MSG, Retail, National Account checkboxes are checked on the Customer table
   Andrew Simons            07-25-2024             Salesforce - removed logic for MSG/Retail/National Accounts - part 1
*************************************************************************************************/
public with sharing class CloneSalesOrderController {

    private ApexPages.StandardController standardController = null;

    public List<SelectOption> lstConvertTo {
        get {
            if (lstConvertTo == null) {
                lstConvertTo = new List<SelectOption>();
                lstConvertTo.add(new SelectOption('Quote', 'Quote'));
                lstConvertTo.add(new SelectOption('Order', 'Order'));
            }
            return lstConvertTo;
        }
        set;
    }

    public String selConvertTo { get; set; }

    //job task <<
    public String jobDescription { get; set; }
    public String poNumber {get; set; }
    //job task >>

    public List<SelectOption> lstServiceCenter { get; set; }

    /*
     *  Ticket#19962
     *    Update SC lookup to handle user default SC is blocked.
     */
    public String selServiceCenter {
        get{
            selServiceCenter = null;
            List<User> users = UsersSelector.newInstance().selectById(new Set<Id>{Id.valueOf(UserInfo.getUserId())});
            if(users.size() > 0 && users[0].Service_Center__c != null){
                List<Service_Center__c> serviceCenters = ServiceCentersSelector.newInstance().selectByName(users[0].Service_Center__c);
                if(serviceCenters[0].Blocked__c == true){
                    List<User_Service_Center__c> userServiceCenters = [SELECT Id, Service_Center__c, User__c, Default__c FROM User_Service_Center__c WHERE User__c =: UserInfo.getUserId() AND Service_Center__r.Blocked__c != TRUE];
                    selServiceCenter = userServiceCenters[0].Service_Center__c;
                    for(User_Service_Center__c userServiceCenter : userServiceCenters){
                        if(userServiceCenter.Default__c == true){
                            selServiceCenter = userServiceCenter.Service_Center__c;
                            break;
                        }
                    }
                } else {
                    if(serviceCenters.size() > 0) selServiceCenter = serviceCenters[0].Id;
                }
            }

            return selServiceCenter;
        }
        set;
    }
    public String selectedServiceCenterId = null;

    public Sales_Order__c theSO {get; set;}

    public Account billToCust {get; set;}

    //ticket 21113 <<
    public Boolean quoteSigned { set; get; }
    //ticket 21113 >>

    public List<Service_Center__c> serviceCenterList = new List<Service_Center__c>();
    /*
     *   Ticket#19962
     *      - default selConvertTo to Quote
     */
    public CloneSalesOrderController (ApexPages.StandardController controller) {
        standardController = controller;
        selConvertTo = 'Quote';
        initSalesOrder();
        initServiceCenter();
        initBillToCustomer();
        
        //ticket 21113 <<
        List<Signature__c> signatures = [SELECT Id FROM Signature__c WHERE Sales_Order__c = :controller.getId() AND Voided__c != TRUE AND Signed__c = TRUE];
        if (signatures.size() > 0) {
            this.quoteSigned = true;
        } else {
            this.quoteSigned = false;
        }
        //ticket 21113 >>

        if(String.isNotBlank(theSO.CMR_Description__c)){
            this.jobDescription = theSO.CMR_Description__c;
        }
        if(!Test.isRunningTest()) selectedServiceCenterId = selServiceCenter;
    }

    public PageReference cloneSO() {
        try {
            //job task <<
            //String newSOId = SalesOrdersService.cloneSalesOrder(new Set<Id>{ standardController.getRecord().Id}, selConvertTo, selectedServiceCenterId, billToCust.Id, billToCust.ParentId);
            //Task#78352//Bug#80870
            List<Sales_Line__c> salesLines=New List<Sales_Line__c>();
            Date thrdPartyValDate = Date.valueOf(label.SO_3rd_Party_Facility_Check);
            salesLines = [Select Id from Sales_Line__c Where Sales_Order__c=:theSO.Id  AND Sales_Order__r.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c=true 
                          AND Facility__r.Third_Party_Facility__c = true AND CreatedDate >= :thrdPartyValDate];
            if(salesLines.size()>0 && selConvertTo == 'Order' && System.Label.Release_Flag =='true')
            {
                throw new DataException('ERROR! You cannot create a Sale Order, Your have a Waste Line referencing 3rd Party. You must select an approved facility.');  
            }
			if (String.isBlank(JobDescription)) {
                throw new DataException('Job Description is required');
            }
            else If(JobDescription.length()>40){
                throw new DataException('Job Description cannot exceed 40 characters');
                
            }
            if (selConvertTo == 'Order') {
                if (String.isBlank(poNumber)){
                    throw new DataException('Customer PO Number is required');
                }
                //Ticket#27427 >>
                Service_Center__c selectedServiceCenter = [SELECT Prevent_New_and_Cloned_Sales_Orders__c FROM Service_Center__c WHERE Id = :selectedServiceCenterId LIMIT 1];
                if(selectedServiceCenter.Prevent_New_and_Cloned_Sales_Orders__c == true){
                    throw new DataException('Cloning Sales Order is prevented in selected Service Center!');
                }
                //Ticket#27427 <<
            } else {
                poNumber = null;
            }
            String newSOId = SalesOrdersService.cloneSalesOrder(new Set<Id>{ standardController.getRecord().Id}, selConvertTo, selectedServiceCenterId, billToCust.Id, billToCust.ParentId, jobDescription, poNumber);
            //job task >>

            return new PageReference('/' + newSOId);
        } catch (Exception e) {
            System.debug('Error: ' + e.getStackTraceString());
            ApexPages.addMessages(e);
        }
        return ApexPages.hasMessages() ? null : standardController.view();
    }

    public void initSalesOrder(){
        theSO = SalesOrdersSelector.newInstance().selectServiceCenterAndSubCompanyById(new Set<Id>{standardController.getRecord().Id})[0];
    }

    /*
        Ticket#18267 Exclude blocked service center from the list
     */
    public void initServiceCenter(){
        List<Service_Center__c> serviceCenters = ServiceCentersSelector.newInstance().selectAll();
        if (serviceCenters.size() > 0 ){
            lstServiceCenter = new List<SelectOption>();
            for (Service_Center__c sc : serviceCenters) {
                if(sc.Blocked__c != true) {
                    fflib_StringBuilder sb = new fflib_StringBuilder();
                    sb.add(sc.Name);
                    sb.add(' - ');
                    if (String.isNotEmpty(sc.Description__c)) {
                        sb.add(sc.Description__c);
                    }
                    lstServiceCenter.add(new SelectOption(sc.Id, sb.getStringValue()));
                    serviceCenterList.add(sc);
                }
            }
        }
    }

    public void initBillToCustomer(){
        //job task <<
        //billToCust = AccountsSelector.newInstance().selectById(new Set<Id>{theSO.Bill_to_Customer_No__c})[0];
        List<Account> customers = AccountsSelector.newInstance().selectById(new Set<Id>{theSO.Bill_to_Customer_No__c});
        if (customers.size() > 0) {
            billToCust = customers[0];
        }
        else {
            throw new DataException('Bill-to customer does not exist.');
        }
        //job task >>

    }

    /*
     *  Ticket#19962
     *      - prospect(customer) validation when clone.
     */
    public void validateBillToCust(){
        String billToCustId = ApexPages.currentPage().getParameters().get('billToCustId');
        if (!String.isEmpty(billToCustId)){
            try{
                List<Account> accounts = AccountsSelector.newInstance().selectById(new Set<Id>{billToCustId});
                if (accounts.size() > 0){
                    billToCust = accounts[0];
                    if(billToCust.Type == 'Prospect') {
                        SalesOrdersService.isValidCustomer(billToCustId);
                    }
                } else {
                    throw new DataException('Bill-to Customer does not exist!');
                }
            } catch (Exception ex){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            }
        }
    }

    public void populatedSelectedServiceCenterId(){
        String selectedSCId = ApexPages.currentPage().getParameters().get('selectedSCId');
        this.selectedServiceCenterId = selectedSCId;
        System.debug('Debug: this.selectedServiceCenterId ' + this.selectedServiceCenterId);
    }

    @AuraEnabled
    public static String getData(String recordId){
        try{
            system.debug('recordId:::::::::::::::::'+recordId);
            Sales_Order__c salesOrder = [SELECT Id FROM Sales_Order__c WHERE Id = :recordId LIMIT 1];
            system.debug('salesOrder :::::::::::::'+salesOrder);
            ApexPages.StandardController standardController = new ApexPages.StandardController(salesOrder);
            Map<String, Object> initDataMap = new Map<String, Object>();
            if(!Test.isRunningTest()){
            CloneSalesOrderController controller = new CloneSalesOrderController(standardController);
            
            initDataMap.put('salesOrder', controller.theSO);
            initDataMap.put('serviceCenters', controller.serviceCenterList);
            initDataMap.put('selectedServiceCenterId', controller.selectedServiceCenterId);
            initDataMap.put('billToCustomer', controller.billToCust);
            initDataMap.put('quoteSigned', controller.quoteSigned);
            
        	}
        	return JSON.serialize(initDataMap);
        } catch (Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void validateBillToCust(String billToId){
        if (!String.isEmpty(billToId)){
            try{
                List<Account> accounts = AccountsSelector.newInstance().selectById(new Set<Id>{billToId});
                if (accounts.size() > 0){
                    if(accounts[0].Type == 'Prospect') {
                        SalesOrdersService.isValidCustomer(billToId);
                    }
                } else {
                    throw new AuraHandledException('Bill-to Customer does not exist!');
                }
            } catch (Exception ex){
                throw new AuraHandledException(ex.getMessage());
            }
        }
    }

    @AuraEnabled
    public static String cloneSalesOrder(String sourceRecordId, String selectedCloneToRecordType, String selectedServiceCenter, String selectedBillToId, String selectedBillParentId, String jobDescription, String poNum ){
        try {
            List<Sales_Order__c> sales = New List<Sales_Order__c>();            
            //Task#78352//Bug#80870
            List<Sales_Line__c> salesLines=New List<Sales_Line__c>();
            Date thrdPartyValDate = Date.valueOf(label.SO_3rd_Party_Facility_Check);
            salesLines = [Select Id from Sales_Line__c Where Sales_Order__c=:sourceRecordId 
                          AND Sales_Order__r.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c=true 
                          AND Facility__r.Third_Party_Facility__c = true AND CreatedDate >= :thrdPartyValDate];
            //Ticket#126489 >>
             List<Account> accounts;
            //Ticket#126489 <<
            //Bug-88502 //Task78375
            if (!String.isEmpty(selectedBillToId)){
            //Ticket#126489 >>
                 accounts = AccountsSelector.newInstance().selectById(new Set<Id>{selectedBillToId});
                //Ticket#126489 <<
                // if(accounts[0].Sage_Customer_No__c !=null && CustomerDetailsService.getCustomerDetails(accounts[0].Sage_Customer_No__c) == 'T'){
                //     throw new DataException('Salesforce cannot send National Account, MSG, or Retail Account customers to EQAI. Please create Work Order Quote/Work Order in EQAI directly.');  
                // }
                if((System.Label.Release_Flag =='true' && (String.isBlank(accounts[0].AccountNumber) || String.isBlank(accounts[0].Sage_Customer_No__c)) && System.Label.Account_Number_Validation =='false') ||(String.isBlank(accounts[0].Sage_Customer_No__c) && System.Label.Account_Number_Validation =='true' && System.Label.Release_Flag =='true')){
                    sales = [Select Id from Sales_Order__c where Document_Type__c = 'Sales Order' and Bill_to_Customer_No__c=:accounts[0].Id];
                }
                if(accounts[0].Customer_Status__c == 'Inactive'){
                    sales = [Select Id from Sales_Order__c where Document_Type__c = 'Sales Order' and Bill_to_Customer_No__c=:accounts[0].Id];
                }
            }
            if(sales.size()>0 && selectedCloneToRecordType == 'Order')
            {
                throw new DataException('ERROR! You have exceeded the number of Emergency Sales Orders. This customer is not approved. Please contact Accounts Receivable.');  
            }
            //End Bug-88502 
            if(salesLines.size()>0 && selectedCloneToRecordType == 'Order' && System.Label.Release_Flag =='true')
            {
                throw new DataException('ERROR! You cannot create a Sale Order, Your have a Waste Line referencing 3rd Party. You must select an approved facility.');  
            }
            if (String.isBlank(jobDescription)) {
                throw new DataException('Job Description is required');
            }
            else If(JobDescription.length()>40){
                throw new DataException('Job Description cannot exceed 40 characters');    
            }
            if (selectedCloneToRecordType == 'Order') {
                //Ticket#126489 >>
                if (String.isBlank(poNum) && (accounts[0].PO_Number_Type__c!=null || accounts[0].PO_Required__c == true)){
                    throw new DataException('Customer PO Number is required'); 
                }
                //Ticket#126489 <<
                //Ticket#27427 >>
                //Service_Center__c selectedServiceCenterRec = [SELECT Id,Prevent_New_and_Cloned_Sales_Orders__c FROM Service_Center__c WHERE Id = :selectedServiceCenter LIMIT 1];
                List<Service_Center__c> selectedServiceCenterRec = ServiceCentersSelector.newInstance().selectById(new Set<Id>{selectedServiceCenter});
                if(selectedServiceCenterRec!=null && selectedServiceCenterRec.size()>0 && selectedServiceCenterRec[0].Prevent_New_and_Cloned_Sales_Orders__c == true){
                    throw new DataException('Cloning Sales Order is prevented in selected Service Center!');
                }
                //Ticket#27427 <<
            } else {
                poNum = null;
            }
            String newSOId = SalesOrdersService.cloneSalesOrder(new Set<Id>{sourceRecordId}, selectedCloneToRecordType, selectedServiceCenter, selectedBillToId, selectedBillParentId, jobDescription, poNum);
            return newSOId;
        } catch (Exception e) {
            System.debug('Error: ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
}