/*
* Class Name: SFJobBillingProjectUpdateJSON
* Summary  : Update Details format send to EQAI

* Modification Log :
* Developer                 Date                   Description
--------------------------------------------------------------------------------------------------------------               
Sathish Rosekumar           30/04/2024         79107: new billing project within EQAI from Salesforce "Job Billing Project"
*************************************************************************************************************/
public class SFJobBillingProjectUpdateJSON {
    Public String Employee_id;
    Public String SalesforceJobBillingProjectCsid;
    Public DateTime SalesforceSalesorderCloseDate;
    public SFJobBillingProjectUpdateJSON(Sales_order__c salesOrderRec, String employeeId){
        this.Employee_id = employeeId;
        this.SalesforceJobBillingProjectCsid = salesOrderRec.CSID__c;
        this.SalesforceSalesorderCloseDate = System.today();
    }
}