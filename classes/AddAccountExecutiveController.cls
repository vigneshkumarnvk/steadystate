/*************************************************************************************************
* Name         :  AddAccountExecutiveController 
* Description  :  Apex Class for addAccountExecutive aura component
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Pavithra P				08-21-2024             US124701 : [Continued] [Continued] [Unplanned] - Update - Salesforce Assign Multiple Salespeople to an Account and Sales Orders
*************************************************************************************************/
public class AddAccountExecutiveController {
    
    @AuraEnabled
    public static void addMultipleAccountExecutives(string AccountId, string AccountExecutiveIds){
        
        list<Id> setOfSalesPersonIds = new list<Id>();
        if(AccountExecutiveIds !=  null){            
            setOfSalesPersonIds.addall(AccountExecutiveIds.split(','));            
        }else{            
            Account updateAccount = new Account();
            updateAccount.Id = AccountId;
            updateAccount.Account_Executives__c = null;
            updateAccount.Account_Executive_ids__c = null;
            update updateAccount;
            
        }
         
        String hyperlinks = '';
        integer count = 0;
        integer totalSalesPersons = setOfSalesPersonIds.size();
        
        if(!setOfSalesPersonIds.isEmpty()){
            Map<Id, Salesperson__c> AccountExecutiveMap = new Map<Id, Salesperson__c>([SELECT Id, Name FROM Salesperson__c WHERE Id IN :setOfSalesPersonIds]);
            String baseUrl = URL.getOrgDomainURL().toExternalForm();
            for (String salesPersonId : setOfSalesPersonIds) {
                Salesperson__c salesPerson = AccountExecutiveMap.get(salesPersonId);
                if (salesPerson != null) {
                    String recordUrl = baseUrl + '/' + salesPerson.Id;
                    String hyperlink = '<a href="' + recordUrl + '">' + salesPerson.Name + '</a>';
                    hyperlinks += hyperlink;
                    // Append a comma if it's not the last record
                    if (count < totalSalesPersons - 1) {
                        hyperlinks += ', ';
                    }
                }
                count++;
            }                
        }
        Account updateAccount = new Account();
        updateAccount.Id = AccountId;
        updateAccount.Account_Executives__c = hyperlinks;
        updateAccount.Account_Executive_ids__c = AccountExecutiveIds;
        update updateAccount;        
    }
    
    @AuraEnabled
    public static List<SalesPerson__c> getAccountExecutives(String accountId){
        List<Salesperson__c> accountExecutivesList = new List<Salesperson__c>();
        if(accountId != null){
            Account accRecord = [SELECT Id,Name,Account_Executive_ids__c FROM Account WHERE Id =: accountId];
            if(accRecord.Account_Executive_ids__c != null){
                List<Id> relatedIds = accRecord.Account_Executive_ids__c.split(',');
                accountExecutivesList = [SELECT Id,Name FROM Salesperson__c WHERE Id IN: relatedIds];
            }  
        }
        return accountExecutivesList;
    }
}