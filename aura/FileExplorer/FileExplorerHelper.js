({
    getFiles : function(component, event) {
        var recordId = component.get("v.recordId");
        var childRelationshipName = component.get("v.childRelationshipName");
        var params = { "recordId": recordId, "childRelationshipName": childRelationshipName };
        this.callServerMethod(component, event, "c.getFiles", params, function(response) {
            try {
                var files = JSON.parse(response);
                component.set("v.files", files);
            }
            catch (e) {

            }
        });
    }
});