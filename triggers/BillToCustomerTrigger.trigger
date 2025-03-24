trigger BillToCustomerTrigger on Bill_to_Customer__c (before delete) {
    if (Trigger.isBefore) {
        User u = [SELECT Allow_Deleting_Bill_to_Customer__c FROM User WHERE Id = :UserInfo.getUserId()];
        for (Bill_to_Customer__c customer : Trigger.Old) {
            if (u.Allow_Deleting_Bill_to_Customer__c != true) {
                customer.addError('You should not delete bill-to customers.');
            }
        }
    }
}