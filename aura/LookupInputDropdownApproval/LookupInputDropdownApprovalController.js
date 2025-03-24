({
    doInit : function(component, event, helper) {
        window.addEventListener("scroll", $A.getCallback(function() {
            var fixedPosition = component.get("v.fixedPosition");
            if (fixedPosition == true) {
                var parentElement = component.get("v.parentElement");
                var dropdownElement = component.get("v.dropdownElement");
                if (parentElement && dropdownElement) {
                    var dropdownOnBottom = component.get("v.dropdownOnBottom");
                    var dropdownTop;
                    if (dropdownOnBottom == true) {
                        var dropdownTop = parentElement.getElement().getBoundingClientRect().top - dropdownElement.getBoundingClientRect().height;
                    }
                    else {
                        dropdownTop = parentElement.getElement().getBoundingClientRect().bottom;// + parentElement.getElement().getBoundingClientRect().height;
                    }
                    dropdownElement.style.top = dropdownTop + 'px';
                }
            }
        }));
    },
    handleMouseDown : function(component, event, helper) {
        //stop stealing focus from the input box
        event.preventDefault();
    },
    showDropdown : function(component, event, helper) {
        var dropdownLeft = component.get("v.dropdownLeft");
        var dropdownTop = component.get("v.dropdownTop");
        var dropdownBottom = component.get("v.dropdownBottom");
        var dropdownMinWidth = component.get("v.dropdownMinWidth");
        var dropdownOnBottom = component.get("v.dropdownOnBottom");
        var fixedPosition = component.get("v.fixedPosition");
        var dropdownBox = component.find("dropdown-box");

        var dropdownElement = dropdownBox.getElement();
        $A.util.addClass(dropdownBox, "slds-dropdown_left");
        $A.util.addClass(dropdownBox, "slds-dropdown");

        if (dropdownOnBottom == true) {
            $A.util.addClass(dropdownBox, "slds-dropdown_bottom");
            if (dropdownElement) {
                if (fixedPosition == true) {
                    dropdownElement.style.position = 'fixed';
                    dropdownElement.style.left = dropdownLeft + 'px';
                    dropdownElement.style.bottom = dropdownBottom + 'px';
                    dropdownElement.style.display = 'block';
                    dropdownElement.style.transform = '';
                    dropdownElement.style.maxHeight = '250px';
                    dropdownElement.style.overscrollBehaviorY = 'contain';
                    dropdownElement.style.maxWidth = 'fit-content'; //'min-content';
                    document.body.appendChild(dropdownElement);
                    component.set("v.dropdownElement", dropdownElement);
                }
                dropdownElement.style.display = 'block';
                dropdownElement.style.minWidth = dropdownMinWidth + 'px';
                dropdownElement.style.maxWidth = "none";
            }
        }
        else {
            $A.util.removeClass(dropdownBox, "slds-dropdown_bottom");
            if (dropdownElement) {
                if (fixedPosition == true) {
                    dropdownElement.style.position = 'fixed';
                    dropdownElement.style.left = dropdownLeft + 'px';
                    dropdownElement.style.top = dropdownTop + 'px';
                    dropdownElement.style.display = 'block';
                    dropdownElement.style.transform = '';
                    dropdownElement.style.maxHeight = '250px';
                    dropdownElement.style.overscrollBehaviorY = 'contain';
                    dropdownElement.style.maxWidth = 'fit-content'; //'min-content';
                    document.body.appendChild(dropdownElement);
                    component.set("v.dropdownElement", dropdownElement);
                }
                dropdownElement.style.display = 'block';
                dropdownElement.style.minWidth = dropdownMinWidth + 'px';
                dropdownElement.style.maxWidth = "none";
            }
        }
    },
    closeDropdown : function(component, event, helper) {
        helper.closeDropdown(component);
    }
});