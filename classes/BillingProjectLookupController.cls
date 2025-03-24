public with sharing class BillingProjectLookupController extends EQAIWrapper{
    public class GeneratorLookupControllerException extends Exception {}
    
    @AuraEnabled
    public static Model getBillingPackageLookup(String customerId, String serviceCenter){
        System.debug('inside backend controller method1:::::::::::::::'+customerId);
        String profitCenterId = '';
        String companyId = '';
        map<String,String> company_Id_EQIMap = new map<String,String>();
        map<String,String> profit_Ctr_Id_EQIMap = new map<String,String>();
        for(Sales_Order_EQAI_Mapping__mdt salesOrderEQIMappingRecord :[select Id,EQAI_Field_Name__c,EQAI_Field_Value__c,EQAI_Table_Name__c,Salesforce_Field_API_Name__c,Salesforce_Field_Value__c from Sales_Order_EQAI_Mapping__mdt]){
            if(salesOrderEQIMappingRecord.EQAI_Field_Name__c =='company_id'){
                company_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c,salesOrderEQIMappingRecord.EQAI_Field_Value__c);
            }
            else if(salesOrderEQIMappingRecord.EQAI_Field_Name__c=='profit_ctr_id'){
                profit_Ctr_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c,salesOrderEQIMappingRecord.EQAI_Field_Value__c);
            }
            
    }

     profitCenterId =  profit_Ctr_Id_EQIMap.get(serviceCenter);  
     companyId =  company_Id_EQIMap.get(serviceCenter);  
     try{
        ResponseWrapper response = getBillingProjectsFromEQAI(customerId, profitCenterId, companyId);
        if (response != null && !String.isEmpty(response.Error)){
            throw new GeneratorLookupControllerException(response.Error);
        } else {
            return new Model(response);
        }
     }
     catch (Exception ex) {
        throw new AuraHandledException(ex.getMessage());
    }

        //return null;
    }

    public static ResponseWrapper getBillingProjectsFromEQAI(String customerId, String profitCtrId,String companyId){
        EQAI_API_URL_Extensions__mdt getBillingProjectLookupDetails = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='getBillingProjectLookupDetails'];
        HttpRequest req = new HttpRequest();
        String endPoint =     getBillingProjectLookupDetails.API_Extension__c;
        endpoint = endPoint + 'D365CustomerId='+customerId+'&CompanyId='+Integer.valueOf(companyId)+'&ProfitCenterId='+Integer.valueOf(profitCtrId);
        System.debug('endpoint::::::::::::'+endpoint);
        req.setEndpoint('callout:EQAI_Base_URL'+endpoint);
            req.setHeader('x-api-key',getBillingProjectLookupDetails.API_Key__c);
            req.setHeader('x-secret-token',getBillingProjectLookupDetails.API_Token__c);
            req.setHeader('Content-Type','application/json');
            req.setMethod('GET');
            req.setTimeOut(20000);
            Http http = new Http();
            System.debug('Request: '+req.getEndpoint());
            HTTPResponse res = http.send(req);
            String response = res.getBody();
            System.debug('Response: '+ response);
            ResponseWrapper resWrapper = new ResponseWrapper();
            if(res.getStatusCode() == 200){
                System.debug('Response code::::::'+res.getStatusCode());
                List<GetBillingProjectResponseWrapper> billingProjectList = new List<GetBillingProjectResponseWrapper>();
                if(response.contains('"E-manifest Fee":') ||response.contains('"Fee Type":') ||response.contains('"Contact E-mail":') ||response.contains('"Contact Name":') ||response.contains('"Distribution method":') ||response.contains('"FIS AE":') ||response.contains('"FIS Territory":') ||response.contains('"ES AE":') || response.contains('"ES Territory":') ||response.contains('"Link Req":') ||response.contains('"Expiration Date":') ||response.contains('"Start Date":') ||response.contains('"PO Amount":') ||response.contains('"PO Description":') || response.contains('"Release":') ||response.contains('"Billing Project ID":') || response.contains('"Billing Project Name":') || response.contains('"Fee":') || (response.contains('"Status":')) || (response.contains('"Purchase Order":')) ){

                    while (response.contains('"Billing Project ID"')) {
                        response = response.replace('"Billing Project ID":', '"billing_project_Id":');
                    }
                    while (response.contains('"Billing Project Name"')) {
                        response = response.replace('"Billing Project Name":', '"billing_project_name":');
                    }
                    while (response.contains('"Purchase Order"')) {
                        response = response.replace('"Purchase Order":', '"purchase_order":');
                    }
                    while (response.contains('"PO Description"')) {
                        response = response.replace('"PO Description":', '"po_description":');
                    }
                    while (response.contains('"PO Amount"')) {
                        response = response.replace('"PO Amount":', '"po_amount":');
                    }
                    while (response.contains('"Start Date"')) {
                        response = response.replace('"Start Date":', '"start_date":');
                    }
                    while (response.contains('"Expiration Date"')) {
                        response = response.replace('"Expiration Date":', '"expiration_date":');
                    }
                    while (response.contains('"Link Reqd"')) {
                        response = response.replace('"Link Reqd":', '"link_reqd":');
                    }
                    while (response.contains('"ES Territory"')) {
                        response = response.replace('"ES Territory":', '"es_territory":');
                    }
                    while (response.contains('"Link Reqd"')) {
                        response = response.replace('"Link Reqd":', '"link_reqd":');
                    }
                    while (response.contains('"ES AE"')) {
                        response = response.replace('"ES AE":', '"es_ae":');
                    }
                    while (response.contains('"FIS Territory"')) {
                        response = response.replace('"FIS Territory":', '"fis_territory":');
                    }
                    while (response.contains('"FIS AE"')) {
                        response = response.replace('"FIS AE":', '"fis_ae":');
                    }
                    while (response.contains('"Distribution method"')) {
                        response = response.replace('"Distribution method":', '"distribution_method":');
                    }
                    while (response.contains('"Contact Name"')) {
                        response = response.replace('"Contact Name":', '"contact_name":');
                    }
                    while (response.contains('"Contact E-mail"')) {
                        response = response.replace('"Contact E-mail":', '"contact_email":');
                    }
                    while (response.contains('"Fee Type"')) {
                        response = response.replace('"Fee Type":', '"fee_type":');
                    }
                    while (response.contains('"E-manifest Fee"')) {
                        response = response.replace('"E-manifest Fee":', '"manifest_fee":');
                    }

                    System.debug('After update Response: '+ response);
                    List<GetBillingProjectResponseWrapper> billingProjectWrapperList = (List<GetBillingProjectResponseWrapper>)System.JSON.deserialize(response,List<GetBillingProjectResponseWrapper>.class);
                    resWrapper.billingProjectList = billingProjectWrapperList;
                    resWrapper.Error = null;

                }

            }
            else if(res.getStatusCode() == 400){
                resWrapper.billingProjectList = null;
                  resWrapper.Error = res.getBody();
                  System.debug('errorWrapper:'+ resWrapper.Error);
            }
            
        return resWrapper;
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
        public List<BillingProjectInfoResponse> generatorStateResult { get; set; }

        public Model (ResponseWrapper result){
            this.generatorStateResult = new List<BillingProjectInfoResponse>();
            if (result != null && result.billingProjectList != null && !result.billingProjectList.isEmpty()){
                for (GetBillingProjectResponseWrapper eachBillingProjectInfoResponse : result.billingProjectList) {
                    this.generatorStateResult.add(new BillingProjectInfoResponse(eachBillingProjectInfoResponse));
                } 
            } 
        }
    }

    public class BillingProjectInfoResponse {
        @AuraEnabled
        public string projectId { get;set; }

        @AuraEnabled
        public string projectname { get;set; }

        @AuraEnabled
        public string fee { get;set; }

        @AuraEnabled
        public string status { get;set; }

        @AuraEnabled
        public string purchaseorder { get;set; }

        @AuraEnabled
        public string release { get;set; }

        @AuraEnabled
        public string podescription { get;set; }

        @AuraEnabled
        public string poamount { get;set; }

        @AuraEnabled
        public string startdate { get;set; }

        @AuraEnabled
        public string expirationdate { get;set; }

        @AuraEnabled
        public string link { get;set; }

        @AuraEnabled
        public string esterritory { get;set; }

        @AuraEnabled
        public string esae { get;set; }


        @AuraEnabled
        public string fisterritory { get;set; }

        @AuraEnabled
        public string fisae { get;set; }

        @AuraEnabled
        public string distributionmethod { get;set; }

        @AuraEnabled
        public string contactname { get;set; }

        @AuraEnabled
        public string contactemail { get;set; }

        @AuraEnabled
        public string feetype { get;set; }

        @AuraEnabled
        public string manifestfee { get;set; }

        @AuraEnabled
        public Boolean selected { get; set; }

        public BillingProjectInfoResponse(GetBillingProjectResponseWrapper billingprojectInfoResponse){
            this.projectId = billingprojectInfoResponse.billing_project_Id;
            this.projectname = billingprojectInfoResponse.billing_project_name;
            this.fee = billingprojectInfoResponse.Fee;
            this.status = billingprojectInfoResponse.Status;
            this.purchaseorder = billingprojectInfoResponse.purchase_order;
            this.release = billingprojectInfoResponse.Release;
            this.podescription = billingprojectInfoResponse.po_description;
            this.poamount = billingprojectInfoResponse.po_amount;
            this.startdate = billingprojectInfoResponse.start_date;
            this.expirationdate = billingprojectInfoResponse.expiration_date;
            this.link = billingprojectInfoResponse.link_reqd;
            this.esterritory = billingprojectInfoResponse.es_territory;
            this.esae = billingprojectInfoResponse.es_ae;
            this.fisterritory = billingprojectInfoResponse.fis_territory;
            this.fisae = billingprojectInfoResponse.fis_ae;
            this.distributionmethod = billingprojectInfoResponse.distribution_method;
            this.contactname = billingprojectInfoResponse.contact_name;
            this.contactemail = billingprojectInfoResponse.contact_email;
            this.feetype = billingprojectInfoResponse.fee_type;
            this.manifestfee = billingprojectInfoResponse.manifest_fee;
            this.selected = false;
        }


 	}

     public class GetBillingProjectResponseWrapper{
        public string billing_project_Id {get;set;}
        public string billing_project_name {get;set;}
        public string Fee {get;set;}
        public string Status {get;set;}
        public string purchase_order {get;set;}
        public string Release {get;set;}
        public string po_description {get;set;}
        public string po_amount {get;set;}
        public string start_date {get;set;}
        public string expiration_date {get;set;}
        public string link_reqd {get;set;}
        public string es_territory {get;set;}
        public string es_ae {get;set;}
        public string fis_territory {get;set;}
        public string fis_ae {get;set;}
        public string distribution_method {get;set;}
        public string contact_name {get;set;}
        public string contact_email {get;set;}
        public string fee_type {get;set;}
        public string manifest_fee {get;set;}

 	}

     public class ResponseWrapper{
        public list<GetBillingProjectResponseWrapper> billingProjectList{get;set;}
         public string Error{get;set;}
    }

     

     
}