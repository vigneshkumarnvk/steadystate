public with sharing class BillingWorksheetSetupData {
    @AuraEnabled
    public Company_Setup__c CompanySetup { set; get; }
    //@AuraEnabled
    //public Map<Integer, Map<Id, TM_Job_Task__c>> TMTasksByTMIdByOrderTaskLineNo { set; get; }
    @AuraEnabled
    public Map<Id, Map<Integer, TM_Job_Task__c>> TMTasksByOrderTaskLineNoByTMId { set; get; }

    @AuraEnabled
    public Service_Center__c TempServiceCenter { set; get; }

    public BillingWorksheetSetupData(Id salesOrderId) {
        this.CompanySetup = CompanyMgmt.getCompanySetup();
        /*
        this.TMTasksByTMIdByOrderTaskLineNo = new Map<Integer, Map<Id, TM_Job_Task__c>>();
        List<TM_Job_Task__c> jobTasks = [SELECT Id, Name, Line_No__c, Task_No__c, TM__c, Sales_Order_Job_Task__c, Sales_Order_Job_Task__r.Line_No__c FROM TM_Job_Task__c WHERE Sales_Order_Job_Task__r.Sales_Order__c = :salesOrderId AND TM__r.Status__c = 'Confirmed'];
        for (TM_Job_Task__c jobTask : jobTasks) {
            Map<Id, TM_Job_Task__c> mapTMTasksByTMId;
            Integer salesOrderJobTaskLineNo = jobTask.Sales_Order_Job_Task__r.Line_No__c.intValue();
            if (this.TMTasksByTMIdByOrderTaskLineNo.containsKey(salesOrderJobTaskLineNo)) {
                mapTMTasksByTMId = this.TMTasksByTMIdByOrderTaskLineNo.get(salesOrderJobTaskLineNo);
            }
            else {
                mapTMTasksByTMId = new Map<Id, TM_Job_Task__c>();
                this.TMTasksByTMIdByOrderTaskLineNo.put(salesOrderJobTaskLineNo, mapTMTasksByTMId);
            }
            mapTMTasksByTMId.put(jobTask.TM__c, jobTask);
        }*/


        this.TMTasksByOrderTaskLineNoByTMId = new Map<Id, Map<Integer, TM_Job_Task__c>>();
        List<TM_Job_Task__c> jobTasks = [SELECT Id, Name, Line_No__c, Task_No__c, TM__c, Sales_Order_Job_Task__c, Sales_Order_Job_Task__r.Line_No__c FROM TM_Job_Task__c WHERE Sales_Order_Job_Task__r.Sales_Order__c = :salesOrderId AND TM__r.Status__c = 'Confirmed'];
        for (TM_Job_Task__c jobTask : jobTasks) {
            Map<Integer, TM_Job_Task__c> mapTMTasksByOrderTaskLineNo;
            if (this.TMTasksByOrderTaskLineNoByTMId.containsKey(jobTask.TM__c)) {
                mapTMTasksByOrderTaskLineNo = this.TMTasksByOrderTaskLineNoByTMId.get(jobTask.TM__c);
            }
            else {
                mapTMTasksByOrderTaskLineNo = new Map<Integer, TM_Job_Task__c>();
                this.TMTasksByOrderTaskLineNoByTMId.put(jobTask.TM__c, mapTMTasksByOrderTaskLineNo);
            }
            mapTMTasksByOrderTaskLineNo.put(jobTask.Sales_Order_Job_Task__r.Line_No__c.intValue(), jobTask);
        }

        for (Service_Center__c sc : [SELECT Id, Name, Description__c, Subsidiary_Company__c, Subsidiary_Company__r.Name, Temporary__c FROM Service_Center__c WHERE Temporary__c = TRUE AND Blocked__c != TRUE]) {
            this.TempServiceCenter = sc;
            break;
        }
    }
}