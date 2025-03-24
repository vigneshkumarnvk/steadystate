public with sharing class JobSchedulerController {
    @AuraEnabled
    public static String getAllSchedulableClasses() {

        Map<String, ApexJob> mapJobsByName = new Map<String, ApexJob>();
        Map<String, String> mapApexClassByJobName = new Map<String, String>();

        try {
            List<Schedulable_Apex_Job__c> schedulableApexJobs = [SELECT Id, Name, Schedulable_Class_Name__c FROM Schedulable_Apex_Job__c ORDER BY Name];
            for (Schedulable_Apex_Job__c schedulableApexJob : schedulableApexJobs) {
                mapApexClassByJobName.put(schedulableApexJob.Schedulable_Class_Name__c, schedulableApexJob.Name);
            }

            Map<String, AsyncApexJob> mapAsyncApexJobsByName = new Map<String, AsyncApexJob>();
            for (AsyncApexJob asyncApexJob : [
                    SELECT Status, ApexClass.Name, JobItemsProcessed, TotalJobItems FROM AsyncApexJob
                    WHERE Status IN ('Holding', 'Queued', 'Preparing', 'Processing') AND ApexClass.Name IN : mapApexClassByJobName.keySet()]) {
                if (mapApexClassByJobName.containsKey(asyncApexJob.ApexClass.Name)) {
                    mapAsyncApexJobsByName.put(mapApexClassByJobName.get(asyncApexJob.ApexClass.Name), asyncApexJob);
                }
            }

            for (String valueName : mapApexClassByJobName.keySet()) {
                String jobLabel = mapApexClassByJobName.get(valueName);
                ApexJob job = new ApexJob(jobLabel, valueName);

                if (mapAsyncApexJobsByName.containsKey(jobLabel)) {
                    AsyncApexJob asyncApexJob = mapAsyncApexJobsByName.get(jobLabel);
                    job.BatchesProcessed = asyncApexJob.JobItemsProcessed;
                    job.TotalBatches = asyncApexJob.TotalJobItems;
                    job.JobStatus = asyncApexJob.Status;
                }

                mapJobsByName.put(jobLabel, job);
            }

            for (CronTrigger cronTrigger :  [SELECT PreviousFireTime, NextFireTime, CronJobDetail.Name, CronExpression, State FROM CronTrigger WHERE CronJobDetail.Name IN :mapJobsByName.keySet()]) {
                ApexJob job = mapJobsByName.get(cronTrigger.CronJobDetail.Name);

                job.ApexJobId = cronTrigger.Id;
                job.LastRunTime = cronTrigger.PreviousFireTime;
                job.NextRunTime = cronTrigger.NextFireTime;
                job.CronExpression = cronTrigger.CronExpression;
                job.ScheduleState = cronTrigger.State;

                String[] tokens = job.CronExpression.split(' ');
                String lastChar = tokens[tokens.size()-1];
                if (tokens[2] == '0/1') {
                    job.Frequency = 'Hourly';
                    job.Minute = ('0' + tokens[1]).right(2);
                } else if (tokens[3] == '1/1') {
                    job.Frequency = 'Daily';
                    job.Minute = ('0' + tokens[1]).right(2);
                    job.Meridiem = 'AM';
                    Integer hour = Integer.valueOf(tokens[2]);
                    if (hour >= 12) {
                        hour -= 12;
                        job.Meridiem = 'PM';
                    }
                    job.Hour = ('0' + hour).right(2);
                } else  if (lastChar.length() == 1 && lastChar.isNumeric() == true) {
                    job.Frequency = 'Weekly';
                    job.Minute = ('0' + tokens[1]).right(2);
                    job.Meridiem = 'AM';
                    Integer hour = Integer.valueOf(tokens[2]);
                    if (hour >= 12) {
                        hour -= 12;
                        job.Meridiem = 'PM';
                    }
                    job.Hour = ('0' + hour).right(2);
                    job.WeekDay = lastChar;
                }
            }

            return JSON.serialize(mapJobsByName.values());
        } catch (exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void addSchedulableApexJob(String JSONSchedulableApexJob) {
        try {
            Schedulable_Apex_Job__c schedulableApexJob = (Schedulable_Apex_Job__c)JSON.deserialize(JSONSchedulableApexJob, Schedulable_Apex_Job__c.class);

            if ([SELECT Id, CronJobDetail.Name FROM CronJobDetail WHERE Name = :schedulableApexJob.Name].size() > 0) {
                throw new DataException('You cannot use job name "' + schedulableApexJob.Name + '" because there is another scheduled apex job using the same name.');
            }

            if ([SELECT Id FROM ApexClass WHERE Name = :schedulableApexJob.Schedulable_Class_Name__c].size() == 0) throw new DataException('Class ' + schedulableApexJob.Schedulable_Class_Name__c + ' is not a valid class.');

            insert schedulableApexJob;
        } catch (exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void runApexJobNow(String jobName) {
        if (String.isNotBlank(jobName)) {
            Type tp = Type.forName(jobName);
            Schedulable theCon = (Schedulable)tp.newInstance();
            theCon.execute(null);
        }
    }

    @AuraEnabled
    public static void scheduleApexJob(String JSONJob) {
        ApexJob job = (ApexJob)JSON.deserialize(JSONJob, ApexJob.class);
        String jobLabel = job.label;
        String jobName = job.valueName;
        String cronExpr = createCronExpr(job.Frequency, job.WeekDay, job.Hour, job.Minute, job.Meridiem);
        Type tp = Type.forName(jobName);
        System.schedule(jobLabel, cronExpr, (Schedulable)tp.newInstance());
    }

    @AuraEnabled
    public static void abortApexJob(String JSONJob) {
        try {
            ApexJob job = (ApexJob)JSON.deserialize(JSONJob, ApexJob.class);
            System.abortJob(job.ApexJobId);
        } catch (exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public static String createCronExpr(String frequency, String WeekDay, String hour, String minute, String meridiem) {
        if (frequency == 'Hourly') {
            return '00' + ' ' + minute + ' 0/1 1/1 * ? *';
        } else if (frequency == 'Daily') {
            Datetime startTime;
            Integer year = DateTime.now().year();
            Integer month = DateTime.now().month();
            Integer day = DateTime.now().Day();

            Integer intHour = Integer.valueOf(hour);
            Integer intMinute = Integer.valueOf(minute);
            if (meridiem == 'PM') {
                intHour += 12;
            }
            startTime = Datetime.newInstance(year, month, day, intHour, intMinute, 0);
            if (startTime.addMinutes(-5) < Datetime.now()) { //advance to next day if less than 5 minutes
                startTime = startTime.addDays(1);
            }
            return startTime.second() + ' ' + startTime.minute() + ' ' + startTime.hour() + ' 1/1 * ? *';
        } else if (frequency == 'Weekly') {
            Datetime startTime;
            Integer year = DateTime.now().year();
            Integer month = DateTime.now().month();
            Integer day = DateTime.now().Day();

            Integer intHour = Integer.valueOf(hour);
            Integer intMinute = Integer.valueOf(minute);
            if (meridiem == 'PM') {
                intHour += 12;
            }
            startTime = Datetime.newInstance(year, month, day, intHour, intMinute, 0);
            if (startTime.addMinutes(-5) < Datetime.now()) { //advance to next day if less than 5 minutes
                startTime = startTime.addDays(1);
            }
            return startTime.second() + ' ' + startTime.minute() + ' ' + startTime.hour() + ' ? * '+WeekDay;
        } else {
            throw new AuraHandledException('Error generating cron expression.');
        }
    }

    public class GlobalValueSet {
//        public String entityTypeName;
        public cls_records[] records;
    }
    class cls_records {
        public cls_attributes attributes;
        public cls_Metadata Metadata;
    }
    class cls_attributes {
        public String type;	//GlobalValueSet
        public String url;	///services/data/v50.0/tooling/sobjects/GlobalValueSet/0Nt4p0000008yMkCAI
    }
    class cls_Metadata {
        public cls_customValue[] customValue;
        public String masterLabel;
        public boolean sorted;
    }
    class cls_customValue {
        public String label;	//Electronic Document Schedulable
        public String valueName;	//ElectronicDocumentSchedulable
    }

    public class ApexJob {
        public Id ApexJobId;
        public String label;
        public String valueName;
        public Datetime NextRunTime;
        public Datetime LastRunTime;
        public String Frequency;
        public String WeekDay;
        public String Hour;
        public String Minute;
        public String Meridiem;
        public String CronExpression;
        public Integer BatchSize;
        public String ScheduleState;
        public Integer TotalBatches;
        public Integer BatchesProcessed;
        public String JobStatus;
        public ApexJob(String jobName, String valueName) {
            this.label = jobName;
            this.valueName = valueName;
            this.BatchSize = 10;
        }
    }
}