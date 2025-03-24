public with sharing class SignaturesSelector extends fflib_SObjectSelector implements ISignaturesSelector {
    public static ISignaturesSelector newInstance() {
        return (ISignaturesSelector) Application.Selector.newInstance(Signature__c.SObjectType);
    }

    public SObjectType getSObjectType() {
        return Signature__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
                Signature__c.TM__c,
                Signature__c.Id,
                Signature__c.Signer_Role__c,
                Signature__c.Name,
                Signature__c.Print_Name__c,
                Signature__c.Email__c,
                Signature__c.Accept_Terms_and_Conditions__c,
                Signature__c.Customer_Not_Available__c,
                Signature__c.Request_Signature__c,
                Signature__c.Signature_Request_Date__c,
                Signature__c.Signature_Request_Email_Sent__c,
                Signature__c.Signature_Request__c,
                Signature__c.Site_Access_Token__c,
                Signature__c.Token_Expiration_Date__c,
                Signature__c.Signed__c,
                Signature__c.Signature_Date__c,
                Signature__c.Email__c,
                Signature__c.Voided__c,
                Signature__c.Void_Reason__c,
                //ticket 21113 <<
                Signature__c.Related_To_Object_Name__c,
                Signature__c.Related_To_Id__c,
                Signature__c.Declined__c,
                Signature__c.Customer_PO_No__c,
                Signature__c.Customer_Comment__c
                //ticket 21113 >>
        };
    }

    public List<Signature__c> selectById(Set<Id> ids) {
        return Database.query(newQueryFactory(true)
                .selectField('TM__r.Name')
                .selectField('Signature_Request__r.Signed__c')
                .selectField('Signature_Request__r.Signature_Date__c')
                .setCondition('Id IN :ids').toSOQL());
    }

    public List<Signature__c> selectByTMId(Set<Id> tmIds) {
        List<String> filters = new List<String>();
        filters.add('TM__c IN :tmIds');
        filters.add('Voided__c != TRUE');
        String conditions = String.join(filters, ' AND ');

        return Database.query(newQueryFactory(true)
                .selectField('TM__r.Name')
                .selectField('Signature_Request__r.Signed__c')
                .selectField('Signature_Request__r.Signature_Date__c')
                .setCondition(conditions).toSOQL());
    }

    public List<Signature__c> selectByRoles(Set<Id> tmIds, List<String> roles) {
        List<String> filters = new List<String>();
        filters.add('TM__c IN :tmIds');
        filters.add('Voided__c != TRUE');
        filters.add('Signer_Role__c IN :roles');
        String conditions = String.join(filters, ' AND ');

        return Database.query(newQueryFactory(true)
                .selectField('TM__r.Name')
                .selectField('Signature_Request__r.Signed__c')
                .selectField('Signature_Request__r.Signature_Date__c')
                .setCondition(conditions).toSOQL());
    }

    public Signature__c selectCustomerSignatureBySiteAccessToken(String siteAccessToken) {
        List<Signature__c> signatures = Database.query(newQueryFactory(true)
                .selectField('TM__r.Name')
                .selectField('Signature_Request__r.Signed__c')
                .selectField('Signature_Request__r.Signature_Date__c')
                .setCondition('Site_Access_Token__c = :siteAccessToken').toSOQL());
        if (signatures.size() > 0) {
            return signatures[0];
        }
        return null;
    }
}