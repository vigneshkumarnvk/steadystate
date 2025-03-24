({
	doInit : function(component, event, helper) {
		//alert(JSON.stringify(component.get("v.record")));
	}, 
    handleContactChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record != null) {
            component.set("v.record.Contact__c", record.Id);
            component.set("v.record.Site_Phone_No__c", record.Phone);
            component.set("v.record.Site_Email_Address__c", record.Email);
            component.set("v.record.Site_Contact__c", record.Name);
        }
        else {
            component.set("v.record.Contact__c", null);
            component.set("v.record.Site_Phone_No__c", null);
            component.set("v.record.Site_Email_Address__c", null);
            component.set("v.record.Site_Contact__c", null);
        }
    },
    handleTaxAreaChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.record.Tax_Area__c", record.Id);
        }
        else {
            component.set("v.record.Tax_Area__c", null);
        }
    },
    doSave : function(component, event, helper) {
        helper.createSiteAddress(component, event);
    }
})