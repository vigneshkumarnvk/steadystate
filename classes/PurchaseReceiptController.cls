public with sharing class PurchaseReceiptController {
    private final ApexPages.StandardController theController;
    public Purchase_Receipt__c thePR { set; get; }
    private Purchase_Order__c thePO;
    private Purchase_Line__c thePL;
    private List<Purchase_Line__c> thePLList;
    public List<Purch_Rcpt_Line__c> thePRLList;
    private List<Sales_Line__c> theSLList;
    private List<Resource__c> theItemList;
    private Company_Setup__c theCompanySetup = CompanyMgmt.getCompanySetup();
    public Decimal PRLTotal {get; set;}
    String PRId;
    public Boolean IntegrationAdministrator { get; set; }

    public PurchaseReceiptController(ApexPages.StandardController Controller) {
            theController = Controller;
            PRId = ApexPages.CurrentPage().getParameters().get('id');
            if (PRId != null) {
                selectPR();
                selectPRLList();
                selectPO();
                selectPLList();
                selectItemList();
            }            
    }

    public Boolean posted {
        get {
            if (thePR.Document_Status__c == 'Posted' || thePR.Document_Status__c == 'Partially Invoiced' || thePR.Document_Status__c == 'Fully Invoiced') {
                return true;
            } else {
                return false;
            }
        }
    }

    public Boolean allowDataOverride {get{return CompanyMgmt.allowDataOverride();}}

    private void selectPR() {
        User theUser = [SELECT Id, FirstName, LastName, Phone, Service_Center__c, Integration_Administrator__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        this.IntegrationAdministrator = theUser.Integration_Administrator__c;
                
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Purchase_Receipt__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' ,PO_Requestor__r.Name, Service_Center__r.Name ';
        strQuery += ' FROM Purchase_Receipt__c WHERE Id = :PRId ';
        thePR = Database.query(strQuery);
    }

    private void selectPO() {
        String POId = thePR.Purchase_Order__c;
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Purchase_Order__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Purchase_Order__c WHERE Id = :POId ';
        thePO = Database.query(strQuery);
    }

    private void selectPRLList() {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Purch_Rcpt_Line__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Item__r.Name,Purchase_Line__r.Outstanding_Qty__c, Service_Center__r.Name ';
        strQuery += ' FROM Purch_Rcpt_Line__c WHERE Receipt__c = :PRId ';
        thePRLList = Database.query(strQuery);
        CalculateTotal();
    }

    private void selectPLList() {
        List<String> thePLIdList = new List<String>();
        for (Integer i = 0; i < thePRLList.size(); i++) {
            thePLIdList.add(thePRLList[i].Purchase_Line__c);
        }

        thePLList = [SELECT Name, Received_Qty__c, Discount_Pct__c, Line_No__c,
                     Description__c, Unit_Cost__c, Outstanding_Qty__c
                      FROM Purchase_Line__c WHERE Id IN :thePLIdList ];
    }

    private void selectItemList() {
        Set<Id> theItemListId = new Set<Id>();
        for (integer i = 0; i < thePRLList.Size(); i++) {
            theItemListId.add(thePRLList[i].Item__c);
        }
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Resource__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Resource__c WHERE Id IN : theItemListId';
        theItemList = Database.query(strQuery);
    }

    public string title {
        get {
            return thePR.Name;
        }
    }

    public Purchase_Receipt__c PR {
        get {
            return thePR;
        }
    }

    public List<Purch_Rcpt_Line__c > PRLList {
        get {
            return thePRLList;
        }
    }

    public Company_Setup__c CompanySetup {
        get { return theCompanySetup ;}
    }


    public List<String> getMessages() {
        return new List<string> {'Document Status: ' + thePR.Document_Status__c, '', ''};
    }

    public PageReference save() {
        // Need to insert BC
        companyMgmt.systemCall = true;

        Set<String> ItemSetId;
        Set<String> UOMSetId;
        Set<String> SLSetId;
        Map<String, String> mapLineNoKey = new Map<String, String>();

        Integer i;

        List<Purch_Rcpt_Line__c> delPRLList = New List<Purch_Rcpt_Line__c>();

        for (Purch_Rcpt_Line__c PRL : [SELECT Id FROM Purch_Rcpt_Line__c WHERE Receipt__c = : PRId]) {
            boolean lineFound = false;
            for (Purch_Rcpt_Line__c PRL2 : thePRLList) {
                if (PRL.Id == PRL2.Id) {
                    lineFound = true;
                }
            }
            if (lineFound == false) {
                delPRLList.add(PRL);
            }
        }

        if (!delPRLList.isEmpty()) {
            try {
                delete delPRLList;
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
                return null;
            }
        }

        Purchase_Receipt__c OldPR = thePR.clone(true); 
        List<Purch_Rcpt_Line__c> oldPRLList = new List<Purch_Rcpt_Line__c>();  
        // Savepoint
        Savepoint sp = database.setSavePoint();

        //Check Errors
        List<string> errorList = new List<string>();
        errorList = PurchaseReceiptMgmt.checkSave(thePR, thePRLList, thePLList);

        if (errorList.size() > 0) {
            for (i = 0; i < errorList.size(); i++) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, errorList[i]));
            }
            return null;
        } else {
            try {
                upsert thePR;
                // Save Warehouse Shipment Lines
                i = 0;
                while (i < thePRLList.size()) {
                    oldPRLList.add(thePRLList[i].clone(true)); 
                    // Assign Item Journal Id for new item journal lines
                    if (string.isBlank(thePRLList[i].Receipt__c)) {
                        thePRLList[i].Receipt__c = thePR.Id;
                    }
                    i++;
                }

                upsert thePRLList;

                return theController.view();
            } catch (exception e) {
                // Rollback
                Database.Rollback(sp);
                thePR = oldPR;
                thePRLList = oldPRLList;

                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
                return null;
            }
        }
    }

    public PageReference quickSave() {
        Purchase_Receipt__c OldPR = thePR.clone(true); 
        List<Purch_Rcpt_Line__c> oldPRLList = new List<Purch_Rcpt_Line__c>();
        // Savepoint
        Savepoint sp = database.setSavePoint();
        try {
            upsert thePR;
            
            Integer i = 0;
            while (i < thePRLList.size()) {
                oldPRLList.add(thePRLList[i].clone(true)); 
                if (string.isBlank(thePRLList[i].Receipt__c)) {
                    thePRLList[i].Receipt__c = thePR.Id;
                }
                i++;
            }
            upsert thePRLList;
        } catch (exception e) {
            // Rollback 
            Database.Rollback(sp);
            thePR = oldPR;
            thePRLList = oldPRLList;

            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
            return null;
        }
        return null;
    }

    public PageReference postPR() {
        // To differentiate from stanadrd edit page
        CompanyMgmt.systemCall = true;

        // Savepoint
        Savepoint sp = database.setSavePoint();

        //if (thePR.Posting_Date__c == null) {
            thePR.Posting_Date__c = thePR.Actual_Receipt_Date__c;        
        //}

        List<string> errorList = new List<string> ();
        errorList = PurchaseReceiptMgmt.checkPost(thePR, thePRLList, thePLList); 

        if (errorList.size() > 0 && !Test.isRunningTest()) {
            for (Integer i = 0; i < errorList.size(); i++) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, errorList[i]));
            }
        } else {
            try {
                PurchaseReceiptMgmt.postPR(thePR, thePRLList, thePLList);
                thePR.Document_Status__c = 'Posted';

                update thePR;

                // Update Order Status
                selectPO();
                //List<Purchase_Order__c> thePOList = PurchOrderMgmt.updateOrderStatus(new List<Purchase_Order__c> {thePO}); // #GFERP-805
                //update thePOList;
                thePO = PurchOrderMgmt.updateOrderStatus(thePO);
                update thePO;
                String strMessage;
                strMessage = 'You have successfully posted Purchase Receipt.';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, strMessage));
            } catch (Exception e) {
                // Rollback
                Database.rollback(sp);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
        }
        return null;
    }
    
    public PageReference unpostPR() {
        if (companyMgmt.checkUnpostPermission() == false) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You are not allowed to unpost transactions.'));
        } else {
            // Savepoint
            Savepoint sp = database.setSavePoint();

            List<String> errorList = new List<String> ();
            errorList = PurchaseReceiptMgmt.checkUnpostPR(thePR, thePRLList, theSLList);

            if (errorList.size() > 0) {
                for (Integer i = 0; i < errorList.size(); i++) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, errorList[i]));
                }
            } else {
                try {
                    thePR.Document_Status__c = 'Open';

                    update thePR;

                    PurchaseReceiptMgmt.UnpostPR(thePR, thePRLList, thePLList);

                    selectPO();
                    //List<Purchase_Order__c> thePOList = PurchOrderMgmt.updateOrderStatus(new List<Purchase_Order__c> {thePO});
                    //update thePOList;
                    thePO = PurchOrderMgmt.updateOrderStatus(thePO);
                    update thePO;

                } catch (exception e) {
                    // Rollback
                    Database.Rollback(sp);

                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
                    return null;
                }
            }
        }
        return null;
    }
    
    public PageReference clonePR() {
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You must create Purchase Receipt from Purchase Order.'));
        return null;
    }

    public PageReference newPR() {
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You must create Purchase Receipt from Purchase Order.'));
        return null;
    }

    public PageReference deletePR() {
        // To differentiate from stanadrd edit page
        // Need this in order to update Document Status of Purchase Order
        CompanyMgmt.systemCall = true;

        // Savepoint
        Savepoint sp = database.setSavePoint();

        //Check Errors
        //Logics are in PurchaseTriggerManagement
        try {
            delete thePRLList;

            delete thePR;

            // Update Order Status
            selectPO();
            //List<Purchase_Order__c> thePOList = PurchOrderMgmt.updateOrderStatus(new List<Purchase_Order__c> {thePO}); // #GFERP-805
            //update thePOList;
            thePO = PurchOrderMgmt.updateOrderStatus(thePO);
            update thePO;

            return new ApexPages.Action('{!List}').invoke();
        } catch (exception e) {
            // Rollback
            Database.Rollback(sp); 
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); 
            return null;
        }
    }

    public PageReference Cancel() {
        return theController.cancel();
    }

    public PageReference returnBack() {
        return theController.view();
    }


    public PageReference goBacktoList() {
        PageReference PRListPage = new PageReference('/a0P/o');
        PRListPage.setRedirect(true);
        return PRListPage;
    }

    public PageReference deleteLine() {
        string objectType = ApexPages.CurrentPage().getParameters().get('objectType');
        string lineNo = ApexPages.CurrentPage().getParameters().get('lineNo');
        system.debug('delete ' + lineNo);
        if (objectType == 'PurchaseReceiptLine') {
            for (Integer i = 0; i < thePRLList.size(); i++) {
                if (thePRLList[i].Line_No__c == decimal.valueOf(lineNo)) {
                    thePRLList.remove(i); break;
                }
            }
        }
        CalculateTotal();
        return null;
    }    

    public PageReference validateField() {

        string fieldName = ApexPages.currentPage().getParameters().get('fieldName');
        Integer i = Integer.valueOf(ApexPages.currentPage().getParameters().get('lineNo'));
        string newFieldValue = ApexPages.currentPage().getParameters().get('newFieldValue');

        Boolean foundError = false;

        if (fieldName == 'theItem') {
            thePRLList[i].Item__c = (ID) newFieldValue;
            if (thePRLList[i].Item__c != null) {
                Resource__c theItem = [SELECT Id, Name FROM Resource__c WHERE Id = :thePRLList[i].Item__c];
                thePRLList[i].Item__r = new Purchase_Price__c(Id = theItem.Id, Name = theItem.Name);
            }
        } else if (fieldName == 'theQuantity') {
            if (string.isBlank(newFieldValue)) newFieldValue = '0';
            try {
                thePRLList[i].Quantity__c = decimal.ValueOf(newFieldValue);
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            List<String> PLError = PurchaseReceiptMgmt.checkPL(thePR, thePRLList[i], thePLList, 'fromVF', thePRLList[i].Quantity__c);
            for (Integer j = 0; j < PLError.size(); j++) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, PLError[j])); return null;
            }
            thePRLList[i] = PurchaseReceiptMgmt.updatePRL(thePRLList[i], 'theQuantity');
        }

        return null;
    }

    private void calculateTotal() {
        PRLTotal = 0.00;
        for (Purch_Rcpt_Line__c thePRL : thePRLList) {
            PRLTotal += CompanyMgmt.zeroIfNull(thePRL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
        }
    }
}