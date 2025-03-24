({
    afterRender : function(component, helper) {
        this.superAfterRender(); 
        var containerDiv = component.find("container").getElement();
        containerDiv.addEventListener("touchmove", function(e) {
            e.stopPropagation();
        }, false); 
    }
})