trigger RateSheetLineTrigger on Rate_Sheet_Line__c (before update) {
    if(Trigger.isBefore) {
        if (Trigger.isUpdate) {
            List<Rate_Sheet_Line__c> rateSheetLinesWithPriceUpdate = new List<Rate_Sheet_Line__c>();
            for(Rate_Sheet_Line__c rateSheetLine : Trigger.new){
                Rate_Sheet_Line__c oldRateSheetLine = Trigger.oldMap.get(rateSheetLine.Id);
                if(rateSheetLine.Unit_Price__c != oldRateSheetLine.Unit_Price__c ||
                        rateSheetLine.ER_Unit_Price__c != oldRateSheetLine.ER_Unit_Price__c ||
                        rateSheetLine.Unit_of_Measure__c != oldRateSheetLine.Unit_of_Measure__c){
                    rateSheetLinesWithPriceUpdate.add(rateSheetLine);
                }
            }
            if(rateSheetLinesWithPriceUpdate.size() > 0){
                RateSheetService.tryToUpdateDefaultResAndResTypePriceByRateSheetLines(rateSheetLinesWithPriceUpdate);
            }
        }
    }
}