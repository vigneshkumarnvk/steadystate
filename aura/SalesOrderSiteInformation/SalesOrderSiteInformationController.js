({
	doInit : function(component, event, helper) {
		//helper.setNewSiteAddressRecordParams(component, event);
	},
    setNewSiteAddressRecordParams : function(component, event, helper) {
        helper.setNewSiteAddressRecordParams(component, event);
        helper.setNewSiteContactRecordParams(component, event);
    },
    setNewSiteContactRecordParams : function(component, event, helper) {
        helper.setNewSiteContactRecordParams(component, event);
    },
handleCreateSalesOrderMessage : function (component, event, helper) {
        helper.handleCreateSalesOrderMessage(component, event);
    },
    handleSiteAddressChange : function(component, event, helper) {
		var record = event.getParam("record");
        var salesOrder = component.get("v.salesOrder");
        if (record) {
            salesOrder.Alternate_Site_Address__c = record.Id;
            salesOrder.Site_Name__c = record.Name;
            if (record.Contact__r) {
                //salesOrder.Site_Contact__c = record.Contact__r.Name;  need to be enabled in uat2 and production. Site contact is a lookup in dev2
            	salesOrder.Site_Contact_2__c = record.Contact__r.Id;
                salesOrder.Site_Contact_2__r = record.Contact__r;
            }
            salesOrder.Site_Street__c = record.Site_Street__c;
            salesOrder.Site_City__c = record.Site_City__c;
            salesOrder.Site_State__c = record.Site_State__c;
            salesOrder.Site_Postal_Code__c = record.Site_Postal_Code__c;
            salesOrder.Site_Country__c = record.Site_Country__c;
            salesOrder.Site_Phone_No__c = record.Site_Phone_No__c;
            salesOrder.Site_Email_Address__c = record.Site_Email_Address__c;
            salesOrder.Tax_Area__c = record.Tax_Area__c;
            salesOrder.Tax_Area__r = record.Tax_Area__r;
            salesOrder.Print_Site_Name__c = record.Print_Site_Name__c;
//  Bug#77410
            salesOrder.EPA_ID__c = null;
            salesOrder.EqaiGeneratorId__c = null;
        }
        else {
            salesOrder.Alternate_Site_Address__c = null;
            salesOrder.Site_Name__c = null;
            //salesOrder.Site_Contact__c = null;
            salesOrder.Site_Contact_2__c = null;
            salesOrder.Site_Contact_2__r = null;
            salesOrder.Site_Street__c = null;
            salesOrder.Site_City__c = null;
            salesOrder.Site_State__c = null;
            salesOrder.Site_Postal_Code__c = null;
            salesOrder.Site_Country__c = null;
            salesOrder.Site_Phone_No__c = null;
            salesOrder.Site_Email_Address__c = null;
            salesOrder.Tax_Area__c = null;
            salesOrder.Tax_Area__r = null;
            salesOrder.Print_Site_Name__c = false;
//  Bug#77410
            salesOrder.EPA_ID__c = null;
            salesOrder.EqaiGeneratorId__c = null;
        }
        component.set("v.salesOrder", salesOrder);
	},
    handlevalueChange : function(component, event, helper) {
        
    },
    handleSiteContactChange : function(component, event, helper) {
        var record = event.getParam("record");
        var salesOrder = component.get("v.salesOrder");
        if (record) {
            salesOrder.Site_Contact_2__c = record.Id;

            //Ticket#21076 >>
            if(record.MobilePhone != null) {
                salesOrder.Site_Phone_No__c = record.MobilePhone;
            } else if (record.Phone != null) {
                salesOrder.Site_Phone_No__c = record.Phone;
            }
            //Ticket#21076 <<

            salesOrder.Site_Email_Address__c = record.Email;
        }
        else {
            salesOrder.Site_Contact_2__c = null;
            salesOrder.Site_Phone_No__c = null;
            salesOrder.Site_Email_Address__c = null;
        }
        component.set("v.salesOrder", salesOrder)
    },
    handleTaxAreaChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.salesOrder.Tax_Area__c", record.Id);
            var salesOrder = component.get("v.salesOrder");
            var jobTaskWrappers = component.get("v.jobTaskWrappers");
            helper.calculateSalesOrder(component, event, salesOrder, jobTaskWrappers, false);
        }
        else {
            component.set("v.salesOrder.Tax_Area__c", null);
        }
	},
    handleTaxLiableChange : function(component, event, helper) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        helper.updateTaxGroup(component, event,salesOrder,jobTaskWrappers);
        helper.calculateSalesOrder(component, event, salesOrder, jobTaskWrappers, false);
    },
	navigateToCreateGeneratorLookup : function (component, event, helper) {
        helper.showCreateGeneratorLookup(component, event);
    },
    validateFields : function(component, event, helper) {
        var fields = new Array();
        fields.push(component.find("tax-area"));
        //ticket 19895 <<
        fields.push(component.find("site-street"));
        fields.push(component.find("site-city"));
        fields.push(component.find("site-state"));
        fields.push(component.find("site-postal-code"));
        fields.push(component.find("site-country"));
        //ticket 19895 >>

        var allValid = fields.reduce(function(valid, inputField) {
            if (inputField) {
            	inputField.showHelpMessageIfInvalid();
            }
            return valid && inputField.get("v.validity").valid;
        }, true);
        
        return allValid;
    },
    
    handleSiteStreetChange: function(component, event, helper) {
        helper.clearGeneratorAndEpaFields(component);
    },

    handleSiteCityChange: function(component, event, helper) {
        helper.clearGeneratorAndEpaFields(component);
    },

    handleSiteStateChange: function(component, event, helper) {
        helper.clearGeneratorAndEpaFields(component);
    },

    handleSiteNameChange: function(component, event, helper) {
        var salesOrder = component.get("v.salesOrder");
    var siteName = salesOrder.Site_Name__c;
    var generatorId = salesOrder.EqaiGeneratorId__c;

    if (!generatorId) {
        if (siteName && siteName.length > 40) {
            helper.showToast(component, 'Error', 'Site Name value is too long (max length = 40). Please edit the Site Name and Save.', "Error", "dismissible");
            return;
        }
    }
        helper.clearGeneratorAndEpaFields(component);
    },

    handleSiteCountryChange: function(component, event, helper) {
        helper.clearGeneratorAndEpaFields(component);
    },

    handleSitePostalCodeChange: function(component, event, helper) {
        helper.clearGeneratorAndEpaFields(component);
    },
    handleMessage: function (component, event, helper) {
        helper.handleMessage(component, event);
    },
    clearGeneratorId: function(component, event, helper) {
        let salesOrder = component.get("v.salesOrder");
        salesOrder.Site_Name__c = null;
        salesOrder.Site_Street__c = null;
        salesOrder.Site_City__c = null;
        salesOrder.Site_State__c = null;
        salesOrder.Site_Postal_Code__c = null;
        salesOrder.Site_Country__c = null;
        salesOrder.EqaiGeneratorId__c = null;
        salesOrder.EPA_ID__c = null;
        //component.set("v.salesOrder.EqaiGeneratorId__c", ""); // Clear the value
        component.set("v.salesOrder", salesOrder);
    },
        handleInputGeneratorChange: function(component, event) {
        // Get updated value
        var newValue = event.getSource().get("v.value");
        // Set value to the attribute
        component.set("v.salesOrder.EqaiGeneratorId__c", newValue);
    },
})
