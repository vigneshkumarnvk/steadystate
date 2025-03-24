({
    moveToQuestionSet : function(component, questionSetIndex) {
        var questionSets = component.get("v.questionSets");
        if (questionSetIndex < questionSets.length) {
            var questionSet = questionSets[questionSetIndex];
            questionSet.questionIndex = 0;
            questionSet.completed = false;
            component.set("v.questionSet", questionSets[questionSetIndex]);
            component.set("v.questionSetIndex", questionSetIndex);
            var templateLine = questionSet.templateLines[questionSet.questionIndex];
            var questionList = component.find("question-list");
            questionList.set("v.templateLine", templateLine);
        }
    },
    saveAnswer : function(component) {
        var questionSet = component.get("v.questionSet");
        var answers = component.get("v.answers");
        answers.push(questionSet);
        component.set("v.answers", answers);
    }
});