({
	doInit : function(component, event, helper) {
		component.set("v.spinner", true); 
        helper.getServiceCenters(component);
        helper.getDefaultStartDate(component);
        helper.getDefaultEndDate(component);
        
        var selected = component.find("serviceCenterFilter").get("v.value");        
        var startDate = component.find("startDateFilter").get("v.value");  
        var endDate = component.find("endDateFilter").get("v.value");   
        
        console.log('selected ' + selected);
        console.log('startDate ' + startDate);
        console.log('endDate ' + endDate);
        
		helper.getFilters(component); 
	},

    sendToUrl : function(component,event, helper){
        // Get filter values
        var selected = component.find("serviceCenterFilter").get("v.value");        
        var startDate = component.find("startDateFilter").get("v.value");  
        var endDate = component.find("endDateFilter").get("v.value");
        
        // Redirect to PDF URL
        var url = "/apex/EquipmentUtilizationReport?ServiceCenter=" + selected + "&startDate=" + startDate + "&endDate=" + endDate;
        window.location.href = url;
    },

    sendToUrlExcel : function(component,event, helper){
        // Get filter values
        var selected = component.find("serviceCenterFilter").get("v.value");
        var startDate = component.find("startDateFilter").get("v.value");
        var endDate = component.find("endDateFilter").get("v.value");

        // Redirect to PDF URL
        var url = "/apex/EquipmentUtilizationExcel?ServiceCenter=" + selected + "&startDate=" + startDate + "&endDate=" + endDate;
        window.location.href = url;
    },
    
    onFiltersChange : function(component, event, helper) {		
		helper.getFilters(component);        
    },
    renderPage: function(component, event, helper) {
        helper.renderPage(component);
    }
})