({
	searchHelper : function(component,event,getInputkeyWord) {
        // call the apex class method 
        var action = component.get("c.fetchLookUpValues");
        // set param to method  
        action.setParams({
            'keywords': getInputkeyWord,
            'objectName' : component.get("v.objectAPIName"),
            'displayFields' : component.get("v.fieldNames"),
            'additionalFields' : component.get("v.additionalFields"),
            'searchFields' : component.get("v.fieldNames"),
            'filterExpr' : component.get("v.filters")
        });
        // set a callBack    
        action.setCallback(this, function(response) {
            $A.util.removeClass(component.find("mySpinner"), "slds-show");
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
                // if storeResponse size is equal 0 ,display No Result Found... message on screen.                }
                if (storeResponse.length == 0) {
                    component.set("v.Message", 'No Result Found...');
                } else {
                    component.set("v.Message", '');
                }
                // set searchResult list with return value from server.
                component.set("v.listOfSearchRecords", storeResponse);
            }
            
        });
        // enqueue the Action  
        $A.enqueueAction(action);
	},
    assignPillLabel : function(component, event) {
        var selectedRecord = component.get("v.selectedRecord");
        if (selectedRecord) {
            var field = component.get("v.field");
            component.set("v.selectedValue", selectedRecord[field]);
        }
    }
})