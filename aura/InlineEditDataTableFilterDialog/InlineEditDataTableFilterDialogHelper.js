({
    showDialog : function(component) {
        /*
        var dialog = component.find("dialog");
        $A.util.addClass(dialog, 'slds-is-open');
        $A.util.removeClass(dialog, 'slds-is-close');
        */

        var button = component.find("dialog");
        var dropdown = component.find("dropdown");
        $A.util.addClass(button, 'slds-is-open');
        $A.util.removeClass(button, 'slds-is-close');

        var top = button.getElement().getBoundingClientRect().top;
        var left = button.getElement().getBoundingClientRect().left;
        var bottom = button.getElement().getBoundingClientRect().bottom;
        bottom += 5;

        //dropdown.getElement().style.position = 'fixed'; //to position the dropdown relative to the viewport
        dropdown.getElement().style.left = left + 'px';
        dropdown.getElement().style.top = bottom + 'px';


        setTimeout(function( ) {
            var input = component.find("input");
            if (input) {
                input.focus();
            }
        }, 1);
    },
    hideDialog : function(component) {
        var dialog = component.find("dialog");
        $A.util.addClass(dialog, 'slds-is-close');
        $A.util.removeClass(dialog, 'slds-is-open');
    },
    fireFilterEvent : function(component, action) {
        var columnIndex = component.get("v.columnIndex");
        var value = component.get("v.value");
        var onfilter = component.getEvent("onfilter");
        onfilter.setParams({ "columnIndex": columnIndex, "value": value, "action": action });
        onfilter.fire();
        this.hideDialog(component);
    }
});