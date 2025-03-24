public with sharing class SalesInvoiceWithPaginationController {
    private final ApexPages.StandardController theController;
    public Sales_Invoice__c theSI;
    public List<Sales_Invoice_Line__c> theSILList;
    private String SIId;
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

    public Contact theBTContact {get; set; } //Ticket# AES-401
    public Contact theSiteContact {get; set; } //Ticket# AES-401

    public SalesInvoiceWithPaginationController(ApexPages.StandardController controller) {
        theController = controller;
        SIId = ApexPages.currentPage().getParameters().get('id');
        theBTContact = new Contact();
        theSiteContact = new Contact();
        if (SIId != null) {
            selectSI();
            selectSILList();
            // Ticket# AES-401 >>
            if (!String.isEmpty(theSI.Contact__c)){
                theBTContact.Id = theSI.Contact__c;
                theBTContact = theSI.Contact__r;
            }
            if (!String.isEmpty(theSI.Site_Contact_2__c)){
                theSiteContact.Id = theSI.Site_Contact_2__c;
                theSiteContact = theSI.Site_Contact_2__r;
            }
        }
        CalculateTotalOrder();
    }

    public Boolean allowDataOverride { get {return CompanyMgmt.allowDataOverride();} }

    private void selectSI() {
        theSI = SalesInvoicesSelector.newInstance().selectById(new Set<Id>{SIId})[0];
    }

    private void selectSILList() {
        theSILList = SalesInvoiceLinesSelector.newInstance().selectLinesByInvoiceId(SIId);
        //theSILList = SalesInvoiceLinesSelector.newInstance().selectByInvoiceId(SIId);
    }

    public Sales_Invoice__c SI {
        get {
            return theSI;
        }
    }

    public Boolean posted {
        get {
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

    public void validateContact() {
        String contactId = ApexPages.currentPage().getParameters().get('contactId');
        String fieldId = ApexPages.currentPage().getParameters().get('fieldId');
        if (!String.isEmpty(contactId)){
            List<Contact> contacts = [SELECT Id, FirstName, LastName, Name FROM Contact WHERE Id = :contactId];
            if (contacts.size() > 0){
                if(fieldId == 'theBTContact') {
                    theSI.Contact__c = contacts[0].Id;
                    theSI.Contact__r = contacts[0];
                    theBTContact = contacts[0];
                } else {
                    theSI.Site_Contact_2__c = contacts[0].Id;
                    theSI.Site_Contact_2__r = contacts[0];
                    theSiteContact = contacts[0];
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contact does not exist!' + contactId));
            }
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

    public void msave() {
        CompanyMgmt.systemCall = true;

        Sales_Invoice__c oldSI = theSI.clone(true);
        List<Sales_Invoice_Line__c> oldSILList = new List<Sales_Invoice_Line__c>();
        // Savepoint
        Savepoint sp = Database.setSavepoint();

        //Check Errors
        List<String> errorList = new List<String>();
        errorList = SalesInvoiceMgmt.checkSave(theSI, theSILList);

        if (errorList.size() > 0) {
            Integer i = 0;
            for (i = 0; i < errorList.size(); i++) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorList[i]));
            }
            return;
        } else {
            try {
                //Save SIL first in case upsert theSI has error
                for (Sales_Invoice_Line__c SIL : theSILList) {
                    oldSILList.add(SIL.clone(true));
                }

                theSI = SalesInvoiceMgmt.nullRelationshipFields(theSI);
                upsert theSI;
                upsert theSILList;
                return;
            } catch (Exception e) {
                Database.rollback(sp);
                theSI = oldSI;
                theSILList = oldSILList;
                System.debug('Error: ' + e.getStackTraceString());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return;
            }
        }
    }

    public PageReference save() {
        msave();
        if (!ApexPages.hasMessages()) {
            PageReference SalesInvoicePage = new PageReference('/' + theSI.Id);
            SalesInvoicePage.setRedirect(true);
            return SalesInvoicePage;
        } else {
            return null;
        }
    }

    public PageReference quickSaveForLinePaginationPage() {
        msave();
        if (!ApexPages.hasMessages()) {
            PageReference SalesInvoicePage = new PageReference('/apex/SalesInvoiceWithLinePagination?id=' + theSI.Id);
            SalesInvoicePage.setRedirect(true);
            return SalesInvoicePage;
        } else {
            return null;
        }
    }

    public PageReference cancel() {
        return theController.cancel();
    }

    public PageReference returnBack() {
        return theController.view();
    }

    private void CalculateTotalOrder() {
        SILSubtotal = 0.00;
        SILTaxTotal = 0.00;
        SILTotal = 0.00;
        SILProfitMargin = 0.00;
        SILTotalCost = 0.00;

        for(Sales_Invoice_Line__c salesInvoiceLine : theSILList){
            SILSubtotal += CompanyMgmt.zeroIfNull(salesInvoiceLine.Line_Amount__c);
            SILTotal += CompanyMgmt.zeroIfNull(salesInvoiceLine.Line_Amt_Incl_Tax__c);
            SILTaxTotal = SILTotal - SILSubtotal;
            SILTotalCost += CompanyMgmt.zeroIfNull(salesInvoiceLine.Line_Cost__c);
        }

        if (SILSubtotal !=0 ){
            SILProfitMargin = (1 - SILTotalCost / SILSubtotal) * 100;
        }
    }

    public PageReference reInsertSIL() {
        CompanyMgmt.systemCall = true;

        Savepoint sp = Database.setSavepoint();
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

                if (String.isEmpty(theTaxDetail.Tax_Area__c) || String.isEmpty(theTaxDetail.Tax_Group__c)) continue;

                if (SalesInvoiceMgmt.mapSalesTax.get(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c) == null) {
                    SalesInvoiceMgmt.mapSalesTax.put(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c, theTaxDetail.Tax_Pct__c);
                } else {
                    SalesInvoiceMgmt.mapSalesTax.put(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c, SalesInvoiceMgmt.mapSalesTax.get(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c) + theTaxDetail.Tax_Pct__c);
                }
            }

            CompanyMgmt.mapSalesTax = SalesInvoiceMgmt.mapSalesTax;
            SalesInvoiceMgmt.isReinsertSL = true;

            List<Sales_Invoice_Line__c> theNewSILList = new List<Sales_Invoice_Line__c>();

            for (Sales_Invoice_Line__c SIL : theSILList) {
                Sales_Invoice_Line__c newSIL = new Sales_Invoice_Line__c();
                newSIL = SIL.clone(true);
                newSIL = SalesInvoiceMgmt.updateSIL(theSI, newSIL, 'theTaxGroup');
                theNewSILList.add(newSIL);
            }

            if (theSI.Id != null) {
                theSI = SalesInvoiceMgmt.nullRelationshipFields(theSI);
                try {
                    upsert theSI;
                    update theNewSILList;
                } catch (Exception e) {
                    System.debug('Error: ' + e.getMessage());
                }
                selectSI();
            }
            theSILList.clear();
            theSILList.addAll(theNewSILList);
            CalculateTotalOrder();
        } catch (Exception e) {
            // Rollback
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    /*Sales Invoice Line Pagination*/
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

    transient public List<Sales_Invoice_Line__c> salesInvoiceLines{
        get{
        return (List<Sales_Invoice_Line__c>) setCon.getRecords();
    }
        set;
    }

}