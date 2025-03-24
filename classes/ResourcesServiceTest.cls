/*************************************************************************************************
* Name         :  ResourcesServiceTest
* Description  :  Test class for ResourcesService
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Pavithra Periyasamy		03/20/2025             US144300: Resource Sync : Salesforce : Labor : New/Termed Labor Resources sync from EQAI to Salesforce
***********************************************************************************************************/
@isTest
private class ResourcesServiceTest {
    @isTest
    static void testUpsertResources_Success() {
        Test.startTest();
        // Create test data for Resource_Type__c
        Resource_Type__c resourceType = new Resource_Type__c(Name='Test Resource Type', Resource_Class_Code__c='TestCode');
        insert resourceType;
        Id profileId = [SELECT Id FROM Profile WHERE Name='System Administrator' LIMIT 1].Id;
        List<User> userList = new List<User>();
        
        User userRecord = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Username = 'testuser1@example.com.test',
            Email = 'testuser1@republicservices.com',
            Alias = 'tus1',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            RSG_EIN__c = '12345'
        );
        User userRecord1 = new User(
            FirstName = 'Test',
            LastName = 'User2',
            Username = 'testuser2@example.com.test',
            Email = 'testuser2@republicservices.com',
            Alias = 'tus2',
            ProfileId = profileId,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            RSG_EIN__c = '12346'
        );
        userList.add(userRecord);
        userList.add(userRecord1);
        
        insert userList;
        
        // Create test data for Service_Center__c
        NewTestData.createTestData();
        Service_Center__c serviceCenter = NewTestData.mapServiceCenterWrappersByName.get('02').ServiceCenter;
        
        
        
        // Create a JSON request body
        ResourceRequest request = new ResourceRequest();
        
        ResourceRequest.ResourceInfo resourceInfo = new ResourceRequest.ResourceInfo();
        
        resourceInfo.Resource_CSID = null;
        resourceInfo.resource_type = 'Labor';
        resourceInfo.First_Name = 'John';
        resourceInfo.Last_Name = 'Doe';
        resourceInfo.Resource_code = 'R123';
        resourceInfo.Resource_Class = 'TestCode';
        resourceInfo.company_id = 72;
        resourceInfo.default_profit_ctr_id = 8;
        resourceInfo.Employee_Id = '12345';
        resourceInfo.resource_status =  'Active';
        
        
        ResourceRequest.ResourceInfo resourceInfo1 = new ResourceRequest.ResourceInfo();
        
        resourceInfo1.Resource_CSID = null;
        resourceInfo1.resource_type = 'Labor';
        resourceInfo1.First_Name = 'John';
        resourceInfo1.Last_Name = 'Doe';
        resourceInfo1.Resource_code = 'R123';
        resourceInfo1.Resource_Class = 'TestCode';
        resourceInfo1.company_id = 72;
        resourceInfo1.default_profit_ctr_id = 8;
        resourceInfo1.Employee_Id = '12346';
        resourceInfo1.resource_status =  'Inactive';
        request.Resources = new List<ResourceRequest.ResourceInfo> { resourceInfo,resourceInfo1 };
            String jsonString = JSON.serialize(request);
        // Create the mock request and response
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'PUT';
        RestContext.request = req;
        RestContext.response = res;
        
        
        ResourcesService.upsertResources();
        Test.stopTest();
        
        // Validate the response
        System.assertEquals(200, res.statusCode);
        String responseBody = res.responseBody.toString();
        System.debug('Response Body: ' + responseBody);
        System.assert(responseBody.contains('Resource created successfully'));
    }
    
    @isTest
    static void testUpsertResources_Exception() {
        // Invalid JSON to simulate an exception
        String invalidJsonBody = '{"invalidField": "value"}';
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(invalidJsonBody);
        req.httpMethod = 'PUT';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ResourcesService.upsertResources();
        Test.stopTest();
        
        // Validate exception response
        System.assertEquals(500, res.statusCode);
        String responseBody = res.responseBody.toString();
        System.assert(responseBody.contains('Error'));
    }
}