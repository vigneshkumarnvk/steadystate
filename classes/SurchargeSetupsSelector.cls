public with sharing class SurchargeSetupsSelector extends fflib_SObjectSelector{
    public static SurchargeSetupsSelector newInstance(){
        return (SurchargeSetupsSelector) Application.Selector.newInstance(Surcharge_Setup__c.SObjectType);
    }

    public Schema.SObjectType getSObjectType(){
        return Surcharge_Setup__c.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
                Surcharge_Setup__c.Id,
                Surcharge_Setup__c.Name,
                Surcharge_Setup__c.Surcharge_Type__c,
                Surcharge_Setup__c.Surcharge_Pct__c,
                Surcharge_Setup__c.Effective_Date__c
        };
    }

    public Surcharge_Setup__c selectByTypeAndEffectiveDate(Date dateValue, String surchargeType){
        List<Surcharge_Setup__c> surchargeSetups = System.Database.query(
                newQueryFactory(true).setCondition('Effective_Date__c <= :dateValue AND Surcharge_Type__c =: surchargeType')
                        .setOrdering('Effective_Date__c', fflib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );

        if(surchargeSetups.size() > 0){
            return surchargeSetups[0];
        } else {
            return null;
        }
    }

    public List<Surcharge_Setup__c> selectByEffectiveDate(Date dateValue){
        List<Surcharge_Setup__c> surchargeSetups = System.Database.query(
                newQueryFactory(true).setCondition('Effective_Date__c <= :dateValue')
                        .setOrdering('Effective_Date__c', fflib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );

        return surchargeSetups;
    }

    //Ticket#21540
    public Surcharge_Setup__c selectByTypeAndEffectiveDate(Date dateValue, String surchargeType, Id subsidiaryCompanyId){
        List<Surcharge_Setup__c> surchargeSetups = System.Database.query(
                newQueryFactory(true)
                        .setCondition('Subsidiary_Company__c = :subsidiaryCompanyId AND Effective_Date__c <= :dateValue AND Surcharge_Type__c =: surchargeType')
                        .setOrdering('Effective_Date__c', fflib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );

        if(surchargeSetups.size() > 0){
            return surchargeSetups[0];
        } else {
            return null;
        }
    }

    //Ticket#21540
    public List<Surcharge_Setup__c> selectByEffectiveDate(Date dateValue, Id subsidiaryCompanyId){
        List<Surcharge_Setup__c> surchargeSetups = System.Database.query(
                newQueryFactory(true).setCondition('Subsidiary_Company__c = :subsidiaryCompanyId AND Effective_Date__c <= :dateValue')
                        .setOrdering('Effective_Date__c', fflib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );

        return surchargeSetups;
    }
}