({
	getStagingAccount : function(component, event) {
        component.set("v.message", null);
        
        var recordId = component.get("v.recordId");
        var params = { "recordId": recordId };
        this.callServerMethod(component, event, "c.getStagingAccountById", params, function(response) {
            response.Verify_Information__c = false; //init to false
            component.set("v.account", response);
			component.set("v.changesPending", false);
            this.updateLastUpdateInfo(component, event);
        })
	},
    validateAddressAndSave : function(component, event) {
        try {
            component.set("v.message", null);
            var account = component.get("v.account");
            var params = { "JSONAccount": JSON.stringify(account) };
            this.callServerMethod(
                component, 
                event, 
                "c.validateBillingAddress", 
                params, 
                function(USPSAddress) {
                    if (USPSAddress.Address2 != account.Billing_Street__c
                            || USPSAddress.City != account.Billing_City__c
                            || USPSAddress.State != account.Billing_State__c
                            || USPSAddress.Zip5 != account.Billing_Postal_Code__c) {
     
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
                        this.saveAccount(component, event);
                    }
                }, 
                function(err) {
                    component.set("v.message", err);
                }
            );
        }
        catch(err) {
            component.set("v.message", err);
        }
    },
    addressOverwriteYesCallback : function(component, event, USPSAddress) {
        var account = component.get("v.account");
        account.Billing_Street__c = USPSAddress.Address2;
        account.Billing_City__c = USPSAddress.City;
        account.Billing_State__c = USPSAddress.State;
        account.Billing_Postal_Code__c = USPSAddress.Zip5;
        component.set("v.account", account);
        
        this.saveAccount(component, event);
    	this.closeModal(component, event);
	},
    addressOverwriteNoCallback : function(component, event) {
        this.saveAccount(component, event);
        this.closeModal(component, event);
    },
    saveAccount : function(component, event) {
        var account = component.get("v.account"); 
        var loginInfo = component.get("v.loginInfo");
        account.Last_Updated_By__c = loginInfo.PortalLogin.Id;
        var params = { "JSONAccount": JSON.stringify(account) };
        this.callServerMethod(component, event, "c.saveStagingAccount", params, function(response) {
            component.set("v.message", "The address is saved.")
            component.set("v.account", response);
            component.set("v.changesPending", false);
            this.updateLastUpdateInfo(component, event);
        }, function(err) {
            component.set("v.message", err);
        })
    },
    updateLastUpdateInfo : function(component, event) {
        var account = component.get("v.account");
        if (account.Last_Updated_By__r != null) {
        	var info = 'Last updated by ' + account.Last_Updated_By__r.Name + ' on ' + $A.localizationService.formatDate(account.Last_Updated_Date__c, "MM/dd/yyyy hh:mm A");;
        	component.set("v.lastUpdateInfo", info);
        }
    }
})