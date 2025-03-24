/*
 *  Ticket#19962
 *      - add Bill_to_Customer_No__r.Type
 *  Ticket#19931
 *      - add Resource_Type__r.Rental_Resource_Type__c to queries.
 *  Ticket#20079
 *      - method: selectCreateInvoiceRequiredFieldsById - add Payment Term to contract
 *   Shahwaz Khan              03-12-2024             Task78375: Salesforce - 5/1 Need for Account Number Validation
     Sanjana                   03-12-2024             Task78376: Salesforce - 7/1 Need for Account Number Validation
     Shahwaz Khan              03-15-2024             Task81352: Salesforce - Add Additional Options to Sales Order Type Field
     Andrew Simons             03-26-2024             Task8099:  Salesforce - Updated EI_Surcharge_Cost_Pct__c to EEC_Surcharge_Cost_Pct__c and Energy_Insurance_Pct to Energy_Environmental_Compliance_Pct
 	 Sanjana				   04/17/2024			  Bug84607: Worker Responsible Field Allowing Inactive Labor Resource to be assigned to Sales Order and Sales Quote
     Andrew Simons             05-13-2024             Task87270: added Sent_to_EQAI_Date__c field
	 Pavithra P				   08-26-2024             DE35161 : Selected contacts in Bill to contact field is not stored in Sales orders
     Prabhu Rathakrishnan      09/09/2024             US121824: Salesforce - Billing Project lookup on Sales Order
	 Prabhu Rathakrishnan 12-14-2023 US127188 - Salesforce - Modifications to allow ESIC Surcharge Type
*/

public class SalesOrdersSelector extends fflib_SObjectSelector implements ISalesOrdersSelector{

    public static ISalesOrdersSelector newInstance() {
        return (ISalesOrdersSelector) Application.Selector.newInstance(Sales_Order__c.SObjectType);
    }

    public SObjectType getSObjectType() {
        return Sales_Order__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
                Sales_Order__c.Id,
                Sales_Order__c.Approved_Profit_Margin__c,
                Sales_Order__c.Approval_Step_Completed__c,
                Sales_Order__c.Approval_Status__c,
                Sales_Order__c.Approved__c,
                Sales_Order__c.Approved_Amount__c,
                Sales_Order__c.Approved_Level__c,
                Sales_Order__c.Allow_Convert__c,
                Sales_Order__c.Account_Executives__c,
                Sales_Order__c.Alternate_Site_Address__c,
                Sales_Order__c.Applicable_Taxes__c,
                Sales_Order__c.Applicable_Taxes_Quote__c,
//                Sales_Order__c.Amount__c,
                Sales_Order__c.Any_Deviations__c,
                Sales_Order__c.Billing_Type__c,
                Sales_Order__c.Bill_to_Customer_No__c,
                Sales_Order__c.Bill_to_Contact__c,
                Sales_Order__c.Quote_Contact__c,
                Sales_Order__c.Billing_Instructions__c,
                Sales_Order__c.Contract__c,
                Sales_Order__c.Contract_Name__c, //67202
                Sales_Order__c.CreatedDate,
                Sales_Order__c.CreatedById,
                Sales_Order__c.Custom_Assumptions1__c,
                Sales_Order__c.Custom_Assumptions2__c,
                Sales_Order__c.Custom_Assumptions3__c,
                Sales_Order__c.Custom_Assumptions4__c,
                Sales_Order__c.Custom_Assumptions5__c,
                Sales_Order__c.Custom_Assumptions6__c,
                Sales_Order__c.Custom_Assumptions7__c,
                Sales_Order__c.Custom_Assumptions8__c,
                Sales_Order__c.Custom_Assumptions9__c,
                Sales_Order__c.Custom_Assumptions10__c,
                Sales_Order__c.Certified_PW_Job__c,
                Sales_Order__c.CMR_Description__c,
                Sales_Order__c.Country__c,
                Sales_Order__c.City__c,
                Sales_Order__c.Customer_PO_No__c,
                Sales_Order__c.EqaiGeneratorId__c,
                Sales_Order__c.EPA_ID__c,
//                Sales_Order__c.Customer_Name__c,
                Sales_Order__c.Create_Site_Address__c,
                Sales_Order__c.Charges_For_Labor__c,
                Sales_Order__c.Characterization_Of_Waste__c,
                Sales_Order__c.Convert_Count__c,
                Sales_Order__c.Cylinders_Require_Evaluation__c,
                Sales_Order__c.Client_Is_Responsible__c,
                Sales_Order__c.Document_Type__c,
                Sales_Order__c.Document_Status__c,
                Sales_Order__c.Disposal_Pricing__c,
                Sales_Order__c.Do_Not_Reset_Sync_Flag__c,
                Sales_Order__c.Daily_Rate__c,
                Sales_Order__c.Emergency_Sales_Order__c,
                Sales_Order__c.Estimated_Revenue__c,
                Sales_Order__c.End_Date__c,
                Sales_Order__c.Expendables__c,
                Sales_Order__c.From_Sales_Quote__c,
                Sales_Order__c.Fax_No__c,
                Sales_Order__c.First_Hour_Of_Loading__c,
                Sales_Order__c.Free_Access__c,
                Sales_Order__c.Generate_Before_Final__c,
                Sales_Order__c.Inter_Company_Job__c,
                Sales_Order__c.Invoice_Of_Work__c,
                Sales_Order__c.In_The_Event__c,
                Sales_Order__c.Internal_Comments__c,
                Sales_Order__c.LastModifiedDate,
                Sales_Order__c.LastModifiedById,
                Sales_Order__c.Lump_Sum__c,
                Sales_Order__c.Lab_Packs_Rate__c,
//                Sales_Order__c.Misc_Sales__c,
                Sales_Order__c.Minimum_Disposal_Fee__c,
                Sales_Order__c.Minimum_Disposal_Charge__c,
                Sales_Order__c.Maximum_Weight__c,
                Sales_Order__c.Manifest_And_Profile__c,
                Sales_Order__c.Name,
                Sales_Order__c.No__c,
                Sales_Order__c.NAV_Job_No__c,
                Sales_Order__c.Net_Due_Day__c,
                Sales_Order__c.OwnerId,
                Sales_Order__c.Off_Specification__c,
                Sales_Order__c.Overtime_Rate__c,
                Sales_Order__c.Overtime_Rate_Description__c,
                Sales_Order__c.Order_Description__c,
                Sales_Order__c.Order_Type_Description__c,
                Sales_Order__c.Opportunity__c,
                Sales_Order__c.Pay_Rule__c,
                Sales_Order__c.Prevailing_Wage_Job__c,
                Sales_Order__c.RecordTypeId,
                Sales_Order__c.Project_Coordinator__c,
                Sales_Order__c.Postal_Code__c,
                Sales_Order__c.Phone_No__c,
                Sales_Order__c.Phone_Ext__c,
                Sales_Order__c.Payment_Term__c,
                Sales_Order__c.Print_Site_Name__c,
                Sales_Order__c.Portal_Basis_Adv__c,
                Sales_Order__c.Portal_Basis__c,
                Sales_Order__c.Pricing__c,
                Sales_Order__c.Pending_Approval_Level__c,
                Sales_Order__c.Pending_Approval_From__c,
                Sales_Order__c.Quote_Date__c,
                Sales_Order__c.Quote_Status__c,
                Sales_Order__c.Quote_Valid_30__c,
                Sales_Order__c.Service_Center__c,
                Sales_Order__c.Service_Center_Code__c,
                Sales_Order__c.Sales_Order_Type__c,
                Sales_Order__c.State__c,
                Sales_Order__c.Site_Name__c,
                Sales_Order__c.Street__c,
                Sales_Order__c.Site_Street__c,
                Sales_Order__c.Site_City__c,
                Sales_Order__c.Site_Country__c,
                Sales_Order__c.Site_State__c,
                Sales_Order__c.Site_Postal_Code__c,
                Sales_Order__c.Site_Phone_No__c,
                Sales_Order__c.Site_Email_Address__c,
                Sales_Order__c.Site_Scope__c,
                Sales_Order__c.SO_sent_to_EQAI__c,
                Sales_Order__c.Sent_to_EQAI_Date__c, //ticket #87270
                Sales_Order__c.Sync_d__c,
                Sales_Order__c.Sage_Job_No__c,
                Sales_Order__c.Start_Date__c,
                Sales_Order__c.Site_Contact__c,
                Sales_Order__c.Service_Center__c,
                Sales_Order__c.Subsidiary_Company__c,
                Sales_Order__c.SystemModstamp,
                Sales_Order__c.Site_Contact_2__c,
                Sales_Order__c.Surcharge_Type__c,
                Sales_Order__c.Surcharge_Pct__c,
                Sales_Order__c.Surcharge_Amount__c,
                Sales_Order__c.SHippable_Containers__c,
                Sales_Order__c.Total_Amount__c,
                Sales_Order__c.Total_Margin_Pct__c,
                Sales_Order__c.Total_Amount_Incl_Tax__c,
                Sales_Order__c.Order_Total_Amount__c,
                Sales_Order__c.Order_Total_Amount_Incl_Tax__c,
                Sales_Order__c.Order_Total_Tax__c,
                Sales_Order__c.Total_Cost__c,
                Sales_Order__c.Total_Profit__c,
                Sales_Order__c.Total_Profit_Pct__c,
                Sales_Order__c.Total_Tax__c,
                Sales_Order__c.Tax_Liable__c,
                Sales_Order__c.Tax_Area__c,
                Sales_Order__c.Rate_Time_Definitions__c,
                Sales_Order__c.Unless_Superseded__c,
                Sales_Order__c.Waste_Disposal_And_Ancillary__c,
                Sales_Order__c.Rate_Sheet__c,
                Sales_Order__c.Quote_Type__c,
                Sales_Order__c.Billing_Rule__c,
                Sales_Order__c.Duration__c,
                Sales_Order__c.Estimated_Job_Start_Date__c,
                Sales_Order__c.Estimated_Job_End_Date__c,
                Sales_Order__c.Estimated_Job_Start_Time__c,
                Sales_Order__c.Estimated_Job_End_Time__c,
                Sales_Order__c.Include_Weekend__c,
                Sales_Order__c.Include_Holiday__c,
                Sales_Order__c.Mobile_Email__c,
                Sales_Order__c.Billing_Rule_Not_Required__c,
                Sales_Order__c.Job_Description__c,
                Sales_Order__c.Charge_Rinse_Out_Fee__c,
                Sales_Order__c.Distance_to_Job_Site__c,
                Sales_Order__c.Customer_Billing_Instructions__c,
                Sales_Order__c.Sales_Order_Instructions__c,
				Sales_Order__c.Expired__c,
                Sales_Order__c.Blocked__c, //Ticket#21908
                Sales_Order__c.Term_Conditions_Opt20__c,
				Sales_Order__c.Default_Billing_Rule_2023__c, //Ticket#24559
                Sales_Order__c.Default_Billing_Rule_To_Display__c, //Ticket#24559
                Sales_Order__c.Approved_Date__c, //Ticket#24688
                Sales_Order__c.Operating_Expense_Cost_Pct__c, //Ticket#24650
                Sales_Order__c.Allow_Edit__c, //Ticket#27427
                Sales_Order__c.D365_Project_ID__c, // Ticket#67141
                Sales_Order__c.Name_of_Worker_Responsible__c, //ticket#76558
                Sales_Order__c.Worker_Responsible__c, //ticket#76558
                Sales_Order__c.EQAI_Response__c, //Ticket#77452
                Sales_Order__c.Disposal_Billing_Method__c,
                Sales_Order__c.Bill_To_Contacts__c,
                Sales_Order__c.Bill_To_Contacts_Link__c,
                Sales_Order__c.EQAI_Billing_Project_Name__c

        };
    }

    public List<Sales_Order__c> selectById(Set<Id> idSet){
        System.debug('newQueryFactory====>'+newQueryFactory());
        return (List<Sales_Order__c>) Database.query(newQueryFactory()
                .selectField('Bill_to_Customer_No__r.Name')
                .selectField('Id')
                .selectField('Bill_to_Customer_No__r.Inter_co_Account__c') //Ticket#21211
                
                .selectField('Duration__c')
                .selectField('Service_Center__r.Name')
                .selectField('Service_Center__r.Subsidiary_Company__c') //Ticket#20977
                .selectField('Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c') //Ticket#76558
                .selectField('Subsidiary_Company__r.Name')
                .selectField('Payment_Term__r.Name')
                .selectField('Owner.Name')
                .selectField('Billing_Owner__r.Name')
                .selectField('Sales_Order_Type__r.Name')
                .selectField('Sales_Order_Type__r.Single_Sales_Order__c')
                .selectField('Opportunity__r.Name')
                .selectField('Sales_Order_Type__r.Emergency_Response__c')
                .selectField('Sales_Order_Type__r.Job_Task_Template__c')
                .selectField('Sales_Order_Type__r.Blocked__c')
                .selectField('SO_sent_to_EQAI__c')
                .selectField('Sent_to_EQAI_Date__c') //ticket #87270
                .selectField('SO_Submitted_to_EQAI__c')
                .selectField('From_Sales_Quote__r.Name')
                .selectField('Bill_to_Customer_No__r.Payment_Term__c')
                .selectField('Account_Executives__r.Name')
                .selectField('Project_Coordinator__r.Name') 
                .selectField('Name_of_Worker_Responsible__r.Name') //ticket#76558
                .selectField('Name_of_Worker_Responsible__r.Description__c') //ticket#76558
                .selectField('Name_of_Worker_Responsible__r.RSG_EIN__c') //ticket#76558
                .selectField('Billing_Rule__r.Name')
                .selectField('Billing_Rule__r.Enable_Weekly_Total_Calculation__c') //Ticket#20496
                .selectField('Pay_Rule__r.Name')
                .selectField('Pay_Rule__r.Type__c')
                .selectField('Alternate_Site_Address__r.Name')
                .selectField('Bill_to_Contact__r.Name')
                .selectField('Bill_to_Contact__r.Blocked__c') //Ticket#21357
                .selectField('Bill_to_Customer_No__r.AccountNumber')
                .selectField('Bill_to_Customer_No__r.Credit_Hold__c')
                .selectField('Bill_to_Customer_No__r.Emergency__c')
                .selectField('From_Sales_Quote__r.Name')
                .selectField('From_Sales_Quote__r.Service_Center__c') //Ticket#23587
                .selectField('Contract__r.Name')
                .selectField('Contract__r.ContractNumber')
                .selectField('Contract__r.Billing_Rule__c')
                .selectField('Contract__r.Billing_Rule__r.Name')
                .selectField('EqaiGeneratorId__c')
                .selectField('EPA_ID__c')
                //billing rule mapping <<
                .selectField('Contract__r.Billing_Rule__r.Quote_Order_Assumption__c')
                //billing rule mapping >>
                .selectField('Contract__r.Billing_Rule__r.Enable_Weekly_Total_Calculation__c') //Ticket#20496
                .selectField('Contract__r.Surcharge_Type__c')
                .selectField('Contract__r.Surcharge_Pct__c')
                .selectField('Contract__r.Status')
                .selectField('Contract__r.StartDate')
                .selectField('Contract__r.EndDate')
                .selectField('Tax_Area__r.Name')
                .selectField('Tax_Area__r.Description__c')
                .selectField('Contract__r.Has_Lump_Sum_Lines__c')
                .selectField('Site_Contact_2__r.Name')
                .selectField('Site_Contact_2__r.Blocked__c') //Ticket#21357
                .selectField('Quote_Contact__r.Name')
                .selectField('Bill_to_Customer_No__r.ParentId')
                .selectField('Rate_Sheet__r.Name')
                .selectField('Bill_To_Contacts__c')
                .selectField('Bill_To_Contacts_Link__c')                                     
                //aura >>
                .selectField('Bill_to_Customer_No__r.Contact_Type_Filter__c') //billing instruction
                .selectField('Bill_to_Customer_No__r.PO_Number_Type__c') //billing instruction
                .selectField('Bill_to_Customer_No__r.Type')
                .selectField('Bill_to_Customer_No__r.Subsidiary_Company__c') //Ticket#20977
                .selectField('Bill_to_Customer_No__r.Subsidiary_Company__r.Name') //Ticket#20977
                .selectField('Bill_to_Customer_No__r.Customer_Status__c') //Ticket#23145
                .selectField('Bill_to_Customer_No__r.Sage_Customer_No__c') 
                .selectField('Bill_to_Customer_No__r.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c')  // Task#81352                                   
                //Ticket21540 >>
                .selectField('Service_Center__r.Standard_AC_Opt1__c')
                .selectField('Service_Center__r.Standard_AC_Opt2__c')
                .selectField('Service_Center__r.Standard_AC_Opt3__c')
                .selectField('Service_Center__r.Standard_AC_Opt4__c')
                .selectField('Service_Center__r.Disposal_Related_Asm_Cont_Opt1__c')
                .selectField('Service_Center__r.Disposal_Related_Asm_Cont_Opt2__c')
                .selectField('Service_Center__r.Disposal_Related_Asm_Cont_Opt3__c')
                .selectField('Service_Center__r.Disposal_Related_Asm_Cont_Opt4__c')
                .selectField('Service_Center__r.Disposal_Related_Asm_Cont_Opt5__c')
                .selectField('Service_Center__r.Disposal_Related_Asm_Cont_Opt6__c')
                .selectField('Service_Center__r.Disposal_Related_Asm_Cont_Opt7__c')
                .selectField('Service_Center__r.Term_Conditions_Opt1__c')
                .selectField('Service_Center__r.Term_Conditions_Opt2__c')
                .selectField('Service_Center__r.Term_Conditions_Opt3__c')
                .selectField('Service_Center__r.Term_Conditions_Opt4__c')
                .selectField('Service_Center__r.Term_Conditions_Opt5__c')
                .selectField('Service_Center__r.Term_Conditions_Opt6__c')
                .selectField('Service_Center__r.Term_Conditions_Opt7__c')
                .selectField('Service_Center__r.Term_Conditions_Opt8__c')
                .selectField('Service_Center__r.Term_Conditions_Opt9__c')
                .selectField('Service_Center__r.Term_Conditions_Opt10__c')
                .selectField('Service_Center__r.Term_Conditions_Opt11__c')
                .selectField('Service_Center__r.Term_Conditions_Opt12__c')
                .selectField('Service_Center__r.Term_Conditions_Opt13__c')
                .selectField('Service_Center__r.Term_Conditions_Opt14__c')
                .selectField('Service_Center__r.Term_Conditions_Opt15__c')
                .selectField('Service_Center__r.Term_Conditions_Opt16__c')
                .selectField('Service_Center__r.Term_Conditions_Opt17__c')
                .selectField('Service_Center__r.Term_Conditions_Opt18__c')
                .selectField('Service_Center__r.Term_Conditions_Opt19__c')
                .selectField('Service_Center__r.Term_Conditions_Opt20__c')
                .selectField('Service_Center__r.Billing_Rule__c')
                .selectField('Service_Center__r.Billing_Rule__r.Name')
                .selectField('Service_Center__r.Billing_Rule__r.Enable_Weekly_Total_Calculation__c')
				.selectField('Service_Center__r.Prevent_TM_Creation__c') //Ticket#27427
                .selectField('Subsidiary_Company__r.Billing_Rule__c')
                .selectField('Subsidiary_Company__r.Billing_Rule__r.Name')
                .selectField('Subsidiary_Company__r.Billing_Rule__r.Enable_Weekly_Total_Calculation__c')
                .selectField('Service_Center__r.Advanced_Disposal__c')
                .selectField('Disposal_Billing_Method__c')
                .selectField('EQAI_Billing_Project_Name__c')
                .selectField('EQAI_Billing_Project_Id__c')
                .selectField('Is_New_D365_Project__c')
                .selectField('D365_Project_ID__c') 
                //Ticket21540 <<
                .setCondition('Id IN :idSet').toSOQL());
    }

    public List<Sales_Order__c> selectCreateInvoiceRequiredFieldsById(Set<Id> idSet){
        return (List<Sales_Order__c>) Database.query(newQueryFactory(true).
                selectField('Id').
                selectField('Bill_to_Customer_No__c').
                selectField('Bill_to_Customer_No__c.BillingStreet').
                selectField('Bill_to_Customer_No__c.BillingCity').
                selectField('Bill_to_Customer_No__c.BillingStateCode').
                selectField('Bill_to_Customer_No__c.BillingPostalCode').
                selectField('Bill_to_Customer_No__c.BillingCountryCode').
                selectField('Bill_to_Customer_No__c.Payment_Term__c').
                selectField('Bill_to_Customer_No__r.Payment_Term__r.Due_Date_Calculation__c').
                selectField('Bill_to_Customer_No__r.Customer_Type__c').
                selectField('Payment_Term__r.Due_Date_Calculation__c').
                selectField('Bill_to_Customer_No__c.Salesperson__c').
                selectField('Bill_to_Customer_No__r.Contact_Type_Filter__c').
                selectField('Payment_Term__c').
                selectField('Account_Executives__c').
                selectField('Customer_PO_No__c').
                selectField('Service_Center__c').
                selectField('Subsidiary_Company__c').
                selectField('Bill_to_Contact__c').
                selectField('Bill_to_Contact__r.Blocked__c'). //Ticket#21357
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
                selectField('Contract__r.Payment_Term__c').
                selectField('Contract__r.Payment_Term__r.Due_Date_Calculation__c').
                selectField('Contract__r.EndDate').
                selectField('Surcharge_Type__c').
                selectField('Surcharge_Pct__c').
                selectField('Billing_Instructions__c').
                selectField('Internal_Comments__c').
                selectField('Site_Scope__c').
                selectField('Customer_Billing_Instructions__c').
                selectField('Sales_Order_Instructions__c').
                selectField('Bill_to_Customer_No__r.Type').
                selectField('Service_Center__r.Fuel_Surcharge_Cost_Pct__c'). //Ticket#21883
                selectField('Service_Center__r.EEC_Surcharge_Cost_Pct__c'). //Ticket#21883
                selectField('Subsidiary_Company__r.Fuel_Surcharge_Cost_Pct__c'). //Ticket#21883
                selectField('Subsidiary_Company__r.EEC_Surcharge_Cost_Pct__c'). //Ticket#21883
                selectField('Service_Center__r.ESIC_Surcharge_Cost_Pct__c').
                selectField('Subsidiary_Company__r.ESIC_Surcharge_Cost_Pct__c').
                selectField('Disposal_Billing_Method__c').
                setCondition('Id IN :idSet').toSOQL());
    }

    public List<Sales_Order__c> selectByIdWithLinesForClone(Set<Id> idSet){
        fflib_QueryFactory qf = newQueryFactory(true);
        qf.selectField('IsDeleted').
            	selectField('Customer_PO_No__c').
            selectField('Is_New_D365_Project__c').
                selectField('LastActivityDate').
                selectField('LastViewedDate').
                selectField('LastReferencedDate').
                selectField('Bill_to_Customer_No__r.ParentId').
                selectField('Sales_Order_Type__r.Blocked__c').
                selectField('Bill_to_Customer_No__r.Emergency__c').
                selectField('Sales_Order_Type__r.Emergency_Response__c').
                selectField('Contract__r.Status').
                selectField('Contract__r.Billing_Rule__c').
                selectField('Pay_Rule__r.Blocked__c').
                selectField('Tax_Area__r.Blocked__c').
                selectField('Bill_to_Customer_No__r.Type').
                selectField('EQAI_Billing_Project_Id__c').
                //Ticket#21357 >>
                selectField('Bill_to_Customer_No__r.Name').
                selectField('Quote_Contact__r.Contact_Type__c').
                selectField('Quote_Contact__r.Blocked__c').
                selectField('Quote_Contact__r.Name').
                selectField('Bill_to_Contact__r.Contact_Type__c').
                selectField('Bill_to_Contact__r.Blocked__c').
                selectField('Bill_to_Contact__r.Name').
                selectField('Site_Contact_2__r.Contact_Type__c').
                selectField('Site_Contact_2__r.Blocked__c').
                selectField('Site_Contact_2__r.Name').
                //Ticket#21357 <<
                setCondition('Id IN :idSet');
                //Sales Order Job Task Info
                qf.subselectQuery('Sales_Order_Job_Tasks__r')
                .selectField('Name')
                .selectField('Sales_Order__c')
                .selectField('Line_No__c')
                .selectField('Job_Task_Template__c');
                //Sales Line Info
                qf.subselectQuery('Sales_Lines__r').
                selectField('IsDeleted').
                selectField('CreatedDate').
                selectField('CreatedById').
                selectField('LastModifiedDate').
                selectField('LastModifiedById').
                selectField('SystemModstamp').
                selectField('LastViewedDate').
                selectField('LastReferencedDate').
                selectField('Line_No__c').
                selectField('Description__c').
                selectField('Unit_Price__c').
                selectField('Tax__c').
                selectField('Quantity__c').
                selectField('Resource__c').
                selectField('Unit_of_Measure__c').
                selectField('Category__c').
                selectField('Scheduled_Date__c').
                selectField('Resource_Type__c').
                selectField('Tax_Pct__c').
                selectField('Tax_Group__c').
                selectField('Contract_Line__c').
                selectField('Line_Amount__c').
                selectField('Line_Amt_Incl_Tax__c').
                selectField('Contract_Regular_Rate__c').
                selectField('Unit_Cost__c').
                selectField('Line_Cost__c').
                selectField('Quote_Line__c').
                selectField('Regular_Rate__c').
                selectField('Overtime_Rate__c').
                selectField('Premium_Rate__c').
                selectField('Contract_Premium_Rate__c').
                selectField('Contract_Overtime_Rate__c').
                selectField('UOM_Qty__c').
                selectField('Process_Code__c').
                selectField('Regular_Hours__c').
                selectField('Overtime_Hours__c').
                selectField('Premium_Hours__c').
                selectField('Markup__c').
                selectField('Markup_Option__c').
                selectField('System_Calculated_Line__c').
                selectField('Profit_Margin__c').
                selectField('Bill_as_Lump_Sum__c').
                selectField('Non_Billable__c').
                selectField('xRegular_Rate__c').
                selectField('xOvertime_Rate__c').
                selectField('xPremium_Rate__c').
                selectField('xUnit_Price__c').
                selectField('Number_of_Day__c').
                selectField('Premium_Day__c').
                selectField('Regular_Day__c').
                selectField('Overtime_Day__c').
                selectField('Pricing_Source_2__c').
                selectField('Bundle_Line__c').
                selectField('Bundle_Line__r.Line_No__c').
                selectField('xUnit_Cost__c').
                selectField('xLine_Amount__c').
                selectField('xLine_Cost__c').
                selectField('Rolled_up_Unit_Price__c').
                selectField('Container_Size__c').
                selectField('Cost_Method__c').
                selectField('Facility__c').
                selectField('Manually_Entered_Cost__c').
                selectField('Min_Sell_Qty__c').
                selectField('Resource_Type_UOM__c').
                selectField('Resource_UOM__c').
                selectField('Scheduled_Date__c').
                selectField('Unit_Weight_Vol__c').
                selectField('Bundle_Pricing_Method__c').
                selectField('Sales_Order_Job_Task__c').
                selectField('Sales_Order_Job_Task__r.Line_No__c').
                //Ticket#22710 >>
                selectField('Regular_Unit_Cost__c').
                selectField('Overtime_Unit_Cost__c').
                selectField('Double_Time_Unit_Cost__c').
                //Ticket#22710 <<                
                //ticket 19130 <<
                //selectField('Parent_Line__r.Line_No__c').
                selectField('Is_Child_Resource__c').
                selectField('Dereferenced_Child_Resource__c').
                //ticket 19130 >>
                selectField('Wizard_Question_Answered__c').
                //job task >>
                selectField('Resource__r.Blocked__c').
                selectField('Resource_Type__r.Blocked__c').
                selectField('Sales_Order__c');
        String soql = qf.toSOQL();
        return (List<Sales_Order__c>) Database.query(soql);
    }

    //Ticket#20749 - add contract status
    public List<Sales_Order__c> selectConvertRelatedFieldsById(Set<Id> idSet){
        return (List<Sales_Order__c>) Database.query(newQueryFactory().
                selectField('Bill_to_Customer_No__c.RecordTypeId').
                selectField('Bill_to_Customer_No__r.Emergency__c').
                selectField('Bill_to_Customer_No__r.Type').
                selectField('Sales_Order_Type__r.Emergency_Response__c').
                selectField('Sales_Order_Type__r.Blocked__c').
                selectField('Contract__r.Status').
                selectField('Name_of_Worker_Responsible__r.status__c'). //ticket#84607
                selectField('Name_of_Worker_Responsible__r.status__c').
				selectField('Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c').                                       
                selectField('Is_New_D365_Project__c').
                selectField('D365_Project_ID__c').                                                     
                setCondition('Id IN :idSet').toSOQL());
    }

    public List<Sales_Order__c> selectTMsById(Set<Id> idSet) {
        fflib_QueryFactory qf = newQueryFactory(false);
        qf.selectField('Id').
                selectField('Name').
                selectField('Sales_Order_Type__r.Emergency_Response__c').
                setCondition('Id IN :idSet').
                subselectQuery('Service_Orders__r').
                selectField('Id').
                setCondition('Status__c != \'Void\' ').
                setOrdering('Scheduled_Date__c', fflib_QueryFactory.SortOrder.ASCENDING, true).
                addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.ASCENDING, true);
        String soql = qf.toSOQL();
        return (List<Sales_Order__c>) Database.query(soql) ;
    }

    public List<Sales_Order__c> selectServiceCenterById(Set<Id> idSet){
        return (List<Sales_Order__c>) Database.query(newQueryFactory().selectField('Service_Center__c').setCondition('Id IN :idSet').toSOQL());
    }

    public List<Sales_Order__c> selectServiceCenterAndSubCompanyById(Set<Id> idSet){
        return (List<Sales_Order__c>) Database.query(newQueryFactory().
                selectField('Service_Center__c').
                selectField('Service_Center__r.Subsidiary_Company__c').
                selectField('Subsidiary_Company__c').
                selectField('Bill_to_Customer_No__c').
                selectField('Bill_to_Customer_No__r.ParentId').
                selectField('Bill_to_Customer_No__r.Type').
                selectField('Bill_to_Customer_No__r.Name').
                setCondition('Id IN :idSet').toSOQL());
    }

    public List<Sales_Order__c> selectQuotesByBillToCustomer(Id billToCustomer){
        return (List<Sales_Order__c>) Database.query(
                newQueryFactory(false).
                selectField('Id').
                selectField('Name').
                selectField('Order_Description__c').
                setCondition('Bill_to_Customer_No__c =: billToCustomer AND ' +
                        'Document_Type__c = \'Sales Quote\' AND ' +
                        'Allow_Convert__c = TRUE').toSOQL()); // updated Allow_Convert__c formula condition Quote_Type__c <> null
    }


    public List<Sales_Order__c> selectConvertCountById(Set<Id> idSet) {
        return (List<Sales_Order__c>) Database.query(newQueryFactory(false).
                selectField('Id').selectField('Convert_Count__c').selectField('Quote_Status__c').
                setCondition('Id IN :idSet').toSOQL());
    }

    public List<Sales_Order__c> selectByIdWithSalesLines(Set<Id> ids){
        fflib_QueryFactory salesOrderQueryFactory = newQueryFactory();
        new SalesLinesSelector().addQueryFactorySubselect(salesOrderQueryFactory);
        return (List<Sales_Order__c>) Database.query(salesOrderQueryFactory
                .setCondition('Id IN :ids')
                .toSOQL());
    }

    public List<Sales_Order__c> selectByIdWithLinesAndProcessSteps(Set<Id> idSet) {
        fflib_QueryFactory salesOrderQueryFactory = newQueryFactory();
        new SalesLinesSelector().addQueryFactorySubselect(salesOrderQueryFactory)
                .selectField('Resource_Type__r.Fuel_Fired_Equipment__c')
                .selectField('Resource_Type__r.Fleet_No_Required__c')
                .selectField('Resource_Type__r.Rental_Resource_Type__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Resource__r.Name')
                .selectField('Bundle_Line__r.Line_No__c')
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING,true);
                
        salesOrderQueryFactory.selectField('Bill_to_Customer_No__r.Name')
            .selectField('Service_Center__r.Name')
            .selectField('Sales_Order_Type__c')
            .selectField('Owner.Name')
            .selectField('CreatedBy.Name')
            .selectField('Pay_Rule__r.Name')
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
        return (List<Sales_Order__c>) Database.query(salesOrderQueryFactory.toSOQL());
    }

    public List<Sales_Order__c> selectByContractIdsWithLines(Set<Id> contractIds) {
        fflib_QueryFactory salesOrderQueryFactory = newQueryFactory();
        //Ticket#21540 >>
        salesOrderQueryFactory.selectField('Service_Center__r.Fuel_Surcharge_Pct__c')
            .selectField('Service_Center__r.Energy_Environmental_Compliance_Pct__c');
        //Ticket#21540 <<
        //ticket 19672 <<
        //new SalesLinesSelector().addQueryFactorySubselect(salesOrderQueryFactory);
        new SalesLinesSelector()
                .addQueryFactorySubselect(salesOrderQueryFactory)
                .selectField('Sales_Order_Job_Task__r.Line_No__c');
        //ticket 19672 >> 
        salesOrderQueryFactory.setCondition('Contract__c IN :contractIds AND Document_Status__c = \'Open\'');
        return (List<Sales_Order__c>) Database.query(salesOrderQueryFactory.toSOQL());
    }
}