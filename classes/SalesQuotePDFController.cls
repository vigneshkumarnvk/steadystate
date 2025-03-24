/*************************************************************************************************
* Name         :  SalesQuotePDFController
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan      10-13-2024             US127188 - Salesforce - Modifications to allow ESIC Surcharge Type
* Samuel Moses				02-11-2025			   US140822: Sales Quote Customer Facing PDF Should be in Proper Case
* Vignesh Kumar				03-10-2025			   DE38217: Salesforce Quote PDF Consolidated Version, Output Issue in Prod
*************************************************************************************************/
public with sharing class SalesQuotePDFController {
    private final ApexPages.StandardController controller;
    public Sales_Order__c SalesOrder { set; get; }
    public List<SalesQuotePDFController.Job> Jobs { set; get; }
    public Company_Setup__c CompanySetup { set; get; }
    public String PrintType { set; get; }
    public Boolean IsFixedPriceJob { set; get; }
    public Boolean hasFixedPriceJob { set; get; }
    public String draftImageUrl { set; get; }

    public Company_Setup__c companySetupLogo { set; get; } //Ticket#21540
    public Service_Center__c serviceCenterSetupLog { set; get; } //Ticket#21540
    public Contract contractSetupLogo { set; get; } //Ticket#21540
    public String websiteUrl {set; get;} //Ticket#21540
    public String representativeColLabel {set; get;} //Ticket#21540
    public Boolean printEstimatedDuration { set; get; } //Ticket#21772
    public String logoUrl {set; get;} //Ticket#23989
    //ticket 21113 <<
    public String CustomerPrintName { set; get; }
    public String CustomerPONo { set; get; }
    public String CustomerSignatureFileId { set; get; }
    public Datetime CustomerSignatureDate { set; get; }
    //ticket 21113 >>
    public String ContactName { get; set; }
    public String ContactTitle { get; set; }
    public String BillToCustName { get; set; }
    public String BillToCustBillingStreet { get; set; }
    public String BillToCustBillingCity { get; set; }
    public String SiteName { get; set; }
    public String SiteStreet { get; set; }
    public String SiteCity { get; set; }

    public SalesQuotePDFController(ApexPages.StandardController controller) {
        this.controller = controller;
        if (this.controller.getId() != null) {
            this.CompanySetup = CompanyMgmt.getCompanySetup();
            this.SalesOrder = getSalesOrder(this.controller.getId());
            this.IsFixedPriceJob = false;
            //ticket 19672 <<
            this.hasFixedPriceJob = false;
            //ticket 19672 >>
            this.PrintType = ApexPages.currentPage().getParameters().get('printType');
            this.printEstimatedDuration = Boolean.valueOf(ApexPages.currentPage().getParameters().get('printEstimatedDuration')); //Ticket#21772
            this.InitData(this.controller.getId(), this.PrintType);
            String download = ApexPages.currentPage().getParameters().get('download');
            if(download != null){
                ApexPages.currentPage().getHeaders().put( 'content-disposition', 'inline; filename=' + this.SalesOrder.Name + '.pdf');
            }
        }

        //ticket 21088 <
        this.draftImageUrl = '';
        if (this.SalesOrder.Approval_Status__c != EnumUtil.ApprovalStatus.APPROVED.name()) {
            if(this.SalesOrder.Bill_to_Customer_No__c != null && this.SalesOrder.Bill_to_Customer_No__r.Subsidiary_Company__c != null &&
                    this.SalesOrder.Bill_to_Customer_No__r.Subsidiary_Company__r.Watermark__c != null){
                this.draftImageUrl = 'url("' + this.SalesOrder.Bill_to_Customer_No__r.Subsidiary_Company__r.Watermark__c + '")';
            } else {
                this.draftImageUrl = 'url("/resource/draftWaterMark")';
            }
        }
    }

    public void InitData(Id salesQuoteId, String printType) {
        List<Sales_Order_Job_Task__c> jobTasks = SalesOrderJobTasksSelector.newInstance().selectBySalesOrderId(new Set<Id>{
                salesQuoteId
        });
        List<Sales_Line__c> salesLines = this.getSalesLines(salesQuoteId);

        ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(this.SalesOrder, jobTasks, salesLines);

        Integer fixedPriceJobCount = 0;
        for (Sales_Order_Job_Task__c jobTask : jobTasks) {
            if (jobTask.Billing_Type__c == 'Fixed Price') {
                fixedPriceJobCount++;
            }
        }

        //Ticket#23989 >>
        this.logoUrl = StringUtil.extractLogoURLFromRichTextLogoField(CompanySetup.Company_Logo__c);
        //Ticket#21540 >>
        if(this.SalesOrder.Contract__c != null && this.SalesOrder.Contract__r.Logo__c != null){
            this.contractSetupLogo = [SELECT Id, Logo__c FROM Contract WHERE Id = :this.SalesOrder.Contract__c LIMIT 1];
            this.logoUrl = StringUtil.extractLogoURLFromRichTextLogoField(contractSetupLogo.Logo__c); //Ticket#23989
        } else if (this.SalesOrder.Service_Center__c != null && this.SalesOrder.Service_Center__r.Logo__c != null){
            this.serviceCenterSetupLog = [SELECT Id, Logo__c FROM Service_Center__c WHERE Id = :this.SalesOrder.Service_Center__c LIMIT 1];
            this.logoUrl = StringUtil.extractLogoURLFromRichTextLogoField(serviceCenterSetupLog.Logo__c); //Ticket#23989
        } else {
            this.companySetupLogo = CompanySetup;
        }

        if(String.isNotBlank(this.SalesOrder.Service_Center__r.Website__c)){
            this.websiteUrl = this.SalesOrder.Service_Center__r.Website__c;
        } else {
            this.websiteUrl = this.SalesOrder.Service_Center__r.Subsidiary_Company__r.Website__c;
        }

        if(String.isNotBlank(this.SalesOrder.Service_Center__r.PA_Rep_Sign_Col_Label__c)){
            this.representativeColLabel = this.SalesOrder.Service_Center__r.PA_Rep_Sign_Col_Label__c;
        } else {
            this.representativeColLabel = this.SalesOrder.Service_Center__r.Subsidiary_Company__r.PA_Rep_Sign_Col_Label__c;
        }
        //Ticket#21540 <<

        this.IsFixedPriceJob = (fixedPriceJobCount > 0 && fixedPriceJobCount == jobTasks.size());
        //ticket 19672 <<
        this.hasFixedPriceJob = (fixedPriceJobCount > 0);
        //ticket 19672 >>

        this.Jobs = new List<SalesQuotePDFController.Job>();
        if (printType == 'Detail') {
            this.InitDetailData(salesOrderWrapper);
        }
        else {
            this.InitConsolidatedData(salesOrderWrapper);
        }

        //ticket 21113 <<
        //get customer signature
        List<Signature__c> signatures = [SELECT Id, Print_Name__c, Signature_Date__c, Customer_PO_No__c, (SELECT Id FROM Attachments LIMIT 1) FROM Signature__c WHERE Sales_Order__c = :this.SalesOrder.Id AND Signer_Role__c = 'Customer A' AND Voided__c != TRUE AND Signed__c = TRUE];
        if (signatures.size() > 0) {
            if (signatures[0].Attachments.size() > 0) {
                this.CustomerPrintName = signatures[0].Print_Name__c;
                this.CustomerPONo = (signatures[0].Customer_PO_No__c != null ? signatures[0].Customer_PO_No__c : '');
                this.CustomerSignatureDate = signatures[0].Signature_Date__c;
                this.CustomerSignatureFileId = signatures[0].Attachments[0].Id;
            }
        }
        //ticket 21113 >>
        String contactSalutation =  String.isBlank(this.SalesOrder.Quote_Contact__r.Salutation) ? '' : this.SalesOrder.Quote_Contact__r.Salutation;
        contactName =  contactSalutation + toSentenceCase(this.SalesOrder.Quote_Contact__r.Name);
        contactTitle = toSentenceCase(salesOrder.Quote_Contact__r.Title);
        billToCustName = toSentenceCase(this.salesOrder.Bill_to_Customer_No__r.Name);
        billToCustBillingStreet = toSentenceCase(this.salesOrder.Bill_to_Customer_No__r.BillingStreet);
        billToCustBillingCity = toSentenceCase(salesOrder.Bill_to_Customer_No__r.BillingCity);
        siteName = toSentenceCase(this.salesOrder.Site_Name__c);
        siteStreet = toSentenceCase(this.salesOrder.Site_Street__c);
        siteCity = toSentenceCase(salesOrder.Site_City__c);
    }

    public void InitDetailData(ACVSalesOrderWrapper salesOrderWrapper) {
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : salesOrderWrapper.JobTaskWrappers) {
            SalesQuotePDFController.Job job = new SalesQuotePDFController.Job(jobTaskWrapper.JobTask);
            this.Jobs.add(job);

            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                if (salesLine.Category__c == 'Labor') {
                    job.LaborGroup.SalesLines.add(salesLine);
                    List<LaborLine> laborLines = this.createLaborLines(salesLine);

                    if (job.JobTask.Billing_Type__c == 'Fixed Price') {
                        for (LaborLine laborLine : laborLines) {
                            laborLine.unitPrice = 0;
                            laborLine.extendedPrice = 0;
                        }
                    }

                    job.LaborGroup.SplitLaborLines.addAll(laborLines);
                }
                else if (salesLine.Bill_as_Lump_Sum__c != true && salesLine.Non_Billable__c != true) {
                    switch on salesLine.Category__c {
                        when 'Equipment' {
                            job.EquipmentGroup.SalesLines.add(this.createEquipmentLine(salesLine));
                        }
                        when 'Materials' {
                            job.MaterialGroup.SalesLines.add(salesLine);
                        }
                        when 'Subcontractors' {
                            job.SubcontractorGroup.SalesLines.add(salesLine);
                        }
                        when 'Waste Disposal' {
                            job.WasteDisposalGroup.SalesLines.add(this.createWasteDisposalLine(salesLine));
                        }
                        when 'Demurrage' {
                            job.DemurrageGroup.SalesLines.add(salesLine);
                        }
                        when 'Misc. Charges And Taxes' {
                            if (salesLine.System_Calculated_Line__c == true && (salesLine.Resource__c == this.CompanySetup.Default_Fuel_Surcharge_Resource__c || salesLine.Resource__c == this.CompanySetup.Default_Energy_Insurance_Resource__c || salesLine.Resource__c == this.CompanySetup.Default_ESIC_Surcharge_Resource__c)) {
                                //ticket 19672 <<
                                //if (job.JobTask.Billing_Type__c != 'Fixed Price') {
                                if (job.JobTask.Billing_Type__c != 'Fixed Price' || (job.JobTask.Billing_Type__c == 'Fixed Price' && job.JobTask.Fixed_Price_Surcharge_Option__c == 'Fixed Price Does Not Include Surcharge')) {
                                //ticket 19672 >>
                                    job.SurchargeAmount = salesLine.Line_Amount__c;
                                    job.SurchargeTax = salesLine.Tax__c;
                                }
                            }
                            else {
                                job.MiscChargeGroup.SalesLines.add(salesLine);
                            }
                        }
                        when 'Bundled' {
                            job.LumpSumGroup.SalesLines.add(salesLine);
                        }
                    }

                    if (job.JobTask.Billing_Type__c == 'Fixed Price') {
                        salesLine.Unit_Price__c = 0;
                        salesLine.Line_Amount__c = 0;
                        salesLine.Line_Amt_Incl_Tax__c = 0;
                    }
                }
            }
        }
    }

    public void InitConsolidatedData(ACVSalesOrderWrapper salesOrderWrapper) {
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : salesOrderWrapper.JobTaskWrappers) {
            SalesQuotePDFController.Job job = new SalesQuotePDFController.Job(jobTaskWrapper.JobTask);
            this.Jobs.add(job);

            //Map<String, Sales_Line__c> mapConsolidatedLines = new Map<String, Sales_Line__c>();
            List<Sales_Line__c> salesLinesList = new List<Sales_Line__c>();	//DE38217
            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                //blank out unit price and amounts for fixed price
                if (jobTaskWrapper.JobTask.Billing_Type__c == 'Fixed Price') {
                    //ticket 19672 <<
                    if (jobTaskWrapper.JobTask.Fixed_Price_Surcharge_Option__c == 'Fixed Price Does Not Include Surcharge'
                        && salesLine.Category__c == 'Misc. Charges And Taxes' && salesLine.System_Calculated_Line__c == true
                        && (salesLine.Resource__c == this.CompanySetup.Default_Fuel_Surcharge_Resource__c || salesLine.Resource__c == this.CompanySetup.Default_Energy_Insurance_Resource__c)) {

                    }
                    else {
                    //ticket 19672 >>
                        salesLine.Unit_Price__c = 0;
                        salesLine.Line_Amount__c = 0;
                        salesLine.Line_Amt_Incl_Tax__c = 0;
                        salesLine.Regular_Rate__c = 0;
                        salesLine.Overtime_Rate__c = 0;
                        salesLine.Premium_Rate__c = 0;
                    //ticket 19672 <<
                    }
                    //ticket 19672 >>
                }

                if (salesLine.Category__c == 'Labor') {
                    job.LaborGroup.SalesLines.add(salesLine);
                    List<LaborLine> laborLines = this.createLaborLines(salesLine);
                    job.LaborGroup.SplitLaborLines.addAll(laborLines);
                }
                else {
                    if (salesLine.Bill_as_Lump_Sum__c != true && salesLine.Non_Billable__c != true) {
                        Boolean consolidate = true;
                        //String salesLineKey = salesLine.Category__c + ';' + salesLine.Description__c + ';' + salesLine.Unit_of_Measure__c;
                        if (salesLine.Category__c == 'Subcontractors') {
                            salesLine.Unit_Price__c = salesLine.Line_Amount__c / salesLine.Quantity__c ;
                        }
                        else if (salesLine.Category__c == 'Misc. Charges And Taxes' && salesLine.System_Calculated_Line__c == true && (salesLine.Resource__c == this.CompanySetup.Default_Fuel_Surcharge_Resource__c || salesLine.Resource__c == this.CompanySetup.Default_Energy_Insurance_Resource__c || salesLine.Resource__c == this.CompanySetup.Default_ESIC_Surcharge_Resource__c)) {
                            //ticket 19672 <<
                            //if (job.JobTask.Billing_Type__c != 'Fixed Price') {
                            if (job.JobTask.Billing_Type__c != 'Fixed Price' || (job.JobTask.Billing_Type__c == 'Fixed Price' && job.JobTask.Fixed_Price_Surcharge_Option__c == 'Fixed Price Does Not Include Surcharge')) {
                            //ticket 19672 >>
                            	job.SurchargeTax = salesLine.Tax__c;
                                job.SurchargeAmount = salesLine.Line_Amount__c;
                                consolidate = false;
                            }
                        }

                        //Ticket#27588 >>
                        if(salesLine.Category__c == ResourceService.EQUIPMENT_CATEGORY){
                            salesLine = createEquipmentLine(salesLine);
                        }
                        //Ticket#27588 <<

                        if (consolidate == true) {
                            /*if (mapConsolidatedLines.containsKey(salesLineKey)) {
                                Sales_Line__c consolidatedLine = mapConsolidatedLines.get(salesLineKey);
                                consolidatedLine.Quantity__c = CompanyMgmt.zeroIfNull(consolidatedLine.Quantity__c) + CompanyMgmt.zeroIfNull(salesLine.Quantity__c);
                                consolidatedLine.UOM_Qty__c = CompanyMgmt.zeroIfNull(consolidatedLine.UOM_Qty__c) + CompanyMgmt.zeroIfNull(salesLine.UOM_Qty__c); //Ticket#27588
                                consolidatedLine.Line_Amt_Incl_Tax__c = CompanyMgmt.zeroIfNull(consolidatedLine.Line_Amt_Incl_Tax__c) + CompanyMgmt.zeroIfNull(salesLine.Line_Amt_Incl_Tax__c);
                                consolidatedLine.Line_Amount__c = CompanyMgmt.zeroIfNull(consolidatedLine.Line_Amount__c) + CompanyMgmt.zeroIfNull(salesLine.Line_Amount__c);
                            } else {
                                mapConsolidatedLines.put(salesLineKey, salesLine);
                            }*/
                            salesLinesList.add(salesLine);
                        }
                    }
                }
            }
            job.ConsolidatedGroup.SalesLines = salesLinesList;//mapConsolidatedLines.values();
        }

        //consolidate labor lines
        for (Job job : this.Jobs) {
            //consolidate labor lines
            //Map<String, LaborLine> mapConsolidatedLaborLines = new Map<String, LaborLine>();
            List<LaborLine> laborLinesList = new List<LaborLine>();	//DE38217
            for (LaborLine laborLine : job.LaborGroup.SplitLaborLines) {
               /*if (mapConsolidatedLaborLines.containsKey(laborLine.description + laborLine.rateType)) {
                    LaborLine consolidatedLaborLine = mapConsolidatedLaborLines.get(laborLine.description + laborLine.rateType);
                    consolidatedLaborLine.qty += laborLine.qty;
                    consolidatedLaborLine.uomQty += laborLine.uomQty;
                    consolidatedLaborLine.extendedPrice += laborLine.extendedPrice;
                } else {
                    if (laborLine.billAsLumpSum != true) {
                        mapConsolidatedLaborLines.put(laborLine.description + laborLine.rateType, laborLine);
                    }
                }*/
                laborLinesList.add(laborLine);
            }
            job.LaborGroup.SplitLaborLines = laborLinesList;//mapConsolidatedLaborLines.values();

            //calculate totals
        }
    }

    public Decimal Subtotal {
        get {
            Decimal x = 0;
            for (Job job : this.Jobs) {
                x += job.Subtotal;
            }
            return  x;
        }
    }

    public Decimal Tax {
        get {
            Decimal x = 0;
            for (Job job : this.Jobs) {
                x += job.Tax;
            }
            return  x;
        }
    }

    public Decimal SurchargeAmount {
        get {
            Decimal x = 0;
            for (Job job : this.Jobs) {
                x += job.SurchargeAmount;
            }
            return  x;
        }
    }

    public Decimal Total {
        get {
            Decimal x = 0;
            for (Job job : this.Jobs) {
                x += job.Total;
            }
            return  x;
        }
    }

    private List<LaborLine> createLaborLines(Sales_Line__c salesLine) {
        List<LaborLine> laborLines = new List<LaborLine>();

        String rateType;
        Decimal unitPrice;
        Decimal extendedPrice;
        Decimal uOMQty;
        Boolean billAsLumpSum = salesLine.Bill_as_Lump_Sum__c != true && salesLine.Non_Billable__c!= true ? false : true;
        Boolean printRegLine = false;
        Boolean printOTLine = false;
        Boolean printDTLine = false;

        Decimal lineRegRate = 0;
        Decimal lineOTRate = 0;
        Decimal lineDTRate =0;
        if (!billAsLumpSum) {
            lineRegRate = CompanyMgmt.zeroIfNull(salesLine.Regular_Rate__c);
            lineOTRate = CompanyMgmt.zeroIfNull(salesLine.Overtime_Rate__c);
            lineDTRate = CompanyMgmt.zeroIfNull(salesLine.Premium_Rate__c);
        }
        Decimal lineRegDay = 0;
        Decimal lineOTDay = 0;
        Decimal lineDTDay = 0;
        Decimal lineRegHour = 0;
        Decimal lineOTHour = 0;
        Decimal lineDTHour = 0;
        if (salesLine.Sales_Line_Details__r != null) {
            for (Sales_Line_Detail__c salesLineDetail : salesLine.Sales_Line_Details__r) {
                lineRegHour += CompanyMgmt.zeroIfNull(salesLineDetail.Regular_Hours__c);
                lineOTHour += CompanyMgmt.zeroIfNull(salesLineDetail.Overtime_Hours__c);
                lineDTHour += CompanyMgmt.zeroIfNull(salesLineDetail.Premium_Hours__c);

                if (salesLineDetail.Unit_of_Measure__r.Hours_UOM__c != true) {
                    lineRegDay++;
                }
            }
        }

        if ((lineRegRate * lineRegHour != 0) || (lineRegRate * lineRegDay != 0)){
            printRegLine = true;
        }

        if ((lineOTRate * lineOTHour != 0) || (lineOTRate * lineOTDay != 0)){
            printOTLine = true;
        }

        if ((lineDTRate * lineDTHour != 0) || (lineDTRate * lineDTDay != 0)){
            printDTLine = true;
        }

        if (printRegLine == true) {
            rateType = 'Reg';
            unitPrice = lineRegRate;
            if(salesLine.Unit_of_Measure__r.Hours_UOM__c == true){
                uOMQty = lineRegHour;
            } else if(salesLine.Unit_of_Measure__c == this.CompanySetup.Day_Unit_of_Measure__c){
                uomQty = lineRegDay;
            } else {
                uomQty = lineRegHour;
            }
            extendedPrice = unitPrice * salesLine.Quantity__c * uomQty;

            laborLines.add(new LaborLine(
                    salesLine.Description__c,
                    rateType,
                    salesLine.Quantity__c,
                    uomQty,
                    salesLine.Unit_of_Measure__r.Name,
                    unitPrice,
                    extendedPrice, billAsLumpSum));
        }

        if(printOTLine == true){
            rateType = 'OT';
            unitPrice = lineOTRate;
            if(salesLine.Unit_of_Measure__r.Hours_UOM__c == true){
                uomQty = lineOTHour;
            } else if(salesLine.Unit_of_Measure__c == this.CompanySetup.Day_Unit_of_Measure__c){
                uomQty = lineOTDay;
            } else {
                uomQty = lineOTHour;
            }

            extendedPrice = unitPrice * salesLine.Quantity__c * uOMQty;
            laborLines.add(new LaborLine(
                    salesLine.Description__c,
                    rateType,
                    salesLine.Quantity__c,
                    uomQty,
                    salesLine.Unit_of_Measure__r.Name,
                    unitPrice,
                    extendedPrice, billAsLumpSum));
        }

        if(printDTLine == true){
            rateType = 'DT';
            unitPrice = lineDTRate;
            if(salesLine.Unit_of_Measure__r.Hours_UOM__c == true){
                uomQty = lineDTHour;
            } else if(salesLine.Unit_of_Measure__c == this.CompanySetup.Day_Unit_of_Measure__c){
                uomQty = lineDTDay;
            } else {
                uomQty = lineDTHour;
            }
            extendedPrice = unitPrice * salesLine.Quantity__c * uOMQty;
            laborLines.add(new LaborLine(
                    salesLine.Description__c,
                    rateType,
                    salesLine.Quantity__c,
                    uomQty,
                    salesLine.Unit_of_Measure__r.Name,
                    unitPrice,
                    extendedPrice, billAsLumpSum));
        }
        return laborLines;
    }

    private Sales_Line__c createEquipmentLine(Sales_Line__c salesLine) {
        if(salesLine.Unit_of_Measure__c == this.CompanySetup.Day_Unit_of_Measure__c){
            salesLine.UOM_Qty__c = salesLine.Number_of_Day__c;
        } else if (salesLine.Unit_of_Measure__r.Hours_UOM__c == true){
            if(salesLine.Sales_Line_Details__r != null){
                Decimal uomQty = 0;
                for (Sales_Line_Detail__c salesLineDetail : salesLine.Sales_Line_Details__r) {
                    uomQty = uomQty + CompanyMgmt.zeroIfNull(salesLineDetail.UOM_Qty__c);
                }
                salesLine.UOM_Qty__c = uomQty;
            } else {
                salesLine.UOM_Qty__c = salesLine.UOM_Qty__c * salesLine.Number_of_Day__c;
            }
        }
        return salesLine;
    }

    private Sales_Line__c createWasteDisposalLine(Sales_Line__c salesLine) {
        /*
        if(salesLine.Cost_Method__c == EnumUtil.CostMethod.CONTAINER.name()) {
            salesLine.Unit_of_Measure__r = salesLine.Container_Size__r;
        }

        else if (salesLine.Cost_Method__c == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name()) {
            salesLine.Unit_of_Measure__r = salesLine.Unit_Weight_Vol__r;
        }
         */

        if (CompanyMgmt.zeroIfNull(salesLine.Min_Sell_Qty__c) >  salesLine.Quantity__c) {
            salesLine.Quantity__c = salesLine.Min_Sell_Qty__c;
        }
        return salesLine;
    }

    /*
     *   Ticket#21540 - add service center field into the Sales Quote query
     */
    private Sales_Order__c getSalesOrder(Id salesQuoteId) {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Sales_Order__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ', Bill_to_Contact__r.Salutation,Bill_to_Contact__r.Suffix, Bill_to_Contact__r.LastName, ' +
                'Bill_to_Contact__r.Title, Bill_to_Contact__r.Name, Bill_to_Contact__r.FirstName, Bill_to_Customer_No__r.Name, ' +
                'Bill_to_Customer_No__r.Credit_Hold__c, Sales_Order_Type__r.Name, Account_Executives__r.Name, ' +
                'Service_Center__r.Name, Project_Coordinator__r.Name,Contract__r.Name, Alternate_Site_Address__r.Name ';
        strQuery += ', Bill_to_Customer_No__r.Id, Bill_to_Customer_No__r.Service_Center__c, ' +
                'Bill_to_Customer_No__r.Subsidiary_Company__c, Bill_to_Customer_No__r.Tax_Area__c, ' +
                'Bill_to_Customer_No__r.Billing_Contact__c, Tax_Area__r.Name ';
        strQuery += ', Bill_to_Customer_No__r.BillingStreet , Bill_to_Customer_No__r.BillingCity, ' +
                'Bill_to_Customer_No__r.BillingState, Bill_to_Customer_No__r.BillingStateCode, Bill_to_Customer_No__r.BillingPostalCode, ' +
                'Bill_to_Customer_No__r.BillingCountry, Bill_to_Customer_No__r.Payment_Term__c, ' +
                'Bill_to_Customer_No__r.ParentId, Contract__r.ContractNumber ';
        strQuery += ', Sales_Order_Type__r.Description__c, Bill_to_Customer_No__r.AccountNumber, ' +
                'Bill_to_Customer_No__r.Emergency__c, From_Sales_Quote__r.Name, Site_Contact_2__r.Name, ' +
                'Site_Contact_2__r.FirstName, Site_Contact_2__r.LastName, Bill_to_Customer_No__r.RecordTypeId,' +
                'Contract__r.Billing_Rule__c, Contract__r.Billing_Rule__r.Name, Sales_Order_Type__r.Emergency_Response__c, Quote_Contact__r.Name, ' +
                'Quote_Contact__r.FirstName, Quote_Contact__r.LastName, Contract__r.Surcharge_Type__c, Contract__r.Surcharge_Pct__c, Rate_Sheet__r.Name, ' +
                'CreatedBy.Name';
        //quote contact <<
        strQuery += ',Quote_Contact__r.Salutation, Quote_Contact__r.Title ';
        //quote contact >>
        //Ticket#21540 >>
        strQuery += ',Service_Center__r.Standard_AC_Opt1__c, Service_Center__r.Standard_AC_Opt2__c, Service_Center__r.Standard_AC_Opt3__c' +
                ',Service_Center__r.Standard_AC_Opt4__c, Service_Center__r.Disposal_Related_Asm_Cont_Opt1__c' +
                ',Service_Center__r.Disposal_Related_Asm_Cont_Opt2__c, Service_Center__r.Disposal_Related_Asm_Cont_Opt3__c' +
                ',Service_Center__r.Disposal_Related_Asm_Cont_Opt4__c, Service_Center__r.Disposal_Related_Asm_Cont_Opt5__c' +
                ',Service_Center__r.Disposal_Related_Asm_Cont_Opt6__c, Service_Center__r.Disposal_Related_Asm_Cont_Opt7__c' +
                ',Service_Center__r.Term_Conditions_Opt1__c, Service_Center__r.Term_Conditions_Opt2__c' +
                ',Service_Center__r.Term_Conditions_Opt3__c, Service_Center__r.Term_Conditions_Opt4__c' +
                ',Service_Center__r.Term_Conditions_Opt5__c, Service_Center__r.Term_Conditions_Opt6__c' +
                ',Service_Center__r.Term_Conditions_Opt7__c, Service_Center__r.Term_Conditions_Opt8__c' +
                ',Service_Center__r.Term_Conditions_Opt9__c, Service_Center__r.Term_Conditions_Opt10__c' +
                ',Service_Center__r.Term_Conditions_Opt11__c, Service_Center__r.Term_Conditions_Opt12__c' +
                ',Service_Center__r.Term_Conditions_Opt13__c, Service_Center__r.Term_Conditions_Opt14__c' +
                ',Service_Center__r.Term_Conditions_Opt15__c, Service_Center__r.Term_Conditions_Opt16__c' +
                ',Service_Center__r.Term_Conditions_Opt17__c, Service_Center__r.Term_Conditions_Opt18__c' +
                ',Service_Center__r.Term_Conditions_Opt19__c, Service_Center__r.Quote_Closing_Paragraph__c' +
                ',Service_Center__r.Quote_Introductory_Paragraph__c, Service_Center__r.Quote_TC_Introductory_Paragraph__c' +
                ',Service_Center__r.Logo__c, Contract__r.Logo__c, Bill_to_Customer_No__r.Subsidiary_Company__r.Watermark__c' +
                ',Service_Center__r.Subsidiary_Company__r.Website__c,Service_Center__r.Website__c' +
                ',Service_Center__r.PA_Rep_Sign_Col_Label__c, Service_Center__r.Subsidiary_Company__r.PA_Rep_Sign_Col_Label__c' +
                ',Service_Center__r.Term_Conditions_Opt20__c, Service_Center__r.Legal_Entity_Name__c';
        //Ticket#21540 <<
        strQuery += ' FROM Sales_Order__c WHERE Id =: salesQuoteId';
        return Database.query(strQuery);
    }
    private List<Sales_Line__c> getSalesLines(Id salesQuoteId) {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Sales_Line__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ', Unit_of_Measure__r.Name,Resource__r.Name, Sales_Order__r.Name, Resource_Type__r.Name, Resource__r.Unit_Cost__c, Resource_Type__r.Unit_Cost__c, Contract_Line__r.Name';
        strQuery += ', Resource_Type__r.Unit_of_Measure__c, Resource_Type__r.Unit_of_Measure1__c, Resource_Type__r.Unit_of_Measure2__c, Resource_Type__r.Unit_of_Measure3__c, Resource_Type__r.Unit_of_Measure4__c ';
        strQuery += ', Resource_Type__r.Fuel_Fired_Equipment__c, Sales_Order__r.Document_Type__c';
        strQuery += ', Resource__r.Unit_of_Measure__c, Resource__r.Unit_of_Measure1__c, Resource__r.Unit_of_Measure2__c, Resource__r.Unit_of_Measure3__c, Resource__r.Unit_of_Measure4__c ';
        strQuery += ', Sales_Line__c.Container_Size__r.Name, Sales_Line__c.Unit_Weight_Vol__r.Name, Facility__r.Name, Unit_of_Measure__r.Hours_UOM__c, Resource__r.EEC_Surcharge_Exempted__c, Resource_Type__r.EEC_Surcharge_Exempted__c';
        strQuery += ', Bundle_Line__r.Line_No__c, Resource__r.Tax_Group__c';
        strQuery += ', Sales_Order_Job_Task__r.Name, Sales_Order_Job_Task__r.Line_No__c';
        strQuery += ', (SELECT Id, Sales_Line__c, Unit_of_Measure__r.Hours_UOM__c, UOM_Qty__c, Regular_Hours__c, Overtime_Hours__c, Premium_Hours__c FROM Sales_Line_Details__r)';
        strQuery += ' FROM Sales_Line__c WHERE Sales_Order__c = :salesQuoteId AND Quantity__c != 0 AND Quantity__c != NULL ORDER BY Line_No__c';
        return Database.query(strQuery);
    }

    public class Job {
        public Sales_Order_Job_Task__c JobTask { set; get; }

        public LaborLineGroup LaborGroup { set; get; }
        public SalesLineGroup EquipmentGroup { set; get; }
        public SalesLineGroup MaterialGroup { set; get; }
        public SalesLineGroup SubcontractorGroup { set; get; }
        public SalesLineGroup WasteDisposalGroup { set; get; }
        public SalesLineGroup DemurrageGroup { set; get; }
        public SalesLineGroup MiscChargeGroup { set; get; }
        public SalesLineGroup LumpSumGroup { set; get; }
        public SalesLineGroup ConsolidatedGroup { set; get; }
        public Decimal SurchargeAmount { set; get; }
        public Decimal SurchargeTax { set; get;}

        public Job(Sales_Order_Job_Task__c jobTask) {
            this.JobTask = jobTask;
            this.LaborGroup = new LaborLineGroup(jobTask);
            this.EquipmentGroup = new SalesLineGroup(jobTask);
            this.MaterialGroup = new SalesLineGroup(jobTask);
            this.SubcontractorGroup = new SalesLineGroup(jobTask);
            this.WasteDisposalGroup = new SalesLineGroup(jobTask);
            this.DemurrageGroup = new SalesLineGroup(jobTask);
            this.MiscChargeGroup = new SalesLineGroup(jobTask);
            this.LumpSumGroup = new SalesLineGroup(jobTask);
            this.ConsolidatedGroup = new SalesLineGroup(jobTask);
            this.SurchargeAmount = 0;
            this.SurchargeTax = 0;
        }

        public Decimal Subtotal {
            get {
                Decimal x = 0;
                if (this.JobTask.Billing_Type__c == 'Fixed Price') {
                    x = CompanyMgmt.zeroIfNull(this.JobTask.Fixed_Price__c);
                }
                else {
                    x = this.LaborGroup.Subtotal + this.EquipmentGroup.Subtotal + this.MaterialGroup.Subtotal + this.SubcontractorGroup.Subtotal + this.WasteDisposalGroup.Subtotal + this.DemurrageGroup.Subtotal + this.LumpSumGroup.Subtotal + this.MiscChargeGroup.Subtotal + this.ConsolidatedGroup.Subtotal;
                }
                return x;
            }
        }
        public Decimal Tax {
            get {
                Decimal x = 0;
                if (this.JobTask.Billing_Type__c == 'Fixed Price') {
                    x = CompanyMgmt.zeroIfNull(this.JobTask.Tax__c);
                }
                else {
                    x = this.LaborGroup.Tax + this.EquipmentGroup.Tax + this.MaterialGroup.Tax + this.SubcontractorGroup.Tax + this.WasteDisposalGroup.Tax + this.DemurrageGroup.Tax + this.LumpSumGroup.Tax + this.MiscChargeGroup.Tax + this.ConsolidatedGroup.Tax + this.SurchargeTax;
                }
                return x;
            }
        }
        public Decimal Total {
            get {
                Decimal x = 0;
                if (this.JobTask.Billing_Type__c == 'Fixed Price') {
                    x = CompanyMgmt.zeroIfNull(this.JobTask.Fixed_Price__c) + CompanyMgmt.zeroIfNull(this.JobTask.Tax__c);// + this.SurchargeAmount;
                    //ticket 19672 <<
                    if (this.JobTask.Fixed_Price_Surcharge_Option__c == 'Fixed Price Does Not Include Surcharge') {
                        x += this.SurchargeAmount;
                    }
                    //ticket 19672 >>
                }
                else {
                    x = this.LaborGroup.Total + this.EquipmentGroup.Total + this.MaterialGroup.Total + this.SubcontractorGroup.Total + this.WasteDisposalGroup.Total + this.DemurrageGroup.Total + this.LumpSumGroup.Total + this.MiscChargeGroup.Total + this.ConsolidatedGroup.Total + this.SurchargeAmount + this.SurchargeTax;
                }
                return x;
            }
        }
    }

    public virtual class SalesLineGroup {
        public Sales_Order_Job_Task__c JobTask;
        public List<Sales_Line__c> SalesLines { set; get; }

        public SalesLineGroup(Sales_Order_Job_Task__c jobTask) {
            this.JobTask = jobTask;
            this.SalesLines = new List<Sales_Line__c>();
        }

        public Decimal Subtotal {
            get {
                Decimal x = 0;
                if (this.JobTask.Billing_Type__c != 'Fixed Price') {
                    for (Sales_Line__c salesLine : this.SalesLines) {
                        x += CompanyMgmt.zeroIfNull(salesLine.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
                    }
                }
                return x;
            }
        }
        public Decimal Tax {
            get {
                Decimal x = 0;
                if (this.JobTask.Billing_Type__c != 'Fixed Price') {
                    for (Sales_Line__c salesLine : this.SalesLines) {
                        x += (CompanyMgmt.zeroIfNull(salesLine.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(salesLine.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
                    }
                }
                return x;
            }
        }
        public Decimal Total {
            get {
                Decimal x = 0;
                if (this.JobTask.Billing_Type__c != 'Fixed Price') {
                    for (Sales_Line__c salesLine : this.SalesLines) {
                        x += CompanyMgmt.zeroIfNull(salesLine.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
                    }
                }
                return x;
            }
        }
    }

    public class LaborLineGroup extends SalesLineGroup{
        public List<LaborLine> SplitLaborLines { set; get; }

        public LaborLineGroup(Sales_Order_Job_Task__c jobTask) {
            super(jobTask);
            this.SplitLaborLines = new List<LaborLine>();
        }
    }
    
    public String toSentenceCase(String text) {
        if (String.isEmpty(text)) return '';
        text = text.toLowerCase();
        
        String exceptionsStr = System.Label.SalesQuotePDFAddressFormatExceptions;
        Set<String> exceptions = new Set<String>(exceptionsStr.toLowerCase().split(',')); 
        
        Pattern letterPattern = Pattern.compile('^[a-zA-Z]');
        List<String> words = text.split(' ');
        for (Integer i = 0; i < words.size(); i++) {
            if (words[i].length() > 0) {
                Matcher m = letterPattern.matcher(words[i]); 
                if (m.find()) {
                    if (!exceptions.contains(words[i].toLowerCase())) { 
                        words[i] = words[i].substring(0,1).toUpperCase() + words[i].substring(1);
                    } else {
                        words[i] = words[i].toUpperCase();
                    }
                }
            }
        }
        return String.join(words, ' ');
    }


    public class LaborLine {
        public String description {get; set;}
        public String rateType {get;set;}
        public Decimal qty {get;set;}
        public Decimal uomQty {get;set;}
        public String uom {get;set;}
        public Decimal unitPrice {get;set;}
        public Decimal extendedPrice {get;set;}
        public Boolean billAsLumpSum {get;set;}

        public LaborLine(String description, String rateType, Decimal quantity, Decimal uomQty, String uom, Decimal unitPrice, Decimal extendedPrice, Boolean billAsLumpSum){
            this.description = description;
            this.rateType = rateType;
            this.qty = quantity;
            this.uomQty = uomQty;
            this.uom = uom;
            this.unitPrice = unitPrice;
            this.extendedPrice = extendedPrice;
            this.billAsLumpSum = billAsLumpSum;
        }
    }
}