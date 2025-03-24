/*************************************************************************************************
* Name         :  WorkOrderQuoteHeaderJSON
* Description  :  JSON Apex Class for WorkOrderQuoteHeader
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Praneeth Yalamati         08-17-2023             US94501: Create Work Order in EQAI when Convert Quote to Order button is pressed
* Prabhu Rathakrishnan      11-13-2023             Task74219: Salesforce - Generator ID - Add Generator ID to JSON msg
* Andrew Simons             11-14-2023             Task74481 Salesforce - Update JSON
* Prabhu Rathakrishnan      12-28-2023             Task74716: The Sales quote which was created in Salesforce without utilizing the generator  lookup was not integrated in EQAI.
* Shahwaz Khan              01-09-2024             Task75619: Salesforce - Save ALL Site Addresses
* Prabhu Rathakrishnan      01-10-2024             Task75621: Salesforce - Add Fields for "Generator ID and "EPA ID"
* Prabhu Rathakrishnan      02-12-2024             Task78245: Observation: Salesforce - Generator ID is not exist in EQAI generator table error message during Quote/order creation
* Vennila Paramasivam		02-16-2024			   Task78892: Updating D365_Account_Number mapping
* Prabhu Rathakrishnan      02-16-2024             Task78482: Salesforce - Need EPA ID field editable in the Generator lookup
* Vennila Paramasivam		03-05-2024			   Task80420: Mapping confirm_author with Created_By
* Sanjana Ravichandran      03-06-2024			   Requirement 80420: Salesforce - Pass the @confirm_author to EQAI in WOQ and WO
* Prabhu Rathakrishnan      11-13-2023             Task81356: Salesforce - WOQ - Generator Phone # Formatting is Incorrect
* Prabhu Rathakrishnan      11-14-2023             Task81560: EQAI Generator Phone Number Formatting
* Prabhu Rathakrishnan 		03-20-2024      		82266: P3 - Salesforce - Country ID for USA sending as US
* Vennila Paramasivam		03-22-2024			   Task81412 - Added employee_id
* Prabhu Rathakrishnan 		03-25-2024      		82265:P3 - Salesforce - Generator site mailing address wrong went order sent to EQAI
* Prabhu Rathakrishnan      04-10-2024             83374:Salesforce - EPA ID From Salesforce 
* Sathish				    04-22-2024             84645:Converted site address details in to uppercase  
* Sanjana Ravichandran 		08-19-2024				US122329: Salesforce - Limit Characters for Fields
*************************************************************************************************/
public class WorkOrderQuoteHeaderJSON {

    public String  account_executive;   
    Public String  bill_to_contact;
    Public String  d365customer_id;
    Public String  Gen_Mail_City;
    Public String  Gen_Mail_Country;
    Public String  estimated_job_end_date;
    Public String  estimated_job_end_time;
    Public String  start_date;
    Public String  estimated_job_start_time;
    Public string  project_name;
    Public string  salesforce_SO_QUOTE_ID;
    Public Decimal Total_Price;
    Public String  order_total_amount_incl_tax;
    Public String  order_total_tax;
    Public String  pay_rule;
    Public String  project_code;
    Public String  Generator_Phone;
    Public String  Gen_Mail_Zip_Code;
    Public String  prevailing_wage_job;
    Public String  project_manager;
    Public String  project_scope;
    Public Integer company_id;
    Public Integer profit_ctr_id;
    Public String  generator_city;
    Public String  Generator_Country;
    Public String  Generator_Zip_Code;
    Public String  generator_state;
    Public String  Generator_Address_1;
    Public String  Gen_Mail_State;
    Public String  subsidiary_company;
    Public String  tax_area;
    Public String  tax_liable;
    Public Decimal Total_Cost;
    Public Integer generator_id;
    public String curr_status_code;
    public String generator_name;
    public String salesforce_site_csid;
    public String EPA_ID;
    public String status;
    public String confirm_author;
    public String employee_id;
    public String Gen_Mail_Address_1;
    public integer use_contact_id;            
   
     public WorkOrderQuoteHeaderJSON(Sales_Order__c orderRecord ,map<String,String> project_Code_EQIMap, map<String,String>  company_Id_EQIMap, map<String,String> profit_Ctr_Id_EQIMap, String employeeId){
        
         
        employee_id = employeeId;
        if(orderRecord.Account_Executives__c != null) account_executive = orderRecord.Account_Executives__r.Name;
         //80266
        if(orderRecord.Bill_to_Contact__c != null)  bill_to_contact = orderRecord.Bill_to_Contact__c; 
        //78892 update the Account number mapping to D365 Account number
        if(orderRecord.Bill_to_Customer_No__c != null && orderRecord.Bill_to_Customer_No__r.Sage_Customer_No__c !=null ) d365customer_id = orderRecord.Bill_to_Customer_No__r.Sage_Customer_No__c;
        if(orderRecord.City__c != null) Gen_Mail_City = orderRecord.Site_City__c.toUpperCase();//84645:Converted site address details in to uppercase
        if(orderRecord.Site_Country__c != null) {
             if(orderRecord.Site_Country__c =='US'){
                 Gen_Mail_Country = 'USA';
             }
             else{
            	Gen_Mail_Country = orderRecord.Site_Country__c.toUpperCase();//84645:Converted site address details in to uppercase
             }
        }
        if(orderRecord.Estimated_Job_End_Date__c != null) estimated_job_end_date = String.valueOf(orderRecord.Estimated_Job_End_Date__c);
        if(orderRecord.Estimated_Job_End_Time__c != null) estimated_job_end_time = String.valueOf(orderRecord.Estimated_Job_End_Time__c);
        if(orderRecord.Estimated_Job_Start_Date__c != null) start_date = String.valueOf(orderRecord.Estimated_Job_Start_Date__c);
        if(orderRecord.Estimated_Job_Start_Time__c != null) estimated_job_start_time = String.valueOf(orderRecord.Estimated_Job_Start_Time__c);
        if(orderRecord.CMR_Description__c != null) project_name = orderRecord.CMR_Description__c;
        if(orderRecord.Name != null) salesforce_SO_QUOTE_ID = orderRecord.Name;
        if(orderRecord.Name != null) project_code = orderRecord.Name; 
        Total_Price = orderRecord.Order_Total_Amount__c > 0 ? orderRecord.Order_Total_Amount__c : 0 ;
        if(orderRecord.Order_Total_Amount_Incl_Tax__c != null) order_total_amount_incl_tax = String.valueOf(orderRecord.Order_Total_Amount_Incl_Tax__c);
        if(orderRecord.Order_Total_Tax__c != null) order_total_tax = String.valueOf(orderRecord.Order_Total_Tax__c);
        if(orderRecord.Pay_Rule__c != null) pay_rule = orderRecord.Pay_Rule__r.Name; 
        if(orderRecord.Payment_Term__c != null && orderRecord.Payment_Term__r.Name != null && project_Code_EQIMap !=null && project_Code_EQIMap.containskey(orderRecord.Payment_Term__r.Name)) project_code = project_Code_EQIMap.get(orderRecord.Payment_Term__r.Name);
        //if(orderRecord.Site_Phone_No__c != null) Generator_Phone = orderRecord.Site_Phone_No__c.replaceAll('\\D', '');
        String sitePhone = orderRecord.Site_Phone_No__c;
        if (sitePhone != null) {
            sitePhone = sitePhone.replaceAll('\\D', '');
            if (sitePhone.length() > 10) {
                sitePhone = sitePhone.substring(0, 10);
            }
            Generator_Phone = sitePhone;
        } else {
            Generator_Phone = '';
        } 
        //if(orderRecord.Postal_Code__c != null) Gen_Mail_Zip_Code = orderRecord.Site_Postal_Code__c;
        if(orderRecord.Prevailing_Wage_Job__c != null) prevailing_wage_job = String.valueOf(orderRecord.Prevailing_Wage_Job__c);
        if(orderRecord.Project_Coordinator__c != null)project_manager = orderRecord.Project_Coordinator__r.Name;
        if(orderRecord.Site_Scope__c != null) 
        {
            if(orderRecord.Site_Scope__c.length() > 250)
            	project_scope = orderRecord.Site_Scope__c.subString(0,250);
            else
                project_scope = orderRecord.Site_Scope__c;
        }
            
        if(orderRecord.Service_Center__c != null && orderRecord.Service_Center__r.Name != null && company_Id_EQIMap !=null && company_Id_EQIMap.containskey(orderRecord.Service_Center__r.Name)) company_id = Integer.valueOf(company_Id_EQIMap.get(orderRecord.Service_Center__r.Name));
        if(orderRecord.Service_Center__c != null && orderRecord.Service_Center__r.Name != null && profit_Ctr_Id_EQIMap !=null && profit_Ctr_Id_EQIMap.containskey(orderRecord.Service_Center__r.Name)) profit_ctr_id = Integer.valueOf(profit_Ctr_Id_EQIMap.get(orderRecord.Service_Center__r.Name));
        if(orderRecord.Site_City__c != null) generator_city = orderRecord.Site_City__c.toUpperCase();
        if(orderRecord.Site_Country__c != null) {
             if(orderRecord.Site_Country__c == 'US'){
            	Generator_Country = 'USA';
             }
             else
                 Generator_Country = orderRecord.Site_Country__c.toUpperCase();//84645:Converted site address details in to uppercase
        }
         if(orderRecord.Site_Postal_Code__c != null){
             Generator_Zip_Code = orderRecord.Site_Postal_Code__c.toUpperCase();//84645:Converted site address details in to uppercase
             Gen_Mail_Zip_Code = orderRecord.Site_Postal_Code__c.toUpperCase();//84645:Converted site address details in to uppercase
         }
        if(orderRecord.Site_State__c != null) generator_state = orderRecord.Site_State__c.toUpperCase();//84644 converted to upper case
         if(orderRecord.Site_Street__c != null){ 
             Generator_Address_1 = orderRecord.Site_Street__c.toUpperCase();//84645:Converted site address details in to uppercase
             Gen_Mail_Address_1 = orderRecord.Site_Street__c.toUpperCase();//84645:Converted site address details in to uppercase
         }
        if(orderRecord.State__c != null) Gen_Mail_State = orderRecord.Site_State__c.toUpperCase();//84645:Converted site address details in to uppercase
        if(orderRecord.Subsidiary_Company__c != null) subsidiary_company = orderRecord.Subsidiary_Company__r.Name;
        if(orderRecord.Tax_Area__c != null) tax_area = orderRecord.Tax_Area__r.Name;
        if(orderRecord.Tax_Liable__c != null) tax_liable = String.valueOf(orderRecord.Tax_Liable__c);
        Total_Cost = orderRecord.Total_Cost__c > 0 ? orderRecord.Total_Cost__c : 0 ;
        //84645:Converted site address details in to uppercase
        String siteName = orderRecord.Site_Name__c.toUpperCase();
        if (siteName != null) {
            if (siteName.length() > 40) {
                siteName = siteName.substring(0, 40);
            }
            generator_name = siteName;
        } else {
            generator_name = '';
        }
        //80420
        confirm_author = orderRecord.CreatedBy.Name;
        if(orderRecord.EqaiGeneratorId__c!= null){
            generator_id = Integer.ValueOf(orderRecord.EqaiGeneratorId__c);       
         }
         else if(orderRecord.Alternate_Site_Address__c != null) 
         {
             salesforce_site_csid = orderRecord.Alternate_Site_Address__c;
         }
         EPA_ID = orderRecord.EPA_ID__c != null ? orderRecord.EPA_ID__c : 'N/A';
        curr_status_code ='A';
         status = 'A'; //Setting default value for generatory
        //Hardcoded value for integration testing purpose
        //company_id= Integer.valueOf('21');
         //d365customer_id= 'C022410';
        
     
       
    }
   
}