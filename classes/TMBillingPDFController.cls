public with sharing class TMBillingPDFController {
    public Company_Setup__c CompanySetup { set; get; }
    public List<TMBillingWrapper> TMBillingWrappers { set; get; }
    public Integer tmCount { set; get; }
    public Integer taskCount { set; get; }
    public Map<Id, Contract> contractsByIds = new Map<Id, Contract>(); //Ticket#21540
    public Map<Id, Service_Center__c> serviceCentersByIds = new Map<Id, Service_Center__c>(); //Ticket#21540

    public TMBillingPDFController() {
        String id = ApexPages.currentPage().getParameters().get('id');
        String ids = ApexPages.currentPage().getParameters().get('ids');
        String download = ApexPages.currentPage().getParameters().get('download');

        Set<Id> tmIds = new Set<Id>();
        if (id != null) {
            tmIds.add(id);
        }
        else if (ids != null) {
            tmIds.addAll((List<Id>)ids.split(','));
        }

        if (tmIds.size() > 0) {
            this.print(tmIds);
            if(download != null){
                ApexPages.currentPage().getHeaders().put( 'content-disposition', 'inline; filename=' + this.TMBillingWrappers[0].TM.Name + '.pdf');
            }
        }
    }

    private void print(Set<Id> tmIds) {
        this.CompanySetup = CompanyMgmt.getCompanySetup();

        List<TM__c> tms = this.getTMs(tmIds);

        //Ticket#21540 >>
        Set<Id> contractIds = new Set<Id>();
        Set<Id> serviceCenterIds = new Set<Id>();
        for(TM__c tm : tms){
            if(tm.Service_Center__c != null){
                serviceCenterIds.add(tm.Service_Center__c);
            }
            if(tm.Contract__c != null){
                contractIds.add(tm.Contract__c);
            }
            if(tm.Sales_Order__r.Contract__c != null){
                contractIds.add(tm.Sales_Order__r.Contract__c);
            }
        }

        if(contractIds.size() > 0){
            this.contractsByIds.putAll([SELECT Id, Logo__c FROM Contract WHERE Id = :contractIds]);
        }

        if(serviceCenterIds.size() > 0){
            this.serviceCentersByIds.putAll([SELECT Id, Logo__c FROM Service_Center__c WHERE Id = :serviceCenterIds]);
        }
        //Ticket#21540 <<

        Map<Id, List<TM_Job_Task__c>> mapJobTasksByTMId = new Map<Id, List<TM_Job_Task__c>>();
        Map<Id, List<TM_Line__c>> mapTMLinesByTaskId = new Map<Id, List<TM_Line__c>>();
        for (TM_Job_Task__c jobTask : this.getJobTasks(tmIds)) {
            List<TM_Job_Task__c> jobTasks;
            if (mapJobTasksByTMId.containsKey(jobTask.TM__c)) {
                jobTasks = mapJobTasksByTMId.get(jobTask.TM__c);
            }
            else {
                jobTasks = new List<TM_Job_Task__c>();
                mapJobTasksByTMId.put(jobTask.TM__c, jobTasks);
            }
            jobTasks.add(jobTask);
        }
        for (TM_Line__c tmLine : this.getTMLines(tmIds)) {
            List<TM_Line__c> tmLines;
            if (mapTMLinesByTaskId.containsKey(tmLine.TM_Job_Task__c)) {
                tmLines = mapTMLinesByTaskId.get(tmLine.TM_Job_Task__c);
            }
            else {
                tmLines = new List<TM_Line__c>();
                mapTMLinesByTaskId.put(tmLine.TM_Job_Task__c, tmLines);
            }
            tmLines.add(tmLine);
        }

        this.TMBillingWrappers = new List<TMBillingWrapper>();
        //labor
        for (TM__c tm : tms) {
            TMBillingWrapper billingWrapper = new TMBillingWrapper(tm);

            billingWrapper.LogoUrl = StringUtil.extractLogoURLFromRichTextLogoField(this.CompanySetup.Company_Logo__c); //Ticket#23989
            if(tm.Contract__c != null && tm.Contract__r.Logo__c != null){
                billingWrapper.contractSetupLogo = this.contractsByIds.get(tm.Contract__c);
                billingWrapper.LogoUrl = StringUtil.extractLogoURLFromRichTextLogoField(tm.Contract__r.Logo__c); //Ticket#23989
            } else if (tm.Sales_Order__c != null && tm.Sales_Order__r.Contract__c != null && tm.Sales_Order__r.Contract__r.Logo__c != null){
                billingWrapper.contractSetupLogo = this.contractsByIds.get(tm.Sales_Order__r.Contract__c);
                billingWrapper.LogoUrl = StringUtil.extractLogoURLFromRichTextLogoField(tm.Sales_Order__r.Contract__r.Logo__c); //Ticket#23989
            } else if (tm.Service_Center__c != null && tm.Service_Center__r.Logo__c != null){
                billingWrapper.serviceCenterSetupLog = serviceCentersByIds.get(tm.Service_Center__c);
                billingWrapper.LogoUrl = StringUtil.extractLogoURLFromRichTextLogoField(tm.Service_Center__r.Logo__c); //Ticket#23989
            } else {
                billingWrapper.companySetupLogo = this.CompanySetup;
            }

            this.TMBillingWrappers.add(billingWrapper);

            for (TM_Job_Task__c jobTask : mapJobTasksByTMId.get(tm.Id)) {
                if (mapTMLinesByTaskId.containsKey(jobTask.Id)) { //only if TM job task contains T&M lines
                    TMBillingTaskWrapper taskWrapper = new TMBillingTaskWrapper(jobTask);
                    billingWrapper.BillingTaskWrappers.add(taskWrapper);

                    for (TM_Line__c tmLine : mapTMLinesByTaskId.get(jobTask.Id)) {
                        Decimal subtotal = CompanyMgmt.zeroIfNull(tmLine.Billing_Worksheet_Line__r.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
                        Decimal tax = (CompanyMgmt.zeroIfNull(tmLine.Billing_Worksheet_Line__r.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(tmLine.Billing_Worksheet_Line__r.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
                        Decimal total = CompanyMgmt.zeroIfNull(tmLine.Billing_Worksheet_Line__r.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
						system.debug('tmLine.Invoiced__c::::::::::::::::::::'+tmLine.Invoiced__c);
                         if(tmLine.Invoiced__c){
                                    subtotal = 0;
                                    tax =0;
                                    Total =0;
                                    
                                }
                        switch on tmLine.Category__c {
                            when 'Labor' {                              
                                    taskWrapper.LaborLineSection.TMLineWrappers.add(new TMLineWrapper(tmLine));                                
                                    taskWrapper.LaborLineSection.Subtotal += subtotal;
                                    taskWrapper.LaborLineSection.Tax += tax;
                                    taskWrapper.LaborLineSection.Total += total;
                                
                            }
                            when 'Equipment' {
                                taskWrapper.EquipmentLineSection.TMLineWrappers.add(new TMLineWrapper(tmLine));                               
                                taskWrapper.EquipmentLineSection.Subtotal += subtotal;
                                taskWrapper.EquipmentLineSection.Tax += tax;
                                taskWrapper.EquipmentLineSection.Total += total;
                            }
                            when 'Materials' {
                                taskWrapper.MaterialLineSection.TMLineWrappers.add(new TMLineWrapper(tmLine));
                                taskWrapper.MaterialLineSection.Subtotal += subtotal;
                                taskWrapper.MaterialLineSection.Tax += tax;
                                taskWrapper.MaterialLineSection.Total += total;
                            }
                            when 'Subcontractors' {
                                taskWrapper.SubcontractorLineSection.TMLineWrappers.add(new TMLineWrapper(tmLine));
                                taskWrapper.SubcontractorLineSection.Subtotal += subtotal;
                                taskWrapper.SubcontractorLineSection.Tax += tax;
                                taskWrapper.SubcontractorLineSection.Total += total;
                            }
                            when 'Waste Disposal' {
                                taskWrapper.WasteDisposalLineSection.TMLineWrappers.add(new TMLineWrapper(tmLine));
                                taskWrapper.WasteDisposalLineSection.Subtotal += subtotal;
                                taskWrapper.WasteDisposalLineSection.Tax += tax;
                                taskWrapper.WasteDisposalLineSection.Total += total;
                            }
                            when 'Demurrage' {
                                taskWrapper.DemurrageLineSection.TMLineWrappers.add(new TMLineWrapper(tmLine));
                                taskWrapper.DemurrageLineSection.Subtotal += subtotal;
                                taskWrapper.DemurrageLineSection.Tax += tax;
                                taskWrapper.DemurrageLineSection.Total += total;
                            }
                            when 'Misc. Charges And Taxes' {
                                taskWrapper.MiscChargeLineSection.TMLineWrappers.add(new TMLineWrapper(tmLine));
                                taskWrapper.MiscChargeLineSection.Subtotal += subtotal;
                                taskWrapper.MiscChargeLineSection.Tax += tax;
                                taskWrapper.MiscChargeLineSection.Total += total;
                            }
                            when 'Bundled' {
                                taskWrapper.LumpSumLineSection.TMLineWrappers.add(new TMLineWrapper(tmLine));
                                taskWrapper.LumpSumLineSection.Subtotal += subtotal;
                                taskWrapper.LumpSumLineSection.Tax += tax;
                                taskWrapper.LumpSumLineSection.Total += total;
                            }
                        }

                        taskWrapper.Subtotal += subtotal;
                        taskWrapper.Tax += tax;
                        taskWrapper.Total += total;

                        billingWrapper.Subtotal += subtotal;
                        billingWrapper.Tax += tax;
                        billingWrapper.Total += total;
                    }
                }
            }
        }
    }

    /*
     *  Ticket#21540 add Service Center Logo to the query.
     */
    private List<TM__c> getTMs(Set<Id> tmIds) {
        List<String> fields = new List<String>();
        for (Schema.SObjectField field : Schema.SObjectType.TM__c.fields.getMap().values()) {
            fields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(fields, ',') + ',' +
                'Contract__r.Name, Bill_To_Customer__r.Name, Bill_To_Customer__r.AccountNumber,' +
                'Bill_To_Customer__r.Account_Executive__r.Name,Sales_Order__r.Name,Tax_Area__r.Name, Site_Contact_2__r.Name,' +
                'Account_Executive__r.Name, Project_Coordinator__r.Name, Contact__r.Name, Contact__r.FirstName, Contact__r.LastName,' +
                'Bill_to_Customer__r.Pricing_Group__c, Bill_to_Customer__r.BillingCity, Bill_to_Customer__r.BillingStreet,' +
                'Bill_to_Customer__r.BillingState, Bill_to_Customer__r.BillingPostalCode, Bill_to_Customer__r.BillingCountry,' +
                'Bill_to_Customer__r.Payment_Term__c, Contract__r.Allow_Lunch_Time_on_Equipment__c,Sales_Order__r.Sales_Order_Type__r.Name, ' +
                'Sales_Order__r.Street__c, Sales_Order__r.City__c, Sales_Order__r.State__c, Sales_Order__r.Postal_Code__c,' +
                'Service_Center__r.Name, Service_Center__r.Disable_TM_Printing__c,' +
                'Contract__r.Logo__c, Sales_Order__r.Contract__c, Sales_Order__r.Contract__r.Logo__c, Service_Center__r.Logo__c' +
                ' FROM TM__c WHERE Id IN :tmIds';
        return Database.query(strQuery);
    }

    private List<TM_Job_Task__c> getJobTasks(Set<Id> tmIds) {
        return TMJobTasksSelector.newInstance().selectByTMId(tmIds);
    }

    private List<TM_Line__c> getTMLines(Set<Id> tmIds) {
        List<String> fields = new List<String>();
        for (Schema.SObjectField field : Schema.SObjectType.TM_Line__c.fields.getMap().values()) {
            fields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(fields, ',') + ',' +
                'Unit_of_Measure__r.Name, Resource__r.Name, Resource__r.Description__c, Resource_Type__r.Name,Job_Type__r.Name,' +
                'Service_Center__r.Name, Resource__r.Silver_Rate__c, Resource__r.Silver_ER_Rate__c, Resource__r.Platinum_Rate__c, Resource__r.Fleet_Number__c, ' +
                'Resource__r.Platinum_ER_Rate__c, Resource__r.Gold_Rate__c, Resource__r.Gold_ER_Rate__c, Resource__r.Unit_of_Measure__c, Contract_Line__r.Name,' +
                'Facility__r.Name, Container_Size__r.Name, Unit_Weight_Vol__r.Name, ' +
                'Billing_Worksheet_Line__r.Unit_Price__c, Billing_Worksheet_Line__r.Regular_Rate__c, Billing_Worksheet_Line__r.Overtime_Rate__c, Billing_Worksheet_Line__r.Premium_Rate__c, ' +
                'Billing_Worksheet_Line__r.Regular_Hours__c, Billing_Worksheet_Line__r.Overtime_Hours__c, Billing_Worksheet_Line__r.Premium_Hours__c, ' +
                'Billing_Worksheet_Line__r.Line_Amount__c, Billing_Worksheet_Line__r.Line_Amt_Incl_Tax__c, Billing_Worksheet_Line__r.Tax__c, ' +
                'Billing_Worksheet_Line__r.Billing_Start_Time__c, Billing_Worksheet_Line__r.Billing_End_Time__c, Billing_Worksheet_Line__r.Include_Lunch_Y_N__c, Billing_Worksheet_Line__r.Hour__c, ' +
                'Billing_Worksheet_Line__r.Quantity__c ' +
                'FROM TM_Line__c WHERE TM__c IN :tmIds ORDER BY TM__c, Line_No__c';
        return Database.query(strQuery);
    }


    //line wrapper
    public class TMLineWrapper {
        public TM_Line__c TMLine { get; set;}

        public TMLineWrapper(TM_Line__c tmLine) {
            this.TMLine = tmLine;
            this.TMLine.Regular_Hours__c = 0;
            this.TMLine.Overtime_Hours__c = 0;
            this.TMLine.Premium_Hours__c = 0;
            this.TMLine.Regular_Rate__c = 0;
            this.TMLine.Overtime_Rate__c = 0;
            this.TMLine.Premium_Rate__c = 0;
            if (tmLine.Billing_Worksheet_Line__r != null) {
                this.TMLine.Unit_Price__c = tmLine.Billing_Worksheet_Line__r.Unit_Price__c;
                this.TMLine.Line_Amount__c = tmLine.Billing_Worksheet_Line__r.Line_Amount__c;
                this.TMLine.Line_Amt_Incl_Tax__c = tmLine.Billing_Worksheet_Line__r.Line_Amt_Incl_Tax__c;
                this.TMLine.Tax__c = tmLine.Billing_Worksheet_Line__r.Tax__c;
                this.TMLine.Billing_Start_Time__c = tmLine.Billing_Worksheet_Line__r.Billing_Start_Time__c;
                this.TMLine.Billing_End_Time__c = tmLine.Billing_Worksheet_Line__r.Billing_End_Time__c;
                this.TMLine.Quantity__c = tmLine.Billing_Worksheet_Line__r.Quantity__c; //Ticket#21793
                this.TMLine.Include_Lunch_Y_N__c = tmLine.Billing_Worksheet_Line__r.Include_Lunch_Y_N__c;
                this.TMLine.Hour__c = tmLine.Billing_Worksheet_Line__r.Hour__c;
                if(tmLine.Invoiced__c)
                {
                   this.TMLine.Line_Amount__c = 0; 
                   this.TMLine.Unit_Price__c = 0;
                }
                if (tmLine.Category__c == 'Labor') {
                    
                    this.TMLine.Regular_Hours__c = tmLine.Billing_Worksheet_Line__r.Regular_Hours__c;
                    this.TMLine.Overtime_Hours__c = tmLine.Billing_Worksheet_Line__r.Overtime_Hours__c;
                    this.TMLine.Premium_Hours__c = tmLine.Billing_Worksheet_Line__r.Premium_Hours__c;
                    this.TMLine.Regular_Rate__c = tmLine.Billing_Worksheet_Line__r.Regular_Rate__c;
                    this.TMLine.Overtime_Rate__c = tmLine.Billing_Worksheet_Line__r.Overtime_Rate__c;
                    this.TMLine.Premium_Rate__c = tmLine.Billing_Worksheet_Line__r.Premium_Rate__c;
                    if(tmLine.Invoiced__c)
                    {
                        this.TMLine.Regular_Rate__c = 0;
                        this.TMLine.Overtime_Rate__c = 0;
                        this.TMLine.Premium_Rate__c = 0;                        
                        
                    }
                   
                }
            }
        }
    }

    //category wrapper
    public class TMCategoryWrapper {
        public List<TMLineWrapper> TMLineWrappers { set; get; }
        public Decimal Subtotal { set; get; }
        public Decimal Tax { set; get; }
        public Decimal Total { set; get; }

        public TMCategoryWrapper() {
            this.Subtotal = 0;
            this.Tax = 0;
            this.Total = 0;
            this.TMLineWrappers = new List<TMLineWrapper>();
        }
    }

    //task wrapper
    public class TMBillingTaskWrapper {
        public TM_Job_Task__c JobTask { set; get; }
        public TMCategoryWrapper LaborLineSection { set; get; }
        public TMCategoryWrapper EquipmentLineSection { set; get; }
        public TMCategoryWrapper MaterialLineSection { set; get; }
        public TMCategoryWrapper SubcontractorLineSection { set; get; }
        public TMCategoryWrapper WasteDisposalLineSection { set; get; }
        public TMCategoryWrapper DemurrageLineSection { set; get; }
        public TMCategoryWrapper LumpSumLineSection { set; get; }
        public TMCategoryWrapper MiscChargeLineSection { set; get; }
        public Decimal Subtotal { set; get; }
        public Decimal Tax { set; get; }
        public Decimal Total { set; get; }

        public TMBillingTaskWrapper(TM_Job_Task__c jobTask) {
            this.JobTask = jobTask;
            this.LaborLineSection = new TMCategoryWrapper();
            this.EquipmentLineSection = new TMCategoryWrapper();
            this.MaterialLineSection = new TMCategoryWrapper();
            this.SubcontractorLineSection = new TMCategoryWrapper();
            this.WasteDisposalLineSection = new TMCategoryWrapper();
            this.DemurrageLineSection = new TMCategoryWrapper();
            this.LumpSumLineSection = new TMCategoryWrapper();
            this.MiscChargeLineSection = new TMCategoryWrapper();
            this.Subtotal = 0;
            this.Tax = 0;
            this.Total = 0;
        }
    }

    //billing wrapper
    public class TMBillingWrapper {
        public TM__c TM { set; get; }
        public List<TMBillingTaskWrapper> BillingTaskWrappers { set; get; }
        public Decimal Subtotal { set; get; }
        public Decimal Tax { set; get; }
        public Decimal Total { set; get; }
        public Company_Setup__c companySetupLogo { set; get; } //Ticket#21540
        public Service_Center__c serviceCenterSetupLog { set; get; } //Ticket#21540
        public Contract contractSetupLogo { set; get; } //Ticket#21540
        public String LogoUrl {set; get;} //Ticket#23989

        public TMBillingWrapper(TM__c tm) {
            this.TM = tm;
            this.BillingTaskWrappers = new List<TMBillingTaskWrapper>();
            this.Subtotal = 0;
            this.Tax = 0;
            this.Total = 0;
        }
    }


}