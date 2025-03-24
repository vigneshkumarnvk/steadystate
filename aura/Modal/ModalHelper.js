({
    clearModal : function(component, event) {
        var components = component.find("componentAuraId");
        if (components) {
            for (var i = 0; i < components.length; i++) {
            	components[i].destroy();
            }
        }
        
        //destory the buttons
        var containers = component.find("buttonContainer");
        if (containers) {
        	for (var i = 0; i < containers.length; i++) {
        		//containers[i].set("v.body", null);
        		containers[i].destroy();
        	}
        }
    },
	showModal : function(component, event) {
		var modal = component.find('modal');
		var backdrop = component.find('backdrop');
		$A.util.addClass(modal, 'slds-fade-in-open');
		$A.util.addClass(backdrop, 'slds-backdrop--open');

        var container = component.find("modal-container");
        $A.util.removeClass(container, 'large');
        $A.util.removeClass(container, 'medium');
        $A.util.removeClass(container, 'small');
        $A.util.removeClass(container, 'small-high');

        var content = component.find("content");
        //$A.util.removeClass(content, 'content-height');

        var size = component.get("v.size");
        if (size != null) {
            $A.util.addClass(container, size);
            //$A.util.addClass(content, 'content-height');
        }

        document.body.style.overflow = "hidden"; //disable background scroll
	},
    hideModal : function(component, event) {
        var modal = component.find('modal');
		var backdrop = component.find('backdrop');
		$A.util.removeClass(backdrop,'slds-backdrop--open');
		$A.util.removeClass(modal, 'slds-fade-in-open');

        var container = component.find("modal-container");
        $A.util.removeClass(container, 'large');
        $A.util.removeClass(container, 'medium');
        $A.util.removeClass(container, 'small');
        $A.util.removeClass(container, 'small-high');

        document.body.style.overflow = "auto";
    },
})