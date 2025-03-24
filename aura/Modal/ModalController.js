({
    doInit : function(component, event, helper) {

    },
	openModal : function(component, event, helper) {
        try {
            var params = event.getParams().arguments;
            component.set("v.title", params.title);
            component.set("v.message", params.message);
            component.set("v.componentName", params.componentName);
            component.set("v.params", params.params);
            component.set("v.buttons", params.buttons);
            component.set("v.size", params.size);
            component.set("v.xButton", params.xButton);
            component.set("v.closeCallback", params.closeCallback);
            component.set("v.shiftY", params.shiftY);
            var componentParams;
            if (params.params) {
            	componentParams = params.params;
            }
            else {
                componentParams = {};
            }
            componentParams["aura:id"] = "componentAuraId";
            //create the component
            var componentName = component.get("v.componentName");
            if (componentName) {
                $A.createComponent(
                    componentName,
                    componentParams,
                    function(newComponent, status, errorMessage) {
                        if (status == "SUCCESS") {
                            var container = component.find("container");
                            var body = container.get("v.body");
                            body.splice(0, body.length);
                            body.push(newComponent);
                            container.set("v.body", body);
                        }
                        else if (status == "INCOMPLETE") {
                            throw ('No response from server or client is offline.');
                        }
                        else if (status == "ERROR") {
                            throw status;
                        }
                    }
                );  
            };
            helper.showModal(component, event);
        }
        catch(err) {
            throw err;
        }
        //return params.callback;
	},
    closeModal : function(component, event, helper) {
		helper.clearModal(component, event, helper);
        helper.hideModal(component, event);

        var closeCallback = component.get("v.closeCallback");
        if (closeCallback) {
            closeCallback();
        }
    },
    clearModal : function(component, event, helper) {
        helper.clearModal(component, event, helper);
    },
    handleButtonClick : function(component, event, helper) {
        var action = event.getSource().get("v.value");
        if (action) {

            if (action.scope == "COMPONENT") { //call the component's method
                var childComponent = component.find("componentAuraId");
                if (childComponent) {
                    if (childComponent.length) {
                        childComponent = childComponent[0];
                    }
                    
                    if (childComponent[action.method]) {
                        if (!$A.util.isUndefinedOrNull(action.callback)) {
                            //calling the child component's method with an argument that is the callback function
                            childComponent[action.method](action.callback);
                        }
                    }
                    else {
                        alert('Method "' + action.method + '" is not found in the component "' + childComponent.getName() + '".')
                    }
                }
            }
            else { //call the parent's method
                action.callback();
            }
        }
    },
})