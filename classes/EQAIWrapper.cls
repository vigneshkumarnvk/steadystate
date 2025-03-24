/*
Dated    : 07/30/2023
Summary  : Wrapper class for EQAI callouts
* Modification Log :
 * Developer                 Date                   Description
 * ----------------------------------------------------------------------------------------------------------               
Harika Madapathi           07/30/2023              67233 - Building GetGeneratorInfo API Callout
Avinash Panda              09/11/2023              US95612 - Add Street Address to ES Generator Look Up Button on Quote/Order
Sanjana R				   01/21/2025			   US138841: SF - Add Site Location to Generator Lookup
*************************************************************************************************************/
public virtual class EQAIWrapper {
    
    public class GetGeneratorInfoRequestWrapper{
        public string epa_id {get;set;}
        public string generator_name {get;set;}
        public string generator_address_1 {get;set;}
        public string generator_city {get;set;}
        public string generator_zip_code {get;set;}
        public string generator_state {get;set;}
 	}
     public class GetGeneratorInfoResponseWrapper{
        public string Name {get;set;}
        public string Street_Address {get;set;}
        public string City {get;set;}
        public string State {get;set;}
        public string Zip {get;set;}
        public string EPA_ID {get;set;}
        public string Business_Phone {get;set;}
        public Integer NAICS_ID {get;set;}
        public integer EQAI_generator_ID {get;set;}
        public string generator_country {get;set;} //DE37105
        public string Site_Location {get;set;} //US138841
 	}
     public class ResponseWrapper{
        public list<GetGeneratorInfoResponseWrapper> siteList{get;set;}
         public string Error{get;set;}
    }

}