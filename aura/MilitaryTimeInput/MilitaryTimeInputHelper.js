({
    createTimePicklist : function(component, event) {
        var disabled = component.get("v.disabled");
        if (disabled == true) return;

        if (component.get("v.times").length == 0) {
            var times = [];
            for (var i = 0; i < 24; i++) {
                var cells = [];
                var h = ('0' + i).slice(-2);
                for (var j = 0; j < 4; j++) {
                    var m = ('0' + (j * 15)).slice(-2);
                    cells.push(h + ':' + m);
                }
                times.push({"hour": h, "cells": cells});
            }
            component.set("v.times", times);
        }
        this.showTimePicklist(component, event);

        setTimeout($A.getCallback(function() {
            var value = component.get("v.value");
            var selectedTime;
            if (value != null) {
                selectedTime = value.substring(0, 5);
            }

            var defaultTime = component.get("v.defaultTime");
            if (defaultTime != null) {
                defaultTime = defaultTime.substring(0, 5);
            }

            //var slots = document.getElementsByClassName('time-slot');
            var slots = component.find("time-slot");
            if (slots) {
                for (var i = 0; i < slots.length; i++) {
                    $A.util.removeClass(slots[i], 'default-time');
                    $A.util.removeClass(slots[i], 'selected-time');
                }
                var slot = null;
                for (var i = 0; i < slots.length; i++) {
                    if (selectedTime != null) {
                        if (slots[i].getElement().innerHTML == selectedTime) {
                            $A.util.addClass(slots[i], 'selected-time');
                            slot = slots[i];
                            break;
                        }
                    } else if (defaultTime != null) {
                        if (slots[i].getElement() != null && slots[i].getElement().innerHTML == defaultTime) {
                            $A.util.addClass(slots[i], 'default-time');
                            slot = slots[i];
                            break;
                        }
                    }
                }

                if (slot != null) {
                    var timeContainer = component.find("time-container");
                    var timeInputTop = timeContainer.getElement().getBoundingClientRect().top;
                    //set scroller to the top
                    component.find("scroller-wrapper").scrollTo('top');
                    //child's relative top to the time input container
                    var top = slot.getElement().getBoundingClientRect().top - timeInputTop;
                    top = top - 45; // position to show the time,
                    if (top < 0) {
                        top = 0;
                    }
                    component.find("scroller-wrapper").scrollTo('custom', 0, top);
                }
            }
        }),1);
    },
    showTimePicklist : function(component, event) {
        var timeContainer = component.find("time-container");
        $A.util.addClass(timeContainer, 'slds-is-open');
        $A.util.removeClass(timeContainer, 'slds-is-close');

        //dropdown position
        var top = timeContainer.getElement().getBoundingClientRect().top;
        var left = timeContainer.getElement().getBoundingClientRect().left;
        var bottom = timeContainer.getElement().getBoundingClientRect().bottom;
        var width = timeContainer.getElement().getBoundingClientRect().width;
        var vh = Math.max(document.documentElement.clientHeight, window.innerHeight || 0);

        var dropdown = component.find("dropdown");
        if (top > (vh / 1.3)) {
            $A.util.removeClass(dropdown, "slds-dropdown");
            $A.util.addClass(dropdown, "slds-dropdown_bottom");
            $A.util.addClass(dropdown, "dropdown-bottom");
        } else {
            $A.util.addClass(dropdown, "slds-dropdown");
            $A.util.removeClass(dropdown, "slds-dropdown_bottom");
            $A.util.removeClass(dropdown, "dropdown-bottom");
        }

        $A.util.addClass(dropdown, "slds-dropdown_left");
        $A.util.removeClass(dropdown, "slds-dropdown_right");

        var dropdownWidth = Math.max(dropdown.getElement().getBoundingClientRect().width, timeContainer.getElement().getBoundingClientRect().width);
        dropdown.getElement().style.minWidth = dropdownWidth + 'px';

        //temp fix for displaying dropdown in datatable <<
        var datatable = component.get("v.datatable");
        if (datatable == true) {
            dropdown.getElement().style.position = 'fixed';
            dropdown.getElement().style.left = left + 'px';
            dropdown.getElement().style.top = bottom + 'px';
        }
    },
    hideTimePicklist : function(component, event) {
        var timeContainer = component.find("time-container");
        $A.util.addClass(timeContainer, 'slds-is-close');
        $A.util.removeClass(timeContainer, 'slds-is-open');
    },
    fireTimeChangeEvent : function(component, event) {
        var value = component.get("v.value");
        var onchange = component.getEvent("onchange");
        onchange.setParams({ "value": value });
        onchange.fire();

        //dispatch a DOM change event //for use in FlexDataTable, event are bubbled to the parent element
        var timeContainer = component.find("time-container");
        var element = timeContainer.getElement();
        if (element != null) {
            var event = new CustomEvent('change', { bubbles: true, cancelable: true, detail: { value: JSON.stringify(value) }});
            element.dispatchEvent(event);
        }
    },
})