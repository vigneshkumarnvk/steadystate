({
    doInit : function(component, event, helper) {
        helper.goToTemplateLine(component, event);
    },
    handleButtonClick : function(component, event, helper) {
        var value = event.getSource().get("v.value");
        switch (value) {
            case 'previous':
                helper.moveToPreviousTemplateLine(component, event);
                break;
            case 'next':
                var templateLine = component.get("v.templateLine");
                if (templateLine != null && templateLine.answer == null) {
                    var question = component.find("question-card");
                    if (question.validateFields(component)) {
                        helper.saveAnswerLine(component, event, 'Yes');
                        helper.moveToNextTemplateLine(component, event);
                    }
                } else {
                    helper.moveToNextTemplateLine(component, event);
                }
                break;
        }
    }, 
    doNo : function(component, event, helper) {
        helper.saveAnswerLine(component, event, 'No');
        helper.moveToNextTemplateLine(component, event);
    },
    doYes : function(component, event, helper) {
        var question = component.find("question-card");
        if (question.validateFields(component)) {
            helper.saveAnswerLine(component, event, 'Yes');
            helper.moveToNextTemplateLine(component, event);
        }
    }
});