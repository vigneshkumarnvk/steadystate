({
    showFields : function(component) {
        var fields = {};
        fields.select = { "visible": false, "disabled": true };
        fields.delete = { "visible": false, "disabled": true };

        var worksheetLine = component.get("v.worksheetLine");
        console.log('worksheetline',JSON.stringify(worksheetLine));
        // console.log('worksheetline',worksheetLine.original_customer_price__c);

        fields.select.visible = true;
        fields.select.disabled = false;
        switch(worksheetLine.Category__c) {
            case 'Labor':
                if (!worksheetLine.Service_Center__r || worksheetLine.Service_Center__r.Temporary__c == true) {
                    fields.delete.visible = true;
                    fields.delete.disabled = false;
                }
                break;
            case 'Equipment':
                if (!worksheetLine.Service_Center__r || worksheetLine.Service_Center__r.Temporary__c == true) {
                    fields.delete.visible = true;
                    fields.delete.disabled = false;
                }
                break;
            case 'Materials':
                fields.delete.visible = true;
                fields.delete.disabled = false;
                break;
            case 'Subcontractors':
                fields.delete.visible = true;
                fields.delete.disabled = false;
                break;
            case 'Waste Disposal':
                fields.delete.visible = true;
                fields.delete.disabled = false;
                break;
            case 'Demurrage':
                fields.delete.visible = true;
                fields.delete.disabled = false;
                break;
            case 'Misc. Charges And Taxes':
                fields.delete.visible = true;
                fields.delete.disabled = false;
                break;
            default:
                fields.delete.visible = true;
                fields.delete.disabled = false;
                break;
        }

        //if (worksheetLine.Parent_Line__r != null || worksheetLine.System_Calculated_Line__c == true || worksheetLine.Bundle_Line__r != null) {
        if (worksheetLine.System_Calculated_Line__c == true || worksheetLine.Bundle_Line__r != null) {
            fields.delete.disabled = true;
        }

        component.set("v.fields", fields);
    },
    setBillingMethod : function(component) {
        console.log('inside helper billing method*****************');
        var worksheetLine = component.get("v.worksheetLine");
        console.log('worksheetline***********',worksheetLine.Category__c);
        console.log('worksheetline',worksheetLine.Disposal_Billing_Method__c);
        console.log('worksheetline',worksheetLine.Sales_Order__r.Disposal_Billing_Method__c);
        if(worksheetLine.Category__c == 'Waste Disposal'){
            if(worksheetLine.Sales_Order__r.Disposal_Billing_Method__c != null && (worksheetLine.Disposal_Billing_Method__c == '' || worksheetLine.Disposal_Billing_Method__c == null)){
                worksheetLine.Disposal_Billing_Method__c = worksheetLine.Sales_Order__r.Disposal_Billing_Method__c;
            }
        }

    }
});