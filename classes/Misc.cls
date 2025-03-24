public with sharing class Misc {
    public static string GetNameSpace() {
        //return 'GFUTIL__';  // for live instance
        return '';  // for dev instance
    }

    public static string convertObjectdName(string objectName) {
        if (objectName.contains('__c'))
            return GetNameSpace() + objectName;
        else
                return objectName;
    }

    public static string converFieldSetdName(string objectName) {
        return GetNameSpace() + objectName;
    }
}