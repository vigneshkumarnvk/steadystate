({
    activateTab : function(component, tabId, resolve) {
        component.set("v.selectedTabId", tabId);
        if (resolve) {
            resolve();
        }
    },
    moveLines : function(component, event, tmLines, fromJobTask, toJobTask) {
        if (toJobTask) {
            //ticket 19130 <<
            /*
            var mapTMLinesByLineNo = new Map();
            tmLines.forEach(function(tmLine) {
               mapTMLinesByLineNo.set(tmLine.Line_No__c, tmLine);
            });

            var jobTaskWrapperIndex = -1;
            var jobTaskWrappers = component.get("v.jobTaskWrappers");
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                var jobTaskWrapper = jobTaskWrappers[i];
                for (var j = 0; j < jobTaskWrapper.TMLines.length; j++) {
                    var tmLine = jobTaskWrapper.TMLines[j];
                    if (mapTMLinesByLineNo.has(tmLine.Line_No__c)) {
                        jobTaskWrapper.TMLines.splice(j, 1);
                        j--;
                    }

                    //unlink child lines
                    if (tmLine.Parent_Line__r && tmLine.Parent_Line__r.Line_No__c == tmLine.Line_No__c) {
                        tmLine.Parent_Line__c = null;
                        tmLine.Parent_Line__r = null;
                    }
                }
                if (jobTaskWrapper.JobTask.Line_No__c == toJobTask.Line_No__c) {
                    jobTaskWrapperIndex = i;
                }
            }

            if (jobTaskWrapperIndex >= 0) {
                var jobTaskWrapper = jobTaskWrappers[jobTaskWrapperIndex];
                for (var i = 0; i < tmLines.length; i++) {
                    var tmLine = tmLines[i];
                    tmLine.TM_Job_Task__c = jobTaskWrapper.JobTask.Id;
                    tmLine.TM_Job_Task__r = { "Id": jobTaskWrapper.JobTask.Id, "Task_No__c": jobTaskWrapper.JobTask.Task_No__c, "Line_No__c": jobTaskWrapper.JobTask.Line_No__c };
                    jobTaskWrapper.TMLines.push(tmLine);
                }
            }
            */
            var fromJobTaskWrapperIndex = -1;
            var toJobTaskWrapperIndex = -1;
            var mapTMLinesByLineNo = new Map();
            var mapChildTMLinesByResourceId = new Map();
            var existingToChildResourceIds = [];
            var jobTaskWrappers = component.get("v.jobTaskWrappers");
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                if (jobTaskWrappers[i].JobTask.Line_No__c == fromJobTask.Line_No__c) {
                    fromJobTaskWrapperIndex = i;
                    for (var j = 0; j < jobTaskWrappers[i].TMLines.length; j++) {
                        var tmLine = jobTaskWrappers[i].TMLines[j];
                        mapTMLinesByLineNo.set(tmLine.Line_No__c, tmLine);
                    }
                }
                else if (jobTaskWrappers[i].JobTask.Line_No__c == toJobTask.Line_No__c) {
                    toJobTaskWrapperIndex = i;
                    for (var j = 0; j < jobTaskWrappers[i].TMLines.length; j++) {
                        var tmLine = jobTaskWrappers[i].TMLines[j];
                        mapTMLinesByLineNo.set(tmLine.Line_No__c, tmLine);

                        if (tmLine.Is_Child_Resource__c == true) {
                            var resourceId;
                            if (tmLine.Resource_Type__c == 'Labor' || tmLine.Resource_Type__c == 'Equipment' || tmLine.Resource_Type__c == 'Bundled') {
                                resourceId = tmLine.Resource_Type__c;
                            }
                            else {
                                resourceId = tmLine.Resource__c;
                            }
                            mapChildTMLinesByResourceId.set(resourceId, tmLine);
                            existingToChildResourceIds.push(resourceId);
                        }
                    }
                }
            }

            //add fromJobTaskWrapper child resources to the existing child tm line map for lookup later
            for (var i = 0 ; i < tmLines.length; i++) {
                var tmLine = tmLines[i];
                if (tmLine.Is_Child_Resource__c == true) {
                    var resourceId;
                    if (tmLine.Resource_Type__c == 'Labor' || tmLine.Resource_Type__c == 'Equipment' || tmLine.Resource_Type__c == 'Bundled') {
                        resourceId = tmLine.Resource_Type__c;
                    }
                    else {
                        resourceId = tmLine.Resource__c;
                    }
                    if (!mapChildTMLinesByResourceId.has(resourceId)) {
                        mapChildTMLinesByResourceId.set(resourceId, tmLine);
                    }
                }
            }

            var fromJobTaskWrapper = jobTaskWrappers[fromJobTaskWrapperIndex];
            var toJobTaskWrapper = jobTaskWrappers[toJobTaskWrapperIndex];
            for (var i = 0 ; i < tmLines.length; i++) {
                var tmLine = tmLines[i];

                //handle fromJobTaskWrapper
                for (var j = 0; j < fromJobTaskWrapper.TMLines.length; j++) {
                    var fromTMLine = fromJobTaskWrapper.TMLines[j];
                    if (fromTMLine.Line_No__c == tmLine.Line_No__c) {
                        //remove the TM line from the fromJobTaskWrapper
                        fromJobTaskWrapper.TMLines.splice(j, 1);
                    }

                    if (tmLine.Is_Child_Resource__c == true) {
                        //remove child references
                        if (fromTMLine.TM_Child_Lines__r && fromTMLine.TM_Child_Lines__r.records) {
                            for (var k = 0; k < fromTMLine.TM_Child_Lines__r.records.length; k++) {
                                var relation = fromTMLine.TM_Child_Lines__r.records[k];

                                if (parseInt(relation.Child_Line__r.Line_No__c) == parseInt(tmLine.Line_No__c)) {
                                    fromTMLine.TM_Child_Lines__r.records.splice(k, 1);
                                    k--;
                                }
                            }
                            fromTMLine.TM_Child_Lines__r.totalSize = fromTMLine.TM_Child_Lines__r.records.length;
                            fromTMLine.TM_Child_Lines__r.done = "true";
                        }
                    }
                }

                //handle toJobTaskWrapper
                tmLine.TM_Job_Task__c = toJobTaskWrapper.JobTask.Id;
                tmLine.TM_Job_Task__r = { "Id": toJobTaskWrapper.JobTask.Id, "Task_No__c": toJobTaskWrapper.JobTask.Task_No__c, "Line_No__c": toJobTaskWrapper.JobTask.Line_No__c };
                if (tmLine.Is_Child_Resource__c == true) {
                    var resourceId;
                    if (tmLine.Resource_Type__c == 'Labor' || tmLine.Resource_Type__c == 'Equipment' || tmLine.Resource_Type__c == 'Bundled') {
                        resourceId = tmLine.Resource_Type__c;
                    }
                    else {
                        resourceId = tmLine.Resource__c;
                    }

                    if (!existingToChildResourceIds.includes(resourceId)) {
                        toJobTaskWrapper.TMLines.push(tmLine);
                    }
                }
                else {
                    //handle child references
                    if (tmLine.TM_Child_Lines__r && tmLine.TM_Child_Lines__r.records) {
                        for (var j = 0; j < tmLine.TM_Child_Lines__r.records.length; j++) {
                            var relation = tmLine.TM_Child_Lines__r.records[j];
                            var fromChildLineNo = relation.Child_Line__r.Line_No__c;
                            var fromChildResourceId;

                            if (mapTMLinesByLineNo.has(fromChildLineNo)) {
                                var fromChildTMLine = mapTMLinesByLineNo.get(fromChildLineNo);
                                if (fromChildTMLine.Category__c == 'Labor' || fromChildTMLine.Category__c == 'Equipment' || fromChildTMLine.Category__c == 'Bundled') {
                                    fromChildResourceId = fromChildTMLine.Resource_Type__c;
                                }
                                else {
                                    fromChildResourceId = fromChildTMLine.Resource__c;
                                }
                            }
                            if (mapChildTMLinesByResourceId.has(fromChildResourceId)) {
                                var toChildTMLine = mapChildTMLinesByResourceId.get(fromChildResourceId);
                                relation.Child_Line__c = toChildTMLine.Id;
                                relation.Child_Line__r = { "Id": toChildTMLine.Id, "Line_No__c": toChildTMLine.Line_No__c, "Description__c": toChildTMLine.Description__c };
                            }
                            else {
                                tmLine.TM_Child_Lines__r.records.splice(j, 1);
                                j--;
                            }
                        }
                        tmLine.TM_Child_Lines__r.totalSize = tmLine.TM_Child_Lines__r.records.length;
                        tmLine.TM_Child_Lines__r.done = "true";
                    }
                    toJobTaskWrapper.TMLines.push(tmLine);
                }
            }

            this.cleanUpParentChildRelations(fromJobTaskWrapper);
            this.cleanUpParentChildRelations(toJobTaskWrapper);
            //ticket 19130 >>


            var tm = component.get("v.tm");
            var params = {"JSONTM": JSON.stringify(tm), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers)};
            this.callServerMethod(component, event, "c.calculateTMJobTasks", params, function (response) {
                var jobTaskWrappers = JSON.parse(response);
                component.set("v.jobTaskWrappers", jobTaskWrappers);

                //calculate flat pays after move lines
                var jobTaskLines = this.getTaskTabs(component);
                for (var i = 0; i < jobTaskLines.length; i++) {
                    jobTaskLines[i].calculateFlatPays();
                }

                this.refreshTasks(component, event);
            });
        }
    },
    importJobTasksFromSalesOrder : function(component, event) {
        var tm = component.get("v.tm");
        if (tm.Sales_Order__c == null) {
            this.showToast(component, 'Error', 'This T&M is not associated with a sales order.', 'error', 'dismissible');
            return;
        }

        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Import', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "save", "callback": this.importJobTasksFromSalesOrderCallback.bind(this, component, event) }});
        var params = { "salesOrderId": tm.Sales_Order__c };
        this.openModal(component, event, 'Import Job Tasks', null, buttons, 'c:TMImportJobTasks', params, 'medium');
    },
    importJobTasksFromSalesOrderCallback : function(component, event, salesOrderJobTaskWrappers) {
        this.closeModal(component, event);
        var tm = component.get("v.tm");
        var nextJobTaskLineNo = component.get("v.nextJobTaskLineNo");
        var nextTMLineNo = component.get("v.nextTMLineNo");

        //ticket 19130 <<
        //var params = { "JSONTM": JSON.stringify(tm), "JSONSalesOrderJobTaskWrappers": JSON.stringify(salesOrderJobTaskWrappers), "nextJobTaskLineNo": nextJobTaskLineNo, "nextTMLineNo": nextTMLineNo };
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var selectedJobTaskWrappers = [];
        for (var i = 0; i < salesOrderJobTaskWrappers.length; i++) {
            for (var j = 0; j < jobTaskWrappers.length; j++) {
                if (salesOrderJobTaskWrappers[i].JobTask.Id == jobTaskWrappers[j].JobTask.Sales_Order_Job_Task__c) {
                    selectedJobTaskWrappers.push(jobTaskWrappers[j]);
                    break;
                }
            }
        }
        var params = { "JSONTM": JSON.stringify(tm), "JSONTMJobTaskWrappers": JSON.stringify(selectedJobTaskWrappers), "JSONSalesOrderJobTaskWrappers": JSON.stringify(salesOrderJobTaskWrappers), "nextJobTaskLineNo": nextJobTaskLineNo, "nextTMLineNo": nextTMLineNo };
        //ticket 19130 >>
        this.callServerMethod(component, event, "c.createTMJobTasksFromSalesOrder", params, function (response) {
            var newJobTaskWrappers = JSON.parse(response);

            //ticket 19130 <<
            //var jobTaskWrappers = component.get("v.jobTaskWrappers");
            var firstJobTaskWrapperIndex;
            //ticket 19130 >>

            for (var i = 0; i < newJobTaskWrappers.length; i++) {
                var newJobTaskWrapper = newJobTaskWrappers[i];
                var jobTaskWrapperIndex = -1;
                if (newJobTaskWrapper.JobTask.Sales_Order_Job_Task__c) {
                    for (var j = 0; j < jobTaskWrappers.length; j++) {
                        if (jobTaskWrappers[j].JobTask.Sales_Order_Job_Task__c == newJobTaskWrapper.JobTask.Sales_Order_Job_Task__c) {
                            jobTaskWrapperIndex = j;

                            //ticket 19130 <<
                            if (!firstJobTaskWrapperIndex) {
                                firstJobTaskWrapperIndex = jobTaskWrapperIndex;
                            }
                            //ticket 19130 >>

                            break;
                        }
                    }
                }

                if (jobTaskWrapperIndex >= 0) {
                    //ticket 19130 <<
                    /*
                    var jobTaskWrapper = jobTaskWrappers[jobTaskWrapperIndex];
                    for (var j = 0; j < newJobTaskWrapper.TMLines.length; j++) {
                        var tmLine = newJobTaskWrapper.TMLines[j];
                        //update the job task on the tmLine
                        tmLine.TM_Job_Task__c = jobTaskWrapper.JobTask.TM_Job_Task__c;
                        tmLine.TM_Job_Task__r = jobTaskWrapper.JobTask;
                        jobTaskWrapper.TMLines.push(tmLine);
                    }*/
                    jobTaskWrappers[jobTaskWrapperIndex].TMLines = newJobTaskWrapper.TMLines;
                    //ticket 19130 >>
                }
                else {
                    jobTaskWrappers.push(newJobTaskWrapper);
                }
            }
            component.set("v.jobTaskWrappers", jobTaskWrappers); //refresh the view
            //ticket 19130 <<
            //var tabId = 'tab' + (jobTaskWrappers.length - 1);
            //component.set("v.selectedTabId", tabId);
            if (firstJobTaskWrapperIndex) {
                var tabId = 'tab' + firstJobTaskWrapperIndex;
                component.set("v.selectedTabId", tabId);
            }
            //ticket 19130 >>

            this.refreshTasks(component);
        });
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },
    getTaskTabs : function(component) {
        var taskTabs = [];
        var comp = component.find("job-task-line");

        if (comp) {
            if (Array.isArray(comp)) {
                taskTabs = comp;
            } else {
                taskTabs.push(comp);
            }
        }
        return taskTabs;
    },
    closeAllInlineEditRows : function(component, event, helper) {
        var jobTaskLines = [];
        var jobTaskLine = component.find("job-task-line");
        if (Array.isArray(jobTaskLine)) {
            jobTaskLines = jobTaskLine;
        }
        else {
            jobTaskLines.push(jobTaskLine);
        }
        jobTaskLines.forEach(function(jobTaskLine) {
            jobTaskLine.closeAllInlineEditRows();
        });
    },
    refreshTasks : function(component) {
        var jobTaskLines = this.getTaskTabs(component);
        for (var i = 0; i < jobTaskLines.length; i++) {
            jobTaskLines[i].groupTMLines();
        }
    },
    updateJobTaskOptions : function(component, jobTaskWrappers) {
        var jobTaskOptions = [];
        for (var i = 0; i < jobTaskWrappers.length; i++) {
            var jobTask = jobTaskWrappers[i].JobTask;
            var label = 'Task ' + jobTask.Task_No__c + ' - ' + jobTask.Name;
            jobTaskOptions.push({ "label": label, "value": jobTask.Line_No__c });
        }
        component.set("v.jobTaskOptions", jobTaskOptions);
    }
});