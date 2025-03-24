({
	doInit : function(component, event, helper) {
		helper.getStagingContact(component, event);
	},
    handleDataChange : function(component, event, helper) {
        component.set("v.changesPending", true);
    },
    saveContact : function(component, event, helper) {
        var contact = component.get("v.contact");
        
        var fields = new Array();
        fields.push(component.find('verify-information'));
        fields.push(component.find('first-name'));
        fields.push(component.find('last-name'));
        fields.push(component.find('street'));
        fields.push(component.find('city'));
        fields.push(component.find('state'));
        fields.push(component.find('postal-code'));
        fields.push(component.find('country'));
        
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