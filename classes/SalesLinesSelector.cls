/*  Ticket#19931
 *      - add Resource_Type__r.Rental_Resource_Type__c to queries.
 *
 */
public class SalesLinesSelector extends fflib_SObjectSelector {

    public static SalesLinesSelector newInstance() {
        return (SalesLinesSelector) Application.Selector.newInstance(Sales_Line__c.SObjectType);
    }

    public Schema.SObjectType getSObjectType() {
        return Sales_Line__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
                Sales_Line__c.Bill_as_Lump_Sum__c,
                Sales_Line__c.Category__c,
                Sales_Line__c.Container_Size__c,
                Sales_Line__c.Contract_Line__c,
                Sales_Line__c.Contract_Overtime_Rate__c,
                Sales_Line__c.Contract_Premium_Rate__c,
                Sales_Line__c.Contract_Regular_Rate__c,
                Sales_Line__c.Cost_Method__c,
                Sales_Line__c.CreatedById,
                Sales_Line__c.CreatedDate,
                Sales_Line__c.Description__c,
                Sales_Line__c.Facility__c,
                Sales_Line__c.Id,
                Sales_Line__c.IsDeleted,
                Sales_Line__c.LastModifiedById,
                Sales_Line__c.LastModifiedDate,
                Sales_Line__c.LastReferencedDate,
                Sales_Line__c.LastViewedDate,
                Sales_Line__c.Line_Amount__c,
                Sales_Line__c.Line_Amt_Incl_Tax__c,
                Sales_Line__c.Line_Cost__c,
                Sales_Line__c.Line_No__c,
                Sales_Line__c.Manually_Entered_Cost__c,
                Sales_Line__c.Markup__c,
                Sales_Line__c.Markup_Option__c,
                Sales_Line__c.Min_Sell_Qty__c,
                Sales_Line__c.Name,
                Sales_Line__c.Non_Billable__c,
                Sales_Line__c.Number_of_Day__c,
                Sales_Line__c.Overtime_Day__c,
                Sales_Line__c.Overtime_Hours__c,
                Sales_Line__c.Overtime_Rate__c,
                Sales_Line__c.Premium_Day__c,
                Sales_Line__c.Premium_Hours__c,
                Sales_Line__c.Premium_Rate__c,
                Sales_Line__c.Pricing_Source_2__c,
                Sales_Line__c.Process_Code__c,
                Sales_Line__c.Profit_Margin__c,
                Sales_Line__c.Quote_Line__c,
                Sales_Line__c.Quantity__c,
                Sales_Line__c.Regular_Day__c,
                Sales_Line__c.Regular_Hours__c,
                Sales_Line__c.Regular_Rate__c,
                Sales_Line__c.Resource__c,
                Sales_Line__c.Resource_Type__c,
                Sales_Line__c.Resource_Type_UOM__c,
                Sales_Line__c.Resource_UOM__c,
                Sales_Line__c.Sales_Order__c,
                Sales_Line__c.Scheduled_Date__c,
                Sales_Line__c.System_Calculated_Line__c,
                Sales_Line__c.SystemModstamp,
                Sales_Line__c.Tax__c,
                Sales_Line__c.Approval_Id__c, 
                Sales_Line__c.Profile_Id__c,
                Sales_Line__c.Disposal_Billing_Method__c,
                Sales_Line__c.EQAI_UOM__c, 
                Sales_Line__c.Tax_Group__c,
                Sales_Line__c.Tax_Pct__c,
                Sales_Line__c.Unit_Cost__c,
                Sales_Line__c.Unit_of_Measure__c,
                Sales_Line__c.Unit_Price__c,
                Sales_Line__c.Unit_Weight_Vol__c,
                Sales_Line__c.UOM_Qty__c,
                Sales_Line__c.xOvertime_Rate__c,
                Sales_Line__c.xPremium_Rate__c,
                Sales_Line__c.xRegular_Rate__c,
                Sales_Line__c.xUnit_Price__c,
                //aura <<
                Sales_Line__c.xUnit_Cost__c,
                Sales_Line__c.Bundle_Line__c,
                Sales_Line__c.xLine_Amount__c,
                Sales_Line__c.xLine_Cost__c,
                Sales_Line__c.Rolled_up_Unit_Price__c,
                Sales_Line__c.Bundle_Pricing_Method__c,
                Sales_Line__c.Sales_Order_Job_Task__c,
                //Ticket#22710 >>
                Sales_Line__c.Regular_Unit_Cost__c,
                Sales_Line__c.Overtime_Unit_Cost__c,
                Sales_Line__c.Double_Time_Unit_Cost__c,
                /*
                Sales_Line__c.xOvertime_Unit_Cost__c,
                Sales_Line__c.xDouble_Time_Unit_Cost__c,
                Sales_Line__c.xRegular_Unit_Cost__c,
                 */
                //Ticket#22710 <<                
                //ticket 19130 <<
                //Sales_Line__c.Parent_Line__c,
                Sales_Line__c.Dereferenced_Child_Resource__c,
                //ticket 19130 >>
                Sales_Line__c.Is_Child_Resource__c,
                Sales_Line__c.Wizard_Question_Answered__c
                //job task >>
        };
    }

    public List<Sales_Line__c> selectLinesById(Set<Id> idSet) {
        return (List<Sales_Line__c>) Database.query(newQueryFactory()
                //aura <<
                .selectField('Resource__r.Name')
                .selectField('Resource__r.Allow_Zero_Unit_Cost_at_TM_Confirmation__c')
                .selectField('Resource__r.Allow_Manual_Unit_Cost_Adjustment__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Resource__r.Blocked__c')
                .selectField('Resource_Type__r.Blocked__c')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Facility__r.Name')
                .selectField('Quote_Line__r.Name')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Contract_Line__r.Name')
                //aura >>
                .setCondition('Id IN :idSet').toSOQL());
    }

    //job task <<
    /*
    public List<Sales_Line__c> selectLinesBySalesOrderId(Set<Id> idSet) {
        return (List<Sales_Line__c>) Database.query(newQueryFactory()
                .selectField('Resource__r.Name')
                .selectField('Resource_Type__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Facility__r.Name')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                //aura <<
                //.setCondition('Sales_Order__c IN :idSet').toSOQL());
                .selectField('Resource__r.Blocked__c')
                .selectField('Resource_Type__r.Blocked__c')
                .selectField('Resource__r.Name')
                .selectField('Resource_Type__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Facility__r.Name')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Quote_Line__r.Name')
                .selectField('Contract_Line__r.Name')
                .setCondition('Sales_Order__c IN :idSet')
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .addOrdering('Category__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .toSOQL());
                //aura >>
    }
    */

    public List<Sales_Line__c> selectLinesBySalesOrderId(Set<Id> idSet) {
        return selectLinesByJobTaskId(idSet, null);
    }

    public List<Sales_Line__c> selectLinesByJobTaskId(Set<Id> salesOrderIds, Set<Id> jobTaskIds) {
        List<String> filters = new List<String>();
        if (salesOrderIds != null) {
            filters.add('Sales_Order__c IN :salesOrderIds');
        }
        if (jobTaskIds != null && jobTaskIds.size() > 0) {
            filters.add('Sales_Order_Job_Task__c IN :jobTaskIds');
        }

        //ticket 19130 <<
        /*
        return (List<Sales_Line__c>) Database.query(newQueryFactory(true)
                .selectField('Resource__r.Name')
                .selectField('Resource__r.Has_Container__c')
                .selectField('Resource__r.Has_Weight_Volume__c')
                .selectField('Resource__r.Allow_Manual_Unit_Cost_Adjustment__c')                
                .selectField('Resource_Type__r.Name')
                .selectField('Resource_Type__r.Blocked__c')
                .selectField('Resource_Type__r.Fuel_Fired_Equipment__c')
                .selectField('Resource_Type__r.Fleet_No_Required__c')
                .selectField('Resource_Type__r.Rental_Resource_Type__c')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Facility__r.Name')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Resource__r.Blocked__c')
                .selectField('Resource__r.Name')
                .selectField('Resource_Type__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Facility__r.Name')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Quote_Line__r.Name')
                .selectField('Contract_Line__r.Name')
                .selectField('Contract_Line__r.Contract__r.Status') //Ticket#20749
                .selectField('Contract_Line__r.Contract__r.StartDate') //Ticket#20749
                .selectField('Contract_Line__r.Contract__r.EndDate') //Ticket#20749                
                .selectField('Bundle_Line__r.Line_No__c')
                .selectField('Sales_Order_Job_Task__r.Name')
                .selectField('Sales_Order_Job_Task__r.Line_No__c')
                .selectField('Sales_Order_Job_Task__r.Task_No__c')
                .selectField('Sales_Order__r.Name')
                .selectField('Parent_Line__r.Line_No__c')
                .selectField('Quote_Line__r.Sales_Order__c') //Ticket#23178
                .setCondition(String.join(filters, ' AND '))
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .addOrdering('Category__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .toSOQL());
        */
        fflib_QueryFactory queryFactory = newQueryFactory(true);
        queryFactory.selectField('Resource__r.Name')
                .selectField('Resource__r.Has_Container__c')
                .selectField('Resource__r.Has_Weight_Volume__c')
                .selectField('Resource__r.Allow_Manual_Unit_Cost_Adjustment__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Resource_Type__r.Blocked__c')
                .selectField('Resource_Type__r.Fuel_Fired_Equipment__c')
                .selectField('Resource_Type__c.Fleet_No_Required__c')
                .selectField('Resource_Type__r.Rental_Resource_Type__c')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Facility__r.Name')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Resource__r.Blocked__c')
                .selectField('Resource__r.Name')
                .selectField('Resource_Type__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Facility__r.Name')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Quote_Line__r.Name')
                .selectField('Contract_Line__r.Name')
                .selectField('Contract_Line__r.Contract__r.Status') //Ticket#20749
                .selectField('Contract_Line__r.Contract__r.StartDate') //Ticket#20749
                .selectField('Contract_Line__r.Contract__r.EndDate') //Ticket#20749
                .selectField('Bundle_Line__r.Line_No__c')
                .selectField('Sales_Order_Job_Task__r.Name')
                .selectField('Sales_Order_Job_Task__r.Line_No__c')
                .selectField('Sales_Order_Job_Task__r.Task_No__c')
                .selectField('Sales_Order__r.Name')
                .selectField('Quote_Line__r.Sales_Order__c') //Ticket#23178
                .setCondition(String.join(filters, ' AND '))
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .addOrdering('Category__c', fflib_QueryFactory.SortOrder.ASCENDING, true);
        queryFactory.subselectQuery('Sales_Child_Lines__r')
                .selectField('Id')
                .selectField('Parent_Line__c')
                .selectField('Parent_Line__r.Line_No__c')
                .selectField('Parent_Line__r.Category__c')
                .selectField('Parent_Line__r.Resource_Type__c')
                .selectField('Parent_Line__r.Resource__c')
                .selectField('Parent_Line__r.Description__c')
                .selectField('Child_Line__c')
                .selectField('Child_Line__r.Line_No__c')
                .selectField('Child_Line__r.Category__c')
                .selectField('Child_Line__r.Resource_Type__c')
                .selectField('Child_Line__r.Resource__c')
                .selectField('Child_Line__r.Description__c')
                .setOrdering('Child_Line__r.Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true);
        return Database.query(queryFactory.toSOQL());
        //ticket 19130 >>
    }
    //job task >>

    //job task <<
    /* not needed anymore
    public List<Sales_Line__c> selectLinesByJobTaskId(Id salesOrderId) {
        fflib_QueryFactory queryFactory = newQueryFactory()
            .selectField('Resource__r.Name')
            .selectField('Resource_Type__r.Name')
            .selectField('Unit_of_Measure__r.Name')
            .selectField('Facility__r.Name')
            .selectField('Unit_Weight_Vol__r.Name')
            .selectField('Container_Size__r.Name')
            .selectField('Resource__r.Blocked__c')
            .selectField('Resource_Type__r.Blocked__c')
            .selectField('Resource__r.Name')
            .selectField('Resource_Type__r.Name')
            .selectField('Unit_of_Measure__r.Name')
            .selectField('Unit_of_Measure__r.Hours_UOM__c')
            .selectField('Facility__r.Name')
            .selectField('Unit_Weight_Vol__r.Name')
            .selectField('Container_Size__r.Name')
            .selectField('Quote_Line__r.Name')
            .selectField('Contract_Line__r.Name')
            .selectField('Bundle_Line__r.Line_No__c')
            .selectField('Sales_Order_Job_Task__r.Line_No__c')
            .setCondition('Sales_Order__c = :salesOrderId')
            .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
            .addOrdering('Category__c', fflib_QueryFactory.SortOrder.ASCENDING, true);
        return (List<Sales_Line__c>) Database.query(queryFactory.toSOQL());
    }*/
    //job task >>

    //aura <<
    public List<Sales_Line__c> selectLinesWithDetailsBySalesOrderId(Set<Id> idSet) {
        fflib_QueryFactory queryFactory = newQueryFactory(true);
        queryFactory.selectField('Resource__r.Name')
                .selectField('Resource__r.Has_Container__c')
                .selectField('Resource__r.Has_Weight_Volume__c')
                .selectField('Resource__r.Allow_Manual_Unit_Cost_Adjustment__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Resource_Type__r.Description__c')
                .selectField('Resource__r.Description__c')
                .selectField('Facility__r.Name')
                .selectField('Facility__r.Third_Party_Facility__c')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Resource__r.Name')
                .selectField('Resource_Type__r.Name')
                //ticket 19861 <<
                .selectField('Resource__r.Blocked__c')
                .selectField('Resource_Type__r.Blocked__c')
                //ticket 19861 >>
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Resource_UOM__r.Name')
                .selectField('Resource_UOM__r.Unit_of_Measure__r.Name')
                .selectField('Resource_Type_UOM__r.Name')
                .selectField('Resource_Type_UOM__r.Unit_of_Measure__r.Name')
                .selectField('Quote_Line__r.Name')
                .selectField('Bundle_Line__r.Line_No__c')
                .selectField('Contract_Line__r.Name')
                .selectField('Contract_Line__r.Contract__c')
                .selectField('Contract_Line__r.Customer_Description__c')
                //job task <<
                .selectField('Sales_Order_Job_Task__r.Name')
                .selectField('Sales_Order_Job_Task__r.Line_No__c')
                //ticket 19130 <<
                //.selectField('Parent_Line__r.Line_No__c')
                //ticket 19130 >>
                //job task >>
                .setCondition('Sales_Order__c IN :idSet')
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .addOrdering('Category__c', fflib_QueryFactory.SortOrder.ASCENDING, true);
                //ticket 19535 <<
                //.subselectQuery('Sales_Line_Details__r')
                //ticket 19535 >>
        queryFactory.subselectQuery('Sales_Line_Details__r')
                .selectField('Id')
                .selectField('Sales_Line__c')
                //equipment schedule lines <<
                .selectField('Sales_Line__r.Category__c')
                //equipment schedule lines >>
                .selectField('Scheduled_Date__c')
                .selectField('Start_Time__c')
                .selectField('End_Time__c')
                .selectField('Quantity__c')
                .selectField('UOM_Qty__c')
                .selectField('Unit_of_Measure__c')
                //rate.code.fix <<
                .selectField('Unit_of_Measure__r.Name')
                //rate.code.fix >>
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Regular_Rate__c')
                .selectField('Overtime_Rate__c')
                .selectField('Premium_Rate__c')
                .selectField('Unit_Price__c')
                .selectField('Regular_Hours__c')
                .selectField('Overtime_Hours__c')
                .selectField('Premium_Hours__c')
                .selectField('Unit_Cost__c')
                .selectField('Line_Amount__c')
                .selectField('Line_Cost__c')
                //rate.code.fix <<
                .selectField('Day_Rate_Code__c')
                //rate.code.fix >>
                .selectField('Regular_Unit_Cost__c')
                .selectField('Overtime_Unit_Cost__c')
                .selectField('Double_Time_Unit_Cost__c')
                .setOrdering('Scheduled_Date__c', fflib_QueryFactory.SortOrder.ASCENDING, true);

        //ticket 19130 <<
        queryFactory.subselectQuery('Sales_Child_Lines__r')
                .selectField('Id')
                .selectField('Parent_Line__c')
                .selectField('Parent_Line__r.Line_No__c')
                .selectField('Parent_Line__r.Category__c')
                .selectField('Parent_Line__r.Resource_Type__c')
                .selectField('Parent_Line__r.Resource__c')
                .selectField('Parent_Line__r.Description__c')
                .selectField('Child_Line__c')
                .selectField('Child_Line__r.Line_No__c')
                .selectField('Child_Line__r.Category__c')
                .selectField('Child_Line__r.Resource_Type__c')
                .selectField('Child_Line__r.Resource__c')
                .selectField('Child_Line__r.Description__c')
                .setOrdering('Child_Line__r.Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true);
        //ticket 19130 >>

        //ticket 19535 << -- include TM Lines
        queryFactory.subselectQuery('T_M_Lines1__r')
                .selectField('Id')
                .setCondition('TM__r.Status__c != \'Void\'')
                .setLimit(1);
        //ticket 19535 >>
        String soql = queryFactory.toSOQL();

        soql = soql.replaceFirst('SELECT', 'SELECT toLabel(Category__c) CategoryName,'); //include category name

        return (List<Sales_Line__c>) Database.query(soql);
    }
    //aura >>

    //job task <<  Obsolete functions
    /*
    //aura <<
    public List<Sales_Line__c> selectLinesWithBundledLines(Set<Id> idSet) {
        fflib_QueryFactory queryFactory = newQueryFactory()
                .selectField('Resource__r.Name')
                .selectField('Resource_Type__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Facility__r.Name')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Quote_Line__r.Name')
                .setCondition('Sales_Order__c IN :idSet')
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .addOrdering('Category__c', fflib_QueryFactory.SortOrder.ASCENDING, true);

                queryFactory.subselectQuery('Bundle_Lines__r').selectFields(getSObjectFieldList())
                .selectField('Resource__r.Name')
                .selectField('Resource_Type__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Facility__r.Name')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Quote_Line__r.Name')
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .addOrdering('Category__c', fflib_QueryFactory.SortOrder.ASCENDING, true);


        return (List<Sales_Line__c>) Database.query(queryFactory.toSOQL());
    }
    public List<Sales_Line__c> selectBundledLines(Set<Id> idSet) {
        return (List<Sales_Line__c>) Database.query(newQueryFactory()
                .selectField('Resource__r.Name')
                .selectField('Resource_Type__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Facility__r.Name')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Quote_Line__r.Name')
                .setCondition('Bundle_Line__c IN :idSet')
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .addOrdering('Category__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .toSOQL());
    }

    public List<Sales_Line__c> selectUnbundledLines(Set<Id> idSet) {
        return (List<Sales_Line__c>) Database.query(newQueryFactory()
                .selectField('Resource__r.Name')
                .selectField('Resource_Type__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Facility__r.Name')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Quote_Line__r.Name')
                .setCondition('Sales_Order__c IN :idSet AND Bundle_Line__c = null')
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .addOrdering('Category__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .toSOQL());
    }
    //aura >>
    public List<Sales_Line__c> selectLinesBySalesOrderIdByCategory(Set<Id> idSet, Set<String> category) {
        return (List<Sales_Line__c>) Database.query(newQueryFactory()
        //aura <<
        .selectField('Unit_Weight_Vol__r.Name')
        .selectField('Resource_UOM__r.Name')
        .selectField('Resource_UOM__r.Unit_of_Measure__c')
        .selectField('Resource_UOM__r.Unit_of_Measure__r.Name')
        .selectField('Container_Size__r.Name')
        .selectField('Resource_UOM__r.Container_Size__c')
        .selectField('Resource_UOM__r.Container_Size__r.Name')
        .selectField('Resource__r.Name')
        .selectField('Resource_Type__r.Name')
        .selectField('Unit_of_Measure__r.Name')
        .selectField('Facility__r.Name')
        .selectField('Quote_Line__r.Name')
        //aura >>
        .setCondition('Sales_Order__c IN :idSet AND Category__c IN :category').toSOQL());
    }
    */
    //job task << obsolete functions

    //job task <<
    public List<Sales_Line__c> selectByCategories(Set<Id> salesOrderIds, Set<String> categories, List<String> filters) {
        fflib_QueryFactory queryFactory = newQueryFactory(true);
        queryFactory.selectField('Resource__r.Name')
                .selectField('Resource__r.Has_Container__c')
                .selectField('Resource__r.Has_Weight_Volume__c')
                .selectField('Resource__r.Allow_Manual_Unit_Cost_Adjustment__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Facility__r.Name')
                .selectField('Facility__r.Third_Party_Facility__c')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Resource__r.Name')
                .selectField('Resource__r.Allow_Zero_Unit_Cost_at_TM_Confirmation__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Resource_UOM__r.Name')
                .selectField('Resource_UOM__r.Unit_of_Measure__r.Name')
                .selectField('Resource_Type_UOM__r.Name')
                .selectField('Resource_Type_UOM__r.Unit_of_Measure__r.Name')
                .selectField('Quote_Line__r.Name')
                .selectField('Bundle_Line__r.Line_No__c')
                .selectField('Contract_Line__r.Name')
                .selectField('Contract_Line__r.Contract__c')
                .selectField('Contract_Line__r.Customer_Description__c')
                .selectField('Sales_Order_Job_Task__r.Name')
                .selectField('Sales_Order_Job_Task__r.Line_No__c');
                //ticket 19130 <<
                //.selectField('Parent_Line__r.Line_No__c');
                //ticket 19130 >>

        if (filters == null) {
            filters = new List<String>();
        }
        if (salesOrderIds != null) {
            filters.add('Sales_Order__c IN :salesOrderIds');
        }
        if (categories != null) {
            filters.add('Category__c IN :categories');
        }

        if (filters.size() > 0) {
            queryFactory.setCondition(String.join(filters, ' AND '));
        }
        queryFactory.addOrdering('Category__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .addOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true);

        String queryString = queryFactory.toSOQL();
        return (List<Sales_Line__c>) Database.query(queryString);
    }
    //job task >>

    public List<Sales_Line__c> selectSurchargeLinesBySalesOrderIdAndResId(Id salesOrderId, Set<Id> resIds){
        return (List<Sales_Line__c>) Database.query(newQueryFactory().
                setCondition('Sales_Order__c = :salesOrderId AND Resource__c IN :resIds').toSOQL());
    }

    public List<Sales_Line__c> selectSafetyPlanLineBySalesOrderId(Set<Id> idSet, Id resourceId) {
        return (List<Sales_Line__c>) Database.query(newQueryFactory(false).selectField('Sales_Order__c').selectField('Unit_Price__c').
                selectField('Id').selectField('Unit_Price__c').
                setCondition('Sales_Order__c IN :idSet AND Category__c=\'Misc. Charges And Taxes\' AND Resource__c = :resourceId').toSOQL());
    }
}