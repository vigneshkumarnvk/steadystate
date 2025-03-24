public interface ITMLLinesService {
    Map<Id, String> retrieveContractLinesTMDescription(List<TM_Line__c> theTMLList);
    void initStaticVariables(Map<TM__c, List<TM_Line__c>> tmLinesByTms);
    void validateTMLinesResourceType(List<TM_Line__c> theTMLList);
    void validateTMLinesUnitOfMeasure(List<TM_Line__c> theTMLList);
    void validateTMLinesRestOfFields(List<TM_Line__c> theTMLList);
    void populateLinesInfo(Map<TM__c, List<TM_Line__c>> tmLinesByTMs);
    void calcLineCost(Map<TM__c, List<TM_Line__c>> tmLinesByTms);
    void calcUnitPrice(TM__c tm, TM_Line__c tmLine);
    void calcUnitCost(TM__c tm, TM_Line__c tmLine);
    void calcTotals(Map<TM__c, List<TM_Line__c>> tmLinesByTMs);
    void validateResourceType(TM__c tm, TM_Line__c tmLine);
    void validateResource(TM__c tm, TM_Line__c tmLine);
    void validateContractLine(TM__c tm, TM_Line__c tmLine); //Ticket18265
    Boolean isCalcBaseOnResType(String lineCategory);

    //job task <<
    void validateUnitOfMeasure(TM__c tm, TM_Line__c tmLine);
    //ticket 19130 05.13.2023 <<
    //List<TM_Line__c> calculatePresumptiveChildLines(TM__c tm, TM_Job_Task__c jobTask, TM_Line__c parentLine, Integer nextTMLineNo);
    TM_Line__c calculatePresumptiveChildLines(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper, TM_Line__c tmLine, Integer nextTMLineNo);
    //ticket 19130 05.13.2023 >>
    //void createFlatPayLines(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper, Integer nextTMLineNo);
    void createSafetyPlanLine(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper, Integer nextTMLineNo);
    void calculateManifestFeeLine(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper, Integer nextTMLineNo);
    void calculateRinseOutFeeLine(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper, Integer nextTMLineNo);
    //job task >>
}