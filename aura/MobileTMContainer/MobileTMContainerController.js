({
    doInit : function(component, event, helper) {
        helper.getTM(component, event);
    },
    handleUnsavedChangesEvent : function(component, event, helper) {
        var unsaved = event.getParam("unsaved");
        component.set("v.unsavedChanges", unsaved);
    },
    handleMenuButtonClick : function(component, event, helper) {
        var value = event.getSource().get("v.value");
        var unsavedChanges = component.get("v.unsavedChanges");

        /* move to signature tab'ssave button
        if (value != 'signature') {
            if (unsavedChanges == true) {
                helper.confirmUnsavedChanges(component, event, value);
            }
            else {
                helper.navigateToTab(component, event, value);
            }
        }
        else {
            var tm = component.get("v.tm");
            var jobTaskWrappers;

            var promise0;
            if (unsavedChanges == true) {
                promise0 = new Promise(
                    $A.getCallback(function(resolve, reject) {
                        helper.confirmUnsavedChanges(component, event, value, resolve, reject);
                    })
                );
            }
            else {
                promise0 = new Promise(
                    $A.getCallback(function(resolve, reject) {
                        resolve();
                    })
                );
            }

            promise0.then(
                $A.getCallback(function(result) {
                    return new Promise($A.getCallback(function(resolve, reject)
                    {
                        helper.getJobTaskWrappers(component, event, tm.Id, resolve, reject);
                    }));
                }),
                $A.getCallback(function() {
                    reject();
                })
            ).then(
                $A.getCallback(function(result) {
                    //prompt wizard
                    jobTaskWrappers = result;
                    var prompt = false;
                    for (var i = 0; i < jobTaskWrappers.length; i++) {
                        var jobTaskWrapper = jobTaskWrappers[i];
                        for (var j = 0; j < jobTaskWrapper.TMLines.length; j++) {
                            var tmLine = jobTaskWrapper.TMLines[j];
                            if (tmLine.Parent_Line__r && tmLine.Parent_Line__r.Line_No__c && (!tmLine.Quantity__c || tmLine.Quantity__c == 0)) {
                                prompt = true;
                                break;
                            }
                        }
                        if (prompt == true) {
                            break;
                        }
                    }
                    if (prompt == true) {
                        return new Promise($A.getCallback(function(resolve, reject) {
                            helper.promptWizard(component, event, jobTaskWrappers, resolve, reject);
                        }));
                    }
                }),
                $A.getCallback(function() {
                    reject();
                })
            ).then(
                $A.getCallback(function() {
                    return new Promise($A.getCallback(function(resolve, reject) {
                        helper.calculateTMJobTasks(component, event, tm, jobTaskWrappers, resolve, reject);
                    }));
                }),
                $A.getCallback(function() {
                    reject();
                })
            ).then(
                $A.getCallback(function() {
                    return new Promise($A.getCallback(function(resolve, reject) {
                        helper.saveTM(component, event, tm, jobTaskWrappers, resolve, reject);
                    }));
                }),
                $A.getCallback(function() {
                    reject();
                })
            ).then(
                $A.getCallback(function() {
                    helper.navigateToTab(component, event, value);
                }),
                $A.getCallback(function() {

                })
            ).catch(function(error) {
                $A.reportError("Error", error);
            });
        }
        */
        if (unsavedChanges == true) {
            helper.confirmUnsavedChanges(component, event, value);
        }
        else {
            helper.navigateToTab(component, event, value);
        }
    },
    doUploadFile : function(component, event, helper) {
        helper.uploadFile(component, event);
    }
});