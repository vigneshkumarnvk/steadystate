({
	doInit : function(component, event, helper) {
	},
	handleRowAction : function(component, event, helper) {
		var name = event.getParam("name");
		var rowIndex = event.getParam("rowIndex");
		var value = event.getParam("value");

		var salesLine = component.get("v.salesLine");
		//fix.null.fields <<
		/*
		if (salesLine.Sales_Line_Details__r && salesLine.Sales_Line_Details__r.length > rowIndex) {
			var salesLineDetail = salesLine.Sales_Line_Details__r[rowIndex];
		*/
		if (salesLine.Sales_Line_Details__r && salesLine.Sales_Line_Details__r.records.length > rowIndex) {
			var salesLineDetail = salesLine.Sales_Line_Details__r.records[rowIndex];
		//fix.null.fields >>
			switch (name) {
				case 'scheduledDate':
					var valid = true;
					//fix.null.fields <<
					/*
					if (salesLine && salesLine.Sales_Line_Details__r) {
						var map = new Map();
						for (var i = 0; i < salesLine.Sales_Line_Details__r.length; i++) {
							var salesLineDetail = salesLine.Sales_Line_Details__r[i];
					 */
					if (salesLine && salesLine.Sales_Line_Details__r.records) {
						var map = new Map();
						for (var i = 0; i < salesLine.Sales_Line_Details__r.records.length; i++) {
							var salesLineDetail = salesLine.Sales_Line_Details__r.records[i];
					//fix.null.fields >>
							if (!map.has(salesLineDetail.Scheduled_Date__c)) {
								map.set(salesLineDetail.Scheduled_Date__c, salesLineDetail);
							} else {
								valid = false;
								var dt = new Date(salesLineDetail.Scheduled_Date__c);
								var formattedDate = (dt.getUTCMonth() + 1) + '/' + dt.getUTCDate() + '/' + dt.getUTCFullYear();
								alert('The scheduled date ' + formattedDate + ' already exist. Please choose a different date.');
								salesLineDetail.Scheduled_Date__c = null;
							}
						}
					}

					if (valid) {
						helper.recalculate(component, event);
					}
					break;
				case 'startTime':

					if (salesLineDetail.Start_Time__c != null && salesLineDetail.End_Time__c != null) {
						helper.recalculate(component, event, salesLineDetail);
					}
					break;
				case 'endTime':
					if (salesLineDetail.Start_Time__c != null && salesLineDetail.End_Time__c != null) {
						helper.recalculate(component, event, salesLineDetail);
					}
					break;
			}
		}
	},
    explode : function(component, event, helper) {
        helper.explode(component, event);
    },
    recalculate : function(component, event, helper) {
		helper.recalculate(component, event);
	},
	copyTimes : function (component, event, helper){
		helper.confirmCopyTime(component, event);
	}
})