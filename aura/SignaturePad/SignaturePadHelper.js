({
    resizeCanvas : function(component, canvas) {
        /*
        var ratio =  Math.max(window.devicePixelRatio || 1, 1);
        canvas.width = canvas.offsetWidth * ratio;
        canvas.height = canvas.offsetHeight * ratio;
        canvas.getContext("2d").scale(ratio, ratio);
        */
    },
    getSignature : function(component, event) {
        var signatureWrapper = component.get("v.signatureWrapper");
        //signature request <<
        //var params = { "relatedToId" : signatureWrapper.RelatedToId, "filename": signatureWrapper.Name };
        var params = { "tmId" : signatureWrapper.TMId, "role": signatureWrapper.SignerRole };
        //signature request >>
        this.callServerMethod(component, event, "c.getSignature", params, function(response) {
            if (response != null) {
                var signatureWrapper = JSON.parse(response);
                if (signatureWrapper.SignatureData) {
                    var signaturePad = component.get("v.signaturePad");
                    signaturePad.fromDataURL('data:image/png;base64,' + signatureWrapper.SignatureData);
                    signaturePad.off();
                }
                //component.set("v.empty", (signatureWrapper.SignatureData == null));
                //var canvas = component.find('sPad').getElement();
                //var blank = !canvas.getContext('2d').getImageData(0, 0, canvas.width, canvas.height).data.some(color  => color  !== 0);
                component.set("v.signatureWrapper", signatureWrapper);
            }
        }, function(err) {
            this.showToast(component, "Signature", err, "error", "dismissible");
        });
    },
    saveSignature : function(component, event) {
        var signatureWrapper = component.get("v.signatureWrapper");
        var signaturePad = component.get("v.signaturePad");

        signatureWrapper.SignatureData = null;
        if (signatureWrapper.NotAvailable != true) {
            if (!signaturePad.isEmpty()) {
                signatureWrapper.SignatureData = signaturePad.toDataURL().replace(/^data:image\/(png|jpg);base64,/, "");
            }
        }

        var params = { "JSONSignatureWrapper": JSON.stringify(signatureWrapper) };
        this.callServerMethod(component, event, "c.saveSignature", params, function(response) {
            var signatureWrapper = JSON.parse(response);
            if (signatureWrapper.SignatureData) {
                var signaturePad = component.get("v.signaturePad");
                signaturePad.fromDataURL('data:image/png;base64,' + signatureWrapper.SignatureData);
                signaturePad.off();
            }
            component.set("v.signatureWrapper", signatureWrapper);

            var afterSignatureSaved = component.getEvent("afterSignatureSaved");
            //signature request <<
            /*
            var label = component.get("v.label");
            afterSignatureSaved.setParams({ "label": label });
            */
            afterSignatureSaved.setParams({ "signerRole": signatureWrapper.SignerRole });
            //signature request >>
            afterSignatureSaved.fire();

            this.showToast(component, '', 'Signature saved!', 'success', 'dismissible');
        }, function(err) {
            this.showToast(component, '', err, 'error', 'dismissible');
        })
    },
    //signature request <<
    validateEmailAddress : function(component, event) {
        var signatureWrapper = component.get("v.signatureWrapper");
        if (signatureWrapper.Email) {
            var regExpEmailformat = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
            if (signatureWrapper.Email.match(regExpEmailformat)) {
                return true;
            }
            return false;
        }
        return true;
    },
    //signature request >>
    callServerMethod : function(component, event, method, params, successCallback, failureCallback) {
        var action = component.get(method);
        if (params) {
            action.setParams(params);
        }
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                if (successCallback) {
                    successCallback.call(this, response.getReturnValue());
                }
            } else if (state === "ERROR") {
                var error = '';
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        error =  errors[0].message;
                    }
                } else {
                    error = "Unexpected error";
                }

                if (failureCallback) {
                    failureCallback.call(this, error);
                }
            }
        });
        $A.enqueueAction(action);
    },
    showToast : function(component, title, message, type, mode) {
        try {
            var evt = $A.get("e.force:showToast");
            if (evt) {
                evt.setParams({
                    "title": title,
                    "message": message,
                    "type": type,
                    "mode": mode
                });
                evt.fire();
            }
            else {
                alert(message);
            }
        }
        catch(err) {
            alert(err);
        }
    }
})