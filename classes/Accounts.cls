public with sharing class Accounts extends fflib_SObjectDomain
        implements IAccounts
{
    public static IAccounts newInstance(List<Account> sObjectList)
    {
        return (IAccounts) Application.Domain.newInstance(sObjectList);
    }

    public Accounts(List<Account> sObjectList)
    {
        super(sObjectList);
    }
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new Accounts(sObjectList);
        }
    }
}