public with sharing class PurchOrderController {

    private final ApexPages.StandardController theController;
    public Purchase_Order__c thePO { set; get; }
    public Account theBFVendor;
    public List<Purchase_Line__c> thePLList;
    private Purchase_Receipt__c thePR;
    private Purch_Rcpt_Line__c thePRL;
    private List<Purch_Rcpt_Line__c> thePRLList;
    private String POId;
    private String newPOId;
    private String accountId;
    private Company_Setup__c theCompanySetup = CompanyMgmt.getCompanySetup();
    public Decimal PLSubtotal {get; set;}
    public Decimal TaxAmt {get; set;}
    public Decimal TotalIncTax {get; set;}
    public Boolean forceClosePO { get; set; }
    public Purchase_Receipt__c TempPR { get; set; }
    public Boolean IntegrationAdministrator { get; set; }

    public PurchOrderController(ApexPages.StandardController controller) {
        theController = controller;
        POId = ApexPages.currentPage().getParameters().get('id');
        Map<String, String> thePageParameters = ApexPages.currentPage().getParameters();
        for (String key : thePageParameters.keySet()) {
            if (key.contains('_lkid')) {
                accountId = thePageParameters.get(key);
            }
        }

        if (POId == null) {
            init();
            if (accountId != null) {
                thePO.Buy_from_Vendor__c = accountId;
                validateBuyFromVendor();
                PurchOrderMgmt.validateBuyFromVendor(thePO);
            }
        } else {
            selectPO();
        }
        selectPLList();
        CalculateTotal();

        this.TempPR = new Purchase_Receipt__c();
    }

    public Boolean allowDataOverride {
        get{
            return CompanyMgmt.allowDataOverride();
        }
    }

    private void init(){
        if(POId == null){
            thePO = new Purchase_Order__c();
            thePO.Document_Status__c = 'Open';
            User theUser = [SELECT Id, FirstName, LastName, Phone, Service_Center__c, Integration_Administrator__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
            this.IntegrationAdministrator = theUser.Integration_Administrator__c;

            thePO.Delivery_Contact_Name__c = theUser.FirstName + ' ' + theUser.LastName;
            thePO.Contact_Phone_No__c = theUser.Phone;
            thePO.OwnerId = UserInfo.getUserId();
            List<Service_Center__c> sc = [SELECT Id, Name, Code__c,State__c, Street__c,Postal_Code__c,Country__c,City__c, UEZ_No_Tax_on_PO__c FROM Service_Center__c WHERE Name =: theUser.Service_Center__c LIMIT 1];
            if(!sc.isEmpty()){
                thePO.Service_Center__c = sc[0].Id;
                thePO.Service_Center__r = new Service_Center__c(Id = sc[0].Id, Name = sc[0].Name, Code__c = sc[0].Code__c);
                //validateServiceCenter();
                thePO.Shipping_Street__c = sc[0].Street__c;
                thePO.Shipping_City__c = sc[0].City__c;
                thePO.Shipping_State__c = sc[0].State__c;
                thePO.Shipping_Postal_Code__c = sc[0].Postal_Code__c;
                thePO.Shipping_Country__c = sc[0].Country__c;
            }
            //thePO.PO_Requestor__c = UserInfo.getUserId();
            thePO.PO_Requestor__c = theUser.Id;
            thePO = PurchOrderMgmt.validatethePORequestor(thePO);
        }
    }

    private void selectPO() {
        User theUser = [SELECT Id, FirstName, LastName, Phone, Service_Center__c, Integration_Administrator__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        this.IntegrationAdministrator = theUser.Integration_Administrator__c;

        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Purchase_Order__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Buy_from_Vendor__r.Name,Ship_To_Address__r.Name,Buy_from_Vendor__r.E_Mail__c,' +
                'Pay_to_Vendor__r.Name,Billing_Contact__r.Name,Billing_Contact__r.FirstName,' +
                'Billing_Contact__r.LastName,' +
                'Service_Center__r.Name,' +
                'Service_Center__r.Code__c,' +
                'Currency__r.Name, ' +
                'Payment_Term__r.Name, ' +
                'Buy_from_Vendor__r.Auto_Create_Catalog_Item__c,' +
                'Service_Center__r.Subsidiary_Company__c,' +
                'Service_Center__r.Subsidiary_Company__r.Name,' +
                'Subsidiary_Company__r.Name, ' +
                'PO_Requestor__r.Email, ' +
                'PO_Requestor__r.Name ';
        strQuery += ' FROM Purchase_Order__c WHERE Id = : POId';
        thePO = Database.query(strQuery);
    }

    private void selectPLList() {

        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Purchase_Line__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Item__r.Name,Unit_of_Measure__r.Name,Service_Center__r.Name,Sales_Order__r.Name, Service_Center__r.Subsidiary_Company__c,' +
                'Subsidiary_Company__r.Name, Vendor_Account__r.Name, Service_Center__r.Subsidiary_Company__r.Name, Service_Center__r.PO_Allow_Blank_SO_with_Direct_GL_Account__c,' +
                'Item__r.Vendor_Description__c' ;
        strQuery += ' FROM Purchase_Line__c WHERE Purchase_Order__c = : POId ORDER BY Line_No__c';
        thePLList = Database.query(strQuery);
    }

    public String title {
        get {
            if (POId == null) {
                return 'New Order';
            } else {
                return thePO.Name;
            }
        }
    }

    public Purchase_Order__c PO {
        get {
            return thePO;
        }
    }

    public Boolean Completed {
        get {
            if (thePO.Document_Status__c == 'Completed' || thePO.Closed__c == true) {
                return true;
            } else {
                return false;
            }
        }
    }

    public Boolean open {
        get {
            if ((thePO.Document_Status__c == null || thePO.Document_Status__c == 'Open' || thePO.Document_Status__c == 'Rejected') && thePO.Closed__c != true) {
                return true;
            } else {
                return false;
            }
        }
    }

    public Company_Setup__c CompanySetup {
        get{ return theCompanySetup; }
    }

    public void validateBuyFromVendor() {
        if (thePLList.size() == 0) {
            ApexPages.currentPage().getParameters().put('ObjectType', 'PurchaseLine');
            this.insertLine();
        }
        else {
            for (Purchase_Line__c pl : thePLList) {
                if (String.isNotEmpty(pl.Item__c) && pl.Vendor_Account__c != thePO.Buy_from_Vendor__c) {
                    thePO.addError('You must not change the vendor because there are PO lines created for the vendor.');
                    return;
                }
            }

            for (Purchase_Line__c pl : thePLList) {
                pl.Vendor_Account__c = thePO.Buy_from_Vendor__c;
            }
        }

        thePO = PurchOrderMgmt.validateBuyFromVendor(thePO);
        //if (BuyFromVendor != thePO.Buy_From_vendor__r.Name)
        //reInsertPL();
    }

    public void validateBillingVendor() {
        thePO = PurchOrderMgmt.validateBillingVendor(thePO);
        thePO = PurchOrderMgmt.validatePaymentTerm(thePO);
    }

    public void validateShipToAddress(){
        thePO = PurchOrderMgmt.validateShipToAddress(thePO);
    }

    public void validateOrderDate() {
        validatePaymentTerm();
        reInsertPL();
    }

    public void validatePaymentTerm() {
        thePO = PurchOrderMgmt.validatePaymentTerm(thePO);
    }
    
    //check vendor invoice # duplicate <<
    public void validateVendorInvoiceNo() {
        try {
            thePO = PurchOrderMgmt.validateVendorInvoiceNo(thePO);
        }
        catch(exception ex) {
            thePO.addError(ex.getMessage());
        }
    }
    //check vendor invoice # duplicate >>

    public void validateBillingContact() {
        thePO = PurchOrderMgmt.validateBillingContact(thePO);
    }

    //public void validateCurreny() {
    //    thePO = PurchOrderMgmt.validateCurreny(thePO);
    //}

    public void validateServiceCenter(){
        thePO = PurchOrderMgmt.validateServiceCenter(thePO);
        for (Purchase_Line__c pl : thePLList) {
            if (String.isEmpty(pl.Item__c)) {
                pl.Service_Center__c = thePO.Service_Center__c;
                pl.Subsidiary_Company__c = thePO.Subsidiary_Company__c;
            }
        }
    }

    public void validatethePORequestor(){
        thePO = PurchOrderMgmt.validatethePORequestor(thePO);
    }

    public List<Purchase_Line__c > PLList {
        get {
            return thePLList;
        }
    }

    public PageReference PrintConfirmation() {
        List<String> errorList = new List<String>();
        if ((thePO.Document_Status__c == 'Open') || (thePO.Document_Status__c == 'Pending Approval') || (thePO.Is_Temporary__c)){
            errorList.add('Cannot print document before order is approved!');
        }
        //errorList = PurchOrderMgmt.checkPrintConfirmation(thePO);
        if (errorList.size() > 0) {
            for (Integer i = 0; i < errorList.size(); i++) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, errorList[i]));
            }
            return null;
        } else {
            try {
                PageReference PurchaseOrderPDFPage = new PageReference('/apex/PurchaseOrderPDF?Id=' + thePO.Id);
                PurchaseOrderPDFPage.setRedirect(true);
                return PurchaseOrderPDFPage;
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
        }
    }

    public PageReference notValidatePrintConfirmation() {
        try {
            PageReference PurchaseOrderPDFPage = new PageReference('/apex/PurchaseOrderPDF?Id=' + thePO.Id);
            PurchaseOrderPDFPage.setRedirect(true);
            return PurchaseOrderPDFPage;

        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }

    public PageReference save() {
        Savepoint sp = Database.setSavepoint();
        try{
            msave();
            PageReference PurchaseOrderPage = new PageReference('/' + thePO.Id);
            PurchaseOrderPage.setRedirect(true);
            return PurchaseOrderPage;
        } catch (Exception e){
            Database.rollback(sp);
            System.debug('Error: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
        /*
        msave();
        if (!ApexPages.hasMessages()) {
            PageReference PurchaseOrderPage = new PageReference('/' + thePO.Id);
            PurchaseOrderPage.setRedirect(true);
            return PurchaseOrderPage;
        } else {
            return null;
        }
         */
    }

    public PageReference quickSave() {
        Savepoint sp = Database.setSavepoint();
        try {
            msave();
            PageReference PurchOrderPage = new PageReference('/apex/PurchOrder?id=' + thePO.Id);
            PurchOrderPage.setRedirect(true);
            return PurchOrderPage;
        } catch (Exception e){
            Database.rollback(sp);
            System.debug('Error: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
        /*
        msave();
        if (!ApexPages.hasMessages()) {
            PageReference PurchOrderPage = new PageReference('/apex/PurchOrder?id=' + thePO.Id);
            PurchOrderPage.setRedirect(true);
            return PurchOrderPage;
        } else {
            return null;
        }
         */
    }

    private void msave() {
        if(thePO.Id != null){
            if (Approval.isLocked(thePO.Id)){
                throw new DataException('Record is locked for approval!');
                //return;
            }
        }

        CompanyMgmt.systemCall = true;

        //Delete lines without Item No. in the temporary list
        Integer i = 0;

        while (i < thePLList.size()) {
            if (String.isEmpty(thePLList[i].Item__c)) {
                thePLList.remove(i);
            } else {
                i++;
            }
        }

        List<Purchase_Line__c> delPLList = new List<Purchase_Line__c>();

        //Delete lines that are not found in the temporary list
        for (Purchase_Line__c purchaseLine : [SELECT Id FROM Purchase_Line__c WHERE Purchase_Order__c = : POId]) {
            Boolean lineFound = false;
            for (Purchase_Line__c purchaseLine2 : thePLList) {
                if (purchaseLine.Id == purchaseLine2.Id) {
                    lineFound = true;
                }
            }
            if (lineFound == false) {
                delPLList.add(purchaseLine);
            }
        }

        if (!delPLList.isEmpty()) {
            delete delPLList;
        }
        /*
        if (!delPLList.isEmpty()) {
            try {

                delete delPLList;

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return ;
            }
        }
         */

        Purchase_Order__c OldPO = thePO.clone(true);
        List<Purchase_Line__c> oldPLList = new List<Purchase_Line__c>();

        // Savepoint
        Savepoint sp = Database.setSavepoint();

        //Check Errors
        //List<String> errorList = new List<String> ();

        if ((thePO.Subsidiary_Company__c == null) || (thePO.Subsidiary_Vendor_Account__c == null)){
            throw new DataException('Subsidiary Company and Subsidiary Vendor Account must not be blank!');
        }

        if(thePO.Service_Center__c != null){
            Service_Center__c sc = [SELECT Id, Name, Subsidiary_Company__c, Subsidiary_Company__r.Name FROM Service_Center__c WHERE Id =: thePO.Service_Center__c];

            if(Test.isRunningTest() != true) {
                if (thePO.Subsidiary_Company__c != sc.Subsidiary_Company__c) {
                    throw new DataException('Service center is not found in subsidiary company!');
                }
            }

            if(thePO.SC_Field_Update__c != sc.Name){
                thePO.SC_Field_Update__c = sc.Name;
            }
        }

        PurchOrderMgmt.checkSave(thePO, thePLList);

        /*
        if (errorList.size() > 0 && !Test.isRunningTest()) {
            for (Integer j = 0; j < errorList.size(); j++) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorList[j]));
            }
            return;
        } else {
         */
        try {
            //Save PL first in case upsert thePO has error
            i = 0;
            while (i < thePLList.size()) {
                oldPLList.add(thePLList[i].clone(true));
                i++;
            }
            // Null all relationship fields to save
            thePO = PurchOrderMgmt.nullRelationshipFields(thePO);

            List<Purchase_Order__c> oldPOList = [SELECT Id, Approval_Status__c, Document_Status__c, Approved_Amount__c, Order_Cost_Incl_Tax__c
                FROM Purchase_Order__c WHERE Id =: thePO.Id LIMIT 1];

            upsert thePO;

            //get temp item list for vendor
            if (theBFVendor == null) {
                selectBuyFromVendor();
            }

            List<Purchase_Price__c> ppList = new List<Purchase_Price__c>();
            List<String> processedTempItemList = new List<String>();
            Map<String, Purchase_Price__c> ppMap = new Map<String, Purchase_Price__c>();
            //Assign PO Id
            i = 0;
            while (i < thePLList.size()) {
                if (thePLList[i].Purchase_Order__c == null) {
                    POId = thePO.Id;
                    thePLList[i].Purchase_Order__c = POId;
                }

                if (theBFVendor.Auto_Create_Catalog_Item__c == true && thePLList[i].Item__r.Name.toUpperCase() == 'NEW'){
                    if(!ppMap.containsKey(thePLList[i].Vendor_Description__c)){
                        List<Purchase_Price__c> lpp = [SELECT Id, Name FROM Purchase_Price__c WHERE Name =: thePLList[i].Vendor_Description__c AND Account__c =: theBFVendor.Id LIMIT 1];
                        if ((!processedTempItemList.contains(thePLList[i].Vendor_Description__c)) && (lpp.isEmpty())) {
                            processedTempItemList.add(thePLList[i].Vendor_Description__c);
                            Purchase_Price__c pp = new Purchase_Price__c();
                            pp.Account__c = theBFVendor.Id;
                            pp.Name = thePLList[i].Vendor_Description__c;
                            pp.Vendor_Description__c = thePLList[i].Vendor_Description__c;
                            pp.Vendor_SKU__c = thePLList[i].Vendor_SKU__c;
                            pp.Unit_Cost__c = thePLList[i].Unit_Cost__c;
                            pp.Unit_of_Measure__c = thePLList[i].Unit_of_Measure__c;
                            pp.Status__c = 'Pending Approval';

                            if (thePLList[i].Direct_G_L_Account__c == true) {
                                pp.Show_Direct_Accouts__c = true;
                                pp.Show_Indirect_Account__c = false;
                                pp.Default_Direct_G_L_Account__c = thePLList[i].G_L_Account__c;
                            }
                            else {
                                pp.Show_Direct_Accouts__c = false;
                                pp.Show_Indirect_Account__c = true;
                                pp.Default_Indirect_G_L_Account__c = thePLList[i].G_L_Account__c;
                            }
                            ppList.add(pp);
                        }
                        //if price catalog already exist put in the map.
                        if(!lpp.isEmpty()){
                            ppMap.put(lpp[0].Name.toUpperCase(), lpp[0]);
                        }
                    }
                }
                i++;
            }

            upsert thePLList;

            //insert new item catalog on the line
            if(ppList.size() > 0){
                insert ppList;
                //update temp item lines with newly created product catalog
                for(Purchase_Price__c pp : ppList){
                    ppMap.put(pp.Name.toUpperCase(), pp);
                }
            }

            if(!ppMap.isEmpty()){
                for(Purchase_Line__c pl : thePLList){
                    if(pl.Item__r.Name.toUpperCase() == 'NEW'){
                        pl.Item__c = ppMap.get(pl.Vendor_Description__c.toUpperCase()).Id;
                    }
                }
                update thePLList;
            }

            if(oldPOList.size() > 0) {
                Decimal totalAmtInclTax = 0;

                Set<String> reapprovalProcessStatus = new Set<String>();
                reapprovalProcessStatus.add('Approved');
                reapprovalProcessStatus.add('Partially Received');
                reapprovalProcessStatus.add('Fully Received');

                for(Purchase_Line__c pl : thePLList){
                    totalAmtInclTax = totalAmtInclTax + pl.Line_Cost__c + pl.Tax__c;
                }
                if ((oldPOList[0].Approval_Status__c == thePO.Approval_Status__c) &&
                        (reapprovalProcessStatus.contains(oldPOList[0].Document_Status__c)) &&
                        (totalAmtInclTax > oldPOList[0].Approved_Amount__c)) {
                    PurchOrderApprovalProcess pap = new PurchOrderApprovalProcess(thePO);
                    pap.resubmitForApproval();
                }
            }
            return;
        } catch (Exception e) {
            // Rollback
            Database.rollback(sp);
            thePO = OldPO;
            thePLList = oldPLList;
            throw e;
            /*
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() + ', ' + e.getCause() + ', ' + e.getLineNumber() + ', ' + e.getStackTraceString()));
            return;
             */
        }

    }

    public PageReference saveAndSubmit() {
        /*
        try {
            List<String> errorList = PurchOrderApprovalProcess.checkSubmitForApproval(thePO, thePLList);
            if (errorList.size() > 0){
                for(String err : errorList){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, err));
                }
                if(!Test.isRunningTest()) return null;
            }

            this.mSaveAndSubmit();
            PageReference pageRef = new PageReference('/' + thePO.Id);
            return pageRef.setRedirect(true);
        }
        catch(Exception e) {
            System.debug('Error: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
         */
        try {
            PurchOrderApprovalProcess.checkSubmitForApproval(thePO, thePLList);
            this.mSaveAndSubmit();
            PageReference pageRef = new PageReference('/' + thePO.Id);
            return pageRef.setRedirect(true);
        }
        catch(Exception e) {
            System.debug('Error: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }

    private void mSaveAndSubmit() {
        //resolve partical data commit error <<
        Savepoint sp = Database.setSavepoint();
        try {
            //resolve partical data commit error >>
            this.msave();
            PurchOrderApprovalProcess pap = new PurchOrderApprovalProcess(thePO);
            pap.submitApprovalRequest();
        //resolve partical data commit error <<
        } catch(Exception ex) {
            Database.rollback(sp);
            throw ex;
        }
        //resolve partical data commit error >>
    }

    public PageReference reInsertPL() {

        CompanyMgmt.systemCall = true;

        // Savepoint
        Savepoint sp = Database.setSavepoint();
        try {
            //******** To overcome soql limit on reInsert PL *********
            selectBuyFromVendor();
            Integer i = 0;
            while (i < thePLList.size()) {
                if (String.isEmpty(thePLList[i].Item__c)) {
                    thePLList.remove(i);
                } else {
                    i++;
                }
            }
            Set<Id> setItemId = new Set<Id>();
            Set<Id> setUOM = new Set<Id>();
            for (Purchase_Line__c PL : thePLList) {
                if (PL.Item__c != null) {
                    setItemId.add(PL.Item__c);
                }
                if (PL.Unit_of_Measure__c != null) {
                    setUOM.add(PL.Unit_of_Measure__c);
                }
            }

            PurchOrderMgmt.mapItem = new Map<Id, Purchase_Price__c>([SELECT Id, Name, Account__c, Default_Direct_G_L_Account__c, Unit_of_Measure__c, Unit_of_Measure__r.Name
            FROM Purchase_Price__c WHERE Id IN :setItemId]);

            PurchOrderMgmt.mapItemUOM = new Map<Id, Unit_of_Measure__c>([SELECT Id, Name FROM Unit_of_Measure__c WHERE Id IN :setUOM]);

            for (Purchase_Price__c thePP : [SELECT Id, Unit_Cost__c, Unit_of_Measure__c, Minimum_Quantity__c FROM Purchase_Price__c
            WHERE Account__c = : thePO.Buy_from_Vendor__c AND Unit_of_Measure__c IN :setUOM AND Id IN :setItemId
            AND Starting_Date__c <= : thePO.Order_Date__c
            AND Ending_Date__c >= : thePO.Order_Date__c ORDER BY Unit_Cost__c ASC]) {
                String key = thePP.Id + ';' + thePP.Unit_of_Measure__c;
                if (!PurchOrderMgmt.mapPurchPrice.containsKey(key)) {
                    PurchOrderMgmt.mapPurchPrice.put(key, new List<Purchase_Price__c>());
                }
                PurchOrderMgmt.mapPurchPrice.get(key).add(thePP);
            }
            //** To overcome soql limit on reInsertPL

            // Assign those  PL which is exist in DB
            List<Purchase_Line__c> theNewPLList = new List<Purchase_Line__c>();

            // Assign those PL which is not exist in DB
            List<Purchase_Line__c> thePLListWOId = new List<Purchase_Line__c>();
            for (Purchase_Line__c PL : thePLList) {
                Purchase_Line__c newPL =  new Purchase_Line__c();
                newPL.Item__c = PL.Item__c;
                newPL.Line_No__c = PL.Line_No__c;
                if(!Test.isRunningTest()) newPL = PurchOrderMgmt.updatePL(newPL, thePO, 'theItem');
                newPL.Quantity__c = PL.Quantity__c;
                newPL.Discount_Pct__c = PL.Discount_Pct__c;
                newPL = PurchOrderMgmt.updatePL(newPL, thePO, 'theQuantity');
                newPL.Unit_of_Measure__c = PL.Unit_of_Measure__c;
                newPL = PurchOrderMgmt.updatePL(newPL, thePO, 'theUOM');
                if (PL.Id != null) {
                    newPL.Purchase_Order__c = thePO.Id;
                    theNewPLList.add(newPL);
                } else {
                    thePLListWOId.add(newPL);
                }
            }
            List<Purchase_Line__c> delPLList = new List<Purchase_Line__c>();

            //Delete lines that are not found in the temporary list
            for (Purchase_Line__c purchaseLine : [SELECT Id FROM Purchase_Line__c WHERE Purchase_Order__c = : POId]) {
                Boolean lineFound = false;
                for (Purchase_Line__c purchaseLine2 : thePLList) {
                    if (purchaseLine.Id == purchaseLine2.Id) {
                        lineFound = true;
                    }
                }
                if (lineFound == true) {
                    delPLList.add(purchaseLine);
                }
            }
            if (!delPLList.isEmpty()) {
                try {
                    //delete delPLList;

                    delete delPLList;

                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                    return null;
                }
            }

            if (thePO.Id != null || Test.isRunningTest()) {
                // Null all relationship fields to save
                thePO = PurchOrderMgmt.nullRelationshipFields(thePO);
                update thePO;
                insert theNewPLList;
                selectPO();
            }
            thePLList.clear();
            thePLList.addAll(theNewPLList);
            thePLList.addAll(thePLListWOId);
            CalculateTotal();
        } catch (Exception e) {
            // Rollback
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));

        }

        return null;
    }

    public PageReference clonePO() {

        Purchase_Order__c theNewPO;

        // Savepoint
        Savepoint sp = Database.setSavepoint();

        try {
            List<Subsidiary_Vendor__c> subVendor = [SELECT Id FROM Subsidiary_Vendor__c
            WHERE Subsidiary_Company__c = :thePO.Subsidiary_Company__c AND Account__c = :thePO.Buy_from_Vendor__c];

            if(subVendor.size() == 0){
                throw new DataException('Subsidiary Vendor is not setup for vendor: ' + thePO.Buy_from_Vendor__r.Name);
            }

            theNewPO = thePO.clone(false);
            theNewPO.Order_Date__c = Date.today();
            theNewPO = PurchOrderMgmt.validateBuyFromVendor(theNewPO);
            theNewPO = PurchOrderMgmt.nullRelationshipFields(theNewPO);
            theNewPO.Document_Status__c = 'Open';
            //ticket 14205 <<
            theNewPO.Billing_Contact__c = thePO.Billing_Contact__c;
            //ticket 14205
            theNewPO.Pending_Approval_From__c = null;
            theNewPO.Is_Temporary__c = true;
            theNewPO.Pending_Approval_Step__c = null;
            theNewPO.Approval_Status__c = null;
            theNewPO.Approval_Step_Completed__c = false;
            theNewPO.Approved_Amount__c = 0;
            theNewPO.Approval_Stage__c = null;
            theNewPO.Vendor_Invoice_No__c = null;
            theNewPO.Closed__c = false;
            theNewPO.OwnerId = UserInfo.getUserId();
            theNewPO.PO_Requestor__c = UserInfo.getUserId();
            theNewPO.Id = null;

            insert theNewPO;

            newPOId = theNewPO.Id;

            //******** To overcome soql limit on clonePO ***********
            Set<Id> setItemId = new Set<Id>();
            Set<Id> setItemUOM = new Set<Id>();
            for (Purchase_Line__c PL : thePLList) {
                if (PL.Item__c != null) {
                    setItemId.add(PL.Item__c);
                }
                if (PL.Unit_of_Measure__c != null) {
                    setItemUOM.add(PL.Unit_of_Measure__c);
                }
            }

            PurchOrderMgmt.mapItem = new Map<Id, Purchase_Price__c>([SELECT Id, Name, Account__c, Vendor_SKU__c, Vendor_Description__c, Default_Indirect_G_L_Account__c, Default_Direct_G_L_Account__c,
                    Unit_Cost__c, Unit_of_Measure__c, Unit_of_Measure__r.Name FROM Purchase_Price__c WHERE Id IN :setItemId]);

            PurchOrderMgmt.mapItemUOM = new Map<Id, Unit_of_Measure__c>([SELECT Id, Name FROM Unit_of_Measure__c WHERE Id IN :setItemUOM]);

            for (Purchase_Price__c thePP : [SELECT Id, Unit_Cost__c, Unit_of_Measure__c, Minimum_Quantity__c FROM Purchase_Price__c
            WHERE Account__c = : thePO.Buy_from_Vendor__c AND Unit_of_Measure__c IN :setItemUOM AND Id IN :setItemId
            AND Starting_Date__c <= : thePO.Order_Date__c
            AND Ending_Date__c >= : thePO.Order_Date__c ORDER BY Unit_Cost__c ASC]) {
                String key = thePP.Id + ';' + thePP.Unit_of_Measure__c;
                if (!PurchOrderMgmt.mapPurchPrice.containsKey(key)) {
                    PurchOrderMgmt.mapPurchPrice.put(key, new List<Purchase_Price__c>());
                }
                PurchOrderMgmt.mapPurchPrice.get(key).add(thePP);
            }
            PurchOrderMgmt.isClonePO = true;
            //******** To overcome soql limit on clonePO *********

            List<Purchase_Line__c> theNewPLList = new List<Purchase_Line__c>();
            for (Purchase_Line__c PL : thePLList) {
                Purchase_Line__c newPL =  new Purchase_Line__c();
                newPL.Purchase_Order__c = theNewPO.Id;
                newPL.G_L_Account__c = PL.G_L_Account__c;
                newPL.Direct_G_L_Account__c = PL.Direct_G_L_Account__c;
                newPL.Vendor_Account__c = PL.Vendor_Account__c;
                newPL.Item__c = PL.Item__c;
                newPL.Unit_of_Measure__c = PL.Unit_of_Measure__c;
                newPL.Line_No__c = PL.Line_No__c;
                //if(!Test.isRunningTest()) newPL = PurchOrderMgmt.updatePL(newPL, theNewPO, 'theItem');
                //ticket 14205 <<
                newPL.Sales_Order__c = PL.Sales_Order__c;
                newPL.Tax_Pct__c = PL.Tax_Pct__c;
                newPL.Unit_Cost__c = PL.Unit_Cost__c;
                //newPL.Tax__c = CompanyMgmt.halfUpTo2D(newPL.Line_Cost__c * (CompanyMgmt.zeroIfNull(newPL.Tax_Pct__c) / 100));
                //ticket 14205 >>
                newPL.Quantity__c = PL.Quantity__c;
                newPL.Received_Qty__c = 0;
                newPL.Discount_Pct__c = PL.Discount_Pct__c;
                newPL.Line_Cost__c = PL.Line_Cost__c;
                newPL.Tax__c = PL.Tax__c;
                //newPL = PurchOrderMgmt.updatePL(newPL, theNewPO, 'theQuantity');
                //newPL = PurchOrderMgmt.updatePL(newPL, theNewPO, 'theUOM');
                newPL.Vendor_Description__c = PL.Vendor_Description__c;
                newPL.Vendor_SKU__c = PL.Vendor_SKU__c;
                newPL.Description__c = PL.Description__c;
                newPL.Subsidiary_Company__c = PL.Subsidiary_Company__c;
                newPL.Service_Center__c = PL.Service_Center__c; ////Ticket#17993
                //nav-sf 01.20.20 <<
                newPL.Synced__c = false;
                //nav-sf 01.20.20 >>
                theNewPLList.add(newPL);
            }
            insert theNewPLList;
            PageReference POPage = new PageReference('/' + newPOId);
            POPage.setRedirect(true);
            return POPage;
        } catch (Exception e) {
            // Rollback
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));

        }

        return null;
    }

    public PageReference goToNewPO() {
        PageReference POPage;
        if (newPOId != null) {
            POPage = new PageReference('/' + newPOId);
        } else {
            POPage = new PageReference('/' + thePO.Id);
        }
        POPage.setRedirect(true);
        return POPage;
    }

    public PageReference deletePO() {
        // Savepoint
        Savepoint sp = Database.setSavepoint();
        try {
            // Delete header
            delete thePO;

            return new ApexPages.Action('{!List}').invoke();
        } catch (Exception e) {
            // Rollback
            Database.rollback(sp);

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }

    }
    
    //po void <<
    public PageReference voidPO() {
        try {
            this.voidPO(thePO.Id);
            return this.theController.view().setRedirect(true);
        }
        catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }
    
    public PageReference cancelVoid() {
        return this.theController.view();
    }
    
    private void voidPO(Id poId) {
        if (thePO.Document_Status__c == 'Partially Received' || thePO.Document_Status__c == 'Fully Received' || thePO.Document_Status__c == 'Rejected' || thePO.Document_Status__c == 'Voided') {
            throw new DataException('You cannot void this PO because it\'s been ' + thePO.Document_Status__c + '.');
        }
        else if (thePO.Document_Status__c == 'Pending Approval') {
            Savepoint sp = Database.setSavepoint();
            try {
                ProcessInstance instance = [SELECT Id FROM ProcessInstance WHERE TargetObjectId=:thePO.Id AND Status='Pending' LIMIT 1];
                if (instance != null) {
                    ProcessInstanceWorkitem workItem = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstanceId=:instance.Id LIMIT 1];
        
                    Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                    req.setWorkitemId(workItem.Id);
                    req.setAction('Removed'); // This means to remove/recall Approval Request
                    req.setComments(UserInfo.getName() + ' recalled the approval request.');
                    Approval.ProcessResult result = Approval.process(req);
                    thePO.Document_Status__c = 'Voided';
                    update thePO;
                }
            }
            catch(Exception ex) {
                Database.rollback(sp);
                throw ex;
            }
        }
        else {
            thePO.Document_Status__c = 'Voided';
            update thePO;
        }
    }
    //po void >>

    public PageReference postPR() {

        //Save Qty. to Received entered in Post Purchase receipt screen
        if (!PLList.isEmpty()){
            update PLList;
        }

        CompanyMgmt.systemCall = true;
        // Savepoint
        Savepoint sp = Database.setSavepoint();

        /*
        List<String> errorList = new List<String> ();
        errorList = PurchOrderMgmt.checkCreateReceipt(thePO);

        if (errorList.size() > 0) {
            for (Integer i = 0; i < errorList.size(); i++) {
                if (!((forceClosePO) && (errorList[i].equals('There is nothing to create.')))){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorList[i]));
                    return null;
                }
            }
        }
         */

        try {
            PurchOrderMgmt.checkCreateReceipt(thePO);
            insertPRL();
            if (thePRLList != null && thePRLList.size() > 0) {

                if (!CompanyMgmt.checkPostingDate(thePR.Posting_Date__c)) {
                    throw new DataException(thePR.Posting_Date__c.format() + ' is not within your range of allowed posting dates.');
                }
                // Post Purchase Receipt
                PurchaseReceiptMgmt.postPR(thePR, thePRLList, thePLList);
                thePR.Document_Status__c = 'Posted';

                update thePR;

                // Update Order Status
                updateOrderReceivedStatus();
                update thePO;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have successfully posted Purchase Receipt.'));
                return null;
            } else {
                if (!forceClosePO){
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There is nothing to create'));
                    throw new DataException('There is nothing to create');
                } else {
                    // Update Order Status
                    updateOrderReceivedStatus();
                    update thePO;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have successfully closed Purchase Order.'));
                }
                return null;
            }
        } catch (Exception e) {
            // Rollback
            Database.rollback(sp);
            System.debug('ERROR: Stack Trace: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }

    public void updateOrderReceivedStatus(){
        Boolean fullReceived = true;
        for(Purchase_Line__c pl : thePLList){
            if(pl.Received_Qty__c < pl.Quantity__c){
                fullReceived = false;
            }
        }

        if(fullReceived){
            thePO.Document_Status__c = 'Fully Received';
            thePO.Closed__c = true;
        } else {
            thePO.Document_Status__c = 'Partially Received';
        }

        if (forceClosePO == true) {
            thePO.Closed__c = true;
        }
    }

    public PageReference cancel() {
        return theController.cancel();
    }

    public PageReference returnBack() {
        return theController.view();
    }

    public void insertPR() {
        thePR = new Purchase_Receipt__c();
        thePR.Purchase_Order__c = POId;
        thePR.Buy_from_Vendor__c = thePO.Buy_from_Vendor__c;
        thePR.Expected_Receipt_Date__c = thePO.Expected_Receipt_Date__c;
        thePR.Actual_Receipt_Date__c = TempPR.Actual_Receipt_Date__c;
        //thePR.Posting_Date__c = date.today();
        thePR.Posting_Date__c = TempPR.Actual_Receipt_Date__c;
        thePR.Shipping_Street__c = thePO.Shipping_Street__c;
        thePR.Shipping_City__c = thePO.Shipping_City__c;
        thePR.Shipping_Country__c = thePO.Shipping_Country__c;
        thePR.Shipping_Postal_Code__c = thePO.Shipping_Postal_Code__c;
        thePR.Shipping_State__c = thePO.Shipping_State__c;
        thePR.Note__c = thePO.Note__c;
        thePR.Return_Order__c = thePO.Return_Order__c;
        thePR.Contact_Phone_No__c = thePO.Contact_Phone_No__c;
        thePR.Delivery_Contact_Name__c = thePO.Delivery_Contact_Name__c;
        thePR.Service_Center__c = thePO.Service_Center__c;
        thePR.PO_Requestor__c = thePO.PO_Requestor__c;
        thePR.Type__c = thePO.Order_Type__c;
        thePR.Subsidiary_Company__c = thePO.Subsidiary_Company__r.Name;
        thePR.Inter_Company__c = thePO.Inter_Company__c;
        thePR.Instructions_to_Vendor__c = thePO.Instructions_to_Vendor__c;
        thePR.Document_Status__c = 'Open';
        insert thePR;

    }

    public void insertPRL() {
        //companyMgmt.systemCall = true;

        List<Purchase_Line__c> theUpdatedPLList = new List<Purchase_Line__c>();
        thePRLList = new List<Purch_Rcpt_Line__c>();
        /*
        thePLList = [SELECT Name, Line_No__c, Item__c, Item__r.Name, Description__c, Unit_of_Measure__c,
                     Unit_of_Measure__r.Name, Outstanding_Qty__c,Qty_to_Receive__c, Unit_Cost__c, Received_Qty__c,
                     Purchase_Order__c, Expected_Receipt_Date__c, Discount__c, Discount_Pct__c,
                     Service_Center__c, Service_Center__r.Name, G_L_Account__c, Direct_G_L_Account__c, Note__c, Subsidiary_Company__c, Subsidiary_Company__r.Name, Vendor_Account__c, Vendor_Account__r.Name
                     FROM Purchase_Line__c WHERE Purchase_Order__c = : POId AND Qty_to_Receive__c <> 0 ORDER BY Line_No__c ];
        */
        if ( thePLList != null && thePLList.size() > 0) {
            insertPR();

            for (Integer i = 0; i < thePLList.size(); i++) {
                if(thePLList[i].Qty_to_Receive__c != 0 && thePLList[i].Qty_to_Receive__c != null){
                    thePRL = new Purch_Rcpt_Line__c();
                    thePRL.Description__c = thePLList[i].Description__c;
                    thePRL.Line_No__c = thePLList[i].Line_No__c;
                    thePRL.Item__c = thePLList[i].Item__c;
                    thePRL.Quantity__c = thePLList[i].Qty_to_Receive__c;
                    thePRL.Unit_of_Measure__c = thePLList[i].Unit_of_Measure__c;
                    thePRL.Discount__c = thePLList[i].Discount__c;
                    thePRL.Discount_Pct__c = thePLList[i].Discount_Pct__c;
                    thePRL.Receipt__c = thePR.Id;
                    thePRL.Unit_Cost__c = thePLList[i].Unit_Cost__c;
                    thePRL.Purchase_Line__c = thePLList[i].Id;
                    thePRL.Expected_Receipt_Date__c = thePLList[i].Expected_Receipt_Date__c;
                    thePRL.Service_Center__c = thePLList[i].Service_Center__c;
                    thePRL.G_L_Account__c = thePLList[i].G_L_Account__c;
                    thePRL.Direct_G_L_Account__c = thePLList[i].Direct_G_L_Account__c;
                    thePRL.Note__c = thePLList[i].Note__c;
                    thePRL.Vendor_Vehicle_Number__c = thePLList[i].Vendor_Vehicle_Number__c;
                    thePRL.Rental_Frequency__c = thePLList[i].Rental_Frequency__c;
                    thePRL.Equipment_No__c = thePLList[i].Equipment_No__c;
                    thePRL.Cost_Type__c = thePLList[i].Cost_Type__c;
                    //thePRL.Vendor_Description__c = thePLList[i].Vendor_Description__c;
                    thePRLList.add(thePRL);
                    //thePLList[i].Received_Qty__c += thePLList[i].Qty_to_Receive__c;
                    thePLList[i].Qty_to_Receive__c = 0;
                    theUpdatedPLList.add(thePLList[i]);
                }
            }

            if (thePRLList != null && thePRLList.size() > 0) {
                insert thePRLList;
            }

            if (theUpdatedPLList != null && theUpdatedPLList.size() > 0) {
                update theUpdatedPLList;
            }
        }
    }

    public PageReference insertLine() {
        if (String.isEmpty(thePO.Buy_from_Vendor__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must choose a Vendor Account.'));
            return null;
        }

        Integer PLListSize = thePLList.size();
        Integer LinesToInsert = Integer.valueOf(theCompanySetup.Lines_to_Insert__c);
        //Integer LinesToInsert = 5;
        Decimal lineNo = 0;

        if (thePLList != null && thePLList.size() > 0) {
            if (thePLList[PLListSize - 1].Line_No__c != null) {
                lineNo = thePLList[PLListSize - 1].Line_No__c;
            }
        }

        String objectType = ApexPages.currentPage().getParameters().get('ObjectType');
        if (objectType == 'PurchaseLine') {
            if (LinesToInsert > 0) {
                for (Integer i = 0; i < LinesToInsert; i++) {
                    lineNo = lineNo + 1;
                    thePLList.add(new Purchase_Line__c(Purchase_Order__c = POId, Line_No__c = lineNo, Vendor_Account__c = thePO.Buy_from_Vendor__c,
                            Subsidiary_Company__c = thePO.Subsidiary_Company__c, Service_Center__c = thePO.Service_Center__c, Direct_G_L_Account__c = false));
                }
            }
        }
        return null;
    }

    public PageReference deleteLine() {
        String objectType = ApexPages.currentPage().getParameters().get('objectType');
        String lineNo = ApexPages.currentPage().getParameters().get('lineNo');
        if (lineNo == '') {
            lineNo = '0';
        }

        if (objectType == 'PurchaseLine') {
            for (Integer i = 0; i < thePLList.size(); i++) {
                if (thePLList[i].Line_No__c == Decimal.valueOf(lineNo)) {
                    thePLList.remove(i);
                    break;
                }
            }
        }
        return null;
    }

    public PageReference validateField() {

        String fieldName = ApexPages.currentPage().getParameters().get('fieldName');
        Integer i = Integer.valueOf(ApexPages.currentPage().getParameters().get('lineNo'));
        String newFieldValue = ApexPages.currentPage().getParameters().get('newFieldValue');
        Boolean foundError = false;

        //Check order header
        if (thePO.Buy_from_Vendor__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Buy-from Vendor cannnot be blank.'));
            foundError = true;
        }
        if (foundError) {
            return null;
        }
        if (theBFVendor == null) {
            selectBuyFromVendor();
        }

        if (fieldName == 'theItem') {
            if(String.isBlank(newFieldValue)){
                thePLList[i].Item__c = null;
            } else {
                thePLList[i].Item__c = newFieldValue;
            }
            thePLList[i] = PurchOrderMgmt.updatePL(thePLList[i], thePO, 'theItem');
        } else if (fieldName == 'theQuantity') {
            foundError = false;
            if (String.isBlank(newFieldValue)) {
                newFieldValue = '0';
            }
            try {
                thePLList[i].Quantity__c = Decimal.valueOf(newFieldValue.replace(',', ''));
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
            if (String.isEmpty(thePLList[i].Item__c)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Item must not be blank.'));
                foundError = true;
            }
            if (thePLList[i].Unit_of_Measure__c == null) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unit of Measure must not be blank.'));
                foundError = true;
            }
            if ((thePLList[i].Quantity__c).abs() < (thePLList[i].Received_Qty__c).abs()) {
                if (thePO.Return_Order__c) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Quantity cannot be less than Returned ' +
                            'Qty. ' + (thePLList[i].Received_Qty__c).abs() + '. Line No: ' + thePLList[i].Line_No__c));

                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Quantity cannot be less than Received ' +
                            'Qty. ' + (thePLList[i].Received_Qty__c).abs() + '. Line No: ' + thePLList[i].Line_No__c));
                }
                foundError = true;
            }

            if (foundError) {
                return null;
            }
            thePLList[i] = PurchOrderMgmt.updatePL(thePLList[i], thePO, 'theQuantity');
        } else if (fieldName == 'theUOM') {
            if (String.isBlank(newFieldValue)){
                return null;
            }
            if (String.isEmpty(thePLList[i].Item__c)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Item must not be blank.'));
                return null;
            }
            thePLList[i].Unit_of_Measure__c = newFieldValue;
            thePLList[i] = PurchOrderMgmt.updatePL(thePLList[i], thePO, 'theUOM');
        } else if (fieldName == 'theUnitCost') {
            if (String.isBlank(newFieldValue)) newFieldValue = '0';
            try {
                thePLList[i].Unit_Cost__c = Decimal.valueOf(newFieldValue);
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
            if (String.isEmpty(thePLList[i].Item__c)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Item must not be blank.'));
                return null;
            }
            thePLList[i] = PurchOrderMgmt.updatePL(thePLList[i], thePO, 'theUnitCost');
        } else if (fieldName == 'theDiscountPct') {
            if (String.isBlank(newFieldValue)) newFieldValue = '0';
            try {
                thePLList[i].Discount_Pct__c = Decimal.valueOf(newFieldValue);
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
            if (String.isEmpty(thePLList[i].Item__c)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Item must not be blank.'));
                return null;
            }
            thePLList[i] = PurchOrderMgmt.updatePL(thePLList[i], thePO, 'theDiscountPct');
        } else if (fieldName == 'theTaxPct') {
            if (String.isBlank(newFieldValue)) newFieldValue = '0';
            try{
                thePLList[i].Tax_Pct__c = Decimal.valueOf(newFieldValue);
                thePLList[i] = PurchOrderMgmt.updatePL(thePLList[i], thePO, 'theTaxPct');
            } catch (Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
            if(thePLList[i].Item__c == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Item must not be blank.'));
                return null;
            }
        } else if(fieldName == 'theLineSalesOrder'){
            if(String.isEmpty(thePLList[i].Item__c)){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Item must not be blank.'));
                return null;
            }

            if(!String.isBlank(newFieldValue)) {
                thePLList[i].Direct_G_L_Account__c = true;
            } else {
                thePLList[i].Direct_G_L_Account__c = false;
            }

            thePLList[i] = PurchOrderMgmt.updatePL(thePLList[i], thePO, 'theLineSalesOrder');
        } else if(fieldName == 'theLineServiceCenter'){
            if(String.isBlank(newFieldValue)){
                return null;
            }
            thePLList[i].Service_Center__c = newFieldValue;
            thePLList[i].Sales_Order__c = null;
            thePLList[i].Sales_Order__r = null;
            thePLList[i].Direct_G_L_Account__c = false;
            thePLList[i] = PurchOrderMgmt.updatePL(thePLList[i], thePO, 'theLineServiceCenter');
        } else if(fieldName == 'theLineGLAccount'){
            thePLList[i].G_L_Account__c = newFieldValue;
            thePLList[i] = PurchOrderMgmt.updatePL(thePLList[i], thePO, 'theLineGLAccount');
        } else if(fieldName == 'theLineDirectGLAccount'){ //Ticket 13388 >>
            if(newFieldValue == 'true'){
                thePLList[i].Direct_G_L_Account__c = true;
            } else {
                thePLList[i].Direct_G_L_Account__c = false;
        }
            thePLList[i] = PurchOrderMgmt.updatePL(thePLList[i], thePO, 'theLineDirectGLAccount');
        }

        CalculateTotal();

        return null;
    }

    public void CalculateTotal() {
        PLSubtotal = 0.00;
        TotalIncTax = 0.00;
        TaxAmt = 0.00;
        for (Purchase_Line__c thePL : thePLList) {
            PLSubtotal += CompanyMgmt.zeroIfNull(thePL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
            TaxAmt += CompanyMgmt.zeroIfNull(thePL.Tax__c).setScale(2, RoundingMode.HALF_UP);
        }
        Decimal freight = CompanyMgmt.zeroIfNull(thePO.Estimated_Freight_Amount__c);
        TotalIncTax += CompanyMgmt.zeroIfNull(PLSubtotal + TaxAmt + freight).setScale(2, RoundingMode.HALF_UP);
    }

    public void selectBuyFromVendor() {
        if (thePO.Buy_from_Vendor__c != null) {
            theBFVendor = [SELECT Id, Name,Auto_Create_Catalog_Item__c
            FROM Account
            WHERE Id = : thePO.Buy_from_Vendor__c];
        }
    }
    public void updateReturnOrder() {
        thePO.Return_Order__c = PO.Return_Order__c;
    }

    public void updateReceiptDate() {
        List<Purchase_Line__c> theNewRDPLList = new List<Purchase_Line__c>();
        CompanyMgmt.systemCall = true;

        // Open PL is PL without any linked WRL, Open or Posted
        if (thePLList != null && thePLList.size() > 0) {
            Set<Id> thePLIdList = new Set<Id>();

            for (Purchase_Line__c thePL : thePLList) {
                thePLIdList.add(thePL.Id);
            }

            //theNewPILList = new  List<Purchase_Invoice_Line__c>();
            List<Purch_Rcpt_Line__c> thePRLList = [SELECT Id, Name, Purchase_Line__c
            FROM Purch_Rcpt_Line__c WHERE Purchase_Line__c IN: thePLIdList];

            thePLIdList.clear();

            for (Purch_Rcpt_Line__c thePLPRL : thePRLList) {
                thePLIdList.add(thePLPRL.Purchase_Line__c);
            }

            for (Purchase_Line__c thePL : thePLList) {
                if (!thePLIdList.contains(thePL.Id)) {
                    thePL.Expected_Receipt_Date__c = thePO.Expected_Receipt_Date__c;
                }
                if (thePL.Id != null) {
                    theNewRDPLList.add(thePL);
                }
            }
            if (theNewRDPLList.size() > 0) {
                update theNewRDPLList;
            }
        }
    }

    public PageReference openPO() {
        CompanyMgmt.systemCall = true;

        if (thePO.Closed__c == false) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Purchase Order is open already.'));
            return null;
        } else {
            thePO.Closed__c = false;

            update thePO;

            return theController.view();
        }
    }

    public PageReference closePO() {
        /*
        CompanyMgmt.systemCall = true;

        List<String> errorList = new List<String> ();

        errorList = PurchOrderMgmt.checkClose(thePO);

        if (errorList.size() > 0) {
            for (Integer i = 0; i < errorList.size(); i++) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorList[i]));
            }
            return null;
        } else {
            thePO.Closed__c = true;
            update thePO;
        }

        return theController.view();
         */
        Savepoint sp = Database.setSavepoint();
        try {
            CompanyMgmt.systemCall = true;
            PurchOrderMgmt.checkClose(thePO);
            thePO.Closed__c = true;
            update thePO;
            return theController.view();
        } catch(Exception e) {
            Database.rollback(sp);
            System.debug('Error: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }

    }

    public PageReference SendEmail(){
        //define email
        if ((thePO.Document_Status__c == 'Open') || (thePO.Document_Status__c == 'Pending Approval') || (thePO.Document_Status__c == 'Rejected')){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Cannot print document before order is approved!'));
            return null;
        }

        if(String.isNotEmpty(thePO.Buy_from_Vendor__r.E_Mail__c)){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

            //Reference the attachment
            PageReference purchPDF = Page.PurchaseOrderPDF;
            purchPDF.getParameters().put('id', (String) thePO.Id);
            purchPDF.setRedirect(true);
            Messaging.EmailFileAttachment efa;
            if(!Test.isRunningTest())
            {
                Blob b = purchPDF.getContent();
                efa = new Messaging.EmailFileAttachment();
                efa.setFileName(thePO.Name + '_' + thePO.Buy_from_Vendor__r.Name + '.pdf');
                efa.setBody(b);
            }
            String[] addresses = new List<String>();
            addresses.add(thePO.Buy_from_Vendor__r.E_Mail__c);
            email.setSubject('Test PDF');
            email.setToAddresses(addresses);
            email.setPlainTextBody('test body');
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{ efa });

            if(!Test.isRunningTest()) {
                Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ email });
            }
        }

        return theController.view();
    }

    public PageReference submitForApproval(){
        /*
        List<String> errorList = new List<String>();
        errorList = PurchOrderApprovalProcess.checkSubmitForApproval(thePO, thePLList);
        if (errorList.size() > 0){
            for(String err : errorList){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, err));
            }
            return null;
        } else {
            PurchOrderApprovalProcess pap = new PurchOrderApprovalProcess(thePO);
            pap.submitApprovalRequest();
        }
        return theController.view();
         */

        Savepoint sp = Database.setSavepoint();
        try {
            PurchOrderApprovalProcess.checkSubmitForApproval(thePO, thePLList);
            PurchOrderApprovalProcess pap = new PurchOrderApprovalProcess(thePO);
            pap.submitApprovalRequest();
            return theController.view();
        } catch(Exception e) {
            Database.rollback(sp);
            System.debug('Error: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }
}