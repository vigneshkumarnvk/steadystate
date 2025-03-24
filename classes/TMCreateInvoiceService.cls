public with sharing class TMCreateInvoiceService {
    /* Depreciated
    Public Static Company_Setup__c theCompanySetup = CompanyMgmt.getCompanySetup();

    public static Sales_invoice__c insertSI(TM__c theTM) {
        Sales_Invoice__c theSI = new Sales_Invoice__c();
        theSI.Sales_Order__c = theTM.Sales_Order__c;
        theSI.Bill_To_Customer__c = theTM.Bill_To_Customer__c;
        theSI = SalesInvoiceMgmt.validateBillToCustomer(theSI);
        theSI.Posting_Date__c = date.today();
        theSI.Account_Executive__c = theTM.Account_Executive__c;
        theSI.Customer_PO_No__c = theTM.Customer_PO_No__c;
        theSI.Service_Center__c = theTM.Service_Center__c;
        theSI.Subsidiary_Company__C = theTM.Subsidiary_Company__c;
        theSI.Document_Status__c = 'Open';
        theSI.Invoice_Date__c = date.Today();
        theSI.Contact__c = theTM.Contact__c;
        theSI.Site_Contact_2__c = theTM.Site_Contact_2__c;
        theSI.Bill_to_Customer__r = null; theSI.Contact__r = null;
        theSI.Tax_Area__r = null;
        theSI.Site_Name__c = theTM.Site_Name__c;
        theSI.Site_Street__c = theTM.Site_Street__c;
        theSI.Site_City__c = theTM.Site_City__c;
        theSI.Site_State__c = theTM.Site_State__c;
        theSI.Site_Postal_Code__c = theTM.Site_Postal_Code__c;
        theSI.Site_Country__c = theTM.Site_Country__c;
        theSI.Site_Contact__c = theTM.Site_Contact__c;
        theSI.Site_Phone_No__c = theTM.Site_Phone_No__c;
        theSI.Site_Email_Address__c = theTM.Site_Email_Address__c;
        theSI.Tax_Liable__c = theTM.Tax_Liable__c;
        theSI.Tax_Area__c = theTM.Tax_Area__c;
        theSI.Contract__c = theTM.Contract__c;
        //AES-438
        theSI.Billing_Instructions__c = theTM.Billing_Instructions__c;
        theSI.Internal_Comments__c = theTM.Internal_Comments__c; //14554
        theSI.Site_Scope__c = theTM.Site_Scope__c;//14554
        return theSI;
    }

    public static Sales_Invoice__c insertSIL(Sales_Invoice__c theSI, TM__c theTM, List<TM_Line__c> theTMLList, String invoiceNote) {
        theSI = new Sales_invoice__c();
        Integer i;
        Decimal lineNo = 0;
        Sales_Invoice_Line__c newSIL;
        List<Sales_Invoice_Line__c> theNewSILList;

        if (theTMLList != null && theTMLList.size() > 0) {
            theNewSILList = new List<Sales_Invoice_Line__c>();
            for (TM_Line__c theTML : theTMLList) {
                if (theTML.Invoiced__c != true) {

                    lineNo = lineNo + 1;
                    newSIL = new Sales_Invoice_Line__c();
                    newSIL.Sales_Invoice__c = theSI.Id;
                    newSIL.Resource_Type__c = theTML.Resource_Type__c;
                    newSIL.Resource__c = theTML.Resource__c;
                    if ((!theTML.Resource_Type__r.Fleet_No_Required__c || theTML.Service_Center__r.Equipment_Fleet_No_Not_Required__c)
                            && (newSIL.Resource__c == null)) {
                        System.debug('Steven here ' + theTML.Resource_Type__r.Name);
                        newSIL.Resource__c = theCompanySetup.Default_Equipment_Resource__c;
                    }
                    newSIL.Description__c = theTML.Description__c;
                    newSIL.Category__c = theTML.Category__c;
                    newSIL.Unit_of_Measure__c = theTML.Unit_of_Measure__c;
                    newSIL.Line_No__c = lineNo;
                    newSIL.Tax_Group__c = theTML.Tax_Group__c;
                    newSIL.Tax_Pct__c = theTML.Tax_Pct__c;
                    newSIL.Tax__c = theTML.Tax__c;
                    newSIL.TM_Line__c = theTML.Id;
                    newSIL.TM__c = theTML.TM__c;
                    newSIL.Service_Center__c = theTML.Service_Center__c; //AES-406
                    newSIL.Bill_as_Lump_Sum__c = theTML.Bill_as_Lump_Sum__c;
                    newSIL.Non_Billable__c = theTML.Non_Billable__c; //Ticket#13673
                    newSIL.BOL_Manifest__c = theTML.BOL_Manifest__c;
                    newSIL.Scheduled_Date__c = theTML.TM__r.Scheduled_Date__c;
                    //For labor lines, if hours = quantity, assume UOM = hours
                    if ((theTML.Category__c != 'Labor') || (theTML.Hour__c != theTML.Quantity__c)) {
                        newSIL.Quantity__c = theTML.Quantity__c;
                        newSIL.Unit_of_Measure__c = theTML.Unit_of_Measure__c;
                        if (newSIL.Quantity__c != 0) {
                            newSIL.Unit_Price__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(theTML.Line_Amount__c) / newSIL.Quantity__c);
                        } else newSIL.Unit_Price__c = 0;
                        newSIL.Cost_Qty__c = theTML.Cost_Qty__c;
                        newSIL.Unit_Cost__c = theTML.Unit_Cost__c;
                        newSIL.Line_Cost__c = theTML.Line_Cost__c;
                        newSIL.Line_Amount__c = theTML.Line_Amount__c;
                        newSIL.Line_Amt_Incl_Tax__c = theTML.Line_Amt_Incl_Tax__c;

                        if (newSIL.Quantity__c <> 0 || newSIL.Line_Amt_Incl_Tax__c <> 0) theNewSILList.add(newSIL);
                    } else {
                        if (theTML.Regular_Hours__c != null && theTML.Regular_Hours__c != 0) {
                            newSIL.Quantity__c = theTML.Regular_Hours__c;
                                newSIL.Unit_Price__c = theTML.Regular_Rate__c;
                            newSIL.Line_Amount__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(newSIL.Unit_Price__c) *
                                    companyMgmt.zeroIfNull(newSIL.Quantity__c));
                            newSIL.Tax__c = CompanyMgmt.halfUpTo2D(newSIL.Line_Amount__c * companyMgmt.zeroIfNull(newSIL.Tax_Pct__c) / 100);
                            newSIL.Line_Amt_Incl_Tax__c = newSIL.Line_Amount__c + newSIL.Tax__c;
                            newSIL.Cost_Qty__c = newSIL.Quantity__c;
                            newSIL.Unit_Cost__c = theTML.Unit_Cost__c;
                            newSIL.Line_Cost__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(newSIL.Unit_Cost__c) *
                                    companyMgmt.zeroIfNull(newSIL.Quantity__c));
                            if (newSIL.Quantity__c <> 0 || newSIL.Line_Amt_Incl_Tax__c <> 0) {
                                theNewSILList.add(newSIL);
                            }
                        }

                        if (theTML.Overtime_Hours__c != null && theTML.Overtime_Hours__c != 0) {
                            lineNo = lineNo + 1;
                            newSIL = new Sales_Invoice_Line__c();
                            newSIL.Sales_Invoice__c = theSI.Id;
                            newSIL.Resource__c = theTML.Resource__c;
                            newSIL.Resource_Type__c = theTML.Resource_Type__c;
                            newSIL.Description__c = theTML.Description__c + '-OT';
                            newSIL.Category__c = theTML.Category__c;
                            newSIL.Unit_of_Measure__c = theTML.Unit_of_Measure__c;
                            newSIL.Line_No__c = lineNo;
                            newSIL.Tax_Group__c = theTML.Tax_Group__c;
                            newSIL.Tax_Pct__c = theTML.Tax_Pct__c;
                            newSIL.Tax__c = theTML.Tax__c;
                            newSIL.TM_Line__c = theTML.Id;
                            newSIL.TM__c = theTML.TM__c;
                            newSIL.Service_Center__c = theTML.Service_Center__c; //AES-406
                            newSIL.Bill_as_Lump_Sum__c = theTML.Bill_as_Lump_Sum__c;
                            newSIL.Non_Billable__c = theTML.Non_Billable__c; //Ticket#13673
                            newSIL.Scheduled_Date__c = theTML.TM__r.Scheduled_Date__c;
                            newSIL.Quantity__c = theTML.Overtime_Hours__c;
                            newSIL.Unit_Price__c = theTML.Overtime_Rate__c;
                            newSIL.Line_Amount__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(newSIL.Unit_Price__c) *
                                    companyMgmt.zeroIfNull(newSIL.Quantity__c));
                            newSIL.Tax__c = CompanyMgmt.halfUpTo2D(newSIL.Line_Amount__c * companyMgmt.zeroIfNull(newSIL.Tax_Pct__c) / 100);
                            newSIL.Line_Amt_Incl_Tax__c = newSIL.Line_Amount__c + newSIL.Tax__c;
                            newSIL.Cost_Qty__c = newSIL.Quantity__c;
                            newSIL.Unit_Cost__c = theTML.Unit_Cost__c;
                            newSIL.Line_Cost__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(newSIL.Unit_Cost__c) *
                                    companyMgmt.zeroIfNull(newSIL.Quantity__c));
                            if (newSIL.Quantity__c <> 0 || newSIL.Line_Amt_Incl_Tax__c <> 0) {
                                theNewSILList.add(newSIL);
                            }
                        }
                        //Ticket#13673 >>
                        if (theTML.Premium_Hours__c != null && theTML.Premium_Hours__c != 0) {
                            lineNo = lineNo + 1;
                            newSIL = new Sales_Invoice_Line__c();
                            newSIL.Sales_Invoice__c = theSI.Id;
                            newSIL.Resource__c = theTML.Resource__c;
                            newSIL.Resource_Type__c = theTML.Resource_Type__c;
                            newSIL.Description__c = theTML.Description__c + '-PREM';
                            newSIL.Category__c = theTML.Category__c;
                            newSIL.Unit_of_Measure__c = theTML.Unit_of_Measure__c;
                            newSIL.Line_No__c = lineNo;
                            newSIL.Tax_Group__c = theTML.Tax_Group__c;
                            newSIL.Tax_Pct__c = theTML.Tax_Pct__c;
                            newSIL.Tax__c = theTML.Tax__c;
                            newSIL.TM_Line__c = theTML.Id;
                            newSIL.TM__c = theTML.TM__c;
                            newSIL.Service_Center__c = theTML.Service_Center__c; //AES-406
                            newSIL.Bill_as_Lump_Sum__c = theTML.Bill_as_Lump_Sum__c;
                            newSIL.Non_Billable__c = theTML.Non_Billable__c; //Ticket#13673
                            newSIL.Scheduled_Date__c = theTML.TM__r.Scheduled_Date__c;
                            newSIL.Quantity__c = theTML.Premium_Hours__c;
                            newSIL.Unit_Price__c = theTML.Premium_Rate__c;
                            newSIL.Line_Amount__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(newSIL.Unit_Price__c) *
                                    companyMgmt.zeroIfNull(newSIL.Quantity__c));
                            newSIL.Tax__c = CompanyMgmt.halfUpTo2D(newSIL.Line_Amount__c * companyMgmt.zeroIfNull(newSIL.Tax_Pct__c) / 100);
                            newSIL.Line_Amt_Incl_Tax__c = newSIL.Line_Amount__c + newSIL.Tax__c;
                            newSIL.Cost_Qty__c = newSIL.Quantity__c;
                            newSIL.Unit_Cost__c = theTML.Unit_Cost__c;
                            newSIL.Line_Cost__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(newSIL.Unit_Cost__c) *
                                    companyMgmt.zeroIfNull(newSIL.Quantity__c));
                            if (newSIL.Quantity__c <> 0 || newSIL.Line_Amt_Incl_Tax__c <> 0) {
                                theNewSILList.add(newSIL);
                            }
                        }
                        //Ticket#13673 >>
                    }
                }
            }
            //To update Invoiced field
            //upsert theTMLList;
            if (theNewSILList != null && theNewSILList.size() > 0) {
                theSI = insertSI(theTM);
                if (invoiceNote != null) {
                    if (invoiceNote.length() > 0) {
                        theSI.Invoice_Note__c = invoiceNote;
                    }
                }

                theSI.Account_Executive__r = null;
                theSI.Salesperson__r = null;
                if (!test.isrunningtest()) insert theSI;

                for (i = 0; i < theNewSILList.size(); i++) {
                    theNewSILList[i].Sales_Invoice__c = theSI.Id;
                }
                if (!test.isrunningtest()) insert theNewSILList;
            }
        }
        return theSI;
    }
     */
}