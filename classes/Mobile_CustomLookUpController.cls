public class Mobile_CustomLookUpController {
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String keywords, String objectName, String[] displayFields, String[] additionalFields, String[] searchFields, String filterExpr) {        
        if (searchFields == null || searchFields.size() == 0) {
            searchFields.add('Name');
        }
        
        String filterExpr2 = '';
        if (String.isNotEmpty(keywords)) {
            List<String> filters = new List<String>();
            for (String field : searchFields) {
                filters.add(field + ' LIKE \'%' + keywords + '%\'');
            }
            filterExpr2 = String.join(filters, ' OR ');
            filterExpr = '(' + filterExpr2 + ') AND ' + filterExpr;
        }
        
        List < sObject > result = new List < sObject > ();
        
        List<String> fields = new List<String>();
        fields.addAll(displayFields);
        fields.addAll(additionalFields);
        if (fields.size() == 0) {
            fields.add('Id');
        }
        String sQuery =  'SELECT ' + String.join(fields, ',') + ' FROM ' + objectName;
        if (String.isNotEmpty(filterExpr)) {
            sQuery += ' WHERE ' + filterExpr;
        }
        sQuery += ' ORDER BY Name ASC limit 100';

        List < sObject > lstOfRecords = Database.query(sQuery);
        
        for (sObject obj: lstOfRecords) {
            result.add(obj);
        }
        return result;
    }
}