/*
 *  Ticket#19931
 *      - add Rental_Resource_Type__c
 * Pavithra Periyasamy    11-18-2023      DE36562: Salesforce - Disposal Billing Method selected in Sales Order prompts again in Billing Worksheet
 */
public class TMLinesSelector extends fflib_SObjectSelector implements ITMLinesSelector {

    public static ITMLinesSelector newInstance() {
        return (ITMLinesSelector) Application.Selector.newInstance(TM_Line__c.SObjectType);
    }

    public SObjectType getSObjectType() {
        return TM_Line__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
                TM_Line__c.TM__c,
                TM_Line__c.Id,
                TM_Line__c.Name,
                TM_Line__c.Line_No__c,
                TM_Line__c.Category__c,
                TM_Line__c.Service_Center__c,
                TM_Line__c.Resource_Type__c,
                TM_Line__c.Resource__c,
                TM_Line__c.Resource_Name__c,
                TM_Line__c.Description__c,
                TM_Line__c.Hour__c,
                TM_Line__c.Quantity__c,
                TM_Line__c.Unit_of_Measure__c,
                TM_Line__c.Resource_UOM__c,
                TM_Line__c.Resource_Type_UOM__c,
                TM_Line__c.Unit_Price__c,
                TM_Line__c.Unit_Cost__c,
                TM_Line__c.Cost_Qty__c,
                TM_Line__c.Line_Amount__c,
                TM_Line__c.Line_Cost__c,
                TM_Line__c.Line_Amt_Incl_Tax__c,
                TM_Line__c.Markup__c,
                TM_Line__c.Markup_Option__c,
                TM_Line__c.Tax_Pct__c,
                TM_Line__c.Tax_Group__c,
                TM_Line__c.Tax__c,
                TM_Line__c.Billing_Start_Time__c,
                TM_Line__c.Billing_End_Time__c,
                TM_Line__c.Bill_as_Lump_Sum__c,
                TM_Line__c.BOL_Manifest__c,
                TM_Line__c.Cost_Method__c,
                TM_Line__c.Container_Size__c,
                TM_Line__c.Contract_Line__c,
                TM_Line__c.Contract_Regular_Rate__c,
                TM_Line__c.Contract_Overtime_Rate__c,
                TM_Line__c.Contract_Premium_Rate__c,
                TM_Line__c.Drop_Off_Rental__c,
                TM_Line__c.Facility__c,
                TM_Line__c.Inter_Company_Resource__c,
                TM_Line__c.Include_Lunch_Y_N__c,
                TM_Line__c.Invoiced__c,
                TM_Line__c.Job_Start_Time__c,
                TM_Line__c.Job_End_Time__c,
                TM_Line__c.Lunch__c,
                TM_Line__c.Lunch_Start_Time__c,
                TM_Line__c.Lunch_End_Time__c,
                TM_Line__c.Min_Sell_Qty__c,
                TM_Line__c.Non_Billable__c,
                TM_Line__c.Overtime_Hours__c,
                TM_Line__c.Overtime_Rate__c,
                TM_Line__c.Premium_Hours__c,
                TM_Line__c.Premium_Rate__c,
                TM_Line__c.Pricing_Source_2__c,
                TM_Line__c.Regular_Hours__c,
                TM_Line__c.Regular_Rate__c,
                TM_Line__c.Rent_Billing_Type__c,
                TM_Line__c.Rent_Billing_Amount__c,
                TM_Line__c.Scheduled_Date__c,
                TM_Line__c.Sales_Line__c,
                TM_Line__c.Sales_Invoice_Line__c,
                TM_Line__c.Site_Start_Time__c,
                TM_Line__c.Site_End_Time__c,
                TM_Line__c.Unit_Weight_Vol__c,
                TM_Line__c.xUnit_Price__c,
                TM_Line__c.xRegular_Rate__c,
                TM_Line__c.xPremium_Rate__c,
                TM_Line__c.xOvertime_Rate__c,
                TM_Line__c.Bill_Site_Time__c,
                TM_Line__c.Total_Job_Hours__c,
                TM_Line__c.Total_Site_Hours__c,
                TM_Line__c.TM_Job_Task__c,
                TM_Line__c.Flat_Pay_Line__c,
                TM_Line__c.Sales_Bundle_Line__c,
                //ticket 19130 <<
                //TM_Line__c.Parent_Line__c,
                //ticket 19130 >>
                TM_Line__c.Is_Child_Resource__c,
                TM_Line__c.System_Calculated_Line__c,
                TM_Line__c.Fleet_No_Required__c,
                TM_Line__c.Fleet_No__c,
                TM_Line__c.Billing_Worksheet_Line__c,
                TM_Line__c.Wizard_Question_Answered__c,
                TM_Line__c.Quote_Line__c,
                TM_Line__c.Eligible_Dispatch_from_Home_Pay__c,
                TM_Line__c.Wizard_Question_Parent_Quantity__c,
                TM_Line__c.LastModifiedDate,
                TM_Line__c.CreatedDate, //Ticket#19586
                TM_Line__c.Travel_Hours__c, //PW Travel Cost
                TM_Line__c.KronosTimeEntriesProcessed__c, //Kronos
                TM_Line__c.Kronos_Integration_Note__c, //Kronos
                //ticket 19130 <<
                TM_Line__c.Profile_Id__c,
                TM_Line__c.Approval_Id__c,
                TM_Line__c.Dereferenced_Child_Resource__c,
                //US129137
                TM_Line__c.EQAI_Bill_Unit_Code__c

                //ticket 19130 >>
        };
    }

    public List<TM_Line__c> selectByIds(Set<Id> ids){
        String query = newQueryFactory(true).
                selectField('Resource_Type__r.Fuel_Fired_Equipment__c').
                selectField('Resource_Type__r.Name').
                selectField('Resource_Type__r.Fleet_No_Required__c').
                selectField('Resource_Type__r.Rental_Resource_Type__c').
                selectField('Resource__r.Name').
                selectField('Unit_of_Measure__r.Name').
                selectField('Unit_of_Measure__r.Hours_UOM__c').
                selectField('Contract_Line__r.Name').
                selectField('Quote_Line__r.Resource__c').
                selectField('Quote_Line__r.Resource_Type__c').
                selectField('Quote_Line__r.Sales_Order__c').
                selectField('Sales_Line__r.Resource_Type__c').
                selectField('Sales_Line__r.Resource__c').
                selectField('Sales_Line__r.Sales_Order__c').
                selectField('TM__r.Sales_Order__c'). //Kronos
                selectField('Service_Center__r.Temporary__c'). //Kronos
                selectField('TM__r.Scheduled_Date__c'). //Kronos
                selectField('TM__r.Sales_Order__r.Pay_Rule__c'). //Kronos
                selectField('Resource__r.Pay_Rule__c'). //Kronos
                setCondition('Id IN :ids').toSOQL();

        return (List<TM_Line__c>) Database.query(query);
    }

    public List<TM_Line__c> selectByTmId(Set<Id> tmIds){
        String query = newQueryFactory(true)
                .selectField('Contract_Line__r.Name')
                .selectField('Contract_Line__r.Resource_Type__r.Name')
                .selectField('Contract_Line__r.Resource__r.Name')
                .selectField('Resource_Type__r.Blocked__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Resource__r.Blocked__c')
                .selectField('Resource__r.Name')
                .selectField('Quote_Line__r.Resource__c')
                .selectField('Quote_Line__r.Resource_Type__c')
                .selectField('Quote_Line__r.Sales_Order__c')
                .selectField('Sales_Line__r.Resource_Type__c')
                .selectField('Sales_Line__r.Resource__c')
                .selectField('Sales_Line__r.Sales_Order__c')
                .selectField('TM__r.Sales_Order__c') //Kronos
                .selectField('Service_Center__r.Temporary__c') //Kronos
                .selectField('TM__r.Scheduled_Date__c') //Kronos
                .selectField('TM__r.Sales_Order__r.Pay_Rule__c') //Kronos
                .selectField('Resource__r.Pay_Rule__c')  //Kronos
                .setCondition('TM__c IN :tmIds').toSOQL();

        return (List<TM_Line__c>) Database.query(query);
    }

    //job task <<
    public List<TM_Line__c> selectByTmId(Set<Id> tmIds, List<String> filters){
        fflib_QueryFactory queryFactory = newQueryFactory(true).
                selectField('TM__r.Sales_Order__c').
                selectField('TM__r.Scheduled_Date__c').
                selectField('TM_Job_Task__c').
                selectField('TM_Job_Task__r.Line_No__c').
                selectField('TM_Job_Task__r.Sales_Order_Job_Task__c').
                selectField('TM_Job_Task__r.Sales_Order_Job_Task__r.Billing_Type__c').
                selectField('Resource_Type__r.Name').
                selectField('Resource_Type__r.Fleet_No_Required__c').
                selectField('Resource_Type__r.Rental_Resource_Type__c').
                selectField('Resource__r.Name').
                selectField('Resource__r.Has_Container__c').
                selectField('Resource__r.Has_Weight_Volume__c').
                //ticket 19861 <<
                selectField('TM__r.Name').
                selectField('Resource__r.Blocked__c').
                selectField('Resource_Type__r.Blocked__c').
                //ticket 19861 <>>
                selectField('Service_Center__r.Name').
                selectField('Service_Center__r.Temporary__c').
                selectField('Service_Center__r.Equipment_Fleet_No_Not_Required__c').
                selectField('Unit_of_Measure__r.Name').
                selectField('Unit_of_Measure__r.Hours_UOM__c').
                selectField('Unit_Weight_Vol__r.Name').
                selectField('Container_Size__r.Name').
                selectField('Facility__r.Name').
                selectField('Sales_Bundle_Line__r.Name').
                selectField('Sales_Bundle_Line__r.Line_No__c').
                selectField('Parent_Line__r.Line_No__c').
                selectField('Linked_Line__r.Line_No__c').
                selectField('Quote_Line__r.Resource__c').
                selectField('Quote_Line__r.Resource_Type__c').
                selectField('Quote_Line__r.Sales_Order__c').
                selectField('Sales_Line__r.Resource_Type__c').
                selectField('Sales_Line__r.Resource__c').
                selectField('Sales_Line__r.Sales_Order__c').
                //ticket 19130 <<
                //selectField('Parent_Line__r.Line_No__c').
                //ticket 19130 >>
                selectField('Bundle_Line__r.Line_No__c').
                selectField('Linked_Line__r.Line_No__c').
                selectField('TM__r.Sales_Order__r.Pay_Rule__c'). //Kronos
                selectField('Resource__r.Pay_Rule__c'). //Kronos;
                selectField('Contract_Line__r.Contract__c'); //Ticket#24525;
        //ticket 19130 <<
        queryFactory.subselectQuery('TM_Child_Lines__r')
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

        if (filters == null) {
            filters = new List<String>();
        }
        filters.add('TM__c IN :tmIds');
        queryFactory.setCondition(String.join(filters, ' AND '));

        return (List<TM_Line__c>) Database.query(queryFactory.toSOQL());
    }

    public List<TM_Line__c> selectWithFlatPaysByTmId(Set<Id> tmIds, List<String> tmLineFilters) {
        fflib_QueryFactory queryFactory = newQueryFactory(true)
                .selectField('TM__r.Name')
                .selectField('TM__r.Sales_Order__c')
                .selectField('TM__r.Scheduled_Date__c')
                .selectField('TM_Job_Task__c')
                .selectField('TM_Job_Task__r.Line_No__c')
                .selectField('TM_Job_Task__r.Name')
                .selectField('TM_Job_Task__r.Task_No__c')
                .selectField('TM_Job_Task__r.Sales_Order_Job_Task__c')
                .selectField('TM_Job_Task__r.Sales_Order_Job_Task__r.Billing_Type__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Resource_Type__r.Fleet_No_Required__c')
                .selectField('Resource_Type__r.Rental_Resource_Type__c')
                .selectField('Resource__r.Name')
                .selectField('Resource__r.Has_Container__c')
                .selectField('Resource__r.Has_Weight_Volume__c')
                .selectField('Resource__r.Allow_Zero_Unit_Cost_at_TM_Confirmation__c')
                .selectField('Resource__r.Bypass_Time_Overlap_Checking__c') //Ticket#22307
                .selectField('Service_Center__r.Name')
                .selectField('Service_Center__r.Temporary__c')
                .selectField('Service_Center__r.Equipment_Fleet_No_Not_Required__c')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Facility__r.Name')
                .selectField('Contract_Line__r.Name')
                .selectField('Contract_Line__r.Contract__c') //Ticket#25514
                .selectField('Sales_Bundle_Line__r.Name')
                .selectField('Sales_Bundle_Line__r.Line_No__c')
                //ticket 19130 <<
                //.selectField('Parent_Line__r.Line_No__c')
                //ticket 19130 >>
                .selectField('Linked_Line__r.Line_No__c')
                .selectField('Quote_Line__r.Resource__c')
                .selectField('Quote_Line__r.Resource_Type__c')
                .selectField('Quote_Line__r.Sales_Order__c')
                .selectField('Sales_Line__r.Resource_Type__c')
                .selectField('Sales_Line__r.Resource__c')
                .selectField('Sales_Line__r.Sales_Order__c')
                .selectField('Linked_Line__r.Resource_Name__c')
                //ticket  19693 <<
                .selectField('Billing_Worksheet_Line__r.Name')
                .selectField('Billing_Worksheet_Line__r.Line_No__c')
                //ticket  19693 >>
                //ticket 19535 <<
                .selectField('Sales_Line__r.Sales_Order__c')
                //ticket 19535 >>
                .selectField('TM__r.Sales_Order__r.Pay_Rule__c') //Kronos
                .selectField('TM__r.Sales_Order__r.Disposal_Billing_Method__c')//DE36562
                .selectField('Resource__r.Pay_Rule__c'); //Kronos


        if (tmLineFilters != null) {
            tmLineFilters.add('TM__c IN :tmIds');
            queryFactory.setCondition(String.join(tmLineFilters, ' AND '));
        }
        else {
            queryFactory.setCondition('TM__c IN :tmIds');
        }
        queryFactory.setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true);

        //ticket 19130 <<
        queryFactory.subselectQuery('TM_Child_Lines__r')
                .selectField('Id')
                .selectField('Parent_Line__c')
                .selectField('Parent_Line__r.Line_No__c')
                .selectField('Parent_Line__r.Description__c')
                .selectField('Child_Line__c')
                .selectField('Child_Line__r.Line_No__c')
                .selectField('Child_Line__r.Category__c')
                .selectField('Child_Line__r.Resource_Type__c')
                .selectField('Child_Line__r.Resource__c')
                .selectField('Child_Line__r.Description__c')
                .setOrdering('Child_Line__r.Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true);
        //ticket 19130 >>

        queryFactory.subselectQuery('Resource_Flat_Pays1__r')
                .selectField('Id')
                .selectField('Name')
                .selectField('T_M__c')
                .selectField('T_M__r.Name')
                .selectField('T_M_Line__c')
                .selectField('T_M_Line__r.Line_No__c')
                .selectField('Show_Flat_Pay_Code__c')
                .selectField('Flat_Rate_Type__c')
                .selectField('Flat_Rate_Type__r.Name')
                .selectField('Rate__c')
                .selectField('Misc_Charge_Resource__c')
                .selectField('Misc_Charge_Resource__r.Name')
                .selectField('Unit_of_Measure__c')
                .selectField('Unit_of_Measure__r.Name');

        String soql = queryFactory.toSOQL();
        //soql = soql.replaceFirst('SELECT', 'SELECT toLabel(Category__c) CategoryName,'); //include category name

        return (List<TM_Line__c>) Database.query(soql);
    }
    //job task >>

    public Map<Id, TM_Line__c> selectTMLMapWithResourceTypeAndResourceById(Set<Id> idSet){
        return new Map<Id, TM_Line__c> (
                (List<TM_Line__c>) Database.query(newQueryFactory().
                        selectField(TM_Line__c.Resource_Type__c).
                        selectField(TM_Line__c.Resource__c).
                        setCondition('Id IN :idSet').toSOQL())
        );
    }

    public Map<Id, TM_Line__c> selectTMLMapWithUnitOfMeasureById(Set<Id> idSet) {
        return new Map<Id, TM_Line__c> (
                (List<TM_Line__c>) Database.query(newQueryFactory().
                        selectField(TM_Line__c.Unit_of_Measure__c).
                        selectField('Unit_Of_Measure__r.Name').
                        setCondition('Id IN :idSet').toSOQL())
        );
    }

    public List<TM_Line__c> selectInterCompanyLineByScheduledDateRange(Date startDate, Date endDate){
        return new List<TM_Line__c>(
                (List<TM_Line__c>) Database.query(newQueryFactory(true).
                        selectField('TM__r.Scheduled_Date__c').
                        selectField('TM__r.Sales_Invoice__r.Document_Status__c').
                        selectField('TM__r.Status__c').
                        selectField('TM__r.Name').
                        selectField('TM__r.Service_Center__r.Name').
                        selectField('Service_Center__r.Name').
                        selectField('Resource__r.Name').
                        selectField('TM__r.Sales_Order__r.Name').
                        selectField('Unit_of_Measure__r.Name').
                        selectField('TM__r.Manual_Closed_At__c').
                        selectField('TM__r.Manual_Closed_By__r.Name').
                        selectField('Billing_Worksheet_Line__r.Line_Cost__c').
                        selectField('Billing_Worksheet_Line__r.Unit_Cost__c').
                        selectField('Billing_Worksheet_Line__r.Quantity__c').
                        selectField('Billing_Worksheet_Line__r.Unit_of_Measure__c').
                        selectField('Billing_Worksheet_Line__r.Cost_Qty__c').
                        selectField('Billing_Worksheet_Line__r.Cost_Unit_of_Measure__c').
                        selectField('Billing_Worksheet_Line__r.Unit_of_Measure__r.Name').
                        addOrdering('Service_Center__r.Name', fflib_QueryFactory.SortOrder.ASCENDING).
                        setCondition('Inter_Company_Resource__c = true AND ' +
                                'TM__r.Scheduled_Date__c >= :startDate AND ' +
                                'TM__r.Scheduled_Date__c <= :endDate AND ' +
                                'Service_Center__r.Temporary__c = false AND ' +
                                'Resource__r.Exclude_from_I_C_Cost_Calculation__c != true AND ' +
                                '(TM__r.Sales_Invoice__r.Document_Status__c = \'Open\' OR TM__r.Sales_Invoice__c = null OR Invoiced__c != true) AND ' +
                                'Category__c IN (\'Labor\', \'Equipment\') AND ' +
                                'TM__r.Status__c IN (\'Confirmed\', ' +
                                '\'Received By Billing\', ' +
                                '\'Ready to Bill\',' +
                                '\'Fully Invoiced\',' +
                                '\'Closed\',' +
                                '\'Void\',' +
                                '\'Partially Invoiced\'' +
                                ')').toSOQL())
        );

    }

    //job task <<
    //public List<TM_Line__c> selectTMLinesByCategory(Id tmId, String category){
    public List<TM_Line__c> selectTMLinesByCategory(Id tmId, Id jobTaskId, String category) {
        //job task >>
        String condition = 'TM__c = :tmId';
        if (category != null) {
            condition += ' AND Category__c = :category';
        }
        //job task <<
        if (jobTaskId != null) {
            condition += ' AND TM_Job_Task__c = :jobTaskId';
        }
        //job task >>
        return (List<TM_Line__c>) Database.query(newQueryFactory().
                selectField(TM_Line__c.Id).
                selectField(TM_Line__c.TM__c).
                selectField('TM__r.Sales_Order__c').
                selectField('TM__r.From_Sales_Quote__c').
                selectField('TM__r.Bill_to_Customer__c').
                selectField('TM__r.Tax_Liable__c').
                selectField('TM__r.Tax_Area__c').
                selectField(TM_Line__c.Line_No__c).
                selectField(TM_Line__c.Resource_Type__c).
                selectField('Resource_Type__r.Id').
                selectField('Resource_Type__r.Name').
                selectField(TM_Line__c.Resource__c).
                selectField('Resource__r.Id').
                selectField('Resource__r.Name').
                selectField(TM_Line__c.Resource_Name__c).
                selectField('Resource__r.Description__c').
                selectField(TM_Line__c.Category__c).
                selectField(TM_Line__c.Tax_Group__c).
                selectField(TM_Line__c.Unit_of_Measure__c).
                selectField('Unit_of_Measure__r.Id').
                selectField('Unit_of_Measure__r.Name').
                selectField('Unit_of_Measure__r.Description__c').
                selectField('Unit_of_Measure__r.Hours_UOM__c').
                selectField(TM_Line__c.Service_Center__c).
                selectField('Service_Center__r.Id').
                selectField('Service_Center__r.Name').
                selectField(TM_Line__c.Job_Start_Time__c).
                selectField(TM_Line__c.Job_End_Time__c).
                selectField(TM_Line__c.Site_Start_Time__c).
                selectField(TM_Line__c.Site_End_Time__c).
                selectField(TM_Line__c.Lunch_Start_Time__c).
                selectField(TM_Line__c.Lunch_End_Time__c).
                selectField(TM_Line__c.Description__c).
                selectField(TM_Line__c.BOL_Manifest__c).
                selectField(TM_Line__c.Facility__c).
                //job task <<
                //selectField(TM_Line__c.Facility__r.Name).
                selectField('Facility__r.Name').
                //job task >>
                selectField(TM_Line__c.Quantity__c).
                selectField(TM_Line__c.Regular_Hours__c).
                selectField(TM_Line__c.Regular_Rate__c).
                selectField(TM_Line__c.Overtime_Hours__c).
                selectField(TM_Line__c.Overtime_Rate__c).
                selectField(TM_Line__c.Premium_Hours__c).
                selectField(TM_Line__c.Premium_Rate__c).
                selectField(TM_Line__c.Unit_Price__c).
                selectField(TM_Line__c.Unit_Cost__c).
                selectField(TM_Line__c.Use_Premium_Rate__c).
                selectField(TM_Line__c.Non_Billable__c).
                selectField(TM_Line__c.Billing_Start_Time__c).
                selectField(TM_Line__c.Billing_End_Time__c).
                selectField(TM_Line__c.Lunch__c).
                selectField(TM_Line__c.Include_Lunch_Y_N__c).
                selectField(TM_Line__c.Contract_Overtime_Rate__c).
                selectField(TM_Line__c.Contract_Regular_Rate__c).
                selectField(TM_Line__c.Contract_Premium_Rate__c).
                selectField('Linked_Line__r.Resource_Name__c').
                setCondition(condition).toSOQL());
    }

    public List<TM_Line__c> selectAwayServiceCenterLinesByScheduledDateServiceCenterAndCategory(Date scheduledDate, String serviceCenter, String category){
        return (List<TM_Line__c>) Database.query(newQueryFactory(false).
                selectField(TM_Line__c.Id).
                selectField(TM_Line__c.Resource__c).
                setCondition('Category__c = :category AND ' +
                        'Inter_Company_Resource__c = TRUE AND ' +
                        'Service_Center__r.Name <> :serviceCenter AND Service_Center__c != null AND ' +
                        'TM__r.Service_Center__r.Name = :serviceCenter AND TM__r.Service_Center__c != null AND ' +
                        'TM__r.Scheduled_Date__c = :scheduledDate').
                toSOQL());
    }

    public List<TM_Line__c> selectCreateInvoiceRequiredFieldsById(Set<Id> idSet){
        return (List<TM_Line__c>) Database.query(newQueryFactory(false).
                selectField('Id').
                selectField('Invoiced__c').
                selectField('Resource_Type__c').
                selectField('Resource__c').
                selectField('Resource_Type__r.Fleet_No_Required__c').
                selectField('Resource_Type__r.Rental_Resource_Type__c').
                selectField('Resource_Type__r.Fuel_Fired_Equipment__c').
                selectField('Service_Center__r.Equipment_Fleet_No_Not_Required__c').
                selectField('Category__c').
                selectField('Service_Center__r.Temporary__c').
                selectField('Description__c').
                selectField('Unit_of_Measure__c').
                selectField('Tax_Group__c').
                selectField('Tax_Pct__c').
                selectField('Tax__c').
                selectField('TM__c').
                selectField('Service_Center__c').
                selectField('Bill_as_Lump_Sum__c').
                selectField('Non_Billable__c').
                selectField('BOL_Manifest__c').
                selectField('TM__r.Scheduled_Date__c').
                selectField('TM__r.Tax_Liable__c').
                selectField('Hour__c').
                selectField('Quantity__c').
                selectField('Unit_of_Measure__c').
                selectField('Line_Amount__c').
                selectField('xUnit_Price__c').
                selectField('Unit_Cost__c').
                selectField('Cost_Qty__c').
                selectField('Line_Cost__c').
                selectField('Line_Amt_Incl_Tax__c').
                selectField('Pricing_Source_2__c').
                selectField('Regular_Hours__c').
                selectField('Regular_Rate__c').
                selectField('xRegular_Rate__c').
                selectField('Overtime_Hours__c').
                selectField('Overtime_Rate__c').
                selectField('xOvertime_Rate__c').
                selectField('Premium_Hours__c').
                selectField('Premium_Rate__c').
                selectField('xPremium_Rate__c').
                selectField('Drop_Off_Rental__c').
                selectField('Rent_Billing_Type__c').
                selectField('Rent_Billing_Amount__c').
                selectField('Sales_Invoice_Line__c').
                selectField('Cost_Method__c').
                selectField('Min_Sell_Qty__c').
                selectField('Resource_UOM__c').
                selectField('Resource_Type_UOM__c').
                selectField('Container_Size__c').
                selectField('Unit_Weight_Vol__c').
                selectField('Contract_Line__c').
                selectField('Contract_Line__r.Customer_Item_No__c').
                selectField('Contract_Line__r.Customer_Description__c').
                selectField('Contract_Line__r.Customer_Overtime_Item_No__c').
                selectField('Contract_Line__r.Customer_Overtime_Description__c').
                selectField('Contract_Line__r.Customer_Premium_Item_No__c').
                selectField('Contract_Line__r.Customer_Premium_Description__c').
                selectField('Quote_Line__r.Resource__c').
                selectField('Quote_Line__r.Resource_Type__c').
                selectField('Quote_Line__r.Sales_Order__c').
                selectField('Sales_Line__r.Resource_Type__c').
                selectField('Sales_Line__r.Resource__c').
                selectField('Sales_Line__r.Sales_Order__c').
                setCondition('Invoiced__c <> TRUE').
                setCondition('Id IN :idSet').toSOQL());
    }

    public List<TM_Line__c> selectSafetyPlanLineByTMId(Set<Id> idSet, Id resourceId){
        String soql = newQueryFactory(false).
                selectField('TM__r.Sales_Order__c').
                setCondition('TM__r.Id IN :idSet AND ' +
                        'Category__c = \'Misc. Charges And Taxes\' AND ' +
                        'Resource__c = :resourceId').
                toSOQL();
        return (List<TM_Line__c>) Database.query(soql);
    }

}