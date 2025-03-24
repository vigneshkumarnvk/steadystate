/*
Dated    : 08/07/2023
Summary  : Test class for EQAI callouts
* Modification Log :
 * Developer                 Date                   Description
 * ----------------------------------------------------------------------------------------------------------               
Harika Madapathi           08/07/2023              67233 - Building GetGeneratorInfo API Callout
*************************************************************************************************************/
@isTest
public class EQAIGetGeneratorInfoAPITest {
    public static string EPAIDError = 'EPA ID is not valid or not exists , provide any of the other parameters to search, Check Source_Error_Log for more details'; 
    public class EQAIGetGeneratorInfoHttpMockResponse implements HttpCalloutMock {
         public HTTPResponse respond(HTTPRequest req) {
             // Create a mock response for EQAI GetGeneratorInfo API callout
             HttpResponse res = new HttpResponse();
             res.setHeader('Content-Type', 'application/json');
             System.assertEquals('POST', req.getMethod());
             res.setBody('[{\"Name\":\"EATON-BELMOND\",\"City\":\"BELMOND\",\"State\":\"IA\",\"Zip\":\"50421\",\"EPA ID\":\"IAT200011187\",\"Business Phone\":\"5154445273\",\"NAICS ID\":332813,\"EQAI generator ID\":5323}]');
             res.setStatusCode(200);
             return res;
        }
    }
    
    public class EQAIGetGeneratorInfoHttpMockResponse2 implements HttpCalloutMock {
         public HTTPResponse respond(HTTPRequest req) {
             // Create a mock response for EQAI GetGeneratorInfo API callout
             HttpResponse res = new HttpResponse();
             res.setHeader('Content-Type', 'application/json');
             System.assertEquals('POST', req.getMethod());
             res.setBody('EPA ID is not valid or not exists , provide any of the other parameters to search, Check Source_Error_Log for more details');
             res.setStatusCode(400);
             return res;
        }
    }
    
    @isTest
    static void testGetGeneratorInfoAPISuccessResponse(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EQAIGetGeneratorInfoHttpMockResponse());
        EQAIWrapper.ResponseWrapper res = EQAIGetGeneratorInfoAPI.getMatchingSitesFromEQAI('','EATON','','','','IA');
        System.assertEquals('EATON-BELMOND',res.siteList[0].Name);
        System.assertEquals(332813,res.siteList[0].NAICS_ID);
        System.assertEquals('BELMOND',res.siteList[0].City);
        System.assertEquals('IA',res.siteList[0].State);
        System.assertEquals('50421',res.siteList[0].Zip);
        System.assertEquals('IAT200011187',res.siteList[0].EPA_ID);
        System.assertEquals('5154445273',res.siteList[0].Business_Phone);
        System.assertEquals(5323,res.siteList[0].EQAI_generator_ID);
        Test.stopTest();
    }
    
     @isTest
    static void testGetGeneratorInfoAPIErrorResponse(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EQAIGetGeneratorInfoHttpMockResponse2());
        EQAIWrapper.ResponseWrapper res = EQAIGetGeneratorInfoAPI.getMatchingSitesFromEQAI('vvv','','','San Francisco','','CA');
        System.debug('Wrapper: '+ res);
        System.assertEquals(EPAIDError, res.Error);
        Test.stopTest();
    }

}