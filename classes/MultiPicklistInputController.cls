public with sharing class MultiPicklistInputController {

    @AuraEnabled
    public static String getFieldLabel( String SObjectName, String fieldName ) {
        String label = Schema.getGlobalDescribe().get(SObjectName).getDescribe().fields.getMap().get(fieldName).getDescribe().getLabel();
        return label;
    }

    @AuraEnabled
    public static Map<String, String> GetPicklistOptions(String SObjectName, String fieldName, String controllingValue) {
        if (String.isNotEmpty(controllingValue)) {
            Map<Object,Map<String, String>> dependentValues = getDependentPicklistValues(Schema.getGlobalDescribe().get(SObjectName).getDescribe().fields.getMap().get(fieldName));
            if (dependentValues.containsKey(controllingValue)) {
                return dependentValues.get(controllingValue);
            }
            else {
                return null;
            }
        }
        else {
            return GetPicklistValues(SObjectName, fieldName);
        }
    }

    private static Map<String, String> GetPicklistValues(String SObjectName, String fieldName) {

        Schema.sObjectType objType = Schema.getGlobalDescribe().get(SObjectName);
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        list<Schema.PicklistEntry> entries = fieldMap.get(fieldName).getDescribe().getPickListValues();

        Map<String, String> options = new Map<String, String>();
        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive()) {
                options.put(entry.getValue(), entry.getLabel());
            }
        }
        return options;
    }

    private static Map<Object,Map<String, String>> GetDependentPicklistValues(Schema.sObjectField dependToken)
    {
        Schema.DescribeFieldResult depend = dependToken.getDescribe();
        Schema.sObjectField controlToken = depend.getController();
        if ( controlToken == null ) return null;
        Schema.DescribeFieldResult control = controlToken.getDescribe();
        List<Schema.PicklistEntry> controlEntries = (control.getType() == Schema.DisplayType.Boolean ? null : control.getPicklistValues());

        String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
        Map<Object, Map<String, String>> dependentPicklistValues = new Map<Object, Map<String, String>>();
        for ( Schema.PicklistEntry entry : depend.getPicklistValues() ) {
            if ( entry.isActive() )
            {
                List<String> base64chars = String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++)
                {
                    //Object controlValue = (controlEntries == null ? (Object) (index == 1) : (Object) (controlEntries[ index ].isActive() ? controlEntries[ index ].getLabel() : null));
                    Object controlValue = (controlEntries == null ? (Object) (index == 1) : (Object) (controlEntries[ index ].isActive() ? controlEntries[ index ].getValue() : null));
                    Integer bitIndex = index / 6;
                    Integer bitShift = 5 - Math.mod(index, 6);
                    if (controlValue == null || (base64map.indexOf(base64chars[ bitIndex ] ) & (1 << bitShift)) == 0) continue;
                    if (!dependentPicklistValues.containsKey(controlValue))
                    {
                        dependentPicklistValues.put(controlValue, new Map<String, String>());
                    }
                    dependentPicklistValues.get(controlValue).put(entry.getValue(), entry.getLabel());
                }
            }
        }
        return dependentPicklistValues;
    }
}