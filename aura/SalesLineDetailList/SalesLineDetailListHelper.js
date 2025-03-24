({
    explode : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var salesLine = component.get("v.salesLine");
        var JSONSalesOrder = this.serializeObject(salesOrder);
        var JSONSalesLine = this.serializeObject(salesLine, 'Sales_Line_Details__r');
        var params = { "JSONSalesOrder": JSONSalesOrder, "JSONSalesLine": JSONSalesLine };
        this.callServerMethod(component, event, "c.explodeSalesLineDetails", params, function(result) {
            //fix.null.fields <<
            //component.set("v.salesLine", result);
            component.set("v.salesLine", JSON.parse(result));
            //fix.null.fields >>
        }, function(err) {
            alert(err);
        })
    },
    recalculate : function(component, event, rowIndex) {
        var salesOrder = component.get("v.salesOrder");
        var salesLine = component.get("v.salesLine");
        //job task <<
        /*
        var JSONSalesOrder = this.serializeObject(salesOrder);
        var JSONSalesLine = this.serializeObject(salesLine, 'Sales_Line_Details__r');
        var params = { "JSONSalesOrder": JSONSalesOrder, "JSONSalesLine": JSONSalesLine, "calculateHours": false };
        this.callServerMethod(component, event, "c.recalculateSalesLineDetails", params, function(result) {
            //fix.null.fields <<
            //component.set("v.salesLine", result);
            component.set("v.salesLine", JSON.parse(result));
            //fix.null.fields >>
        }, function(err) {
            alert(err);
        })
        */
        var JSONSalesOrder = this.serializeObject(salesOrder);
        var JSONSalesLine = this.serializeObject(salesLine, 'Sales_Line_Details__r');
        var params = { "JSONSalesOrder": JSONSalesOrder, "JSONSalesLine": JSONSalesLine, "recalculateHours": false };
        this.callServerMethod(component, event, "c.calculateSalesLine", params, function(result) {
            component.set("v.salesLine", JSON.parse(result));
        }, function(err) {
            alert(err);
        })
        //job task >>
    },
    confirmCopyTime : function(component, event) {
        var buttons = [];
        buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.copyTimeCallback.bind(this, component, event) }});
        this.openModal(component, event, 'Copy Time', 'Are you sure you want to times from this line to all the lines below it?', buttons, null, null, null);
    },
    copyTimeCallback : function(component, event) {
        this.copyTime(component, event);
        this.closeModal(component, event);
    },
    copyTime : function(component, event) {
        var lineIndex = event.getParam("lineIndex");
        var salesLine = component.get("v.salesLine");
        var salesOrder = component.get("v.salesOrder");

        if(salesLine.Sales_Line_Details__r != null) {
            for (var i = lineIndex + 1; i < salesLine.Sales_Line_Details__r.records.length; i++) {
                salesLine.Sales_Line_Details__r.records[i].Start_Time__c = salesLine.Sales_Line_Details__r.records[i - 1].Start_Time__c;
                salesLine.Sales_Line_Details__r.records[i].End_Time__c = salesLine.Sales_Line_Details__r.records[i - 1].End_Time__c;
                salesLine.Sales_Line_Details__r.records[i].UOM_Qty__c = salesLine.Sales_Line_Details__r.records[i - 1].UOM_Qty__c;
            }
            var JSONSalesOrder = this.serializeObject(salesOrder);
            var JSONSalesLine = this.serializeObject(salesLine, 'Sales_Line_Details__r');
            var params = { "JSONSalesOrder": JSONSalesOrder, "JSONSalesLine": JSONSalesLine, "recalculateHours": false };
            this.callServerMethod(component, event, "c.calculateSalesLine", params, function(result) {
                component.set("v.salesLine", JSON.parse(result));
                this.showToast(component, 'success', 'Time copied!', '', 'dismissable');
            }, function(err) {
                alert(err);
            })
        }
    },
})