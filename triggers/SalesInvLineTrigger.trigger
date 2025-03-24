trigger SalesInvLineTrigger on Sales_Invoice_Line__c (before insert, before update, before delete, after insert, after update, after delete) {
    if (CompanyMgmt.byPassTrigger == true) return; 

    if (Trigger.isBefore) {
        if (Trigger.isDelete == false) {
            List<Sales_Invoice_Line__c> SILList = Trigger.new;
            SalesInvoiceTriggersMgmt.SILInsertUpdate(SILList);
        } else {
            if (CompanyMgmt.systemCall != true) {
                if (Trigger.old.size() > 0) {
                    Company_Setup__c defaultCompanySetup = CompanySettingUtil.defaultCompanySetup;
                    for (Sales_Invoice_Line__c salesInvoiceLine : Trigger.old) {
                        if (salesInvoiceLine.Resource__c != defaultCompanySetup.Default_Fuel_Surcharge_Resource__c &&
                                salesInvoiceLine.Resource__c != defaultCompanySetup.Default_Energy_Insurance_Resource__c) {
                            Trigger.old[0].addError('Deleting invoice line is not allowed!');
                        }
                    }
                }
            }
        }
    }
    else if (Trigger.isAfter) {
        //job task <<
        //causing query 101 error move to SalesInvoiceTrigger when there a lot of lines to process.
        /*
        List<Sales_Invoice_Line__c> SILList;
        if (Trigger.isInsert || Trigger.isUpdate) {
            SILList = Trigger.new;
        }
        else if (Trigger.isDelete) {
            SILList = (Trigger.old);
        }
        SalesInvoiceTriggersMgmt.updateTMInvoiceRelations(SILList);
        */
        //job task >>
    }
}