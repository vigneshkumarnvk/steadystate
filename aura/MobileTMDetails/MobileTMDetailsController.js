({
    doInit : function(component, event, helper) {
    },
    handleTMChange : function(component, event, helper) {
        component.set("v.unsavedChanges", true);
    },
    handleStatusChange : function(component, event, helper) {
        if (component.get("v.tm.Status__c") == 'Scheduled') {
            var dt = $A.localizationService.formatDate(new Date(), "yyyy-MM-dd");
            component.set("v.tm.Scheduled_Date__c", dt);
        }
    },
    handleSiteContactChange : function(component, event, helper) {
        var record = event.getParam("record");
        var tm = component.get("v.tm");
        if (record) {
            tm.Site_Contact_2__c = record.Id;
            tm.Site_Contact_2__r = record;

            //Ticket#21076 >>
            if(record.MobilePhone != null) {
                tm.Site_Phone_No__c = record.MobilePhone;
            } else if (record.Phone != null) {
                tm.Site_Phone_No__c = record.Phone;
            }
            //Ticket#21076 <<

            tm.Site_Email_Address__c = record.Email;
        }
        else {
            tm.Site_Contact_2__c = null;
            tm.Site_Contact_2__r = null;
            tm.Site_Phone_No__c = null;
            tm.Site_Email_Address__c = null;
        }
        component.set("v.tm", tm)
        /*
        var record = event.getParam("record");
        if (record != null) {
            component.set("v.tm.Site_Contact_2__c", record.Contact.Id);
            component.set("v.tm.Site_Contact_2__r", record.Contact);
            component.set("v.tm.Site_Phone_No__c", record.Phone);
            component.set("v.tm.Site_Email_Address__c", record.Email);
        }
        else {
            component.set("v.tm.Site_Contact_2__c", null);
            component.set("v.tm.Site_Contact_2__r", null);
            component.set("v.tm.Site_Phone_No__c", null);
            component.set("v.tm.Site_Email_Address__c", null);
        }
         */
    },
    handleBillingContactChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record != null) {
            component.set("v.tm.Contact__c", record.Id);
            component.set("v.tm.Contact__r", record);
        }
        else {
            component.set("v.tm.Contact__c", null);
            component.set("v.tm.Contact__r", null);
        }
    },
    changeStatusToScheduled : function(component, event, helper) {
        helper.confirmStatusChange(component, event);
    },
    doSave : function(component, event, helper) {
        try {
            if (helper.validate(component, event)) {
                helper.saveTM(component, event);
            }
        }
        catch(err) {
            helper.showToast(component, "Error", err.message, "error", "dismissible");
        }
    }
})