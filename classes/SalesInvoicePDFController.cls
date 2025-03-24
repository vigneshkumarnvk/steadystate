public with sharing class SalesInvoicePDFController {
    public Company_Setup__c CompanySetup { set; get; }
    public List<InvoiceWrapper> InvoiceWrappers { set; get; }
    //ticket 19127 <<
    //public String InvoiceType { set; get; }
    //ticket 19127 >>
    public Integer counter { set; get; }
    public String draftImageUrl { set; get; }
    public Boolean IsFixedPriceJob { set; get; }

    public SalesInvoicePDFController() {
        Map<String, String> params = ApexPages.currentPage().getParameters();
        String salesInvoiceId = params.get('id');

        //ticket 19127 <<
        //String invoiceType = params.get('InvoiceType');
        //this.InvoiceType = invoiceType;
        //ticket 19127 >>
        this.IsFixedPriceJob = false;
        Set<Id> salesInvoiceIds = new Set<Id>{ salesInvoiceId };

        //ticket 19127 <<
        //this.print(salesInvoiceIds, invoiceType);
        this.print(salesInvoiceIds);
        //ticket 19127 >>
    }

    //ticket 19127 <<
    //public void print(Set<Id> salesInvoiceIds, String invoiceType) {
    public void print(Set<Id> salesInvoiceIds) {
    //ticket 19127 >>
        this.CompanySetup = CompanyMgmt.getCompanySetup();

        List<Sales_Invoice__c> salesInvoices = this.getSalesInvoices(salesInvoiceIds);
        Map<Id, List<Sales_Invoice_Job_Task__c>> mapJobTasksByInvoiceId = new Map<Id, List<Sales_Invoice_Job_Task__c>>();
        Map<Id, List<Sales_Invoice_Line__c>> mapSalesInvoiceLinesByTaskId = new Map<Id, List<Sales_Invoice_Line__c>>();

        this.draftImageUrl = '';
        if (salesInvoices.size() > 0) {
            if (salesInvoices[0].Approval_Status__c != EnumUtil.ApprovalStatus.APPROVED.name() && salesInvoices[0].Credit_Memo__c != true) {
                //Ticket#21540 >>
                if(salesInvoices[0].Bill_to_Customer__c != null && salesInvoices[0].Bill_to_Customer__r.Subsidiary_Company__c != null &&
                        salesInvoices[0].Bill_to_Customer__r.Subsidiary_Company__r.Watermark__c != null){
                    this.draftImageUrl = 'url("' + salesInvoices[0].Bill_to_Customer__r.Subsidiary_Company__r.Watermark__c + '")';
                } else {
                    this.draftImageUrl = 'url("/resource/draftWaterMark")';
                }
                //Ticket#21540 <<
            }
        }

        Integer fixedPriceJobCount = 0;
        Integer jobTaskCount = 0;
        for (Sales_Invoice_Job_Task__c jobTask : this.getJobTasks(salesInvoiceIds)) {
            List<Sales_Invoice_Job_Task__c> jobTasks;
            if (mapJobTasksByInvoiceId.containsKey(jobTask.Sales_Invoice__c)) {
                jobTasks = mapJobTasksByInvoiceId.get(jobTask.Sales_Invoice__c);
            }
            else {
                jobTasks = new List<Sales_Invoice_Job_Task__c>();
                mapJobTasksByInvoiceId.put(jobTask.Sales_Invoice__c, jobTasks);
            }

            //ticket 19127 <<
            if (jobTask.Invoice_Format__c == null) {
                jobTask.Invoice_Format__c = 'Detail';
            }
            //ticket 19127 >>

            jobTasks.add(jobTask);

            if (jobTask.Billing_Type__c == 'Fixed Price') {
                fixedPriceJobCount++;
            }
            jobTaskCount++;
        }
        this.IsFixedPriceJob = (fixedPriceJobCount > 0 && fixedPriceJobCount == jobTaskCount);

        //ticket 19631 << - print non-billable lines
        //for (Sales_Invoice_Line__c salesInvoiceLine : this.getSalesInvoiceLines(salesInvoiceIds)) {
        List<String> filters = new List<String>();
        filters.add('(Non_Billable__c != TRUE OR Print_Line__c = TRUE)');
        for (Sales_Invoice_Line__c salesInvoiceLine : this.getSalesInvoiceLines(salesInvoiceIds, filters)) {
        //ticket 19631 >>
            List<Sales_Invoice_Line__c> salesInvoiceLines;
            if (mapSalesInvoiceLinesByTaskId.containsKey(salesInvoiceLine.Sales_Invoice_Job_Task__c)) {
                salesInvoiceLines = mapSalesInvoiceLinesByTaskId.get(salesInvoiceLine.Sales_Invoice_Job_Task__c);
            }
            else {
                salesInvoiceLines = new List<Sales_Invoice_Line__c>();
                mapSalesInvoiceLinesByTaskId.put(salesInvoiceLine.Sales_Invoice_Job_Task__c, salesInvoiceLines);
            }
            salesInvoiceLines.add(salesInvoiceLine);
        }

        //ticket 19127 <<
        //this.initData(salesInvoices, mapJobTasksByInvoiceId, mapSalesInvoiceLinesByTaskId, invoiceType);
        this.initData(salesInvoices, mapJobTasksByInvoiceId, mapSalesInvoiceLinesByTaskId);
        //ticket 19127 >>
    }

    //ticket 19127 <<
    //public void initData(List<Sales_Invoice__c> salesInvoices, Map<Id, List<Sales_Invoice_Job_Task__c>> mapJobTasksByInvoiceId, Map<Id, List<Sales_Invoice_Line__c>> mapSalesInvoiceLinesByTaskId, String invoiceType) {
    public void initData(List<Sales_Invoice__c> salesInvoices, Map<Id, List<Sales_Invoice_Job_Task__c>> mapJobTasksByInvoiceId, Map<Id, List<Sales_Invoice_Line__c>> mapSalesInvoiceLinesByTaskId) {
    //ticket 19127 >>
        Set<Id> serviceCenterIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();
        for (Sales_Invoice__c salesInvoice : salesInvoices) {
            serviceCenterIds.add(salesInvoice.Service_Center__c);
            if (salesInvoice.Contract__c != null) {
                contractIds.add(salesInvoice.Contract__c);
            }
        }
        Map<Id, Service_Center__c> mapServiceCentersById = new Map<Id, Service_Center__c>();
        for (Service_Center__c serviceCenter : ServiceCentersSelector.newInstance().selectById(serviceCenterIds)) {
            mapServiceCentersById.put(serviceCenter.Id, serviceCenter);
        }
        Map<Id, Contract> mapContractsById = new Map<Id, Contract>();
        for (Contract contract : ContractsSelector.newInstance().selectById(contractIds)) {
            mapContractsById.put(contract.Id, contract);
        }

        Map<Id, InvoiceWrapper> mapInvoiceWrappersById = new Map<Id, InvoiceWrapper>();
        for (Sales_Invoice__c salesInvoice : salesInvoices) {
            Service_Center__c serviceCenter = mapServiceCentersById.get(salesInvoice.Service_Center__c);
            Contract contract = mapContractsById.get(salesInvoice.Contract__c);

            InvoiceWrapper invoiceWrapper = new InvoiceWrapper(salesInvoice, contract, this.CompanySetup, serviceCenter);
            mapInvoiceWrappersById.put(salesInvoice.Id, invoiceWrapper);

            List<Sales_Invoice_Job_Task__c> jobTasks = mapJobTasksByInvoiceId.get(salesInvoice.Id);
            for (Sales_Invoice_Job_Task__c jobTask : jobTasks) {
                TaskWrapper taskWrapper = new TaskWrapper(jobTask);
                invoiceWrapper.TaskWrappers.add(taskWrapper);

                if (mapSalesInvoiceLinesByTaskId.containsKey(jobTask.Id)) {
                    List<Sales_Invoice_Line__c> salesInvoiceLines = mapSalesInvoiceLinesByTaskId.get(jobTask.Id);
                    for (Sales_Invoice_Line__c salesInvoiceLine : salesInvoiceLines) {
                        //Ticket#19386
                        if(salesInvoiceLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY
                                && salesInvoiceLine.Min_Sell_Qty__c != null
                                && salesInvoiceLine.Recorded_Qty__c != null
                                && salesInvoiceLine.Min_Sell_Qty__c > salesInvoiceLine.Recorded_Qty__c){
                            //salesInvoiceLine.Description__c = salesInvoiceLine.Description__c + ' (Min. Qty.) ' + salesInvoiceLine.Min_Sell_Qty__c + ' )';
                            salesInvoiceLine.Description__c = salesInvoiceLine.Description__c + ' (Min. Qty.)';
                        }
                        //Ticket#19386

                        if (salesInvoiceLine.Line_Amt_Incl_Tax__c == null) {
                            salesInvoiceLine.Line_Amt_Incl_Tax__c = 0;
                        }
                        Decimal lineAmount = CompanyMgmt.zeroIfNull(salesInvoiceLine.Line_Amount__c);
                        Decimal tax = CompanyMgmt.zeroIfNull(salesInvoiceLine.Tax__c);

                        if (salesInvoiceLine.System_Calculated_Line__c != true) { //surcharge line is a system calculated line, exclude from line print
                            List<String> keys = new List<String>();

                            //ticket 19127 <<
                            /*
                            if (invoiceType == 'TM by Date by Category') {
                                keys.add(salesInvoiceLine.Category__c);
                                keys.add(String.valueOf(salesInvoiceLine.Scheduled_Date__c));
                            } else if (invoiceType == 'TM Summary') {
                                keys.add(salesInvoiceLine.Category__c);
                            } else if (invoiceType == 'TM Detail') {
                                keys.add(String.valueOf(salesInvoiceLine.Scheduled_Date__c));
                            }
                            */
                            if (jobTask.Invoice_Format__c == 'By Date by Category') {
                                keys.add(salesInvoiceLine.Category__c);
                                keys.add(String.valueOf(salesInvoiceLine.Scheduled_Date__c));
                            } else if (jobTask.Invoice_Format__c == 'Summary') {
                                keys.add(salesInvoiceLine.Category__c);
                            } else if (jobTask.Invoice_Format__c == 'Detail') {
                                keys.add(String.valueOf(salesInvoiceLine.Scheduled_Date__c));
                            }
                            //ticket 19127 <<

                            String keyString = String.join(keys, ';');

                            LinesWrapper linesWrapper;
                            if (taskWrapper.MapLinesWrappersByKey.containsKey(keyString)) {
                                linesWrapper = taskWrapper.MapLinesWrappersByKey.get(keyString);
                            } else {
                                linesWrapper = new LinesWrapper(salesInvoiceLine.Category__c, salesInvoiceLine.Scheduled_Date__c);
                                taskWrapper.MapLinesWrappersByKey.put(keyString, linesWrapper);
                            }
                            linesWrapper.InvoiceLines.add(salesInvoiceLine);
                            linesWrapper.Amount += lineAmount;
                        }

                        //surcharge line
                        if (salesInvoiceLine.System_Calculated_Line__c == true && (salesInvoiceLine.Resource__c == companySetup.Default_Fuel_Surcharge_Resource__c || salesInvoiceLine.Resource__c == companySetup.Default_Energy_Insurance_Resource__c)) {
                            taskWrapper.SurchargeAmount += lineAmount;
                            invoiceWrapper.SurchargeAmount += lineAmount;
                        } else {
                            taskWrapper.Amount += lineAmount;
                            invoiceWrapper.Amount += lineAmount;
                        }
                        taskWrapper.Tax += tax;
                        invoiceWrapper.Tax += tax;

                        //invoice fields
                        if (invoiceWrapper.LastServiceDate == null || invoiceWrapper.LastServiceDate < salesInvoiceLine.Scheduled_Date__c) {
                            invoiceWrapper.LastServiceDate = salesInvoiceLine.Scheduled_Date__c;
                        }
                    }
                }
            }
        }
        this.InvoiceWrappers = mapInvoiceWrappersById.values();
    }

    private List<Sales_Invoice__c> getSalesInvoices(Set<Id> salesInvoiceIds) {
        List<Sales_Invoice__c> salesInvoices = SalesInvoicesSelector.newInstance().selectById(salesInvoiceIds);
        return salesInvoices;
    }

    private  List<Sales_Invoice_Job_Task__c> getJobTasks(Set<Id> salesInvoiceIds) {
        //Ticket#20402
        //List<Sales_Invoice_Job_Task__c> jobTasks = SalesInvoiceJobTasksSelector.newInstance().selectBySalesInvoiceId(salesInvoiceIds);
        List<Sales_Invoice_Job_Task__c> jobTasks = SalesInvoiceJobTasksSelector.newInstance().selectBySalesInvoiceIdForPrint(salesInvoiceIds);
        return jobTasks;
    }

    //ticket 19631 <<
    /*
    private List<Sales_Invoice_Line__c> getSalesInvoiceLines(Set<Id> salesInvoiceIds) {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Sales_Invoice_Line__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Unit_of_Measure__r.Name,Sales_Invoice__r.Bill_to_Customer__c,Resource__r.Name, TM__r.Name, Resource_Type__r.Name,' +
                'Container_Size__r.Name, Unit_Weight_Vol__r.Name ';
        strQuery += 'FROM Sales_Invoice_Line__c ';
        strQuery += 'WHERE Sales_Invoice__c IN :salesInvoiceIds AND Bill_as_Lump_Sum__c <> TRUE AND Non_Billable__c <> TRUE ';
        strQuery += 'ORDER BY Scheduled_Date__c ASC NULLS LAST, Category__c ASC NULLS LAST, Line_No__c ASC NULLS LAST';
        List<Sales_Invoice_Line__c> salesInvoiceLines = Database.query(strQuery);
        return salesInvoiceLines;
    }
    */
    private List<Sales_Invoice_Line__c> getSalesInvoiceLines(Set<Id> salesInvoiceIds, List<String> filters) {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Sales_Invoice_Line__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Unit_of_Measure__r.Name,Sales_Invoice__r.Bill_to_Customer__c,Resource__r.Name, TM__r.Name, Resource_Type__r.Name,' +
                'Container_Size__r.Name, Unit_Weight_Vol__r.Name';
        strQuery += ' FROM Sales_Invoice_Line__c';
        strQuery += ' WHERE Sales_Invoice__c IN :salesInvoiceIds AND Bill_as_Lump_Sum__c <> TRUE';
        if (filters != null && filters.size() > 0) {
            strQuery += ' AND ' + String.join(filters, ' AND ');
        }
        strQuery += ' ORDER BY Scheduled_Date__c ASC NULLS LAST, Category__c ASC NULLS LAST, Line_No__c ASC NULLS LAST';
        List<Sales_Invoice_Line__c> salesInvoiceLines = Database.query(strQuery);
        return salesInvoiceLines;
    }
    //ticket 19631 >>

    private class LinesWrapper {
        public String Category { set; get; }
        public Date ScheduledDate { set; get; }
        public Decimal Amount { set; get; }
        public List<Sales_Invoice_Line__c> InvoiceLines { set; get; }

        public LinesWrapper(String category, Date scheduledDate) {
            this.Category = category;
            this.ScheduledDate = scheduledDate;
            this.InvoiceLines = new List<Sales_Invoice_Line__c>();
            this.Amount = 0;
        }
    }

    private class TaskWrapper {
        public Sales_Invoice_Job_Task__c JobTask { set; get; }
        public Map<String, LinesWrapper> MapLinesWrappersByKey { set; get; }
        public Decimal Amount { set; get; }
        public Decimal Tax { set; get; }
        public Decimal SurchargeAmount { set; get; }

        public TaskWrapper(Sales_Invoice_Job_Task__c jobTask) {
            this.JobTask = jobTask;
            this.MapLinesWrappersByKey = new Map<String, LinesWrapper>();
            this.Amount = 0;
            this.Tax = 0;
            this.SurchargeAmount = 0;
        }

        public List<LinesWrapper> LinesWrappers {
            get {
                return this.MapLinesWrappersByKey.values();
            }
        }
    }

    private class InvoiceWrapper {
        public Sales_Invoice__c SalesInvoice { set; get;}
        public List<TaskWrapper> TaskWrappers { set; get; }
        public Date LastServiceDate { set; get; }
        public Decimal Amount { set; get; }
        public Decimal Tax { set; get; }
        public Decimal SurchargeAmount { set; get; }
        public Decimal RetainageAmount { set; get; }
        public String remName { get; set; }
        public String remAdd1 { get; set; }
        public String remAdd2 { get; set; }
        public String eftBank { get; set; }
        public String eft1 { get; set; }
        public String eft2 { get; set; }
        public String chk1 { get; set; }
        public String chk2 { get; set; }
        public String documentType { get; set; }
        public String documentDate { get; set; }
        public String remPhone { get; set; }
        public Company_Setup__c companyLogo { get; set; }
        public Service_Center__c serviceCenterLogo { get; set; }
        public Contract contractLogo { get; set; }
        public String websiteUrl { set; get; } //Ticket#21540
        public String logoURL {set; get; }

        public InvoiceWrapper(Sales_Invoice__c salesInvoice, Contract contract, Company_Setup__c companySetup, Service_Center__c serviceCenter) {
            this.SalesInvoice = salesInvoice;
            //Ticket21540 >>
            String website = salesInvoice.Bill_to_Customer__r.Subsidiary_Company__r.Website__c;
            if(String.isNotBlank(serviceCenter.Website__c)){
                website = serviceCenter.Website__c;
            }
            if(String.isNotBlank(website) && ((website.startsWithIgnoreCase('http') || website.startsWithIgnoreCase('www')) == false)){
                website = 'www.' + website;
            }
            this.websiteUrl = website;
            //Ticket21540 <<
            this.TaskWrappers = new List<TaskWrapper>();
            this.Amount = 0;
            this.Tax = 0;
            this.SurchargeAmount = 0;
            this.RetainageAmount = 0;
            if (salesInvoice.Retainage_Amount__c != null) {
                this.RetainageAmount = salesInvoice.Retainage_Amount__c;
            }

            logoURL = StringUtil.extractLogoURLFromRichTextLogoField(CompanySetup.Company_Logo__c);

            if (contract != null && contract.Override_Remittance_on_Invoice__c) {
                remName = contract.Remittance_Name__c;
                remAdd1 = contract.Remittance_Address_1__c;
                remAdd2 = contract.Remittance_Address_2__c;
                eftBank = contract.EFT_To_Bank_Name__c;
                eft1 = contract.EFT_Address_1__c;
                eft2 = contract.EFT_Address_2__c;
                chk1 = contract.Checking_Account_1__c;
                chk2 = contract.Checking_Account_2__c;
                remPhone = contract.Remittance_Phone__c;
                contractLogo = contract;
                if(String.isNotBlank(contract.Logo__c)){
                    logoURL = StringUtil.extractLogoURLFromRichTextLogoField(contract.Logo__c);
                }
            } else if (serviceCenter.Override_Remittance_on_Invoice__c) {
                remName = serviceCenter.Remittance_Name__c;
                remAdd1 = serviceCenter.Remittance_Address_1__c;
                remAdd2 = serviceCenter.Remittance_Address_2__c;
                eftBank = serviceCenter.EFT_To_Bank_Name__c;
                eft1 = serviceCenter.EFT_Address_1__c;
                eft2 = serviceCenter.EFT_Address_2__c;
                chk1 = serviceCenter.Checking_Account_1__c;
                chk2 = serviceCenter.Checking_Account_2__c;
                remPhone = serviceCenter.Remittance_Phone__c;
                serviceCenterLogo = serviceCenter;
                if(String.isNotBlank(serviceCenter.Logo__c)){
                    logoURL = StringUtil.extractLogoURLFromRichTextLogoField(serviceCenter.Logo__c);
                }
            } else {
                remName = companySetup.Remittance_Name__c;
                remAdd1 = companySetup.Remittance_Address_1__c;
                remAdd2 = companySetup.Remittance_Address_2__c;
                eftBank = companySetup.EFT_to_Bank_Name__c;
                eft1 = companySetup.EFT_Address_1__c;
                eft2 = companySetup.EFT_Address_2__c;
                chk1 = companySetup.Checking_Account_1__c;
                chk2 = companySetup.Checking_Account_2__c;
                remPhone = companySetup.Remittance_Phone__c;
                companyLogo = companySetup;
            }

            if (this.SalesInvoice.Credit_Memo__c == true){
                documentType = 'CR. MEMO';
                documentDate = 'CR. MEMO DATE';
            } else {
                documentType = 'BILLING PACKAGE';
                documentDate = 'BILLING PACKAGE DATE';
            }
        }

        public Boolean isApproved {
            get {
                if (this.SalesInvoice.Approval_Status__c != EnumUtil.ApprovalStatus.APPROVED.name()){
                    return false;
                }
                return true;
            }
            set ;
        }

        public String docType {
            get {
                if (!this.SalesInvoice.Credit_Memo__c) {
                    return 'Sales Invoice';
                } else {
                    return 'Credit Memo';
                }
            }
        }

        public String TMNames {
            get {
                Set<String> TMNos = new Set<String>();
                //ticket 20103 <<
                /*
                for (TaskWrapper taskWrapper : taskWrappers) {
                    for (LinesWrapper linesWrapper : taskWrapper.MapLinesWrappersByKey.values()) {
                        for (Sales_Invoice_Line__c salesInvoiceLine : linesWrapper.InvoiceLines) {
                            if (salesInvoiceLine.TM__r != null) {
                                TMNos.add(salesInvoiceLine.TM__r.Name);
                            }
                        }
                    }
                }
                */
                List<TM_Invoice_Relation__c> relations = [SELECT TM__r.Name FROM TM_Invoice_Relation__c WHERE Sales_Invoice__c = :salesInvoice.Id];
                if (relations.size() > 0) {
                    for (TM_Invoice_Relation__c relation : relations) {
                        TMNos.add(relation.TM__r.Name);
                    }
                }
                else {
                    //handle old sales invoices before TM_Invoice_Relation mod
                    for (TaskWrapper taskWrapper : taskWrappers) {
                        for (LinesWrapper linesWrapper : taskWrapper.MapLinesWrappersByKey.values()) {
                            for (Sales_Invoice_Line__c salesInvoiceLine : linesWrapper.InvoiceLines) {
                                if (salesInvoiceLine.TM__r != null) {
                                    TMNos.add(salesInvoiceLine.TM__r.Name);
                                }
                            }
                        }
                    }
                }
                //ticket 20103 >>
                return String.join(new List<String>(TMNos), ', ');
            }
        }
    }
}