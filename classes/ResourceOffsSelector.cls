public class ResourceOffsSelector extends fflib_SObjectSelector{

    public static ResourceOffsSelector newInstance(){
        return (ResourceOffsSelector) Application.Selector.newInstance(Resource_Off__c.SObjectType);
    }

    public SObjectType getSObjectType(){
        return Resource_Off__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
                Resource_Off__c.Id,
                Resource_Off__c.Name,
                Resource_Off__c.Date__c,
                Resource_Off__c.Resource__c,
                Resource_Off__c.Service_Center__c,
                Resource_Off__c.Resource_Service_Center__c,
                Resource_Off__c.Off_Type__c,
                Resource_Off__c.Pay_Rule__c,
                Resource_Off__c.Start_Time__c,
                Resource_Off__c.End_Time__c,
                Resource_Off__c.Lunch_Start_Time__c,
                Resource_Off__c.Lunch_End_Time__c,
                Resource_Off__c.Hours__c,
                Resource_Off__c.Total_Hours__c,
                Resource_Off__c.Description__c,
                Resource_Off__c.PTO_Type__c,
                Resource_Off__c.Shop_Time_Category__c,
                Resource_Off__c.Unavailable_Reason__c,
                Resource_Off__c.Note__c
        };
    }

    public List<Resource_Off__c> selectBorrowedResOffByDate(String workingSCName, Date workingDate){
        System.debug('Info: workingSC ' + workingSCName);
        System.debug('Info: workingDate ' + workingDate);
        return (List<Resource_Off__c>) Database.query(
                newQueryFactory(true).selectField('Resource__r.Name').
                        selectField('Off_Type__r.Name').
                        selectField('Service_Center__r.Name').
                        selectField('Resource_Service_Center__r.Name').
                        setCondition('Resource_Service_Center__r.Name != :workingSCName AND Resource_Service_Center__c != null AND ' +
                                'Service_Center__r.Name = :workingSCName AND Service_Center__c != null AND Date__c = :workingDate').toSOQL()
        );
    }
}