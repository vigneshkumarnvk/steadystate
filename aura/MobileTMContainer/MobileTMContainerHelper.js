({
    getTM : function(component, event) {
        var page = component.get("v.page");
        var tmId = component.get("v.tmId");
        var params = { "tmId": tmId }
        this.callServerMethod(component, event, "c.getTM", params, function(response) {
            var tm = JSON.parse(response);
            //set Site State to avoid unsaved changes message due to the picklist control on the MobileTMDetails automatically add Site_Sate_c = "" if Site_Sate__c is not present, result TM changed event
            if (!tm.Site_State__c) {
                tm.Site_State__c = '';
            }
            component.set("v.tm", tm);
            component.set("v.unsavedChanges", false);
        });
    },
    confirmUnsavedChanges : function(component, event, page, resolve, reject) {
        var buttons = [];
        buttons.push({
            "label": 'No',
            "variant": 'neutral',
            "action": {"callback": this.cancelCallback.bind(this, component, event, reject)}
        });
        buttons.push({
            "label": 'Yes',
            "variant": 'brand',
            "action": {"callback": this.discardChanges.bind(this, component, event, page, resolve)}
        });
        this.openModal(component, event, 'Unsaved Changes', 'You have unsaved changes. Are you sure you want to navigate away?', buttons, null, null, null);
    },
    discardChanges : function(component, event, page, resolve) {
        this.closeModal(component, event);
        component.set("v.unsavedChanges", false);
        //this.navigateToTab(component, event, page);
        if (resolve) {
            resolve();
        }
        else {
            this.navigateToTab(component, event, page);
        }
    },
    uploadFile : function(component, event) {
        var tmId = component.get("v.tm.Id");

        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        var params = { "recordId": tmId, "callback": this.uploadFileCallback.bind(this, component, event) };
        this.openModal(component, event, 'Upload File', null, buttons, 'c:TMUploadFile', params, 'small');
    },
    uploadFileCallback : function(component, event) {
        this.closeModal(component, event);
    },
    cancelCallback : function(component, event, reject) {
        this.closeModal(component, event);
        if (reject) {
            reject();
        }
    },
    navigateToTab : function(component, event, page) {
        switch(page) {
            case 'home':
                var tmNavigationEvent = component.getEvent("tmNavigationEvent");
                tmNavigationEvent.setParams({ "page": "home" });
                tmNavigationEvent.fire();
                break;
            case 'details':
                component.set('v.page', page);
                break;
            case 'labor':
                component.set('v.page', page);
                break;
            case 'equipment':
                component.set('v.page', page);
                break;
            case 'material':
                component.set('v.page', page);
                break;
            case 'subcontractor':
                component.set('v.page', page);
                break;
            case 'waste disposal':
                component.set('v.page', page);
                break;
            case 'signature':
                component.set("v.page", page)
                break;
            case 'upload':
                break;
        }
    }
});