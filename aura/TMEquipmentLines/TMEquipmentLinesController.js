({
    handleLaborLinesChange : function(component, event, helper) {
        //update equipment operators list in the equipment section
        var inlineEditComponentParams = component.get("v.inlineEditComponentParams");
        var laborLines = JSON.parse(JSON.stringify(component.get("v.laborLines")));
        var laborLinesCopy = [];
        for (var i = 0; i < laborLines.length; i++) {
            var laborLine = laborLines[i];
            if (laborLine.Resource__r) {
                laborLinesCopy.push(laborLine);
            }
        }
        inlineEditComponentParams.laborLines = laborLinesCopy;
        component.set("v.inlineEditComponentParams", inlineEditComponentParams);
    }
});