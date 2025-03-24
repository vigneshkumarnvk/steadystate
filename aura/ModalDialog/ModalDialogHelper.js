({
	showModal : function(component, event) {
		var modal = component.find('modal');
		var backdrop = component.find('backdrop');
		$A.util.addClass(modal, 'slds-fade-in-open');
		$A.util.addClass(backdrop, 'slds-backdrop--open');
	},
    hideModal : function(component, event) {
        var modal = component.find('modal');
		var backdrop = component.find('backdrop');
		$A.util.removeClass(backdrop,'slds-backdrop--open');
		$A.util.removeClass(modal, 'slds-fade-in-open');
    }
})