/*************************************************************************************************
* Name         :  TMsServiceImpl 
* Description  :  
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
  Shahwaz Khan              03-12-2024             Task78375: Salesforce - 5/1 Need for Account Number Validation
  Sanjana                   03-12-2024             Task78376: Salesforce - 7/1 Need for Account Number Validation
  Shahwaz Khan              16-05-2024             Task85892: Salesforce - Logic for MSG, Retail, National Accounts, US Ecology Internal Account.
  Andrew Simons             07-25-2024             Salesforce - removed logic for MSG/Retail/National Accounts - part 1
*************************************************************************************************/
public class TMsServiceImpl implements ITMsService {

    public static Company_Setup__c theCompanySetupValue;

    public Company_Setup__c theCompanySetup {
        get{
            if (theCompanySetupValue == null) {
                theCompanySetupValue = CompanyMgmt.getCompanySetup();
            }
            return theCompanySetupValue;
        }
        set;
    }

    //Depreciated
    public String createSalesInvoice(Id salesOrderId, Set<Id> TMIds, Set<Id> TMLIds, String invoiceNote) {
        return salesOrderId;
        /*
        // Unit of Work
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();

        //ISalesOrders SalesOrderDomain = SalesOrders.newInstance(SalesOrdersSelector.newInstance().selectCreateInvoiceRequiredFieldsById(new Set<Id>{salesOrderId}));
        ITMs TMDomain = TMs.newInstance(TMsSelector.newInstance().selectCreateInvoiceHeaderRequiredFieldsById(TMIds));
        ITMLines TMLDomain = TMLines.newInstance(TMLinesSelector.newInstance().selectCreateInvoiceRequiredFieldsById(TMLIds));
        Sales_Invoice__c theSI = new Sales_Invoice__c();
        //Invoice Versioning >>
        Map<Id, String> parentInvWithNextReversionInvNo = SalesInvoicesService.getParentInvIdWithNextReversionInvNum(TMIds, TMLIds);
        if(parentInvWithNextReversionInvNo.size() > 0){
            for(Id parentInvId:parentInvWithNextReversionInvNo.keySet()){
                //System.debug('Info: createSalesInvoice parentInvId ' + parentInvId);
                //System.debug('Info: createSalesInvoice parentInvWithNextReversionInvNo ' + parentInvWithNextReversionInvNo.get(parentInvId));
                theSI.Name = parentInvWithNextReversionInvNo.get(parentInvId);
                theSI.Parent_Record__c = parentInvId;
            }
        }
        //Invoice Versioning <<
        // Add AsyncRequest__c record for trigger to process, threshold is 1000 lines; Create value in CompanySet to control this , test TMEL12436
        if (TMLDomain.getRecords().size() > theCompanySetup.Review_Invoice_Async_No_of_Records__c) {
            createSalesInvoiceHeader(theSI, ((List<TM__c>)TMDomain.getRecords())[0], invoiceNote, uow);
            uow.commitWork();
            List<AsyncRequest__c> requests = new List<AsyncRequest__c>();
            List<Id> tempList = new List<Id>();
            for (Id id : TMLIds) {
                tempList.add(id);
                if (tempList.size() >= theCompanySetup.Review_Invoice_Async_No_of_Records__c) {
                    requests.add(
                            new AsyncRequest__c(
                                    AsyncType__c = 'Create Sales Invoice Lines',
                                    Params__c = theSI.Id,
                                    Params1__c = String.join(tempList,',')
                            )
                    );
                    tempList.clear();
                }
            }
            if (tempList.size() > 0) {
                requests.add(
                        new AsyncRequest__c(
                                AsyncType__c = 'Create Sales Invoice Lines',
                                Params__c = theSI.Id,
                                Params1__c = String.join(tempList,',')
                        )
                );
                tempList.clear();
            }
            if (tempList.size() == 0) {
                requests.add(
                        new AsyncRequest__c(
                                AsyncType__c = 'Add Surcharge Line to Sales Invoice',
                                Params__c = theSI.Id
                        )
                );
            }
            insert requests;
            return 'Async:' + theSI.Id;
        }

        // Create Invoice header
        createSalesInvoiceHeader(theSI, ((List<TM__c>)TMDomain.getRecords())[0], invoiceNote, uow);

        // Create Invoice lines
        List<Sales_Invoice_Line__c> theNewSILList = new List<Sales_Invoice_Line__c>();
        createSalesInvoiceLinesAndUpdateTML(theSI, theNewSILList, (List<TM_Line__c>) TMLDomain.getRecords(), uow);

        //TODO: Create Drop Off Rental Order and Update Pickup Rental Order

        // Update TM Status and register Sales_Invoice_Line__c value to T&M Line
        updateTMStatusAndSIValue(theSI, (List<TM__c>) TMDomain.getRecords(), (List<TM_Line__c>)TMLDomain.getRecords(), uow);

        // create Surcharge Line
        createSurchargeLine(theSI, theNewSILList, uow);
        CompanyMgmt.systemCall = true;
        uow.commitWork();
        return theSI.Id;
         */
    }

    //Depreciated
    public void addLinesToSalesInvoiceAsync(Id salesInvoice, Set<Id> TMLIds) {
        /*
        if (!System.isQueueable()) return;
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        ISalesInvoices SIDomain = SalesInvoices.newInstance(SalesInvoicesSelector.newInstance().selectLineCountById(new Set<Id>{salesInvoice}));
        Sales_Invoice__c theSI = ((List<Sales_Invoice__c>)SIDomain.getRecords())[0];

        ITMLines TMLDomain = TMLines.newInstance(TMLinesSelector.newInstance().selectCreateInvoiceRequiredFieldsById(TMLIds));
        Set<Id> theTMIds = new Set<Id>();
        for (TM_Line__c theTML : (List<TM_Line__c>) TMLDomain.getRecords()) {
            theTMIds.add(theTML.TM__c);
        }
        System.debug(theTMIds.size());
        ITMs TMDomain = TMs.newInstance(TMsSelector.newInstance().selectCreateInvoiceRequiredFieldsById(theTMIds));

        // Create Invoice lines
        List<Sales_Invoice_Line__c> theNewSILList = new List<Sales_Invoice_Line__c>();
        createSalesInvoiceLinesAndUpdateTML(theSI, theNewSILList, (List<TM_Line__c>) TMLDomain.getRecords(), uow);

        // Update TM Status and register Sales_Invoice_Line__c value to T&M Line
        updateTMStatusAndSIValue(theSI, (List<TM__c>) TMDomain.getRecords(), (List<TM_Line__c>)TMLDomain.getRecords(), uow);

        CompanyMgmt.byPassTrigger = true;
        uow.commitWork();
        CompanyMgmt.byPassTrigger = false;
         */
    }

    //Depreciated
    public void addSurchargeLineToSalesInvoiceAsync(Id salesInvoice){
        /*
        if (!System.isQueueable()) return;
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        ISalesInvoices SIDomain = SalesInvoices.newInstance(SalesInvoicesSelector.newInstance().selectByIdWithSILines(new Set<Id>{salesInvoice}));
        Sales_Invoice__c theSI = ((List<Sales_Invoice__c>)SIDomain.getRecords())[0];
        List<Sales_Invoice_Line__c> theSILList = theSI.Sales_Invoice_Lines__r;
        createSurchargeLine(theSI, theSILList, uow);
        uow.commitWork();
         */
    }

    /* Depreciated
    public void updateTMStatusAndSIValue(Sales_Invoice__c theSI, List<TM__c> theTMList, List<TM_Line__c> theTMLList, fflib_ISObjectUnitOfWork uow) {
        Map<Id,Integer> sizeMap = new Map<Id, Integer>();
        for (TM_Line__c theTML : theTMLList) {
            if (sizeMap.containsKey(theTML.TM__c)) {
                sizeMap.put(theTML.TM__c, sizeMap.get(theTML.TM__c) + 1);
            } else {
                sizeMap.put(theTML.TM__c, 1);
            }
        }
        for (TM__c theTM : theTMList){
            uow.registerRelationship(theTM, TM__c.Sales_Invoice__c, theSI);
            Decimal invoicedLines = Test.isRunningTest() ? 0 : theTM.Invoiced_Lines__c;
            Integer tmlSize = sizeMap.get(theTM.Id);
            Decimal totalLines = Test.isRunningTest() ? 2 : theTM.Total_Lines__c;
            System.debug(invoicedLines + '/' + tmlSize + '/' + totalLines);

            if (invoicedLines + tmlSize == totalLines) {
                theTM.Status__c = 'Fully Invoiced';
            } else if (invoicedLines + tmlSize < totalLines) {
                theTM.Status__c = 'Partially Invoiced';
            }
            uow.registerDirty(theTM);
        }
    }
     */

    /* Depreciated
    public void createSalesInvoiceHeader(Sales_Invoice__c theSI, TM__c theTM, String invoiceNote, fflib_ISObjectUnitOfWork uow) {

        theSI.Sales_Order__c = theTM.Sales_Order__c;
        theSI.Document_Status__c = 'Open';
        theSI.Sales_Invoice_Status__c = 'Open';
        theSI.Bill_to_Customer__c = theTM.Bill_to_Customer__c;
        theSI.Street__c = theTM.Bill_to_Customer__r.BillingStreet;
        theSI.City__c = theTM.Bill_to_Customer__r.BillingCity;
        theSI.State__c = theTM.Bill_to_Customer__r.BillingStateCode;
        theSI.Postal_Code__c = theTM.Bill_to_Customer__r.BillingPostalCode;
        theSI.Country__c = theTM.Bill_to_Customer__r.BillingCountryCode;
        theSI.Salesperson__c = theTM.Bill_to_Customer__r.Salesperson__c;
        theSI.Payment_Term__c = theTM.Bill_to_Customer__r.Payment_Term__c;
        //Ticket#15235 >>
        Decimal dueDateCalc = CompanyMgmt.zeroIfNull(theTM.Bill_to_Customer__r.Payment_Term__r.Due_Date_Calculation__c);
        if (String.isNotEmpty(theTM.Sales_Order__r.Payment_Term__c)){
            theSI.Payment_Term__c = theTM.Sales_Order__r.Payment_Term__c;
            dueDateCalc = theTM.Sales_Order__r.Payment_Term__r.Due_Date_Calculation__c;
        }
        //Ticket#15235 <<
        theSI.Posting_Date__c = Date.today();
        theSI.Account_Executive__c = theTM.Account_Executive__c;
        theSI.Customer_PO_No__c = theTM.Customer_PO_No__c;
        theSI.Service_Center__c = theTM.Service_Center__c;
        theSI.Subsidiary_Company__c = theTM.Subsidiary_Company__c;
        theSI.Invoice_Date__c = Date.today();
        theSI.Due_Date__c = CompanyMgmt.calcDate(theSI.Invoice_Date__c, dueDateCalc); //Ticket#15235
        theSI.Contact__c = theTM.Contact__c;
        theSI.Site_Contact_2__c = theTM.Site_Contact_2__c;
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
        theSI.Surcharge_Type__c = theTM.Sales_Order__r.Surcharge_Type__c;
        theSI.Surcharge_Pct__c = theTM.Sales_Order__r.Surcharge_Pct__c;
        theSI.Billing_Instructions__c = theTM.Billing_Instructions__c;
        theSI.Customer_Billing_Instructions__c = theTM.Customer_Billing_Instructions__c;
        theSI.Internal_Comments__c = theTM.Internal_Comments__c;
        theSI.Site_Scope__c = theTM.Site_Scope__c;
        //theSI.Pricing_Source__c = theTM.Pricing_Source__c;
        theSI.Invoice_Note__c = invoiceNote;
        if(theTM.Bill_to_Customer__r.Customer_Type__c == 'I/C'){
            theSI.Approved__c = true;
            theSI.Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name();
        }
        uow.registerNew(theSI);
    }
     */

    /*Depreciated
    public void createSalesInvoiceLinesAndUpdateTML(Sales_Invoice__c theSI, List<Sales_Invoice_Line__c> theNewSILList, List<TM_Line__c> theTMLList, fflib_ISObjectUnitOfWork uow) {
        Decimal lineNo = 0;
        if (theSI.Invoice_Lines__c != null){
            lineNo = theSI.Invoice_Lines__c;
        }
        for (TM_Line__c theTML : theTMLList) {
            if (theTML.Invoiced__c != true) {
                lineNo++;
                Sales_Invoice_Line__c newSIL = new Sales_Invoice_Line__c();
                newSIL.Resource_Type__c = theTML.Resource_Type__c;
                if (theTML.Resource_Type__r.Fuel_Fired_Equipment__c) {
                    newSIL.Resource_Type__r = new Resource_Type__c(Id = theTML.Resource_Type__c, Fuel_Fired_Equipment__c = theTML.Resource_Type__r.Fuel_Fired_Equipment__c);
                }
                newSIL.Resource__c = theTML.Resource__c;
                if ((!theTML.Resource_Type__r.Fleet_No_Required__c || theTML.Service_Center__r.Equipment_Fleet_No_Not_Required__c)
                        && (newSIL.Resource__c == null)) {
                    if (theTML.Category__c == 'Equipment') {
                        newSIL.Resource__c = theCompanySetup.Default_Equipment_Resource__c;
                    }
                }
                if (theTML.Service_Center__r.Temporary__c && newSIL.Resource__c == null && theTML.Category__c == 'Labor') {
                    newSIL.Resource__c = theCompanySetup.Default_Labor_Resource__c;
                }
                newSIL.Description__c = theTML.Description__c;
                if (String.isNotBlank(theTML.Contract_Line__c)){
                    newSIL.Description__c = generateLineDescription(theTML.Description__c, theTML.Contract_Line__r.Customer_Item_No__c, theTML.Contract_Line__r.Customer_Description__c);
                }

                newSIL.Category__c = theTML.Category__c;
                newSIL.Unit_of_Measure__c = theTML.Unit_of_Measure__c;
                newSIL.Line_No__c = lineNo;
                newSIL.Tax_Group__c = theTML.Tax_Group__c;
                newSIL.Tax_Pct__c = theTML.Tax_Pct__c;
                newSIL.Tax__c = CompanyMgmt.halfUpTo2D(theTML.Tax__c);
                newSIL.TM_Line__c = theTML.Id;
                newSIL.TM__c = theTML.TM__c;
                newSIL.Service_Center__c = theTML.Service_Center__c; //AES-406
                newSIL.Bill_as_Lump_Sum__c = theTML.Bill_as_Lump_Sum__c;
                newSIL.Non_Billable__c = theTML.Non_Billable__c; //Ticket#13673
                newSIL.BOL_Manifest__c = theTML.BOL_Manifest__c;
                newSIL.Scheduled_Date__c = theTML.TM__r.Scheduled_Date__c;
                newSIL.Resource_Type_UOM__c = theTML.Resource_Type_UOM__c;
                newSIL.Resource_UOM__c = theTML.Resource_UOM__c;

                if(theTML.Category__c == 'Waste Disposal'){
                    newSIL.Cost_Method__c = theTML.Cost_Method__c;
                    newSIL.Min_Sell_Qty__c = theTML.Min_Sell_Qty__c;
                    if(String.isNotBlank(theTML.Cost_Method__c)){
                        newSIL.Unit_Weight_Vol__c = theTML.Unit_Weight_Vol__c;
                        newSIL.Container_Size__c = theTML.Container_Size__c;
                    } else {
                        theTML.Unit_Weight_Vol__c = null;
                        theTML.Container_Size__c = null;
                    }
                }
                if ((theTML.Category__c != 'Labor') || (theTML.Hour__c != theTML.Quantity__c)) {
                    newSIL.Quantity__c = theTML.Quantity__c;
                    newSIL.Unit_of_Measure__c = theTML.Unit_of_Measure__c;
                    if (newSIL.Quantity__c != 0) {
                        newSIL.Unit_Price__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(theTML.Line_Amount__c) / newSIL.Quantity__c);
                    } else {
                        newSIL.Unit_Price__c = 0;
                    }

                    newSIL.xUnit_Price__c = theTML.xUnit_Price__c;
                    if(theTML.Category__c != 'Lump Sum'){
                        newSIL.Unit_Cost__c = theTML.Unit_Cost__c;
                        newSIL.Cost_Qty__c = theTML.Cost_Qty__c;
                        newSIL.Line_Cost__c = theTML.Line_Cost__c;
                    } else {
                        newSIL.Unit_Cost__c = 0;
                        newSIL.Cost_Qty__c = 0;
                        newSIL.Line_Cost__c = 0;
                    }
                    newSIL.Pricing_Source_2__c = theTML.Pricing_Source_2__c;

                    newSIL.Line_Amount__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(newSIL.Unit_Price__c) *
                            CompanyMgmt.zeroIfNull(newSIL.Quantity__c));
                    newSIL.Tax__c = CompanyMgmt.halfUpTo2D(newSIL.Line_Amount__c * CompanyMgmt.zeroIfNull(newSIL.Tax_Pct__c) / 100);
                    newSIL.Line_Amt_Incl_Tax__c = CompanyMgmt.halfUpTo2D(newSIL.Line_Amount__c + newSIL.Tax__c);

                    //newSIL.Line_Amount__c = CompanyMgmt.halfUpTo2D(theTML.Line_Amount__c);
                    //newSIL.Line_Amt_Incl_Tax__c = CompanyMgmt.halfUpTo2D(theTML.Line_Amt_Incl_Tax__c);

                    if (newSIL.Quantity__c <> 0 || newSIL.Line_Amt_Incl_Tax__c <> 0) {
                        theNewSILList.add(newSIL);
                        uow.registerNew(newSIL, Sales_Invoice_Line__c.Sales_Invoice__c, theSI);
                    }
                } else {
                    Boolean lineAdded = false;
                    Decimal nonBilledCostQty = 0;
                    Decimal extraHrs = 0;
                    Decimal regHrs = CompanyMgmt.zeroIfNull(theTML.Regular_Hours__c);
                    Decimal otHrs = CompanyMgmt.zeroIfNull(theTML.Overtime_Hours__c);
                    Decimal dtHrs = CompanyMgmt.zeroIfNull(theTML.Premium_Hours__c);
                    Decimal totalCostQty = CompanyMgmt.zeroIfNull(theTML.Cost_Qty__c);
                    if(regHrs + otHrs + dtHrs < totalCostQty){
                        nonBilledCostQty = (totalCostQty - dtHrs - otHrs - regHrs);
                    } else if (regHrs + otHrs + dtHrs > totalCostQty){
                        extraHrs = regHrs + otHrs + dtHrs - totalCostQty;
                    }

                    Decimal dtCostQty = dtHrs;
                    Decimal otCostQty = otHrs;
                    Decimal regCostQty = regHrs;

                    if(regHrs > 0) {
                        regCostQty += nonBilledCostQty;
                    } else if(otHrs > 0) {
                        otCostQty += nonBilledCostQty;
                    } else if(dtHrs > 0) {
                        dtCostQty += nonBilledCostQty;
                    }

                    if(extraHrs > 0){
                        if(regHrs > extraHrs) {
                            regCostQty -= extraHrs;
                        } else if(otHrs > extraHrs) {
                            otCostQty -= extraHrs;
                        } else if(dtHrs > extraHrs) {
                            dtCostQty -= extraHrs;
                        }
                    }



                    if (theTML.Regular_Hours__c != null && theTML.Regular_Hours__c != 0) {
                        if (String.isNotBlank(theTML.Contract_Line__c)){
                            newSIL.Description__c = generateLineDescription(theTML.Description__c, theTML.Contract_Line__r.Customer_Item_No__c, theTML.Contract_Line__r.Customer_Description__c);
                        }
                        newSIL.Quantity__c = theTML.Regular_Hours__c;
                        newSIL.Unit_Price__c = theTML.Regular_Rate__c;
                        newSIL.xUnit_Price__c = theTML.xRegular_Rate__c;
                        newSIL.Cost_Qty__c = regCostQty;
                        newSIL.Unit_Cost__c = theTML.Unit_Cost__c;
                        newSIL.Pricing_Source_2__c = theTML.Pricing_Source_2__c;
                        //newSIL.Time_Rate_Code__c = EnumUtil.TimeRateCode.REG.Name();

                        newSIL.Line_Amount__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(newSIL.Unit_Price__c) *
                                CompanyMgmt.zeroIfNull(newSIL.Quantity__c));
                        newSIL.Tax__c = CompanyMgmt.halfUpTo2D(newSIL.Line_Amount__c * CompanyMgmt.zeroIfNull(newSIL.Tax_Pct__c) / 100);
                        newSIL.Line_Amt_Incl_Tax__c = CompanyMgmt.halfUpTo2D(newSIL.Line_Amount__c + newSIL.Tax__c);
                        newSIL.Line_Cost__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(newSIL.Unit_Cost__c) * newSIL.Cost_Qty__c);

                        if (newSIL.Quantity__c <> 0 || newSIL.Line_Amt_Incl_Tax__c <> 0) {
                            theNewSILList.add(newSIL);
                            uow.registerNew(newSIL, Sales_Invoice_Line__c.Sales_Invoice__c, theSI);
                            lineAdded = true;
                        }
                    }

                    if (theTML.Overtime_Hours__c != null && theTML.Overtime_Hours__c != 0) {
                        if (lineAdded) lineNo++;
                        newSIL = new Sales_Invoice_Line__c();
                        newSIL.Resource__c = theTML.Resource__c;
                        newSIL.Resource_Type__c = theTML.Resource_Type__c;
                        newSIL.Description__c = theTML.Description__c + '-OT';
                        //newSIL.Time_Rate_Code__c = EnumUtil.TimeRateCode.OT.name();
                        //newSIL.System_Calculated_Line__c = true;
                        if (String.isNotBlank(theTML.Contract_Line__c)){
                            String contractDescription = generateLineDescription(theTML.Description__c, theTML.Contract_Line__r.Customer_Overtime_Item_No__c, theTML.Contract_Line__r.Customer_Overtime_Description__c);
                            if(theTML.Description__c != contractDescription){
                                newSIL.Description__c = contractDescription;
                            }
                        }
                        newSIL.Category__c = theTML.Category__c;
                        newSIL.Unit_of_Measure__c = theTML.Unit_of_Measure__c;
                        newSIL.Line_No__c = lineNo;
                        newSIL.Tax_Group__c = theTML.Tax_Group__c;
                        newSIL.Tax_Pct__c = theTML.Tax_Pct__c;
                        newSIL.Tax__c = theTML.Tax__c;
                        newSIL.TM_Line__c = theTML.Id;
                        newSIL.TM__c = theTML.TM__c;
                        newSIL.Service_Center__c = theTML.Service_Center__c;
                        newSIL.Bill_as_Lump_Sum__c = theTML.Bill_as_Lump_Sum__c;
                        newSIL.Non_Billable__c = theTML.Non_Billable__c;
                        newSIL.Scheduled_Date__c = theTML.TM__r.Scheduled_Date__c;
                        newSIL.Quantity__c = theTML.Overtime_Hours__c;
                        newSIL.Unit_Price__c = theTML.Overtime_Rate__c;
                        newSIL.xUnit_Price__c = theTML.xOvertime_Rate__c;
                        newSIL.Cost_Qty__c = otCostQty;
                        newSIL.Unit_Cost__c = theTML.Unit_Cost__c;
                        newSIL.Pricing_Source_2__c = theTML.Pricing_Source_2__c;

                        newSIL.Line_Amount__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(newSIL.Unit_Price__c) *
                                CompanyMgmt.zeroIfNull(newSIL.Quantity__c));
                        newSIL.Tax__c = CompanyMgmt.halfUpTo2D(newSIL.Line_Amount__c * CompanyMgmt.zeroIfNull(newSIL.Tax_Pct__c) / 100);
                        newSIL.Line_Amt_Incl_Tax__c = CompanyMgmt.halfUpTo2D(newSIL.Line_Amount__c + newSIL.Tax__c);
                        newSIL.Line_Cost__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(newSIL.Unit_Cost__c) * newSIL.Cost_Qty__c);

                        if (newSIL.Quantity__c <> 0 || newSIL.Line_Amt_Incl_Tax__c <> 0) {
                            theNewSILList.add(newSIL);
                            uow.registerNew(newSIL, Sales_Invoice_Line__c.Sales_Invoice__c, theSI);
                            lineAdded = true;
                        }
                    }
                    if (theTML.Premium_Hours__c != null && theTML.Premium_Hours__c != 0) {
                        if (lineAdded) lineNo++;
                        newSIL = new Sales_Invoice_Line__c();
                        newSIL.Resource__c = theTML.Resource__c;
                        newSIL.Resource_Type__c = theTML.Resource_Type__c;
                        newSIL.Description__c = theTML.Description__c + '-DT';
                        //newSIL.Time_Rate_Code__c = EnumUtil.TimeRateCode.DT.name();
                        //newSIL.System_Calculated_Line__c = true;
                        if (String.isNotBlank(theTML.Contract_Line__c)){
                            String contractDescription = generateLineDescription(theTML.Description__c, theTML.Contract_Line__r.Customer_Premium_Item_No__c, theTML.Contract_Line__r.Customer_Premium_Description__c);
                            if(theTML.Description__c != contractDescription){
                                newSIL.Description__c = contractDescription;
                            }
                        }
                        newSIL.Category__c = theTML.Category__c;
                        newSIL.Unit_of_Measure__c = theTML.Unit_of_Measure__c;
                        newSIL.Line_No__c = lineNo;
                        newSIL.Tax_Group__c = theTML.Tax_Group__c;
                        newSIL.Tax_Pct__c = theTML.Tax_Pct__c;
                        newSIL.TM_Line__c = theTML.Id;
                        newSIL.TM__c = theTML.TM__c;
                        newSIL.Service_Center__c = theTML.Service_Center__c;
                        newSIL.Bill_as_Lump_Sum__c = theTML.Bill_as_Lump_Sum__c;
                        newSIL.Non_Billable__c = theTML.Non_Billable__c;
                        newSIL.Scheduled_Date__c = theTML.TM__r.Scheduled_Date__c;
                        newSIL.Quantity__c = theTML.Premium_Hours__c;
                        newSIL.Unit_Price__c = theTML.Premium_Rate__c;
                        newSIL.xUnit_Price__c = theTML.xPremium_Rate__c;
                        newSIL.Cost_Qty__c = dtCostQty;
                        newSIL.Unit_Cost__c = theTML.Unit_Cost__c;
                        newSIL.Pricing_Source_2__c = theTML.Pricing_Source_2__c;
                        newSIL.Line_Amount__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(newSIL.Unit_Price__c) *
                                CompanyMgmt.zeroIfNull(newSIL.Quantity__c));
                        newSIL.Tax__c = CompanyMgmt.halfUpTo2D(newSIL.Line_Amount__c * CompanyMgmt.zeroIfNull(newSIL.Tax_Pct__c) / 100);
                        newSIL.Line_Amt_Incl_Tax__c = CompanyMgmt.halfUpTo2D(newSIL.Line_Amount__c + newSIL.Tax__c);
                        newSIL.Line_Cost__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(newSIL.Unit_Cost__c) * newSIL.Cost_Qty__c);
                        if (newSIL.Quantity__c <> 0 || newSIL.Line_Amt_Incl_Tax__c <> 0) {
                            theNewSILList.add(newSIL);
                            uow.registerNew(newSIL, Sales_Invoice_Line__c.Sales_Invoice__c, theSI);
                        }
                    }
                }
                uow.registerRelationship(theTML, TM_Line__c.Sales_Invoice_Line__c, newSIL);
                theTML.To_Invoice__c = false;
                theTML.Invoiced__c = true;
                uow.registerDirty(theTML);
            }
        }
    }
     */

    /*Depreciated
    public void createSurchargeLine(Sales_Invoice__c theSI, List<Sales_Invoice_Line__c> theNewSILList, fflib_ISObjectUnitOfWork uow){
        if (String.isNotEmpty(theSI.Surcharge_Type__c) && (theSI.Surcharge_Type__c == 'Energy & Insurance' || theSI.Surcharge_Type__c == 'Fuel Surcharge')) {
            Sales_Invoice_Line__c surchargeLine = new Sales_Invoice_Line__c();
            Integer count = theNewSILList.size();
            Decimal displayNo = 0;
            if (theNewSILList[count - 1].Line_No__c != null) displayNo = theNewSILList[count - 1].Line_No__c;
            surchargeLine.Category__c = 'Misc. Charges And Taxes';
            surchargeLine.Line_No__c = displayNo + 1;
            surchargeLine.Tax_Group__c = 'NT';
            if (theSI.Surcharge_Type__c == 'Energy & Insurance'){
                surchargeLine.Resource__c = theCompanySetup.Default_Energy_Insurance_Resource__c;
                surchargeLine.Description__c = theCompanySetup.Default_Energy_Insurance_Resource__r.Description__c;
            }
            if (theSI.Surcharge_Type__c == 'Fuel Surcharge'){
                surchargeLine.Resource__c = theCompanySetup.Default_Fuel_Surcharge_Resource__c;
                surchargeLine.Description__c = theCompanySetup.Default_Fuel_Surcharge_Resource__r.Description__c;
            }

            Set<Id> resIds = new Set<Id>();
            Set<Id> resTypeIds = new Set<Id>();
            for(Sales_Invoice_Line__c salesInvoiceLine : theNewSILList){
                if(salesInvoiceLine.Resource_Type__c != null) resTypeIds.add(salesInvoiceLine.Resource_Type__c);
                if(salesInvoiceLine.Resource__c != null) resIds.add(salesInvoiceLine.Resource__c);
            }

            Map<Id, Resource_Type__c> resourceTypesByIds = ResourceTypesSelector.newInstance().getResourceTypesByIdsMap(resTypeIds);
            Map<Id, Resource__c> resourcesByIds = ResourcesSelector.newInstance().getResourcesByIdsMapByResIds(resIds);

            surchargeLine.Unit_of_Measure__c =
                    Test.isRunningTest() ? fflib_IDGenerator.generate(Unit_of_Measure__c.SObjectType) : CompanyMgmt.getResource(surchargeLine.Resource__c).Unit_of_Measure__c;
            surchargeLine.Quantity__c = 1;
            Decimal unitPrice = 0;
            if (theSI.Surcharge_Type__c == 'Energy & Insurance') {
                for (Sales_Invoice_Line__c sil : theNewSILList) {
                    Boolean eiExempted = false;
                    if (sil.Resource_Type__c != null && resourceTypesByIds.containsKey(sil.Resource_Type__c)) {
                        Resource_Type__c resourceType = resourceTypesByIds.get(sil.Resource_Type__c);
                        eiExempted = resourceType.E_I_Surcharge_Exempted__c;
                    }
                    if (sil.Resource__c != null && eiExempted != true && resourcesByIds.containsKey(sil.Resource__c)) {
                        Resource__c resource = resourcesByIds.get(sil.Resource__c);
                        eiExempted = resource.E_I_Surcharge_Exempted__c;
                    }
                    if(eiExempted != true) unitPrice += sil.Line_Amount__c;
                }
            } else {
                for (Sales_Invoice_Line__c sil : theNewSILList) {
                    if (sil.Category__c == 'Equipment' && sil.Resource_Type__r.Fuel_Fired_Equipment__c) {
                        if (sil.Bill_as_Lump_Sum__c == true || sil.Non_Billable__c == true) {
                            unitPrice += CompanyMgmt.zeroIfNull(sil.Quantity__c) * CompanyMgmt.zeroIfNull(sil.xUnit_Price__c);
                        } else {
                            unitPrice += sil.Line_Amount__c;
                        }
                    }
                }
            }
            unitPrice = theSI.Surcharge_Pct__c > 0 ? (unitPrice * theSI.Surcharge_Pct__c / 100).setScale(2) : 0;
            surchargeLine.Unit_Price__c = unitPrice;
            surchargeLine.Line_Amount__c = unitPrice;
            surchargeLine.Line_Amt_Incl_Tax__c = unitPrice;
            surchargeLine.System_Calculated_Line__c = true;
            uow.registerNew(surchargeLine, Sales_Invoice_Line__c.Sales_Invoice__c, theSI);
        }
    }
     */

    /*
    private String generateLineDescription(String lineDescription, String customerItemNo, String customerDescription){
        String description = lineDescription;
        if(String.isNotBlank(customerItemNo) && String.isNotBlank(customerDescription)){
            description = customerItemNo + ' - ' + customerDescription;
        } else if (String.isNotBlank(customerItemNo) && String.isNotBlank(lineDescription)){
            description = lineDescription + ' - ' + customerItemNo;
        } else if (String.isNotBlank(customerDescription)){
            description = customerDescription;
        }
        return description;
    }
     */

    //job task <<
    public ACVTMWrapper createTMFromSalesOrder(Id salesOrderId, List<ACVSalesOrderJobTaskWrapper> salesOrderJobTaskWrappers) {
        List<Sales_Order__c> salesOrders = SalesOrdersSelector.newInstance().selectById(new Set<Id>{ salesOrderId });
        Sales_Order__c salesOrder = salesOrders[0];
        //85892
        // if(salesOrder.Bill_to_Customer_No__r.Sage_Customer_No__c !=null && CustomerDetailsService.getCustomerDetails(salesOrder.Bill_to_Customer_No__r.Sage_Customer_No__c) == 'T')
        // {
        //     throw new DataException('Salesforce cannot send National Account, MSG, or Retail Account customers to EQAI. Please create Work Order Quote/Work Order in EQAI directly.');  
        // }
        Savepoint sp = Database.setSavepoint();
        try {


            List<TM__c> tms = [SELECT Id, Sales_Order__c FROM TM__c WHERE Sales_Order__c = :salesOrder.Id];
            //Task#78375 Task#78376 Bug#84091
            if (salesOrder.Bill_to_Customer_No__r.Customer_Status__c == 'Inactive') {
                List<Sales_Order__c> salesOdrs = [select id,Bill_to_Customer_No__c,Document_Type__c  from Sales_Order__c where Document_Type__c = 'Sales Order' and Bill_to_Customer_No__c = :salesOrder.Bill_to_Customer_No__c];
                if(salesOdrs!=null && salesOdrs.size()>1){
                    throw new DataException('New T&M cannot be created because bill-to customer is inactive!'); 
                }
                else if(salesOdrs!=null && salesOdrs.size()==1){
                    if (Integer.valueOf(CompanyMgmt.zeroIfNull(theCompanySetup.Max_T_M_for_not_Approved_Customer__c)) < (tms.size() + 1)) {
                        throw new DataException('This customer has exceeded the number of Emergency T&Ms allowed for unapproved customers. Please contact Accounts Receivable.');
                    }
                }
            }
            if ((System.Label.Release_Flag =='true' && (String.isBlank(salesOrder.Bill_to_Customer_No__r.AccountNumber) || String.isBlank(salesOrder.Bill_to_Customer_No__r.Sage_Customer_No__c)) && System.Label.Account_Number_Validation =='false') ||(String.isBlank(salesOrder.Bill_to_Customer_No__r.Sage_Customer_No__c) && System.Label.Account_Number_Validation =='true')) {
                List<Sales_Order__c> salesOdrs = [select id,Bill_to_Customer_No__c,Document_Type__c  from Sales_Order__c where Document_Type__c = 'Sales Order' and Bill_to_Customer_No__c = :salesOrder.Bill_to_Customer_No__c];
                if(salesOdrs!=null && salesOdrs.size()>1){
                    throw new DataException('New T&M cannot be created because bill-to customer number is missing'); 
                }
                else if(salesOdrs!=null && salesOdrs.size()==1){
                    if (Integer.valueOf(CompanyMgmt.zeroIfNull(theCompanySetup.Max_T_M_for_not_Approved_Customer__c)) < (tms.size() + 1)) {
                        throw new DataException('This customer has exceeded the number of Emergency T&Ms allowed for unapproved customers. Please contact Accounts Receivable.');
                    }
                }
            }
            else if(System.Label.Release_Flag =='false' && salesOrder.Bill_to_Customer_No__r.Emergency__c == true && String.isBlank(salesOrder.Bill_to_Customer_No__r.AccountNumber))
            {
                if (Integer.valueOf(CompanyMgmt.zeroIfNull(theCompanySetup.Max_T_M_for_not_Approved_Customer__c)) < (tms.size() + 1)) {
                    throw new DataException('This customer has exceeded the number of Emergency T&Ms allowed for unapproved customers. Please contact Accounts Receivable.');
                } 
            }

            if (salesOrder.Bill_to_Customer_No__r.Emergency__c == false && String.isBlank(salesOrder.Bill_to_Customer_No__r.Sage_Customer_No__c)) {
                throw new DataException('This customer is not approved. Please contact Accounts Receivable.');
            }

            //Ticket#20749
            if(salesOrder.Contract__c != null) {
                if (salesOrder.Contract__r.Status != 'Activated') {
                    throw new DataException('Contract associated with sales order is not activated.');
                }
                if (Date.today() > salesOrder.Contract__r.EndDate){
                    throw new DataException('Contract expired on ' + salesOrder.Contract__r.EndDate);
                }
            }

            TM__c tm = new TM__c();
            tm.Bill_to_Customer__c = salesOrder.Bill_to_Customer_No__c;
            tm.Contact__c = salesOrder.Bill_to_Contact__c;
            tm.Site_Contact_2__c = salesOrder.Site_Contact_2__c;
            tm.Sales_Order__c = salesOrder.Id;
            tm.Sales_Order__r = new Sales_Order__c(Id=salesOrder.Id, Manifest_And_Profile__c = salesOrder.Manifest_And_Profile__c); //for manifest fee line creation
            tm.Project_Coordinator__c = salesOrder.Project_Coordinator__c;
            tm.Account_Executive__c = salesOrder.Account_Executives__c;
            tm.Prevailing_Wage_Job__c = salesOrder.Prevailing_Wage_Job__c;
            tm.Certified_PW_Job__c = salesOrder.Certified_PW_Job__c;
            tm.Subsidiary_Company__c = salesOrder.Subsidiary_Company__c;
            tm.Service_Center__c = salesOrder.Service_Center__c;
            tm.Customer_PO_No__c = salesOrder.Customer_PO_No__c;
            tm.Day_of_Job__c = tms.size() + 1;
            tm.Description__c = 'Day of Job ' + tm.Day_of_Job__c.intValue() + ' ' + salesOrder.Bill_to_Customer_No__r.Name;
            tm.Contract__c = salesOrder.Contract__c;
            tm.Status__c = 'Open';
            tm.Alternate_Site_Address__c = salesOrder.Alternate_Site_Address__c;
            tm.Site_Name__c = salesOrder.Site_Name__c;
            tm.Site_Street__c = salesOrder.Site_Street__c;
            tm.Site_City__c = salesOrder.Site_City__c;
            tm.Site_State__c = salesOrder.Site_State__c;
            tm.Site_Postal_Code__c = salesOrder.Site_Postal_Code__c;
            tm.Site_Country__c = salesOrder.Site_Country__c;
            tm.Site_Contact__c = salesOrder.Site_Contact__c;
            tm.Site_Phone_No__c = salesOrder.Site_Phone_No__c;
            tm.Site_Email_Address__c = salesOrder.Site_Email_Address__c;
            tm.Tax_Liable__c = salesOrder.Tax_Liable__c;
            tm.Tax_Area__c = salesOrder.Tax_Area__c;
            tm.Site_Scope__c = salesOrder.Site_Scope__c;
            tm.From_Sales_Quote__c = salesOrder.From_Sales_Quote__c;
            tm.Print_Site_Name__c = salesOrder.Print_Site_Name__c;
            tm.Billing_Instructions__c = salesOrder.Billing_Instructions__c;
            tm.Internal_Comments__c = salesOrder.Internal_Comments__c;
            tm.Customer_Billing_Instructions__c = salesOrder.Customer_Billing_Instructions__c;
            tm.Sales_Order_Instructions__c = salesOrder.Sales_Order_Instructions__c;
            tm.Mobile_Email__c = salesOrder.Mobile_Email__c;
            tm.Rate_Sheet__c = salesOrder.Rate_Sheet__c;
            insert tm;

            //create TM lines
            Integer nextJobTaskLineNo = 1;
            Integer nextTMLineNo = 1;
            List<ACVTMJobTaskWrapper> tmJobTaskWrappers = new List<ACVTMJobTaskWrapper>();

            for (ACVSalesOrderJobTaskWrapper salesOrderJobTaskWrapper : salesOrderJobTaskWrappers) {

                ACVTMJobTaskWrapper tmJobTaskWrapper = new ACVTMJobTaskWrapper();
                tmJobTaskWrapper.JobTask = createTMJobTaskFromSalesOrderJobTask(tm, salesOrderJobTaskWrapper.JobTask, nextJobTaskLineNo);
                tmJobTaskWrappers.add(tmJobTaskWrapper);

                if (salesOrderJobTaskWrapper.SalesLines.size() > 0) {
                    createTMLinesFromSalesOrder(salesOrder, salesOrderJobTaskWrapper, tm, tmJobTaskWrapper, nextTMLineNo);
                    nextTMLineNo = tmJobTaskWrapper.NextTMLineNo;
                }
                nextJobTaskLineNo++;
            }

            //ticket 19130 05.13.2023 <<
            calculateChildResources(tm, tmJobTaskWrappers);
            //ticket 19130 05.13.2023 >>

            ACVTMWrapper tmWrapper = new ACVTMWrapper(tm, tmJobTaskWrappers);
            return tmWrapper;
        } catch (exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    //ticket 19130 <<
    //public List<ACVTMJobTaskWrapper> createTMJobTasksFromSalesOrder(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> salesOrderJobTaskWrappers, TM__c tm, Integer nextJobTaskLineNo, Integer nextTMLineNo) {
    public List<ACVTMJobTaskWrapper> createTMJobTasksFromSalesOrder(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> salesOrderJobTaskWrappers, TM__c tm, List<ACVTMJobTaskWrapper> tmJobTaskWrappers, Integer nextJobTaskLineNo, Integer nextTMLineNo) {
    //ticket 19130 >>
        Savepoint sp = Database.setSavepoint();
        try {
            //ticket 19130 <<
            //List<ACVTMJobTaskWrapper> tmJobTaskWrappers = new List<ACVTMJobTaskWrapper>();
            //ticket 19130 >>
            for (ACVSalesOrderJobTaskWrapper salesOrderJobTaskWrapper : salesOrderJobTaskWrappers) {
                nextJobTaskLineNo++;

                //ticket 19130 <<
                //ACVTMJobTaskWrapper tmJobTaskWrapper = new ACVTMJobTaskWrapper();
                //tmJobTaskWrapper.JobTask = createTMJobTaskFromSalesOrderJobTask(tm, salesOrderJobTaskWrapper.JobTask, nextJobTaskLineNo);
                ACVTMJobTaskWrapper tmJobTaskWrapper;
                Boolean jobTaskExists = false;
                for (Integer j = 0; j < tmJobTaskWrappers.size(); j++) {
                    if (tmJobTaskWrappers[j].JobTask.Sales_Order_Job_Task__c == salesOrderJobTaskWrapper.JobTask.Id) {
                        tmJobTaskWrapper = tmJobTaskWrappers[j];
                        jobTaskExists = true;
                        break;
                    }
                }
                if (!jobTaskExists) {
                    tmJobTaskWrapper = new ACVTMJobTaskWrapper();
                    tmJobTaskWrapper.JobTask = createTMJobTaskFromSalesOrderJobTask(tm, salesOrderJobTaskWrapper.JobTask, nextJobTaskLineNo);
                }
                //ticket 19130 >>

                createTMLinesFromSalesOrder(salesOrder, salesOrderJobTaskWrapper, tm, tmJobTaskWrapper, nextTMLineNo);
                tmJobTaskWrappers.add(tmJobTaskWrapper);

                nextTMLineNo = tmJobTaskWrapper.NextTMLineNo;
                nextJobTaskLineNo = tmJobTaskWrapper.JobTask.Line_No__c.intValue();
            }

            //ticket 19130 05.13.2023 <<
            calculateChildResources(tm, tmJobTaskWrappers);
            //ticket 19130 05.13.2023 >>

            return tmJobTaskWrappers;
        } catch (exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    public TM_Job_Task__c createTMJobTaskFromSalesOrderJobTask(TM__c tm, Sales_Order_Job_Task__c salesOrderJobTask, Integer nextJobTaskLineNo) {
        TM_Job_Task__c tmJobTask = new TM_Job_Task__c();
        tmJobTask.Id = null;
        tmJobTask.TM__c = tm.Id;
        tmJobTask.Name = salesOrderJobTask.Name;
        tmJobTask.Billing_Type__c = salesOrderJobTask.Billing_Type__c;
        //tmJobTask.Fixed_Price__c = salesOrderJobTask.Fixed_Price__c;
        tmJobTask.Line_No__c = nextJobTaskLineNo;
        tmJobTask.Job_Task_Template__c = salesOrderJobTask.Job_Task_Template__c;
        tmJobTask.Sales_Order_Job_Task__c = salesOrderJobTask.Id; //link TM job task with sales order job task
        tmJobTask.Sales_Order_Job_Task__r = salesOrderJobTask;
        Formula.recalculateFormulas(new List<TM_Job_Task__c> { tmJobTask }); //calculate Task_No__c
        return tmJobTask;
    }

    public void createTMLinesFromSalesOrder(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper salesOrderJobTaskWrapper, TM__c tm, ACVTMJobTaskWrapper tmJobTaskWrapper, Integer nextTMLineNo) {
        //ticket 19130 <<
        //Map<Id, TM_Line__c> mapTMLinesBySalesLineId = new Map<Id, TM_Line__c>();
        Map<Integer, Sales_Line__c> mapSalesLinesByTMLineNo = new Map<Integer, Sales_Line__c>();
        Map<Integer, List<TM_Line__c>> mapTMLinesBySalesLineNo = new Map<Integer, List<TM_Line__c>>();

        //find existing child lines on the TM
        Map<Id, TM_Line__c> mapExistingChildLinesByResourceId = new Map<Id, TM_Line__c>();
        for (TM_Line__c tmLine : tmJobTaskWrapper.TMLines) {
            if (tmLine.Is_Child_Resource__c == true && tmLine.Invoiced__c != true) {
                Id resourceId;
                if (tmLine.Category__c == 'Labor' || tmLine.Category__c == 'Equipment' || tmLine.Category__c == 'Bundled') {
                    resourceId = tmLine.Resource_Type__c;
                }
                else {
                    resourceId = tmLine.Resource__c;
                }
                if (!mapExistingChildLinesByResourceId.containsKey(resourceId)) {
                    mapExistingChildLinesByResourceId.put(resourceId, tmLine);
                }
            }
        }

        //add existing TM Lines to the map by sales line no.
        for (Sales_Line__c salesLine : salesOrderJobTaskWrapper.SalesLines) {
            if (salesLine.Is_Child_Resource__c == true) {
                Id resourceId;
                if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment' || salesLine.Category__c == 'Bundled') {
                    resourceId = salesLine.Resource_Type__c;
                }
                else {
                    resourceId = salesLine.Resource__c;
                }
                if (mapExistingChildLinesByResourceId.containsKey(resourceId)) {
                    TM_Line__c tmLine = mapExistingChildLinesByResourceId.get(resourceId);
                    List<TM_Line__c> tmLines;
                    if (mapTMLinesBySalesLineNo.containsKey(salesLine.Line_No__c.intValue())) {
                        tmLines = mapTMLinesBySalesLineNo.get(salesLine.Line_No__c.intValue());
                    }
                    else {
                        tmLines = new List<TM_Line__c>();
                        mapTMLinesBySalesLineNo.put(salesLine.Line_No__c.intValue(), tmLines);
                    }
                    tmLines.add(tmLine);
                }
            }
        }
        //ticket 19130 >>

        for (Sales_Line__c salesLine : salesOrderJobTaskWrapper.SalesLines) {
            //ticket 19130 <<
            if (mapTMLinesBySalesLineNo.containsKey(salesLine.Line_No__c.intValue())) {
                continue;
            }

            //ticket 19861 <<
            if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment' || salesLine.Category__c == 'Bundled') {
                if (salesLine.Resource_Type__r != null && salesLine.Resource_Type__r.Blocked__c == true) {
                    throw new DataException('Resource type "' + salesLine.Resource_Type__r.Name + '" is blocked.');
                }
            }
            else {
                if (salesLine.Resource__r != null && salesLine.Resource__r.Blocked__c == true) {
                    throw new DataException('Resource "' + salesLine.Resource__r.Name + '" is blocked.');
                }
            }
            //ticket 29861 >>

            //ticket 19130 >>
            if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment') {
                Integer lineQty = salesLine.Quantity__c.intValue();
                if (lineQty == 0) {
                    lineQty = 1; //child resource lines may have qty 0
                }

                for (Integer j = 0; j < lineQty; j++) {
                    TM_Line__c tmLine = new TM_Line__c();
                    tmLine.Line_No__c = nextTMLineNo;
                    tmLine.TM__c = tm.Id;
                    tmLine.Service_Center__c = salesOrder.Service_Center__c;
                    tmLine.Service_Center__r = salesOrder.Service_Center__r;
                    tmLine.Category__c = salesLine.Category__c;
                    tmLine.Resource_Type__c = salesLine.Resource_Type__c;
                    tmLine.Resource_Type__r = salesLine.Resource_Type__r;
                    tmLine.Resource__c = salesLine.Resource__c;
                    tmLine.Resource__r = salesLine.Resource__r;
                   
                    
                    if (salesLine.Resource__r != null) {
                        tmLine.Resource_Name__c = salesLine.Resource__r.Name;
                    }
                    tmLine.Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                    tmLine.Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                    if (salesLine.Unit_of_Measure__r.Hours_UOM__c != true && salesLine.Category__c == 'Labor') {
                        tmLine.Quantity__c = 1;
                    }
                    else {
                        tmLine.Quantity__c = 0;
                    }
                    tmLine.Description__c = salesLine.Description__c;
                    tmLine.Unit_Price__c = salesLine.Unit_Price__c;
                    tmLine.xUnit_Price__c = salesLine.xUnit_Price__c;
                    tmLine.Bill_as_Lump_Sum__c = salesLine.Bill_as_Lump_Sum__c;
                    tmLine.Non_Billable__c = salesLine.Non_Billable__c;
                    tmLine.Tax_Group__c = salesLine.Tax_Group__c;
                    tmLine.Sales_Line__c = salesLine.Id;
                    tmLine.Quote_Line__c = salesLine.Quote_Line__c;
                    //ticket 19535 <<
                    tmLine.Sales_Line__r = new Sales_Line__c(Id = salesLine.Id, Sales_Order__c = salesOrder.Id);
                    tmLine.Quote_Line__r = salesLine.Quote_Line__r;
                    //ticket 19535 >>

                    //Ticket#19511 >>
                    if(String.isNotBlank(salesLine.Contract_Line__c)) {
                        tmLine.Contract_Line__c = salesLine.Contract_Line__c;
                        tmLine.Contract_Line__r = new Contract_Line__c(Id = salesLine.Contract_Line__c, Contract__c = salesOrder.Contract__c);
                    }
                    //Ticket#19511 >>

                    tmLine.TM_Job_Task__c = tmJobTaskWrapper.JobTask.Id;
                    tmLine.TM_Job_Task__r = new TM_Job_Task__c(Id = tmJobTaskWrapper.JobTask.Id, Line_No__c = tmJobTaskWrapper.JobTask.Line_No__c);
                    tmLine.Sales_Bundle_Line__c = salesLine.Bundle_Line__c;
                    tmLine.Sales_Bundle_Line__r = salesLine.Bundle_Line__r;
                    //ticket 19130 <<
                    /*
                    tmLine.Sales_Parent_Line__c = salesLine.Parent_Line__c;
                    tmLine.Sales_Parent_Line__r = salesLine.Parent_Line__r;

                    if (j < lineQty - 1) {
                        tmLine.Wizard_Question_Answered__c = true; //only enable wizard for the last line
                    }
                    else {
                        tmLine.Wizard_Question_Parent_Quantity__c = lineQty;
                    }
                    */
                    tmLine.Is_Child_Resource__c = salesLine.Is_Child_Resource__c;
                    //ticket 19130 >>

                    tmJobTaskWrapper.TMLines.add(tmLine);
                    nextTMLineNo++;

                    //ticket 19130 <<
                    //mapTMLinesBySalesLineId.put(tmLine.Sales_Line__c, tmLine);
                    mapSalesLinesByTMLineNo.put(tmLine.Line_No__c.intValue(), salesLine);
                    List<TM_Line__c> tmLines;
                    if (mapTMLinesBySalesLineNo.containsKey(salesLine.Line_No__c.intValue())) {
                        tmLines = mapTMLinesBySalesLineNo.get(salesLine.Line_No__c.intValue());
                    }
                    else {
                        tmLines = new List<TM_Line__c>();
                        mapTMLinesBySalesLineNo.put(salesLine.Line_No__c.intValue(), tmLines);
                    }
                    tmLines.add(tmLine);
                    //ticket 19130 >>
                }
            } else {
                if (salesLine.Category__c == 'Misc. Charges And Taxes') {
                    if (salesLine.Resource__c == theCompanySetup.Default_Energy_Insurance_Resource__c
                            || salesLine.Resource__c == theCompanySetup.Default_Fuel_Surcharge_Resource__c
                            || (salesOrder.Sales_Order_Type__r.Emergency_Response__c && salesLine.Resource__c == theCompanySetup.Default_Safety_Plan_Resource__c)) {
                        continue;
                    }
                }

                if (salesLine.Category__c == 'Bundled') {
                    continue;
                }

                TM_Line__c tmLine = new TM_Line__c();
                tmLine.Line_No__c = nextTMLineNo;
                tmLine.TM__c = tm.Id;
                tmLine.Category__c = salesLine.Category__c;
                tmLine.Description__c = salesLine.Description__c;
                tmLine.Resource_Type__c = salesLine.Resource_Type__c;
                tmLine.Resource_Type__r = salesLine.Resource_Type__r;
                tmLine.Approval_Id__c = salesLine.Approval_Id__c;
                tmLine.Profile_Id__c = salesLine.Profile_Id__c;
                tmLine.EQAI_Bill_Unit_Code__c = salesLine.EQAI_UOM__c;
                if (tmLine.Resource_Type__r != null) {
                    tmLine.Description__c = salesLine.Resource_Type__r.Name;
                }
                tmLine.Quantity__c = CompanyMgmt.zeroIfNull(salesLine.Quantity__c);
                tmLine.Resource__c = salesLine.Resource__c;
                tmLine.Resource__r = salesLine.Resource__r;

                if (tmLine.Category__c == 'Subcontractors' && tmLine.Resource__c == null) {
                    tmLine.Resource__c = theCompanySetup.Default_Subcontractor_Resource__c;
                    tmLine.Resource__r = theCompanySetup.Default_Subcontractor_Resource__r;
                }
                if (tmLine.Category__c == 'Subcontractors') {
                    tmLine.Unit_Price__c = salesLine.Unit_Price__c;
                    tmLine.xUnit_Price__c = salesLine.Unit_Price__c;
                    tmLine.Unit_Cost__c = salesLine.Unit_Cost__c;
                    tmLine.Markup_Option__c = salesLine.Markup_Option__c;
                    tmLine.Markup__c = salesLine.Markup__c;
                }

                tmLine.Bill_as_Lump_Sum__c = salesLine.Bill_as_Lump_Sum__c;
                tmLine.Non_Billable__c = salesLine.Non_Billable__c;
                tmLine.Tax_Group__c = salesLine.Tax_Group__c;
                tmLine.Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                tmLine.Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                tmLine.Resource_UOM__c = salesLine.Resource_UOM__c;
                tmLine.Resource_UOM__r = salesLine.Resource_UOM__r;
                tmLine.Resource_Type_UOM__c = salesLine.Resource_Type_UOM__c;
                tmLine.Resource_Type_UOM__r = salesLine.Resource_Type_UOM__r;
                /*Waste001
                tmLine.Cost_Method__c = salesLine.Cost_Method__c;
                tmLine.Unit_Weight_Vol__c = salesLine.Unit_Weight_Vol__c;
                tmLine.Unit_Weight_Vol__r = salesLine.Unit_Weight_Vol__r;
                tmLine.Container_Size__c = salesLine.Container_Size__c;
                tmLine.Container_Size__r = salesLine.Container_Size__r;
                 */
                tmLine.Cost_Method__c = null;
                tmLine.Unit_Weight_Vol__c = null;
                tmLine.Container_Size__c = null;

                tmLine.Facility__c = salesLine.Facility__c;
                tmLine.Facility__r = salesLine.Facility__r;
                tmLine.Sales_Line__c = salesLine.Id;
                //ticket 19535 <<
                tmLine.Quote_Line__c = salesLine.Quote_Line__c;
                tmLine.Sales_Line__r = new Sales_Line__c(Id = salesLine.Id, Sales_Order__c = salesOrder.Id);
                tmLine.Quote_Line__r = salesLine.Quote_Line__r;
                //ticket 19535 >>
                if(String.isNotBlank(salesLine.Contract_Line__c)) {
                    tmLine.Contract_Line__c = salesLine.Contract_Line__c;
                    tmLine.Contract_Line__r = new Contract_Line__c(Id = salesLine.Contract_Line__c, Contract__c = salesOrder.Contract__c);
                }
                tmLine.TM_Job_Task__c = tmJobTaskWrapper.JobTask.Id;
                tmLine.TM_Job_Task__r = new TM_Job_Task__c(Id = tmJobTaskWrapper.JobTask.Id, Line_No__c = tmJobTaskWrapper.JobTask.Line_No__c);
                tmLine.Sales_Bundle_Line__c = salesLine.Bundle_Line__c;
                tmLine.Sales_Bundle_Line__r = salesLine.Bundle_Line__r;

                //ticket 19130 <<
                /*
                tmLine.Sales_Parent_Line__c = salesLine.Parent_Line__c;
                tmLine.Sales_Parent_Line__r = salesLine.Parent_Line__r;
                */
                tmLine.Is_Child_Resource__c = salesLine.Is_Child_Resource__c;
                //ticket 19130 >>
                tmJobTaskWrapper.TMLines.add(tmLine);
                nextTMLineNo++;

                //ticket 19130 <<
                //mapTMLinesBySalesLineId.put(tmLine.Sales_Line__c, tmLine);
                mapSalesLinesByTMLineNo.put(tmLine.Line_No__c.intValue(), salesLine);
                mapTMLinesBySalesLineNo.put(salesLine.Line_No__c.intValue(), new List<TM_Line__c>{ tmLine });
                //ticket 19130 >>
            }
        }

        //link parent-child
        //ticket 19130 <<
        /*
        for (TM_Line__c tmLine : tmJobTaskWrapper.TMLines) {
            if (tmLine.Sales_Parent_Line__c != null) {
                if (mapTMLinesBySalesLineId.containsKey(tmLine.Sales_Parent_Line__c)) {

                    TM_Line__c parentTMLine = mapTMLinesBySalesLineId.get(tmLine.Sales_Parent_Line__c);
                    tmLine.Parent_Line__c = parentTMLine.Id;
                    tmLine.Parent_Line__r = new TM_Line__c(Id = parentTMLine.Id, Line_No__c = parentTMLine.Line_No__c);
                }
            }
        }

        */
        //ticket 19130 >>

        tmJobTaskWrapper.NextTMLineNo = nextTMLineNo;
    }

    private Integer getNextTMLineNo(List<ACVTMJobTaskWrapper> jobTaskWrappers) {
        Integer nextTMLineNo = 0;
        for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                if (nextTMLineNo < tmLine.Line_No__c) {
                    nextTMLineNo = tmLine.Line_No__c.intValue();
                }
            }
        }
        nextTMLineNo++;
        return nextTMLineNo;
    }
    //job task >>



    //ticket 19130 05.12.2023 <<
    public void calculateChildResources(TM__c tm, List<ACVTMJobTaskWrapper> jobTaskWrappers) {
        TMLLinesService.initStaticVariables(tm, jobTaskWrappers);
        Integer nextTMLineNo = getNextTMLineNo(jobTaskWrappers);

        Set<Id> tmLineIds = new Set<Id>();
        Map<Id, ACVSalesOrderJobTaskWrapper> mapSalesOrderJobTaskWrappersById = new Map<Id, ACVSalesOrderJobTaskWrapper>();
        for (Integer i = 0; i < jobTaskWrappers.size(); i++) {
            ACVTMJobTaskWrapper jobTaskWrapper = jobTaskWrappers[i];
            for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                if (tmLine.Id != null) {
                    tmLineIds.add(tmLine.Id);
                }
            }

            ACVSalesOrderJobTaskWrapper salesOrderJobTaskWrapper = new ACVSalesOrderJobTaskWrapper();
            salesOrderJobTaskWrapper.JobTask = new Sales_Order_Job_Task__c(Id = jobTaskWrapper.JobTask.Sales_Order_Job_Task__c);
            mapSalesOrderJobTaskWrappersById.put(salesOrderJobTaskWrapper.JobTask.Id, salesOrderJobTaskWrapper);
        }

        for (Sales_Line__c salesLine : [SELECT Id, Sales_Order_Job_Task__c, Category__c, Resource_Type__c, Resource_Type__r.Name, Resource__c, Resource__r.Name, Description__c,
                Sales_Order__r.Service_Center__c, Sales_Order__r.Service_Center__r.Name,
        (SELECT Id, Child_Line__c, Child_Line__r.Category__c, Child_Line__r.Resource_Type__c, Child_Line__r.Resource_Type__r.Name,
                Child_Line__r.Resource__c, Child_Line__r.Resource__r.Name, Child_Line__r.Description__c,
                Child_Line__r.Unit_of_Measure__c, Child_Line__r.Unit_of_Measure__r.Name,
                Child_Line__r.Sales_Order__r.Service_Center__c, Child_Line__r.Sales_Order__r.Service_Center__r.Name
        FROM Sales_Child_Lines__r)
        FROM Sales_Line__c WHERE Sales_Order_Job_Task__c IN :mapSalesOrderJobTaskWrappersById.keySet()]) {
            ACVSalesOrderJobTaskWrapper salesOrderJobTaskWrapper = mapSalesOrderJobTaskWrappersById.get(salesLine.Sales_Order_Job_Task__c);
            salesOrderJobTaskWrapper.SalesLines.add(salesLine);
        }

        for (Integer i = 0; i < jobTaskWrappers.size(); i++) {
            ACVTMJobTaskWrapper jobTaskWrapper = jobTaskWrappers[i];

            //set Wizard_Question_Answered__c
            Map<Integer, TM_Line__c> mapTMLinesByLineNo = new Map<Integer, TM_Line__c>();
            for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                mapTMLinesByLineNo.put(tmLine.Line_No__c.intValue(), tmLine);
            }
            for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                if (tmLine.Wizard_Question_Answered__c != true) {
                    if (tmLine.TM_Child_Lines__r != null) {
                        for (TM_Parent_Child_Relation__c relation : tmLine.TM_Child_Lines__r) {
                            if (relation.Child_Line__r != null) {
                                if (mapTMLinesByLineNo.containsKey(relation.Child_Line__r.Line_No__c.intValue())) {
                                    mapTMLinesByLineNo.get(relation.Child_Line__r.Line_No__c.intValue()).Wizard_Question_Answered__c = false;
                                }
                            }
                        }
                    }
                }
            }

            ACVSalesOrderJobTaskWrapper salesOrderJobTaskWrapper = mapSalesOrderJobTaskWrappersById.get(jobTaskWrapper.JobTask.Sales_Order_Job_Task__c);
            Map<Id, Sales_Line__c> mapSalesLinesById = new Map<Id, Sales_Line__c>();
            Map<Id, Sales_Line__c> mapSalesLinesByResourceId = new Map<Id, Sales_Line__c>();
            for (Sales_Line__c salesLine : salesOrderJobTaskWrapper.SalesLines) {
                mapSalesLinesById.put(salesLine.Id, salesLine);

                Id resourceId = getSalesLineResourceTypeIdOrResourceId(salesLine);
                if (!mapSalesLinesByResourceId.containsKey(resourceId)) {
                    mapSalesLinesByResourceId.put(resourceId, salesLine);
                }
            }

            Map<Id, TM_Line__c> mapTMLinesByResourceId = new Map<Id, TM_Line__c>();
            for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                Id resourceId = getTMLineResourceTypeIdOrResourceId(tmLine);
                mapTMLinesByResourceId.put(resourceId, tmLine);
            }

            for (Integer j = 0; j < jobTaskWrapper.TMLines.size(); j++) {
                TM_Line__c tmLine = jobTaskWrapper.TMLines[j];

                if (tmLine.Wizard_Question_Answered__c == true) continue;

                //track relationships at TM level, SQ/SO level, Resource level
                Map<Id, TM_Parent_Child_Relation__c> mapTMParentRelationsByResourceId = new Map<Id, TM_Parent_Child_Relation__c>();

                //insert TM level parent-child relationship
                if (tmLine.TM_Child_Lines__r != null) {
                    for (TM_Parent_Child_Relation__c relation : tmLine.TM_Child_Lines__r) {
                        if (relation.Child_Line__r != null) {
                            Id childResourceId = getTMLineResourceTypeIdOrResourceId(relation.Child_Line__r);
                            mapTMParentRelationsByResourceId.put(childResourceId, relation);
                        }
                    }
                }

                //insert SQ/SO level parent-child relationship
                Sales_Line__c salesLine;
                if (tmLine.Sales_Line__c != null) {
                    salesLine = mapSalesLinesById.get(tmLine.Sales_Line__c);
                } else {
                    Id resourceId = getTMLineResourceTypeIdOrResourceId(tmLine);
                    salesLine = mapSalesLinesByResourceId.get(resourceId);
                }

                if (salesLine != null && salesLine.Sales_Child_Lines__r != null) {
                    tmLine.Sales_Line__c = salesLine.Id;
                    for (Sales_Parent_Child_Relation__c salesParentChildRelation : salesLine.Sales_Child_Lines__r) {
                        if (salesParentChildRelation.Child_Line__r != null) {
                            Sales_Line__c childSalesLine = salesParentChildRelation.Child_Line__r;
                            Id childResourceId = getSalesLineResourceTypeIdOrResourceId(childSalesLine);

                            if (!mapTMParentRelationsByResourceId.containsKey(childResourceId)) { //relationship does not exist
                                TM_Line__c childTMLine;
                                //check if the resource exists as a TM Line
                                if (mapTMLinesByResourceId.containsKey(childResourceId)) {
                                    childTMLine = mapTMLinesByResourceId.get(childResourceId);
                                } else {
                                    childTMLine = new TM_Line__c();
                                    childTMLine.Line_No__c = nextTMLineNo;
                                    childTMLine.TM__c = tm.Id;
                                    childTMLine.TM_Job_Task__c = jobTaskWrapper.JobTask.Id;
                                    childTMLine.TM_Job_Task__r = jobTaskWrapper.JobTask;
                                    childTMLine.Category__c = childSalesLine.Category__c;
                                    childTMLine.Resource_Type__c = childSalesLine.Resource_Type__c;
                                    childTMLine.Resource_Type__r = childSalesLine.Resource_Type__r;
                                    childTMLine.Resource__c = childSalesLine.Resource__c;
                                    childTMLine.Resource__r = childSalesLine.Resource__r;
                                    childTMLine.Unit_of_Measure__c = childSalesLine.Unit_of_Measure__c;
                                    childTMLine.Unit_of_Measure__r = childSalesLine.Unit_of_Measure__r;
                                    childTMLine.Description__c = childSalesLine.Description__c;
                                    childTMLine.Quantity__c = 0;
                                    if (childTMLine.Category__c == 'Labor' || childTMLine.Category__c == 'Equipment') {
                                        childTMLine.Service_Center__c = salesLine.Sales_Order__r.Service_Center__c;
                                        childTMLine.Service_Center__r = salesLine.Sales_Order__r.Service_Center__r;
                                    }
                                    childTMLine.Is_Child_Resource__c = true;
                                    childTMLine.Wizard_Question_Answered__c = false;
                                    childTMLine.Sales_Line__c = childSalesLine.Id;

                                    mapTMLinesByResourceId.put(childResourceId, childTMLine);
                                    jobTaskWrapper.TMLines.add(childTMLine); //include the new line. The new line will also be picked up for the parent-child relationship
                                    nextTMLineNo++;
                                }

                                //create relationship
                                TM_Parent_Child_Relation__c relation = new TM_Parent_Child_Relation__c();
                                relation.Parent_Line__c = tmLine.Id;
                                relation.Parent_Line__r = tmLine;
                                relation.Child_Line__c = childTMLine.Id;
                                relation.Child_Line__r = childTMLine;
                                mapTMParentRelationsByResourceId.put(childResourceId, relation);
                            }
                        }
                    }
                }
                tmLine = (TM_Line__c) JSONUtils.attachListToParent(tmLine, mapTMParentRelationsByResourceId.values(), 'TM_Child_Lines__r');
                //resource level parent-child relationship
                tmLine = TMLLinesService.calculatePresumptiveChildLines(tm, jobTaskWrapper, tmLine, nextTMLineNo); //new TM Lines are added for the new relationship if lines don't already exist, and the new lines will be picked up for the parent child relationship check.
                if (nextTMLineNo < jobTaskWrapper.NextTMLineNo) {
                    nextTMLineNo = jobTaskWrapper.NextTMLineNo;
                }
                jobTaskWrapper.TMLines[j] = tmLine;
            }
        }

        for (Integer i = 0; i < jobTaskWrappers.size(); i++) {
            jobTaskWrappers[i].NextTMLineNo = nextTMLineNo;
        }
    }
    //ticket 19130 05.13.2023 >>


    //ticket 19130 05.13.2023 <<
    private Id getSalesLineResourceTypeIdOrResourceId(Sales_Line__c salesLine) {
        if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment' || salesLine.Category__c == 'Bundled') {
            return salesLine.Resource_Type__c;
        }
        else {
            return salesLine.Resource__c;
        }
    }

    private Id getTMLineResourceTypeIdOrResourceId(TM_Line__c tmLine) {
        if (tmLine.Category__c == 'Labor' || tmLine.Category__c == 'Equipment' || tmLine.Category__c == 'Bundled') {
            return tmLine.Resource_Type__c;
        }
        else {
            return tmLine.Resource__c;
        }
    }
    //ticket 19130 05.12.2023 >>
}