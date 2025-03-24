({
	login : function(component, event) {
        component.set("v.error", null);        
        var username = component.get("v.username");
        var password = component.get("v.password");
        var params = { "username": username, "password": password };
        this.callServerMethod(
            component, 
            event, 
            "c.login", 
            params, 
            function(loginInfo) {
                if (loginInfo.Authorized == true) {
                    var loginEvent = component.getEvent("loginEvent");
                    loginEvent.setParams({ "loginInfo": loginInfo });
                    loginEvent.fire();
                }
            }, 
            function(err) {
                component.set("v.password", null);
                switch (err) {
                    case 'INVALID_CREDENTIAL':
                		err = 'Invalid credential.';
                        break;
                    case 'DISABLED_LOGIN':
                        err= 'Invalid login.';
                        break;
                    case 'EXPIRE_LOGIN':
                        err = 'Login has expired.'
                        break;
                    default:
                        //err = 'Unexpected error';
                }
                component.set("v.error", err);
            }
        );
	}
})