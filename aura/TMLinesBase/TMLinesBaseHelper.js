({
    fireTMLinesChangedEvent : function(component, causedByRowIndex, causedByField) {
        var onchange = component.getEvent("onchange");
        var category = component.get("v.category");
        var tmLines = component.get("v.tmLines");
        onchange.setParams({ "category": category, "tmLines": tmLines, "causedByRowIndex": causedByRowIndex, "causedByField": causedByField });
        onchange.fire();
    },
    viewLine : function(component, event, rowIndex) {
        //ticket 19130 <<
        var tm = component.get("v.tm");
        var jobTaskWrapper = component.getReference("v.jobTaskWrapper");
        //ticket 19130 >>
        var tmLines = component.get("v.tmLines");
        var tmLine = tmLines[rowIndex];


        //ticket 19130 <<
        /*
        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Save', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "save", "callback": this.viewLineCallback.bind(this, component, event, rowIndex) }});
        var params = { "tmLine": tmLine };
        this.openModal(component, event, 'T&M Line Details', null, buttons, 'c:TMLineCard', params, 'small');
        */
        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        if (tm.Status__c != 'Fully Invoiced' && tm.Status__c != 'Void' && tmLine.System_Calculated_Line__c != true) {
            buttons.push({ "label": 'Save', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "save", "callback": this.viewLineCallback.bind(this, component, event, rowIndex) }});
        }

        var params = { "tm": tm, "jobTaskWrapper": jobTaskWrapper, "tmLine": tmLine };
        this.openModal(component, event, 'Edit T&M Line', null, buttons, 'c:TMLineCard', params, 'small');
        //ticket 19130 >>


    },
    viewLineCallback : function(component, event, rowIndex, tmLine) {
        this.closeModal(component, event);

        //ticket 19130 <<
        //check if the relationship has changed, if so, need the wizard popped out
        let tmLines = component.get("v.tmLines");
        let xTMLine = tmLines[rowIndex];

        if (!xTMLine.TM_Child_Lines__r && tmLine.TM_Child_Lines__r) {
            tmLine.Wizard_Question_Answered__c = false;
        }
        else if (xTMLine.TM_Child_Lines__r && tmLine.TM_Child_Lines__r) {
            let xChildLineNos = [];
            let childLineNos = [];
            if (xTMLine.TM_Child_Lines__r.records) {
                for (var i = 0; i < xTMLine.TM_Child_Lines__r.records.length; i++) {
                    if (xTMLine.TM_Child_Lines__r.records[i].Child_Line__r) {
                        xChildLineNos.push(parseInt(xTMLine.TM_Child_Lines__r.records[i].Child_Line__r.Line_No__c));
                    }
                }
            }
            if (tmLine.TM_Child_Lines__r.records) {
                for (var i = 0; i < tmLine.TM_Child_Lines__r.records.length; i++) {
                    if (tmLine.TM_Child_Lines__r.records[i].Child_Line__r) {
                        childLineNos.push(parseInt(tmLine.TM_Child_Lines__r.records[i].Child_Line__r.Line_No__c));
                    }
                }
            }

            for (var i = 0; i < xChildLineNos.length; i++) {
                let lineNo = xChildLineNos[i];
                let index = childLineNos.indexOf(lineNo);
                if (index >= 0) {
                    xChildLineNos.splice(i, 1);
                    i--;
                    childLineNos.splice(index, 1);
                }
            }

            tmLine.Wizard_Question_Answered__c = !(xChildLineNos.length > 0 || childLineNos.length > 0);

            //set child lines question answered to false
            var jobTaskWrapper = component.get("v.jobTaskWrapper");
            var childLineNosToUpdate = [...xChildLineNos, ...childLineNos];

            childLineNosToUpdate.forEach(childLineNo => {
                for (var i = 0; i < jobTaskWrapper.TMLines.length; i++) {
                    if (jobTaskWrapper.TMLines[i].Line_No__c == childLineNo) {
                        jobTaskWrapper.TMLines[i].Wizard_Question_Answered__c = false;
                    }
                }
            });
        }


        //ticket 19130 >>

        component.set("v.tmLines[" + rowIndex + "]", tmLine);
        //ticket 19130 <<
        //this.cleanUpChildResourceLines(component);
        //this.fireTMLinesChangedEvent(component, null, 'Flat_Pay_Lines__r'); //trigger flat pay calculation in TMJobTaskLine component
        this.fireTMLinesChangedEvent(component, rowIndex);
        //ticket 19130 >>
    },
    addLine : function(component, event, resolve, reject) {
        var tm = component.get("v.tm");
        var category = component.get("v.category");
        //ticket 19130 <<
        //var jobTask = component.get("v.jobTask");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        //ticket 19130 >>
        var tmLines = component.get("v.tmLines");
        var variables = component.get("v.variables");

        var nextTMLineNo = component.get("v.nextTMLineNo");
        var tmLine = {};
        tmLine.Line_No__c = nextTMLineNo;
        tmLine.Category__c = category;
        if (tmLine.Category__c == 'Labor' || tmLine.Category__c == 'Equipment') {
            if (tm.Status__c == 'Confirmed') {
                tmLine.Service_Center__c = variables.TemporaryServiceCenter.Id;
                tmLine.Service_Center__r = variables.TemporaryServiceCenter;
            }
            else {
                tmLine.Service_Center__c = tm.Service_Center__c;
                tmLine.Service_Center__r = tm.Service_Center__r;
            }
        }
        //ticket 19130 <<
        /*
        tmLine.TM_Job_Task__c = jobTask.Id;
        tmLine.TM_Job_Task__r = jobTask;
        */
        tmLine.TM_Job_Task__c = jobTaskWrapper.JobTask.Id;
        tmLine.TM_Job_Task__r = jobTaskWrapper.JobTask;
        //ticket 19130 >>
        tmLine.TM__c = tm.Id;
        tmLine.TM__r = { Id: tm.Id, Name: tm.Name };

        //ticket 19130 <<
        tmLine.TM_Child_Lines__r = { "records": [] };
        //ticket 19130 >>

        tmLines.push(tmLine);
        component.set("v.tmLines", tmLines);//JSON.parse(JSON.stringify(tmLines))); //reset the variable reference to rerender the table
        component.set("v.inlineEditRowIndex", tmLines.length - 1);
        //nextTMLineNo++;
        //component.set("v.nextTMLineNo", nextTMLineNo);

        if (resolve) {
            resolve();
        }
    },
    confirmCopyTime : function(component, event, rowIndex) {
        var tmLines = component.get("v.tmLines");
        var tmLine = tmLines[rowIndex];
        if (tmLine.Category__c == 'Labor') {
            if (tmLine.Job_Start_Time__c == null || tmLine.Job_End_Time__c == null || tmLine.Site_Start_Time__c == null || tmLine.Site_End_Time__c == null) {
                this.showToast(component, "Copy Time Error", 'You must complete Job Start Time, Job End Time, Site Start Time and Site End Time to copy time.', 'error', 'dismissible');
                return;
            }
        }
        else if (tmLine.Category__c == 'Equipment') {
            if (tmLine.Job_Start_Time__c == null || tmLine.Job_End_Time__c == null) {
                this.showToast(component, "Copy Time Error", 'You must complete Job Start Time, Job End Time to copy time.', 'error', 'dismissible');
                return;
            }
        }
        else {
            return;
        }

        var buttons = [];
        buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.confirmCopyTimeCallback.bind(this, component, event, rowIndex) }});
        this.openModal(component, event, 'Copy Time', 'Are you sure to copy times of this line to the lines below it?', buttons, null, null, null);
    },
    confirmCopyTimeCallback : function(component, event, rowIndex) {
        this.closeModal(component, event);

        //pass a callback function to the closeInLineEdit to trigger the function after TMCalculateLines async server call
        //this.closeInlineEdit(component, this.copyTime.bind(this, component, event, rowIndex));
        var helper = this;
        var calls = [];
        calls.push(helper.closeInlineEdit.bind(helper, component, event));
        calls.push(helper.copyTime.bind(helper, component, event, rowIndex));
        calls.push(helper.fireTMLinesChangedEvent.bind(helper, component));
        this.makeStackedCalls(component, event, helper, calls);
    },
    copyTime : function(component, event, rowIndex, resolve, reject) {
        var tmLines = component.get("v.tmLines");
        var tmLine = tmLines[rowIndex];
        for (var i = rowIndex + 1; i < tmLines.length; i++) {
            if (tmLines[i].Invoiced__c != true) {
                tmLines[i].Job_Start_Time__c = tmLine.Job_Start_Time__c;
                tmLines[i].Job_End_Time__c = tmLine.Job_End_Time__c;
                tmLines[i].Site_Start_Time__c = tmLine.Site_Start_Time__c;
                tmLines[i].Site_End_Time__c = tmLine.Site_End_Time__c;
                tmLines[i].Lunch_Start_Time__c = tmLine.Lunch_Start_Time__c;
                tmLines[i].Lunch_End_Time__c = tmLine.Lunch_End_Time__c;
                tmLines[i].Total_Job_Hours__c = tmLine.Total_Job_Hours__c;
                tmLines[i].Total_Site_Hours__c = tmLine.Total_Site_Hours__c;
                tmLines[i].Regular_Hours__c = tmLine.Regular_Hours__c;
                tmLines[i].Overtime_Hours__c = tmLine.Overtime_Hours__c;
                tmLines[i].Premium_Hours__c = tmLine.Premium_Hours__c;
                if (tmLines[i].Unit_of_Measure__r) {
                    if (tmLines[i].Unit_of_Measure__r.Hours_UOM__c == true) {
                        tmLines[i].Quantity__c = tmLines[i].Total_Job_Hours__c;
                        //ticket 19725 <<
                        if (tmLines[i].Category__c == 'Labor') {
                            tmLines[i].Quantity__c = tmLines[i].Quantity__c  - this.calculateLunchHours(tmLine);
                        }
                        //ticket 19725 >>
                    } else if (!tmLines[i].Quantity__c) {
                        tmLines[i].Quantity__c = 1;
                    }
                }
            }
        }
        component.set("v.tmLines", tmLines);
        this.refreshTable(component);

        if (resolve) {
            resolve();
        }
    },
    validateDeleteLines : function(component, rowIndexes) {
        var tm = component.get("v.tm");
        var tmLines = component.get("v.tmLines");
        var childLines = [];
        var bundleLines = [];
        var systemLines = [];
        var invoicedLines = [];
        var undeletableLines = [];

        for (var i = 0; i < tmLines.length; i++) {
            var tmLine = tmLines[i];
            if (tmLine.Selected === true) {
                //ticket 19130 <<
                /*
                if (tmLine.Parent_Line__r != null) {
                    childLines.push(tmLine.Line_No__c);
                }
                */
                //ticket 19130 >>
                if (tmLine.Bundle_Line__r != null) {
                    bundleLines.push(tmLine.Line_No__c);
                }
                if (tmLine.System_Calculated_Line__c === true) {
                    systemLines.push(tmLine.Line_No__c);
                }
                if (tm.Status__c === 'Confirmed' && (tmLine.Category__c === 'Labor' || tmLine.Category__c === 'Equipment') && tmLine.Service_Center__r && tmLine.Service_Center__r.Temporary__c !== true) {
                    undeletableLines.push(tmLine.Line_No__c);
                }
                if (tmLine.Invoiced__c === true) {
                    invoicedLines.push(tmLine.Line_No__c);
                }
            }
        }

        var ok = true;
        /* disabled. child lines can be deleted
        if (childLines.length > 0) {
            this.showToast(component, "Delete Error", "You cannot delete lines (" + childLines.join(", ") + ") because they are linked to a parent line. Please delete the parent line first.", "error", "dismissible");
            ok = false;
        }*/

        if (systemLines.length > 0) {
            this.showToast(component, "Delete Error", "You cannot delete system calculated lines (" + systemLines.join(", ") + ").", "error", "dismissible");
            ok = false;
        }
        if (invoicedLines.length > 0) {
            this.showToast(component, "Delete Error", "You cannot delete lines that have been invoiced (" + invoicedLines.join(", ") + ").", "error", "dismissible");
            ok = false;
        }
        if (undeletableLines.length > 0) {
            this.showToast(component, "Delete Error", "You cannot delete none temporary labor/equipment line number(s) " + undeletableLines.join(", ") + ".", "error", "dismissible");
            ok = false;
        }
        return ok;
    },
    confirmDeleteLines : function(component, event, rowIndexes) {
        var buttons = [];
        buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.confirmDeleteLinesCallback.bind(this, component, event, rowIndexes) }});
        this.openModal(component, event, 'Delete Lines', 'Are you sure to delete selected line(s)?', buttons, null, null, null);
    },
    confirmDeleteLinesCallback : function(component, event, rowIndexes) {
        this.closeModal(component, event);
        //this.closeInlineEdit(component, this.deleteLines.bind(this, component, event, rowIndexes));
        var helper = this;
        var calls = [];
        calls.push(helper.closeInlineEdit.bind(helper, component, event));

        var causedByField = null;
        var causedByIndex = -1;
        var tmLines = component.get("v.tmLines");
        for (var i = 0; i < tmLines.length; i++) {
            var tmLine = tmLines[i];
            if (tmLine.Category__c == 'Labor' && rowIndexes.includes(i)) {
                if (tmLine.Resource_Flat_Pays1__r && tmLine.Resource_Flat_Pays1__r.records) {
                    causedByField = 'Flat_Pay_Lines__r';
                    causedByIndex = i;
                    break;
                }
            }
        }

        calls.push(helper.deleteLines.bind(helper, component, event, rowIndexes));
        calls.push(helper.fireTMLinesChangedEvent.bind(helper, component, causedByIndex, causedByField));
        this.makeStackedCalls(component, event, helper, calls);
    },
    deleteLines : function(component, event, rowIndexes, resolve, reject) {
        var category = component.get("v.category");
        var tmLines = component.get("v.tmLines");

        for (var i = tmLines.length - 1; i >= 0; i--) {
            if (rowIndexes.includes(i)) {
                tmLines.splice(i, 1);
                rowIndexes.splice(rowIndexes.indexOf(i), 1);
            }
        }

        component.set("v.tmLines", tmLines);
        this.refreshTable(component);

        if (resolve) {
            resolve();
        }
    },
    //ticket 19130 <<
    /*
    cleanUpChildResourceLines : function(component) {
        var tmLines = component.get("v.tmLines");
        var linesDeleted = 0;
        for (var i = tmLines.length - 1; i >= 0; i--) {
            if (tmLines[i].Is_Child_Resource__c == true && !tmLines[i].Parent_Line__r) {
                tmLines.splice(i, 1);
                linesDeleted++;
            }
        }
        if (linesDeleted > 0) {
            component.set("v.tmLines", tmLines);
        }
    },
    */
    //ticket 19130 >>
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },
    getSelectedLines : function(component) {
        var rowIndexes = [];
        var tmLines = component.get("v.tmLines");
        for (var i = 0; i < tmLines.length; i++) {
            if (tmLines[i].Selected == true) {
                rowIndexes.push(i);
            }
        }
        return rowIndexes;
    },
    //closeInlineEdit : function(component, callback) {
    closeInlineEdit : function(component, event, resolve, reject) {
        //console.log("closing inline edit")
        component.set("v.inlineEditRowIndex", null);
        var datatable = component.getConcreteComponent().find("datatable");
        if (datatable) {
            if (datatable.isInlineEditMode() == true) {
                //return datatable.closeInlineEdit(callback);
                datatable.closeInlineEdit(resolve);
            }
            else {
                if (resolve) {
                    resolve();
                }
            }
        }
    },
    activateInlineEdit : function(component, event, resolve, reject) {
        var rowIndex = component.get("v.inlineEditRowIndex");
        if (rowIndex) {
            var datatable = component.getConcreteComponent().find("datatable");
            if (datatable) {
                datatable.openInlineEdit(rowIndex);
            }
        }
        if (resolve) {
            resolve();
        }
    },
    refreshTable : function(component) {
        var datatable = component.getConcreteComponent().find("datatable");
        if (datatable) {
            return datatable.refreshTable();
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
    validateLaborLines : function(component, tmLines) {
        var ok = true;
        for (var i = 0; i < tmLines.length; i++) {
            var tmLine = tmLines[i];
            tmLine.errorText = null;

            var err = {"descriptions": []};
            if (!tmLine.Resource_Type__c) {
                err.descriptions.push('Resource Type is required.');
            }
            if (!tmLine.Resource__c) {
                err.descriptions.push('Resource is required.');
            }
            if (!tmLine.Service_Center__c) {
                err.descriptions.push('Service Center is required.');
            }

            if (!tmLine.Unit_of_Measure__c) {
                err.descriptions.push('UOM is required.');
            }

            if (!tmLine.Job_Start_Time__c) {
                err.descriptions.push('Job Start Time is required.');
            }
            if (!tmLine.Site_Start_Time__c) {
                err.descriptions.push('Site Start Time is required.');
            }
            if (!tmLine.Site_End_Time__c) {
                err.descriptions.push('Site End Time is required.');
            }
            if (!tmLine.Job_End_Time__c) {
                err.descriptions.push('Job End Time is required.');
            }

            //Ticket#24285 >>
            let isZeroQtyLine = false;
            let lunchHrs = this.calculateLunchHours(tmLine);
            if(tmLine.Job_Start_Time__c !== null && tmLine.Job_End_Time__c !== null && tmLine.Site_Start_Time__c !== null && tmLine.Site_End_Time__c !== null && lunchHrs === 0
                && tmLine.Job_Start_Time__c === tmLine.Site_Start_Time__c && tmLine.Site_Start_Time__c === tmLine.Site_End_Time__c && tmLine.Site_End_Time__c === tmLine.Job_End_Time__c){
                isZeroQtyLine = true;
            }
            //Ticket#24285 <<

            //ticket 19130 <<
            /*
            if ((!tmLine.Quantity__c || tmLine.Quantity__c === 0) && !tmLine.Parent_Line__r) {
                //Ticket#24285 >>
                if(isZeroQtyLine === false){
                    err.descriptions.push('Quantity is required.');
                }
                //err.descriptions.push('Quantity is required.');
                //Ticket#24285 <<
            }
            */
            if (tmLine.Is_Child_Resource__c != true && tmLine.Wizard_Question_Answered__c != true && (!tmLine.Quantity__c || tmLine.Quantity__c === 0) && !tmLine.Parent_Line__r) {
                //Ticket#24285 >>
                if(isZeroQtyLine === false){
                    err.descriptions.push('Quantity is required.');
                }
                //err.descriptions.push('Quantity is required.');
                //Ticket#24285 <<
            }
            //ticket 19130 >>

            //ticket 19447 <<
            else if (tmLine.Unit_of_Measure__r && tmLine.Unit_of_Measure__r.Hours_UOM__c === true) {
                if (parseFloat(tmLine.Total_Job_Hours__c) - this.calculateLunchHours(tmLine) !== parseFloat(tmLine.Quantity__c)) {
                    err.descriptions.push('Quantity must equal to Job Hours.');
                }
            }
            //ticket 19447 >>

            //check duplicated flat pay lines
            if (tmLine.Resource_Flat_Pays1__r != null && tmLine.Resource_Flat_Pays1__r.records != null) {
                var flatRateTypeIds = [];
                for (var j = 0; j < tmLine.Resource_Flat_Pays1__r.records.length; j++) {
                    var flatRateTypeId = tmLine.Resource_Flat_Pays1__r.records[j].Flat_Rate_Type__c;
                    if (flatRateTypeIds.includes(flatRateTypeId)) {
                        err.descriptions.push('Duplicated flat pay type ' + tmLine.Resource_Flat_Pays1__r.records[i].Flat_Rate_Type__r.Name);
                        break;
                    }
                    flatRateTypeIds.push(flatRateTypeId);
                }
            }

            if (err.descriptions.length > 0) {
                tmLine.errorText = '';
                for (var j = 0; j < err.descriptions.length; j++) {
                    tmLine.errorText += (j + 1) + ') ' + err.descriptions[j] + ' ';
                }
                ok = false;
            } else {
                tmLine.errorText = null;
            }
        }
        return ok;
    },
    /*  Ticket#19931
     *    - Job times is not required for Resource Type with Rental Resource Type checked.
     */
    validateEquipmentLines : function(component, tmLines) {
        var ok = true;
        for (var i = 0; i < tmLines.length; i++) {
            var tmLine = tmLines[i];
            var err = {"descriptions": []};

            if (!tmLine.Resource_Type__c) {
                err.descriptions.push('Equipment Type is required.');
            }
            if (!tmLine.Resource__c && tmLine.Resource_Type__r && tmLine.Resource_Type__r.Fleet_No_Required__c == true && tmLine.Service_Center__r && tmLine.Service_Center__r.Equipment_Fleet_No_Not_Required__c != true) {
                err.descriptions.push('Equipment is required.');
            }

            if (!tmLine.Service_Center__c) {
                err.descriptions.push('Service Center is required');
            }

            if (tmLine.Resource_Type__r && tmLine.Resource_Type__r.Fleet_No_Required__c == true && tmLine.Resource_Type__r.Rental_Resource_Type__c != true) {
                if (!tmLine.Job_Start_Time__c) {
                    err.descriptions.push('Job Start Time is required');
                }
                if (!tmLine.Job_End_Time__c) {
                    err.descriptions.push('Job End Time is required');
                }
            }

            //ticket 19130 <<
            /*
            if (!tmLine.Quantity__c || tmLine.Quantity__c == 0) {
                err.descriptions.push('Quantity is required.');
            }
            */
            if (tmLine.Is_Child_Resource__c != true && tmLine.Wizard_Question_Answered__c != true && (!tmLine.Quantity__c || tmLine.Quantity__c == 0)) {
                err.descriptions.push('Quantity is required.');
            }
            //ticket 19130 >>

            //ticket 19447 <<
            else if (tmLine.Resource_Type__r && tmLine.Resource_Type__r.Fleet_No_Required__c == true  && tmLine.Resource_Type__r.Rental_Resource_Type__c != true && tmLine.Unit_of_Measure__r && tmLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                if (parseFloat(tmLine.Total_Job_Hours__c) - this.calculateLunchHours(tmLine) != parseFloat(tmLine.Quantity__c)) {
                    err.descriptions.push('Quantity must equal to Job Hours.');
                }
            }
            //ticket 19447 >>

            if (!tmLine.Unit_of_Measure__c) {
                err.descriptions.push('UOM is required');
            }

            if (err.descriptions.length > 0) {
                tmLine.errorText = '';
                for (var j = 0; j < err.descriptions.length; j++) {
                    tmLine.errorText += (j + 1) + ') ' + err.descriptions[j] + ' ';
                }
                ok = false;
            } else {
                tmLine.errorText = null;
            }
        }
        return ok;
    },
    validateMaterialLines : function(component, tmLines) {
        var ok = true;
        for (var i = 0; i < tmLines.length; i++) {
            var tmLine = tmLines[i];
            var err = {"descriptions": []};

            if (!tmLine.Resource__c) {
                err.descriptions.push('Material is required.');
            }

            //ticket 19130 <<
            /*
            if (!tmLine.Quantity__c || tmLine.Quantity__c == 0) {
                err.descriptions.push('Quantity is required.');
            }
            */
            if (tmLine.Is_Child_Resource__c != true && tmLine.Wizard_Question_Answered__c != true && (!tmLine.Quantity__c || tmLine.Quantity__c == 0)) {
                err.descriptions.push('Quantity is required.');
            }
            //ticket 19130 >>

            if (!tmLine.Unit_of_Measure__c) {
                err.descriptions.push('UOM is required');
            }

            if (err.descriptions.length > 0) {
                tmLine.errorText = '';
                for (var j = 0; j < err.descriptions.length; j++) {
                    tmLine.errorText += (j + 1) + ') ' + err.descriptions[j] + ' ';
                }
                ok = false;
            } else {
                tmLine.errorText = null;
            }
        }
        return ok;
    },
    validateSubcontractorLines : function(component, tmLines) {
        var ok = true;
        for (var i = 0; i < tmLines.length; i++) {
            var tmLine = tmLines[i];
            var err = {"descriptions": []};

            if (!tmLine.Description__c) {
                err.descriptions.push('Billing Description is required.');
            }

            //ticket 19130 <<
            /*
            if (!tmLine.Quantity__c || tmLine.Quantity__c == 0) {
                err.descriptions.push('Quantity is required.');
            }
            */
            if (tmLine.Is_Child_Resource__c != true && tmLine.Wizard_Question_Answered__c != true && (!tmLine.Quantity__c || tmLine.Quantity__c == 0)) {
                err.descriptions.push('Quantity is required.');
            }
            //ticket 19130 >>

            if (!tmLine.Unit_of_Measure__c) {
                err.descriptions.push('UOM is required');
            }

            if (err.descriptions.length > 0) {
                tmLine.errorText = '';
                for (var j = 0; j < err.descriptions.length; j++) {
                    tmLine.errorText += (j + 1) + ') ' + err.descriptions[j] + ' ';
                }
                ok = false;
            } else {
                tmLine.errorText = null;
            }
        }
        return ok;
    },
    validateWasteDisposalLines : function(component, tmLines) {
        var ok = true;
        for (var i = 0; i < tmLines.length; i++) {
            var tmLine = tmLines[i];
            var err = {"descriptions": []};

            if (!tmLine.Resource__c) {
                err.descriptions.push('Waste Disposal is required.');
            }

            //ticket 19130 <<
            /*
            if (!tmLine.Quantity__c || tmLine.Quantity__c == 0) {
                err.descriptions.push('Quantity is required.');
            }
            */
            if (tmLine.Is_Child_Resource__c != true && tmLine.Wizard_Question_Answered__c != true && (!tmLine.Quantity__c || tmLine.Quantity__c == 0)) {
                err.descriptions.push('Quantity is required.');
            }
            //ticket 19130 >>

            /* Waste001
            if (tmLine.Resource__r == null || tmLine.Resource__r.Name == 'WD' || tmLine.Resource__r.Name == 'MA Transporter Fee' || tmLine.Resource__r.Name == 'Manifest Fee' || (tmLine.Resource__r.Has_Container__c != true && tmLine.Resource__r.Has_Weight_Volume__c != true)) {
                if (!tmLine.Unit_of_Measure__c) {
                    err.descriptions.push('UOM is required');
                }
            } else {

                if (tmLine.System_Calculated_Line__c != true) {
                    if (!tmLine.Cost_Method__c) {
                        err.descriptions.push('Cost Method is required');
                    }
                    //ticket 19586 <<
                    if (!tmLine.Facility__c) {
                        var facilityRequiredStartDate = new Date('2021-05-04T12:00:00.000Z');
                        if (!tmLine.CreatedDate || (tmLine.CreatedDate && new Date(tmLine.CreatedDate) >= facilityRequiredStartDate)) {
                            err.descriptions.push('Facility is required.');
                        }
                    }
                    //ticket 19586 >>
                }
            }
             */
            if (tmLine.Resource__r != null && tmLine.Resource__r.Name != 'WD' && tmLine.Resource__r.Name != 'MA Transporter Fee' && tmLine.Resource__r.Name != 'Manifest Fee' && tmLine.System_Calculated_Line__c != true) {
                if (!tmLine.Facility__c) {
                    var facilityRequiredStartDate = new Date('2021-05-04T12:00:00.000Z');
                    if (!tmLine.CreatedDate || (tmLine.CreatedDate && new Date(tmLine.CreatedDate) >= facilityRequiredStartDate)) {
                        err.descriptions.push('Facility is required.');
                    }
                }
            }
            //Waste001

            if (!tmLine.Unit_of_Measure__c) {
                err.descriptions.push('UOM is required');
            }

            if (err.descriptions.length > 0) {
                tmLine.errorText = '';
                for (var j = 0; j < err.descriptions.length; j++) {
                    tmLine.errorText += (j + 1) + ') ' + err.descriptions[j] + ' ';
                }
                ok = false;
            } else {
                tmLine.errorText = null;
            }
        }
        return ok;
    },
    validateDemurrageLines : function(component, tmLines) {
        var ok = true;for (var i = 0; i < tmLines.length; i++) {
            var tmLine = tmLines[i];
            var err = {"descriptions": []};

            if (!tmLine.Resource__c) {
                err.descriptions.push('Resource is required.');
            }

            //ticket 19130 <<
            /*
            if (!tmLine.Quantity__c || tmLine.Quantity__c == 0) {
                err.descriptions.push('Quantity is required.');
            }
            */
            if (tmLine.Is_Child_Resource__c != true && tmLine.Wizard_Question_Answered__c != true && (!tmLine.Quantity__c || tmLine.Quantity__c == 0)) {
                err.descriptions.push('Quantity is required.');
            }
            //ticket 19130 >>

            if (!tmLine.Unit_of_Measure__c) {
                err.descriptions.push('UOM is required');
            }

            if (err.descriptions.length > 0) {
                tmLine.errorText = '';
                for (var j = 0; j < err.descriptions.length; j++) {
                    tmLine.errorText += (j + 1) + ') ' + err.descriptions[j] + ' ';
                }
                ok = false;
            } else {
                tmLine.errorText = null;
            }
        }
        return ok;
    },
    validateMiscChargeLines : function(component, tmLines) {
        var ok = true;
        for (var i = 0; i < tmLines.length; i++) {
            var tmLine = tmLines[i];
            var err = {"descriptions": []};

            if (!tmLine.Resource__c) {
                err.descriptions.push('Resource is required.');
            }

            //ticket 19130 <<
            /*
            if (!tmLine.Quantity__c || tmLine.Quantity__c == 0) {
                err.descriptions.push('Quantity is required.');
            }
            */
            if (tmLine.Is_Child_Resource__c != true && tmLine.Wizard_Question_Answered__c != true && (!tmLine.Quantity__c || tmLine.Quantity__c == 0)) {
                err.descriptions.push('Quantity is required.');
            }
            //ticket 19130 >>

            if (!tmLine.Unit_of_Measure__c) {
                err.descriptions.push('UOM is required');
            }

            if (err.descriptions.length > 0) {
                tmLine.errorText = '';
                for (var j = 0; j < err.descriptions.length; j++) {
                    tmLine.errorText += (j + 1) + ') ' + err.descriptions[j] + ' ';
                }
                ok = false;
            }
            else {
                tmLine.errorText = null;
            }
        }
        return ok;
    },
    //ticket 19447 <<
    calculateLunchHours : function(tmLine) {
        return this.calculateHours(tmLine.Lunch_Start_Time__c, tmLine.Lunch_End_Time__c);
    }
    //ticket 19447 >>
});