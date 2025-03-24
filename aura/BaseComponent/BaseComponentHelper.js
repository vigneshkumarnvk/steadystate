({
	callServerMethod : function(component, event, method, params, successCallback, failureCallback, disableSpinner) {
        var action = component.get(method);
        if (params) {
            action.setParams(params);
        }
 
        if (!disableSpinner) {
            component.set("v.showSpinner", true);
        }

        action.setCallback(this, function (response) {
            if (!disableSpinner) {
                component.set("v.showSpinner", false);
            }

            var state = response.getState();
            if (state === "SUCCESS") {
                if (successCallback) {
                    successCallback.call(this, response.getReturnValue());
                }
            } else if (state === "ERROR") {
                var error = ''; 
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        error = errors[0].message;
                    }
                } else {
                    error = 'Unexpected error.';
                }

                if (failureCallback) {
                    failureCallback.call(this, error);
                } else {
                    //this.showToast(component, "Error", error, "error", "dismissible");
                    alert(error);
                }
            }
        });
        $A.enqueueAction(action);
    },
    makeStackedCalls : function(component, event, helper, calls) {
	    var callIndex = 0;
	    this.stackCalls(component, event, helper, calls, callIndex);
    },
    stackCalls : function(component, event, helper, calls, callIndex) {
        return new Promise(
            $A.getCallback(
                function(resolve, reject) {
                    calls[callIndex](resolve, reject);
                }
            )
        ).then(
            $A.getCallback(function() {
                callIndex++;
                if (callIndex < calls.length) {
                     helper.stackCalls(component, event, helper, calls, callIndex);
                }
            }),
            $A.getCallback(function(error) {
                    if (error) {
                        helper.showToast(component, "", error, "error", "dismissible");
                    }
                    else {
                        alert('Unexpected error.');
                    }
                }
            )
        ).catch(function(error) {
            $A.reportError("Error", error);
        });
    },
    openModal : function(component, event, title, message, buttons, componentName, params, size, xButton, closeCallback, shiftY) {
	    /*
        var modal = this.findModal(component, event);
        if (modal) {
        	modal.open(title, message, buttons, componentName, params, size, xButton, onClose);
        }*/

        var findComponent = function(component, componentName) {
            var cmp = component;
            while (cmp && !cmp.find(componentName)) {
                cmp = cmp.getSuper();
            }
            return cmp.find(componentName);
        };

        $A.createComponent("c:Modal", {}, function(modal, status, errorMessage) {
            if (status === 'SUCCESS') {
                var container = findComponent(component,"my-modal-container");
                $A.util.removeClass(container, 'slds-hide');

                var body = container.get("v.body");
                body.push(modal);
                container.set("v.body", body);
                modal.open(title, message, buttons, componentName, params, size, xButton, closeCallback, shiftY);
            }
            else if (status == "INCOMPLETE") {
                throw Error('No response from server or client is offline.');
            }
            else if (status == "ERROR") {
                throw Error('x' + errorMessage);
            }
            else {
                throw Error('unexpected error');
            }
        });
	},
    closeModal : function(component, event) {
	    /*
        var modal = this.findModal(component, event);
        if (modal) {
        	modal.close();
        }
	    */

        var findComponent = function(component, componentName) {
            var cmp = component;
            while (cmp && !cmp.find(componentName)) {
                cmp = cmp.getSuper();
            }
            return cmp.find(componentName);
        };

        var container = findComponent(component,"my-modal-container");
        $A.util.addClass(container, 'slds-hide');
        var body = container.get("v.body");
        if (body.length > 0) {
            var modal = body[0];
            modal.close();
            body.splice(0, body.length);
        }
        container.set("v.body", body);
    },
    clearModal : function(component, event) {
	    /*
        var modal = this.findModal(component, event);
        if (modal) {
        	modal.clear();
        }
	    */
    },
    findModal : function(component, event) {
        var cmp = component;
        while (cmp && !cmp.find("modal")) {
            cmp = cmp.getSuper();
        }
        return cmp.find("modal");
    },
    //ticket 19725 <<
    //showToast : function(component, title, message, type, mode) {
    showToast : function(component, title, message, type, mode, duration) {
    //ticket 19725 >>
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "mode": mode
        });
        //ticket 19725 <<
        if (duration) {
            toastEvent.setParam('duration', duration);
        }
        //ticket 19725 >>
        toastEvent.fire();
    },
    navigateToSObject : function(component, event, recordId, actionName) {
        setTimeout(function() {
            $A.get('e.force:refreshView').fire();
            var evt = $A.get("e.force:navigateToSObject");
            evt.setParams({"recordId": recordId, "slideDevName": 'detail'});
            evt.fire();
        }, 1);
    },
    navigateToUrl : function(component, event, url) {
        var evt = $A.get("e.force:navigateToURL");
        evt.setParams({
            "url": url
        });
        evt.fire();
    },
    navigateToComponent : function(component, event, componentName, componentAttributes) {
	    var evt = $A.get("e.force:navigateToComponent");
	    evt.setParams({
            componentDef: componentName,
            componentAttributes: componentAttributes
        });
	    evt.fire();
    },
    showSpinner : function(component, event) {
        component.set("v.showSpinner", true);
    },
    hideSpinner : function(component, event) {
        component.set("v.showSpinner", false);
    }
})