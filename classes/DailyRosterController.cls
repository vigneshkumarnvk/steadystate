public class DailyRosterController {
    /*
    @AuraEnabled

    public static String getWOData(string scheduledDate) {
        system.debug('scheduledDate ***' + scheduledDate);
        String strMsg = 'OK';
        List<TM__c> theWOList = new List<TM__c>();
        try {
            if (string.isNotEmpty(scheduledDate)) {
                system.debug('1***');
                theWOList = [
                        SELECT Id, Name, Status__c, Site_City__c, Site_State__c, Project_Coordinator__r.Name, Site_Name__c, Site_Email_Address__c, Scheduled_Date__c
                        FROM TM__c
                        WHERE Scheduled_Date__c = :date.valueOf(scheduledDate)
                ];
            } else {
                system.debug('2***');
                theWOList = [SELECT Id, Name, Status__c, Site_City__c, Site_State__c, Project_Coordinator__r.Name, Site_Name__c, Site_Email_Address__c, Scheduled_Date__c FROM TM__c];
            }
        } catch (dmlexception e) {
            strMsg = e.getMessage();
        }

        if (strMsg == 'OK') {
            return JSON.serialize(new ResponseWrapper(strMsg, JSON.serialize(theWOList)));
        } else {
            return JSON.serialize(new ResponseWrapper(strMsg, ''));
        }
    }

    public class ResponseWrapper {
        @AuraEnabled
        public String respMsg { get; set; }
        @AuraEnabled
        public String respJson { get; set; }

        public ResponseWrapper(string respMsg, string respJson) {
            this.respMsg = respMsg;
            this.respJson = respJson;
        }
    }
    */
}