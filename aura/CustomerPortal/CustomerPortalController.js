({
	doInit : function(component, event, helper) {
        var JSONSession = helper.getCookie("acvportal");
        if (JSONSession && JSONSession != '') {
        	var info = JSON.parse(unescape(JSONSession)); 
            helper.checkSession(component, event, info.session);
        }
	},
    handleLogin : function(component, event, helper) {
        var loginInfo = event.getParam("loginInfo");
        component.set("v.loginInfo", loginInfo);
        if (loginInfo.Authorized == true) {
            helper.createCookie('acvportal', loginInfo, 1);
            if (loginInfo && loginInfo.Authorized == true) {
                if (loginInfo.StagingAccountId != null) {
                    helper.navigateTo(component, event, 'account-information');
                }
                else if (loginInfo.StagingContactId != null) {
                    helper.navigateTo(component, event, 'contact-information');
                }
            }
        }
    },
    getUserIpAddress : function(component, event, helper) {
        const Http = new XMLHttpRequest();
        const url='https://api.ipify.org/';
        Http.open("GET", url);
        Http.send();
        Http.onreadystatechange=(e)=>{
            console.log(Http.responseText); // This prints Ip address
            component.set("v.ipAddress", Http.responseText);
        }
    },
    handleLogout : function(component, event, helper) {
        helper.createCookie('acvportal', null, 0);
        component.set("v.loginInfo", null);
    },
    handleNavigationMenuItemClick : function(component, event, helper) {
        var name = event.getSource().get("v.name");
        helper.navigateTo(component, event, name);
    }
})