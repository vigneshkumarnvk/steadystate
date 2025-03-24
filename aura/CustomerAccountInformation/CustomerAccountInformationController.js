({
	doInit : function(component, event, helper) {
		helper.getStagingAccount(component, event);
	},
    handleDataChange : function(component, event, helper) {
        component.set("v.changesPending", true);
    },
    saveAccount : function(component, event, helper) {
        var account = component.get("v.account");
        
        var fields = new Array();
        fields.push(component.find('verify-information'));
        fields.push(component.find('company-name'));
        fields.push(component.find('billing-street'));
        fields.push(component.find('billing-city'));
        fields.push(component.find('billing-state'));
        fields.push(component.find('billing-postal-code'));
        fields.push(component.find('billing-country'));
        
        var allValid = fields.reduce(function(valid, inputField) {
            
            if (inputField) {
            	inputField.showHelpMessageIfInvalid();
            	return valid && inputField.get("v.validity").valid;
            }
            return false;
        }, true);

        if (allValid) {
        	helper.validateAddressAndSave(component, event);
        }
    }
})