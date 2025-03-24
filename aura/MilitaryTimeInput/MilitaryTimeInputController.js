({
    doInit : function(component, event, helper) {
        var xValue;
        var value = component.get("v.value");
        if (value != null) {
            xValue = value.substring(0, 5);
        }
        component.set("v.xValue", xValue);

    },
    handleKeyDown : function(component, event, helper) {
        if (event.which == 9 || event.which == 27) { // tab away or escape key
            helper.hideTimePicklist(component, event);
        }
        else if (event.which == 13) {
            var value = component.get("v.value");
            if (!value || value == '') {
                helper.createTimePicklist(component, event);
            }
        }
        else if (event.which == 46) { // delete key
            component.set("v.value", null);
        }
    },
    handleTimeClick : function(component, event, helper) {
        //move to helper
        /*
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
        helper.showTimePicklist(component, event);

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
        }),1);
        */
        helper.createTimePicklist(component, event);
    },
    handleTimeSelect : function(component, event, helper) {
        var xValue = event.target.name;
        if (xValue) {
            component.set("v.xValue", xValue);
			component.find("input").showHelpMessageIfInvalid();
            helper.hideTimePicklist(component, event);
            component.set("v.value", xValue + ':00.000Z');
            helper.fireTimeChangeEvent(component, event);
        }
    },
    handleTimeChange : function(component, event, helper) {
        var xValue = component.get("v.xValue");
        if (xValue != null) {
            var colonIndex = xValue.indexOf(":");
            if (colonIndex >= 0) {
                var status = /^(2[0-3]|[0-1]?[\d]):[0-5][\d]$/.test(xValue);
                if (status) {
                    if (colonIndex == 1) { //eg. 5:00
                        xValue = '0' + xValue;
                    }
                }
                else {
                    xValue = null;
                }
            }
            else {
                var status = /^(2[0-3]|[0-1][\d])([0-5][\d])$/.test(xValue);
                if (status) {
                    xValue = xValue.substring(0, 2) + ':' + xValue.substring(2, 4);
                }
                else {
                    xValue = null;
                }
            }
        }
        component.set("v.xValue", xValue);
        if (xValue != null) {
            component.set("v.value", xValue + ':00.000Z');
        }
        else {
            component.set("v.value", null);
        }
        helper.hideTimePicklist(component, event);
        helper.fireTimeChangeEvent(component, event);
    },
    handleValueChange : function(component, event, helper) {
        var xValue;
        var value = component.get("v.value");
        if (value != null) {
            xValue = value.substring(0, 5);
        }
        component.set("v.xValue", xValue);
    },
    doClearTime : function(component, event, helper) {
        component.set("v.value", null);
    },
    handleMouseLeave : function(component,event,helper) {
        setTimeout($A.getCallback(
            function() {
                var lostFocusTime = component.get("v.lostFocusTime");
                if (new Date() - lostFocusTime > 300) {
                    helper.hideTimePicklist(component, event);
                }
            }
        ), 300); //alow .5 second to close the dropdown
    },
    handleMouseEnter : function(component, event, helper) {
        component.set("v.lostFocusTime", new Date());
    },
    showHelpMessageIfInvalid : function(component, event, helper) {
        var input = component.find("input");
        if (input) {
            input.showHelpMessageIfInvalid();
        }
    }
})