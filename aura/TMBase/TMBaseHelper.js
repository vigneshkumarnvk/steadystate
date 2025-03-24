({
    calculateNextTMLineNo : function(component) {
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var nextTMLineNo = 0;
        var nextJobTaskLineNo = 0;
        jobTaskWrappers.forEach(function(jobTaskWrapper) {
            if (nextJobTaskLineNo < jobTaskWrapper.JobTask.Line_No__c) {
                nextJobTaskLineNo = jobTaskWrapper.JobTask.Line_No__c;
            }

            jobTaskWrapper.TMLines.forEach(function(tmLine) {
                if (nextTMLineNo < tmLine.Line_No__c) {
                    nextTMLineNo = tmLine.Line_No__c;
                }
            })
        });
        nextJobTaskLineNo++;
        nextTMLineNo++;
        component.set("v.nextJobTaskLineNo", nextJobTaskLineNo);
        component.set("v.nextTMLineNo", nextTMLineNo);
    },
    promptWizard : function(component, event, jobTaskWrappers, resolve, reject) {
        var tm = component.get("v.tm");
        var params = { "JSONTM": JSON.stringify(tm), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };
        this.callServerMethod(component, event, "c.prepareWizardQuestions", params, function (response) {
            var mapQuestionsByIndex = JSON.parse(response);
            var jobTaskQuestionSets = [];
            if (Object.keys(mapQuestionsByIndex).length > 0) {
                for (var jobTaskWrapperIndex in mapQuestionsByIndex) {
                    var questions = mapQuestionsByIndex[jobTaskWrapperIndex];
                    var jobTaskWrapper = jobTaskWrappers[jobTaskWrapperIndex];
                    var jobTaskTemplate = {
                        "jobTaskWrapperIndex": jobTaskWrapperIndex,
                        "title": 'Task ' + jobTaskWrapper.JobTask.Task_No__c + ' - ' + jobTaskWrapper.JobTask.Name,
                        "templateLines": questions
                    };
                    jobTaskQuestionSets.push(jobTaskTemplate);
                }
            }

            if (jobTaskQuestionSets.length > 0) {
                var buttons = [];

                //ticket 19130 <<
                /*
                var params = {
                    "questionSets": jobTaskQuestionSets,
                    "contractId": tm.Contract__c,
                    "completeCallback": this.completeWizardCallback.bind(this, component, event, resolve, jobTaskWrappers),
                    "cancelCallback": this.cancelCallback.bind(this, component, event),
                };
                this.openModal(component, event, "Wizard", null, buttons, "c:Wizard", params, "medium", null, null);
                */
                var params = {
                    "questionSets": jobTaskQuestionSets,
                    "contractId": tm.Contract__c,
                    "sourceObjectType": "TM",
                    "completeCallback": this.completeWizardCallback.bind(this, component, event, resolve, jobTaskWrappers),
                    "cancelCallback": this.cancelCallback.bind(this, component, event),
                };
                var device = $A.get("$Browser.formFactor");
                if (device == 'TABLET' || device == 'IPAD') {
                    this.openModal(component, event, "Wizard", null, buttons, "c:Wizard", params, "large", null, null);
                }
                else {
                    this.openModal(component, event, "Wizard", null, buttons, "c:Wizard", params, "small-high", null, null);
                }
                //ticket 19130 >>
            }
            else {
                resolve();
            }
        }, function(error) {
            if (reject) {
                reject(error);
            }
        });
    },
    completeWizardCallback : function(component, event, resolve, jobTaskWrappers, jobTaskQuestionSets) {
        this.closeModal(component, event);
        var tm = component.get("v.tm");

        //ticket 19130 <<
        /*
        for (var i = 0; i < jobTaskQuestionSets.length; i++) {
            var jobTaskQuestionSet = jobTaskQuestionSets[i];
            var mapTemplateLinesByIndex = new Map();
            for (var j = 0; j < jobTaskQuestionSet.templateLines.length; j++) {
                var templateLine = jobTaskQuestionSet.templateLines[j];
                mapTemplateLinesByIndex.set(templateLine.Line_No__c, templateLine);
            }

            //update existing lines
            var mapTMLinesByLineNo = new Map();
            var parentLineNos = [];

            var jobTaskWrapper = jobTaskWrappers[jobTaskQuestionSet.jobTaskWrapperIndex];
            for (var j = 0; j < jobTaskWrapper.TMLines.length; j++) {
                var tmLine = jobTaskWrapper.TMLines[j];
                if (mapTemplateLinesByIndex.has(tmLine.Line_No__c)) {
                    var templateLine = mapTemplateLinesByIndex.get(tmLine.Line_No__c);
                    if (templateLine.Quantity__c) {
                        tmLine.Quantity__c = templateLine.Quantity__c;
                        tmLine.Unit_of_Measure__c = templateLine.Unit_of_Measure__c;
                        tmLine.Unit_of_Measure__r = templateLine.Unit_of_Measure__r;
                    }
                    tmLine.Wizard_Question_Answered__c = true;
                    parentLineNos.push(tmLine.Parent_Line__r.Line_No__c);
                    mapTemplateLinesByIndex.delete(tmLine.Line_No__c);
                }
                mapTMLinesByLineNo.set(tmLine.Line_No__c, tmLine);
            }

            //insert new child lines
            if (mapTemplateLinesByIndex.size > 0) {
                for (const [key, templateLine] of mapTemplateLinesByIndex.entries()) {
                    var parentLine = mapTMLinesByLineNo.get(templateLine.Parent_Line__r.Line_No__c);
                    parentLineNos.push(parentLine.Line_No__c);
                    if (templateLine.Quantity__c != null && templateLine.Quantity__c > 0) {
                        var childLine = {};
                        childLine.Line_No__c = templateLine.Line_No__c;
                        childLine.TM_Job_Task__c = jobTaskWrapper.JobTask.Id;
                        childLine.TM_Job_Task__r = jobTaskWrapper.JobTask;
                        childLine.TM__c = tm.Id;
                        childLine.TM__r = {"Id": tm.Id, "Name": tm.Name};
                        childLine.Category__c = templateLine.Category__c;
                        if (childLine.Category__c == 'Labor' || childLine.Category__c == 'Equipment') {
                            childLine.Service_Center__c = parentLine.Service_Center__c;
                            childLine.Service_Center__r = parentLine.Service_Center__r;
                        }
                        childLine.Parent_Line__c = parentLine.Id;
                        childLine.Parent_Line__r = { "Id": parentLine.Id, "Line_No__c": parentLine.Line_No__c};
                        childLine.Resource_Type__c = templateLine.Resource_Type__c;
                        childLine.Resource_Type__r = templateLine.Resource_Type__r;
                        childLine.Resource__c = templateLine.Resource__c;
                        childLine.Resource__r = templateLine.Resource__r;
                        if (templateLine.Resource_Type__r) {
                            childLine.Description__c = templateLine.Description__c;
                            if (childLine.Resource__r) {
                                childLine.Resource_Name__c = templateLine.Resource__r.Name;
                            }
                        }
                        else {
                            childLine.Description__c = templateLine.Description__c;
                        }
                        childLine.Quantity__c = templateLine.Quantity__c;
                        childLine.Unit_of_Measure__c = templateLine.Unit_of_Measure__c;
                        childLine.Unit_of_Measure__r = templateLine.Unit_of_Measure__r;
                        childLine.Cost_Method__c = templateLine.Cost_Method__c;
                        childLine.Container_Size__c = templateLine.Container_Size__c;
                        childLine.Container_Size__r = templateLine.Container_Size__r;
                        childLine.Unit_Weight_Vol__c = templateLine.Unit_Weight_Vol__c;
                        childLine.Unit_Weight_Vol__r = templateLine.Unit_Weight_Vol__r;
                        childLine.Wizard_Question_Answered__c = true;
                        jobTaskWrapper.TMLines.push(childLine);
                    }
                }
            }

            //update parent lines
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                var jobTaskWrapper = jobTaskWrappers[i];
                for (var j = 0; j < jobTaskWrapper.TMLines.length; j++) {
                    var tmLine = jobTaskWrapper.TMLines[j];
                    if (parentLineNos.includes(tmLine.Line_No__c)) {
                        tmLine.Wizard_Question_Answered__c = true;
                    }
                }
            }
        }
        */

        for (var i = 0; i < jobTaskQuestionSets.length; i++) {
            var jobTaskQuestionSet = jobTaskQuestionSets[i];
            var mapTMLinesByLineNo = new Map();
            var mapParentChildRelationsByKey = new Map();
            var mapParentLinesByChildLineNo = new Map();
            var jobTaskWrapper = jobTaskWrappers[jobTaskQuestionSet.jobTaskWrapperIndex];

            for (var j = 0; j < jobTaskWrapper.TMLines.length; j++) {
                var tmLine = jobTaskWrapper.TMLines[j];
                tmLine.Wizard_Question_Answered__c = true;
                mapTMLinesByLineNo.set(tmLine.Line_No__c, tmLine);
            }

            for (var j = 0; j < jobTaskWrapper.TMLines.length; j++) {
                var tmLine = jobTaskWrapper.TMLines[j];
                if (tmLine.TM_Child_Lines__r && tmLine.TM_Child_Lines__r.records) {
                    for (var k = 0; k < tmLine.TM_Child_Lines__r.records.length; k++) {
                        var relation = tmLine.TM_Child_Lines__r.records[k];
                        var key = relation.Parent_Line__r.Line_No__c + ';' + relation.Child_Line__r.Line_No__c;
                        mapParentChildRelationsByKey.set(key, relation);

                        var parentLines;
                        if (mapParentLinesByChildLineNo.has(relation.Child_Line__r.Line_No__c)) {
                            parentLines = mapParentLinesByChildLineNo.get(relation.Child_Line__r.Line_No__c);
                        }
                        else {
                            parentLines = [];
                            mapParentLinesByChildLineNo.set(relation.Child_Line__r.Line_No__c, parentLines);
                        }
                        parentLines.push(mapTMLinesByLineNo.get(relation.Parent_Line__r.Line_No__c));
                    }
                }
            }

            for (var j = 0; j < jobTaskQuestionSet.templateLines.length; j++) {
                var templateLine = jobTaskQuestionSet.templateLines[j];
                if (templateLine.Quantity__c && templateLine.Quantity__c > 0) {
                    var childLine;
                    if (mapTMLinesByLineNo.has(templateLine.Line_No__c)) {
                        childLine = mapTMLinesByLineNo.get(templateLine.Line_No__c);
                        childLine.Quantity__c = templateLine.Quantity__c;
                        childLine.Unit_of_Measure__c = templateLine.Unit_of_Measure__c;
                        childLine.Unit_of_Measure__r = templateLine.Unit_of_Measure__r;
                    }
                    else {
                        childLine = {};
                        childLine.Line_No__c = templateLine.Line_No__c;
                        childLine.TM_Job_Task__c = jobTaskWrapper.JobTask.Id;
                        childLine.TM_Job_Task__r = jobTaskWrapper.JobTask;
                        childLine.TM__c = tm.Id;
                        childLine.TM__r = {"Id": tm.Id, "Name": tm.Name};
                        childLine.Category__c = templateLine.Category__c;
                        if (childLine.Category__c == 'Labor' || childLine.Category__c == 'Equipment') {
                            childLine.Service_Center__c = tm.Service_Center__c;
                            childLine.Service_Center__r = tm.Service_Center__r;
                        }
                        childLine.Resource_Type__c = templateLine.Resource_Type__c;
                        childLine.Resource_Type__r = templateLine.Resource_Type__r;
                        childLine.Resource__c = templateLine.Resource__c;
                        childLine.Resource__r = templateLine.Resource__r;
                        if (templateLine.Resource_Type__r) {
                            childLine.Description__c = templateLine.Description__c;
                            if (childLine.Resource__r) {
                                childLine.Resource_Name__c = templateLine.Resource__r.Name;
                            }
                        } else {
                            childLine.Description__c = templateLine.Description__c;
                        }
                        childLine.Quantity__c = templateLine.Quantity__c;
                        childLine.Unit_of_Measure__c = templateLine.Unit_of_Measure__c;
                        childLine.Unit_of_Measure__r = templateLine.Unit_of_Measure__r;
                        /*Waste001
                        childLine.Cost_Method__c = templateLine.Cost_Method__c;
                        childLine.Container_Size__c = templateLine.Container_Size__c;
                        childLine.Container_Size__r = templateLine.Container_Size__r;
                        childLine.Unit_Weight_Vol__c = templateLine.Unit_Weight_Vol__c;
                        childLine.Unit_Weight_Vol__r = templateLine.Unit_Weight_Vol__r;
                         */
                        childLine.Cost_Method__c = null;
                        childLine.Container_Size__c = null;
                        childLine.Container_Size__r = null;
                        childLine.Unit_Weight_Vol__c = null;
                        childLine.Unit_Weight_Vol__r = null;

                        childLine.Wizard_Question_Answered__c = true;
                        childLine.Is_Child_Resource__c = true;
                        childLine.Sales_Line__c = templateLine.Sales_Line__c;
                        jobTaskWrapper.TMLines.push(childLine);

                        mapTMLinesByLineNo.set(childLine.Line_No__c, childLine);
                    }

                    //handle new relationship
                    if (templateLine.Parent_Lines__r && templateLine.Parent_Lines__r.records) {
                        for (var k = 0; k < templateLine.Parent_Lines__r.records.length; k++) {
                            var relation = templateLine.Parent_Lines__r.records[k];
                            if (!mapTMLinesByLineNo.has(relation.Parent_Line__r.Line_No__c)) alert(templateLine.Line_No__c + ': parent line #' + relation.Parent_Line__r.Line_No__c + ' is not found.');
                            if (!mapTMLinesByLineNo.has(relation.Child_Line__r.Line_No__c)) alert(templateLine.Line_No__c + ': child line #' + relation.Child_Line__r.Line_No__c + ' is not found.');
                            var parentLine = mapTMLinesByLineNo.get(relation.Parent_Line__r.Line_No__c);
                            var childLine = mapTMLinesByLineNo.get(relation.Child_Line__r.Line_No__c);

                            var key = parentLine.Line_No__c + ';' + childLine.Line_No__c;
                            if (!mapParentChildRelationsByKey.has(key)) {
                                if (!parentLine.TM_Child_Lines__r || !parentLine.TM_Child_Lines__r.records) {
                                    parentLine.TM_Child_Lines__r = {"records": []};
                                }
                                var relation2 = {};
                                relation2.Parent_Line__c = parentLine.Id;
                                relation2.Parent_Line__r = {
                                    "Id": parentLine.Id,
                                    "Line_No__c": parentLine.Line_No__c,
                                    "Category__c": parentLine.Category__c,
                                    "Resource_Type__c": parentLine.Resource_Type__c,
                                    "Resource__c": parentLine.Resource__c,
                                    "Resource__r": parentLine.Resource__r
                                };
                                relation2.Child_Line__c = childLine.Id;
                                relation2.Child_Line__r = {
                                    "Id": childLine.Id,
                                    "Line_No__c": childLine.Line_No__c,
                                    "Category__c": childLine.Category__c,
                                    "Resource_Type__c": childLine.Resource_Type__c,
                                    "Resource_Type__r": childLine.Resource_Type__r,
                                    "Resource__c": childLine.Resource__c,
                                    "Resource__r": childLine.Resource__r
                                };

                                parentLine.TM_Child_Lines__r.records.push(relation2);
                                parentLine.TM_Child_Lines__r.totalSize = parentLine.TM_Child_Lines__r.records.length;
                                parentLine.TM_Child_Lines__r.done = "true";
                                mapTMLinesByLineNo.set(parentLine.Line_No__c, parentLine);
                            }
                        }
                    }
                } else {
                    /* system should not delete the child line * email 10/25 <<
                    if (mapTMLinesByLineNo.has(templateLine.Line_No__c)) {
                        mapTMLinesByLineNo.delete(templateLine.Line_No__c);
                        for (var k = 0; k < jobTaskWrapper.TMLines.length; k++) {
                            if (jobTaskWrapper.TMLines[k].Line_No__c == templateLine.Line_No__c) {
                                jobTaskWrapper.TMLines.splice(k, 1);
                                break;
                            }
                        }

                        if (mapParentLinesByChildLineNo.has(templateLine.Line_No__c)) {
                            for (var k = 0; k < mapParentLinesByChildLineNo.get(templateLine.Line_No__c); k++) {
                                var parentLine = mapParentLinesByChildLineNo.get(templateLine.Line_No__c);
                                for (var l = 0; l < parentLine.TM_Child_Lines__r.records.length; l++) {
                                    if (parentLine.TM_Child_Lines__r.records[l].Child_Line__r.Line_No__c == templateLine.Line_No__c) {
                                        parentLine.TM_Child_Lines__r.records.splice(l, 1);
                                        l--;
                                    }
                                }
                            }
                        }
                    }
                    system should not delete the child line * email 10/25 >>
                    */

                    //unlink the line from any child-child resource that has the line as a parent
                    var childLine;
                    if (mapTMLinesByLineNo.has(templateLine.Line_No__c)) {
                        childLine = mapTMLinesByLineNo.get(templateLine.Line_No__c);
                        childLine.Quantity__c = 0;
                    }

                    for (var k = 0; k < jobTaskQuestionSet.templateLines.length; k++) {
                        var templateLine2 = jobTaskQuestionSet.templateLines[k];
                        if (templateLine2.Parent_Lines__r && templateLine2.Parent_Lines__r.records) {
                            for (var l = 0; l < templateLine2.Parent_Lines__r.records.length; l++) {
                                var relation = templateLine2.Parent_Lines__r.records[l];
                                if (relation.Parent_Line__r.Line_No__c == templateLine.Line_No__c) {
                                    templateLine2.Parent_Lines__r.records.splice(l, 1);
                                    l--;
                                }
                            }
                        }
                    }
                }
            }

            this.cleanUpParentChildRelations(jobTaskWrapper);
            jobTaskWrappers[jobTaskQuestionSet.jobTaskWrapperIndex] = jobTaskWrapper;
        }
        //ticket 19130 >>

        this.refreshLineSections(component, event);
        if (resolve) {
            resolve();
        }
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },
    calculateTMJobTasks : function(component, event, tm, jobTaskWrappers, resolve, reject) {
        var params = { "JSONTM": JSON.stringify(tm), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };
        this.callServerMethod(component, event, "c.calculateTMJobTasks", params, function(response) {
            Object.assign(jobTaskWrappers, JSON.parse(response));
            this.refreshLineSections(component, event);

            if (resolve) {
                resolve();
            }
        }, function(error) {
            if (reject) {
                reject(error);
            }
        })
    },
    refreshLineSections : function(component, event) {
        var tmlinelist = component.find("tm-lines");
        if (tmlinelist) {
            tmlinelist.refreshTasks();
        }
    },
    //ticket 19130 <<
    cleanUpParentChildRelations : function(jobTaskWrapper) {
        var lineNos = [];
        for (var i = 0; i < jobTaskWrapper.TMLines.length; i++) {
            lineNos.push(parseInt(jobTaskWrapper.TMLines[i].Line_No__c));
        }

        var childLineNos = [];
        for (var i = 0; i < jobTaskWrapper.TMLines.length; i++) {
            var tmLine = jobTaskWrapper.TMLines[i];
            if (tmLine.TM_Child_Lines__r && tmLine.TM_Child_Lines__r.records) {
                for (var j = 0; j < tmLine.TM_Child_Lines__r.records.length; j++) {
                    var relation = tmLine.TM_Child_Lines__r.records[j];
                    if (relation.Child_Line__r) {
                        var childLineNo = parseInt(relation.Child_Line__r.Line_No__c);
                        if (!lineNos.includes(childLineNo)) { //child resource line is deleted
                            tmLine.TM_Child_Lines__r.records.splice(j, 1);
                            j--;
                        }
                        else {
                            if (!childLineNos.includes(childLineNo)) {
                                childLineNos.push(childLineNo);
                            }
                        }
                    }
                }
                tmLine.TM_Child_Lines__r.totalSize = tmLine.TM_Child_Lines__r.records.length;
                tmLine.TM_Child_Lines__r.done = "true";
            }
        }

        for (var i = 0; i < jobTaskWrapper.TMLines.length; i++) {
            var tmLine = jobTaskWrapper.TMLines[i];
            tmLine.Dereferenced_Child_Resource__c = false;
            if (childLineNos.includes(parseInt(tmLine.Line_No__c))) {
                tmLine.Is_Child_Resource__c = true;
            } else if (tmLine.Is_Child_Resource__c == true) {
                tmLine.Dereferenced_Child_Resource__c = true;
            }
        }
    }
    //ticket 19130 >>
})