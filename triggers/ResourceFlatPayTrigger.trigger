/**
 * Created by Steven on 6/11/2018.
 */

trigger ResourceFlatPayTrigger on Resource_Flat_Pay__c (before insert, before update, before delete) {
    if(Trigger.isBefore){
        //job task <<
        if (Trigger.isInsert || Trigger.isUpdate) {
            Map<Id, Flat_Rate_Type__c> mapFlatRateTypesById = new Map<Id, Flat_Rate_Type__c>();
            for (Flat_Rate_Type__c flatRateType : [SELECT Id, Name, ADP_Code__c FROM Flat_Rate_Type__c]) {
                mapFlatRateTypesById.put(flatRateType.Id, flatRateType);
            }
            for (Resource_Flat_Pay__c resourceFlatPay : Trigger.new) {
                if (resourceFlatPay.Flat_Rate_Type__c != null) {
                    if (mapFlatRateTypesById.containsKey(resourceFlatPay.Flat_Rate_Type__c)) {
                        Flat_Rate_Type__c flatRateType = mapFlatRateTypesById.get(resourceFlatPay.Flat_Rate_Type__c);
                        if (flatRateType.ADP_Code__c == null) {
                            resourceFlatPay.addError('Flat rate type ' + flatRateType.Name + ': ADP Code is blank.');
                        }
                        resourceFlatPay.Rate_Type__c = flatRateType.ADP_Code__c;
                    }
                }
            }
        }
        //job task >>

        if(Trigger.isInsert){
            List<Resource_Flat_Pay__c> theResFlatPay = Trigger.new;
            Set<String> tmLineIds = new Set<String>();
            for(Resource_Flat_Pay__c rfp: theResFlatPay){
                String tmLineId = rfp.T_M_Line__c;
                if(!tmLineIds.contains(tmLineId)){
                    tmLineIds.add(tmLineId);
                }
            }

            List<TM_Line__c> tmLineList = [SELECT Id, Name, Resource_Type__c, Resource__c, Resource_Name__c, TM__c FROM TM_Line__c WHERE Id IN :tmLineIds];

            Map<String, TM_Line__c> tmLineMap = new Map<String, TM_Line__c>();

            for(TM_Line__c tmLine:tmLineList){
                String tmLineId = tmLine.Id;
                if(!tmLineMap.containsKey(tmLineId)){
                    tmLineMap.put(tmLineId, tmLine);
                }
            }

            for(Resource_Flat_Pay__c rfp: Trigger.new){
                TM_Line__c tmLine = tmLineMap.get(rfp.T_M_Line__c);
                rfp.T_M__c = tmLine.TM__c;
                System.debug('RFP ' + tmLine.TM__c);
            }
        }
    }
}