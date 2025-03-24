public class UsersSelector extends fflib_SObjectSelector implements IUsersSelector{

    public static IUsersSelector newInstance() {
        return (IUsersSelector) Application.Selector.newInstance(User.SObjectType);
    }
    public SObjectType getSObjectType() {
        return User.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
                User.Id,
                User.Name,
                User.Service_Center__c,
                User.Email
        };
    }

    public List<User> selectById(Set<Id> idSet) {
        return (List<User>) Database.query(newQueryFactory().setCondition('Id In :idSet').toSOQL());
    }
}