/*  Ticket#19931
 *      - add Resource_Type__r.Rental_Resource_Type__c to queries.
 *  Ticket#19992
 *      - add xLine_Amount__c
 */
public class SalesInvoiceLinesSelector extends fflib_SObjectSelector implements ISalesInvoiceLinesSelector {

    public static ISalesInvoiceLinesSelector newInstance(){
        return (ISalesInvoiceLinesSelector) Application.Selector.newInstance(Sales_Invoice_Line__c.SObjectType);
    }

    public SObjectType getSObjectType(){
        return Sales_Invoice_Line__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
                Sales_Invoice_Line__c.Id,
                Sales_Invoice_Line__c.Sales_Invoice__c,
                Sales_Invoice_Line__c.Name,
                Sales_Invoice_Line__c.Line_No__c,
                Sales_Invoice_Line__c.Category__c,
                Sales_Invoice_Line__c.Resource__c,
                Sales_Invoice_Line__c.Resource_Type__c,
                Sales_Invoice_Line__c.Quantity__c,
                Sales_Invoice_Line__c.Unit_of_Measure__c,
                Sales_Invoice_Line__c.Resource_UOM__c,
                Sales_Invoice_Line__c.Resource_Type_UOM__c,
                Sales_Invoice_Line__c.Unit_Price__c,
                Sales_Invoice_Line__c.Unit_Cost__c,
                Sales_Invoice_Line__c.Cost_Qty__c,
                Sales_Invoice_Line__c.Cost_UOM__c,
                Sales_Invoice_Line__c.Container_Size__c,
                Sales_Invoice_Line__c.Contract_Line__c,
                Sales_Invoice_Line__c.Cost_Method__c,
                Sales_Invoice_Line__c.Line_Amount__c,
                Sales_Invoice_Line__c.Line_Amt_Incl_Tax__c,
                Sales_Invoice_Line__c.Line_Cost__c,
                Sales_Invoice_Line__c.Cost_Qty__c,
                Sales_Invoice_Line__c.BOL_Manifest__c,
                Sales_Invoice_Line__c.Bill_as_Lump_Sum__c,
                Sales_Invoice_Line__c.Non_Billable__c,
                Sales_Invoice_Line__c.TM__c,
                Sales_Invoice_Line__c.TM_Line__c,
                Sales_Invoice_Line__c.xUnit_Price__c,
                Sales_Invoice_Line__c.Description__c,
                Sales_Invoice_Line__c.Pricing_Source_2__c,
                Sales_Invoice_Line__c.Tax__c,
                Sales_Invoice_Line__c.Tax_Pct__c,
                Sales_Invoice_Line__c.Tax_Group__c,
                Sales_Invoice_Line__c.Scheduled_Date__c,
                //Sales_Invoice_Line__c.Parent_Record_Line__c,
                Sales_Invoice_Line__c.Service_Center__c,
                Sales_Invoice_Line__c.System_Calculated_Line__c,
                //Sales_Invoice_Line__c.Line_Updated_by_Worksheet__c,
                Sales_Invoice_Line__c.Time_Rate_Code__c,
                Sales_Invoice_Line__c.Facility__c,
                Sales_Invoice_Line__c.Inter_Company_Resource__c,
                Sales_Invoice_Line__c.Min_Sell_Qty__c,
                Sales_Invoice_Line__c.Overtime__c,
                Sales_Invoice_Line__c.Qty_to_Display__c,
                Sales_Invoice_Line__c.Unit_Weight_Vol__c,
                Sales_Invoice_Line__c.Tax_Reverse_Line__c,
                Sales_Invoice_Line__c.Sales_Invoice_Job_Task__c,
                Sales_Invoice_Line__c.Billing_Worksheet_Line__c,                
                Sales_Invoice_Line__c.Print_Line__c,
                Sales_Invoice_Line__c.xLine_Amount__c,
                Sales_Invoice_Line__c.Approval_Id__c,
                Sales_Invoice_Line__c.Disposal_Billing_Method__c,
                Sales_Invoice_Line__c.LastModifiedDate //Ticket#22853
        };
    }

    public List<Sales_Invoice_Line__c> selectByIds(Set<Id> ids){
        return (List<Sales_Invoice_Line__c>) Database.query(newQueryFactory().setCondition('Id IN :ids').toSOQL());
    }

    public  List<Sales_Invoice_Line__c> selectByInvoiceId(Id id){
        return (List<Sales_Invoice_Line__c>) Database.query(newQueryFactory()
                .selectField('Resource_Type__r.Fuel_Fired_Equipment__c')
                .selectField('Resource_Type__r.Fleet_No_Required__c')
                .selectField('Resource_Type__r.Rental_Resource_Type__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Resource_Type__c')
                .selectField('Resource__r.Name')
                .selectField('Resource__r.Description__c')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('TM__r.Name')
                .selectField('TM__r.Service_Center__r.Advanced_Disposal__c')                                            
                .selectField('Service_Center__r.Name')
                .selectField('Service_Center__r.Advanced_Disposal__c')                                            
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Sales_Invoice__r.Bill_to_Customer__c')
                .selectField('Contract_Line__r.Name')
                .selectField('Contract_Line__r.Regular_Rate__c')
                .selectField('Service_Center__r.Name')
                .selectField('Resource_Type__r.Fuel_Fired_Equipment__c')
                .selectField('Resource_Type__r.Fleet_No_Required__c')
                .selectField('Resource__r.Resource_Type__r.Fleet_No_Required__c')
                .selectField('Resource__r.Resource_Type__r.Rental_Resource_Type__c')
                .selectField('Facility__r.Name')
                .selectField('Billing_Worksheet_Line__r.Line_No__c')
                //job task <<
                .selectField('TM__r.Scheduled_Date__c')
                .selectField('Sales_Invoice_Job_Task__r.Name')
                .selectField('Sales_Invoice_Job_Task__r.Line_No__c')
                .selectField('Sales_Invoice_Job_Task__r.Billing_Type__c')
                .selectField('Sales_Invoice_Job_Task__r.Sales_Order_Job_Task__c')
                .selectField('TM_Line__r.Name')
                .selectField('Billing_Worksheet_Line__r.Line_No__c')
                .selectField('Bundle_Line__r.Line_No__c')
                //job task >>
                .setCondition('Sales_Invoice__c = :id')
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING,true)
                .toSOQL());
    }

    public  List<Sales_Invoice_Line__c> selectLinesByInvoiceId(Id id){
        return (List<Sales_Invoice_Line__c>) Database.query(newQueryFactory(false)
                .selectField('Id')
                .selectField('Description__c')
                .selectField('Quantity__c')
                .selectField('Unit_of_Measure__c')
                .selectField('Unit_Price__c')
                .selectField('Tax_Group__c')
                .selectField('Line_Amount__c')
                .selectField('Line_Amt_Incl_Tax__c')
                .selectField('Category__c')
                .selectField('Resource_Type__c')
                .selectField('Resource__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Resource__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Line_Cost__c')
                .selectField('Scheduled_Date__c')
                .selectField('BOL_Manifest__c')
                .selectField('Non_Billable__c')
                .selectField('Bill_as_Lump_Sum__c')
                .setCondition('Sales_Invoice__c = :id')
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING,true)
                .toSOQL());
    }

    //Invoice Versioning >>
    public  List<Sales_Invoice_Line__c> selectByInvoiceIds(Set<Id> idSet){
        return (List<Sales_Invoice_Line__c>) Database.query(newQueryFactory()
                .setCondition('Sales_Invoice__c IN :idSet')
                .toSOQL());
    }

    public List<Sales_Invoice_Line__c> selectPostedInvoiceLinesByTMLineIds(Set<Id> tmLineIds){
        return (List<Sales_Invoice_Line__c>) Database.query(newQueryFactory()
                .selectField('Sales_Invoice__r.Name')
                .selectField('Sales_Invoice__r.Document_Status__c')
                .selectField('Sales_Invoice__r.Credit_Memo__c')
                .selectField('Sales_Invoice__r.Worksheet__c')
                .selectField('Sales_Invoice__r.Misc_Invoice__c')
                .setCondition('TM_Line__c IN :tmLineIds AND ' +
                        'Sales_Invoice__r.Document_Status__c != \'Void\' AND ' +
                        'Sales_Invoice__r.Credit_Memo__c = FALSE AND ' +
                        'Sales_Invoice__r.Misc_Invoice__c = FALSE AND ' +
                        'Sales_Invoice__r.Worksheet__c = FALSE').toSOQL());
        //'Sales_Invoice__r.Document_Status__c != \'Void\' AND ' +
    }
    //Invoice Versioning <<

    public List<Sales_Invoice_Line__c> selectApprovedCreditMemoWorksheetByTMLineIds(Set<Id> tmLineIds){
        fflib_QueryFactory queryFactory = newQueryFactory();
        queryFactory.selectField('Sales_Invoice__r.Name')
                .selectField('TM_Line__c')
                .selectField('Sales_Invoice__r.Document_Status__c')
                .selectField('Sales_Invoice__r.Worksheet__c')
                .selectField('Sales_Invoice__r.Credit_Memo__c')
                .selectField('Sales_Invoice__r.Misc_Invoice__c')
                .selectField('Sales_Invoice__r.Approved_Profit_Margin__c')
                .selectField('Sales_Invoice__r.Approval_Status__c')
                .selectField('Sales_Invoice__r.CreatedDate')
                .selectField('Unit_of_Measure__r.Name')
                .setCondition('Sales_Invoice__r.Credit_Memo__c = FALSE AND ' +
                'Sales_Invoice__r.Misc_Invoice__c = FALSE AND ' +
                'Sales_Invoice__r.Worksheet__c = TRUE AND ' +
                'Sales_Invoice__r.Approval_Status__c = \'Approved\' AND ' +
                'TM_Line__c IN :tmLineIds')
                .setOrdering('Sales_Invoice__r.CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING,true)
                .setLimit(1);
        return (List<Sales_Invoice_Line__c>) Database.query(queryFactory.toSOQL());
    }

}