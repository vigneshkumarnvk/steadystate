/*************************************************************************************************
* Name         :  SalesInvoiceController
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan      12-14-2023             Task75275: Salesforce - Remove or disable the below on the Sales Invoice Object
* Prabhu Rathakrishnan      10-13-2024             US127188 - Salesforce - Modifications to allow ESIC Surcharge Type
*************************************************************************************************/
public with sharing class SalesInvoiceController {
    private final ApexPages.StandardController theController;
    public Sales_Invoice__c theSI;
    public List<Sales_Invoice_Line__c> theSILList;
    public List<Sales_Invoice_Line__c> theSILListLabor;
    public List<Sales_Invoice_Line__c> theSILListEquipment;
    public List<Sales_Invoice_Line__c> theSILListMaterials;
    public List<Sales_Invoice_Line__c> theSILListSubcontractors;
    public List<Sales_Invoice_Line__c> theSILListWasteDisposal;
    public List<Sales_Invoice_Line__c> theSILListDemurrage;
    public List<Sales_Invoice_Line__c> theSILListLumpSum;
    public List<Sales_Invoice_Line__c> theSILListMisc;

    private String SIId;
    private Boolean SkipPostingMessage;
    public static Company_Setup__c theCompanySetupValue;
    public Company_Setup__c theCompanySetup{
        get{
            if(theCompanySetupValue == null) {
                theCompanySetupValue = CompanyMgmt.getCompanySetup();
            }
            return theCompanySetupValue;
        }
        set;
    }
    public Decimal SILSubtotal { get; set; }
    public Decimal SILTaxTotal { get; set; }
    public Decimal SILTotal { get; set; }
    public Decimal SILProfitMargin {get;set;} // AES-437
    public Decimal SILTotalCost {get;set;}
    public Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public Numbering_Series__c theNumberingSeries;
    public String selPrintCopy { get; set; }
    public String selInvoiceType { get; set; }
    public String selLogo { get; set; }
    public List<WrapSILByCategory> theWrapSILList { get; set; }
    public String TMNames { get; set; }

    public String remName { get; set; }
    public String remAdd1 { get; set; }
    public String remAdd2 { get; set; }
    public String eftBank { get; set; }
    public String eft1 { get; set; }
    public String eft2 { get; set; }
    public String chk1 { get; set; }
    public String chk2 { get; set; }
    public String documentType { get; set; }
    public String documentDate { get; set; }
    public String remPhone { get; set; }
    public Boolean useCompanylogo { get; set; }
    public Boolean useSClogo { get; set; }
    public Boolean useContractlogo { get; set; }

    public Date lastServiceDate { get; set; }

    public Decimal SILSubtotalLabor { get; set; }
    public Decimal SILTaxTotalLabor { get; set; }
    public Decimal SILTotalLabor { get; set; }
    public Decimal SILProfitMarginLabor { get; set; } //Ticket# AES-437
    public Decimal SILTotalCostLabor { get; set; }

    public Decimal SILSubtotalEquipment { get; set; }
    public Decimal SILTaxTotalEquipment { get; set; }
    public Decimal SILTotalEquipment { get; set; }
    public Decimal SILProfitMarginEquipment {get;set;} // AES-437
    public Decimal SILTotalCostEquipment {get;set;}

    public Decimal SILSubtotalMaterials { get; set; }
    public Decimal SILTaxTotalMaterials { get; set; }
    public Decimal SILTotalMaterials { get; set; }
    public Decimal SILProfitMarginMaterials {get;set;} // AES-437
    public Decimal SILTotalCostMaterials {get;set;}

    public Decimal SILSubtotalSubcontractors { get; set; }
    public Decimal SILTaxTotalSubcontractors { get; set; }
    public Decimal SILTotalSubcontractors { get; set; }
    public Decimal SILProfitMarginSubcontractors {get;set;} // AES-437
    public Decimal SILTotalCostSubcontractors {get;set;}

    public Decimal SILSubtotalWasteDisposal { get; set; }
    public Decimal SILTaxTotalWasteDisposal { get; set; }
    public Decimal SILTotalWasteDisposal { get; set; }
    public Decimal SILProfitMarginWasteDisposal {get;set;} // AES-437
    public Decimal SILTotalCostWasteDisposal {get;set;}

    public Decimal SILSubtotalDemurrage { get; set; }
    public Decimal SILTaxTotalDemurrage { get; set; }
    public Decimal SILTotalDemurrage { get; set; }
    public Decimal SILProfitMarginDemurrage {get;set;} // AES-437
    public Decimal SILTotalCostDemurrage {get;set;}

    public Decimal SILSubtotalLumpSum { get; set; }
    public Decimal SILTaxTotalLumpSum { get; set; }
    public Decimal SILTotalLumpSum { get; set; }
    public Decimal SILProfitMarginLumpSum {get;set;} // AES-437
    public Decimal SILTotalCostLumpSum {get;set;}

    public Decimal SILSubtotalMisc { get; set; }
    public Decimal SILTaxTotalMisc { get; set; }
    public Decimal SILTotalMisc { get; set; }
    public Decimal SILProfitMarginMisc { get; set; }
    public Decimal SILTotalCostMisc { get; set; }

    public Decimal SurchargeAmount {get;set;} //AES-438
    public Decimal SurchargeAmtInclTax {get;set;} //AES-438

    //public Contact theBTContact {get; set; } //Ticket# AES-401
    //public Contact theSiteContact {get; set; } //Ticket# AES-401
    public Decimal invoiceTotal{get;set;}
    public Map<String, String> fieldNameCategoryMap;
    private Boolean EISurchargeLineFound = false; //14250
    private Boolean FuelSurchargeLineFound = false; // 14250
    private Boolean ESICSurchargeLineFound = false;
    public String creditMemoNote {get; set;} // 15090
    public String approvalComment {get; set;} //Ticket#16912

    public Decimal RetainageAmount {get; set;}

    public SalesInvoiceController(Id salesInvoiceId) {
        SIId = salesInvoiceId;
        this.SkipPostingMessage = true;
        selectSI();
        selectSILList();
        setRemittance();
    }
    
    public SalesInvoiceController(ApexPages.StandardController controller) {
        theController = controller;
        SIId = ApexPages.currentPage().getParameters().get('id');
        if (SIId != null) {
            selectSI();
            selectSILList();
            setRemittance();
            validatePostFunctionEligibility();
        } else {
            theSI = new Sales_Invoice__c();
            theSI.Invoice_Date__c = Date.today();
            theSI.Document_Status__c = 'Open';
            theSI.Sales_Invoice_Status__c = 'Open';
            theSILList = new List<Sales_Invoice_Line__c>();
        }
        CalculateTotal();
    }

    public Boolean allowDataOverride { get {return CompanyMgmt.allowDataOverride();} }

    private void selectSI() {
        theSI = SalesInvoicesSelector.newInstance().selectById(new Set<Id>{SIId})[0];
    }

    private void selectSILList() {
        theSILList = SalesInvoiceLinesSelector.newInstance().selectByInvoiceId(SIId);

    }
    
    public void validatePostFunctionEligibility(){
        if(theSI.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c && CompanyMgmt.getVFPageName() =='PostSalesInvoice'){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The Post function has been disabled for this Service Center'));
        }
    }

    private void setRemittance() {
        if (String.isNotEmpty(theSI.Contract__c) && theSI.Contract__r.Override_Remittance_on_Invoice__c) {
            remName = theSI.Contract__r.Remittance_Name__c;
            remAdd1 = theSI.Contract__r.Remittance_Address_1__c;
            remAdd2 = theSI.Contract__r.Remittance_Address_2__c;
            eftBank = theSI.Contract__r.EFT_To_Bank_Name__c;
            eft1 = theSI.Contract__r.EFT_Address_1__c;
            eft2 = theSI.Contract__r.EFT_Address_2__c;
            chk1 = theSI.Contract__r.Checking_Account_1__c;
            chk2 = theSI.Contract__r.Checking_Account_2__c;
            remPhone = theSI.Contract__r.Remittance_Phone__c;
            useContractlogo = true;
        } else if (theSI.Service_Center__r.Override_Remittance_on_Invoice__c) {
            remName = theSI.Service_Center__r.Remittance_Name__c;
            remAdd1 = theSI.Service_Center__r.Remittance_Address_1__c;
            remAdd2 = theSI.Service_Center__r.Remittance_Address_2__c;
            eftBank = theSI.Service_Center__r.EFT_To_Bank_Name__c;
            eft1 = theSI.Service_Center__r.EFT_Address_1__c;
            eft2 = theSI.Service_Center__r.EFT_Address_2__c;
            chk1 = theSI.Service_Center__r.Checking_Account_1__c;
            chk2 = theSI.Service_Center__r.Checking_Account_2__c;
            remPhone = theSI.Service_Center__r.Remittance_Phone__c;
            useSClogo = true;
        } else {
            remName = CompanySetup.Remittance_Name__c;
            remAdd1 = CompanySetup.Remittance_Address_1__c;
            remAdd2 = CompanySetup.Remittance_Address_2__c;
            eftBank = CompanySetup.EFT_to_Bank_Name__c;
            eft1 = CompanySetup.EFT_Address_1__c;
            eft2 = CompanySetup.EFT_Address_2__c;
            chk1 = CompanySetup.Checking_Account_1__c;
            chk2 = CompanySetup.Checking_Account_2__c;
            remPhone = CompanySetup.Remittance_Phone__c;
            useCompanylogo = true;
        }
        if (theSI.Credit_Memo__c == true){
            documentType = 'CR. MEMO';
            documentDate = 'CR. MEMO DATE';
        } else {
            documentType = 'INVOICE';
            documentDate = 'INVOICE DATE';
        }
    }

    public String title {
        get {
            if (SIId == null) {
                return 'New Invoice';
            } else {
                return theSI.Name;
            }
        }
    }
    public String docType {
        get {
            if (!theSI.Credit_Memo__c) {
                return 'Sales Invoice';
            } else {
                return 'Credit Memo';
            }
        }
    }

    public Sales_Invoice__c SI {
        get {
            return theSI;
        }
    }

    public Boolean posted {
        get {
            //Ticket#Void Sales Invoice
            if (theSI.Document_Status__c == 'Posted' || theSI.Document_Status__c == 'Void') {
                return true;
            } else {
                return false;
            }
        }
    }

    public Company_Setup__c CompanySetup {
        get {
            return theCompanySetup;
        }
    }

    public List<String> getMessages() {
        return new List<String>{
                'Document Status: ' + theSI.Document_Status__c, '', ''
        };
    }

    public void validateBillToCustomer() {
        theSI = SalesInvoiceMgmt.validateBillToCustomer(theSI);
    }

    public void validateInvoiceDate() {
        validatePaymentTerm();
    }

    public void validatePaymentTerm() {
        theSI = SalesInvoiceMgmt.validatePaymentTerm(theSI);
    }

    public void validateTaxArea() {
        theSI = SalesInvoiceMgmt.validateTaxArea(theSI);
        reInsertSIL();
    }

    public void validateTaxLiable() {
        reInsertSIL();
    }
    // Ticket# AES-401
    public void validateContact() {
        /*System.debug('validate Contact called==>');
        theSI = SalesInvoiceMgmt.validateContact(theSI);*/
        String contactId = ApexPages.currentPage().getParameters().get('contactId');
        String fieldId = ApexPages.currentPage().getParameters().get('fieldId');
        System.debug('***contactId' + contactId);
        System.debug('***fieldId' + fieldId);
        if (!String.isEmpty(contactId)){
            List<Contact> contacts = [SELECT Id, FirstName, LastName, Name FROM Contact WHERE Id = :contactId];
            if (contacts.size() > 0){
                if(fieldId == 'theBTContact') {
                    theSI.Contact__c = contacts[0].Id;
                    theSI.Contact__r = contacts[0];
                    //theBTContact = contacts[0];
                } else {
                    theSI.Site_Contact_2__c = contacts[0].Id;
                    theSI.Site_Contact_2__r = contacts[0];
                    //theSiteContact = contacts[0];
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contact does not exist!' + contactId));
            }
        }
    }

    //Ticket#18141
    public void validateAppliesToDoc(){
        try {
            String appliedToDocId = ApexPages.currentPage().getParameters().get('appliedToDocId');
            System.debug('Info: appliedToDocId ' + appliedToDocId);
            if (String.isNotBlank(appliedToDocId)) {
                List<Sales_Invoice__c> salesInvoices = SalesInvoicesSelector.newInstance().selectById(new Set<Id>{
                        appliedToDocId
                });
                if (salesInvoices.size() > 0) {
                    theSI.Reversed_from_SI__c = salesInvoices[0].Id;
                    theSI.Reversed_from_SI__r = salesInvoices[0];
                    if(theSI.Credit_Memo_Reason_Code__c == 'Customer is tax exempt') {
                        SalesInvoicesService.autoReverseTaxAmount(salesInvoices[0], theSI, theSILList);
                        CalculateTotal();
                    }
                } else {
                    throw new DataException('Invoiced applied-to invoice number selected!');
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invoiced applied-to invoice number selected!'));
                }
            } else {
                theSI.Reversed_from_SI__c = null;
            }
        } catch (Exception e){
            System.debug('Error: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }

    public void calcRetainageAmt(){
        try{
            if(theSI.Retainage_Pct__c > 100){
                throw new DataException('Retainage % cannot be greater than 100%!');
            }
            theSI.Retainage_Amount__c = SalesInvoicesService.calcRetainageAmount(theSI.Invoice_Amt_Incl_Tax__c, theSI.Retainage_Pct__c);
        } catch (Exception e){
            theSI.Retainage_Pct__c = 0;
            theSI.Retainage_Amount__c = 0;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }
    public List<Sales_Invoice_Line__c > SILList {
        get {
            return theSILList;
        }
        private set {
            theSILList = value;
        }
    }

    public List<Sales_Invoice_Line__c > SILListLabor {
        get {
            theSILListLabor = new List<Sales_Invoice_Line__c>();
            for (Sales_Invoice_Line__c theSIL : SILList) {
                if (theSIL.Category__c == 'Labor') {
                    theSILListLabor.add(theSIL);
                }
            }
            return theSILListLabor;
        }
        private set {
            theSILListLabor = value;
        }
    }

    public List<Sales_Invoice_Line__c > SILListEquipment {
        get {
            theSILListEquipment = new List<Sales_Invoice_Line__c>();
            for (Sales_Invoice_Line__c theSIL : SILList) {
                if (theSIL.Category__c == 'Equipment') {
                    theSILListEquipment.add(theSIL);
                }
            }
            return theSILListEquipment;
        }
        private set {
            theSILListEquipment = value;
        }
    }

    public List<Sales_Invoice_Line__c > SILListMaterials {
        get {
            theSILListMaterials = new List<Sales_Invoice_Line__c>();
            for (Sales_Invoice_Line__c theSIL : SILList) {
                if (theSIL.Category__c == 'Materials') theSILListMaterials.add(theSIL);
            }
            return theSILListMaterials;
        }
        private set {
            theSILListMaterials = value;
        }
    }

    public List<Sales_Invoice_Line__c > SILListSubcontractors {
        get {
            theSILListSubcontractors = new List<Sales_Invoice_Line__c>();
            for (Sales_Invoice_Line__c theSIL : SILList) {
                if (theSIL.Category__c == 'Subcontractors') theSILListSubcontractors.add(theSIL);
            }
            return theSILListSubcontractors;
        }
        private set {
            theSILListSubcontractors = value;
        }
    }

    public List<Sales_Invoice_Line__c > SILListWasteDisposal {
        get {
            theSILListWasteDisposal = new List<Sales_Invoice_Line__c>();
            for (Sales_Invoice_Line__c theSIL : SILList) {

                if (theSIL.Category__c == 'Waste Disposal') theSILListWasteDisposal.add(theSIL);
            }
            return theSILListWasteDisposal;
        }
        private set {
            theSILListWasteDisposal = value;
        }
    }

    public List<Sales_Invoice_Line__c > SILListDemurrage {
        get {
            theSILListDemurrage = new List<Sales_Invoice_Line__c>();
            for (Sales_Invoice_Line__c theSIL : SILList) {

                if (theSIL.Category__c == 'Demurrage')  theSILListDemurrage.add(theSIL);
            }
            return theSILListDemurrage;
        }
        private set {
            theSILListDemurrage = value;
        }
    }

    public List<Sales_Invoice_Line__c > SILListLumpSum {
        get {
            theSILListLumpSum = new List<Sales_Invoice_Line__c>();
            for (Sales_Invoice_Line__c theSIL : SILList) {

                if (theSIL.Category__c == 'Bundled')  theSILListLumpSum.add(theSIL);
            }
            return theSILListLumpSum;
        }
        private set {
            theSILListLumpSum = value;
        }
    }

    public List<Sales_Invoice_Line__c > SILListMisc {
        get {
            theSILListMisc = new List<Sales_Invoice_Line__c>();
            for (Sales_Invoice_Line__c theSIL : SILList) {
                if (theSIL.Category__c == 'Misc. Charges And Taxes')   theSILListMisc.add(theSIL);
            }
            return theSILListMisc;
        }
        private set {
            theSILListMisc = value;
        }
    }

    public void msave() {
        if(theSI.Misc_Invoice__c == true) {
            CompanyMgmt.systemCall = true;
        }
        // Delete lines without Item No. in the temporary list
        // Not sure to delete lines when save SZ 032118
        Integer i = 0;
        while (i < theSILList.size()) {
            if (String.isEmpty(theSILList[i].Resource__c)) {
                if(theSILList[i].Resource_Type__r.Fleet_No_Required__c == true && theSILList[i].Category__c == ResourceService.EQUIPMENT_CATEGORY){
                    theSILList.remove(i);
                } else if (theSILList[i].Category__c != ResourceService.EQUIPMENT_CATEGORY){
                    theSILList.remove(i);
                } else {
                    i++;
                }
            } else {
                i++;
            }
        }

        List<Sales_Invoice_Line__c> delSILList = new List<Sales_Invoice_Line__c>();

        // Delete lines that are not found in the temporary list
        for (Sales_Invoice_Line__c salesLine : [SELECT Id FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c = :SIId]) {
            Boolean lineFound = false;
            for (Sales_Invoice_Line__c salesLine2 : theSILList) {
                if (salesLine.Id == salesLine2.Id) {
                    lineFound = true;
                }
            }

            if (lineFound == false) delSILList.add(salesLine);
        }
        if (!delSILList.isEmpty()) {
            try {
                delete delSILList;
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        }

        Sales_Invoice__c oldSI = theSI.clone(true); // #GFERP-287
        List<Sales_Invoice_Line__c> oldSILList = new List<Sales_Invoice_Line__c>(); //#GFERP-287
        // Savepoint
        Savepoint sp = Database.setSavepoint();

        //Check Errors
        List<String> errorList = new List<String>();
        errorList = SalesInvoiceMgmt.checkSave(theSI, theSILList);
        if (errorList.size() > 0) {
            for (i = 0; i < errorList.size(); i++) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorList[i]));
            }
            return;
        } else {
            try {
                //THIS FOR LOOP MUST BE FIRST, MOVING LINES TO TEMP OLD LIST, BEFORE ANY ERROR IS THROWN
                //Save SIL first in case upsert theSI has error
                for (Sales_Invoice_Line__c SIL : theSILList) {
                    oldSILList.add(SIL.clone(true));
                }

                if(String.isNotBlank(theSI.Bill_to_Customer__c)){
                    List<Account> billToCusts = AccountsSelector.newInstance().selectById(new Set<Id>{theSI.Bill_to_Customer__c});
                    if(billToCusts.size() > 0){
                        if(String.isNotBlank(theSI.Customer_PO_No__c)){
                            AccountsService.validatePONumberFormat(billToCusts[0], theSI.Customer_PO_No__c);
                        }
                        /*
                        theSI.Billing_Instructions__c = AccountsService.generateBillingInstruction(
                                billToCusts[0].PO_Number_Type__c,
                                billToCusts[0].PO_Number_Format__c,
                                billToCusts[0].Invoice_Email_Contact_Type__c,
                                billToCusts[0].Invoice_Submission_Channel__c,
                                billToCusts[0].Invoice_Portal__c,
                                billToCusts[0].Invoice_Backup__c,
                                theSI.Billing_Instructions__c);
                         */
                    }
                }

                if(theSI.Approval_Status__c == EnumUtil.ApprovalStatus.PENDING_APPROVAL.name()){
                    throw new DataException('Invoice record cannot be modify, it is pending for approval!');
                }

                theSI = SalesInvoiceMgmt.nullRelationshipFields(theSI);

                upsert theSI;

                // 14250 Toggle functions with different selected Surcharge Type
                List<Sales_Invoice_Line__c> deleteList = new List<Sales_Invoice_Line__c>();
                if (theSI.Surcharge_Type__c == 'EEC Fee' ) {
                    if (EISurchargeLineFound) {
                        updateDemurrageSurchargeLine();
                    } else {
                        removeDemurrageSurchargeLine(deleteList);
                        addDemurrageSurchargeLine(theSI.Surcharge_Type__c);
                    }
                } else if (theSI.Surcharge_Type__c == 'Fuel Surcharge') {
                    if (FuelSurchargeLineFound) {
                        updateDemurrageSurchargeLine();
                    } else {
                        removeDemurrageSurchargeLine(deleteList);
                        addDemurrageSurchargeLine(theSI.Surcharge_Type__c);
                    }
                } else {
                    if(ESICSurchargeLineFound){
                        updateDemurrageSurchargeLine();
                    }
                    else{
                    	removeDemurrageSurchargeLine(deleteList);
                        addDemurrageSurchargeLine(theSI.Surcharge_Type__c);
                    }
                }
                upsert theSILList;

                if(theSI.Misc_Invoice__c == true){
                    System.debug('Info: checking');
                    Decimal appliedToBalance = 0;
                    Decimal creditAmountInclTax = 0;
                    List<Sales_Invoice__c> appliesToInvoices = new List<Sales_Invoice__c>();
                    if(String.isNotBlank(theSI.Reversed_from_SI__c)){
                        appliesToInvoices = [SELECT Id, Name, Balance__c FROM Sales_Invoice__c WHERE Id = :theSI.Reversed_from_SI__c];
                        if(appliesToInvoices.size() > 0){
                            appliedToBalance = appliesToInvoices[0].Balance__c;

                            for(Sales_Invoice_Line__c salesInvoiceLine : theSILList){
                                creditAmountInclTax = creditAmountInclTax + CompanyMgmt.zeroIfNull(salesInvoiceLine.Line_Amt_Incl_Tax__c);
                            }

                            creditAmountInclTax = Math.abs(creditAmountInclTax);

                            System.debug('Info: appliedToBalance ' + appliedToBalance);
                            System.debug('Info: creditAmountInclTax ' + creditAmountInclTax);

                            if(creditAmountInclTax > appliedToBalance){
                                String message = 'Credit Memo amount: ' + creditAmountInclTax + ' is larger than remaining balance ' + appliedToBalance + ' on applies-to invoice# ' + appliesToInvoices[0].Name;
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, message));
                                System.debug('Info: message ' + message);
                            }
                        }
                    }
                }

                if(deleteList.size() > 0) {
                    delete deleteList;
                }
                return;
            } catch (exception e) {
                Database.rollback(sp);
                theSI = oldSI;
                theSILList = oldSILList;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return;
            }
        }
    }

    // 14250
    public void addDemurrageSurchargeLine (String surchargeType){
        CalculateTotalOrder();
        Integer SILineListSize = theSILList.size();
        Decimal displayNo = 0;
        if (SILineListSize > 0 && theSILList[SILineListSize - 1].Line_No__c != null) displayNo = theSILList[SILineListSize - 1].Line_No__c;
        displayNo = displayNo + 1;
        Sales_Invoice_Line__c surchargeLine = new Sales_Invoice_Line__c();
        surchargeLine.Sales_Invoice__c = theSI.Id;
        surchargeLine.Category__c = 'Misc. Charges And Taxes';
        surchargeLine.Line_No__c = displayNo;
        //surchargeLine.Non_Billable__c = true;
        surchargeLine.Tax_Group__c = 'NT';
        if (surchargeType == 'EEC Fee') {
            surchargeLine.Resource__c = theCompanySetup.Default_Energy_Insurance_Resource__c;
            surchargeLine.Description__c = theCompanySetup.Default_Energy_Insurance_Resource__r.Description__c;
            surchargeLine.Resource__r = new Resource__c(Id = theCompanySetup.Default_Energy_Insurance_Resource__c, Name = theCompanySetup.Default_Energy_Insurance_Resource__r.Name);
        } else if (surchargeType == 'Fuel Surcharge') {
            surchargeLine.Resource__c = theCompanySetup.Default_Fuel_Surcharge_Resource__c;
            surchargeLine.Description__c = theCompanySetup.Default_Fuel_Surcharge_Resource__r.Description__c;
            surchargeLine.Resource__r = new Resource__c(Id = theCompanySetup.Default_Fuel_Surcharge_Resource__c, Name = theCompanySetup.Default_Fuel_Surcharge_Resource__r.Name);
        }
        else{
            //ESIC
            surchargeLine.Resource__c = theCompanySetup.Default_ESIC_Surcharge_Resource__c;
            surchargeLine.Description__c = theCompanySetup.Default_ESIC_Surcharge_Resource__r.Description__c;
            surchargeLine.Resource__r = new Resource__c(Id = theCompanySetup.Default_ESIC_Surcharge_Resource__c, Name = theCompanySetup.Default_ESIC_Surcharge_Resource__r.Name);
        }
        surchargeLine.Unit_of_Measure__c = CompanyMgmt.getResource(surchargeLine.Resource__c).Unit_of_Measure__c;
        surchargeLine.Quantity__c = 1;
        surchargeLine.Unit_Price__c = SurchargeAmount;
        surchargeLine.Line_Amount__c = SurchargeAmount;
        surchargeLine.Tax__c = 0.00;
        surchargeLine.Line_Amt_Incl_Tax__c = SurchargeAmount;
        surchargeLine.System_Calculated_Line__c = true;
        theSILList.add(surchargeLine);
    }

    public void removeDemurrageSurchargeLine (List<Sales_Invoice_Line__c> deleteList){
        for (Sales_Invoice_Line__c theSIL : theSILList) {
            if (theSIL.Resource__c == theCompanySetup.Default_Energy_Insurance_Resource__c ||
                    theSIL.Resource__c == theCompanySetup.Default_Fuel_Surcharge_Resource__c  || 
               			theSIL.Resource__c == theCompanySetup.Default_ESIC_Surcharge_Resource__c) {
                deleteList.add(theSIL);
            }
        }

    }
    public void updateDemurrageSurchargeLine(){
        CalculateTotalOrder();
        for (Sales_Invoice_Line__c theSIL : theSILList) {
            if (theSIL.Resource__c == theCompanySetup.Default_Energy_Insurance_Resource__c ||
                    theSIL.Resource__c == theCompanySetup.Default_Fuel_Surcharge_Resource__c ||
               			theSIL.Resource__c == theCompanySetup.Default_ESIC_Surcharge_Resource__c) {
                theSIL.Unit_Price__c = SurchargeAmount;
                theSIL.Line_Amount__c = SurchargeAmount;
                theSIL.Line_Amt_Incl_Tax__c = SurchargeAmount;
                break;
            }
        }
    }

    public pagereference save() {
        System.debug('****ashish' + ' One');
        msave();
        System.debug('****ashish' + ' three');
        if (!ApexPages.hasMessages()) {
            PageReference SalesInvoicePage = new PageReference('/' + theSI.Id);
            SalesInvoicePage.setRedirect(true);
            return SalesInvoicePage;
        } else
                return null;
    }

    public pagereference quickSave() {
        msave();
        if (!ApexPages.hasMessages()) {
            PageReference SalesInvoicePage = new PageReference('/apex/SalesInvoice?id=' + theSI.Id);
            SalesInvoicePage.setRedirect(true);
            return SalesInvoicePage;
        } else {
            return null;
        }
    }

    public pagereference quickSaveForLinePaginationPage() {
        msave();
        if (!ApexPages.hasMessages()) {
            PageReference SalesInvoicePage = new PageReference('/apex/SalesInvoiceWithLinePagination?id=' + theSI.Id);
            SalesInvoicePage.setRedirect(true);
            return SalesInvoicePage;
        } else {
            return null;
        }
    }

    //Ticket#13607
    public PageReference updatePostedSI(){
        try{
            update theSI;
            PageReference SalesInvoicePage = new PageReference('/' + theSI.Id);
            SalesInvoicePage.setRedirect(true);
            return SalesInvoicePage;
        } catch (Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage()));
            return null;
        }
    }

    public PageReference cloneSalesInvoice() {
        CompanyMgmt.systemCall = true;
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You are not allowed to clone sales invoices.'));
        return null;
    }

    public PageReference deleteSalesInvoice() {
        Set<string> setTM = new Set<string>();
        Set<string> setTML = new Set<string>();
        companyMgmt.systemCall = true;
        // Savepoint
        Savepoint sp = database.setSavePoint();
        // Check Errors
        // Logics are in SalesTriggerManagement
        try {
            if (theSI.Document_Status__c == 'Posted') {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You are not allowed to delete Posted Sales Invoice.')); return null;
            }
            if (theSI.Credit_Memo__c != true){
                List<TM__c> theTMList = new List<TM__c>();
                List<TM_Line__c> theTMLList = new List<TM_Line__c>();
                if(theSILList != null && theSILList.size() > 0) {
                    for(Sales_Invoice_Line__c SIL : theSILList) {
                        if(SIL.TM__c != null && !setTM.contains(SIL.TM__c)) {
                            setTM.add(SIL.TM__c);
                        }
                        if (SIL.TM_Line__c != null && !setTML.contains(SIL.TM_Line__c)) {
                            setTML.add(SIL.TM_Line__c);
                        }
                    }
                    if (setTML.size() > 0) {
                        theTMLList = [SELECT Invoiced__c FROM TM_Line__c WHERE Id IN:setTML];
                        for (TM_Line__c TML : theTMLList) {
                            TML.Invoiced__c = false;
                        }
                        upsert theTMLList;
                    }
                    if(setTM.size() > 0) {
                        theTMList = [SELECT Id, Name, Total_Lines__c, Invoiced_Lines__c, Status__c FROM TM__c WHERE Id IN:setTM];
                        if(theTMList != null && theTMList.size() > 0) {
                            theTMList = TMMgmt.updateTMStatus(theTMList);
                        }
                    }
                }
                // Update T&M
                update theTMList;
            } else {
                // Update Reverse SI
                if (!theSI.Misc_Invoice__c && theSI.Reversed_from_SI__c != null){
                    Sales_Invoice__c theReversedfromSI = [
                            SELECT Name, Reversed__c, Reversed_from_SI__c
                            FROM Sales_Invoice__c
                            WHERE Id = :theSI.Reversed_from_SI__c
                    ];
                    theReversedfromSI.Reversed__c = false;
                    theReversedfromSI.Reversed_from_SI__c = null;
                    update theReversedfromSI;
                }
            }

            // Delete header
            // No need to delete lines separately
            delete theSI;

            return new ApexPages.Action('{!List}').invoke();
        } catch (exception e) {
            // Rollback
            Database.Rollback(sp);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
            return null;
        }
    }

    public PageReference cancel() {
        return theController.cancel();
    }

    public PageReference returnBack() {
        return theController.view();
    }

    public PageReference addLine() {
        if (theSILList == null) theSILList = new List<Sales_Invoice_Line__c>();
        integer SILineListSize = theSILList.size();
        string description = '';
        Id resource = null;
        Resource__c theResource;
        Unit_of_Measure__c theUnitOfMeasure;
        integer LinesToInsert = 1;
        decimal displayNo = 0;
        decimal unitCost = 0;

        if (theSILList != null && theSILList.size() > 0) {
            if (theSILList[SILineListSize - 1].Line_No__c != null) {
                displayNo = theSILList[SILineListSize - 1].Line_No__c;
            }
        }
        String objectType = ApexPages.CurrentPage().getParameters().get('ObjectType');
        String lineCategory = ApexPages.CurrentPage().getParameters().get('LineCategory');

        if (lineCategory == 'Waste Disposal') {
            resource = theCompanySetup.Default_Waste_Disposal_Resource__c;
            description = theCompanySetup.Default_Waste_Disposal_Resource__r.Name;
            //LinesToInsert = 1;
            unitCost = companyMgmt.zeroIfNull(theCompanySetup.Default_Waste_Disposal_Resource__r.Unit_Cost__c);
        } else if (lineCategory == 'Bundled') {
            resource = theCompanySetup.Default_Lump_Sum_Resource__c;
            description = theCompanySetup.Default_Lump_Sum_Resource__r.Name;
            //LinesToInsert = 1;
            unitCost = companyMgmt.zeroIfNull(theCompanySetup.Default_Lump_Sum_Resource__r.Unit_Cost__c);
        } else if (lineCategory == 'Misc. Charges And Taxes') {
            resource = theCompanySetup.Default_Misc_Charges_Taxes_Resource__c;
            description = theCompanySetup.Default_Misc_Charges_Taxes_Resource__r.Name;
            //LinesToInsert = 1;
            unitCost = companyMgmt.zeroIfNull(theCompanySetup.Default_Misc_Charges_Taxes_Resource__r.Unit_Cost__c);
        } else if (lineCategory == 'Subcontractors') {
            resource = theCompanySetup.Default_Subcontractor_Resource__c;
            //description = theCompanySetup.Default_Subcontractor_Resource__r.Name;
            //LinesToInsert = 1;
            unitCost = companyMgmt.zeroIfNull(theCompanySetup.Default_Subcontractor_Resource__r.Unit_Cost__c);
        } else if (lineCategory == 'Demurrage') {
            description = '';
            //LinesToInsert = 1;
        } else if (lineCategory == 'Labor'){
            //billSiteTime = false;  // default bill job time
        }

        if (objectType == 'SILine') {
            if (LinesToInsert > 0) {
                for (Integer i = 0; i < LinesToInsert; i++) {
                    displayNo = displayNo + 1;
                    if (lineCategory != 'Labor' && lineCategory != 'Equipment' && lineCategory != 'Materials' && lineCategory != 'Demurrage') {
                        theResource = [SELECT Id, Name, Unit_of_Measure__c FROM Resource__c WHERE Id = :resource LIMIT 1];
                        if (theResource.Unit_of_Measure__c != null) {
                            theUnitOfMeasure = [SELECT Id, Name FROM Unit_of_Measure__c WHERE Id = :theResource.Unit_of_Measure__c LIMIT 1];
                            theSILList.add(new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = displayNo,
                                    Category__c = lineCategory, Resource__c = resource, Description__c = description, Tax_Group__c = 'TX',
                                    Service_Center__c = theSI.Service_Center__c,
                                    Unit_of_Measure__c = theResource.Unit_of_Measure__c,
                                    Unit_of_Measure__r = new Unit_of_Measure__c(Id = theUnitOfMeasure.Id, Name = theUnitOfMeasure.Name),
                                    Quantity__c = 0, Unit_Price__c = 0,
                                    Unit_Cost__c = unitCost));
                        } else {
                            theSILList.add(new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = displayNo,
                                    Category__c = lineCategory, Resource__c = resource, Description__c = description, Tax_Group__c = 'TX',
                                    Service_Center__c = theSI.Service_Center__c,
                                    Quantity__c = 0, Unit_Price__c = 0,
                                    Unit_Cost__c = unitCost));
                        }
                    } else {
                        theSILList.add(new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = displayNo,
                                Service_Center__c = theSI.Service_Center__c,
                                Category__c = lineCategory, Resource__c = resource, Description__c = description, Tax_Group__c = 'TX',
                                Quantity__c = 0, Unit_Price__c = 0,
                                Unit_Cost__c = unitCost));
                    }
                }
            }
        }


        return null;
    }

    public PageReference deleteLine() {
        String objectType = ApexPages.CurrentPage().getParameters().get('objectType');
        String displayId = ApexPages.CurrentPage().getParameters().get('displayId');
        String lineType = ApexPages.CurrentPage().getParameters().get('lineType');
        system.debug('delete ' + displayId);

        if (displayId == '') displayId = '0';

        if (objectType == 'SILine') {
            for (Integer i = 0; i < theSILList.size(); i++) {
                system.debug('theSILList[i].Line_No__c***' + theSILList[i].Line_No__c);
                system.debug('displayId***' + displayId);
                if (companyMgmt.zeroIfNull(theSILList[i].Line_No__c) == decimal.valueOf(displayId) && theSILList[i].Category__c == lineType) {
                    theSILList.remove(i);break;
                }
            }
        }
        return null;
    }

    public PageReference postSI() {
        System.debug('###postSI Button begin ###');
        Set<String> setTM = new Set<String>();
        Set<Id> tmlineIds = new Set<Id>();
        List<TM_Line__c> theTMLineList = new List<TM_Line__c>();
        // To differentiate from standard edit page
        CompanyMgmt.systemCall = true;

        if (theSI.Posting_Date__c == null) {
            theSI.Posting_Date__c = Date.today();
        }
        // Savepoint
        Savepoint sp = Database.setSavepoint();

        List<String> errorList = new List<String>();
        errorList = SalesInvoiceMgmt.checkPost(theSI);
        if (errorList.size() > 0 && !Test.isRunningTest()) {
            for (Integer i = 0; i < errorList.size(); i++) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorList[i]));
            }
        } else {
            try {
                SalesInvoiceMgmt.postSI(theSILList, theSI);

                //Ticket#16965 - not so smart way to prevent two identical gl been posted.
                List<GL_Entry__c> glEntries = [SELECT Id FROM GL_Entry__c WHERE Sales_Invoice__c = :theSI.Id AND Account_Type__c = 'Customer'];
                if(glEntries.size() > 1){
                    throw new DataException('There is invoice may already posted please review!');
                }

                theSI.Document_Status__c = 'Posted';
                theSI.Sales_invoice_Posted_Date__c = Date.today();
                theSI.Sales_Invoice_Status__c = 'Posted';
                update theSI;

                //Update TML
                //job task <<
                Set<Id> worksheetLineIds = new Set<Id>();
                //job task >>
                for (Sales_Invoice_Line__c SIL : theSILList) {
                    if (SIL.TM_Line__c != null && !tmlineIds.contains(SIL.TM_Line__c)) {
                        tmlineIds.add(SIL.TM_Line__c);
                    }
                    //job task <<
                    if (SIL.Billing_Worksheet_Line__c != null) {
                        worksheetLineIds.add(SIL.Billing_Worksheet_Line__c);
                    }
                    //job task >>
                }

                //job task <<
                if (worksheetLineIds.size() > 0) {
                    if (theSI.Credit_Memo__c == true) {
                        List<Billing_Worksheet_Line__c> worksheetLines = [SELECT Id, Invoiced__c FROM Billing_Worksheet_Line__c WHERE Id IN :worksheetLineIds];
                        for (Billing_Worksheet_Line__c worksheetLine : worksheetLines) {
                            worksheetLine.Invoiced__c = false;
                        }
                        update worksheetLines;
                    }
                }
                //job task >>

                if (tmlineIds.size() > 0) {
                    theTMLineList = [SELECT Id, Name, Invoiced__c FROM TM_Line__c WHERE Id IN:tmlineIds];
                    if (theTMLineList != null && theTMLineList.size() > 0) {
                        for (TM_Line__c TML : theTMLineList) {
                            if (theSI.Credit_Memo__c == true) {
                                TML.Invoiced__c = false;
                            } else {
                                TML.Invoiced__c = true;
                            }
                        }
                    }
                }

                //ticket 19897 <<
                CompanyMgmt.byPassTrigger = true;
                //ticket 19897 >>
                update theTMLineList;

                //Update T&M
                List<TM__c> theTMList = new List<TM__c>();
                for (Sales_Invoice_Line__c SIL : theSILList) {
                    if (SIL.TM__c != null && !setTM.contains(SIL.TM__c)) {
                        setTM.add(SIL.TM__c);
                    }
                }

                if (setTM.size() > 0) {
                    theTMList = [SELECT Id, Name, Invoiced_Lines__c, Total_Lines__c , Status__c FROM TM__c WHERE Id IN:setTM];
                }

                theTMList = TMMgmt.updateTMStatus(theTMList);

                if (theTMList != null && theTMList.size() > 0) {
                    for (TM__c TM : theTMList) {
                        if (theSI.Credit_Memo__c) {
                            TM.Sales_Invoice__c = null;
                        } else {
                            TM.Sales_Invoice__c = theSI.Id;
                        }
                    }
                }
                //ticket 19897 <<
                CompanyMgmt.byPassTrigger = true;
                //ticket 19897 >>
                update theTMList;

                if (SkipPostingMessage == true) return null;
                
                if (!theSI.Credit_Memo__c) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'You have successfully posted Sales Invoice.'));
                } else {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'You have successfully posted Sales Credit Memo.'));
                }

            } catch (exception e) {
                // Rollback
                Database.Rollback(sp);
                System.debug('Exception Stack Trace ' + e.getStackTraceString());
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
                return null;
            }
        }
        System.debug('###postSI Button end ###');
        return null;
    }

    public PageReference unpostSI() {
        Set<String> setTM = new Set<String>();
        if (CompanyMgmt.checkUnpostPermission() == false && !Test.isRunningTest()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You are not allowed to unpost transactions.'));
        } else {
            // Savepoint
            Savepoint sp = Database.setSavepoint();

            List<String> errorList = new List<String>();
            errorList = SalesInvoiceMgmt.unpostCheck(theSI);
            if (errorList.size() > 0 && !Test.isRunningTest()) {
                for (Integer i = 0; i < errorList.size(); i++){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorList[i]));
                }
            } else {
                try {
                    SalesInvoiceMgmt.unpostSI(theSI);
                    theSI.Document_Status__c = 'Open';
                    theSI.Sales_Invoice_Status__c = 'Open';
                    theSI.Sales_invoice_Posted_Date__c = null;
                    update theSI;
                    //Update T&M
                    List<TM__c> theTMList = new List<TM__c>();
                    for (Sales_Invoice_Line__c SIL : theSILList) {
                        if (SIL.TM__c != null && !setTM.contains(SIL.TM__c)) {
                            setTM.add(SIL.TM__c);
                        }
                    }

                    if (setTM.size() > 0) {
                        theTMList = [SELECT Id, Name, Invoiced_Lines__c, Total_Lines__c , Status__c, Sales_Invoice__c,
                                        Sales_Invoice__r.Name, (SELECT Id, Invoiced__c FROM TM_Lines__r)
                                        FROM TM__c WHERE Id IN:setTM];
                    }

                    theTMList = TMMgmt.updateTMStatus(theTMList);
                    List<TM_Line__c> tmlLstUpdate = new List<TM_Line__c>();
                    if (theTMList != null && theTMList.size() > 0) {
                        for (TM__c TM : theTMList) {
                            if (theSI.Credit_Memo__c) {
                                if(String.isBlank(TM.Sales_Invoice__c)){
                                    TM.Sales_Invoice__c = theSI.Reversed_from_SI__c;
                                    TM.Status__c = 'Fully Invoiced';
                                    List<TM_Line__c> tmlLst = TM.TM_Lines__r;
                                    for(TM_Line__c tml : tmlLst){
                                        tml.Invoiced__c = true;
                                        tmlLstUpdate.add(tml);
                                    }
                                } else if (TM.Sales_Invoice__c != theSI.Reversed_from_SI__c && String.isNotBlank(theSI.Reversed_from_SI__c)){
                                    throw new DataException('Cannot un-post this credit memo because T&M associated with the credit memo is already re-invoiced');
                                }
                            } else {
                                TM.Sales_Invoice__c = theSI.Id;
                            }
                        }
                    }
                    update theTMList;
                    if(tmlLstUpdate.size() > 0) update tmlLstUpdate;

                    if (!theSI.Credit_Memo__c) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have successfully unposted Sales Invoice.'));
                    } else {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have successfully unposted Sales Credit Memo.'));
                    }
                } catch (Exception e) {
                    //Rollback
                    Database.rollback(sp);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                    return null;
                }
            }
        }
        return null;
    }

    public PageReference validateField() {
        setFieldNameCategoryMap();

        String fieldName = ApexPages.currentPage().getParameters().get('fieldName');
        Integer i = Integer.valueOf(ApexPages.currentPage().getParameters().get('lineNo'));
        String newFieldValue = ApexPages.currentPage().getParameters().get('newFieldValue');
        String Category = '';

        if (fieldName == 'theJobPosition') {
            if (String.isBlank(newFieldValue)) {
                system.debug('Testing' + i + theSILListLabor);
                theSILListLabor[i].Resource_Type__c = null;
                theSILListLabor[i].Resource_Type__r = null;
                theSILListLabor[i].Description__c = '';
                Decimal lineNo = theSILListLabor[i].Line_No__c;
                theSILListLabor[i] = new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = lineNo);
            } else {
                try {
                    theSILListLabor[i].Resource_Type__c = newFieldValue;
                    theSILListLabor[i].Quantity__c = 0;
                    System.debug('scott/847Value from lkup==>' + newFieldValue);
                    theSILListLabor[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListLabor[i], 'theJobPosition');
                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Labor';
        } else if (fieldName == 'theEquipment') {
            if (String.isBlank(newFieldValue)) {
                theSILListEquipment[i].Resource_Type__c = null;
                theSILListEquipment[i].Resource_Type__r = null;
                theSILListEquipment[i].Description__c = '';
                Decimal lineNo = theSILListEquipment[i].Line_No__c;
                theSILListEquipment[i] = new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = lineNo);
            } else {
                try {
                    theSILListEquipment[i].Resource_Type__c = newFieldValue;
                    theSILListEquipment[i].Quantity__c = 0;
                    theSILListEquipment[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListEquipment[i], 'theEquipment');

                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Equipment';
        } else if (fieldName == 'theLumpSumResourceType') {
            if (String.isBlank(newFieldValue)) {
                theSILListLumpSum[i].Resource_Type__c = null;
                theSILListLumpSum[i].Resource_Type__r = null;
                theSILListLumpSum[i].Description__c = '';
                Decimal lineNo = theSILListLumpSum[i].Line_No__c;
                theSILListLumpSum[i] = new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = lineNo);
            } else {
                try {
                    theSILListLumpSum[i].Resource_Type__c = newFieldValue;
                    theSILListLumpSum[i].Quantity__c = 0;
                    theSILListLumpSum[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListLumpSum[i], 'theLumpSumResourceType');

                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Bundled';
        } else if (fieldName == 'theMResource') {
            System.debug('Steven- M Resource');
            if (String.isBlank(newFieldValue)) {
                theSILListMaterials[i].Resource__c = null;
                theSILListMaterials[i].Resource__r = null;
                theSILListMaterials[i].Description__c = '';
                Decimal lineNo = theSILListMaterials[i].Line_No__c;
                theSILListMaterials[i] = new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = lineNo);
            } else {
                try {
                    theSILListMaterials[i].Resource__c = newFieldValue;
                    theSILListMaterials[i].Quantity__c = 0;
                    System.debug('scott1211');
                    theSILListMaterials[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListMaterials[i], 'theResource');

                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Materials';
        } else if (fieldName == 'theLResource') {
            system.debug('newFieldValue***' + newFieldValue);
            if (String.isBlank(newFieldValue)) {
                theSILListLabor[i].Resource__c = null;
                theSILListLabor[i].Resource__r = null;
                //theSILListLabor[i].Resource_Name__c = '';
                Decimal lineNo = theSILListLabor[i].Line_No__c;
                theSILListLabor[i] = new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = lineNo);
            } else {
                try {
                    theSILListLabor[i].Resource__c = newFieldValue;
                    theSILListLabor[i].Quantity__c = 0;
                    theSILListLabor[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListLabor[i], 'theLResource');

                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Labor';
        } else if (fieldName == 'theEResource') {
            if (String.isBlank(newFieldValue)) {
                theSILListEquipment[i].Resource__c = null;
                theSILListEquipment[i].Resource__r = null;
                //theSILListEquipment[i].Resource_Name__c = '';
                Decimal lineNo = theSILListEquipment[i].Line_No__c;
                theSILListEquipment[i] = new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = lineNo);
            } else {
                try {
                    theSILListEquipment[i].Resource__c = newFieldValue;
                    theSILListEquipment[i].Quantity__c = 0;
                    theSILListEquipment[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListEquipment[i], 'theEResource');

                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Equipment';
        } else if (fieldName == 'theSResource') {
            if (String.isBlank(newFieldValue)) {
                theSILListSubcontractors[i].Resource__c = null;
                theSILListSubcontractors[i].Resource__r = null;
                Decimal lineNo = theSILListSubcontractors[i].Line_No__c;
                theSILListSubcontractors[i] = new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = lineNo);
            } else {
                try {
                    theSILListSubcontractors[i].Resource__c = newFieldValue;
                    theSILListSubcontractors[i].Quantity__c = 0;
                    theSILListSubcontractors[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListSubcontractors[i], 'theResource');

                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Subcontractors';
        } else if (fieldName == 'theWResource') {
            //Ticket#13594
            if (String.isBlank(newFieldValue)) {
                theSILListWasteDisposal[i].Resource__c = null;
                theSILListWasteDisposal[i].Resource__r = null;
                Decimal lineNo = theSILListWasteDisposal[i].Line_No__c;
                theSILListWasteDisposal[i] = new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = lineNo);
            } else {
                try {
                    theSILListWasteDisposal[i].Resource__c = newFieldValue;
                    theSILListWasteDisposal[i].Quantity__c = 0;
                    theSILListWasteDisposal[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListWasteDisposal[i], 'theResource');

                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Waste Disposal';
        } else if (fieldName == 'theDResource') {
            if (String.isBlank(newFieldValue)) {
                theSILListDemurrage[i].Resource__c = null;
                theSILListDemurrage[i].Resource__r = null;
                Decimal lineNo = theSILListDemurrage[i].Line_No__c;
                theSILListDemurrage[i] = new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = lineNo);
            } else {
                try {
                    theSILListDemurrage[i].Resource__c = newFieldValue;
                    theSILListDemurrage[i].Quantity__c = 0;
                    theSILListDemurrage[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListDemurrage[i], 'theResource');
                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Demurrage';
        } else if (fieldName == 'theMiscResource') {
            if (String.isBlank(newFieldValue)) {
                theSILListMisc[i].Resource__c = null;
                theSILListMisc[i].Resource__r = null;
                theSILListMisc[i].Description__c = '';
                Decimal lineNo = theSILListMisc[i].Line_No__c;
                theSILListMisc[i] = new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = lineNo);
            } else {
                try {
                    theSILListMisc[i].Resource__c = newFieldValue;
                    theSILListMisc[i].Quantity__c = 0;
                    theSILListMisc[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListMisc[i], 'theResource');

                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Misc. Charges And Taxes';
        } else if (fieldName == 'theMiscResourceType') {
            if (String.isBlank(newFieldValue)) {
                theSILListMisc[i].Resource_Type__c = null;
                theSILListMisc[i].Resource_Type__r = null;
                theSILListMisc[i].Description__c = '';
                Decimal lineNo = theSILListMisc[i].Line_No__c;
                theSILListMisc[i] = new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = lineNo);
            } else {
                try {
                    theSILListMisc[i].Resource_Type__c = newFieldValue;
                    theSILListMisc[i].Quantity__c = 0;
                    theSILListMisc[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListMisc[i], 'theResourceType');

                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Misc. Charges And Taxes';
        } else if (fieldName == 'theLUOM') {
            system.debug('theSILListLabor[i].Unit_of_Measure__c***' + theSILListLabor[i].Unit_of_Measure__c);
            system.debug('newFieldValue***' + newFieldValue);
            if (String.isBlank(newFieldValue)) {
                theSILListLabor[i].Unit_of_Measure__c = null;
                theSILListLabor[i].Unit_of_Measure__r = null;
            } else {
                System.debug('eValue from lkup==>' + newFieldValue);

                set<Id> setUOM = new set<Id>();
                if (!string.isEmpty(theSILListLabor[i].Resource_Type__c)) {
                    Resource_Type__c theResourceType = CompanyMgmt.getResourceType(theSILListLabor[i].Resource_Type__c);

                    setUOM.add(theResourceType.Unit_of_Measure__c);
                    setUOM.add(theResourceType.Unit_of_Measure1__c);
                    setUOM.add(theResourceType.Unit_of_Measure2__c);
                    setUOM.add(theResourceType.Unit_of_Measure3__c);
                    setUOM.add(theResourceType.Unit_of_Measure4__c);
                }

                if (setUOM != null && setUOM.size() > 0 && setUOM.contains(newFieldValue)) {
                    theSILListLabor[i].Unit_of_Measure__c = newFieldValue;
                    theSILListLabor[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListLabor[i], 'theUOM');
                } else {
                    theSILListLabor[i].Unit_of_Measure__c = null; //Ticket#14606
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Unit of Measure is not defined on the Resource Type.'));
                    return null;
                }
            }
            system.debug('theSILListLabor[i].Unit_of_Measure__c***' + theSILListLabor[i].Unit_of_Measure__c);
            Category = 'Labor';
        } else if (fieldName == 'theMUOM') {
            if (String.isBlank(newFieldValue)) {
                theSILListMaterials[i].Unit_of_Measure__c = null;
                theSILListMaterials[i].Unit_of_Measure__r = null;
            } else {
                System.debug('eValue from lkup==>' + newFieldValue);

                set<Id> setUOM = new set<Id>();
                if (!string.isEmpty(theSILListMaterials[i].Resource__c)) {
                    Resource__c theResource = CompanyMgmt.getResource(theSILListMaterials[i].Resource__c);

                    setUOM.add(theResource.Unit_of_Measure__c);
                    setUOM.add(theResource.Unit_of_Measure1__c);
                    setUOM.add(theResource.Unit_of_Measure2__c);
                    setUOM.add(theResource.Unit_of_Measure3__c);
                    setUOM.add(theResource.Unit_of_Measure4__c);
                }

                if (setUOM != null && setUOM.size() > 0 && setUOM.contains(newFieldValue)) {
                    theSILListMaterials[i].Unit_of_Measure__c = newFieldValue;
                    theSILListMaterials[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListMaterials[i], 'theUOM');
                } else {
                    theSILListMaterials[i].Unit_of_Measure__c = null; //Ticket#14606
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Unit of Measure is not defined on the Resource.'));
                    return null;
                }
            }
            Category = 'Materials';
        } else if (fieldName == 'theEUOM') {
            if (String.isBlank(newFieldValue)) {
                theSILListEquipment[i].Unit_of_Measure__c = null;
                theSILListEquipment[i].Unit_of_Measure__r = null;
            } else {
                System.debug('eValue from lkup==>' + newFieldValue);

                set<Id> setUOM = new set<Id>();
                if (!string.isEmpty(theSILListEquipment[i].Resource_Type__c)) {
                    Resource_Type__c theResourceType = CompanyMgmt.getResourceType(theSILListEquipment[i].Resource_Type__c);

                    setUOM.add(theResourceType.Unit_of_Measure__c);
                    setUOM.add(theResourceType.Unit_of_Measure1__c);
                    setUOM.add(theResourceType.Unit_of_Measure2__c);
                    setUOM.add(theResourceType.Unit_of_Measure3__c);
                    setUOM.add(theResourceType.Unit_of_Measure4__c);
                }

                if (setUOM != null && setUOM.size() > 0 && setUOM.contains(newFieldValue)) {
                    theSILListEquipment[i].Unit_of_Measure__c = newFieldValue;
                    theSILListEquipment[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListEquipment[i], 'theUOM');
                } else {
                    theSILListEquipment[i].Unit_of_Measure__c = null; //Ticket#14606
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Unit of Measure is not defined on the Resource Type.'));
                    return null;
                }
            }
            Category = 'Equipment';
        } else if (fieldName == 'theSUOM') {
            if (String.isBlank(newFieldValue)) {
                theSILListSubcontractors[i].Unit_of_Measure__c = null;
                theSILListSubcontractors[i].Unit_of_Measure__r = null;
            } else {
                theSILListSubcontractors[i].Unit_of_Measure__c = newFieldValue;
                theSILListSubcontractors[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListSubcontractors[i], 'theUOM');
            }
            Category = 'Subcontractors';
        } else if (fieldName == 'theWUOM') {
            if (String.isBlank(newFieldValue)) {
                theSILListWasteDisposal[i].Unit_of_Measure__c = null;
                theSILListWasteDisposal[i].Unit_of_Measure__r = null;
            } else {
                theSILListWasteDisposal[i].Unit_of_Measure__c = newFieldValue;
                theSILListWasteDisposal[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListWasteDisposal[i], 'theUOM');
            }
            Category = 'Waste Disposal';
        } else if (fieldName == 'theDUOM') {
            if (String.isBlank(newFieldValue)) {
                theSILListDemurrage[i].Unit_of_Measure__c = null;
                theSILListDemurrage[i].Unit_of_Measure__r = null;
            } else {
                System.debug('eValue from lkup==>' + newFieldValue);

                set<Id> setUOM = new set<Id>();
                if (!string.isEmpty(theSILListDemurrage[i].Resource__c)) {
                    Resource__c theResource = CompanyMgmt.getResource(theSILListDemurrage[i].Resource__c);

                    setUOM.add(theResource.Unit_of_Measure__c);
                    setUOM.add(theResource.Unit_of_Measure1__c);
                    setUOM.add(theResource.Unit_of_Measure2__c);
                    setUOM.add(theResource.Unit_of_Measure3__c);
                    setUOM.add(theResource.Unit_of_Measure4__c);
                }

                if (setUOM != null && setUOM.size() > 0 && setUOM.contains(newFieldValue)) {
                    theSILListDemurrage[i].Unit_of_Measure__c = newFieldValue;
                    theSILListDemurrage[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListDemurrage[i], 'theUOM');
                } else {
                    theSILListDemurrage[i].Unit_of_Measure__c = null; //Ticket#14606
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Unit of Measure is not defined on the Resource.'));
                    return null;
                }
            }
            Category = 'Demurrage';
        } else if (fieldName == 'theLumpUOM') {
            if (String.isBlank(newFieldValue)) {
                theSILListLumpSum[i].Unit_of_Measure__c = null;
                theSILListLumpSum[i].Unit_of_Measure__r = null;
            } else {
                System.debug('eValue from lkup==>' + newFieldValue);

                set<Id> setUOM = new set<Id>();

                if (!string.isEmpty(theSILListLumpSum[i].Resource_Type__c)) {

                    Resource_Type__c theResourceType = CompanyMgmt.getResourceType(theSILListLumpSum[i].Resource_Type__c);

                    setUOM.add(theResourceType.Unit_of_Measure__c);
                    setUOM.add(theResourceType.Unit_of_Measure1__c);
                    setUOM.add(theResourceType.Unit_of_Measure2__c);
                    setUOM.add(theResourceType.Unit_of_Measure3__c);
                    setUOM.add(theResourceType.Unit_of_Measure4__c);
                }

                if (setUOM != null && setUOM.size() > 0 && setUOM.contains(newFieldValue)) {
                    theSILListLumpSum[i].Unit_of_Measure__c = newFieldValue;
                    theSILListLumpSum[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListLumpSum[i], 'theUOM');
                } else {
                    theSILListLumpSum[i].Unit_of_Measure__c = null; //Ticket#14606
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Unit of Measure is not defined on the Resource.'));
                    return null;
                }
            }
            Category = 'Bundled';
        } else if (fieldName == 'theMiscUOM') {
            if (String.isBlank(newFieldValue)) {
                theSILListMisc[i].Unit_of_Measure__c = null;
                theSILListMisc[i].Unit_of_Measure__r = null;
            } else {
                System.debug('eValue from lkup==>' + newFieldValue);
                theSILListMisc[i].Unit_of_Measure__c = newFieldValue;
                theSILListMisc[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListMisc[i], 'theUOM');
            }
            Category = 'Misc. Charges And Taxes';
        } else if (fieldName == 'theLBillasLumpSum') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListLabor[i].Bill_as_Lump_Sum__c = false;
                } else {
                    theSILListLabor[i].Bill_as_Lump_Sum__c = boolean.valueOf(newFieldValue);
                }

                //system.debug('theSILListLabor[i].Use_Premium_Rate__c***' + theSILListLabor[i].Use_Premium_Rate__c);
                theSILListLabor[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListLabor[i], 'theLBillasLumpSum');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListLabor[i].Tax_Group__c = '';
                } else {
                    theSILListLabor[i].Tax_Group__c = newFieldValue;
                }
                theSILListLabor[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListLabor[i], 'theTaxGroup');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theLQuantity') {
            try {
                system.debug('***newFieldValue' + newFieldValue);
                if (String.isBlank(newFieldValue)) {
                    system.debug('1***');
                    theSILListLabor[i].Quantity__c = 0;
                } else {
                    system.debug('2***');
                    theSILListLabor[i].Quantity__c = decimal.valueOf(newFieldValue);
                }
                system.debug('***theSILListLabor[i].Quantity__c' + theSILListLabor[i].Quantity__c);
                theSILListLabor[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListLabor[i], 'theLQuantity');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theUnitPrice') {
            if (theSILList[i].Resource__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Resource cannot be blank.')); return null;
            }
            try {
                if (string.isBlank(newFieldValue)) {
                    newFieldValue = '0';
                } else {
                    theSILList[i].Unit_Price__c = decimal.ValueOf(NewFieldValue);
                }
                system.debug('scott1313');
                theSILList[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILList[i], 'theUnitPrice');
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }
            Category = 'Labor';
        } else if (fieldName == 'theMQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListMaterials[i].Quantity__c = 0;
                } else {
                    theSILListMaterials[i].Quantity__c = decimal.valueOf(newFieldValue);
                }
                theSILListMaterials[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListMaterials[i], 'theQuantity');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Materials';
        } else if (fieldName == 'theMUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListMaterials[i].Unit_Price__c = 0;
                } else {
                    theSILListMaterials[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theSILListMaterials[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListMaterials[i], 'theUnitPrice');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Materials';
        } else if (fieldName == 'theMTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListMaterials[i].Tax_Group__c = '';
                } else {
                    theSILListMaterials[i].Tax_Group__c = newFieldValue;
                }
                theSILListMaterials[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListMaterials[i], 'theTaxGroup');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Materials';
        } else if (fieldName == 'theEQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListEquipment[i].Quantity__c = 0;
                } else {
                    theSILListEquipment[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                theSILListEquipment[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListEquipment[i], 'theQuantity');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theEBillasLumpSum') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListEquipment[i].Bill_as_Lump_Sum__c = false;
                } else {
                    theSILListEquipment[i].Bill_as_Lump_Sum__c = boolean.valueOf(newFieldValue);
                }

                //system.debug('theSILListLabor[i].Use_Premium_Rate__c***' + theSILListLabor[i].Use_Premium_Rate__c);
                theSILListEquipment[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListEquipment[i], 'theEBillasLumpSum');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theEUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListEquipment[i].Unit_Price__c = 0;
                } else {
                    theSILListEquipment[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theSILListEquipment[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListEquipment[i], 'theUnitPrice');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theETaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListEquipment[i].Tax_Group__c = '';
                } else {
                    theSILListEquipment[i].Tax_Group__c = newFieldValue;
                }
                theSILListEquipment[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListEquipment[i], 'theTaxGroup');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theSQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListSubcontractors[i].Quantity__c = 0;
                } else {
                    theSILListSubcontractors[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                theSILListSubcontractors[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListSubcontractors[i], 'theQuantity');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Subcontractors';
        } else if (fieldName == 'theSUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListSubcontractors[i].Unit_Price__c = 0;
                } else {
                    theSILListSubcontractors[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theSILListSubcontractors[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListSubcontractors[i], 'theUnitPrice');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Subcontractors';
        } else if (fieldName == 'theSTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListSubcontractors[i].Tax_Group__c = '';
                } else {
                    theSILListSubcontractors[i].Tax_Group__c = newFieldValue;
                }
                theSILListSubcontractors[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListSubcontractors[i], 'theTaxGroup');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Subcontractors';
        } else if (fieldName == 'theWQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListWasteDisposal[i].Quantity__c = 0;
                } else {
                    theSILListWasteDisposal[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                theSILListWasteDisposal[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListWasteDisposal[i], 'theQuantity');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Waste Disposal';
        } else if (fieldName == 'theWUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListWasteDisposal[i].Unit_Price__c = 0;
                } else {
                    theSILListWasteDisposal[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theSILListWasteDisposal[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListWasteDisposal[i], 'theUnitPrice');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Waste Disposal';
        } else if (fieldName == 'theWTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListWasteDisposal[i].Tax_Group__c = '';
                } else {
                    theSILListWasteDisposal[i].Tax_Group__c = newFieldValue;
                }

                theSILListWasteDisposal[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListWasteDisposal[i], 'theTaxGroup');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Waste Disposal';
        } else if (fieldName == 'theDQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListDemurrage[i].Quantity__c = 0;
                } else {
                    theSILListDemurrage[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                theSILListDemurrage[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListDemurrage[i], 'theQuantity');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Demurrage';
        } else if (fieldName == 'theDUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListDemurrage[i].Unit_Price__c = 0;
                } else {
                    theSILListDemurrage[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theSILListDemurrage[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListDemurrage[i], 'theUnitPrice');
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Demurrage';
        } else if (fieldName == 'theDTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListDemurrage[i].Tax_Group__c = '';
                } else {
                    theSILListDemurrage[i].Tax_Group__c = newFieldValue;
                }
                theSILListDemurrage[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListDemurrage[i], 'theTaxGroup');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Demurrage';
        } else if (fieldName == 'theLumpQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListLumpSum[i].Quantity__c = 0;
                } else {
                    theSILListLumpSum[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                theSILListLumpSum[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListLumpSum[i], 'theQuantity');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Bundled';
        } else if (fieldName == 'theLumpUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListLumpSum[i].Unit_Price__c = 0;
                } else {
                    theSILListLumpSum[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theSILListLumpSum[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListLumpSum[i], 'theUnitPrice');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Bundled';
        } else if (fieldName == 'theLumpTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListLumpSum[i].Tax_Group__c = '';
                } else {
                    theSILListLumpSum[i].Tax_Group__c = newFieldValue;
                }
                theSILListLumpSum[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListLumpSum[i], 'theTaxGroup');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Bundled';
        } else if (fieldName == 'theMiscQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListMisc[i].Quantity__c = 0;
                } else {
                    theSILListMisc[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                theSILListMisc[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListMisc[i], 'theQuantity');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Misc. Charges And Taxes';
        } else if (fieldName == 'theMiscUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListMisc[i].Unit_Price__c = 0;
                } else {
                    theSILListMisc[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theSILListMisc[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListMisc[i], 'theUnitPrice');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }
            Category = 'Misc. Charges And Taxes';
        } else if (fieldName == 'theMiscTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListMisc[i].Tax_Group__c = '';
                } else {
                    theSILListMisc[i].Tax_Group__c = newFieldValue;
                }
                theSILListMisc[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListMisc[i], 'theTaxGroup');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Misc. Charges And Taxes';
        } else if (fieldName == 'theLContractLine') {
            if (String.isBlank(newFieldValue)) {
                // not allowed to blank out because custom lookup may receive view state error
                system.debug('Testing' + i + theSILListLabor);
                theSILListLabor[i].Contract_Line__c = null;
                theSILListLabor[i].Contract_Line__r = null;
                Decimal lineNo = theSILListLabor[i].Line_No__c;
                theSILListLabor[i] = new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = lineNo);
            } else {
                try {
                    theSILListLabor[i].Contract_Line__c = newFieldValue;
                    System.debug('Value from lkup==>' + newFieldValue);
                    theSILListLabor[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListLabor[i], 'theLContractLine');
                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }

            }
            Category = 'Labor';
        } else if (fieldName == 'theEContractLine') {
            if (String.isBlank(newFieldValue)) {
                // not allowed to blank out because custom lookup may receive view state error
                system.debug('Testing' + i + theSILListEquipment);
                theSILListEquipment[i].Contract_Line__c = null;
                theSILListEquipment[i].Contract_Line__r = null;
                Decimal lineNo = theSILListEquipment[i].Line_No__c;
                theSILListEquipment[i] = new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = lineNo);
            } else {
                try {
                    theSILListEquipment[i].Contract_Line__c = newFieldValue;
                    System.debug('Value from lkup==>' + newFieldValue);
                    theSILListEquipment[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListEquipment[i], 'theEContractLine');
                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }

            }
            Category = 'Equipment';
        } else if (fieldName == 'theLumpSumContractLine') {
            if (String.isBlank(newFieldValue)) {
                // not allowed to blank out because custom lookup may receive view state error
                system.debug('Testing' + i + theSILListEquipment);
                theSILListLumpSum[i].Contract_Line__c = null;
                theSILListLumpSum[i].Contract_Line__r = null;
                Decimal lineNo = theSILListLumpSum[i].Line_No__c;
                theSILListLumpSum[i] = new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = lineNo);
            } else {
                try {
                    theSILListLumpSum[i].Contract_Line__c = newFieldValue;
                    System.debug('Value from lkup==>' + newFieldValue);
                    theSILListLumpSum[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListLumpSum[i], 'theLumpSumContractLine');
                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }

            }
            Category = 'Bundled';
        } else if (fieldName == 'theMContractLine') {
            if (String.isBlank(newFieldValue)) {
                // not allowed to blank out because custom lookup may receive view state error
                system.debug('Testing' + i + theSILListMaterials);
                theSILListMaterials[i].Contract_Line__c = null;
                theSILListMaterials[i].Contract_Line__r = null;
                Decimal lineNo = theSILListMaterials[i].Line_No__c;
                theSILListMaterials[i] = new Sales_Invoice_Line__c(Sales_Invoice__c = SIId, Line_No__c = lineNo);
            } else {
                try {
                    theSILListMaterials[i].Contract_Line__c = newFieldValue;
                    System.debug('Value from lkup==>' + newFieldValue);
                    theSILListMaterials[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListMaterials[i], 'theMContractLine');
                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }

            }
            Category = 'Materials';
        } else if (fieldName == 'theLBillasLumpSum') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListLabor[i].Bill_as_Lump_Sum__c = false;
                } else {
                    theSILListLabor[i].Bill_as_Lump_Sum__c = boolean.valueOf(newFieldValue);
                }

                //system.debug('theSILListLabor[i].Use_Premium_Rate__c***' + theSILListLabor[i].Use_Premium_Rate__c);
                theSILListLabor[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListLabor[i],'theLBillasLumpSum');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theLNonBillable') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListLabor[i].Non_Billable__c = false;
                } else {
                    theSILListLabor[i].Non_Billable__c = boolean.valueOf(newFieldValue);
                }
                system.debug('theSILListLabor[i].Non_Billable__c***' + theSILListLabor[i].Non_Billable__c);

                //system.debug('theSILListLabor[i].Use_Premium_Rate__c***' + theSILListLabor[i].Use_Premium_Rate__c);
                theSILListLabor[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListLabor[i], fieldName);

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theEBillasLumpSum') { //Ticket#13673
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListEquipment[i].Bill_as_Lump_Sum__c = false;
                } else {
                    theSILListEquipment[i].Bill_as_Lump_Sum__c = boolean.valueOf(newFieldValue);
                }

                //system.debug('theSILListEquipment[i].Use_Premium_Rate__c***' + theSILListEquipment[i].Use_Premium_Rate__c);
                theSILListEquipment[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListEquipment[i], 'theEBillasLumpSum');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theENonBillable') { //Ticket#13673
            try {
                if (String.isBlank(newFieldValue)) {
                    theSILListEquipment[i].Non_Billable__c = false;
                } else {
                    theSILListEquipment[i].Non_Billable__c = boolean.valueOf(newFieldValue);
                }

                //system.debug('theTMLListLabor[i].Use_Premium_Rate__c***' + theTMLListLabor[i].Use_Premium_Rate__c);
                theSILListEquipment[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListEquipment[i], fieldName);

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theMBillasLumpSum' || fieldName == 'theSBillasLumpSum' || fieldName == 'theWBillasLumpSum' ||
                fieldName == 'theDBillasLumpSum' || fieldName == 'theMiscBillasLumpSum'){
            try {

                Category = fieldNameCategoryMap.get(fieldName);
                Boolean isChecked = false;

                if (String.isNotBlank(newFieldValue)) {
                    //isChecked = true; 14250
                    isChecked = Boolean.valueOf(newFieldValue);
                }

                switch on Category{
                    when 'Subcontractors'{
                        theSILListSubcontractors[i].Bill_as_Lump_Sum__c = isChecked;
                        theSILListSubcontractors[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListSubcontractors[i], fieldName);
                    }
                    when 'Waste Disposal'{
                        theSILListWasteDisposal[i].Bill_as_Lump_Sum__c = isChecked;
                        theSILListWasteDisposal[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListWasteDisposal[i], fieldName);
                    }
                    when 'Demurrage'{
                        theSILListDemurrage[i].Bill_as_Lump_Sum__c = isChecked;
                        theSILListDemurrage[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListDemurrage[i], fieldName);
                    }
                    when 'Bundled' {
                        theSILListLumpSum[i].Bill_as_Lump_Sum__c = isChecked;
                        theSILListLumpSum[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListLumpSum[i], fieldName);
                    }
                    when 'Misc. Charges And Taxes'{
                        theSILListMisc[i].Bill_as_Lump_Sum__c = isChecked;
                        theSILListMisc[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListMisc[i], fieldName);
                    }
                    when 'Materials'{
                        theSILListMaterials[i].Bill_as_Lump_Sum__c = isChecked;
                        theSILListMaterials[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListMaterials[i], fieldName);
                    }
                }

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

        } else if (fieldName == 'theMNonBillable' || fieldName == 'theSNonBillable' || fieldName == 'theWNonBillable' ||
                fieldName == 'theDNonBillable' || fieldName == 'theLumpNonBillable' || fieldName == 'theMiscNonBillable') {
            try {
                Category = fieldNameCategoryMap.get(fieldName);
                System.debug('***Category ' + Category);
                Boolean isChecked = false;

                if (String.isNotBlank(newFieldValue)) {
                    //isChecked = true;
                    isChecked = Boolean.valueOf(newFieldValue);
                }

                switch on Category{
                    when 'Subcontractors'{
                        theSILListSubcontractors[i].Non_Billable__c = isChecked;
                        theSILListSubcontractors[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListSubcontractors[i], fieldName);
                    }
                    when 'Waste Disposal'{
                        theSILListWasteDisposal[i].Non_Billable__c = isChecked;
                        theSILListWasteDisposal[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListWasteDisposal[i], fieldName);
                    }
                    when 'Demurrage'{
                        theSILListDemurrage[i].Non_Billable__c = isChecked;
                        theSILListDemurrage[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListDemurrage[i], fieldName);
                    }
                    when 'Bundled' {
                        theSILListLumpSum[i].Non_Billable__c = isChecked;
                        theSILListLumpSum[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListLumpSum[i], fieldName);
                    }
                    when 'Misc. Charges And Taxes'{
                        theSILListMisc[i].Non_Billable__c = isChecked;
                        theSILListMisc[i] = SalesInvoiceMgmt.updateSIL( theSI, theSILListMisc[i],fieldName);
                    }
                    when 'Materials'{
                        theSILListMaterials[i].Non_Billable__c = isChecked;
                        theSILListMaterials[i] = SalesInvoiceMgmt.updateSIL(theSI, theSILListMaterials[i], fieldName);
                    }
                }

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }
        }

        if (!Test.isRunningTest()) {
            if (Category == 'Labor') {
                CalculateTotalLabor();
                CalculateTotalOrder();
            }
            if (Category == 'Equipment') {
                CalculateTotalEquipment();
                CalculateTotalOrder();
            }
            if (Category == 'Materials') {
                CalculateTotalMaterials();
                CalculateTotalOrder();
            }
            if (Category == 'Subcontractors') {
                CalculateTotalSubcontractors();
                CalculateTotalOrder();
            }
            if (Category == 'Waste Disposal') {
                CalculateTotalWasteDisposal();
                CalculateTotalOrder();
            }
            if (Category == 'Demurrage') {
                CalculateTotalDemurrage();
                CalculateTotalOrder();
            }
            if (Category == 'Bundled') {
                CalculateTotalLumpSum();
                CalculateTotalOrder();
            }
            if (Category == 'Misc. Charges And Taxes') {
                CalculateTotalMisc();
                CalculateTotalOrder();
            }
        }
        return null;
    }

    public PageReference createRetainageInvoice(){
        Savepoint sp = Database.setSavepoint();
        try{
            Sales_Invoice__c retainageInvoice = SalesInvoicesService.createRetainageInvoice(theSI);
            //job task <<
            //PageReference SalesInvoicePage = new PageReference('/apex/SalesInvoice?id=' + retainageInvoice.Id);
            PageReference salesInvoicePage = new PageReference('/' + retainageInvoice.Id);
            //job task >>
            SalesInvoicePage.setRedirect(true);
            return SalesInvoicePage;
        } catch (Exception e){
            Database.rollback(sp);
            System.debug('ERROR: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
            return null;
        }
    }

    public void setFieldNameCategoryMap() {
        fieldNameCategoryMap = new Map<String, String>();
        fieldNameCategoryMap.put('theMBillasLumpSum', 'Materials');
        fieldNameCategoryMap.put('theMNonBillable', 'Materials');
        fieldNameCategoryMap.put('theDBillasLumpSum', 'Demurrage');
        fieldNameCategoryMap.put('theDNonBillable', 'Demurrage');
        fieldNameCategoryMap.put('theLumpBillasLumpSum', 'Bundled');
        fieldNameCategoryMap.put('theLumpNonBillable', 'Bundled');
        fieldNameCategoryMap.put('theSBillasLumpSum', 'Subcontractors');
        fieldNameCategoryMap.put('theSNonBillable', 'Subcontractors');
        fieldNameCategoryMap.put('theWBillasLumpSum', 'Waste Disposal');
        fieldNameCategoryMap.put('theWNonBillable', 'Waste Disposal');
        fieldNameCategoryMap.put('theMiscBillasLumpSum', 'Misc. Charges And Taxes');
        fieldNameCategoryMap.put('theMiscNonBillable', 'Misc. Charges And Taxes');
    }

    private void CalculateTotal() {
        CalculateTotalLabor();
        CalculateTotalEquipment();
        CalculateTotalMaterials();
        CalculateTotalSubcontractors();
        CalculateTotalWasteDisposal();
        CalculateTotalDemurrage();
        CalculateTotalLumpSum();
        CalculateTotalMisc();
        CalculateTotalOrder();
    }

    private void CalculateTotalOrder() {
        SILSubtotal = 0.00;
        SILTaxTotal = 0.00;
        SILTotal = 0.00;
        SILProfitMargin = 0.00;
        SILTotalCost = 0.00;
        SurchargeAmount = 0.00; //AES-438
        SurchargeAmtInclTax = 0.00; //AES-438
        Decimal surchargeAmtTax = 0.00; //AES-438
        SILSubtotal = SILSubtotalLabor + SILSubtotalEquipment + SILSubtotalMaterials + SILSubtotalSubcontractors +
                //SILSubtotalFieldRemediation +
                SILSubtotalWasteDisposal + SILSubtotalDemurrage +
                SILSubtotalLumpSum + SILSubtotalMisc;

        SurchargeAmount = SalesInvoicesService.calcSurchargeAmount(theSI, theSILList);
        theSI.Surcharge_Amount__c = SurchargeAmount;
        /*
        //AES-438 >>
        if(CompanyMgmt.zeroIfNull(theSI.Surcharge_Pct__c) != 0){
            if(theSI.Surcharge_Type__c == 'EEC Fee'){
                theSI.Surcharge_Amount__c = (SILSubtotal * theSI.Surcharge_Pct__c / 100).setScale(2, RoundingMode.HALF_UP);
                SurchargeAmount = theSI.Surcharge_Amount__c;
            }

            if(theSI.Surcharge_Type__c == 'Fuel Surcharge') {
                Decimal fuelSurcharge = 0.00;
                for (Sales_Invoice_Line__c theSIL : SILListEquipment) {
                    if(theSIL.Resource_Type__r.Fuel_Fired_Equipment__c){
                        fuelSurcharge += CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
                        if (theSIL.Bill_as_Lump_Sum__c == true || theSIL.Non_Billable__c == true){ //14250
                            fuelSurcharge += CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(theSIL.xUnit_Price__c) * companyMgmt.zeroIfNull(theSIL.Quantity__c));
                        }
                    }
                }
                theSI.Surcharge_Amount__c = (fuelSurcharge * theSI.Surcharge_Pct__c / 100).setScale(2, RoundingMode.HALF_UP);
                SurchargeAmount = theSI.Surcharge_Amount__c;
            }
        } else {
            theSI.Surcharge_Amount__c = 0;
        }
         */

        /*
        if(theSI.Tax_Liable__c == true){
            Decimal taxPct = CompanyMgmt.getSalesTax(theSI.Tax_Area__c, 'TX');
            if(CompanyMgmt.zeroIfNull(taxPct) > 0){
                surchargeAmtTax = (SurchargeAmount * taxPct / 100).setScale(2, RoundingMode.HALF_UP);
                SurchargeAmtInclTax = SurchargeAmount + surchargeAmtTax;
            } else {
                SurchargeAmtInclTax = SurchargeAmount;
            }

            theSI.Surcharge_Amt_Incl_Tax__c = SurchargeAmtInclTax;
        }
        */

        //AES-438 <<
        SILTaxTotal = SILTaxTotalLabor + SILTaxTotalEquipment + SILTaxTotalMaterials + SILTaxTotalSubcontractors +
                SILTaxTotalWasteDisposal + SILTaxTotalDemurrage +
                SILTaxTotalLumpSum + SILTaxTotalMisc;
                //+ surchargeAmtTax;

        SILTotal = SILTotalLabor + SILTotalEquipment + SILTotalMaterials + SILTotalSubcontractors +
                //SILTotalFieldRemediation +
                SILTotalWasteDisposal + SILTotalDemurrage +
                SILTotalLumpSum + SILTotalMisc + SurchargeAmount;
                //+ SurchargeAmtInclTax;

        SILTotalCost = SILTotalCostLabor + SILTotalCostEquipment + SILTotalCostSubcontractors + SILTotalCostMaterials +
                SILTotalCostWasteDisposal + SILTotalCostLumpSum + SILTotalCostMisc + SILTotalCostDemurrage;

        //if (SILSubtotal !=0) SILProfitMargin = (1 - SILTotalCost / SILSubtotal) * 100;
        if (SILSubtotal !=0){
            SILProfitMargin = (1 - SILTotalCost / (SILSubtotal + SurchargeAmount)) * 100;
        }

        RetainageAmount = CompanyMgmt.zeroIfNull(theSI.Retainage_Amount__c);

    }

    private void CalculateTotalLabor() {
        SILSubtotalLabor = 0.00;
        SILTaxTotalLabor = 0.00;
        SILTotalLabor = 0.00;
        SILProfitMarginLabor = 0.00;
        SILTotalCostLabor = 0.00;
        Decimal totalCostWithoutLumpSum = 0.00;
        for (Sales_Invoice_Line__c theSIL : SILListLabor) {
            SILSubtotalLabor += CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
            SILTaxTotalLabor += (CompanyMgmt.zeroIfNull(theSIL.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
            SILTotalLabor += CompanyMgmt.zeroIfNull(theSIL.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
            SILTotalCostLabor += CompanyMgmt.zeroIfNull(theSIL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
            if (!theSIL.Bill_as_Lump_Sum__c && !theSIL.Non_Billable__c ) totalCostWithoutLumpSum += CompanyMgmt.zeroIfNull(theSIL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
        }

        if(theSI.Credit_Memo__c == true){
            totalCostWithoutLumpSum = totalCostWithoutLumpSum * -1;
            SILTotalCostLabor = SILTotalCostLabor * -1;
        }

        if (SILSubtotalLabor != 0) {
            SILProfitMarginLabor = (1 - totalCostWithoutLumpSum / SILSubtotalLabor) * 100;
        }
    }

    private void CalculateTotalEquipment() {
        SILSubtotalEquipment = 0.00;
        SILTaxTotalEquipment = 0.00;
        SILTotalEquipment = 0.00;
        SILProfitMarginEquipment = 0.00;
        SILTotalCostEquipment = 0.00;
        Decimal totalCostWithoutLumpSum = 0.00;
        for (Sales_Invoice_Line__c theSIL : SILListEquipment) {
            SILSubtotalEquipment += CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
            SILTaxTotalEquipment += (CompanyMgmt.zeroIfNull(theSIL.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
            SILTotalEquipment += CompanyMgmt.zeroIfNull(theSIL.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
            SILTotalCostEquipment += CompanyMgmt.zeroIfNull(theSIL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
            if (!theSIL.Bill_as_Lump_Sum__c && !theSIL.Non_Billable__c ) totalCostWithoutLumpSum += CompanyMgmt.zeroIfNull(theSIL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
        }
        if(theSI.Credit_Memo__c == true){
            totalCostWithoutLumpSum = totalCostWithoutLumpSum * -1;
            SILTotalCostEquipment = SILTotalCostEquipment * -1;
        }
        if (SILSubtotalEquipment != 0) SILProfitMarginEquipment = (1 - totalCostWithoutLumpSum / SILSubtotalEquipment) * 100;
    }

    private void CalculateTotalMaterials() {
        SILSubtotalMaterials = 0.00;
        SILTaxTotalMaterials = 0.00;
        SILTotalMaterials = 0.00;
        SILProfitMarginMaterials = 0.00;
        SILTotalCostMaterials = 0.00;
        Decimal totalCostWithoutLumpSum = 0.00;
        for (Sales_Invoice_Line__c theSIL : SILListMaterials) {
            SILSubtotalMaterials += CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
            SILTaxTotalMaterials += (CompanyMgmt.zeroIfNull(theSIL.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
            SILTotalMaterials += CompanyMgmt.zeroIfNull(theSIL.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
            SILTotalCostMaterials += CompanyMgmt.zeroIfNull(theSIL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
            if (!theSIL.Bill_as_Lump_Sum__c && !theSIL.Non_Billable__c ) totalCostWithoutLumpSum += CompanyMgmt.zeroIfNull(theSIL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
        }
        if(theSI.Credit_Memo__c == true){
            totalCostWithoutLumpSum = totalCostWithoutLumpSum * -1;
            SILTotalCostMaterials = SILTotalCostMaterials * -1;
        }
        if (SILSubtotalMaterials != 0) SILProfitMarginMaterials = (1 - totalCostWithoutLumpSum / SILSubtotalMaterials) * 100;
    }

    private void CalculateTotalSubcontractors() {
        SILSubtotalSubcontractors = 0.00;
        SILTaxTotalSubcontractors = 0.00;
        SILTotalSubcontractors = 0.00;
        SILProfitMarginSubcontractors = 0.00;
        SILTotalCostSubcontractors = 0.00;
        Decimal totalCostWithoutLumpSum = 0.00;
        for (Sales_Invoice_Line__c theSIL : SILListSubcontractors) {
            SILSubtotalSubcontractors += CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
            SILTaxTotalSubcontractors += (CompanyMgmt.zeroIfNull(theSIL.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
            SILTotalSubcontractors += CompanyMgmt.zeroIfNull(theSIL.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
            SILTotalCostSubcontractors += CompanyMgmt.zeroIfNull(theSIL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
            if (!theSIL.Bill_as_Lump_Sum__c && !theSIL.Non_Billable__c ) totalCostWithoutLumpSum += CompanyMgmt.zeroIfNull(theSIL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
        }
        if(theSI.Credit_Memo__c == true){
            totalCostWithoutLumpSum = totalCostWithoutLumpSum * -1;
            SILTotalCostSubcontractors = SILTotalCostSubcontractors * -1;
        }
        if (SILSubtotalSubcontractors != 0) {
            SILProfitMarginSubcontractors = (1 - totalCostWithoutLumpSum / SILSubtotalSubcontractors) * 100;
        }
    }

    private void CalculateTotalWasteDisposal() {
        SILSubtotalWasteDisposal = 0.00;
        SILTaxTotalWasteDisposal = 0.00;
        SILTotalWasteDisposal = 0.00;
        SILProfitMarginWasteDisposal = 0.00;
        SILTotalCostWasteDisposal = 0.00;
        Decimal totalCostWithoutLumpSum = 0.00;
        for (Sales_Invoice_Line__c theSIL : SILListWasteDisposal) {
            SILSubtotalWasteDisposal += CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
            SILTaxTotalWasteDisposal += (CompanyMgmt.zeroIfNull(theSIL.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
            SILTotalWasteDisposal += CompanyMgmt.zeroIfNull(theSIL.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
            SILTotalCostWasteDisposal += CompanyMgmt.zeroIfNull(theSIL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
            if (!theSIL.Bill_as_Lump_Sum__c && !theSIL.Non_Billable__c ) totalCostWithoutLumpSum += CompanyMgmt.zeroIfNull(theSIL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
        }
        if(theSI.Credit_Memo__c == true){
            totalCostWithoutLumpSum = totalCostWithoutLumpSum * -1;
            SILTotalCostWasteDisposal = SILTotalCostWasteDisposal * -1;
        }
        if (SILSubtotalWasteDisposal != 0) SILProfitMarginWasteDisposal = (1 - totalCostWithoutLumpSum / SILSubtotalWasteDisposal) * 100;
    }

    private void CalculateTotalDemurrage() {
        SILSubtotalDemurrage = 0.00;
        SILTaxTotalDemurrage = 0.00;
        SILTotalDemurrage = 0.00;
        SILProfitMarginDemurrage = 0.00;
        SILTotalCostDemurrage = 0.00;
        Decimal totalCostWithoutLumpSum = 0.00;
        for (Sales_Invoice_Line__c theSIL : SILListDemurrage) {
            SILSubtotalDemurrage += CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
            SILTaxTotalDemurrage += (CompanyMgmt.zeroIfNull(theSIL.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
            SILTotalDemurrage += CompanyMgmt.zeroIfNull(theSIL.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
            SILTotalCostDemurrage += CompanyMgmt.zeroIfNull(theSIL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
            if (!theSIL.Bill_as_Lump_Sum__c && !theSIL.Non_Billable__c ) {
                totalCostWithoutLumpSum += CompanyMgmt.zeroIfNull(theSIL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
            }
        }
        if(theSI.Credit_Memo__c == true){
            totalCostWithoutLumpSum = totalCostWithoutLumpSum * -1;
            SILTotalCostDemurrage = SILTotalCostDemurrage * -1;
        }
        if (SILSubtotalDemurrage != 0) SILProfitMarginDemurrage = (1 - totalCostWithoutLumpSum / SILSubtotalDemurrage) * 100;
    }

    private void CalculateTotalLumpSum() {
        SILSubtotalLumpSum = 0.00;
        SILTaxTotalLumpSum = 0.00;
        SILTotalLumpSum = 0.00;
        SILProfitMarginLumpSum = 0.00;
        SILTotalCostLumpSum = 0.00;
        for (Sales_Invoice_Line__c theSIL : SILListLumpSum) {
            SILSubtotalLumpSum += CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
            SILTaxTotalLumpSum += (CompanyMgmt.zeroIfNull(theSIL.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
            SILTotalLumpSum += CompanyMgmt.zeroIfNull(theSIL.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
            SILTotalCostLumpSum += CompanyMgmt.zeroIfNull(theSIL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
        }
        if(theSI.Credit_Memo__c == true){
            SILTotalCostLumpSum = SILTotalCostLumpSum * -1;
        }
        if (SILSubtotalLumpSum != 0) SILProfitMarginLumpSum = (1 - SILTotalCostLumpSum / SILSubtotalLumpSum) * 100;
    }

    private void CalculateTotalMisc() {
        SILSubtotalMisc = 0.00;
        SILTaxTotalMisc = 0.00;
        SILTotalMisc = 0.00;
        SILProfitMarginMisc = 0.00;
        SILTotalCostMisc = 0.00;
        Decimal totalCostWithoutLumpSum = 0.00;
        for (Sales_Invoice_Line__c theSIL : SILListMisc) {
            if(theSIL.Resource__c != theCompanySetup.Default_Energy_Insurance_Resource__c && theSIL.Resource__c != theCompanySetup.Default_Fuel_Surcharge_Resource__c){  // 14250
                SILSubtotalMisc += CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
                SILTaxTotalMisc += (CompanyMgmt.zeroIfNull(theSIL.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
                SILTotalMisc += CompanyMgmt.zeroIfNull(theSIL.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
                SILTotalCostMisc += CompanyMgmt.zeroIfNull(theSIL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
                if (!theSIL.Bill_as_Lump_Sum__c && !theSIL.Non_Billable__c ) totalCostWithoutLumpSum += CompanyMgmt.zeroIfNull(theSIL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
            }
        }
        if(theSI.Credit_Memo__c == true){
            totalCostWithoutLumpSum = totalCostWithoutLumpSum * -1;
            SILTotalCostMisc = SILTotalCostMisc * -1;
        }
        if (SILSubtotalMisc != 0) SILProfitMarginMisc = (1 - totalCostWithoutLumpSum / SILSubtotalMisc) * 100;
    }

    public PageReference reInsertSIL() {
        CompanyMgmt.systemCall = true;

        Savepoint sp = database.setSavePoint();
        try {
            Set<String> setTaxGroup = new Set<String>();
            Set<String> setItemDiscGrp = new Set<String>();
            for (Resource__c theResource : SalesInvoiceMgmt.mapResource.values()) {
                setTaxGroup.add(theResource.Tax_Group__c);
                setItemDiscGrp.add(theResource.Category__c);
            }
            for (Tax_Detail__c theTaxDetail : [
                    SELECT Tax_Pct__c, Tax_Area__c, Tax_Group__c
                    FROM Tax_Detail__c
                    WHERE Tax_Area__c = :theSI.Tax_Area__r.Name AND Tax_Group__c IN :setTaxGroup
            ]) {

                if (string.isEmpty(theTaxDetail.Tax_Area__c) || string.isEmpty(theTaxDetail.Tax_Group__c)) continue;

                if (SalesInvoiceMgmt.mapSalesTax.get(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c) == null)
                    SalesInvoiceMgmt.mapSalesTax.put(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c, theTaxDetail.Tax_Pct__c); else
                        SalesInvoiceMgmt.mapSalesTax.put(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c, SalesInvoiceMgmt.mapSalesTax.get(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c) + theTaxDetail.Tax_Pct__c);
            }

            CompanyMgmt.mapSalesTax = SalesInvoiceMgmt.mapSalesTax;
            SalesInvoiceMgmt.isReinsertSL = true;
            // Assign those  SL which is exist in DB
            List<Sales_Invoice_Line__c> theNewSILList = new List<Sales_Invoice_Line__c>();
            // Assign those  SL which is not exist in DB
            system.debug('Ashish SL List::' + theSILList.size());
            for (Sales_Invoice_Line__c SIL : theSILList) {
                Sales_Invoice_Line__c newSIL = new Sales_Invoice_Line__c();
                newSIL = SIL.clone(true);
                system.debug('Resource::' + SIL.Resource__c);
                newSIL = SalesInvoiceMgmt.updateSIL(theSI, newSIL, 'theTaxGroup');
                theNewSILList.add(newSIL);
            }
            if (theSI.Id != null) {
                //clear __r values, value update should be based on __c values.
                theSI = SalesInvoiceMgmt.nullRelationshipFields(theSI);
                try {
                    upsert theSI;
                    update theNewSILList;
                } catch (exception e) {
                    System.debug('****ashish' + ' six ' + e.getmessage());
                }
                selectSI();
            }
            System.debug('Old List::' + theSILList);
            theSILList.clear();
            System.debug('Clear List::' + theSILList);
            System.debug('new List::' + theNewSILList);
            theSILList.addAll(theNewSILList);
            System.debug('Updated List::' + theSILList);
            CalculateTotal();
        } catch (exception e) {
            // Rollback
            Database.Rollback(sp);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
        }
        return null;
    }

    public List<SelectOption> lstPrintCopy {
        get {
            if (lstPrintCopy == null) {
                lstPrintCopy = new List<SelectOption>();
                lstPrintCopy.add(new SelectOption('None', '-None-'));
                lstPrintCopy.add(new SelectOption('Customer Copy', 'Customer Copy'));
                lstPrintCopy.add(new SelectOption('Job File Copy', 'Job File Copy'));
                lstPrintCopy.add(new SelectOption('Project Coordinator Copy', 'Project Coordinator Copy'));
                lstPrintCopy.add(new SelectOption('Other', 'Other'));
            }
            return lstPrintCopy;
        }
        set;
    }

    public List<SelectOption> lstInvoiceType {
        get {
            if (lstInvoiceType == null) {
                //job task <<
                /*
                lstInvoiceType = new List<SelectOption>();
                lstInvoiceType.add(new SelectOption('TM Detail', 'T&M Detail'));
                lstInvoiceType.add(new SelectOption('TM Summary', 'T&M Summary'));
                //lstInvoiceType.add(new SelectOption('TM Lump Sum', 'Consolidated T&M')); //Ticket#13385
				lstInvoiceType.add(new SelectOption('TM Lump Sum', 'T&M Lump Sum'));
                lstInvoiceType.add(new SelectOption('TM by Date by Category', 'T&M by Date by Category'));
                */
                lstInvoiceType = new List<SelectOption>();
                lstInvoiceType.add(new SelectOption('TM Detail', 'Detail'));
                lstInvoiceType.add(new SelectOption('TM Summary', 'Summary'));
                lstInvoiceType.add(new SelectOption('TM by Date by Category', 'By Date by Category'));
            }
            return lstInvoiceType;
        }
        set;
    }

    public String selectedInvoicetype {
        get {
            string InvoiceType = ApexPages.CurrentPage().getParameters().get('InvoiceType');

            return InvoiceType;
        }
        set;
    }

    public List<SelectOption> lstLogo {
        get {
            if (lstInvoiceType == null) {
                lstInvoiceType = new List<SelectOption>();
                lstInvoiceType.add(new SelectOption('ACV Enviro', 'ACV Enviro'));
                lstInvoiceType.add(new SelectOption('Allstate Power VAC', 'Allstate Power VAC'));
                lstInvoiceType.add(new SelectOption('Clean Venture', 'Clean Venture'));
            }
            return lstInvoiceType;
        }
        set;
    }

    public Boolean containsLumSumCategory {
        get {
            containsLumSumCategory = false;
            if (theSILList != null && theSILList.size() > 0) {
                for (Integer i = 0; i < theSILList.size(); i++) {
                    if (theSILList[i].Category__c == 'Bundled') {
                        containsLumSumCategory = true; break;
                    }
                }
            }
            return containsLumSumCategory;
        }
        set;
    }

    public List<WrapSILByCategory> WrapSIL {
        get {
            theWrapSILList = new List<WrapSILByCategory>();
            WrapSILByCategory theWrapSILLine;
            TMNames = '';
            Set<String> SetTMName = new Set<String>();
            //Get SIL again as some SIL do not need to printed
            Map<String, Schema.SObjectField> fields = Schema.SObjectType.Sales_Invoice_Line__c.fields.getMap();
            List<String> lstFields = new List<String>();
            for (Schema.SObjectField field : fields.values()) {
                lstFields.add(field.getDescribe().getName());
            }
            //Ticket#13673 - add Non_Billable__c
            String strQuery = 'SELECT ' + String.join(lstFields, ',');
            strQuery += ',Unit_of_Measure__r.Name,Sales_Invoice__r.Bill_to_Customer__c,Resource__r.Name, TM__r.Name, Resource_Type__r.Name ';
            //Ticket#14591 >>
            //strQuery += ' FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c =: SIId AND Bill_as_Lump_Sum__c = false AND Non_Billable__c = false ORDER BY Scheduled_Date__c, Category__c, Line_No__c';
            strQuery += ' FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c =: SIId ORDER BY Scheduled_Date__c ASC NULLS LAST, Category__c ASC NULLS LAST, Line_No__c ASC NULLS LAST';
            theSILList = Database.query(strQuery);

            System.debug('Info: WrapSIL: ' + theSILList);
            //Collect all T&M name
            for(Sales_Invoice_Line__c salesInvoiceLine:theSILList){
                if (String.isNotEmpty(salesInvoiceLine.TM__r.Name)) SetTMName.add(salesInvoiceLine.TM__r.Name);
            }

            //Remove Bill as Lump Sum and Non-Billable line from print out
            Integer k = 0;
            while (k < theSILList.size()) {
                if(theSILList[k].Bill_as_Lump_Sum__c == true || theSILList[k].Non_Billable__c == true || theSILList[k].System_Calculated_Line__c == true){
                    theSILList.remove(k);
                } else {
                    k++;
                }
            }

            //Ticket#14591 <<
            if (theSILList != null && theSILList.size() > 0) {
                for (Integer i = 0; i < theSILList.size(); i++) {
                    //Ticket#14591 >>
//                    if (!string.isEmpty(theSILList[i].TM__r.Name)) {
//                        SetTMName.add(theSILList[i].TM__r.Name);
//                        //TMNames += theSILList[i].TM__r.Name + ' ,';
//                    }
                    //Ticket#14591 <<
                    if (theSILList[i].Line_Amt_Incl_Tax__c == null) theSILList[i].Line_Amt_Incl_Tax__c = 0;

                    if (i == 0) {
                        theWrapSILLine = new WrapSILByCategory();
                        theWrapSILLine.theSILLines = new List<Sales_Invoice_Line__c>();

                        theWrapSILLine.CategoryAmtTotal = 0;
                        theWrapSILLine.Category = theSILList[i].Category__c;
                        theWrapSILLine.theSILLines.add(theSILList[i]);
                        //theWrapSILLine.CategoryAmtTotal += theSILList[i].Line_Amt_Incl_Tax__c;
                        theWrapSILLine.CategoryAmtTotal += CompanyMgmt.zeroIfNull(theSILList[i].Line_Amount__c); //#Ticket13858
                        if (i == theSILList.size() - 1) {
                            theWrapSILList.add(theWrapSILLine);
                        }

                    } else {
                        if (theSILList[i].Category__c != theSILList[i - 1].Category__c) {
                            theWrapSILList.add(theWrapSILLine);
                            theWrapSILLine = new WrapSILByCategory();
                            theWrapSILLine.theSILLines = new List<Sales_Invoice_Line__c>();

                            theWrapSILLine.CategoryAmtTotal = 0;
                            theWrapSILLine.Category = theSILList[i].Category__c;
                            theWrapSILLine.theSILLines.add(theSILList[i]);
                            //theWrapSILLine.CategoryAmtTotal += theSILList[i].Line_Amt_Incl_Tax__c;
                            theWrapSILLine.CategoryAmtTotal += CompanyMgmt.zeroIfNull(theSILList[i].Line_Amount__c); //#Ticket13858
                            if (i == theSILList.size() - 1) {
                                theWrapSILList.add(theWrapSILLine);
                            }
                        } else {
                            theWrapSILLine.theSILLines.add(theSILList[i]);
                            //theWrapSILLine.CategoryAmtTotal += theSILList[i].Line_Amt_Incl_Tax__c;
                            theWrapSILLine.CategoryAmtTotal += CompanyMgmt.zeroIfNull(theSILList[i].Line_Amount__c); //Ticket#13858

                            if (i == theSILList.size() - 1) theWrapSILList.add(theWrapSILLine);

                        }
                    }

                    system.debug('theSILList[i].Scheduled_Date__c***' + theSILList[i].Scheduled_Date__c);
                    if (lastServiceDate == null || lastServiceDate <= theSILList[i].Scheduled_Date__c) {
                        lastServiceDate = theSILList[i].Scheduled_Date__c;
                    }
                }
            }

            for (string TMName : SetTMName) {
                if (string.isBlank(TMNames)) TMNames = TMName; else TMNames += ', ' + TMName;
            }

            return theWrapSILList;


        }
    }

    public List<WrapSILByCategory> WrapSILByCategory {
        get {
            theWrapSILList = new List<WrapSILByCategory>();
            WrapSILByCategory theWrapSILLine;
            TMNames = '';
            Set<String> SetTMName = new Set<String>();
            //Get SIL again as some SIL do not need to printed
            Map<String, Schema.SObjectField> fields = Schema.SObjectType.Sales_Invoice_Line__c.fields.getMap();
            List<String> lstFields = new List<String>();
            for (Schema.SObjectField field : fields.values()) {
                lstFields.add(field.getDescribe().getName());
            }
            //Ticket#13673 - add Non_Billable__c
            String strQuery = 'SELECT ' + String.join(lstFields, ',');
            strQuery += ',Unit_of_Measure__r.Name,Sales_Invoice__r.Bill_to_Customer__c,Resource__r.Name, TM__r.Name, Resource_Type__r.Name ';
            //Ticket#14591 >>
            strQuery += ' FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c =: SIId ORDER BY Category__c ASC NULLS LAST, Line_No__c ASC NULLS LAST';
            //strQuery += ' FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c =: SIId AND Bill_as_Lump_Sum__c = false AND Non_Billable__c = false ORDER BY Category__c, Line_No__c';
            //Ticket#14591 <<
            theSILList = Database.query(strQuery);

            //Ticket#14591 >>
            //Collect all T&M name
            for(Sales_Invoice_Line__c salesInvoiceLine:theSILList){
                if (String.isNotEmpty(salesInvoiceLine.TM__r.Name)) SetTMName.add(salesInvoiceLine.TM__r.Name);
            }

            //Remove Bill as Lump Sum and Non-Billable line from print out
            Integer k = 0;
            while (k < theSILList.size()) {
                if(theSILList[k].Bill_as_Lump_Sum__c == true || theSILList[k].Non_Billable__c == true || theSILList[k].System_Calculated_Line__c == true){
                    theSILList.remove(k);
                } else {
                    k++;
                }
            }
            //Ticket#14591 <<

            if (theSILList != null && theSILList.size() > 0) {
                for (Integer i = 0; i < theSILList.size(); i++) {
                    /*Ticket#14591
                    if (!string.isEmpty(theSILList[i].TM__r.Name)) {
                        SetTMName.add(theSILList[i].TM__r.Name);
                        //TMNames += theSILList[i].TM__r.Name + ' ,';
                    }
                    */

                    if (theSILList[i].Line_Amt_Incl_Tax__c == null) theSILList[i].Line_Amt_Incl_Tax__c = 0;

                    if (i == 0) {
                        theWrapSILLine = new WrapSILByCategory();
                        theWrapSILLine.theSILLines = new List<Sales_Invoice_Line__c>();

                        theWrapSILLine.CategoryAmtTotal = 0;
                        theWrapSILLine.Category = theSILList[i].Category__c;
                        theWrapSILLine.theSILLines.add(theSILList[i]);
                        //theWrapSILLine.CategoryAmtTotal += theSILList[i].Line_Amt_Incl_Tax__c;
                        theWrapSILLine.CategoryAmtTotal += CompanyMgmt.zeroIfNull(theSILList[i].Line_Amount__c); //#Ticket13858
                        if (i == theSILList.size() - 1) {
                            theWrapSILList.add(theWrapSILLine);
                        }

                    } else {
                        if (theSILList[i].Category__c != theSILList[i - 1].Category__c) {
                            theWrapSILList.add(theWrapSILLine);
                            theWrapSILLine = new WrapSILByCategory();
                            theWrapSILLine.theSILLines = new List<Sales_Invoice_Line__c>();

                            theWrapSILLine.CategoryAmtTotal = 0;
                            theWrapSILLine.Category = theSILList[i].Category__c;
                            theWrapSILLine.theSILLines.add(theSILList[i]);
                            //theWrapSILLine.CategoryAmtTotal += theSILList[i].Line_Amt_Incl_Tax__c;
                            theWrapSILLine.CategoryAmtTotal += CompanyMgmt.zeroIfNull(theSILList[i].Line_Amount__c); //#Ticket13858
                            if (i == theSILList.size() - 1) {
                                theWrapSILList.add(theWrapSILLine);
                            }
                        } else {
                            theWrapSILLine.theSILLines.add(theSILList[i]);
                            //theWrapSILLine.CategoryAmtTotal += theSILList[i].Line_Amt_Incl_Tax__c;
                            theWrapSILLine.CategoryAmtTotal += CompanyMgmt.zeroIfNull(theSILList[i].Line_Amount__c); //Ticket#13858

                            if (i == theSILList.size() - 1) theWrapSILList.add(theWrapSILLine);

                        }
                    }

                    system.debug('theSILList[i].Scheduled_Date__c***' + theSILList[i].Scheduled_Date__c);
                    if (lastServiceDate == null || lastServiceDate <= theSILList[i].Scheduled_Date__c) {
                        lastServiceDate = theSILList[i].Scheduled_Date__c;
                    }
                }
            }

            for (string TMName : SetTMName) {
                if (string.isBlank(TMNames)) TMNames = TMName; else TMNames += ', ' + TMName;
            }

            return theWrapSILList;
        }
    }

    public List<WrapSILByCategory> WrapSILByCategoryAndDate {
        get {
            theWrapSILList = new List<WrapSILByCategory>();
            WrapSILByCategory theWrapSILLine;
            TMNames = '';
            Set<String> SetTMName = new Set<String>();

            //Get SIL again as some SIL do not need to printed
            Map<String, Schema.SObjectField> fields = Schema.SObjectType.Sales_Invoice_Line__c.fields.getMap();
            List<String> lstFields = new List<String>();
            for (Schema.SObjectField field : fields.values()) {
                lstFields.add(field.getDescribe().getName());
            }
            //Ticket#13673 - add Non_Billable__c
            String strQuery = 'SELECT ' + String.join(lstFields, ',');
            strQuery += ',Unit_of_Measure__r.Name,Sales_Invoice__r.Bill_to_Customer__c,Resource__r.Name, TM__r.Name, Resource_Type__r.Name ';
            //Ticket#14591 >>
            strQuery += ' FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c =: SIId ORDER BY Scheduled_Date__c ASC NULLS LAST, Category__c ASC NULLS LAST, Line_No__c ASC NULLS LAST';
            //strQuery += ' FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c =: SIId AND Bill_as_Lump_Sum__c = false AND Non_Billable__c = false ORDER BY Scheduled_Date__c, Category__c, Line_No__c';
            //Ticket#14591 >>
            theSILList = Database.query(strQuery);

            //Ticket#14591 >>
            //Collect all T&M name
            for(Sales_Invoice_Line__c salesInvoiceLine:theSILList){
                if (String.isNotEmpty(salesInvoiceLine.TM__r.Name)) SetTMName.add(salesInvoiceLine.TM__r.Name);
            }

            //Remove Bill as Lump Sum and Non-Billable line from print out
            Integer k = 0;
            while (k < theSILList.size()) {
                if(theSILList[k].Bill_as_Lump_Sum__c == true || theSILList[k].Non_Billable__c == true || theSILList[k].System_Calculated_Line__c == true){
                    theSILList.remove(k);
                } else {
                    k++;
                }
            }
            //Ticket#14591 <<

            if (theSILList != null && theSILList.size() > 0) {
                for (Integer i = 0; i < theSILList.size(); i++) {
                    /*Ticket#14591
                    if (!string.isEmpty(theSILList[i].TM__r.Name)) {
                        SetTMName.add(theSILList[i].TM__r.Name);
                        //TMNames += theSILList[i].TM__r.Name + ' ,';
                    }
                    */

                    if (i == 0) {
                        theWrapSILLine = new WrapSILByCategory();
                        theWrapSILLine.theSILLines = new List<Sales_Invoice_Line__c>();

                        theWrapSILLine.CategoryAmtTotal = 0;
                        theWrapSILLine.Category = theSILList[i].Category__c;
                        theWrapSILLine.ScheduleDate = date.valueOf(theSILList[i].Scheduled_Date__c);
                        theWrapSILLine.theSILLines.add(theSILList[i]);
                        theWrapSILLine.CategoryAmtTotal += theSILList[i].Line_Amt_Incl_Tax__c;
                        if (i == theSILList.size() - 1) {
                            theWrapSILList.add(theWrapSILLine);
                        }

                    } else {
                        if (theSILList[i].Category__c != theSILList[i - 1].Category__c ||
                                date.valueOf(theSILList[i].Scheduled_Date__c) != date.valueOf(theSILList[i - 1].Scheduled_Date__c)) {
                            theWrapSILList.add(theWrapSILLine);
                            theWrapSILLine = new WrapSILByCategory();
                            theWrapSILLine.theSILLines = new List<Sales_Invoice_Line__c>();

                            theWrapSILLine.CategoryAmtTotal = 0;
                            theWrapSILLine.Category = theSILList[i].Category__c;
                            theWrapSILLine.ScheduleDate = date.valueOf(theSILList[i].Scheduled_Date__c);
                            theWrapSILLine.theSILLines.add(theSILList[i]);
                            theWrapSILLine.CategoryAmtTotal += theSILList[i].Line_Amt_Incl_Tax__c;

                            if (i == theSILList.size() - 1) theWrapSILList.add(theWrapSILLine);

                        } else {
                            theWrapSILLine.theSILLines.add(theSILList[i]);
                            theWrapSILLine.CategoryAmtTotal += theSILList[i].Line_Amt_Incl_Tax__c;

                            if (i == theSILList.size() - 1) theWrapSILList.add(theWrapSILLine);

                        }
                    }
                }
            }

            for (string TMName : SetTMName) {
                if (string.isBlank(TMNames)) TMNames = TMName; else TMNames += ', ' + TMName;
            }

            return theWrapSILList;

        }
    }


    /*
        Lump Billing
     */
    public List<WrapSILByCategory> WrapSILForLumpFormat {
        get {
            theWrapSILList = new List<WrapSILByCategory>();
            WrapSILByCategory theWrapSILLine;
            TMNames = '';
            Set<String> SetTMName = new Set<String>();
            Map<String, Sales_Invoice_Line__c> mapBillingDescWithSIL = new Map<String, Sales_Invoice_Line__c>();
            //Get SIL again as some SIL do not need to printed
            Map<String, Schema.SObjectField> fields = Schema.SObjectType.Sales_Invoice_Line__c.fields.getMap();
            List<String> lstFields = new List<String>();
            for (Schema.SObjectField field : fields.values()) {
                lstFields.add(field.getDescribe().getName());
            }
            String strQuery = 'SELECT ' + String.join(lstFields, ',');
            strQuery += ',Unit_of_Measure__r.Name,Sales_Invoice__r.Bill_to_Customer__c,Resource__r.Name, TM__r.Name, Resource_Type__r.Name ';
            //Ticket#14591 >>
            strQuery += ' FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c =: SIId ORDER BY Scheduled_Date__c, Category__c, Line_No__c';
            //strQuery += ' FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c =: SIId AND Bill_as_Lump_Sum__c = false ORDER BY Scheduled_Date__c, Category__c, Line_No__c';
            //Ticket#14591 <<
            theSILList = Database.query(strQuery);
            //Ticket#14591 >>
            //Collect all T&M name
            for(Sales_Invoice_Line__c salesInvoiceLine:theSILList){
                if (String.isNotEmpty(salesInvoiceLine.TM__r.Name)) SetTMName.add(salesInvoiceLine.TM__r.Name);
            }

            //Remove Bill as Lump Sum and Non-Billable line from print out
            Integer k = 0;
            while (k < theSILList.size()) {
                if(theSILList[k].Bill_as_Lump_Sum__c == true || theSILList[k].Non_Billable__c == true){
                    theSILList.remove(k);
                } else {
                    k++;
                }
            }

            //Ticket#14591 <<
            if (theSILList != null && theSILList.size() > 0) {
                for (Integer i = 0; i < theSILList.size(); i++) {
                    //Lump Sum line could be from Misc. credit memo
                    //if (!string.isEmpty(theSILList[i].TM__r.Name)) {
                    //Ticket#14591 >>
                    //System.debug('****The SI Line Lump Sum ' + theSILList[i]);
                    //SetTMName.add(theSILList[i].TM__r.Name);
                    //Ticket#14591 <<
                    if(mapBillingDescWithSIL.containsKey(theSILList[i].Description__c)){
                        Sales_Invoice_Line__c theSIL = mapBillingDescWithSIL.get(theSILList[i].Description__c);
                        theSIL.Quantity__c = theSIL.Quantity__c + theSILList[i].Quantity__c;
                        theSIL.Line_Amt_Incl_Tax__c = theSIL.Line_Amt_Incl_Tax__c + theSILList[i].Line_Amt_Incl_Tax__c;
                        theSIL.Line_Amount__c = CompanyMgmt.zeroIfNull(theSIL.Line_Amount__c) + CompanyMgmt.zeroIfNull(theSILList[i].Line_Amount__c); //#Ticket13858
                        if (theSIL.Quantity__c != 0) theSIL.Unit_Price__c = companyMgmt.halfUpTo2D(theSIL.Line_Amount__c / theSIL.Quantity__c);
                        if (theSILList[i].Scheduled_Date__c < theSIL.First_Lump_Sum_Date__c || theSIL.First_Lump_Sum_Date__c == null){
                            theSIL.First_Lump_Sum_Date__c = theSILList[i].Scheduled_Date__c;
                        }
                        if (theSILList[i].Scheduled_Date__c > theSIL.Last_Lump_Sum_Date__c || theSIL.Last_Lump_Sum_Date__c == null){
                            theSIL.Last_Lump_Sum_Date__c = theSILList[i].Scheduled_Date__c;
                        }
                        if (theSIL.Quantity__c != 0 || theSIL.Line_Amt_Incl_Tax__c != 0){
                            mapBillingDescWithSIL.put(theSILList[i].Description__c, theSIL);
                        }
                    } else {
                        theSILList[i].First_Lump_Sum_Date__c = theSILList[i].Scheduled_Date__c;
                        theSILList[i].Last_Lump_Sum_Date__c = theSILList[i].Scheduled_Date__c;
                        if (theSILList[i].Quantity__c != 0 || theSILList[i].Line_Amt_Incl_Tax__c != 0) {
                            mapBillingDescWithSIL.put(theSILList[i].Description__c, theSILList[i]);
                        }
                    }
                    //}

                    if (lastServiceDate == null || lastServiceDate <= theSILList[i].Scheduled_Date__c) {
                        lastServiceDate = theSILList[i].Scheduled_Date__c;
                    }
                }

                System.debug('***mapBillingDescWithSIL' + mapBillingDescWithSIL);

                for (String mapkey : mapBillingDescWithSIL.keySet()) {
                    theWrapSILLine = new WrapSILByCategory();
                    theWrapSILLine.theSILLines = new List<Sales_Invoice_Line__c>();
                    theWrapSILLine.CategoryAmtTotal = 0;
                    Sales_Invoice_Line__c theSIL = mapBillingDescWithSIL.get(mapkey);
                    theWrapSILLine.Category = theSIL.Category__c;
                    theWrapSILLine.theSILLines.add(theSIL);
                    theWrapSILLine.CategoryAmtTotal += theSIL.Line_Amt_Incl_Tax__c;

                    theWrapSILList.add(theWrapSILLine);
                    System.debug('***theSIL ' + theSIL);
                }
                System.debug('***theWrapSILList ' + theWrapSILList);
            }

            for (string TMName : SetTMName) {
                if (string.isBlank(TMNames)) TMNames = TMName; else TMNames += ', ' + TMName;
            }

            return theWrapSILList;
        }
    }

    public class WrapSILByCategory {
        public String Category { get; set; }
        public List<Sales_Invoice_Line__c> theSILLines { get; set; }
        public Decimal CategoryAmtTotal { get; set; }
        public Date ScheduleDate { get; set; }
    }

    public PageReference PrintSalesInvoice() {
        //Ticket#13385
        if (selInvoiceType != 'TM Lump Sum' && containsLumSumCategory) {
            string msg = 'You are not allowed to print ' + selInvoiceType + ' Invoice because there are Lump Sum invoice lines.';
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, msg)); return null;
        }
        PageReference redirectPage = new PageReference('/apex/SalesInvoicePdf?id=' + SIId + '&PrintCopy=' + selPrintCopy + '&InvoiceType=' + selInvoiceType);
        redirectPage.setRedirect(true);
        return redirectPage;
    }

    //job task << 
    public PageReference PrintNewSalesInvoice() {
        //Ticket#13385
        PageReference redirectPage = new PageReference('/apex/NewSalesInvoicePdf?id=' + SIId + '&PrintCopy=' + selPrintCopy + '&InvoiceType=' + selInvoiceType);
        redirectPage.setRedirect(true);
        return redirectPage;
    }
    //job task >>

    public PageReference reverseSalesInvoice() {

        if (String.isEmpty(theSI.Credit_Memo_Reason_Code__c)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a credit memo reason code to continue!'));
            return null;
        }
        /*
        else if (theSI.Credit_Memo_Reason_Code__c  == 'Customer is tax exempt'){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Partial Credit Memos created in Salesforce are created to correct billing errors and should not be created to credit tax. Tax Related Credit Memos must be created in Navision. Please contact the Corporate Accounts Payable Department!'));
            return null;
        }
         */

        if(String.isEmpty(creditMemoNote)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Credit Memo Note field must not be blank!'));
            return null;
        } else {
            String tempStr = creditMemoNote;
            tempStr = creditMemoNote.trim();
            if(tempStr.length() < 10){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Credit Memo Note field must be at least 10 characters long!'));
                return null;
            }
        }

        Sales_Invoice__c theNewSI = new Sales_Invoice__c();
        List<Sales_Invoice_Line__c> theNewSILList = new List<Sales_Invoice_Line__c>();

        // Savepoint
        Savepoint sp = database.setSavePoint();
        List<String> errorList = new List<String>();
        errorList = SalesInvoiceMgmt.checkReverseSI(theSI);

        if (errorList.size() > 0 && !test.isrunningtest()) {

            for (Integer i = 0; i < errorList.size(); i++) ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, errorList[i]));
            return null;
        } else {
            try {
                theNewSI = theSI.Clone(false, true);
                theNewSI.Credit_Memo__c = true;
                theNewSI.Reversed_from_SI__c = theSI.Id;
                theNewSI.Document_Status__c = 'Open';
                theNewSI.Sales_Invoice_Status__c = 'Open';
                theNewSI.Credit_Memo_Reason_Code__c = theSI.Credit_Memo_Reason_Code__c;
                theNewSI.Internal_Comments__c = String.isEmpty(theNewSI.Internal_Comments__c) ? creditMemoNote : theNewSI.Internal_Comments__c + '\n' + creditMemoNote; //15090
                //Ticket#13511 >>
                theNewSI.Sync_d__c = false;
                //Ticket#13511 <<
                insert theNewSI;

                theNewSILList = theSILList.deepClone();

                if (theNewSILList != null && theNewSILList.size() > 0) {
                    for (Sales_Invoice_Line__c SIL : theNewSILList) {
                        SIL.Sales_Invoice__c = theNewSI.Id;
                        SIL.Quantity__c = -CompanyMgmt.zeroIfNull(SIL.Quantity__c);
                        SIL.Line_Amount__c = -CompanyMgmt.zeroIfNull(SIL.Line_Amount__c); //#Ticket13858
                        SIL.Tax__c = -CompanyMgmt.zeroIfNull(SIL.Tax__c);
                        SIL.Line_Amt_Incl_Tax__c = -CompanyMgmt.zeroIfNull(SIL.Line_Amt_Incl_Tax__c);
                    }
                    insert theNewSILList;
                }

                // Update current SI
                theSI.Reversed__c = true;
                theSI.Reversed_by_CM_No__c = theNewSI.Id;
                theSI.Credit_Memo_Reason_Code__c = null;
                update theSI;

                PageReference InvoicePage = new PageReference('/' + theNewSI.Id);
                InvoicePage.setRedirect(true);
                return InvoicePage;
            } catch (exception e) {
                System.debug('Error: ' + e.getCause());
                System.debug('Error: ' + e.getStackTraceString());
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
                return null;
            }
        }
    }
    /*
        Ticket#13580 - void Sales Invoice
     */
    public PageReference voidSalesInvoice(){
        Set<string> setTM = new Set<string>();
        Set<string> setTML = new Set<string>();
        List<TM_Line__c> theTMLineList = new List<TM_Line__c>();
        // To differentiate from standard edit page
        CompanyMgmt.systemCall = true;

        if (theSI.Document_Status__c != 'Open') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'System can only void Open invoices! + Invoice Status is: ' + theSI.Document_Status__c));
            return null;
        }

        // Savepoint
        Savepoint sp = Database.setSavepoint();

        try {
            //Set Sales Invoice to Void
            theSI.Document_Status__c = 'Void';
            theSI.Sales_Invoice_Status__c = 'Void';

            //Retainage Invoice
            if(theSI.Credit_Memo__c != true){
                List<Retainage_Ledger_Entry__c> retainageLedgerEntries = new List<Retainage_Ledger_Entry__c>();
                if(theSI.Retainage_Invoice__c == true){
                    retainageLedgerEntries = [SELECT Id, Invoiced__c, Closed_By_Invoice_No__c FROM Retainage_Ledger_Entry__c WHERE Closed_By_Invoice_No__c = :theSI.Id LIMIT 1];
                    if(retainageLedgerEntries.size() > 0){
                        retainageLedgerEntries[0].Invoiced__c = false;
                        retainageLedgerEntries[0].Closed_By_Invoice_No__c = null;
                        update retainageLedgerEntries;
                    }
                } else {
                    retainageLedgerEntries = [SELECT Id FROM Retainage_Ledger_Entry__c WHERE Sales_Invoice__c = :theSI.Id LIMIT 1];
                    if(retainageLedgerEntries.size() > 0){
                        delete retainageLedgerEntries;
                    }
                }
            } else {
                List<Retainage_Ledger_Entry__c> retainageLedgerEntries = new List<Retainage_Ledger_Entry__c>();
                if(theSI.Reversed_from_SI__r.Retainage_Invoice__c == true){
                    retainageLedgerEntries = [SELECT Id, Sales_Invoice__r.Name, Closed_By_Invoice_No__c, Closed_By_Invoice_Reversed_By__c
                    FROM Retainage_Ledger_Entry__c
                    WHERE Closed_By_Invoice_Reversed_By__c = :theSI.Id];
                    if(retainageLedgerEntries.size() > 0){
                        if(String.isNotBlank(retainageLedgerEntries[0].Closed_By_Invoice_No__c)){
                            throw new DataException('Credit Memo cannot be void! Retainage invoice already been created for sales invoice# ' + retainageLedgerEntries[0].Sales_Invoice__r.Name);
                        } else {
                            retainageLedgerEntries[0].Closed_By_Invoice_No__c = theSI.Reversed_from_SI__c;
                            retainageLedgerEntries[0].Invoiced__c = true;
                            retainageLedgerEntries[0].Closed_By_Invoice_Reversed_By__c = null;
                            update retainageLedgerEntries;
                        }
                    }
                }
            }
            //Retainage Invoice

            if (theSI.Credit_Memo__c) {
                if (theSI.Reversed_from_SI__c != null){
                    Sales_Invoice__c theReversedFromSI = [SELECT Id, Name FROM Sales_Invoice__c WHERE Id = :theSI.Reversed_from_SI__c];
                    theReversedFromSI.Reversed_by_CM_No__c = null;
                    theReversedFromSI.Reversed__c = false;
                    update theReversedFromSI;
                    theSI.Reversed_from_SI__c = null;
                }
            }

            //Changed Void Sales Invoice Number
            theSI.Name = 'VOID-' + theSI.Name + '-' + theSI.Id;

            update theSI;

            //Update T&M: set T&M status to Ready to Bill
            if (!theSI.Credit_Memo__c){
                List<TM__c> theTMList = new List<TM__c>();
                if (theSILList != null && theSILList.size() > 0) {
                    for (Sales_Invoice_Line__c SIL : theSILList) {
                        if (SIL.TM__c != null && !setTM.contains(SIL.TM__c)) {
                            setTM.add(SIL.TM__c);
                        }
                        if (SIL.TM_Line__c != null && !setTML.contains(SIL.TM_Line__c)) {
                            setTML.add(SIL.TM_Line__c);
                        }
                    }

                    if (setTM.size() > 0) {
                        theTMList = [SELECT Id, Name, Status__c FROM TM__c WHERE Id IN:setTM];
                        if (theTMList != null && theTMList.size() > 0) {
                            //Code is not right scott 112918
                            for (TM__c TM : theTMList) {
                                TM.Status__c = 'Ready to Bill';
                                TM.Sales_Invoice__c = null;
                            }
                        }
                        //Update TML
                        theTMLineList = [SELECT Id, Name, Invoiced__c, To_Invoice__c, Sales_Invoice_Line__c FROM TM_Line__c WHERE Id IN:setTML];
                        if (theTMLineList != null && theTMLineList.size() > 0) {
                            for (TM_Line__c TML : theTMLineList) {
                                TML.To_Invoice__c = false;
                                TML.Invoiced__c = false;
                                TML.Sales_Invoice_Line__c = null;
                            }
                        }
                    }
                }
                // Update T&M
                update theTMList;
                update theTMLineList;
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have successfully voided the Sales Invoice'));
        } catch (Exception e) {
            // Rollback
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
        return null;
    }

//////////////////////////////////////////////////////////////////////////////////////////
    public InvoiceHeader InvoiceHeaderInfo { get; set; }
    public List<CategoryHeader> CategoryHeaderInfo { get; set; }
    public void organizeData() {
        CategoryHeaderInfo = new List<CategoryHeader>();
        Map<String, List<Sales_Invoice_Line__c>> SILbyCategory = New Map<String, List<Sales_Invoice_Line__c>>();
        invoiceTotal = 0;

        Sales_Invoice__c theSI = [
                SELECT Bill_to_Customer__r.Name,
                        Sales_Order__r.name,
                        Sales_Order__r.Site_Name__c, (
                        SELECT Name, Line_No__c,
                                Category__c,
                                Overtime__c,
                                Use_Premium_Rate__c,
                                Scheduled_Date__c,
                                Unit_Price__c,
                                Line_Amount__c,
                                Quantity__c,
                                Contract_Line__r.Name,
                                Contract_Line__r.Customer_Description__c,
                                Contract_Line__r.Customer_Overtime_Description__c,
                                Contract_Line__r.Customer_Premium_Description__c,
                                Contract_Line__r.Customer_Item_No__c,
                                Contract_Line__r.Customer_Overtime_Item_No__c,
                                Contract_Line__r.Customer_Premium_Item_No__c
                        from Sales_Invoice_Lines__r
                )
                FROM Sales_Invoice__c
                WHERE Id = :SIId
        ];

        /////////////////SEGREGATING DATA BASED ON TYPE////////////////////
        Map<Date, Date> DateMap = new Map<Date, Date>();
        for (Sales_Invoice_Line__c SIL : theSI.Sales_Invoice_Lines__r) {

            if (SIL.Scheduled_Date__c != null) {
                DateMap.put(SIL.Scheduled_Date__c, SIL.Scheduled_Date__c);
            } else {
                throw new DataException('You must specify Schedule Date on Line: ' + SIL.Line_No__c);
            }

            if (SILbyCategory.get(SIL.Category__c) != null) {
                List<Sales_Invoice_Line__c> theSILList = SILbyCategory.get(SIL.Category__c);
                theSILList.add(SIL);
                SILbyCategory.put(SIL.Category__c, theSILList);
            } else {
                List<Sales_Invoice_Line__c> theSILList = New List<Sales_Invoice_Line__c>();
                theSILList.add(SIL);
                SILbyCategory.put(SIL.Category__c, theSILList);
            }
        }

        ////////Generating Header Column Information//////////
        InvoiceHeaderInfo = new InvoiceHeader();
        InvoiceHeaderInfo.HeaderName = theSI.Bill_to_Customer__r.Name + '-' + theSI.Sales_Order__r.Site_Name__c + '-' + theSI.Sales_Order__r.name;
        InvoiceHeaderInfo.HeaderInfoMap = DateMap;
        InvoiceHeaderInfo.TotalUnitName = 'TOTAL UNITS';
        InvoiceHeaderInfo.CostName = 'COST';
        InvoiceHeaderInfo.TotalName = 'TOTAL';
        System.debug('Header Info==>' + InvoiceHeaderInfo);
        ///////////////////////////////////////////////////////

        for (String category : SILbyCategory.keyset()) {
            List<Sales_Invoice_Line__c> theSILList = SILbyCategory.get(category);

            CategoryHeader CategoryInfo = new CategoryHeader();
            CategoryInfo.Category = category;

            List<InvoiceLineInfo> CategorySILList = new List<InvoiceLineInfo>();
            Decimal total = 0;

            Map<String, InvoiceLineInfo>SegLineMap = new Map<String, InvoiceLineInfo>();
            String key = '';
            Map<String, InvoiceLineQtyByDateInfo> RowValueMap = new Map<String, InvoiceLineQtyByDateInfo>();
            for (Sales_Invoice_Line__c SIL : theSILList) {
                InvoiceLineInfo SILInfo;

                if (SIL.Use_Premium_Rate__c) {
                    key = SIL.Contract_Line__r.Customer_Overtime_Item_No__c;
                } else if (SIL.Overtime__c) {
                    key = SIL.Contract_Line__r.Customer_Overtime_Item_No__c;
                } else {
                    key = SIL.Contract_Line__r.Customer_Overtime_Item_No__c;
                }
                if (SegLineMap.get(key) != null) {
                    SILInfo = SegLineMap.get(key);
                } else {
                    SILInfo = new InvoiceLineInfo();
                }
                if (SIL.Use_Premium_Rate__c) {
                    SILInfo.ItemNumber = SIL.Contract_Line__r.Customer_Overtime_Item_No__c;
                    SILInfo.ItemDescription = SIL.Contract_Line__r.Customer_Premium_Description__c;
                } else if (SIL.Overtime__c) {
                    SILInfo.ItemNumber = SIL.Contract_Line__r.Customer_Overtime_Item_No__c;
                    SILInfo.ItemDescription = SIL.Contract_Line__r.Customer_Overtime_Description__c;
                } else {
                    SILInfo.ItemNumber = SIL.Contract_Line__r.Customer_Overtime_Item_No__c;
                    SILInfo.ItemDescription = SIL.Contract_Line__r.Customer_Description__c;
                }
                ///////////segregating Multiple Entried of same Item Number/////////////////////////
                if (RowValueMap.get(key + String.valueof(SIL.Scheduled_Date__c)) != null) {
                    InvoiceLineQtyByDateInfo SILQtyInfo = RowValueMap.get(key + String.valueof(SIL.Scheduled_Date__c));
                    SILQtyInfo.TotalUnit = SILQtyInfo.TotalUnit + SIL.Quantity__c;
                    SILQtyInfo.Cost = SIL.Unit_Price__c;
                    SILQtyInfo.Total = SILQtyInfo.Total + CompanyMgmt.zeroIfNull(SIL.Line_Amount__c); //#Ticket13858
                    Map<Date, Decimal> DateQtyMap = SILQtyInfo.ValueMap;
                    if (SIL.Quantity__c != null) {
                        DateQtyMap.Put(SIL.Scheduled_Date__c, SIL.Quantity__c + DateQtyMap.get(SIL.Scheduled_Date__c));
                    } else DateQtyMap.Put(SIL.Scheduled_Date__c, 0);
                    SILQtyInfo.ValueMap = DateQtyMap;
                    RowValueMap.Put((key + String.valueof(SIL.Scheduled_Date__c)), SILQtyInfo);
                    SILInfo.QtyByDate = SILQtyInfo;
                } else {
                    InvoiceLineQtyByDateInfo SILQtyInfo = new InvoiceLineQtyByDateInfo();
                    SILQtyInfo.TotalUnit = SIL.Quantity__c;
                    SILQtyInfo.Cost = SIL.Unit_Price__c;
                    SILQtyInfo.Total = CompanyMgmt.zeroIfNull(SIL.Line_Amount__c); //#Ticket13858
                    Map<Date, Decimal> DateQtyMap = New Map<Date, Decimal>();
                    for (Date D : DateMap.keyset()) DateQtyMap.put(D, 0); //initializing with the date values
                    if (SIL.Quantity__c != null) {
                        DateQtyMap.Put(SIL.Scheduled_Date__c, SIL.Quantity__c);
                    } else {
                        DateQtyMap.Put(SIL.Scheduled_Date__c, 0);
                    }
                    SILQtyInfo.ValueMap = DateQtyMap;
                    RowValueMap.Put(key + String.valueof(SIL.Scheduled_Date__c), SILQtyInfo);
                    SILInfo.QtyByDate = SILQtyInfo;
                }

                total = total + companyMgmt.zeroIfNull(SIL.Line_Amount__c);
                CategorySILList.add(SILInfo);
            }
            CategoryInfo.Total = total;
            CategoryInfo.InvoiceLineInfoList = CategorySILList;
            CategoryHeaderInfo.add(CategoryInfo);

            invoiceTotal = invoiceTotal + CategoryInfo.Total;
        }
        System.debug('CategoryHeaderInfo==>' + CategoryHeaderInfo);
    }

    public class InvoiceHeader {
        public String HeaderName { get; Set; }
        public String Blank { get; Set; }
        public Map<Date, Date> HeaderInfoMap { get; set; }
        public String TotalUnitName { get; Set; }
        public String CostName { get; Set; }
        public String TotalName { get; Set; }
    }


    public class CategoryHeader {
        public String Category { get; Set; }
        public Decimal Total { get; Set; }
        public List<InvoiceLineInfo> InvoiceLineInfoList { get; Set; }
    }

    public class InvoiceLineInfo {
        public String ItemNumber { get; Set; }
        public String ItemDescription { get; Set; }
        public InvoiceLineQtyByDateInfo QtyByDate { get; Set; }
    }

    public class InvoiceLineQtyByDateInfo {
        public Map<Date, Decimal> ValueMap { get; set; }
        public Decimal TotalUnit { get; Set; }
        public Decimal Cost { get; Set; }
        public Decimal Total { get; Set; }
    }

    /*Sales Invoice Line Pagination*/
    /* Moved to SalesInvoiceWithPagination.cls
    public Integer noOfRecords{get; set;}
    public Integer size{get; set;}
    public final Integer Page_Size=25;

    public ApexPages.StandardSetController setCon{
        get{
            if(setCon == null){
                size = Page_Size;
                setCon = new ApexPages.StandardSetController(theSILList);
                setCon.setPageSize(size);
                noOfRecords = setCon.getResultSize();
            }

            return setCon;
        }
        set;
    }

    public Boolean hasNext{
        get{
            return setCon.getHasNext();
        }
        set;
    }

    public Boolean hasPrevious{
        get{
            return setCon.getHasPrevious();
        }
        set;
    }

    public Integer pageNumber{
        get{
            return setCon.getPageNumber();
        }
        set;
    }

    public void previous(){
        setCon.save();
        setCon.previous();
    }

    public void next(){
        setCon.save();
        setCon.next();

    }

    public List<Sales_Invoice_Line__c> getSalesInvoiceLines(){
        return (List<Sales_Invoice_Line__c>) setCon.getRecords();
    }
     */

    public pagereference saveAndPost() {
        msave();
        if (!ApexPages.hasMessages()) {
            PageReference PostSalesInvoicePage = new PageReference('/apex/PostSalesInvoice?id=' + theSI.Id);
            PostSalesInvoicePage.setRedirect(true);
            return PostSalesInvoicePage;
        } else {
            return null;
        }
    }

    /*
     *  Ticket#16912
     *      add approval comment
     *  Ticket#21357
     *      block approval process for invoice with blocked/inactive contact.
     */
    public PageReference saveAndSubitForApproval() {
        if (theSI.Worksheet__c != true) {
            try {
                if(theSI.Approval_Status__c != EnumUtil.ApprovalStatus.DRAFT.name() && theSI.Approval_Status__c != EnumUtil.ApprovalStatus.REJECTED.name()){
                    throw new DataException('You can not submit this record for approval because its approval status is ' + theSI.Approval_Status__c);
                }

                if(theSI.Contact__r.Blocked__c == true){
                    throw new DataException('ou can not submit this record for approval because invoice contact has been blocked/inactive.');
                }

                //Check when posting misc. credit memo
                if(String.isNotBlank(theSI.Reversed_from_SI__c) && theSI.Misc_Invoice__c == true){
                    if(theSI.Reversed_from_SI__r.Balance__c < Math.abs(theSI.Invoice_Amt_Incl_Tax__c)){
                        throw new DataException('Credit Memo amount: ' + Math.abs(theSI.Invoice_Amt_Incl_Tax__c) + ' is larger than remaining balance '
                                + theSI.Reversed_from_SI__r.Balance__c + ' on invoice# ' + theSI.Reversed_from_SI__r.Name);
                    }
                }

                SalesInvoicesService.submitForApproval(theSI.Id, true, approvalComment);
                PageReference salesInvoicePage = new PageReference('/' + theSI.Id);
                salesInvoicePage.setRedirect(true);
                return salesInvoicePage;
            } catch (Exception e){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage() + ' - ' + e.getStackTraceString()));
                return null;
            }
        }
        return null;
    }

    public Boolean isApproved{
        get {
            if (theSI.Approval_Status__c != EnumUtil.ApprovalStatus.APPROVED.name()){
                return false;
            }
            return true;
        }
        set ;
    }
}