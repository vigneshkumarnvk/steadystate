public with sharing class ContractTriggersMgmt {
    public static Map<String,Numbering_Series__c> mapNumberSeries = new Map<String,Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;

    public static void CLInsertUpdate(List<Contract_Line__c> CLList, Map<Id, Contract_Line__c > oldCLMap, Boolean isInsert) {
        Set<Id> resIds = new Set<Id>();
        Set<Id> resTypeIds = new Set<Id>();
        Set<String> possibleresTypeAndUOMCombination = new Set<String>();
        Set<String> possibleresAndUOMCombination = new Set<String>();

        //contract resource << this trigger does not handle multiple contracts
        Set<Id> contractIds = new Set<Id>();
        //contract resource >>

        for (Contract_Line__c theCL : CLList) {
            if (IsInsert) {
                mapNumberSeries = CompanyMgmt.getNumber('Contract Line');
                theNumberingSeries = mapNumberSeries.get('Contract Line');
                theCL.Name = theNumberingSeries.Prefix__c + theNumberingSeries.Separator__c + String.valueOf(theNumberingSeries.Last_Number_Used__c);
            }

            if(theCL.Unit_of_Measure__c != null){
                if(theCL.Resource_Type__c != null) resTypeIds.add(theCL.Resource_Type__c);
                if(theCL.Resource__c != null) resIds.add(theCL.Resource__c);
            }

            //contract resource <<
            contractIds.add(theCL.Contract__c);
            //contract resource >>
        }

        if(resTypeIds != null){
            List<ResourceTypeUOMAssociation__c> resourceTypeUOMAssociations = ResourceTypeUnitOfMeasuresSelector.newInstance().selectByResTypeId(resTypeIds);
            for(ResourceTypeUOMAssociation__c resourceTypeUOMAssociation:resourceTypeUOMAssociations){
                possibleresTypeAndUOMCombination.add(resourceTypeUOMAssociation.Resource_Type__c + ':' + resourceTypeUOMAssociation.Unit_of_Measure__c);
            }
        }

        if(resIds != null){
            List<ResourceUOMAssociation__c> resourceUOMAssociations = new ResourceUnitOfMeasuresSelector().selectByResId(resIds);
            for(ResourceUOMAssociation__c resourceUOMAssociation:resourceUOMAssociations){
                possibleresAndUOMCombination.add(resourceUOMAssociation.Resource__c + ':' + resourceUOMAssociation.Unit_of_Measure__c);
            }
        }

        //contract resource <<
        for (Contract_Resource_Type__c contractResourceType : [SELECT Id, Resource_Type__c, Unit_of_Measure__c FROM Contract_Resource_Type__c WHERE Contract__c IN :contractIds AND Resource_Type__c IN : resTypeIds]) {
            possibleresTypeAndUOMCombination.add(contractResourceType.Resource_Type__c + ':' + contractResourceType.Unit_of_Measure__c);
        }
        for (Contract_Resource__c contractResource : [SELECT Id, Resource__c, Unit_of_Measure__c FROM Contract_Resource__c WHERE Contract__c IN :contractIds AND Resource__c IN : resIds]) {
            possibleresAndUOMCombination.add(contractResource.Resource__c + ':' + contractResource.Unit_of_Measure__c);
        }
        //contract resource >>

        for(Contract_Line__c contractLine:CLList){
            if(contractLine.Unit_of_Measure__c != null){
                if(contractLine.Resource_Type__c != null){
                    String checkStr = contractLine.Resource_Type__c + ':' + contractLine.Unit_of_Measure__c;
                    if(!possibleresTypeAndUOMCombination.contains(checkStr)){
                        contractLine.addError('Resource Type and Unit of Measure combination does not exist!');
                    }
                } else if (contractLine.Resource__c != null){
                    String checkStr = contractLine.Resource__c + ':' + contractLine.Unit_of_Measure__c;
                    if(!possibleresAndUOMCombination.contains(checkStr)){
                        contractLine.addError('Resource and Unit of Measure combination does not exist!');
                    }
                }
            }
        }

        update mapNumberSeries.values();
    }
}