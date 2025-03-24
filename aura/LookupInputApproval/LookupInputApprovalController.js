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
    handleLookupContainerBlur : function(component, event, helper) {
        //handle dropdown close on iPad. When soft keyboard is closed, inputbox loses focus. Don't close the dropdown until user tap somewhere to trigger this event
        if (!helper.isTablet(component, event)) {
            return;
        }
        helper.closeDropdown(component, event);
    },
    handleInputBoxClick : function(component, event, helper) {
        var keyword = component.get("v.keyword");
        var disabled = component.get("v.disabled");
        if (disabled != true) {
            //use showLookupSpinner to check if the dropdown has finished loading to prevent double clicking
            var showLookupSpinner = component.get("v.showLookupSpinner");
            var lastClickedOn = JSON.parse(JSON.stringify(component.get("v.lastClickedOn")));
            component.set("v.lastClickedOn", Date.now());
            if ((!lastClickedOn || (Date.now() - lastClickedOn > 100)) && showLookupSpinner != true) {
                var keyword = component.get("v.keyword");
                var minimumChars = component.get("v.minimumChars");
                if (minimumChars == 0 || (keyword && keyword.length >= minimumChars)) {
                    helper.search(component, event, keyword);
                    helper.showLookupContainer(component, event);
                } else {
                    component.set("v.result", null);
                    helper.hideLookupContainer(component, event);
                }
                //}
            }

        }
    },
    handleInputBoxFocus : function(component, event, helper) {
    },
    handleInputBoxBlur : function(component, event, helper) {
        //handle dropdown close on iPad. When soft keyboard is closed, input box loses focus. Don't close the dropdown until user tap somewhere to trigger this event
        if (helper.isTablet(component, event)) {
            return;
        }
            helper.closeDropdown(component, event);
    },
    handleInputBoxMouseEnter : function(component, event, helper) {
        //component.set("v.mouseOverInputBox", true);
    },
    handleInputBoxMouseLeave : function(component, event, helper) {
        //component.set("v.mouseOverInputBox", false);
    },
    handleKeyDown : function(component, event, helper) {
        if (event.which == 9 || event.which == 27) { // tab away or escape key
            helper.closeDropdown(component, event);
            return;
        }
        else if (event.which == 13) {
            var value = component.get("v.value");
            if (!value || value == '') {
                helper.handleKeyStrokes(component, event);
                return;
            }
        }
    },
    handleKeyUp : function(component, event, helper) {
        //console.log("handleKeyUp");
        if (event.which != 9 && event.which != 27 && event.which != 13) {
            helper.handleKeyStrokes(component, event);
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
        event.stopPropagation();
        var recordId = event.getSource().get("v.name");
        helper.resetAttributes(component);
        component.set("v.dropdownbox", null);
        component.set("v.value",null);
        helper.removeLookupRecord(component, event, recordId);
    },
    handleSelect : function(component, event, helper) {
        event.stopPropagation();
        var record = event.getParam("record");
        helper.resetAttributes(component);
        helper.addLookupRecord(component, event, record);
        helper.closeDropdown(component, event);
    },
    handleDropdownClose : function(component, event, helper) {
        //component.set("v.xKeyword", '!@#$%^*');
        helper.resetAttributes(component);
        component.set("v.dropdownbox", null);
    },
})