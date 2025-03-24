({
    addLine : function(component, event) {
        var tm = component.get("v.tm"); 
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var category = component.get("v.category");
        var nextTMLineNo = component.get("v.nextTMLineNo");

        var tmLine = {};
        tmLine.Line_No__c = nextTMLineNo;
        tmLine.TM__c = tm.Id;
        tmLine.Category__c = category;
        tmLine.Service_Center__c = tm.Service_Center__c;
        tmLine.Service_Center__r = tm.Service_Center__r;
        tmLine.TM_Job_Task__c = jobTaskWrapper.JobTask.Id
        tmLine.TM_Job_Task__r = jobTaskWrapper.JobTask;
        nextTMLineNo++;

        jobTaskWrapper.TMLines.push(tmLine);
        component.set("v.jobTaskWrapper", jobTaskWrapper);
        component.set("v.nextTMLineNo", nextTMLineNo);
    },
    confirmDeleteLine : function(component, event) {
        var buttons = [];
        buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.deleteLineCallback.bind(this, component, event) }});
        this.openModal(component, event, 'Delete Line', 'Are you sure you want to delete this line?', buttons, null, null, null);
    },
    deleteLineCallback : function(component, event) {
        this.closeModal(component, event);
        this.deleteLine(component, event);
    },
    deleteLine : function(component, event) {
        var rowIndex = event.getParam("rowIndex");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        if (jobTaskWrapper.TMLines.length > rowIndex) {
            //deleted lines <<
            jobTaskWrapper.DeletedTMLines.push(jobTaskWrapper.TMLines[rowIndex]);
            //deleted lines >>
            jobTaskWrapper.TMLines.splice(rowIndex, 1);
        }
        component.set("v.jobTaskWrapper", jobTaskWrapper);
    },
    confirmDeleteLines : function(component, event) {
        var lineCount = 0;
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        for (var i = 0; i < jobTaskWrapper.TMLines.length; i++) {
            if (jobTaskWrapper.TMLines[i].Selected == true) {
                lineCount++;
            }
        }

        if (lineCount > 0) {
            var buttons = [];
            buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
            buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.deleteLinesCallback.bind(this, component, event) }});
            this.openModal(component, event, 'Delete Lines', 'Are you sure you want to delete selected lines?', buttons, null, null, null);
        }
    },
    deleteLinesCallback : function(component, event) {
        this.closeModal(component, event);
        this.deleteLines(component, event);
    },
    deleteLines : function(component, event) {
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        for (var i = 0; i < jobTaskWrapper.TMLines.length; i++) {
            if (jobTaskWrapper.TMLines[i].Selected == true) {
                //deleted lines <<
                jobTaskWrapper.DeletedTMLines.push(jobTaskWrapper.TMLines[i]);
                //deleted lines >>
                jobTaskWrapper.TMLines.splice(i, 1);
                i--;
            }

        }
        component.set("v.jobTaskWrapper", jobTaskWrapper);
    },
    confirmMoveLines : function(component, event) {
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var tmLines = [];
        for (var i = 0; i < jobTaskWrapper.TMLines.length; i++) {
            if (jobTaskWrapper.TMLines[i].Selected == true) {
                tmLines.push(jobTaskWrapper.TMLines[i]);
            }
        }

        if (tmLines.length > 0) {
            var jobTaskOptions = component.get("v.jobTaskOptions");
            var buttons = [];
            buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
            buttons.push({ "label": 'OK', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "move", "callback": this.moveLinesCallback.bind(this, component, event, tmLines, jobTaskWrapper.JobTask) }});
            var params = { "jobTaskOptions": jobTaskOptions, "fromJobTask": jobTaskWrapper.JobTask };
            this.openModal(component, event, 'Move Lines', null, buttons, 'c:MoveJobTaskLinesDialog', params, 'small');
        }
        else {
            this.showToast(component, "Move Lines", "Please choose lines to move.", "error", "dismissible");
        }
    },
    moveLinesCallback : function(component, event, tmLines, fromJobTask, toJobTask) {
        this.closeModal(component, event);
        this.fireTMLinesMoveEvent(component, event, tmLines, fromJobTask, toJobTask);
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },
    toggleView : function(component, event, mode) {
        //var viewSection = component.find("view-section");
        var editSection = component.find("edit-section");
        if (mode == 'edit') {
            //$A.util.addClass(viewSection, 'slds-hide');
            $A.util.removeClass(editSection, 'slds-hide');
        }
        else {
            //$A.util.removeClass(viewSection, 'slds-hide');
            $A.util.addClass(editSection, 'slds-hide');
        }
    },
    fireTMLinesMoveEvent : function(component, event, tmLines, fromJobTask, toJobTask) {
        var tmLinesMoveEvent = component.getEvent("tmLinesMoveEvent");
        var params = { "taskLines": tmLines, "fromJobTask": fromJobTask, "toJobTask": toJobTask };
        tmLinesMoveEvent.setParams(params);
        tmLinesMoveEvent.fire();
    },
    calculateQuantity : function(component, tmLine) {
        if (tmLine.Unit_of_Measure__r && tmLine.Unit_of_Measure__r.Hours_UOM__c == true) {
            //tmLine.Quantity__c = tmLine.Total_Job_Hours__c;
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
});