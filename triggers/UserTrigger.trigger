trigger UserTrigger on User (after insert, after update) {
    if (CompanyMgmt.ByPassTrigger == true) return;
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            List<Id> uIds = new List<Id>();
            for (User u : Trigger.New) {
                uIds.add(u.Id);
            }            
            UserController.LinkSalespeople(uIds);   
        }
    }
}