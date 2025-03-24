({
    createSiteAddress : function(component, event) {
        if (this.validateFields(component, event) == true) { 
            var siteAddr = component.get("v.record");
            var params = { "JSONSiteAddress": JSON.stringify(siteAddr) };
            this.callServerMethod(component, event, "c.saveSiteAddress", params, function(response) {
                var actionParams = event.getParams().arguments;
                if (actionParams.callback) { //pass the contact to the callback function
                    actionParams.callback(response);
                }
            });
            
        }
    },
    validateFields : function(component, event) {
        var fields = new Array();
        fields.push(component.find("name"));        
        fields.push(component.find("customer"));
        fields.push(component.find("site-country"));
        fields.push(component.find("site-street"));
        fields.push(component.find("site-city"));
        fields.push(component.find("site-state"));
        fields.push(component.find("site-postal-code"));
        fields.push(component.find("tax-area"));

        var allValid = fields.reduce(function(valid, inputField) {
            inputField.showHelpMessageIfInvalid();
            return valid && inputField.get("v.validity").valid;
        }, true);
        
        return allValid;
    },
})