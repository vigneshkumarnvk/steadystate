({
    fireTMLineViewEvent : function(component, event) {
        var rowIndex = component.get("v.index");
        var tmLineViewEvent = component.getEvent("tmLineViewEvent");
        tmLineViewEvent.setParams({ "rowIndex": rowIndex });
        tmLineViewEvent.fire();
    },
    fireTMLineCopyTimeEvent : function(component, event) {
        var tmLine = component.get("v.tmLine");
        var rowIndex = component.get("v.index");
        var tmLineCopyTimeEvent = component.getEvent("tmLineCopyTimeEvent");
        tmLineCopyTimeEvent.setParams({ "tmLine": tmLine, "rowIndex": rowIndex });
        tmLineCopyTimeEvent.fire();
    },
    fireTMLineUpdateEvent : function(component, causedByField) {
        var rowIndex = component.get("v.index");
        var tmLine = component.get("v.tmLine");
        var tmLineUpdateEvent = component.getEvent("tmLineUpdateEvent");
        tmLineUpdateEvent.setParams({ "rowIndex": rowIndex, "tmLine": tmLine, "causedByField": causedByField });
        tmLineUpdateEvent.fire();
    },
    fireTMLineDeleteEvent : function(component, event) {
        var rowIndex = component.get("v.index");
        var tmLineDeleteEvent = component.getEvent("tmLineDeleteEvent");
        tmLineDeleteEvent.setParams({ "rowIndex": rowIndex });
        tmLineDeleteEvent.fire();
    },
    /*
    fireTMLinesMoveEvent : function(component, event, toJobTask) {
        var jobTask = component.get("v.jobTask");
        var tmLine = component.get("v.tmLine");
        var tmLines = [];
        tmLines.push(tmLine);
        var tmLinesMoveEvent = component.getEvent("tmLinesMoveEvent");
        tmLinesMoveEvent.setParams({ "fromJobTask": jobTask, "toJobTask": toJobTask, "tmLines": tmLines });
        tmLinesMoveEvent.fire();
    },*/
    validateResourceType : function(component, event, resolve) {
        var tm = component.get("v.tm");
        var tmLine = component.get("v.tmLine");
        var params = { "JSONTM": JSON.stringify(tm), "JSONTMLine": JSON.stringify(tmLine) };
        this.callServerMethod(component, event, "c.validateResourceType", params, function(response) {
            //ticket 19725 <<
            //component.set("v.tmLine", JSON.parse(response));
            var tmLine = JSON.parse(response);
            this.calculateQuantity(tmLine);
            component.set("v.tmLine", tmLine);
            //ticket 19725 >>
            resolve();
        })
    },
    validateResource : function(component, event, resolve) {
        var tm = component.get("v.tm");
        var tmLine = component.get("v.tmLine");
        var params = { "JSONTM": JSON.stringify(tm), "JSONTMLine": JSON.stringify(tmLine) };
        this.callServerMethod(component, event, "c.validateResource", params, function(response) {
            component.set("v.tmLine", JSON.parse(response));
            resolve();
        });
    },
    validateUnitOfMeasure : function(component, event, resolve) {
        var tm = component.get("v.tm");
        var tmLine = component.get("v.tmLine");
        var params = { "JSONTM": JSON.stringify(tm), "JSONTMLine": JSON.stringify(tmLine) };
        this.callServerMethod(component, event, "c.validateUnitOfMeasure", params, function(response) {
            var tmLine2 = JSON.parse(response);
            //ticket 22134 <<
            //Object.assign(tmLine, tmLine2);
            //ticket 22134 >>
            component.set("v.tmLine", tmLine2);
            if(resolve) {
                resolve();
            }
        })
    },
    calculateFleetNotRequired : function(tmLine) {
        var fleetNotRequired = false;
        if (tmLine.Service_Center__r) {
            if (tmLine.Service_Center__r.Equipment_Fleet_No_Not_Required__c != true) {
                if (tmLine.Resource_Type__r) {
                    tmLine.Fleet_No_Required__c = tmLine.Resource_Type__r.Fleet_No_Required__c;
                }
            }
        }
        else if (tmLine.Resource_Type__r) {
            tmLine.Fleet_No_Required__c = tmLine.Resource_Type__r.Fleet_No_Required__c;
        }
    },
    calculateJobHours : function(tmLine) {
        return this.calculateHours(tmLine.Job_Start_Time__c, tmLine.Job_End_Time__c);
    },
    calculateSiteHours : function(tmLine) {
        return this.calculateHours(tmLine.Site_Start_Time__c, tmLine.Site_End_Time__c);
    },
    calculateLunchHours : function(tmLine) {
        return this.calculateHours(tmLine.Lunch_Start_Time__c, tmLine.Lunch_End_Time__c);
    },
    calculateHours : function(startTime, endTime) {
        var hours = 0;
        if (startTime != null && endTime != null) {
            var startTimeValue = this.timeToInteger(startTime);
            var endTimeValue = this.timeToInteger(endTime);
            if (startTimeValue == endTimeValue) {
                hours = 24;
            } else {
                hours = (endTimeValue - startTimeValue) / 36e5;
                hours = Math.round(hours * 100) / 100;
            }
        }

        if (hours < 0) {
            hours += 24;
        }

        return hours;
    },
    timeToInteger : function(timeString) {
        var timeValue = null;
        if (timeString) {
            var arr = timeString.split(':');
            var h = arr[0];
            var m = arr[1];
            var s = arr[2];
            timeValue = (h * 60 * 60 + m * 60 + parseInt(s)) * 1000;
        }
        return timeValue;
    },
    showToast : function(component, title, message, type, mode) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "mode": mode
        });
        toastEvent.fire();
    },
    //ticket 19725 <<
    calculateQuantity : function(tmLine) {
        if (tmLine.Category__c === 'Labor' || tmLine.Category__c === 'Equipment') {
            if (tmLine.Unit_of_Measure__r.Hours_UOM__c === true) {
                if(tmLine.Category__c === 'Labor'){
                    tmLine.Quantity__c = tmLine.Total_Job_Hours__c - this.calculateLunchHours(tmLine);
                } else {
                    tmLine.Quantity__c = tmLine.Total_Job_Hours__c;
                }
            } else {
                tmLine.Quantity__c = 1;
            }
        }
    },
    getValidUOMs: function(component, billUnitCode, callback) {      
        var action = component.get("c.getValidBillUnitCode");  // Apex method to fetch UOMs
        action.setParams({ billUnitCode: billUnitCode });    
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                console.log('Suc');
                var uomList = response.getReturnValue();
                callback(uomList);  // Return the valid UOM list to the callback
            } else {
                console.error("Error fetching valid UOMs:", response.getError());
                callback([]);  // Fallback to empty list in case of error
            }
        });

    $A.enqueueAction(action);  // Enqueue the action
}
        //ticket 19725 >>
});