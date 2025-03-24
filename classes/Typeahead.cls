// Controller class for the Force.com Typeahead component
global with sharing class Typeahead {
    global String sObjectFieldId { get; set; }

    global static String sObj;
    global static String sObjField;
    global String LookupFieldApiName{get;set;}
    global String FieldName{get;set;}

    //global Company_Setup__c theCompanySetup;
    //global Company_Setup__c CompanySetup{
    //    get {
    //        return theCompanySetup;
    //    }
    //}
    global String NameSpace{
        get {
            return Misc.GetNameSpace();
        }
    }

    @RemoteAction
    global static List<SObject> searchRecords(String queryString, String objectName, List<String> fieldNames, String fieldsToSearch, String filterClause, String orderBy, Integer recordLimit, Boolean useSOSL ) {
        System.debug('Search Record Fired===>');
        String sObjectName = String.escapeSingleQuotes(objectName);
        System.debug('-->filterclause : ' + filterClause);
        if (String.isEmpty(sObjectName)) return null;

        String sQuery = String.escapeSingleQuotes(queryString);
        if (String.isEmpty(sQuery)) return null;

        String sInFields = ' IN ' + String.escapeSingleQuotes(String.isEmpty(fieldsToSearch) ? 'NAME' : fieldsToSearch) + ' FIELDS';

        Boolean addIdField = true;
        for (String fieldName : fieldNames) {
            if (fieldName.toUpperCase() == 'ID') {
                addIdField = false;
                break;
            }
        }
        if (addIdField) {
            fieldNames.add('Id');
        }
        String sFields = (fieldNames == null || fieldNames.isEmpty() ? 'Id, Name' : String.escapeSingleQuotes(String.join(fieldNames, ',')));

        String sOrder = ' ORDER BY ' + ( (orderBy == null || orderBy == '') ? 'Name' : String.escapeSingleQuotes(orderBy));

        String sLimit = (recordLimit == null || recordLimit == 0 || recordLimit >= 2000) ? '' : ( ' LIMIT ' + String.valueOf(recordLimit));

        // can't escape the filter clause
        String sWhere = (filterClause == null || filterClause == '') ? '' : ( ' WHERE ' + filterClause );
        if(useSOSL) {
            List<List<SObject>> results = Search.query('FIND \'' + sQuery + '*\'' + sInFields + ' RETURNING ' + sObjectName + '(' + sFields + sWhere + sOrder + sLimit + ')');

            return results[0];
        }
        else { //search using SOQL
            sInFields = 'NAME LIKE \'%' + sQuery + '%\'';
            //sWhere = String.isBlank(filterClause) ? (' WHERE ' + sInFields) : (' WHERE ' + filterClause);
            sWhere = ' WHERE ' + sInFields;
            sWhere += String.isBlank(filterClause) ? '' :   ' AND ' + filterClause;
            String queryStr = 'SELECT ' + sFields + ' FROM ' + sObjectName + sWhere + sOrder + sLimit;
            System.debug('-->queryStr : ' + queryStr);
            List<SObject> lstSobject = Database.query(queryStr);
            return lstSobject;
        }

    }

    @RemoteAction
    global static String getRecordNameById(String type, String Id) {
        if (Id != null) {
            List<SObject> records = Database.query('SELECT Id, Name FROM ' + type + ' WHERE Id = \'' + Id + '\'');
            if (records.size() > 0) {
                return (String)records[0].get('Name');
            }
        }
        return null;
    }

    @RemoteAction
    global static String getRecordIdByName(String type, String name) {
        System.debug('getRecordIdByName Fired===>');
        if (name != null) {
            List<SObject> records = Database.query('SELECT Id, Name FROM ' + type + ' WHERE Name = \'' + name + '\'');
            if (records.size() > 0) {
                return (String)records[0].get('Id');
            }
        }
        return null;
    }


    //used to get field ids
    global static Map<String,Id> getFieldIdMap(String SObjName) {
        return getFieldIdMap(SObjName, '');
    }

    global static Map<String,Id> getFieldIdMap(String SObjName, String fieldName) {
        System.debug('getFieldIdMap Fired===>');
        Map<String,Id> mapFieldId = new Map<String,Id>();

        if(SObjName.endsWith('__c')) {
            SObjName = SObjName.removeEnd('__c');
            String strQuery = 'SELECT+Id,DeveloperName+FROM+CustomObject+WHERE+DeveloperName=\'' + SObjName + '\'';
            String res = requestToolingAPI(strQuery);
            Matcher m = Pattern.compile('"Id":"(\\w+)","DeveloperName":"(\\w+)"').matcher(res);
            while(m.find()) {
                SObjName = m.group(1);
            }
        }
        String SfieldQuery = 'Select+id,DeveloperName+from+CustomField+where+TableEnumOrId=\''+SObjName+'\'' ;
        if(String.isNotBlank(fieldName)) {
            if(fieldName.endsWith('__c')){ fieldName = fieldName.removeEnd('__c'); }
            SfieldQuery += '+AND+DeveloperName=\'' + fieldName +'\'';
        }
        String a = requestToolingAPI(SfieldQuery);
        Matcher m = Pattern.compile('"Id":"(\\w+)","DeveloperName":"(\\w+)"').matcher(a);
        while(m.find()) {
            mapFieldId.put(m.group(2) + '__c' , m.group(1));
        }
        //System.debug(mapFieldId);
        return mapFieldId;
    }

    global static Map<String,Id> getSObjectIdMap() {
        Map<String,Id> mapSobj = new Map<String,Id>();
        String strQuery = 'SELECT+Id,DeveloperName+FROM+CustomObject';
        String res = requestToolingAPI(strQuery);
        Matcher m = Pattern.compile('"Id":"(\\w+)","DeveloperName":"(\\w+)"').matcher(res);
        while(m.find()) {
            mapSobj.put(m.group(2) + '__c' , m.group(1));
        }
        return mapSobj;
    }

    global static Map<String,Map<String,String>> getSFieldIdMap() {
        Map<String,Map<String,String>> mapFieldId = new Map<String,Map<String,String>>();
        String strQuery = 'SELECT+Id,DeveloperName,TableEnumOrId+FROM+CustomField';
        String res = requestToolingAPI(strQuery);
        Matcher m = Pattern.compile('"Id":"(\\w+)","DeveloperName":"(\\w+)","TableEnumOrId":"(\\w+)"').matcher(res);
        while(m.find()) {
            String SobjId = m.group(3);
            String fieldName = m.group(2);
            String fieldId = String.valueOf(m.group(1)).left(15);
            if(!mapFieldId.containsKey(SobjId)) {
                mapFieldId.put(SobjId, new Map<String,String>());
            }
            mapFieldId.get(SobjId).put(fieldName + '__c' , fieldId);
        }
        return mapFieldId;
    }

    global static String requestToolingAPI(String query) {
        System.debug('requestToolingAPI Fired===>');
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint( Url.getSalesforceBaseUrl().toExternalForm()+'/services/data/v38.0/tooling/query/?q=' + query);
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse res;
        if(!Test.isRunningTest())res = h.send(req);
        else
        {
            res = new HttpResponse();
            res.setBody('{ "size" : 1, "totalSize" : 1, "done" : true, "queryLocator" : null, "entityTypeName" : "ApexClass", "records" : [ { "attributes" : { "type" : "ApexClass", "url" : "/services/data/v39.0/tooling/sobjects/ApexClass/01p46000004cy5oAAA" }, "Id" : "01p46000004cy5oAAA", "Name" : "DualSelectListController" } ] }');
        }
        req.setMethod('POST');
        return res.getBody();
    }
}