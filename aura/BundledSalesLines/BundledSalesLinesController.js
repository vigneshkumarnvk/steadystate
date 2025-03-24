({
	doInit : function(component, event, helper) {

		//job task <<
		/*
		var parentSalesLine = component.get("v.parentSalesLine");
		var salesLines = component.get("v.salesLines");
		var hasBundledLines = false;
		for (var i = 0; i < salesLines.length; i++) {
			//if (salesLines[i].Bill_as_Lump_Sum__c == true && salesLines[i].Bundle_Line__r != null && salesLines[i].Bundle_Line__r.Line_No__c == parentSalesLine.Line_No__c) {
			if (salesLines[i].Bundle_Line__r != null && salesLines[i].Bundle_Line__r.Line_No__c == parentSalesLine.Line_No__c) {
				hasBundledLines = true;
				break;
			}
		}
		component.set("v.showBundledOnly", hasBundledLines);
		 */
		var lumpSumLine = component.get("v.lumpSumLine");
		var jobTaskWrapper = component.get("v.jobTaskWrapper");
		var showBundledOnly = false;
		for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
			if (jobTaskWrapper.SalesLines[i].Bundle_Line__r != null && jobTaskWrapper.SalesLines[i].Bundle_Line__r.Line_No__c == lumpSumLine.Line_No__c) {
				showBundledOnly = true;
				break;
			}
		}
		component.set("v.showBundledOnly", showBundledOnly);
		//job task >>

		helper.setLinesVisibility(component, event);
	},
	refresh : function(component, event, helper) {
		helper.setLinesVisibility(component, event);
	},
	handleRowAction : function(component, event, helper) {
		//job task <<
		/*
    	var params = event.getParams();

    	if (params.rowIndex != null) {
			var salesLines = component.get("v.salesLines");
			if (salesLines.length > params.rowIndex) {
				var row = salesLines[params.rowIndex];
				switch (params.name) {
					case 'select':
						helper.selectSalesLine(component, event, row);
						break;
				}
			}
		}
		*/
		var name = event.getParam("name");
		var rowIndex = event.getParam("rowIndex");
		var action = event.getParam("action");
		var jobTaskWrapper = component.get("v.jobTaskWrapper");
		if (jobTaskWrapper.SalesLines.length > rowIndex) {
			var row = jobTaskWrapper.SalesLines[rowIndex];
			switch (name) {
				case 'select':
					if (action == 'change') {
						helper.selectSalesLine(component, event, row);
					}
					break;
			}
		}
		//job task >>
	},
})