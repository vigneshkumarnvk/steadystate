public class AccountsSelector extends fflib_SObjectSelector
        implements IAccountsSelector
{
    public static IAccountsSelector newInstance()
    {
        return (IAccountsSelector) Application.Selector.newInstance(Account.SObjectType);
    }
    
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
                Account.AccountNumber,
                Account.Id,
                Account.ParentId,
                Account.Name,
                Account.NAV_ID__c,
                Account.Service_Center__c,
                Account.BillingStreet,
                Account.BillingCity,
                Account.BillingStateCode,
                Account.BillingPostalCode,
                Account.BillingCountryCode,
                Account.Fax,
                Account.Phone,
                Account.Phone_Ext__c,
                Account.Tax_Area__c,
                Account.Tax_Liable__c,
                Account.Inter_co_Account__c,
                Account.Pricing_Group__c,
                Account.Type,
                Account.Subsidiary_Company__c,
                Account.Emergency__c,
                Account.Payment_Term__c,
                Account.Internal_Comments__c,
                Account.Billing_Instructions__c,
                Account.Salesperson__c,
                Account.Account_Executive__c,
                Account.Customer_Status__c,
                Account.PO_Number_Type__c,
                Account.PO_Required__c, //US141334
                Account.Invoice_Email_Contact_Types__c,
                Account.Invoice_Submission_Channels__c,
                Account.Invoice_Portal__c,
                Account.Invoice_Backup_Documents__c,
                Account.Contact_Type_Filter__c,
                Account.Customer_Billing_Instructions__c,
                Account.InterCo__c, //Ticket#21211
                Account.Sage_Customer_No__c, //Task#78375
                Account.Service_Center__c  //Task#81352    
        };
    }

    public Schema.SObjectType getSObjectType(){
        return Account.SObjectType;
    }

    public List<Account> selectById(Set<Id> idSet){
        return (List<Account>)Database.query(newQueryFactory().
                selectField('Tax_Area__r.Name').
                selectField('Subsidiary_Company__r.Name').
                selectField('Payment_Term__r.Name').
                selectField('Account_Executive__r.Name').
                selectField('Salesperson__r.Name').
                selectField('Owner.Name').
                selectField('Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c').  //Task#81352  
                selectField('Account_Executive_ids__c').
                setCondition('Id IN :idSet').toSOQL());
    }

    public List<Account> selectBillingInstructionsById(Set<Id> idSet){
        return (List<Account>) Database.query(
                newQueryFactory(false).
                        selectField(Account.Id).
                        selectField(Account.Billing_Instructions__c).
                        selectField(Account.Internal_Comments__c).
                        setCondition('Id IN :idSet').toSOQL());
    }

    public List<Account> selectTaxAreaNameById(Set<Id> idSet){
        return (List<Account>) Database.query(newQueryFactory().
                selectField('Tax_Area__r.Name').
                selectField(Account.ParentId).
                selectField(Account.Subsidiary_Company__c).
                selectField(Account.Account_Executive__c).
                selectField(Account.Salesperson__c).
                selectField('Subsidiary_Company__r.Name').
                selectField(Account.Billing_Instructions__c).
                selectField(Account.Internal_Comments__c).
                selectField(Account.ParentId).
                selectField(Account.Payment_Term__c).
                //aura <<
                selectField('Payment_Term__r.Name').
                selectField('Account_Executive__r.Name').
                selectField('Salesperson__r.Name').
                selectField('Owner.Name').
                //aura >>
                setCondition('Id IN :idSet').toSOQL());
    }

    public List<Account> selectSubsidiaryCompInfoById(Set<Id> idSet){
        return (List<Account>) Database.query(newQueryFactory().
                selectField('Subsidiary_Company__r.Name').
                selectField('Subsidiary_Company__r.QtC_Enabled__c').
                selectField(Account.Emergency__c).
                setCondition('Id IN :idSet').toSOQL());
    }

    public List<Account> selectParentAccountById(Set<Id> idSet){
        return (List<Account>) Database.query(newQueryFactory(false).
                selectField('Id').
                selectField('Name').
                selectField('ParentId').
                selectField('Subsidiary_Company__c').
                selectField('Subsidiary_Company__r.Name').
                setCondition('Id In :idSet').
                toSOQL());
    }

    public List<Account> selectBySubsidiaryCompanyAndType(Id subCompanyId){
        return (List<Account>) Database.query(newQueryFactory().
                setCondition('Subsidiary_Company__c =: subCompanyId AND ' +
                '(Type =\'Customer\' OR Type = \'Prospect\')').toSOQL());
    }
}