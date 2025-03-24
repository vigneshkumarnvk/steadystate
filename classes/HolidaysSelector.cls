public class HolidaysSelector extends fflib_SObjectSelector{

    public static HolidaysSelector newInstance()
    {
        return (HolidaysSelector) Application.Selector.newInstance(Holiday__c.SObjectType);
    }

    public HolidaysSelector()
    {
        super(false);
    }

    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField>{
                Holiday__c.Id,
                Holiday__c.Name,
                Holiday__c.Holiday__c,
                Holiday__c.Date__c,
                Holiday__c.Holiday_Name_Map__c
        };
    }

    public Schema.SObjectType getSObjectType()
    {
        return Holiday__c.SObjectType;
    }

    public List<Holiday__c> selectHolidaysYearBeforeAndAfter()
    {
        Integer year = Date.today().year();
        Date yearBefore = Date.newInstance(year-1,1,1);
        Date yearAfter = Date.newInstance(year+1,12,31);

        return (List<Holiday__c>) Database.query(
                newQueryFactory(true).setCondition('Date__c >= :yearBefore AND Date__c <= :yearAfter AND Holiday_Name_Map__c <> null').toSOQL()
        );
    }

    public Map<Date, Holiday__c> getHolidaysByDates(){
        Map<Date, Holiday__c> holidaysByDates = new Map<Date, Holiday__c>();
        for(Holiday__c holiday:selectHolidaysYearBeforeAndAfter()){
            holidaysByDates.put(holiday.Date__c, holiday);
        }
        return holidaysByDates;
    }

    public List<Holiday__c> selectAll(){
        return (List<Holiday__c>) Database.query(newQueryFactory().setCondition('Holiday_Name_Map__c <> null').setOrdering('Date__c', fflib_QueryFactory.SortOrder.DESCENDING).toSOQL());
    }
}