({
    doInit : function(component, event, helper) {
        var myPageRef = component.get("v.pageReference");
        var userId = myPageRef.state.c__UserId;
        component.set("v.userId", userId);

        helper.getUserServiceCenters(component, event);
    },
    doNewUserServiceCenter : function(component, event, helper) {
        //helper.newUserServiceCenter(component, event);


    },
    doAddAll : function(component, event, helper) {
        helper.addAllServiceCenters(component, event);
    },
    doNew : function(component, event, helper) {
        var userId = component.get("v.userId");
        var user = component.get("v.user");
        var userServiceCenters = component.get("v.userServiceCenters");
        userServiceCenters.push({ "User__c": userId, "User__r": user });
        component.set("v.userServiceCenters", userServiceCenters);
    },
    doSave : function(component, event, helper) {
        helper.saveUserServiceCenters(component, event);
    },
    /*
    handleRowAction : function(component, event, helper) {
        var name = event.getParam("name");
        var rowIndex = event.getParam("rowIndex");
        var action = event.getParam("action");
        var userServiceCenters = component.get("v.userServiceCenters");
        console.log(userServiceCenters  + ' , ' + (userServiceCenters.length > rowIndex) + ' , ' + name + ', ' + action)
        if (userServiceCenters && userServiceCenters.length > rowIndex) {
            var userServiceCenter = userServiceCenters[rowIndex];
            switch (name) {
                case 'delete':
                    if (action == 'click') {
                        for (var i = 0; i < userServiceCenters.length; i++) {
                            if (i == rowIndex) {
                                userServiceCenters.splice(i, 1);
                                break;
                            }
                        }
                        component.set("v.userServiceCenters", userServiceCenters);
                    }
                    break;
                case 'service-center':
                    if (action == 'change') {
                        alert('xxxx')
                        if (userServiceCenter.Service_Center__r != null) {
                            userServiceCenter.Service_Center__c = userServiceCenter.Service_Center__r.Id;
                        } else {
                            userServiceCenter.Service_Center__c = null;
                        }
                        component.set("v.userServiceCenters[" + rowIndex + "]", userServiceCenter);
                    }
                    break;
                case 'default':
                    if (action == 'change') {
                        if (userServiceCenter.Default__c == true) {
                            var spinner = component.find("spinner");
                            $A.util.removeClass(spinner, 'slds-hide');
                            for (var i = 0; i < userServiceCenters.length; i++) {
                                if (i != rowIndex && userServiceCenters[i].Default__c == true) {
                                    userServiceCenters[i].Default__c = false;
                                    component.set("v.userServiceCenters[" + i + "]", userServiceCenters[i]);
                                }
                            }
                        }
                    }
                    break;
                case 'manager':
                    break;
            }
        }
    },*/
    doCancel : function(component, event, helper) {
        var userId = component.get("v.userId");
        var url = '/' + userId + '?noredirect=1&isUserEntityOverride=1';
        var navigateEvent = $A.get("e.force:navigateToURL");
        navigateEvent.setParams({ "url": url });
        navigateEvent.fire();

    }
});