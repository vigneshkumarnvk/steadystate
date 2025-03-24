@isTest
global class CustomerServiceMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        
        // Simulating a successful response
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        res.setBody('{"isSuccess": true, "message": "Customer created successfully"}');
        
        return res;
    }
}