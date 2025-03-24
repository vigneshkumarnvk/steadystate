({
    doInit : function(component, event, helper) {
        helper.getBundleLines(component, event);
    },
    getLines : function(component, event, helper) {
        var bundleLines = JSON.parse(JSON.stringify(component.get("v.bundleLines")));
        for (var i = 0; i < bundleLines.length; i++) {
            if (bundleLines[i].Selected != true) {
                bundleLines.splice(i, 1);
                i--;
            }
        }

        if (bundleLines.length == 0) {
            helper.showToast(component, "Error", "You must choose a line to continue.", "error", "dismissible");
            return;
        }
        var callback = event.getParams().arguments.callback;
        if (callback) {
            callback(bundleLines);
        }
    }
});