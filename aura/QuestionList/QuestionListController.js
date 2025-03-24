({
    doInit : function(component, event, helper) {
        helper.goToQuestion(component, event);
        //ticket 19130 <<
        let templateLine = component.get("v.templateLine");
        component.set("v.xTemplateLine", JSON.parse(JSON.stringify(templateLine)));
        //ticket 19130 >>
    },
    handleButtonClick : function(component, event, helper) {
        var value = event.getSource().get("v.value");
        switch (value) {
            case 'previous':
                helper.moveToPreviousQuestion(component, event);
                break;
            case 'next':
                //ticket 19130 <<
                /*
                var templateLine = component.get("v.templateLine");
                if (templateLine != null && templateLine.answer == null) {
                    var question = component.find("question-card");
                    if (question.validateFields(component)) {
                        helper.saveAnswer(component, event, 'Yes');
                        helper.moveToNextQuestion(component, event);
                    }
                } else {
                    helper.moveToNextQuestion(component, event);
                }
                */
                helper.moveToNextQuestion(component, event);
                //ticket 19130 >>
                break;
        }
    },
    handleRowAction : function(component, event, helper) {
        var name = event.getParam("name");
        var rowIndex = event.getParam("rowIndex");
        var action = event.getParam("action");
        var questionSet = component.get("v.questionSet");
        if (questionSet.templateLines && questionSet.templateLines.length > rowIndex) {
            switch (name) {
                case 'edit-answer':
                    if (action == 'click') {
                        questionSet.questionIndex = rowIndex;
                        var templateLine = questionSet.templateLines[questionSet.questionIndex];
                        component.set("v.questionSet", questionSet);
                        component.set("v.templateLine", templateLine);
                    }
                    break;
            }
        }
    },
    doNo : function(component, event, helper) {
        //ticket 19130 <<
        var question = component.find("question-card");
        if (!question.validateFields('No')) return;
        //ticket 19130 <<
        helper.saveAnswer(component, event, 'No');
        helper.moveToNextQuestion(component, event);
    },
    doYes : function(component, event, helper) {
        //ticket 19130 <<
        /*
        var question = component.find("question-card");
        if (question.validateFields(component)) {
            helper.saveAnswer(component, event, 'Yes');
            helper.moveToNextQuestion(component, event);
        }
        */
        var question = component.find("question-card");
        if (question.validateFields('Yes')) {
            helper.saveAnswer(component, event, 'Yes');
            helper.moveToNextQuestion(component, event);
        }
        //ticket 19130 >>
    }
});