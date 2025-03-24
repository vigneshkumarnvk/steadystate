({
	getData : function(component) {
        var keyword = component.find("searchbox").get("v.value");
      	var userScope = component.get("v.userScope");
        var scheduledDate = component.get("v.scheduledDate");
        if (!scheduledDate) {
            scheduledDate = null;
        }
        var resource = component.get("v.resource");

		var action = component.get("c.Search");
        
        //cache <<
        //var params = { "keyword": keyword, "scheduledDate": scheduledDate, "userScope": userScope, "resource": resource };
        var version = component.get("v.version");
        var params = { "keyword": keyword, "scheduledDate": scheduledDate, "userScope": userScope, "resource": resource, "version": version };
        //cache >>
        
        this.callServerMethod(component, event, "c.Search", params, function(response) {
            var rows = response;
            for (var i = 0; i < rows.length; i++) {
                var row = rows[i];
                if (row.Sales_Order__r) {
                    row.SalesOrderNumber = row.Sales_Order__r.Name;
                }
                if (row.Service_Center__r) {
                    row.ServiceCenterName = row.Service_Center__r.Name;
                    row.ServiceCenterId = row.Service_Center__r.Id;
                }
                if (row.Bill_to_Customer__r) {
                    row.CustomerName = row.Bill_to_Customer__r.Name;
                }
                var siteAddress1 = '';
                if (row.Site_Street__c) {
                    siteAddress1 = row.Site_Street__c;
                }
                
                var siteAddress2 = '';
                if (row.Site_City__c) {
                    siteAddress2 = row.Site_City__c;
                }
                if (row.Site_State__c) {
                    if (siteAddress2 != '') {
                        siteAddress2 += ', ';
                    }
                    siteAddress2 += row.Site_State__c;
                }
                if (row.Site_Postal_Code__c) {
                    if (siteAddress2 != '') {
                        siteAddress2 += ' ';
                    }
                    siteAddress2 = row.Site_Postal_Code__c;
                }
                
                row.SiteLocation = '';
                if (siteAddress1 != '') {
                    row.SiteLocation = siteAddress1;
                }
                if (siteAddress2 != '') {
                    row.SiteLocation += '\n' + siteAddress2
                }
            }
        	component.set("v.data", rows);
    	},
		//cache <<
        function(error) {
            if (error == "VERSION_ERROR") {
                component.set("v.version", "VERSION_ERROR");
                this.showToast(component, "error", "Error", "Mobile T&M version has been updated. Please follow the instructions on the screen to load the new version.", 'dismissible');
            }
            else { 
                this.showToast(component, "error", "Error", error, 'dismissible');
            }
        }
        //cache >>
		); 
	},    
	getBarcode : function(component, event) {
		component.find("scanner").scan(component, event, this.scanCallback.bind(this));  
    },
    scanCallback : function(component, event, barcode) {
        component.set("v.barcode", barcode);
	},
    getUserInfo : function(component) {        
		var action = component.get("c.GetUserInfo");
        action.setCallback(this, function(response) {
        	var state = response.getState();
            if (state == "SUCCESS") {
                component.set("v.userInfo", response.getReturnValue());
            } 
            else if (state == "INCOMPLETE") {
                this.showToast(component, 'error', 'T&M', 'Connection interrupted! Please try again.', 'dismissable');
            }
            else if (state == "ERROR") {
                var message = 'An unexpected error has occurred!';
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        message = errors[0].message;
                    }
                }
                this.showToast(component, 'error', 'T&M', message, 'dismissable');
            }
        });
        $A.enqueueAction(action);
	},
    getResources : function(component, event) {  
        this.callServerMethod(component, event, "c.GetLaborResources", null, function(response) {
            var options = [{"label": '', "value": ''}];
            var resources = response;
            if (resources) {
                for (var i = 0; i < resources.length; i++) {
                    var resource = resources[i];
                    options.push({"label": resource.Description__c, "value": resource.Description__c });
                }
            }
            component.set("v.resources", options);
        });
	},
    showToast : function(component, variant, title, message, mode) {
        component.find('notifLib').showToast({
            "variant": variant,
            "header": title,
            "mode": mode,
            "message": message,
            closeCallback: function() {
            }
        });
    },
})