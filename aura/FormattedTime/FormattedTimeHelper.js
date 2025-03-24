({
    displayTime : function(component, event) {
        var value = component.get("v.value");
        if (value != null && value != '') {
            var arr = value.split(':');
            component.set("v.displayValue", arr[0] + ':' + arr[1]);
        }
        else {
            component.set("v.displayValue", "");
        }
    }
});