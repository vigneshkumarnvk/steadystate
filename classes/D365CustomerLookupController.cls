/*************************************************************************************************
* Name         :  D365CustomerLookupController
* Description  :  D365 Project Lookup Functionality wrapper and JSON Parse class 
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Shahwaz Khan             02-14-2025            US141063:  Add D365 Project Lookup Functionality
Shahwaz Khan             03-06-2025            US142841:  Update D365 Project Lookup(Update Wrapper class as per updated Response)
*************************************************************************************************/
public class D365CustomerLookupController {
    public class D365CustomerRecords {
        @AuraEnabled public String Message;
        @AuraEnabled public String statusCode;
        @AuraEnabled public List<D365CustomerRecord> projectIds;
    }    
    
    public class D365CustomerRecord {
        @AuraEnabled public String projectId;  
        @AuraEnabled public String projectName;
        @AuraEnabled public String prevailingWage;
        @AuraEnabled public String department;
        @AuraEnabled public String businessUnit;
        @AuraEnabled public String deptCostCenter;
        
        public D365CustomerRecord(String d365Project, String projectName, String prevailingWage, String department, String businessUnit, String deptCostCenter) {
            this.projectId = d365Project;
            this.projectName = projectName;
            this.prevailingWage = prevailingWage;
            this.department = department; 
            this.businessUnit = businessUnit;
            this.deptCostCenter = deptCostCenter;
        }
    }
    
    @AuraEnabled
    public static D365CustomerRecords fetchRecords(String d365CustomerId, String serviceCenterId, String keyword) {
        D365CustomerRecords response = new D365CustomerRecords();
        response.projectIds = new List<D365CustomerRecord>();
        response.statusCode = '200';
        
        System.debug('Service Center====>' + serviceCenterId);
        
        // Fetch service center records
        List<Service_Center__c> serviceCenterRecords = [SELECT Id, Name, D365_Business_Unit__c, D365_LE__c 
                                                        FROM Service_Center__c 
                                                        WHERE Id = :serviceCenterId];
        
        // If no service center is found, return empty response
        if (serviceCenterRecords.isEmpty()) {
            response.Message = 'No matching records found.';
            return response;
        }
        
        // Fetch the first record (since we ensured it's not empty)
        Service_Center__c serviceCenterRecord = serviceCenterRecords[0];
        
        // Call external service
        HttpResponse res = D365CustomerService.fetchCustomerIds(d365CustomerId, serviceCenterRecord, keyword);
        if (res != null && res.getStatusCode() == 200) {
            try {
                Object rawResponse = JSON.deserializeUntyped(res.getBody());
                if (rawResponse instanceOf List<Object>) {
                    List<Object> responseList = (List<Object>) rawResponse;
                    
                    for (Object obj : responseList) {
                        if (obj instanceOf Map<String, Object>) {
                            Map<String, Object> responseMap = (Map<String, Object>) obj;
                            String projectId = (String) responseMap.get('PROJECTID');
                            
                            // If keyword is empty or matches projectId, add record
                            if (String.isEmpty(keyword) || (projectId != null && projectId.containsIgnoreCase(keyword))) {
                                response.projectIds.add(new D365CustomerRecord(
                                    projectId,
                                    (String) responseMap.get('PROJECTNAME'),
                                    (String) responseMap.get('USEPREVAILINGWAGE'),
                                    (String) responseMap.get('BUSINESSUNIT'),
                                    (String) responseMap.get('DEPARTMENT'),
                                    (String) responseMap.get('COSTCENTER')
                                ));
                            }
                        }
                    }
                }
            } catch (Exception e) {
                System.debug('Error parsing API response: ' + e.getMessage());
            }
        }
        
        if (response.projectIds.isEmpty()) {
            response.Message = 'No matching records found.';
        }
        
        return response;
    }
}