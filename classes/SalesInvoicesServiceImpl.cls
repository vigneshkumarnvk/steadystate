/*************************************************************************************************
* Name         :  SalesLinesServiceImpl
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan      10-13-2024             US127188 - Salesforce - Modifications to allow ESIC Surcharge Type 
*************************************************************************************************/
public class SalesInvoicesServiceImpl implements ISalesInvoicesService {

    public static Company_Setup__c theCompanySetupValue;

    private Company_Setup__c theCompanySetup {
        get{
            if (theCompanySetupValue == null){
                theCompanySetupValue = CompanyMgmt.getCompanySetup();
            }
            return theCompanySetupValue;
        }
    }

    public Decimal calcSurchargeAmount(Sales_Invoice__c salesInvoice, List<Sales_Invoice_Line__c> salesInvoiceLines){
        Decimal surchargeAmt = 0;
        if(salesInvoice.Surcharge_Type__c != null){
            Decimal subTotalForSurchargeCalculation = 0;
            subTotalForSurchargeCalculation = calcTotalForSurchargeCalculation(salesInvoice.Surcharge_Type__c, salesInvoiceLines);
            surchargeAmt = CompanyMgmt.halfUpTo2D(subTotalForSurchargeCalculation * CompanyMgmt.zeroIfNull(salesInvoice.Surcharge_Pct__c) / 100);
        }

        //Handle user manual updated surcharge line.
        Decimal surchargeAmountInSalesLine = 0;
        for(Sales_Invoice_Line__c salesInvoiceLine : salesInvoiceLines){
            if(salesInvoiceLine.System_Calculated_Line__c == true &&
                    (salesInvoiceLine.Resource__c == theCompanySetup.Default_Energy_Insurance_Resource__c ||
                    	salesInvoiceLine.Resource__c == theCompanySetup.Default_Fuel_Surcharge_Resource__c ||
                      		salesInvoiceLine.Resource__c == theCompanySetup.Default_ESIC_Surcharge_Resource__c)){
                surchargeAmountInSalesLine += CompanyMgmt.zeroIfNull(salesInvoiceLine.Line_Amt_Incl_Tax__c);
            }
        }

        if(surchargeAmountInSalesLine > 0 && surchargeAmountInSalesLine != surchargeAmt){
            surchargeAmt = surchargeAmountInSalesLine;
        }

        return surchargeAmt;
    }

    public Decimal calcTotalForSurchargeCalculation(String surchargeType, List<Sales_Invoice_Line__c> salesInvoiceLines){
        Decimal subTotal = 0;
        Set<Id> resIds = new Set<Id>();
        Set<Id> resTypeIds = new Set<Id>();
        for(Sales_Invoice_Line__c salesInvoiceLine : salesInvoiceLines){
            if(salesInvoiceLine.Resource_Type__c != null) resTypeIds.add(salesInvoiceLine.Resource_Type__c);
            if(salesInvoiceLine.Resource__c != null) resIds.add(salesInvoiceLine.Resource__c);
        }

        Map<Id, Resource_Type__c> resourceTypesByIds = ResourceTypesSelector.newInstance().getResourceTypesByIdsMap(resTypeIds);
        Map<Id, Resource__c> resourcesByIds = ResourcesSelector.newInstance().getResourcesByIdsMapByResIds(resIds);

        switch on surchargeType{
            when 'EEC Fee'{
                for(Sales_Invoice_Line__c salesInvoiceLine : salesInvoiceLines) {
                    Boolean eiExempted = false;
                    if (salesInvoiceLine.Resource_Type__c != null && resourceTypesByIds.containsKey(salesInvoiceLine.Resource_Type__c)) {
                        Resource_Type__c resourceType = resourceTypesByIds.get(salesInvoiceLine.Resource_Type__c);
                        eiExempted = resourceType.EEC_Surcharge_Exempted__c;
                    }
                    if (salesInvoiceLine.Resource__c != null && eiExempted != true && resourcesByIds.containsKey(salesInvoiceLine.Resource__c)) {
                        Resource__c resource = resourcesByIds.get(salesInvoiceLine.Resource__c);
                        eiExempted = resource.EEC_Surcharge_Exempted__c;
                    }

                    if (salesInvoiceLine.Resource__c != theCompanySetup.Default_Energy_Insurance_Resource__c &&
                            salesInvoiceLine.Resource__c != theCompanySetup.Default_Fuel_Surcharge_Resource__c &&
                            eiExempted != true) {
                        subTotal += CompanyMgmt.zeroIfNull(salesInvoiceLine.Line_Amount__c);
                    }
                }
            }
            when 'ESIC'{
                for(Sales_Invoice_Line__c salesInvoiceLine : salesInvoiceLines) {
                    Boolean eiExempted = false;
                    if (salesInvoiceLine.Resource_Type__c != null && resourceTypesByIds.containsKey(salesInvoiceLine.Resource_Type__c)) {
                        Resource_Type__c resourceType = resourceTypesByIds.get(salesInvoiceLine.Resource_Type__c);
                        eiExempted = resourceType.EEC_Surcharge_Exempted__c;
                    }
                    if (salesInvoiceLine.Resource__c != null && eiExempted != true && resourcesByIds.containsKey(salesInvoiceLine.Resource__c)) {
                        Resource__c resource = resourcesByIds.get(salesInvoiceLine.Resource__c);
                        eiExempted = resource.EEC_Surcharge_Exempted__c;
                    }

                    if (salesInvoiceLine.Resource__c != theCompanySetup.Default_Energy_Insurance_Resource__c &&
                            salesInvoiceLine.Resource__c != theCompanySetup.Default_Fuel_Surcharge_Resource__c &&
                        	salesInvoiceLine.Resource__c != theCompanySetup.Default_ESIC_Surcharge_Resource__c	&&
                            eiExempted != true) {
                        subTotal += CompanyMgmt.zeroIfNull(salesInvoiceLine.Line_Amount__c);
                    }
                }
            }
            when 'Fuel Surcharge'{
                for(Sales_Invoice_Line__c salesInvoiceLine : salesInvoiceLines){
                    if(salesInvoiceLine.Category__c == 'Equipment' && salesInvoiceLine.Resource_Type__c != null &&
                            resourceTypesByIds.containsKey(salesInvoiceLine.Resource_Type__c)){
                        Resource_Type__c resourceType = resourceTypesByIds.get(salesInvoiceLine.Resource_Type__c);
                        if(resourceType.Fuel_Fired_Equipment__c == true){
                            subTotal += CompanyMgmt.zeroIfNull(salesInvoiceLine.Line_Amount__c);
                            if(salesInvoiceLine.Bill_as_Lump_Sum__c == true || salesInvoiceLine.Non_Billable__c == true){
                                subTotal += CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(salesInvoiceLine.xUnit_Price__c) *
                                        companyMgmt.zeroIfNull(salesInvoiceLine.Quantity__c));
                            }
                        }
                    }
                }
            }
        }
        return CompanyMgmt.halfUpTo2D(subTotal);
    }


    public void submitForApproval(Id recordId){
        List<Sales_Invoice__c> invoiceRecords = SalesInvoicesSelector.newInstance().selectByIdWithSILines(new Set<Id>{recordId});
        if(invoiceRecords.size() > 0){
            InvoiceRecordApprovalProcess invoiceRecordApprovalProcess = new InvoiceRecordApprovalProcess(invoiceRecords[0]);
            invoiceRecordApprovalProcess.submitApprovalRequest();
        }
    }

    public void submitForApproval(Id recordId, Boolean isInitialApprovalRequest){
        List<Sales_Invoice__c> invoiceRecords = SalesInvoicesSelector.newInstance().selectByIdWithSILines(new Set<Id>{recordId});
        if(invoiceRecords.size() > 0){
            InvoiceRecordApprovalProcess invoiceRecordApprovalProcess = new InvoiceRecordApprovalProcess(invoiceRecords[0]);
            invoiceRecordApprovalProcess.isInitialApprovalRequest = isInitialApprovalRequest;
            invoiceRecordApprovalProcess.submitApprovalRequest();
        }
    }

    /*
     * Ticket#16912
     * add approval comment
     */
    public void submitForApproval(Id recordId, Boolean isInitialApprovalRequest, String comment){
        List<Sales_Invoice__c> invoiceRecords = SalesInvoicesSelector.newInstance().selectByIdWithSILines(new Set<Id>{recordId});
        if(invoiceRecords.size() > 0){
            InvoiceRecordApprovalProcess invoiceRecordApprovalProcess = new InvoiceRecordApprovalProcess(invoiceRecords[0]);
            invoiceRecordApprovalProcess.isInitialApprovalRequest = isInitialApprovalRequest;
            invoiceRecordApprovalProcess.approvalComment = comment;
            invoiceRecordApprovalProcess.submitApprovalRequest();
        }
    }
     
     public Sales_Invoice__c createCreditMemo(Sales_Invoice__c recordToReverse, Id creditMemoWorkSheetId){
        Sales_Invoice__c creditMemo = new Sales_Invoice__c();
        List<Sales_Invoice_Line__c> creditMemoLines = new List<Sales_Invoice_Line__c>();
        creditMemo = recordToReverse.clone(false, true);
        creditMemo.Credit_Memo__c = true;
        creditMemo.Reversed_from_SI__c = recordToReverse.Id;
        creditMemo.Parent_Record__c = recordToReverse.Id;
        creditMemo.Credit_Memo_Worksheet__c = creditMemoWorkSheetId;
        creditMemo.Document_Status__c = 'Open';
        creditMemo.Credit_Memo_Reason_Code__c = recordToReverse.Credit_Memo_Reason_Code__c;
        creditMemo.Name = '';
        //creditMemo.Internal_Comments__c = String.isEmpty(creditMemo.Internal_Comments__c) ? creditMemoNote : theNewSI.Internal_Comments__c + '\n' + creditMemoNote; //15090
        //Ticket#13511 >>
        creditMemo.Sync_d__c = false;
        //Ticket#13511 <<
        insert creditMemo;

        creditMemoLines = recordToReverse.Sales_Invoice_Lines__r.deepClone();

        if (creditMemoLines != null && creditMemoLines.size() > 0) {
            for (Sales_Invoice_Line__c creditMemoLine : creditMemoLines) {
                creditMemoLine.Sales_Invoice__c = creditMemo.Id;
                creditMemoLine.Quantity__c = -CompanyMgmt.zeroIfNull(creditMemoLine.Quantity__c);
                creditMemoLine.Line_Amount__c = -CompanyMgmt.zeroIfNull(creditMemoLine.Line_Amount__c);
                creditMemoLine.Tax__c = -CompanyMgmt.zeroIfNull(creditMemoLine.Tax__c);
                creditMemoLine.Line_Amt_Incl_Tax__c = -CompanyMgmt.zeroIfNull(creditMemoLine.Line_Amt_Incl_Tax__c);
            }
            insert creditMemoLines;
        }

        // Update current SI
        recordToReverse.Reversed__c = true;
        recordToReverse.Reversed_by_CM_No__c = creditMemo.Id;
        recordToReverse.Credit_Memo_Reason_Code__c = null;
        update recordToReverse;

        return creditMemo;
    }

    //Invoice Versioning >>
    public Map<Id, String> getParentInvIdWithNextReversionInvNum(Set<Id> tmIds, Set<Id> tmlIds){
        Map<Id, String> parentInvIdWithNextReversionInvNum = new Map<Id, String>();
        Integer count = 0;
        String invoiceNo = '';
        List<Sales_Invoice_Line__c> salesInvoiceLines = SalesInvoiceLinesSelector.newInstance().selectPostedInvoiceLinesByTMLineIds(tmlIds);

        Set<Id> existingInvoiceIds = new Set<Id>();
        for(Sales_Invoice_Line__c salesInvoiceLine:salesInvoiceLines){
            existingInvoiceIds.add(salesInvoiceLine.Sales_Invoice__c);
        }

        Map<Id, Set<Id>> tmIdsByInvoiceId = new Map<Id, Set<Id>>();
        List<Sales_Invoice__c> existingInvoices = SalesInvoicesSelector.newInstance().selectById(existingInvoiceIds);
        Map<Id, Sales_Invoice__c> existingInvoicesByIds = new Map<Id, Sales_Invoice__c>(existingInvoices);
        //Map<Id, List<Sales_Invoice_Line__c>> salesInvoiceLinesByInvoiceIds = new Map<Id, List<Sales_Invoice_Line__c>>();
        List<Sales_Invoice_Line__c> salesInvoiceLines2 = SalesInvoiceLinesSelector.newInstance().selectByInvoiceIds(existingInvoiceIds);
        for(Sales_Invoice_Line__c salesInvoiceLine:salesInvoiceLines2) {
            if (String.isNotBlank(salesInvoiceLine.TM__c)) {
                if (tmIdsByInvoiceId.containsKey(salesInvoiceLine.Sales_Invoice__c)) {
                    Set<Id> tempTMIds = new Set<Id>();
                    tempTMIds = tmIdsByInvoiceId.get(salesInvoiceLine.Sales_Invoice__c);
                    tempTMIds.add(salesInvoiceLine.TM__c);
                    tmIdsByInvoiceId.put(salesInvoiceLine.Sales_Invoice__c, tempTMIds);
                } else {
                    tmIdsByInvoiceId.put(salesInvoiceLine.Sales_Invoice__c, new Set<Id>{salesInvoiceLine.TM__c});
                }
            }
        }

        Map<String, Integer> invoiceNumberCount = new Map<String, Integer>();
        for(Sales_Invoice__c salesInvoice:existingInvoices){
            //Set<Id> tempTMIds = new Set<Id>();
            Integer invCount = 1;
            String invoiceName = '';
            if(salesInvoice.Name.contains('-')){
                List<String> invoicesStr = salesInvoice.Name.split('-');
                invoiceName = invoicesStr[0];
                if(invoiceNumberCount.containsKey(invoiceName)){
                    invCount = invoiceNumberCount.get(invoicesStr[0]) + 1;
                }
            } else {
                invoiceName = salesInvoice.Name;
            }

            invoiceNumberCount.put(invoiceName, invCount);
        }

        Id matchedInvoiceId;
        for(Id invoiceId : tmIdsByInvoiceId.keySet()){
            Set<Id> tempTMIds = tmIdsByInvoiceId.get(invoiceId);
            if(tmIds.equals(tempTMIds)){
                matchedInvoiceId = invoiceId;
                break;
            }
        }

        if(matchedInvoiceId != null){
            Sales_Invoice__c existingSalesInvoice = existingInvoicesByIds.get(matchedInvoiceId);
            if(existingSalesInvoice.Name.contains('-')){
                List<String> invoicesStr = existingSalesInvoice.Name.split('-');
                invoiceNo = invoicesStr[0];
            } else {
                invoiceNo = existingSalesInvoice.Name;
            }
            count = invoiceNumberCount.get(invoiceNo);
        }

        if(count > 0){
            Boolean isInvoiceNoValid = true;
            String newInvoiceNo = invoiceNo + '-R' + count;
            while (isInvoiceNoValid == true){
                List<Sales_Invoice__c> salesInvoices = [SELECT Id FROM Sales_Invoice__c WHERE Name = :newInvoiceNo];
                if(salesInvoices.size() > 0){
                    count += 1;
                    newInvoiceNo = invoiceNo + '-R' + count;
                } else {
                    isInvoiceNoValid = false;
                }
            }
            parentInvIdWithNextReversionInvNum.put(salesInvoiceLines[0].Sales_Invoice__c, newInvoiceNo);
        }

        return parentInvIdWithNextReversionInvNum;
    }
    //Invoice Versioning <<
}