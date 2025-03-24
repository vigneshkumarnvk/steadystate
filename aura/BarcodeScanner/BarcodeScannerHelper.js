({
    getBarCode:function(component, event,result){
        var barcode = '';
        if (result && result.data) {
            try{
                var _result = JSON.parse(result.data);
                if (_result && _result.codeResult) {
                	barcode = _result.codeResult.code;
                }
            }catch(e){
                //this.showToast(component, 'warning', 'Scan', e.message, 'sticky');
            }
        }
        if (barcode == '') {
        	//this.showToast(component, 'warning', 'Scan', 'No barcode found. Barcode may be too small. Place the camera closer.', 'dismissable');
        }
        
        component.set('v.barcode', barcode);
        var cmpEvent = component.getEvent('onScanComplete');
        if (cmpEvent != null) {
            cmpEvent.setParams( { "barcode" : barcode })
            cmpEvent.fire();
            $A.util.addClass(component.find('_spinner'),"slds-hide");
        }
    },
    showToast : function(component, variant, title, message, mode) {
        component.find('notifLib').showToast({
            "variant": variant,
            "header": title,
            "mode": mode,
            "message": message,
            closeCallback: function() {
            }
        });
    },
})