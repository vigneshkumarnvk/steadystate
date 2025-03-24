({
    getUserServiceCenters : function(component, event) {
        var userId = component.get("v.userId");

        var params = { "userId" : userId };
        this.callServerMethod(component, event, "c.getUser", params, function(response) {
            component.set("v.user", response);
            this.callServerMethod(component, event, "c.getUserServiceCenters", params, function(response) {
                var userServiceCenters = JSON.parse(response);
                component.set("v.userServiceCenters", userServiceCenters);
            });
        });
    },
    addAllServiceCenters : function(component, event) {
        var user = component.get("v.user");
        var userServiceCenters = component.get("v.userServiceCenters");
        var params = { "JSONUser": JSON.stringify(user), "JSONUserServiceCenters": JSON.stringify(userServiceCenters) };
        this.callServerMethod(component, event, "c.addAllServiceCenters", params, function(response) {
            userServiceCenters = JSON.parse(response);
            component.set("v.userServiceCenters", userServiceCenters);
        })
    },
    saveUserServiceCenters : function(component, event) {
        var userId = component.get("v.userId");
        var userServiceCenters = component.get("v.userServiceCenters");
        var params = { "userId": userId, "JSONUserServiceCenters": JSON.stringify(userServiceCenters) };
        this.callServerMethod(component, event, "c.saveUserServiceCenters", params, function(response) {
            var userServiceCenters = JSON.parse(response);
            component.set("v.userServiceCenters", userServiceCenters);
            this.showToast(component, 'Save', 'User service centers are saved!', 'success', 'dismissable');
        });
    }
});