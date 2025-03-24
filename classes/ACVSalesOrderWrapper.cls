//job task <<
//public with sharing class ACVSalesOrderWrapper {
global with sharing class ACVSalesOrderWrapper {
//job task >>

    //fix.null.fields <<
    /*
    @AuraEnabled
    public Sales_Order__c SalesOrder { set; get; }
    @AuraEnabled
    public List<Sales_Line__c> SalesLines { set; get; }
    */

    //job task <<
    /*
    @AuraEnabled
    public String JSONSalesOrder { set; get; }
    @AuraEnabled
    public String JSONSalesLines { set; get; }
    */
    //job task >>
    //fix.null.fields >>

    //job task <<
    /*
    //public ACVSalesOrderWrapper(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines) {
        //fix.null.fields <<
        //this.SalesOrder = salesOrder;
        //this.SalesLines = salesLines;

        this.JSONSalesOrder = JSON.serialize(salesOrder);
        if (salesLines == null) {
            salesLines = new List<Sales_Line__c>();
        }
        this.JSONSalesLines = JSON.serialize(salesLines);
        //fix.null.fields >>
    }
    */

    @AuraEnabled
    public Sales_Order__c SalesOrder;
    @AuraEnabled
    public List<Contact> SObillToContacts{get;set;}
    @AuraEnabled
    public List<Id> accountExecutivesIds{get;set;}

    @AuraEnabled
    public List<ACVSalesOrderJobTaskWrapper> JobTaskWrappers { get; set; }

    public ACVSalesOrderWrapper(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers) {
        this.SalesOrder = salesOrder;
        this.JobTaskWrappers = jobTaskWrappers;
    }

    /*
    public ACVSalesOrderWrapper(Sales_Order__c salesOrder, List<ACVSalesOrderWrapper> jOrderWrappers, List<Sales_Line__c> salesLines) {
    }
    */

    public ACVSalesOrderWrapper(Sales_Order__c salesOrder, List<Sales_Order_Job_Task__c> jobTasks, List<Sales_Line__c> salesLines) {
        this.SalesOrder = salesOrder;
        this.JobTaskWrappers = new List<ACVSalesOrderJobTaskWrapper>();
        Map<Integer, ACVSalesOrderJobTaskWrapper> mapSalesOrderJobTaskWrappersByJobTask = new Map<Integer, ACVSalesOrderJobTaskWrapper>();

        for (Sales_Order_Job_Task__c jobTask : jobTasks) {
            Integer jobTaskLineNo = jobTask.Line_No__c.intValue();
            ACVSalesOrderJobTaskWrapper jobTaskWrapper = new ACVSalesOrderJobTaskWrapper();
            jobTaskWrapper.JobTask = jobTask;
            jobTaskWrapper.SalesLines = new List<Sales_Line__c>();
            mapSalesOrderJobTaskWrappersByJobTask.put(jobTaskLineNo, jobTaskWrapper);
        }

        for (Sales_Line__c salesLine : salesLines) {
            Integer jobTaskLineNo = 0;
            if (salesLine.Sales_Order_Job_Task__r != null && salesLine.Sales_Order_Job_Task__r.Line_No__c != null) {
                jobTaskLineNo = salesLine.Sales_Order_Job_Task__r.Line_No__c.intValue();
            }

            ACVSalesOrderJobTaskWrapper jobTaskWrapper;
            if (mapSalesOrderJobTaskWrappersByJobTask.containsKey(jobTaskLineNo)) {
                jobTaskWrapper = mapSalesOrderJobTaskWrappersByJobTask.get(jobTaskLineNo);
            }
            else {
                //handle sales lines without a job task -- old quotes and orders
                jobTaskWrapper = new ACVSalesOrderJobTaskWrapper();
                jobTaskWrapper.JobTask = new Sales_Order_Job_Task__c(Line_No__c = jobTaskLineNo, Name = 'Unassigned Sales Lines');
                jobTaskWrapper.SalesLines = new List<Sales_Line__c>();
                mapSalesOrderJobTaskWrappersByJobTask.put(jobTaskWrapper.JobTask.Line_No__c.intValue(), jobTaskWrapper);
            }

            salesLine.Sales_Order_Job_Task__c = jobTaskWrapper.JobTask.Id;
            salesLine.Sales_Order_Job_Task__r = jobTaskWrapper.JobTask;
            jobTaskWrapper.SalesLines.add(salesLine);
        }

        this.JobTaskWrappers = mapSalesOrderJobTaskWrappersByJobTask.values();
    }

    public List<Sales_Order_Job_Task__c> getJobTasks() {
        List<Sales_Order_Job_Task__c> salesOrderJobTasks = new List<Sales_Order_Job_Task__c>();
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : this.JobTaskWrappers) {
            salesOrderJobTasks.add(jobTaskWrapper.JobTask);
        }
        return salesOrderJobTasks;
    }

    //ticket 20876 <<
    //public List<Sales_Line__c> SalesLines {
    public transient List<Sales_Line__c> SalesLines {
    //ticket 20876 >>
        get {
            List<Sales_Line__c> salesLines = new List<Sales_Line__c>();
            for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : this.JobTaskWrappers) {
                for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                    salesLines.add(salesLine);
                }
            }
            return salesLines;
        }
        set {
            if (this.JobTaskWrappers != null) {
                for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : this.JobTaskWrappers) {
                    jobTaskWrapper.SalesLines = new List<Sales_Line__c>();
                    for (Sales_Line__c salesLine : value) {
                        if (salesLine.Sales_Order_Job_Task__r.Line_No__c == jobTaskWrapper.JobTask.Line_No__c) {
                            jobTaskWrapper.SalesLines.add(salesLine);
                        }
                    }
                }
            }
        }
    }
    //job task >>
}