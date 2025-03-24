public class LookupInputController {
    @AuraEnabled
    public static List<SObject> fetchRecords(String sObjectName, String[] fields, String[] fieldsToSearch, String[] keyFields, String[] filters, String sorting, String keyword, Integer fetchLimit) {
        Map<String, Schema.SObjectField> sObjectFields = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();

        if (fields == null || fields.size() == 0) {
            if (sObjectFields.containsKey('Name')) {
                fields.add('Name');
            }
        }
        
        Set<String> fieldSet = new Set<String>(fields);
        fieldSet.add('Id');
        fields = new List<String>(fieldSet);
        
        if (fieldsToSearch == null || fieldsToSearch.size() == 0) {
            fieldsToSearch = fields.clone();
        }
        fieldSet = new Set<String>(fieldsToSearch);
        fieldSet.remove('Id');
        fieldsToSearch = new List<String>(fieldSet);

        /*
        List<String> filters = new List<String>();
        if (filter != null) {
            filters.add(filter);
        }
        */

        //init keyword filters
        List<String> keywordFilters = new List<String>();
        if (String.isNotEmpty(keyword)) {
            for (String fieldName : fieldsToSearch) {
                Schema.SOAPType fieldSOAPType = null;
                Schema.DisplayType displayType = null;
                if (fieldName.contains('.')) { //lookup relationship
                    List<String> names = fieldName.split('\\.');
                    String parentSObjectName = SObjectName;
                    for (Integer i = 0; i < names.size(); i++) { 
                        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(parentSObjectName).getDescribe().fields.getMap();
                        if (i < names.size() - 1) { 
                            for (Schema.SObjectField field : fieldMap.values()) {
                                Schema.DescribeFieldResult fieldResult = field.getDescribe();
    
                                if (fieldResult.getRelationshipName() != null) {
                                    if (fieldResult.getRelationshipName() == names[i]) {
                                        parentSObjectName = fieldResult.getReferenceTo()[0].getDescribe().getName();
                                        break;
                                    }
                                }
                            }
                        } else {
                            if (fieldMap.containsKey(names[i])) {
                                Schema.DescribeFieldResult fieldResult = fieldMap.get(names[i]).getDescribe();
                                fieldSOAPType = fieldResult.getSOAPType();
                                displayType = fieldResult.getType();
                            }
                        }
                    }
                }
                else {
                    Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(SObjectName).getDescribe().fields.getMap();
                    if (fieldMap.containsKey(fieldName)) {
                        Schema.DescribeFieldResult fieldResult = fieldMap.get(fieldName).getDescribe();
                        fieldSOAPType = fieldResult.getSOAPType();
                        displayType = fieldResult.getType();
                    }
                }

                if (fieldSOAPType == Schema.SOAPType.String) {
                    if (displayType == Schema.DisplayType.MULTIPICKLIST) {
                        keywordFilters.add(fieldName + ' INCLUDES (\'' + String.escapeSingleQuotes(keyword) + '\')');
                    }
                    else {
                        keywordFilters.add(fieldName + ' LIKE \'%' + String.escapeSingleQuotes(keyword) + '%\'');
                    }
                }                    
            }
        }

        /*
        if (keywordFilters.size() > 0) {
            filters.add('(' + String.join(keywordFilters, ' OR ') + ')');

            if (appendableQueryResultFilters != null && appendableQueryResultFilters.size() > 0) {
                for (String appendableQueryResultFilter : appendableQueryResultFilters) {
                    appendableQueryResultFilter = appendableQueryResultFilter + ' AND (' + String.join(keywordFilters, ' OR ') + ')';
                }
            }
        }
        */

        List<String> filterClauses = new List<String>();
        if (filters.size() == 0) {
            filters.add('Id <> NULL'); //a dummy filter to activate the filters
        }
        /*
        if (appendableQueryResultFilters != null && appendableQueryResultFilters.size() > 0) {
            for (String appendableQueryResultFilter : appendableQueryResultFilters) {
                filterClauses.add(appendableQueryResultFilter);
            }
        }
        */

        if (keywordFilters.size() > 0) {
            for (Integer i = 0; i < filters.size(); i++) {
                filters[i] = filters[i] + ' AND (' + String.join(keywordFilters, ' OR ') + ')';
            }
        }

        filterClauses.addAll(filters);

        String sortingClause = sorting;
        if (sortingClause == null) {
            if (sObjectFields.containsKey('Name')) {
                sortingClause = 'Name';
            }
            else {
                sortingClause = 'LastModifiedDate DESC';
            }
        }

        if (fetchLimit == null || fetchLimit == 0) {
            fetchLimit = 100;
        }

        List<String> queryStrings = new List<String>();

        String selectClause =  'SELECT ' + String.join(fields, ',') + ' FROM ' + sObjectName;

        for (String filterClause : filterClauses) {
            String queryString = selectClause + ' WHERE ' + filterClause + ' ORDER BY ' + sortingClause + ' LIMIT ' + String.valueOf(fetchLimit);
            queryStrings.add(queryString);
        }

        //system.debug('** ' + queryStrings);

        List<SObject> records = new List<SObject>();
        for (String queryString : queryStrings) {
            //if (1==1) throw new DataException(queryString);
            List<SObject> result = Database.query(queryString);
            records.addAll(result);
        }

        Map<String, SObject> mapRecordsByKeyFields = new Map<String, SObject>();
        if (keyFields.size() == 0) {
            keyFields.add('Id'); //remove duplicate records resulted from multiple query results
        }
        if (keyFields.size() > 0) {

            for (SObject record : records) {
                List<String> keys = new List<String>();
                for (String field : keyFields) {
                    Object value = record.get(field);
                    if (value != null) {
                        keys.add(String.valueOf(value));
                    }
                    else {
                        keys.add('');
                    }
                }
                String keyString = String.join(keys, ';');
                if (!mapRecordsByKeyFields.containsKey(keyString)) {
                    mapRecordsByKeyFields.put(keyString, record);
                }
            }
        }

        //sort the map and return number of records by the fetch limit
        List<String> sorts = sortingClause.split(',');
        String[] tokens = sorts[0].split(' ');

        if (tokens.size() > 0) {
            SortableRecord.FieldName = tokens[0].trim();
            if (sObjectFields.get(SortableRecord.FieldName) == null) {
                throw new DataException('Invalid field name: ' + SortableRecord.FieldName);
            }
            Schema.DescribeFieldResult fieldResult = sObjectFields.get(SortableRecord.FieldName).getDescribe();
            SortableRecord.FieldDataType = fieldResult.getSoapType().name();
            if (tokens.size() > 1) {
                SortableRecord.Descending = (tokens[1].trim().toUpperCase() == 'DESC');
            }
        }

        List<SortableRecord> sortableRecords = new List<SortableRecord>();
        for (SObject record : mapRecordsByKeyFields.values()) {
            sortableRecords.add(new SortableRecord(record));
        }
        sortableRecords.sort();

        List<SObject> result = new List<SObject>();
        for (Integer i = 0; i < sortableRecords.size(); i++) {
            result.add(sortableRecords[i].Record);
            if (i >= fetchLimit) {
                break;
            }
        }

        return result;
    }
	 @AuraEnabled(cacheable=true)
    public static List<Sobject> getRecords(String sObjectName, String[] fields, String[] fieldsToSearch, String[] keyFields, String[] filters, String sorting, String keyword, Integer fetchLimit,String parentId) {
        List<Sobject> result = new List<Sobject>();
        String groupCServiceCenters = System.Label.GroupCServiceCenters.replaceAll('\\s+','');
        List<String> groupCList = groupCServiceCenters.split(',');
        List<Sobject> getResult = fetchRecords(sObjectName, fields, fieldsToSearch, keyFields, filters, sorting, keyword, fetchLimit);
        System.debug('Parent Id '+parentId);
        if(parentId == null){
            return result;
        }
        if(sObjectName == 'Service_Center__c'){
            TM__c tmRecord = [Select Id,Name,Service_Center__r.Name,Service_Center__r.Description__c FROM TM__c WHERE Id =: parentId];
            if(System.Label.GroupCServiceCenters.contains(tmRecord.Service_Center__r.Name)){
                result.add(tmRecord.Service_Center__r);
                for(Sobject record : getResult){
                    Service_Center__c scRecord = (Service_Center__c)record;                
                    if(scRecord.Name == '99 - Temp'){
                        result.add(record);
                        break;
                    }
                }
                
            }else{
                for(Sobject record : getResult){
                    Service_Center__c scRecord = (Service_Center__c)record;
                    if(!System.Label.GroupCServiceCenters.contains(scRecord.Name)){
                        result.add(record);
                    }
                }
            }
        }
        else if(sObjectName == 'Resource__c'){
            if(System.Label.ValidateGroupC == 'True'){
            TM__c tmRecord = [Select Id,Name,Service_Center__r.Name,Service_Center__r.Description__c FROM TM__c WHERE Id =: parentId];
            if(groupCList.contains(tmRecord.Service_Center__r.Name)){
                for(Sobject record : getResult){
                    Resource__c resRecord = (Resource__c)record;
                    if(tmRecord.Service_Center__r.Name == resRecord.Service_Center__r.Name || resRecord.Service_Center__r.Name == '99 - Temp'){                        
                    	result.add(record);
                    }
                }
            }else{
                for(Sobject record : getResult){
                    Resource__c resRecord = (Resource__c)record;  
                    if(!groupCList.contains(resRecord.Service_Center__r.Name)){                        
                        result.add(record);
                    }
                }
            }
            }else{
                return getResult;            
        }
            
        }
        return result;
    }
    

    public class SearchException extends exception {}
}