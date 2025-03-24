/*************************************************************************************************
* Name         :  CompanySettingUtil
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan      10-13-2024             US127188 - Salesforce - Modifications to allow ESIC Surcharge Type 
*************************************************************************************************/
public with sharing class CompanySettingUtil {    
    /*
     *  Ticket#24469 - add Payroll blockout time related fields: Payroll_Blockout_Start_Hour__c, Payroll_Blockout_Start_Minute__c, Payroll_Blockout_End_Minute__c
     *  Ticket#24559 add 2023 Billing Rule Start Date to acv setting query
     */
    public static Company_Setting__mdt acvSetting{
        get{
            if(acvSetting == null){
                acvSetting = [
                        SELECT Id, Name__c, Retainage_Receivable_GL_Account_Id__c,Default_Retainage_Resource_Id__c,Rinse_Out_Fee_Resource_Id__c,
                                API2PDF_Key__c, Default_Resource_Type_for_FA__c, Fixed_Price_Job_Resource__c, Mobile_TM_Version_No__c, Sandbox__c,
                                Sandbox_Email_Recipients__c, X2023_Billing_Rule_Start_Date__c, TM_Signature_Site_URL__c, Payroll_Blockout_Start_Hour__c, Payroll_Blockout_Start_Minute__c, Payroll_Blockout_End_Minute__c,
                                Quote_Signature_Token_Expiration_Hours__c, TM_Signature_Token_Expiration_Hours__c
                        FROM Company_Setting__mdt
                        WHERE Label = 'ACV'
                        LIMIT 1];
            }
            return acvSetting;
        }
        private set;
    }

    public static Company_Setup__c defaultCompanySetup {
        get{
            if (defaultCompanySetup == null) {
                defaultCompanySetup = CompanyMgmt.getCompanySetup();
            }
            return defaultCompanySetup;
        }
        private set;
    }

    public static Boolean isSandbox(){
        return acvSetting.Sandbox__c;
    }

    public static List<String> getSandboxEmailRecipients(){
        List<String> emails = new List<String>();
        if(String.isNotBlank(acvSetting.Sandbox_Email_Recipients__c)){
            emails = acvSetting.Sandbox_Email_Recipients__c.split(';');
        }
        return emails;
    }

    //Ticket#21883 - add Surcharge_Cost_Pct__c
    public static Subsidiary_Company__c getSubsidiaryCompanySetup(Id subsidiaryCompanyId){
        return [SELECT Id, Name, Disable_Customer_Portal__c, Display_Name__c, QtC_Enabled__c,
                Watermark__c, Billing_Rule__c, Fuel_Surcharge_Cost_Pct__c, EEC_Surcharge_Cost_Pct__c,ESIC_Surcharge_Cost_Pct__c
                    FROM Subsidiary_Company__c WHERE Id = :subsidiaryCompanyId LIMIT 1];
    }
}