({
    doInit : function(component, event, helper) {
        var selectedRecord = component.get("v.selectedRecord");
        if (selectedRecord) {
            var forclose = component.find("lookup-pill");
            $A.util.addClass(forclose, 'slds-show');
            $A.util.removeClass(forclose, 'slds-hide');
            
            var lookUpTarget = component.find("lookupField");
            $A.util.addClass(lookUpTarget, 'slds-hide');
            $A.util.removeClass(lookUpTarget, 'slds-show');
            
            helper.assignPillLabel(component, event);
        }
    },
    onselect : function(component,event,helper) {
        if (component.get("v.selectedRecord")) {
            if (JSON.stringify(component.get("v.selectedRecord")) !== JSON.stringify({})) {
                var forclose = component.find("lookup-pill");
                $A.util.addClass(forclose, 'slds-show');
                $A.util.removeClass(forclose, 'slds-hide');
                
                var lookUpTarget = component.find("lookupField");
                $A.util.addClass(lookUpTarget, 'slds-hide');
                $A.util.removeClass(lookUpTarget, 'slds-show');
                
                helper.assignPillLabel(component, event);
            }
        }
    },
    onfocus : function(component,event,helper) {
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        var forOpen = component.find("searchRes");
        $A.util.addClass(forOpen, 'slds-is-open');
        $A.util.removeClass(forOpen, 'slds-is-close');
        
		var selectOptionBox = component.find("selectOptionBox");
        var top = forOpen.getElement().getBoundingClientRect().top;
        var vh = Math.max(document.documentElement.clientHeight, window.innerHeight || 0);
        if (top > (vh / 2)) {
            $A.util.addClass(selectOptionBox, "slds-dropdown_bottom");
            $A.util.removeClass(selectOptionBox, "slds-dropdown");
        }
        else {
        	$A.util.addClass(selectOptionBox, "slds-dropdown");
            $A.util.removeClass(selectOptionBox, "slds-dropdown_bottom");
        }
        
        // Get Default 5 Records order by createdDate DESC  
        var getInputkeyWord = '';
        helper.searchHelper(component,event,getInputkeyWord);        
    },
    onblur : function(component,event,helper) {       
        component.set("v.listOfSearchRecords", null);
        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
    },
    keyPressController : function(component, event, helper) {
        // get the search Input keyword   
        var getInputkeyWord = component.get("v.SearchKeyWord");
        // check if getInputKeyWord size id more then 0 then open the lookup result List and 
        // call the helper 
        // else close the lookup result List part.   
        if( getInputkeyWord.length > 0 ){
            var forOpen = component.find("searchRes");
            $A.util.addClass(forOpen, 'slds-is-open');
            $A.util.removeClass(forOpen, 'slds-is-close');
            helper.searchHelper(component,event,getInputkeyWord);
        }
        else{  
            component.set("v.listOfSearchRecords", null ); 
            var forclose = component.find("searchRes");
            $A.util.addClass(forclose, 'slds-is-close');
            $A.util.removeClass(forclose, 'slds-is-open');
        }
    },
    clear :function(component,event,heplper) {
        var pillTarget = component.find("lookup-pill");
        var lookUpTarget = component.find("lookupField"); 
        
        $A.util.addClass(pillTarget, 'slds-hide');
        $A.util.removeClass(pillTarget, 'slds-show');
        
        $A.util.addClass(lookUpTarget, 'slds-show');
        $A.util.removeClass(lookUpTarget, 'slds-hide');
        
        component.set("v.SearchKeyWord",null);
        component.set("v.listOfSearchRecords", null );
        component.set("v.selectedRecord", {} );
        
        var customLookupSelectEvent = component.getEvent("customLookupSelectEvent");
        customLookupSelectEvent.setParams({ "selectedRecord": null });
        customLookupSelectEvent.fire();
    },    
    handleComponentEvent : function(component, event, helper) {
        // get the selected Account record from the COMPONETN event 	 
        var selectedRecord = event.getParam("recordByEvent");
        component.set("v.selectedRecord", selectedRecord); 
        
        var forclose = component.find("lookup-pill");
        $A.util.addClass(forclose, 'slds-show');
        $A.util.removeClass(forclose, 'slds-hide');
        
        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
        
        var lookUpTarget = component.find("lookupField");
        $A.util.addClass(lookUpTarget, 'slds-hide');
        $A.util.removeClass(lookUpTarget, 'slds-show');  
        
        var customLookupSelectEvent = component.getEvent("customLookupSelectEvent");
        customLookupSelectEvent.setParams({ "selectedRecord": selectedRecord });
        customLookupSelectEvent.fire();
    }
})