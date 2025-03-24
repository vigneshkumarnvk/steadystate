({
    validateFields : function(component, event, helper) {
        var fields = [];
        fields.push(component.find("project-scope"));
        var ok = fields.reduce(function(valid, inputField) {
            if (inputField) {
                inputField.showHelpMessageIfInvalid();
            }
            return valid && inputField.get("v.validity").valid;
        }, true);

        return ok;
    }
});