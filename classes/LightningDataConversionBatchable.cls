public with sharing class LightningDataConversionBatchable implements Database.Batchable<SObject>, Database.Stateful {

    public String SObjectName { set; get; }
    public Integer FetchLimit { set; get; }
    public List<SObject> start(Database.BatchableContext bc) {
        List<SObject> records;
        if (SObjectName == 'TMStatus') {
            records = [SELECT Status__c FROM TM__c WHERE Status__c = 'Received By Billing' OR Status__c = 'Ready to Bill' OR Status__c = 'Partially Invoiced' ORDER BY CreatedDate DESC LIMIT :FetchLimit];
        }
        else if (SObjectName == 'SalesOrderJobTasks') {
            records = [SELECT Id, Document_Type__c, CMR_Description__c,
            (SELECT Id, Category__c, Resource__c, System_Calculated_Line__c, Sales_Order__c, Line_Amount__c, Unit_Price__c, Unit_Cost__c, Number_of_Day__c FROM Sales_Lines__r) FROM Sales_Order__c WHERE Number_of_Tasks__c = 0 ORDER BY CreatedDate DESC LIMIT :FetchLimit];
        }
        else if (SObjectName == 'TMJobTasks') {
            records = [SELECT Id, Sales_Order__c, Sales_Order__r.CMR_Description__c, (SELECT Id, TM__c FROM TM_Lines__r) FROM TM__c WHERE Number_of_Tasks__c = 0 ORDER BY CreatedDate DESC LIMIT :FetchLimit];
        }
        else if (SObjectName == 'SalesInvoiceJobTasks') {
            //records = [SELECT Id, Sales_Order__c, (SELECT Id, Sales_Invoice__c FROM Sales_Invoice_Lines__r) FROM Sales_Invoice__c WHERE Number_of_Tasks__c = 0 ORDER BY CreatedDate DESC LIMIT :FetchLimit];

        }
        else if (SObjectName == 'BillingWorksheetLines') {
            String queryString = '';
            List<String> fieldNames;
            fieldNames = new List<String>(Schema.SObjectType.TM__c.getSObjectType().getDescribe().fields.getMap().keySet());
            queryString = 'SELECT ' + String.join(fieldNames, ' ,');
            fieldNames = new List<String>(Schema.SObjectType.TM_Line__c.getSObjectType().getDescribe().fields.getMap().keySet());
            queryString += ',(SELECT ' + String.join(fieldNames, ',') + ' FROM TM_Lines__r WHERE Invoiced__c != TRUE)';
            queryString += ' FROM TM__c WHERE (Status__c = \'Confirmed\' OR Status__c = \'Received By Billing\' OR Status__c = \'Ready to Bill\' OR Status__c = \'Partially Invoiced\') ';
            queryString += ' AND Billing_Worksheet_Line_Created__c != TRUE ORDER BY CreatedDate DESC LIMIT ' + FetchLimit;
            records = (List<TM__c>)Database.query(queryString);
        }
        else if (SObjectName == 'EquipmentDetailLines') {
            records = [SELECT Id, Sales_Order__c, Category__c, Resource_Type__c, Resource__c,
                    Number_of_Day__c, Quantity__c, UOM_Qty__c, Unit_of_Measure__c, Bill_as_Lump_Sum__c, Non_Billable__c,
                    Unit_Price__c, Unit_Cost__c, xUnit_Price__c, xUnit_Cost__c,
                    System_Calculated_Line__c FROM Sales_Line__c WHERE Category__c = 'Equipment' AND Record_Updated__c != TRUE ORDER BY CreatedDate DESC LIMIT :FetchLimit];
        }
        else if (SObjectName == 'TMInvoiceRelations') {
            records = [SELECT Id, (SELECT Id, TM__c, Sales_Invoice__c FROM Sales_Invoice_Lines__r) FROM Sales_Invoice__c WHERE TM_Invoice_Relation_Created__c != TRUE ORDER BY CreatedDate DESC LIMIT :FetchLimit];
        }
        return records;
    }

    public void execute(Database.BatchableContext bc, List<SObject> records) {
        if (SObjectName == 'TMStatus') {
            LightningDataConversion.updateTMStatus((List<TM__c>)records);
        }
        else if (SObjectName == 'SalesOrderJobTasks') {
            LightningDataConversion.createSalesOrderJobTasks((List<Sales_Order__c>)records);
        }
        else if (SObjectName == 'TMJobTasks') {
            LightningDataConversion.createTMJobTasks((List<TM__c>)records);
        }
        else if (SObjectName == 'SalesInvoiceJobTasks') {
            LightningDataConversion.createSalesInvoiceJobTasks((List<Sales_Invoice__c>)records);
        }
        else if (SObjectName == 'BillingWorksheetLines') {
            LightningDataConversion.createBillingWorksheetLines((List<TM__c>)records);
        }
        else if (SObjectName == 'EquipmentDetailLines') {
            LightningDataConversion.insertEquipmentDetailLines((List<Sales_Line__c>)records);
        }
        else if (SObjectName == 'TMInvoiceRelations') {
            LightningDataConversion.createTMInvoiceRelations((List<Sales_Invoice__c>)records);
        }
    }

    public void finish(Database.BatchableContext bc) {

    }
}