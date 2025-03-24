({
    doInit : function(component, event, helper) {
        helper.moveToQuestionSet(component, 0); //first question set
    },
    doYes : function(component, event, helper) {
        var questionsList = component.find("question-list");
        questionsList.doYes();
    },
    doNo : function(component, event, helper) {
        var questionsList = component.find("question-list");
        questionsList.doNo();
    },
    doCompleteQuestionSet : function(component, event, helper) {
        //helper.saveAnswer(component);
        var questionSetIndex = component.get("v.questionSetIndex");
        questionSetIndex++;
        helper.moveToQuestionSet(component, questionSetIndex);
    },
    doCompleteWizard : function(component, event, helper) {
        //helper.saveAnswer(component);
        var completeCallback = component.get("v.completeCallback");
        if (completeCallback) {
            var questionSets = component.get("v.questionSets");
            //var resolve = component.get("v.resolve");
            //completeCallback(questionSets, resolve);
            completeCallback(questionSets);
        }
    },
    doCancel : function(component, event, helper) {
        var cancelCallback = component.get("v.cancelCallback");
        if (cancelCallback) {
            cancelCallback();
        }
    }
});