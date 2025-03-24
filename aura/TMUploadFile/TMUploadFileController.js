({
    handleUploadFinished : function(component, event, helper) {
        var callback = component.get("v.callback");
        if (callback) {
            callback();
        }
    }
});