({
    afterRender: function (component, helper) {
        this.superAfterRender();
        helper.addListeners(component);
    },
});