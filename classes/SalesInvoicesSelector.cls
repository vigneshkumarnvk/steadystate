/*************************************************************************************************
* Name         :  SalesInvoicesSelector
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan      12-14-2023             Task75275: Salesforce - Remove or disable the below on the Sales Invoice Object
*                                                  Ticket#19931: add Resource_Type__r.Rental_Resource_Type__c to queries.
* Sathish Rosekumar         12-20-2023             Task75285: add Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c
* Yuvraj Ganesan            02-10-2025             US139234 - Added Bill_To_Customer__r.Sage_Customer_No__c
***********************************************************************************************/
public class SalesInvoicesSelector extends fflib_SObjectSelector implements ISalesInvoicesSelector{

    public static ISalesInvoicesSelector newInstance(){
        return (ISalesInvoicesSelector) Application.Selector.newInstance(Sales_Invoice__c.SObjectType);
    }

    public SObjectType getSObjectType() {
        return Sales_Invoice__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
                Sales_Invoice__c.Id,
                Sales_Invoice__c.Name,
                Sales_Invoice__c.OwnerId,
                Sales_Invoice__c.Parent_Record__c,
                Sales_Invoice__c.Rental_Invoice__c,
                Sales_Invoice__c.Subsidiary_Company__c,
                Sales_Invoice__c.Service_Center__c,
                Sales_Invoice__c.Bill_to_Customer__c,
                Sales_Invoice__c.Salesperson__c,
                Sales_Invoice__c.Sales_Order__c,
                Sales_Invoice__c.Account_Executive__c,
                Sales_Invoice__c.Contract__c,
                Sales_Invoice__c.Completed_Date__c,
                Sales_Invoice__c.Sync_d__c,
                //Sales_Invoice__c.Pay_Rule__c,
                Sales_Invoice__c.Worksheet__c,
                Sales_Invoice__c.Street__c,
                Sales_Invoice__c.City__c,
                Sales_Invoice__c.State__c,
                Sales_Invoice__c.Postal_Code__c,
                Sales_Invoice__c.Country__c,
                Sales_Invoice__c.Site_Name__c,
                Sales_Invoice__c.Site_Street__c,
                Sales_Invoice__c.Site_City__c,
                Sales_Invoice__c.Site_State__c,
                Sales_Invoice__c.Site_Postal_Code__c,
                Sales_Invoice__c.Site_Country__c,
                Sales_Invoice__c.Site_Contact__c,
                Sales_Invoice__c.Site_Contact_2__c,
                Sales_Invoice__c.Site_Email_Address__c,
                Sales_Invoice__c.Site_Phone_No__c,
                Sales_Invoice__c.Tax_Area__c,
                Sales_Invoice__c.Tax_Liable__c,
                Sales_Invoice__c.Invoice_Date__c,
                Sales_Invoice__c.Payment_Term__c,
                Sales_Invoice__c.Posting_Date__c,
                Sales_Invoice__c.Due_Date__c,
                Sales_Invoice__c.Surcharge_Pct__c,
                Sales_Invoice__c.Surcharge_Type__c,
                Sales_Invoice__c.Surcharge_Amount__c,
                Sales_Invoice__c.Surcharge_Amt_Incl_Tax__c,
                Sales_Invoice__c.Misc_Invoice__c,
                Sales_Invoice__c.Credit_Memo__c,
                Sales_Invoice__c.Credit_Memo_Reason_Code__c,
                Sales_Invoice__c.SPO_No__c,
                Sales_Invoice__c.Expected_Payment_Date__c,
                Sales_Invoice__c.Contact__c,
                Sales_Invoice__c.Corrected_Customer_PO_No__c,
                Sales_Invoice__c.Site_Scope__c,
                Sales_Invoice__c.Billing_Instructions__c,
                Sales_Invoice__c.Internal_Comments__c,
                //Sales_Invoice__c.Credit_Memo_Note__c,
                Sales_Invoice__c.Invoice_Note__c,
                Sales_Invoice__c.Customer_PO_No__c,
                Sales_Invoice__c.Document_Status__c,
                Sales_Invoice__c.Approved_Profit_Margin__c,
                Sales_Invoice__c.Approved__c,
                Sales_Invoice__c.Approval_Step_Completed__c,
                Sales_Invoice__c.Approved_Level__c,
                Sales_Invoice__c.Approved_Amount__c,
                Sales_Invoice__c.Approval_Status__c,
                Sales_Invoice__c.Pending_Approval_Level__c,
                Sales_Invoice__c.Pending_Approval_From__c,
                Sales_Invoice__c.Invoice_Cost__c,
                Sales_Invoice__c.Invoice_Profit_Prct__c,
                Sales_Invoice__c.Invoice_Profit__c,
                Sales_Invoice__c.Invoice_Amount__c,
                Sales_Invoice__c.Invoice_Amt_Incl_Tax__c,
                Sales_Invoice__c.Balance__c,
                Sales_Invoice__c.Approval_Date__c,
                Sales_Invoice__c.Invoice_Tax__c,
                Sales_Invoice__c.NT_Amount__c,
                Sales_Invoice__c.Region__c,
                Sales_Invoice__c.Reversed_from_SI__c,
                Sales_Invoice__c.Reversed_by_CM_No__c,
                Sales_Invoice__c.Reversed__c,                
                Sales_Invoice__c.Contract_Name__c,
                Sales_Invoice__c.Sales_Order_type__c,
                Sales_Invoice__c.Sales_Order_Type_Description__c,
                Sales_Invoice__c.Retainage_Amount__c,
                Sales_Invoice__c.Retainage_Pct__c,
                Sales_Invoice__c.Retainage_Invoice__c,
                Sales_Invoice__c.Sales_invoice_Posted_Date__c,
                Sales_Invoice__c.Sales_Invoice_Status__c,
                Sales_Invoice__c.Customer_Billing_Instructions__c,
                Sales_Invoice__c.Document_Type__c,                
                Sales_Invoice__c.LastModifiedDate, //Ticket#22853
                Sales_Invoice__c.Operating_Expense_Cost_Pct__c //Ticket#24560
        };
    }

    public List<Sales_Invoice__c> selectById(Set<Id> idSet) {
        return (List<Sales_Invoice__c>) Database.query(
                newQueryFactory()
                        .selectField('Bill_To_Customer__r.Name')
                        .selectField('Bill_To_Customer__r.Sage_Customer_No__c')//US139234
                        .selectField('Tax_Area__r.Name')
                        .selectField('Contact__r.Name')
                        .selectField('Contact__r.Blocked__c') //Ticket#21357
                        .selectField('Account_Executive__r.Name')
                        .selectField('Salesperson__r.Name')
                        .selectField('Sales_Order__r.Name')
                        .selectField('Payment_Term__r.Name')
                        .selectField('Bill_to_Customer__r.AccountNumber')
                        .selectField('Service_Center__r.Remittance_Name__c')
                        .selectField('Service_Center__r.Remittance_Address_1__c')
                        .selectField('Service_Center__r.Remittance_Address_2__c')
                        .selectField('Service_Center__r.Remittance_Phone__c')
                        .selectField('Service_Center__r.EFT_To_Bank_Name__c')
                        .selectField('Service_Center__r.EFT_Address_1__c')
                        .selectField('Service_Center__r.EFT_Address_2__c')
                        .selectField('Service_Center__r.Checking_Account_1__c')
                        .selectField('Service_Center__r.Checking_Account_2__c')
            			.selectField('Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c') //75285 && 75284
            			.selectField('Service_Center__r.Advanced_Disposal__c')
                        .selectField('Contract__r.Override_Remittance_on_Invoice__c')
                        .selectField('Contract__r.Remittance_Name__c')
                        .selectField('Contract__r.Remittance_Address_1__c')
                        .selectField('Contract__r.Remittance_Address_2__c')
                        .selectField('Contract__r.EFT_To_Bank_Name__c')
                        .selectField('Contract__r.EFT_Address_1__c')
                        .selectField('Contract__r.EFT_Address_2__c')
                        .selectField('Contract__r.Checking_Account_1__c')
                        .selectField('Contract__r.Checking_Account_2__c')
                        .selectField('Contract__r.Remittance_Phone__c')
                        .selectField('Contract__r.Logo__c')
                        .selectField('Contract__r.Billing_Rule__c')
                        .selectField('Service_Center__r.Override_Remittance_on_Invoice__c')
                        .selectField('Service_Center__r.Logo__c')
                        .selectField('Tax_Area__r.Sales_Tax_Account__c')
                        .selectField('Sales_Order__r.CMR_Description__c')
                        .selectField('Bill_to_Customer__r.Inter_co_Account__c')
                        .selectField('Bill_to_Customer__r.Inter_co_Revenue_Account__c')
                        .selectField('Bill_to_Customer__r.Inter_co_AR_Account__c')
                        .selectField('Bill_to_Customer__r.InterCo__c') //Ticket#21211
                        .selectField('Bill_to_Customer__r.Contact_Type_Filter__c') //Ticket#21357
                        .selectField('Bill_to_Customer__r.Subsidiary_Company__r.Watermark__c') //Ticket#21540
                        .selectField('Bill_to_Customer__r.Subsidiary_Company__c') //Ticket#21540
                        .selectField('Bill_to_Customer__r.Subsidiary_Company__r.Website__c') //Ticket#21540
                        .selectField('Bill_to_Customer__r.MsgRetailNational__c') // US119454
                        .selectField('Bill_to_Customer__r.MSG__c')
            			.selectField('Bill_to_Customer__r.Retail__c')
            			.selectField('Bill_to_Customer__r.National_Account__c')
            			.selectField('Reversed_from_SI__r.Name')
                        .selectField('Service_Center__r.Name')
                        .selectField('Site_Contact_2__r.Name')
                        .selectField('Reversed_from_SI__r.Retainage_Invoice__c')
                        .selectField('Reversed_from_SI__r.Balance__c')
            			//.selectField('Document_Status__c')
                        //job task <<
                        .selectField('Reversed_by_CM_No__r.Name')
                        //job task >>
                        .selectField('Bill_to_Customer__r.Prevent_Billing_Project__c')
                        .setCondition('Id IN :idSet').toSOQL());
    }

    public List<Sales_Invoice__c> selectLineCountById(Set<Id> idSet) {
        return (List<Sales_Invoice__c>) Database.query(
                newQueryFactory(false).
                        selectField('Id').
                        selectField('Invoice_Lines__c').
                        setCondition('Id IN :idSet').
                        toSOQL());
    }
    public List<Sales_Invoice__c> selectByIdWithSILines(Set<Id> idSet) {
        fflib_QueryFactory invoiceQueryFactory = newQueryFactory();
        new SalesInvoiceLinesSelector().addQueryFactorySubselect(invoiceQueryFactory)
                .selectField('Resource_Type__r.Fuel_Fired_Equipment__c')
                .selectField('Resource_Type__c.Fleet_No_Required__c')
                .selectField('Resource_Type__c.Rental_Resource_Type__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Resource__r.Name')
                .selectField('TM__r.Name')
                .selectField('Service_Center__r.Name')
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING,true);
                invoiceQueryFactory.selectField('Bill_to_Customer__r.Name')
                .selectField('Service_Center__r.Name')
                .selectField('Sales_Order__r.Approval_Status__c')
                .selectField('Sales_Order__r.Approved_Profit_Margin__c')
                .selectField('Sales_Order__r.Sales_Order_Type__c')
                .selectField('Sales_Order__r.Owner.Name')
                .selectField('CreatedBy.Name')
                .setCondition('Id IN :idSet');
        return (List<Sales_Invoice__c>) Database.query(invoiceQueryFactory.toSOQL());
    }


    public List<Sales_Invoice__c> selectByIdWithSILinesForReverse(Set<Id> idSet) {
        fflib_QueryFactory invoiceQueryFactory = newQueryFactory();
        new SalesInvoiceLinesSelector().addQueryFactorySubselect(invoiceQueryFactory)
                .selectField('TM__r.Name')
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING,true);
        invoiceQueryFactory.setCondition('Id IN :idSet');
        return (List<Sales_Invoice__c>) Database.query(invoiceQueryFactory.toSOQL());
    }

    public List<Sales_Invoice__c> selectPOBySalesOrderId(Set<Id> idSet) {
        return (List<Sales_Invoice__c>) Database.query(
                newQueryFactory(false).
                        selectField('Id').
                        selectField('Sales_Order__c').
                        selectField('Customer_PO_No__c').
                        setCondition('Sales_Order__c IN :idSet AND ' +
                                'Document_Status__c <> \'Posted\' ').toSOQL());
    }

    public List<Sales_Invoice__c> selectOpenCreditMemoWorksheetWithLines(Id id){
        fflib_QueryFactory openWorksheetQF = newQueryFactory();
        new SalesInvoiceLinesSelector().addQueryFactorySubselect(openWorksheetQF)
                .selectField('Resource_Type__r.Fuel_Fired_Equipment__c')
                .selectField('Resource_Type__c.Fleet_No_Required__c')
                .selectField('Resource_Type__c.Rental_Resource_Type__c')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Resource_Type__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('TM__r.Name')
                .selectField('Service_Center__r.Name')
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true);
        openWorksheetQF.setCondition('Parent_Record__c = :id AND Worksheet__c = TRUE AND Approval_Status__c = \'Pending_Approval\'');
        return (List<Sales_Invoice__c>) Database.query(openWorksheetQF.toSOQL());
    }

    public List<Sales_Invoice__c> selectCreditMemoWorksheetsWithChangedLines(Id crWorksheetId){
        fflib_QueryFactory worksheetQueryFactory = newQueryFactory();
        new SalesInvoiceLinesSelector().addQueryFactorySubselect(worksheetQueryFactory)
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Resource_Type__c.Fleet_No_Required__c')
                .selectField('Resource_Type__c.Rental_Resource_Type__c')
                .setCondition('Line_Updated_by_Worksheet__c=true OR System_Calculated_Line__c=false');
        worksheetQueryFactory.setCondition('Id = :crWorksheetId');
        return (List<Sales_Invoice__c>) Database.query(worksheetQueryFactory.toSOQL());
    }

    public List<Sales_Invoice__c> selectByIdWithLinesAndProcessSteps(Set<Id> idSet) {
        fflib_QueryFactory invoiceQueryFactory = newQueryFactory();
        new SalesInvoiceLinesSelector().addQueryFactorySubselect(invoiceQueryFactory)
                .selectField('Resource_Type__r.Fuel_Fired_Equipment__c')
                .selectField('Resource_Type__c.Fleet_No_Required__c')
                .selectField('Resource_Type__c.Rental_Resource_Type__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Resource__r.Name')
                .selectField('TM__r.Name')
                .selectField('Service_Center__r.Name')
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING,true);
                invoiceQueryFactory.selectField('Bill_to_Customer__r.Name')
                .selectField('Service_Center__r.Name')
                .selectField('Sales_Order__r.Sales_Order_Type__c')
                .selectField('Sales_Order__r.Owner.Name')
                .selectField('Parent_Record__r.Name')
                .selectField('CreatedBy.Name')
                .setCondition('Id IN :idSet')
                .subselectQuery('ProcessSteps')
                    .selectField('Id')
                    .selectField('Actor.Name')
                    .selectField('OriginalActor.Name')
                    .selectField('StepStatus')
                    .selectField('Comments')
                    .selectField('CreatedDate')
                    .setCondition('Comments != null')
                    .setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING, true);
        return (List<Sales_Invoice__c>) Database.query(invoiceQueryFactory.toSOQL());
    }
}