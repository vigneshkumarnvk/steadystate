({
    doInit : function(component, event, helper) {
        helper.getServiceRating(component, event);
        helper.getTM(component, event);
    },
    handleRatingChange : function(component, event, helper) {
        if (event.type == 'click') {
            if (event.currentTarget && event.currentTarget.dataset) { //current target = row
                var index = event.currentTarget.dataset.index;
                component.set("v.rating.Rating__c", index);

                if (index >= 3) {
                    component.set("v.rating.Customer_Review__c", null);
                }
                component.set("v.showRatingRequiredMessage", false);
            }
        }
    },
    save : function(component, event, helper) {
        helper.saveServiceRating(component, event);
    }
});