({
	getData : function(component, event, refresh) {
        var tmId = component.get("v.tmId");
        
        var params = { tmId: tmId, category: 'Labor' };
        //06.23.20 >>
        //this.callServerMethod(component, event, "c.GetTMLinesByCategory", params, function(data){
        this.callServerMethod(component, event, "c.GetTMLinesByCategoryJSON", params, function(response){
            var data = JSON.parse(response);
        //06.23.20 >>
            for (var i = 0; i < data.length; i++) {
                //06.23.20 <<
                /*
                data[i].Job_Start_Time__c = this.integerToTime(data[i].Job_Start_Time__c);
                data[i].Job_End_Time__c = this.integerToTime(data[i].Job_End_Time__c);                    
                data[i].Site_Start_Time__c = this.integerToTime(data[i].Site_Start_Time__c);                     
                data[i].Site_End_Time__c = this.integerToTime(data[i].Site_End_Time__c);
                data[i].Lunch_Start_Time__c = this.integerToTime(data[i].Lunch_Start_Time__c);
                data[i].Lunch_End_Time__c = this.integerToTime(data[i].Lunch_End_Time__c);
                */
                //06.23.20 >>
                //
                if (data[i].Resource_Type__r) {
                    data[i].ResourceTypeName = data[i].Resource_Type__r.Name;
                }

                if (data[i].Resource__r) {
                    data[i].ResourceName = data[i].Resource__r.Description__c;
                }

                //05.17.2019 <<
                if (data[i].Service_Center__r) {
                    data[i].ServiceCenterName = data[i].Service_Center__r.Name;
                }
                //05.17.2019 >>
            }
            component.set("v.data", data);
            
            if (component.get("v.tm.Status__c") == 'Scheduled') {
            	this.addNewLine(component, event);  
            }
            
            setTimeout($A.getCallback(function() {
            	component.set("v.pendingChangesStatus", "");    
            }), 1);
            
            this.calculateHours(component, event);
            
            if (refresh) {
                this.showToast(component, 'success', 'T&M', 'Page refreshed!', 'dismissable');
            }
        });
	},
    addNewLine : function(component, event) {
        var tmId = component.get("v.tmId");
        var serviceCenterId = component.get("v.tm.Service_Center__c");
        var serviceCenterName = component.get("v.tm.Service_Center__r.Name");
        
        var row = { 
            "TM__c": tmId,
            "Category__c": "Labor",
            "Service_Center__c": serviceCenterId,
            "Service_Center__r": { "Id": serviceCenterId, "Name": serviceCenterName },
            "Tax_Group__c": "TX"
        };
        var data = component.get("v.data");
        data.push(row);
        component.set("v.data", data);
    },
    saveData : function(component, event) {
        var tmId = component.get("v.tmId");
        var data = component.get("v.data");
        
        /*
        //check duplicated labor lines
        var duplicateResourceName = null;
        var resources = [];
        for (var i = 0 ; i < data.length; i++) {
            //05.12.2020 <<
            //if (data[i].Resource__c && data[i].Deleted != true) {
            if (data[i].Resource__c && data[i].Deleted != true && data[i].Service_Center__r != null && data[i].Service_Center__r.Name != '99 - Temp') {
            //05.12.2020 >>
                if (resources.includes(data[i].Resource__c)) {
                    duplicateResourceName = data[i].ResourceName;
                    break;
                }
                resources.push(data[i].Resource__c)
            }
        }
        
        if (!duplicateResourceName) {
        */
            var dataCopy = JSON.parse(JSON.stringify(data)); //make a copy of data
        	//06.23.20 <<
        	/*
            for (var i = 0; i < dataCopy.length; i++) {
                dataCopy[i].Job_Start_Time__c = this.timeToInteger(dataCopy[i].Job_Start_Time__c);
                dataCopy[i].Job_End_Time__c = this.timeToInteger(dataCopy[i].Job_End_Time__c);                    
                dataCopy[i].Site_Start_Time__c = this.timeToInteger(dataCopy[i].Site_Start_Time__c);                     
                dataCopy[i].Site_End_Time__c = this.timeToInteger(dataCopy[i].Site_End_Time__c);
                dataCopy[i].Lunch_Start_Time__c = this.timeToInteger(dataCopy[i].Lunch_Start_Time__c);
                dataCopy[i].Lunch_End_Time__c = this.timeToInteger(dataCopy[i].Lunch_End_Time__c);
            }
            */
        	//06.23.20 >>
            
            var params = { "data": JSON.stringify(dataCopy) };
            this.callServerMethod(component, event, "c.saveTMLines", params, function(data){
                this.getData(component, event, false);
                this.showToast(component, 'success', 'T&M', 'Changes saved!', 'dismissable');
        	});
        /*
        }
        else {
            this.showToast(component, 'error', 'T&M', 'Duplicate lines found for resource "' + duplicateResourceName + '".');
        }
        */
    },
    confirmDeleteLine : function(component, event) {
        /*
        var modal = component.find("modal");
        var handler = modal.open('T&M', 'Delete Line', 'Are you sure you want to delete this line?', 'confirmation', component, event, this.deleteLineCallback.bind(this));
        */
 		var buttons = [];
        buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.deleteLineCallback.bind(this, component, event) }});
        this.openModal(component, event, 'Delete Line', 'Are you sure you want to delete this line?', buttons, null, null, null);
	},
    deleteLineCallback : function(component, event) {
        this.deleteLine(component, event);
        this.closeModal(component, event);
    },
    deleteLine : function(component, event) {
        var tmlId = event.getParam("recordId");
        var lineIndex = event.getParam("lineIndex");
    	var data = component.get("v.data");
        if (data) {
            var row = data[lineIndex];
            if (row.Id) {
                data[lineIndex].Deleted = true;
            }
            else {
                data.splice(lineIndex, 1);
            }
            this.showToast(component, 'info', 'T&M', 'The line is marked for deletion. Please save before leaving this page.', 'dismissable');
        }
        component.set("v.data", data);
    },
    confirmDeleteLines : function(component, event) {
        /*
        var modal = component.find("modal");
        var handler = modal.open('T&M', 'Delete Lines', 'Are you sure you want to delete the selected lines?', 'confirmation', component, event, this.deleteLinesCallback.bind(this));
        */
        var buttons = [];
        buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.deleteLinesCallback.bind(this, component, event) }});
        this.openModal(component, event, 'Delete Lines', 'Are you sure you want to delete selected lines?', buttons, null, null, null);
	},
    deleteLinesCallback : function(component, event) {
        this.deleteLines(component, event);
        this.closeModal(component, event);
    },
    deleteLines : function(component, event) {
    	var data = component.get("v.data");
        if (data) {
            for (var i = 0; i < data.length; i++) {
                if (data[i].Selected == true) {
                    if (data[i].Id) {
	                    data[i].Deleted = true;
    	                data[i].Selected = false;
                    }
                    else {
                        data.splice(i, 1);
                        i--;
                    }
                }
            }
        }
        component.set("v.data", data);
        this.showToast(component, 'info', 'T&M', 'The lines are marked for deletion. Please save before leaving this page.', 'dismissable');
    },
    confirmCopyTime : function(component, event) {
        //component.find("modal").open('T&M', 'Copy Time', 'Are you sure you want to copy times from this line to all the lines below it?', 'confirmation', component, event, this.copyTimeCallback.bind(this));
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
        var tmlId = event.getParam("recordId");
        var lineIndex = event.getParam("lineIndex");
    	var data = component.get("v.data");
        for (var i = lineIndex + 1; i < data.length; i++) {
            data[i].Job_Start_Time__c = data[i-1].Job_Start_Time__c;
            data[i].Job_End_Time__c = data[i-1].Job_End_Time__c;
            data[i].Site_Start_Time__c = data[i-1].Site_Start_Time__c;
            data[i].Site_End_Time__c = data[i-1].Site_End_Time__c;
            data[i].Lunch_Start_Time__c = data[i-1].Lunch_Start_Time__c;
            data[i].Lunch_End_Time__c = data[i-1].Lunch_End_Time__c;
        }
        component.set("v.data", data);
        this.showToast(component, 'success', 'T&M', 'Time copied!', 'dismissable');
    },
    confirmRefresh : function(component, event) {
        var pendingChangesStatus = component.get("v.pendingChangesStatus");
        if (pendingChangesStatus == 'Pending_Changes') {
        	//component.find("modal").open('T&M', 'Refresh', 'You have unsaved changes! Are you sure you want to refresh this page?', 'confirmation', component, event, this.refreshCallback.bind(this));
            var buttons = [];
            buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
            buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.refreshCallback.bind(this, component, event) }});       
            this.openModal(component, event, 'Refresh', 'You have unsaved changes! Are you sure you want to refresh this page?', buttons, null, null, null);
        }
        else {
            this.refresh(component, event);
        }
    },
    refreshCallback : function(component, event) {
        this.refresh(component, event);
        this.closeModal(component, event);
	},
    refresh : function(component, event) {
        this.getData(component, event, true);
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },
    integerToTime : function(timeValue) {
        var timeString = '';
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
    timeToInteger : function(timeString) {
        var timeValue;
        if (timeString) {
            var arr = timeString.split(':');
            var h = arr[0];
            var m = arr[1];
            var s = arr[2];
            timeValue = (h * 60 * 60 + m * 60 + parseInt(s)) * 1000;
        }
        else {
            return null;
        }
        return timeValue;
    },
    calculateHours : function(component, event) {
        var data = component.get("v.data");
        var timeValue = 0;
        if (data) {
            //05.17.2019 <<
            var midnight = this.timeToInteger('24:00:00');
            //05.17.2019 >>
            for (var i = 0 ; i < data.length; i++) {
                var row = data[i];
                if (row.Deleted != true) {
                    if (row.Job_End_Time__c && row.Job_Start_Time__c) {
						var startTime = this.timeToInteger(row.Job_Start_Time__c) ;
                        var endTime = this.timeToInteger(row.Job_End_Time__c) ;
                        
						//05.17.2019 <<
                        //time += endTime - startTime;
                        if (startTime > endTime) {
                            timeValue += (midnight - startTime) + endTime;
                        }
                        else {
                            timeValue += endTime - startTime;
                        }
                        //05.17.2019 >>
                    }
                }
            }
        }
        var timeString = this.integerToTime(timeValue);
        var items = timeString.split(':');
        timeString = parseInt(items[0]) + ' hours';
        if (parseInt(items[1]) != 0) {
            timeString += ' ' + items[1] + ' minutes';
        }
        component.set("v.hours", timeString);
    }
})