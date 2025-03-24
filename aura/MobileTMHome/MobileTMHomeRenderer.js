({
    afterRender : function(component, helper) {
        this.superAfterRender();
        var container = component.find("container").getElement();
        container.addEventListener("touchmove", function(e) {
            e.stopPropagation();
        }, false);
    }
});