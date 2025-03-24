public class TaxService {
    public static Map<Id, Map<String, Decimal>> taxPctByTaxGroupByTaxAreaId = new Map<Id, Map<String, Decimal>>();

    public static void setTaxPctByTaxGroupByTaxAreaIdMap(Set<Id> taxAreaIds){
        List<Tax_Detail__c> taxDetails = [SELECT Id, Tax_Area__c, Tax_Group__c, Tax_Pct__c FROM Tax_Detail__c WHERE Tax_Area__c IN :taxAreaIds];
        for(Tax_Detail__c taxDetail : taxDetails){
            Map<String, Decimal> taxPctByTaxGroup = new Map<String, Decimal>();
            if(taxPctByTaxGroupByTaxAreaId.containsKey(taxDetail.Tax_Area__c)){
                taxPctByTaxGroup = taxPctByTaxGroupByTaxAreaId.get(taxDetail.Tax_Area__c);
            }
            taxPctByTaxGroup.put(taxDetail.Tax_Group__c, taxDetail.Tax_Pct__c);
            taxPctByTaxGroupByTaxAreaId.put(taxDetail.Tax_Area__c, taxPctByTaxGroup);
        }
    }

    public static Decimal getTaxPct(Id taxAreaId, String taxGroup){
        Decimal taxPct = 0;
        if(taxPctByTaxGroupByTaxAreaId.containsKey(taxAreaId)){
            Map<String, Decimal> taxPctByTaxGroup = taxPctByTaxGroupByTaxAreaId.get(taxAreaId);
            if(taxPctByTaxGroup.containsKey(taxGroup)){
                taxPct = taxPctByTaxGroup.get(taxGroup);
            }
        }
        return taxPct;
    }

}