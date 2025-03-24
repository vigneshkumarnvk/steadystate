({
    afterRender : function(component, helper) {
        this.superAfterRender();
        helper.fetchPickListValues(component, helper);
    }
});