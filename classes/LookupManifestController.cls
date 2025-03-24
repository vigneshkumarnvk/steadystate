/*************************************************************************************************
* Name         :  LookupManifestController
* Description  :  Fetches manifest records from external service
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Shahwaz Khan             12-09-2024             US117942:  Salesforce - Manifest lookup on T&M
*************************************************************************************************/
public class LookupManifestController {
    @AuraEnabled
    public static List<ManifestRecord> fetchRecords(String tsdfApprovalCode, String tmId) {
        List<ManifestRecord> records = new List<ManifestRecord>();
        try {
            HTTPResponse res = ManifestService.sendRequestToEQAI(tsdfApprovalCode, tmId);
            if (res != null && res.getStatusCode() == 200) {
                List<ManifestRecord> manifestRecords = parseResponse(res.getBody());
                if (manifestRecords != null) {
                    records.addAll(manifestRecords);
                }
            } else {
                System.debug('Failed to fetch records::'+res);
            }
        }
        catch(Exception ex) {
            System.debug('error::'+ex.getMessage());
            System.debug('line::'+ex.getLineNumber());
        }
        return records;
    }

    public static List<ManifestRecord> parseResponse(String jsonResponse) {
        List<ManifestRecord> manifestRecords = new List<ManifestRecord>();
        try {
            List<Object> jsonList = (List<Object>) JSON.deserializeUntyped(jsonResponse);
            for (Object jsonObj : jsonList) {
                Map<String, Object> recordMap = (Map<String, Object>) jsonObj;
                String manifest = String.valueOf(recordMap.get('manifest'));
                String generatorId = String.valueOf(recordMap.get('generator_id'));
                manifestRecords.add(new ManifestRecord(manifest, generatorId));
            }
        } catch (Exception e) {
            System.debug('Error parsing JSON response: ' + e.getMessage());
        }
        return manifestRecords;
    }

    public class ManifestRecord {
        @AuraEnabled public String Manifest;
        @AuraEnabled public String GeneratorId;

        public ManifestRecord(String Manifest, String GeneratorId) {
            this.Manifest = Manifest;
            this.GeneratorId = GeneratorId;
        }
    }
}