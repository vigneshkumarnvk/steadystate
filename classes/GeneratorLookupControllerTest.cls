@IsTest
public with sharing class GeneratorLookupControllerTest {
    @IsTest
    private static void ctor() {
        Test.startTest();
        GeneratorLookupController generatorLookupController = new GeneratorLookupController();
        Test.stopTest();

        System.assert(generatorLookupController != null, 'Expected the class to be initialized.');
    }

    @IsTest
    private static void properties() {
        EQAIWrapper.GetGeneratorInfoResponseWrapper eachGetGeneratorInfoResponseWrapper = new EQAIWrapper.GetGeneratorInfoResponseWrapper();
        eachGetGeneratorInfoResponseWrapper.Name = 'EATON-BELMOND';
        eachGetGeneratorInfoResponseWrapper.NAICS_ID = 332813;
        eachGetGeneratorInfoResponseWrapper.City = 'BELMOND';
        eachGetGeneratorInfoResponseWrapper.State = 'IA';
        eachGetGeneratorInfoResponseWrapper.Zip = '50421';
        eachGetGeneratorInfoResponseWrapper.EPA_ID = 'IAT200011187';
        eachGetGeneratorInfoResponseWrapper.Business_Phone = '5154445273';
        eachGetGeneratorInfoResponseWrapper.EQAI_generator_ID = 5323;

        List<EQAIWrapper.GetGeneratorInfoResponseWrapper> getGeneratorInfoResponseWrapper = new List<EQAIWrapper.GetGeneratorInfoResponseWrapper>();
        getGeneratorInfoResponseWrapper.add(eachGetGeneratorInfoResponseWrapper);

        EQAIWrapper.ResponseWrapper responseWrapper = new EQAIWrapper.ResponseWrapper();
        responseWrapper.siteList = getGeneratorInfoResponseWrapper;
        
        Test.startTest();
        GeneratorLookupController.Model model = new GeneratorLookupController.Model();
        GeneratorLookupController.Model modelWithResponseWrapper = new GeneratorLookupController.Model(responseWrapper);
        Test.stopTest();

        System.assert(model != null, 'Expected the class to be initialized.');
        System.assert(modelWithResponseWrapper != null, 'Expected the class to be initialized.');
    }
    
    @IsTest
    private static void validate() {
        String errorMessage = '';
       
        Test.startTest();
        GeneratorLookupController.Model model = new GeneratorLookupController.Model();
        try {
            model.validate();
        } catch (Exception Ex) {
            errorMessage = ex.getMessage();
        }
        Test.stopTest();

        System.assert(model != null, 'Expected the class to be initialized.');
        System.assertEquals('Please enter at least one value to search on', errorMessage, 'Expected the class to be initialized.');
    }
    
    @IsTest
    private static void getGeneratorLookup() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EQAIGetGeneratorInfoHttpMockResponse());
        GeneratorLookupController.Model model = new GeneratorLookupController.Model();
        model.generatorName = 'EATON';
        model.generatorState = 'IA';
        GeneratorLookupController.Model modelResponse = GeneratorLookupController.getGeneratorLookup(model);
        Test.stopTest();

        System.assert(model != null, 'Expected the class to be initialized.');
        System.assert(modelResponse != null, 'Expected the class to be initialized.');
    }
    
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
}