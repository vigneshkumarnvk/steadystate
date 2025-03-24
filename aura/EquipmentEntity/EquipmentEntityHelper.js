({
    scanResource : function(component, event) {
		var data = component.get("v.data");
        var resourceTypeId = data.Resource_Type__c;
        if (!resourceTypeId) {
            this.showToast(component, 'error', 'T&M', 'Please choose a resource type first.', 'dismissable');
            return;
        }
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
	},
    integerToTime : function(timeValue) {
        var timeString;
        if (timeValue != null) {
            var timeValue = timeValue / 1000;
            var h = Math.floor(timeValue / 60 / 60);
            var timeValue = (timeValue % (60 * 60));
            var m = Math.floor(timeValue / 60);
            var s = (timeValue % 60);
            
            var hours = h < 10 ? '0' + h : h;
            var minutes = m < 10 ? '0' + m : m;
            var seconds = s < 10 ? '0' + s : s;
            timeString = hours + ':' + minutes + ':' + seconds + '.000Z'
        }
        return timeString;
    },
    timeToInteger : function(timeString) {
        var timeValue;
        if (timeString) {
            var arr = timeString.split(':');
            var h = arr[0];
            var m = arr[1];
            var s = arr[2];
            timeValue = (h * 60 * 60 + m * 60 + parseInt(s)) * 1000;
        }
        return timeValue;
    },
    validateTimeFields : function(component, jobStartTime, jobEndTime) {
        if (jobStartTime && jobEndTime) {
            if (jobStartTime > jobEndTime) {
                this.showToast(component, 'error', 'T&M', 'Job Start Time must NOT be greater than Job End Time.', 'dismissable');
                return false;
            }
        }
        return true;
    }
})