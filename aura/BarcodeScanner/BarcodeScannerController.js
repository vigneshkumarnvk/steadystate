({
    doInit:function(component, event, helper){
      if (window.addEventListener) {
          //alert('init');
          window.addEventListener("message", function(result){
              helper.getBarCode(component, event, result);
          }, false);
      } else {
          window.attachEvent("onmessage", function(result){
              helper.getBarCode(component, event, result);
          });
      }
    },
    scanBarcode: function(component, event, helper) {
        var params = event.getParams().arguments;
        component.set("v.callerComponent", params.callerComponent);
        component.set("v.callerEvent", params.callerEvent);
        component.set("v.callback", params.callback);

        var barcodeContainer = component.find('uploadBarcode').getElement();
        barcodeContainer.click();
        return params.callback;
    },
    uploadBarcode: function(component, event, helper) {
        $A.util.removeClass(component.find('_spinner'),"slds-hide");
        var file = event.target.files[0];
        if (file) {
       		var reader = new FileReader();
            var blob = file.slice(0, file.size);
            reader.readAsBinaryString(blob);
    
            reader.onloadend = function(e) {
                if (e.target.readyState == FileReader.DONE) {
    
                    var fileContent = 'data:' + file.type + ';base64,' + btoa(e.target.result);
                    var barcodeImage = component.find('barcodeImage').getElement();
                    barcodeImage.src = fileContent;
    
                    //$A.util.removeClass(component.find('_barcodeImageContainer'),"slds-hide");
                    var quaggaData = {};
                    quaggaData.imageWidth = 800;
                    if(barcodeImage.naturalWidth>800){
                      quaggaData.imageWidth = barcodeImage.naturalWidth;
                    }
                    quaggaData.fileContent = fileContent;
                    var quaggaFrame = component.find('_quaggaFrame');
                    quaggaFrame.getElement().contentWindow.postMessage(JSON.stringify(quaggaData), '*');
                }
        	}
        }
        else {
            $A.util.addClass(component.find('_spinner'),"slds-hide");
        }
    },
    handleScanComplete : function(component, event, helper) {
        var callback = component.get("v.callback");
        if (!$A.util.isUndefinedOrNull(callback)) {
            var barcode = component.get("v.barcode");
        	var callerComponent = component.get("v.callerComponent");
            var callerEvent = component.get("v.callerEvent");
            callback(callerComponent, callerEvent, barcode);
        }
    }
})