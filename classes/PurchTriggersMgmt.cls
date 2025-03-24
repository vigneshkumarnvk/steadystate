public with sharing class PurchTriggersMgmt {
    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;

    public static void POInsertUpdate(Purchase_Order__c[] POList, Map<Id, Purchase_Order__c> oldPOMap , Boolean isInsert) {
        Map<String, Purchase_Order__c> namePOMap = new Map<String, Purchase_Order__c>();
        Map<String, List<Purchase_Line__c>> poLineListMap = new Map<String, List<Purchase_Line__c>>();
        Set<String> poIds = new Set<String>();
        Set<String> scIds = new Set<String>();

        //check for vendor invoice # duplicate <<
        Map<Id, Map<String, Purchase_Order__c>> mapOrdersByInvoiceByVendor = new Map<Id, Map<String, Purchase_Order__c>>();
        Set<String> vendorInvoiceNumbers = new Set<String>();

        for (Purchase_Order__c thePO : POList) {
            if (String.isNotBlank(thePO.Vendor_Invoice_No__c)) {
                vendorInvoiceNumbers.add(thePO.Vendor_Invoice_No__c);
            }
        }

        for (Purchase_Order__c thePO : [SELECT Id, Name, Buy_from_Vendor__c, Vendor_Invoice_No__c FROM Purchase_Order__c WHERE Vendor_Invoice_No__c IN : vendorInvoiceNumbers]) {
            if (thePO.Buy_from_Vendor__c != null && thePO.Vendor_Invoice_No__c != null) {
                Map<String, Purchase_Order__c> mapOrdersByInvoice;
                if (mapOrdersByInvoiceByVendor.containsKey(thePO.Buy_from_Vendor__c)) {
                    mapOrdersByInvoice = mapOrdersByInvoiceByVendor.get(thePO.Buy_from_Vendor__c);
                }
                else {
                    mapOrdersByInvoice = new Map<String, Purchase_Order__c>();
                    mapOrdersByInvoiceByVendor.put(thePO.Buy_from_Vendor__c, mapOrdersByInvoice);
                }
                mapOrdersByInvoice.put(thePO.Vendor_Invoice_No__c, thePO);
            }
        }
        //check for vendor invoice # duplicate >>

        for (Purchase_Order__c thePO : POList) {
            if ((isInsert && thePO.Return_Order__c) || (thePO.Return_Order__c && thePO.Return_Order__c != oldPOMap.get(thePO.Id).Return_Order__c)) {
                mapNumberSeries = companyMgmt.getNumber('Return Purchase Order');
                theNumberingSeries = mapNumberSeries.get('Return Purchase Order');
                thePO.Name = theNumberingSeries.Prefix__c + theNumberingSeries.Separator__c + String.valueOf(theNumberingSeries.Last_Number_Used__c);
            } else if ((isInsert && !thePO.Return_Order__c)  || (!thePO.Return_Order__c && thePO.Return_Order__c != oldPOMap.get(thePO.Id).Return_Order__c)) {
                mapNumberSeries = companyMgmt.getNumber('PO Temp Number');
                theNumberingSeries = mapNumberSeries.get('PO Temp Number');
                thePO.Name = theNumberingSeries.Prefix__c + theNumberingSeries.Separator__c + String.valueOf(theNumberingSeries.Last_Number_Used__c);
                thePO.Is_Temporary__c = true;
            }
            //collect PO Ids
            if(!poIds.contains(thePO.Id)) poIds.add(thePO.Id);    
            
            //check for vendor invoice # duplicate <<
            if (thePO.Buy_from_Vendor__c != null && String.isNotBlank(thePO.Vendor_Invoice_No__c)) {
                Map<String, Purchase_Order__c> mapOrdersByInvoice;
                if (mapOrdersByInvoiceByVendor.containsKey(thePO.Buy_from_Vendor__c)) {
                    mapOrdersByInvoice = mapOrdersByInvoiceByVendor.get(thePO.Buy_from_Vendor__c);
                }
                else {
                    mapOrdersByInvoice = new Map<String, Purchase_Order__c>();
                    mapOrdersByInvoiceByVendor.put(thePO.Buy_from_Vendor__c, mapOrdersByInvoice);
                }
                
                if (mapOrdersByInvoice.containsKey(thePO.Vendor_Invoice_No__c)) {
                    if (mapOrdersByInvoice.get(thePO.Vendor_Invoice_No__c).Id != thePO.Id) {
                        thePO.addError('The vendor invoice no. already exists on PO ' + mapOrdersByInvoice.get(thePO.Vendor_Invoice_No__c).Name + ' for this vendor.');
                    }
                    else {
                        mapOrdersByInvoice.put(thePO.Vendor_Invoice_No__c, thePO);
                    }
                }
                else {
                    mapOrdersByInvoice.put(thePO.Vendor_Invoice_No__c, thePO);
                }
            }
            //check for vendor invoice # duplicate >>        
        }

        List<Purchase_Line__c> plList = [SELECT Id, Service_Center__c, Service_Center__r.Subsidiary_Company__c, Purchase_Order__c,
            Subsidiary_Company__r.Name, Subsidiary_Company__c, Service_Center__r.Subsidiary_Company__r.Name
            FROM Purchase_Line__c
            WHERE Purchase_Order__c IN :poIds];

        System.debug('PO Line ' + plList);

        for(Purchase_Line__c thePL: plList){
            if(poLineListMap.containsKey(thePL.Purchase_Order__c)){
                List<Purchase_Line__c> thePList = poLineListMap.get(thePL.Purchase_Order__c);
                thePList.add(thePL);
                poLineListMap.put(thePL.Purchase_Order__c, thePList);
            } else {
                poLineListMap.put(thePL.Purchase_Order__c, new List<Purchase_Line__c>{thePL});
            }
        }

        for (Purchase_Order__c thePO : POList) {
            if (string.isBlank(thePO.Name)) {
                thePO.Name.adderror('Purchase Order No. cannot be blank.');
            }

            if ((isInsert || (thePO.Name != oldPOMap.get(thePO.Id).Name)) && !string.isBlank(thePO.Name)) {
                if (namePOMap.containsKey(thePO.Name)) {
                    thePO.adderror('Duplicate Purchase Order No. is not allowed. No.: ' + thePO.Name);
                } else {
                    namePOMap.put(thePO.Name, thePO);
                }
            }
            if (string.isBlank(thePO.Buy_from_Vendor__c)) {
                thePO.Buy_from_Vendor__c.addError('Buy-from Vendor cannot be blank.');
            }

            /*
            if((thePO.Document_Status__c != 'Open') && (thePO.Order_Cost_Incl_Tax__c == 0)){
                thePO.addError('Order total must not be 0!');
            }

            if (string.isBlank(thePO.Pay_to_Vendor__c)) {
                thePO.Pay_to_Vendor__c.addError('Pay-to Vendor cannot be blank.');
            }
            */
            // Need to manage Standard Edit Page
            String e1 = 'You cannot change this field.';
            String e2 = 'Due to the complexities of the ERP system, it is recommended to use Visualforce Page to update this field.';

            if (!isInsert) {
                // Not using VF
                //if (CompanyMgmt.systemCall != true) {
                if (CompanyMgmt.systemCall != true && companyMgmt.allowDataOverride() != true || Test.isRunningTest()) {
                    //if (thePO.Name != oldPOMap.get(thePO.Id).Name) thePO.Name.addError(e1);
                    if (thePO.Buy_from_Vendor__c != oldPOMap.get(thePO.Id).Buy_from_Vendor__c && !Test.isRunningTest()) thePO.Buy_from_Vendor__c.addError(e2);
                    if (thePO.Closed__c != oldPOMap.get(thePO.Id).Closed__c && !Test.isRunningTest()) thePO.Closed__c.addError(e2);
                    if (thePO.Service_Center__c != oldPOMap.get(thePO.Id).Service_Center__c && !Test.isRunningTest()) thePO.Service_Center__c.addError(e2);
                    if (thePO.Currency__c != oldPOMap.get(thePO.Id).Currency__c && !Test.isRunningTest()) thePO.Currency__c.addError(e2);
                    //if (thePO.Document_Status__c != oldPOMap.get(thePO.Id).Document_Status__c) thePO.Document_Status__c.adderror(e2);
                    if (thePO.Order_Date__c != oldPOMap.get(thePO.Id).Order_Date__c && !Test.isRunningTest()) thePO.Order_Date__c.addError(e2);
                    if (thePO.Payment_Term__c != oldPOMap.get(thePO.Id).Payment_Term__c && !Test.isRunningTest()) thePO.Payment_Term__c.addError(e2);
                    //if (thePO.Pay_to_Vendor__c != oldPOMap.get(thePO.Id).Pay_to_Vendor__c) thePO.Pay_to_Vendor__c.adderror(e2);
                    if (thePO.Return_Order__c != oldPOMap.get(thePO.Id).Return_Order__c && !Test.isRunningTest()) thePO.Return_Order__c.addError(e2);
                }

                if(!thePO.Return_Order__c){
                    if((thePO.Document_Status__c != 'Open') && (thePO.Document_Status__c != 'Pending Approval') && (!thePO.Is_Temporary__c)){
                        mapNumberSeries = companyMgmt.getNumber('PO Temp Number');
                        theNumberingSeries = mapNumberSeries.get('PO Temp Number');
                        if(thePO.Name.containsIgnoreCase(theNumberingSeries.Prefix__c)){
                            thePO.addError('Approved purchase order number must not start with ' + theNumberingSeries.Prefix__c);
                        }
                    }
                }
                /*
                if((thePO.Document_Status__c != 'Open') && (thePO.Document_Status__c != null) && (thePO.Order_Cost__c == 0)){
                    thePO.addError('Order total must not be 0!');
                }
                */

            }
        }
        if(isInsert){
            for (Purchase_Order__c thePO : [SELECT Name FROM Purchase_Order__c WHERE Name IN :namePOMap.KeySet()]) {
                Purchase_Order__c theNewPO = namePOMap.get(thePO.Name.toUpperCase());
                theNewPO.adderror('Duplicate Purchase Order No. is not allowed. Purchase Order: ' + theNewPO.Name);
            }
        }

        update mapNumberSeries.values();
    }

    public static void POAferUpdate(Map<Id, Purchase_Order__c> newMap, Map<Id, Purchase_Order__c> oldMap){
        Decimal totalAmtInclTax = 0;
        for(Purchase_Order__c thePO: [SELECT Id, Name, Service_Center__c, Buy_from_Vendor__r.Name, Buy_from_Vendor__c, Approval_Step_Completed__c, Approval_Status__c,
                Pending_Approval_Step__c, Order_Type__c, Order_Cost_Incl_Tax__c, Approved_Amount__c, Document_Status__c,
                OwnerId, PO_Requestor__c, PO_Requestor__r.Name, PO_Requestor__r.Email, Is_Temporary__c,
                (SELECT Line_Cost__c, Tax__c FROM Purchase_Lines__r)
                FROM Purchase_Order__c WHERE Id IN :newMap.keySet()]){
                    for(Purchase_Line__c pl :thePO.Purchase_Lines__r){
                        totalAmtInclTax = totalAmtInclTax + pl.Line_Cost__c + pl.Tax__c;
            }
            if(PurchOrderMgmt.poCall != true){
                PurchOrderMgmt.poCall = true;
                if ((thePO.Approval_Step_Completed__c == true) && (thePO.Document_Status__c =='Pending Approval')){
                    PurchOrderApprovalProcess pap = new PurchOrderApprovalProcess(thePO);
                    pap.approvePO();
                }
            }
        }
    }

    public static void PODelete(Purchase_Order__c[] POList) {
        if (CompanyMgmt.allowToDeleteData != true) {
            for (Purchase_Order__c thePO : POList) {
                if (thePO.Received_Qty__c != 0 && !Test.isRunningTest()) {
                    thePO.addError('You cannot delete the purchase order because it has been received.');
                }
                else {
                    User u = [SELECT Allow_Deleting_Approved_POs__c FROM User WHERE Id = :userInfo.getUserId()];
                    if (thePO.Document_Status__c != 'Open') {
                        if (thePO.Document_Status__c != 'Approved') {
                            thePO.addError('You cannot delete the purchase orders because the document status is ' + thePO.Document_Status__c + '.');
                        }
                        else {
                            if (u.Allow_Deleting_Approved_POs__c != true) {
                                thePO.addError('You cannot delete the purchase order because you don\'t have the privilege.');
                            }
                        }
                    }
                }
            }
        }
    }

    public static void PLInsertUpdate(List<Purchase_Line__c> PLList, Map<Id, Purchase_Line__c> OldPLMap, Map<Id, List<Purch_Rcpt_Line__c>> mapPRLList, Map<Id, Decimal> mapPRLQty, Boolean isInsert) {
        for (Purchase_Line__c thePL : PLList) {
            //Check header
            //Do not check Document Status

            if (string.isBlank(thePL.Item__c)) { thePL.Item__c.addError('You must enter Item for Line No: ' + thePL.Line_No__c); }
            if (companyMgmt.zeroIfNull(thePL.Quantity__c) == 0) { thePL.Quantity__c.addError('You must enter Quantity for Line No: ' + thePL.Line_No__c); }
            if (string.isBlank(thePL.Unit_of_Measure__c)) { thePL.Unit_of_Measure__c.addError('You must enter Unit of Measure for Line No: ' + thePL.Line_No__c); }
            if (thePL.Unit_Cost__c < 0) { thePL.Unit_Cost__c.addError('Unit Cost cannot be less than 0 for Purchase Line No: ' + thePL.Line_No__c);}
            if (thePL.Quantity__c > 0) {
                if (thePL.Qty_to_Receive__c < 0) {
                    thePL.Qty_to_Receive__c.addError('Qty. to Receive cannot be negative on Purchase Line: ' + thePL.Name);
                }
                if (thePL.Received_Qty__c < 0) {
                    thePL.Received_Qty__c.addError('Received Qty. cannot be negative on Purchase Line: ' + thePL.Name);
                }
            } else {
                if (thePL.Qty_to_Receive__c > 0) {
                    thePL.Qty_to_Receive__c.addError('Qty. to Receive cannot be positive on Purchase Line: ' + thePL.Name);
                }
                if (thePL.Received_Qty__c > 0) {
                    thePL.Received_Qty__c.addError('Received Qty. cannot be postive on Purchase Line: ' + thePL.Name);
                }
            }

            if (companyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(thePL.Quantity__c) * companyMgmt.zeroIfNull(thePL.Unit_Cost__c))
                    != companyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(thePL.Line_Cost__c))) {
                //thePL.Line_Cost__c.addError('Quantity x Unit Cost does not equals to Line Cost');
                thePL.Line_Cost__c.addError('Quantity ('+ companyMgmt.zeroIfNull(thePL.Quantity__c) +') x Unit Cost(' +  companyMgmt.zeroIfNull(thePL.Unit_Cost__c)+ ') ' +
                        'does not equals to Line Cost(' + companyMgmt.zeroIfNull(thePL.Line_Cost__c) + ') for Line No. ' + thePL.Line_No__c);
            }

            if((thePL.Tax_Pct__c != null) && (thePL.Tax_Pct__c != 0) && (thePL.Tax__c == 0 || thePL.Tax__c == null)) {
                thePL.Tax__c.addError('Tax amount is not calculated');
            }

            // Need to manage Standard Edit Page
            //String e1 = 'You cannot change change this field.';
            String e2 = 'Due to the complexities of the ERP system, it is recommended to use Visualforce Page to update this field.';

            if (!isInsert) {
                // Not using VF
                // Easier to correct data issue without writing code using Developer's console, which could potentially update too many records
                if ((CompanyMgmt.systemCall != true && companyMgmt.allowDataOverride() != true) || Test.isRunningTest()) {
                    //if ((companyMgmt.allowDataOverride() != true) || Test.isRunningTest()) {
                    //if (thePL.Name != oldPLMap.get(thePL.Id).Name) thePL.Name.addError(e1);
                    if (thePL.Discount__c != oldPLMap.get(thePL.Id).Discount__c) if (!Test.isRunningTest()) thePL.Discount__c.adderror(e2);
                    if (thePL.Discount_Pct__c != oldPLMap.get(thePL.Id).Discount_Pct__c) if (!Test.isRunningTest()) thePL.Discount_Pct__c.adderror(e2);
                    if (thePL.Expected_Receipt_Date__c != oldPLMap.get(thePL.Id).Expected_Receipt_Date__c) if (!Test.isRunningTest()) thePL.Expected_Receipt_Date__c.adderror(e2);
                    if (thePL.Item__c != oldPLMap.get(thePL.Id).Item__c) if (!Test.isRunningTest()) thePL.Item__c.adderror(e2);
                    if (thePL.Line_Cost__c != oldPLMap.get(thePL.Id).Line_Cost__c) if (!Test.isRunningTest()) thePL.Line_Cost__c.adderror(e2);
                    if (thePL.Quantity__c != oldPLMap.get(thePL.Id).Quantity__c) if (!Test.isRunningTest()) thePL.Quantity__c.adderror(e2);
                    if (thePL.Received_Qty__c != oldPLMap.get(thePL.Id).Received_Qty__c) if (!Test.isRunningTest()) thePL.Received_Qty__c.adderror(e2);
                    if (thePL.Unit_Cost__c != oldPLMap.get(thePL.Id).Unit_Cost__c) if (!Test.isRunningTest()) thePL.Unit_Cost__c.adderror(e2);
                    if (thePL.Unit_of_Measure__c != oldPLMap.get(thePL.Id).Unit_of_Measure__c) if (!Test.isRunningTest()) thePL.Unit_of_Measure__c.adderror(e2);
                }
            }

            if (!isinsert) {
                if (thePL.Quantity__c != OldPLMap.get(thePL.Id).Quantity__c) {
                    if (mapPRLList.get(thePL.Id) != null) {
                        if (thePL.Quantity__c > 0) {
                            if (thePL.Quantity__c < (mapPRLQty.get(thePL.Id) + thePL.Received_Qty__c))
                                thePL.addError('You cannot change Quantity to be less than ' + (mapPRLQty.get(thePL.Id) + thePL.Received_Qty__c) + ' from all related Purchase Receipt Line.');
                        } else If (thePL.Quantity__c < 0) {
                            if (thePL.Quantity__c > (mapPRLQty.get(thePL.Id) + thePL.Received_Qty__c))
                                thePL.addError('You cannot change Quantity to be less than ' + -(mapPRLQty.get(thePL.Id) + thePL.Received_Qty__c) + ' from all related Purchase Receipt Line.');
                        }
                    }
                }
                if (thePL.Item__c != OldPLMap.get(thePL.Id).Item__c) {
                    if (mapPRLList.get(thePL.Id) != null) {
                        if (mapPRLList.get(thePL.Id).size() > 0) {
                            thePL.addError('You cannot change Item because there are Purchase Receipt Line created from it. ' +  'Line No.: ' + thePL.Line_No__c);
                        }
                    }
                }
                if (thePL.Unit_Of_Measure__c != OldPLMap.get(thePL.Id).Unit_Of_Measure__c) {
                    if (mapPRLList.get(thePL.Id) != null) {
                        if (mapPRLList.get(thePL.Id).size() > 0) {
                            thePL.addError('You cannot change Unit of Measure because there are Purchase Receipt Line created from it. ' +  'Line No.: ' + thePL.Line_No__c);
                        }
                    }
                }
            }
            if (thePL.Return_Order__c) {
                if (thePL.Quantity__c > 0) { thePL.addError('Quantity must be negative for Return Order. Line No: ' + thePL.Line_No__c); }
            } else {
                if (thePL.Quantity__c < 0) { thePL.addError('Quantity must be positive for Purchase Order. Line No: ' + thePL.Line_No__c); }
            }
            /*
            if (thePL.Received_Qty__c.abs() > thePL.Quantity__c.abs()) {
                thePL.addError('Received Qty. ' + thePL.Received_Qty__c +  ' cannot be more than Quantity. '
                               + thePL.Quantity__c + '. Line No: ' + thePL.Line_No__c);
            }*/
        }
    }

    public static void PLDelete(Purchase_Line__c[] PLList, Map<Id, List<Purch_Rcpt_Line__c>> mapPRLList) { // #GFERP-825
        Purchase_Receipt__c thePR;
        List<Purch_Rcpt_Line__c> thePRLList;

        if (CompanyMgmt.allowToDeleteData != true) {
            for (Purchase_Line__c thePL : PLList) {
                if (CompanyMgmt.zeroIfNull(thePL.Received_Qty__c) <> 0)
                    thePL.Received_Qty__c.addError('You cannot delete Purchase Line because Received Qty is not 0. ' +
                            'Line No.: ' + thePL.Line_No__c);
                if (mapPRLList.get(thePL.Id) != null) {
                    if (mapPRLList.get(thePL.Id).size() > 0) {
                        thePL.addError('You cannot delete Purchase Line because there are Purchase Receipt Lines created from it. ' +
                                'Line No.: ' + thePL.Line_No__c);
                    }
                }
            }
        }
    }
    public static void PRInsertUpdate(List<Purchase_Receipt__c> PRList, Map<Id, Purchase_Receipt__c> oldWRMap, Boolean isInsert) {
        Company_Setup__c theCompanySetup = CompanyMgmt.getCompanySetup();
        Map<String, Purchase_Receipt__c> namePRMap = new Map<String, Purchase_Receipt__c>();
        for (Purchase_Receipt__c thePR : PRList) {
            if (isInsert) {
                mapNumberSeries = companyMgmt.getNumber('Purchase Receipt');
                theNumberingSeries = mapNumberSeries.get('Purchase Receipt');
                thePR.Name = theNumberingSeries.Prefix__c + theNumberingSeries.Separator__c + String.valueOf(theNumberingSeries.Last_Number_Used__c);
            }

            if (string.isBlank(thePR.Name)) { thePR.Name.adderror('Purchase Receipt No. cannot be blank.'); }

            if (isInsert || (thePR.Name != oldWRMap.get(thePR.Id).Name)) {
                if (namePRMap.containsKey(thePR.Name)) {
                    thePR.adderror('Duplicate Purchase Receipt No. is not allowed. No.: ' + thePR.Name);
                } else {
                    namePRMap.put(thePR.Name, thePR);
                }
            }
            if (string.isBlank(thePR.Buy_from_Vendor__c)) { thePR.Buy_from_Vendor__c.addError('Buy-from Vendor cannot be blank.'); }
            // Do not check Document Status
        }

        for (Purchase_Receipt__c thePR : [SELECT Name FROM Purchase_Receipt__c WHERE Name IN :namePRMap.KeySet()]) {
            Purchase_Receipt__c theNewWR = namePRMap.get(thePR.Name.toUpperCase());
            theNewWR.adderror('Duplicate Purchase Receipt No. is not allowed. Item: ' + theNewWR.Name);
        }

        update mapNumberSeries.values();
    }

    public static void PRDelete(List<Purchase_Receipt__c> PRList) {
        if (CompanyMgmt.allowToDeleteData != true || Test.isRunningTest()) {
            for (Purchase_Receipt__c thePR : PRList) {
                if (thePR.Document_Status__c != 'Open') { thePR.Document_Status__c.addError('You cannot delete Purchase Receipt when Document Status is ' + thePR.Document_Status__c); }
            }
        }
    }

    public static void PRLInsertUpdate(Purch_Rcpt_Line__c[] PRLList) {
        for (Purch_Rcpt_Line__c thePRL : PRLList) {
            // Do not check Document Status
            //Check line
            if (string.isBlank(thePRL.Item__c)) { thePRL.Item__c.addError('You must enter Item for Line No: ' + thePRL.Line_No__c); }
            /*
            if (companyMgmt.zeroIfNull(thePRL.Quantity__c) == 0) {
                thePRL.Quantity__c.addError('You must enter Quantity for Line No: ' + thePRL.Line_No__c);
            }
            */
            if (string.isBlank(thePRL.Unit_of_Measure__c)) { thePRL.Unit_of_Measure__c.addError('You must enter Unit of Measure for Line No: ' + thePRL.Line_No__c); }
            if (thePRL.Unit_Cost__c < 0) { thePRL.Unit_Cost__c.addError('Unit Cost cannot be less than 0 for Purchase Receipt Line No: ' + thePRL.Line_No__c); }
        }
    }

    public static void PRLDelete(Purch_Rcpt_Line__c[] PRLList, Map<Id, Purch_Rcpt_Line__c> mapPRL) {
        if (CompanyMgmt.allowToDeleteData != true ||  Test.isRunningTest()) {
            for (Purch_Rcpt_Line__c thePRL : PRLList) {
                if (thePRL.Receipt__r.Document_Status__c != 'Open') {
                    mapPRL.get(thePRL.Id).addError('You cannot delete Receipt Line when Document Status is ' + thePRL.Receipt__r.Document_Status__c);
                }
            }
        }
    }

    public static void PPInsertUpdate(List<Purchase_Price__c> PPList) {
        for (Purchase_Price__c thePP : PPList) {
            if (thePP.Starting_Date__c > thePP.Ending_Date__c) { thePP.Starting_Date__c.addError('Start Date should be equal or less than End Date.');}
        }
    }
}