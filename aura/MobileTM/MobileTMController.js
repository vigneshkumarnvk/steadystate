({
    //cache control <<
    doInit : function(component, event, helper) {
        var device = $A.get("$Browser.formFactor");
        component.set("v.formFactor", device);

        /*
        var userInfo = component.get("v.currentUser");
        if(device == 'DESKTOP' && userInfo.Super_User__c != true){
            component.set("v.mobileTMAllowed", false);
        } else {
            component.set("v.mobileTMAllowed", true);
        }
         */

        helper.callServerMethod(component, event, "c.getVersion", null, function(response) {
            component.set("v.version", response);
        })
    },
    //cache control >>
    handleTMNavigationEvent : function(component, event, helper) {
        var tmId = event.getParam("tmId");
        var page = event.getParam("page");
        var reloadTM = event.getParam("reloadTM");
        component.set("v.tmId", tmId);
        component.set("v.page", page);
        if (reloadTM == true && page == 'details') {
            var container = component.find("container");
            if (container) {
                container.reloadTM();
            }
        }
    }
})