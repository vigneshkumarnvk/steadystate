public with sharing class SalesInvoiceUnitCostUpdateController {
    private final ApexPages.StandardSetController controller;
    
    public SalesInvoiceUnitCostUpdateController(ApexPages.StandardSetController controller) {
        this.controller = controller;
    }
    
    public PageReference UpdateUnitCost() {
        try {
            List<AsyncApexJob> apexJobs = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus from AsyncApexJob where ApexClass.Name = 'Sales Invoice Unit Cost Update' AND Status <> 'Aborted' AND Status <> 'Completed' AND Status <> 'Failed'];
            if (apexJobs.size() > 0) {
                throw new RunTimeException('There is already a sales invoice unit cost update job in progress. You cannot run sales invoice unit cost update before the current job finishes.');
            }
            SILUnitCostUpdateBatchable batch = new SILUnitCostUpdateBatchable();
            database.executeBatch(batch, 100);
            
            return new ApexPages.Action('{!List}').invoke();
        }
        catch(exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }
    }
    
    public class RunTimeException extends exception {} 
}