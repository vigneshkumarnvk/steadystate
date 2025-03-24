({
    loadSignaturePad : function(component, event, helper) {
        window.addEventListener('load', function() {
            var maybePreventPullToRefresh = false;
            var lastTouchY = 0;

            var touchstartHandler = function(e) {
                if (e.touches.length != 1) return;
                lastTouchY = e.touches[0].clientY;
                maybePreventPullToRefresh = (window.pageYOffset == 0);
            }

            var touchmoveHandler = function(e) {
                var touchY = e.touches[0].clientY;
                var touchYDelta = touchY - lastTouchY;
                lastTouchY = touchY;

                if (maybePreventPullToRefresh) {
                    maybePreventPullToRefresh = false;
                    if (touchYDelta > 0) {
                        e.preventDefault();
                        return;
                    }
                }
            }
        });

        var sPad = component.find("sPad");
        if (sPad) {
            var canvas = sPad.getElement();
            var signaturePad = new SignaturePad(canvas,
                {
                    backgroundColor: 'rgb(255,255,255)',
                    onEnd: function () {
                    }
                }
            );
            component.set("v.signaturePad", signaturePad);

            var token = component.get("v.token");
            helper.getSignature(component, event, token);
        }
    },
    doInit : function(component, event, helper) {
        helper.getUserIpAddress(component, event);
    },
    doClear : function(component, event, helper) {
        var signaturePad = component.get("v.signaturePad");
        signaturePad.clear();
        signaturePad.on();

        var signatureWrapper = component.get("v.signatureWrapper");
        signatureWrapper.PrintName = null;
        signatureWrapper.SignatureDate = null;
        signatureWrapper.SignatureData = null;
        signatureWrapper.AcceptTerms = false;
        signatureWrapper.NotAvailable = false;
        signatureWrapper.Email = null;
        signatureWrapper.Signed = false;
        signatureWrapper.RequestSignature = false;
        signatureWrapper.RequestSignatureEmailSent = false;
        component.set("v.signatureWrapper", signatureWrapper);
    },
    doSave : function(component, event, helper) {
        var signaturePad = component.get("v.signaturePad");
        var signatureWrapper = component.get("v.signatureWrapper");
        //ticket 21113 <<
        let decision = event.getSource().get("v.value");
        //ticket 21113 >>


        //ticket 21113 <<
        /*
        if (signaturePad.isEmpty() == true) {
            alert("Please sign your name.");
            return;
        }
        if (component.get("v.hideAcceptTermsCheckbox") != true && signatureWrapper.AcceptTerms != true) {
            alert("You must accept terms and conditions.");
            return;
        }

        if (!signatureWrapper.PrintName) {
            alert("Please print your name.");
            return;
        }
        if (!helper.validateEmailAddress(component, event)) {
            helper.showToast(component, "Error", "Please enter a valid email address.", "error", "dismissible");
            return;
        }
        */
        if (decision != 'DECLINE' && signaturePad.isEmpty() == true) {
            alert("Please sign your name in the box.");
            return;
        }

        if (!signatureWrapper.PrintName) {
            alert("Please print your name.");
            return;
        }
        if (!signatureWrapper.Email) {
            alert('Please enter your email address.');
            return;
        }
        else if (!helper.validateEmailAddress(component, event)) {
            alert('Please enter a valid email address.');
            return;
        }

        if (decision != 'DECLINE' && signatureWrapper.AcceptTerms != true) {
            alert("You must accept terms and conditions to continue.");
            return;
        }
        //ticket 21113 >>

        //helper.saveSignature(component, event);
        //ticket 21113 <<
        //helper.save(component, event);
        helper.save(component, event, decision);
        //ticket 21113 >>
    },
    showTermsDialog : function(component, event, helper) {
        helper.showTermsDialog(component, event);
    },
    //ticket 21113 <<
    handleDecline : function (component, event, helper) {
        let decline = event.getSource().get("v.checked");
        let signatureWrapper = component.get("v.signatureWrapper");
        var signaturePad = component.get("v.signaturePad");
        if (decline == true) {
            signatureWrapper.AcceptTerms = false;
            signaturePad.clear();
            signaturePad.off();
        }
        else {
            signatureWrapper.CustomerComment = null;
            signaturePad.on();
        }
        component.set("v.signatureWrapper", signatureWrapper);
    }
    //ticket 21113 >>

});