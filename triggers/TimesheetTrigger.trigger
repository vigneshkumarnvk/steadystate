trigger TimesheetTrigger on Timesheet__c (before insert, before update, before delete) {
    //Ticket#23713 >>
    if(CompanyMgmt.systemCall != true){
        //Ticket#24469 >>
        Boolean isPayrollBlockoutPeriod = PayrollMgmt.isPayrollBlockoutPeriod();
        if(isPayrollBlockoutPeriod == true){
            throw new DataException('You are not allow to create/edit timesheet during Monday payroll period.');
        }
        //Ticket#24469 <<
    }
    //Ticket#23713 <<
    if(Trigger.isInsert || Trigger.isUpdate){
        TimesheetTriggerMgmt.TSInsertUpdate(Trigger.new, Trigger.oldMap, Trigger.isInsert);
    }
}