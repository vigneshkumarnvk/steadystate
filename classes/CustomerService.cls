@RestResource(urlMapping='/CustomerService/*')
global with sharing class CustomerService {
    @HttpPut
    global static void createOrUpdateCustomers() {
        ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
        logData.className = 'CustomerService';
        logData.methodName = 'createOrUpdateCustomers'; 
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            String jsonString = req.requestBody.toString();
            system.debug('jsonString: ' + jsonString);
            logData.serviceRequest = 'CustomerServiceReq>>' + jsonString;
            List<CustomerRequest.CustomerInfo> customersInfoList = 
                (List<CustomerRequest.CustomerInfo>) JSON.deserialize(jsonString, List<CustomerRequest.CustomerInfo>.class);
            
            List<Account> accountsToUpsert = new List<Account>();
            Set<String> eqaiCustomerIds = new Set<String>();
            Set<String> d365CustomerNumbers = new Set<String>();
            List<String> responseList = new List<String>();
            Boolean hasErrors = false;
            Set<String> accountNumbers = new Set<String>();
            Set<String> execTerritoryCodes = new Set<String>();
            Set<String> paymentTermsCodes = new Set<String>();
            
            // Collect necessary IDs for lookups
            for (CustomerRequest.CustomerInfo customerInfo : customersInfoList) {
                if (String.isNotBlank(customerInfo.ax_customer_id)) {
                    accountNumbers.add(customerInfo.ax_customer_id);
                }
                
                if (String.isNotBlank(customerInfo.territory_code)) {
                    execTerritoryCodes.add(customerInfo.territory_code); 
                }
                
                if (String.isNotBlank(customerInfo.terms_code)) {
                    paymentTermsCodes.add(customerInfo.terms_code);
                }
            }
            
            
            
            
            
            // Query Salesperson records based on Territory Codes (Territory_Code__c)
            Map<String, Id> territoryCodeToSalespersonId = new Map<String, Id>();
            for (Salesperson__c salesperson : [
                SELECT Id, Territory_Code__c 
                FROM Salesperson__c 
                WHERE Territory_Code__c IN :execTerritoryCodes
            ]) {
                territoryCodeToSalespersonId.put(salesperson.Territory_Code__c, salesperson.Id);
            }
            
            // Query Payment Term records
            Map<String, Id> paymentTermMap = new Map<String, Id>();
            for (Payment_Term__c term : [
                SELECT Id, EQAI_Terms_Code__c 
                FROM Payment_Term__c 
                WHERE EQAI_Terms_Code__c IN :paymentTermsCodes
            ]) {
                paymentTermMap.put(term.EQAI_Terms_Code__c, term.Id);
            }
            
            Map<String, String> countryCodeMap = new Map<String, String>();
            Map<String, String> eqaiCountryCodeMap = new Map<String, String>();
            // Custom metadata for country code
            Sales_Order_EQAI_Mapping__mdt[] salesOrderEQIMappingRecords = [
                SELECT EQAI_Field_Value__c, Salesforce_Field_Value__c 
                FROM Sales_Order_EQAI_Mapping__mdt 
                WHERE EQAI_Field_Name__c = 'Country_Code'];
            for (Sales_Order_EQAI_Mapping__mdt record : salesOrderEQIMappingRecords) {
                countryCodeMap.put(record.EQAI_Field_Value__c, record.Salesforce_Field_Value__c);
            }            
            if (!countryCodeMap.isEmpty())
                eqaiCountryCodeMap = CountryCodeHandler.getActiveCountries('Sales_Order__c','Site_Country__c',countryCodeMap);
            
            for (CustomerRequest.CustomerInfo customerInfo : customersInfoList) {
                if (String.isNotBlank(customerInfo.customer_ID)) {
                    eqaiCustomerIds.add(customerInfo.customer_ID);
                } 
                if (String.isNotBlank(customerInfo.ax_customer_id)) {
                    d365CustomerNumbers.add(customerInfo.ax_customer_id);
                }
            }
            system.debug('eqaiCustomerIds'+eqaiCustomerIds);
            system.debug('d365CustomerNumbers'+d365CustomerNumbers);
            // Query existing Accounts
            List<Account> existingAccounts = [
                SELECT Id, Sage_Customer_No__c, EQAI_Customer_ID__c 
                FROM Account 
                WHERE (Sage_Customer_No__c IN :d365CustomerNumbers AND EQAI_Customer_ID__c IN :eqaiCustomerIds)
            ];
            
            Map<String, Account> existingAccountMap = new Map<String, Account>();
            
            for (Account acc : existingAccounts) {
                String key = (acc.Sage_Customer_No__c != null ? acc.Sage_Customer_No__c.toUpperCase() : '') 
                    + '|' + 
                    (acc.EQAI_Customer_ID__c != null ? acc.EQAI_Customer_ID__c.toUpperCase() : '');
                                system.debug('key'+key);

                existingAccountMap.put(key, acc);
            }
            
            
            Subsidiary_Company__c theSCompany = [SELECT Id, Name FROM Subsidiary_Company__c WHERE Name = '1-REPUBLIC SERVICES'];
            
            for (CustomerRequest.CustomerInfo customerInfo : customersInfoList) {
                Account account;
                
                String accountKey = (customerInfo.ax_customer_id != null ? customerInfo.ax_customer_id.toUpperCase() : '') 
                    + '|' + 
                    (customerInfo.customer_ID != null ? customerInfo.customer_ID.toUpperCase() : '');
                system.debug('accountKey'+accountKey);

                
                if (existingAccountMap.containsKey(accountKey)) {
                    account = existingAccountMap.get(accountKey);
                } else {
                    account = new Account();
                    
                    account.Name = customerInfo.cust_name;
                    account.Type = 'Customer';
                    account.Subsidiary_Company__c = theSCompany.Id; 
                    account.Sage_Customer_No__c = customerInfo.ax_customer_id;
                    account.Website = customerInfo.cust_website;
                    account.Phone = customerInfo.cust_phone;
                    account.Fax = customerInfo.cust_fax;
                    
                    // Billing Address
                    account.BillingStreet = customerInfo.bill_to_addr1;
                    account.BillingCity = customerInfo.bill_to_city;
                    account.BillingStateCode = customerInfo.bill_to_state;
                    account.BillingPostalCode = customerInfo.bill_to_zip_code;
                    account.BillingCountryCode = (!(eqaiCountryCodeMap.isEmpty()) && eqaiCountryCodeMap.containsKey(customerInfo.bill_to_country)) ? eqaiCountryCodeMap.get(customerInfo.bill_to_country) : customerInfo.bill_to_country;
                    
                    // Shipping Address
                    account.ShippingStreet = customerInfo.cust_addr1;
                    account.ShippingCity = customerInfo.cust_city;
                    account.ShippingStateCode = customerInfo.cust_state;
                    account.ShippingPostalCode = customerInfo.cust_zip_code;
                    account.ShippingCountryCode = (!(eqaiCountryCodeMap.isEmpty()) && eqaiCountryCodeMap.containsKey(customerInfo.cust_country)) ? eqaiCountryCodeMap.get(customerInfo.cust_country) : customerInfo.cust_country;
                    
                    account.NAICS_Code__c = customerInfo.cust_naics_code;
                    account.EQAI_Customer_ID__c = customerInfo.customer_ID;
                    account.D365_Customer_Classification_Group__c = customerInfo.d365_customer_classification_group;
                    account.Intercompany__c = (customerInfo.eq_flag == 'T');
                    account.MSG__c = (customerInfo.msg_customer_flag == 'T'); 
                    account.National_Account__c = (customerInfo.national_account_flag== 'T');
                    account.Retail__c = (customerInfo.retail_customer_flag== 'T');
                    account.Prevent_Billing_Project__c = (customerInfo.sfdc_billing_package_flag== 'T');
                    account.Credit_Limit_LCY__c = customerInfo.credit_limit;
                    account.PO_Required__c = (customerInfo.PO_required_flag == 'T');
                    if (customerInfo.cust_status == 'A') {
                        account.Customer_Status__c = 'Active';
                    } else if (customerInfo.cust_status == 'I') {
                        account.Customer_Status__c = 'Inactive';
                    }                            
                    if (territoryCodeToSalespersonId.containsKey(customerInfo.territory_code)) {
                        account.Account_Executive__c = territoryCodeToSalespersonId.get(customerInfo.territory_code);
                    }
                    
                    
                    
                    if (customerInfo.terms_code != null && paymentTermMap.containsKey(customerInfo.terms_code)) {
                        account.Payment_Term__c = paymentTermMap.get(customerInfo.terms_code);
                    }
                }
                
                // Update specific fields based on EQAI data
                
                account.EQAI_Customer_ID__c = customerInfo.customer_ID;
                account.PO_Required__c = (customerInfo.PO_required_flag == 'T');
                if (customerInfo.cust_status == 'A') {
                    account.Customer_Status__c = 'Active';
                } else if (customerInfo.cust_status == 'I') {
                    account.Customer_Status__c = 'Inactive';
                }               
                account.Prevent_Billing_Project__c = (customerInfo.sfdc_billing_package_flag == 'T');
                account.MSG__c = (customerInfo.msg_customer_flag == 'T');
                account.National_Account__c = (customerInfo.national_account_flag == 'T');
                account.Retail__c = (customerInfo.retail_customer_flag == 'T');
                
                accountsToUpsert.add(account);
            }
            
            try {
                upsert accountsToUpsert;
                for (Account acc : accountsToUpsert) {
                    responseList.add('{"isSuccess":true,"statusMessage":"Customer updated/created successfully","SF_Account_CSID":"' + acc.Id + '","D365_customer_id":"' + acc.Sage_Customer_No__c + '"}');
                }
                res.statusCode = 200;
                res.responseBody = Blob.valueOf('[' + String.join(responseList, ',') + ']');
            } catch (DmlException e) {
                // Error handling if upsert fails
                hasErrors = true;
                responseList.add('{"isSuccess":false,"statusMessage":"Error during upsert: ' + e.getMessage() + '","SF_Account_CSID":"","D365_customer_id":""}');
                res.statusCode = 500;
                res.responseBody = Blob.valueOf('[' + String.join(responseList, ',') + ']');
            }
            
            logData.serviceResponse = 'CustomerServiceRes>>' + res.responseBody.toString();
            ApplicationLog.startLog(JSON.serialize(logData));
            
        } catch (Exception e) {
            logData.serviceResponse = 'CustomerServiceRes>>' + e.getMessage();
            ApplicationLog.startLog(JSON.serialize(logData));
            System.debug('Exception: ' + e.getMessage());
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('[{"isSuccess":false,"statusMessage":"Error: ' + e.getMessage() + '","SF_Account_CSID":"","D365_customer_id":""}]');
            ApplicationLog.startLog(JSON.serialize(logData));
        }
    }
}