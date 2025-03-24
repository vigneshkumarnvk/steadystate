public with sharing class FieldTMPDFController {
    private final Integer MINIMUM_LABOR_LINES = 10;
    private final Integer MINIMUM_EQUIPMENT_LINES = 15;
    private final Integer MINIMUM_MATERIAL_LINES = 15;
    private final Integer MINIMUM_WASTE_DISPOSAL_LINES = 3;
    private final Integer MINIMUM_SUBCONTRACTOR_LINES = 3;

    public TM__c TM {get; set;}
    public Company_Setup__c CompanySetup { set; get; }
    public List<FieldTMWrapper> FieldTMWrappers { set; get; }
    public Map<Boolean, String> CheckboxUrl { get; set; }

    public Integer tmCount { set; get; }
    public Integer taskCount { set; get; }

    private Map<Id, String> mapContractLineDescriptionsByTMLineId;
    //Ticket#21540 >>
    public Map<Id, Contract> contractsByIds = new Map<Id, Contract>();
    public Map<Id, Service_Center__c> serviceCentersByIds = new Map<Id, Service_Center__c>();
    //Ticket#21540 <<

    public FieldTMPDFController() {
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
        }

        if(download != null){
            ApexPages.currentPage().getHeaders().put( 'content-disposition', 'inline; filename=' + this.TM.Name + '.pdf');
        }
    }

    public void print(Set<Id> tmIds) {
        this.CompanySetup = CompanyMgmt.getCompanySetup();

        this.CheckboxUrl = new Map<Boolean, String>();
        this.CheckboxUrl.put(true, '<img src="/img/checkbox_checked.gif"/>');
        this.CheckboxUrl.put(false, '<span class="chkbx">&nbsp;&nbsp;&nbsp;&nbsp;</span>');

        List<TM__c> tms = this.getTMs(tmIds);
        this.TM = tms[0]; //for download field T&M page.

        if(this.TM.Service_Center__r.Disable_TM_Printing__c == true){
            throw new DataException('T&M Printing is disabled for Service Center ' + this.TM.Service_Center__r.Name);
        }

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

        Map<Id, List<TM_Job_Task__c>> mapJobTasksByTMId = new Map<Id, List<TM_Job_Task__c>>();
        Map<Id, List<TM_Line__c>> mapTMLinesByTaskId = new Map<Id, List<TM_Line__c>>();
        Map<Id, List<Signature__c>> mapSignaturesByTMId = new Map<Id, List<Signature__c>>();

        for (TM_Job_Task__c jobTask : TMJobTasksSelector.newInstance().selectByTMId(tmIds)) {
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

        List<TM_Line__c> tmls = this.getTMLines(tmIds);
        this.mapContractLineDescriptionsByTMLineId = TMLLinesService.retrieveContractLinesTMDescription(tmls);

        for (TM_Line__c tmLine : tmls) {
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

        for (Signature__c signature : this.getSignatures(tmIds)) {
            List<Signature__c> signatures;
            if (mapSignaturesByTMId.containsKey(signature.TM__c)) {
                signatures = mapSignaturesByTMId.get(signature.TM__c);
            }
            else {
                signatures = new List<Signature__c>();
                mapSignaturesByTMId.put(signature.TM__c, signatures);
            }
            signatures.add(signature);
        }
        this.initData(tms, mapJobTasksByTMId, mapTMLinesByTaskId, mapSignaturesByTMId);
        //this.initSignatures();
    }


    public void initData(List<TM__c> tms, Map<Id, List<TM_Job_Task__c>> mapJobTasksByTMId, Map<Id, List<TM_Line__c>> mapTMLinesByTaskId, Map<Id, List<Signature__c>> mapSignaturesByTMId) {
        Map<Id, FieldTMWrapper> mapFieldTMWrappersById = new Map<Id, FieldTMWrapper>();
        for (TM__c tm : tms) {
            FieldTMWrapper fieldTMWrapper = new FieldTMWrapper(tm);

            fieldTMWrapper.LogoUrl = StringUtil.extractLogoURLFromRichTextLogoField(this.CompanySetup.Company_Logo__c); //Ticket#23989
            if(tm.Contract__c != null && tm.Contract__r.Logo__c != null){
                fieldTMWrapper.contractSetupLogo = this.contractsByIds.get(tm.Contract__c);
                fieldTMWrapper.LogoUrl = StringUtil.extractLogoURLFromRichTextLogoField(tm.Contract__r.Logo__c); //Ticket#23989
            } else if (tm.Sales_Order__c != null && tm.Sales_Order__r.Contract__c != null && tm.Sales_Order__r.Contract__r.Logo__c != null){
                fieldTMWrapper.contractSetupLogo = this.contractsByIds.get(tm.Sales_Order__r.Contract__c);
                fieldTMWrapper.LogoUrl = StringUtil.extractLogoURLFromRichTextLogoField(tm.Sales_Order__r.Contract__r.Logo__c); //Ticket#23989
            } else if (tm.Service_Center__c != null && tm.Service_Center__r.Logo__c != null){
                fieldTMWrapper.serviceCenterSetupLog = serviceCentersByIds.get(tm.Service_Center__c);
                fieldTMWrapper.LogoUrl = StringUtil.extractLogoURLFromRichTextLogoField(tm.Service_Center__r.Logo__c); //Ticket#23989
            } else {
                fieldTMWrapper.companySetupLogo = this.CompanySetup;
            }

            mapFieldTMWrappersById.put(tm.Id, fieldTMWrapper);

            List<TM_Job_Task__c> jobTasks = mapJobTasksByTMId.get(tm.Id);
            for (TM_Job_Task__c jobTask : jobTasks) {
                FieldTMTaskWrapper fieldTMTaskWrapper = new FieldTMTaskWrapper(jobTask);
                fieldTMWrapper.TMTaskWrappers.add(fieldTMTaskWrapper);

                List<TM_Line__c> tmLines = mapTMLinesByTaskId.get(jobTask.Id);
                if (tmLines != null) {
                    for (TM_Line__c tmLine : tmLines) {
                        String contractLineDescription;
                        if (this.mapContractLineDescriptionsByTMLineId.containsKey(tmLine.Id)) {
                            contractLineDescription = mapContractLineDescriptionsByTMLineId.get(tmLine.Id);
                        }

                        switch on tmLine.Category__c {
                            when 'Labor' {
                                fieldTMTaskWrapper.LaborLineWrappers.add(new FieldTMLineWrapper(tmLine, contractLineDescription));
                            }
                            when 'Equipment' {
                                fieldTMTaskWrapper.EquipmentLineWrappers.add(new FieldTMLineWrapper(tmLine, contractLineDescription));
                            }
                            when 'Materials' {
                                fieldTMTaskWrapper.MaterialLineWrappers.add(new FieldTMLineWrapper(tmLine, contractLineDescription));
                            }
                            when 'Waste Disposal' {
                                if (tmLine.Cost_Method__c == EnumUtil.CostMethod.CONTAINER.name()) {
                                    tmLine.Unit_of_Measure__c = tmLine.Container_Size__c;
                                    tmLine.Unit_of_Measure__r = tmLine.Container_Size__r;
                                } else if (tmLine.Cost_Method__c == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name()) {
                                    tmLine.Unit_of_Measure__c = tmLine.Unit_Weight_Vol__c;
                                    tmLine.Unit_of_Measure__r = tmLine.Unit_Weight_Vol__r;
                                }
                                fieldTMTaskWrapper.WasteDisposalLineWrappers.add(new FieldTMLineWrapper(tmLine, contractLineDescription));
                            }
                            when 'Subcontractors' {
                                fieldTMTaskWrapper.SubcontractorLineWrappers.add(new FieldTMLineWrapper(tmLine, contractLineDescription));
                            }
                        }
                    } //end of tm line loop
                }

                //labor lines - add empty lines
                for (Integer i = fieldTMTaskWrapper.LaborLineWrappers.size(); i < this.MINIMUM_LABOR_LINES; i++) {
                    fieldTMTaskWrapper.LaborLineWrappers.add(new FieldTMLineWrapper(new TM_Line__c(TM__c = tm.Id), null));
                }
                fieldTMTaskWrapper.LaborLineWrappers[0].Note = 'Lunch Taken: Yes No';
                fieldTMTaskWrapper.LaborLineWrappers[1].Note = 'If Yes, Time: ';

                //equipment lines - add empty lines
                for (Integer i = fieldTMTaskWrapper.EquipmentLineWrappers.size(); i < this.MINIMUM_EQUIPMENT_LINES; i++) {
                    fieldTMTaskWrapper.EquipmentLineWrappers.add(new FieldTMLineWrapper(new TM_Line__c(TM__c = tm.Id), null));
                }

                //material lines - add empty lines
                for (Integer i = fieldTMTaskWrapper.MaterialLineWrappers.size(); i < this.MINIMUM_MATERIAL_LINES; i++) {
                    fieldTMTaskWrapper.MaterialLineWrappers.add(new FieldTMLineWrapper(new TM_Line__c(TM__c = tm.Id), null));
                }

                //waste disposal lines - add empty lines
                for (Integer i = fieldTMTaskWrapper.WasteDisposalLineWrappers.size(); i < this.MINIMUM_WASTE_DISPOSAL_LINES; i++) {
                    fieldTMTaskWrapper.WasteDisposalLineWrappers.add(new FieldTMLineWrapper(new TM_Line__c(TM__c = tm.Id), null));
                }
                //subcontractor lines - add empty lines
                for (Integer i = fieldTMTaskWrapper.SubcontractorLineWrappers.size(); i < this.MINIMUM_SUBCONTRACTOR_LINES; i++) {
                    fieldTMTaskWrapper.SubcontractorLineWrappers.add(new FieldTMLineWrapper(new TM_Line__c(TM__c = tm.Id), null));
                }

                //signatures
                if (mapSignaturesByTMId.containsKey(tm.Id)) {
                    fieldTMWrapper.CustomerANotAvailable = false;
                    fieldTMWrapper.CustomerBNotAvailable = false;
                    Map<Id, Signature__c> signatures = new Map<Id, Signature__c>();

                    for (Signature__c signature : mapSignaturesByTMId.get(tm.Id)) {
                        if (signature.Signer_Role__c == 'Supervisor') {
                            fieldTMWrapper.SupervisorName = signature.Print_Name__c;
                            if (signature.Attachments.size() > 0) {
                                fieldTMWrapper.SupervisorSignatureFileId = signature.Attachments[0].Id;
                            }
                        } else if (signature.Signer_Role__c == 'Customer A') {
                            fieldTMWrapper.CustomerANotAvailable = signature.Customer_Not_Available__c;
                            fieldTMWrapper.CustomerAName = signature.Print_Name__c;
                            //ticket 21770 <<
                            //fieldTMWrapper.CustomerASignatureDate = signature.Signature_Date__c.date();
                            if (signature.Signature_Date__c != null) {
                                fieldTMWrapper.CustomerASignatureDate = signature.Signature_Date__c.date();
                            }
                            ///ticket 21770 >>
                            if (signature.Attachments.size() > 0) {
                                fieldTMWrapper.CustomerASignatureFileId = signature.Attachments[0].Id;
                            }
                            fieldTMWrapper.CustomerARequestingSignature = false;
                            if (signature.Request_Signature__c == true && signature.Signed__c != true) {
                                fieldTMWrapper.CustomerARequestingSignature = true;
                            }
                        } else if (signature.Signer_Role__c == 'Customer B') {
                            fieldTMWrapper.CustomerBNotAvailable = signature.Customer_Not_Available__c;
                            fieldTMWrapper.CustomerBName = signature.Print_Name__c;
                            //ticket 21770 <<
                            //fieldTMWrapper.CustomerBSignatureDate = signature.Signature_Date__c.date();
                            if (signature.Signature_Date__c != null) {
                                fieldTMWrapper.CustomerBSignatureDate = signature.Signature_Date__c.date();
                            }
                            //ticket 21770 >>
                            if (signature.Attachments.size() > 0) {
                                fieldTMWrapper.CustomerBSignatureFileId = signature.Attachments[0].Id;
                            }

                            fieldTMWrapper.CustomerBRequestingSignature = false;
                            if (signature.Request_Signature__c == true && signature.Signed__c != true) {
                                fieldTMWrapper.CustomerBRequestingSignature = true;
                            }
                        }
                    }
                }
            } //end of tasks loop
        } //end of tm loop

        this.FieldTMWrappers = mapFieldTMWrappersById.values();
    }

    public void initSignatures() {
        /*
        ApexPages.currentPage().getHeaders().put('content-disposition', 'filename=' + this.TM.Name + '.pdf');
        this.CustomerANotAvailable = false;
        this.CustomerBNotAvailable = false;
        Map<Id, Signature__c> signatures = new Map<Id, Signature__c>();

        for (Signature__c signature : [SELECT Id, Name, Signer_Role__c, Print_Name__c, Signature_Date__c, Customer_Not_Available__c, Request_Signature__c, Signed__c,
        (SELECT Id FROM Attachments ORDER BY CreatedDate DESC)
        FROM Signature__c WHERE TM__c =:this.TM.Id AND Voided__c <> TRUE]) {
            if (signature.Signer_Role__c == 'Supervisor') {
                this.SupervisorName = signature.Print_Name__c;
                if (signature.Attachments.size() > 0) {
                    this.SupervisorSignatureFileId = signature.Attachments[0].Id;
                }
            }
            else if (signature.Signer_Role__c == 'Customer A') {
                this.CustomerANotAvailable = signature.Customer_Not_Available__c;
                this.CustomerAName = signature.Print_Name__c;
                this.CustomerASignatureDate = signature.Signature_Date__c.date();

                if (signature.Attachments.size() > 0) {
                    this.CustomerASignatureFileId = signature.Attachments[0].Id; //URL.getFileFieldURL(attach.Id, 'Body');
                }
                this.CustomerARequestingSignature = false;
                if (signature.Request_Signature__c == true && signature.Signed__c != true) {
                    this.CustomerARequestingSignature = true;
                }
            }
            else if (signature.Signer_Role__c == 'Customer B') {
                this.CustomerBNotAvailable = signature.Customer_Not_Available__c;
                this.CustomerBName = signature.Print_Name__c;
                this.CustomerBSignatureDate = signature.Signature_Date__c.date();
                if (signature.Attachments.size() > 0) {
                    this.CustomerBSignatureFileId = signature.Attachments[0].Id; //URL.getFileFieldURL(attach.Id, 'Body');
                }

                this.CustomerBRequestingSignature = false;
                if (signature.Request_Signature__c == true && signature.Signed__c != true) {
                    this.CustomerBRequestingSignature = true;
                }
            }
        }*/
    }

    /*
     *  Ticket#21540 add Service Center Logo, Disable TM Printing, Contract__r.Logo to the query.
     */
    private List<TM__c> getTMs(Set<Id> tmIds) {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.TM__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',') +
                ', Contract__r.Name, Bill_To_Customer__r.Name, Bill_To_Customer__r.AccountNumber' +
                ', Bill_To_Customer__r.Account_Executive__r.Name,Sales_Order__r.Name,Tax_Area__r.Name, Alternate_Site_Address__r.Name ' +
                ', Account_Executive__r.Name, Project_Coordinator__r.Name, Contact__r.Name, Contact__r.FirstName, Contact__r.LastName' +
                ', Bill_to_Customer__r.Pricing_Group__c, Bill_to_Customer__r.BillingCity, Bill_to_Customer__r.BillingStreet' +
                ', Bill_to_Customer__r.BillingState, Bill_to_Customer__r.BillingPostalCode, Bill_to_Customer__r.BillingCountry' +
                ', Bill_to_Customer__r.Payment_Term__c, Bill_to_Customer__r.Print_TM_Time_Detail__c, Sales_Order__r.From_Sales_Quote__c, Site_Contact_2__r.Name' +
                ', Sales_Order__r.Surcharge_Type__c, Sales_Order__r.Surcharge_Pct__c, Contract__r.ContractNumber, Bill_to_Customer__r.ParentId' +
                ', Contract__r.Allow_Lunch_Time_on_Equipment__c, Sales_Order__r.Sales_Order_Type__r.Emergency_Response__c,Sales_Order__r.Pay_Rule__c' +
                ', Contract__r.Billing_Rule__c, Sales_Order__r.Rate_Sheet__c, TM__c.Rate_Sheet__r.Name,Sales_Order__r.Portal_Basis__c,Sales_Order__r.Overtime_Rate__c' +
                ', Sales_Order__r.Daily_Rate__c,Sales_Order__r.Lump_Sum__c, Sales_Order__r.Billing_Rule_Not_Required__c,Sales_Order__r.Manifest_And_Profile__c' +
                ', Sales_Order__r.Charge_Rinse_Out_Fee__c, Sales_Order__r.Sales_Order_Type__r.Name, Service_Center__r.Name, Service_Center__r.Disable_TM_Printing__c' +
                ', Contract__r.Logo__c, Sales_Order__r.Contract__c, Sales_Order__r.Contract__r.Logo__c, Service_Center__r.Logo__c' +
                ' FROM TM__c WHERE Id IN :tmIds';
        List<TM__c> tms = (List<TM__c>)Database.query(strQuery);
        return tms;
    }

    private List<TM_Job_Task__c> getJobTasks(Set<Id> tmIds) {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.TM_Job_Task__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }

        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM TM_Line__c WHERE TM__c IN :tmId ORDER BY Task_No__c';
        return Database.query(strQuery);
    }

    private List<TM_Line__c> getTMLines(Set<Id> tmIds) {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.TM_Line__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',TM__r.Name, TM_Job_Task__r.Name, TM_Job_Task__r.Line_No__c, TM_Job_Task__r.Billing_Type__c, Unit_of_Measure__r.Name, Resource__r.Name, Resource__r.Description__c, Resource_Type__r.Name, Job_Type__r.Name,TM__r.Scheduled_Date__c';
        strQuery += ' ,Drop_Off_R_O__r.Sales_Order__c, Drop_Off_R_O__r.Resource__c, Drop_Off_R_O__r.Pick_Up_Date__c, Resource_Type__r.Description__c, Resource_Type__r.Fleet_No_Required__c ';
        strQuery += ' ,Service_Center__r.Name, Resource__r.Silver_Rate__c, Resource__r.Silver_ER_Rate__c, Resource__r.Platinum_Rate__c, Resource__r.Fleet_Number__c, ' +
                'Resource__r.Platinum_ER_Rate__c, Resource__r.Gold_Rate__c, Resource__r.Gold_ER_Rate__c, Contract_Line__r.Name, Resource__r.Employee_No__c, ' +
                'Service_Center__r.Equipment_Fleet_No_Not_Required__c,Resource__r.Service_Center__c, Sales_Line__r.Unit_of_Measure__c, Sales_Line__r.Unit_Price__c';
        strQuery += ', Resource_Type__r.Unit_of_Measure__c, Resource_Type__r.Unit_of_Measure1__c, Resource_Type__r.Unit_of_Measure2__c, Resource_Type__r.Unit_of_Measure3__c, Resource_Type__r.Unit_of_Measure4__c ';
        strQuery += ', Resource__r.Unit_of_Measure__c, Resource__r.Unit_of_Measure1__c, Resource__r.Unit_of_Measure2__c, Resource__r.Unit_of_Measure3__c, Resource__r.Unit_of_Measure4__c ' +
                ',Resource__r.Non_Payroll_Labor_Resource__c, Service_Center__r.Temporary__c, Unit_of_Measure__r.Hours_UOM__c, ' +
                'TM__r.Sales_Order__r.Portal_Basis__c, TM__r.Sales_Order__r.Overtime_Rate__c, TM__r.Sales_Order__r.Daily_Rate__c,' +
                'TM__r.Sales_Order__r.Lump_Sum__c, Resource_Type__r.Fuel_Fired_Equipment__c, Container_Size__r.Name, Unit_Weight_Vol__r.Name, Facility__r.Name, Resource__r.Resource_Type__c,' +
                'TM__r.Sales_Order__r.Billing_Rule_Not_Required__c, Resource__r.Has_Container__c, Resource__r.Has_Weight_Volume__c';
        strQuery += ' FROM TM_Line__c WHERE TM__c IN :tmIds ORDER BY Line_No__c';
        return Database.query(strQuery);
    }

    private List<Signature__c> getSignatures(Set<Id> tmIds) {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Signature__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ', (SELECT Id FROM Attachments ORDER BY CreatedDate DESC)';
        strQuery += ' FROM Signature__c WHERE TM__c IN :tmIds AND Voided__c <> TRUE';
        return Database.query(strQuery);
    }

    public class FieldTMLineWrapper {
        public TM_Line__c TMLine { get; set;}
        public String Note {get; set; }
        public String ContractLineDescription {get;set;}

        public FieldTMLineWrapper(TM_Line__c tml, String contractLineDescription){
            this.TMLine = tml;
            this.ContractLineDescription = contractLineDescription;
        }

        public String JobStartTime {
            get {
                String timeString;
                if (this.TMLine.Job_Start_Time__c != null) {
                    timeString = String.valueOf(this.TMLine.Job_Start_Time__c).left(5);
                }
                return timeString;
            }
        }

        public String JobEndTime {
            get {
                String timeString;
                if (this.TMLine.Job_End_Time__c != null) {
                    timeString = String.valueOf(this.TMLine.Job_End_Time__c).left(5);
                }
                return timeString;
            }
        }

        public String SiteStartTime {
            get {
                String timeString;
                if (this.TMLine.Site_Start_Time__c != null) {
                    timeString = String.valueOf(this.TMLine.Site_Start_Time__c).left(5);
                }
                return timeString;
            }
        }

        public String SiteEndTime {
            get {
                String timeString;
                if (this.TMLine.Site_End_Time__c != null) {
                    timeString = String.valueOf(this.TMLine.Site_End_Time__c).left(5);
                }
                return timeString;
            }
        }
    }

    public class FieldTMTaskWrapper {
        public TM_Job_Task__c JobTask { set; get; }
        public List<FieldTMLineWrapper> LaborLineWrappers { set; get; }
        public List<FieldTMLineWrapper> EquipmentLineWrappers { set; get; }
        public List<FieldTMLineWrapper> MaterialLineWrappers { set; get; }
        public List<FieldTMLineWrapper> WasteDisposalLineWrappers { set; get; }
        public List<FieldTMLineWrapper> SubcontractorLineWrappers { set; get; }

        public FieldTMTaskWrapper(TM_Job_Task__c jobTask) {
            this.JobTask = jobTask;
            this.LaborLineWrappers = new List<FieldTMLineWrapper>();
            this.EquipmentLineWrappers = new List<FieldTMLineWrapper>();
            this.MaterialLineWrappers = new List<FieldTMLineWrapper>();
            this.WasteDisposalLineWrappers = new List<FieldTMLineWrapper>();
            this.SubcontractorLineWrappers = new List<FieldTMLineWrapper>();
        }
    }

    public class FieldTMWrapper {
        public TM__c TM { set; get; }
        public List<FieldTMTaskWrapper> TMTaskWrappers { set; get; }
        public String SupervisorName { set; get; }
        public String SupervisorSignatureFileId { set; get; }
        public String CustomerAName { set; get; }
        public String CustomerASignatureFileId { set; get; }
        public Boolean CustomerANotAvailable { set; get; }
        public Date CustomerASignatureDate { set; get; }
        public String CustomerBName { set; get; }
        public String CustomerBSignatureFileId { set; get; }
        public Boolean CustomerBNotAvailable { set; get; }
        public Date CustomerBSignatureDate { set; get; }
        public Boolean CustomerARequestingSignature { set; get; }
        public Boolean CustomerBRequestingSignature { set; get; }
        public Company_Setup__c companySetupLogo { set; get; } //Ticket#21540
        public Service_Center__c serviceCenterSetupLog { set; get; } //Ticket#21540
        public Contract contractSetupLogo { set; get; } //Ticket#21540
        public String LogoUrl { set; get; } //Ticket#23989

        public FieldTMWrapper(TM__c tm) {
            this.TM = tm;
            this.TMTaskWrappers = new List<FieldTMTaskWrapper>();
        }
    }
}