({

    validateSurchargeType : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };
        this.callServerMethod(component, event, "c.validateSurchargeType", params, function(response) {
            var salesOrderWrapper = JSON.parse(response);
            component.set("v.salesOrder", salesOrderWrapper.SalesOrder);
            component.set("v.jobTaskWrappers", salesOrderWrapper.JobTaskWrappers);
        })
    },
    validateSurchargePct : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };
        this.callServerMethod(component, event, "c.validateSurchargePct", params, function(response) {
            component.set("v.jobTaskWrappers", JSON.parse(response));
        }, function(err) {
            component.set("v.salesOrder.Surcharge_Pct__c", null);
            this.showToast(component, "Error", err, "Error", "dismissible");
        });
    },
    calculateEstimatedDateInfo : function(component, event, suggestWeekendAndHoliday) {
        var salesOrder = component.get('v.salesOrder');
        //billing.rule.fix <<
        //if (salesOrder.Estimated_Job_Start_Date__c && salesOrder.Duration__c && salesOrder.Billing_Rule__c != null) {
        if (salesOrder.Estimated_Job_Start_Date__c && salesOrder.Duration__c) {
        //billing.rule.fix >>
            if (suggestWeekendAndHoliday == true) {
                this.suggestWeekendAndHoliday(component, event, true, true); //suggest both weekend and holiday by default
            }
            else {
                //helper.calculateSalesOrder(component, event, method);
                this.calculateEstimatedJobEndDate(component, event);
            }
        }
    },
    suggestWeekendAndHoliday : function(component, event, suggestWeekend, suggestHoliday) {
        var salesOrder = component.get("v.salesOrder");
        var suggestWeekendAndHoliday = event.getParam("suggestWeekendAndHoliday");
        var includeWeekend = salesOrder.Include_Weekend__c;
        var includeHoliday = salesOrder.Include_Holiday__c;
        var billingRuleId = salesOrder.Billing_Rule__c;

        //determine which suggestions are valid
        if (includeWeekend == true) {
            suggestWeekend = false;
        }
        if (includeHoliday == true) {
            suggestHoliday = false;
        }

        //suggest if at one suggestion is valid
        if (suggestWeekend == true || suggestHoliday == true) { //determine which day comes first
            var params = { "startDate": salesOrder.Estimated_Job_Start_Date__c, "duration": salesOrder.Duration__c, "billingRuleId": billingRuleId, "includeWeekend": includeWeekend, "includeHoliday": includeHoliday  };
            this.callServerMethod(component, event, "c.getWeekendAndHoliday", params, function(response) {
                var weekend;
                if (response.WEEKEND != null) {
                    weekend = Date.parse(response.WEEKEND);
                }
                var holiday;
                if (response.HOLIDAY != null) {
                    holiday = Date.parse(response.HOLIDAY);
                }

                var suggest;
                if (weekend != null && holiday != null) {
                    if (weekend <= holiday) {
                        if (suggestWeekend == true) {
                            suggest = 'WEEKEND';
                        }
                        else if (suggestHoliday == true) {
                            suggest = 'HOLIDAY';
                        }
                    }
                    else {
                        if (suggestHoliday == true) {
                            suggest = 'HOLIDAY';
                        }
                        else if (suggestWeekend == true) {
                            suggest = 'WEEKEND';
                        }
                    }
                }
                else if (weekend == null && holiday != null) {
                    if (suggestHoliday == true) {
                        suggest = 'HOLIDAY';
                    }
                }
                else if (weekend != null && holiday == null) {
                    if (suggestWeekend == true) {
                        suggest = 'WEEKEND';
                    }
                }

                if (suggest == 'HOLIDAY') {
                    this.promptIncludeHoliday(component, event, suggestWeekend);
                }
                else if (suggest == 'WEEKEND') {
                    this.promptIncludeWeekend(component, event, suggestHoliday);
                }
                else {
                    this.calculateEstimatedJobEndDate(component, event);
                }
            });
        }
        else {
            this.calculateEstimatedJobEndDate(component, event);
        }
    },
    promptIncludeWeekend : function(component, event, suggestHoliday) {
        var salesOrder = component.get("v.salesOrder");
        var buttons = [
            { "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelIncludeWeekendCallback.bind(this, component, event, suggestHoliday) }},
            { "label": 'Yes', "variant": 'brand', "action": { "callback": this.confirmIncludeWeekendCallback.bind(this, component, event, suggestHoliday) }},
        ];
        this.openModal(component, event, 'Inlcude Weekend', 'Do you want to include weekend?', buttons, null, null);
    },
    confirmIncludeWeekendCallback : function(component, event, suggestHoliday) {
        component.set("v.salesOrder.Include_Weekend__c", true);
        this.closeModal(component, event);

        if (suggestHoliday == true) {
            this.suggestWeekendAndHoliday(component, event, false, suggestHoliday);
        }

        this.calculateEstimatedJobEndDate(component, event, '');
    },
    cancelIncludeWeekendCallback : function(component, event, suggestHoliday) {
        this.closeModal(component, event);

        if (suggestHoliday == true) {
            this.suggestWeekendAndHoliday(component, event, false, suggestHoliday);
        }

        this.calculateEstimatedJobEndDate(component, event);
    },
    promptIncludeHoliday : function(component, event, suggestWeekend) {
        var salesOrder = component.get("v.salesOrder");
        var buttons = [
            { "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelIncludeHolidayCallback.bind(this, component, event, suggestWeekend) }},
            { "label": 'Yes', "variant": 'brand', "action": { "callback": this.confirmIncludeHolidayCallback.bind(this, component, event, suggestWeekend) }},
        ];
        this.openModal(component, event, 'Inlcude Holiday', 'Do you want to include holiday?', buttons, null, null);
    },
    confirmIncludeHolidayCallback : function(component, event, suggestWeekend) {
        component.set("v.salesOrder.Include_Holiday__c", true);
        this.closeModal(component, event);

        if (suggestWeekend == true) {
            this.suggestWeekendAndHoliday(component, event, suggestWeekend, false);
        }

        this.calculateEstimatedJobEndDate(component, event);
    },
    cancelIncludeHolidayCallback : function(component, event, suggestWeekend) {
        this.closeModal(component, event);

        if (suggestWeekend == true) {
            this.suggestWeekendAndHoliday(component, event, suggestWeekend, false);
        }

        this.calculateEstimatedJobEndDate(component, event);
    },
    calculateEstimatedJobEndDate : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        let recalculateDuration = component.get("v.recalculateDuration"); //Ticket#24326
        //Ticket#24326 - add recalculateDuration to the call parameters
        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers), 'recalculateDuration': recalculateDuration };
        this.callServerMethod(component, event, "c.calculateEstimatedDateInfo", params, function(response) {
            var salesOrderWrapper = JSON.parse(response);
            var salesOrder = salesOrderWrapper.SalesOrder;
            var jobTaskWrappers = salesOrderWrapper.JobTaskWrappers;
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                this.rollupAllLumpSumLines(jobTaskWrappers[i].SalesLines, true);
            }
            component.set("v.salesOrder", salesOrder);
            component.set("v.jobTaskWrappers", jobTaskWrappers);
        });
    },

    /*
        Ticket#17051 - helper that will update line pricing info once the rate sheet change is detected
     */
    validateRateSheet : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        let rateSheetId = salesOrder.Rate_Sheeet__c;
        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers), "RateSheetId": rateSheetId};
        this.callServerMethod(component, event, "c.validateRateSheet", params, function(response) {
            var salesOrderWrapper = JSON.parse(response);
            component.set("v.salesOrder", salesOrderWrapper.SalesOrder);
            component.set("v.jobTaskWrappers", salesOrderWrapper.JobTaskWrappers);
        });
    },
    //Ticket#21540
    validateServiceCenter : function (component, event) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers)};
        this.callServerMethod(component, event, "c.validateServiceCenter", params, function(response) {
            var salesOrderWrapper = JSON.parse(response);
            component.set("v.salesOrder", salesOrderWrapper.SalesOrder);
            component.set("v.jobTaskWrappers", salesOrderWrapper.JobTaskWrappers);
        });
    },
    //US114833 - Method to display warning msg if a Sales Order Type is changed
    validateSOTypeChange: function(component, event) {
        var soType = component.get("v.soType");
        var salesOrder = component.get("v.salesOrder");
        
        if (soType && salesOrder && salesOrder.Service_Center__r && soType.operation == "edit" &&
            salesOrder.SO_sent_to_EQAI__c && salesOrder.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c) {
            var salesOrderTypeLkpCmp;
            if (component.find("sotype") != undefined || component.find("sotype") != null) {
                salesOrderTypeLkpCmp = component.find("sotype");   
            } else {
                salesOrderTypeLkpCmp = component.find("sotype-order");                  
            }  
            
            var newSalesOrderType = salesOrderTypeLkpCmp.get("v.value");            
            if (newSalesOrderType != undefined) {
                newSalesOrderType = newSalesOrderType.Id;
            }
            
            if (soType.existingSalesOrderType != newSalesOrderType) {
                soType.displayWaringMsg = true;                
            } else {
                soType.displayWaringMsg = false;
            }
            component.set("v.soType", soType);
        }
    },
})