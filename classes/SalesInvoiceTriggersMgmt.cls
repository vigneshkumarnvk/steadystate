public with sharing class SalesInvoiceTriggersMgmt {
    public static Map<String,Numbering_Series__c> mapNumberSeries = new Map<String,Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;

    //Sales Invoice Header Insert Update
    public static void SIInsertUpdate(Sales_Invoice__c[] InvoiceList, Map<Id, Sales_Invoice__c> oldSIMap, Boolean isInsert) {
        Map<String, Sales_Invoice__c> nameSIMap = new Map<String, Sales_Invoice__c>();
        //Company_Setup__c theCompanySetup = CompanyMgmt.getCompanySetup();


        Set<Id> accountIds = new Set<Id>();
        Map<Id, Account> accountsByIds = new Map<Id, Account>();

        //Ticket#28846 >>
        Set<Id> salesOrderIds = new Set<Id>();
        Map<Id, Sales_Order__c> salesOrdersByIds = new Map<Id, Sales_Order__c>();
        //Ticket#28846 <<
        for (Sales_Invoice__c theSI: InvoiceList) {
            accountIds.add(theSI.Bill_to_Customer__c);
            salesOrderIds.add(theSI.Sales_Order__c);
        }

        if(accountIds.size() > 0){
            accountsByIds.putAll([SELECT Id, Name, Inter_co_Account__c, Tax_Area__r.Name, Customer_Billing_Instructions__c, Billing_Instructions__c FROM Account WHERE Id IN :accountIds]);
        }

        //Ticket#28846 >>
        if(salesOrderIds.size() > 0){
            salesOrdersByIds.putAll([SELECT Id, Sales_Order_Instructions__c FROM Sales_Order__c WHERE Id IN :salesOrderIds]);
        }
        //Ticket#28846 <<
        
        //change posting date <<
        Map<Id, Date> salesInvPostingDates = new Map<Id, Date>();
        //change posting date >>
        
        for (Sales_Invoice__c theSI : InvoiceList) {
            if (isInsert) {
                if (theSI.Credit_Memo__c == false){
                	if(String.isBlank(theSI.Name)){
	                	mapNumberSeries = CompanyMgmt.getNumber('Sales Invoice');
	                	theNumberingSeries = mapNumberSeries.get('Sales Invoice');
	                	theSI.Name = theNumberingSeries.Prefix__c + theNumberingSeries.Separator__c + String.valueOf(theNumberingSeries.Last_Number_Used__c);
                	}
                } else {
                    mapNumberSeries = CompanyMgmt.getNumber('Credit Memo');
                    theNumberingSeries = mapNumberSeries.get('Credit Memo');
                    theSI.Name = theNumberingSeries.Prefix__c + theNumberingSeries.Separator__c + String.valueOf(theNumberingSeries.Last_Number_Used__c);
                }
            } else {//Ticket#13607
                if(oldSIMap.containsKey(theSI.Id) && theSI.Sync_d__c == true){
                    if(theSI.SPO_No__c != oldSIMap.get(theSI.Id).SPO_No__c ||
                            theSI.Expected_Payment_Date__c != oldSIMap.get(theSI.Id).Expected_Payment_Date__c){
                        theSI.Sync_d__c = false;
                    }
                }
            }

            if (String.isBlank(theSI.Name)){
            	theSI.Name.addError('Sales Invoice No. cannot be blank.');
			}

            if (isInsert || (theSI.Name != oldSIMap.get(theSI.Id).Name)) {
            
                if (nameSIMap.containsKey(theSI.Name)) {
                    theSI.addError('Duplicate Sales Invoice No. is not allowed. No.: ' + theSI.Name);
                }
                else {
                    nameSIMap.put(theSI.Name, theSI);
                }
                   
            }

            if (String.isBlank(theSI.Bill_to_Customer__c)) {
                theSI.Bill_to_Customer__c.addError('Bill-to Customer cannot be blank.');
            }

            if (String.isBlank(theSI.Document_Status__c)) {
                theSI.Document_Status__c.addError('Document Status cannot be blank.');
            }

            if (String.isBlank(theSI.Subsidiary_Company__c)) {
                theSI.Subsidiary_Company__c.addError('Subsidiary Company cannot be blank.');
            }

            if (String.isBlank(theSI.Service_Center__c)) {
                theSI.Service_Center__c.addError('Service Center cannot be blank.');
            }

            if (String.isBlank(theSI.Tax_Area__c)) {
                theSI.Tax_Area__c.addError('Tax Area cannot be blank.');
            }

            if (String.isBlank(theSI.Sales_Order__c)) {
                theSI.Sales_Order__c.addError('Sales Order cannot be blank.');
            }

            if(theSI.Name.containsIgnoreCase('void') == false){
                if (!isInsert && (theSI.Name != oldSIMap.get(theSI.Id).Name)) {
                    theSI.addError('You are not allowed to change Sales Invoice No: ' + theSI.Name);
                }
            }

            if (theSI.Bill_to_Customer__c != null){
                Account account = accountsByIds.get(theSI.Bill_to_Customer__c);
                // test inter-co tax area
                if(CompanyMgmt.systemCall == false &&
                        account.Inter_co_Account__c == true &&
                        theSI.Tax_Liable__c == true) {
                    //Ticket#21211 Inter_co_Account__c - re-labeled to Intra-Co
                    theSI.Tax_Liable__c.addError('Tax Liable must be No for Intra-Co Account.');
                }

                theSI.Customer_Billing_Instructions__c = AccountsService.generateCustomerBillingInstructions(account);
                //Ticket#28846 >>
                if(salesOrdersByIds.containsKey(theSI.Sales_Order__c)){
                    Sales_Order__c salesOrder = salesOrdersByIds.get(theSI.Sales_Order__c);
                    if(String.isNotBlank(salesOrder.Sales_Order_Instructions__c)){
                        theSI.Customer_Billing_Instructions__c = theSI.Customer_Billing_Instructions__c + '\r\n' + salesOrder.Sales_Order_Instructions__c;
                    }
                }
                //Ticket#28846 <<
            }

            //Change Record Id
            if (theSI.Document_Status__c == 'Posted'){
                theSI.RecordTypeId = Schema.SObjectType.Sales_Invoice__c.getRecordTypeInfosByName().get('Posted Invoice').getRecordTypeId();
                //change posting date <<
                if (!isInsert) {
                    if (theSI.New_Posting_Date__c != null && theSI.Posting_Date__c != theSI.New_Posting_Date__c) {
                        theSI.Original_Posting_Date__c = theSI.Posting_Date__c;
                        theSI.Posting_Date__c = theSI.New_Posting_Date__c;
                        salesInvPostingDates.put(theSI.Id, theSI.New_Posting_Date__c);
                    }
                }
                //change posting date >>

                //replace workflow Sales Invoice Sys Posted Date <<
                theSI.SysPostedDate__c = System.today();
                //replace workflow Sales Invoice Sys Posted Date >>
            } else {
                theSI.RecordTypeId = Schema.SObjectType.Sales_Invoice__c.getRecordTypeInfosByName().get('Open Invoice').getRecordTypeId();
            }
        }

        for (Sales_Invoice__c theSI : [SELECT Name FROM Sales_Invoice__c WHERE Name IN : nameSIMap.keySet()]) {
            Sales_Invoice__c theNewSI = nameSIMap.get(theSI.Name);
            theNewSI.addError('Sales Invoice already exists with same Name : ' + theSI.Name);
        }
        
        //change posting date <<
        if (salesInvPostingDates.size() > 0) {
            List<GL_Entry__c> gls = [SELECT Id, Sales_Invoice__c, Posting_Date__c FROM GL_Entry__c WHERE Sales_Invoice__c IN :salesInvPostingDates.keySet()];
            for (GL_Entry__c gl : gls) {
                gl.Original_Posting_Date__c = gl.Posting_Date__c;
                gl.Posting_Date__c = salesInvPostingDates.get(gl.Sales_Invoice__c);
            }
            if (gls.size() > 0) {
                update gls;
            }
        }
        //change posting date >>

        update mapNumberSeries.values();

    }

    public static void SIDelete(Sales_Invoice__c[] InvoiceList) {
        if (CompanyMgmt.allowToDeleteData != true) {
            for (Sales_Invoice__c theSI : InvoiceList) {
                //if (theSI.Document_Status__c == 'Posted')  theSI.addError('You cannot delete Invoice when Document Status is Posted.');
                theSI.addError('You are not allowed to delete Invoice!');
            }
        }
    }

    public static void SILInsertUpdate(List<Sales_Invoice_Line__c> SILList) {
        Set<Id> theSIId = new Set<Id>();
        Map<Id, Sales_Invoice__c> mapIdSI = new Map<Id, Sales_Invoice__c>();

        Set<Id> theTMLId = new Set<Id>();
        Map<Id, TM_Line__c> mapIdTMLine = new Map<Id, TM_Line__c>();

        for (Sales_Invoice_Line__c theSIL : SILList) {
            theSIId.add(theSIL.Sales_Invoice__c);
            theTMLId.add(theSIL.TM_Line__c);
        }

        for (Sales_Invoice__c theSI : [
                SELECT Id, Document_Status__c, Credit_Memo__c
                FROM Sales_Invoice__c
                WHERE Id IN :theSIId
        ]) {
            mapIdSI.put(theSI.Id, theSI);
        }

        for(TM_Line__c theTML:[SELECT Id, TM__r.Name, Line_No__c FROM TM_Line__c WHERE Id IN :theTMLId]){
            mapIdTMLine.put(theTML.Id, theTML);
        }

        for (Sales_Invoice_Line__c theSIL : SILList) {
            if (CompanyMgmt.byPassTrigger != true) {
                if (theSIL.TM_Line__c != null){
                    TM_Line__c theTML = mapIdTMLine.get(theSIL.TM_Line__c);
                    String tmInfo = '';
                    if(theTML != null && theTML.TM__r.Name != null){
                        tmInfo = 'T&M No.# '+theTML.TM__r.Name + ' T&M Line No.' + theTML.Line_No__c;
                    }
                    if (String.isBlank(theSIL.Category__c)) {
                        //theSIL.Category__c.addError('Category cannot be blank for Line No: ' + theSIL.Line_No__c);
                        theSIL.Category__c.addError('Category cannot be blank for Line with ' + tmInfo);
                    }
                    if (String.isBlank(theSIL.Resource__c)) {
                        if((theSIL.Category__c == ResourceService.EQUIPMENT_CATEGORY && theSIL.Resource_Type__r.Fleet_No_Required__c == true) ||
                                (theSIL.Category__c != ResourceService.EQUIPMENT_CATEGORY)){
                            theSIL.Resource__c.addError('You must enter Resource for ' + tmInfo);
                        }
                    }

                    //job task <<
                    /*
                    if (String.isBlank(theSIL.TM__c) && theSIL.Rental_Order__c == null) {
                        theSIL.TM__c.addError('T&M cannot be blank for Line No: ' + theSIL.Line_No__c);
                    }
                    if (String.isBlank(theSIL.TM_Line__c) && theSIL.Rental_Order__c == null) {
                        theSIL.TM_Line__c.addError('T&M Line cannot be blank for Line No: ' + theSIL.Line_No__c);
                    }
                    */
                    if (String.isBlank(theSIL.TM__c) && theSIL.Rental_Order__c == null && theSIL.Category__c != 'Bundled' && theSIL.System_Calculated_Line__c != true) {
                        theSIL.TM__c.addError('T&M cannot be blank for Line No: ' + theSIL.Line_No__c);
                    }
                    if (String.isBlank(theSIL.TM_Line__c) && theSIL.Rental_Order__c == null && theSIL.Category__c != 'Bundled' && theSIL.System_Calculated_Line__c != true) {
                        theSIL.TM_Line__c.addError('T&M Line cannot be blank for Line No: ' + theSIL.Line_No__c);
                    }
                    //job task >>

                    if (theSIL.Tax_Group__c == null) {
                        //theSIL.Tax_Group__c.addError('Tax Group cannot be blank for Line No: ' + theSIL.Line_No__c);
                        theSIL.Tax_Group__c.addError('Tax Group cannot be blank for ' + tmInfo);
                    }
                    if (CompanyMgmt.zeroIfNull(theSIL.Quantity__c) == 0) {
                        //theSIL.Quantity__c.addError('You must enter Quantity for Line No: ' + theSIL.Line_No__c);
                        theSIL.Quantity__c.addError('You must enter Quantity for ' + tmInfo);
                    }
                        if (mapIdSI != null && mapIdSI.containsKey(theSIL.Sales_Invoice__c) && mapIdSI.get(theSIL.Sales_Invoice__c).Credit_Memo__c) {
                        if (theSIL.Quantity__c > 0) {
                                    //SW Temp Credit Memo mod test
                                    //theSIL.addError('Quantity must be negative for Credit Memo. Line No: ' + theSIL.Line_No__c);
                        }
                    } else {
                        if (theSIL.Quantity__c < 0) {
                            //theSIL.addError('Quantity must be positive for Sales Invoice. Line No: ' + theSIL.Line_No__c);
                            theSIL.addError('Quantity must be positive for ' + tmInfo);
                        }
                    }
                    //Ticket# 13515 <<
                    //if (string.isBlank(theSIL.Unit_of_Measure__c)) {
                    //    theSIL.Unit_of_Measure__c.addError('You must enter Unit of Measure for Line No: ' + theSIL.Line_No__c);
                    //}
                } else {
                    // Rental Invoice
                    if (String.isBlank(theSIL.Resource__c)) {
                        if((theSIL.Category__c == ResourceService.EQUIPMENT_CATEGORY && theSIL.Resource_Type__r.Fleet_No_Required__c == true) ||
                                (theSIL.Category__c != ResourceService.EQUIPMENT_CATEGORY)){
                            theSIL.Resource__c.addError('You must enter Resource for line #' + theSIL.Line_No__c);
                        }
                        //theSIL.Resource__c.addError('You must enter Resource for Line No: ' + theSIL.Line_No__c);
                    }
                    if (theSIL.Tax_Group__c == null) {
                        theSIL.Tax_Group__c.addError('Tax Group cannot be blank for Line No: ' + theSIL.Line_No__c);
                    }
                    if (CompanyMgmt.zeroIfNull(theSIL.Quantity__c) == 0) {
                        theSIL.Quantity__c.addError('You must enter Quantity for Line No: ' + theSIL.Line_No__c);
                    }
                    if (mapIdSI.containsKey(theSIL.Sales_Invoice__c)) {
                        if (mapIdSI.get(theSIL.Sales_Invoice__c).Credit_Memo__c) {
                                    //Temp Credit Memo mod test
                                    //if (theSIL.Quantity__c > 0) {
                                    //    theSIL.addError('Quantity must be negative for Credit Memo. Line No: ' + theSIL.Line_No__c);
                                    //}
                                    //Temp Credit Memo mod test
                        } else {
                            if (theSIL.Quantity__c < 0) {
                                theSIL.addError('Quantity must be positive for Sales Invoice. Line No: ' + theSIL.Line_No__c);
                            }
                        }
                    }
                }
            }
        }
    }

    //job task <<
    public static void updateTMInvoiceRelations(List<Sales_Invoice_Line__c> salesInvoiceLines) {
        Set<Id> tmIds = new Set<Id>();
        for (Sales_Invoice_Line__c salesInvoiceLine : salesInvoiceLines) {
            if (salesInvoiceLine.TM__c != null) {
                tmIds.add(salesInvoiceLine.TM__c);
            }
        }

        Map<Id, Map<Id, TM_Invoice_Relation__c>> mapRelationsByInvoiceIdByTMId = new Map<Id, Map<Id, TM_Invoice_Relation__c>>();
        for (TM_Invoice_Relation__c relation : [SELECT Id, TM__c, Sales_Invoice__c FROM TM_Invoice_Relation__c WHERE TM__c IN :tmIds]) {
            Map<Id, TM_Invoice_Relation__c> mapRelationsByInvoiceId;
            if (mapRelationsByInvoiceIdByTMId.containsKey(relation.TM__c)) {
                mapRelationsByInvoiceId = mapRelationsByInvoiceIdByTMId.get(relation.TM__c);
            }
            else {
                mapRelationsByInvoiceId = new Map<Id, TM_Invoice_Relation__c>();
                mapRelationsByInvoiceIdByTMId.put(relation.TM__c, mapRelationsByInvoiceId);
            }
            mapRelationsByInvoiceId.put(relation.Sales_Invoice__c, relation);
        }

        Set<Id> relationIds = new Set<Id>();
        List<TM_Invoice_Relation__c> relationsToInsert = new List<TM_Invoice_Relation__c>();
        for (Sales_Invoice_Line__c salesInvoiceLine : salesInvoiceLines) {
            if (salesInvoiceLine.TM__c != null) {
                Map<Id, TM_Invoice_Relation__c> mapRelationsByInvoiceId;
                if (mapRelationsByInvoiceIdByTMId.containsKey(salesInvoiceLine.TM__c)) {
                    mapRelationsByInvoiceId = mapRelationsByInvoiceIdByTMId.get(salesInvoiceLine.TM__c);
                    if (!mapRelationsByInvoiceId.containsKey(salesInvoiceLine.Sales_Invoice__c)) {
                        TM_Invoice_Relation__c relation = new TM_Invoice_Relation__c();
                        relation.TM__c = salesInvoiceLine.TM__c;
                        relation.Sales_Invoice__c = salesInvoiceLine.Sales_Invoice__c;
                        mapRelationsByInvoiceId.put(salesInvoiceLine.Sales_Invoice__c, relation);
                        relationsToInsert.add(relation);
                    } else {
                        TM_Invoice_Relation__c relation = mapRelationsByInvoiceId.get(salesInvoiceLine.Sales_Invoice__c);
                        if (relation.Id != null) { //existing relation record
                            relationIds.add(relation.Id);
                        }
                    }
                } else {
                    mapRelationsByInvoiceId = new Map<Id, TM_Invoice_Relation__c>();
                    mapRelationsByInvoiceIdByTMId.put(salesInvoiceLine.TM__c, mapRelationsByInvoiceId);

                    TM_Invoice_Relation__c relation = new TM_Invoice_Relation__c();
                    relation.TM__c = salesInvoiceLine.TM__c;
                    relation.Sales_Invoice__c = salesInvoiceLine.Sales_Invoice__c;
                    mapRelationsByInvoiceId.put(salesInvoiceLine.Sales_Invoice__c, relation);
                    relationsToInsert.add(relation);
                }
            }
        }

        //clean up the map, remove relation records that are not valid anymore
        List<TM_Invoice_Relation__c> relationsToDelete = new List<TM_Invoice_Relation__c>();
        for (Map<Id, TM_Invoice_Relation__c> mapRelationsByInvoiceId : mapRelationsByInvoiceIdByTMId.values()) {
            for (TM_Invoice_Relation__c relation : mapRelationsByInvoiceId.values()) {
                if (relationIds.contains(relation.Id)) {
                    relationsToDelete.add(relation);
                }
            }
        }

        CompanyMgmt.byPassTrigger = true;
        if (relationsToInsert.size() > 0) {
            insert relationsToInsert;
        }
        if (relationsToDelete.size() > 0) {
            delete relationsToDelete;
        }
        CompanyMgmt.byPassTrigger = false;
    }
    //job task >>
}