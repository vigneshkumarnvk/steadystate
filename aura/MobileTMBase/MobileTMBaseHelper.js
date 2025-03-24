({
    fireTMNavigationEvent : function(component, event, tmId, page, reloadTM) {
        var tmNavigationEvent = component.getEvent("tmNavigationEvent");
        tmNavigationEvent.setParams({ "tmId": tmId, "page": page, "reloadTM": reloadTM });
        tmNavigationEvent.fire();
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
    calculateHours : function (startTime, endTime) {
        var hours;
        if (startTime != null && endTime != null) {
            //fix.null.fields <<
            /*
            if (startTime == endTime) {
                hours = 24;
            } else {
                hours = (endTime - startTime) / 36e5;
            }
            */
            var startTimeValue = this.timeToInteger(startTime);
            var endTimeValue = this.timeToInteger(endTime);
            if (startTimeValue == endTimeValue) {
                hours = 24;
            } else {
                hours = (endTimeValue - startTimeValue) / 36e5;
            }
            //fix.null.fields >>
        }
        else {
            hours = 0;
        }

        if (hours < 0) {
            hours += 24;
        }

        return hours;
    },
})