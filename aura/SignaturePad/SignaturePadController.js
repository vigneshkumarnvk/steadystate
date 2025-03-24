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
            helper.getSignature(component, event);
        }
    },
    handleNotAvailableChange : function(component, event, helper) {
        var signatureWrapper = component.get("v.signatureWrapper");
        var signaturePad = component.get("v.signaturePad");
        if (signatureWrapper.NotAvailable == true) {
            var signaturePad = component.get("v.signaturePad");
            signaturePad.clear();
            signaturePad.off();

            signatureWrapper.PrintName = null;
            signatureWrapper.SignatureDate = null;
            signatureWrapper.SignatureData = null;
            signatureWrapper.AcceptTerms = false;
            signatureWrapper.Email = null;
            signatureWrapper.Signed = false;
            component.set("v.signatureWrapper", signatureWrapper);
        }
        else {
            signaturePad.on();

            signatureWrapper.RequestSignature = false;
            signatureWrapper.SignatureRequestEmailSent = false;
            component.set("v.signatureWrapper", signatureWrapper);
        }
    },
    //signature request <<
    handleRequestSignatureChange : function(component, event, helper) {
        var signatureWrapper = component.get("v.signatureWrapper");
        if (signatureWrapper.RequestSignature != true) {
            signatureWrapper.PrintName = null;
            signatureWrapper.Email = null;
            component.set("v.signatureWrapper", signatureWrapper);
        }
    },
    //signature request >>
    doSave : function(component, event, helper) {

        //ticket 19408 <<
        var externalCall = false;
        if (event.getParams() && event.getParams().arguments) {
            externalCall = event.getParams().arguments.externalCall;
        }
        var fireBeforeSaveEvent = component.get("v.fireBeforeSaveEvent");
        if (fireBeforeSaveEvent && externalCall != true) {
            var beforeSignatureSave = component.getEvent("beforeSignatureSave");
            beforeSignatureSave.fire();
            return;
        }
        //ticket 19408 >>

        var signaturePad = component.get("v.signaturePad");
        var signatureWrapper = component.get("v.signatureWrapper");
        //request signature <<
        /*
        if (signaturePad.isEmpty() != true || signatureWrapper.NotAvailable == true) {
            helper.saveSignature(component, event);
        }
        else {
            helper.showToast(component, "Signature", "Please sign first.", "error", "dismissible");
        }
        */
        if (signatureWrapper.SignerRole == 'Customer A' || signatureWrapper.SignerRole == 'Customer B') {
            if (signatureWrapper.NotAvailable != true) {
                if (signaturePad.isEmpty() == true) {
                    helper.showToast(component, "Error", "Please sign your name.", "error", "dismissible");
                    return;
                }
                if (!signatureWrapper.PrintName) {
                    helper.showToast(component, "Error", "Please enter your name.");
                    return;
                }
                if (component.get("v.hideAcceptTermsCheckbox") != true && signatureWrapper.AcceptTerms != true) {
                    helper.showToast(component, "Error", "You must accept terms and conditions.", "error", "dismissible");
                    return;
                }
            } else {
                if (signatureWrapper.RequestSignature == true) {
                    if (!signatureWrapper.PrintName || !signatureWrapper.Email) {
                        helper.showToast(component, "Error", "Please enter Name and Email to request the signature.", "error", "dismissible");
                        return;
                    }
                }
            }

            if (!helper.validateEmailAddress(component, event)) {
                helper.showToast(component, "Error", "Please enter a valid email address.", "error", "dismissible");
                return;
            }
        }
        else {
            if (signaturePad.isEmpty() == true) {
                helper.showToast(component, "Error", "Please sign your name.", "error", "dismissible");
                return;
            }
            if (!signatureWrapper.PrintName) {
                helper.showToast(component, "Error", "Please enter your name.");
                return;
            }
        }

        helper.saveSignature(component, event);
        //request signature >>
    },
    doRefresh : function(component, event, helper) {
        helper.getSignature(component, event);
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
        signatureWrapper.SignatureRequestEmailSent = false;
        component.set("v.signatureWrapper", signatureWrapper);
    }
})