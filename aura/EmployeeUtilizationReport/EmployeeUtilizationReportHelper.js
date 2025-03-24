({
    getDefaultStartDate : function(component) {
        var action = component.get('c.getLastWeekFirstDate');
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
				component.find("startDateFilter").set("v.value", response.getReturnValue());
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
					this.errorsHandler(errors);
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);      
    },
    
    getDefaultEndDate : function(component) {
        var action = component.get('c.getLastWeekLastDate');
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
				component.find("endDateFilter").set("v.value", response.getReturnValue());
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
					this.errorsHandler(errors);
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);      
    },
    
    getServiceCenters : function(component) {
        var action = component.get('c.getServiceCenters');
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
				component.set("v.serviceCenters", response.getReturnValue());  
                
                var scList = [];
                var scObj;
                
                for(var i = 0; i < response.getReturnValue().length; i++) {
                    scObj = new Object();
                    scObj["value"] = response.getReturnValue()[i].Id;
                    scObj["label"] = response.getReturnValue()[i].Description;
                    if(response.getReturnValue()[i].isDefault){
                        scObj["selected"] = "true";
                    }
                    
                    scList.push(scObj);
                }
                component.find("serviceCenterFilter").set("v.options", scList);
                //component.find("serviceCenterFilter").set("v.options", response.getReturnValue());
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
					this.errorsHandler(errors);
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);		
	},
    
    getTMLaborLines : function(component, svcCenter, startDate, endDate,checkbox) {      
        console.log('@@startDate: ' + startDate);
        console.log('@@endDate: ' + endDate);
        var action = component.get('c.getTMLaborLines');
        action.setParams({  ServiceCenter : svcCenter, startDate : startDate, endDate : endDate, includeWeekend : checkbox  });
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
				component.set("v.employees", response.getReturnValue());                
            } else if (state === 'ERROR') {
                component.set("v.spinner", false);
                var errors = response.getError();
                if (errors) {
					this.errorsHandler(errors);
                } else {
                    this.unknownErrorsHandler();
                }
            }
        });
        $A.enqueueAction(action);
	},
    
    getFilters : function(component){
		// Get filter values
        var selected = component.find("serviceCenterFilter").get("v.value");        
        var startDate = component.find("startDateFilter").get("v.value");  
        var endDate = component.find("endDateFilter").get("v.value");  
        var checkbox = component.find("includeWeekendFilter").get("v.value");
        
        // Validate if the start date is before the end date
        if(startDate > endDate){
        	var title = "Error";
            var message = "The start date must be before the end date!";
            this.showToast(title, message);   
        } else {
        	this.getTMLaborLines(component,selected,startDate,endDate,checkbox); 
        }        
    },
    
    errorsHandler : function(errors){
        if (errors[0] && errors[0].message) {
            console.log('Error message: ' + errors[0].message);
            this.showToast('Error', errors[0].message);
    	}
	},
 
    unknownErrorsHandler : function(){
        console.log('Unknown error');
    	this.showToast('Error', 'Unknown error'); 
    },
    
	showToast : function(title, message,type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type
        });
        toastEvent.fire();
    },
    
    updateTableResult: function(component, event, helper) {
        var id = component.get("v.id");
        var container = component.find("container");
        $A.createComponent("force:recordView",
                           {recordId: id,type: "MINI"},
                           function(cmp) {
                               container.set("v.body", [cmp]);
                           });
    }    
})