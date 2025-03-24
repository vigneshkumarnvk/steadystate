({
    handleEquipmentOperatorChange : function(component, event, helper) {
        var record = event.getParam("record");
        var tmLine = component.get("v.tmLine");
        if (record) {
            tmLine.Linked_Line__c = record.Id;
            //ticket 19130 <<
            tmLine.Linked_Line__r = { "Line_No__c": record.Line_No__c, "Id": record.Id, "Resource_Name__c": record.Resource_Name__c }
            //ticket 19130 >>
            tmLine.Job_Start_Time__c = record.Job_Start_Time__c;
            tmLine.Job_End_Time__c = record.Job_End_Time__c;
            tmLine.Total_Job_Hours__c = helper.calculateHours(tmLine.Job_Start_Time__c, tmLine.Job_End_Time__c);

            if (tmLine.Unit_of_Measure__r) {
                if (tmLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                    tmLine.Quantity__c = tmLine.Total_Job_Hours__c;
                }
                else {
                    if (!tmLine.Quantity__c) {
                        tmLine.Quantity__c = 1;
                    }
                }
            }
        }
        else {
            tmLine.Linked_Line__c = null;
        }
        component.set("v.tmLine", tmLine);
    }
});