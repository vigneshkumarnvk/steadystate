({
    render : function(component, helper) {
        var result = this.superRender();
        helper.showSpinner(component);
        return result;
    },
    afterRender : function(component, helper) {
        this.superAfterRender();
        helper.hideSpinner(component);
    },
});