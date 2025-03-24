/*
 *  Ticket#19931
 *      - add Rental_Resource_Type__c
 * * Prabhu Rathakrishnan      11-12-2024			 US131092: Salesforce - Add "Disposal Billing Method" field to Sales Lines level
 */
public with sharing class BillingWorksheetLinesSelector extends fflib_SObjectSelector implements IBillingWorksheetLinesSelector {
    public static IBillingWorksheetLinesSelector newInstance() {
        return (IBillingWorksheetLinesSelector) Application.Selector.newInstance(Billing_Worksheet_Line__c.SObjectType);
    }

    public SObjectType getSObjectType() {
        return Billing_Worksheet_Line__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
                Billing_Worksheet_Line__c.Id,
                Billing_Worksheet_Line__c.Name,
                Billing_Worksheet_Line__c.Line_No__c,
                Billing_Worksheet_Line__c.Category__c,
                Billing_Worksheet_Line__c.Service_Center__c,
                Billing_Worksheet_Line__c.Resource_Type__c,
                Billing_Worksheet_Line__c.Resource__c,
                Billing_Worksheet_Line__c.Resource_Name__c,
                Billing_Worksheet_Line__c.Description__c,
                Billing_Worksheet_Line__c.Hour__c,
                Billing_Worksheet_Line__c.Quantity__c,
                Billing_Worksheet_Line__c.Unit_of_Measure__c,
                Billing_Worksheet_Line__c.Resource_UOM__c,
                Billing_Worksheet_Line__c.Resource_Type_UOM__c,
                Billing_Worksheet_Line__c.Unit_Price__c,
                Billing_Worksheet_Line__c.xUnit_Price__c,
                Billing_Worksheet_Line__c.Unit_Cost__c,
                Billing_Worksheet_Line__c.xUnit_Cost__c,
                Billing_Worksheet_Line__c.Cost_Qty__c,
                Billing_Worksheet_Line__c.Line_Amount__c,
                Billing_Worksheet_Line__c.xLine_Amount__c,
                Billing_Worksheet_Line__c.Line_Cost__c,
                Billing_Worksheet_Line__c.xLine_Cost__c,
                Billing_Worksheet_Line__c.Line_Amt_Incl_Tax__c,
                Billing_Worksheet_Line__c.Markup__c,
                Billing_Worksheet_Line__c.Markup_Option__c,
                Billing_Worksheet_Line__c.Tax_Pct__c,
                Billing_Worksheet_Line__c.Tax_Group__c,
                Billing_Worksheet_Line__c.Tax__c,
                Billing_Worksheet_Line__c.Include_Lunch_Y_N__c,
                Billing_Worksheet_Line__c.Bill_Site_Time__c,
                Billing_Worksheet_Line__c.Billing_Start_Time__c,
                Billing_Worksheet_Line__c.Billing_End_Time__c,
                Billing_Worksheet_Line__c.Hour__c,
                Billing_Worksheet_Line__c.Bill_as_Lump_Sum__c,
                Billing_Worksheet_Line__c.Non_Billable__c,
                Billing_Worksheet_Line__c.BOL_Manifest__c,
                Billing_Worksheet_Line__c.Disposal_Billing_Method__c,
                Billing_Worksheet_Line__c.Cost_Method__c,
                Billing_Worksheet_Line__c.Container_Size__c,
                Billing_Worksheet_Line__c.Contract_Line__c,
                Billing_Worksheet_Line__c.Contract_Regular_Rate__c,
                Billing_Worksheet_Line__c.Contract_Overtime_Rate__c,
                Billing_Worksheet_Line__c.Contract_Premium_Rate__c,
                Billing_Worksheet_Line__c.Drop_Off_Rental__c,
                Billing_Worksheet_Line__c.Facility__c,
                Billing_Worksheet_Line__c.Job_Start_Time__c,
                Billing_Worksheet_Line__c.Job_End_Time__c,
                Billing_Worksheet_Line__c.Lunch_Start_Time__c,
                Billing_Worksheet_Line__c.Lunch_End_Time__c,
                Billing_Worksheet_Line__c.Non_Billable__c,
                Billing_Worksheet_Line__c.Overtime_Hours__c,
                Billing_Worksheet_Line__c.Overtime_Rate__c,
                Billing_Worksheet_Line__c.Premium_Hours__c,
                Billing_Worksheet_Line__c.Premium_Rate__c,
                Billing_Worksheet_Line__c.Pricing_Source_2__c,
                Billing_Worksheet_Line__c.Regular_Hours__c,
                Billing_Worksheet_Line__c.Regular_Rate__c,
                Billing_Worksheet_Line__c.Rent_Billing_Type__c,
                Billing_Worksheet_Line__c.Rent_Billing_Amount__c,
                Billing_Worksheet_Line__c.Sales_Line__c,
                Billing_Worksheet_Line__c.Site_Start_Time__c,
                Billing_Worksheet_Line__c.Site_End_Time__c,
                Billing_Worksheet_Line__c.Unit_Weight_Vol__c,
                Billing_Worksheet_Line__c.xRegular_Rate__c,
                Billing_Worksheet_Line__c.xPremium_Rate__c,
                Billing_Worksheet_Line__c.xOvertime_Rate__c,
                Billing_Worksheet_Line__c.Total_Job_Hours__c,
                Billing_Worksheet_Line__c.Total_Site_Hours__c,
                Billing_Worksheet_Line__c.Flat_Pay_Line__c,
                Billing_Worksheet_Line__c.Bundle_Line__c,
                Billing_Worksheet_Line__c.Sales_Bundle_Line__c,
                Billing_Worksheet_Line__c.TM__c,
                Billing_Worksheet_Line__c.TM_Line__c,
                Billing_Worksheet_Line__c.TM_Job_Task__c,
                Billing_Worksheet_Line__c.Sales_Order_Job_Task__c,
                Billing_Worksheet_Line__c.Sales_Order__c,
                //ticket 19130 <<
                //Billing_Worksheet_Line__c.Parent_Line__c,
                //ticket 19130 >>
                Billing_Worksheet_Line__c.Fleet_No_Required__c,
                Billing_Worksheet_Line__c.Fleet_No__c,
                Billing_Worksheet_Line__c.Min_Sell_Qty__c,
                Billing_Worksheet_Line__c.Rolled_up_Unit_Price__c,
                Billing_Worksheet_Line__c.System_Calculated_Line__c,
                Billing_Worksheet_Line__c.Profit__c,
                Billing_Worksheet_Line__c.Profit_Pct__c,
                Billing_Worksheet_Line__c.Invoiced__c,
                //ticket 19130 <<
                //Billing_Worksheet_Line__c.TM_Parent_Line__c,
                //ticket 19130 >>
                Billing_Worksheet_Line__c.Costing_Source__c,
                Billing_Worksheet_Line__c.Wizard_Question_Answered__c,
                Billing_Worksheet_Line__c.Status__c,
                Billing_Worksheet_Line__c.Bundle_Pricing_Method__c,
                Billing_Worksheet_Line__c.To_Invoice__c,
                Billing_Worksheet_Line__c.Quote_Line__c,
                //ticket 19586 << 
                Billing_Worksheet_Line__c.CreatedDate,
                //PW Travel Cost
                Billing_Worksheet_Line__c.Travel_Hour_Unit_Cost__c,
                Billing_Worksheet_Line__c.Travel_Hours__c,
                Billing_Worksheet_Line__c.Non_Travel_Hour_Unit_Cost__c,
                //PW Travel Cost
                //ticket 19586 >>
                //ticket 20143 <<
                Billing_Worksheet_Line__c.Inserted_by_User__c,
                //ticket 20143 >>
                Billing_Worksheet_Line__c.Week_Number__c, //Ticket#20496
                //Ticket#22710 >>
                Billing_Worksheet_Line__c.Regular_Unit_Cost__c,
                Billing_Worksheet_Line__c.Overtime_Unit_Cost__c,
                Billing_Worksheet_Line__c.Double_Time_Unit_Cost__c,
                Billing_Worksheet_Line__c.Approval_Id__c,
                Billing_Worksheet_Line__c.Profile_Id__c,
                //US129137
				Billing_Worksheet_Line__c.EQAI_Bill_Unit_Code__c                   
                //Ticket#22710 <<
        };
    }

    public List<Billing_Worksheet_Line__c> selectById(Set<Id> idSet) {
        fflib_QueryFactory queryFactory = newQueryFactory(true)
                .selectField('Service_Center__r.Name')
                .selectField('Service_Center__r.Temporary__c')
                .selectField('Service_Center__r.Equipment_Fleet_No_Not_Required__c')
                .selectField('Resource_Type__r.Fuel_Fired_Equipment__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Resource_Type__r.Fleet_No_Required__c')
                .selectField('Resource_Type__r.Rental_Resource_Type__c')
                .selectField('Resource__r.Name')
                .selectField('Resource__r.Has_Container__c')
                .selectField('Resource__r.Has_Weight_Volume__c')
                .selectField('Resource__r.Allow_Manual_Unit_Cost_Adjustment__c')
                .selectField('Resource__r.Allow_Negative_Quantity_Values__c')
                .selectField('Resource__r.Name')
                .selectField('Resource_Type_UOM__r.Name')
                .selectField('Resource_UOM__r.Name')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Facility__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Sales_Bundle_Line__r.Name')
                .selectField('Sales_Bundle_Line__r.Line_No__c')
                .selectField('Bundle_Line__r.Name')
                .selectField('Bundle_Line__r.Line_No__c')
                .selectField('TM__r.Name')
                .selectField('TM__r.Scheduled_Date__c')
                .selectField('TM__r.Rate_Sheet__c')
                .selectField('TM_Line__r.Name')
                .selectField('TM_Line__r.Line_No__c')
                //.selectField('TM_Line__r.Resource_Type__c') //Ticket#24817 not needed
                .selectField('TM_Job_Task__r.Line_No__c')
                .selectField('TM_Job_Task__r.Sales_Order_Job_Task__c')
                .selectField('Sales_Order_Job_Task__r.Line_No__c')
                .selectField('Sales_Order_Job_Task__r.Billing_Type__c')
                .selectField('Sales_Order__r.Name')
                .selectField('Sales_Order__r.From_Sales_Quote__c')
                .selectField('Sales_Order__r.Tax_Liable__c')
                .selectField('Sales_Order__r.Contract__c') //Ticket#19511
                //ticket 19130 <<
                //.selectField('Parent_Line__r.Line_No__c')
                //ticket 19130 >>
                .selectField('Contract_Line__r.Name')
                .selectField('Contract_Line__r.Customer_Description__c')
                .selectField('Contract_Line__r.Customer_Item_No__c')
                .selectField('Contract_Line__r.Customer_Premium_Item_No__c')
                .selectField('Contract_Line__r.Customer_Premium_Description__c')
        		.selectField('TM__c.Sales_Order__r');

        queryFactory.setCondition('Id IN :idSet');
        return (List<Billing_Worksheet_Line__c>) Database.query(queryFactory.toSOQL());
    }

    public List<Billing_Worksheet_Line__c> selectBySalesOrderJobTaskId(Set<Id> salesOrderJobTaskIds, List<String> filters) {
        fflib_QueryFactory queryFactory = newQueryFactory(true)
                .selectField('Service_Center__r.Name')
                .selectField('Service_Center__r.Temporary__c')
                .selectField('Service_Center__r.Equipment_Fleet_No_Not_Required__c')
                .selectField('TM__r.Service_Center__r.Advanced_Disposal__c')//US128849
                .selectField('Resource_Type__r.Fuel_Fired_Equipment__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Resource_Type__r.Fleet_No_Required__c')
                .selectField('Resource_Type__r.Rental_Resource_Type__c')
                .selectField('Resource__r.Name')
                .selectField('Resource__r.Has_Container__c')
                .selectField('Resource__r.Has_Weight_Volume__c')
                .selectField('Resource__r.Name')
                .selectField('Resource__r.Allow_Manual_Unit_Cost_Adjustment__c')
                .selectField('Resource__r.Allow_Negative_Quantity_Values__c')
                .selectField('Resource_Type_UOM__r.Name')
                .selectField('Resource_UOM__r.Name')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Facility__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Sales_Bundle_Line__r.Name')
                .selectField('Sales_Bundle_Line__r.Line_No__c')
                .selectField('Bundle_Line__r.Name')
                .selectField('Bundle_Line__r.Line_No__c')
                .selectField('Bundle_Line__r.TM__c')
                .selectField('Bundle_Line__r.TM__r.Name')
                .selectField('TM__r.Name')
                .selectField('TM__r.Scheduled_Date__c')
                .selectField('TM__r.Rate_Sheet__c')
                .selectField('TM__r.Service_Center__c')
                .selectField('TM_Line__r.Name')
                .selectField('TM_Line__r.Line_No__c')
                //.selectField('TM_Line__r.Resource_Type__c') //Ticket#24817 not needed
                .selectField('TM_Job_Task__r.Line_No__c')
                .selectField('TM_Job_Task__r.Sales_Order_Job_Task__c')
                .selectField('Sales_Order_Job_Task__r.Line_No__c')
                .selectField('Sales_Order_Job_Task__r.Billing_Type__c')
                .selectField('Sales_Order__r.Name')
                .selectField('Sales_Order__r.From_Sales_Quote__c')
                .selectField('Sales_Order__r.Tax_Liable__c')
                .selectField('Sales_Order__r.Contract__c') //Ticket#19511
                //ticket 19130 <<
                //.selectField('Parent_Line__r.Line_No__c')
                //ticket 19130 >>
                .selectField('Contract_Line__r.Name')
                .selectField('Contract_Line__r.Customer_Description__c')
                .selectField('Contract_Line__r.Customer_Item_No__c')
                .selectField('Contract_Line__r.Customer_Premium_Item_No__c')
                .selectField('Contract_Line__r.Customer_Premium_Description__c')
            	.selectField('Sales_Order__r.Disposal_Billing_Method__c');//DE36562

        if (filters == null) {
            filters = new List<String>();
        }
        filters.add('Sales_Order_Job_Task__c IN :salesOrderJobTaskIds');

        queryFactory.setCondition(String.join(filters, ' AND '))
                .addOrdering('Category__c', fflib_QueryFactory.SortOrder.ASCENDING, true);
        //.setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true);

        String soql = queryFactory.toSOQL();
        return (List<Billing_Worksheet_Line__c>) Database.query(soql);
    }

    public List<Billing_Worksheet_Line__c> selectOpenLinesBySalesOrderId(Set<Id> salesOrderIds){
        fflib_QueryFactory queryFactory = newQueryFactory(true)
                .selectField('Service_Center__r.Name')
                .selectField('Service_Center__r.Temporary__c')
                .selectField('Service_Center__r.Equipment_Fleet_No_Not_Required__c')
                .selectField('Resource_Type__r.Fuel_Fired_Equipment__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Resource_Type__r.Fleet_No_Required__c')
                .selectField('Resource_Type__r.Rental_Resource_Type__c')
                .selectField('Resource__r.Name')
                .selectField('Resource__r.Has_Container__c')
                .selectField('Resource__r.Has_Weight_Volume__c')
                .selectField('Resource__r.Name')
                .selectField('Resource__r.Allow_Manual_Unit_Cost_Adjustment__c')
                .selectField('Resource__r.Allow_Negative_Quantity_Values__c')
                .selectField('Resource_Type_UOM__r.Name')
                .selectField('Resource_UOM__r.Name')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Facility__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Sales_Bundle_Line__r.Name')
                .selectField('Sales_Bundle_Line__r.Line_No__c')
                .selectField('Bundle_Line__r.Name')
                .selectField('Bundle_Line__r.Line_No__c')
                .selectField('TM__r.Name')
                .selectField('TM__r.Scheduled_Date__c')
                .selectField('TM__r.Rate_Sheet__c')
                .selectField('TM_Line__r.Name')
                .selectField('TM_Line__r.Line_No__c')
                .selectField('TM_Job_Task__r.Line_No__c')
                .selectField('TM_Job_Task__r.Sales_Order_Job_Task__c')
                .selectField('Sales_Order_Job_Task__r.Line_No__c')
                .selectField('Sales_Order_Job_Task__r.Billing_Type__c')
                .selectField('Sales_Order__r.Name')
                .selectField('Sales_Order__r.From_Sales_Quote__c')
                .selectField('Sales_Order__r.Tax_Liable__c')
                .selectField('Sales_Order__r.Contract__c') //Ticket#19511
                //ticket 19130 <<
                //.selectField('Parent_Line__r.Line_No__c')
                //ticket 19130 >>
                .selectField('Contract_Line__r.Customer_Description__c')
                .selectField('Contract_Line__r.Customer_Item_No__c')
                .selectField('Contract_Line__r.Customer_Premium_Item_No__c')
                .selectField('Contract_Line__r.Customer_Premium_Description__c')
                .setCondition('Sales_Order__c IN :salesOrderIds AND Invoiced__c != TRUE');
        String soql = queryFactory.toSOQL();
        return (List<Billing_Worksheet_Line__c>) Database.query(soql);
    }

    public List<Billing_Worksheet_Line__c> selectOpenLinesByTMIds(Set<Id> tmIds){
        fflib_QueryFactory queryFactory = newQueryFactory(true)
                .selectField('Service_Center__r.Name')
                .selectField('Service_Center__r.Temporary__c')
                .selectField('Service_Center__r.Equipment_Fleet_No_Not_Required__c')
                .selectField('Resource_Type__r.Fuel_Fired_Equipment__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Resource_Type__r.Fleet_No_Required__c')
                .selectField('Resource_Type__r.Rental_Resource_Type__c')
                .selectField('Resource__r.Name')
                .selectField('Resource__r.Has_Container__c')
                .selectField('Resource__r.Has_Weight_Volume__c')
                .selectField('Resource__r.Name')
                .selectField('Resource__r.Allow_Manual_Unit_Cost_Adjustment__c')
                .selectField('Resource__r.Allow_Zero_Unit_Cost_at_TM_Confirmation__c')
                .selectField('Resource__r.Allow_Negative_Quantity_Values__c')
                .selectField('Resource_Type_UOM__r.Name')
                .selectField('Resource_UOM__r.Name')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Facility__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Sales_Bundle_Line__r.Name')
                .selectField('Sales_Bundle_Line__r.Line_No__c')
                .selectField('Bundle_Line__r.Name')
                .selectField('Bundle_Line__r.Line_No__c')
                .selectField('TM__r.Name')
                .selectField('TM__r.Scheduled_Date__c')
                .selectField('TM__r.Rate_Sheet__c')
            	.selectField('TM__r.Sales_Order__r.Disposal_Billing_Method__c')
                .selectField('TM_Line__r.Name')
                .selectField('TM_Line__r.Line_No__c')
                //.selectField('TM_Line__r.Resource_Type__c') //Ticket#24817 not needed
                .selectField('TM_Job_Task__r.Line_No__c')
                .selectField('TM_Job_Task__r.Sales_Order_Job_Task__c')
                .selectField('Sales_Order_Job_Task__r.Line_No__c')
                .selectField('Sales_Order_Job_Task__r.Billing_Type__c')
                .selectField('Sales_Order__r.Name')
                .selectField('Sales_Order__r.From_Sales_Quote__c')
                .selectField('Sales_Order__r.Tax_Liable__c')
                .selectField('Sales_Order__r.Contract__c') //Ticket#19511
                //ticket 19130 <<
                //.selectField('Parent_Line__r.Line_No__c')
                //ticket 19130 >>
                .selectField('Contract_Line__r.Customer_Description__c')
                .selectField('Contract_Line__r.Customer_Item_No__c')
                .selectField('Contract_Line__r.Customer_Premium_Item_No__c')
                .selectField('Contract_Line__r.Customer_Premium_Description__c')
                .setCondition('TM__c IN :tmIds AND Invoiced__c != TRUE');
        String soql = queryFactory.toSOQL();
        return (List<Billing_Worksheet_Line__c>) Database.query(soql);
    }

    public List<Billing_Worksheet_Line__c> selectBillingWorksheetLinesWithZeroCost(){
        fflib_QueryFactory queryFactory = newQueryFactory(true)
                .selectField('Service_Center__r.Name')
                .selectField('Service_Center__r.Temporary__c')
                .selectField('Service_Center__r.Equipment_Fleet_No_Not_Required__c')
                .selectField('Resource_Type__r.Fuel_Fired_Equipment__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Resource_Type__r.Fleet_No_Required__c')
                .selectField('Resource_Type__r.Rental_Resource_Type__c')
                .selectField('Resource__r.Name')
                .selectField('Resource__r.Has_Container__c')
                .selectField('Resource__r.Has_Weight_Volume__c')
                .selectField('Resource__r.Name')
                .selectField('Resource__r.Allow_Zero_Unit_Cost_at_TM_Confirmation__c')
                .selectField('Resource__r.Allow_Manual_Unit_Cost_Adjustment__c')
                .selectField('Resource__r.Allow_Negative_Quantity_Values__c')
                .selectField('Resource_Type_UOM__r.Name')
                .selectField('Resource_UOM__r.Name')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Container_Size__r.Name')
                .selectField('Facility__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Sales_Bundle_Line__r.Name')
                .selectField('Sales_Bundle_Line__r.Line_No__c')
                .selectField('Bundle_Line__r.Name')
                .selectField('Bundle_Line__r.Line_No__c')
                .selectField('TM__r.Name')
                .selectField('TM__r.Scheduled_Date__c')
                .selectField('TM__r.Rate_Sheet__c')
                .selectField('TM_Line__r.Name')
                .selectField('TM_Line__r.Line_No__c')
                //.selectField('TM_Line__r.Resource_Type__c') //Ticket#24817 not needed
                .selectField('TM_Job_Task__r.Line_No__c')
                .selectField('TM_Job_Task__r.Sales_Order_Job_Task__c')
                .selectField('Sales_Order_Job_Task__r.Line_No__c')
                .selectField('Sales_Order_Job_Task__r.Billing_Type__c')
                .selectField('Sales_Order__r.Name')
                .selectField('Sales_Order__r.From_Sales_Quote__c')
                .selectField('Sales_Order__r.Tax_Liable__c')
                //ticket 19130 <<
                //.selectField('Parent_Line__r.Line_No__c')
                //ticket 19130 >>
                .selectField('Sales_Order__r.Contract__c') //Ticket#19511
                .selectField('Contract_Line__r.Customer_Description__c')
                .selectField('Contract_Line__r.Customer_Item_No__c')
                .selectField('Contract_Line__r.Customer_Premium_Item_No__c')
                .selectField('Contract_Line__r.Customer_Premium_Description__c')
                .setCondition('(Unit_Cost__c = 0 OR Unit_Cost__c = 0 OR Line_Cost__c = 0 OR Line_Cost__c = NULL) ' +
                        'AND Invoiced__c != TRUE AND Category__c != \'Demurrage\' AND Category__c != \'Misc. Charges And Taxes\' ' +
                        'AND Category__c !=\'Bundled\'');

        //Category__c !='Lump Sum' && worksheetLine.Category__c != 'Demurrage' && worksheetLine.Category__c != 'Misc. Charges And Taxes')
        String soql = queryFactory.toSOQL();
        return (List<Billing_Worksheet_Line__c>) Database.query(soql);
    }
}