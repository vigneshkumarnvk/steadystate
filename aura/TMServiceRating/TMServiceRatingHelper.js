({
    getServiceRating : function(component, event) {
        var tmId = component.get("v.tmId");
        var customerName = component.get("v.customerName");
        var customerEmail = component.get("v.customerEmail");
        var params = { "tmId": tmId };
        this.callServerMethod(component, event, "c.getServiceRating", params, function(response) {
            var rating;
            if (response) {
                rating = JSON.parse(response);
            }
            else {
                rating = { "TM__c": tmId };
            }
            rating.Customer_Name__c = customerName;
            rating.Customer_Email__c = customerEmail;
            component.set("v.rating", rating);
        })
    },
    getTM : function(component, event) {
        var tmId = component.get("v.tmId");
        var params = { "tmId": tmId };
        this.callServerMethod(component, event, "c.getTM", params, function(response) {
            var tm;
            if (response) {
                tm = JSON.parse(response);
            }
            component.set("v.tm", tm);
        })
    },
    saveServiceRating : function(component, event) {
        var rating = component.get("v.rating");
        if (!rating.Rating__c) {
            component.set("v.showRatingRequiredMessage", true);
            return;
        }
        if ((rating.Rating__c <= 2 && !rating.Customer_Review__c)) {
            component.set("v.showFeedbackRequiredMessage", true);
            return;
        }

        var params = { "JSONServiceRating": JSON.stringify(rating) };
        this.callServerMethod(component, event, "c.saveServiceRating", params, function() {
            var args = event.getParams().arguments;
            if (args.callback) {
                args.callback();
            }
        })
    }
});