({
    reportCustomValidity : function(component, event) {
        var params = event.getParams().arguments;
        var input = component.find("custom-lightning-input");
        input.focus();
        input.setCustomValidity(params.message);
        input.reportValidity();
    },
    clearCustomValidity : function(component, event) {
        var input = component.find("custom-lightning-input");
        input.setCustomValidity('');
        input.reportValidity();
    },
    focus : function(component, event) {
        component.find("custom-lightning-input").focus();
    },
});