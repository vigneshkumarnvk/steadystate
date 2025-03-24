({
	getData : function(component, event, refresh) {
        var tmId = component.get("v.tmId");
        var params = { tmId: tmId, category: 'Subcontractors' };
        this.callServerMethod(component, event, "c.GetTMLinesByCategory", params, function(data){
            for (var i = 0; i < data.length; i++) {                
                if (data[i].Unit_of_Measure__r) {
                    data[i].UnitOfMeasureName = data[i].Unit_of_Measure__r.Name;
                }
                
                //05.17.2019 <<
                if (data[i].Service_Center__r) {
                    data[i].ServiceCentername = data[i].Service_Center__r.Name;
                }
                //05.17.2019 >>
            }
            component.set("v.data", data);
            
            if (component.get("v.tm.Status__c") == 'Scheduled') {
            	this.addNewLine(component, event);
            }
            
            setTimeout($A.getCallback(function(){
                component.set("v.pendingChangesStatus", "");
            }), 1);
            
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
            "Category__c": "Subcontractors",
            "Service_Center__c": serviceCenterId,
            //05.17.2019 <<
            "Service_Center__r": { "Id": serviceCenterId, "Name": serviceCenterName },
			//05.17.2019 >>
            "Tax_Group__c": "TX"
        };
        var data = component.get("v.data");
        data.push(row);
        component.set("v.data", data);
    },
    saveData : function(component, event) {
        var tmId = component.get("v.tmId");
        var data = component.get("v.data");
        var dataCopy = JSON.parse(JSON.stringify(data)); //make a copy of data
		
        var params = { "data": JSON.stringify(dataCopy) };
        this.callServerMethod(component, event, "c.saveTMLines", params, function(data){
            this.getData(component, event, false);
            this.showToast(component, 'success', 'T&M', 'Changes saved!', 'dismissable');
        });
    },
    confirmDeleteLine : function(component, event) {
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
            this.showToast(component, 'info', 'Delete', 'The line is marked for deletion. you need to save before leaving this page.', 'dismissable');
        }
        component.set("v.data", data);
    },
    confirmDeleteLines : function(component, event) {
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
            this.showToast(component, 'info', 'T&M', 'The lines are marked for deletion. Please save before leaving this page.', 'dismissable');
        }
        component.set("v.data", data);
    },
    confirmRefresh : function(component, event) {
        var pendingChangesStatus = component.get("v.pendingChangesStatus");
        if (pendingChangesStatus == 'Pending_Changes') {
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
})