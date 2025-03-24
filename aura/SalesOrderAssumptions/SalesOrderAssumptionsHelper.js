({
    //job task <<
    confirmCheckOffManifestFee : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        if (salesOrder.Manifest_And_Profile__c == false) {
            var buttons = [];
            buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
            buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.confirmCheckOffManifestFeeCallback.bind(this, component, event) }});
            this.openModal(component, event, 'Manifest Fee Removal', 'Are you sure you want to uncheck this option? <br/>Please note system will also remove unbilled manifest fee lines from all T&Ms associated with this order after you save the changes.', buttons, null, null, null);
        }
        else {
            this.confirmCheckOffManifestFeeCallback(component, event);
        }
    },
    confirmCheckOffManifestFeeCallback : function(component, event) {
        this.closeModal(component, event);
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        this.calculateSalesOrder(component, event, salesOrder, jobTaskWrappers, false);
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
        component.set("v.salesOrder.Manifest_And_Profile__c", true);
    }
    //job task >>
});