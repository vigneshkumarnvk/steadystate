/*************************************************************************************************
* Name         :  LookupProfileController
* Description  :  
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Shahwaz Khan             15-08-2024             US117942:  Add a Waste profile approval lookup in Salesforce T&M
* Shahwaz Khan             26-09-2024             US124980:  Add Placeholder Text/Guidance for Profile Approval Lookup
* Shahwaz Khan             10/30/2024             US129137: Disposal UOM on SF disposal line(s) must align to selected profile approval 
*************************************************************************************************/
public class LookupProfileController {
    @AuraEnabled
    public static ApprovalRecords fetchRecords(String ObjectName, String keyword, String tmId, String facilityId,string genId, String scId) {
        ApprovalRecords response = new ApprovalRecords();
        List<ApprovalRecord> approvals = new List<ApprovalRecord>();
        try {
            HTTPResponse res = ProfileApprovalService.approvalJsonfromEQAI(tmId, keyword, facilityId,genId,scId);
            if (res != null && res.getStatusCode() == 200) {
                approvals = parseResponse(res.getBody());
            } else {
                System.debug('Failed to fetch records::' + res);
            }
        } catch (Exception ex) {
            System.debug('error::' + ex.getMessage());
            System.debug('line::' + ex.getLineNumber());
        }
        //US124980
        if (approvals.size() == 0 && String.isNotBlank(keyword)) {
            response.Message = 'No Matching Records with this Description';
        } else if (approvals.size() == 0 && String.isBlank(keyword)) {
            response.Message = 'No matching records found.';
        }
        
        response.statusCode = '200';
        response.approvals = approvals;
        return response;
    }
    
    public static List<ApprovalRecord> parseResponse(String jsonResponse) {
        List<ApprovalRecord> approvalRecords = new List<ApprovalRecord>();
        try {
            List<Object> jsonList = (List<Object>) JSON.deserializeUntyped(jsonResponse);
            for (Object jsonObj : jsonList) {
                Map<String, Object> recordMap = (Map<String, Object>) jsonObj;
                String approval = String.valueOf(recordMap.get('Approval'));
                String profileId = String.valueOf(recordMap.get('Profile ID'));
                String wasteCode = String.valueOf(recordMap.get('Waste Code'));
                String description = String.valueOf(recordMap.get('Description'));
                String expirationDate = String.valueOf(recordMap.get('Expiration Date'));
                String facility = String.valueOf(recordMap.get('Facility'));
                //US129137
                String uom = String.valueOf(recordMap.get('UOM'));
                String originalCustomerPrice = String.valueOf(recordMap.get('Original Customer Price'));

                approvalRecords.add(new ApprovalRecord(approval, profileId, wasteCode, description, expirationDate, facility, uom, originalCustomerPrice));
            }
        } catch (Exception e) {
            System.debug('Error parsing JSON response: ' + e.getMessage());
        }
        return approvalRecords;
    }

    // Wrapper class for the response
    public class ApprovalRecords {
        @AuraEnabled public String Message;
        @AuraEnabled public String statusCode;
        @AuraEnabled public List<ApprovalRecord> approvals;
    }
    
    // Separate class for each approval record
    public class ApprovalRecord {
        @AuraEnabled public String Approval;
        @AuraEnabled public String ProfileID;
        @AuraEnabled public String WasteCode;
        @AuraEnabled public String Description;
        @AuraEnabled public String ExpirationDate;
        @AuraEnabled public String Facility;
        //US129137
        @AuraEnabled public String UOM;
        @AuraEnabled public String OriginalCustomerPrice;

        public ApprovalRecord(String Approval, String ProfileID, String WasteCode, String Description, String ExpirationDate, String Facility, String UOM, String OriginalCustomerPrice) {
            this.Approval = Approval;
            this.ProfileID = ProfileID;
            this.WasteCode = WasteCode;
            this.Description = Description;
            this.ExpirationDate = ExpirationDate;
            this.Facility = Facility;
            this.UOM = UOM;
            this.OriginalCustomerPrice = OriginalCustomerPrice;
        }
    }
}