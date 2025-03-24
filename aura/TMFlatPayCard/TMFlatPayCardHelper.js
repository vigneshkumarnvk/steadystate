({
    create : function(component, event) {
        var flatPay = component.get("v.flatPay");
        var actionParams = event.getParams().arguments;
        if (actionParams.callback) {
            actionParams.callback(flatPay);
        }
    },
    validateFields : function(component, event) {
        var fields = [];
        fields.push(component.find("rate-type"));
        fields.push(component.find("rate"));

        var allValid = fields.reduce(function(valid, inputField) {
            if (inputField) {
                if (Array.isArray(inputField)) {
                    for (var i = 0; i < inputField.length; i++) {
                        inputField[i].showHelpMessageIfInvalid();
                        valid = valid && inputField[i].get("v.validity").valid
                    }
                }
                else {
                    inputField.showHelpMessageIfInvalid();
                    valid = valid && inputField.get("v.validity").valid;
                }
            }
            return valid;
        }, true);
        return allValid;
    }
});