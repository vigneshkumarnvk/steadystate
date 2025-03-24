/*************************************************************************************************
* Name         :  ResourceJSON
* Description  :  Apex Class for generating JSON Payload for Resource
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan      04-30-2024             84924:Salesforce - Updates to Equipment Resource Automation 
* Prabhu Rathakrishnan      05-14-2024              86829Salesforce - Newly created resource is not integrated into the EQAI if the user does not enter/Select the  Resource class code (Required fields) in SF.
*************************************************************************************************/

public class ResourceJSON {
    integer companyId;
    integer defaultProfitCtrId;
    String ResourceType;
    String SalesforceResourceCSID;
    String ResourceClassCode;
    String BillUnitCode;
    String EmployeeId;
    String Description;
    String ResourceCode;
    

    public ResourceJSON(Resource__c resource, String empId,Map<String,String> bill_Unit_Code_EQIMap, Map<String, String> company_Id_EQIMap, Map<String, String> profit_Ctr_Id_EQIMap){
        if(resource.Service_Center__c != null && resource.Service_Center__r.Name != null && company_Id_EQIMap !=null && company_Id_EQIMap.containskey(resource.Service_Center__r.Name)) companyId = Integer.valueOf(company_Id_EQIMap.get(resource.Service_Center__r.Name));
        if(resource.Service_Center__c != null && resource.Service_Center__r.Name != null && profit_Ctr_Id_EQIMap !=null && profit_Ctr_Id_EQIMap.containskey(resource.Service_Center__r.Name)) defaultProfitCtrId = Integer.valueOf(profit_Ctr_Id_EQIMap.get(resource.Service_Center__r.Name));
        ResourceType = 'E';
        ResourceClassCode = resource.Resource_Class_Code__c;
        SalesforceResourceCSID = resource.Id;
        EmployeeId = empId;
        if(resource.Unit_of_Measure__c != null && bill_Unit_Code_EQIMap !=null && bill_Unit_Code_EQIMap.containsKey(resource.Unit_of_Measure__r.Name)) BillunitCode = bill_Unit_Code_EQIMap.get(resource.Unit_of_Measure__r.Name);
        Description = resource.Description__c;
        ResourceCode = resource.Name;
    }
}