@IsTest
global class CoupaResponseMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req) {
        String endPoint = req.getEndpoint();
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

        if(endPoint.contains('lookup_values')){
            if(req.getMethod() == 'POST'){
                res.setBody('{"example":"test"}');
            } else if (req.getMethod() == 'PUT'){
                res.setBody('{"example":"test"}');
            } else if (req.getMethod() == 'GET'){
                res.setBody('[{"id":1230,"name":"RO-0089"}]');
            } else {
                res.setBody('{"example":"test"}');
            }
        } else if (endPoint.contains('purchase_orders')){
            if(req.getMethod() == 'GET'){
                String resBody = '[{' +
                        '"id":63, ' +
                        '"created-at": "2020-12-06T14:23:12-05:00",' +
                        '"updated-at": "2020-12-11T21:01:21-05:00",' +
                        '"po-number": "63",' +
                        '"status": "soft_closed",' +
                        '"ship-to-address": {' +
                            '"id": 2121,' +
                            '"name": "Rahway",' +
                            '"street1": "928 East Hazelwood Avenue",' +
                            '"street2": null,' +
                            '"city": "Rahway",' +
                            '"state": "NJ",' +
                            '"postal-code": "07065",' +
                            '"country": {' +
                                '"id": 223,' +
                                '"code": "US",' +
                                '"name": "United States"' +
                                '}' +
                        '},' +
                        '"supplier": {' +
                            '"id": 590,' +
                            '"name": "DIVAL SAFETY SUP EQUIP INC"' +
                        '},' +
                        '"payment-term": {' +
                            '"id": 5,' +
                            '"code": "30",' +
                            '"description": "Net 30"' +
                        '},' +
                        '"order-lines": [{' +
                            '"id": 88,' +
                            '"created-at": "2020-12-06T14:23:13-05:00",' +
                            '"updated-at": "2020-12-11T21:01:20-05:00",' +
                            '"description": "Moldex P100 filter disk withnuisance ov",' +
                            '"line-num": "1",' +
                            '"price": "4.50",' +
                            '"quantity": "225.0",' +
                            '"total": "1012.50",' +
                            '"uom": {' +
                                '"id": 1,' +
                                '"code": "EA",' +
                                '"name": "Each"' +
                            '},' +
                            '"account-allocations": [{' +
                                '"id": 7,' +
                                '"amount": "465.75",' +
                                '"pct": "46.0",' +
                                '"account": {' +
                                    '"id": 283,' +
                                    '"name": "Rahway-Safety Supplies - Direct-RH102365",' +
                                    '"code": "31-52970-RH102365",' +
                                    '"segment-1": "31",' +
                                    '"segment-2": "52970",' +
                                    '"segment-3": "RH102365"' +
                                '}' +
                            '}]' +
                        '}]' +
                    '}]';
                res.setBody(resBody);
            } else {
                res.setBody('{"example":"test"}');
            }
        } else if (endPoint.contains('token')) {
            if(req.getMethod() == 'POST'){
                String resBody = '{' +
                        '"access_token": "eyJ0eXAiOiJhdCtKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IjRmOjMzOmI3OmY3OjVmOjg4OjQ3OmRhOjAzOmVmOjkzOjQ1OmU5OmNjOmZiOjg3In0.eyJpc3MiOiJodHRwczovL2FjdmVudmlyby5jb3VwYWhvc3QuY29tIiwiaWF0IjoxNjg0NTMyNTUwLCJleHAiOjE2ODQ2MTg5NTAsInN1YiI6IjgxYWYzYWRjOGU3ZmQ2YTliZGQ2NzI0YTE4NmU0MzQyIiwianRpIjoiYmNhOGY5NWYtMDJlMS00MDkyLTkzOWMtNTA1OGVhMWE4ZGE0IiwiY2xpZW50X2lkIjoiODFhZjNhZGM4ZTdmZDZhOWJkZDY3MjRhMTg2ZTQzNDIiLCJzY29wZSI6ImNvcmUuY2F0YWxvZy5yZWFkIGNvcmUuY2F0YWxvZy53cml0ZSBjb3JlLmNvbW1lbnQud3JpdGUgY29yZS5jb21tb24ucmVhZCBjb3JlLmNvbW1vbi53cml0ZSBjb3JlLmNvbnRyYWN0LnJlYWQgY29yZS5pdGVtLnJlYWQgY29yZS5wdXJjaGFzZV9vcmRlcl9jaGFuZ2UucmVhZCBjb3JlLnB1cmNoYXNlX29yZGVyLnJlYWQgY29yZS5yZXF1aXNpdGlvbi5yZWFkIGNvcmUuc291cmNpbmcucmVhZCBjb3JlLnNvdXJjaW5nLndyaXRlIGNvcmUuc3VwcGxpZXJfaW5mb3JtYXRpb25fc2l0ZXMucmVhZCBjb3JlLnN1cHBsaWVyX3NpdGVzLnJlYWQgY29yZS5zdXBwbGllci5yZWFkIGNvcmUudHJhbnNsYXRpb24ucmVhZCBjb3JlLnVvbS5yZWFkIGNvcmUudXNlcl9ncm91cC5yZWFkIGVtYWlsIGxvZ2luIiwiYXVkIjpbImNvcmUiXX0.TmQZtbIaPUQV9J_ks5CTQ4OzsWv6PBacvzHxlWQpvGmNNCv2lCJEExQqoHSLPjgmdN828mQPRda8WBAq81GZPAwaZhPrKMTuPtYe0mahiSvhm-TPCO7FddYBxhIj1lboO035nzwqghlrsGucbujASnJuQdFG3_Q3S7Ctg8A_QzIIuaQniSREEiKimFQZELb00Z7jF2L3rrJY2dGqG0FcCutjXmoiWyACxIz1IzrIfJoaDH0srOUp3pHrFqUyc1NmAXK_MIlP6LMr0hWiKTSdzvpI2BSS35GvjjmFpMs4VJxPDiNBFuzpAFPyWnnsRQidkRX9_OeaBVTUZpPbYFcT8g",' +
                        '"token_type": "bearer",' +
                        '"expires_in": 86400' +
                        '}';
                res.setBody(resBody);
            }
        }
        else {
            res.setBody('{"example":"test"}');
        }

        res.setStatusCode(200);
        return res;
    }
}