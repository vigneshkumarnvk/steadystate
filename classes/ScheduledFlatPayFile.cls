/************************************************************************************************************
 * Name         :  ScheduledFlatPayFile
 * Description  :  Schedulable apex for exporting payroll flat pay lines via email.
 * Test Class	:  ScheduledFlatPayFileTest
 *
 * @author Michael Duran
 * @date 06/27/2022
 *
 * Modification Log :
 * Developer                 Date                   Description
 * -----------------------------------------------------------------------------------------------------------                 
 * Michael Duran			07/20/2022				US75942: Add users to targetAddresses list.
 * Steven Wang              05/24/2023              Ticket#25097: ACV Rebranding.
 * Andrew Simons            01/19/2024              Updated target addresses(removed agarcia@acvenviro.com and added grincon@republicservices.com, jodell@republicservices.com)
 *************************************************************************************************************/

global class ScheduledFlatPayFile implements Schedulable {
	
    public List<Id> payrollIds;
    public List<Payroll__c> payrollList;
    public List<Payroll_Line__c> payrollLineList;
    public String fileName;
    public Boolean multiplePayrolls = false;
    public List<String> targetAddresses = new List<String> {'payroll@republicservices.com','mduran@republicservices.com','cmcabee@ecoflo.com','grincon@republicservices.com','jodell@republicservices.com'};
    
    global void execute (SchedulableContext sc){
        
		payrollList = getPayrolls();
        if(payrollList.size() > 0) {
            
            String weekNo = payrollList[0].Week_Number__r.Name;
            if (payrollList.size() > 1) multiplePayrolls = true;
        
        	payrollIds = getPayrollIds(payrollList);
        	payrollLineList = getPayrollFlatPayLinesByPayrollIds(payrollIds);
        	
        	String selectedIds = '';
        	for (Integer i = 0; i < PayrollList.size(); i++) {
            	if (i != 0) selectedIds += ',';
            	selectedIds += payrollList[i].Id;
        	}
        
        	// Format data into XLS file
        	String URL = '/apex/ExportWorkdayDataAsCSV?selectedIds=' + selectedIds;
        	PageReference report = new PageReference(URL);
        
        	// Create attachment
        	Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        
        	String fileName = generateFileName(payrollLineList, multiplePayrolls);
        	attachment.setFileName(fileName + '.xls');
        	if(!test.isRunningTest()){
        		attachment.setBody(report.getContent());
        	} else {
        	    attachment.setBody(Blob.valueOf('This is a test.'));
        	}
        	attachment.setContentType('text/csv');
        
        	// Create email and get FROM address
        	Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        	OrgWideEmailAddress[] fromAddress = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Republic Services']; //Ticket#25097;
        	if ( fromAddress.size() > 0 ) message.setOrgWideEmailAddressId(fromAddress.get(0).Id);
        
        	// Attach file and send email
        	message.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment } );
        	message.setSubject('ACV Workday Flat Pay File ' + weekNo + ' ' + System.datetime.now().format());
        	message.setPlainTextBody('The report is attached.');
        	message.setToAddresses(targetAddresses);
        	Messaging.sendEmail( new Messaging.SingleEmailMessage[] { message } );                 
        }
    }
    
    private List<Payroll__c> getPayrolls(){
        List<Payroll__c> payrolls = [SELECT Id, End_Date__c, Service_Center__r.Name, Week_Number__r.Name,
                Start_Date__c
        FROM Payroll__c WHERE Start_Date__c = LAST_WEEK AND Status__c <> 'Open'];
		
        //System.debug('Payroll Size:  ' + payrolls.size());
        return payrolls;
    }
    
    
    private List<Id> getPayrollIds(List<Payroll__c> payrolls){
        List<Id> PRIds = new List<Id>();
        for (Integer i = 0; i < payrolls.size(); i++) {
            PRIds.add(payrolls[i].Id);
        }
        return PRIds;
    }
    
    private List<Payroll_Line__c> getPayrollFlatPayLinesByPayrollIds(List<Id> payrollIds){
        List<Payroll_Line__c> payrollLines = [SELECT Id, Resource__r.RSG_EIN__c, Resource__r.Employee_No__c,
                Resource__r.Description__c, Timesheet_Line__r.Scheduled_Date__c, Payroll__r.End_Date__c, Pay_Rate__c,
                Pay_Code__c, Sales_Order__r.Name, Payroll__r.Service_Center__r.Name, Payroll__r.Week_Number__r.Name,
                Payroll__r.Start_Date__c
        FROM Payroll_Line__c WHERE Timesheet_Line__r.Time_Type__c = 'Flat Pay' AND Payroll__c IN :payrollIds];
		
        //System.debug('###############   Payroll Lines:' + payrollLines.size() + '   ###############');
        return payrollLines;
    }   
    
    private String generateFileName(List<Payroll_Line__c> payrollLines, Boolean multipleServiceCenter){
        String tempFileName = 'WorkdayFileExport';
        String startDate = String.valueOf(payrollLines[0].Payroll__r.Start_Date__c.day()) +
                String.valueOf(payrollLines[0].Payroll__r.Start_Date__c.month()) +
                String.valueOf(payrollLines[0].Payroll__r.Start_Date__c.year());
        String endDate = String.valueOf(payrollLines[0].Payroll__r.End_Date__c.day()) +
                String.valueOf(payrollLines[0].Payroll__r.End_Date__c.month()) +
                String.valueOf(payrollLines[0].Payroll__r.End_Date__c.year());

        if(multipleServiceCenter == false){
            tempFileName = tempFileName + '_SC' + payrollLines[0].Payroll__r.Service_Center__r.Name + '_' + startDate
                    + '_' + endDate;
        } else {
            tempFileName = tempFileName + startDate
                    + '_' + endDate;
        }
        return tempFileName;
    }
	
}