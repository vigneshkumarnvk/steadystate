public with sharing class RateSheetsSelector extends fflib_SObjectSelector {
    public static RateSheetsSelector newInstance(){
        return (RateSheetsSelector) Application.Selector.newInstance(Rate_Sheet__c.SObjectType);
    }

    public SObjectType getSObjectType(){
        return Rate_Sheet__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
                Rate_Sheet__c.Id,
                Rate_Sheet__c.Name
        };
    }

    public List<Rate_Sheet__c> selectByIds(Set<Id> rateSheetIds){
        return (List<Rate_Sheet__c>) Database.query(
                newQueryFactory(true)
                        .setCondition('Id IN :rateSheetIds')
                        .toSOQL());
    }
}