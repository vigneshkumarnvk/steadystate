trigger EmployeeClockedTimeForKronosTrigger on Employee_Clocked_Time_for_Kronos__c (before insert, before update, before delete) {
    if(CompanyMgmt.systemCall != true){
        Trigger.old[0].addError('Manual operation on the record is not allowed!');
    }
}