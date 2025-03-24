({
    afterRender : function(component, helper) {
        this.superAfterRender();
        var container = component.find("tm-container").getElement();
        container.addEventListener("touchmove", function(e) {
            e.stopPropagation();
        }, false);
    }
});