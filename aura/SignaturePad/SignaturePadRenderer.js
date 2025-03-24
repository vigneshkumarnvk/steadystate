({
    afterRender : function(component, helper) {
        this.superAfterRender();

        var appDom = component.find("container").getElement();
        appDom.addEventListener("touchmove", function(e) {
            e.stopPropagation();
        }, false);
 
        appDom.addEventListener("touchstart", function(e) {
            e.stopPropagation();
        }, false);

        appDom.addEventListener("mousedown", function(e) {
            e.stopPropagation();
        }, false);
    }
})