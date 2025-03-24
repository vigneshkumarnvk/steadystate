/*************************************************************************************************
* Name         :  SalesInvLineWODetailsJSON 
* Description  :  Construct JSON for SalesInvoiceWorkOrderService
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Vennila P       11-24-2023           73779: Create Work order header in EQAI 
                          when Sales Invoice and Sales Invoice Lines created in Salesforce
* Vennila P      12-18-2023       74081: Sending value as blank if it is null in salesforce
* Vennila P		 2/23/2023		  79187 : Sending BillRate as 1.0 by default for all category except labor
* Andrew S     3/5/2024       80112 : ExtendedPrice updated to receive Line_Amt_Incl_Tax__c and note_line_amt updated to receive Line_Amount__c
* Vennila Paramasivam		03-07-2024			   Task80081- Updated the ResourceCSID and ResourceClassCSID with External Id.
* Vennila Paramasivam		03-13-2024			   Task81421- Updated the Createdby and Lastmodifiedby with RSG_EIN__c
* Prabhu Rathakrishnan      03-21-2024             Task82264- P2 - Resource type = Supply in EQAI don't send Resource ID from SF
* Vennila Paramasivam		03-22-2024			   Task81412 - Added employee_id
* Andrew S              4/8/2024       83635 : ExtendedPrice updated to receive Line_Amount__c and note_line_amt_incl_tax updated to receive Line_Amt_Including_Tax__c
* Vennila Paramasivam	4/23/2024	   82344:Child - No price ,With cost
										Parent - with Price - No cost
* Vennila Paramasivam	04/29/2024		83646 - Sending InvoiceTax as a seperate line item
  Shahwaz Khan          05/06/2024      86613 - Salesforce - Change mapping for BOL manifest number (RSG#)
* Sanjana Ravichandran      05/13/2024             Bug 84930: Salesforce Equipment Resources Mapping to EQAI Type Supply Are Failing to Integrate on the Work Order Quote & Work Oder
* Vennila Paramasivam		06-18-2024				US115603: Adding TM Number .
* Sanjana Ravichandran		08/21/2024	US122329: Salesforce - Limit Characters for Fields			
* Sanjana Ravichandran		08/21/2024	US122329: Salesforce - Limit Characters for Fields	
* Sanjana Ravichandran 		09/02/2024  US118336: Salesforce - Send Billing Package Lines to Existing Work Order and Map to Disposal tab
* Sanjana Ravichandran 		10/01/2024  DE35882: [Continued] [Unplanned] Map start and end date to work order from billing package submission
* Pavithra Periyasamy		11/07/2024  US129598: [Continued] SF -  Create single JSON object for billing package integration
* Andrew Simons             12/05/2024             US134521: Salesforce - updated to include Profile Id from tm line in sales invoice query
* Prabhu Rathakrishnan      12/05/2024             US132386: Salesforce - Move 'Disposal Billing Method' field to be on Sales Lines of Sales Quote/Order
* Sanjana Ravichandran 		12/27/2024			   US135268: Salesforce - Send bill rate based on Disposal Billing Method
*************************************************************************************************/


public class SalesInvLineWODetailsJSON {
    public string Manifest;
    public string SalesforceBundleId; 
    public string ResourceType; 
    public string Description; 
    public string TSDFCode; 
    public Decimal ExtendedPrice; 
    public Decimal ExtendedCost; 
    public string SalesforceInvoiceLineId; 
    public Decimal BillRate; 
    public string PriceSource; 
    public string PrintOnInvoiceFlag; 
    public decimal QuantityUsed; 
    public decimal Quantity; 
    public string ResourceAssigned; 
    public string ResourceClassCode; 
    public string SfTaskName; 
    public Date StartDate; 
    public Decimal Cost; 
    public string BillUnitCode; 
    public integer CompanyId; 
    public datetime DateService; 
    public decimal Price; 
    public integer PricedFlag;
    public string PriceClass; 
    public integer ProfitCenterId; 
    public decimal BillingSequenceId;   
    public string currency_code;
    public date date_added;
    public date date_modified;
    public string group_instance_id; 
    public string PrevailingWageCode;
    public string sequence_ID; 
    //public string workorder_ID;
    //public string SalesforceInvoiceCsid;
    public integer WorkOrderTypeId;
    Public string note_contract_line;
    public decimal note_line_amt_incl_tax;
    public string note_tm;
    public string SalesforceInvoiceCSID;
    public string SalesforceResourceCsid;
    public string SalesforceResourceClassCSID;
    public string employee_id;
    Public string  SalesTaxLineFlag;
	Public string  Description2;
    Public string note_tmNumber;
    Public Integer ResourceCompanyId;
    Public string tsdfApprovalCode;
    Public string AsMapDisposalLine;
    Public string SalesforceSoCsid;
    Public string AsWohDisposalFlag;
    public string Profileid;
    public date start_date;
    public date end_date;
    public String old_billunitcode;
    public Integer workorder_id;
    
    
    public SalesInvLineWODetailsJSON(Sales_Invoice_Line__c salesInvoiceRec,Integer companyId1, Integer profitCtrId,Map<String,String> resource_Type_EQIMap, Map<String,String> bill_Unit_Code_EQIMap, String employeeId, boolean runTaxLine, Integer resCompanyId, Boolean wasteDisposal)
    {
        
        employee_id=employeeId;
        AsWohDisposalFlag = 'F';
        
        if(runTaxLine != true)
        {
          BillingSequenceId =0 ;
          ResourceCompanyId = resCompanyId;        
          Price = 0;
            //86613
            if(salesInvoiceRec.Category__c =='Waste Disposal'){
                Description2 = (salesInvoiceRec.BOL_Manifest__c != null)?salesInvoiceRec.BOL_Manifest__c:'';
            }
            else{
                Manifest = (salesInvoiceRec.BOL_Manifest__c != null)?salesInvoiceRec.BOL_Manifest__c:'';  
            }
         	 SalesforceBundleId = salesInvoiceRec.Bundle_Line__r.Id;
          
          	if(salesInvoiceRec.Category__c != null && resource_Type_EQIMap !=null && resource_Type_EQIMap.containsKey(salesInvoiceRec.Category__c)) {
            if(salesInvoiceRec.Resource_Type__r.EQAI_Supply__c) {
                    ResourceType = 'S';
                }
                else if(salesInvoiceRec.Resource__r != null && salesInvoiceRec.Category__c == 'Materials' && salesInvoiceRec.Resource__r.EQAI_Other__c){
                     ResourceType = 'O';   
                }
                else{
                    ResourceType = resource_Type_EQIMap.get(salesInvoiceRec.Category__c);
                }
        	}
 			//Description = (salesInvoiceRec.Description__c != null)?salesInvoiceRec.Description__c:'';
            String descp = salesInvoiceRec.Description__c;
            if (descp != null) {
                if (descp.length() > 100) {
                    descp = descp.substring(0, 100);
                }
                Description = descp;
            } else {
                Description = '';
            }          
            
          TSDFCode = (salesInvoiceRec.Facility__c != null)?salesInvoiceRec.Facility__r.TSDF_Code__c:'';
          ExtendedPrice = (salesInvoiceRec.Line_Amount__c != null)?salesInvoiceRec.Line_Amount__c:0; // 83635
          ExtendedCost = (salesInvoiceRec.Line_Cost__c != null)?salesInvoiceRec.Line_Cost__c:0;
          SalesforceInvoiceLineId = (salesInvoiceRec.Name != null)?salesInvoiceRec.Id:'';
          
         if(salesInvoiceRec.Non_billable__c == True)
           BillRate = 0.0;
         else if(salesInvoiceRec.Time_Rate_Code__c == 'REG')
           BillRate = 1.0;
         else if (salesInvoiceRec.Time_Rate_Code__c == 'OT')
           BillRate = 1.5;
         else if (salesInvoiceRec.Time_Rate_Code__c == 'DT')
           BillRate = 2.0;
        //79187 && 86684
         if(BillRate == Null)
             BillRate = 1.0;
        
         PriceSource = (salesInvoiceRec.Pricing_Source_2__c != null)?salesInvoiceRec.Pricing_Source_2__c:'';
         PrintOnInvoiceFlag = salesInvoiceRec.Print_Line__c == True?'T':'F';
         QuantityUsed = (salesInvoiceRec.Qty_to_Display__c != null)?decimal.valueOf(salesInvoiceRec.Qty_to_Display__c):0;
         Quantity = (salesInvoiceRec.Quantity__c != null)?salesInvoiceRec.Quantity__c:0;
         ResourceAssigned = (salesInvoiceRec.Resource__c != null)?salesInvoiceRec.Resource__r.Name:'';
         
        if((salesInvoiceRec.Category__c =='Labor' || salesInvoiceRec.Category__c =='Equipment'))
        {
         SalesforceResourceClassCSID = salesInvoiceRec.Resource_Type__r.External_id__c;//salesInvoiceRec.Resource_Type__c;
         SalesforceResourceCsid = salesInvoiceRec.Resource__r.External_id__c;//salesInvoiceRec.Resource__r.CSID__c; 
          if(salesInvoiceRec.Resource_Type__c != null)
         		ResourceClassCode = salesInvoiceRec.Resource_Type__r.Resource_Class_Code__c;
          else
                   ResourceClassCode = '';
        }
        else
        {
            ResourceClassCode = salesInvoiceRec.Resource__r.Resource_Class_Code__c;
            SalesforceResourceClassCSID = salesInvoiceRec.Resource__r.External_id__c;//salesInvoiceRec.Resource__r.CSID__c;
            SalesforceResourceCsid = '';
        }
        
         SfTaskName = (salesInvoiceRec.Sales_Invoice_Job_Task__c != null)?salesInvoiceRec.Sales_Invoice_Job_Task__r.Name:'';
         StartDate = salesInvoiceRec.Scheduled_Date__c;
         Cost = (salesInvoiceRec.Unit_Cost__c != null)?salesInvoiceRec.Unit_Cost__c:0;
         Price = salesInvoiceRec.Unit_Price__c;
         
        //82344 
         if(salesInvoiceRec.Category__c =='Bundled')
         {
             SalesforceBundleId = salesInvoiceRec.id;
             Cost =0;
         }
          
         if(salesInvoiceRec.Bundle_Line__c != Null)
         {
             Price = 0;
             BillRate = 0.0;
         }
          
        
        // BillUnitCode = (salesInvoiceRec.Unit_of_Measure__c != null)?salesInvoiceRec.Unit_of_Measure__c:'';
        
         if(salesInvoiceRec.Unit_of_Measure__c != null && bill_Unit_Code_EQIMap !=null && bill_Unit_Code_EQIMap.containsKey(salesInvoiceRec.Unit_of_Measure__r.Name)) 
                BillUnitCode = bill_Unit_Code_EQIMap.get(salesInvoiceRec.Unit_of_Measure__r.Name);
        
        
         CompanyId = companyId1;//Integer.valueOf(salesInvoiceRec.Service_Center__r.Name);
         
         DateService = salesInvoiceRec.Scheduled_Date__c;
         ProfitCenterId = profitCtrId;//String.valueOf(profitCtrId);//salesInvoiceRec.Service_Center__r.Name;
         PriceClass = (salesInvoiceRec.Resource_Class_Code__c != null)?salesInvoiceRec.Resource_Class_Code__c:''; 
         SalesforceInvoiceCSID = salesInvoiceRec.Sales_Invoice__r.CSID__c;       
         note_contract_line  = salesInvoiceRec.Contract_Line__c;
         note_line_amt_incl_tax = salesInvoiceRec.Line_Amt_Incl_Tax__c; // 83635
         note_tm  = salesInvoiceRec.TM__c;
         SalesTaxLineFlag = 'F';
                //87285
         if(PriceSource == '')
         {
             PriceSource = salesInvoiceRec.Sales_Invoice__r.Sales_Order__r.Name;
         }
         if(salesInvoiceRec.TM__c != Null)
         note_tmNumber = salesInvoiceRec.TM__r.Name;
            
		
       }
       else
       {
          // 83646 - Sending InvoiceTax as a seperate line item
           Description = 'Sales Tax'; //86837
           Price = salesInvoiceRec.Sales_Invoice__r.Invoice_Tax__c;
           ExtendedPrice = salesInvoiceRec.Sales_Invoice__r.Invoice_Tax__c;
           ExtendedCost = salesInvoiceRec.Sales_Invoice__r.Invoice_Tax__c;
           BillUnitCode = 'EACH';
           Quantity = 1;
           ResourceClassCode ='FEESLSTX';
           ResourceType = 'O';
           CompanyId = companyId1;
           ProfitCenterId = profitCtrId;
           SalesforceInvoiceCSID = salesInvoiceRec.Sales_Invoice__r.CSID__c;
           SalesforceInvoiceLineId = salesInvoiceRec.Sales_Invoice__r.CSID__c;
           SalesTaxLineFlag = 'T';           
           QuantityUsed = 1;
           BillRate = 1.0;
           PriceSource = salesInvoiceRec.Sales_Invoice__r.Sales_Order__r.Name;
           
       }
       
        if(PriceSource != Null)
        {
            if(PriceSource.length() > 40)
                PriceSource = PriceSource.subString(0,40);
        }
       
        
        //DISPOSAL LINE ATTRIBUTES
        if(wasteDisposal){
            AsWohDisposalFlag = 'T';
            SalesforceSoCsid = salesInvoiceRec.Sales_Invoice__r.Sales_Order__r.Id;
            start_date = salesInvoiceRec.Sales_Invoice__r.First_Service_Date__c != null ?salesInvoiceRec.Sales_Invoice__r.First_Service_Date__c:null; 
        	end_date = salesInvoiceRec.Sales_Invoice__r.Last_Service_Dates__c != null ?salesInvoiceRec.Sales_Invoice__r.Last_Service_Dates__c :null;
            if(salesInvoiceRec.Category__c =='Waste Disposal'){
                tsdfApprovalCode = salesInvoiceRec.TM_Line__r.Approval_Id__c;
                Profileid = salesInvoiceRec.TM_Line__r.Profile_Id__c;
                AsMapDisposalLine = (salesInvoiceRec.Disposal_Billing_Method__c == 'Direct') ? 'D' : 'I';
                //AsMapDisposalLine = (salesInvoiceRec.Sales_Invoice__r.Sales_Order__r.Disposal_Billing_Method__c == 'Direct') ? 'D' : 'I';
                ResourceType = 'D';
                Manifest = (salesInvoiceRec.BOL_Manifest__c != null)?salesInvoiceRec.BOL_Manifest__c:'';  
                //US129598: 
                workorder_id = salesInvoiceRec.TM_Line__r.BOL_Manifest_Workorder_Id__c != null ? Integer.valueOf(salesInvoiceRec.TM_Line__r.BOL_Manifest_Workorder_Id__c) : null;
                old_billunitcode = 	salesInvoiceRec.TM_Line__r.EQAI_Bill_Unit_Code__c;
                if(salesInvoiceRec.Description__c == 'Manifest Fee' || ResourceAssigned == 'Manifest Fee'){
                    ResourceType = 'O';
                }
                if (salesInvoiceRec.Disposal_Billing_Method__c == 'Direct') {
                    // If it's Direct billing, set BillRate to -1
                    BillRate = -1.0;
                } else if (salesInvoiceRec.Disposal_Billing_Method__c == 'Indirect') {
                    // If it's Indirect billing, set BillRate to 1
                    BillRate = 1.0;
                } 
                // If Disposal Billing Method is neither Direct nor Indirect, check for bundle condition
                if (salesInvoiceRec.Bundle_Line__c != null) {
                    // If it's part of a bundle, set BillRate to 0
                    BillRate = 0.0;
                }
            }
        }
        
    }
}