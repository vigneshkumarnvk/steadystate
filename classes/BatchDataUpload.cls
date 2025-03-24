/******************************************************************************************************************
* Name         :  BatchDataUpload 
* Description  :  Used to import records.
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Vignesh Kumar N         01-15-2024             Initial Version
***********************************************************************************************************************/
public with sharing class BatchDataUpload implements Database.Batchable<String>, Database.Stateful {
    
    public Map<String, String> csvColumnFieldMap;
    public Map<String, Schema.DisplayType> sObjectFieldDataTypeMap;
    public String recordId, objectName, csvFile, csvFileName, csvFileContent, csvResultHeader='';
    public Integer successCount, failureCount, totalRecordsCount;
    public List<String> csvColumnNamesList = new List<String>();
    public List<String> csvResult =  new List<String>();
    public Boolean isFirstBatch = true, isPartial = false;
    
    public BatchDataUpload(Id recordId, String objectName, String csvFileContent, String csvFileName) {
        this.recordId = recordId;
        this.objectName = objectName;
        this.successCount = 0;
        this.failureCount = 0;
        this.totalRecordsCount = 0;
        this.csvFileName = csvFileName;
        this.csvFileContent = csvFileContent;
        this.csvColumnFieldMap = DataUploadHandler.getCSVFieldMapping(objectName);   //Query Custom Metadata     
        this.sObjectFieldDataTypeMap = DataUploadHandler.getFieldDataType(objectName); //Get Field DataType        
    }
    
    public Iterable<String> start(Database.BatchableContext bc) {
        List<String> csvRecordsList = csvFileContent.split('\n');
        totalRecordsCount = csvRecordsList.size() - 1;	//Count except header
        return csvRecordsList;
    }    
    
    public void execute(Database.BatchableContext bc, List<String> records) {        
        try {
            
            String csvRecords = String.join(records, '\n'); 
            List<List<String>> csvRecordList =  CSVFileReader.Parse(csvRecords);
            
            if (isFirstBatch) { //Store CSV Column Names only for first batch
                csvColumnNamesList = csvRecordList.remove(0);
                List<String> tempList = csvColumnNamesList;
                String tempString = String.join(tempList, ',');
                tempString += ',Result';
                csvResult.add(tempString);
                records.remove(0);
                isFirstBatch = false;
            }
            
            List<sObject> sObjectList = DataUploadHandler.mapContractLineCsvRecords(csvColumnFieldMap, sObjectFieldDataTypeMap,
                                                                                    csvRecordList, objectName, recordId,
                                                                                    csvColumnNamesList, records);
            List<Database.SaveResult> srList = Database.insert(sObjectList, false);
            
            // Iterate through each returned result
            for (Integer i = 0; i < srList.size(); i++)  {
                if (srList.get(i).isSuccess()) {
                    successCount += 1;
                }
                else {
                    // Operation failed, create the result for csv                
                    Database.Error err = srList.get(i).getErrors().get(0);
                    //System.debug('The following error has occurred.'+err);                    
                    //System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    //System.debug('Account fields that affected this error: ' + err.getFields());  
                    failureCount += 1;      
                    String record = String.valueOf(DataUploadHandler.csvRecMap.get(i)).replaceAll('[\\n\\r]+', ' ').trim() + ',';
                    String res = err.getStatusCode()+' :'+err.getMessage();
                    if (res.contains(',')) {
                        res = record + (err.getStatusCode()+' :'+err.getMessage()).replaceAll(',', ';');
                    } else {
                        res = record + err.getStatusCode()+' :'+err.getMessage();
                    }
                    csvResult.add(res);                
                }           
            }
            
            if (failureCount > 0) {
                csvFile = String.join( csvResult, '\n');
            }
        } catch (Exception e) {
            String request = 'ClassName: BatchDataUpload, MethodName: execute, Contract Id: '+recordId+', JobId: '+bc.getJobId();
            String response = 'Cause: '+e.getCause();
            DataUploadHandler.insertErrorLog(request, response, e.getMessage(), objectName, '', 
                                             e.getStackTraceString(), e.getLineNumber(), e.getTypeName());
        }
    } 
    
    public void finish(Database.BatchableContext bc) {
        
        DataUploadHandler.handleFinish(bc, csvFile, csvFileName, successCount, failureCount, totalRecordsCount, recordId); 
    }
}