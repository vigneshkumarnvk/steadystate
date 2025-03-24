({
    scanResource : function(component, event) {
		var data = component.get("v.data");
		component.find("resourceScanner").scan(component, event, this.scanResourceCallback.bind(this));  
    },
    scanResourceCallback : function(component, event, barcode) {
        if (barcode != '') {
            this.getResource(component, event, barcode);
        }
	},
	getResource : function(component, event, resourceNo) {
        var data = component.get("v.data");
        var serviceCenterId = data.Service_Center__c;
        var resourceTypeId = data.Resource_Type__c;
        
        var params = { "serviceCenterId": serviceCenterId, "resourceTypeId": resourceTypeId, "resourceNo": resourceNo };
        this.callServerMethod(component, event, "c.GetResource", params, function(resource){
            if (resource) {
                component.set("v.data.Resource__c", resource.Id);
                component.set("v.data.Resource__r", resource);
            }
            else {
                component.set("v.data.Resource__c", null);
                component.set("v.data.Resource__r", null);
                this.showToast(component, 'error', 'T&M', 'Resource ' + resourceNo + ' does not exist!', 'dismissable');
            }
        });
	}
})