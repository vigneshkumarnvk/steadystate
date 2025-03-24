public with sharing class PurchaseReceiptMgmt {
    public static List <string> checkSave(Purchase_Receipt__c thePR, List<Purch_Rcpt_Line__c> thePRLList, list<Purchase_Line__c> thePLList) {
        List<string> errorList = new List<string> ();

        // Bypass checkings when allow data override
        //if (companyMgmt.allowDataOverride())  return errorList;

        if (thePR.Document_Status__c != 'Open' && CompanyMgmt.systemCall != true) errorList.add('You cannot update Purchase Receipt when Document Status is ' + thePR.Document_Status__c);

        else {
            for (Integer i = 0; i < thePRLList.size(); i++) {
                // Check Purchase Line
                List<string> PLError = checkPL(thePR, thePRLList[i], thePLList, 'toReceive', 0);
                for (Integer j = 0; j < PLError.size(); j++)  errorList.add(PLError[j]);
            }
        }
        return errorList;
    }

    public static List<String> checkPRLSave(Purchase_Receipt__c thePR, Purch_Rcpt_Line__c thePRL) {
        List<String> errorList = new List<String> ();
        Decimal totalLotQty = 0;
        Decimal qtyAvail = 0;

        return errorList;
    }

    public static List <string> checkPost(Purchase_Receipt__c thePR, List<Purch_Rcpt_Line__c> thePRLList, List<Purchase_Line__c> thePLList) {
        List<string> errorList = new List<string> ();
//        Set<Id> theSOId = new Set<Id>();
//        List<Sales_Order__c> theSOList = new List<Sales_Order__c>();
        Integer i, j;
//        Decimal totalQty = 0;
//        Decimal qtyAvail = 0;
//        Decimal LotEntered = 0;

        if (thePR.Document_Status__c == 'Posted') {
            errorList.add('Purchase Receipt was posted already.');
        }

        User theUser = [SELECT Id, Name, Purchasing_Department_Receiver__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        if((thePR.PO_Requestor__c != UserInfo.getUserId()) && (thePR.OwnerId != UserInfo.getUserId()) &&(!theUser.Purchasing_Department_Receiver__c)){
            errorList.add('Receipt can only post by PO Requestor, PO Owner and purchasing department staff!');
        }

        if (!CompanyMgmt.checkPostingDate(thePR.Posting_Date__c)) {
            errorList.add(thePR.Posting_Date__c.format() + ' is not within your range of allowed posting dates.');
        }
        // Remove PRL with Quantity = 0
        for (i = 0; i < thePRLList.size(); i++) {
            if (thePRLList[i].Quantity__c == 0) thePRLList.remove(i);
        }

        if (thePRLList.size() == 0)  errorList.add('There is nothing to post.');

        // Check lines
        for (i = 0; i < thePRLList.size(); i++) {
            // Check Unit Cost
            if (thePRLList[i].Unit_Cost__c < 0) errorList.add('Unit Cost cannot be negative. ' + thePRLList[i].Name);// #GFERP-749

            // Check Purchase Line
            List<string> PLError = checkPL(thePR, thePRLList[i], thePLList, 'toReceive', 0);
            for (j = 0; j < PLError.size(); j++) {
                errorList.add(PLError[j]);
            }
        }

        return errorList;
    }

    public static List <String> checkUnpostPR(Purchase_Receipt__c thePR, List<Purch_Rcpt_Line__c> thePRLList, List<Sales_Line__c> theSLList) {
        List<String> errorList = new List<String> ();
        Set<Id> theSOId = new Set<Id>();
        List<Sales_Order__c> theSOList = new List<Sales_Order__c>();
        Integer i;
        Set<Id> thePRLIdList = new Set<Id>();

        for (i = 0; i < thePRLList.size(); i++) {
            thePRLIdList.add(thePRLList[i].Id);
        }

        if (thePR.Document_Status__c == 'Open') {
            errorList.add('Purchase Receipt is not posted yet.');
            return errorList;
        }

        if (thePRLList.size() == 0) {
            errorList.add('There is nothing to unpost.');
            return errorList;
        }

        return errorList;
    }

    public static List<String> checkPL(Purchase_Receipt__c thePR, Purch_Rcpt_Line__c thePRL, List<Purchase_Line__c> thePLList, String theSource, Decimal newQty) {
        List<String> errorList = new List<String> ();
        Integer i;
        Boolean PLFound = false;

        for (i = 0; i < thePLList.size(); i++) {
            if (thePLList[i].Id == thePRL.Purchase_Line__c) {
                PLFound = true;

                if (theSource == 'fromVF') {
                    if (thePR.Return_Order__c) {

                        if (newQty > 0)  errorList.add('Quantity must be negative for Return Order. Line No: ' + thePRL.Line_No__c);
                        else if (thePLList[i].Outstanding_Qty__c > newQty)  errorList.add('You cannot return more than Outstanding Qty. ' + (thePLList[i].Outstanding_Qty__c) + ' for the purchase line. Line No: ' + thePRL.Line_No__c);

                    }
                    if (!thePR.Return_Order__c) {

                        if (newQty < 0) errorList.add('Quantity must be positive for Purchase Order. Line No: ' + thePRL.Line_No__c);
                        else if (thePLList[i].Outstanding_Qty__c < newQty) errorList.add('You cannot receive more than Outstanding Qty. ' + (thePLList[i].Outstanding_Qty__c) + ' for the purchase line. Line No: ' + thePRL.Line_No__c);

                        //
                    }

                    if (theSource == 'toReceive') {
                        if (thePR.Return_Order__c) {

                            if (thePRL.Quantity__c > 0) errorList.add('Quantity must be negative for Return Order. Line No: ' + thePRL.Line_No__c);

                            else if (thePLList[i].Outstanding_Qty__c > thePRL.Quantity__c)   errorList.add('You cannot return more than Outstanding Qty. ' + (thePLList[i].Outstanding_Qty__c) + ' for the purchase line. Line No: ' + thePRL.Line_No__c);

                        }
                        if (!thePR.Return_Order__c) {
                            /*
                            if (thePRL.Quantity__c < 0) {
                                errorList.add('Quantity must be positive for Purchase Order. Line No: ' + thePRL.Line_No__c);
                            } else if (thePLList[i].Outstanding_Qty__c < thePRL.Quantity__c) {
                                errorList.add('You cannot receive more than Outstanding Qty. ' + (thePLList[i].Outstanding_Qty__c) + ' for the purchase line. Line No: ' + thePRL.Line_No__c);
                            }*/
                        }
                    }
                }
            }

            if (thePLList.size() == 0) errorList.add('Purchase Line could not be found. Line No: ' + thePRL.Line_No__c);
        }
        return errorList;
    }

    public static void postPR(Purchase_Receipt__c thePR, List<Purch_Rcpt_Line__c> thePRLList, List<Purchase_Line__c> thePLList) {
        Resource__c theItem;
        Integer i, j;
        CompanyMgmt.systemCall = true;

        for (i = 0; i < thePRLList.size(); i++) {

            // Update Purchase Line
            for (j = 0; j < thePLList.size(); j++) {
                if (thePLList[j].Id == thePRLList[i].Purchase_Line__c) {
                    thePLList[j].Received_Qty__c = CompanyMgmt.zeroIfNull(thePLList[j].Received_Qty__c) + CompanyMgmt.zeroIfNull(thePRLList[i].Quantity__c);
                }
            }
        }

        update thePLList;
    }

    public static void unpostPR(Purchase_Receipt__c thePR, List<Purch_Rcpt_Line__c> thePRLList, List<Purchase_Line__c> thePLList) {
        CompanyMgmt.systemCall = true;
        Integer i, j;
        String PRId = thePR.Id;

        // Update Purchase Line
        for (i = 0; i < thePRLList.size(); i++) {
            for (j = 0; j < thePLList.size(); j++) {
                if (thePLList[j].Id == thePRLList[i].Purchase_Line__c) {
                    thePLList[j].Received_Qty__c -= thePRLList[i].Quantity__c;
                }
            }
        }

        update thePLList;

    }

    public static Purch_Rcpt_Line__c updatePRL(Purch_Rcpt_Line__c thePRL, String sourceField) {

        if (thePRL.Item__c == null)  return thePRL;

        if (sourceField == 'theQuantity') {
        }
        return thePRL;
    }

}