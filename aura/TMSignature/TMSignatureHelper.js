({
    getSignature : function(component, event, token) {
        var params = { "token" : token };
        this.callServerMethod(component, event, "c.getSignature", params, function(response) {
            var signatureWrapper = JSON.parse(response);

            signatureWrapper.NotAvailable = false;
            //ticket 21113 <<
            /*
            if (signatureWrapper.Signed != true) {
                signatureWrapper.SignatureData = null;
                signatureWrapper.AcceptTerms = false;
                signatureWrapper.PrintName = null;
            }
            */
            signatureWrapper.Decline = signatureWrapper.Declined;
            //ticket 21113 >>

            if (signatureWrapper.SignatureData) {
                var signaturePad = component.get("v.signaturePad");
                signaturePad.fromDataURL('data:image/png;base64,' + signatureWrapper.SignatureData);
                signaturePad.off();
            }

            component.set("v.signatureWrapper", signatureWrapper);
            component.set("v.error", false);
            component.set("v.ready", true);
        }, function(failure) {
            component.set("v.error", true);
            component.set("v.errorDescription", failure);
        })
    },
    //ticket 21113 <<
    //save : function (component, event){
    save : function (component, event, decision){
    //ticket 21113 >>
        var calls = [];
        var helper = this;
        //ticket 21113 <<
        let token = component.get("v.token");
        //ticket 21113 >>

        //ticket 21113 <<
        //calls.push(this.saveSignature.bind(helper, component, event));
        calls.push(this.saveSignature.bind(helper, component, event, decision));
        calls.push(this.getSignature.bind(helper, component, event, token));
        //ticket 21113 >>
        this.makeStackedCalls(component, event, helper, calls);
    },
    //ticket 21113 <<
    //saveSignature : function(component, event) {
    //    var signatureWrapper = component.get("v.signatureWrapper");
    saveSignature : function(component, event, decision) {
        let signatureWrapper = JSON.parse(JSON.stringify(component.get("v.signatureWrapper"))); //make a copy of signatureWrapper to save
        if (decision == 'DECLINE') {
            signatureWrapper.Declined = true;
        }
        else {
            signatureWrapper.Declined = false;
        }
    //ticket 21113 >>

        var signaturePad = component.get("v.signaturePad");

        signatureWrapper.SignatureData = null;
        if (!signaturePad.isEmpty()) {
            signatureWrapper.SignatureData = signaturePad.toDataURL().replace(/^data:image\/(png|jpg);base64,/, "");
        }

        signatureWrapper.IPAddress = component.get("v.clientIpAddress");

        var params = { "JSONSignatureWrapper": JSON.stringify(signatureWrapper) };
        this.callServerMethod(component, event, "c.saveSignature", params, function(response) {
            var signatureWrapper = JSON.parse(response);
            if (signatureWrapper.SignatureData) {
                var signaturePad = component.get("v.signaturePad");
                signaturePad.fromDataURL('data:image/png;base64,' + signatureWrapper.SignatureData);
                signaturePad.off();
            }
            component.set("v.signatureWrapper", signatureWrapper);

            if (resolve) {
                resolve();
            }

        }, function(err) {
            alert(err)
        })
    },
    validateEmailAddress : function(component, event) {
        var signatureWrapper = component.get("v.signatureWrapper");
        if (!$A.util.isEmpty(signatureWrapper.Email)) {
            var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
            if (signatureWrapper.Email.match(regExpEmailformat)) {
                return true;
            }
            return false;
        }
        //ticket 21113 <<
        return false;
        //ticket 21113 >>
    },
    /*
    showTermsDialog : function(component, event) {
        var salesOrderId = component.get("v.tm.Sales_Order__c");
        var buttons = [];
        buttons.push({ "label": 'Close', "variant": 'brand', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        var params = { "salesOrderId": salesOrderId };
        this.openModal(component, event, 'Terms and Conditions', null, buttons, "c:MobileTMTerms", params, "large");
    },*/
    getUserIpAddress : function(component, event) {
        var clientIpAddress = component.get("v.clientIpAddress");
        if (!clientIpAddress) {
            const Http = new XMLHttpRequest();
            const url = 'https://api.ipify.org/';
            Http.open("GET", url);
            Http.send();
            Http.onreadystatechange = (e) => {
                if (Http.responseText) {
                    component.set("v.clientIpAddress", Http.responseText);
                }
            }
        }
    },
});