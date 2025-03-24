public with sharing class SalesInvoiceMgmt {
    //public static Boolean isCloneSO = false;
    public static Map<Id, Resource__c> mapResource = new Map<Id, Resource__c>();
    //public static Map<Id, Unit_of_Measure__c> mapItemUOM = new Map<Id, Unit_of_Measure__c>();
    public static Map<String, Decimal> mapSalesTax = new Map<String, Decimal>();
    public static Boolean isReinsertSL = false;
    public static Map<Id, Account> mapAccount = new Map<Id, Account>();
    public static Map<Id, Resource_Type__c> mapResourceType = new Map<Id, Resource_Type__c>();
    //public static Map<String, Contract_Line__c> mapContractLines = new Map<String, Contract_Line__c>();
    //public static Map<Id, Contract_Line__c> mapCL = new Map<Id, Contract_Line__c>();
    public static Boolean oldInvoiceBypassInterCoCostCheck = false;

    public static List <String> checkSave(Sales_Invoice__c theSI, List<Sales_Invoice_Line__c> theSILList) {
        List<String> errorList = new List<String>();
        //Ticket#14554 >>
        if(String.isBlank(theSI.Site_Scope__c)){
            errorList.add('Site Scope must not be blank!');
        }

        //Credit Memo created from Sales Order AKA Partial credit memo
        if(theSI.Credit_Memo__c == true && theSI.Misc_Invoice__c == true){
            if(String.isBlank(theSI.Reversed_from_SI__c)){
                errorList.add('Applies-to Invoice No. must not be blank for partial invoice!');
            }
        }
        //Ticket#14554 <<
        // Bypass checkings when allow data override
//        if (CompanyMgmt.allowDataOverride()) {
//            return errorList;
//        }
        return errorList;
    }

    public static List <String> checkPost(Sales_Invoice__c theSI) {
        List<String> errorList = new List<String>();
        Set<String> setTML = new Set<String>();
        List<TM_Line__c> theTMLineList = new List<TM_Line__c>();

        List<Sales_Invoice_Line__c> theSILList = [
                SELECT Line_No__c, Quantity__c, Name, TM_Line__c,Resource_Type__c
                FROM Sales_Invoice_Line__c
                WHERE Sales_Invoice__c = :theSI.Id AND Quantity__c <> 0
        ];

        if (theSI.Document_Status__c == 'Posted') {
            errorList.add('Sales Invoice was posted already.');
        } else {
            if (theSILList.size() == 0) {
                errorList.add('There is nothing to post.');
            } else {
                // Check posting date
                if (!CompanyMgmt.checkPostingDate(theSI.Posting_Date__c)) {
                    errorList.add(theSI.Posting_Date__c.format() + ' is not within your range of allowed posting dates.');
                }
                //Ticket# 13886 >>
                if (theSI.Reversed_from_SI__c != null){
                    System.debug(theSI.Reversed_from_SI__c);
                    Sales_Invoice__c reversedFromSI = [SELECT Id, Name, Posting_Date__c FROM Sales_Invoice__c WHERE Id = :theSI.Reversed_from_SI__c];
                    if (theSI.Posting_Date__c < reversedFromSI.Posting_Date__c){
                        errorList.add('Credit memo posting date must not be earlier than the original invoice: ' + reversedFromSI.Name + ' posting date ' + reversedFromSI.Posting_Date__c);
                    }
                }
                //Ticket# 13886 >>
                if (theSI.Invoice_Date__c == null) {
                    errorList.add('Invoice Date cannot be blank.');
                }
                // Check Inter-co
                //Ticket#21211
                /*
                 *   Inter_co_Account__c - renamed to Intra-Co
                 *   Add new Inter-Co InterCo__c for Republic Service
                 */
                if (theSI.Bill_to_Customer__r.Inter_co_Account__c == true || theSI.Bill_to_Customer__r.InterCo__c == true) {
                    if (theSI.Bill_to_Customer__r.Inter_co_AR_Account__c == null) {
                        errorList.add('You must specify Inter-Co AR Account for the Bill-to Customer.');
                    }
                    if (theSI.Bill_to_Customer__r.Inter_co_Revenue_Account__c == null) {
                        errorList.add('You must specify Inter-Co Revenue Account for the Bill-to Customer.');
                    }
                }

                //Ticket#21357
                if (theSI.Contact__r.Blocked__c == true) {
                    errorList.add('Invoice cannot be posted because Contact has been blocked/inactive.');
                }

                //Check Amount
                if (!theSI.Credit_Memo__c){
                    if (theSI.Invoice_Amount__c < 0){
                        errorList.add('Invoice Amount cannot be negative for Sales Invoice.');
                    }
                } else {
                    if (theSI.Invoice_Amount__c > 0){
                        errorList.add('Invoice Amount cannot be positive for Credit Memo.');
                    }
                }

                //Check when posting misc. credit memo
                if(String.isNotBlank(theSI.Reversed_from_SI__c) && theSI.Misc_Invoice__c == true){
                    if(theSI.Reversed_from_SI__r.Balance__c < Math.abs(theSI.Invoice_Amt_Incl_Tax__c)){
                        errorList.add('Credit Memo amount: ' + Math.abs(theSI.Invoice_Amt_Incl_Tax__c) + ' is larger than remaining balance '
                                + theSI.Reversed_from_SI__r.Balance__c + ' on invoice# ' + theSI.Reversed_from_SI__r.Name);
                    }
                }

                //Check TML
                for (Sales_Invoice_Line__c SIL : theSILList) {
                    if (SIL.TM_Line__c != null && !setTML.contains(SIL.TM_Line__c)) {
                        setTML.add(SIL.TM_Line__c);
                    }
                }

                if (setTML.size() > 0) {
                    theTMLineList = [SELECT Id, Name, Invoiced__c FROM TM_Line__c WHERE Id IN:setTML];
                    if (theTMLineList != null && theTMLineList.size() > 0) {
                        for (TM_Line__c TML : theTMLineList) {
                            //We check Invoiced field when creating invoices
                            //if(TML.Invoiced__c && theSI.Credit_Memo__c != true) {
                            //    errorList.add('T&M Line: ' + TML.Name + ' is already invoiced.');
                            //}
                            if(TML.Invoiced__c == false && theSI.Credit_Memo__c == true) {
                                errorList.add('T&M Line: ' + TML.Name + ' is not yet invoiced.');
                            }
                        }
                    }
                }
            }
        }
        return errorList;
    }

    public static List<String> checkReverseSI(Sales_Invoice__c theSI) {
        List<Sales_Invoice_Line__c> theSILList;
        List<String> errorList = new List<String>();
        List<GL_Entry__c> theGLList = new List<GL_Entry__c>();

        if (theSI.Credit_Memo__c == true) {
            errorList.add('You can only reverse from Invoice.');
        }
        if (theSI.Document_Status__c == 'Open') {
            errorList.add('Invoice is not posted yet.');
        }
        theGLList = [SELECT GL_Batch__r.Name, GL_Batch__r.Sync_d__c FROM GL_Entry__c WHERE Sales_Invoice__c = :theSI.Id];
        for (GL_Entry__c GL : theGLList) {
            if (GL.GL_Batch__r.Sync_d__c != true) {
                errorList.add('GL Batch ' + GL.GL_Batch__r.Name + ' is not yet sent to Dynamics NAV. Try to unpost.');
            }
        }

        List<Customer_Ledger_Entry__c> cleLst = [SELECT Open__c FROM Customer_Ledger_Entry__c
        WHERE Document_Type__c = 'Invoice' AND Document_No__c =: theSI.Name];

        for(Customer_Ledger_Entry__c cle:cleLst){
            if(cle.Open__c == false){
                errorList.add('You cannot reverse Sales Invoice '+ theSI.Name + ' since all entries related to it are closed.');
            }
        }

        List<Retainage_Ledger_Entry__c> retainageLedgerEntries = [
                SELECT Id, Invoiced__c, Closed_By_Invoice_No__c, Closed_By_Invoice_No__r.Name
                FROM Retainage_Ledger_Entry__c WHERE Sales_Invoice__c = :theSI.Id AND Closed_By_Invoice_No__c != NULL];
        if(retainageLedgerEntries.size() > 0){
            errorList.add('You cannot reverse Sales Invoice ' + theSI.Name + ' because it is linked to a retainage invoice ' + retainageLedgerEntries[0].Closed_By_Invoice_No__r.Name + '.  ' +
                    'Please reverse or un-post the linked retainage invoice first!');
        }

        theSILList = [
                SELECT Name
                FROM Sales_Invoice_Line__c
                WHERE Sales_Invoice__c = :theSI.Id
        ];
        if (theSILList == null || theSILList.size() == 0) {
            errorList.add('There are not lines to reverse.');
        }

        if (theSI.Reversed__c == true) {
            errorList.add('The Invoice is reversed already.');
        }

        return errorList;
    }

    /*
     *  Ticket#19992
     *      - allow post to resource sales gl account when bundled.
     */
    public static void postSI(List<Sales_Invoice_Line__c> theSILList, Sales_Invoice__c theSI) {
        Map<Id, Decimal> mapGLAccountAmt = new Map<Id, Decimal>();
        Id GLAccount;
        Id SIId = theSI.Id;
        Decimal GLAmount;
        CompanyMgmt.systemCall = true;
        Integer i;
        if(theSI.Id == 'a1U8X000008s8X1UAI'){
            oldInvoiceBypassInterCoCostCheck = true;
        }
        List<Tax_Jurisdiction__c> taxJurisdictions = [SELECT Id, Name FROM Tax_Jurisdiction__c WHERE Tax_Area__c = :theSI.Tax_Area__c LIMIT 1];
        Tax_Jurisdiction__c taxJurisdiction = new Tax_Jurisdiction__c();
        if(taxJurisdictions.size() > 0){
            taxJurisdiction = taxJurisdictions[0];
        } else {
            throw new myException('Setup for Tax Area Code: ' + theSI.Tax_Area__r.Name + ' is not complete! Missing Tax Jurisdiction and Tax Detail!');
        }

        List<GL_Entry__c> theGLList = new List<GL_Entry__c>();
        GL_Entry__c theGL;

        Company_Setup__c theCompanySetup = CompanyMgmt.getCompanySetup();
        if (theSI.Tax_Area__r.Sales_Tax_Account__c == null && !Test.isRunningTest()){
            throw new myException('Sales Tax Account cannot be blank for Tax Area: ' + theSI.Tax_Area__r.Name);
        }

        if(theSI.Credit_Memo__c == true){
            if(theSI.Invoice_Amt_Incl_Tax__c > 0 && theSI.Invoice_Amt_Incl_Tax__c != theSI.Invoice_Tax__c){
                throw new myException('Amount for Credit Memo must be negative!.');
            }
        }

        //Post GL Entries
        if (theSI.Invoice_Amt_Incl_Tax__c <> 0) {
            // Post AR
            theGL = new GL_Entry__c();
            theGL.Account__c = theSI.Bill_to_Customer__c;
            theGL.Amount__c = theSI.Invoice_Amt_Incl_Tax__c;
            if(theGL.Amount__c == null)
                theGL.Amount__c = 0;
            Decimal retaiangeAmount = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(theSI.Retainage_Amount__c));
            if(retaiangeAmount > 0){
                if(theSI.Credit_Memo__c == true){
                    theGL.Amount__c = theGL.Amount__c + retaiangeAmount;
                } else {
                    theGL.Amount__c = theGL.Amount__c - retaiangeAmount;
                }
            }

            theGL.Service_Center__c = theSI.Service_Center__c; //AES-406
            theGL.Subsidiary_Company__c = theSI.Subsidiary_Company__c; //AES-406
            //Ticket#21211 - Add new Inter-Co InterCo__c for Republic Service
            if (theSI.Bill_to_Customer__r.Inter_co_Account__c == false && theSI.Bill_to_Customer__r.InterCo__c == false) {
                theGL.GL_Account__c = theCompanySetup.AR_GL_Account__c;
            } else {
                theGL.GL_Account__c = theSI.Bill_to_Customer__r.Inter_co_AR_Account__c;
            }

            theGL = updateGL(theGL, theSI, true);
            theGL.Tax_Line__c = true;
            theGL.Tax_Area__c = theSI.Tax_Area__c;
            theGL.Tax_Jurisdiction__c = taxJurisdiction.Id;
            theGL.Tax_Group__c = 'NT';
            if (theSI.Invoice_Tax__c == 0) {
                theGL.Tax_Base_Amount__c = theSI.Invoice_Amount__c;
            } else {
                theGL.Tax_Base_Amount__c = theSI.NT_Amount__c;
            }
            theGL.Tax__c = 0;
            theGL.Tax_Liable__c = theSI.Tax_Liable__c;
            theGLList.add(theGL);

            // Post Retainage
            Retainage_Ledger_Entry__c retainageLedgerEntry;
            if(theSI.Credit_Memo__c != true){
                if(theSI.Retainage_Invoice__c != true && retaiangeAmount > 0){
                    GL_Entry__c retainageGL = theGL.clone(false);
                    retainageGL.GL_Account__c = CompanySettingUtil.acvSetting.Retainage_Receivable_GL_Account_Id__c;
                    retainageGL.Amount__c = retaiangeAmount;
                    retainageGL = updateGL(retainageGL, theSI, false);
                    retainageGL.Tax__c = 0;
                    retainageGL.Tax_Group__c = null;
                    retainageGL.Tax_Line__c = false;
                    retainageGL.Tax_Area__c = null;
                    retainageGL.Tax_Jurisdiction__c = null;
                    retainageGL.Tax_Base_Amount__c = null;
                    retainageGL.Tax_Liable__c = false;
                    theGLList.add(retainageGL);

                    retainageLedgerEntry = new Retainage_Ledger_Entry__c();
                    retainageLedgerEntry.Sales_Invoice__c = theSI.Id;
                    retainageLedgerEntry.Customer__c = theSI.Bill_to_Customer__c;
                    retainageLedgerEntry.Sales_Order__c = theSI.Sales_Order__c;
                    retainageLedgerEntry.Amount__c = retainageGL.Amount__c;
                    insert retainageLedgerEntry;
                } else if (theSI.Retainage_Invoice__c == true){
                    retainageLedgerEntry = [SELECT Id, Invoiced__c
                    FROM Retainage_Ledger_Entry__c
                    WHERE Closed_By_Invoice_No__c = :theSI.Id LIMIT 1];
                    retainageLedgerEntry.Invoiced__c = true;
                    update retainageLedgerEntry;
                }
            } else {
                if(theSI.Retainage_Invoice__c != true && retaiangeAmount > 0) {
                    GL_Entry__c retainageGL = theGL.clone(false);
                    retainageGL.GL_Account__c = CompanySettingUtil.acvSetting.Retainage_Receivable_GL_Account_Id__c;
                    retainageGL.Amount__c = retaiangeAmount * -1;
                    retainageGL = updateGL(retainageGL, theSI, false);
                    retainageGL.Tax__c = 0;
                    retainageGL.Tax_Group__c = null;
                    retainageGL.Tax_Line__c = false;
                    retainageGL.Tax_Area__c = null;
                    retainageGL.Tax_Jurisdiction__c = null;
                    retainageGL.Tax_Base_Amount__c = null;
                    retainageGL.Tax_Liable__c = false;
                    theGLList.add(retainageGL);
                }

                if(theSI.Reversed_from_SI__r.Retainage_Invoice__c == true){
                    retainageLedgerEntry = [SELECT Id, Closed_By_Invoice_No__c, Invoiced__c
                    FROM Retainage_Ledger_Entry__c
                    WHERE Closed_By_Invoice_No__c = :theSI.Reversed_from_SI__c LIMIT 1];
                    retainageLedgerEntry.Invoiced__c = false;
                    retainageLedgerEntry.Closed_By_Invoice_No__c = null;
                    retainageLedgerEntry.Closed_By_Invoice_Reversed_By__c = theSI.Id;
                    update retainageLedgerEntry;
                } else if(retaiangeAmount > 0 && !Test.isRunningTest()){
                    retainageLedgerEntry = [SELECT Id, Closed_By_Invoice_No__r.Name, Invoiced__c,Closed_By_Invoice_No__c
                    FROM Retainage_Ledger_Entry__c
                    WHERE Sales_Invoice__c = :theSI.Reversed_from_SI__c LIMIT 1];
                    if(String.isNotBlank(retainageLedgerEntry.Closed_By_Invoice_No__c) || retainageLedgerEntry.Invoiced__c == true){
                        throw new DataException('Cannot post Credit Memo# ' + theSI.Name + ' because the invoice it try to revser is linked to retainage invoice# ' + retainageLedgerEntry.Closed_By_Invoice_No__r.Name + '.' +
                                ' Please credit out the retainage invoice first!');
                    }
                    if(retainageLedgerEntry != null){
                        delete retainageLedgerEntry;
                    }
                }
            }

            // Post Sales Tax Payable
            if (theSI.Invoice_Tax__c <> 0){
                theGL = new GL_Entry__c();
                if(theSI.Credit_Memo__c == true && theSI.Invoice_Amt_Incl_Tax__c > 0){
                    theGL.Amount__c = CompanyMgmt.zeroIfNull(theSI.Invoice_Tax__c);
                } else {
                    theGL.Amount__c = -CompanyMgmt.zeroIfNull(theSI.Invoice_Tax__c);
                }

                theGL.Service_Center__c = theSI.Service_Center__c; //AES-406
                theGL.Subsidiary_Company__c = theSI.Subsidiary_Company__c; //AES-406
                theGL.GL_Account__c = theSI.Tax_Area__r.Sales_Tax_Account__c;
                theGL = updateGL(theGL, theSI, false);
                theGL.Tax_Line__c = true;
                theGL.Tax_Area__c = theSI.Tax_Area__c;
                theGL.Tax_Jurisdiction__c = taxJurisdiction.Id;
                theGL.Tax_Group__c = 'TX';
                theGL.Tax_Base_Amount__c = CompanyMgmt.zeroIfNull(theSI.Invoice_Amount__c) - CompanyMgmt.zeroIfNull(theSI.NT_Amount__c);
                theGL.Tax__c = CompanyMgmt.zeroIfNull(theSI.Invoice_Tax__c);
                theGL.Tax_Liable__c = theSI.Tax_Liable__c;
                theGLList.add(theGL);
            }
        }

        // get updated Sales Invoice Line List
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Sales_Invoice_Line__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Sales_Invoice__r.Bill_to_Customer__c,Sales_Invoice__r.Posting_Date__c, Resource__r.Sales_GL_Account__c, Resource__r.Post_Sale_to_Own_GL_Acct_When_Bundled__c, ' +
                'Sales_Invoice__r.Service_Center__r.Name, Service_Center__r.Name, Service_Center__r.Temporary__c, ' +
                'Resource__r.Exclude_from_I_C_Cost_Calculation__c, Sales_Invoice_Job_Task__r.Billing_Type__c';
        strQuery += ' FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c =: SIId ORDER BY Line_No__c';
        theSILList = Database.query(strQuery);

        // Post Sales Invoice Lines
        //Ticket#21211 Add new Inter-Co InterCo__c for Republic Service
        if (theSI.Bill_to_Customer__r.Inter_co_Account__c == false && theSI.Bill_to_Customer__r.InterCo__c == false) {
            //Ticket#19992
            Map<Id, Decimal> glAmountByPostToOwnWhenBundledGLAccounts = new Map<Id, Decimal>();
            Map<Id, Decimal> glAmountByDeductFromGLAccountId = new Map<Id, Decimal>();
            Id bundledGLId = theCompanySetup.Lump_Sum_GL_Account__c;
            List<Resource__c> fixPriceResource = new List<Resource__c>();
            if(Test.isRunningTest() == false) {
                fixPriceResource = [SELECT Id, Sales_GL_Account__c FROM Resource__c WHERE Id = :CompanySettingUtil.acvSetting.Fixed_Price_Job_Resource__c];
            } else {
                fixPriceResource = [SELECT Id, Sales_GL_Account__c FROM Resource__c WHERE Category__c = 'Misc. Charges And Taxes'];
            }
            if(fixPriceResource.size() == 0){
                if(Test.isRunningTest() == false) {
                    throw new DataException('Fixed Price Resource Id is not setup!');
                }
            }

            Id fixedPriceResourceGLId = fixPriceResource[0].Sales_GL_Account__c;

            for(Sales_Invoice_Line__c salesInvoiceLine : theSILList){
                if((salesInvoiceLine.Bill_as_Lump_Sum__c == true || (salesInvoiceLine.Sales_Invoice_Job_Task__c != null && salesInvoiceLine.Sales_Invoice_Job_Task__r.Billing_Type__c == 'Fixed Price')) &&
                        CompanyMgmt.zeroIfNull(salesInvoiceLine.xLine_Amount__c) <> 0 &&
                        salesInvoiceLine.Resource__r.Post_Sale_to_Own_GL_Acct_When_Bundled__c == true &&
                        String.isNotBlank(salesInvoiceLine.Resource__r.Sales_GL_Account__c)){
                    GLAccount = salesInvoiceLine.Resource__r.Sales_GL_Account__c;
                    GLAmount = -salesInvoiceLine.xLine_Amount__c;

                    if(glAmountByPostToOwnWhenBundledGLAccounts.containsKey(GLAccount)){
                        GLAmount = glAmountByPostToOwnWhenBundledGLAccounts.get(GLAccount) + GLAmount;
                    }
                    glAmountByPostToOwnWhenBundledGLAccounts.put(GLAccount, GLAmount);

                    if(salesInvoiceLine.Sales_Invoice_Job_Task__c != null) {
                        Decimal amount = -salesInvoiceLine.xLine_Amount__c;
                        Id lookupId = bundledGLId;
                        if (salesInvoiceLine.Sales_Invoice_Job_Task__r.Billing_Type__c == 'Fixed Price') {
                            lookupId = fixedPriceResourceGLId;
                        }

                        if(glAmountByDeductFromGLAccountId.containsKey(lookupId)){
                            amount = amount + glAmountByDeductFromGLAccountId.get(lookupId);
                        }
                        glAmountByDeductFromGLAccountId.put(lookupId, amount);
                    }
                }
            }
            //Ticket#19992

            for (i = 0; i < theSILList.size(); i++) {
                // Post Sales
                if(theSILList[i].Resource__r.Sales_GL_Account__c != null){
                    GLAccount = theSILList[i].Resource__r.Sales_GL_Account__c;
                } else {
                    if (theSILList[i].Category__c == 'Labor') {
                        GLAccount = theCompanySetup.Labor_GL_Account__c;
                    } else if (theSILList[i].Category__c == 'Equipment') {
                        GLAccount = theCompanySetup.Equipment_GL_Account__c;
                    } else if (theSILList[i].Category__c == 'Materials') {
                        GLAccount = theCompanySetup.Material_GL_Account__c;
                    } else if (theSILList[i].Category__c == 'Subcontractors') {
                        GLAccount = theCompanySetup.Subcontractors_GL_Account__c;
                    } else if (theSILList[i].Category__c == 'Waste Disposal') {
                        GLAccount = theCompanySetup.Waste_Disposal_GL_Account__c;
                    } else if (theSILList[i].Category__c == 'Demurrage') {
                        if (theSILList[i].Resource__r.Sales_GL_Account__c != null){
                            GLAccount = theSILList[i].Resource__r.Sales_GL_Account__c;
                        } else {
                            GLAccount = theCompanySetup.Demurrage_GL_Account__c;
                        }
                    } else if (theSILList[i].Category__c == 'Misc. Charges And Taxes') {
                        GLAccount = theCompanySetup.MCNT_GL_Account__c;
                    } else if (theSILList[i].Category__c == 'Bundled') {
                        GLAccount = theCompanySetup.Lump_Sum_GL_Account__c;
                    } else {
                        GLAccount = theCompanySetup.MCNT_GL_Account__c;  // place holder for Lump Sum
                    }
                }

                GLAmount = -CompanyMgmt.zeroIfNull(theSILList[i].Line_Amount__c);

                if (mapGLAccountAmt.get(GLAccount) == null) {
                    mapGLAccountAmt.put(GLAccount, GLAmount);
                } else {
                    mapGLAccountAmt.put(GLAccount, mapGLAccountAmt.get(GLAccount) + GLAmount);
                }
            }

            //Ticket#19992
            for(Id lookupId : glAmountByDeductFromGLAccountId.keySet()){
                Decimal glAmountToDeduct = glAmountByDeductFromGLAccountId.get(lookupId);
                Decimal acctTotalGlAmount = mapGLAccountAmt.get(lookupId);
                System.debug('Info: lookupId ' + lookupId + ' --- acctTotalGlAmount ' + acctTotalGlAmount + ' -- glAmountToDeduct: ' + glAmountToDeduct);
                mapGLAccountAmt.put(lookupId, acctTotalGlAmount - glAmountToDeduct);
            }

            for (Id key : glAmountByPostToOwnWhenBundledGLAccounts.keySet()) {
                Decimal amount = glAmountByPostToOwnWhenBundledGLAccounts.get(key);
                if (amount <> 0) {
                    if (mapGLAccountAmt.containsKey(key)) {
                        GLAmount = mapGLAccountAmt.get(key) + amount;
                    }
                    mapGLAccountAmt.put(key, GLAmount);
                }
                System.debug('Info: key ' + key + ' --- GLAmount ' + GLAmount);
            }
            //Ticket#19992

            for (Id key : mapGLAccountAmt.keySet()) {
                if (mapGLAccountAmt.get(key) <> 0) {
                    theGL = new GL_Entry__c();
                    theGL.Service_Center__c = theSI.Service_Center__c; //AES-406
                    theGL.Subsidiary_Company__c = theSI.Subsidiary_Company__c; //AES-406
                    theGL.Amount__c = mapGLAccountAmt.get(key);
                    theGL.GL_Account__c = key;
                    theGL = updateGL(theGL, theSI, false);
                    theGL.Posting_Type__c = 'Sales';
                    theGLList.add(theGL);
                }
            }
        } else {
            // Post Revenue for Inter-Co
            theGL = new GL_Entry__c();
            theGL.Service_Center__c = theSI.Service_Center__c; //AES-406
            theGL.Subsidiary_Company__c = theSI.Subsidiary_Company__c; //AES-406
            theGL.Amount__c = -(theSI.Invoice_Amt_Incl_Tax__c - theSI.Invoice_Tax__c);
            theGL.GL_Account__c = theSI.Bill_to_Customer__r.Inter_co_Revenue_Account__c;
            theGL = updateGL(theGL, theSI, false);
            theGL.Posting_Type__c = 'Sales';
            theGLList.add(theGL);
        }

        //Post Inter-co entries - AES-406
        Map<Id, String> serviceCenterCodeMap = new Map<Id, String>();
        serviceCenterCodeMap.put(theSI.Service_Center__c, theSI.Service_Center__r.Name);
        Set<Id> resTypeIdSet = new Set<Id>();
        List<Sales_Invoice_Line__c> interCompanyInvoiceLines = new List<Sales_Invoice_Line__c>();
       
        for(Sales_Invoice_Line__c salesInvoiceLine:theSILList){
            
            if((salesInvoiceLine.Category__c == 'Labor' || salesInvoiceLine.Category__c == 'Equipment')
                    && salesInvoiceLine.Service_Center__c != theSI.Service_Center__c
                    && salesInvoiceLine.Service_Center__c != null
                    && salesInvoiceLine.Service_Center__r.Temporary__c == false
                    && salesInvoiceLine.Resource__r.Exclude_from_I_C_Cost_Calculation__c != true
                    && salesInvoiceLine.Scheduled_Date__c >= Date.newInstance(2019,1,1)
                    && CompanyMgmt.zeroIfNull(salesInvoiceLine.Quantity__c) != 0
                    && String.isNotBlank(salesInvoiceLine.Resource_Type__c)){

                resTypeIdSet.add(salesInvoiceLine.Resource_Type__c);

                if(oldInvoiceBypassInterCoCostCheck != true) {
                    if (CompanyMgmt.zeroIfNull(salesInvoiceLine.Cost_Qty__c) <= 0) {
                        salesInvoiceLine.Cost_Qty__c = salesInvoiceLine.Quantity__c;
                    }
                }

                interCompanyInvoiceLines.add(salesInvoiceLine);
                if(!serviceCenterCodeMap.containsKey(salesInvoiceLine.Service_Center__c)) {
                    serviceCenterCodeMap.put(salesInvoiceLine.Service_Center__c, salesInvoiceLine.Service_Center__r.Name);
                }
            }
       
        }

        List<Resource_Type__c> resourceTypes = new ResourceTypesSelector(false).selectById(resTypeIdSet);
        Map<Id, Resource_Type__c> resTypeMap = new Map<Id, Resource_Type__c>(resourceTypes);
        Map<String,Decimal> dueToAmountMap = new Map<String, Decimal>();
        for(Sales_Invoice_Line__c interCompanyInvLine:interCompanyInvoiceLines){
            //Decimal interCompanyResTypeCost = CompanyMgmt.zeroIfNull(resTypeMap.get(interCompanyInvLine.Resource_Type__c).Inter_co_Cost__c);
            Decimal interCompanyResCost = CompanyMgmt.zeroIfNull(interCompanyInvLine.Line_Cost__c);

            if(oldInvoiceBypassInterCoCostCheck != true) {
                if (interCompanyResCost == 0) {
                    throw new DataException('Inter-co Cost is zero for line: ' + interCompanyInvLine.Line_No__c);
                }

                if (CompanyMgmt.zeroIfNull(interCompanyInvLine.Cost_Qty__c) <= 0) {
                    throw new DataException('Inter-co Cost Qty. must be greater than 0 for line: ' + interCompanyInvLine.Line_No__c);
                }
            }

            String dueToMapKey = interCompanyInvLine.Service_Center__c + ':' + interCompanyInvLine.Category__c;
            //Decimal dueToAmount = interCompanyInvLine.Quantity__c * CompanyMgmt.zeroIfNull(resTypeMap.get(interCompanyInvLine.Resource_Type__c).Inter_co_Cost__c);
            Decimal dueToAmount = interCompanyResCost;
            if(dueToAmountMap.containsKey(dueToMapKey)) {
                dueToAmountMap.put(dueToMapKey, dueToAmountMap.get(dueToMapKey) + dueToAmount);
            } else {
                dueToAmountMap.put(dueToMapKey, dueToAmount);
            }
        }

        for(String dueToMapKey:dueToAmountMap.keySet()){
            String scId = dueToMapKey.split(':')[0];
            String category = dueToMapKey.split(':')[1];
            Id dueToGLAccountId = null;
            Id dueFromGLAccountId = null;
            Decimal dueAmt = dueToAmountMap.get(dueToMapKey);
            switch on category {
                when 'Labor'{
                    dueToGLAccountId = theCompanySetup.Labor_Inter_co_Due_to_Account__c;
                    dueFromGLAccountId = theCompanySetup.Labor_Inter_co_Due_from_Account__c;
                }
                when 'Equipment'{
                    dueToGLAccountId = theCompanySetup.Equipment_Inter_co_Due_to_Account__c;
                    dueFromGLAccountId = theCompanySetup.Equipment_Inter_co_Due_from_Account__c;
                }
                when else{
                    throw new DataException('Inter-co Posting for category ' + category + ' is not implement yet!');
                }
            }

            //due-to entry - debit
            theGL = new GL_Entry__c();
            theGL.Amount__c = dueAmt;
            if(theSI.Credit_Memo__c == true && theGL.Amount__c > 0) theGL.Amount__c = theGL.Amount__c * -1;
            theGL.GL_Account__c = dueToGLAccountId;
            theGL.Service_Center__c = theSI.Service_Center__c;
            theGL.Subsidiary_Company__c = theSI.Subsidiary_Company__c;
            List<String> descInfo = new String[]{serviceCenterCodeMap.get(scId), category};
            //theGL.Description__c = String.format('Due to SC{0} for Inter-co {1}', new List<String>{serviceCenterCodeMap.get(scId), category});
            theGL.Description__c = String.format('Due to SC{0} for Inter-co {1}', descInfo);
            theGL = updateGL(theGL, theSI, false);
            theGL.Posting_Type__c = 'Sales';
            theGLList.add(theGL);

            //due-from entry - credit
            theGL = new GL_Entry__c();
            theGL.Amount__c = dueAmt * -1;
            if(theSI.Credit_Memo__c == true && theGL.Amount__c < 0) theGL.Amount__c = theGL.Amount__c * -1;
            theGL.GL_Account__c = dueFromGLAccountId;
            theGL.Service_Center__c = scId;
            theGL.Subsidiary_Company__c = theSI.Subsidiary_Company__c;
            theGL.Description__c = String.format('Due from SC{0} for Inter-co {1}', new List<String>{serviceCenterCodeMap.get(theSI.Service_Center__c), category});
            theGL = updateGL(theGL, theSI, false);
            theGL.Posting_Type__c = 'Sales';
            theGLList.add(theGL);
        }

        Set<Id> glaIdSet = new Set<Id>();
        for(GL_Entry__c gl:theGLList){
            if(String.isBlank(gl.Description__c) == true){
                glaIdSet.add(gl.GL_Account__c);
            }
        }

        Map<Id, GL_Account__c> glAccountMap = new Map<Id, GL_Account__c>([SELECT Id, Description__c FROM GL_Account__c WHERE Id IN :glaIdSet]);

        if(glAccountMap.size() > 0){
            for(GL_Entry__c gl:theGLList){
                if(String.isBlank(gl.Description__c) == true && !Test.isRunningTest()) {
                    if (!glAccountMap.containsKey(gl.GL_Account__c) ) {
                        throw new DataException('G/L account ' + gl.GL_Account__c + ' is not found');
                    }
                    gl.Description__c = glAccountMap.get(gl.GL_Account__c).Description__c;
                }
            }
        }


        if (CompanyMgmt.CheckGLConsistency(theGLList) != 0) {
            throw new myException('Total amount from new GL entries is ' + CompanyMgmt.CheckGLConsistency(theGLList) + '. It must be 0.');
        }

        theGLList = CompanyMgmt.getBatchId(theGLList, theSI.Subsidiary_Company__c);

        if (!Test.isRunningTest()) {
            insert theGLList;
        }
    }

    public static List <String> unpostCheck(Sales_Invoice__c theSI) {
        List<String> errorList = new List<String>();
        List<GL_Entry__c> theGLList = new List<GL_Entry__c>();

        List<Sales_Invoice_Line__c> theSILList = [
                SELECT Line_No__c, Quantity__c
                FROM Sales_Invoice_Line__c
                WHERE Sales_Invoice__c = :theSI.Id AND Quantity__c <> 0
        ];

        // Check posting date
        if (!CompanyMgmt.checkPostingDate(theSI.Posting_Date__c)) {
            errorList.add(theSI.Posting_Date__c.format() + ' is not within your range of allowed posting dates.');
        }
        //if (!CompanyMgmt.checkPostingDate2(theSI.Posting_Date__c)) {
        //    errorList.add(theSI.Posting_Date__c.format() + ' is in a closed accounting period.');
        //}

        if (theSI.Document_Status__c == 'Open') {
            errorList.add('Sales Invoice is not posted yet.');
            //return errorList;
        } else {
            if (theSILList.size() == 0) {
                errorList.add('There is nothing to unpost.');
                //return errorList;
            }
        }

        theGLList = [SELECT GL_Batch__r.Name, GL_Batch__r.Sync_d__c FROM GL_Entry__c WHERE Sales_Invoice__c = :theSI.Id];

        for (GL_Entry__c GL : theGLList) {
            if (GL.GL_Batch__r.Sync_d__c == true) {
                errorList.add('GL Batch ' + GL.GL_Batch__r.Name + ' is sent to Dynamics NAV already. You cannot unpost.');
            }
        }

        if(theSI.Credit_Memo__c != true){
            List<Retainage_Ledger_Entry__c> retainageLedgerEntries = [SELECT Id FROM Retainage_Ledger_Entry__c WHERE Sales_Invoice__c = :theSI.Id AND Invoiced__c = TRUE];
            if(retainageLedgerEntries.size() > 0){
                errorList.add('Invoice for the Retainage is already created!');
            }
        } else {
            if(theSI.Reversed_from_SI__r.Retainage_Invoice__c == true){
                List<Retainage_Ledger_Entry__c> retainageLedgerEntries = [SELECT Id, Closed_By_Invoice_No__r.Name, Closed_By_Invoice_No__c FROM Retainage_Ledger_Entry__c WHERE Closed_By_Invoice_Reversed_By__c = :theSI.Id LIMIT 1];
                if(retainageLedgerEntries.size() > 0){
                    if(String.isNotBlank(retainageLedgerEntries[0].Closed_By_Invoice_No__c)){
                        errorList.add('You Cannot un-post credit memo#' + theSI.Name + ' because retainace invoice is already created! Retainage invoice# ' + retainageLedgerEntries[0].Closed_By_Invoice_No__r.Name);
                    }
                }
            }
        }

        return errorList;
    }

    public static void unpostSI(Sales_Invoice__c theSI) {
        Id SIId = theSI.Id;
        CompanyMgmt.systemCall = true;
        List<GL_Entry__c> theOldGLList = new List<GL_Entry__c>();

        /*
        Map<String, Schema.SObjectField> fields2 = Schema.SObjectType.GL_Entry__c.fields.getMap();
        List<String> lstFields2 = new List<String>();
        for (Schema.SObjectField field : fields2.values()) {
            lstFields2.add(field.getDescribe().getName());
        }
        String strQuery2 = 'SELECT ' + String.join(lstFields2, ',');
        strQuery2 += ',GL_Batch__r.Name FROM GL_Entry__c WHERE Sales_Invoice__c = :SIId';
        theOldGLList = Database.query(strQuery2);
         */

        theOldGLList = [SELECT Id, GL_Batch__r.Name FROM GL_Entry__c WHERE Sales_Invoice__c = :SIId];
        delete theOldGLList;

        List<Retainage_Ledger_Entry__c> retainageLedgerEntries = new List<Retainage_Ledger_Entry__c>();
        if(theSI.Credit_Memo__c != true){
            if(theSI.Retainage_Invoice__c == true){
                retainageLedgerEntries = [SELECT Id, Invoiced__c, Closed_By_Invoice_No__c FROM Retainage_Ledger_Entry__c WHERE Closed_By_Invoice_No__c = :theSI.Id LIMIT 1];
                retainageLedgerEntries[0].Closed_By_Invoice_No__c = null;
                retainageLedgerEntries[0].Invoiced__c = false;
                update retainageLedgerEntries;
            } else if(CompanyMgmt.zeroIfNull(theSI.Retainage_Amount__c) > 0) {
                retainageLedgerEntries = [SELECT Id, Invoiced__c, Closed_By_Invoice_No__r.Name FROM Retainage_Ledger_Entry__c WHERE Sales_Invoice__c = :theSI.Id LIMIT 1];
                if(retainageLedgerEntries.size() > 0 && retainageLedgerEntries[0].Invoiced__c != true){
                    delete retainageLedgerEntries;
                } else {
                    throw new DataException('You cannot un-post invoice# ' +
                            theSI.Name + ' because it is linked to retainage invoice# ' +
                            retainageLedgerEntries[0].Closed_By_Invoice_No__r.Name);
                }
            }
        } else {
            if(theSI.Reversed_from_SI__r.Retainage_Invoice__c == true){
                retainageLedgerEntries = [SELECT Id, Closed_By_Invoice_No__c, Invoiced__c, Closed_By_Invoice_Reversed_By__c
                FROM Retainage_Ledger_Entry__c WHERE Closed_By_Invoice_Reversed_By__c = :theSI.Id LIMIT 1];
                if(retainageLedgerEntries.size() > 0){
                    retainageLedgerEntries[0].Closed_By_Invoice_No__c = theSI.Reversed_from_SI__c;
                    retainageLedgerEntries[0].Invoiced__c = true;
                    retainageLedgerEntries[0].Closed_By_Invoice_Reversed_By__c = null;
                    update retainageLedgerEntries;
                } else {
                    throw new DataException('You cannot un-post credit memo# ' + theSI.Name + ' because retainage entry is already reversed');
                }
            }
            if(CompanyMgmt.zeroIfNull(theSI.Retainage_Amount__c) > 0){
                throw new DataException('You cannot un-post credit memo#' + theSI.Name + ' because it related to retainage invoice.');
            }
        }
    }


    public static GL_Entry__c updateGL(GL_Entry__c theGL, Sales_Invoice__c theSI, Boolean AR) {
        theGL.Document_No__c = theSI.Name;
        theGL.Sales_Invoice__c = theSI.Id;
        theGL.Posting_Date__c = theSI.Posting_Date__c;
        theGL.Transaction_Source__c = 'Sales Invoice';
        theGL.Account_Type__c = 'GL Account';
        if (!theSI.Credit_Memo__c) {
            theGL.Document_Type__c = 'Invoice';
        } else {
            theGL.Document_Type__c = 'Cr. Memo';
        }
        if (AR) {
            theGL.Document_Date__c = theSI.Invoice_Date__c;
            theGL.Account_Type__c = 'Customer';
            //theGL.Description = theSI.Sell_to_Customer__r.Name;
            theGL.Payment_Term__c = theSI.Payment_Term__c;
        }

        return theGL;
    }

    public static Sales_Invoice_Line__c updateSIL(Sales_Invoice__c theSI, Sales_Invoice_Line__c theSIL, String sourceField) {
        if (sourceField == 'theJobPosition') {
            theSIL = setResourceType(theSIL, theSI);
            theSIL.Quantity__c = 0;
        } else if (sourceField == 'theResource' || sourceField == 'theLResource' || sourceField == 'theEResource' || sourceField == 'theMResource' ||
                sourceField == 'theFResource' || sourceField == 'theSResource' || sourceField == 'theWResource') {
            Resource__c theResource;
            if (!mapResource.containsKey(theSIL.Resource__c)) {
                theResource = CompanyMgmt.getResource(theSIL.Resource__c);
                mapResource.put(theSIL.Resource__c, theResource);
            }

            theResource = mapResource.get(theSIL.Resource__c);
            theSIL.Resource__r = new Resource__c(Id = theResource.Id, Name = theResource.Name);
            theSIL.Resource__r.Name = theResource.Name;
            if (theSIL.Category__c != 'Labor' && theSIL.Category__c != 'Equipment') {
                theSIL.Description__c = theResource.Description__c;
            }
            theSIL.Quantity__c = 0;
            if (sourceField == 'theLResource') {
                theSIL.Resource_Type__r = new Resource_Type__c(Id = theResource.Resource_Type__c, Name = theResource.Resource_Type__r.Name);
                theSIL.Resource_Type__c = theResource.Resource_Type__c;
                theSIL = setResourceType(theSIL, theSI);
            } else if (sourceField == 'theEResource') {
                theSIL.Resource_Type__r = new Resource_Type__c(Id = theResource.Resource_Type__c, Name = theResource.Resource_Type__r.Name);
                theSIL.Resource_Type__c = theResource.Resource_Type__c;
                theSIL = setResourceType(theSIL, theSI);
            } else {
                theSIL.Description__c = theResource.Description__c;
                theSIL.Unit_Cost__c = theResource.Unit_Cost__c;
            }
        } else if (sourceField == 'theEquipment' || sourceField == 'theLumpSumResourceType' || sourceField == 'theResourceType') {
            theSIL = setResourceType(theSIL, theSI);
            theSIL.Quantity__c = 0;
        }
        if (sourceField == 'theUOM' && !Test.isRunningTest()) {
            Unit_of_Measure__c theUOM = [SELECT Id, Name FROM Unit_of_Measure__c WHERE Id = :theSIL.Unit_of_Measure__c LIMIT 1];
            theSIL.Unit_of_Measure__r = new Unit_of_Measure__c(Id = theUOM.Id, Name = theUOM.Name);
            theSIL.Unit_of_Measure__c = theUOM.Id;
        }
        if (sourceField == 'theTaxGroup') {
            if (theSI.Tax_Liable__c && theSIL.Tax_Group__c != null) {
                theSIL.Tax_Pct__c = CompanyMgmt.getSalesTax(theSI.Tax_Area__c, theSIL.Tax_Group__c);
            }
            else {
                theSIL.Tax_Pct__c = 0;
            }
        }
        if (sourceField == 'theLQuantity') {
            system.debug('***Quantity' + theSIL.Quantity__c);
            theSIL.Line_Cost__c = companyMgmt.zeroIfNull(theSIL.Unit_Cost__c) * companyMgmt.zeroIfNull(theSIL.Quantity__c);
        }
        if (sourceField == 'theQuantity') {
            theSIL.Line_Cost__c = companyMgmt.zeroIfNull(theSIL.Unit_Cost__c) * companyMgmt.zeroIfNull(theSIL.Quantity__c);
        }
        if (sourceField == 'theLBillasLumpSum' || sourceField == 'theLNonBillable'||
                sourceField == 'theEBillasLumpSum' || sourceField == 'theENonBillable' ||
                sourceField == 'theMBillasLumpSum' || sourceField == 'theMNonBillable' ||
                sourceField == 'theSBillasLumpSum' || sourceField == 'theSNonBillable' ||
                sourceField == 'theWBillasLumpSum' || sourceField == 'theWNonBillable' ||
                sourceField == 'theDBillasLumpSum' || sourceField == 'theDNonBillable' ||
                sourceField == 'theMiscBillasLumpSum' || sourceField == 'theMiscNonBillable' || sourceField == 'theLumpNonBillable'){ // 14250
            System.debug('theSIL.Bill_as_Lump_Sum__c***' + theSIL.Bill_as_Lump_Sum__c);
            System.debug('theSIL.Non_Billable__c***' + theSIL.Non_Billable__c);
            if (theSIL.Bill_as_Lump_Sum__c == true || theSIL.Non_Billable__c == true){
                theSIL.xUnit_Price__c = theSIL.Unit_Price__c;
                theSIL.Unit_Price__c = 0;
            }
            else{
                theSIL.Unit_Price__c = theSIL.xUnit_Price__c; // 14250
            }
        }

        if (theSI.Tax_Liable__c && theSIL.Tax_Group__c != null) {
            theSIL.Tax_Pct__c = CompanyMgmt.getSalesTax(theSI.Tax_Area__c, theSIL.Tax_Group__c);
        }
        else {
            theSIL.Tax_Pct__c = 0;
        }

        if(theSIL.Category__c == 'Subcontractors'){
            if(theSIL.Bill_as_Lump_Sum__c == true || theSIL.Non_Billable__c == true){
                theSIL.Unit_Cost__c = theSIL.xUnit_Price__c;
            } else {
                theSIL.Unit_Cost__c = theSIl.Unit_Price__c;
            }
        }

        if(theSIL.Category__c == 'Labor' || theSIL.Resource_Type__r.Fleet_No_Required__c == true){
            theSIL.Line_Cost__c = CompanyMgmt.zeroIfNull(theSIL.Unit_Cost__c) * CompanyMgmt.zeroIfNull(theSIL.Cost_Qty__c);
        } else {
            theSIL.Line_Cost__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(theSIL.Unit_Cost__c) * CompanyMgmt.zeroIfNull(theSIL.Quantity__c));
        }

        theSIL.Line_Amount__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(theSIL.Unit_Price__c) * CompanyMgmt.zeroIfNull(theSIL.Quantity__c));
        theSIL.Tax__c = CompanyMgmt.halfUpTo2D(theSIL.Line_Amount__c * CompanyMgmt.zeroIfNull(theSIL.Tax_Pct__c) / 100);
        theSIL.Line_Amt_Incl_Tax__c = theSIL.Line_Amount__c + theSIL.Tax__c;

        return theSIL;
    }

    public static Sales_Invoice_Line__c setResourceType(Sales_Invoice_Line__c theSIL, Sales_Invoice__c theSI) {
        Resource_Type__c theResourceType;
        if(!String.isEmpty(theSIL.Resource_Type__c)) {
            if (!mapResourceType.containsKey(theSIL.Resource_Type__c)) {
                theResourceType = CompanyMgmt.getResourceType(theSIL.Resource_Type__c);
                mapResourceType.put(theSIL.Resource_Type__c, theResourceType);
            }
            theResourceType = mapResourceType.get(theSIL.Resource_Type__c);
            theSIL.Resource_Type__r = theResourceType;
            /*
            theSIL.Resource_Type__r = new Resource_Type__c(Id = theResourceType.Id, Name = theResourceType.Name);
            theSIL.Resource_Type__r.Name = theResourceType.Name;
             */
            theSIL.Description__c = theResourceType.Description__c;
            theSIL.Unit_of_Measure__c = theResourceType.Unit_of_Measure__c;
            theSIL.Unit_of_Measure__r = new Unit_of_Measure__c(Id = theResourceType.Unit_of_Measure__c, Name = theResourceType.Unit_of_Measure__r.Name);
            theSIL.Unit_Cost__c = theResourceType.Unit_Cost__c;
        }

        return theSIL;
    }

    public static Sales_Invoice__c validateBillToCustomer(Sales_Invoice__c theSI) {
        Account theBTCust;
        if (!mapAccount.containsKey(theSI.Bill_to_Customer__c)) {
            theBTCust = [
                    SELECT Id, Name, Billing_Contact__c, Billing_Contact__r.FirstName, Billing_Contact__r.LastName, BillingStreet, BillingCity,
                            BillingStateCode, BillingPostalCode, BillingCountryCode,
                            ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode,
                            ShippingCountry,Pricing_Group__c,
                            Payment_Term__c, Payment_Term__r.Name,Salesperson__c,Salesperson__r.Name,
                            Tax_Liable__c, Tax_Area__c, Tax_Area__r.Name
                    FROM Account
                    WHERE Id = :theSI.Bill_to_Customer__c
                    LIMIT 1
            ];
            mapAccount.put(theSI.Bill_to_Customer__c, theBTCust);
        }

        theBTCust = mapAccount.get(theSI.Bill_to_Customer__c);
        theSI.Bill_to_Customer__r = new Account(Id = theBTCust.Id, Name = theBTCust.Name);
        theSI.Contact__c = theBTCust.Billing_Contact__c;
        theSI.Street__c = theBTCust.BillingStreet;
        theSI.City__c = theBTCust.BillingCity;
        theSI.State__c = theBTCust.BillingStateCode;
        theSI.Postal_Code__c = theBTCust.BillingPostalCode;
        theSI.Country__c = theBTCust.BillingCountryCode;
        theSI.Tax_Liable__c = theBTCust.Tax_Liable__c;
        theSI.Tax_Area__c = theBTCust.Tax_Area__c;
        theSI.Payment_Term__c = theBTCust.Payment_Term__c;
        theSI = validatePaymentTerm(theSI);
        Contact billingContact = new Contact(Id = theBTCust.Billing_Contact__c, FirstName = theBTCust.Billing_Contact__r.FirstName, LastName = theBTCust.Billing_Contact__r.LastName);
        theSI.Contact__r = billingContact;
        theSI.Tax_Area__r = new Tax_Area__c(Id = theBTCust.Tax_Area__c, Name = theBTCust.Tax_Area__r.Name);
        theSI.Document_Status__c = 'Open';
        theSI.Sales_Invoice_Status__c = 'Open';
        theSI.Salesperson__c = theBTCust.Salesperson__c;
        theSI.Salesperson__r = new Salesperson__c(Id = theBTCust.Salesperson__c, Name = theBTCust.Salesperson__r.Name);
        return theSI;
    }

    public static Sales_Invoice__c validateTaxArea(Sales_Invoice__c theSI) {
        if (String.isEmpty(theSI.Tax_Area__c)) {
            return theSI;
        } else {
            Tax_Area__c TaxArea = [SELECT Id, Name FROM Tax_Area__c WHERE Id = :theSI.Tax_Area__c LIMIT 1];
            theSI.Tax_Area__r = new Tax_Area__c(Id = TaxArea.Id, Name = TaxArea.Name);
        }
        return theSI;
    }

    public static Sales_Invoice__c validatePaymentTerm(Sales_Invoice__c theSI) {
        List<Payment_Term__c> paymentTerm = [
                SELECT Id, Name, Discount_Pct__c, Discount_Date_Calculation__c, Due_Date_Calculation__c
                FROM Payment_Term__c
                WHERE Id = :theSI.Payment_Term__c
        ];
        if (!paymentTerm.isEmpty()) {
            theSI.Due_Date__c = CompanyMgmt.calcDate(theSI.Invoice_Date__c, paymentTerm[0].Due_Date_Calculation__c);
            //theSI.Payment_term__r = new Payment_Term__c(Id = paymentTerm[0].Id, Name = paymentTerm[0].Name);
        }
        return theSI;
    }

    ///////////////////////New Validation Function////////////////////////
    public static Sales_Invoice__c validateContact(Sales_Invoice__c theSI) {
        System.debug('Method Contact Validation Called===>');
        /*if (String.isEmpty(theSI.Billing_Contact__c)) {
            return theSI;
        } else {
            Contact Con = [SELECT Id, Name FROM Contact WHERE Id = :theSI.Billing_Contact__c LIMIT 1];
            theSI.Billing_Contact__c = Con.Id;
        }*/
        return theSI;
    }

    public static Sales_Invoice__c nullRelationshipFields(Sales_Invoice__c theSI) {
        theSI.Contact__r = null;
        theSI.Salesperson__r = null;
        theSI.Bill_to_Customer__r = null;
        theSI.Tax_Area__r = null;
        return theSI;
    }
    
   
}
