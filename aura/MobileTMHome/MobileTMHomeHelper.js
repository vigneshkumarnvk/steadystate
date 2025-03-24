({
    getTMs : function(component, event) {
        var ownership = component.get("v.ownership");
        var scheduledDate = component.get("v.scheduledDate");
        var keyword = component.get("v.keyword");

        //ticket 19130 <<
        if (keyword) {
            keyword = keyword.trim();
        }
        //ticket 19130 >>

        //cache control <<
        //var params = { "ownership": ownership, "scheduledDate": scheduledDate, "keyword": keyword };
        var version = component.get("v.version");
        var params = { "ownership": ownership, "scheduledDate": scheduledDate, "keyword": keyword, "version": version };
        //cache control >>

        this.callServerMethod(component, event, "c.getTMs", params, function(response) {
            var tms = JSON.parse(response);
            for (var i = 0; i < tms.length; i++) {
                var tm = tms[i];

                if (tm.Scheduled_Date__c != null) {
                    tm.formattedScheduledDate = $A.localizationService.formatDate(tm.Scheduled_Date__c, "MM-dd-yyyy")
                }
                var parts = [];
                if (tm.Site_Street__c) {
                    parts.push(tm.Site_Street__c + ',');
                }

                if (tm.Site_City__c) {
                    parts.push(tm.Site_City__c + ',');
                }

                if (tm.Site_State__c) {
                    parts.push(tm.Site_State__c);
                }

                if (tm.Site_Postal_Code__c) {
                    parts.push(tm.Site_Postal_Code__c);
                }
                tm.SiteLocation = parts.join(' ');
            }
            component.set("v.tms", tms);
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
    openTM : function(component, event, tmId) {
        var params = { "tmId": tmId, page: "details" }

        //this.navigateToComponent(component, event, "c:MobileTMContainer", params);
    }
});