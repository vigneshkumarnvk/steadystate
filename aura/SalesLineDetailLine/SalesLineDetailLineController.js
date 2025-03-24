({
    handleScheduledDateChange : function(component, event, helper) {
        /*
        var valid = true;
        if (salesLine && salesLine.Sales_Line_Details__r) {
            var map = new Map();
            for (var i = 0; i < salesLine.Sales_Line_Details__r.length; i++) {
                var salesLineDetail = salesLine.Sales_Line_Details__r[i];
                if (!map.has(salesLineDetail.Scheduled_Date__c)) {
                    map.set(salesLineDetail.Scheduled_Date__c, salesLineDetail);
                } else {
                    valid = false;
                    var dt = new Date(salesLineDetail.Scheduled_Date__c);
                    var formattedDate = (dt.getUTCMonth() + 1) + '/' + dt.getUTCDate() + '/' + dt.getUTCFullYear();
                    alert('The scheduled date ' + formattedDate + ' already exist. Please choose a different date.');
                    salesLineDetail.Scheduled_Date__c = null;
                }
            }
        }

        if (valid) {
            helper.recalculate(component, event);
        }
        */
        helper.recalculateDetailLine(component, event);
    },
    handleStartTimeChange : function(component, event, helper) {
        helper.calculateUOMQty(component, event);
    },
    handleEndTimeChange : function(component, event, helper) {
        helper.calculateUOMQty(component, event);
    },
    handleUOMQtyChange : function(component, event, helper) {
        component.set("v.salesLineDetail.Start_Time__c", null);
        component.set("v.salesLineDetail.End_Time__c", null);
        helper.calculateUOMQty(component, event);
    },
    handleCopyTime : function (component, event, helper){
        helper.copyTimes(component, event);
    }
});