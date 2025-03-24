public with sharing class AutoNumberController {
    public static Boolean ValidateFormatString(String formatString) {
        Pattern pat = Pattern.compile('\\{([^}]*)\\}');
        Matcher mat = pat.matcher(formatString);
        if (!mat.find() || mat.groupCount() != 1) {
            return false;
        }
        return true;
    }
    
    public static String GetNextNumber(String name) {
        Auto_Number__c autoNumber = [SELECT Id, Displaying_Format__c, Starting_Number__c FROM Auto_Number__c WHERE Name = :name LIMIT 1 FOR UPDATE];
        String nextNoSeries = '';
        String formatString = autoNumber.Displaying_Format__c;
        Pattern pat = Pattern.compile('\\{([^}]*)\\}');
        Matcher mat = pat.matcher(formatString);
        if (mat.find()) {
            if (mat.groupCount() == 1) {
                autoNumber.Starting_Number__c += 1;
                nextNoSeries = String.valueOf(autoNumber.Starting_Number__c.intValue());
                nextNoSeries = formatString.replace(mat.group(), nextNoSeries.leftPad(mat.group().length() - 2, '0'));
                update autoNumber;
            }
        }
        return nextNoSeries;
    }
}