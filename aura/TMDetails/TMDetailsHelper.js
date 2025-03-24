({
    /*
    validateSalesOrder : function(component, event) {
        var tm = component.get("v.tm");
        var params = { "JSONTM": JSON.stringify(tm) };
        this.callServerMethod(component, event, "c.validateSalesOrder", params, function(response) {
            var tm = JSON.parse(response);
            component.set("v.tm", tm);
        })
    }*/
    linkToSalesOrder : function(component, event) {
        var tm = component.get("v.tm");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var params = {  "tm": tm, "jobTaskWrappers": jobTaskWrappers };
        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": {"callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Save', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "save", "callback": this.linkToSalesOrderCallback.bind(this, component, event) }});
        this.openModal(component, event, 'Link T&M to Sales Order', null, buttons, 'c:LinkTMToSalesOrderCard', params, 'small');
    },
    linkToSalesOrderCallback : function(component, event, tm, jobTaskWrappers) {
        this.closeModal(component, event);
        component.set("v.tm", tm);
        component.set("v.jobTaskWrappers", jobTaskWrappers);
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },
    //US115867
    getUnvoicedPick : function(component, event) {
        var params = { "sObjectName": 'TM__c' };
        this.callServerMethod(component, event, "c.getUnvoicedPicklist", params, function(response) {
            var result = response;
            var UnvoicedPicklistMap = [];
            for(var key in result){
                UnvoicedPicklistMap.push({key: key, value: result[key]});
            }
            component.set("v.UnvoicedPicklistMap", UnvoicedPicklistMap);
        })
    }   
});