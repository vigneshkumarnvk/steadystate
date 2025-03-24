({
    checkSession : function(component, event, session) {
        component.set("v.error", null);     
        var params = { "session": session };
        this.callServerMethod(
            component, 
            event, 
            "c.checkSession", 
            params, 
            function(loginInfo) {            
            	component.set("v.loginInfo", loginInfo);
            	if (loginInfo && loginInfo.Authorized == true) {
                	if (loginInfo.StagingAccountId != null) {
                    	this.navigateTo(component, event, 'account-information');
                	}
                	else if (loginInfo.StagingContactId != null) {
                    	this.navigateTo(component, event, 'contact-information');
                	}
                }
            }, 
            function(err) {
                component.set("v.password", null);
                switch (err) {
                    case 'INVALID_SESSION':
                		err = 'Invalid session.';
                        break;
                    case 'EXPIRED_SESSION':
                        err = 'Session has expired.';
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
            });
	},
    navigateTo : function(component, event, page) {        
        switch(page) {
            case 'account-information':
                var loginInfo = component.get("v.loginInfo");
                            
                if (loginInfo.PortalLogin) {
                    var stagingAccountId = loginInfo.StagingAccountId;
                    var params = { "recordId": stagingAccountId, "loginInfo": loginInfo };
                    this.createComponent(component, event, "c:CustomerAccountInformation", params);
                }
                break;
            case 'contact-information':
                var loginInfo = component.get("v.loginInfo");
                            
                if (loginInfo.PortalLogin) {
                    var stagingContactId = loginInfo.StagingContactId;
                    var params = { "recordId": stagingContactId, "loginInfo": loginInfo };
                    this.createComponent(component, event, "c:CustomerContactInformation", params);
                }
                break;
        }
    },
    createComponent : function(component, event, componentName, params) {
        $A.createComponent(
            componentName,
            params,
            function(newComponent, status, errorMessage) {
                if (status === "SUCCESS") {
                    var container = component.find("content-container");
                    var body = container.get("v.body");
                    body.splice(0, 1);
                    body.push(newComponent);
                    container.set("v.body", body);
                }
                else if (status === 'INCOMPLETE') {
                    console.log('No response from server or client is offline.');
                }
                else if (status == 'ERROR') {
                    console.log(errorMessage);
                }
            }
        );
    },
	createCookie : function(name, value, hours) {
		var expires;
        if (hours) {
            var date = new Date();
            date.setTime(date.getTime() + (hours * 60 * 60 * 1000));
            expires = 'expires=' + date.toUTCString();
        }
        else {
            expires = '';
        }

        if (value != null) {
            var info = { "session": value.PortalLogin.Session_Token__c };
			document.cookie = name + '=' + escape(JSON.stringify(info)) + ';' + expires + ';path=/';
        }
        else {
            document.cookie = name + '=;expires=Thu, 01 Jan 1970 00:00:01 GMT; path=/';
        }
	},
    getCookie : function(name) {
        //var value = 'LSKey[' + 'c' + ']' + name;
        name += '=';
        var ca = document.cookie.split(';');
        for (var i = 0; i < ca.length; i++) {
            var c = ca[i];
            while (c.charAt(0) == ' ') {
                c = c.substring(1);
            }
            if (c.indexOf(name) == 0) {
                return c.substring(name.length, c.length);
            }
        }
        return '';
    }
})