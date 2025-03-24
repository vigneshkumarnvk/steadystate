/*************************************************************************************************************
* Name         :  HttpCalloutController 
* Description  :  Common class to Integration
*
*
* Modification Log :
* Developer                 Date                   Description
* ----------------------------------------------------------------------------                 
* Pavithra Periyasamy		11/06/2024             US129598: [Continued] SF -  Create single JSON object for billing package integration
* Pavithra Periyasamy		11/21/2024             US133594: [Unplanned] Salesforce - Use single JSON format to create Work Order at time of Sales Order creation in Salesforce
* Prabhu Rathakrishnan      12/03/2024             US132386: Salesforce - Move 'Disposal Billing Method' field to be on Sales Lines of Sales Quote/Order
* Andrew Simons             12/05/2024             US134521: Salesforce - updated to include Profile Id from tm line in sales invoice query
* Prabhu Rathakrishnan      12/05/2024             US132386: Salesforce - Move 'Disposal Billing Method' field to be on Sales Lines of Sales Quote/Order
*************************************************************************************************************/
public class BillingPackageJSON {
    public JSONWrapper JSON = new JSONWrapper();
    
    public class JSONWrapper{
        public SalesInvoiceWOHeaderJSON Header;
    	public List<SalesInvLineWODetailsJSON> details;
   
    }
         
    public BillingPackageJSON(Sales_Invoice__c salesInvoiceRec,map<String,String> project_Code_EQIMap, map<String,String>  company_Id_EQIMap, map<String,String> profit_Ctr_Id_EQIMap,String employeeId){
         
        JSON.Header = new SalesInvoiceWOHeaderJSON(salesInvoiceRec,project_Code_EQIMap,company_Id_EQIMap,profit_Ctr_Id_EQIMap,employeeId);        
        JSON.details = getworkOrderDetailInfo(salesInvoiceRec.Id,JSON.Header.CompanyId,JSON.Header.ProfitCenterId,employeeId);
       
        
    }
    
    //US133594
    public BillingPackageJSON(Sales_Order__c salesOrder,map<String,String> project_Code_EQIMap, map<String,String>  company_Id_EQIMap, map<String,String> profit_Ctr_Id_EQIMap,String employeeId){   
        JSON.Header = new SalesInvoiceWOHeaderJSON(salesOrder,project_Code_EQIMap,company_Id_EQIMap,profit_Ctr_Id_EQIMap,employeeId);  
    }
    
    public static List<SalesInvLineWODetailsJSON> getworkOrderDetailInfo(Id salesInvoiceId,Integer companyId, Integer profitCtrId, String employeeId){
                    
        Map<String,String> resource_Type_EQIMap = new map<String,String>();
        Map<String,String> bill_Unit_Code_EQIMap = new map<String,String>();
        Map<String,String> company_Id_EQIMap = new map<String,String>();
        Integer resourceCompanyId;
        Boolean wasteDisposal = SalesInvoiceWorkOrderService.containsWasteDisposalInvoiceLine(salesInvoiceId);
        for(Sales_Order_EQAI_Mapping__mdt salesOrderEQIMappingRecord :[select Id,EQAI_Field_Name__c,EQAI_Field_Value__c,EQAI_Table_Name__c,Salesforce_Field_API_Name__c,Salesforce_Field_Value__c from Sales_Order_EQAI_Mapping__mdt]){
                if(salesOrderEQIMappingRecord.EQAI_Field_Name__c =='company_id'){
                    company_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c,salesOrderEQIMappingRecord.EQAI_Field_Value__c);
                }
        }
        for(Sales_Line_EQAI_Mapping__mdt salesLineEQIMappingRecord : [select Id,EQAI_Field_Name__c,EQAI_Field_Value__c,Salesforce_Field_Value__c from Sales_Line_EQAI_Mapping__mdt  ]){
            if(salesLineEQIMappingRecord.EQAI_Field_Name__c =='resource_type'){
                resource_Type_EQIMap.put(salesLineEQIMappingRecord.Salesforce_Field_Value__c ,salesLineEQIMappingRecord.EQAI_Field_Value__c);
            }
            else if(salesLineEQIMappingRecord.EQAI_Field_Name__c =='bill_unit_code'){
                bill_Unit_Code_EQIMap.put(salesLineEQIMappingRecord.Salesforce_Field_Value__c ,salesLineEQIMappingRecord.EQAI_Field_Value__c);
            }
        }
        List<Sales_Invoice_Line__c> invoiceLineRec = [SELECT Id,Disposal_Billing_Method__c, BOL_Manifest__c,Resource_Class_Code__c,Bundle_Line__c,Category__c,CreatedById,Description__c,Facility__c,LastModifiedById,
                                                      CreatedBy.Name,LastModifiedBy.RSG_EIN__c,CreatedBy.RSG_EIN__c,Bundle_Line__r.Name,Bundle_Line__r.Id,
                                                      Facility__r.Name, Facility__r.TSDF_Code__c,LastModifiedBy.Name,Line_Amount__c,Line_Cost__c,Name,Pricing_Source_2__c,Qty_to_Display__c,
                                                      Quantity__c,Resource__r.Name,Resource__r.Service_Center__c,Resource__r.Service_Center__r.name,Resource_Type__r.Resource_Class_Code__c,Sales_Invoice_Job_Task__r.Name,Scheduled_Date__c,Unit_Price__c,
                                                      Unit_Cost__c,Unit_of_Measure__c,Unit_of_Measure__r.Name,Service_Center__r.Name,Print_Line__c,Sales_Invoice__r.CSID__c,
                                                      Contract_Line__c, Line_Amt_Incl_Tax__c,TM__c, Non_billable__c,Time_Rate_Code__c,Resource__r.CSID__c,
                                                      Resource__r.Resource_Class_Code__c,Resource__r.EQAI_Other__c, Resource__r.External_ID__c,Resource_Type__r.External_ID__c,Sales_Invoice__r.Invoice_Tax__c,TM_Line__r.EQAI_Bill_Unit_Code__c,TM_Line__r.BOL_Manifest_Workorder_Id__c,
                                                      Sales_Invoice__r.First_Service_Date__c,Sales_Invoice__r.Last_Service_Dates__c,Sales_Invoice__r.Sales_Order__r.Name,Resource_Type__r.EQAI_Supply__c,TM__r.Name,Sales_Invoice__r.Sales_Order__r.Disposal_Billing_Method__c,TM_Line__r.Approval_Id__c,TM_Line__r.Profile_Id__c,Sales_Invoice__r.Sales_Order__r.CSID__c
                                                      FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c = : salesInvoiceId Order by Bundle_Line__c NULLS FIRST];
        
        //creating the JSON body in a array format to send it to EQI System           
        List<SalesInvLineWODetailsJSON> invoiceLineDetailsList = new list<SalesInvLineWODetailsJSON>();
        ///InvoiceLineWODetailsJSON invoiceLineJson = new InvoiceLineWODetailsJSON(invoiceLineRec[0]);
        Sales_Invoice_Line__c salesInvLneRecord;
        
        for(Sales_Invoice_Line__c salesInvLineRecord : invoiceLineRec) 
        { 
            System.debug('salesInvLineRecord++++++++++++' + salesInvLineRecord.non_billable__c);
            
            if(salesInvLineRecord.Resource__r!= null && salesInvLineRecord.Resource__r.Service_Center__c!=null && salesInvLineRecord.Resource__r.Service_Center__r.name!=null){
                if(salesInvLineRecord.Resource__r.Service_Center__r.name.equals('99 - Temp')){
                    resourceCompanyId = companyId;
                }
                else{
                	resourceCompanyId = company_Id_EQIMap.get(salesInvLineRecord.Resource__r.Service_Center__r.name)!= null ?Integer.ValueOf(company_Id_EQIMap.get(salesInvLineRecord.Resource__r.Service_Center__r.name)) : null;
                }
            }
            else{
                resourceCompanyId = null;
            }
            
            if (wasteDisposal) {
            if (salesInvLineRecord.Description__c == 'Manifest Fee') {
                if (salesInvLineRecord.Disposal_Billing_Method__c != 'Direct') {
                    SalesInvLineWODetailsJSON invoiceLineJson = new SalesInvLineWODetailsJSON(
                        salesInvLineRecord, companyId, profitCtrId, resource_Type_EQIMap, bill_Unit_Code_EQIMap,employeeId,false, resourceCompanyId,wasteDisposal
                    );
                    invoiceLineDetailsList.add(invoiceLineJson);
                }
            } else {
                SalesInvLineWODetailsJSON invoiceLineJson = new SalesInvLineWODetailsJSON(
                    salesInvLineRecord, companyId, profitCtrId, resource_Type_EQIMap, bill_Unit_Code_EQIMap,employeeId,false, resourceCompanyId,wasteDisposal
                );
                invoiceLineDetailsList.add(invoiceLineJson);
            }
        }else{
                SalesInvLineWODetailsJSON invoiceLineJson = new SalesInvLineWODetailsJSON(salesInvLineRecord, companyId,  profitCtrId,resource_Type_EQIMap,bill_Unit_Code_EQIMap,employeeId,false,resourceCompanyId,wasteDisposal);
                invoiceLineDetailsList.add(invoiceLineJson);                 
            }
            salesInvLneRecord = salesInvLineRecord;
            
        }        
        if(invoiceLineRec[0].Sales_Invoice__r.Invoice_Tax__c > 0 || Test.isRunningTest())
            invoiceLineDetailsList.add(new SalesInvLineWODetailsJSON(salesInvLneRecord, companyId,  profitCtrId,resource_Type_EQIMap,bill_Unit_Code_EQIMap,employeeId, true,resourceCompanyId,wasteDisposal));  
        
        return invoiceLineDetailsList;        
    } 

}