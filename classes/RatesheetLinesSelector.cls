public with sharing class RatesheetLinesSelector extends fflib_SObjectSelector {
    public static RatesheetLinesSelector newInstance(){
        return (RatesheetLinesSelector) Application.Selector.newInstance(Rate_Sheet_Line__c.SObjectType);
    }

    public SObjectType getSObjectType(){
        return Rate_Sheet_Line__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
                Rate_Sheet_Line__c.Container_Size__c,
                Rate_Sheet_Line__c.Default__c,
                Rate_Sheet_Line__c.ER_Unit_Price__c,
                Rate_Sheet_Line__c.Facility__c,
                Rate_Sheet_Line__c.Id,
                Rate_Sheet_Line__c.Min_Sell_Qty__c,
                Rate_Sheet_Line__c.Name,
                Rate_Sheet_Line__c.Rate_Sheet__c,
                Rate_Sheet_Line__c.RecordTypeId,
                Rate_Sheet_Line__c.Resource__c,
                Rate_Sheet_Line__c.Resource_Type__c,
                Rate_Sheet_Line__c.Unit_Cost__c,
                Rate_Sheet_Line__c.Unit_Price__c,
                Rate_Sheet_Line__c.Unit_of_Measure__c
        };
    }

    public List<Rate_Sheet_Line__c> selectByRateSheetIds(Set<Id> ratesheetIds){
        return (List<Rate_Sheet_Line__c>) Database.query(
                newQueryFactory(true)
                        .selectField('Unit_of_Measure__r.Name')
                        .selectField('Unit_of_Measure__r.Hours_UOM__c')
                        .selectField('Resource_Type__r.Name')
                        .selectField('Resource_Type__r.Blocked__c')
                        .selectField('Resource_Type__r.Category__c')
                        .selectField('Resource__r.Name')
                        .selectField('Resource__r.Blocked__c')
                        .selectField('Resource__r.Category__c')                        
                        .selectField('Facility__r.Name')
                        .selectField('Container_Size__r.Name')
                        .selectField('Rate_Sheet__r.Name')
                        .setCondition('Rate_Sheet__c IN :ratesheetIds')
                        .toSOQL());
    }
}