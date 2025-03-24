/*
    Ticket#17051 - Link Rate Sheet to Sales Order Type
    Ticket#21540 - handleServiceCenterChange() add Service_Center__r
 */
({
    setNewContactRecordParams : function(component, event, helper) {
        var account = component.get("v.salesOrder.Bill_to_Customer_No__r");
        var record = {};
        if (account != null) {
            record.AccountId = account.Id;
            record.Account = account;
            record.MailingStreet = account.BillingStreet;
            record.MailingCity = account.BillingCity;
            record.MailingPostalCode = account.BillingPostalCode;
            record.MailingCountryCode = account.BillingCountryCode;
            record.MailingStateCode = account.BillingStateCode;
        }
        record.Contact_Type__c = 'Quote';
        var newContactRecordParams = { "record": record };
        component.set("v.newContactRecordParams", newContactRecordParams);
    },
    handleQuoteTypeChange : function(component, event, helper) {
        var salesOrder = component.get("v.salesOrder");
        component.set("v.salesOrder", salesOrder);
    },
    /*
     *  Ticket#20977 add subsidiary company checking
     */
    handleServiceCenterChange : function(component, event, helper) {
        var record = event.getParam("record");
        var newSalesOrderAllowed = true;
        if (record) {
            var salesOrder = component.get("v.salesOrder");
            console.log('record.Prevent_New_and_Cloned_Sales_Orders__c: ' + record.Prevent_New_and_Cloned_Sales_Orders__c);
            console.log('salesOrder.Id: ' +  salesOrder.Id);
            console.log('salesOrder.Document_Type__c: ' +  salesOrder.Document_Type__c);
            if(record.Prevent_New_and_Cloned_Sales_Orders__c === true && (salesOrder.Id === null || salesOrder.Id === undefined) && salesOrder.Document_Type__c === 'Sales Order'){
                component.set("v.salesOrder.Service_Center__c", null);
                component.set("v.salesOrder.Service_Center__r", null);
                helper.showToast(component, 'Error', 'New Sales Order is prevented in Selected Service Center!', "Error", "dismissible");
            } else {
                var account = component.get("v.salesOrder.Bill_to_Customer_No__r");
                if (record.Subsidiary_Company__c !== account.Subsidiary_Company__c) {
                    component.set("v.salesOrder.Service_Center__c", null);
                    component.set("v.salesOrder.Service_Center__r", null);
                    helper.showToast(component, 'Error', 'Selected Service Center does not belong to bill-to account subsidiary company!', "Error", "dismissible");
                } else {
                    //Ticket#27427 var salesOrder = component.get("v.salesOrder");
                    console.log('record+++++++'+JSON.stringify(record));
                    component.set("v.salesOrder.Service_Center__c", record.Id);
                    component.set("v.salesOrder.Service_Center__r", record);
                    component.set("v.salesOrder.Subsidiary_Company__c", record.Subsidiary_Company__c);
                    component.set("v.salesOrder.Subsidiary_Company__r", record.Subsidiary_Company__r);
                    component.set("v.salesOrder", salesOrder);
                }
            }
        }
        else {
            component.set("v.salesOrder.Service_Center__c", null);
            component.set("v.salesOrder.Subsidiary_Company__c", null);
            component.set("v.salesOrder.Subsidiary_Company__r", null);
            component.set("v.salesOrder.Is_New_D365_Project__c", false);
            component.set("v.salesOrder.D365_Project_ID__c", null);
        }

        //Ticket#21540 >>
        helper.validateServiceCenter(component, event);
        component.set("v.salesOrder", salesOrder);
        //Ticket#21540 <<
    },
    handlePrevailingWageJobChange : function(component, event, helper) {
        component.set("v.salesOrder", component.get("v.salesOrder")); //update the field on the sales order information tab
    },
    handlePayRuleChange : function(component, event, helper) {
        helper.validatePayRule(component, event);
    },
    handleOwnerChange : function(component, event, helper) {
		var salesOrder = component.get("v.salesOrder");
        var record = event.getParam("record");
        if (record) {
            salesOrder.OwnerId = record.Id;
            //include "attributes", owner field relationship without "attributes" causes JSON deserialize error in the apex controller
            salesOrder.Owner.attributes = { "type": 'User' };
        }
        else {
            salesOrder.OwnerId = null;
            salesOrder.Owner = null;
        }
        component.set("v.salesOrder", salesOrder);
    },
    handleBillingOwnerChange : function(component, event, helper) {
        var salesOrder = component.get("v.salesOrder");
        var record = event.getParam("record");
        if (record) {
            salesOrder.Billing_Owner__c = record.Id;
        }
        else {
            salesOrder.Billing_Owner__c = null;
        }
        component.set("v.salesOrder", salesOrder);
    },
    handleAccountExecutiveChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.salesOrder.Account_Executives__c", record.Id);            
        }
        else {
            component.set("v.salesOrder.Account_Executives__c", null);            
        }
    },
    handleProjectCoordinatorChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.salesOrder.Project_Coordinator__c", record.Id);
        }
        else {
            component.set("v.salesOrder.Project_Coordinator__c", null);
        }
    },
    handleNameOfWorkerResponsibleChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            console.log('record rsg ' +record.RSG_EIN__c);
            component.set("v.salesOrder.Name_of_Worker_Responsible__c", record.Id);
            component.set("v.salesOrder.Worker_Responsible__c", record.RSG_EIN__c);
        }
        else {
            component.set("v.salesOrder.Name_of_Worker_Responsible__c", null);
            component.set("v.salesOrder.Worker_Responsible__c", null);
        }
    },
    handleQuoteContactChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.salesOrder.Quote_Contact__c", record.Id);
        }
        else {
            component.set("v.salesOrder.Quote_Contact__c", null);
        }
    },
    handleOpportunityChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.salesOrder.Opportunity__c", record.Id);
        }
        else {
            component.set("v.salesOrder.Opportunity__c", null);
        }
    },
    handleQuoteDateChange : function(component, event, helper) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        helper.calculateSalesOrder(component, event, salesOrder, jobTaskWrappers,true);
    },
    handleSurchargeTypeChange : function(component, event, helper) {
        helper.validateSurchargeType(component, event);
    },
    handleSurchargePctChange : function(component, event, helper) {
        helper.validateSurchargePct(component, event);
    },
    handleSalesOrderTypeChange : function(component, event, helper) {
        helper.validateSOTypeChange(component, event);	//US114833
        helper.validateSalesOrderType(component, event);
    },
    handleEstimatedJobStartDateChange : function(component, event, helper) {
        component.set("v.recalculateDuration", false); //Ticket#24326
        helper.calculateEstimatedDateInfo(component, event, true);
    },
    handleEstimatedJobStartTimeChange : function(component, event, helper) {
        var salesOrder = component.get("v.salesOrder");
        if (salesOrder.Estimated_Job_Start_Time__c != null && salesOrder.Estimated_Job_End_Time__c != null) {
            helper.recalculateSalesLineDetails(component, event, true);
        }
    },
    handleEstimatedJobEndTimeChange : function(component, event, helper) {
        var salesOrder = component.get("v.salesOrder");
        if (salesOrder.Estimated_Job_Start_Time__c != null && salesOrder.Estimated_Job_End_Time__c != null) {
            helper.recalculateSalesLineDetails(component, event, true);
        }
    },
    handleIncludeWeekendChange : function(component, event, helper) {
        component.set("v.recalculateDuration", false); //Ticket#24326
        helper.calculateEstimatedDateInfo(component, event, false);
    },
    handleDurationChange : function(component, event, helper) {
        component.set("v.recalculateDuration", true); //Ticket#24326
        helper.calculateEstimatedDateInfo(component, event, true);
    },
    handleIncludeHolidayChange : function(component, event, helper) {
        component.set("v.recalculateDuration", false); //Ticket#24326
        helper.calculateEstimatedDateInfo(component, event, false);
    },
    /*
    handleBillingRuleChange : function(component, event, helper) {
        var record = event.getParam("record");
        var salesOrder = component.get("v.salesOrder");
        if (record) {
            salesOrder.Billing_Rule__c = record.Id;
        }
        else {
            salesOrder.Billing_Rule__c = null;
        }
        component.set("v.salesOrder", salesOrder);
        helper.calculateEstimatedDateInfo(component, event, false);
    },
     */
    //Ticket#21908
    handleBlockedChange : function (component, event, helper){
        component.set("v.salesOrder", component.get("v.salesOrder"));
    },
    /*
        Ticket#17051 - Rate Sheet change handler
     */
    handleRateSheetChange : function(component, event, helper) {
        var record = event.getParam("record");
        var salesOrder = component.get("v.salesOrder");
        if (record) {
            salesOrder.Rate_Sheet__c = record.Id;
        }
        else {
            salesOrder.Rate_Sheet__c = null;
        }
        component.set("v.salesOrder", salesOrder);
    },

    validateFields : function(component, event, helper) {
        var fields = new Array();
        //fields.push(component.find("document-type"));
        fields.push(component.find("owner"));
        fields.push(component.find("surcharge-type"));
        fields.push(component.find("service-center"));
        //fields.push(component.find("subsidiary-company"));
        fields.push(component.find("job-description"));
        fields.push(component.find("estimated-job-start-date"));
        fields.push(component.find("estimated-job-start-time"));
        fields.push(component.find("estimated-job-end-time"));
        fields.push(component.find("duration"));
        fields.push(component.find("account-executive"));

        //02.10.20 <<
        //fields.push(component.find("billing-rule"));
        //02.10.20 >>
        
        var salesOrder = component.get("v.salesOrder");
        if (salesOrder.Document_Type__c == 'Sales Order') {
            fields.push(component.find("document-status"));
        	fields.push(component.find("job-description"));
            if (salesOrder.Contract__c == null) {
                fields.push(component.find("quote-date"));
            }
            if (salesOrder.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c) {
                fields.push(component.find("worker-responsible"));
                fields.push(component.find("name-of-worker-responsible"));
            }
        }

        if (salesOrder.Prevailing_Wage_Job__c == true) {
            fields.push(component.find("pay-rule"));
        }

        if (salesOrder.Document_Type__c == 'Sales Quote') {
            fields.push(component.find("quote-type"));
            fields.push(component.find("quote-contact"));
            fields.push(component.find("quote-date"));
            if (salesOrder.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c) {
                fields.push(component.find("worker-responsible"));
                fields.push(component.find("name-of-worker-responsible"));
            }
        }

        if (salesOrder.Surcharge_Type__c == 'EEC Fee' || salesOrder.Surcharge_Type__c == 'Fuel Surcharge') {
            fields.push(component.find("surcharge-percentage"));
        }

        var allValid = fields.reduce(function(valid, inputField) {
            if (inputField) {                
            	//inputField.showHelpMessageIfInvalid();
            	if (Array.isArray(inputField)) {
                    for (var i = 0; i < inputField.length; i++) {
                        inputField[i].showHelpMessageIfInvalid();
                        valid = valid && inputField[i].get("v.validity").valid;
                    }
                }
                else {
                    inputField.showHelpMessageIfInvalid();
                    valid = valid && inputField.get("v.validity").valid;
                }
            }
            //return valid && inputField.get("v.validity").valid;
        	return valid;
        }, true);
        return allValid;
    }
})