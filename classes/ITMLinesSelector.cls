public interface ITMLinesSelector extends fflib_ISObjectSelector{
    List<TM_Line__c> selectByIds(Set<Id> ids);
    List<TM_Line__c> selectByTmId(Set<Id> tmIds);
    Map<Id, TM_Line__c> selectTMLMapWithResourceTypeAndResourceById(Set<Id> idSet);
    Map<Id, TM_Line__c> selectTMLMapWithUnitOfMeasureById(Set<Id> idSet);
    List<TM_Line__c> selectInterCompanyLineByScheduledDateRange(Date startDate, Date endDate);
    //job task <<
    //List<TM_Line__c> selectTMLinesByCategory(Id tmId, String category);
    List<TM_Line__c> selectByTmId(Set<Id> tmIds, List<String> filters);
    List<TM_Line__c> selectTMLinesByCategory(Id tmId, Id jobTaskId, String category);
    List<TM_Line__c> selectWithFlatPaysByTmId(Set<Id> tmIds, List<String> tmLineFilters); 
    //job task >>
    List<TM_Line__c> selectAwayServiceCenterLinesByScheduledDateServiceCenterAndCategory(Date scheduledDate, String serviceCenter, String category);
    List<TM_Line__c> selectCreateInvoiceRequiredFieldsById(Set<Id> idSet); 
    List<TM_Line__c> selectSafetyPlanLineByTMId(Set<Id> idSet, Id resourceId);
}