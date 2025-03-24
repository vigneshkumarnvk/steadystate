public with sharing class GeneratorLookupController {
    public class GeneratorLookupControllerException extends Exception {}
    
    private static Map<String, String> countryCodeMap; 
    private static Boolean isCountryCodeMapLoaded = false; 

    
    private static void loadCountryCodeMap() {
        if (!isCountryCodeMapLoaded) {
            countryCodeMap = new Map<String, String>();
            for (Sales_Order_EQAI_Mapping__mdt record : [SELECT EQAI_Field_Value__c, Salesforce_Field_Value__c 
                                                         FROM Sales_Order_EQAI_Mapping__mdt 
                                                         WHERE EQAI_Field_Name__c = 'Country_Code']) {
                                                             countryCodeMap.put(record.EQAI_Field_Value__c, record.Salesforce_Field_Value__c);
                                                         }
            
            isCountryCodeMapLoaded = true; 
        }
    }
    
    @AuraEnabled
    public static Model getGeneratorLookup(Model model){
        model.validate();
        try {
            EQAIWrapper.ResponseWrapper response = EQAIGetGeneratorInfoAPI.getMatchingSitesFromEQAI(
               model.epaId, 
               model.generatorName, 
               model.generatorAddress, 
               model.generatorCity, 
               model.generatorZipCode, 
               model.generatorState);    
            if (response != null && !String.isEmpty(response.Error)){
                throw new GeneratorLookupControllerException(response.Error);
            } else {
                return new Model(response);
            }
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    public class Model {
        @AuraEnabled
        public String epaId { get; set; }

        @AuraEnabled
        public String generatorName { get; set; }

        @AuraEnabled
        public String generatorAddress { get; set; }

        @AuraEnabled
        public String generatorCity { get; set; }

        @AuraEnabled
        public String generatorZipCode { get; set; }

        @AuraEnabled
        public String generatorState { get; set; }

        @AuraEnabled
        public List<GeneratorInfoResponse> generatorStateResult { get; set; }

        public void validate() {
            if (String.isEmpty(epaId) && String.isEmpty(generatorName) && String.isEmpty(generatorAddress) &&
                String.isEmpty(generatorCity) && String.isEmpty(generatorZipCode) && String.isEmpty(generatorState)) {
                    throw new GeneratorLookupControllerException('Please enter at least one value to search on');
                }
        }

        public Model() {
            this.epaId = '';
            this.generatorName = '';
            this.generatorAddress = '';
            this.generatorCity = '';
            this.generatorZipCode = '';
            this.generatorState = '';
        }

        public Model (EQAIWrapper.ResponseWrapper result){
            this.generatorStateResult = new List<GeneratorInfoResponse>();
            if (result != null && result.siteList != null && !result.siteList.isEmpty()){
                for (EQAIWrapper.GetGeneratorInfoResponseWrapper eachGeneratorInfoResponse : result.siteList) {
                    this.generatorStateResult.add(new GeneratorInfoResponse(eachGeneratorInfoResponse));
                } 
            } 
        }
    }

    public class GeneratorInfoResponse {
        @AuraEnabled
        public string name { get;set; }

        @AuraEnabled
        public string streetAddress { get;set; }

        @AuraEnabled
        public string city { get;set; }

        @AuraEnabled
        public string state { get;set; }

        @AuraEnabled
        public string zip { get;set; }

        @AuraEnabled
        public string epaId { get;set; }

        @AuraEnabled
        public string businessPhone { get;set; }

        @AuraEnabled
        public Integer naicsId { get;set; }

        @AuraEnabled
        public integer eqaiGeneratorId { get;set; }
        
        @AuraEnabled
        public string eqaiGeneratorCountry { get;set; }

        @AuraEnabled
        public Boolean selected { get; set; }
        
        @AuraEnabled
        public string siteLocation {get; set; } //US138841

        
        private Map<String, String> eqaiCountryCodeMap;
        public GeneratorInfoResponse(EQAIWrapper.GetGeneratorInfoResponseWrapper generatorInfoResponse){
            if (countryCodeMap == null) {
                loadCountryCodeMap(); 
            }
            
            // Get country code map
            if (!countryCodeMap.isEmpty())
                eqaiCountryCodeMap = CountryCodeHandler.getActiveCountries('Sales_Order__c','Site_Country__c',countryCodeMap);
            //DE37105 ent..
            this.name = generatorInfoResponse.Name;
            this.streetAddress = generatorInfoResponse.Street_Address;
            this.city = generatorInfoResponse.City;
            this.state = generatorInfoResponse.State;
            this.zip = generatorInfoResponse.Zip;
            this.epaId = generatorInfoResponse.EPA_ID;
            this.businessPhone = generatorInfoResponse.Business_Phone;
            this.naicsId = generatorInfoResponse.NAICS_ID;
            this.eqaiGeneratorId = generatorInfoResponse.EQAI_generator_ID;
            //DE37105
            this.eqaiGeneratorCountry = (!(eqaiCountryCodeMap.isEmpty()) && eqaiCountryCodeMap.containsKey(generatorInfoResponse.generator_country)) ? eqaiCountryCodeMap.get(generatorInfoResponse.generator_country) : generatorInfoResponse.generator_country;
            this.selected = false;
			this.siteLocation = generatorInfoResponse.Site_Location == 'T' ? 'Y' : 'N'; //US138841
        }
 	}
}