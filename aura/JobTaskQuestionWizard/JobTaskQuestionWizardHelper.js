({
    goToTemplateLine : function(component, event) {
        var templateLineIndex = component.get("v.templateLineIndex");
        var templateLines = component.get("v.templateLines");
        if (templateLineIndex < templateLines.length) {
            //component.set("v.templateLine", templateLines[templateLineIndex]);
            var templateLine = this.getTemplateLine(component, templateLineIndex);
            component.set("v.templateLine", templateLine);
            this.initAnswerLine(component, event);
        }
    },
    moveToPreviousTemplateLine : function(component, event) {
        var templateLineIndex = component.get("v.templateLineIndex");
        var templateLines = component.get("v.templateLines");

        /*
        if (templateLineIndex > 0) {
            templateLineIndex--;
            component.set("v.templateLine", templateLines[templateLineIndex]);
            component.set("v.templateLineIndex", templateLineIndex);
            this.initAnswerLine(component, event);
        }*/

        if (templateLineIndex > 0) {
            var found = false;
            while (templateLineIndex > 0 && !found) {
                templateLineIndex--;
                var templateLine = templateLines[templateLineIndex];

                //skip the child line if the parent line's answer is No.
                var parentLine = null;
                if (templateLine.Parent_Line__r && templateLine.Parent_Line__r.Line_No__c) {
                    for (var i = 0; i < templateLines.length; i++) {
                        if (templateLines[i].Line_No__c == templateLine.Parent_Line__r.Line_No__c) {
                            parentLine = templateLines[i];
                            break;
                        }
                    }
                }

                if (parentLine) {
                    if (templateLines[i].answer == 'Yes') {
                        found = true;
                    }
                } else {
                    found = true;
                }
            }

            if (templateLineIndex >= 0) {
                //templateLineIndex++;
                //component.set("v.templateLine", templateLines[templateLineIndex]);
                var templateLine = this.getTemplateLine(component, templateLineIndex);
                component.set("v.templateLine", templateLine);
                component.set("v.templateLineIndex", templateLineIndex);
                this.initAnswerLine(component, event);
            }
        }
    }, 
    moveToNextTemplateLine : function(component, event) {
        var templateLineIndex = component.get("v.templateLineIndex");
        var templateLines = component.get("v.templateLines");

        if (templateLineIndex < templateLines.length - 1) {
            var found = false;
            while (templateLineIndex < templateLines.length - 1 && !found) {
                templateLineIndex++;
                var templateLine = templateLines[templateLineIndex];
                //skip the child line if the parent line's answer is No.
                var parentLine = null;
                if (templateLine.Parent_Line__r && templateLine.Parent_Line__r.Line_No__c) {
                    for (var i = 0; i < templateLines.length; i++) {
                        if (templateLines[i].Line_No__c == templateLine.Parent_Line__r.Line_No__c) {
                            parentLine = templateLines[i];
                            break;
                        }
                    }
                }

                if (parentLine) {
                    if (templateLines[i].answer == 'Yes') {
                        found = true;
                    }
                } else {
                    found = true;
                }
            }

            if (templateLineIndex < templateLines.length) {
                //templateLineIndex++;
                //component.set("v.templateLine", templateLines[templateLineIndex]);
                var templateLine = this.getTemplateLine(component, templateLineIndex);
                component.set("v.templateLine", templateLine);
                component.set("v.templateLineIndex", templateLineIndex);
                this.initAnswerLine(component, event);
            }
        }
        else if (templateLineIndex == templateLines.length - 1) {
            component.set("v.templateLine", null);
            component.set("v.templateLineIndex", templateLines.length);
            var finished = true;
            for (var i = 0; i < templateLines.length; i++) {
                if (templateLines[i].answer == null) {
                    finished = false;
                    break;
                }
            };
            component.set("v.finished", finished);
        }

    },
    getTemplateLine : function(component, templateLineIndex) {
        var templateLines = component.get("v.templateLines");
        return JSON.parse(JSON.stringify(templateLines[templateLineIndex]));
    },
    initAnswerLine : function(component, event) {
        var templateLineIndex = component.get("v.templateLineIndex");
        var templateLines = component.get("v.templateLines");
        if (templateLineIndex < templateLines.length) {
            var templateLine = templateLines[templateLineIndex];
            if (templateLine.answer == null) {
                var answerLine = {};
                answerLine.Category__c = templateLine.Category__c;
                answerLine.Category__r = templateLine.Category__r;
                answerLine.Resource_Type__r = templateLine.Resource_Type__r;
                answerLine.Resource_Type__c = templateLine.Resource_Type__c;
                answerLine.Resource__c = templateLine.Resource__c;
                answerLine.Resource__r = templateLine.Resource__r;
                answerLine.Description__c = templateLine.Description__c;
                answerLine.Unit_of_Measure__c = templateLine.Unit_of_Measure__c;
                answerLine.Unit_of_Measure__r = templateLine.Unit_of_Measure__r;
                /*Waste001
                answerLine.Cost_Method__c = templateLine.Cost_Method__c;
                answerLine.Unit_Weight_Vol__c = templateLine.Unit_Weight_Vol__c;
                answerLine.Unit_Weight_Vol__r = templateLine.Unit_Weight_Vol__r;
                answerLine.Container_Size__c = templateLine.Container_Size__c;
                answerLine.Container_Size__r = templateLine.Container_Size__r;
                 */
                answerLine.Cost_Method__c = null;
                answerLine.Unit_Weight_Vol__c = null;
                answerLine.Unit_Weight_Vol__r = null;
                answerLine.Container_Size__c = null;
                answerLine.Container_Size__r = null;
                //answerLine.Quantity__c = templateLine.Quantity__c;
                templateLine.answerLine = answerLine;
            }
            var questionCard = component.find("question-card");
            questionCard.clearErrors();
            //alert(templateLineIndex + ': ' + templateLine.answerLine.Quantity__c)
            component.set("v.templateLine", templateLine);
        }
    },
    saveAnswerLine : function(component, event, answer) {
        var templateLines = component.get("v.templateLines");
        var templateLineIndex = component.get("v.templateLineIndex");
        var templateLine = component.get("v.templateLine");
        templateLine.answer = answer;
        if (templateLine.answer == 'No') {
            templateLine.Quantity__c = null;
        }
        templateLines[templateLineIndex] = templateLine;
        component.set("v.templateLines", templateLines);
    }
});