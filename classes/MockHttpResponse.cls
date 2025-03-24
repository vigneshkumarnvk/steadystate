@isTest
public class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock response here
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success":true,"pdf":"mocked_pdf_url"}');
            res.setStatusCode(200);
            return res;
        }
    
}