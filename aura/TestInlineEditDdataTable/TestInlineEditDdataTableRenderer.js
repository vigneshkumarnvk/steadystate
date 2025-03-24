({
    afterRender : function(component, helper) {
        this.superAfterRender();

        var fixedHeaders = component.get("v.fixedHeaders");
        var fixedColumns = component.get("v.fixedColumns");

        if (fixedHeaders == true && fixedColumns > 0) {
            var headers = component.find("column-headers");
            if (headers) {
                var columnWidths = [];
                for (var i = 0; i < headers.getElement().childNodes.length; i++) {
                    if (i < fixedColumns) {
                        var th = headers.getElement().childNodes[i];
                        columnWidths.push(th.getBoundingClientRect().width);
                    }
                }
                component.set("v.columnWidths", columnWidths);
                helper.setFixedColumnHeaders(component, headers);
            }
        }
    }
});