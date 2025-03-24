/*************************************************************************************************
* Name         :  WorkOrderQuoteDetailsJSON 
* Description  :  JSON Class for API call out of the work order Quote Details Service
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Praneeth Yalamati         08-17-2023             US94501: Create Work Order in EQAI when Convert Quote to Order button is pressed
* Praneeth Yalamati         09-29-2023             US97345: WorkOrderQuoteDetail JSON Updates
* Praneeth Yalamati         10-06-2023             US97655: ACV: WorkOrderQuoteDetail JSON updates for Tasks
* Sanjana Ravichandran      11-24-2023             Task72439: WorkOrderQuoteDetail JSON updates for Tasks - Add Salesforce CSID as column to API
* Sathish Rosekumar         11-28-2023             Task74762: Updated the logic values in Quantity, quantity_std, quantity_ot, quantity_dt based on category 
* Andrew Simons             12-07-2023             Updated EQAI field salesforce_QUOTE_ID to project_code
* Vennila Paramasivam		12-18-2023			   Task74762 : Updated the mapping Quantity = Quantity__c, before it was UOM_Qty.
* Vennila Paramasivam		01-31-2024			   Task77590, 77591, 77597 : Updated Quantity, Quantity_std, Quantity_ot and price mapping
* Vennila Paramasivam		03-07-2024			   Task80081- Updated the ResourceCSID and ResourceClassCSID with External Id.
* Prabhu Rathakrishnan      03-15-2024             Task81370-EQAI - No Ext Amt or Ext Cost Totals on WOQ For Supplies Tab
* Vennila Paramasivam		03-22-2024			   Task81412 - Added employee_id
* Vennila Paramsivam		03-29-2024			   Task82268 - Mapping Quantity as Quantity_Std for others tab
                                                    and Quantity = 1 by default for WasteDisposal
* Vennila Paramasivam		04-11-2024			   Task84552 - Line cost won't send for Parent bundled.
												   Task84886 - Updated the mapping based on 84886.
												   Task84664 - Updated the mapping price =0 for child bundle items
* Sanjana Ravichandran      05/13/2024             Bug 84930: Salesforce Equipment Resources Mapping to EQAI Type Supply Are Failing to Integrate on the Work Order Quote & Work Oder
* Vennila Paramasivam		05-13-2024			    Task 86884 - Updated labor Quantity Std, dt and Price mappings.
* Sanjana Ravichandran 		08-19-2024				US122329: Salesforce - Limit Characters for Fields
*************************************************************************************************/
public class WorkOrderQuoteDetailsJSON {

    Public Decimal profit_ctr_id;
    Public Decimal company_id;
    Public String project_code;
    Public String resource_type;
    Public String days_needed;
    Public String service_desc;
    Public Decimal quantity_dt;
    Public Decimal price_dt;
    Public String line_amount;
    Public String line_amt_incl_tax;
    Public String line_cost;
    Public String salesforce_so_quote_line_id;
    Public String markup;
    Public String markup_option;
    Public Decimal quantity_ot;
    Public Decimal price_ot;
    Public Decimal Quantity;
    Public Decimal quantity_std;
    Public String regular_rate;
    Public String resource_item_code;
    Public String tax;
    Public String tax_percent;
    Public String tax_group;
    Public Decimal cost;
    Public String bill_unit_code;
    Public Decimal price;
    public String salesforce_bundle_ID;
    public String Salesforce_Task_CSID;
    public String Salesforce_Task_Name;
    public String salesforce_resource_csid;
    public String salesforce_resourceclass_CSID;
    public String employee_id;
        
    public WorkOrderQuoteDetailsJSON(Sales_Line__c salesLineRecord, Decimal profitCtrId, Decimal companyId,  Map<String,String> resource_Type_EQIMap, Map<String,String> bill_Unit_Code_EQIMap, String employeeId){
    
        
        
        employee_id = employeeId;
        Quantity = 0;
        cost = 0;
        quantity_ot = 0;
        quantity_dt = 0; 
        price_dt = 0;
        if(profitCtrId != null) profit_ctr_id = profitCtrId ;
        if(companyId != null) company_id = companyId;
        if(salesLineRecord.Sales_Order__c != null) project_code = salesLineRecord.Sales_Order__r.Name;
        if(salesLineRecord.Category__c != null && resource_Type_EQIMap !=null && resource_Type_EQIMap.containsKey(salesLineRecord.Category__c)) {
            if(salesLineRecord.Resource_Type__r.EQAI_Supply__c) {
                resource_type = 'S';
            }
            else if(salesLineRecord.Resource__r != null && salesLineRecord.Category__c == 'Materials' && salesLineRecord.Resource__r.EQAI_Other__c){
                     resource_type = 'O';   
                }
            else{
                resource_type = resource_Type_EQIMap.get(salesLineRecord.Category__c);
            }
        }    
        if(salesLineRecord.Number_of_Day__c != null) days_needed = String.valueOf(salesLineRecord.Number_of_Day__c);
        String Descrpt =  salesLineRecord.Description__c;
        if (Descrpt != null) {
            if (Descrpt.length() > 100) {
                Descrpt = Descrpt.substring(0, 100);
            }
            service_desc = Descrpt;
        } else {
            service_desc = '';
        }
        if(salesLineRecord.Line_Amount__c != null) line_amount = String.valueOf(salesLineRecord.Line_Amount__c);
        if(salesLineRecord.Line_Amt_Incl_Tax__c!= null) line_amt_incl_tax = String.valueOf(salesLineRecord.Line_Amt_Incl_Tax__c);
        //84552 Parent bundled should not populate cost
        if(salesLineRecord.Line_Cost__c != null /* && salesLineRecord.Category__c !='Bundled'*/) line_cost = String.valueOf(salesLineRecord.Line_Cost__c);
        if(salesLineRecord.Line_No__c != null) salesforce_so_quote_line_id = String.valueOf(salesLineRecord.Line_No__c);
        if(salesLineRecord.Markup__c >0) markup = String.valueOf(salesLineRecord.Markup__c);
        if(salesLineRecord.Markup_Option__c != null) markup_option = salesLineRecord.Markup_Option__c;
        if(salesLineRecord.Unit_of_Measure__c != null && bill_Unit_Code_EQIMap !=null 
            	&& bill_Unit_Code_EQIMap.containsKey(salesLineRecord.Unit_of_Measure__r.Name)) 
        {
             bill_unit_code = bill_Unit_Code_EQIMap.get(salesLineRecord.Unit_of_Measure__r.Name);
        }
            
        //74762 and Task77590, 77591, 77597 
        if(salesLineRecord.Overtime_Rate__c >0 ) 
            price_ot =salesLineRecord.Overtime_Rate__c;
        else
            price_ot = 0;
        
        // Quantity mapping          
        if(salesLineRecord.Quantity__c != null && salesLineRecord.Quantity__c > 0)
            Quantity = salesLineRecord.Quantity__c;
        
        
        //Price mapping
        if(salesLineRecord.Category__c =='Labor' && salesLineRecord.Regular_Rate__c >0 &&  bill_unit_code == 'HOUR' )
        	price = salesLineRecord.Regular_Rate__c;
        else if(salesLineRecord.Category__c =='Labor' &&  bill_unit_code != 'HOUR'  && salesLineRecord.Unit_Price__c > 0)
            price = salesLineRecord.Unit_Price__c;
        else if(salesLineRecord.Category__c !='Labor' && salesLineRecord.Unit_Price__c > 0)
            price = salesLineRecord.Unit_Price__c;
        else
            price = 0;
        
        //Regular Time mapping
        if(salesLineRecord.Category__c =='Labor'  && salesLineRecord.Regular_Hours__c > 0 && bill_unit_code == 'HOUR')
        {
           quantity_std = salesLineRecord.Regular_Hours__c; 
        }  
        else if(salesLineRecord.Category__c =='Labor' && bill_unit_code != 'HOUR')
        {
           quantity_std = salesLineRecord.Number_of_Day__c *  saleslineRecord.UOM_Qty__c ; 
        } 
        else if(salesLineRecord.Category__c =='Equipment' && saleslineRecord.UOM_Qty__c > 0)
        {
          quantity_std = salesLineRecord.Number_of_Day__c *  saleslineRecord.UOM_Qty__c ;
        }            
        else if(salesLineRecord.Category__c !='Labor' && salesLineRecord.Category__c !='Equipment')
        {
            quantity_std = saleslineRecord.Quantity__c; 
            Quantity = 1;
            
        }           
        else
           quantity_std = 0;
        
        // Overtime mapping
        if(salesLineRecord.Category__c =='Labor' && salesLineRecord.Overtime_Hours__c >0 && bill_unit_code == 'HOUR')
     		quantity_ot = salesLineRecord.Overtime_Hours__c;
       
            
        
        //DoubleTime Mapping
        if(salesLineRecord.Category__c =='Labor' && salesLineRecord.Premium_Hours__c >0 && bill_unit_code == 'HOUR')  
        	quantity_dt = salesLineRecord.Premium_Hours__c; 
        
            
      
       //cost mapping
       if(salesLineRecord.Unit_Cost__c>0 && salesLineRecord.Category__c !='Bundled')
           cost = salesLineRecord.Unit_Cost__c;
       
           
       // premium rate mapping    		            
       if(salesLineRecord.Premium_Rate__c >0 )
           price_dt = salesLineRecord.Premium_Rate__c;
       
           
        
       if(salesLineRecord.Regular_Rate__c!= null) regular_rate = String.valueOf(salesLineRecord.Regular_Rate__c);
      
       if((salesLineRecord.Category__c =='Labor' || salesLineRecord.Category__c =='Equipment' || salesLineRecord.Category__c =='Bundled'))
        {
            salesforce_resourceclass_CSID = salesLineRecord.Resource_Type__r.External_Id__c; //salesLineRecord.Resource_Type__c;
            if(salesLineRecord.Resource_Type__c != null && salesLineRecord.Resource_Type__r.Resource_Class_Code__c != null)
            {
                resource_item_code = salesLineRecord.Resource_Type__r.Resource_Class_Code__c;
               
            }
            else
            {
               resource_item_code = ''; 
            }
                
        }
        else
        {
           resource_item_code = salesLineRecord.Resource__r.Resource_Class_Code__c;
           salesforce_resourceclass_CSID =salesLineRecord.Resource__r.External_Id__c; //salesLineRecord.Resource__r.CSID__c;
        }
        
        if(salesLineRecord.Tax__c != null) tax = String.valueOf(salesLineRecord.Tax__c);
        if(salesLineRecord.Tax_Pct__c != null) tax_percent = String.valueOf(salesLineRecord.Tax_Pct__c);
        if(salesLineRecord.Tax_Group__c != null) tax_group = salesLineRecord.Tax_Group__c;
       
        if(salesLineRecord.Category__c =='Bundled' && resource_type == 'O') salesforce_bundle_ID = salesLineRecord.Name;
        if(salesLineRecord.Bundle_Line__c !=null ) {
            salesforce_bundle_ID = salesLineRecord.Bundle_Line__r.Name;
            price = 0; // 84664
            price_ot = 0;
            price_dt = 0;
            cost = salesLineRecord.xUnit_Cost__c;
            
        }
        if(salesLineRecord.Sales_Order_Job_Task__c != null) Salesforce_Task_CSID = salesLineRecord.Sales_Order_Job_Task__c;
        if(salesLineRecord.Sales_Order_Job_Task__c != null && salesLineRecord.Sales_Order_Job_Task__r.Name !=null) Salesforce_Task_Name = salesLineRecord.Sales_Order_Job_Task__r.Name;
        if(salesLineRecord.Resource__c != null && salesLineRecord.Resource__r.External_Id__c != null ) salesforce_resource_csid = salesLineRecord.Resource__r.External_Id__c;//salesLineRecord.Resource__r.CSID__c;   
		
		//salesforce_resourceclass_CSID = '';
        //salesforce_resource_csid = '';
     
    }        
                
    
   
}