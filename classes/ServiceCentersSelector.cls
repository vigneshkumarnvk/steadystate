/*************************************************************************************************
* Name         :  ServiceCentersSelector
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan      10-13-2024             US127188 - Salesforce - Modifications to allow ESIC Surcharge Type 
*************************************************************************************************/
public class ServiceCentersSelector extends fflib_SObjectSelector implements IServiceCentersSelector{

    public static IServiceCentersSelector newInstance(){
        return (IServiceCentersSelector) Application.Selector.newInstance(Service_Center__c.SObjectType);
    }

    public SObjectType getSObjectType() {
        return Service_Center__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
                Service_Center__c.ADP_Payroll_Batch_ID__c,
                Service_Center__c.Allow_Override_Logo_on_Inv__c,
                Service_Center__c.Checking_Account_1__c,
                Service_Center__c.Checking_Account_2__c,
                Service_Center__c.City__c,
                Service_Center__c.Code__c,
                Service_Center__c.Country__c,
                Service_Center__c.CreatedById,
                Service_Center__c.CreatedDate,
                Service_Center__c.Description__c,
                Service_Center__c.E_Mail__c,
                Service_Center__c.EFT_Address_1__c,
                Service_Center__c.EFT_Address_2__c,
                Service_Center__c.EFT_To_Bank_Name__c,
                Service_Center__c.EFT_To_Street__c,
                Service_Center__c.Equipment_Fleet_No_Not_Required__c,
                Service_Center__c.Fax__c,
                Service_Center__c.Id,
                Service_Center__c.Include_SO_in_EQAI_Invoice_Integration__c,
                Service_Center__c.Logo__c,
                Service_Center__c.Max_No_of_Emergency_T_M__c,
                Service_Center__c.Name,
                Service_Center__c.NAV_ACV_Service_Center_Code__c,
                Service_Center__c.NAV_CCI_Service_Center_Code__c,
                Service_Center__c.NAV_Service_Center_Code__c,
                Service_Center__c.No_PO_s_Allowed__c,
                Service_Center__c.Override_Remittance_on_Invoice__c,
                Service_Center__c.Payroll_CO_Code__c,
                Service_Center__c.Phone__c,
                Service_Center__c.PO_Allow_Blank_SO_with_Direct_GL_Account__c,
                Service_Center__c.Postal_Code__c,
                Service_Center__c.Price_List__c,
                Service_Center__c.Remittance_Address_1__c,
                Service_Center__c.Remittance_Address_2__c,
                Service_Center__c.Remittance_City__c,
                Service_Center__c.Remittance_Country__c,
                Service_Center__c.Remittance_Name2__c,
                Service_Center__c.Remittance_Name__c,
                Service_Center__c.Remittance_Phone__c,
                Service_Center__c.Remittance_Phone_No__c,
                Service_Center__c.Remittance_Post_Code__c,
                Service_Center__c.Remittance_State__c,
                Service_Center__c.Remittance_Street__c,
                Service_Center__c.Sales_Order_No_Series__c,
                Service_Center__c.Shop_Time_Sales_Order__c,
                Service_Center__c.State__c,
                Service_Center__c.Street__c,
                Service_Center__c.Subsidiary_Company__c,
                Service_Center__c.Temporary__c,
                Service_Center__c.TM_No_Series__c,
                Service_Center__c.UEZ_No_Tax_on_PO__c,
                Service_Center__c.Payroll_Tax_Pct__c,
                Service_Center__c.Blocked__c,
                //Ticket#21540 >>
                Service_Center__c.Standard_AC_Opt1__c,
                Service_Center__c.Standard_AC_Opt2__c,
                Service_Center__c.Standard_AC_Opt3__c,
                Service_Center__c.Standard_AC_Opt4__c,
                Service_Center__c.Disposal_Related_Asm_Cont_Opt1__c,
                Service_Center__c.Disposal_Related_Asm_Cont_Opt2__c,
                Service_Center__c.Disposal_Related_Asm_Cont_Opt3__c,
                Service_Center__c.Disposal_Related_Asm_Cont_Opt4__c,
                Service_Center__c.Disposal_Related_Asm_Cont_Opt5__c,
                Service_Center__c.Disposal_Related_Asm_Cont_Opt6__c,
                Service_Center__c.Disposal_Related_Asm_Cont_Opt7__c,
                Service_Center__c.Term_Conditions_Opt1__c,
                Service_Center__c.Term_Conditions_Opt2__c,
                Service_Center__c.Term_Conditions_Opt3__c,
                Service_Center__c.Term_Conditions_Opt4__c,
                Service_Center__c.Term_Conditions_Opt5__c,
                Service_Center__c.Term_Conditions_Opt6__c,
                Service_Center__c.Term_Conditions_Opt7__c,
                Service_Center__c.Term_Conditions_Opt8__c,
                Service_Center__c.Term_Conditions_Opt9__c,
                Service_Center__c.Term_Conditions_Opt10__c,
                Service_Center__c.Term_Conditions_Opt11__c,
                Service_Center__c.Term_Conditions_Opt12__c,
                Service_Center__c.Term_Conditions_Opt13__c,
                Service_Center__c.Term_Conditions_Opt14__c,
                Service_Center__c.Term_Conditions_Opt15__c,
                Service_Center__c.Term_Conditions_Opt16__c,
                Service_Center__c.Term_Conditions_Opt17__c,
                Service_Center__c.Term_Conditions_Opt18__c,
                Service_Center__c.Term_Conditions_Opt19__c,
                Service_Center__c.Term_Conditions_Opt20__c,
                Service_Center__c.Fuel_Surcharge_Pct__c,
                Service_Center__c.Energy_Environmental_Compliance_Pct__c, // Ticket#82356
                Service_Center__c.Billing_Rule__c,
                Service_Center__c.Website__c,
                //Ticket#21540 >>
                Service_Center__c.EEC_Surcharge_Cost_Pct__c, //Ticket#21883 Ticket#82356
                Service_Center__c.Fuel_Surcharge_Cost_Pct__c, //Ticket#21883 
                Service_Center__c.ESIC_Surcharge_Cost_Pct__c,
                Service_Center__c.Prevent_New_and_Cloned_Sales_Orders__c,
                Service_Center__c.Prevent_TM_Creation__c,
                Service_Center__c.Advanced_Disposal__c   
        };
    }

    public List<Service_Center__c> selectById(Set<Id> idSet){
        return (List<Service_Center__c>) Database.query(newQueryFactory(true)
                .selectField('Subsidiary_Company__r.Name')
                .selectField('Subsidiary_Company__r.Billing_Rule__c')
                .selectField('Subsidiary_Company__r.Billing_Rule__r.Name')
                .selectField('Billing_Rule__r.Name')
                .selectField('Prevent_New_and_Cloned_Sales_Orders__c')
                .setCondition('Id IN :idSet')
                .toSOQL());
    }

    public List<Service_Center__c> selectByName(String name){
        return (List<Service_Center__c>) Database.query(newQueryFactory()
                .selectField('Subsidiary_Company__r.Name')
                .selectField('Subsidiary_Company__r.Billing_Rule__c')
                .selectField('Subsidiary_Company__r.Billing_Rule__r.Name')
                .selectField('Billing_Rule__r.Name')
                .setCondition('Name = :name')
                .setLimit(1)
                .toSOQL());
    }

    public List<Service_Center__c> selectAll(){
        return (List<Service_Center__c>) Database.query(newQueryFactory()
                .selectField('Subsidiary_Company__r.Name')
                .selectField('Subsidiary_Company__r.Billing_Rule__c')
                .selectField('Subsidiary_Company__r.Billing_Rule__r.Name')
                .selectField('Billing_Rule__r.Name')
                .selectField('Prevent_New_and_Cloned_Sales_Orders__c')
                .setOrdering('Name', fflib_QueryFactory.SortOrder.ASCENDING)
                .toSOQL());
    }
}