({
    goToQuestion : function(component, event) {
        var questionSet =component.get("v.questionSet");
        if (questionSet.questionIndex < questionSet.templateLines.length) {
            var templateLine = questionSet.templateLines[questionSet.questionIndex];
            //ticket 19130 <<
            component.set("v.xTemplateLine", JSON.parse(JSON.stringify(templateLine)));
            //ticket 19130 >>
            component.set("v.templateLine", templateLine);
        }
    },
    moveToPreviousQuestion : function(component, event) {
        //ticket 19130 <<
        var questionCard = component.find("question-card");
        questionCard.clearErrors();
        //ticket 19130 >>

        var questionSet = component.get("v.questionSet");
        if (questionSet.questionIndex > 0) {
            //ticket 19130 <<
            /*
            var found = false;
            while (questionSet.questionIndex > 0 && !found) {
                questionSet.questionIndex--;

                var templateLine = questionSet.templateLines[questionSet.questionIndex];
                //skip the child line if the parent line's answer is No.
                var parentLine = null;
                if (templateLine.Parent_Line__r && templateLine.Parent_Line__r.Line_No__c) {
                    for (var i = 0; i < questionSet.templateLines.length; i++) {
                        if (questionSet.templateLines[i].Line_No__c == templateLine.Parent_Line__r.Line_No__c) {
                            parentLine = questionSet.templateLines[i];
                            break;
                        }
                    }
                }

                if (parentLine) {
                    if (questionSet.templateLines[i].answer == 'Yes') {
                        found = true;
                    }
                } else {
                    found = true;
                }
            }
            */
            /*
            var templateLine = component.get("v.templateLine");
            if (templateLine.answer == 'Yes') {
                var question = component.find("question-card");
                if (question.validateFields(component)) {
                    this.saveAnswer(component, event, 'Yes');
                    questionSet.questionIndex--;
                }
            }
            else if (templateLine.answer == 'No') {
                this.saveAnswer(component, event, 'No');
                questionSet.questionIndex--;
            }
            else {
                this.showToast(component, null, "You must answer Yes or No to this question.", "warning", "dismissible");
            }*/
            questionSet.questionIndex--;
            //ticket 19130 >>

            if (questionSet.questionIndex >= 0) {
                var templateLine = questionSet.templateLines[questionSet.questionIndex];
                //ticket 19130 <<
                component.set("v.xTemplateLine", JSON.parse(JSON.stringify(templateLine)));
                //ticket 19130 >>

                component.set("v.questionSet", questionSet);
                component.set("v.templateLine", templateLine);
            }
        }
    },
    moveToNextQuestion : function(component, event) {
        var questionCard = component.find("question-card");
        questionCard.clearErrors();

        var questionSet =component.get("v.questionSet");
        if (questionSet.questionIndex < questionSet.templateLines.length - 1) {
            //ticket 19130 <<
            /*
            var found = false;
            while (questionSet.questionIndex < questionSet.templateLines.length - 1 && !found) {
                questionSet.questionIndex++;
                var templateLine = questionSet.templateLines[questionSet.questionIndex];
                //skip the child line if the parent line's answer is No.
                var parentLine = null;
                if (templateLine.Parent_Line__r && templateLine.Parent_Line__r.Line_No__c) {
                    for (var i = 0; i < questionSet.templateLines.length; i++) {
                        if (questionSet.templateLines[i].Line_No__c == templateLine.Parent_Line__r.Line_No__c) {
                            parentLine = questionSet.templateLines[i];
                            break;
                        }
                    }
                }

                if (parentLine) {
                    if (questionSet.templateLines[i].answer == 'Yes') {
                        found = true;
                    }
                } else {
                    found = true;
                }
            }
            */
            var templateLine = component.get("v.templateLine");
            if (templateLine.answer == 'Yes') {
                var question = component.find("question-card");
                if (question.validateFields(component)) {
                    this.saveAnswer(component, event, 'Yes');
                    questionSet.questionIndex++;
                }
            }
            else if (templateLine.answer == 'No') {
                this.saveAnswer(component, event, 'No');
                questionSet.questionIndex++;

                //ticket 19130 05.13.2023 << -- does not work  comment out
                if (templateLine.Quantity__c == 0) {
                    //check next child resource
                    for (var i = questionSet.questionIndex; i < questionSet.templateLines.length; i++) {
                        var templateLine2 = questionSet.templateLines[i];
                        var qty = 0;

                        for (var j = 0; j < templateLine2.Parent_Lines__r.records.length; j++) {
                            var relation = templateLine2.Parent_Lines__r.records[j];
                            if (relation.Parent_Line__r.Quantity__c) {
                                qty += relation.Parent_Line__r.Quantity__c;
                            }
                        }
                        if (qty == 0) {
                            templateLine2.Wizard_Question_Answered__c = true;
                            templateLine2.answer = 'No';
                            templateLine2.Quantity__c = 0;
                        }
                    }
                }

                for (var i = questionSet.questionIndex; i < questionSet.templateLines.length; i++) {
                    if (questionSet.templateLines[i].Wizard_Question_Answered__c == true) {
                        questionSet.questionIndex++;
                    }
                    else {
                        break;
                    }
                }
                //ticket 19130 05.13.2023 >>
            }
            else {
                this.showToast(component, null, "You must answer Yes or No to this question.", "warning", "dismissible");
            }
            //ticket 19130 >>

            if (questionSet.questionIndex < questionSet.templateLines.length) {
                var templateLine = questionSet.templateLines[questionSet.questionIndex];

                //ticket 19130 <<
                component.set("v.xTemplateLine", JSON.parse(JSON.stringify(templateLine)));
                //ticket 19130 >>

                component.set("v.questionSet", questionSet);
                component.set("v.templateLine", templateLine);
            }
            //ticket 19130 05.13.2023 <<
            else {
                questionSet.completed = completed;
                component.set("v.questionSet", questionSet);
                component.set("v.templateLine", null);
            }
            //ticket 19130 05.13.2023 >>
        }
        else if (questionSet.questionIndex == questionSet.templateLines.length - 1) {
            questionSet.questionIndex = questionSet.templateLines.length;
            component.set("v.questionSet", questionSet);
            var completed = true;
            for (var i = 0; i < questionSet.templateLines.length; i++) {
                if (!questionSet.templateLines[i].answer) {
                    completed = false;
                    break;
                }
            };
            questionSet.completed = completed;
            component.set("v.questionSet", questionSet);
            component.set("v.templateLine", null);
        }

    },
    /*
    getTemplateLine : function(component, questionIndex) {
        var templateLines = component.get("v.questionSet.templateLines");
        return JSON.parse(JSON.stringify(templateLines[questionIndex]));
    },*/
    saveAnswer : function(component, event, answer) {
        var questionSet =component.get("v.questionSet");
        var templateLine = component.get("v.templateLine");
        templateLine.answer = answer;

        //ticket 19130 <<
        /*
        if (templateLine.answer == 'No') {
            templateLine.Quantity__c = null;
        }
        questionSet.templateLines[questionSet.questionIndex] = templateLine;
        component.set("v.questionSet.templateLines", questionSet.templateLines);
        */

        if (templateLine.answer == 'No') {
            let xTemplateLine = component.get("v.xTemplateLine");
            templateLine.Quantity__c = xTemplateLine.Quantity__c;
            templateLine.UOM_Qty__c = xTemplateLine.UOM_Qty__c;
        }
        //ticket 19130 >>
        questionSet.templateLines[questionSet.questionIndex] = templateLine;

        //ticket 19130 05.13.2023 <<
        var templateLines = component.get("v.questionSet.templateLines");
        for (var i = 0; i < templateLines.length; i++) {
            for (var j = 0; j < templateLines[i].Parent_Lines__r.records.length; j++) {
                var relation = templateLines[i].Parent_Lines__r.records[j];
                if (relation.Parent_Line__r.Line_No__c == templateLine.Line_No__c) {
                    relation.Parent_Line__r.Quantity__c = templateLine.Quantity__c;
                }
            }
        }
        //ticket 19130 05.13.2023 >>

        component.set("v.questionSet.templateLines", questionSet.templateLines);

    }
});