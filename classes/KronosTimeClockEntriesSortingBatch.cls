/*************************************************************************************************
* Name         : KronosTimeClockEntriesSortingBatch
* Description  :  Batch for creating T&M punch data
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Andrew SImons             10/17/2024             Added creation of T&M line report in finish method
* Andrew Simons             10/18/2024             Updated report target list
*************************************************************************************************/

public with sharing class KronosTimeClockEntriesSortingBatch implements Database.Batchable<Employee_Clocked_Time_for_Kronos__c> {
    //Ticket#24469
    public Boolean isMondayExtraRun = false;
    public List<String> targetAddresses = new List<String> {};

    //Ticket#24469
    public KronosTimeClockEntriesSortingBatch(Boolean isMondayExtra){
        isMondayExtraRun = isMondayExtra;
    }

    public List<Employee_Clocked_Time_for_Kronos__c> start(Database.BatchableContext bc){
        List<Employee_Clocked_Time_for_Kronos__c> employeeClockedTimeForKronosLst = [SELECT Id, Resource__r.Description__c,
                Resource__r.RSG_EIN__c, Work_Date__c, Time__c, Time_Type__c, Time_Type_Code__c, Entry_Type__c,
                Pay_Rule_Line__c, Sales_Order__r.Name, Sales_Order__r.D365_Project_ID__c, Kronos_Action__c
        FROM Employee_Clocked_Time_for_Kronos__c
        WHERE Exported__c = FALSE ORDER BY Resource__c, Work_Date__c, Kronos_Action__c DESC NULLS LAST, Time__c];
        return employeeClockedTimeForKronosLst;
    }

    public void execute(Database.BatchableContext bc, List<Employee_Clocked_Time_for_Kronos__c> employeeClockedTimeForKronosLst){
        List<Salesforce_Punch_to_Kronos__c> salesforcePunchToKronosEntries = new List<Salesforce_Punch_to_Kronos__c>();
        List<Employee_Clocked_Time_for_Kronos__c> employeeClockedTimeForKronosEntriesToUpdate = new List<Employee_Clocked_Time_for_Kronos__c>();
        for(Employee_Clocked_Time_for_Kronos__c employeeTimeClock : employeeClockedTimeForKronosLst){
            Salesforce_Punch_to_Kronos__c spk = new Salesforce_Punch_to_Kronos__c();
            spk.Name__c = employeeTimeClock.Resource__r.Description__c;
            spk.EIN__c = employeeTimeClock.Resource__r.RSG_EIN__c;
            spk.Date__c = employeeTimeClock.Work_Date__c;
            spk.Time__c = employeeTimeClock.Time__c;
            spk.Time_Type__c = employeeTimeClock.Time_Type__c;
            spk.Time_Type_Code__c = employeeTimeClock.Time_Type_Code__c;
            spk.Type__c = employeeTimeClock.Entry_Type__c;
            spk.Rule_Id__c = employeeTimeClock.Pay_Rule_Line__c;
            if(employeeTimeClock.Time_Type__c == 'Travel Time'){
                spk.Time_Type__c = 'Travel';
                spk.Rule_Id__c = null;
            }
            if(employeeTimeClock.Sales_Order__c != null){
                if(employeeTimeClock.Sales_Order__r.D365_Project_ID__c != null) {
                    spk.Sales_Order__c = employeeTimeClock.Sales_Order__r.Name + ' - ' + employeeTimeClock.Sales_Order__r.D365_Project_ID__c;
                } else {
                    spk.Sales_Order__c = employeeTimeClock.Sales_Order__r.Name;
                }
            }
            spk.Delete_Indicator__c = employeeTimeClock.Kronos_Action__c;
            salesforcePunchToKronosEntries.add(spk);
            employeeTimeClock.Exported__c = true;
            employeeTimeClock.Exported_At__c = System.now();
            employeeClockedTimeForKronosEntriesToUpdate.add(employeeTimeClock);
        }
        if(salesforcePunchToKronosEntries.size() > 0){
            insert salesforcePunchToKronosEntries;
        }

        if(employeeClockedTimeForKronosEntriesToUpdate.size() > 0){
            CompanyMgmt.systemCall = true; //Ticket#23796
            update employeeClockedTimeForKronosEntriesToUpdate;
        }
    }

    public void finish(Database.BatchableContext bc){
    
        //Ticket#24469 >>
        if(isMondayExtraRun == true) {
            //for United States locale, the start of a week is always Sunday.
            Date processDate = System.today().toStartOfWeek();
            //calculate start of week Monday's date.(Previous Week)
            processDate = TimeUtils.toStartOfWeek(processDate);
            GenerateTimesheetBatch generateTimesheetBatch = new GenerateTimesheetBatch(processDate);
            Database.executeBatch(generateTimesheetBatch, 1);
        }
        //Ticket#24469 <<

        DateTime endDate = DateTime.now();
        DateTime startDate = endDate.addMinutes(-20);
       
        // Fetch all the Employee_Clocked_Time_for_Kronos__c records
        List<Employee_Clocked_Time_for_Kronos__c> employeeClockedTimeForKronosLst = [SELECT Id, Resource__r.Description__c, Resource__r.RSG_EIN__c, Work_Date__c, Time__c, Time_Type__c,
                        Entry_Type__c, Pay_Rule_Line__r.Rate__c, T_M_Line__r.Name, T_M_Line__r.Job_Start_Time__c, T_M_Line__r.Resource_Type__r.Name, Original_Labor_Type__c, 
                        T_M_Line__r.Site_Start_Time__c, T_M_Line__r.Site_End_Time__c, T_M_Line__r.Job_End_Time__c, Pay_Rule_Line__r.PW_Labor_Category__c, Pay_Rule_Line__r.Resource_Type__r.Name,
                        T_M_Line__r.Lunch_Start_Time__c, T_M_Line__r.Lunch_End_Time__c, Sales_Order__r.Name, Sales_Order__r.Pay_Rule__r.Name,
                        Sales_Order__r.D365_Project_ID__c, Kronos_Action__c
                            FROM Employee_Clocked_Time_for_Kronos__c
                            WHERE Exported__c = TRUE
                            AND ((CreatedDate >= :startDate AND CreatedDate <= :endDate) OR (LastModifiedDate >= :startDate AND LastModifiedDate <= :endDate))
                            AND Resource_Off__r.Off_Type__r.Name != 'Shop Time'
                            ORDER BY CreatedDate DESC ,Id, T_M_Line__r.Id
        ];
        System.debug(employeeClockedTimeForKronosLst);

        // Prepare CSV string
        String csvData = 'Name,EIN,Date,Start Job Time,Site Start Time,Site End Time,Job End Time,Start Lunch Time,End Lunch Time,Rate,Labor Type,Pay Rule Name,Sales Order,D365 Project Id,Delete Indicator\n';


        // Map to group records by T&M Line ID
        Map<Id, Employee_Clocked_Time_for_Kronos__c> uniqueTMLineRecords = new Map<Id, Employee_Clocked_Time_for_Kronos__c>();

        // Map to group 'Delete' records by T&M Line ID
        Map<Id, List<Employee_Clocked_Time_for_Kronos__c>> deleteRecordsByTMLine = new Map<Id, List<Employee_Clocked_Time_for_Kronos__c>>();

                for (Employee_Clocked_Time_for_Kronos__c record : employeeClockedTimeForKronosLst) {
                    Id tmLineId = record.T_M_Line__c;
                    if (tmLineId != null) {
                        if (record.Kronos_Action__c == 'Delete') {
                        // Collect delete records for each T&M Line
                        if (!deleteRecordsByTMLine.containsKey(tmLineId)) {
                            deleteRecordsByTMLine.put(tmLineId, new List<Employee_Clocked_Time_for_Kronos__c>());
                }
                    deleteRecordsByTMLine.get(tmLineId).add(record);
                } else {
                    // Keep the first non-delete record for each T&M Line
                    if (!uniqueTMLineRecords.containsKey(tmLineId)) {
                        uniqueTMLineRecords.put(tmLineId, record);
                    }
                }
            }
        }

           
            // process non-delete records
            for (Employee_Clocked_Time_for_Kronos__c record : uniqueTMLineRecords.values()) {
            
                // Iterate through the unique records and add them to the CSV
                    String workDate = formatDateTime(record.Work_Date__c);
                    //Formatting the time fields
                    String jobStartTime = formatTime(record.T_M_Line__r.Job_Start_Time__c);
                    String jobEndTime = formatTime(record.T_M_Line__r.Job_End_Time__c);
                    String siteStartTime = '';
                    String siteEndTime = '';
                    String lunchStartTime = formatTime(record.T_M_Line__r.Lunch_Start_Time__c);
                    String lunchEndTime = formatTime(record.T_M_Line__r.Lunch_End_Time__c);
                    String pwLaborType;
        
                    if (record.Sales_Order__r.Pay_Rule__r.Name != null && record.Sales_Order__r.Pay_Rule__r.Name.startsWith('PW')) {
                        siteStartTime = formatTime(record.T_M_Line__r.Site_Start_Time__c);
                        siteEndTime = formatTime(record.T_M_Line__r.Site_End_Time__c);
                        pwLaborType = (record.Pay_Rule_Line__c != null ? (record.Pay_Rule_Line__r.Resource_Type__r.Name + ' - ' + record.Pay_Rule_Line__r.PW_Labor_Category__c) : record.T_M_Line__r.Resource_Type__r.Name);

                    }
        
                    csvData += '"' + record.Resource__r.Description__c + '",' +
                    '"' + record.Resource__r.RSG_EIN__c + '",' +
                    '"' + workDate + '",' +
                    '"' + jobStartTime + '",' +
                    '"' + siteStartTime + '",' +
                    '"' + siteEndTime + '",' +
                    '"' + jobEndTime + '",' +
                    '"' + lunchStartTime + '",' +
                    '"' + lunchEndTime + '",' +
                    '"' + ((record.Pay_Rule_Line__r.Rate__c != null && record.Sales_Order__r.Pay_Rule__r.Name != null) ? record.Pay_Rule_Line__r.Rate__c : 0.0) + '",' +
                    '"' + (pwLaborType != null ? pwLaborType : record.T_M_Line__r.Resource_Type__r.Name)  + '",' +
                    '"' + (record.Sales_Order__r.Pay_Rule__r.Name != null ? record.Sales_Order__r.Pay_Rule__r.Name : '') + '",' +
                    '"' + record.Sales_Order__r.Name + '",' +
                    '"' + (record.Sales_Order__r.D365_Project_ID__c != null ? record.Sales_Order__r.D365_Project_ID__c : '') + '",' +
                    '"' + (record.Kronos_Action__c != null ? record.Kronos_Action__c : '') + '"\n';
                }

                System.debug( deleteRecordsByTMLine.keySet());
            // process delete records
            for (Id tmLineId : deleteRecordsByTMLine.keySet()) {

                List<Employee_Clocked_Time_for_Kronos__c> deleteRecords = deleteRecordsByTMLine.get(tmLineId);
             
                // Variables to store time values
                Time jobStartTime;
                Time siteStartTime;
                Time siteEndTime;
                Time jobEndTime;
                Time startLunchTime;
                Time endLunchTime;

                // Lists to hold IN and OUT entries
                List<Employee_Clocked_Time_for_Kronos__c> inEntries = new List<Employee_Clocked_Time_for_Kronos__c>();
                List<Employee_Clocked_Time_for_Kronos__c> outEntries = new List<Employee_Clocked_Time_for_Kronos__c>();

                // Loop over delete records for the same T&M Line ID
                for (Employee_Clocked_Time_for_Kronos__c delRecord : deleteRecords) {
                    System.debug(delRecord);
                    if (delRecord.Entry_Type__c == 'IN') {
                        inEntries.add(delRecord);
                    } else if (delRecord.Entry_Type__c == 'OUT') {
                        outEntries.add(delRecord);
                    } else if (delRecord.Entry_Type__c == 'Lunch Out') {
                        startLunchTime = delRecord.Time__c;
                    } else if (delRecord.Entry_Type__c == 'Lunch In') {
                        endLunchTime = delRecord.Time__c;
                    }
                }

                // Process IN entries
                if (inEntries.size() >= 3) {
                   
                    // Assign lesser time to Start Job Time, greater time to Site Start Time
                    if(inEntries[1].Sales_Order__r.Pay_Rule__r.Name.startsWith('PW')) {
                        siteStartTime = inEntries[1].Time__c;
                    }
                    if(inEntries[2].Sales_Order__r.Pay_Rule__r.Name.startsWith('PW')) {
                        siteEndTime = inEntries[2].Time__c;
                    }
                    jobStartTime = inEntries[0].Time__c;
                }

              

                if (inEntries.size() == 1) {
                     jobStartTime = inEntries[0].Time__c;
                }

                // Process OUT entries
                if (outEntries.size() >= 1) {
                    // Sort OUT entries by time
                    jobEndTime = outEntries[0].Time__c;
                }

                    // Build CSV row using the computed times
                    Employee_Clocked_Time_for_Kronos__c firstRecord = deleteRecords[0]; 

                    String workDate = formatDateTime(firstRecord.Work_Date__c);
                    String formattedJobStartTime = formatTime(jobStartTime);
                    String formattedSiteStartTime = formatTime(siteStartTime);
                    String formattedSiteEndTime = formatTime(siteEndTime);
                    String formattedJobEndTime = formatTime(jobEndTime);
                    String formattedStartLunchTime = formatTime(startLunchTime);
                    String formattedEndLunchTime = formatTime(endLunchTime);

                    csvData += '"' + firstRecord.Resource__r.Description__c + '",' +
                            '"' + firstRecord.Resource__r.RSG_EIN__c + '",' +
                            '"' + workDate + '",' +
                            '"' + formattedJobStartTime + '",' +
                            '"' + formattedSiteStartTime + '",' +
                            '"' + formattedSiteEndTime + '",' +
                            '"' + formattedJobEndTime + '",' +
                            '"' + formattedStartLunchTime + '",' +
                            '"' + formattedEndLunchTime + '",' +
                            '"' + ((firstRecord.Pay_Rule_Line__r.Rate__c != null && firstRecord.Sales_Order__r.Pay_Rule__r.Name != null) ? firstRecord.Pay_Rule_Line__r.Rate__c : 0.0) + '",' +
                            '"' + (firstRecord.Original_Labor_Type__c != null ? firstRecord.Original_Labor_Type__c : '' ) + '",' +
                            '"' + (firstRecord.Sales_Order__r.Pay_Rule__r.Name != null ? firstRecord.Sales_Order__r.Pay_Rule__r.Name : '') + '",' +
                            '"' + firstRecord.Sales_Order__r.Name + '",' +
                            '"' + (firstRecord.Sales_Order__r.D365_Project_ID__c != null ? firstRecord.Sales_Order__r.D365_Project_ID__c : '') + '",' +
                            '"' + firstRecord.Kronos_Action__c + '"\n';
        }

        String sortedCsvData = KronosCSVSorter.sortCSVData(csvData);
       
        // Convert the CSV data to a Blob
        Blob csvBlob = Blob.valueOf(sortedCsvData);

        // List of target email addresses (update with your list of recipients)
        List<String> emailAddresses = new List<String>{'SLucas3@republicservices.com', 'DDuncan2@republicservices.com', 'NCentofanti@republicservices.com', 'mrooney@republicservices.com', 'ATaylor@republicservices.com', 'GSwift@republicservices.com', 'JGilchrist@republicservices.com', 'TGamba@republicservices.com'};

        // Create an email message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(emailAddresses);
        email.setSubject('Kronos Report '+ System.Today());
        email.setPlainTextBody('Please find the attached Kronos report for today.');

        // Attach the CSV as an attachment
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('Kronos_Report.csv');
        attachment.setBody(csvBlob);
        email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

        // Send the email
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

        System.debug('Email sent with Kronos report attached.');
      
}   

    private String formatTime(Time timeValue) {
        if (timeValue == null) return '';
        String hourStr = (timeValue.hour() < 10 ? '0' : '') + timeValue.hour();
        String minuteStr = (timeValue.minute() < 10 ? '0' : '') + timeValue.minute();
        String secondStr = (timeValue.second() < 10 ? '0' : '') + timeValue.second();
        return hourStr + ':' + minuteStr + ':' + secondStr;
    } 
    
    private String formatDateTime(Date dateValue) {
        if (dateValue == null) {
            return '';
        }

        return dateValue.format();
    }

}
