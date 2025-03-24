public class ResourcesSelector extends fflib_SObjectSelector implements IResourcesSelector{

    public static IResourcesSelector newInstance() {
        return (IResourcesSelector) Application.Selector.newInstance(Resource__c.SObjectType);
    }

    public SObjectType getSObjectType() {
        return Resource__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
                Resource__c.Id,
                Resource__c.Name,
                Resource__c.Description__c,
                Resource__c.Service_Center__c,
                Resource__c.Resource_Type__c,
                Resource__c.State__c,
                Resource__c.Medical__c,
                Resource__c.STD__c,
                Resource__c.LTD__c,
                Resource__c.X401K_Match_Pct__c,
                Resource__c.PTO__c,
                Resource__c.Start_Date__c,
                Resource__c.Category__c,
                Resource__c.Unit_of_Measure__c,
                Resource__c.Unit_of_Measure2__c,
                Resource__c.Unit_of_Measure3__c,
                Resource__c.Unit_of_Measure4__c,
                Resource__c.Unit_of_Measure1__c,
                Resource__c.Silver_ER_Rate__c,
                Resource__c.Silver_ER_Rate1__c,
                Resource__c.Silver_ER_Rate2__c,
                Resource__c.Silver_ER_Rate3__c,
                Resource__c.Silver_ER_Rate4__c,
                Resource__c.Silver_Rate__c,
                Resource__c.Silver_Rate1__c,
                Resource__c.Silver_Rate2__c,
                Resource__c.Silver_Rate3__c,
                Resource__c.Silver_Rate4__c,
                Resource__c.Gold_ER_Rate__c,
                Resource__c.Gold_ER_Rate1__c,
                Resource__c.Gold_ER_Rate2__c,
                Resource__c.Gold_ER_Rate3__c,
                Resource__c.Gold_ER_Rate4__c,
                Resource__c.Gold_Rate__c,
                Resource__c.Gold_Rate1__c,
                Resource__c.Gold_Rate2__c,
                Resource__c.Gold_Rate3__c,
                Resource__c.Gold_Rate4__c ,
                Resource__c.Platinum_ER_Rate__c,
                Resource__c.Platinum_ER_Rate1__c,
                Resource__c.Platinum_ER_Rate2__c,
                Resource__c.Platinum_ER_Rate3__c,
                Resource__c.Platinum_ER_Rate4__c,
                Resource__c.Platinum_Rate__c,
                Resource__c.Platinum_Rate1__c,
                Resource__c.Platinum_Rate2__c,
                Resource__c.Platinum_Rate3__c,
                Resource__c.Platinum_Rate4__c,
                Resource__c.Unit_Cost__c,
                Resource__c.Unit_Cost1__c,
                Resource__c.Unit_Cost2__c,
                Resource__c.Unit_Cost3__c,
                Resource__c.Unit_Cost4__c,
                Resource__c.EEC_Surcharge_Exempted__c,
                Resource__c.Employee_Type__c,
                Resource__c.End_Date__c,
                Resource__c.Pay_Rule__c,
                Resource__c.FLSA__c,
                Resource__c.First_Name__c,
                Resource__c.Last_Name__c,
                Resource__c.Used_for_Contract__c,
                Resource__c.Has_Container__c,
                Resource__c.Has_Weight_Volume__c,
                Resource__c.Allow_Zero_Unit_Cost_at_TM_Confirmation__c,
                Resource__c.Allow_Manual_Unit_Cost_Adjustment__c,
                Resource__c.Bypass_Time_Overlap_Checking__c //Ticket#22307
        };
    }

    public List<Resource__c> selectById(Set<Id> idSet){
        return (List<Resource__c>) Database.query(newQueryFactory()
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Service_Center__r.Name')
                .selectField('Service_Center__r.Temporary__c')
                .setCondition('Id IN :idSet').toSOQL());
    }

    public List<Resource__c> selectLaborResourcesByIds(Set<Id> ids){
        return (List<Resource__c>) Database.query(newQueryFactory().
                selectField('Service_Center__r.Name').
                selectField('Service_Center__r.Temporary__c').
                selectField('Resource_Type__r.Name').
                selectField('Pay_Rule__r.Type__c').
                selectField('Pay_Rule__r.Mon_Sun_Work_Week__c').
                setCondition('Id IN :ids AND Category__c = \'Labor\' AND Employee_Type__c = \'Employee\' AND Status__c = \'Active\' AND Non_Payroll_Labor_Resource__c = FALSE').
                toSOQL());
    }

    public List<Resource__c> selectLaborResourcesByServiceCenter(Id scId){
        return (List<Resource__c>) Database.query(newQueryFactory().
                selectField('Service_Center__r.Name').
                selectField('Service_Center__r.Temporary__c').
                selectField('Resource_Type__r.Name').
                selectField('Pay_Rule__r.Type__c').
                selectField('Pay_Rule__r.Mon_Sun_Work_Week__c').
                setCondition('Service_Center__c  = :scId AND Category__c = \'Labor\' AND Employee_Type__c = \'Employee\' AND Status__c = \'Active\' AND Non_Payroll_Labor_Resource__c = FALSE').
                toSOQL());
    }

    public List<Resource__c> selectPayrollEmployeeByIdsByActivityDate(Set<Id> resIds, Date activityDate){
        return (List<Resource__c>) Database.query(newQueryFactory().
                selectField('Service_Center__r.Name').
                selectField('Service_Center__r.Temporary__c').
                selectField('Resource_Type__r.Name').
                selectField('Pay_Rule__r.Type__c').
                selectField('Pay_Rule__r.Mon_Sun_Work_Week__c').
                setCondition('Id IN :resIds AND Category__c = \'Labor\' ' +
                        'AND Employee_Type__c != NULL ' +
                        'AND Non_Payroll_Labor_Resource__c = FALSE ' +
                        'AND (End_Date__c >= :activityDate OR End_Date__c = null)').
                toSOQL());
        //'AND Employee_Type__c != \'Temp\' AND Employee_Type__c != NULL ' +
    }

    public List<Resource__c> selectPayrollEmployeeBySCIdByActivityDate(Id scId, Date activityDate){
        return (List<Resource__c>) Database.query(newQueryFactory().
                selectField('Service_Center__r.Name').
                selectField('Service_Center__r.Temporary__c').
                selectField('Resource_Type__r.Name').
                selectField('Pay_Rule__r.Type__c').
                selectField('Pay_Rule__r.Mon_Sun_Work_Week__c').
                setCondition('Service_Center__c = :scId AND Category__c = \'Labor\' ' +
                        'AND Employee_Type__c != NULL ' +
                        'AND Non_Payroll_Labor_Resource__c = FALSE ' +
                        'AND (End_Date__c >= :activityDate OR End_Date__c = null)').
                toSOQL());
        //'AND Employee_Type__c != \'Temp\' AND Employee_Type__c != NULL ' +
    }

    public Map<Id, Resource__c> getResourcesByIdsMapByResIds(Set<Id> resIds){
        Map<Id, Resource__c> resourcesByIds = new Map<Id, Resource__c>();
        resourcesByIds.putAll(selectById(resIds));
        return resourcesByIds;
    }
}