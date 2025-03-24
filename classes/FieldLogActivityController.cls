global with sharing class FieldLogActivityController {
    public final ApexPages.StandardController theController;
    public List<Field_Activity_Log__c> fieldActivityLogs {get; set;}
    public String tmId {get; set;}
    public String tmLineId {get; set;}
    public TM_Line__c laborLine {get; set;}
    public Boolean viewMode {get; set;}

    public static Company_Setting__mdt defaultCompanySetting {
        get {
            defaultCompanySetting = CompanySettingUtil.acvSetting;
            return defaultCompanySetting;
        }
        set;
    }

    public FieldLogActivityController(ApexPages.StandardController controller){
        viewMode = false;
        tmLineId = ApexPages.currentPage().getParameters().get('tmlId');
        tmId = ApexPages.currentPage().getParameters().get('tmId');
        fieldActivityLogs = [
                SELECT
                        End_Time__c,
                        Equipment__c,
                        Equipment__r.Name,
                        Id,
                        Resource_Type__c,
                        Resource_Type__r.Name,
                        Start_Time__c,
                        T_M_Line__c,
                        Line_No__c
                FROM Field_Activity_Log__c WHERE T_M_Line__c = :tmLineId ORDER BY Start_Time__c ASC ];

        laborLine = new TM_Line__c();
        List<TM_Line__c> tmLines = [SELECT Id, TM__c, TM__r.Status__c, Resource__c, Resource__r.Name FROM TM_Line__c WHERE Id = :tmLineId];

        if(tmLines.size() > 0){
            laborLine = tmLines[0];
            if(laborLine.TM__r.Status__c != TMsService.OPEN_STATUS &&
                    laborLine.TM__r.Status__c != TMsService.MOBILE_REVIEW_STATUS &&
                    laborLine.TM__r.Status__c != TMsService.SCHEDULED_STATUS){
                viewMode = true;
            }
        }
    }

    public PageReference addLine(){
        Decimal nextLineNo = 0;
        for(Field_Activity_Log__c fieldActivityLog : fieldActivityLogs){
            if(nextLineNo < fieldActivityLog.Line_No__c){
                nextLineNo = fieldActivityLog.Line_No__c;
            }
        }
        nextLineNo += 1;

        fieldActivityLogs.add(
                new Field_Activity_Log__c(
                        T_M_Line__c = tmLineId,
                        Equipment__c = null,
                        Resource_Type__c = defaultCompanySetting.Default_Resource_Type_for_FA__c,
                        Line_No__c = nextLineNo
                )
        );

        System.debug('Info: add Line');
        System.debug('Info: tmLineId ' + tmLineId);
        System.debug('Info: fieldActivityLogs ' + fieldActivityLogs.size());
        return null;
    }

    public PageReference returnToTM(){
        if(String.isNotBlank(tmId)){
            PageReference tmPage = new PageReference('/apex/TM?id=' + tmId);
            tmPage.setRedirect(true);
            return tmPage;
        }
        return null;
    }

    public PageReference deleteLine(){
        String displayId = ApexPages.currentPage().getParameters().get('displayId');
        if (displayId == '') {
            displayId = '0';
        }

        for (Integer i = 0; i < fieldActivityLogs.size(); i++) {

            if (fieldActivityLogs[i].Line_No__c == Decimal.valueOf(displayId)) {
                fieldActivityLogs.remove(i);
                break;
            }
        }

        return null;
    }

    public PageReference save() {
        if(fieldActivityLogs == null) {
            return null;
        }

        List<Field_Activity_Log__c> fieldActivityLogsBackUp = fieldActivityLogs.deepClone(true, true, true);
        Savepoint savepoint = Database.setSavepoint();
        try{
            List<Field_Activity_Log__c> deletedRecords = new List<Field_Activity_Log__c>();
            for(Field_Activity_Log__c fieldActivityLog : [SELECT Id FROM Field_Activity_Log__c WHERE T_M_Line__c = :tmLineId]){
                Boolean lineFound = false;
                for(Field_Activity_Log__c fieldActivityLog2 : fieldActivityLogs){
                    if(fieldActivityLog.Id == fieldActivityLog2.Id){
                        lineFound = true;
                    }
                }

                if(lineFound == false){
                    deletedRecords.add(fieldActivityLog);
                }
            }
            if(deletedRecords.size() > 0){
                delete deletedRecords;
            }

            for(Field_Activity_Log__c fieldActivityLog:fieldActivityLogs){
                if(String.isBlank(fieldActivityLog.Equipment__c)){
                    throw new DataException('Equipment field must not be blank!');
                }
                if(fieldActivityLog.Start_Time__c == null || fieldActivityLog.End_Time__c == null){
                    throw new DataException('Times field must not be blank!');
                }
            }

            upsert fieldActivityLogs;
            return null;
        } catch (Exception e){
            System.debug('Error: ' + e.getStackTraceString());
            Database.rollback(savepoint);
            fieldActivityLogs = fieldActivityLogsBackUp;
            return null;
        }
    }

    public PageReference validateField() {
        String fieldName = ApexPages.currentPage().getParameters().get('fieldName');
        Integer i = Integer.valueOf(ApexPages.currentPage().getParameters().get('indexNo'));
        String newFieldValue = ApexPages.currentPage().getParameters().get('newFieldValue');
        if(fieldName == 'theEquipment'){
            if(String.isBlank(newFieldValue)){
                fieldActivityLogs[i].Equipment__c = null;
            } else {
                fieldActivityLogs[i].Equipment__c = newFieldValue;
                List<Resource__c> equipmentRes = [SELECT Id, Name FROM Resource__c WHERE Id = :newFieldValue];
                fieldActivityLogs[i].Equipment__r = equipmentRes[0];
            }
        } else if(fieldName == 'startTime' || fieldName == 'endTime'){
            List<String> theTime = new List<String>();
            Integer hrs;
            Integer min;
            try {
                if (String.isEmpty(newFieldValue)) {
                    hrs = 0;
                    min = 0;
                } else {
                    if (newFieldValue.contains(':')) {
                        theTime = newFieldValue.split(':');
                        hrs = Integer.valueOf(theTime[0]);
                        min = Integer.valueOf(theTime[1]);
                    } else {
                        hrs = Integer.valueOf(newFieldValue);
                        min = 0;
                    }
                }

                Time enteredTime = Time.newInstance(hrs, min, 0, 0);
                if(fieldName == 'startTime'){
                    fieldActivityLogs[i].Start_Time__c = enteredTime;
                }

                if(fieldName == 'endTime'){
                    fieldActivityLogs[i].End_Time__c = enteredTime;
                }

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
        } else if (fieldName == 'resourceType'){
            if(String.isBlank(newFieldValue)){
                fieldActivityLogs[i].Resource_Type__c = null;
            } else {
                List<Resource_Type__c> resourceTypes = [SELECT Id, Name FROM Resource_Type__c WHERE Id = :newFieldValue];
                fieldActivityLogs[i].Resource_Type__c = resourceTypes[0].Id;
                fieldActivityLogs[i].Resource_Type__r = resourceTypes[0];
            }
        }
        return null;
    }
}