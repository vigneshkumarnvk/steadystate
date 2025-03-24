({
    handleClick : function(component, event, helper){      
		var record = component.get("v.record");
        var onselect = component.getEvent("onselect");
        onselect.setParams({ "record" : record });  
        onselect.fire();
	},
})