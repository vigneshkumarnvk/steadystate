({
    doInit : function(component, event, helper) {
        var worksheetLine = component.get("v.tmLine");
         helper.getValidUOM1(component, worksheetLine.EQAI_Bill_Unit_Code__c, function(uomList) {
                console.log('uomList+++++++++++++++++', uomList);                
                if (uomList.length === 1) {
                    console.log('Single UOM:', uomList[0]);   
                    component.set("v.uomItems", "'" + uomList[0] + "'");  
                } else if (uomList.length > 1) {
                    let formattedValue = uomList.map(uom => "'" + uom + "'").join(",");
                    console.log("Multiple UOMs available:", formattedValue);
                    component.set("v.uomItems", formattedValue);  // Set as string, not array
                }
                // Fire the TMLine Update Event after UOM is set
                component.set("v.tmLine", tmLine);
               
            });
         
    },
    handleResourceChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");        
        var record = event.getParam("record");
        tmLine.Unit_of_Measure__c = null;
        tmLine.Unit_of_Measure__r = null;
        if (record) {
            tmLine.Resource__c = record.Id;
            tmLine.Description__c = record.Description__c;
            if(tmLine.Approval_Id__c == null)
            {
                tmLine.Unit_of_Measure__c = record.Unit_of_Measure__c;
            	tmLine.Unit_of_Measure__r = record.Unit_of_Measure__r;   
            }
                      
        }
        else {
            tmLine.Resource__c = null;
            tmLine.Description__c = null;
            tmLine.Unit_of_Measure__c = null;
            tmLine.Unit_of_Measure__r = null;
        }
        
        //Ticket#19594 >>
        tmLine.Contract_Line__c = null;
        tmLine.Quote_Line__c = null;
        tmLine.Sales_Line__c = null;
        //Ticket#19594 <<
        
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component, event);
    },
    handleUnitOfMeasureChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        var record = event.getParam("record");      
        if (record != null) {           
           
            tmLine.Unit_of_Measure__c = record.Unit_of_Measure__c;
            tmLine.Unit_of_Measure__r = record.Unit_of_Measure__r;          
        }
        else {            
            tmLine.Unit_of_Measure__c = null;
            tmLine.Unit_of_Measure__r = null;
        }
        tmLine.Contract_Line__c = null;
        tmLine.Quote_Line__c = null;
        tmLine.Sales_Line__c = null;
        //Ticket#19594 <<        
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component, event);
    },
    handleFacilityChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        var record = event.getParam("record");
         tmLine.Profile_Id__c  = null;
         tmLine.Approval_Id__c = null;
         tmLine.Description__c = null;
         tmLine.Unit_of_Measure__r = null;
         tmLine.Unit_of_Measure__c = null;
         tmLine.EQAI_Bill_Unit_Code__c = null;
        if (record != null) {
            tmLine.Facility__c = record.Id;
        }
        else {
            tmLine.Facility__c = null;
        }
        
        //Ticket#19594 >>
        tmLine.Contract_Line__c = null;
        tmLine.Quote_Line__c = null;
        tmLine.Sales_Line__c = null;
        //Ticket#19594 <<
        
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component, event);
    },
    doDelete : function(component, event, helper) {
        helper.fireTMLineDeleteEvent(component, event);
    },
    doCopyManifest : function(component, event, helper) {
        var rowIndex = component.get("v.rowIndex");
        var copyManifestEvent = component.getEvent("copyManifestEvent");
        copyManifestEvent.setParams({ "rowIndex": rowIndex });
        copyManifestEvent.fire();
    },
    handleApprovalChange : function(component, event, helper) {
        var record = event.getParam("record");
        var tmLine = component.get("v.tmLine");        
        tmLine.Unit_of_Measure__c = null;
        tmLine.Unit_of_Measure__r = null;
        if (record) {          
            tmLine.Profile_Id__c  = record.ProfileID;
            tmLine.Approval_Id__c = record.Approval;
            tmLine.Description__c = record.Description; 
            tmLine.EQAI_Bill_Unit_Code__c = record.UOM;//US129137 
                    
            helper.getValidUOM1(component, record.UOM, function(uomList) {
                console.log('uomList+++++++++++++++++', uomList);                
                if (uomList.length === 1) {
                    console.log('Single UOM:', uomList[0]);   
                    component.set("v.uomItems", "'" + uomList[0] + "'");  
                } else if (uomList.length > 1) {
                    let formattedValue = uomList.map(uom => "'" + uom + "'").join(",");
                    console.log("Multiple UOMs available:", formattedValue);
                    component.set("v.uomItems", formattedValue);  // Set as string, not array
                }
                // Fire the TMLine Update Event after UOM is set
                component.set("v.tmLine", tmLine);
               
            });
        } else {
            tmLine.Profile_Id__c  = null;
            tmLine.Approval_Id__c = null;
            tmLine.Description__c = null; 
            tmLine.EQAI_Bill_Unit_Code__c = null; //US129137
            component.set("v.tmLine", tmLine);
           // helper.fireTMLineUpdateEvent(component);            
        }
        $A.getCallback(function() {
   			 helper.fireTMLineUpdateEvent(component);
		});
    },
    handleManifestChange : function(component, event, helper) {
        var record = event.getParam("record");
        var tmLine = component.get("v.tmLine");
        if (record) {
            tmLine.BOL_Manifest__c  = record.Manifest;
        } else {
            tmLine.BOL_Manifest__c  = null;
        }
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component);  
    },
    handleComponentEvent : function(component, event, helper) {
        var valueFromChild = event.getParam("message");
        console.log('valueFromChild'+JSON.stringify(valueFromChild));
        var tmLine = component.get("v.tmLine");
        if (valueFromChild) {
            tmLine.BOL_Manifest__c  = valueFromChild.Manifest;
        } else {
            tmLine.BOL_Manifest__c  = null;
        }
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component);
    }
})