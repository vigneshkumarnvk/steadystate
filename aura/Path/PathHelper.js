({
    setStages : function(component, value) {
        var stages = component.get("v.stages");
        var singleStage = component.get("v.singleStage");
        var xValue = component.get("v.xValue");
        if (singleStage == true) {
            stages.forEach(function (stage) {
                var state = 'incomplete';
                if (stage.value == value) {
                    state = 'current';
                }
                stage.state = state;
            });
            component.set("v.stages", stages);
        }
        else {
            var state = 'incomplete';
            if (stages.length > 0) {
                for (var i = stages.length - 1; i >= 0; i--) {
                    if (stages[i].value == value) {
                        state = 'current';
                    } else {
                        if (state == 'current') {
                            state = 'complete';
                        }
                    }
                    stages[i].state = state;
                }

                for (var i = stages.length - 1; i >= 0; i--) {
                    if (stages[i].disabled == true) {
                        stages[i].state = 'incomplete'; //display gray
                    }
                }
                component.set("v.stages", stages);
            }
        }
    },
    showToast : function(component, title, message, type, mode) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "mode": mode
        });
        toastEvent.fire();
    }
});