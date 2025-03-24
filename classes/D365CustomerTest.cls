/*************************************************************************************************
* Name         :  D365CustomerTest
* Description  :  Test class for D365CustomerLookupController & D365CustomerService  
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Shahwaz Khan             02-14-2025            US141063:  Add D365 Project Lookup Functionality
* Shahwaz Khan             03-06-2025            US142841:  Update test class as per new wrapper structure
*************************************************************************************************/
@isTest
public class D365CustomerTest {
    private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{"PROJECTID": "Project1", "PROJECTNAME": "Project Alpha", "USEPREVAILINGWAGE": "Yes", "BUSINESSUNIT": "BU1", "DEPARTMENT": "Dept1", "COSTCENTER": "CC1"},' +
                        '{"PROJECTID": "Project2", "PROJECTNAME": "Project Beta", "USEPREVAILINGWAGE": "No", "BUSINESSUNIT": "BU2", "DEPARTMENT": "Dept2", "COSTCENTER": "CC2"}]');
            res.setStatusCode(200);
            return res;
        }
    }
    
    private class MockHttpResponseEmpty implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[]');
            res.setStatusCode(200);
            return res;
        }
    }
    
    private class MockHttpResponseError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Callout failed');
        }
    }
    
    @isTest
    static void testFetchRecordsSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        // Insert required test data
        Subsidiary_Company__c subsidiaryCompany = new Subsidiary_Company__c(Name = 'Test Company', Display_Name__c = 'ACV Enviro', QtC_Enabled__c = true, Website__c = 'example.com', Watermark__c = '/resources/');
        insert subsidiaryCompany;
        
        Service_Center__c testServiceCenter = new Service_Center__c(Name = 'Test Center', Code__c = '04',D365_Business_Unit__c = 'BU1', D365_LE__c = 'LE1', Subsidiary_Company__c = subsidiaryCompany.Id);
        insert testServiceCenter;
        
        Test.startTest();
        D365CustomerLookupController.D365CustomerRecords result = D365CustomerLookupController.fetchRecords('12345', testServiceCenter.Id, 'Project');
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(2, result.projectIds.size());
        System.assertEquals('Project1', result.projectIds[0].projectId);
        System.assertEquals('Project Alpha', result.projectIds[0].projectName);
    }
    
    @isTest
    static void testFetchRecordsEmptyResponse() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseEmpty());        
        
        // Insert required test data
        Subsidiary_Company__c subsidiaryCompany = new Subsidiary_Company__c(Name = 'Test Company', Display_Name__c = 'ACV Enviro', QtC_Enabled__c = true, Website__c = 'example.com', Watermark__c = '/resources/');
        insert subsidiaryCompany;
        
        Service_Center__c testServiceCenter = new Service_Center__c(Name = 'Test Center',Code__c = '04', D365_Business_Unit__c = 'BU1', D365_LE__c = 'LE1', Subsidiary_Company__c = subsidiaryCompany.Id);
        insert testServiceCenter;
        
        Test.startTest();
        D365CustomerLookupController.D365CustomerRecords result = D365CustomerLookupController.fetchRecords('12345', testServiceCenter.Id, 'xyz');
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(0, result.projectIds.size());
        System.assertEquals('No matching records found.', result.Message);
    }
    
    @isTest
    static void testFetchRecordsExceptionHandling() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseError());
        
        // Insert required test data
        Subsidiary_Company__c subsidiaryCompany = new Subsidiary_Company__c(Name = 'Test Company', Display_Name__c = 'ACV Enviro', QtC_Enabled__c = true, Website__c = 'example.com', Watermark__c = '/resources/');
        insert subsidiaryCompany;
        
        Service_Center__c testServiceCenter = new Service_Center__c(Name = 'Test Center', D365_Business_Unit__c = 'BU1', D365_LE__c = 'LE1',Code__c = '04',Subsidiary_Company__c = subsidiaryCompany.Id);
        insert testServiceCenter;
        
        Test.startTest();
        D365CustomerLookupController.D365CustomerRecords result = D365CustomerLookupController.fetchRecords('12345', testServiceCenter.Id, 'xyz');
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(0, result.projectIds.size());
    }
}