public class ContactsSelector extends fflib_SObjectSelector
{
    public static ContactsSelector newInstance()
    {
        return (ContactsSelector) Application.Selector.newInstance(Contact.SObjectType);
    }

    public SObjectType getSObjectType()
    {
        return Contact.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList()
    {
        return new List<SObjectField>{
                Contact.Id,
                Contact.Name,
                Contact.FirstName,
                Contact.LastName,
                Contact.Title,
                Contact.AccountId,
                Contact.Email,
                Contact.Phone,
                Contact.Contact_Type__c,
                Contact.Mobile_Email__c,
                Contact.Contact_Type__c,
                Contact.Blocked__c
        };
    }

    public List<Contact> selectContactsByIds(Set<Id> contactIds){
        return (List<Contact>) Database.query(newQueryFactory()
                .setCondition('Id IN :contactIds AND Blocked__c != TRUE')
                .toSOQL());
    }
    
    public List<Contact> selectBillingContactsByAccount(Set<Id> accountIds)
    {
        return (List<Contact>) Database.query(newQueryFactory().setCondition('AccountId IN :accountIds AND Contact_Type__c INCLUDES (\'Billing\') AND Blocked__c != TRUE').toSOQL());
    }

    public List<Contact> selectQuoteContactsByAccount(Set<Id> accountIds)
    {
        return (List<Contact>) Database.query(newQueryFactory().setCondition('AccountId IN :accountIds AND Contact_Type__c INCLUDES (\'Quote\') AND Blocked__c != TRUE').toSOQL());
    }
}