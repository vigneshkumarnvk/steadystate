({
    fireSalesInvoiceLineDeleteEvent : function(component) {
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        var salesInvoiceLineDeleteEvent = component.getEvent("salesInvoiceLineDeleteEvent");
        salesInvoiceLineDeleteEvent.setParams({ "salesInvoiceLine": salesInvoiceLine });
        salesInvoiceLineDeleteEvent.fire();
    },
    confirmDeleteLine : function(component, event) {
        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'OK', "variant": 'brand', "action": { "callback": this.confirmDeleteLineCallback.bind(this, component, event) }});
        this.openModal(component, event, 'Delete Lines', 'Are you sure you want to delete this line?', buttons, null, null, null);
    },
    confirmDeleteLineCallback : function(component, event) {
        this.closeModal(component, event);
        this.fireSalesInvoiceLineDeleteEvent(component);
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event)
    }
});