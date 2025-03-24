({
    doInit : function(component, event, helper) {
        component.set("v.enableSpinner", false); // overwrite the attribute in the BaseComponent

        helper.initRecordsFromValue(component, event);

        var container = component.find("lookup-container");
        var variant = component.get("v.variant");
        if (variant == 'label-hidden') {
            $A.util.addClass(container, "slds-form-element_horizontal");
            $A.util.removeClass(container, "slds-form-element_stacked");
        }
        else {
            $A.util.removeClass(container, "slds-form-element_horizontal");
            $A.util.addClass(container, "slds-form-element_stacked");
        }
    },
    navigateToRecord : function(component, event, helper) {
        helper.navigateToRecord(component, event);
    },
    doNewRecord : function(component, event, helper) {
        helper.newRecordPage(component, event);
    },
    handleValueChange : function(component, event, helper) {
        helper.initRecordsFromValue(component, event);
    },
    handleInputFocus : function(component, event, helper) {
        var disabled = component.get("v.disabled");
        if (disabled != true) {
            var keyword = component.get("v.keyword");
            var minimumChars = component.get("v.minimumChars");
            if(minimumChars == 0 || (keyword && keyword.length >= minimumChars)) {
                helper.showLookupContainer(component, event);
                helper.search(component, event, keyword);
            }
            else{
                component.set("v.result", null );
                helper.hideLookupContainer(component, event);
            }
        }
    },
    handleContainerBlur : function(component,event,helper) {
        setTimeout($A.getCallback(
            function() {
                var lostFocusTime = component.get("v.lostFocusTime");
                if (new Date() - lostFocusTime > 250) { //component.get("v.keypressInterval")
                    component.set("v.result", null);
                    helper.hideLookupContainer(component, event);
                }
            }
        ), 250); //alow .3 second to close the dropdown
    },
    handleContainerFocus : function(component, event, helper) {
        component.set("v.lostFocusTime", new Date());
    },
    handleInputBlur : function(component, event, helper) {
        component.set("v.keyword", null);
    },
    handleKeyPressed : function(component, event, helper) {
        //select the record if there is only one result when the enter key is pressed
        component.set("v.lastKeyStrokeTime", new Date());

        var keyword = component.get("v.keyword");
        var minimumChars = component.get("v.minimumChars");
        if(minimumChars == 0 || (keyword && keyword.length >= minimumChars)) {
            setTimeout($A.getCallback(
                function() {
                    if (event.which == 13) { // enter key
                        setTimeout(
                            $A.getCallback(function() {
                                helper.showLookupContainer(component, event);
                                helper.search(component, event, keyword, function() {
                                    var result = component.get("v.result");
                                    if (result && result.length == 1) {
                                        if (component.isValid()) {
                                            helper.addLookupRecord(component, event, result[0]);
                                            helper.hideKeyboard(component, event);
                                        }
                                    }
                                });
                            }), component.get("v.keypressInterval"));
                    }
                    else { //delay submit to capture all input to reduce traffic
                        var lastKeyStrokeTime = component.get("v.lastKeyStrokeTime");
                        if (new Date() - lastKeyStrokeTime > component.get("v.keypressInterval") ) {
                            helper.showLookupContainer(component, event);
                            helper.search(component, event, keyword);
                        }
                    }
                }
            ), component.get("v.keypressInterval"));
        }
        else{
            component.set("v.result", null );
            helper.hideLookupContainer(component, event);
        }
    },
    focus : function(component, event, helper) {
        component.find("input").focus();
    },
    setCustomValidity : function(component, event, helper) {
        var input = component.find("input");
        var params = event.getParams().arguments;
        helper.showLookupInput(component, event);
        input.setCustomValidity(params.message);
        input.set('v.validity', { valid:false, badInput:true });
    },
    reportValidity : function(component, event, helper) {
        var validity = component.find("input").get("v.validity");;
        component.find("input").reportValidity();
    },
    showHelpMessageIfInvalid : function(component, event, helper) {
        var required = component.get("v.required");
        var input = component.find("input");
        if (required == true) {
            if (component.get("v.value") == null) { //check pill value, not the input value, input is always blank
                input.set("v.required", true);
            }
            else {
                input.set("v.required", false);
            }
            input.showHelpMessageIfInvalid();
        }
        component.set("v.validity", input.get("v.validity"));
    },
    handleRemove :function(component, event, helper) {
        var recordId = event.getSource().get("v.name");
        helper.removeLookupRecord(component, event, recordId);
    },
    handleSelect : function(component, event, helper) {
        var record = event.getParam("record");
        helper.addLookupRecord(component, event, record);
    }
})