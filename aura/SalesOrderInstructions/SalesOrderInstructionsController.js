({
    validateFields : function(component, event, helper) {
        var fields = new Array();
        fields.push(component.find("project-scope"));

        var allValid = fields.reduce(function(valid, inputField) {
            if (inputField) {
            	inputField.showHelpMessageIfInvalid();
            }
            return valid && inputField.get("v.validity").valid;
        }, true);
        
        return allValid;
    }
})