({
	setNewSiteAddressRecordParams : function(component, event) {
		var account = component.get("v.salesOrder.Bill_to_Customer_No__r");
        var record = {};
        if (account != null) {
        	record.Customer__c  = account.Id;
            record.Customer__r = account;
        }
        var newSiteAddressRecordParams = { "record": record };
        component.set("v.newSiteAddressRecordParams", newSiteAddressRecordParams);
	},
    setNewSiteContactRecordParams : function(component, event) {
        var account = component.get("v.salesOrder.Bill_to_Customer_No__r");
        var record = {};
        if (account != null) {
        	record.AccountId = account.Id;
            record.Account = account;
        }
        record.Contact_Type__c = 'Site';
        var newSiteContactRecordParams = { "record": record };
        component.set("v.newSiteContactRecordParams", newSiteContactRecordParams);
},
    showCreateGeneratorLookup : function (component, event) {
        let overlayLibrary = component.find("overlayLibCreateSalesOrder");
        let generatorLookup = "c:generatorLookup";
        let salesOrder = component.get("v.salesOrder");
        $A.createComponent( generatorLookup, {
                    "epaId": salesOrder.EPA_ID__c,
                    "siteName":  salesOrder.Site_Name__c,
                    "siteStreet": salesOrder.Site_Street__c,
                    "siteCity": salesOrder.Site_City__c,
                    "siteState": salesOrder.Site_State__c,
                    "sitePostalCode": salesOrder.Site_Postal_Code__c,
                    "mode": "create"
            },
            function(content, status, errorMessage) {
                if (status === 'SUCCESS') {
                   let modelPromise = overlayLibrary.showCustomModal({
                        header: "Generator Lookup",
                        body: content,
                        showCloseButton: true,
                        cssClass: "custom-createoverlay-class",
                        closeCallback: function() {
                            closeQA();
                        }
                    });
                    component.set("v.modelCreatePromise", modelPromise);
                } else {
                    console.log("Error Loading the Component :" + errorMessage);
                }
            }
        )
    },
    
    clearGeneratorAndEpaFields: function(component) {
        var salesOrder = component.get("v.salesOrder");
        var releaseFlag = $A.get("$Label.c.Release_Flag");
        console.log('releaseFlag',releaseFlag);
        console.log('SO_sent_to_EQAI__c',salesOrder.SO_sent_to_EQAI__c);
    if (releaseFlag === 'true' && salesOrder.SO_sent_to_EQAI__c === false) {
        salesOrder.EqaiGeneratorId__c = null;
        salesOrder.EPA_ID__c = null;
    }

        component.set("v.salesOrder", salesOrder);
    },
    handleCreateSalesOrderMessage : function(component, event) {
        let message = event.getParam("dataToSend");
        let salesOrder = component.get("v.salesOrder");
        if (message === 'close'){
            component.get("v.modelCreatePromise").then(
                function (model) {
                    model.close();
                }
            );
        } else {
            //Bug#77410
            salesOrder.Alternate_Site_Address__r = null;
            salesOrder.Alternate_Site_Address__c = null;
            salesOrder.Site_Name__c = message.name;
            salesOrder.Site_Street__c = message.streetAddress;
            salesOrder.Site_City__c = message.city;
            //DE37105
            console.log('message.eqaiGeneratorCountry',message.eqaiGeneratorCountry)
            salesOrder.Site_Country__c = message.eqaiGeneratorCountry;
            salesOrder.Site_State__c = message.state;
            salesOrder.Site_Postal_Code__c = message.zip;
            salesOrder.Site_Phone_No__c = message.businessPhone;
            salesOrder.EqaiGeneratorId__c = message.eqaiGeneratorId;
            salesOrder.EPA_ID__c = message.epaId;
            component.set("v.salesOrder", salesOrder);
            //component.set("v.generatorStreet",message.streetAddress);
            component.get("v.modelCreatePromise").then(
                function (model) {
                    model.close();
                }
            );
        }
    },
    updateTaxGroup: function(component, event, salesOrder, jobTaskWrappers) {
        var taxLiable = salesOrder.Tax_Liable__c;
        var taxGroupValue = taxLiable ? 'TX' : 'NT';  

        console.log("Setting Tax Group to '" + taxGroupValue + "' for SalesLine...");

        for (var i = 0; i < jobTaskWrappers.length; i++) {
            for (var j = 0; j < jobTaskWrappers[i].SalesLines.length; j++) {

                jobTaskWrappers[i].SalesLines[j].Tax_Group__c = taxGroupValue;
            }
        }
            component.set("v.jobTaskWrappers", jobTaskWrappers);
    },
    handleMessage : function(component, event) {
        let message = event.getParam("fieldsVisible");
        console.log('Received Message: '+message);

        if (message) {
            component.set("v.fieldsDisabled", false);
        }
    }   
})