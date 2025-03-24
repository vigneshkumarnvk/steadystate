({
    getTMLines : function(component, event) {
        var tm = component.get("v.tm");
        var category = component.get("v.category");
        var params = { "tmId": tm.Id, "category": category };
        this.callServerMethod(component, event, "c.getTMLines", params, function(response) {
            var jobTaskWrappers = JSON.parse(response);
            //deleted lines <<
            /*
            var nextTMLineNo = 1;
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                if (jobTaskWrappers[i].NextTMLineNo > nextTMLineNo) {
                    nextTMLineNo = jobTaskWrappers[i].NextTMLineNo;
                }
            }
            component.set("v.nextTMLineNo", nextTMLineNo);

            var jobTaskOptions = [];
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                //add a new empty line
                var tmLine = {};
                tmLine.Line_No__c = nextTMLineNo;
                tmLine.TM__c = tm.Id;
                tmLine.Category__c = category;
                tmLine.Service_Center__c = tm.Service_Center__c;
                tmLine.Service_Center__r = tm.Service_Center__r;
                tmLine.TM_Job_Task__c = jobTaskWrappers[i].JobTask.Id
                tmLine.TM_Job_Task__r = jobTaskWrappers[i].JobTask;
                jobTaskWrappers[i].TMLines.push(tmLine);

                //create job task selection list
                var jobTask = jobTaskWrappers[i].JobTask;
                var jobTaskOption = { "label": 'Task ' + jobTask.Task_No__c + ' - ' + jobTask.Name, "value": jobTask.Line_No__c};
                jobTaskOptions.push(jobTaskOption);
                nextTMLineNo++;

                //sort TM Lines
                this.sortTMLines(jobTaskWrappers[i].TMLines);
            }
            component.set("v.jobTaskWrappers", jobTaskWrappers);
            component.set("v.jobTaskOptions", jobTaskOptions);
            component.set("v.nextTMLineNo", nextTMLineNo);
            */
            this.setJobTaskWrappers(component, tm, category, jobTaskWrappers);
            //deleted lines >>
        })
    },
    moveTMLines : function(component, event) {
        var tmLines = event.getParam("taskLines");
        var fromJobTask = event.getParam("fromJobTask");
        var toJobTask = event.getParam("toJobTask");

        var mapTMLinesByLineNo = new Map();
        for (var i = 0; i < tmLines.length; i++) {
            mapTMLinesByLineNo.set(tmLines[i].Line_No__c, tmLines[i]);
        }

        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var targetJobTaskWrapperIndex = -1;
        for (var i = 0; i < jobTaskWrappers.length; i++) {
            if (jobTaskWrappers[i].JobTask.Line_No__c == toJobTask.Line_No__c) {
                targetJobTaskWrapperIndex = i;
                break;
            }
        }

        if (targetJobTaskWrapperIndex >= 0) {
            var targetJobTaskWrapper = jobTaskWrappers[targetJobTaskWrapperIndex];
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                if (i != targetJobTaskWrapperIndex) {
                    var jobTaskWrapper = jobTaskWrappers[i];
                    for (var j = 0; j < jobTaskWrapper.TMLines.length; j++) {
                        var tmLine = jobTaskWrapper.TMLines[j];
                        if (mapTMLinesByLineNo.has(tmLine.Line_No__c)) {
                            tmLine.Selected = false;
                            tmLine.TM_Job_Task__c = targetJobTaskWrapper.JobTask.Id;
                            tmLine.TM_Job_Task__r = targetJobTaskWrapper.JobTask;
                            targetJobTaskWrapper.TMLines.push(tmLine);
                            jobTaskWrapper.TMLines.splice(j, 1);
                            j--;
                        }
                    }
                }
            }
            this.sortTMLines(targetJobTaskWrapper.TMLines);
            component.set("v.jobTaskWrappers", jobTaskWrappers);
            component.set("v.unsavedChanges", true);
        }
    },
    saveTMLines : function(component, event) {
        var tm = component.get("v.tm");
        var category = component.get("v.category");
        var jobTaskWrappers = JSON.parse(JSON.stringify(component.get("v.jobTaskWrappers"))); //make a copy
        var params = { "JSONTM": JSON.stringify(tm), "category": category, "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };
        this.callServerMethod(component, event, "c.saveTM", params, function(response) {
            //deleted lines <<
            var jobTaskWrappers2 = JSON.parse(response);
            this.setJobTaskWrappers(component, tm, category, jobTaskWrappers2);
            //deleted lines >>

            component.set("v.unsavedChanges", false);
            this.showToast(component, "Save", "Your changes are saved.", "success", "dismissible");
        }, function(err) {
            //ticket 19725 <<
            //this.showToast(component, "", err, "error", "dismissible");
            this.showToast(component, "", err, "error", "dismissible", 10000);
            //ticket 19725 >>
        })
    },
    sortTMLines : function(tmLines) {
        let sorts = [
            { fieldName: 'Line_No__c', ascending: true, custom: null },
        ];
        this.sortLines(tmLines, sorts);
    },
    sortLines : function(objList, sorts) {
        objList.sort(function(a, b) {
            return sort(a, b, sorts, 0);
        });

        function sort(a, b, sorts, sortIndex) {
            var fieldName = sorts[sortIndex].fieldName;
            var custom = sorts[sortIndex].custom;
            var ascending = sorts[sortIndex].ascending;

            var val1;
            var val2;
            if (custom != null) {
                val1 = custom.indexOf(a[fieldName]);
                val2 = custom.indexOf(b[fieldName]);
            }
            else {
                val1 = a[fieldName];
                val2 = b[fieldName];
            }

            var order = 0;
            if (val1 > val2) {
                order = 1;
            } else if (val1 < val2) {
                order = -1;
            }
            else {
                if (sortIndex < sorts.length - 1) {
                    sortIndex++;
                    order = sort(a, b, sorts, sortIndex);
                }
            }

            if (ascending != true) {
                order = order * -1;
            }
            return order;
        };
    },
    //deleted lines <<
    setJobTaskWrappers : function(component, tm, category, jobTaskWrappers) {
        var nextTMLineNo = 1;
        for (var i = 0; i < jobTaskWrappers.length; i++) {
            if (jobTaskWrappers[i].NextTMLineNo > nextTMLineNo) {
                nextTMLineNo = jobTaskWrappers[i].NextTMLineNo;
            }
        }
        component.set("v.nextTMLineNo", nextTMLineNo);

        var jobTaskOptions = [];
        for (var i = 0; i < jobTaskWrappers.length; i++) {
            //add a new empty line
            var tmLine = {};
            tmLine.Line_No__c = nextTMLineNo;
            tmLine.TM__c = tm.Id;
            tmLine.Category__c = category;
            tmLine.Service_Center__c = tm.Service_Center__c;
            tmLine.Service_Center__r = tm.Service_Center__r;
            tmLine.TM_Job_Task__c = jobTaskWrappers[i].JobTask.Id
            tmLine.TM_Job_Task__r = jobTaskWrappers[i].JobTask;
            jobTaskWrappers[i].TMLines.push(tmLine);

            //create job task selection list
            var jobTask = jobTaskWrappers[i].JobTask;
            var jobTaskOption = { "label": 'Task ' + jobTask.Task_No__c + ' - ' + jobTask.Name, "value": jobTask.Line_No__c};
            jobTaskOptions.push(jobTaskOption);
            nextTMLineNo++;

            //sort TM Lines
            this.sortTMLines(jobTaskWrappers[i].TMLines); 
        }
        component.set("v.jobTaskWrappers", jobTaskWrappers);
        component.set("v.jobTaskOptions", jobTaskOptions);
        component.set("v.nextTMLineNo", nextTMLineNo);
    }
    //deleted lines >>
});