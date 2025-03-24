public class ResourceTypesSelector extends fflib_SObjectSelector
{
    public static ResourceTypesSelector newInstance() {
        return (ResourceTypesSelector) Application.Selector.newInstance(Resource_Type__c.SObjectType);
    }

    public ResourceTypesSelector()
    {
        super(false);
    }

    public ResourceTypesSelector(Boolean includeFieldSetFields)
    {
        super(includeFieldSetFields);
    }
    /*  Ticket#19931
     *    - Job times is not required for Resource Type with Rental Resource Type checked.
     */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField>{
                Resource_Type__c.Id,
                Resource_Type__c.Name,
                Resource_Type__c.Description__c,
                Resource_Type__c.Category__c,
                Resource_Type__c.Inter_co_Cost__c,
                Resource_Type__c.Fleet_No_Required__c,
                Resource_Type__c.Rental_Resource_Type__c,
                Resource_Type__c.Fuel_Fired_Equipment__c,
                Resource_Type__c.Blocked__c,
                Resource_Type__c.Equipment_Group__c,
                Resource_Type__c.Unit_of_Measure__c,
                Resource_Type__c.Unit_of_Measure1__c,
                Resource_Type__c.Unit_of_Measure2__c,
                Resource_Type__c.Unit_of_Measure3__c,
                Resource_Type__c.Unit_of_Measure4__c,
                Resource_Type__c.Unit_Cost__c,
                Resource_Type__c.Unit_Cost1__c,
                Resource_Type__c.Unit_Cost2__c,
                Resource_Type__c.Unit_Cost3__c,
                Resource_Type__c.Unit_Cost4__c,
                Resource_Type__c.Silver_Rate__c,
                Resource_Type__c.Silver_Rate1__c,
                Resource_Type__c.Silver_Rate2__c,
                Resource_Type__c.Silver_Rate3__c,
                Resource_Type__c.Silver_Rate4__c,
                Resource_Type__c.Silver_ER_Rate__c,
                Resource_Type__c.Silver_ER_Rate1__c,
                Resource_Type__c.Silver_ER_Rate2__c,
                Resource_Type__c.Silver_ER_Rate3__c,
                Resource_Type__c.Silver_ER_Rate4__c,
                Resource_Type__c.Gold_Rate__c,
                Resource_Type__c.Gold_Rate1__c,
                Resource_Type__c.Gold_Rate2__c,
                Resource_Type__c.Gold_Rate3__c,
                Resource_Type__c.Gold_Rate4__c,
                Resource_Type__c.Gold_ER_Rate__c,
                Resource_Type__c.Gold_ER_Rate1__c,
                Resource_Type__c.Gold_ER_Rate2__c,
                Resource_Type__c.Gold_ER_Rate3__c,
                Resource_Type__c.Gold_ER_Rate4__c,
                Resource_Type__c.Platinum_Rate__c,
                Resource_Type__c.Platinum_Rate1__c,
                Resource_Type__c.Platinum_Rate2__c,
                Resource_Type__c.Platinum_Rate3__c,
                Resource_Type__c.Platinum_Rate4__c,
                Resource_Type__c.Platinum_ER_Rate__c,
                Resource_Type__c.Platinum_ER_Rate1__c,
                Resource_Type__c.Platinum_ER_Rate2__c,
                Resource_Type__c.Platinum_ER_Rate3__c,
                Resource_Type__c.Platinum_ER_Rate4__c,
                Resource_Type__c.EEC_Surcharge_Exempted__c,
                //aura <<
                Resource_Type__c.Used_for_Contract__c,
                //aura >>
                Resource_Type__c.Charge_Rinse_Out_Fee__c
        };
    }

    public Schema.SObjectType getSObjectType()
    {
        return Resource_Type__c.SObjectType;
    }

    public List<Resource_Type__c> selectById(Set<Id> idSet)
    {
        return (List<Resource_Type__c>) Database.query(newQueryFactory()
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .setCondition('Id IN :idSet').toSOQL());
    } 

    public Map<Id, Resource_Type__c> getResourceTypesByIdsMap(Set<Id> resTypeIds){
        Map<Id, Resource_Type__c> resourceTypesByIds = new Map<Id, Resource_Type__c>();
        resourceTypesByIds.putAll(selectById(resTypeIds));
        return resourceTypesByIds;
    }
}