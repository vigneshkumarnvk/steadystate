({
    handleTaxAreaChange : function(component, event, helper) {
        var tm = component.get("v.tm");
        var record = event.getParam("record");
        if (record != null) {
            tm.Tax_Area__c = record.Id;
        }
        else {
            tm.Tax_Area__c = null;
        }
        component.set("v.tm", tm);
    },
    handleSiteAddressChange : function(component, event, helper) {
        var record = event.getParam("record");
        var tm = component.get("v.tm");
        if (record) {
            tm.Alternate_Site_Address__c = record.Id;
            tm.Site_Name__c = record.Name;
            if (record.Contact__r) {
                tm.Site_Contact__c = record.Contact__r.Name;
                tm.Site_Contact_2__c = record.Contact__r.Id;
                tm.Site_Contact_2__r = record.Contact__r;
            }
            tm.Site_Street__c = record.Site_Street__c;
            tm.Site_City__c = record.Site_City__c;
            tm.Site_State__c = record.Site_State__c;
            tm.Site_Postal_Code__c = record.Site_Postal_Code__c;
            tm.Site_Country__c = record.Site_Country__c;
            tm.Site_Phone_No__c = record.Site_Phone_No__c;
            tm.Site_Email_Address__c = record.Site_Email_Address__c;
            tm.Tax_Area__c = record.Tax_Area__c;
            tm.Tax_Area__r = record.Tax_Area__r;
            tm.Print_Site_Name__c = record.Print_Site_Name__c;
        }
        else {
            tm.Alternate_Site_Address__c = null;
            tm.Site_Name__c = null;
            tm.Site_Contact__c = null;
            tm.Site_Contact_2__c = null;
            tm.Site_Contact_2__r = null;
            tm.Site_Street__c = null;
            tm.Site_City__c = null;
            tm.Site_State__c = null;
            tm.Site_Postal_Code__c = null;
            tm.Site_Country__c = null;
            tm.Site_Phone_No__c = null;
            tm.Site_Email_Address__c = null;
            tm.Tax_Area__c = null;
            tm.Tax_Area__r = null;
            tm.Print_Site_Name__c = false;
        }
        component.set("v.tm", tm);
    },
    handleSiteContactChange : function(component, event, helper) {
        var record = event.getParam("record");
        var tm = component.get("v.tm");
        if (record) {
            tm.Site_Contact_2__c = record.Id;

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
            tm.Site_Phone_No__c = null;
            tm.Site_Email_Address__c = null;
        }
        component.set("v.tm", tm)
    },
    validateFields : function(component, event, helper) {
        var params = event.getParams().arguments;
        var validateAsStatus = params.validateAsStatus;

        var fields = new Array();
        fields.push(component.find("tax-area"));

        var allValid = fields.reduce(function(valid, inputField) {
            if (inputField) {
                inputField.showHelpMessageIfInvalid();
            }
            return valid && inputField.get("v.validity").valid;
        }, true);

        return allValid;
    }
});