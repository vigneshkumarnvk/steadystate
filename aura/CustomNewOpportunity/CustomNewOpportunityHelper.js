({
    getData : function(component, event) {
        
        var pageReference = component.get("v.pageReference");
        var accountId = pageReference.state.c__recordId;
        var params = { "customerId": accountId };
        this.callServerMethod(component, event, "c.isValidCustomerToCreateOpportunity", params, function (isValid) {
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": '/lightning/o/Opportunity/new?count=1&defaultFieldValues=AccountId%3D'+accountId+'&nooverride=1&useRecordTypeCheck=1&navigationLocation=RELATED_LIST&backgroundContext=%2Flightning%2Fr%2FAccount%2F'+accountId+'%2Fview'
            });
            urlEvent.fire();
            
        }, function (err) {
            this.showToast(component, "Invalid Customer", err, "error", "Sticky");
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId":accountId
            });
            navEvt.fire();
        });
        
    }
})