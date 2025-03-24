trigger UserServiceCenterTrigger on User_Service_Center__c (after insert, after update, after delete) {
    if (Trigger.isAfter) {
        Set<Id> uIds = new Set<Id>();        
        if (Trigger.isInsert || Trigger.isUpdate) {
            for (User_Service_Center__c usc : Trigger.New) {
                uIds.add(usc.User__c);
            }
        }
        else {
            for (User_Service_Center__c usc : Trigger.old) {
                uIds.add(usc.User__c);
            }
        }
        
        List<User> users = [SELECT Id, (SELECT Service_Center__r.Name, Default__c, Manager_of_SC__c FROM User_Service_Centers__r ORDER BY Service_Center__r.Name) FROM User WHERE Id IN :uIds];
        for (User u : users) {
            Set<String> SCs = new Set<String>();
            String defaultSC = null;
            for (User_Service_Center__c usc : u.User_Service_Centers__r) {
                if (usc.Default__c == true) {
                    defaultSC = usc.Service_Center__r.Name;
                }
                if (usc.Manager_of_SC__c == true) {
                    SCs.add(usc.Service_Center__r.Name);
                }
            }

            String managerOfSC = String.join(new List<String>(SCs), ',');
            if (managerOfSC.length() <= 255) {
                u.Manager_of_SC__c = managerOfSC;
                u.Manager_of_SC_2__c = null;
            }
            else {

                Integer p = 0;
                Integer q;
                while (p < 255 && p >= 0) {
                    q = p;
                    p = managerOfSC.indexOf(',', p + 1);
                }
                u.Manager_of_SC__c = managerOfSC.left(q);
                u.Manager_of_SC_2__c = managerOfSC.substring(q + 1);
            }

            u.Service_Center__c = defaultSC;
        }
        if (users.size() > 0) {
            update users;
        }
    }
}