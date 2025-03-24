({
    getTM : function(component, event) {
        var recordId = component.get("v.recordId");
        var params = { "tmId": recordId };
        this.callServerMethod(component, event, "c.getTM", params, function(response) {
            var tmWrapper = JSON.parse(response);
            var tm = tmWrapper.TM;
            var jobTaskWrappers = tmWrapper.JobTaskWrappers;
            component.set("v.tm", tm);
            component.set("v.jobTaskWrappers", jobTaskWrappers);
          
            //ticket 19792 and 75282 <<
           var stages = component.get("v.stages");
           if (tm.Status__c == 'Fully Invoiced' || tm.Status__c == 'Sent to EQAI') {
                for (var i = 0; i < stages.length; i++) {
                    stages[i].disableClick = true;
                }
               
                component.set("v.stages", stages);
            }
           
             if(tm.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c)
                     stages.splice(5, 1);
             else
                     stages.splice(4, 1);
             component.set("v.stages", stages);
         
           
            //ticket 19792 and 75282>>

            this.calculateNextTMLineNo(component);
        });
    },
    saveTMHeader : function(component, event) {
        var tm = component.get("v.tm");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var params = { "JSONTM": JSON.stringify(tm) };
        this.callServerMethod(component, event, "c.saveTMHeader", params, function (response) {
            component.set("v.unsavedChanges", false);
            this.showToast(component, "Successful", "Status changed.", "success", "dismissible");

            setTimeout(
                $A.getCallback(function() {
                    $A.get('e.force:refreshView').fire();
                }), 0
            );
        }, function(error) {
            this.showToast(component, "Error", error, "error", "dismissible");
        });
    },
    saveTM : function(component, event) {
        var tm = component.get("v.tm");

        //ticket 19130 <<
        //var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var jobTaskWrappers = JSON.parse(JSON.stringify(component.get("v.jobTaskWrappers"))); //make a copy
        //remove child lines with qty 0 and don't have a parent line
        for (var i = 0; i < jobTaskWrappers.length; i++) {
            var jobTaskWrapper= jobTaskWrappers[i];

            //remove child lines with zero qty and don't have a parent
            for (var j = jobTaskWrapper.TMLines.length - 1; j >= 0; j--) {
                var tmLine = jobTaskWrapper.TMLines[j];

                if (tm.Status__c == 'Confirmed' && tmLine.Is_Child_Resource__c == true && (!tmLine.Quantity__c || tmLine.Quantity__c == 0)) {
                    jobTaskWrapper.TMLines.splice(j, 1);
                    //remove relationship
                    for (var k = 0; k < jobTaskWrapper.TMLines.length; k++) {
                        var tmLine2 = jobTaskWrapper.TMLines[k];

                        if (tmLine2.TM_Child_Lines__r && tmLine2.TM_Child_Lines__r.records) {
                            for (var l = 0; l < tmLine2.TM_Child_Lines__r.records.length; l++) {
                                var relation = tmLine2.TM_Child_Lines__r.records[l];
                                if (relation.Child_Line__r && parseInt(relation.Child_Line__r.Line_No__c) == parseInt(tmLine.Line_No__c)) {
                                    tmLine2.TM_Child_Lines__r.records.splice(l, 1);
                                    l--;
                                }
                            }
                            tmLine2.TM_Child_Lines__r.totalSize = tmLine2.TM_Child_Lines__r.records.length;
                            tmLine2.TM_Child_Lines__r.done = "true";
                        }
                    }
                }

            }
        }
        //ticket 19130 >>

        var params = { "JSONTM": JSON.stringify(tm), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };
        this.callServerMethod(component, event, "c.saveTM", params, function (response) {
            component.set("v.unsavedChanges", false);
            this.showToast(component, "Successful", "Status changed.", "success", "dismissible");
            setTimeout(
                $A.getCallback(function() {
                    $A.get('e.force:refreshView').fire();
                }), 0
            );
        }, function(error) {
            this.showToast(component, "Error", error, "error", "dismissible");
        });
    },

});