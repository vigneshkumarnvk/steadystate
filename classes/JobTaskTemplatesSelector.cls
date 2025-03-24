public class JobTaskTemplatesSelector extends fflib_SObjectSelector implements IJobTaskTemplatesSelector {

    public static IJobTaskTemplatesSelector newInstance() {
        return (IJobTaskTemplatesSelector) Application.Selector.newInstance(Job_Task_Template__c.SObjectType);
    }

    public SObjectType getSObjectType() {
        return Job_Task_Template__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
                Job_Task_Template__c.Id,
                Job_Task_Template__c.Name
        };
    }

    public List<Job_Task_Template__c> selectById(Set<Id> idSet) {
        return (List<Job_Task_Template__c>) Database.query(newQueryFactory()
                .setCondition('Id IN :idSet').toSOQL());
    }
}