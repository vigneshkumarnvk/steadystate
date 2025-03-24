({
    confirmCopyManifest : function(component, event) {
        var buttons = [];
        buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.copyManifestCallback.bind(this, component, event) }});
        this.openModal(component, event, 'Copy Manifest', 'Are you sure you want to manifest BOL from this line to all the lines below it?', buttons, null, null, null);
    },
    copyManifestCallback : function(component, event) {
        this.closeModal(component, event);
        this.copyManifest(component, event);
    },
    copyManifest : function(component, event) {
        var rowIndex = event.getParam("rowIndex");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        for (var i = rowIndex + 1; i < jobTaskWrapper.TMLines.length; i++) {
            jobTaskWrapper.TMLines[i].BOL_Manifest__c = jobTaskWrapper.TMLines[rowIndex].BOL_Manifest__c;
        }
        component.set("v.jobTaskWrapper", jobTaskWrapper);
    },
});