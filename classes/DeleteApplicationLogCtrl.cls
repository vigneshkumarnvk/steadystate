/*************************************************************************************************
* Name         :  DeleteApplicationLogCtrl 
* Description  :  Delete one month old Application Logs records.
* Test class   :  DeleteApplicationLogCtrlTest

* Modification Log :
* Developer                   Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* 
*************************************************************************************************/
public class DeleteApplicationLogCtrl implements Database.Batchable<SObject>{
    
    // Query to retrieve records to delete
    public Database.QueryLocator start(Database.BatchableContext context) {
        
        string custom = label.deleteApplicationlog;//integer value from custom label
        Integer customlabel = integer.valueof(custom);
        Date daysBefore = System.today().addDays(-customlabel);//create date based on custom label  
        string toDelete = 'SELECT Id FROM Application_Debug_Log__c WHERE  CreatedDate <=: daysBefore';
        return Database.getQueryLocator(toDelete);
    }
    public void execute(Database.BatchableContext context, List<Application_Debug_Log__c> scope){
        
        if(scope != null){     
            delete scope;
        }
    }
    public void finish(Database.BatchableContext context){
        

        
    } 
}