/*************************************************************************************************
* Name         :  SalesInvoiceWOHeaderJSON 
* Description  :  Construct JSON for SalesInvoiceWorkOrderService
*
*
* Modification Log :
* Developer                   Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Vennila P       		 	11-24-2023          	73779: Create Work order header in EQAI 
when Sales Invoice and Sales Invoice Lines created in Salesforce
* Vennila P       			12-18-2023           	74081: Sending value as blank if it is null in salesforce
* Prabhu Rathakrishnan 		01-08-2024      		75097: Salesforce - Send contract number to match to existing billing project EQAI - JSON
* Vennila Paramasivam		02-16-2024	     		Task78892: Updating D365_Account_Number mapping
* Sathish Rosekumar			02-23-2024			 	Task79200: updated the startdate and enddate fields
* Sanjana Ravichandran      02-27-2024              Task79424: Salesforce - Send Project Scope Field to EQAI Work Order Header 
* Vennila Paramasivam		03-05-2024			   Task80420: Mapping confirm_author with Created_By
* Vennila Paramasivam		03-05-2024			   Task80266: Mapping contact_ID with Bill_to_contact
* Vennila Paramasivam		03-13-2024			   Task81421- Updated the Createdby and Lastmodifiedby with RSG_EIN__c
* Prabhu Rathakrishnan 		03-20-2024      		82266: P3 - Salesforce - Country ID for USA sending as US
* Vennila Paramasivam		03-22-2024			   Task81412 - Added employee_id
* Prabhu Rathakrishnan      03-28-2024      	   82299: Site Sent to EQAI WO and Site Display Name is Different 
* Vennila Paramasivam	    03-29-2024			       81405: Updated ProjectName mapping from Job_description to CMR Description.
* Andrew Simons            04-10-2024           83646: Added invoice_tax
* Andrew Simons             04-29-2024              84554: map Invoice_Note__c to eqai Invoicecomment_1
* Vennila Paramasivam		06-18-2024				US115603: Adding SalesInvoiceNumber 
Shahwaz Khan              07-10-2024             US117390 : Salesforce - Updates to Site Address
* Prabhu Rathakrishnan      07-27-2024             US117946:Salesforce - Send work order header information to EQAI upon creation of Sales order with waste disposal  
* Sanjana Ravichandran 		08-19-2024				US122329: Salesforce - Limit Characters for Fields
* Prabhu Rathakrishnan      09/09/2024             US121824: Salesforce - Billing Project lookup on Sales Order
* Sanjana Ravichandran 		10/01/2024  DE35882: [Continued] [Unplanned] Map start and end date to work order from billing package submission
* Pavithra Periyasamy		11/07/2024              US129598: [Continued] SF -  Create single JSON object for billing package integration
* Pavithra Periyasamy		11/21/2024              US133594: [Unplanned] Salesforce - Use single JSON format to create Work Order at time of Sales Order creation in Salesforce
*************************************************************************************************/


public class SalesInvoiceWOHeaderJSON {
    public string Work_Order_Status_Submitted_Flag;
    public string D365CustomerId;
    public string SalesforceInvoiceCSID;
    public string PurchaseOrder;
    public string ProjectCode;
    public string quote_id;
    public integer CompanyId;
    public string currency_code;
    public decimal cust_discount;
    public integer GeneratorId;
    public string other_submit_required_flag;
    public integer ProfitCenterId;
    public integer WorkOrderTypeId;
    public string note_account_executive;
    public string note_billing_instructions;
    public boolean note_approved;
    public decimal note_approved_amount;
    public string note_contact;
    public string note_contract_name;  
    public string note_corrected_customer_PO_no;
    public string note_country;
    public string note_instructions;
    public string note_ic;
    public string note_internal_comments;
    public string note_invoice_note;
    public string note_lastmodified;
    public string note_owner;
    public string note_payment_term;
    public string note_remit_to;
    public decimal note_Amount;
    public boolean note_rental_invoice;
    public string note_rental_order;
    public string note_sales_quote;
    public string note_salesperson;
    public decimal note_service_days;
    public string note_subsidiary_company;
    public decimal note_surcharge_pct;
    public decimal note_surcharge_amount;
    public decimal note_surcharge_amt_Incl_tax;
    public string note_surcharge_type;
    public string note_tax_area;
    public boolean note_tax_liable;
    public string AXDimension5Part1='';
    public date note_Payment_Date;
    public String SalesforceContractNumber;
    public String description;
    public String Bill_to_Contact;
    public string confirm_author;
    public string ProjectName;
    public date StartDate;
    public date EndDate;
    public String employee_id;
    public String SalesforceSiteCSID;
    public decimal invoice_tax;
    public string Invoicecomment_1;
    public string note_SalesInvoiceNumber;
    //US117390: New Site attributes
    public String GeneratorName;
    public String GeneratorAddress1;
    public String GeneratorCity;
    public String GeneratorState;
    public String GeneratorZipCode;
    public String GeneratorCountry;
    public String GeneratorPhone;
    public String GeneratorFax;
    public String GenMailName;
    public String GenMailAddress1;
    public String GenMailCity;
    public String GenMailState;
    public String GenMailZipCode;
    public String GenMailCountry;
    public Integer NAICScode;
    public String GeneratorStatus;
    public String AsSiteChanged;
    public String AsSoDisposalFlag;
    public Integer BillingProjectId;
    
    public String SalesforceSoCsid;
    public SalesInvoiceWOHeaderJSON(Sales_Invoice__c salesInvoiceRec,map<String,String> project_Code_EQIMap, map<String,String>  company_Id_EQIMap, map<String,String> profit_Ctr_Id_EQIMap,String employeeId)
    {
        Boolean wasteDisposal = SalesInvoiceWorkOrderService.containsWasteDisposalInvoiceLine(salesInvoiceRec.Id);
        employee_id=employeeId;
        Work_Order_Status_Submitted_Flag = salesInvoiceRec.Approval_Status__c!=Null?salesInvoiceRec.Approval_Status__c:'F';
        D365CustomerId = (salesInvoiceRec.Bill_to_Customer__c != Null)?salesInvoiceRec.Bill_to_Customer__r.Sage_Customer_No__c:'';
        ProjectCode = salesInvoiceRec.Sales_Order__r.Name;
        SalesforceInvoiceCSID = salesInvoiceRec.CSID__c;
        PurchaseOrder = (salesInvoiceRec.Customer_PO_No__c != null)?salesInvoiceRec.Customer_PO_No__c:'';
        quote_id = (salesInvoiceRec.Sales_Order__c != null)?salesInvoiceRec.Sales_Order__c:'';
        CompanyId = Integer.valueOf(salesInvoiceRec.Service_Center__r.Name);
        AXDimension5Part1 = (salesInvoiceRec.Sales_order__r.D365_Project_Id__c != null)? salesInvoiceRec.Sales_order__r.D365_Project_Id__c:'';
       
        if(salesInvoiceRec.Service_Center__c != null && salesInvoiceRec.Service_Center__r.Name != null && company_Id_EQIMap !=null && company_Id_EQIMap.containskey(salesInvoiceRec.Service_Center__r.Name)) CompanyId = Integer.valueOf(company_Id_EQIMap.get(salesInvoiceRec.Service_Center__r.Name));
        if(salesInvoiceRec.Service_Center__c != null && salesInvoiceRec.Service_Center__r.Name != null && profit_Ctr_Id_EQIMap !=null && profit_Ctr_Id_EQIMap.containskey(salesInvoiceRec.Service_Center__r.Name)) ProfitCenterId = Integer.valueOf(profit_Ctr_Id_EQIMap.get(salesInvoiceRec.Service_Center__r.Name));
        StartDate = salesInvoiceRec.First_Service_Date__c != null ?salesInvoiceRec.First_Service_Date__c:null; 
        EndDate = salesInvoiceRec.Last_Service_Dates__c != null ?salesInvoiceRec.Last_Service_Dates__c :null; 
        //80266
        if(salesInvoiceRec.Sales_Order__r.Bill_to_Contact__c != Null)
            Bill_to_Contact = salesInvoiceRec.Sales_Order__r.Bill_to_Contact__r.Name;   
        //GeneratorId=0;
        if(salesInvoiceRec.Sales_order__r.EqaiGeneratorId__c!= null){
            GeneratorId = Integer.ValueOf(salesInvoiceRec.Sales_order__r.EqaiGeneratorId__c);
            AsSiteChanged= 'F';
        }
        else if(salesInvoiceRec.Sales_Order__r !=null && salesInvoiceRec.Sales_Order__r.Alternate_Site_Address__c!=null){
            SalesforceSiteCSID = salesInvoiceRec.Sales_Order__r.Alternate_Site_Address__c;
            AsSiteChanged = salesInvoiceRec.Sales_Order__r.Site_Address_Changed__c?'T':'F'; 
        }
       
       
        if(salesInvoiceRec.Sales_Order_type__c != null) WorkOrderTypeId = Integer.valueOf(salesInvoiceRec.Work_Order_Type_ID__c);       
       
       
        
        if(salesInvoiceRec.Account_Executive__c != null)
        	note_account_executive = salesInvoiceRec.Account_Executive__c;
        else
           note_account_executive = '';
        
        note_billing_instructions  = (salesInvoiceRec.Billing_Instructions__c != null)?salesInvoiceRec.Billing_Instructions__c:'';
        note_approved  = salesInvoiceRec.Approved__c;
        note_approved_amount  = (salesInvoiceRec.Approved_Amount__c != null)?salesInvoiceRec.Approved_Amount__c:0;
        note_contact  = salesInvoiceRec.Contact__c;
        note_contract_name  = (salesInvoiceRec.Contract_Name__c != null) ?salesInvoiceRec.Contract_Name__c:'';
        note_Surcharge_pct  = (salesInvoiceRec.Contract_Surcharge_Prct__c != null)?salesInvoiceRec.Contract_Surcharge_Prct__c:0;
        note_Surcharge_type  = (salesInvoiceRec.Contract_Surcharge_Type__c != null)?salesInvoiceRec.Contract_Surcharge_Type__c:'';
        note_corrected_customer_PO_no  = (salesInvoiceRec.Corrected_Customer_PO_No__c != null)?salesInvoiceRec.Corrected_Customer_PO_No__c:'';
        //note_country  = (salesInvoiceRec.Country__c != null)?salesInvoiceRec.Country__c:'';
        if(salesInvoiceRec.Country__c != null){
            if(salesInvoiceRec.Country__c == 'US'){
                note_country = 'USA';
            }
            else{
                note_country = salesInvoiceRec.Country__c;
            }
        }
        else{
            note_country = '';
        }
        note_instructions  = (salesInvoiceRec.Customer_Billing_Instructions__c != null)?salesInvoiceRec.Customer_Billing_Instructions__c:'';
        note_Payment_Date  = salesInvoiceRec.Expected_Payment_Date__c;
        note_ic  = (salesInvoiceRec.I_C__c != null)?salesInvoiceRec.I_C__c:'';
        note_internal_comments  = (salesInvoiceRec.Internal_Comments__c != null)?salesInvoiceRec.Internal_Comments__c:'';
        note_invoice_note  = (salesInvoiceRec.Invoice_Note__c != null)?salesInvoiceRec.Invoice_Note__c:'';
        note_lastmodified  = (salesInvoiceRec.LastModifiedBy.Name != null)?salesInvoiceRec.LastModifiedBy.Name:'';
        note_owner  = (salesInvoiceRec.OwnerId != null)?salesInvoiceRec.OwnerId:'';
        note_payment_term  = (salesInvoiceRec.Payment_Term__c != null) ?salesInvoiceRec.Payment_Term__c:'';
        note_remit_to  = (salesInvoiceRec.Remit_To__c != null)?salesInvoiceRec.Remit_To__c:'';
        note_amount  = (salesInvoiceRec.Rent_Billing_Amount__c != null)?salesInvoiceRec.Rent_Billing_Amount__c:0;
        note_rental_invoice  = salesInvoiceRec.Rental_Invoice__c; 
        
        if(salesInvoiceRec.Sales_Quote__c != null)
            note_sales_quote  = salesInvoiceRec.Sales_Quote__c;
        else
            note_sales_quote = ''; 
        
        if(salesInvoiceRec.Salesperson__c != null)
            note_salesperson  = salesInvoiceRec.Salesperson__c;
        else
            note_salesperson = '';
        
        note_service_days  = (salesInvoiceRec.Service_Days__c != null)?salesInvoiceRec.Service_Days__c:0;
        note_subsidiary_company  = (salesInvoiceRec.Subsidiary_Company__c != null) ?salesInvoiceRec.Subsidiary_Company__c:'';
        note_surcharge_pct  = (salesInvoiceRec.Surcharge_Pct__c != null)?salesInvoiceRec.Surcharge_Pct__c:0;
        note_surcharge_amount  = (salesInvoiceRec.Surcharge_Amount__c != null)?salesInvoiceRec.Surcharge_Amount__c:0;
        note_surcharge_amt_Incl_tax  = (salesInvoiceRec.Surcharge_Amt_Incl_Tax__c != null)?salesInvoiceRec.Surcharge_Amt_Incl_Tax__c:0;
        note_surcharge_type  = (salesInvoiceRec.Surcharge_Type__c != null)?salesInvoiceRec.Surcharge_Type__c:'';
        note_tax_area  = (salesInvoiceRec.Tax_Area__c != null)?salesInvoiceRec.Tax_Area__c:'';
        note_tax_liable  =salesInvoiceRec.Tax_Liable__c;
        if(salesInvoiceRec.Rental_Order__c != null)
            note_rental_order  = salesInvoiceRec.Rental_Order__c;
        else
            note_rental_order = '';          
        if(salesInvoiceRec.Contract__c != null)

     
            SalesforceContractNumber = salesInvoiceRec.Contract__r.ContractNumber;
        
        //description = (salesInvoiceRec.Site_Scope__c!=null)?salesInvoiceRec.Site_Scope__c:'';
        if(salesInvoiceRec.Site_Scope__c != null)
        {
            if(salesInvoiceRec.Site_Scope__c.length() > 250)
                description = salesInvoiceRec.Site_Scope__c.substring(0,250);
            else
                description = salesInvoiceRec.Site_Scope__c; 
        }
            
        confirm_author = salesInvoiceRec.CreatedBy.name;
        ProjectName = (salesInvoiceRec.Sales_order__r.CMR_Description__c!=null)?salesInvoiceRec.Sales_order__r.CMR_Description__c:'';
        invoice_tax = (salesInvoiceRec.Invoice_Tax__c!=null)?salesInvoiceRec.Invoice_Tax__c:0;
        //Invoicecomment_1 = (salesInvoiceRec.Invoice_Note__c!=null)?salesInvoiceRec.Invoice_Note__c:'';
        String invoiceNote = salesInvoiceRec.Invoice_Note__c;
        if (invoiceNote != null) {
            if (invoiceNote.length() > 80) {
                invoiceNote = invoiceNote.substring(0, 80);
            }
            Invoicecomment_1 = invoiceNote;
        } else {
            Invoicecomment_1 = '';
        }
        note_SalesInvoiceNumber = salesInvoiceRec.Name;
        //US117390 >> Start>>
        if (salesInvoiceRec.Sales_Order__r.Site_City__c != null) {
            GenMailCity = salesInvoiceRec.Sales_Order__r.Site_City__c.toUpperCase();
            GeneratorCity = salesInvoiceRec.Sales_Order__r.Site_City__c.toUpperCase();
        }
        if (salesInvoiceRec.Sales_Order__r.Site_Country__c != null) {
            if (salesInvoiceRec.Sales_Order__r.Site_Country__c == 'US') {
                GenMailCountry = 'USA';
                GeneratorCountry = 'USA';
            } else {
                GenMailCountry = salesInvoiceRec.Sales_Order__r.Site_Country__c.toUpperCase();
                GeneratorCountry = salesInvoiceRec.Sales_Order__r.Site_Country__c.toUpperCase();
            }
        }
        if (salesInvoiceRec.Sales_Order__r.Site_Postal_Code__c != null) {
            GenMailZipCode = salesInvoiceRec.Sales_Order__r.Site_Postal_Code__c.toUpperCase();
            GeneratorZipCode = salesInvoiceRec.Sales_Order__r.Site_Postal_Code__c.toUpperCase();
        }
        if (salesInvoiceRec.Sales_Order__r.Site_State__c != null) {
            GenMailState = salesInvoiceRec.Sales_Order__r.Site_State__c.toUpperCase();
            GeneratorState = salesInvoiceRec.Sales_Order__r.Site_State__c.toUpperCase();
        }
        if (salesInvoiceRec.Sales_Order__r.Site_Street__c != null) {
            GenMailAddress1 = salesInvoiceRec.Sales_Order__r.Site_Street__c.toUpperCase();
            GeneratorAddress1 = salesInvoiceRec.Sales_Order__r.Site_Street__c.toUpperCase();
        }
        String siteName = salesInvoiceRec.Sales_Order__r.Site_Name__c.toUpperCase();
        system.debug('sitename'+siteName);
        if (siteName != null) {
            if (siteName.length() > 40) {
                siteName = siteName.substring(0, 40);
            }
            GeneratorName = siteName;
        } else {
            GeneratorName = '';
        }

        GeneratorAddress1 = (salesInvoiceRec.Sales_Order__r.Site_Street__c!=null)? salesInvoiceRec.Sales_Order__r.Site_Street__c.toUpperCase():'';
        GeneratorCity = (salesInvoiceRec.Sales_Order__r.Site_City__c!=null)?salesInvoiceRec.Sales_Order__r.Site_City__c.toUpperCase():'';
        GeneratorState = (salesInvoiceRec.Sales_Order__r.Site_State__c!=null)?salesInvoiceRec.Sales_Order__r.Site_State__c.toUpperCase():'';
        GeneratorZipCode = (salesInvoiceRec.Sales_Order__r.Site_Postal_Code__c!=null)?salesInvoiceRec.Sales_Order__r.Site_Postal_Code__c.toUpperCase():'';
        GeneratorCountry = (salesInvoiceRec.Sales_Order__r.Site_Country__c!=null)?((salesInvoiceRec.Sales_Order__r.Site_Country__c == 'US')?'USA':salesInvoiceRec.Sales_Order__r.Site_Country__c.toUpperCase()):'';
        String sitePhone = salesInvoiceRec.Sales_Order__r.Site_Phone_No__c;
        if (sitePhone != null) {
            sitePhone = sitePhone.replaceAll('[^\\d]', '');
            if (sitePhone.length() > 10) {
                sitePhone = sitePhone.substring(sitePhone.length() - 10);
            }
            GeneratorPhone = sitePhone;
        } else {
            GeneratorPhone = '';
        } 
        String GenMailSiteName = salesInvoiceRec.Sales_Order__r.Site_Name__c.toUpperCase();
        if (GenMailSiteName != null) {
            if (GenMailSiteName.length() > 40) {
                GenMailSiteName = GenMailSiteName.substring(0, 40);
            }
            GenMailName = GenMailSiteName;
        } else {
            GenMailName = '';
        }        
        GenMailAddress1 = (salesInvoiceRec.Sales_Order__r.Site_Street__c!=null)?salesInvoiceRec.Sales_Order__r.Site_Street__c.toUpperCase():'';
        GenMailCity = (salesInvoiceRec.Sales_Order__r.Site_City__c!=null)?salesInvoiceRec.Sales_Order__r.Site_City__c.toUpperCase():'';
        GenMailState = (salesInvoiceRec.Sales_Order__r.Site_State__c!=null)?salesInvoiceRec.Sales_Order__r.Site_State__c.toUpperCase() : '';
        GenMailZipCode = (salesInvoiceRec.Sales_Order__r.Site_Postal_Code__c != null)?salesInvoiceRec.Sales_Order__r.Site_Postal_Code__c.toUpperCase():'';
        GenMailCountry = (salesInvoiceRec.Sales_Order__r.Site_Country__c!=null)?((salesInvoiceRec.Sales_Order__r.Site_Country__c == 'US')?'USA' : salesInvoiceRec.Sales_Order__r.Site_Country__c.toUpperCase()):'';
        //NAICScode = (salesInvoiceRec.Bill_to_Customer__r.NAICS_code__c != null) ? Integer.ValueOf(salesInvoiceRec.Bill_to_Customer__r.NAICS_code__c) :0; 
        NAICScode =0;
        GeneratorStatus = 'A'; 
        //AsSiteChanged = salesInvoiceRec.Sales_Order__r.Site_Address_Changed__c?'T':'F'; 
        AsSoDisposalFlag = 'F';
        if(salesInvoiceRec.Sales_Order__r.EQAI_Billing_Project_Id__c!= null)
            BillingProjectId = Integer.ValueOf(salesInvoiceRec.Sales_Order__r.EQAI_Billing_Project_Id__c);
        //US129598: 
        if(wasteDisposal){
            SalesforceSoCsid = salesInvoiceRec.Sales_Order__c;
            AsSoDisposalFlag = 'T';
        }
    } 
    public SalesInvoiceWOHeaderJSON(Sales_Order__c salesOrderRec,map<String,String> project_Code_EQIMap, map<String,String>  company_Id_EQIMap, map<String,String> profit_Ctr_Id_EQIMap,String employeeId){
        employee_id=employeeId;
        D365CustomerId = (salesOrderRec.Bill_to_Customer_No__c != Null)?salesOrderRec.Bill_to_Customer_No__r.Sage_Customer_No__c:'';
        ProjectCode = salesOrderRec.Name;
        WorkOrderTypeId = Integer.valueOf(salesOrderRec.Sales_Order_Type__r.Work_Order_Type_ID__c);       
        SalesforceInvoiceCSID = salesOrderRec.Id;
        PurchaseOrder = (salesOrderRec.Customer_PO_No__c != null)?salesOrderRec.Customer_PO_No__c:'';
        quote_id = (salesOrderRec != null)?salesOrderRec.ID:'';
        CompanyId = Integer.valueOf(salesOrderRec.Service_Center__r.Name);
        AXDimension5Part1 = (salesOrderRec.D365_Project_Id__c != null)? salesOrderRec.D365_Project_Id__c:'';
        if(salesOrderRec.Service_Center__c != null && salesOrderRec.Service_Center__r.Name != null && company_Id_EQIMap !=null && company_Id_EQIMap.containskey(salesOrderRec.Service_Center__r.Name)) CompanyId = Integer.valueOf(company_Id_EQIMap.get(salesOrderRec.Service_Center__r.Name));
        if(salesOrderRec.Service_Center__c != null && salesOrderRec.Service_Center__r.Name != null && profit_Ctr_Id_EQIMap !=null && profit_Ctr_Id_EQIMap.containskey(salesOrderRec.Service_Center__r.Name)) ProfitCenterId = Integer.valueOf(profit_Ctr_Id_EQIMap.get(salesOrderRec.Service_Center__r.Name));
        if(salesOrderRec.Bill_to_Contact__c != Null)
            Bill_to_Contact = salesOrderRec.Bill_to_Contact__r.Name;   
        //GeneratorId=0;
        
        
        if(salesOrderRec.EqaiGeneratorId__c!= null){
            GeneratorId = Integer.ValueOf(salesOrderRec.EqaiGeneratorId__c);
            AsSiteChanged= 'F';
        }
        else if(salesOrderRec !=null && salesOrderRec.Alternate_Site_Address__c!=null){
            SalesforceSiteCSID = salesOrderRec.Alternate_Site_Address__c;
            AsSiteChanged = salesOrderRec.Site_Address_Changed__c?'T':'F'; 
        }
        
        If(!test.isrunningtest())
            note_account_executive  = (salesOrderRec.Account_Executives__c != null)?salesOrderRec.Account_Executives__c:'';
        note_billing_instructions  = (salesOrderRec.Billing_Instructions__c != null)?salesOrderRec.Billing_Instructions__c:'';
        note_contact  = salesOrderRec.Bill_to_Contact__c;
        note_contract_name  = (salesOrderRec.Contract_Name__c != null) ?salesOrderRec.Contract_Name__c:'';
        note_Surcharge_pct  = (salesOrderRec.Surcharge_Pct__c != null)?salesOrderRec.Surcharge_Pct__c:0;
        note_Surcharge_type  = (salesOrderRec.Contract_Surcharge_Type__c != null)?salesOrderRec.Contract_Surcharge_Type__c:'';
        
        if(salesOrderRec.Country__c != null){
            if(salesOrderRec.Country__c == 'US'){
                note_country = 'USA';
            }
            else{
                note_country = salesOrderRec.Country__c;
            }
        }
        else{
            note_country = '';
        }
        note_instructions  = (salesOrderRec.Customer_Billing_Instructions__c != null)?salesOrderRec.Customer_Billing_Instructions__c:'';
        note_internal_comments  = (salesOrderRec.Internal_Comments__c != null)?salesOrderRec.Internal_Comments__c:'';
        If(!test.isrunningtest())
            note_payment_term  = (salesOrderRec.Payment_Term__c != null) ?salesOrderRec.Payment_Term__c:'';
        if(salesOrderRec.From_Sales_Quote__c != null)
            note_sales_quote  = salesOrderRec.From_Sales_Quote__c;
        else
            note_sales_quote = ''; 
        note_subsidiary_company  = (salesOrderRec.Subsidiary_Company__c != null) ?salesOrderRec.Subsidiary_Company__c:'';
        note_surcharge_pct  = (salesOrderRec.Surcharge_Pct__c != null)?salesOrderRec.Surcharge_Pct__c:0;
        note_surcharge_amount  = (salesOrderRec.Surcharge_Amount__c != null)?salesOrderRec.Surcharge_Amount__c:0;
        note_surcharge_type  = (salesOrderRec.Surcharge_Type__c != null)?salesOrderRec.Surcharge_Type__c:'';
        If(!test.isrunningtest()) 
            note_tax_area  = (salesOrderRec.Tax_Area__c != null)?salesOrderRec.Tax_Area__c:'';
        note_tax_liable  =salesOrderRec.Tax_Liable__c;
        if(salesOrderRec.Contract__c != null)
            SalesforceContractNumber = salesOrderRec.Contract__r.ContractNumber;
        if(salesOrderRec.Site_Scope__c != null)
        {
            if(salesOrderRec.Site_Scope__c.length() > 250)
                description = salesOrderRec.Site_Scope__c.substring(0,250);
            else
                description = salesOrderRec.Site_Scope__c; 
        }
        ProjectName = (salesOrderRec.CMR_Description__c!=null)?salesOrderRec.CMR_Description__c:'';
        
        if (salesOrderRec.Site_City__c != null) {
            GenMailCity = salesOrderRec.Site_City__c.toUpperCase();
            GeneratorCity = salesOrderRec.Site_City__c.toUpperCase();
        }
        if (salesOrderRec.Site_Country__c != null) {
            if (salesOrderRec.Site_Country__c == 'US') {
                GenMailCountry = 'USA';
                GeneratorCountry = 'USA';
            } else {
                GenMailCountry = salesOrderRec.Site_Country__c.toUpperCase();
                GeneratorCountry = salesOrderRec.Site_Country__c.toUpperCase();
            }
        }
        if (salesOrderRec.Site_Postal_Code__c != null) {
            GenMailZipCode = salesOrderRec.Site_Postal_Code__c.toUpperCase();
            GeneratorZipCode = salesOrderRec.Site_Postal_Code__c.toUpperCase();
        }
        if (salesOrderRec.Site_State__c != null) {
            GenMailState = salesOrderRec.Site_State__c.toUpperCase();
            GeneratorState = salesOrderRec.Site_State__c.toUpperCase();
        }
        if (salesOrderRec.Site_Street__c != null) {
            GenMailAddress1 = salesOrderRec.Site_Street__c.toUpperCase();
            GeneratorAddress1 = salesOrderRec.Site_Street__c.toUpperCase();
        }
        String siteName = salesOrderRec.Site_Name__c.toUpperCase();
        if (siteName != null) {
            if (siteName.length() > 40) {
                siteName = siteName.substring(0, 40);
            }
            GeneratorName = siteName;
        } else {
            GeneratorName = '';
        }
        String sitePhone = salesOrderRec.Site_Phone_No__c;
        if (sitePhone != null) {
            sitePhone = sitePhone.replaceAll('[^\\d]', '');
            if (sitePhone.length() > 10) {
                sitePhone = sitePhone.substring(sitePhone.length() - 10);
            }
            GeneratorPhone = sitePhone;
        } else {
            GeneratorPhone = '';
        }
        String GenMailSiteName = salesOrderRec.Site_Name__c.toUpperCase();
        if (GenMailSiteName != null) {
            if (GenMailSiteName.length() > 40) {
                GenMailSiteName = GenMailSiteName.substring(0, 40);
            }
            GenMailName = GenMailSiteName;
        } else {
            GenMailName = '';
        }
        NAICScode =0;
        GeneratorStatus = 'A'; 
        AsSoDisposalFlag = 'T';
        StartDate = salesOrderRec.Estimated_Job_Start_Date__c;
        EndDate = salesOrderRec.Estimated_Job_End_Date__c;
        if(salesOrderRec.EQAI_Billing_Project_Id__c!= null)
            BillingProjectId = Integer.ValueOf(salesOrderRec.EQAI_Billing_Project_Id__c);
        //US133594
		SalesforceSoCsid = salesOrderRec.Id;
    }
}