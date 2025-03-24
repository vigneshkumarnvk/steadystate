({
    doInit : function(component, event, helper) {
        helper.getFiles(component, event);
    },
    handleRowAction : function(component, event, helper) {
        var files = component.get("v.files");
        var name = event.getParam("name");
        var rowIndex = event.getParam("rowIndex");
        var action = event.getParam("action");
        switch (name) {
            case 'preview':
                if (action == 'click') {
                    var documentSource = files[rowIndex].DocumentSource;
                    var fileId = files[rowIndex].DocumentId;
                    if (documentSource == 'ContentDocument') {
                        var openPreview = $A.get('e.lightning:openFiles');
                        openPreview.fire({recordIds: [fileId]});
                    }
                    else {
                        window.open('/servlet/servlet.FileDownload?file=' + fileId, '_blank');
                    }
                }
                break;
        }
    }
});