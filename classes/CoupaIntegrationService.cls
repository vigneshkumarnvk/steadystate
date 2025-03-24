public class CoupaIntegrationService {
    public static Boolean newTokenIssued = false;
    private static External_API_Token__c apiToken = new External_API_Token__c();

    public static String getTokenOAuth2(){
        List<External_API_Token__c> apiTokens = [SELECT Id, Token__c, Token_Expires_At__c, Client_Id__c FROM External_API_Token__c WHERE Client_Id__c = :IntegrationSettingUtil.coupaSetting.Client_Id__c];
        if(apiTokens.size() > 0) {
            apiToken = apiTokens[0];
            if (apiToken.Token_Expires_At__c > System.now()) {
                return apiTokens[0].Token__c;
            }
        } else {
            apiToken.Name = IntegrationSettingUtil.coupaSetting.Label;
            apiToken.Client_Id__c = IntegrationSettingUtil.coupaSetting.Client_Id__c;
        }

        Authorization oAuth = refreshToken();
        newTokenIssued = true;
        apiToken.Token__c = oAuth.access_token;
        apiToken.Token_Expires_At__c = System.now().addSeconds(oAuth.expires_in - 120);
        return oAuth.access_token;
    }

    public static Authorization refreshToken(){
        String endPoint = IntegrationSettingUtil.coupaSetting.Base_URL__c + 'oauth2/token';
        String clientIdUTF8UrlEncoded;
        String clientSecretUTF8UrlEncoded;
        String grantTypeUTF8UrlEncoded;
        String scopeUTF8UrlEncoded;

        if(String.isBlank(IntegrationSettingUtil.coupaSetting.Client_Id__c)){
            throw new DataException('Client Id cannot be blank for Coupa Integration Setting!');
        } else {
            clientIdUTF8UrlEncoded = EncodingUtil.urlEncode(IntegrationSettingUtil.coupaSetting.Client_Id__c, 'UTF-8');
        }

        if(String.isBlank(IntegrationSettingUtil.coupaSetting.Client_Secret__c)){
            throw new DataException('Client Secret cannot be blank for Coupa Integration Setting!');
        } else {
            clientSecretUTF8UrlEncoded = EncodingUtil.urlEncode(IntegrationSettingUtil.coupaSetting.Client_Secret__c, 'UTF-8');
        }

        if(String.isBlank(IntegrationSettingUtil.coupaSetting.Grant_Type__c)){
            throw new DataException('Grant Type cannot be blank for Coupa Integration Setting!');
        } else {
            grantTypeUTF8UrlEncoded = EncodingUtil.urlEncode(IntegrationSettingUtil.coupaSetting.Grant_Type__c, 'UTF-8');
        }

        if(String.isBlank(IntegrationSettingUtil.coupaSetting.Scope__c)){
            throw new DataException('Scope cannot be blank for Coupa Integration Setting!');
        } else {
            scopeUTF8UrlEncoded = EncodingUtil.urlEncode(IntegrationSettingUtil.coupaSetting.Scope__c, 'UTF-8');
        }

        String requestBody = 'grant_type=' + grantTypeUTF8UrlEncoded +
                '&client_id=' + clientIdUTF8UrlEncoded +
                '&client_secret=' + clientSecretUTF8UrlEncoded +
                '&scope=' + scopeUTF8UrlEncoded;

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endPoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setBody(requestBody);
        Http http = new Http();
        HttpResponse response = http.send(request);
        Authorization oAuth = new Authorization();

        JSONParser parser = JSON.createParser(response.getBody());
        oAuth = (Authorization)JSON.deserialize(response.getBody(), Authorization.class);
        return oAuth;
    }

    public static HttpResponse callout(String httpMethod, String endpoint, String body){
        String token = getTokenOAuth2();
        String authorizationHeader = 'Bearer ' + token;
        HttpRequest req = new HttpRequest();
        req.setMethod(httpMethod);
        req.setEndpoint(endpoint);
        req.setHeader('Accept', 'application/json');
        /*
        String apiKey = IntegrationSettingUtil.coupaSetting.API_Key__c;
        if(apiKey == null){
            throw new DataException('Please provide Coupa API Key!');
        }
        req.setHeader('X-COUPA-API-KEY', apiKey);
         */
        req.setHeader('Authorization', authorizationHeader);

        if(String.isNotBlank(body)){
            req.setBody(body);
        }

        HttpResponse res = new HttpResponse();
        /*
        if(IntegrationSettingUtil.coupaSetting.Enabled__c == true || Test.isRunningTest() == true) {
            res = new Http().send(req);
        }
         */
        res = new Http().send(req);
        saveNewToken();
        return res;
    }

    public static HttpResponse syncLookupValue(String method, String lookupName, String recordId, String recordName, Boolean isActive){
        String payload = '';
        String endPoint = IntegrationSettingUtil.coupaSetting.Base_URL__c + 'api/lookup_values/';
        if(method == 'PUT'){
            endPoint = endPoint + recordId;
        }
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('name', recordName);
        gen.writeBooleanField('active', isActive);
        gen.writeFieldName('lookup');
        gen.writeStartObject();
        gen.writeStringField('name', lookupName);
        gen.writeEndObject();
        gen.writeStringField('external-ref-num', recordName);
        gen.writeEndObject();
        payload = gen.getAsString();

        return callout(method, endPoint, payload);
    }

    public static Integer getLookupValueByName(String name, String lookupId){
        Integer coupaId = null;
        name = EncodingUtil.urlEncode(name, 'UTF-8');
        String endPoint = IntegrationSettingUtil.coupaSetting.Base_URL__c + 'api/lookup_values?name=' + name + '&lookup[id]=' + lookupId;
        HttpResponse res = callout('GET', endPoint, '');
        if(res.getStatusCode() == 200){
            List<LookupValue> lookupValues = (List<LookupValue>)JSON.deserialize(res.getBody(), List<LookupValue>.class);
            if(lookupValues.size() > 0){
                coupaId = lookupValues[0].id;
            }
        }
        return coupaId;
    }

    @future(callout=true)
    public static void getPurchaseOrder(){
        try{
            List<Company_Setup__c> acvCompanySetups = [SELECT Coupa_PO_Last_Synced__c FROM Company_Setup__c WHERE Name = 'DEFAULT'];
            String responseBody = '';
            if(acvCompanySetups.size() > 0){
                responseBody = getPOResponseBody(acvCompanySetups[0].Coupa_PO_Last_Synced__c, null);
                processPOResponse(responseBody, acvCompanySetups[0]);
            } else {
                responseBody = getPOResponseBody(null, null);
                processPOResponse(responseBody, null);
            }
        } catch (Exception e){
            throw e;
        }
    }

    public static void getPurchaseOrderByPONumber(String poNumber){
        try{
            String responseBody = '';
            if(String.isNotBlank(poNumber)){
                responseBody = getPOResponseBody(null, poNumber);
            }
            processPOResponse(responseBody, null);
        } catch (Exception e){
            throw e;
        }
    }

    public static String replaceResponseFieldName(String response, String oldFieldName, String newFieldName){
        String httpResponse = response;
        httpResponse = httpResponse.replace(oldFieldName, newFieldName);
        return httpResponse;
    }

    public static String getPOResponseBody(Datetime lastSyncedDateTime, String poNumber){
        String responseBody = '';
        Integration_Setting__mdt coupaSetting = IntegrationSettingUtil.coupaSetting;
        String endPoint = coupaSetting.Base_URL__c + 'api/purchase_orders';
        String queryFields = '["id",' +
                '"created-at",' +
                '"updated-at",' +
                '"po-number",' +
                '"status",' +
                '{"ship_to_address":[' +
                    '"id",' +
                    '"name",' +
                    '"street1",' +
                    '"street2",' +
                    '"city",' +
                    '"state",' +
                    '"postal-code",{"country":["id","code","name"]}' +
                ']},' +
                '{"supplier":["id","name","email","number"]},' +
                '{"payment_term":["id","code","description"]},' +
                '{"order_lines":[' +
                    '"id",' +
                    '"created-at",' +
                    '"updated-at",' +
                    '"description",' +
                    '"line_num",' +
                    '"type",' +
                    '"quantity",' +
                    '"price",' +
                    '"total",' +
                    '{"uom":["id","name","code"]},' +
                    '{"account":["id","name","code","segment-1","segment-2","segment-3","segment-4"]},' +
                    '{"custom_fields":["repair-type"]},' +
                    '{"supplier":["id","name","email","number"]},' +
                    '{"account_allocations":[' +
                        '"id",' +
                        '"amount",' +
                        '"pct",' +
                        '{"account":["id","name","code","segment-1","segment-2","segment-3","segment-4"]}' +
                    ']}' +
                ']}' +
                ']';

        if(poNumber != null){
            endPoint = endPoint + '/' + poNumber;
        }

        if(lastSyncedDateTime == null || poNumber != null){
            endPoint = endPoint + '?fields=' + queryFields;
        } else {
            endPoint = endPoint + '?updated-at[gt]=' + lastSyncedDateTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.ssss') + '&fields=' + queryFields;
        }
        HttpResponse res = callout('GET', endPoint, '');
        if(res.getStatusCode() == 200 && String.isNotBlank(res.getBody())){
            responseBody = res.getBody();
        } else {
            System.debug('Error: ' + res.getStatusCode() + ' -- ' + res.getBody());
            throw new CalloutException();
        }
        return responseBody;
    }

    public static void processPOResponse(String responseBody, Company_Setup__c companySetup){
        if(String.isNotBlank(responseBody)){
            Datetime lastModifiedDateTime = null;
            responseBody = replaceResponseFieldName(responseBody, 'order-lines', 'order_lines');
            responseBody = replaceResponseFieldName(responseBody, '"number"', '"num"');
            responseBody = replaceResponseFieldName(responseBody,'account-allocations', 'account_allocations');
            responseBody = replaceResponseFieldName(responseBody,'segment-1', 'segment_1');
            responseBody = replaceResponseFieldName(responseBody,'segment-2', 'segment_2');
            responseBody = replaceResponseFieldName(responseBody,'segment-3', 'segment_3');
            responseBody = replaceResponseFieldName(responseBody,'segment-4', 'segment_4');
            responseBody = replaceResponseFieldName(responseBody,'created-at', 'created_at');
            responseBody = replaceResponseFieldName(responseBody,'updated-at', 'updated_at');
            responseBody = replaceResponseFieldName(responseBody,'po-number', 'po_number');
            responseBody = replaceResponseFieldName(responseBody,'line-num', 'line_num');
            responseBody = replaceResponseFieldName(responseBody,'payment-term', 'payment_term');
            responseBody = replaceResponseFieldName(responseBody,'custom-fields', 'custom_fields');
            responseBody = replaceResponseFieldName(responseBody,'repair-type', 'repair_type');
            responseBody = replaceResponseFieldName(responseBody,'postal-code', 'postal_code');
            responseBody = replaceResponseFieldName(responseBody,'ship-to-address', 'ship_to_address');

            List<CoupaIntegrationService.OrderHeader> orderHeaders = new List<CoupaIntegrationService.OrderHeader>();
            JSONParser parser = JSON.createParser(responseBody);
            if(parser.nextToken() != null){
                if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                    orderHeaders = (List<OrderHeader>)JSON.deserialize(responseBody, List<OrderHeader>.class);
                } else if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    OrderHeader orderHeader = (OrderHeader)JSON.deserialize(responseBody, OrderHeader.class);
                    orderHeaders.add(orderHeader);
                }
            }

            Map<Integer, Purchase_Order__c> purchaseOrderByCoupaId = new Map<Integer, Purchase_Order__c>();
            Map<Integer, List<Purchase_Line__c>> purchaseLinesByCoupaOrderIds = new Map<Integer, List<Purchase_Line__c>>();
            Set<String> coupaOrderId = new Set<String>();
            Set<String> salseOrderNumbers = new Set<String>();
            Set<String> supplierNAVIds = new Set<String>();
            Set<String> equipmentNames = new Set<String>();
            Set<String> serviceCenterNames = new Set<String>();
            Map<Integer, List<AccountAllocation>> accountAllocationsBySalesLine = new Map<Integer, List<AccountAllocation>>();
            for(OrderHeader orderHeader : orderHeaders){
                coupaOrderId.add(String.valueOf(orderHeader.id));
                if(String.isNotBlank(orderHeader.supplier.num)){
                    supplierNAVIds.add(orderHeader.supplier.num);
                }
                if(orderHeader.order_lines != null) {
                    for (OrderLine orderLine : orderHeader.order_lines){
                        List<AccountAllocation> accountAllocations = new List<AccountAllocation>();
                        if(accountAllocationsBySalesLine.containsKey(orderLine.id)){
                            accountAllocations = accountAllocationsBySalesLine.get(orderLine.id);
                        }
                        System.debug('Info: orderLine ' + orderLine);
                        if(orderLine.account_allocations != null && orderLine.account_allocations.size() > 0){
                            System.debug('Info orderLine.account_allocations ' + orderLine.account_allocations);
                            for(AccountAllocation accountAllocation : orderLine.account_allocations){
                                System.debug('Info: accountAllocation ' + accountAllocation);
                                Account account = new Account();
                                account = accountAllocation.account;
                                if(String.isNotBlank(account.segment_1)){
                                    serviceCenterNames.add(account.segment_1);
                                }
                                if(String.isNotBlank(account.segment_3)){
                                    salseOrderNumbers.add(account.segment_3);
                                }
                                if(String.isNotBlank(account.segment_4)){
                                    equipmentNames.add(account.segment_4);
                                }
                                accountAllocations.add(accountAllocation);
                            }
                        } else if(orderLine.account != null){
                            //System.debug('Info: orderLine.account ' + orderLine.account);
                            Account account = new Account();
                            account = orderLine.account;
                            if(String.isNotBlank(account.segment_1)){
                                serviceCenterNames.add(account.segment_1);
                            }
                            if(String.isNotBlank(account.segment_3)){
                                salseOrderNumbers.add(account.segment_3);
                            }
                            if(String.isNotBlank(account.segment_4)){
                                equipmentNames.add(account.segment_4);
                            }
                        }

                        if(orderLine.supplier != null) {
                            if (String.isNotBlank(orderLine.supplier.num)) {
                                supplierNAVIds.add(orderLine.supplier.num);
                            }
                        }

                        if(accountAllocations.size() > 0){
                            accountAllocationsBySalesLine.put(orderLine.id, accountAllocations);
                        }
                        /*
                        if(orderLine.custom_fields != null){
                            if(String.isNotBlank(orderLine.custom_fields.sales_order.name)){
                                salseOrderNumbers.add(orderLine.custom_fields.sales_order.name);
                            }
                        }
                         */
                        //System.debug('Info: orderLine.account ' + orderLine.account);
                    }
                    //System.debug('Info: salseOrderNumbers ' + salseOrderNumbers);
                }
            }

            Map<String, Subsidiary_Vendor__c> subsidiaryVendorsByNAVId = new Map<String, Subsidiary_Vendor__c>();
            if(supplierNAVIds.size() > 0){
                List<Subsidiary_Vendor__c> subsidiaryVendors = [SELECT Account__c, Name FROM Subsidiary_Vendor__c WHERE Name IN :supplierNAVIds];
                for(Subsidiary_Vendor__c subsidiaryVendor:subsidiaryVendors){
                    subsidiaryVendorsByNAVId.put(subsidiaryVendor.Name, subsidiaryVendor);
                }
            }

            for(Purchase_Order__c purchaseOrder : [SELECT Id, Coupa_Id__c, Name, Note__c, (SELECT Id, Coupa_Item__c, Line_No__c, Coupa_Id__c, Unit_of_Measure__c, Unit_Cost__c, Quantity__c, Coupa_Allocation_Line__c FROM Purchase_Lines__r) FROM Purchase_Order__c WHERE Coupa_Id__c IN :coupaOrderId]){
                purchaseOrderByCoupaId.put(Integer.valueOf(purchaseOrder.Coupa_Id__c), purchaseOrder);
                if(purchaseOrder.Purchase_Lines__r != null){
                    purchaseLinesByCoupaOrderIds.put(Integer.valueOf(purchaseOrder.Coupa_Id__c), purchaseOrder.Purchase_Lines__r);
                }
            }

            Map<String, Id> salesOrderIdsByNames = new Map<String, Id>();
            if(salseOrderNumbers.size() > 0){
                List<Sales_Order__c> salesOrders = [SELECT Id, Name FROM Sales_Order__c WHERE Name IN :salseOrderNumbers];
                for(Sales_Order__c salesOrder : salesOrders){
                    //System.debug('Info: salesOrder ' + salesOrder);
                    salesOrderIdsByNames.put(salesOrder.Name, salesOrder.Id);
                }
            }

            Map<String, Id> equipmentIdsByNames = new Map<String, Id>();
            if(equipmentNames.size() > 0){
                List<Resource__c> equipmentResources = [SELECT Id, Name FROM Resource__c WHERE Name IN :equipmentNames];
                for(Resource__c equipmentResource : equipmentResources){
                    equipmentIdsByNames.put(equipmentResource.Name, equipmentResource.Id);
                }
            }

            Map<String, Id> serviceCenterIdsByNames = new Map<String, Id>();
            if(serviceCenterNames.size() > 0){
                List<Service_Center__c> serviceCenters = [SELECT Id, Name FROM Service_Center__c WHERE Name IN :serviceCenterNames];
                for(Service_Center__c serviceCenter : serviceCenters){
                    serviceCenterIdsByNames.put(serviceCenter.Name, serviceCenter.Id);
                }
            }

            List<Purchase_Order__c> purchaseOrders = new List<Purchase_Order__c>();

            Map<Integer, List<CoupaIntegrationService.OrderLine>> orderLinesByOrderId = new Map<Integer, List<CoupaIntegrationService.OrderLine>>();
            for(OrderHeader orderHeader : orderHeaders){
                Purchase_Order__c purchaseOrder = new Purchase_Order__c();
                if(purchaseOrderByCoupaId.containsKey(orderHeader.id)){
                    purchaseOrder = purchaseOrderByCoupaId.get(orderHeader.id);
                }
                purchaseOrder.Name = orderHeader.po_number;
                purchaseOrder.Coupa_Id__c = String.valueOf(orderHeader.id);
                purchaseOrder.Note__c = orderHeader.po_number;
                purchaseOrder.Coupa_Status__c = orderHeader.status;
                purchaseOrder.Order_Date__c = orderHeader.created_at.date();
                if(orderHeader.supplier != null){
                    purchaseOrder.Vendor_Name__c = orderHeader.supplier.name;
                    if(String.isNotBlank(orderHeader.supplier.num)){
                        String navId = orderHeader.supplier.num;
                        purchaseOrder.Coupa_Supplier_Number__c = navId;
                        if(subsidiaryVendorsByNAVId.containsKey(navId)){
                            purchaseOrder.Buy_from_Vendor__c = subsidiaryVendorsByNAVId.get(navId).Account__c;
                        }
                    }
                }
                if(orderHeader.payment_term != null){
                    purchaseOrder.Payment_Term_Name__c = orderHeader.payment_term.code;
                }
                if(orderHeader.ship_to_address != null){
                    if(String.isNotBlank(orderHeader.ship_to_address.street1)){
                        purchaseOrder.Shipping_Street__c = orderHeader.ship_to_address.street1;
                    }

                    if(String.isNotBlank(orderHeader.ship_to_address.street2)){
                        purchaseOrder.Shipping_Street__c = purchaseOrder.Shipping_Street__c + ' ' + orderHeader.ship_to_address.street2;
                    }

                    purchaseOrder.Shipping_City__c = orderHeader.ship_to_address.city;
                    purchaseOrder.Shipping_State__c = orderHeader.ship_to_address.state;
                    purchaseOrder.Shipping_Postal_Code__c = orderHeader.ship_to_address.postal_code;
                    if(orderHeader.ship_to_address.country != null){
                        purchaseOrder.Shipping_Country__c = orderHeader.ship_to_address.country.code;
                    }
                }
                purchaseOrders.add(purchaseOrder);
                if(lastModifiedDateTime == null || lastModifiedDateTime < orderHeader.updated_at){
                    lastModifiedDateTime = orderHeader.updated_at;
                }
                if(orderHeader.order_lines != null) {
                    orderLinesByOrderId.put(orderHeader.id, orderHeader.order_lines);
                }
            }

            if(purchaseOrders.size() > 0){
                CompanyMgmt.byPassTrigger = true;
                CompanyMgmt.byPassLineTrigger = true;
                upsert purchaseOrders;
                if(Test.isRunningTest() == false && companySetup != null) {
                    companySetup.Coupa_PO_Last_Synced__c = lastModifiedDateTime;
                    update companySetup;
                }
                for(Purchase_Order__c purchaseOrder:purchaseOrders){
                    purchaseOrderByCoupaId.put(Integer.valueOf(purchaseOrder.Coupa_Id__c), purchaseOrder);
                }

                List<Purchase_Line__c> purchaseLinesToUpdate = new List<Purchase_Line__c>();
                List<Purchase_Line__c> purchaseLinesRemoved = new List<Purchase_Line__c>();

                for(Integer orderId : orderLinesByOrderId.keySet()){
                    List<Purchase_Line__c> existingPurchaseLines = new List<Purchase_Line__c>();
                    List<OrderLine> orderLines = orderLinesByOrderId.get(orderId);
                    Set<Integer> coupaLineIds = new Set<Integer>();
                    Map<Integer, Purchase_Line__c> purchaseLinesByCoupaId = new Map<Integer, Purchase_Line__c>();
                    for(OrderLine orderLine : orderLines){
                        coupaLineIds.add(orderLine.id);
                    }

                    if(purchaseLinesByCoupaOrderIds.containsKey(orderId)){
                        existingPurchaseLines = purchaseLinesByCoupaOrderIds.get(orderId);
                        for(Purchase_Line__c purchaseLine:existingPurchaseLines){
                            if(purchaseLine.Coupa_Allocation_Line__c == true){
                                purchaseLinesRemoved.add(purchaseLine);
                            } else {
                                purchaseLinesByCoupaId.put(Integer.valueOf(purchaseLine.Coupa_Id__c), purchaseLine);
                                if (coupaLineIds.contains(Integer.valueOf(purchaseLine.Coupa_Id__c)) == false) {
                                    purchaseLinesRemoved.add(purchaseLine);
                                }
                            }
                        }
                    }

                    for(OrderLine orderLine : orderLines){
                        Purchase_Line__c purchaseLine = new Purchase_Line__c();
                        if(purchaseLinesByCoupaId.containsKey(orderLine.id)){
                            purchaseLine = purchaseLinesByCoupaId.get(orderLine.id);
                        } else {
                            purchaseLine.Purchase_Order__c = purchaseOrderByCoupaId.get(orderId).Id;
                        }

                        purchaseLine.Coupa_Id__c = String.valueOf(orderLine.id);
                        purchaseLine.Type__c = orderLine.type;
                        purchaseLine.Coupa_Item__c = orderLine.description;
                        if(purchaseLine.Coupa_Item__c.length() <= 80){
                            purchaseLine.Description__c = purchaseLine.Coupa_Item__c;
                        } else {
                            purchaseLine.Description__c = purchaseLine.Coupa_Item__c.substring(0,80);
                        }
                        purchaseLine.Quantity__c = orderLine.quantity;
                        purchaseLine.Unit_Cost__c = orderLine.price;
                        purchaseLine.Line_Cost__c = orderLine.total;
                        purchaseLine.Sales_Order__c = null;
                        if(orderLine.uom != null) {
                            purchaseLine.Coupa_UOM__c = orderLine.uom.name;
                        }
                        if(orderLine.supplier != null){
                            if(String.isNotBlank(orderLine.supplier.num)){
                                String navId = orderLine.supplier.num;
                                purchaseLine.Coupa_Supplier_Number__c = navId;
                                if(subsidiaryVendorsByNAVId.containsKey(navId)){
                                    purchaseLine.Vendor_Account__c = subsidiaryVendorsByNAVId.get(navId).Account__c;
                                }
                            }
                        }
                        purchaseLine.Line_No__c = Decimal.valueOf(orderLine.line_num);

                        if(orderLine.custom_fields != null && String.isNotBlank(orderLine.custom_fields.repair_type)){
                            purchaseLine.Cost_Type__c = orderLine.custom_fields.repair_type;
                        }

                        System.debug('Info: accountAllocationsBySalesLine ' + accountAllocationsBySalesLine);
                        if(accountAllocationsBySalesLine.containsKey(orderLine.id)){
                            List<AccountAllocation> accountAllocations = accountAllocationsBySalesLine.get(orderLine.id);
                            Integer count = 0;
                            for(AccountAllocation accountAllocation : accountAllocations){
                                System.debug('Info: accountAllocation ' + accountAllocation);
                                count += 1;
                                Purchase_Line__c allocationLine = new Purchase_Line__c();
                                allocationLine = purchaseLine.clone();
                                String orderNumber = accountAllocation.account.segment_3;
                                if(salesOrderIdsByNames.containsKey(orderNumber)){
                                    System.debug('Info: orderNumber ' + orderNumber);
                                    allocationLine.Sales_Order__c = salesOrderIdsByNames.get(orderNumber);
                                }

                                if(String.isNotBlank(accountAllocation.account.segment_4)){
                                    if(equipmentIdsByNames.containsKey(accountAllocation.account.segment_4)){
                                        System.debug('Info: orderNumber ' + accountAllocation.account.segment_4);
                                        allocationLine.Equipment_No__c = equipmentIdsByNames.get(accountAllocation.account.segment_4);
                                    }
                                }

                                if(String.isNotBlank(accountAllocation.account.segment_1)){
                                    if(serviceCenterIdsByNames.containsKey(accountAllocation.account.segment_1)){
                                        System.debug('Info: orderNumber ' + accountAllocation.account.segment_1);
                                        allocationLine.Service_Center__c = serviceCenterIdsByNames.get(accountAllocation.account.segment_1);
                                    }
                                }

                                allocationLine.Quantity__c = 1;
                                allocationLine.Unit_Cost__c = accountAllocation.amount;
                                allocationLine.Line_Cost__c = accountAllocation.amount;
                                allocationLine.Coupa_Allocation_Line__c = true;
                                allocationLine.Coupa_GL_Account__c = accountAllocation.account.segment_2;
                                allocationLine.Line_No__c = purchaseLine.Line_No__c + (count / 100);
                                purchaseLinesToUpdate.add(allocationLine);
                            }
                            purchaseLine.Unit_Cost__c = 0;
                            purchaseLine.Line_Cost__c = 0;
                        } else if (orderLine.account != null) {
                            if(String.isNotBlank(orderLine.account.segment_3)){
                                String orderNumber = orderLine.account.segment_3;
                                if(salesOrderIdsByNames.containsKey(orderNumber)){
                                    purchaseLine.Sales_Order__c = salesOrderIdsByNames.get(orderNumber);
                                }
                            }

                            if(String.isNotBlank(orderLine.account.segment_2)){
                                purchaseLine.Coupa_GL_Account__c = orderLine.account.segment_2;
                            }

                            if(String.isNotBlank(orderLine.account.segment_4)){
                                if(equipmentIdsByNames.containsKey(orderLine.account.segment_4)){
                                    purchaseLine.Equipment_No__c = equipmentIdsByNames.get(orderLine.account.segment_4);
                                }
                            }

                            if(String.isNotBlank(orderLine.account.segment_1)){
                                if(serviceCenterIdsByNames.containsKey(orderLine.account.segment_1)){
                                    purchaseLine.Service_Center__c = serviceCenterIdsByNames.get(orderLine.account.segment_1);
                                }
                            }
                        }
                        purchaseLinesToUpdate.add(purchaseLine);
                    }
                }
                if(purchaseLinesRemoved.size() > 0){
                    delete purchaseLinesRemoved;
                }

                if(purchaseLinesToUpdate.size() > 0){
                    upsert purchaseLinesToUpdate;
                }
            }
        }
    }

    public class OrderHeader {
        public Integer id {get; set;}
        public Datetime created_at {get; set;}
        public Datetime updated_at {get; set;}
        public String po_number {get; set;}
        public String status {get; set;}
        public List<OrderLine> order_lines {get; set;}
        public ShipToAddress ship_to_address {get; set;}
        public Supplier supplier {get; set;}
        public PaymentTerm payment_term {get; set;}
    }

    public class OrderLine {
        public Integer id {get; set;}
        public Datetime created_at {get; set;}
        public Datetime updated_at {get; set;}
        public String description {get; set;}
        public String type {get; set;}
        public Integer line_num {get; set;}
        public Double quantity {get; set;}
        public UOM uom {get; set;}
        public Double price {get; set;}
        public Double total {get; set;}
        public CustomFields custom_fields {get; set;}
        public Account account {get; set;}
        public Supplier supplier {get; set;}
        public List<AccountAllocation> account_allocations {get; set;}
    }

    public class UOM {
        public Integer id {get; set;}
        public String code {get; set;}
        public String name {get; set;}
    }

    public class ShipToAddress {
        public Integer id {get; set;}
        public String name {get; set;}
        public String street1 {get; set;}
        public String street2 {get; set;}
        public String city {get; set;}
        public String state {get; set;}
        public String postal_code {get; set;}
        public Country country {get; set;}
    }

    public class Supplier {
        public Integer id {get; set;}
        public String name {get; set;}
        public String email {get; set;}
        public String num {get; set;}
    }

    public class PaymentTerm {
        public Integer id {get; set;}
        public String code {get; set;}
        public String description {get; set;}
    }

    public class Country {
        public Integer id {get; set;}
        public String code {get; set;}
        public String name {get; set;}
    }

    public class CustomFields {
        public String repair_type {get; set;}
    }

    public class LookupValue {
        public Integer id {get; set;}
        public String name {get; set;}
    }

    public class AccountAllocation {
        public Integer id {get; set;}
        public Double amount {get; set;}
        public Double pct {get; set;}
        public Account account {get; set;}
    }

    public class Account {
        public Integer id {get; set;}
        public String name {get; set;}
        public String code {get; set;}
        public String segment_1 {get; set;}
        public String segment_2 {get; set;}
        public String segment_3 {get; set;}
        public String segment_4 {get; set;}
    }

    public class Authorization{
        public String access_token {get; set;}
        public String token_type {get; set;}
        public Integer expires_in {get; set;}
    }

    private static void saveNewToken(){
        if(newTokenIssued == true) {
            upsert apiToken;
        }
    }
}