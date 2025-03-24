public with sharing class PriceListSelector extends fflib_SObjectSelector {

    public static PriceListSelector newInstance(){
        return (PriceListSelector) Application.Selector.newInstance(Pricing_Rate_Sheet_Association__c.SObjectType);
    }

    public SObjectType getSObjectType(){
        return Pricing_Rate_Sheet_Association__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
                Pricing_Rate_Sheet_Association__c.Id,
                Pricing_Rate_Sheet_Association__c.Name,
                Pricing_Rate_Sheet_Association__c.CreatedDate,
                Pricing_Rate_Sheet_Association__c.Rate_Sheet__c,
                Pricing_Rate_Sheet_Association__c.Pricing__c,
                Pricing_Rate_Sheet_Association__c.Effective_Date__c
        };
    }

    public List<Rate_Sheet_Line__c> selectActiveRateSheetLinesByPriceListAndWorkDate(Id priceListId, Date workDate){
        List<Rate_Sheet_Line__c> activeRateSheetLines = new List<Rate_Sheet_Line__c>();
        List<Pricing_Rate_Sheet_Association__c> pricingRateSheetAssociations =
                (List<Pricing_Rate_Sheet_Association__c>) Database.query(newQueryFactory()
                        .setCondition('Pricing__c = :priceListId AND Effective_Date__c <= :workDate')
                        .setOrdering('Effective_Date__c', fflib_QueryFactory.SortOrder.DESCENDING)
                        .toSOQL());

        if(pricingRateSheetAssociations.size() > 0){
            if(String.isNotBlank(pricingRateSheetAssociations[0].Rate_Sheet__c)){
                activeRateSheetLines = RatesheetLinesSelector.newInstance().selectByRateSheetIds(new Set<Id>{pricingRateSheetAssociations[0].Rate_Sheet__c});
            }
        }
        return activeRateSheetLines;
    }

    public Map<Id, Id> getActiveRateSheetIdByPricesListIdsAndWorkDate(Set<Id> priceListIds, Date workDate){
        System.debug('Info: priceListIds ' + priceListIds);
        System.debug('Info: workDate ' + workDate);
        Map<Id, Id> rateSheetIdsByPriceListIds = new Map<Id, Id>();
        List<Pricing_Rate_Sheet_Association__c> pricingRateSheetAssociations =
                (List<Pricing_Rate_Sheet_Association__c>) Database.query(newQueryFactory()
                        .setCondition('Pricing__c IN :priceListIds AND Effective_Date__c <= :workDate')
                        .setOrdering('Effective_Date__c', fflib_QueryFactory.SortOrder.DESCENDING)
                        .toSOQL());

        for(Pricing_Rate_Sheet_Association__c pricingRateSheetAssociation : pricingRateSheetAssociations){
            System.debug('Info: pricingRateSheetAssociation ' + pricingRateSheetAssociation);
            if(!rateSheetIdsByPriceListIds.containsKey(pricingRateSheetAssociation.Pricing__c)){
                rateSheetIdsByPriceListIds.put(pricingRateSheetAssociation.Pricing__c, pricingRateSheetAssociation.Rate_Sheet__c);
            }
        }

        System.debug('Info: rateSheetIdsByPriceListIds ' + rateSheetIdsByPriceListIds);

        return rateSheetIdsByPriceListIds;
    }

    //job task <<
    public List<Pricing_Rate_Sheet_Association__c> getPricingRateSheetAssociationsByPriceListId(Set<Id> priceListIds, Date workDate){
        return (List<Pricing_Rate_Sheet_Association__c>) Database.query(newQueryFactory()
                        .setCondition('Pricing__c IN :priceListIds AND Effective_Date__c <= :workDate')
                        .setOrdering('Effective_Date__c', fflib_QueryFactory.SortOrder.DESCENDING)
                        .toSOQL());
    }
    //job task >>
}