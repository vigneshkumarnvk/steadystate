/*************************************************************************************************
* Name         :  AccountController
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Sai Kumar 		    22-01-2025      		DE37531: Salesforce - Convert Prospect to Customer Cannot select NONE in PO Format field 
*************************************************************************************************/
public with sharing class AccountController {
    private final ApexPages.StandardController controller;
    public Account Account { set; get; }
    //billing contact <<
    public List<SelectOption> BillingContactOptions { set; get; }
    public Id BillingContactId { set; get; }
    //billing contact >>
    public User theUser { get; set; }
    public String SCompany { get; set; }
    public String SCompanyId { get; set; }
    public String SalesOrderType { get; set;}
    public String SalesOrderTypeDescription { get; set; }
    public String SalesOrderTypeId { get; set; }
    public String ownerId { get; set; }
    public String company { get; set; }
    private Company_Setup__c theCompanySetup = CompanyMgmt.getCompanySetup(); //Ticket AES-424
    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    public Sales_Order_Type__c SOType { get; set;}
    public User ownerUsr{get; set;}
    public Boolean isERCustomer{get; set;} //Ticket#13807 AES-394
    String surchargeType; //Ticket#14268
    public Contract theContract { get; set; } //AES-441
    public Boolean hasBillingContact {get; set;} //Ticket#20977

    public List<String> selectedSalespersons { get; set; }
    public List<SelectOption> salespersonOptions { get; set; }
    //DE37531
    public Boolean hasPONumberType {get; set;}
    public List<SelectOption> PONumberTypeOptions { set; get; }
    public String SelectedPONumberType{ set; get; }


    public AccountController(ApexPages.StandardController controller) {
        this.controller = controller;
        this.Account = GetRecord();
        selectUser();
        SetCompany();
        fetchSalespersons();
        SOType = new Sales_Order_Type__c();
        ownerUsr = theUser; //Ticket#14150
        ownerId = theUser.Id; //Ticket#14150
        isERCustomer = this.Account.Emergency__c; //Ticket#13807 AES-394
        theContract = new Contract(); //AES-441

        //billing contact <<
        List<AccountContactRelation> relations = [SELECT Id, ContactId, Contact.Name FROM AccountContactRelation WHERE AccountId = :this.Account.Id AND Contact.Contact_Type__c INCLUDES ('Billing')];
        //Ticket#20977 >>
        if(relations.size() > 0){
            hasBillingContact = true;
        } else {
            hasBillingContact = false;
        }
        //Ticket#20977 <<

        this.BillingContactOptions = new List<SelectOption>();
        this.BillingContactOptions.add(new SelectOption('', ''));
        for (AccountContactRelation relation : relations) {
            this.BillingContactOptions.add(new SelectOption(relation.ContactId, relation.Contact.Name));
        }
        //billing contact >>
        //DE37531
        this.PONumberTypeOptions = new List<SelectOption>();
        this.PONumberTypeOptions.add(new SelectOption('', ''));
        this.PONumberTypeOptions.add(new SelectOption('None', 'None'));
        
        //Getting Picklist values dynamically
        Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get('Account');
        Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe() ;
        Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get('PO_Number_Type__c').getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            this.PONumberTypeOptions.add(new SelectOption(pickListVal.getValue(), pickListVal.getLabel()));
        }
        //DE37531
    }
    
     // US124701 - Fetch Salespersons related to the Account via Account_Executive_Ids__c
    public void fetchSalespersons() {
        salespersonOptions = new List<SelectOption>();
        List<Id> relatedAccountExecutives = new List<Id>();
        relatedAccountExecutives = this.Account.Account_Executive_ids__c !=null ? this.Account.Account_Executive_ids__c.split(',') : new List<String>();
        //relatedAccountExecutives.add(this.Account.Account_Executive__c);
        List<Salesperson__c> salespersons = [
            SELECT Id, Name 
            FROM Salesperson__c 
            WHERE Id IN: relatedAccountExecutives
        ];
        
        for (Salesperson__c sp : salespersons) {
            salespersonOptions.add(new SelectOption(sp.Id, sp.Name));
        }
    }

    public PageReference ConvertToCustomer() {
        Savepoint sp = Database.setSavepoint();
        try {
            //retrieve again
            Account acct = GetRecord();
            if (acct.Type == 'Customer') {
                throw new DataException('This account has already been converted!.');
            }
            //billing contact <<
            this.Account.Billing_Contact__c = this.BillingContactId;
            //billing contact >>
            //DE37531
            this.Account.Billing_Contact__c = this.BillingContactId;
            if(this.selectedPONumberType == 'None'){
                this.Account.PO_Number_Type__c  = null;
                this.hasPoNumbertype = true;
            } else if(this.selectedPONumberType  == '' || this.selectedPONumberType == null){
                this.hasPONumbertype = false; 
            } else {
                this.Account.PO_Number_Type__c = this.selectedPONumberType ;
                this.hasPONumbertype = true;
            }
            //DE37531
            if (this.Account.Name == null
                    || this.Account.BillingStreet == null
                    || this.Account.BillingCity == null
                    || this.Account.BillingStateCode == null
                    || this.Account.BillingPostalCode == null
                    || this.Account.BillingCountryCode == null
                    // || this.Account.Customer_Type__c == null
                    || this.Account.Account_Executive__c == null
                    || this.Account.Service_Center__c == null
                    || this.Account.Subsidiary_Company__c == null
                    || this.Account.Billing_Contact__c == null
                    || this.Account.Estimated_Amount__c == null
                    // || this.Account.PO_Number_Type__c == null
                    || this.Account.Invoice_Email_Contact_Types__c == null
                    || this.Account.Invoice_Backup_Documents__c == null
                    || this.Account.Invoice_Submission_Channels__c == null
                	|| hasPONumberType == false	
                    ) {
                throw new DataException('You cannot convert the account to customer because not all required fields are filled in. Required fields: Name, Contact, Billing Street, Billing City, Billing State, Billing Postal Code, Billing Country, Account Executive, Service Center and Subsidiary Company, PO Number Type, Invoice Email Contact Types, Invoice Submission Channels, Invoice Backup Documents!');
            }
            //Remove PM || this.Account.Salesperson__c == null
            //Ticket#20977
            if(this.Account.Subsidiary_Company__r.Name == '5-RS-ES Gulf Coast'){
                if(this.Account.Payment_Term__c == null ||
                        this.Account.Tax_Area__c == null ||
                        this.Account.Customer_Status__c == null){
                    throw new DataException('You cannot convert the account to customer because not all required fields are filled in. Required fields: Payment Term, Tax Area, Customer Status');
                }
            }

            if(this.Account.Invoice_Submission_Channels__c.containsIgnoreCase(AccountsService.INVOICE_SUBMISSION_CHANNEL_INVOICE_PORTAL) && String.isBlank(this.Account.Invoice_Portal__c)){
                throw new DataException('Invoice Portal is required! When invoice submission channel is Invoice Portal!');
            }

            if(this.Account.Invoice_Backup_Documents__c.containsIgnoreCase(AccountsService.INVOICE_BACKUP_TYPE_CUSTOMER_SPECIFIC_DOCUMENTATION) && String.isBlank(this.Account.Customer_Specific_Documentation__c)){
                throw new DataException('Customer Specific Documentation is required! When Invoice Portal is required! When invoice backup document is Customer Specific Documentation!');
            }

            /*
             *  Ticket#20977 add Gulf Coast Subsidiaries
             */
            Subsidiary_Company__c subsidiaryCompany = [SELECT Id, Disable_Prospect_Conversion_Email__c, Customer_Numbering_Series__c,
                    Customer_Numbering_Series__r.Name, Disable_Customer_Portal__c
                    FROM Subsidiary_Company__c
                    WHERE Id = :this.Account.Subsidiary_Company__c LIMIT 1];

            if(subsidiaryCompany.Customer_Numbering_Series__c != null) {
                mapNumberSeries = CompanyMgmt.getNumber(subsidiaryCompany.Customer_Numbering_Series__r.Name);
                theNumberingSeries = mapNumberSeries.get(subsidiaryCompany.Customer_Numbering_Series__r.Name);
                this.Account.AccountNumber = theNumberingSeries.Prefix__c + theNumberingSeries.Separator__c +
                        String.valueOf(theNumberingSeries.Last_Number_Used__c);
                update mapNumberSeries.values();
            }

            this.Account.Type = 'Customer';
            this.Account.RecordTypeId = '012f4000000MDXd'; //Customer Record Type
            this.Account.Converted_Date__c = System.now();
            if(selectedSalespersons != null)
            this.Account.Account_Executive_ids__c = string.join(selectedSalespersons,',');
            update this.Account;

            /* Ticket#27252
            if(subsidiaryCompany.Disable_Customer_Portal__c != true) {
                //address validation <<
                StagingAccountController.StageAccount(this.Account.Id);
                //address validation >>
            }
             */

            return this.controller.view().setRedirect(true);
        } catch (Exception ex) {
            Database.rollback(sp);
            ApexPages.addMessages(ex);
            return null;
        }
    }
    //Ticket#14268
    public List<SelectOption> getItems(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('-None-', '-None-'));
        options.add(new SelectOption('N/A', 'N/A'));
        options.add(new SelectOption('EEC Fee', 'EEC Fee'));
        options.add(new SelectOption('Fuel Surcharge', 'Fuel Surcharge'));
        return options;
    }
    //Ticket#14268
    public String getSurchargeType(){
        return surchargeType;
    }
    //Ticket#14268
    public void setSurchargeType(String surchargeType){
        this.surchargeType = surchargeType;
    }

    public void ValidateServiceCenter() {
        if (Account.Service_Center__c != null) {
            Service_Center__c sc = [SELECT Id, Subsidiary_Company__c FROM Service_Center__c WHERE Id = :this.Account.Service_Center__c];
            Account.Subsidiary_Company__c = sc.Subsidiary_Company__c;
        } else {
            Account.Subsidiary_Company__c = null;
        }
    }

    /*
     *  Ticket#20977 add Customer Status field.
     */
    private Account GetRecord() {
        return [
                SELECT Id, Name, Type, BillingStreet, BillingCity, BillingState, BillingStateCode, BillingPostalCode, BillingCountry,Inter_co_Account__c, ParentId, Pricing_Group__c,
                BillingCountryCode, Customer_Type__c, Account_Executive__c, Salesperson__c, Service_Center__c, Subsidiary_Company__c,Emergency__c, AccountNumber,
                Phone, Fax, Phone_Ext__c, Tax_Liable__c, Tax_Area__c, Tax_Area__r.Name, Credit_Hold__c, Billing_Contact__r.Name, Subsidiary_Company__r.Name, Estimated_Amount__c,
                        Subsidiary_Company__r.QtC_Enabled__c, Payment_Term__c, Payment_Term__r.Name, Billing_Instructions__c, Internal_Comments__c, Customer_Billing_Instructions__c,
                        PO_Number_Type__c, Invoice_Submission_Channels__c, Invoice_Backup_Documents__c, Invoice_Email_Contact_Types__c, Invoice_Portal__c, Customer_Specific_Documentation__c,
                        Customer_Status__c,Account_Executive_ids__c,Account_Executives__c
                FROM Account
                WHERE Id = :this.controller.getId()
        ];
    }

    private void selectUser() {
        theUser = [SELECT Id, Name, FirstName, LastName, Phone, Service_Center__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    }

    /*
     *  Ticket#21419 - Add Sales to Customer Revenue
     */
    public static void RollupCustomerRevenue(List<Id> acctIds) {
        Map<Integer, List<Accounting_Period__c>> periods = new Map<Integer, List<Accounting_Period__c>>();
        for (Accounting_Period__c ap : [SELECT Id, Fiscal_Year__c, Fiscal_Period__c, Start_Date__c, End_Date__c FROM Accounting_Period__c WHERE Fiscal_Year__c >= 2021]) {
            List<Accounting_Period__c> aps;
            Integer fiscalYear = ap.Fiscal_Year__c.intValue();
            if (periods.containsKey(fiscalYear)) {
                aps = periods.get(fiscalYear);
            } else {
                aps = new List<Accounting_Period__c>();
                periods.put(fiscalYear, aps);
            }
            aps.add(ap);
        }

        Map<Id, Service_Center__c> centers = new Map<Id, Service_Center__c>();
        for (Service_Center__c sc : [SELECT Id, Code__c FROM Service_Center__c]) {
            centers.put(sc.Id, sc);
        }

        Map<Id, Account> customers = new Map<Id, Account>();
        for (Account acct : [SELECT Id, AccountNumber, Salesperson__c, Account_Executive__c, Subsidiary_Company__c, Subsidiary_Company__r.Name, Subsidiary_Company__r.QtC_Enabled__c FROM Account WHERE Id IN :acctIds]) {
            customers.put(acct.Id, acct);
        }

        Map<String, Customer_Revenue__c> revenues = new Map<String, Customer_Revenue__c>(); //customer, service center, fiscal year, fiscal period
        for (AggregateResult result : [SELECT Customer__c, Service_Center__c, Posting_Date__c, Sales_Order__c SOId, Sales_Order__r.Name SO, SUM(Amount_LCY__c) Amount, SUM(Sales_LCY__c) Sales
                                        FROM Customer_Ledger_Entry__c
                                        WHERE (Document_Type__c = 'Invoice' OR Document_Type__c = 'Credit_Memo')
                                            AND Posting_Date__c >= 2021-01-01
                                            AND Customer__c IN :acctIds GROUP BY Customer__c, Service_Center__c, Sales_Order__c, Sales_Order__r.Name, Posting_Date__c]) {
            Id cId = (Id) result.get('Customer__c');
            Account customer = customers.get(cId);
            String customerNo = customer.AccountNumber;
            String companyName = customer.Subsidiary_Company__r.Name;
            String SOName = (String)result.get('SO');
            String SOId = (Id)result.get('SOId');

            Id scId = (Id) result.get('Service_Center__c');
            String centerCode = '';
            Service_Center__c center = centers.get(scId);
            if (centers.containsKey(scId)) {
                centerCode = center.Code__c;
            }

            Date postingDate = (Date) result.get('Posting_Date__c');
            Integer fiscalYear = postingDate.year();
            Integer fiscalPeriod = 0;
            Date fiscalPeriodStartDate = null;
            Date fiscalPeriodEndDate = null;
            for (Accounting_Period__c ap : periods.get(fiscalYear)) {
                if (postingDate >= ap.Start_Date__c && postingDate <= ap.End_Date__c) {
                    fiscalPeriod = ap.Fiscal_Period__c.intValue();
                    fiscalPeriodStartDate = ap.Start_Date__c;
                    fiscalPeriodEndDate = ap.End_Date__c;
                    break;
                }
            }

            Customer_Revenue__c rev;
            //String key = companyName + ';' + centerCode + ';' + fiscalYear + ';' + fiscalPeriod + ';' + customerNo;
            String key = companyName + ';' + centerCode + ';' + fiscalYear + ';' + fiscalPeriod + ';' + customerNo + ';' + SOName;

            if (revenues.containsKey(key)) {
                rev = revenues.get(key);
                if(rev.Period_End_Date__c == null || rev.Period_Start_Date__c == null) {
                    rev.Period_Start_Date__c = fiscalPeriodStartDate;
                    rev.Period_End_Date__c = fiscalPeriodEndDate;
                }
            }
            else {
                //rev = new Customer_Revenue__c(Name = key, Customer__c = cId, Service_Center__c = scId, Fiscal_Year__c = fiscalYear, Fiscal_Period__c = fiscalPeriod, Salesperson__c = customer.Salesperson__c, Account_Executive__c = customer.Account_Executive__c, Amount__c = 0, Sales_LCY__c = 0, NAV_ID__c = key);
                rev = new Customer_Revenue__c(Name = key,
                        Customer__c = cId,
                        Service_Center__c = scId,
                        Fiscal_Year__c = fiscalYear,
                        Fiscal_Period__c = fiscalPeriod,
                        Period_Start_Date__c = fiscalPeriodStartDate,
                        Period_End_Date__c = fiscalPeriodEndDate,
                        Salesperson__c = customer.Salesperson__c,
                        Account_Executive__c = customer.Account_Executive__c,
                        Amount__c = 0,
                        Sales_LCY__c = 0,
                        NAV_ID__c = key,
                        Sales_Order__c = SOId);
                revenues.put(key, rev);
            }
            rev.Amount__c += (Decimal) result.get('Amount');
            rev.Sales_LCY__c += (Decimal) result.get('Sales');
        }

        Map<String, Customer_Revenue__c> orevenues = new Map<String, Customer_Revenue__c>();
        for (Customer_Revenue__c orev : [SELECT NAV_ID__c, Amount__c, Sales_LCY__c FROM Customer_Revenue__c WHERE Customer__c IN :acctIds]) {
            orevenues.put(orev.NAV_ID__c, orev);
        }

        for (String key : revenues.keySet()) {
            if (orevenues.containsKey(key)) {
                Customer_Revenue__c rev = revenues.get(key);
                rev.Id = orevenues.get(key).Id;
            }
        }

        List<Customer_Revenue__c> revs = new List<Customer_Revenue__c>();
        for (Customer_Revenue__c rev : revenues.values()) {
            revs.add(rev);
        }
        upsert revs;
    }

    //Ticket#22249 - Rollup Customer Rev Using CLE
    public static void RollupCustomerRevenueByCLE(List<Customer_Ledger_Entry__c> customerLedgerEntries) {
        Set<Id> acctIds = new Set<Id>();
        //Set<Id> serviceCenterIds = new Set<Id>();
        Integer earliestYear = null;
        Integer latestYear = null;
        for(Customer_Ledger_Entry__c customerLedgerEntry : customerLedgerEntries){
            if(acctIds.contains(customerLedgerEntry.Customer__c) == false) {
                acctIds.add(customerLedgerEntry.Customer__c);
            }
            /*
            if(serviceCenterIds.contains(customerLedgerEntry.Service_Center__c) == false){
                serviceCenterIds.add(customerLedgerEntry.Service_Center__c);
            }
             */
            Integer tempYear = customerLedgerEntry.Posting_Date__c.year();
            if(latestYear == null || tempYear > latestYear){
                latestYear = tempYear;
            }
            if(earliestYear == null || tempYear < earliestYear){
                earliestYear = tempYear;
            }
        }

        Map<Integer, List<Accounting_Period__c>> periods = new Map<Integer, List<Accounting_Period__c>>();
        for (Accounting_Period__c ap : [SELECT Id, Fiscal_year__c, Fiscal_Period__c, Start_Date__c, End_Date__c FROM Accounting_Period__c WHERE Fiscal_year__c >= :earliestYear AND Fiscal_year__c <= :latestYear]) {
            List<Accounting_Period__c> aps;
            Integer fiscalYear = ap.Fiscal_year__c.intValue();
            if (periods.containsKey(fiscalYear)) {
                aps = periods.get(fiscalYear);
            } else {
                aps = new List<Accounting_Period__c>();
                periods.put(fiscalYear, aps);
            }
            aps.add(ap);
        }

        /*
        Map<Id, Service_Center__c> centers = new Map<Id, Service_Center__c>();
        for (Service_Center__c sc : [SELECT Id, Code__c FROM Service_Center__c WHERE Id IN :serviceCenterIds]) {
            centers.put(sc.Id, sc);
        }


        Map<Id, Account> customers = new Map<Id, Account>();
        for (Account acct : [SELECT Id, AccountNumber, Salesperson__c, Account_Executive__c, Subsidiary_Company__c, Subsidiary_Company__r.Name, Subsidiary_Company__r.QtC_Enabled__c FROM Account WHERE Id IN :acctIds]) {
            customers.put(acct.Id, acct);
        }
         */

        //key = companyName + ';' + centerCode + ';' + fiscalYear + ';' + fiscalPeriod + ';' + customerNo + ';' + SOName;
        Map<String, Customer_Revenue__c> customerRevenueByKey = new Map<String, Customer_Revenue__c>();
        for(Customer_Revenue__c customerRevenue : [SELECT NAV_ID__c, Amount__c, Sales_LCY__c FROM Customer_Revenue__c WHERE Customer__c IN :acctIds]){
            customerRevenueByKey.put(customerRevenue.NAV_ID__c, customerRevenue);
        }

        //List<Customer_Revenue__c> customerRevenuesToUpsert = new List<Customer_Revenue__c>();
        Map<String, Customer_Revenue__c> customerRevenueToUpsertByKey = new Map<String, Customer_Revenue__c>();
        for(Customer_Ledger_Entry__c customerLedgerEntry : customerLedgerEntries){
            Integer fiscalYear = customerLedgerEntry.Posting_Date__c.year();
            Integer fiscalPeriod = 0;
            Date fiscalPeriodStartDate = null;
            Date fiscalPeriodEndDate = null;

            for (Accounting_Period__c ap : periods.get(fiscalYear)) {
                if (customerLedgerEntry.Posting_Date__c >= ap.Start_Date__c && customerLedgerEntry.Posting_Date__c <= ap.End_Date__c) {
                    fiscalPeriod = ap.Fiscal_Period__c.intValue();
                    fiscalPeriodStartDate = ap.Start_Date__c;
                    fiscalPeriodEndDate = ap.End_Date__c;
                    break;
                }
            }

            fflib_StringBuilder.CommaDelimitedListBuilder stringBuilder = new fflib_StringBuilder.CommaDelimitedListBuilder();
            stringBuilder.setDelimiter(';');
            stringBuilder.add(new List<String>{customerLedgerEntry.Customer__r.Subsidiary_Company__r.Name,
                    customerLedgerEntry.Service_Center__r.Code__c,
                    String.valueOf(fiscalYear),
                    String.valueOf(fiscalPeriod),
                    customerLedgerEntry.Customer__r.AccountNumber,
                    customerLedgerEntry.Sales_Order__r.Name
            });
            String key = stringBuilder.getStringValue();
            Customer_Revenue__c customerRevenue;
            if(customerRevenueByKey.containsKey(key) == true){
                customerRevenue = customerRevenueByKey.get(key);
                customerRevenue.Amount__c += CompanyMgmt.zeroIfNull(customerLedgerEntry.Amount_LCY__c);
                customerRevenue.Sales_LCY__c += CompanyMgmt.zeroIfNull(customerLedgerEntry.Sales_LCY__c);
            } else {
                customerRevenue = new Customer_Revenue__c(Name = key, Customer__c = customerLedgerEntry.Customer__c,
                        Service_Center__c = customerLedgerEntry.Service_Center__c,
                        Fiscal_Year__c = fiscalYear,
                        Fiscal_Period__c = fiscalPeriod,
                        Period_Start_Date__c = fiscalPeriodStartDate,
                        Period_End_Date__c = fiscalPeriodEndDate,
                        Salesperson__c = customerLedgerEntry.Customer__r.Salesperson__c,
                        Account_Executive__c = customerLedgerEntry.Customer__r.Account_Executive__c,
                        Amount__c = customerLedgerEntry.Amount_LCY__c,
                        Sales_LCY__c = customerLedgerEntry.Sales_LCY__c,
                        NAV_ID__c = key,
                        Sales_Order__c = customerLedgerEntry.Sales_Order__c);
                customerRevenueByKey.put(key, customerRevenue); //put new revenue record into the existing revenue mapping.                
            }
            customerRevenueToUpsertByKey.put(key, customerRevenue);
            //customerRevenueByKey.put(key, customerRevenue);
            customerLedgerEntry.Processed__c = true;
        }

        CompanyMgmt.byPassTrigger = true;
        update customerLedgerEntries;
        if (customerRevenueToUpsertByKey.values().size() > 0){
            upsert customerRevenueToUpsertByKey.values();
        }
    }

    public static void RollupCustomerAR(List<Id> acctIds) {
        if (acctIds.size() > 0) {
            Map<Id, CustomerAR> ars = new Map<Id, CustomerAR>();

            //Balance
            Map<Integer, DateBucket> buckets = new Map<Integer, DateBucket>();
            buckets.put(0, new DateBucket(Date.newInstance(1900, 1, 1), Date.newInstance(2999, 1, 1), 'Balance_Due_LCY__c'));
            Date startDate = System.today();
            Date endDate = Date.newInstance(2999, 1, 1);
            for (Integer i = 1; i <= 5; i++) {
                String fieldName;
                if (i == 1) fieldName = 'Balance_Due_LCY_Current__c'; else if (i == 2) fieldName = 'Balance_Due_LCY_30_Days__c'; else if (i == 3) fieldName = 'Balance_Due_LCY_60_Days__c'; else if (i == 4) fieldName = 'Balance_Due_LCY_90_Days__c'; else if (i == 5) fieldName = 'Balance_Due_LCY_120_Days__c';
                buckets.put(i + 1, new DateBucket(startDate, endDate, fieldName));

                endDate = startDate.addDays(-1);
                startDate = endDate.addDays(-29);
                if (i == 4) {
                    startDate = Date.newInstance(1900, 1, 1);
                }
            }

            for (DateBucket bucket : buckets.values()) {
                Set<Id> acctIds2 = new Set<Id> (acctIds);
                for (AggregateResult result : [SELECT Customer__c CustomerId, SUM(Remaining_Amount_LCY__c) BalanceDue FROM Customer_Ledger_Entry__c WHERE Customer__c IN :acctIds AND Due_Date__c >= :bucket.StartDate AND Due_Date__c <= :bucket.EndDate GROUP BY Customer__c]) {
                    Id acctId = (Id) result.get('CustomerId');
                    acctIds2.remove(acctId); //remove fromt the Id copy list

                    CustomerAR ar;
                    if (ars.containsKey(acctId)) {
                        ar = ars.get(acctId);
                    } else {
                        ar = new CustomerAR();
                        ar.Account.Id = acctId;
                        ars.put(acctId, ar);
                    }
                    ar.Account.put(bucket.AggregateField, result.get('BalanceDue'));
                }

                //update accounts that does not fall into the bucket to have zero balance
                for (Id acctId : acctIds2) {
                    CustomerAR ar;
                    if (ars.containsKey(acctId)) {
                        ar = ars.get(acctId);
                    } else {
                        ar = new CustomerAR();
                        ar.Account.Id = acctId;
                        ars.put(acctId, ar);
                    }
                    ar.Account.put(bucket.AggregateField, 0);
                }
            }

            //Revenue
            Integer currentFiscalYear = 0;
            Integer currentFiscalPeriod = 0;
            Map<String, Accounting_Period__c> periods = new Map<string, Accounting_Period__c>();
            List<Accounting_Period__c> aps = [SELECT Id, Start_Date__c, End_Date__c, New_Fiscal_Year__c, Fiscal_Year__c, Fiscal_Period__c FROM Accounting_Period__c ORDER BY Start_Date__c DESC];
            for (Accounting_Period__c ap : aps) {
                if (System.today() >= ap.Start_Date__c && System.today() <= ap.End_Date__c) {
                    currentFiscalYear = ap.Fiscal_Year__c.intValue();
                    currentFiscalPeriod = ap.Fiscal_Period__c.intValue();
                }
                periods.put(ap.Fiscal_Year__c.intValue() + ';' + ap.Fiscal_Period__c.intValue(), ap);
            }

            if (currentFiscalYear > 0 && currentFiscalPeriod > 0) {
                Integer fromFiscalYear;
                Integer fromFiscalPeriod;
                Integer toFiscalYear;
                Integer toFiscalPeriod;
                buckets = new Map<Integer, DateBucket>();

                //this month
                buckets.put(1, new DateBucket(currentFiscalyear, currentFiscalPeriod, currentFiscalYear, currentFiscalPeriod, 'Sales_LCY_This_Month__c'));

                //last month
                fromFiscalYear = currentFiscalYear;
                fromFiscalPeriod = currentFiscalPeriod - 1;
                if (fromFiscalPeriod <= 0) {
                    fromFiscalYear = currentFiscalYear - 1;
                    fromFiscalPeriod = 12 + fromFiscalPeriod;
                }
                toFiscalYear = fromFiscalYear;
                toFiscalPeriod = fromFiscalPeriod;
                buckets.put(2, new DateBucket(fromFiscalYear, fromFiscalPeriod, toFiscalYear, toFiscalPeriod, 'Sales_LCY_Last_Month__c'));

                //2 months piror
                fromFiscalYear = currentFiscalYear;
                fromFiscalPeriod = currentFiscalPeriod - 2;
                if (fromFiscalPeriod <= 0) {
                    fromfiscalYear = currentFiscalYear - 1;
                    fromFiscalPeriod = 12 + fromFiscalPeriod;
                }
                toFiscalYear = fromFiscalYear;
                toFiscalPeriod = fromFiscalPeriod;
                buckets.put(3, new DateBucket(fromFiscalYear, fromFiscalPeriod, toFiscalYear, toFiscalPeriod, 'Sales_LCY_2_Months_Prior__c'));

                //last 3 months
                fromFiscalYear = currentFiscalYear;
                fromFiscalPeriod = currentFiscalPeriod - 3;
                toFiscalYear = currentFiscalYear;
                toFiscalPeriod = currentFiscalPeriod - 1;
                if (fromFiscalPeriod <= 0) {
                    fromFiscalYear = currentFiscalYear - 1;
                    fromFiscalPeriod = 12 + fromFiscalPeriod;
                }
                if (toFiscalPeriod <= 0) {
                    toFiscalYear = toFiscalYear - 1;
                    toFiscalPeriod = 12 + toFiscalPeriod;
                }
                buckets.put(4, new DateBucket(fromFiscalYear, fromFiscalPeriod, toFiscalYear, toFiscalPeriod, 'Sales_LCY_Last_3_Months__c'));

                //YTD
                buckets.put(5, new DateBucket(currentFiscalYear, 1, currentFiscalYear, currentFiscalPeriod, 'Sales_LCY_YTD__c'));

                //Last Year
                buckets.put(6, new DateBucket(currentFiscalYear - 1, 1, currentFiscalYear - 1, 12, 'Sales_LCY_Last_Year__c'));

                //2 Year Prior
                buckets.put(7, new DateBucket(currentFiscalYear - 2, 1, currentFiscalYear - 2, 12, 'Sales_LCY_2_Years_Prior__c'));


                for (Integer key : buckets.keySet()) {
                    DateBucket bucket = buckets.get(key);
                    String fromKey = bucket.FromFiscalYear + ';' + bucket.FromFiscalPeriod;
                    String toKey = bucket.ToFiscalYear + ';' + bucket.ToFiscalPeriod;
                    if (periods.containsKey(toKey)) {
                        if (periods.containsKey(fromKey)) {
                            bucket.StartDate = periods.get(fromKey).Start_Date__c;
                        } else {
                            bucket.StartDate = Date.newInstance(1900, 1, 1);
                        }
                        bucket.EndDate = periods.get(toKey).End_Date__c;

                        for (AggregateResult result : [SELECT Customer__c CustomerId, SUM(Sales_LCY__c) SalesLCY FROM Customer_Ledger_Entry__c WHERE Customer__c IN :acctIds AND Posting_Date__c >= :bucket.StartDate AND Posting_Date__c <= :bucket.EndDate GROUP BY Customer__c]) {
                            Id acctId = (Id) result.get('CustomerId');
                            CustomerAR ar;
                            if (ars.containsKey(acctId)) {
                                ar = ars.get(acctId);
                            } else {
                                ar = new CustomerAR();
                                ar.Account.Id = acctId;
                                ars.put(acctId, ar);
                            }
                            ar.Account.put(bucket.AggregateField, result.get('SalesLCY'));
                        }
                    }
                }
            }

            //Average Pay Day
            Map<Id, Account> accounts = new Map<Id, Account>();
            for (Account acct : [SELECT Id, History_No_of_Invoices__c, History_Average_Pay_Day__c, History_Average_Overdue_Day__c FROM Account WHERE Id IN :acctIds]) {
                accounts.put(acct.Id, acct);
            }

            for (AggregateResult result : [SELECT Customer__c CustomerId, COUNT(Id) InvoiceCount, AVG(Due_Days__c) AveragePayDay, AVG(Overdue_Days__c) AverageOverdueDay FROM Customer_Ledger_Entry__c WHERE Customer__c IN :acctIds AND Document_Type__c = 'Invoice' AND Closed_at_Date__c <> NULL GROUP BY Customer__c]) {
                Id acctId = (Id) result.get('CustomerId');

                Decimal avgPayDay;
                Decimal avgOverdueDay;
                Decimal newInvoiceCount = (Integer)result.get('InvoiceCount');
                Decimal newAvgPayDay = (Decimal)result.get('AveragePayDay');
                Decimal newAvgOverdueDay = (Decimal)result.get('AverageOverdueDay');
                Decimal histInvoiceCount = 0;
                Decimal histAvgPayDay = 0;
                Decimal histAvgOverdueDay = 0;
                if (accounts.containsKey(acctId)) {
                    Account acct = accounts.get(acctId);
                    histInvoiceCount = (acct.History_No_of_Invoices__c == null ? 0 : acct.History_No_of_Invoices__c);
                    histAvgPayDay = (acct.History_Average_Pay_Day__c == null ? 0 : acct.History_Average_Pay_Day__c);
                    histAvgOverdueDay = (acct.History_Average_Overdue_Day__c == null ? 0 : acct.History_Average_Overdue_Day__c);
                }

                if (histInvoiceCount + newInvoiceCount > 0) {
                    avgPayDay = (((histInvoiceCount * histAvgPayDay) + (newInvoiceCount * newAvgPayDay)) / (histInvoiceCount + newInvoiceCount)).setScale(0);
                    avgOverdueDay = (((histInvoiceCount * histAvgOverdueDay) + (newInvoiceCount * newAvgOverdueDay)) / (histInvoiceCount + newInvoiceCount)).setScale(0);
                }


                CustomerAR ar;
                if (ars.containsKey(acctId)) {
                    ar = ars.get(acctId);
                } else {
                    ar = new CustomerAR();
                    ar.Account.Id = acctId;
                    ars.put(acctId, ar);
                }
                ar.Account.put('Average_Pay_Day__c', avgPayDay);
                ar.Account.put('Average_Overdue_Day__c', avgOverdueDay);
            }

            List<Account> accts = new List<Account>();
            for (CustomerAR ar : ars.values()) {
                Account acct = (Account) ar.Account;
                acct.API_Call__c = true;
                acct.Last_Rollup_Date__c = system.now();
                accts.add(acct);
            }

            if (accts.size() > 0) {
                update accts;
            }
        }
    }

    public static void RollupVendorAP(List<Id> acctIds){
        if (acctIds.size() > 0) {
            Map<Id, CustomerAR> ars = new Map<Id, CustomerAR>();

            //Balance
            Map<Integer, DateBucket> buckets = new Map<Integer, DateBucket>();
            buckets.put(0, new DateBucket(Date.newInstance(1900, 1, 1), Date.newInstance(2999, 1, 1), 'Purch_Balance_Due_LCY__c'));
            Date startDate = System.today();
            Date endDate = Date.newInstance(2999, 1, 1);
            for (Integer i = 1; i <= 5; i++) {
                String fieldName;
                if (i == 1) fieldName = 'Current_Purchase_Balance_LCY__c'; else if (i == 2) fieldName = 'Purch_Balance_Due_LCY_30_Days__c'; else if (i == 3) fieldName = 'Purch_Balance_Due_LCY_60_Days__c'; else if (i == 4) fieldName = 'Purch_Balance_Due_LCY_90_Days__c'; else if (i == 5) fieldName = 'Purch_Balance_Due_LCY_120_Days__c';
                buckets.put(i + 1, new DateBucket(startDate, endDate, fieldName));

                endDate = startDate.addDays(-1);
                startDate = endDate.addDays(-29);
                if (i == 4) {
                    startDate = Date.newInstance(1900, 1, 1);
                }
            }

            for (DateBucket bucket : buckets.values()) {
                Set<Id> acctIds2 = new Set<Id> (acctIds);
                for (AggregateResult result : [SELECT Vendor__c VendorId, SUM(Remaining_Amount_LCY__c) BalanceDue FROM Vendor_Ledger_Entry__c WHERE Vendor__c IN :acctIds AND Due_Date__c >= :bucket.StartDate AND Due_Date__c <= :bucket.EndDate GROUP BY Vendor__c]) {
                    Id acctId = (Id) result.get('VendorId');
                    acctIds2.remove(acctId); //remove fromt the Id copy list

                    CustomerAR ar;
                    if (ars.containsKey(acctId)) {
                        ar = ars.get(acctId);
                    } else {
                        ar = new CustomerAR();
                        ar.Account.Id = acctId;
                        ars.put(acctId, ar);
                    }
                    ar.Account.put(bucket.AggregateField, result.get('BalanceDue'));
                }

                //update accounts that does not fall into the bucket to have zero balance
                for (Id acctId : acctIds2) {
                    CustomerAR ar;
                    if (ars.containsKey(acctId)) {
                        ar = ars.get(acctId);
                    } else {
                        ar = new CustomerAR();
                        ar.Account.Id = acctId;
                        ars.put(acctId, ar);
                    }
                    ar.Account.put(bucket.AggregateField, 0);
                }
            }

            //Purchase
            Integer currentFiscalYear = 0;
            Integer currentFiscalPeriod = 0;
            Map<String, Accounting_Period__c> periods = new Map<string, Accounting_Period__c>();
            List<Accounting_Period__c> aps = [SELECT Id, Start_Date__c, End_Date__c, New_Fiscal_Year__c, Fiscal_Year__c, Fiscal_Period__c FROM Accounting_Period__c ORDER BY Start_Date__c DESC];
            for (Accounting_Period__c ap : aps) {
                if (System.today() >= ap.Start_Date__c && System.today() <= ap.End_Date__c) {
                    currentFiscalYear = ap.Fiscal_Year__c.intValue();
                    currentFiscalPeriod = ap.Fiscal_Period__c.intValue();
                }
                periods.put(ap.Fiscal_Year__c.intValue() + ';' + ap.Fiscal_Period__c.intValue(), ap);
            }

            System.debug('Info: periods ' + periods);

            if (currentFiscalYear > 0 && currentFiscalPeriod > 0) {
                Integer fromFiscalYear;
                Integer fromFiscalPeriod;
                Integer toFiscalYear;
                Integer toFiscalPeriod;
                buckets = new Map<Integer, DateBucket>();

                //this month
                buckets.put(1, new DateBucket(currentFiscalyear, currentFiscalPeriod, currentFiscalYear, currentFiscalPeriod, 'Purchase_LCY_This_Month__c'));

                //last month
                fromFiscalYear = currentFiscalYear;
                fromFiscalPeriod = currentFiscalPeriod - 1;
                if (fromFiscalPeriod <= 0) {
                    fromFiscalYear = currentFiscalYear - 1;
                    fromFiscalPeriod = 12 + fromFiscalPeriod;
                }
                toFiscalYear = fromFiscalYear;
                toFiscalPeriod = fromFiscalPeriod;
                buckets.put(2, new DateBucket(fromFiscalYear, fromFiscalPeriod, toFiscalYear, toFiscalPeriod, 'Purchase_LCY_Last_Months__c'));

                //2 months piror
                fromFiscalYear = currentFiscalYear;
                fromFiscalPeriod = currentFiscalPeriod - 2;
                if (fromFiscalPeriod <= 0) {
                    fromfiscalYear = currentFiscalYear - 1;
                    fromFiscalPeriod = 12 + fromFiscalPeriod;
                }
                toFiscalYear = fromFiscalYear;
                toFiscalPeriod = fromFiscalPeriod;
                buckets.put(3, new DateBucket(fromFiscalYear, fromFiscalPeriod, toFiscalYear, toFiscalPeriod, 'Purchase_LCY_2_Months_Prior__c'));

                //last 3 months
                fromFiscalYear = currentFiscalYear;
                fromFiscalPeriod = currentFiscalPeriod - 3;
                toFiscalYear = currentFiscalYear;
                toFiscalPeriod = currentFiscalPeriod - 1;
                if (fromFiscalPeriod <= 0) {
                    fromFiscalYear = currentFiscalYear - 1;
                    fromFiscalPeriod = 12 + fromFiscalPeriod;
                }
                if (toFiscalPeriod <= 0) {
                    toFiscalYear = toFiscalYear - 1;
                    toFiscalPeriod = 12 + toFiscalPeriod;
                }
                buckets.put(4, new DateBucket(fromFiscalYear, fromFiscalPeriod, toFiscalYear, toFiscalPeriod, 'Purchase_LCY_Last_3_Months__c'));

                //YTD
                buckets.put(5, new DateBucket(currentFiscalYear, 1, currentFiscalYear, currentFiscalPeriod, 'Purchase_LCY_YTD__c'));

                //Last Year
                buckets.put(6, new DateBucket(currentFiscalYear - 1, 1, currentFiscalYear - 1, 12, 'Purchase_LCY_Last_Year__c'));

                //2 Year Prior
                buckets.put(7, new DateBucket(currentFiscalYear - 2, 1, currentFiscalYear - 2, 12, 'Purchase_LCY_2_Years_Prior__c'));


                for (Integer key : buckets.keySet()) {
                    DateBucket bucket = buckets.get(key);
                    String fromKey = bucket.FromFiscalYear + ';' + bucket.FromFiscalPeriod;
                    String toKey = bucket.ToFiscalYear + ';' + bucket.ToFiscalPeriod;
                    if (periods.containsKey(toKey)) {
                        if (periods.containsKey(fromKey)) {
                            bucket.StartDate = periods.get(fromKey).Start_Date__c;
                        } else {
                            bucket.StartDate = Date.newInstance(1900, 1, 1);
                        }
                        bucket.EndDate = periods.get(toKey).End_Date__c;
                        System.debug('Info: fromKey ' + fromKey + ' to Key ' + toKey);
                        for (AggregateResult result : [SELECT Vendor__c VendorId, SUM(Purchase_LCY__c) PurchaseLCY FROM Vendor_Ledger_Entry__c WHERE Vendor__c IN :acctIds AND Posting_Date__c >= :bucket.StartDate AND Posting_Date__c <= :bucket.EndDate GROUP BY Vendor__c]) {
                            System.debug('Info: Agg Result ' + result);
                            Id acctId = (Id) result.get('VendorId');
                            CustomerAR ar;
                            if (ars.containsKey(acctId)) {
                                ar = ars.get(acctId);
                            } else {
                                ar = new CustomerAR();
                                ar.Account.Id = acctId;
                                ars.put(acctId, ar);
                            }
                            ar.Account.put(bucket.AggregateField, result.get('PurchaseLCY'));
                        }
                    }
                }
            }

            /*
            //Average Pay Day
            Map<Id, Account> accounts = new Map<Id, Account>();
            for (Account acct : [SELECT Id, History_No_of_Invoices__c, History_Average_Pay_Day__c, History_Average_Overdue_Day__c FROM Account WHERE Id IN :acctIds]) {
                accounts.put(acct.Id, acct);
            }

            for (AggregateResult result : [SELECT Customer__c CustomerId, COUNT(Id) InvoiceCount, AVG(Due_Days__c) AveragePayDay, AVG(Overdue_Days__c) AverageOverdueDay FROM Customer_Ledger_Entry__c WHERE Customer__c IN :acctIds AND Document_Type__c = 'Invoice' AND Closed_at_Date__c <> NULL GROUP BY Customer__c]) {
                Id acctId = (Id) result.get('CustomerId');

                Decimal avgPayDay;
                Decimal avgOverdueDay;
                Decimal newInvoiceCount = (Integer)result.get('InvoiceCount');
                Decimal newAvgPayDay = (Decimal)result.get('AveragePayDay');
                Decimal newAvgOverdueDay = (Decimal)result.get('AverageOverdueDay');
                Decimal histInvoiceCount = 0;
                Decimal histAvgPayDay = 0;
                Decimal histAvgOverdueDay = 0;
                if (accounts.containsKey(acctId)) {
                    Account acct = accounts.get(acctId);
                    histInvoiceCount = (acct.History_No_of_Invoices__c == null ? 0 : acct.History_No_of_Invoices__c);
                    histAvgPayDay = (acct.History_Average_Pay_Day__c == null ? 0 : acct.History_Average_Pay_Day__c);
                    histAvgOverdueDay = (acct.History_Average_Overdue_Day__c == null ? 0 : acct.History_Average_Overdue_Day__c);
                }

                if (histInvoiceCount + newInvoiceCount > 0) {
                    avgPayDay = (((histInvoiceCount * histAvgPayDay) + (newInvoiceCount * newAvgPayDay)) / (histInvoiceCount + newInvoiceCount)).setScale(0);
                    avgOverdueDay = (((histInvoiceCount * histAvgOverdueDay) + (newInvoiceCount * newAvgOverdueDay)) / (histInvoiceCount + newInvoiceCount)).setScale(0);
                }


                CustomerAR ar;
                if (ars.containsKey(acctId)) {
                    ar = ars.get(acctId);
                } else {
                    ar = new CustomerAR();
                    ar.Account.Id = acctId;
                    ars.put(acctId, ar);
                }
                ar.Account.put('Average_Pay_Day__c', avgPayDay);
                ar.Account.put('Average_Overdue_Day__c', avgOverdueDay);
            }
            */
            List<Account> accts = new List<Account>();
            for (CustomerAR ar : ars.values()) {
                Account acct = (Account) ar.Account;
                acct.API_Call__c = true;
                acct.Last_Rollup_Date__c = system.now();
                accts.add(acct);

                System.debug('Info: acct.Purchase_LCY_YTD__c $ ' + acct.Purchase_LCY_YTD__c);
                System.debug('Info: acct.Purchase_LCY_This_Month__c $ ' + acct.Purchase_LCY_This_Month__c);
                System.debug('Info: acct.Purchase_LCY_Last_Months__c $ ' + acct.Purchase_LCY_Last_Months__c);
                System.debug('Info: acct.Purchase_LCY_2_Months_Prior__c $ ' + acct.Purchase_LCY_2_Months_Prior__c);
                System.debug('Info: acct.Purchase_LCY_Last_3_Months__c $ ' + acct.Purchase_LCY_Last_3_Months__c);
                System.debug('Info: acct.Purchase_LCY_Last_Year__c $ ' + acct.Purchase_LCY_Last_Year__c);
                System.debug('Info: acct.Purchase_LCY_2_Years_Prior__c $ ' + acct.Purchase_LCY_2_Years_Prior__c);
            }

            if (accts.size() > 0) {
                update accts;
            }
        }
    }

    public static void RollupCorporateAR(List<Id> acctIds) {
        if (acctIds.size() > 0) {
            List<Account> accts = new List<Account>();
            for (AggregateResult result : [
                    SELECT ParentId, SUM(Credit_Limit_LCY__c) CreditLimit, SUM(Balance_Due_LCY__c) BalanceDue, SUM(Balance_Due_LCY_Current__c) BalanceDueCurrent,
                            SUM(Balance_Due_LCY_30_Days__c) BalanceDue30Days, SUM(Balance_Due_LCY_60_Days__c) BalanceDue60Days, SUM(Balance_Due_LCY_90_Days__c) BalanceDue90Days,
                            SUM(Balance_Due_LCY_120_Days__c) BalanceDue120Days, SUM(Sales_LCY_This_Month__c) SalesThisMonth, SUM(Sales_LCY_Last_Month__c) SalesLastMonth,
                            SUM(Sales_LCY_2_Months_Prior__c) Sales2MonthsPrior, SUM(Sales_LCY_Last_3_Months__c) SalesLast3Months,
                            SUM(Sales_LCY_YTD__c) SalesYTD, SUM(Sales_LCY_Last_Year__c) SalesLastYear, SUM(Sales_LCY_2_Years_Prior__c) Sales2YearsPrior,
                            SUM(Budget_This_Month__c) BudgetThisMonth, SUM(Total_Budget_Last_Month__c) BudgetLastMonth, SUM(Budget_Two_Months_Ago__c) BudgetTwoMonthsAgo,
                            SUM(Budget_Last_Three_Months__c) BudgetLastThreeMonths, SUM(Budget_YTD__c) BudgetYTD, SUM(Total_Budget_Last_Year__c) BudgetLastYear,
                            SUM(Purch_Balance_Due_LCY__c) PurchBalanceDue, SUM(Purch_Balance_Due_LCY_30_Days__c) PurchBalanceDue30Days, SUM(Purch_Balance_Due_LCY_60_Days__c) PurchBalanceDue60Days,
                            SUM(Purch_Balance_Due_LCY_90_Days__c) PurchBalanceDue90Days, SUM(Purch_Balance_Due_LCY_120_Days__c) PurchBalanceDue120Days, SUM(Current_Purchase_Balance_LCY__c) PurchBalanceDueCurrent,
                            SUM(Purchase_LCY_This_Month__c) PurchThisMonth, SUM(Purchase_LCY_Last_Months__c) PurchLastMonth, SUM(Purchase_LCY_2_Months_Prior__c) PurchLast2MonthPrior,
                            SUM(Purchase_LCY_Last_3_Months__c) PurchLast3MonthPrior, SUM(Purchase_LCY_Last_Year__c) PurchLastYear, SUM(Purchase_LCY_2_Years_Prior__c) PurchLast2YearsPrior,
                            SUM(Purchase_LCY_YTD__c) PurchYTD
                    FROM Account
                    WHERE ParentId IN :acctIds
                    GROUP BY ParentId
            ]) {
                Id acctId = (Id) result.get('ParentId');
                Account acct = new Account(Id = acctId);
                acct.Credit_Limit_LCY__c = (Decimal) result.get('CreditLimit');
                acct.Balance_Due_LCY__c = (Decimal) result.get('BalanceDue');
                acct.Balance_Due_LCY_Current__c = (Decimal) result.get('BalanceDueCurrent');
                acct.Balance_Due_LCY_30_Days__c = (Decimal) result.get('BalanceDue30Days');
                acct.Balance_Due_LCY_60_Days__c = (Decimal) result.get('BalanceDue60Days');
                acct.Balance_Due_LCY_90_Days__c = (Decimal) result.get('BalanceDue90Days');
                acct.Balance_Due_LCY_120_Days__c = (Decimal) result.get('BalanceDue120Days');
                acct.Sales_LCY_This_Month__c = (Decimal) result.get('SalesThisMonth');
                acct.Sales_LCY_Last_Month__c = (Decimal) result.get('SalesLastMonth');
                acct.Sales_LCY_2_Months_Prior__c = (Decimal) result.get('Sales2MonthsPrior');
                acct.Sales_LCY_Last_3_Months__c = (Decimal) result.get('SalesLast3Months');
                acct.Sales_LCY_YTD__c = (Decimal) result.get('SalesYTD');
                acct.Sales_LCY_Last_Year__c = (Decimal) result.get('SalesLastYear');
                acct.Sales_LCY_2_Years_Prior__c = (Decimal) result.get('Sales2YearsPrior');

                //Purchase
                acct.Purch_Balance_Due_LCY__c = (Decimal) result.get('PurchBalanceDue');
                acct.Current_Purchase_Balance_LCY__c = (Decimal) result.get('PurchBalanceDueCurrent');
                acct.Purch_Balance_Due_LCY_30_Days__c = (Decimal) result.get('PurchBalanceDue30Days');
                acct.Purch_Balance_Due_LCY_60_Days__c = (Decimal) result.get('PurchBalanceDue60Days');
                acct.Purch_Balance_Due_LCY_90_Days__c = (Decimal) result.get('PurchBalanceDue90Days');
                acct.Purch_Balance_Due_LCY_120_Days__c = (Decimal) result.get('PurchBalanceDue120Days');
                acct.Purchase_LCY_This_Month__c = (Decimal) result.get('PurchThisMonth');
                acct.Purchase_LCY_Last_Months__c = (Decimal) result.get('PurchLastMonth');
                acct.Purchase_LCY_2_Months_Prior__c = (Decimal) result.get('PurchLast2MonthPrior');
                acct.Purchase_LCY_Last_3_Months__c = (Decimal) result.get('PurchLast3MonthPrior');
                acct.Purchase_LCY_YTD__c = (Decimal) result.get('PurchYTD');
                acct.Purchase_LCY_Last_Year__c = (Decimal) result.get('PurchLastYear');
                acct.Purchase_LCY_2_Years_Prior__c = (Decimal) result.get('PurchLast2YearsPrior');

                acct.Budget_This_Month__c = (Decimal) result.get('BudgetThisMonth');
                acct.Total_Budget_Last_Month__c = (Decimal) result.get('BudgetLastMonth');
                acct.Budget_Two_Months_Ago__c = (Decimal) result.get('BudgetTwoMonthsAgo');
                acct.Budget_Last_Three_Months__c = (Decimal) result.get('BudgetLastThreeMonths');
                acct.Budget_YTD__c = (Decimal) result.get('BudgetYTD');
                acct.Total_Budget_Last_Year__c = (Decimal) result.get('BudgetLastYear');

                acct.API_Call__c = true;
                acct.Last_Rollup_Date__c = system.now();
                accts.add(acct);
            }

            if (accts.size() > 0) {
                update accts;
            }
        }
    }

    private class CustomerAR {
        public Boolean IsChanged { get; set; }
        public sObject Account { get; set; }

        public CustomerAR() {
            this.IsChanged = false;
            this.Account = new Account(Balance_Due_LCY__c = null,
                    Balance_Due_LCY_30_Days__c = null,
                    Balance_Due_LCY_60_Days__c = null,
                    Balance_Due_LCY_90_Days__c = null,
                    Balance_Due_LCY_120_Days__c = null,
                    Sales_LCY_YTD__c = null,
                    Sales_LCY_Last_Year__c = null,
                    Sales_LCY_2_Years_Prior__c = null,
                    Sales_LCY_This_Month__c = null,
                    Sales_LCY_Last_Month__c = null,
                    Sales_LCY_Last_3_Months__c = null,
                    Sales_LCY_2_Months_Prior__c = null,
                    Average_Pay_Day__c = null,
                    Average_overdue_Day__c = null);
        }

        public CustomerAR(Account cust) {
            this.IsChanged = false;
            this.Account = cust;
        }
    }

    private class DateBucket {
        public Integer FromFiscalYear { get; set; }
        public Integer ToFiscalYear { get; set; }
        public Integer FromFiscalPeriod { get; set; }
        public Integer ToFiscalPeriod { get; set; }
        public Date StartDate { get; set; }
        public Date EndDate { get; set; }
        public String AggregateField { get; set; }

        public DateBucket(Date fromDate, Date toDate, String field) {
            this.StartDate = fromDate;
            this.EndDate = toDate;
            this.AggregateField = field;
        }

        public DateBucket(Integer fromYear, Integer fromPeriod, Integer toYear, Integer toPeriod, String field) {
            this.FromFiscalYear = fromYear;
            this.FromFiscalPeriod = fromPeriod;
            this.ToFiscalYear = toYear;
            this.ToFiscalPeriod = toPeriod;
            this.AggregateField = field;
        }
    }

    public PageReference CreateSO() {
        /* Ticket#24559 Depreciated
        Sales_Order__c theSO = new Sales_Order__c();
        // Savepoint
        Savepoint sp = database.setSavepoint();
        try {
            //Ticket#13807 AES-394 >>
            if(isERCustomer == true){
                Account.Emergency__c = true;
                update Account;
            }
            theSO.Account_Executives__c = this.Account.Account_Executive__c;
            theSO.Project_Coordinator__c = this.Account.Salesperson__c;
            theSO.Bill_to_Customer_No__c = this.Account.Id;

            if (theUser.Service_Center__c == null) {
                throw new DataException('You must choose a Service Center before you can create Sales Order.');
            }
            if (String.isBlank(SalesOrderTypeId)) {
                System.debug('SalesOrderTypeId=========>'+SalesOrderTypeId);
                throw new DataException('You must choose a Sales Order Type before you can create Sales Order.');
            }
            //Ticket#14268
            System.debug('##*surchargeType: ' + this.surchargeType);
            if(this.surchargeType == '-None-'){
                throw new DataException('You must choose a Surcharge Type before you can create Sales Order.');
            }
            if ((this.Account.Subsidiary_Company__r.QtC_Enabled__c != true) && (this.Account.Type == 'Customer')){
                throw new DataException('You cannot create Sales Order for ' + this.Account.Subsidiary_Company__r.Name + ' customer');
            }

            Sales_Order_Type__c sot = [SELECT Id, Emergency_Response__c FROM Sales_Order_Type__c WHERE Id = :SalesOrderTypeId];
            if(isERCustomer == true && sot.Emergency_Response__c != true){
                throw new DataException('This customer is not approved. Only Emergency Response sales order are allowed!');
            }

            theSO.Sales_Order_Type__c = SalesOrderTypeId;

            theSO.Document_Type__c = 'Sales Order';
            theSO.RecordTypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByName().get('Sales Order').getRecordTypeId();
            Id SCId;
            if(!test.isrunningtest()) SCId = [SELECT Id FROM Service_Center__c WHERE Name = :theUser.Service_Center__c LIMIT 1].Id;
            theSO.Service_Center__c = SCId;
            theSO.Subsidiary_Company__c = SCompanyId;
            theSO.Contract__c = theContract.Id; //AES-441
            //Ticket#14554 >>
            if (String.isNotEmpty(theSO.Contract__c)){
                List<Contract> contracts = ContractsSelector.newInstance().selectBillingInstructionsById(new Set<Id>{theSO.Contract__c});
                if (contracts.size() > 0) {
                    Contract contract = contracts[0];
                    if (String.isNotEmpty(contract.Billing_Instructions__c)) {
                        theSO.Billing_Instructions__c = contract.Billing_Instructions__c;
                    }
                    if (String.isNotEmpty(contract.Internal_Comments__c)) {
                        theSO.Internal_Comments__c = contract.Internal_Comments__c;
                    }
                }
            }
            if (String.isBlank(theSO.Billing_Instructions__c)){
                theSO.Billing_Instructions__c = Account.Billing_Instructions__c;
            }
            if (String.isBlank(theSO.Internal_Comments__c)){
                theSO.Internal_Comments__c = Account.Internal_Comments__c;
            }
            if ((String.isEmpty(theSO.Billing_Instructions__c) || String.isEmpty(theSO.Internal_Comments__c)) && String.isNotEmpty(Account.ParentId)){
                List<Account> accounts = AccountsSelector.newInstance().selectBillingInstructionsById(new Set<Id>{this.Account.ParentId});
                if (accounts.size() > 0 ){
                    Account corporateAccount = accounts[0];
                    if (String.isNotEmpty(corporateAccount.Billing_Instructions__c) && String.isEmpty(theSO.Billing_Instructions__c)){
                        theSO.Billing_Instructions__c = corporateAccount.Billing_Instructions__c;
                    }
                    if (String.isNotEmpty(corporateAccount.Internal_Comments__c) && String.isEmpty(theSO.Internal_Comments__c)){
                        theSO.Internal_Comments__c = corporateAccount.Internal_Comments__c;
                    }
                }
            }
            //Ticket#14554 <<

            //emergency response <<
            theSO.Emergency_Sales_Order__c = sot.Emergency_Response__c;
            //emergency response >>
            theSO.Surcharge_Type__c = this.surchargeType; //Ticket#14268
            theSO.Street__c = this.Account.BillingStreet;
            theSO.City__c = this.Account.BillingCity;
            theSO.State__c = this.Account.BillingStateCode;
            theSO.Postal_Code__c = this.Account.BillingPostalCode;
            theSO.Country__c = this.Account.BillingCountryCode;
            theSO.Fax_No__c = this.Account.Fax;
            theSO.Phone_No__c = this.Account.Phone;
            theSO.Phone_Ext__c = this.Account.Phone_Ext__c;
            theSO.Tax_Area__c = this.Account.Tax_Area__c;
            //theSO.Tax_Liable__c = this.Account.Tax_Liable__c;
            if (this.Account.Inter_co_Account__c != true)  theSO.Tax_Liable__c = true;
            else {
                theSO.Tax_Liable__c = false;
                theSO.Inter_Company_Job__c = true;
            }
            theSO.Site_Street__c = this.Account.BillingStreet;
            theSO.Site_City__c = this.Account.BillingCity;
            theSO.Site_State__c = this.Account.BillingStateCode;
            theSO.Site_Postal_Code__c = this.Account.BillingPostalCode;
            theSO.Site_Country__c = this.Account.BillingCountryCode;
            theSO.Site_Phone_No__c = this.Account.Phone;
            //W00028
            theSO.Portal_Basis__c = false;
            theSO.Portal_Basis_Adv__c = true;

            theSO.Quote_Date__c = Date.today();
            SalesOrdersService.setSurchargePct(theSO);

            insert theSO;
            PageReference SOPage = new PageReference('/' + theSO.Id);
            SOPage.setRedirect(true);
            return SOPage;
        } catch (exception e) {
            Database.rollback(sp);
            //Ticket#13807 AES-394 >>
            if(e.getMessage().contains('You have exceeded the number of Emergency Sales Orders. This customer is not approved. Please contact Accounts Receivable.')) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You have exceeded the number of Emergency Sales Orders. This customer is not approved. Please contact Accounts Receivable.'));
            } else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage()));
            }
            //Ticket#13807 AES-394 >>
        }
         */
        return null;
    }

    public pageReference CreateSQ() {
        /* Ticket#24559 Depreciated
        Sales_Order__c theSO = new Sales_Order__c();
        // Savepoint
        Savepoint sp = database.setSavepoint();
        try {
            //Ticket#13807 AES-394 >>
            if(isERCustomer == true){
                this.Account.Emergency__c = true;
                update this.Account;
            }

            theSO.Account_Executives__c = this.Account.Account_Executive__c;
            //theSO.Project_Coordinator__c = this.Account.Salesperson__c;
            theSO.Bill_to_Customer_No__c = this.Account.Id;

            if (theUser.Service_Center__c == null) {
                throw new DataException('You must choose a Service Center before you can create Sales Quote.');
            }
            if (String.isBlank(SalesOrderTypeId)) {
                throw new DataException('You must choose a Sales Order Type before you can create Sales Quote.');
            }
            //Ticket#14268
            System.debug('##*surchargeType: ' + this.surchargeType);
            if(this.surchargeType == '-None-'){
                throw new DataException('You must choose a Surcharge Type before you can create Sales Quote.');
            }

            if ((this.Account.Subsidiary_Company__r.QtC_Enabled__c != true) && (this.Account.Type == 'Customer')){
                throw new DataException('You cannot create Sales Quote for ' + this.Account.Subsidiary_Company__r.Name + ' customer');
            }
            // AES-404
            if (this.Account.Subsidiary_Company__c == null){
                throw new DataException('The account must have a Subsidiary Company to create a Sales Quote');
            }

            if (String.isBlank(ownerId)) {
                throw new DataException('You must choose a Owner before you can create Sales Quote.');
            }
            // Ticket AES-404
            if (this.Account.Subsidiary_Company__r.QtC_Enabled__c != true) {
                throw new DataException('The account\'s subsidiary company must be QtC enabled.');
            }

            Sales_Order_Type__c sot = [SELECT Id, Emergency_Response__c FROM Sales_Order_Type__c WHERE Id = :SalesOrderTypeId];
            //Ticket#14616 <<
            theSO.OwnerId = ownerId;
            theSO.Sales_Order_Type__c = SalesOrderTypeId;
            theSO.Contract__c = theContract.Id; //AES-441
            //Ticket#14554 >>
            if (String.isNotEmpty(theSO.Contract__c)){
                List<Contract> contracts = ContractsSelector.newInstance().selectBillingInstructionsById(new Set<Id>{theSO.Contract__c});
                if (contracts.size() > 0) {
                    Contract contract = contracts[0];
                    if (String.isNotEmpty(contract.Billing_Instructions__c)) {
                        theSO.Billing_Instructions__c = contract.Billing_Instructions__c;
                    }
                    if (String.isNotEmpty(contract.Internal_Comments__c)) {
                        theSO.Internal_Comments__c = contract.Internal_Comments__c;
                    }
                }
            }
            if (String.isEmpty(theSO.Billing_Instructions__c)){
                theSO.Billing_Instructions__c = Account.Billing_Instructions__c;
            }
            if (String.isEmpty(theSO.Internal_Comments__c)){
                theSO.Internal_Comments__c = Account.Internal_Comments__c;
            }
            if ((String.isEmpty(theSO.Billing_Instructions__c) || String.isEmpty(theSO.Internal_Comments__c)) && String.isNotEmpty(Account.ParentId)){
                List<Account> accounts = AccountsSelector.newInstance().selectBillingInstructionsById(new Set<Id>{this.Account.ParentId});
                if (accounts.size() > 0 ){
                    Account corporateAccount = accounts[0];
                    if (String.isNotEmpty(corporateAccount.Billing_Instructions__c) && String.isEmpty(theSO.Billing_Instructions__c)){
                        theSO.Billing_Instructions__c = corporateAccount.Billing_Instructions__c;
                    }
                    if (String.isNotEmpty(corporateAccount.Internal_Comments__c) && String.isEmpty(theSO.Internal_Comments__c)){
                        theSO.Internal_Comments__c = corporateAccount.Internal_Comments__c;
                    }
                }
            }
            //Ticket#14554 <<
            //emergency response <<
            theSO.Emergency_Sales_Order__c = sot.Emergency_Response__c;
            //emergency response >>
            //Ticket#14268
            theSO.Surcharge_Type__c = this.surchargeType;

            theSO.Document_Type__c = 'Sales Quote';
            theSO.RecordTypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId();

            Id SCId = [SELECT Id FROM Service_Center__c WHERE Name = :theUser.Service_Center__c LIMIT 1].Id;
            theSO.Service_Center__c = SCId;
            theSO.Subsidiary_Company__c = SCompanyId;
            // Ticket# 14204 AES-431
            if (this.Account.Type == 'Prospect') {
                theSO.Payment_Term__c = theCompanySetup.Quote_Default_Payment_Term__c; //AES-424
            } else if (this.Account.Type == 'Customer'){
                theSO.Payment_Term__c = this.Account.Payment_Term__c;
            }
            theSO.Quote_Date__c = Date.today(); //AES-424
            theSO.Street__c = this.Account.BillingStreet;
            theSO.City__c = this.Account.BillingCity;
            theSO.State__c = this.Account.BillingStateCode;
            theSO.Postal_Code__c = this.Account.BillingPostalCode;
            theSO.Country__c = this.Account.BillingCountryCode;
            theSO.Fax_No__c = this.Account.Fax;
            theSO.Phone_No__c = this.Account.Phone;
            theSO.Phone_Ext__c = this.Account.Phone_Ext__c;
            theSO.Tax_Area__c = this.Account.Tax_Area__c;
            //theSO.Tax_Liable__c = this.Account.Tax_Liable__c;
            if (this.Account.Inter_co_Account__c != true) theSO.Tax_Liable__c = true;               
            else {
                theSO.Tax_Liable__c = false;
                //theSO.Tax_Area__c = theCompanySetup.Default_Inter_Co_Tax_Area__c;
                theSO.Inter_Company_Job__c = true;
            }
            theSO.Site_Street__c = this.Account.BillingStreet;
            theSO.Site_City__c = this.Account.BillingCity;
            theSO.Site_State__c = this.Account.BillingStateCode;
            theSO.Site_Postal_Code__c = this.Account.BillingPostalCode;
            theSO.Site_Country__c = this.Account.BillingCountryCode;
            theSO.Site_Phone_No__c = this.Account.Phone;
            //W00028
            theSO.Portal_Basis__c = false;
            theSO.Portal_Basis_Adv__c = true;
            
            SalesOrdersService.setSurchargePct(theSO);

            insert theSO;
            PageReference SOPage = new PageReference('/' + theSO.Id);
            SOPage.setRedirect(true);
            return SOPage;
        } catch (exception e) {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage()));
        }
         */
        return null;
    }

    public void SetSalesOrderType() {
        /* Ticket#24559 Depreciated
        //System.debug('SalesOrderType==>' + SalesOrderTypeId);
        SalesOrderType = [SELECT Name FROM Sales_Order_Type__c WHERE Id = :SalesOrderTypeId LIMIT 1].Name;
        SalesOrderTypeDescription = [SELECT Description__c FROM Sales_Order_Type__c WHERE Id = :SalesOrderTypeId LIMIT 1].Description__c;
         */
    }

    public void SetCompany() {
        List<Service_Center__c> SCList = [SELECT Id,Subsidiary_Company__c FROM Service_Center__c WHERE Name = :theUser.Service_Center__c];
        if (SCList != null && SCList.size() > 0) {
            Id SCId = SCList[0].Subsidiary_Company__c;
            Subsidiary_Company__c theSCompany = [SELECT Id, Name FROM Subsidiary_Company__c WHERE Id = :SCId];
            SCompany = theSCompany.Name;
            SCompanyId = theSCompany.Id;
        } else {
            SCompany = '';
            SCompanyId = '';
        }
    }

    public PageReference returnBack() {
        return controller.view();
    }

    public List<String> getMessages() {
        List<String> str = new List<String>();
        if (this.Account.Credit_Hold__c == true) str.add('WARNING! Account is on Credit Hold. Are you sure to continue?');
        return str;
    }

    public PageReference CreateMiscCreditMemo() {
        Sales_Invoice__c theSI = new Sales_Invoice__c();

        theSI.Bill_To_Customer__c = Account.Id;
        theSI = SalesInvoiceMgmt.validateBillToCustomer(theSI);
        theSI.Document_Status__c = 'Posted';
        theSI.Invoice_Date__c = Date.today();
        theSI = SalesInvoiceMgmt.nullRelationshipFields(theSI);

        theSI.Service_Center__c = Account.Service_Center__c;
        theSI.Subsidiary_Company__c = Account.Subsidiary_Company__c;
        theSI.Tax_Area__c = Account.Tax_Area__c;
        theSI.Credit_Memo__c = true;

        try{
            insert theSI;
            PageReference InvoicePage = new PageReference('/' + theSI.Id);
            InvoicePage.setRedirect(true);return InvoicePage;
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }

        return null;
    }

    //Function for Lookup Validation and data Correction
    public PageReference validateField() {

        String fieldName = ApexPages.currentPage().getParameters().get('fieldName');
        String newFieldValue = ApexPages.currentPage().getParameters().get('newFieldValue');
        Boolean foundError = false;

        if(fieldName=='targetNameWH' && newFieldValue !='') {
            List<Sales_Order_Type__c> SOType =[Select Id,Name from Sales_Order_Type__c where Id=:newFieldValue Limit 1];
            if(SOType.size() == 0){
                SOType =[Select Id,Name from Sales_Order_Type__c where Name=:newFieldValue Limit 1];
            }
            if(SOType.size() > 0){
                SalesOrderType=SOType[0].Name;
                SalesOrderTypeId=SOType[0].Id;
            } else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Sales Order Type does not exist! ' + newFieldValue));
                return null;
            }
        }
        //Ticket 13610
        if (fieldName == 'targetOwner' && newFieldValue != ''){
            List<User> ownerUsers = [SELECT Id,FirstName, LastName, Name FROM User WHERE Id = :newFieldValue LIMIT 1]; // Ticket# AES-404
            if (ownerUsers.size() > 0) {
                ownerId = ownerUsers[0].Id;
                ownerUsr = ownerUsers[0];
            }
        }
        if (fieldName == 'targetContract' && newFieldValue != '') { //AES-441
            List<Contract> contracts = [SELECT Id, ContractNumber, Name FROM Contract WHERE Id = :newFieldValue]; // Ticket# AES-404
            if (contracts.size() > 0) {
                theContract = contracts[0];
            }
        }
        return null;
    }
}
