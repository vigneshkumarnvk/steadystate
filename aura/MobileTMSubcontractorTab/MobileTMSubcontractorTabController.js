({
    doSave : function(component, event, helper) {
        try {
            if (helper.validate(component, event)) {
                helper.saveTMLines(component, event);
            }
        }
        catch(err) {
            helper.showToast(component, "Error", err.message, "error", "dismissible");
        }
    }
});