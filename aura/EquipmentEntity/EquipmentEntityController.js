({
    doInit : function(component, event, helper) {
        var data = component.get("v.data");
        if (data) {
            component.set("v.expanded", data.Id == null);
        }
    },
    handleResourceTypeChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.data.Resource_Type__c", record.Id);
            component.set("v.data.ResourceTypeName", record.Name);
            component.set("v.data.Description__c", record.Name);
            component.set("v.data.Unit_of_Measure__c", record.Unit_of_Measure__c);
            component.set("v.data.Unit_of_Measure__r", record.Unit_of_Measure__r);
            if (record.Unit_of_Measure__r != null) {
                component.set("v.data.UnitOfMeasureName", record.Unit_of_Measure__r.Name);
            }
            else {
                component.set("v.data.UnitOfMeasureName", null);
            }
        }
        else {
            var resourceLookup = component.find("resourceLookup");
            component.set("v.data.Resource_Type__c", null);
            component.set("v.data.ResourceTypeName", null);
            component.set("v.data.Resource__c", null);
            component.set("v.data.Resource_Name__c", null);
            component.set("v.data.ResourceName", null);
            component.set("v.data.Description__c", null);
            component.set("v.data.Unit_of_Measure__c", null);
            component.set("v.data.Unit_of_Measure__r", null);
            component.set("v.data.UnitOfMeasureName", null);
        }
    },
    handleServiceCenterChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.data.Service_Center__c", record.Id);
            component.set("v.data.ServiceCenterName", record.Name);
        }
        else {
            component.set("v.data.Service_Center__c", null);
            component.set("v.data.ServiceCenterName", null);
        }

        var resourceLookup = component.find("resourceLookup");
        component.set("v.data.Resource__c", null);
        component.set("v.data.Resource_Name__c", null);
        component.set("v.data.ResourceName", null);
    },
    handleResourceChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.data.Resource__c", record.Id);
            component.set("v.data.Resource_Name__c", record.Description__c);
            component.set("v.data.ResourceName", record.Description__c);
            //06.17.2019 <<
            component.set("v.data.Service_Center__c", record.Service_Center__c);
            component.set("v.data.Service_Center__r", record.Service_Center__r);
            if (component.get("v.data.Resource_Type__c") == null) {
                component.set("v.data.Resource_Type__c", record.Resource_Type__c);
                component.set("v.data.Resource_Type__r", record.Resource_Type__r);
                if (record.Resource_Type__r != null) {
                    component.set("v.data.Unit_of_Measure__c", record.Resource_Type__r.Unit_of_Measure__c);
                    component.set("v.data.Unit_of_Measure__r", record.Resource_Type__r.Unit_of_Measure__r);
                    if (record.Resource_Type__r.Unit_of_Measure__r != null) {
                        component.set("v.data.UnitOfMeasureName", record.Resource_Type__r.Unit_of_Measure__r.Name);
                    }
                    else {
                        component.set("v.data.UnitOfMeasureName", null);
                    }
                }
                else {
                    component.set("v.data.UnitOfMeasureName", null);
                }
            }
            //06.17.2019 >>
        }
        else {
            component.set("v.data.Resource__c", null);
            component.set("v.data.Resource_Name__c", null);
            component.set("v.data.ResourceName", null);
        }
    },
    handleLaborLineChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.data.Linked_Line__c", record.Id);
            component.set("v.data.Site_Start_Time__c", helper.integerToTime(record.Site_Start_Time__c));
            component.set("v.data.Job_Start_Time__c", helper.integerToTime(record.Job_Start_Time__c));
            component.set("v.data.Job_End_Time__c", helper.integerToTime(record.Job_End_Time__c));
            component.set("v.data.Site_End_Time__c", helper.integerToTime(record.Site_End_Time__c));
            //Ticket#19393
            //component.set("v.data.Quantity__c", record.Quantity__c);
            //component.set("v.data.Unit_of_Measure__c", record.Unit_of_Measure__c);
            //component.set("v.data.Unit_of_Measure__r", record.Unit_of_Measure__r);
        }
        else {
            component.set("v.data.Linked_Line__c", null);
            component.set("v.data.Site_Start_Time__c", null);
            component.set("v.data.Job_Start_Time__c", null);
            component.set("v.data.Job_End_Time__c", null);
            component.set("v.data.Site_End_Time__c", null);
            component.set("v.data.Quantity__c", null);
        }
    },
    handleJobStartTimeFocus : function(component, event, helper) {
        if (!component.get("v.data.Job_Start_Time__c")) {
            //set time position
            component.set("v.data.Job_Start_Time__c", component.get("v.lastEnteredTime"));
            setTimeout(function(){
                component.set("v.data.Job_Start_Time__c", null);
            }, 1);
        }
    },
    handleJobStartTimeChange : function(component, event, helper) {
        component.set("v.lastEnteredTime", component.get("v.data.Job_Start_Time__c"));
    },
    handleJobEndTimeFocus : function(component, event, helper) {
        if (!component.get("v.data.Job_End_Time__c")) {
            component.set("v.data.Job_End_Time__c", component.get("v.lastEnteredTime"));
            setTimeout(function(){
                component.set("v.data.Job_End_Time__c", null);
            }, 1);
        }
    },
    handleJobEndTimeChange : function(component, event, helper) {
        component.set("v.lastEnteredTime", component.get("v.data.Job_End_Time__c"));
    },
    doScanResource : function(component, event, helper) {
        helper.scanResource(component, event);
    },
    handleScanComplete : function(component, event, helper) {
        var data = component.get("v.data");
        var resourceTypeId = data.Resource_Type__c;
        //alert(event.getSource().getLocalId() + ', ' + resourceTypeId);
        var barcode = event.getParam("barcode");
        if (barcode != '') {
            helper.getResource(component, event, barcode);
        }
    },
    doJobStartTimeChange : function(component, event, helper) {
        var jobStartTime = event.getParam("value");
        var jobEndTime = component.get("v.data.Job_End_Time__c");
        if (!helper.validateTimeFields(component, jobStartTime, jobEndTime)) {
            component.set("v.data.Job_Start_Time__c", null);
        }
    },
    doJobEndTimeChange : function(component, event, helper) {
        var jobStartTime = component.get("v.data.Job_Start_Time__c");
        var jobEndTime = event.getParam("value");
        if (!helper.validateTimeFields(component, jobStartTime, jobEndTime)) {
            component.set("v.data.Job_End_Time__c", null);
        }
    },
    doPendingChangesStatus : function(component, event, helper) {
        var pendingChangesStatus = component.get("v.pendingChangesStatus");

        if (pendingChangesStatus != null) { // && pendingChangesStatus != 'Pending_Changes') {
            component.set("v.pendingChangesStatus", 'Pending_Changes_Dummy_Status'); //change status values to trigger event
            component.set("v.pendingChangesStatus", 'Pending_Changes');
        }
    },
    doDelete : function(component, event, helper) {
        var tmlId = component.get("v.tmlId");
        var lineIndex = component.get("v.lineIndex")
        var deleteEvent = component.getEvent("deleteTMLineEvent");
        deleteEvent.setParams({
            "recordId": tmlId,
            "lineIndex": lineIndex
        });
        deleteEvent.fire();
    },
    doCopyTime : function(component, event, helper) {
        var tmlId = component.get("v.tmlId");
        var lineIndex = component.get("v.lineIndex")
        var copyTimeEvent = component.getEvent("copyTimeEvent");
        copyTimeEvent.setParams({
            "recordId": tmlId,
            "lineIndex": lineIndex,
        });
        copyTimeEvent.fire();
    },
    toggleDetail : function(component, event, helper) {
        var card = component.find("card");
        $A.util.removeClass(card, "slds-card__header");
        var state = component.get("v.expanded");
        component.set("v.expanded", !state);

        $A.util.addClass("card", "slds-card__header");
    },
    expand : function(component, event, helper) {
        component.set("v.expanded", true);
    },
    collapse : function(component, event, helper) {
        component.set("v.expanded", false);
    }
})