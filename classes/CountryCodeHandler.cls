/*************************************************************************************************
* Name         :  CountryCodeHandler
* Description  :  To Get the EQAI country code(2 Digit)
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
  Shahwaz Khan             24-07-2024             US120613:Salesforce - Contact Sync transaction handling
***********************************************************************************************************/
public class CountryCodeHandler {
    public static Map<String, String> getActiveMailingCountries(Map<String, String> mapofEQAIandSFCountry) {
        Schema.DescribeFieldResult fieldResult = Contact.MailingCountryCode.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        Map<String, String> activeCountries = new Map<String, String>();
        for (Schema.PicklistEntry picklistValue : picklistValues) {
            if (picklistValue.isActive()) {
                String countryName = picklistValue.getLabel();
                String countryCode = picklistValue.getValue();
                activeCountries.put(countryName.toUpperCase(), countryCode);
            }
        }
        Map<String, String> countryCodeMap = new Map<String, String>();
        for (String threeDigitCode : mapofEQAIandSFCountry.keySet()) {
            String countryName = mapofEQAIandSFCountry.get(threeDigitCode);
            if (activeCountries.containsKey(countryName)) {
                String twoDigitCode = activeCountries.get(countryName);
                countryCodeMap.put(threeDigitCode, twoDigitCode);
            }
        }
        System.debug('countryCodeMap::' + countryCodeMap);
        return countryCodeMap;
    }
    public static Map<String, String> getActiveCountries(String objectName,String fieldName,Map<String, String> mapofEQAIandSFCountry) {
        // Retrieve the field describe dynamically
        Schema.DescribeFieldResult fieldResult = 
        Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe();        
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        Map<String, String> activeCountries = new Map<String, String>();
        for (Schema.PicklistEntry picklistValue : picklistValues) {
            if (picklistValue.isActive()) {
                String countryName = picklistValue.getLabel();
                String countryCode = picklistValue.getValue();
                activeCountries.put(countryName.toUpperCase(), countryCode);
            }
        }       
        Map<String, String> countryCodeMap = new Map<String, String>();
        for (String threeDigitCode : mapofEQAIandSFCountry.keySet()) {            
            String countryName = mapofEQAIandSFCountry.get(threeDigitCode);
            if (activeCountries.containsKey(countryName))
                {
                    String twoDigitCode = activeCountries.get(countryName);
                    countryCodeMap.put(threeDigitCode, twoDigitCode);
                }
                else if(activeCountries.containsKey(threeDigitCode) ) {
                    String twoDigitCode = activeCountries.get(threeDigitCode);
                    countryCodeMap.put(threeDigitCode, twoDigitCode);
            }
        }
        System.debug('countryCodeMap::' + countryCodeMap);
        return countryCodeMap;
    }
}