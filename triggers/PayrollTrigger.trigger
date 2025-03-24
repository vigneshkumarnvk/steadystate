trigger PayrollTrigger on Payroll__c (before insert, before update, before delete, after delete) {
    if(CompanyMgmt.systemCall == false){
        Trigger.old[0].addError('You cannot manually update a payroll record!');
    }

	if(Trigger.isInsert || Trigger.isUpdate){
        List<Payroll__c> PRList = Trigger.new;
        PayrollTriggersMgmt.PRInsertUpdate(PRList, Trigger.oldMap, Trigger.isInsert);
    }

    if(Trigger.isBefore && Trigger.isDelete){
        Set<Id> payrollIds = new Set<Id>();
        for(Payroll__c payroll : Trigger.old){
            payrollIds.add(payroll.Id);
        }

        if(payrollIds.size() > 0){
            List<Timesheet__c> timeSheets = [SELECT Id, Status__c, Payroll__c FROM Timesheet__c WHERE Payroll__c IN :payrollIds];
            for(Timesheet__c timesheet : timeSheets){
                timesheet.Status__c = 'Open';
                timesheet.Payroll__c = null;
            }

            if(timeSheets.size() > 0){
                update timeSheets;
            }
        }
    }
}