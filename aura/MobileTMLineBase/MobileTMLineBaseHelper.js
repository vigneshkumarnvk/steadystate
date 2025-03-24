({
    validateResourceType : function(component, event, tmLine) {
        var params = { "JSONTMLine": JSON.stringify(tmLine)};
        this.callServerMethod(component, event, "c.validateResourceType", params, function(response) {
            var tmLine = component.get("v.tmLine");
            Object.assign(tmLine, JSON.parse(response));
            this.fireTMLineUpdateEvent(component, event); 
        })
    },
    //ticket 18178 <<
    validateResource : function(component, event, tmLine) {
        var params = { "JSONTMLine": JSON.stringify(tmLine)};
        this.callServerMethod(component, event, "c.validateResource", params, function(response) {
            component.set("v.tmLine", JSON.parse(response));
            this.fireTMLineUpdateEvent(component, event);
        });
    },
    validateUnitOfMeasure : function(component, event, tmLine) {
        var params = { "JSONTMLine": JSON.stringify(tmLine)};
        this.callServerMethod(component, event, "c.validateUnitOfMeasure", params, function(response) {
            component.set("v.tmLine", JSON.parse(response));
            this.fireTMLineUpdateEvent(component, event);
        });
    },
    //ticket 18178 >>
    fireTMLineDeleteEvent : function(component, event) {
        var rowIndex = component.get("v.rowIndex")
        var tmLineDeleteEvent = component.getEvent("tmLineDeleteEvent");
        tmLineDeleteEvent.setParams({ "rowIndex": rowIndex });
        tmLineDeleteEvent.fire();
    },
    fireTMLineUpdateEvent : function(component, event) {
        var rowIndex = component.get("v.rowIndex")
        var tmLine = component.get("v.tmLine");
        var tmLineUpdateEvent = component.getEvent("tmLineUpdateEvent");
        tmLineUpdateEvent.setParams({ "rowIndex": rowIndex, "tmLine": tmLine });
        tmLineUpdateEvent.fire();
    },
    calculateQuantity : function(component, tmLine) {
        if (tmLine.Unit_of_Measure__r && tmLine.Unit_of_Measure__r.Hours_UOM__c == true) {
            if(tmLine.Category__c === 'Labor'){
                //Ticket#24285 >>
                if(tmLine.Total_Job_Hours__c > 0) {
                    tmLine.Quantity__c = tmLine.Total_Job_Hours__c - this.calculateHours(tmLine.Lunch_Start_Time__c, tmLine.Lunch_End_Time__c);
                } else {
                    tmLine.Quantity__c = tmLine.Total_Job_Hours__c;
                }
                //tmLine.Quantity__c = tmLine.Total_Job_Hours__c - this.calculateHours(tmLine.Lunch_Start_Time__c, tmLine.Lunch_End_Time__c);
                //Ticket#24285 <<
            } else {
                tmLine.Quantity__c = tmLine.Total_Job_Hours__c;
            }
        }
        else {
            if (tmLine.Total_Job_Hours__c > 0) {
                tmLine.Quantity__c = 1;
            }
            else {
                tmLine.Quantity__c = 0;
            }
        }
    },
    calculateHours : function(startTime, endTime) {
        var hours = 0;
        if (startTime != null && startTime.length > 0 && endTime != null && endTime.length > 0) {
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
    integerToTime : function(timeValue) {
        var timeString;
        if (timeValue != null) {
            var timeValue = timeValue / 1000;
            var h = Math.floor(timeValue / 60 / 60);
            var timeValue = (timeValue % (60 * 60));
            var m = Math.floor(timeValue / 60);
            var s = (timeValue % 60);
            
            var hours = h < 10 ? '0' + h : h;
            var minutes = m < 10 ? '0' + m : m;
            var seconds = s < 10 ? '0' + s : s;
            timeString = hours + ':' + minutes + ':' + seconds + '.000Z'
        }
        return timeString;
    },
   getValidUOM1: function(component, billUnitCode, callback) {      
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

console.log('Before enqueue action');
$A.enqueueAction(action);
console.log('After enqueue action');
	} 


    
    
    
});