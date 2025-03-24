({
    goToPrompt : function(component) {
        var promptIndex = component.get("v.promptIndex");
        var prompts = component.get("v.prompts");
        if (promptIndex < prompts.length) {
            prompts[promptIndex].templateLineIndex = 0;
            component.set("v.prompt", prompts[promptIndex]);
        }
    },
    moveToNextPrompt : function(component) {
        var promptIndex = component.get("v.promptIndex");
        var prompts = component.get("v.prompts");
        promptIndex++;
        if (promptIndex < prompts.length) {
            prompts[promptIndex].templateLineIndex = 0;
            component.set("v.prompt", prompts[promptIndex]);
            component.set("v.promptIndex", promptIndex);
        }
    },
    saveAnswerLines : function(component) {
        var prompt = component.get("v.prompt");
        var answers = component.get("v.answers");
        answers.push(prompt);
        component.set("v.answers", answers);
    },
    insertTMLines : function(component, tm, jobTaskWrapper, nextTMLineNo, answer) {
        for (var i = 0; i < answer.templateLines.length; i++) {
            var templateLine = answer.templateLines[i];
            if (templateLine.answer == 'Yes') {
                var answerLine = templateLine.answerLine;
                var tmLine = {};
                tmLine.TM__c = tm.Id;
                tmLine.Line_No__c = nextTMLineNo;
                tmLine.Category__c = answerLine.Category__c;
                tmLine.Resource_Type__c = answerLine.Resource_Type__c;
                tmLine.Resource_Type__r = answerLine.Resource_Type__r;
                tmLine.Resource__c = answerLine.Resource__c;
                tmLine.Resource__r = answerLine.Resource__r;
                tmLine.Description__c = answerLine.Description__c;
                tmLine.Quantity__c = answerLine.Quantity__c;
                tmLine.Unit_of_Measure__c = answerLine.Unit_of_Measure__c;
                tmLine.Unit_of_Measure__r = answerLine.Unit_of_Measure__r;
                /*Waste001
                tmLine.Cost_Method__c = answerLine.Cost_Method__c;
                tmLine.Unit_Weight_Vol__c = answerLine.Unit_Weight_Vol__c;
                tmLine.Unit_Weight_Vol__r = answerLine.Unit_Weight_Vol__r;
                tmLine.Container_Size__c = answerLine.Container_Size__c;
                tmLine.Container_Size__r = answerLine.Container_Size__r;
                 */
                tmLine.Cost_Method__c = null;
                tmLine.Unit_Weight_Vol__c = null;
                tmLine.Unit_Weight_Vol__r = null;
                tmLine.Container_Size__c = null;
                tmLine.Container_Size__r = null;

                tmLine.Facility__c = answerLine.Facility__c;
                tmLine.Facility__r = answerLine.Facility__r;
                if (tmLine.Category__c == 'Labor' || (tmLine.Category__c == 'Equipment')) {
                    tmLine.Service_Center__c = tm.Service_Center__c;
                    tmLine.Service_Center__r = tm.Service_Center__r;
                }
                tmLine.TM_Job_Task__c = jobTaskWrapper.JobTask.Id;
                tmLine.TM_Job_Task__r = jobTaskWrapper.JobTask;
                tmLine.TM__c = tm.Id;
                jobTaskWrapper.TMLines.push(tmLine);

                nextTMLineNo++;
            }
        }
        jobTaskWrapper.NextTMLineNo = nextTMLineNo;
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
    hierarchySort : function(lines) {
        var mapChildLinesByParentLineNo = new Map();
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];
            if (line.Parent_Line__r != null && line.Parent_Line__r.Line_No__c != null) {
                var parentLineNo = line.Parent_Line__r.Line_No__c;
                var children;
                if (mapChildLinesByParentLineNo.has(parentLineNo)) {
                    children = mapChildLinesByParentLineNo.get(parentLineNo);
                }
                else {
                    var children = [];
                    mapChildLinesByParentLineNo.set(parentLineNo, children);
                }
                children.push(line);
            }
        }

        var lines2 = [];
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i];

            if (!line.Parent_Line__r || line.Parent_Line__r.Line_No__c == null) {
                lines2.push(line);
                //push child lines
                if (mapChildLinesByParentLineNo.has(line.Line_No__c)) {
                    var children = mapChildLinesByParentLineNo.get(line.Line_No__c);
                    children.forEach(function(child) {
                        lines2.push(child);
                    })
                }
            }
        }

        //assign the ordered list back to lines
        for (var i = 0; i < lines.length; i++) {
            lines[i] = lines2[i];
        }
    },
});