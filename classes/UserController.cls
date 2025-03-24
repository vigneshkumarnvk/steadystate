public with sharing class UserController {

    @future
    public static void LinkSalespeople(List<Id> uIds) {
        Map<Id, Salesperson__c> mUsers = new Map<Id, Salesperson__c>();
        for (User u : [SELECT Id, Name, FirstName, LastName, UserRole.Name FROM User WHERE Id IN :uIds]) {
            if (u.UserRole != null && (u.UserRole.Name.startsWithIgnoreCase('AE') || u.UserRole.Name.startsWithIgnoreCase('BD'))) {
                mUsers.put(u.Id, new Salesperson__c(Name = u.Name, First_Name__c = u.FirstName, Last_Name__c = u.LastName, Account_Executive__c = true, User__c =  u.Id, Status__c = 'Active'));
            }
            else if (u.UserRole != null && u.UserRole.Name.startsWithIgnoreCase('PC')) {
                mUsers.put(u.Id, new Salesperson__c(Name = u.Name, First_Name__c = u.FirstName, Last_Name__c = u.LastName, Account_Executive__c = false, User__c = u.Id, Status__c = 'Active'));
            }
            else {
                //mUsers.put(u.Id, new Salesperson__c(Name = U.Name, First_Name__c = u.FirstName, Last_Name__c = u.LastName, User__c = u.Id, Status__c = 'Inactive'));
            }
        }

        List<Salesperson__c> salespeople = new List<Salesperson__c>();
                    
        List<Salesperson__c> sps = [SELECT Id, Name, First_Name__c, Last_Name__c, Salesperson_Code__c, User__c, Account_Executive__c, Status__c FROM Salesperson__c];
        Set<String> codes = new Set<String>();
        for (Salesperson__c sp : sps) {
            if (mUsers.containsKey(sp.User__c)) { //check if users already have a salesperson record
                Salesperson__c salesperson = mUsers.get(sp.User__c);
                sp.Account_Executive__c = salesperson.Account_Executive__c;
                sp.Status__c = salesperson.Status__c;
                salespeople.add(sp);
                mUsers.remove(sp.User__c); //remove the existing salesperson record from the queue
            }
            codes.add(sp.Salesperson_Code__c);
        }
        
        //assign codes to the new salesperson records
        for (Salesperson__c sp : mUsers.values()) {            
            String code = (sp.First_Name__c != null ? sp.First_Name__c.left(1) : '') + sp.Last_Name__c;
            if (code.length() >= 3) {
                code = code.left(3);
            }
            Integer i = 0;                
            while (codes.contains(code)) {
                code = code + i;
            }
            sp.Salesperson_Code__c = code.toUpperCase();
            codes.add(sp.Salesperson_Code__c);
            salespeople.add(sp);
        }
        upsert(salespeople);
    }
    //US144300: Resource Sync : Salesforce : Labor : New/Termed Labor Resources sync from EQAI to Salesforce
    //To set IsActive as false based on the request receive from EQAI
    @future
    public static void InactivateUser(Set<String> employeeIds) {
        List<User> updateUserList = new List<User>();
                for(User userRecord : [SELECT Id,Name,IsActive,RSG_EIN__c FROM User WHERE RSG_EIN__c IN: employeeIds]){
                    userRecord.IsActive = False;
                    updateUserList.add(userRecord);
                }
                if(!updateUserList.isEmpty()){
                    Database.SaveResult[] results = Database.update(updateUserList, false);
                }
    }
    
}