/*************************************************************************************************
* Name         :  TMsSelector 
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan      01-10-2024             Task75621: Salesforce - Add Fields for "Generator ID and "EPA ID"
* Shahwaz Khan              09-10-2024             US128845 : SF - Profile field and Manifest Lookup behind Advanced Disposal flag
* Sanjana Ravichandran		01-24-2024			   US140219: [Unplanned] Salesforce - Add D365 Project ID to T&M when Present on Sales Order
*************************************************************************************************/
public class TMsSelector extends fflib_SObjectSelector implements ITMsSelector {

    public static ITMsSelector newInstance(){
        return (ITMsSelector) Application.Selector.newInstance(TM__c.SObjectType);
    }

    public SObjectType getSObjectType() {
        return TM__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
                TM__c.Account_Executive__c,
                TM__c.Alternate_Site_Address__c,
                TM__c.Bill_to_Customer__c,
                TM__c.Billing_Instructions__c,
                TM__c.Billing_Rule_Id__c,
                TM__c.Certified_PW_Job__c,
                TM__c.Contact__c,
                TM__c.Contract__c,
                TM__c.Create_Site_Address__c,
                TM__c.CreatedById,
                TM__c.CreatedDate,
                TM__c.Customer_PO_No__c,
                TM__c.Day_of_Job__c,
                TM__c.Description__c,
                TM__c.Desired_Scheduled_Date__c,
                TM__c.Emergency_TM__c,
                TM__c.From_Sales_Quote__c,
                TM__c.Id,
                TM__c.Internal_Comments__c,
                TM__c.Invoiced_Lines__c,
                TM__c.IsDeleted,
                TM__c.LastModifiedById,
                TM__c.LastModifiedDate,
                TM__c.Lump_Sum_Order__c,
                TM__c.Manual_Closed_At__c,
                TM__c.Manual_Closed_By__c,
                TM__c.Max_Line_No__c,
                TM__c.Name,
                TM__c.Note__c,
                TM__c.Old_Id__c,
                TM__c.Order_Date__c,
                TM__c.OwnerId,
                TM__c.Prevailing_Wage_Job__c,
                TM__c.Print_Site_Name__c,
                TM__c.Project_Coordinator__c,
                TM__c.Ready_to_Close__c,
                TM__c.RecordTypeId,
                TM__c.Rate_Sheet__c,
                TM__c.Sales_Invoice__c,
                TM__c.Sales_Order__c,
                TM__c.Sales_Order_Type__c,
                TM__c.Scheduled_Date__c,
                TM__c.Scheduled_Date_Weekend__c,
                TM__c.Service_Center__c,
                TM__c.Site_City__c,
                TM__c.Site_Contact_2__c,
                TM__c.Site_Contact__c,
                TM__c.Site_Country__c,
                TM__c.Site_Email_Address__c,
                TM__c.Site_Name__c,
                TM__c.Site_Phone_No__c,
                TM__c.Site_Postal_Code__c,
                TM__c.Site_Scope__c,
                TM__c.Site_State__c,
                TM__c.Site_Street__c,
                TM__c.Start_Time__c,
                TM__c.Status__c,
                TM__c.Subsidiary_Company__c,
                TM__c.Tax_Area__c,
                TM__c.Tax_Liable__c,
                TM__c.Total_Amount__c,
                TM__c.Total_Cost__c,
                TM__c.Total_Lines__c,
                TM__c.Total_Profit__c,
                TM__c.Total_Profit_Pct__c,
                TM__c.Total_Tax__c,
                //job task <<
                TM__c.Mobile_TM__c,
                TM__c.Emergency_TM__c,
                //job task >>
                TM__c.Completed_By__c,
				TM__c.Customer_Billing_Instructions__c,
                TM__c.Sales_Order_Instructions__c,
                TM__c.Customer_Comments__c,
                TM__c.LastModifiedDate,
                TM__c.Mobile_First_Save_At__c,
				TM__c.Reviewed_By__c,
                TM__c.Reviewed_Date__c,
                TM__c.Project_Manager_Reviewed__c,
                TM__c.Reviewed_At_Status__c,
                TM__c.Un_invoiced_Reason_Code__c,
                TM__c.D365_Project_ID__c //US140219
        };
    }

    public List<TM__c> selectByIds(Set<Id> tmIds){
        return (List<TM__c>) Database.query(newQueryFactory()
                //job task <<
                .selectField('Service_Center__r.Name')
                .selectField('Service_Center__r.Equipment_Fleet_No_Not_Required__c')
                .selectField('Service_Center__r.Blocked__c') //Ticket#21227
                .selectField('Subsidiary_Company__r.Name')
                .selectField('Sales_Order__r.Name')
                .selectField('Sales_Order__r.Sales_Order_Type__c')
                .selectField('Sales_Order__r.Sales_Order_Type__r.Name')
                .selectField('Sales_Order__r.Sales_Order_Type__r.Job_Task_Template__c')
                .selectField('Sales_Order__r.Manifest_And_Profile__c')
                .selectField('Sales_Order__r.Distance_to_Job_Site__c')
                .selectField('Sales_Order__r.EqaiGeneratorId__c')
                .selectField('Sales_Order__r.EPA_ID__c')
                .selectField('From_Sales_Quote__r.Name')
                .selectField('Contract__r.Name')
                .selectField('Contract__r.ContractNumber')
                .selectField('Bill_to_Customer__r.Name')
                .selectField('Bill_to_Customer__r.Contact_Type_Filter__c') //Ticket#21357
                .selectField('Contact__r.Name')
                .selectField('Contact__r.Blocked__c') //Ticket#21357
                .selectField('Site_Contact_2__r.Blocked__c') //Ticket#21357
                .selectField('Tax_Area__r.Name')
                .selectField('Tax_Area__r.Description__c')
                .selectField('Project_Coordinator__r.Name')
                .selectField('Account_Executive__r.Name')
                .selectField('Alternate_Site_Address__r.Name')
                .selectField('Site_Contact_2__r.Name')
                .selectField('Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c') 
                .selectField('Service_Center__r.Advanced_Disposal__c') //US128845
                                            
                //job task >>
                .setCondition('Id IN :tmIds')
                .toSOQL());
    }

    public List<TM__c> selectCreateInvoiceRequiredFieldsById(Set<Id> idSet) {
        return (List<TM__c>) Database.query(newQueryFactory(false).
                selectField('Id').
                selectField('Sales_Order__c').
                selectField('Sales_Invoice__c').
                selectField('Invoiced_Lines__c').
                selectField('Total_Lines__c').
                selectField('Scheduled_Date__c').
                setCondition('Id IN :idSet').
                toSOQL());
    }

    /*
     *  Ticket#19931
     *      - add Rental_Resource_Type__c
     */
    public List<TM__c> selectByIdWithTMLines(Set<Id> idSet) {

        fflib_QueryFactory qf = newQueryFactory(false);
        qf.selectField(TM__c.Id).
                selectField('Sales_Order__c').
                selectField('Sales_Invoice__c').
                selectField('Invoiced_Lines__c').
                selectField('Total_Lines__c').
                selectField('Scheduled_Date__c').
                setCondition('Id IN :idSet').
                subselectQuery('TM_Lines__r').
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
                selectField('Sales_Invoice_Line__c').setCondition('Invoiced__c <> TRUE');
        String soql = qf.toSOQL();
        System.debug(soql);
        return (List<TM__c>) Database.query(soql);
    }

    public List<TM__c> selectTMLineNOById(Set<Id> idSet) {
        fflib_QueryFactory qf = newQueryFactory(false);
        qf.selectField('Id').
                setCondition('Id IN :idSet').
                subselectQuery('TM_Lines__r').
                selectField('Id').
                selectField('Line_No__c').
                setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.DESCENDING);
        String soql = qf.toSOQL();
        return (List<TM__c>) Database.query(soql);
    }

    public List<TM__c> selectCreateInvoiceHeaderRequiredFieldsById(Set<Id> idSet) {
        return (List<TM__c>) Database.query(newQueryFactory(false).
                selectField('Id').
                selectField('Sales_Order__c').
                selectField('Sales_Invoice__c').
                selectField('Invoiced_Lines__c').
                selectField('Total_Lines__c').
                selectField('Scheduled_Date__c').
                selectField('Bill_to_Customer__c').
                selectField('Bill_to_Customer__c.BillingStreet').
                selectField('Bill_to_Customer__c.BillingCity').
                selectField('Bill_to_Customer__c.BillingStateCode').
                selectField('Bill_to_Customer__c.BillingPostalCode').
                selectField('Bill_to_Customer__c.BillingCountryCode').
                selectField('Bill_to_Customer__c.Payment_Term__c').
                selectField('Bill_to_Customer__c.Payment_Term__r.Due_Date_Calculation__c'). //Ticket#15235
                selectField('Bill_to_Customer__c.Salesperson__c').
                selectField('Bill_to_Customer__c.Customer_Type__c').
                selectField('Sales_Order__c.Payment_Term__c').
                selectField('Sales_Order__c.Payment_Term__r.Due_Date_Calculation__c'). //Ticket#15235
                selectField('Account_Executive__c').
                selectField('Customer_PO_No__c').
                selectField('Service_Center__c').
                selectField('Subsidiary_Company__c').
                selectField('Contact__c').
                selectField('Site_Contact_2__c').
                selectField('Site_Name__c').
                selectField('Site_Street__c').
                selectField('Site_City__c').
                selectField('Site_State__c').
                selectField('Site_Postal_Code__c').
                selectField('Site_Country__c').
                selectField('Site_Contact__c').
                selectField('Site_Phone_No__c').
                selectField('Site_Email_Address__c').
                selectField('Tax_Liable__c').
                selectField('Tax_Area__c').
                selectField('Contract__c').
                selectField('Sales_Order__r.Surcharge_Type__c').
                selectField('Sales_Order__r.Surcharge_Pct__c').
                selectField('Billing_Instructions__c').
                selectField('Internal_Comments__c').
                selectField('Site_Scope__c').
                selectField('Customer_Billing_Instructions__c').
                setCondition('Id IN :idSet').
                setOrdering('Scheduled_Date__c', fflib_QueryFactory.SortOrder.ASCENDING, true).
                addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.ASCENDING).
                toSOQL());
    }

    public List<TM__c> selectPOBySalesOrderId(Set<Id> idSet) {
        return (List<TM__c>) Database.query(
                newQueryFactory(false).
                        selectField('Id').
                        selectField('Sales_Order__c').
                        selectField('Customer_PO_No__c').
                        setCondition('Sales_Order__c IN :idSet AND ' +
                                'Sales_Invoice__r.Document_Status__c <> \'Posted\'').toSOQL());
    }

    public List<TM__c> selectOpenTMsBySalesOrderIdWithLines(Id salesOrderId){
        fflib_QueryFactory tmQueryFactory = newQueryFactory();
        new TMLinesSelector().addQueryFactorySubselect(tmQueryFactory)
                .setCondition('Invoiced__c = false');
        String queryString = tmQueryFactory.setCondition('Sales_Order__c = :salesOrderId ' +
                'AND Status__c != \'Fully Invoiced\' ' +
                'AND Status__c != \'Closed\' ' +
                'AND Status__c != \'Void\'').toSOQL();
        return (List<TM__c>) Database.query(queryString);
    }

    /*
        Sales Order Route
     */
    public List<TM__c> selectTMsBySalesOrderIds(Set<Id> salesOrderIds){
        return (List<TM__c>) Database.query(
                newQueryFactory(false).
                        selectField('Id').
                        selectField('Sales_Order__c').
                        selectField('Prevailing_Wage_Job__c').
                        setCondition('Sales_Order__c IN :salesOrderIds').toSOQL());
    }

    public List<TM__c> selectOpenTMsBySalesOrderIdAndInvoiceIdWithLines(Id salesOrderId, Set<Id> invIds){
        fflib_QueryFactory tmQueryFactory = newQueryFactory();
        new TMLinesSelector().addQueryFactorySubselect(tmQueryFactory);
        String queryString = tmQueryFactory.setCondition('(Sales_Order__c = :salesOrderId AND ' +
                'Sales_Invoice__c = NULL AND Status__c IN (\'Open\',\'Scheduled\',\'Confirmed\',\'Received By Billing\', \'Ready to Bill\'))' +
                'OR (Sales_Order__c = :salesOrderId AND Sales_Invoice__c IN :invIds AND Status__c NOT IN (\'Close\', \'Void\'))').toSOQL();
        return (List<TM__c>) Database.query(queryString);
    }
}