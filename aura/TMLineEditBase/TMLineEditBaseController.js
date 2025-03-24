({
    doInitite: function(component, event, helper) {
		 var tmLine = component.get("v.tmLine");
        // Fetch valid UOMs based on the Bill Unit Code

         helper.getValidUOMs(component, tmLine.EQAI_Bill_Unit_Code__c, function(uomList) {
                console.log('uomList+++++++++++++++++', uomList); 
                if (uomList.length === 1) {
                    console.log('Single UOM:', uomList[0]);                   
                    component.set("v.uomItems", "'" + uomList[0] + "'");  

                } else if (uomList.length > 1) {
                    let formattedValue = uomList.map(uom => "'" + uom + "'").join(",");
                    component.set("v.uomItems", formattedValue); 
                    console.log("Multiple UOMs available:", formattedValue);
                }
            });
	},
    viewLine : function(component, event, helper) {
        helper.fireTMLineViewEvent(component, event);
    },
    copyTime : function(component, event, helper) {
        helper.fireTMLineCopyTimeEvent(component, event);
    },
    deleteLine : function(component, event, helper) {
        helper.fireTMLineDeleteEvent(component, event);
    },
    /*
    handleJobTaskChange : function(component, event, helper) {
        var jobTaskLineNo = component.get("v.tmLine.TM_Job_Task__r.Line_No__c");
        var jobTask = { "Line_No__c": jobTaskLineNo };
        helper.fireTMLinesMoveEvent(component, event, jobTask);
    },*/
    handleResourceTypeChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        var record = event.getParam("record");
        if(tmLine.Category__c == 'Labor' || tmLine.Category__c == 'Equipment' || tmLine.Category__c == 'Bundled') {
            tmLine.Contract_Line__c = null;
            tmLine.Contract_Line__r = null;
            tmLine.Quote_Line__c = null;
            tmLine.Sales_Line__c = null;
        }
        if (record != null) {
            tmLine.Resource_Type__c = record.Id;
            tmLine.Description__c = record.Description__c;
            /* Ticket#19394
            tmLine.Resource__c = null;
            tmLine.Resource__r = null;
            tmLine.Resource_Name__c = null;
             */

            /*
            if (tmLine.Unit_of_Measure__c == null) {
                if (record.Unit_of_Measure__r != null) {
                    tmLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
                    tmLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
                }
            }
            */
            if (tmLine.Category__c === 'Equipment') {
                helper.calculateFleetNotRequired(tmLine);
            }
            component.set("v.tmLine", tmLine);

            var calls = [];
            calls.push(helper.validateResourceType.bind(helper, component, event));
            //calls.push(helper.fireTMLineUpdateEvent.bind(helper, component, 'Resource_Type__c'));
            //ticket 19130 <<
            //calls.push(helper.fireTMLineUpdateEvent.bind(helper, component)); //child resource check fires when T&M is confirmed
            calls.push(helper.fireTMLineUpdateEvent.bind(helper, component, 'Resource_Type__c'));//
            //ticket 19130 >>
            helper.makeStackedCalls(component, event, helper, calls);
        }
        else {
            tmLine.Resource_Type__c = null;
            tmLine.Description__c = null;
            /* Ticket#19394
            tmLine.Resource__r = null;
            tmLine.Resource__c = null;
            tmLine.Resource_Name__c = null;
             */
            tmLine.Fleet_No_Required__c = false;
            tmLine.Contract_Line__c = null;
            tmLine.Contract_Line__r = null;
            component.set("v.tmLine", tmLine);
            //helper.fireTMLineUpdateEvent(component, "Resource_Type__c");
            helper.fireTMLineUpdateEvent(component); //child resource check fires when T&M is confirmed
        }
    },
    handleResourceChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        var record = event.getParam("record");
        tmLine.Cost_Method__c = null;
        tmLine.Unit_Weight_Vol__c = null;
        tmLine.Unit_Weight_Vol__r = null;
        tmLine.Container_Size__c = null;
        tmLine.Container_Size__r = null;
        tmLine.Unit_of_Measure__c = null;
        tmLine.Unit_of_Measure__r = null;
        //tmLine.Facility__c = null;
        //tmLine.Facility__r = null;
        //US137007
        //tmLine.Profile_Id__c = null;
        //tmLine.Approval_Id__c = null;
        if(tmLine.Category__c != 'Labor' && tmLine.Category__c != 'Equipment' && tmLine.Category__c != 'Bundled') {
            tmLine.Contract_Line__c = null;
            tmLine.Contract_Line__r = null;
            tmLine.Quote_Line__c = null;
            tmLine.Sales_Line__c = null;
        }
        if (record) {
            tmLine.Resource__c = record.Id;
            if (tmLine.Category__c === 'Labor' || tmLine.Category__c === 'Equipment') {
                tmLine.Resource_Name__c = record.Description__c;
                tmLine.Service_Center__c = record.Service_Center__c;
                tmLine.Service_Center__r = record.Service_Center__r;

                if (!tmLine.Resource_Type__c && record.Resource_Type__r) {
                    tmLine.Resource_Type__c = record.Resource_Type__c;
                    tmLine.Resource_Type__r = record.Resource_Type__r;
                    tmLine.Description__c = record.Resource_Type__r.Description__c;
                }

                if (!tmLine.Unit_of_Measure__c && tmLine.Approval_Id__c == null) {
                    if (record.Resource_Type__r && record.Resource_Type__r.Unit_of_Measure__r) {
                        tmLine.Unit_of_Measure__c = record.Resource_Type__r.Unit_of_Measure__c;
                        tmLine.Unit_of_Measure__r = record.Resource_Type__r.Unit_of_Measure__r;
                    }
                }
            }
            else {
                if(tmLine.Profile_Id__c == null){
                    tmLine.Description__c = record.Description__c;
                }
            }

            /*
            if (tmLine.Unit_of_Measure__c == null) {
                if (record.Unit_of_Measure__r != null) {
                    tmLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
                    tmLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
                }
            }
            */

            if (tmLine.Category__c === 'Equipment') {
                tmLine.Fleet_No__c = record.Name;
            }
            component.set("v.tmLine", tmLine);

            var calls = [];
            calls.push(helper.validateResource.bind(helper, component, event));
            //calls.push(helper.fireTMLineUpdateEvent.bind(helper, component, 'Resource__c'));
            //ticket 19130 <<
            //calls.push(helper.fireTMLineUpdateEvent.bind(helper, component)); //child resource check fires when T&M is confirmed
            calls.push(helper.fireTMLineUpdateEvent.bind(helper, component, 'Resource__c'));
            //ticket 19130 >>
            helper.makeStackedCalls(component, event, helper, calls);
        }
        else {
            tmLine.Resource__c = null;
            if (tmLine.Category__c === 'Labor' || tmLine.Category__c === 'Equipment') {
                tmLine.Resource_Name__c = null;
            }
            else {
                if(tmLine.Profile_Id__c == null){
                    tmLine.Description__c = null;
                }
            }
            tmLine.Fleet_No__c = null;
            tmLine.Contract_Line__c = null;
            tmLine.Contract_Line__r = null;
            component.set("v.tmLine", tmLine);
            //helper.fireTMLineUpdateEvent(component, "Resource__c");
            helper.fireTMLineUpdateEvent(component); //child resource check fires when T&M is confirmed
        }
    },
    handleServiceCenterChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        var record = event.getParam("record");
        if (record) {
            tmLine.Service_Center__c = record.Id;

            if (tmLine.Category__c === 'Equipment') {
                helper.calculateFleetNotRequired(tmLine);
            }
        }
        else {
            tmLine.Service_Center__c = null;
        }
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component);
    },
    handleUnitOfMeasure1Change : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        var record = event.getParam("record");
        tmLine.Quantity__c = 0;
        tmLine.Contract_Line__c = null;
        tmLine.Contract_Line__r = null;
        tmLine.Quote_Line__c = null;
        tmLine.Sales_Line__c = null;

        if (record) {
            tmLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
            tmLine.Unit_of_Measure__r = record.Unit_of_Measure__r;

            if (tmLine.Category__c === 'Labor' || tmLine.Category__c === 'Equipment') {
                if (tmLine.Unit_of_Measure__r.Hours_UOM__c === true) {
                    if(tmLine.Category__c === 'Labor'){
                        tmLine.Quantity__c = tmLine.Total_Job_Hours__c - helper.calculateLunchHours(tmLine);
                    } else {
                        tmLine.Quantity__c = tmLine.Total_Job_Hours__c;
                    }
                } else {
                    tmLine.Quantity__c = 1;
                }
            }
            component.set("v.tmLine", tmLine);

            var calls = [];
            calls.push(helper.validateUnitOfMeasure.bind(helper, component, event));
            calls.push(helper.fireTMLineUpdateEvent.bind(helper, component));
            helper.makeStackedCalls(component, event, helper, calls);
        }
        else {
            tmLine.Unit_of_Measure__c = null;
            component.set("v.tmLine", tmLine);
            helper.fireTMLineUpdateEvent(component);
        }
    },
    handleUnitOfMeasure3Change : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        var record = event.getParam("record");
        //tmLine.Quantity__c = 0; //Ticket#22286
        tmLine.Contract_Line__c = null;
        tmLine.Contract_Line__r = null;
        tmLine.Quote_Line__c = null;
        tmLine.Sales_Line__c = null;
        
        if (record) {
            tmLine.Unit_of_Measure__c = record.Id;

            if (tmLine.Category__c === 'Labor' || tmLine.Category__c === 'Equipment') {
                if (tmLine.Unit_of_Measure__r.Hours_UOM__c === true) {
                    if(tmLine.Category__c === 'Labor'){
                        tmLine.Quantity__c = tmLine.Total_Job_Hours__c - helper.calculateLunchHours(tmLine);
                    } else {
                        tmLine.Quantity__c = tmLine.Total_Job_Hours__c;
                    }
                } else {
                    tmLine.Quantity__c = 1;
                }
            }
            component.set("v.tmLine", tmLine);

            var calls = [];
            calls.push(helper.validateUnitOfMeasure.bind(helper, component, event));
            calls.push(helper.fireTMLineUpdateEvent.bind(helper, component));
            helper.makeStackedCalls(component, event, helper, calls);
        }
        else {
            tmLine.Unit_of_Measure__c = null;
            component.set("v.tmLine", tmLine);
            helper.fireTMLineUpdateEvent(component);
        }
    },
    handleJobTimeChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        var jobHours = helper.calculateJobHours(tmLine);
        tmLine.Total_Job_Hours__c = jobHours;
        if (tmLine.Unit_of_Measure__r) {
            if (tmLine.Unit_of_Measure__r.Hours_UOM__c === true) {
                if(tmLine.Category__c === 'Labor'){
                    //Ticket#24285 >>
                    let lunchHr = helper.calculateLunchHours(tmLine);
                    tmLine.Quantity__c = tmLine.Total_Job_Hours__c - lunchHr;
                    if(lunchHr === 0 && tmLine.Job_Start_Time__c === tmLine.Site_Start_Time__c && tmLine.Site_Start_Time__c === tmLine.Site_End_Time__c && tmLine.Site_End_Time__c === tmLine.Job_End_Time__c){
                        tmLine.Total_Job_Hours__c = 0;
                        tmLine.Quantity__c = 0;
                    }
                    //tmLine.Quantity__c = tmLine.Total_Job_Hours__c - helper.calculateLunchHours(tmLine);
                    //Ticket#24285 <<
                } else {
                    tmLine.Quantity__c = tmLine.Total_Job_Hours__c;
                }
            } else {
                tmLine.Quantity__c = 1;
            }
        }
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component);
    },
    handleSiteTimeChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        var siteHours = helper.calculateSiteHours(tmLine);
        var lunchHours = helper.calculateLunchHours(tmLine);
        //Ticket#16848 >>
        if(tmLine.Site_Start_Time__c === tmLine.Site_End_Time__c){
            tmLine.Total_Site_Hours__c = 0;
        } else {
            tmLine.Total_Site_Hours__c = siteHours;
        }
        //Ticket#16848 <<
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component);
    },
    handleLunchTimeChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        var jobHours = helper.calculateJobHours(tmLine);
        var siteHours = helper.calculateSiteHours(tmLine);
        var lunchHours = helper.calculateLunchHours(tmLine);
        tmLine.Total_Job_Hours__c = jobHours;
        if(tmLine.Category__c === 'Labor' && tmLine.Unit_of_Measure__r.Hours_UOM__c === true){
            tmLine.Quantity__c = tmLine.Total_Job_Hours__c - lunchHours;
        }
        //Ticket#24285 >>
        if(lunchHours === 0 && tmLine.Site_Start_Time__c === tmLine.Job_Start_Time__c && tmLine.Site_Start_Time__c === tmLine.Site_End_Time__c && tmLine.Site_End_Time__c === tmLine.Job_End_Time__c){
            tmLine.Total_Job_Hours__c = 0;
            tmLine.Quantity__c = 0;
        } else {
            tmLine.Total_Job_Hours__c = jobHours;
        }
        //tmLine.Total_Job_Hours__c = jobHours;
        //Ticket#24285 <<
        //Ticket#16848 >>
        if(tmLine.Site_Start_Time__c === tmLine.Site_End_Time__c){
            tmLine.Total_Site_Hours__c = 0;
        } else {
            tmLine.Total_Site_Hours__c = siteHours;
        }
        //Ticket#16848 <<
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component);
    },
    //ticket 25570 <<
    handleQuantityChange : function (component, event, helper) {
        helper.fireTMLineUpdateEvent(component);
    },
    handleDescriptionChange : function (component, event, helper) {
        helper.fireTMLineUpdateEvent(component);
    },
    //ticket 25570 >>
    //non-billable flag from TM line <<
    handleNonBillableChange : function(component, event, helper) {
        helper.fireTMLineUpdateEvent(component);
    },
    //non-billable flag from TM line >>
    validateFields : function(component, event, helper) {
        return helper.validateFields(component, event);
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
            tmLine.EQAI_Bill_Unit_Code__c = record.UOM;
            
            //US129137
            helper.getValidUOMs(component, tmLine.EQAI_Bill_Unit_Code__c, function(uomList) {
                if (uomList.length === 1) {
                    console.log('Single UOM:', uomList[0]);                   
                    component.set("v.uomItems", "'" + uomList[0] + "'");  
                   
                } else if (uomList.length > 1) {
                    let formattedValue = uomList.map(uom => "'" + uom + "'").join(",");
                    component.set("v.uomItems", formattedValue); 
                    console.log("Multiple UOMs available:", formattedValue);
                }
            });
           
        } else {
           
            tmLine.Profile_Id__c  = null;
            tmLine.Unit_of_Measure__c = null;
            tmLine.Unit_of_Measure__r = null;//US129137
            tmLine.Approval_Id__c = null;
            tmLine.Description__c = null;
            tmLine.EQAI_Bill_Unit_Code__c = null;
           
           
          // console.log('tmLINE+++++++++++++++'+JSON.stringify(tmLine));
           
        }
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component);
        
    },
       handleManifestChange : function(component, event, helper) {
        var record = event.getParam("record");
        var tmLine = component.get("v.tmLine");
        if (record) {
            tmLine.BOL_Manifest__c  = record.Manifest;
            tmLine.BOL_Manifest_Workorder_Id__c = record.WorkorderId;
            helper.fireTMLineUpdateEvent(component);
        } else {
            tmLine.BOL_Manifest__c  = null;
            tmLine.BOL_Manifest_Workorder_Id__c = null;
            helper.fireTMLineUpdateEvent(component);
        }
            
    },
        handleComponentEvent : function(component, event, helper) {
            var valueFromChild = event.getParam("message");
            console.log('valueFromChild'+JSON.stringify(valueFromChild));
            var tmLine = component.get("v.tmLine");
            if (valueFromChild) {
                tmLine.BOL_Manifest__c  = valueFromChild.Manifest;
                console.log('setting value>>>>>>>>' +tmLine.BOL_Manifest__c);
                helper.fireTMLineUpdateEvent(component);
            } else {
                tmLine.BOL_Manifest__c  = null;
                helper.fireTMLineUpdateEvent(component);
            }
    }
});