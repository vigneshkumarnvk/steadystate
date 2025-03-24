public class SalesInvoices extends fflib_SObjectDomain implements ISalesInvoices{
    public static ISalesInvoices newInstance(List<Sales_Invoice__c> sObjectList){
        return (ISalesInvoices) Application.Domain.newInstance(sObjectList);
    }

    public SalesInvoices(List<Sales_Invoice__c> sObjectList){
        super(sObjectList);
    }
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct (List<SObject> sObjectList){
            return new SalesInvoices(sObjectList);
        }
    }

    public override void onAfterUpdate(Map<Id, SObject> existingRecords) {
        List<Sales_Invoice__c> newRecords = (List<Sales_Invoice__c>) Records;
        Set<Id> approvalRecordIds = new Set<Id>();

        for (Sales_Invoice__c record : newRecords) {
            if(record.Approval_Step_Completed__c == true && record.Approval_Status__c == EnumUtil.ApprovalStatus.PENDING_APPROVAL.name())
                approvalRecordIds.add(record.Id);
        }

        if(approvalRecordIds.size() > 0){
            fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();

            if(approvalRecordIds.size() > 0 && CompanyMgmt.approvalCall != true){
                CompanyMgmt.approvalCall = true;
                List<Sales_Invoice__c> invoiceRecords = SalesInvoicesSelector.newInstance().selectByIdWithSILines(approvalRecordIds);
                for(Sales_Invoice__c invoiceRecord:invoiceRecords){
                    System.debug('Info: Trigger Approve Record!');
                    InvoiceRecordApprovalProcess invoiceRecordApprovalProcess = new InvoiceRecordApprovalProcess(invoiceRecord);
                    invoiceRecordApprovalProcess.approveRecord();
                }
                uow.registerDirty(invoiceRecords);
            }

            // This should be call at last
            uow.commitWork();
        }
    }

    public void updateCustomerPONumber(Map<Id, String> poToUpdateBySOIds, fflib_ISObjectUnitOfWork uow) {
        for (Sales_Invoice__c theSI : (List<Sales_Invoice__c>) Records) {
            theSI.Customer_PO_No__c = poToUpdateBySOIds.get(theSI.Sales_Order__c);
            uow.registerDirty(theSI);
        }
    }
}