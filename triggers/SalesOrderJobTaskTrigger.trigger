trigger SalesOrderJobTaskTrigger on Sales_Order_Job_Task__c (after insert, after update) {
    if (CompanyMgmt.byPassTrigger == true) return;
    
    if (Trigger.isAfter) {
        Set<Id> salesOrderIds = new Set<Id>();
        for (Sales_Order_Job_Task__c jobTask : Trigger.new) {
            salesOrderIds.add(jobTask.Sales_Order__c);
        }

        Map<Id, Integer> mapDuplicatedTaskNosByTaskId = new Map<Id, Integer>();
        List<Sales_Order__c> salesOrders = [SELECT Id, (SELECT Task_No__c FROM Sales_Order_Job_Tasks__r) FROM Sales_Order__c WHERE Id IN :salesOrderIds];
        for (Sales_Order__c salesOrder : salesOrders) {
            Set<Integer> taskNos = new Set<Integer>();
            for (Sales_Order_Job_Task__c jobTask : salesOrder.Sales_Order_Job_Tasks__r) {
                if (taskNos.contains(jobTask.Task_No__c.intValue())) {
                    mapDuplicatedTaskNosByTaskId.put(jobTask.Id, jobTask.Task_No__c.intValue());
                }
                taskNos.add(jobTask.Task_No__c.intValue());
            }
        }

        for (Sales_Order_Job_Task__c jobTask : Trigger.new) {
            if (mapDuplicatedTaskNosByTaskId.containsKey(jobTask.Id)) {
                jobTask.addError('Task #' + jobTask.Line_No__c.intValue() + ' is already used by another task.');
            }
        }
    }
}