public with sharing class SILUnitCostUpdateBatchable implements Database.Batchable<Sales_Invoice_Line__c> {
    public List<Sales_Invoice_Line__c> start(Database.BatchableContext bc) {
        List<Sales_Invoice_Line__c> sils = [
        SELECT Id, Sales_Invoice__r.Credit_Memo__c,
            Category__c, Resource__c, Resource_Type__c, Quantity__c, Cost_Qty__c,
            Unit_of_Measure__c, Unit_Cost__c, Resource__r.Resource_Type__c
        FROM Sales_Invoice_Line__c
        WHERE Unit_Cost_Updated__c <> TRUE
            AND (Unit_Cost__c = 0 OR Unit_Cost__c = NULL OR Line_Cost__c = NULL OR Line_Cost__c = 0)
            AND Inter_Company_Resource__c = TRUE
            AND Sales_Invoice__r.Credit_Memo__c = FALSE
            AND (Category__c = 'Labor' OR Category__c = 'Equipment')
            AND Sales_Invoice__r.Document_Status__c != 'Void'
        ];
        return sils;
    }
    
    public void execute(Database.BatchableContext bc, List<Sales_Invoice_Line__c> sils) {
        //Set<Id> resIds = new Set<Id>();
        Set<Id> resTypeIds = new Set<Id>();
        for (Sales_Invoice_Line__c sil : sils) {
            System.debug('Info: sil ' + sil);
            System.debug('Info: sil Category ' + sil.Category__c);
            if (sil.Category__c == 'Labor' || sil.Category__c == 'Equipment' || sil.Category__c == 'Bundled') {
                if(sil.Resource_Type__c != sil.Resource__r.Resource_Type__c && String.isNotBlank(sil.Resource__r.Resource_Type__c)){
                    resTypeIds.add(sil.Resource__r.Resource_Type__c);
                } else if (sil.Resource_Type__c != null) {
                    resTypeIds.add(sil.Resource_Type__c);
                }
            }
        }

        Map<Id, Map<Id, Decimal>> costByUOMIdsByResTypes = new Map<Id, Map<Id, Decimal>>(); //by resource type, by uom
        List<ResourceTypeUOMAssociation__c> resourceTypeUOMAssociations = ResourceTypeUnitOfMeasuresSelector.newInstance().selectByResTypeId(resTypeIds);
        for(ResourceTypeUOMAssociation__c resourceTypeUOMAssociation : resourceTypeUOMAssociations){
            Map<Id, Decimal> resTypeCostByUOMIds = new Map<Id, Decimal>();
            if(costByUOMIdsByResTypes.containsKey(resourceTypeUOMAssociation.Resource_Type__c)){
                resTypeCostByUOMIds = costByUOMIdsByResTypes.get(resourceTypeUOMAssociation.Resource_Type__c);
            }
            resTypeCostByUOMIds.put(resourceTypeUOMAssociation.Unit_of_Measure__c, CompanyMgmt.zeroIfNull(resourceTypeUOMAssociation.Unit_Cost__c));
            costByUOMIdsByResTypes.put(resourceTypeUOMAssociation.Resource_Type__c, resTypeCostByUOMIds);
        }
        
        for (Sales_Invoice_Line__c sil : sils) {
            Decimal unitCost = 0;    //unit cost = 0 if not cost record found    
            Boolean uomExists = false;
            if (sil.Category__c == 'Labor' || sil.Category__c == 'Equipment') {
                Id costResTypeId;
                if(sil.Resource_Type__c != sil.Resource__r.Resource_Type__c && String.isNotBlank(sil.Resource__r.Resource_Type__c)){
                    costResTypeId = sil.Resource__r.Resource_Type__c;
                } else if (sil.Resource_Type__c != null) {
                    costResTypeId = sil.Resource_Type__c;
                }

                if (costByUOMIdsByResTypes.containsKey(costResTypeId)) {
                    Map<Id, Decimal> costs = costByUOMIdsByResTypes.get(costResTypeId);
                    if (costs.containsKey(sil.Unit_of_Measure__c)) {
                        uomExists = true;
                        if (costs.get(sil.Unit_of_Measure__c) > 0) {
                            unitCost = costs.get(sil.Unit_of_Measure__c);
                        }
                    }
                }
            }

            sil.UOM_Exists__c = uomExists;
            sil.Unit_Cost__c = unitCost;
            if(sil.Cost_Qty__c != 0 && sil.Cost_Qty__c != null) {
                sil.Line_Cost__c = CompanyMgmt.zeroIfNull(sil.Unit_Cost__c) * sil.Cost_Qty__c;
            } else {
                sil.Line_Cost__c = CompanyMgmt.zeroIfNull(sil.Unit_Cost__c) * CompanyMgmt.zeroIfNull(Math.abs(sil.Quantity__c));
            }

            if(sil.Unit_Cost__c != 0) {
                sil.Unit_Cost_Updated__c = true;
            }
        }
        update sils;
    }
    
    public void finish(Database.BatchableContext bc) {
    
    }
}