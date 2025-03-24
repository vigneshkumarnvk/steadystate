({
    doInit : function(component, event, helper) {
        component.set('v.laborColumns', [
            { label: 'Resource Type', fieldName: 'ResourceTypeName', type: 'text' },
            { label: 'Resource Name', fieldName: 'Resource_Name__c', type: 'text' },
            /* 06.17.2019 <<
            { label: 'Job Start', fieldName: 'Job_Start_Time__c', type: 'date', typeAttributes: { hour: '2-digit', minute: '2-digit', hour12: true }}, 
            { label: 'Site Start', fieldName: 'Site_Start_Time__c', type: 'date', typeAttributes: { hour: '2-digit', minute: '2-digit', hour12: true }},
            { label: 'Site End', fieldName: 'Site_End_Time__c', type: 'date', typeAttributes: { hour: '2-digit', minute: '2-digit', hour12: true }},
            { label: 'Job End', fieldName: 'Job_End_Time__c', type: 'date', typeAttributes: { hour: '2-digit', minute: '2-digit', hour12: true }},
            */
            { label: 'Hours', fieldName: 'Hours', type: 'number', typeAttributes: { minimumFractionDigits : '2' }, cellAttributes: { alignment: 'left' } },
        ]);

        component.set('v.equipmentColumns', [
            { label: 'Equipment Type', fieldName: 'ResourceTypeName', type: 'text' },
            { label: 'Equipment', fieldName: 'ResourceName', type: 'text' },
            { label: 'Equipment Description', fieldName: 'Description__c', type: 'text' },
            /* 06.17.2019 <<
            { label: 'Job Start', fieldName: 'Job_Start_Time__c', type: 'date', typeAttributes: { hour: '2-digit', minute: '2-digit', hour12: true } },
            { label: 'Job End', fieldName: 'Job_End_Time__c', type: 'date', typeAttributes: { hour: '2-digit', minute: '2-digit', hour12: true } },
            */
            { label: 'Quantity', fieldName: 'Quantity__c', type: 'number', typeAttributes: { minimumFractionDigits : '2' }, cellAttributes: { alignment: 'left' } },
        ]);

        component.set('v.materialColumns', [
            { label: 'Material', fieldName: 'ResourceName', type: 'text' },
            { label: 'Billing Description', fieldName: 'Description__c', type: 'text' },
            { label: 'Unit of Measure', fieldName: 'UnitOfMeasureName', type: 'text' },
            { label: 'Quantity', fieldName: 'Quantity__c', type: 'number', typeAttributes: { minimumFractionDigits : '2' }, cellAttributes: { alignment: 'left' } },
        ]);
        component.set('v.wasteDisposalColumns', [
            { label: 'Manifest #', fieldName: 'BOL_Manifest__c', type: 'text' },
            { label: 'Description', fieldName: 'Description__c', type: 'text' },
            { label: 'Unit of Measure', fieldName: 'UnitOfMeasureName', type: 'text' },
            { label: 'Quantity', fieldName: 'Quantity__c', type: 'number', typeAttributes: { minimumFractionDigits : '2' }, cellAttributes: { alignment: 'left' } },
            { label: 'Facility', fieldName: 'FacilityName', type: 'text' },
        ]);

        component.set('v.costPlusColumns', [
            { label: 'Description', fieldName: 'Description__c', type: 'text' },
            { label: 'Unit of Measure', fieldName: 'UnitOfMeasureName', type: 'text' },
            { label: 'Quantity', fieldName: 'Quantity__c', type: 'number', typeAttributes: { minimumFractionDigits : '2' }, cellAttributes: { alignment: 'left' } },
        ]);

        
        //signature request <<
        /*
        var tmId = component.get("v.tmId");
        var supervisorSignatureWrapper = { "RelatedToObjectName": "TM__c", "RelatedToId": tmId, "Name": 'supervisor_signature', "NotAvailable": false };
        var customerASignatureWrapper = { "RelatedToObjectName": "TM__c", "RelatedToId": tmId, "Name": 'customer_signature', "NotAvailable": false };
        var customerBSignatureWrapper = { "RelatedToObjectName": "TM__c", "RelatedToId": tmId, "Name": 'customer_signature_2', "NotAvailable": false };
        */
        var tm = component.get("v.tm");
        var supervisorSignatureWrapper = { "TMId": tm.Id, "Name": 'supervisor_signature', "NotAvailable": false, "SignerRole": 'Supervisor' };
        var customerASignatureWrapper = { "TMId": tm.Id, "Name": 'customer_signature', "NotAvailable": false, "Email": tm.Site_Email_Address__c, "SignerRole": 'Customer A' };
        var customerBSignatureWrapper = { "TMId": tm.Id, "Name": 'customer_signature_2', "NotAvailable": false, "SignerRole": 'Customer B' };
        //signature request >>
        component.set("v.supervisorSignatureWrapper", supervisorSignatureWrapper);
        component.set("v.customerASignatureWrapper", customerASignatureWrapper);
        component.set("v.customerBSignatureWrapper", customerBSignatureWrapper);

        helper.getData(component, event);
    },
    doSave :function(component, event, helper) {
        helper.saveData(component, event);
    },
    doRefresh : function(component, event, helper) {
        helper.confirmRefresh(component, event);
    },
    showTermsDialog : function(component, event, helper) {
        helper.showTermsDialog(component, event);
    },
    /*
    handleMobileTMSendPDFEvent : function(component, event, helper) {
        helper.processPdf(component, event);
    },*/
    doPendingChangesStatus : function(component, event, helper) {
        var pendingChangesStatus = component.get("v.pendingChangesStatus");

        if (pendingChangesStatus != null) {
            component.set("v.pendingChangesStatus", 'Pending_Changes_Dummy_Status'); //change status values to trigger event
            component.set("v.pendingChangesStatus", 'Pending_Changes');
        }
    },
    afterSignatureSaved : function(component, event, helper) {
        var dualSignaturesRequired = component.get("v.data.Bill_to_Customer__r.Requires_2_Signatures_on_TM__c");
        if (dualSignaturesRequired == true) {
            var customerASignatureWrapper = component.get("v.customerASignatureWrapper");
            var customerBSignatureWrapper = component.get("v.customerBSignatureWrapper");
            //signature request <<
            /*
            if (customerASignatureWrapper.Signed == true && customerBSignatureWrapper.Signed == true) {
                helper.processPDF(component, event);
            }
            */

            //Ticket#28274 Temporary Disable Customer Rating workflow
            /*
            var signerRole = event.getParam("signerRole");
            if (customerASignatureWrapper.Signed == true && signerRole == 'Customer A') {
                helper.showSurvey(component, event, customerASignatureWrapper.PrintName, customerASignatureWrapper.Email);
            }
             */

            if ((customerASignatureWrapper.Signed == true || customerASignatureWrapper.NotAvailable == true) && (customerBSignatureWrapper.Signed == true || customerBSignatureWrapper.NotAvailable == true)) {
                helper.processPDF(component, event);
            }
            //signature request >>
        }
        else {
            //signature request <<
            /*
            helper.processPDF(component, event);
            */
            var customerASignatureWrapper = component.get("v.customerASignatureWrapper");

            /* //Ticket#28274 Temporary Disable Customer Rating workflow
            if (customerASignatureWrapper.Signed == true && customerASignatureWrapper.NotAvailable != true) {
                helper.showSurvey(component, event, customerASignatureWrapper.PrintName, customerASignatureWrapper.Email);
            }
             */

            if (customerASignatureWrapper.Signed == true || customerASignatureWrapper.NotAvailable == true) {
                helper.processPDF(component, event);
            }
            //signature request >>
        }
    }
})