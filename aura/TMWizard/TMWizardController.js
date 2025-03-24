({
    doInit : function(component, event, helper) {
        try {
            var jobTaskTemplateId = component.get("v.jobTaskTemplateId");
            var params = {"jobTaskTemplateId": jobTaskTemplateId};
            helper.callServerMethod(component, event, "c.getJobTaskTemplateQuestionLines", params, function (response) {
                var jobTaskTemplateLines = JSON.parse(response);
                var jobTaskWrappers = component.get("v.jobTaskWrappers");

                var prompts = [];
                for (var i = 0; i < jobTaskWrappers.length; i++) {
                    var templateLines = JSON.parse(JSON.stringify(jobTaskTemplateLines));
                    //remove template lines with the resource already exists on the tm lines
                    var jobTaskWrapper = jobTaskWrappers[i];
                    for (var j = 0; j < templateLines.length; j++) {
                        var lineDeleted = null;
                        if (templateLines[j].Resource__c != null) {
                            for (var k = 0; k < jobTaskWrapper.TMLines.length; k++) {
                                if (templateLines[j].Resource__c == jobTaskWrapper.TMLines[k].Resource__c) {
                                    lineDeleted = templateLines[j].Line_No__c;
                                    templateLines.splice(j, 1);
                                    j--;
                                    break;
                                }
                            }
                        }
                        else if (templateLines[j].Resource_Type__c != null) {
                            for (var k = 0; k < jobTaskWrapper.TMLines.length; k++) {
                                if (templateLines[j].Resource_Type__c == jobTaskWrapper.TMLines[k].Resource_Type__c) {
                                    lineDeleted = templateLines[j].Line_No__c;
                                    templateLines.splice(j, 1);
                                    j--;
                                    break;
                                }
                            }
                        }

                        for (var x = 0; x < templateLines.length; x++) {
                            if (templateLines[x].Parent_Line__r && templateLines[x].Parent_Line__r.Line_No__c == lineDeleted) {
                                templateLines[x].Parent_Line__c = null;
                                templateLines[x].Parent_Line__r = null;
                            }
                        }

                    }

                    //sort template lines by category and parent-child
                    let sorts = [
                        { fieldName: 'Category__c', ascending: true, custom: ['Labor', 'Equipment', 'Materials', 'Subcontractors', 'Waste Disposal', 'Misc. Charges And Taxes', 'Demurrage', 'Bundled']},
                        { fieldName: 'Line_No__c', ascending: true, custom: null },
                    ];
                    this.sortLines(templateLines, sorts);
                    this.hierarchySort(templateLines);

                    if (templateLines.length > 0) {
                        prompts.push({
                            "title": jobTaskWrapper.JobTask.Name,
                            "jobTaskWrapperIndex": i,
                            "templateLines": templateLines
                        });
                    }
                }
                component.set("v.prompts", prompts);

                if (prompts.length > 0) {
                    helper.goToPrompt(component);
                } else {
                    var completeCallback = component.get("v.completeCallback");
                    if (completeCallback) {
                        completeCallback(jobTaskWrappers);
                    }
                }
            });
        }
        catch(err) {
            alert(err)
        }
    },
    doYes : function(component, event, helper) {
        var questions = component.find("question-wizard");
        var prompt = component.get("v.prompt");
        questions.doYes();
    },
    doNo : function(component, event, helper) {
        var prompt = component.get("v.prompt");
        var promptIndex = component.get("v.promptIndex");
        var prompts = component.get("v.prompts");
        var questions = component.find("question-wizard");
        questions.doNo();
    },
    handleRowAction : function(component, event, helper) {
        var name = event.getParam("name");
        var rowIndex = event.getParam("rowIndex");
        var action = event.getParam("action");
        var prompt = component.get("v.prompt");
        if (prompt.templateLines && prompt.templateLines.length > rowIndex) {
            switch (name) {
                case 'edit-answer':
                    if (action == 'click') {
                        component.set("v.prompt.templateLineIndex", rowIndex);
                    }
                    break;
            }
        }
    },
    doCompletePrompt : function(component, event, helper) {
        helper.saveAnswerLines(component);
        helper.moveToNextPrompt(component);
    },
    doCompletePrompts : function(component, event, helper) {
        helper.saveAnswerLines(component);
        var completeCallback = component.get("v.completeCallback");
        if (completeCallback) {
            var answers = component.get("v.answers");
            var tm = component.get("v.tm");
            var jobTaskWrappers = component.get("v.jobTaskWrappers");
            var nextTMLineNo = component.get("v.nextTMLineNo");

            for (var i = 0; i < answers.length; i++) {
                var answer = answers[i];
                var jobTaskWrapper = jobTaskWrappers[answer.jobTaskWrapperIndex];
                helper.insertTMLines(component, tm, jobTaskWrapper, nextTMLineNo, answer);
                nextTMLineNo = jobTaskWrapper.NextTMLineNo;
            }

            //pass jobTaskWrappers back to the caller
            completeCallback(jobTaskWrappers);
        }
    },
    doCancel : function(component, event, helper) {
        helper.showToast(component, "T&M Questions", "You have not completed all T&M questions. You must complete all questions to continue.", "warning", "dismissible");

        var cancelCallback = component.get("v.cancelCallback");
        if (cancelCallback) {
            cancelCallback();
        }
    }
});