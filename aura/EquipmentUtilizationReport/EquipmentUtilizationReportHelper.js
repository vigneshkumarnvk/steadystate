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
				//component.set("v.serviceCenters", response.getReturnValue());   
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
    
    getFilters : function(component){
		// Get filter values
        var selected = component.find("serviceCenterFilter").get("v.value");        
        var startDate = component.find("startDateFilter").get("v.value");  
        var endDate = component.find("endDateFilter").get("v.value");  
        
        // Validate if the start date is before the end date
        if(startDate > endDate){
        	var title = "Error";
            var message = "The start date must be before the end date!";
            this.showToast(title, message);   
        } else {
        	this.getTMEquipLines(component,selected,startDate,endDate); 
        }        
    },   
    
    getTMEquipLines : function(component, svcCenter, startDate, endDate) {      
        console.log('@@startDate: ' + startDate);
        console.log('@@endDate: ' + endDate);
        var action = component.get('c.getTMEquipLines');
        action.setParams({  ServiceCenter : svcCenter, startDate : startDate, endDate : endDate});
        action.setCallback(this, function (response) {
            var state = response.getState();
            
            if (state === 'SUCCESS') {
                component.set("v.spinner", false);
				component.set("v.equipments", response.getReturnValue());                
                //component.set("v.maxPage", Math.floor((component.get("v.equipments").length+9)/component.get("v.recordsToshow")));

                var recordsLength = component.get("v.equipments").length;
                var recordPerPage = component.get("v.recordsToshow");
                var numOfPagesNeeded = recordsLength / recordPerPage;
                if(numOfPagesNeeded <= 1){
                    numOfPagesNeeded = 1;
                } else {
                    if((recordsLength % recordPerPage) === 0){
                        numOfPagesNeeded = recordsLength / recordPerPage;
                    } else {
                        numOfPagesNeeded = Math.floor(recordsLength / recordPerPage) + 1;
                    }
                }

                console.log('@@ numOfPagesNeeded ' + numOfPagesNeeded);
                component.set("v.maxPage", numOfPagesNeeded);
                //console.log('@@v.equipments.length ' + component.get("v.equipments").length);
                //console.log('@@v.equipments.length math floor ' + Math.floor((component.get("v.equipments").length+9)/component.get("v.recordsToshow")));
                //console.log('@@v.recordsToshow ' + component.get("v.recordsToshow"));
                //console.log('@@v.maxPage' + component.get("v.maxPage"));
                /*
                if(component.get("v.equipments").length > 0 && Number(component.get("v.maxPage")) == 0) {
                    component.set("v.maxPage", 1);
                }
                 */

                this.renderPage(component);
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
	renderPage: function(component) {
        var equipments = component.get("v.equipments"),
            pageNumber = component.get("v.pageNumber"),
            pageRecords = equipments.slice((pageNumber-1)*component.get("v.recordsToshow"), pageNumber*component.get("v.recordsToshow"));
        component.set("v.currentEquipmentsArray", pageRecords);
        console.log(pageNumber);
    }    
})