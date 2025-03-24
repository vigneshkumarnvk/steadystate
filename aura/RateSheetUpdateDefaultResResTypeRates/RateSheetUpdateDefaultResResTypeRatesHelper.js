({
    promptQuestion : function (component, event) {
        var buttons = [];
        this.callServerMethod(component, event, "c.getSetupData", null, function(response) {
            var setupData = JSON.parse(response);
            component.set("v.setupData", setupData);
            if(setupData.User.Profile.Name === 'System Administrator') {
                buttons.push({
                    "label": 'No',
                    "variant": 'neutral',
                    "action": {"callback": this.cancelConvert.bind(this, component, event)}
                });
                buttons.push({
                    "label": 'Yes',
                    "variant": 'brand',
                    "action": {"callback": this.updateDefaultResAndResTypePriceByRateSheet.bind(this, component, event)}
                });
                this.openModal(component, event, "Mass Populate System Default Rate", 'Are you sure you want to update company default resource and resource type rate using this rate sheet?', buttons, null, null, null);
            } else {
                buttons.push({
                    "label": 'No',
                    "variant": 'neutral',
                    "action": {"callback": this.cancelConvert.bind(this, component, event)}
                });
                this.openModal(component, event, "Mass Populate System Default Rate", 'Only System Administrator can perform this action!', buttons, null, null, null);
            }
        }, function (error){
            this.navigateToSObject(component, event, recordId);
            this.showToast(component, "Error", error, "error", "dismissible");
        });
    },
    updateDefaultResAndResTypePriceByRateSheet : function (component, event){
        this.closeModal(component, event);
        var recordId = component.get("v.rateSheetId");
        var params = { "rateSheetId": recordId };
        this.callServerMethod(component, event, "c.updateDefaultResAndResTypePriceByRateSheet", params, function (response) {
            this.closeModal(component, event);
            this.navigateToSObject(component, event, recordId);
            this.showToast(component, "Success", 'Default resource/resource type rate update completed!', "success", "dismissible");
        }, function (error) {
            this.navigateToSObject(component, event, recordId);
            this.showToast(component, "Error", error, "error", "dismissible");
        });
    },
    cancelConvert : function(component, event) {
        var recordId = component.get("v.rateSheetId");
        this.closeModal(component, event);
        this.navigateToSObject(component, event, recordId);
    },
    cancelCreationConfirmed : function(component, event) {
        var recordId = component.get("v.rateSheetId");
        this.closeModal(component, event);
        this.navigateToSObject(component, event, recordId);
    },
});