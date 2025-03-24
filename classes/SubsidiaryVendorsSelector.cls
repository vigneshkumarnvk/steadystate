public with sharing class SubsidiaryVendorsSelector extends fflib_SObjectSelector{

    public static SubsidiaryVendorsSelector newInstance(){
        return (SubsidiaryVendorsSelector) Application.Selector.newInstance(Subsidiary_Vendor__c.SObjectType);
    }

    public Schema.SObjectType getSObjectType(){
        return Subsidiary_Vendor__c.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
                Subsidiary_Vendor__c.Id,
                Subsidiary_Vendor__c.Name,
                Subsidiary_Vendor__c.Subsidiary_Company__c,
                Subsidiary_Vendor__c.Account__c,
                Subsidiary_Vendor__c.Service_Center__c
        };
    }

    public List<Subsidiary_Vendor__c> selectBySubsidiaryByName(Id subsidiaryId, Set<String> navVenNos){
        return System.Database.query(
                newQueryFactory().setCondition('Subsidiary_Company__c = :subsidiaryId AND Name IN :navVenNos').toSOQL()
        );
    }
}