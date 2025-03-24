({
    //validate resource type
    validateResourceType : function(component, event) {
        var data = component.get("v.data");
        var params = { "JSONTMLine": JSON.stringify(data)};
        this.callServerMethod(component, event, "c.validateResourceType", params, function(response) {
            var tmLine = JSON.parse(response);
            Object.assign(data, tmLine);
        })
    },
    //validate resource type
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
    validateTimeFields : function(component, jobStartTime, jobEndTime, siteStartTime, siteEndTime, lunchStartTime, lunchEndTime) {
        if (jobStartTime && jobEndTime) {
            if (jobStartTime > jobEndTime) {
                this.showToast(component, 'error', 'T&M', 'Job Start Time must NOT be greater than Job End Time.', 'dismissable');
                return false;
            }
        }
        
        if (siteStartTime && siteEndTime) {
            if (siteStartTime > siteEndTime) {
                this.showToast(component, 'error', 'T&M', 'Site Start Time must NOT be greater than Site End Time.', 'dismissable');
                return false;
            }
        }
        
        if (jobStartTime && siteStartTime) {
            if (jobStartTime > siteStartTime) {
                this.showToast(component, 'error', 'T&M', 'Job Start Time must NOT be greater than Site Start Time.', 'dismissable');
                return false;
            }
        }
        
        if (jobEndTime && siteEndTime) {
            if (siteEndTime > jobEndTime) {
                this.showToast(component, 'error', 'T&M', 'Site End Time must NOT be greater than Job End Time.', 'dismissable');
                return false;
            }
        }
        
        if (lunchStartTime && lunchEndTime) {
            if (lunchStartTime > lunchEndTime) {
                this.showToast(component, 'error', 'T&M', 'Lunch Start Time must NOT be greater than Lunch End Time.', 'dismissable');
                return false;
            }
        }
        
        if (lunchStartTime && siteStartTime) {
            if (siteStartTime > lunchStartTime) {
                this.showToast(component, 'error', 'T&M', 'Site Start Time must NOT be greater than Lunch Start Time.', 'dismissable');
                return false;
            }
        }
        
        if (lunchEndTime && siteEndTime) {
            if (lunchEndTime > siteEndTime) {
                this.showToast(component, 'error', 'T&M', 'Lunch End Time must NOT be greater than Site End Time.', 'dismissable');
                return false;
            }
        }
        
        return true;
    },
    calculateHours : function(component, event) {
        var data = component.get("v.data");
        var time = 0;
        if (data && data.Deleted != true) {
            if (data.Job_End_Time__c && data.Job_Start_Time__c) {
                var startTime = this.timeToInteger(data.Job_Start_Time__c) ;
                var endTime = this.timeToInteger(data.Job_End_Time__c) ;
                //05.17.2019 <<
                //time += endTime - startTime;
                if (startTime > endTime) {
                    var midnight = this.timeToInteger('24:00:00');
                    time += (midnight - startTime) + endTime;
                }
                else {
                    time += endTime - startTime;
                }
                //05.17.2019 >>
                
                //12.30.2019 <<
                if (data.Lunch_End_Time__c && data.Lunch_Start_Time__c) {
                    var lunchStartTime = this.timeToInteger(data.Lunch_Start_Time__c);
                	var lunchEndTime = this.timeToInteger(data.Lunch_End_Time__c);
                    time -= (lunchEndTime-lunchStartTime);
                }
                //12.30.2019 >>
            }            
        }
		var timeString = this.integerToTime(time);
        var items = timeString.split(':');
		timeString = parseInt(items[0]) + ' hours';
        if (parseInt(items[1]) != 0) {
            timeString += ' ' + items[1] + ' minutes';
        }
        component.set("v.hours", timeString);
    }
})