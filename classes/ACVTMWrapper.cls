global with sharing class ACVTMWrapper {
    @AuraEnabled
    public TM__c TM { set; get; }

    @AuraEnabled
    //ticket 19130 04.28.23 <<
    /*
    public List<ACVTMJobTaskWrapper> JobTaskWrappers {
        get {
            return this.mapJobTaskWrappersByLineNo.values();
        }
    }
    */
    public List<ACVTMJobTaskWrapper> JobTaskWrappers { get; set; }
    //ticket 19130 04.28.23 >>

    @AuraEnabled
    public String FieldTMPDFUrl { set; get; }

    //ticket 19130 04.28.23 <<
    //private transient Map<Integer, ACVTMJobTaskWrapper> mapJobTaskWrappersByLineNo;
    //ticket 19130 04.28.23 >>

    public ACVTMWrapper(TM__c tm) {
        this.TM = tm;
        //ticket 19130 04.28.23 <<
        /*
        //this.JobTaskWrappers = new List<ACVTMJobTaskWrapper>();
        this.mapJobTaskWrappersByLineNo = new Map<Integer, ACVTMJobTaskWrapper>();
        */
        this.JobTaskWrappers = new List<ACVTMJobTaskWrapper>();
        //ticket 19130 04.28.23 >>
    }

    public ACVTMWrapper(TM__c tm, List<ACVTMJobTaskWrapper> jobTaskWrappers) {
        this.TM = tm;
        //ticket 19130 04.28.23 <<
        /*
        //this.JobTaskWrappers = new List<ACVTMJobTaskWrapper>();
        this.mapJobTaskWrappersByLineNo = new Map<Integer, ACVTMJobTaskWrapper>();
        for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            this.addJobTaskWrapper(jobTaskWrapper);
        }
        */
        this.JobTaskWrappers = jobTaskWrappers;
        //ticket 19130 04.28.23 >>
    }

    public ACVTMWrapper(TM__c tm, List<TM_Job_Task__c> jobTasks, List<TM_Line__c> tmLines) {
        this.TM = tm;
        //this.JobTaskWrappers = new List<ACVTMJobTaskWrapper>();
        //Map<Integer, ACVTMJobTaskWrapper> mapTMJobTaskWrappersByJobTask = new Map<Integer, ACVTMJobTaskWrapper>();

        //ticket 19130 04.28.23 <<
        //this.mapJobTaskWrappersByLineNo = new Map<Integer, ACVTMJobTaskWrapper>();
        this.JobTaskWrappers = new List<ACVTMJobTaskWrapper>();
        Map<Integer, ACVTMJobTaskWrapper> mapTMJobTaskWrappersByJobTask = new Map<Integer, ACVTMJobTaskWrapper>();
        //ticket 19130 04.28.23 >>
        for (TM_Job_Task__c jobTask : jobTasks) {
            Integer jobTaskLineNo = jobTask.Line_No__c.intValue();
            ACVTMJobTaskWrapper jobTaskWrapper = new ACVTMJobTaskWrapper();
            jobTaskWrapper.JobTask = jobTask;
            jobTaskWrapper.TMLines = new List<TM_Line__c>();
            //mapTMJobTaskWrappersByJobTask.put(jobTaskLineNo, jobTaskWrapper);
            //ticket 19130 04.28.23 <<
            //this.addJobTaskWrapper(jobTaskWrapper);
            mapTMJobTaskWrappersByJobTask.put(jobTaskLineNo, jobTaskWrapper);
            //ticket 19130 04.28.23 >>
        }

        for (TM_Line__c tmLine : tmLines) {
            Integer jobTaskLineNo = 0;
            if (tmLine.TM_Job_Task__r != null && tmLine.TM_Job_Task__r.Line_No__c != null) {
                jobTaskLineNo = tmLine.TM_Job_Task__r.Line_No__c.intValue();
            }

            /*
            ACVTMJobTaskWrapper jobTaskWrapper;
            if (mapTMJobTaskWrappersByJobTask.containsKey(jobTaskLineNo)) {
                jobTaskWrapper = mapTMJobTaskWrappersByJobTask.get(jobTaskLineNo);
            }
            else {
                //handle sales lines without a job task -- old quotes and orders
                jobTaskWrapper = new ACVTMJobTaskWrapper();
                jobTaskWrapper.JobTask = new TM_Job_Task__c(Line_No__c = jobTaskLineNo, Name = 'Unassigned T&M Lines');
                jobTaskWrapper.TMLines = new List<TM_Line__c>();
                mapTMJobTaskWrappersByJobTask.put(jobTaskWrapper.JobTask.Line_No__c.intValue(), jobTaskWrapper);
            }

            tmLine.TM_Job_Task__c = jobTaskWrapper.JobTask.Id;
            tmLine.TM_Job_Task__r = jobTaskWrapper.JobTask;
            jobTaskWrapper.TMLines.add(tmLine);
            */

            //ticket 19130 04.28.2023 <<
            //this.addTMLine(tmLine);
            ACVTMJobTaskWrapper jobTaskWrapper;
            if (mapTMJobTaskWrappersByJobTask.containsKey(jobTaskLineNo)) {
                jobTaskWrapper = mapTMJobTaskWrappersByJobTask.get(jobTaskLineNo);
            }
            else {
                jobTaskWrapper =new ACVTMJobTaskWrapper();
                jobTaskWrapper.JobTask = new TM_Job_Task__c(Line_No__c = jobTaskLineNo, Name = 'Unassigned T&M Lines');
                jobTaskWrapper.TMLines = new List<TM_Line__c>();
                mapTMJobTaskWrappersByJobTask.put(jobTaskWrapper.JobTask.Line_No__c.intValue(), jobTaskWrapper);
            }

            tmLine.TM_Job_Task__c = jobTaskWrapper.JobTask.Id;
            tmLine.TM_Job_Task__r = jobTaskWrapper.JobTask;
            jobTaskWrapper.TMLines.add(tmLine);
            //ticket 19130 04.28.2023 >>
        }

        //ticket 19130 04.28.2023 <<
        //this.JobTaskWrappers = mapTMJobTaskWrappersByJobTask.values();
        this.JobTaskWrappers = mapTMJobTaskWrappersByJobTask.values();
        //ticket 19130 04.28.2023 >>
    }

    //ticket 19130 04.28.23 <<
    /*
    public void addJobTaskWrapper(ACVTMJobTaskWrapper jobTaskWrapper) {
        this.mapJobTaskWrappersByLineNo.put(jobTaskWrapper.JobTask.Line_No__c.intValue(), jobTaskWrapper);
    }

    public void deleteJobTaskWrapper(Integer jobTaskLineNo) {
        this.mapJobTaskWrappersByLineNo.remove(jobTaskLineNo);
    }

    public void addTMLine(TM_Line__c tmLine) {
        if (tmLine.TM_Job_Task__r == null) { //handle old TM lines that don't have a task, create a new task for these lines
            ACVTMJobTaskWrapper jobTaskWrapper;
            Integer jobTaskLineNo = 0;
            if (!this.mapJobTaskWrappersByLineNo.containsKey(jobTaskLineNo)) {
                jobTaskWrapper = new ACVTMJobTaskWrapper();
                jobTaskWrapper.JobTask = new TM_Job_Task__c(Line_No__c = jobTaskLineNo, TM__c = tm.Id, Name = 'T&M lines not assigned to a job task');
                jobTaskWrapper.TMLines = new List<TM_Line__c>();
                this.mapJobTaskWrappersByLineNo.put(jobTaskLineNo, jobTaskWrapper);
            }
            else {
                jobTaskWrapper = this.mapJobTaskWrappersByLineNo.get(jobTaskLineNo);
            }
            tmLine.TM_Job_Task__r = jobTaskWrapper.JobTask;
        }

        if (this.mapJobTaskWrappersByLineNo.containsKey(tmLine.TM_Job_Task__r.Line_No__c.intValue())) {
            ACVTMJobTaskWrapper jobTaskWrapper = this.mapJobTaskWrappersByLineNo.get(tmLine.TM_Job_Task__r.Line_No__c.intValue());
            jobTaskWrapper.TMLines.add(tmLine);
        } else {
            throw new DataException('Job task (line #' + tmLine.TM_Job_Task__r.Line_No__c + ') does not exist on the wrapper.');
        }
    }
    */
    //ticket 19130 04.28.23 >>

    public List<TM_Job_Task__c> getJobTasks() {
        //ticket 19130 04.28.23 <<
        /*
        List<TM_Job_Task__c> salesOrderJobTasks = new List<TM_Job_Task__c>();
        for (ACVTMJobTaskWrapper jobTaskWrapper : this.mapJobTaskWrappersByLineNo.values()) {
            salesOrderJobTasks.add(jobTaskWrapper.JobTask);
        }
        return salesOrderJobTasks;
        */
        List<TM_Job_Task__c> tmJobTasks = new List<TM_Job_Task__c>();
        for (ACVTMJobTaskWrapper jobTaskWrapper : this.JobTaskWrappers) {
            tmJobTasks.add(jobTaskWrapper.JobTask);
        }
        return tmJobTasks;
        //ticket 19130 04.28.23 >>
    }

    public List<TM_Line__c> getTMLines() {
        //ticket 19130 04.28.23 <<
        /*
        List<TM_Line__c> tmLines = new List<TM_Line__c>();
        for (ACVTMJobTaskWrapper jobTaskWrapper : this.mapJobTaskWrappersByLineNo.values()) {
            for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                tmLines.add(tmLine);
            }
        }
        return tmLines;
        */
        List<TM_Line__c> tmLines = new List<TM_Line__c>();
        for (ACVTMJobTaskWrapper jobTaskWrapper : this.JobTaskWrappers) {
            for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                tmLines.add(tmLine);
            }
        }
        return tmLines;
        //ticket 19130 04.28.23 >>
    }
}