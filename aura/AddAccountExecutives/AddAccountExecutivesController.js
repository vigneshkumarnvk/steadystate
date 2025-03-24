({
    doInit : function(component,event,helper){
        var recordId = component.get("v.recordId");
        if(recordId){
            var action = component.get("c.getAccountExecutives");
            // Set the parameters for the Apex method
            action.setParams({
                "accountId": recordId
            });
            
            // Set callback
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set("v.accountExecutives",response.getReturnValue())
                    console.log("From server: " + response.getReturnValue());
                } else {
                    console.error("Failed with state: " + state);
                }
            });
            
            // Send action to server
            $A.enqueueAction(action);
        }
    },
    
    handleSectionToggle: function(component, event, helper) {
        // Handle any specific behavior when the section is toggled
        var openSections = event.getParam('openSections');
        console.log('Open sections: ' + openSections);
    },
    
    handleAccountExecutiveChange : function(component, event, helper) {
        
        var recordcount = 0;
        component.set("v.pillValues",true)
        var selectedExecutiveId = '';
        var record = event.getParam("records");
        if(record){
            if(record.length > 0){
                
                
                for (var i = 0; i< record.length; i++) {
                    recordcount++;
                    selectedExecutiveId = selectedExecutiveId == '' ? record[i].Id : selectedExecutiveId + ',' + record[i].Id ;
                }    
                component.set("v.recordCount",recordcount)
            }
        }
        component.set("v.selectedExecutiveId",selectedExecutiveId);
    },
    
    
    handleClickSave: function(component, event, helper) {
        
        var recordId = component.get("v.recordId");        
        var selectedIds = component.get("v.selectedExecutiveId");        
        if(selectedIds){            
            var action = component.get("c.addMultipleAccountExecutives");
            // Set the parameters for the Apex method
            action.setParams({
                "AccountId": recordId,
                "AccountExecutiveIds": selectedIds
            });
            
            // Set callback
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    
                    console.log("From server: " + response.getReturnValue());
                    //window.location.reload();
                    $A.get('e.force:refreshView').fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "Record Updated Successfully.",
                        "type": "success"
                    });
                    toastEvent.fire();
                    component.set("v.pillValues",false);
                } else {
                    console.error("Failed with state: " + state);
                }
            });
            
            // Send action to server
            $A.enqueueAction(action);            
        }else{            
            var action = component.get("c.addMultipleAccountExecutives");
            action.setParams({
                "AccountId": recordId,
                "AccountExecutiveIds": null
                
            });
            
            // Set callback
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    
                    console.log("From server: " + response.getReturnValue());
                    $A.get('e.force:refreshView').fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "message": "Record Updated Successfully.",
                        "type": "success"
                    });
                    toastEvent.fire();
                    component.set("v.pillValues",false);
                } else {
                    console.error("Failed with state: " + state);
                }
            });
            
            // Send action to server
            $A.enqueueAction(action);
        }        
    },    
})