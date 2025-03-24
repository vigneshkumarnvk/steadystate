/*
    Ticket#20124
        - updating From Sales Quote updates Surcharge Type and Surcharge %
    Ticket#20079
        - add Payment Term to contract
 */

({  
    setNewContactRecordParams : function(component, event, helper) {
        var account = component.get("v.salesOrder.Bill_to_Customer_No__r");
        var record = {};
        if (account != null) {
            record.AccountId = account.Id;
            record.Account = account;
        }
        record.Contact_Type__c = 'Billing';
        var newContactRecordParams = { "record": record };
        component.set("v.newContactRecordParams", newContactRecordParams);
		
		var d365Radio = component.find("d365Radio");
        var salesOrder = component.get("v.salesOrder");
        if(salesOrder.Is_New_D365_Project__c == true){
            d365Radio.set("v.value","new");
        }else if(salesOrder.Is_New_D365_Project__c == false && salesOrder.D365_Project_ID__c != undefined){
            d365Radio.set("v.value","existing");
            component.set("v.isExistingD365",true);
        }
        
    },
    //Ticket#18812
    handleBillToCustomerChange : function(component, event, helper) {
        var record = event.getParam("record");
        var salesOrder = component.get("v.salesOrder");
        salesOrder.Alternate_Site_Address__c = null;
        salesOrder.Alternate_Site_Address__r = null;
        salesOrder.Bill_to_Contact__c = null;
        salesOrder.Bill_to_Contact__r = null;
        salesOrder.Contract__c = null;
        salesOrder.Contract__r = null;
        salesOrder.From_Sales_Quote__c = null;
        salesOrder.From_Sales_Quote__r = null;
        if (record) {
            salesOrder.Bill_to_Customer_No__c = record.Id;
            helper.validateBillToCustomer(component, event);
        }
    },
    handleBillToContactChange : function(component, event, helper) {
        var selectedContactId = '';
        var record = event.getParam("records");
        if(record){
            if(record.length > 0){
                for (var i = 0; i < record.length; i++) {
                    console.log('selectedContactId >>'+selectedContactId);
                    selectedContactId = selectedContactId == '' ? record[i].Id : selectedContactId + ',' + record[i].Id ;
                }
                
            }
        }
        if (selectedContactId != '') {
            component.set("v.salesOrder.Bill_To_Contacts__c", selectedContactId);
            component.set("v.salesOrder.Bill_to_Contact__c", record[0].Id);
        }
        else {
            component.set("v.salesOrder.Bill_To_Contacts__c", null);
            component.set("v.salesOrder.Bill_to_Contact__c", null);
            component.set("v.billToContacts", null);
        } 
        
    },
    //Ticket#18812
    /*
        Ticket#20079
            - add Payment Term to contract
    */
    handleContractChange : function(component, event, helper) {
        var record = event.getParam("record");
        var salesOrder = component.get("v.salesOrder");
        if (record) {
            salesOrder.Contract__c = record.Id;
            salesOrder.Contract_Name__c = record.Name;
            if(salesOrder.Payment_Term__c != null) {
                salesOrder.Payment_Term__c = record.Payment_Term__c;
                salesOrder.Payment_Term__r = record.Payment_Term__r;
            }
        }
        else {
            salesOrder.Contract__c = null;
            salesOrder.Contract__r = null;
            salesOrder.Contract_Name__c = null;
            salesOrder.Payment_Term__c = null;
            salesOrder.Payment_Term__r = null;
        }
        
        //surcharge <<
        helper.validateContract(component, event);
        //surcharge >>
    },
    handleFromSalesQuoteChange : function(component, event, helper) {
        var record = event.getParam("record");
        var salesOrder = component.get("v.salesOrder");
        if (record) {
            salesOrder.From_Sales_Quote__c = record.Id;
            if(record.Surcharge_Pct__c != null && record.Surcharge_Pct__c > 0){
                salesOrder.Surcharge_Type__c = record.Surcharge_Type__c;
                salesOrder.Surcharge_Pct__c = record.Surcharge_Pct__c;
            }
            //Ticket#24560 >>
            if(record.Operating_Expense_Cost_Pct__c != null) {
                salesOrder.Operating_Expense_Cost_Pct__c = record.Operating_Expense_Cost_Pct__c;
            }
            //Ticket#24560 <<
        }
        else {
            salesOrder.From_Sales_Quote__c = null;
            salesOrder.From_Sales_Quote__r = null;
        }
        component.set("v.salesOrder", salesOrder);
        helper.validateFromSalesQuote(component, event);
    },
    validateFields : function(component, event, helper) {
        var fields = new Array();
        fields.push(component.find("bill-to-customer"));
        fields.push(component.find("bill-to-contact"));
        fields.push(component.find("customer-po-number"));
        //var salesOrder = component.get("v.salesOrder");
        //if(salesOrder.Is_New_D365_Project__c  == false)
        fields.push(component.find("d365-project-id"));
        fields.push(component.find("d365Radio"));
        var allValid = fields.reduce(function(valid, inputField) {
            if (inputField) {
                if (Array.isArray(inputField)) {
                    for (var i = 0; i < inputField.length; i++) {
                        inputField[i].showHelpMessageIfInvalid();
                        valid = valid && inputField[i].get("v.validity").valid;
                    }
                }
                else {
                    inputField.showHelpMessageIfInvalid();
                    valid = valid && inputField.get("v.validity").valid;
                }
            }
            //return valid && inputField.get("v.validity").valid;
            return valid;
        }, true);
        
        return allValid;
    },
    handleCustomerPOChange : function (component, event, helper){
        helper.validateCustomerPONumber(component, event);
    },
    handleDisposalBillingChange : function(component, event, helper) {
        var record = event.getParam("record");
        var salesOrder = component.get("v.salesOrder");  
        if (record) {
            salesOrder.Disposal_Billing_Method__c = record.Disposal_Billing_Method__c;
        }
        component.set("v.salesOrder", salesOrder);
    },
    navigateTobillingProjectLookup : function (component, event, helper) {
        console.log('insidle controller on click');
        helper.navigateTobillingProjectLookup(component, event);
    },
    handleBillingProjectLookupMessage: function(component, event, helper) {
        var message = event.getParam("dataToSend");
        var salesOrder = component.get("v.salesOrder");
        
        salesOrder.EQAI_Billing_Project_Id__c = message.projectId;
        salesOrder.EQAI_Billing_Project_Name__c = message.projectname;   
        
        var billingProjectName = `${salesOrder.EQAI_Billing_Project_Id__c || ''} - ${salesOrder.EQAI_Billing_Project_Name__c || ''}`;
        component.set("v.billingProjectName", billingProjectName);
        component.set("v.salesOrder", salesOrder);
        
        component.set("v.isBillingProjectVisible", true);
        
        component.get("v.modelCreatePromise").then(function (model) {
            model.close();
        });
    },
    
    clearBillingProject: function(component, event, helper) {
        var salesOrder = component.get("v.salesOrder");
        
        salesOrder.EQAI_Billing_Project_Id__c = null;
        salesOrder.EQAI_Billing_Project_Name__c = null;
        
        component.set("v.salesOrder", salesOrder);
        component.set("v.billingProjectName", null);
        
        component.set("v.isBillingProjectVisible", true);
    },
    handleD365projectChange : function(component, event, helper){
        var changeValue = event.getParam("value");
        var salesOrder = component.get("v.salesOrder");
        if(changeValue == "existing"){
           component.set("v.isExistingD365",true);
            salesOrder.Is_New_D365_Project__c  = false;
            
        }else{
            component.set("v.isExistingD365",false);
            salesOrder.Is_New_D365_Project__c  = true;
            salesOrder.D365_Project_ID__c = null;
        }
        component.set("v.salesOrder", salesOrder);
    },
    handleD365IdChange : function(component, event, helper) {
    var record = event.getParam("record");
    var salesOrder = component.get("v.salesOrder");    
    if (record) {
    salesOrder.D365_Project_ID__c  = record.d365Project;
     } else {
    salesOrder.D365_Project_ID__c = null;
     }
     component.set("v.salesOrder", salesOrder); 
     }
})