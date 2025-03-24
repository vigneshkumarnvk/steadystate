({
    createContact : function(component, event) {
        try {
            if (this.validateFields(component, event) == true) { 
                var contact = component.get("v.record");
                var params = { "JSONContact": JSON.stringify(contact) };
                this.callServerMethod(component, event, "c.saveContact", params, function(response) {
                    var actionParams = event.getParams().arguments;
                    if (actionParams.callback) { //pass the contact to the callback function
                        actionParams.callback(response);
                    }
                });
            }
        }
        catch(err) {
            alert(err);
        }
    },
    validateFields : function(component, event) {
        var fields = new Array();
        fields.push(component.find("last-name"));     
        fields.push(component.find("account"));

        var allValid = fields.reduce(function(valid, inputField) {
            inputField.showHelpMessageIfInvalid();
            return valid && inputField.get("v.validity").valid;
        }, true);
        
        return allValid;
    },
})