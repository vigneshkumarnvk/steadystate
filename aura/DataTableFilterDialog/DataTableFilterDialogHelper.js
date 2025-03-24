({
    showDialog : function(component) {
        var dialog = component.find("dialog");
        $A.util.addClass(dialog, 'slds-is-open');
        $A.util.removeClass(dialog, 'slds-is-close');

        setTimeout(function( ) {
            var input = component.find("input");
            input.focus();
        }, 1);
    },
    hideDialog : function(component) {
        var dialog = component.find("dialog");
        $A.util.addClass(dialog, 'slds-is-close');
        $A.util.removeClass(dialog, 'slds-is-open');
    },
    fireFilterEvent : function(component) {
        var columnIndex = component.get("v.columnIndex");
        var value = component.get("v.value");
        var onfilter = component.getEvent("onfilter");
        onfilter.setParams({ "columnIndex": columnIndex, "value": value });
        onfilter.fire();
        this.hideDialog(component);
    }
});