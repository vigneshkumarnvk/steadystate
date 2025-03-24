public class UnitOfMeasuresSelector extends fflib_SObjectSelector{

    public static UnitOfMeasuresSelector newInstance() {
        return (UnitOfMeasuresSelector) Application.Selector.newInstance(Unit_of_Measure__c.SObjectType);
    }
    public SObjectType getSObjectType() {
        return Unit_of_Measure__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
                Unit_of_Measure__c.Id,
                Unit_of_Measure__c.Name,
                Unit_of_Measure__c.Hours_UOM__c,
                Unit_of_Measure__c.Weight_Volume__c,
                Unit_of_Measure__c.Container_Size__c,
                Unit_of_Measure__c.Blocked__c
        };
    }

    public List<Unit_of_Measure__c> selectById(Set<Id> idSet){
        return (List<Unit_of_Measure__c>) Database.query(newQueryFactory().setCondition('Id IN :idSet').toSOQL());
    }

    public List<Unit_of_Measure__c> selectByName(String uomName){
        String queryStr = newQueryFactory().setCondition('Name = :uomName').toSOQL();
        System.debug('Info: queryStr ' + queryStr);
        return (List<Unit_of_Measure__c>) Database.query(newQueryFactory().setCondition('Name = :uomName').toSOQL());
    }

    public List<Unit_of_Measure__c> selectContainerSizes(){
        return (List<Unit_of_Measure__c>) Database.query(newQueryFactory()
                .setCondition('Blocked__c != true AND Container_Size__c = true').toSOQL());
    }

    public List<Unit_of_Measure__c> selectWeightVolumes(){
        return (List<Unit_of_Measure__c>) Database.query(newQueryFactory()
                .setCondition('Blocked__c != true AND Weight_Volume__c = true').toSOQL());
    }

    public List<Unit_of_Measure__c> selectAll(){
        return (List<Unit_of_Measure__c>) Database.query(newQueryFactory().setCondition('Blocked__c != true').toSOQL());
    }
    
}