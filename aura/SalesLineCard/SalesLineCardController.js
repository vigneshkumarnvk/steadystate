({
    doInit : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        helper.showFields(component, event);
        console.log('in init controller');
        //job task <<
        var salesLines = component.get("v.jobTaskWrapper.SalesLines");
        
        //ticket 19130 <<
        /*
        var parentLineOptions = [];
        for (var i = 0; i < salesLines.length; i++) {
            if (salesLines[i].Parent_Line__r == null && salesLines[i].Line_No__c != salesLine.Line_No__c) {
                parentLineOptions.push({ "label": 'Line #' + salesLines[i].Line_No__c + " - " + salesLines[i].Description__c, "value": salesLines[i].Line_No__c });
            }
        }
        component.set("v.parentLineOptions", parentLineOptions);
        if (salesLine.Parent_Line__r) {
            component.set("v.selectedParentLineNo", salesLine.Parent_Line__r.Line_No__c);
        }*/
        //ticket 19130 >>
        //job ask >>
        
        //ticket 19130 <<
        var childLineNos = [];
        for (var i = 0; i < salesLines.length; i++) {
            var parentLine = salesLines[i];
            if (parentLine.Sales_Child_Lines__r && parentLine.Sales_Child_Lines__r.records) {
                for (var j = 0; j < parentLine.Sales_Child_Lines__r.records.length; j++) {
                    var relation = parentLine.Sales_Child_Lines__r.records[j];
                    if (relation.Child_Line__r) {
                        childLineNos.push(parseInt(relation.Child_Line__r.Line_No__c));
                    }
                }
            }
        }
        
        if (!childLineNos.includes(salesLine.Line_No__c) && salesLine.Is_Child_Resource__c != true && salesLine.System_Calculated_Line__c != true) {
            if (!salesLine.Sales_Child_Lines__r || !salesLine.Sales_Child_Lines__r.records) {
                salesLine.Sales_Child_Lines__r = { "records": []};
            }
            component.set("v.salesLine.Sales_Child_Lines__r", salesLine.Sales_Child_Lines__r);
        }
        
      if(salesLine.EQAI_UOM__c != null) 
      {
          helper.getValidUOMs(component, salesLine.EQAI_UOM__c, function(uomList) {
                if (uomList.length === 1) {
                    console.log('Single UOM:', uomList[0]);                   
                    component.set("v.uomItems", "'" + uomList[0] + "'");  
                   
                } else if (uomList.length > 1) {
                    let formattedValue = uomList.map(uom => "'" + uom + "'").join(",");
                    component.set("v.uomItems", formattedValue); 
                    console.log("Multiple UOMs available:", formattedValue);
                }
              
            }); 
      }
       
        
        //ticket 19130 >>
        var action = component.get("c.getCostPlusMESResourceId");
        action.setCallback(this, function(response) {
            var state = response.getState();
            // console.log(state);
            if (state = "SUCCESS") {
                var resourceId = response.getReturnValue();
                component.set("v.costPlusMESResourceId", resourceId);
            } else {
                console.error("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },
    //job task <<
    //ticket 19130 <<
    /*
    handleParentLineChange : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        var selectedParentLineNo = component.get("v.selectedParentLineNo");
        if (selectedParentLineNo) {
            var salesLines = component.get("v.jobTaskWrapper.SalesLines");
            for (var i = 0; i < salesLines.length; i++) {
                if (salesLines[i].Line_No__c == selectedParentLineNo) {
                    salesLine.Parent_Line__c = salesLines[i].Id;
                    salesLine.Parent_Line__r = { "Id": salesLines[i].Id, "Line_No__c": selectedParentLineNo };
                    break;
                }
            }
        }
        else {
            salesLine.Parent_Line__c = null;
            salesLine.Parent_Line__r = null;
        }
        component.set("v.salesLine", salesLine);
    },
    */
    //ticket 19130 >>
    //job task >>
    /*
    explodeSalesLineDetails : function(component, event, helper) {
        helper.explodeSalesLineDetails(component, event);
    },
    */
    saveSalesLine : function(component, event, helper) {
        helper.saveSalesLine(component, event);
    },
    //job task <<
    handleJobTaskChange : function(component, event, helper) {
        var selectedJobTaskLineNo = event.getSource().get("v.value");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var salesLine = component.get("v.salesLine");
        var jobTasks = component.get("v.jobTasks");
        var jobTask = null;
        for (var i = 0; i < jobTasks.length; i++) {
            if (jobTasks[i].Line_No__c == selectedJobTaskLineNo) {
                jobTask = jobTasks[i];
                break;
            }
        }
        salesLine.Sales_Order_Job_Task__r = jobTask;
        if (jobTask != null) {
            salesLine.Sales_Order_Job_Task__c = jobTask.Id;
        }
        else {
            salesLine.Sales_Order_Job_Task__c = null;
        }
        
        //handle line move
        if (salesLine.Sales_Order_Job_Task__r.Line_No__c != jobTaskWrapper.JobTask.Line_No__c) {
            //handle sales line if itself is a bundled line
            if (salesLine.Bundle_Line__r != null) {
                salesLine.Bundle_Line__r = null;
                salesLine.Bundle_Line__c = null;
                salesLine.Bill_as_Lump_Sum__c = false;
            }
            
            //update detail lines records' job task
            if (salesLine.Sales_Line_Details__r) {
                for (var i = 0; i < salesLine.Sales_Line_Details__r.length; i++) {
                    salesLine.Sales_Line_Details__r[i].Sales_Order_Job_Task__c = salesLine.Sales_Order_Job_Task__c;
                    salesLine.Sales_Line_Details__r[i].Sales_Order_Job_Task__r = salesLine.Sales_Order_Job_Task__r;
                }
            }
            
            if (jobTaskWrapper.SalesLines) {
                for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
                    //handle bundled lines
                    if (jobTaskWrapper.SalesLines[i].Bundle_Line__r && jobTaskWrapper.SalesLines[i].Bundle_Line__r.Line_No__c == salesLine.Line_No__c) {
                        jobTaskWrapper.SalesLines[i].Sales_Order_Job_Task__c = salesLine.Sales_Order_Job_Task__c;
                        jobTaskWrapper.SalesLines[i].Sales_Order_Job_Task__r = salesLine.Sales_Order_Job_Task__r;
                    }
                }
            }
        }
        component.set("v.salesLine", salesLine);
        component.set("v.jobTaskWrapper", jobTaskWrapper);
    },
    //job task >>
    handleCategoryChange : function(component, event, helper) {
        helper.validateCategory(component, event);
    },
    
    handleDisposalBillingChange : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");  
        var unitPrice;
        var xunitPrice;
        var disposalBillingMethod = salesLine.Disposal_Billing_Method__c;
        console.log('Disposal_Billing_Method__c**********'+disposalBillingMethod);
        if(disposalBillingMethod){
            component.set("v.salesLine.Disposal_Billing_Method__c", disposalBillingMethod);
        }
        unitPrice = salesLine.Unit_Price__c;
        xunitPrice = salesLine.xUnit_Price__c;
        if(salesLine.Disposal_Billing_Method__c == 'Direct')
        { 
            
            if(unitPrice != null && unitPrice!=0)
                component.set("v.prvUnitPrice", unitPrice); 
            if(xunitPrice != null && xunitPrice!=0)
                component.set("v.prvxUnitPrice", xunitPrice);
            component.set("v.salesLine.Unit_Price__c", 0);
            component.set("v.salesLine.xUnit_Price__c", 0);
            
        }
        else
        {
            let prvUnitPrice = component.get("v.prvUnitPrice");
            let prvxUnitPrice = component.get("v.prvxUnitPrice");
            if(prvUnitPrice!=null && prvUnitPrice!=0 )              
                component.set("v.salesLine.Unit_Price__c", prvUnitPrice);
            else if(unitPrice != null && unitPrice!=0)
                component.set("v.salesLine.Unit_Price__c", unitPrice); 
            if(prvxUnitPrice!=null && prvxUnitPrice!=0 )              
                component.set("v.salesLine.xUnit_Price__c", prvxUnitPrice); 
            else if(xunitPrice != null && xunitPrice!=0)
                component.set("v.salesLine.xUnit_Price__c", prvxUnitPrice); 
            
        }
    },
    handleResourceTypeChange1 : function(component, event, helper) {
        console.log('handleresourcetypechange1 called');
        // component.set("v.salesLine.Contract_Line__c", null);
        // component.set("v.salesLine.Contract_Line__r", null);
        
        var record = event.getParam("record");
        //ticket 19130 <<
        component.set("v.salesLine.Sales_Child_Lines__r", null);
        //ticket 19130 >>
        if (record) {
            console.log('record exists....');
            component.set("v.salesLine.Resource_Type__c", record.Id);
            component.set("v.salesLine.Resource_Type__r", record);
            component.set("v.salesLine.Unit_of_Measure__c", record.Unit_of_Measure__c);
            component.set("v.salesLine.Unit_of_Measure__r", record.Unit_of_Measure__r);
            component.set("v.salesLine.isContractLineNotEditable__c", false); // Andrew
            helper.validateResourceType(component, event);
        }
        else {
            console.log('record does not exist');
            component.set("v.salesLine.Resource_Type__c", null);
            component.set("v.salesLine.Resource_Type__r", null);
            component.set("v.salesLine.Resource__c", null);
            component.set("v.salesLine.Resource__r", null);
            //job task <<
            component.set("v.salesLine.Description__c", null);
            component.set("v.salesLine.isContractLineNotEditable__c", true);
            component.set("v.salesLine.Pricing_Source_2__c", null);
            component.set("v.salesLine.Contract_Line__c", null);
            component.set("v.salesLine.Contract_Line__r", null);
            console.log(salesLine.Pricing_Source_2__c);
            //ticket 19130 <<
            /*
            component.set("v.salesLine.Parent_Line__c", null);
            component.set("v.salesLine.Parent_Line__r", null);
            */
            //ticket 19130 >>
            //job task >>
            helper.showFields(component, event);
        }
    },
    //ticket 19130 << obsolete
    /*
    handleResourceTypeChange2 : function(component, event, helper) {
        var record = event.getParam("record"); //record =contract line
        if (record) {
            component.set("v.salesLine.Resource_Type__c", record.Resource_Type__r.Id);
            component.set("v.salesLine.Resource_Type__r", record.Resource_Type__r);
            component.set("v.salesLine.Unit_of_Measure__c", record.Unit_of_Measure__c);
            component.set("v.salesLine.Unit_of_Measure__r", record.Unit_of_Measure__r);
            helper.validateResourceType(component, event);
        }
        else {
            component.set("v.salesLine.Resource_Type__c", null);
            component.set("v.salesLine.Resource_Type__r", null);
            component.set("v.salesLine.Resource__c", null);
            component.set("v.salesLine.Resource__r", null);
            //job task <<
            component.set("v.salesLine.Description__c", null);
            component.set("v.salesLine.Parent_Line__c", null);
            component.set("v.salesLine.Parent_Line__r", null);
            //job task >>
            helper.showFields(component, event);
        }
    },
    handleResourceTypeChange3 : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.salesLine.Resource_Type__c", record.Id);
            helper.validateResourceType(component, event);
        }
        else {
            component.set("v.salesLine.Resource_Type__c", null);
            component.set("v.salesLine.Resource__c", null);
            component.set("v.salesLine.Resource__r", null);
            //job task <<
            component.set("v.salesLine.Description__c", null);
            component.set("v.salesLine.Parent_Line__c", null);
            component.set("v.salesLine.Parent_Line__r", null);
            //job task >>
            helper.showFields(component, event);
        }
    },*/
    handleApprovalChange : function(component, event, helper) {
        var record = event.getParam("record");
        var salesLineItem = component.get("v.salesLine");
        
        if (record) {
            component.set("v.uomItems", null);
			salesLineItem.Unit_of_Measure__c = null;
            salesLineItem.Unit_of_Measure__r = null; 
            salesLineItem.Profile_Id__c  = record.ProfileID;
            salesLineItem.Approval_Id__c = record.Approval;
            //US132832
            if(salesLineItem.Contract_Line__r ==null)
                salesLineItem.Description__c = record.Description; 
            	salesLineItem.EQAI_UOM__c = record.UOM;
            
            // console.log('salesLineItem.EQAI_UOM__c',salesLineItem.EQAI_UOM__c)
            // Fetch valid UOMs based on the Bill Unit Code
            helper.getValidUOMs(component, record.UOM, function(uomList) {
                if (uomList.length === 1) {
                    console.log('Single UOM:', uomList[0]);                   
                    component.set("v.uomItems", "'" + uomList[0] + "'");  
                   
                } else if (uomList.length > 1) {
                    let formattedValue = uomList.map(uom => "'" + uom + "'").join(",");
                    component.set("v.uomItems", formattedValue); 
                    console.log("Multiple UOMs available:", formattedValue);
                }
                 console.log("uomItems++++++++++", component.get("v.uomItems"));
            });
            
            
        } else {
            salesLineItem.Profile_Id__c  = null;
            salesLineItem.Approval_Id__c = null;
            //US132832
            if(salesLineItem.Contract_Line__r ==null)
                salesLineItem.Description__c = null;
            salesLineItem.EQAI_UOM__c = null;
            salesLineItem.Unit_of_Measure__c = null;
            salesLineItem.Unit_of_Measure__r = null; 
            
        }
        component.set("v.salesLine", salesLineItem);
        helper.validateResource(component, event); 
        helper.fireTMLineUpdateEvent(component); 
       
    },
    //ticket 19130 >>
    handleResourceChange : function(component, event, helper) {
        var record = event.getParam("record");
        
        var salesLine = component.get("v.salesLine");
        //job task <<
        //US132832
        if(salesLine.Approval_Id__c == null)
            salesLine.Description__c = null;
        //job task >>
        salesLine.Resource_UOM__c = null;
        salesLine.Resource_UOM__r = null;
        salesLine.Cost_Method__c = null;
        //ticket 19586 <<
        /*
        salesLine.Facility__c = null;
        salesLine.Facility__r = null;
        */
        //ticket 19586 >>
        salesLine.Unit_Weight_Vol__c = null;
        salesLine.Unit_Weight_Vol__r = null;
        salesLine.Container_Size__c = null;
        salesLine.Container_Size__r = null;      
        salesLine.Unit_of_Measure__c = null;
        salesLine.Unit_of_Measure__r = null;  
        
        
        
        //Ticket#19445
        if(salesLine.Category__c != 'Labor' && salesLine.Category__c != 'Equipment' && salesLine.Category__c != 'Bundled'){
            salesLine.Contract_Line__c = null;
            salesLine.Contract_Line__r = null;
        }
        
        //ticket 19130 <<
        salesLine.Sales_Child_Lines__r = null;
        //ticket 19130 >>
        
        component.set("v.salesLine", salesLine);
        
        if (record) {
            component.set("v.salesLine.Resource__c", record.Id);
            component.set("v.salesLine.Resource__r", record);
            component.set("v.salesLine.isContractLineNotEditable__c", false);
            helper.validateResource(component, event);
        }
        else {
            component.set("v.salesLine.Resource__c", null);
            component.set("v.salesLine.isContractLineNotEditable__c", true);
            helper.showFields(component, event);
        }
    },
    handleUnitOfMeasureChange1 : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            var salesLine = component.get("v.salesLine");
            salesLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
            salesLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            
            //fix.null.fields <<
            /*
            if (salesLine.Category__c == 'Labor') {
                if (salesLine.Unit_of_Measure__r.Hours_UOM__c != true) {
                    salesLine.UOM_Qty__c = 1;
                    if (salesLine.Sales_Line_Details__r) {
                        for (var i = 0; i < salesLine.Sales_Line_Details__r.length; i++) {
                            salesLine.Sales_Line_Details__r[i].Start_Time__c = null;
                            salesLine.Sales_Line_Details__r[i].End_Time__c = null;
                            salesLine.Sales_Line_Details__r[i].Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                            salesLine.Sales_Line_Details__r[i].Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                            salesLine.Sales_Line_Details__r[i].UOM_Qty__c = salesLine.UOM_Qty__c;
                        }
                    }
                }
                else {
                    var salesOrder = component.get("v.salesOrder");
                    if (salesLine.Sales_Line_Details__r) {
                        for (var i = 0; i < salesLine.Sales_Line_Details__r.length; i++) {
                            salesLine.Sales_Line_Details__r[i].Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
                            salesLine.Sales_Line_Details__r[i].End_Time__c = salesOrder.Estimated_Job_End_Time__c;
                            salesLine.Sales_Line_Details__r[i].Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                            salesLine.Sales_Line_Details__r[i].Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                            salesLine.Sales_Line_Details__r[i].UOM_Qty__c = salesLine.UOM_Qty__c;
                        }
                    }
                }
            }
            */
            if (salesLine.Sales_Line_Details__r) {
                if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment') {
                    if (salesLine.Unit_of_Measure__r.Hours_UOM__c != true) {
                        salesLine.UOM_Qty__c = 1;
                        
                        for (var i = 0; i < salesLine.Sales_Line_Details__r.records.length; i++) {
                            salesLine.Sales_Line_Details__r.records[i].Start_Time__c = null;
                            salesLine.Sales_Line_Details__r.records[i].End_Time__c = null;
                            salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                            salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                            salesLine.Sales_Line_Details__r.records[i].UOM_Qty__c = salesLine.UOM_Qty__c;
                        }
                    } else {
                        var salesOrder = component.get("v.salesOrder");
                        for (var i = 0; i < salesLine.Sales_Line_Details__r.records.length; i++) {
                            salesLine.Sales_Line_Details__r.records[i].Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
                            salesLine.Sales_Line_Details__r.records[i].End_Time__c = salesOrder.Estimated_Job_End_Time__c;
                            salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                            salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                            salesLine.Sales_Line_Details__r.records[i].UOM_Qty__c = salesLine.UOM_Qty__c;
                        }
                    }
                }
            }
            //fix.null.fields >>
            //contract specific resource <<
            salesLine.Contract_Line__c = null;
            salesLine.Contract_Line__r = null;
            //contract specific resource >>
            component.set("v.salesLine", salesLine);
            helper.validateUnitOfMeasure(component, event);
        }
        else {
            //contract specific resource <<
            //component.set("v.salesLine.Unit_of_Measure__c", null);
            var salesLine = component.get("v.salesLine");
            salesLine.Contract_Line__c = null;
            salesLine.Contract_Line__r = null;
            salesLine.Unit_of_Measure__c = null;
            if (salesLine.Resource_Type__r != null) {
                salesLine.Description__c = salesLine.Resource_Type__r.Description__c;
            }
            else {
                salesLine.Description__c = null;
            }
            salesLine.Pricing_Source_2__c = null;
            component.set("v.salesLine", salesLine);
            //contract specific resource >>
        }
    },
    handleUnitOfMeasureChange2 : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            //contract specific resource <<
            /*
            component.set("v.salesLine.Unit_of_Measure__c", record.Unit_of_Measure__r.Id);
            component.set("v.salesLine.Unit_of_Measure__r", record.Unit_of_Measure__r);
            //cost method <<
            component.set("v.salesLine.Facility__c", record.Facility__c);
            component.set("v.salesLine.Facility__r", record.Facility__r);
            //cost method >>
            */
            var salesLine = component.get("v.salesLine");
            salesLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
            salesLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            salesLine.Facility__c = record.Facility__c;
            salesLine.Facility__r = record.Facility__r;
            salesLine.Contract_Line__c = null;
            salesLine.Contract_Line__r = null;
            component.set("v.salesLine", salesLine);
            //contract specific resource >>
            helper.validateUnitOfMeasure(component, event);
        }
        else {
            //contract specific resource <<
            //component.set("v.salesLine.Unit_of_Measure__c", null);
            var salesLine = component.get("v.salesLine");
            salesLine.Contract_Line__c = null;
            salesLine.Contract_Line__r = null;
            salesLine.Unit_of_Measure__c = null;
            if (salesLine.Resource__r != null) {
                salesLine.Description__c = salesLine.Resource__r.Description__c;
            }
            else {
                salesLine.Description__c = null;
            }
            salesLine.Pricing_Source_2__c = null;
            component.set("v.salesLine", salesLine);
            //contract specific resource >>
        }
    },
    handleUnitOfMeasureChange3 : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        
        var record = event.getParam("record");
        if (record) {
            //contract specific resource <<
            /*
            component.set("v.salesLine.Unit_of_Measure__c", record.Id);
            component.set("v.salesLine.Unit_of_Measure__r", record);
            */
            salesLine.Unit_of_Measure__c = record.Id;
            salesLine.Unit_of_Measure__r = record;
            salesLine.Contract_Line__c = null;
            salesLine.Contract_Line__r = null;
            
            if (salesLine.Sales_Line_Details__r) {
                if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment') {
                    if (salesLine.Unit_of_Measure__r.Hours_UOM__c != true) {
                        salesLine.UOM_Qty__c = 1;
                        
                        for (var i = 0; i < salesLine.Sales_Line_Details__r.records.length; i++) {
                            salesLine.Sales_Line_Details__r.records[i].Start_Time__c = null;
                            salesLine.Sales_Line_Details__r.records[i].End_Time__c = null;
                            salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                            salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                            salesLine.Sales_Line_Details__r.records[i].UOM_Qty__c = salesLine.UOM_Qty__c;
                        }
                    } else {
                        var salesOrder = component.get("v.salesOrder");
                        for (var i = 0; i < salesLine.Sales_Line_Details__r.records.length; i++) {
                            salesLine.Sales_Line_Details__r.records[i].Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
                            salesLine.Sales_Line_Details__r.records[i].End_Time__c = salesOrder.Estimated_Job_End_Time__c;
                            salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                            salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                            salesLine.Sales_Line_Details__r.records[i].UOM_Qty__c = salesLine.UOM_Qty__c;
                        }
                    }
                }
            }
            
            component.set("v.salesLine", salesLine);
            //contract specific resource >>
            helper.validateUnitOfMeasure(component, event);
        }
        else {
            /*
            //contract specific resource <<
            component.set("v.salesLine.Contract_Line__c", null);
            component.set("v.salesLine.Contract_Line__r", null);
            component.set("v.salesLine.Description__c", null);
            component.set("v.salesLine.Pricing_Source_2__c", null);
            //contract specific resource >>
            component.set("v.salesLine.Unit_of_Measure__c", null);
            */
                salesLine.Unit_of_Measure__c =  null;
                salesLine.UnitOfMeasureCleared__c = true;
                console.log(salesLine.UnitOfMeasureCleared__c);
                //DE37326
                if(salesLine.Contract_Line__c != null){
                    salesLine.Profile_Id__c = null;
                    salesLine.Approval_Id__c = null;
                }
                salesLine.Contract_Line__c = null;
                salesLine.Contract_Line__r = null;
                salesLine.Pricing_Source_2__c = null;
                //US137007 // added condition salesLine.Approval_Id__c == null
                if (salesLine.Category__c != 'Subcontractors' && salesLine.Approval_Id__c == null) {
                    salesLine.Description__c = null;
                }
                //DE37326
                helper.validateResource(component, event);
                component.set("v.salesLine", salesLine);
            }
    },
    handleCostMethodChange : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        salesLine.Resource_UOM__c = null;
        salesLine.Resource_UOM__r = null;
        salesLine.Unit_Weight_Vol__c = null;
        salesLine.Unit_Weight_Vol__r = null;
        salesLine.Container_Size__c = null;
        salesLine.Container_Size__r = null;
        component.set("v.salesLine", salesLine);
        
        //cost method <<
        helper.showFields(component, event);
        //cost method >>
        
        helper.calculatePriceAndCost(component, event);
    },
    handleUnitWeightVolumeChange1 : function(component, event, helper) {
        //!important to clear out the container size field first because container size is dependable field based on the unit of weight when cost method is Unit_Weight_Vol
        //if (component.get("v.salesLine.Cost_Method__c") == 'Unit_Weight_Vol') {
        component.set("v.salesLine.Container_Size__c", null);
        component.set("v.salesLine.Container_Size__r", null);
        //}
        
        var record = event.getParam("record");
        //job task <<
        /*
        if (record) {
            component.set("v.salesLine.Resource_UOM__c", record.Id);
            component.set("v.salesLine.Unit_Weight_Vol__c", record.Unit_of_Measure__c);
            component.set("v.salesLine.Unit_Weight_Vol__r", record.Unit_of_Measure__r);
        }
        else {
            component.set("v.salesLine.Resource_UOM__c", null);
            component.set("v.salesLine.Unit_Weight_Vol__c", null);
            component.set("v.salesLine.Unit_Weight_Vol__r", null);
        }
        */
        if (record) {
            component.set("v.salesLine.Resource_UOM__c", record.Id);
            component.set("v.salesLine.Resource_UOM__r", record);
            if (record.Unit_of_Measure__r != null) {
                component.set("v.salesLine.Unit_Weight_Vol__c", record.Unit_of_Measure__c);
                component.set("v.salesLine.Unit_Weight_Vol__r", record.Unit_of_Measure__r);
            }
        }
        else {
            component.set("v.salesLine.Resource_UOM__c", null);
            component.set("v.salesLine.Resource_UOM__r", null);
            component.set("v.salesLine.Unit_Weight_Vol__c", null);
            component.set("v.salesLine.Unit_Weight_Vol__r", null);
        }
        //job task >>
        helper.calculatePriceAndCost(component, event);
    },
    handleUnitWeightVolumeChange2 : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.salesLine.Unit_Weight_Vol__c", record.Id);
        }
        else {
            component.set("v.salesLine.Unit_Weight_Vol__c", null);
        }
        helper.calculatePriceAndCost(component, event);
    },
    handleContainerSizeChange1 : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.salesLine.Container_Size__c", record.Unit_of_Measure__c);
            //var containerSize = { "Id": record.Container_Size__c, "Name": record.Container_Size__r.Name }; //remove self reference fields in the record, selft reference create json deserialization error in apex class
            //component.set("v.salesLine.Container_Size__r", containerSize);
            component.set("v.salesLine.Container_Size__r", record.Unit_of_Measure__r);
        }
        else {
            component.set("v.salesLine.Container_Size__c", null);
            component.set("v.salesLine.Container_Size__r", null);
        }
        helper.calculatePriceAndCost(component, event);
    },
    handleContainerSizeChange3 : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.salesLine.Container_Size__c", record.Container_Size__c);
            var containerSize = { "Id": record.Container_Size__c, "Name": record.Container_Size__r.Name }; //remove self reference fields in the record, self reference create json deserialization error in apex class
            component.set("v.salesLine.Container_Size__r", containerSize);
        }
        else {
            component.set("v.salesLine.Container_Size__c", null);
            component.set("v.salesLine.Container_Size__r", null);
        }
        helper.calculatePriceAndCost(component, event);
    },
    handleContainerSizeChange2 : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.salesLine.Container_Size__c", record.Id);
            component.set("v.salesLine.Container_Size__r", record);
        }
        else {
            component.set("v.salesLine.Container_Size__c", null);
            component.set("v.salesLine.Container_Size__r", null);
        }
        helper.calculatePriceAndCost(component, event);
    },
    handleFacilityChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.salesLine.Facility__c", record.Id);
            component.set("v.salesLine.Facility__r", record);
            //US132832
            component.set("v.salesLine.Profile_Id__c", null);
            component.set("v.salesLine.Approval_Id__c", null);
            component.set("v.salesLine.Unit_of_Measure__c", null);
            component.set("v.salesLine.EQAI_UOM__c", null);
            component.set("v.salesLine.Unit_of_Measure__r", null);
            
        }
        else {
            component.set("v.salesLine.Facility__c", null);
            component.set("v.salesLine.Facility__r", null);
            //US132832
            component.set("v.salesLine.Profile_Id__c", null);
            component.set("v.salesLine.Approval_Id__c", null);
            component.set("v.salesLine.Unit_of_Measure__c", null);
            component.set("v.salesLine.EQAI_UOM__c", null);
            component.set("v.salesLine.Unit_of_Measure__r", null);
            if(component.get("v.salesLine.Resource__c") != null){
                helper.validateResource(component, event);
            }
         
        }
        var faclity = component.get("v.salesOrder.Document_Type__c");
        var servicecenter = component.get("v.salesOrder.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c");
        //Task#78352//Bug#80870
        if (servicecenter && record.Third_Party_Facility__c && faclity ==='Sales Quote' && $A.get("$Label.c.Release_Flag")==='true') {
            helper.showToast(component, 'Warning', 'You have chosen a 3rd Party Facility. Please create an approved facility in EQAI before converting this quote to an order.', 'warning','dismissible');
        }
        else if (servicecenter && record.Third_Party_Facility__c && faclity ==='Sales Order' && $A.get("$Label.c.Release_Flag")==='true') {
            helper.showToast(component, 'Warning', 'You have chosen 3rd Party. Please create an approved facility in EQAI before Sending your Sales Order to EQAI.', 'warning','dismissible');
        }
        helper.calculatePriceAndCost(component, event);
    },
    handleNumberOfDaysChange : function(component, event, helper) {
        //helper.calculateSalesLine(component, event);
        var numberOfDays = component.get("v.salesLine.Number_of_Day__c");
        var maxNumberOfDays = component.get("v.salesOrder.Duration__c");
        if (!isNaN(numberOfDays) && !isNaN(maxNumberOfDays)) {
            if (numberOfDays > maxNumberOfDays) {
                //alert('Days Needed must not exceed the duration (' + maxNumberOfDays + ' days) specified on the sales quote/order.')
                var fieldDaysNeeded = component.find("days-needed");
                if (fieldDaysNeeded) {
                    fieldDaysNeeded.rollbackValue();
                    fieldDaysNeeded.reportValidity('Days Needed must not exceed the duration (' + maxNumberOfDays + ' days) on the quote/order.');
                }
                return;
            }
        }
        //job task <<
        //helper.validateNumberOfDays(component, event);
        var salesLine = component.get("v.salesLine");
        if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment') {
            helper.validateNumberOfDays(component, event);
        }
        else if (salesLine.Category__c == 'Materials') {
            helper.calculateSalesLine(component, event);
        }
        //job task >>
    },
    handleUOMQtyChange : function(component, event, helper) {
        /* replace by apex code - billingService
        var uomQty = component.get("v.salesLine.UOM_Qty__c");
        component.set("v.salesLine.Regular_Hours__c", uomQty);
        */
        var salesOrder = component.get("v.salesOrder");
        var salesLine = component.get("v.salesLine");
        //equipment schedule lines <<
        //if (salesLine.Category__c == 'Labor') {
        if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment') {
            //equipment schedule lines >>
            //if (salesLine.Unit_of_Measure__r.Hours_UOM__c != true) {
            //fix.null.fields <<
            /*
            if (salesLine.Sales_Line_Details__r) {
                for (var i = 0; i < salesLine.Sales_Line_Details__r.length; i++) {
                    salesLine.Sales_Line_Details__r[i].Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                    salesLine.Sales_Line_Details__r[i].Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                    if (salesLine.Unit_of_Measure__r == null || salesLine.Unit_of_Measure__r.Hours_UOM__c != true) {
                        salesLine.Sales_Line_Details__r[i].Start_Time__c = null;
                        salesLine.Sales_Line_Details__r[i].End_Time__c = null;
                    } else {
                        salesLine.Sales_Line_Details__r[i].Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
                        salesLine.Sales_Line_Details__r[i].End_Time__c = salesOrder.Estimated_Job_End_Time__c;
                    }
                    salesLine.Sales_Line_Details__r[i].UOM_Qty__c = salesLine.UOM_Qty__c;
                }
                component.set("v.salesLine", salesLine);
            }
            */
                                        if (salesLine.Unit_of_Measure__r && salesLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                                            if (salesOrder.Estimated_Job_Start_Time__c != null && salesOrder.Estimated_Job_End_Time__c != null) {
                                                //salesLine.UOM_Qty__c = helper.calculateHours(salesOrder.Estimated_Job_Start_Time__c, salesOrder.Estimated_Job_End_Time__c);
                                                //component.set("v.salesLine", salesLine);
                                                var uomQty = component.find("uom-qty");
                                                if (uomQty) {
                                                    uomQty.rollbackValue();
                                                    uomQty.reportValidity('You cannot change UOM Qty because it is driven by the estimated job start time and end time.');
                                                    return;
                                                }
                                            }
                                        }
                                        
                                        if (salesLine.Sales_Line_Details__r) {
                                            for (var i = 0; i < salesLine.Sales_Line_Details__r.records.length; i++) {
                                                salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                                                salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                                                if (salesLine.Unit_of_Measure__r == null || salesLine.Unit_of_Measure__r.Hours_UOM__c != true) {
                                                    salesLine.Sales_Line_Details__r.records[i].Start_Time__c = null;
                                                    salesLine.Sales_Line_Details__r.records[i].End_Time__c = null;
                                                } else {
                                                    salesLine.Sales_Line_Details__r.records[i].Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
                                                    salesLine.Sales_Line_Details__r.records[i].End_Time__c = salesOrder.Estimated_Job_End_Time__c;
                                                }
                                                salesLine.Sales_Line_Details__r.records[i].UOM_Qty__c = salesLine.UOM_Qty__c;
                                            }
                                        }
                                        component.set("v.salesLine", salesLine);
                                        //fix.null.fields >>
                                        //}
                                    }
        helper.calculateSalesLine(component, event);
    },
    handleQuantityChange : function(component, event, helper) {
        //recalculate lump line
        //var salesLine = component.get("v.salesLine");
        //helper.recalculateLumpSumLine(component, event, salesLine);
        //bundle line pricing method <<
        var salesLine = component.get("v.salesLine");
        if (salesLine.Category__c == 'Bundled') {
            //var salesLines = component.get("v.salesLines");
            var salesLines = component.get("v.jobTaskWrapper.SalesLines");
            salesLine = helper.rollupLumpSumLine(salesLine, salesLines, true);
            component.set("v.salesLine", salesLine);
        }
        //bundle line pricing method >>
        helper.calculateSalesLine(component, event);
    },
    handleUnitPriceChange : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        /* Ticket#19964
        if (salesLine.Category__c == 'Subcontractors') {
            salesLine.Unit_Cost__c = salesLine.Unit_Price__c;
            salesLine.xUnit_Cost__c = salesLine.Unit_Cost__c;
        }
         */
        salesLine.xUnit_Price__c = salesLine.Unit_Price__c; //track user entered unit price
        //Ticket#20286 >>
        salesLine.Sales_Line__c = null;
        salesLine.Sales_Line__r = null;
        salesLine.Quote_Line__c = null;
        salesLine.Quote_Line__r = null;
        salesLine.Contract_Line__c = null;
        salesLine.Contract_Line__r = null;
        salesLine.Pricing_Source_2__c = null;
        var unitPrice = salesLine.Unit_Price__c;
        var xunitPrice = salesLine.xUnit_Price__c;
        component.set("v.prvUnitPrice",unitPrice);
        component.set("v.prvxUnitPrice",xunitPrice);
        //Ticket#20286 <<
        helper.calculateSalesLine(component, event);
    },
    handlexUnitPriceChange : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        /* Ticket#19964
        if (salesLine.Category__c == 'Subcontractors') {
            salesLine.xUnit_Cost__c = salesLine.xUnit_Price__c;
            salesLine.Unit_Cost__c = salesLine.xUnit_Cost__c;
        }
         */
        helper.calculateSalesLine(component, event);
    },
    handleRegularRateChange : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        salesLine.xRegular_Rate__c = salesLine.Regular_Rate__c; //track user entered rate
        salesLine.Overtime_Rate__c = Math.round(salesLine.Regular_Rate__c * 1.5 * 100) / 100;
        salesLine.xOvertime_Rate__c = salesLine.xOvertime_Rate__c;
        salesLine.Premium_Rate__c = Math.round(salesLine.Regular_Rate__c * 2.0 * 100) / 100;
        salesLine.xPremium_Rate__c = salesLine.Premium_Rate__c;
        
        //Ticket#20286 >>
        salesLine.Sales_Line__c = null;
        salesLine.Sales_Line__r = null;
        salesLine.Quote_Line__c = null;
        salesLine.Quote_Line__r = null;
        salesLine.Contract_Line__c = null;
        salesLine.Contract_Line__r = null;
        salesLine.Pricing_Source_2__c = null;
        //Ticket#20286 <<
        
        component.set("v.salesLine", salesLine);
        helper.calculateSalesLine(component, event);
    },
    handleOvertimeRateChange : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        salesLine.xOvertime_Rate__c = salesLine.Overtime_Rate__c; //track user entered rate
        //Ticket#20286 >>
        salesLine.Sales_Line__c = null;
        salesLine.Sales_Line__r = null;
        salesLine.Quote_Line__c = null;
        salesLine.Quote_Line__r = null;
        salesLine.Contract_Line__c = null;
        salesLine.Contract_Line__r = null;
        salesLine.Pricing_Source_2__c = null;
        //Ticket#20286 <<
        helper.calculateSalesLine(component, event);
    },
    handleDoubleTimeRateChange : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        salesLine.xPremium_Rate__c = salesLine.Premium_Rate__c; //track user entered rate
        //Ticket#20286 >>
        salesLine.Sales_Line__c = null;
        salesLine.Sales_Line__r = null;
        salesLine.Quote_Line__c = null;
        salesLine.Quote_Line__r = null;
        salesLine.Contract_Line__c = null;
        salesLine.Contract_Line__r = null;
        salesLine.Pricing_Source_2__c = null;
        //Ticket#20286 <<
        helper.calculateSalesLine(component, event);
    },
    handleUnitCostChange : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        if (salesLine.Bill_as_Lump_Sum__c != true) {
            salesLine.xUnit_Cost__c = salesLine.Unit_Cost__c; //track user entered unit cost
        }
        
        if(salesLine.Category__c === 'Subcontractors') {
            var markup = (salesLine.Markup__c ? parseFloat(salesLine.Markup__c) : 0);
            var unitCost = (salesLine.Unit_Cost__c ? parseFloat(salesLine.Unit_Cost__c) : 0);
            if (salesLine.Bill_as_Lump_Sum__c === true) {
                unitCost = (salesLine.xUnit_Cost__c ? parseFloat(salesLine.xUnit_Cost__c) : 0);
            }
            var unitPrice = unitCost;
            if (salesLine.Markup_Option__c === '%') {
                unitPrice = unitCost + Math.round(unitCost * markup) / 100;
            } else if (salesLine.Markup_Option__c === 'Amount') {
                unitPrice = unitCost + markup;
            }
            if (salesLine.Bill_as_Lump_Sum__c === true) {
                salesLine.xUnit_Price__c = unitPrice;
            } else {
                salesLine.Unit_Price__c = unitPrice;
                //ticket 20799 << fix for ticket 19964
                salesLine.xUnit_Price__c = unitPrice;
                //ticket 20799 >>
            }
            salesLine.Pricing_Source_2__c = null;
            salesLine.Quote_Line__c = null;
        }
        helper.calculateSalesLine(component, event);
        component.set("v.salesLine", salesLine);
    },
    handleMarkupOptionChange : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        if(salesLine.Category__c === 'Subcontractors') {
            var markup = (salesLine.Markup__c ? parseFloat(salesLine.Markup__c) : 0);
            var unitCost = (salesLine.Unit_Cost__c ? parseFloat(salesLine.Unit_Cost__c) : 0);
            if (salesLine.Bill_as_Lump_Sum__c === true) {
                unitCost = (salesLine.xUnit_Cost__c ? parseFloat(salesLine.xUnit_Cost__c) : 0);
            }
            var unitPrice = unitCost;
            if (salesLine.Markup_Option__c === '%') {
                unitPrice = unitCost + Math.round(unitCost * markup) / 100;
            } else if (salesLine.Markup_Option__c === 'Amount') {
                unitPrice = unitCost + markup;
            }
            if (salesLine.Bill_as_Lump_Sum__c === true) {
                salesLine.xUnit_Price__c = unitPrice;
            } else {
                salesLine.Unit_Price__c = unitPrice;
                //ticket 20799 << fix for ticket 19964
                salesLine.xUnit_Price__c = unitPrice;
                //ticket 20799 >>
            }
            salesLine.Pricing_Source_2__c = null;
            salesLine.Quote_Line__c = null;
        }
        helper.calculateSalesLine(component, event);
        component.set("v.salesLine", salesLine);
    },
    handleMarkupChange : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        if(salesLine.Category__c === 'Subcontractors') {
            var markup = (salesLine.Markup__c ? parseFloat(salesLine.Markup__c) : 0);
            var unitCost = (salesLine.Unit_Cost__c ? parseFloat(salesLine.Unit_Cost__c) : 0);
            if (salesLine.Bill_as_Lump_Sum__c === true) {
                unitCost = (salesLine.xUnit_Cost__c ? parseFloat(salesLine.xUnit_Cost__c) : 0);
            }
            var unitPrice = unitCost;
            if (salesLine.Markup_Option__c === '%') {
                unitPrice = unitCost + Math.round(unitCost * markup) / 100;
            } else if (salesLine.Markup_Option__c === 'Amount') {
                unitPrice = unitCost + markup;
            }
            if (salesLine.Bill_as_Lump_Sum__c === true) {
                salesLine.xUnit_Price__c = unitPrice;
            } else {
                salesLine.Unit_Price__c = unitPrice;
                //ticket 20799 << fix for ticket 19964
                salesLine.xUnit_Price__c = unitPrice;
                //ticket 20799 >>
            }
            salesLine.Pricing_Source_2__c = null;
            salesLine.Quote_Line__c = null;
        }
        helper.calculateSalesLine(component, event);
        component.set("v.salesLine", salesLine);
    },
    handleContractLineChange : function(component, event, helper) {
        var record = event.getParam("record");
        var salesLine = component.get("v.salesLine");
        if (record) {
            
            salesLine.Contract_Line__c = record.Id;
            salesLine.isContractLineNotEditable__c = false;
            
            salesLine.Resource_Type__c = record.Resource_Type__c;
            salesLine.Resource_Type__r = record.Resource_Type__r;
            salesLine.Resource__c = record.Resource__c;
            salesLine.Resource__r = record.Resource__r;
            
            salesLine.Unit_of_Measure__c = record.Unit_of_Measure__c;
            salesLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            
            salesLine.Unit_Price__c = record.Regular_Rate__c;
            salesLine.xUnit_Price__c = salesLine.Unit_Price__c;
            
            salesLine.Contract_Regular_Rate__c = record.Regular_Rate__c;
            salesLine.Contract_Overtime_Rate__c = record.Overtime_Rate__c;
            salesLine.Contract_Premium_Rate__c = record.Premium_Rate__c;
            
            salesLine.Regular_Rate__c = record.Regular_Rate__c;
            salesLine.Overtime_Rate__c = record.Overtime_Rate__c;
            salesLine.Premium_Rate__c = record.Premium_Rate__c;
            
            salesLine.xRegular_Rate__c = salesLine.Regular_Rate__c;
            salesLine.xOvertime_Rate__c = salesLine.Overtime_Rate__c;
            salesLine.xPremium_Rate__c = salesLine.Premium_Rate__c;
            
            if (record.Customer_Description__c != null) {
                salesLine.Description__c = record.Customer_Description__c;
            }
            
            //Ticket#19445
            if(salesLine.Category__c === 'Waste Disposal'){
                salesLine.Facility__c = record.Facility__c;
                salesLine.Facility__r = record.Facility__r;
                //US132832
                salesLine.Profile_Id__c = null;
                salesLine.Approval_Id__c = null;
            }
        }
        else {
            
            salesLine.Contract_Line__c = null;
            salesLine.isContractLineNotEditable__c = true;
            // salesLine.Resource_Type__c = null;
            // salesLine.Resource_Type__r = null;
            // salesLine.Resource__c = null;
            // salesLine.Resource__r = null;
            //contract specific resource <<
            salesLine.Description__c =  null;
            //contract specific resource >>
            salesLine.Unit_of_Measure__c = null;
            salesLine.Unit_of_Measure__r = null;
            salesLine.Unit_Price__c = salesLine.xUnit_Price__c;
            salesLine.Regular_Rate__c = salesLine.xRegular_Rate__c;
            salesLine.Overtime_Rate__c = salesLine.xOvertime_Rate__c;
            salesLine.Premium_Rate__c = salesLine.xPremium_Rate__c;
            //Ticket#19445
            if(salesLine.Category__c === 'Waste Disposal'){
                salesLine.Facility__c = null;
                salesLine.Facility__r = null;
                //US132832
                salesLine.Profile_Id__c = null;
                salesLine.Approval_Id__c = null;
            }
        }
        
        component.set("v.salesLine", salesLine);
        helper.calculateSalesLine(component, event);
        if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment' || salesLine.Category__c == 'Bundled') {
            helper.validateResourceType(component, event);
        }
        else {
            helper.validateResource(component, event);
        }
        
    },
    handleQuoteLineChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.salesLine.Quote_Line__c", record.Id);
        }
        else {
            component.set("v.salesLine.Quote_Line__c", null);
        }
    },
    handleBillAsLumpSumChange : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        
        //job task <<
        //var salesLines = component.get("v.salesLines");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var salesLines = jobTaskWrapper.SalesLines;
        //job task >>
        var lumpSumLine = null;
        console.log('salesLine.Disposal_Billing_Method__c++++++'+salesLine.Disposal_Billing_Method__c);
        if (salesLine.Bill_as_Lump_Sum__c != true) {
            //ticket 19535 <<
            //lumpSumLine = helper.findLumpSumLine(salesLine, salesLines);
            lumpSumLine = helper.getLumpSumLine(salesLine, salesLines);
            //ticket 19535 >>
            
            //non-billable <<
            //salesLine.Unit_Price__c = salesLine.xUnit_Price__c;
            
            
            if (salesLine.Non_Billable__c != true) {
                salesLine.Unit_Price__c = salesLine.xUnit_Price__c;
            }
            //non-billable >>
            salesLine.Unit_Cost__c = salesLine.xUnit_Cost__c;
            salesLine.Bundle_Line__c = '';  //use blank instead of null to void the field gets dropped after passed to apex and returned
            salesLine.Bundle_Line__r = null;
        }
        salesLines = helper.updateSalesLines(salesLine, salesLines); //update sales lines
        
        //calculate lump sum line <<
        /*
        if (lumpSumLine != null) {
            //lumpSumLine = helper.rollupLumpSumLine(lumpSumLine, salesLines);
            helper.recalculateLumpSumLine(component, event, true);
            lumpSumLine = component.get("v.salesLine");

            salesLines = helper.updateSalesLines(lumpSumLine, salesLines);
        }
        */
        
        component.set("v.salesLine", salesLine);
        //calculate lump sum line <<
        //component.set("v.salesLines", salesLines);
        //calculate lump sum line >>
        helper.calculateSalesLine(component, event);
        
        //calculate lump sum line <<
        if (salesLine.Bundle_Line__r) {
            this.rollUpLumpSum(salesLine.Bundle_Line__r.Line_No__c, jobTaskWrapper);
        }
        //calculate lump sum line >>
    },
    handleNonBillableChange : function(component, event, helper) {
        //non-billable <<
        var salesLine = component.get("v.salesLine");
        if (salesLine.Non_Billable__c == true) {
            salesLine.Unit_Price__c = 0;
            salesLine.Line_Amount__c = 0;
            salesLine.Tax__c = 0;
            salesLine.Line_Amt_Incl_Tax__c = 0;
        }
        if (salesLine.Non_Billable__c != true && salesLine.Bill_as_Lump_Sum__c != true) {
            salesLine.Unit_Price__c = salesLine.xUnit_Price__c;
        }
        
        component.set("v.salesLine", salesLine);
        helper.calculateSalesLine(component, event);
        //non-billable >>
    },
    handleTaxGroupChange : function(component, event, helper) {
        
        //job task <<
        //ticket 19130 << no need to default
        /*
        var salesLine = component.get("v.salesLine");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
            if (jobTaskWrapper.SalesLines[i].Parent_Line__r) {
                if (jobTaskWrapper.SalesLines[i].Parent_Line__r.Line_No__c == salesLine.Line_No__c) {
                    jobTaskWrapper.SalesLines[i].Tax_Group__c = salesLine.Tax_Group__c;
                }
            }
        }
        */
        //ticket 19130 >>
        //job task >>
        helper.calculateSalesLine(component, event);
        
    },
    
    //job task <<
    handleSalesLineChange : function(component, event, helper) {
        component.set("v.linesAdded", true);
    },
    //job task >>
    /*
    rollupLumpSumLine : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        if (salesLine.Category__c == 'Lump Sum') {
            helper.rollupLumpSumLine(component, event, salesLine); //SalesOrderBase
            component.set("v.salesLine", salesLine);
        }
    }
    */
    //bundle line pricing method <<
    handleBundlePricingMethodChange : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        if (salesLine.Bundle_Pricing_Method__c == 'Per Total') {
            salesLine.Quantity__c = 1;
        }
        helper.recalculateLumpSumLine(component, event, salesLine, true);
        if (salesLine.Bundle_Pricing_Method__c == 'Per Unit') {
            salesLine.Quantity__c = null;
        }
        component.set("v.salesLine", salesLine);
    },
    //bundle line pricing method >>
    //ticket 19130 <<
    addChildResource : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        if (!salesLine.Sales_Child_Lines__r || !salesLine.Sales_Child_Lines__r.records) {
            salesLine.Sales_Child_Lines__r = { "records": [] };
        }
        salesLine.Sales_Child_Lines__r.records.push({
            "Parent_Line__c": salesLine.Id,
            "Parent_Line__r": {
                "attributes": {"type": 'Sales_Line__c'},
                "Id": salesLine.Id,
                "Line_No__c": salesLine.Line_No__c,
                "Category__c": salesLine.Category__c,
                "Resource_Type__c": salesLine.Resource_Type__c,
                "Resource_Type__r": salesLine.Resource_Type__r,
                "Resource__c": salesLine.Resource__c,
                "Resource__r": salesLine.Resource__r
            }
        });
        component.set("v.salesLine.Sales_Child_Lines__r", salesLine.Sales_Child_Lines__r);
    },
    removeParentChildRelation : function(component, event, helper) {
        var rowIndex = event.getSource().get("v.value");
        var salesLine = component.get("v.salesLine");
        if (salesLine.Sales_Child_Lines__r && salesLine.Sales_Child_Lines__r.records) {
            salesLine.Sales_Child_Lines__r.records.splice(rowIndex, 1);
        }
        component.set("v.salesLine.Sales_Child_Lines__r", salesLine.Sales_Child_Lines__r);
    },
    handleRelationChange : function(component, event, helper) {
        var rowIndex = parseInt(event.getSource().get("v.label")); //use label to pass rowIndex
        var salesLine = component.get("v.salesLine");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        if (salesLine.Sales_Child_Lines__r && salesLine.Sales_Child_Lines__r.records) {
            var relation = salesLine.Sales_Child_Lines__r.records[rowIndex];
            var childLineNo = relation.Child_Line__r.Line_No__c;
            for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
                if (parseInt(jobTaskWrapper.SalesLines[i].Line_No__c) == parseInt(childLineNo)) {
                    relation.Child_Line__r.Id = jobTaskWrapper.SalesLines[i].Id;
                    relation.Child_Line__r.Category__c = jobTaskWrapper.SalesLines[i].Category__c;
                    relation.Child_Line__r.Resource_Type__c = jobTaskWrapper.SalesLines[i].Resource_Type__c;
                    relation.Child_Line__r.Resource_Type__r = jobTaskWrapper.SalesLines[i].Resource_Type__r;
                    relation.Child_Line__r.Resource__c = jobTaskWrapper.SalesLines[i].Resource__c;
                    relation.Child_Line__r.Resource__r = jobTaskWrapper.SalesLines[i].Resource__r;
                    relation.Child_Line__r.Description__c = jobTaskWrapper.SalesLines[i].Description__c;
                    relation.Child_Line__c = jobTaskWrapper.SalesLines[i].Id;
                    break;
                }
            }
        }
    }
    //ticket 19130 >>
})