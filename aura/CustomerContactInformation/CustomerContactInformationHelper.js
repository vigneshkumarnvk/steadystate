({
	getStagingContact : function(component, event) {
        component.set("v.message", null);
        
        var recordId = component.get("v.recordId");
        var params = { "recordId": recordId };
        this.callServerMethod(component, event, "c.getStagingContactById", params, function(response) {
            response.Verify_Information__c = false; //init to false
            component.set("v.contact", response);
			component.set("v.changesPending", false);
            this.updateLastUpdateInfo(component, event);
        })
	},
    validateAddressAndSave : function(component, event) {
        component.set("v.message", null);
        var contact = component.get("v.contact");
        var params = { "JSONContact": JSON.stringify(contact) };
        this.callServerMethod(
            component, 
            event, 
            "c.validateBillingAddress", 
            params, 
            function(USPSAddress) {
                if (USPSAddress.Address2 != contact.Street__c
                    	|| USPSAddress.City != contact.City__c
                    	|| USPSAddress.State != contact.State__c
                    	|| USPSAddress.Zip5 != contact.Postal_Code__c) {
 
                    var buttons = [];
                    buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.addressOverwriteNoCallback.bind(this, component, event) }});
                    buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.addressOverwriteYesCallback.bind(this, component, event, USPSAddress) }});
                    
                    var message = '<p>Do you want to use the suggested address below?</p><br/>';
                    message += '<p>';
                    message += '<div>' + USPSAddress.Address2 + '</div>'
                    message += '<div>' +  USPSAddress.City + ', ' + USPSAddress.State + ' ' + USPSAddress.Zip5 + '</div>';
                    message += '</p>';
            		this.openModal(component, event, 'Address Validation', message, buttons, null, null);
                }
                else {
                    this.saveContact(component, event);
                }
            }, 
            function(err) {
                component.set("v.message", err);
            }
        );
    },
    addressOverwriteYesCallback : function(component, event, USPSAddress) {
        var contact = component.get("v.contact");
        contact.Street__c = USPSAddress.Address2;
        contact.City__c = USPSAddress.City;
        contact.State__c = USPSAddress.State;
        contact.Postal_Code__c = USPSAddress.Zip5;
        component.set("v.contact", contact);
        
        this.saveContact(component, event);
    	this.closeModal(component, event);
	},
    addressOverwriteNoCallback : function(component, event) {
        this.saveContact(component, event);
        this.closeModal(component, event);
    },
    saveContact : function(component, event) {
        var contact = component.get("v.contact");
        var loginInfo = component.get("v.loginInfo");
        contact.Last_Updated_By__c = loginInfo.PortalLogin.Id;
        var params = { "JSONContact": JSON.stringify(contact) };
        this.callServerMethod(component, event, "c.saveStagingContact", params, function(response) {
            component.set("v.message", "The contact information is saved.")
            component.set("v.contact", response);
            component.set("v.changesPending", false);
            this.updateLastUpdateInfo(component, event);
        })
    },
    updateLastUpdateInfo : function(component, event) {
        var contact = component.get("v.contact");
        if (contact.Last_Updated_By__r != null) {
        	var info = 'Last updated by ' + contact.Last_Updated_By__r.Name + ' on ' + $A.localizationService.formatDate(contact.Last_Updated_Date__c, "MM/dd/yyyy hh:mm A");;
        	component.set("v.lastUpdateInfo", info);
        }
    }
})