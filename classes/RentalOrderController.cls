public with sharing class RentalOrderController {
    private final ApexPages.StandardController theController;
    public ApexPages.StandardSetController setCon;
    private Rental_Order__c theRO;
    @testvisible
    private String ROId;
    private Company_Setup__c theCompanySetup = CompanyMgmt.getCompanySetup();
    public Date lastDateOfLastMonth{get;set;}
    public string lastDateOfLastMonthValue{get;set;}
    @testvisible
    Set<Id> selectedIds;
    public List<Rental_Order__c> selectedROList { get; set; }
    string errMsg;
    
     public RentalOrderController(ApexPages.StandardSetController controller) {
        setCon = controller;
        theRO = new Rental_Order__c();
        lastDateOfLastMonth = Date.today().toStartOfMonth().addDays(-1);
        lastDateOfLastMonthValue = lastDateOfLastMonth.month() + '/' + lastDateOfLastMonth.day() + '/' + lastDateOfLastMonth.year();
    }
    
    public RentalOrderController(ApexPages.StandardController controller) {
        theController = controller;
        ROId = ApexPages.CurrentPage().getParameters().get('id');
        if (ROId != null) {
            selectRO();
        } else {
            theRO = new Rental_Order__c();
        }
        lastDateOfLastMonth = Date.today().toStartOfMonth().addDays(-1);
        lastDateOfLastMonthValue = lastDateOfLastMonth.month() + '/' + lastDateOfLastMonth.day() + '/' + lastDateOfLastMonth.year();
    }
    
    @testvisible
    private void selectRO() {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Rental_Order__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Drop_Off_T_M__r.Name, Drop_Off_T_M_Line__r.Name, Pickup_T_M__r.Name, Pickup_T_M_Line__r.Name, ';
        strQuery += ' Resource__r.Name, Sales_Order__r.Name ';
        strQuery += ' FROM Rental_Order__c WHERE Id =: ROId';
        theRO = Database.query(strQuery);
    }
    
    public String title {
        get {
            if (ROId == null) {
                return 'New Return Order';
            } else {
                return theRO.Name;
            }
        }
    }
    
    public Rental_Order__c RO {
        get {
            return theRO;
        }
    }
    
    public Company_Setup__c CompanySetup {
        get {
            return theCompanySetup;
        }
    }
    
    public pagereference save() {
        msave();
        if (!ApexPages.hasMessages()) {
            PageReference ROPage = new PageReference('/' + theRO.Id);
            ROPage.setRedirect(true);
            return ROPage;
        } else
            return null;
    }
    
    public pagereference quickSave() {
        msave();
        if (!ApexPages.hasMessages()) {
            PageReference ROPage = new PageReference('/apex/RentalOrder?id=' + theRO.Id);
            ROPage.setRedirect(true);
            return ROPage;
        } else {
            return null;
        }
        
    }
    
    public void msave() {
        // To differentiate from stanadrd edit page
        CompanyMgmt.systemCall = true;
        Integer i = 0;
        Rental_Order__c oldRO = theRO.clone(true);
        // Savepoint
        Savepoint sp = database.setSavePoint();
        
        //Check Errors
        List<String> errorList = new List<String>();
        errorList = RentalOrderMgmt.checkSave(theRO);
        if (errorList.size() > 0) {
            for (i = 0; i < errorList.size(); i++) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, errorList[i]));
            }
        } else {
            try {                
                theRO = RentalOrderMgmt.nullRelationshipFields(theRO);
                
                upsert theRO;
                System.debug('****scott' + ' five');
            } catch (exception e) {
                System.debug('****scott' + ' six ' + e.getmessage());
                Database.Rollback(sp);
                theRO = oldRO;
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
            }
        }
    }
    
    public pagereference CreateInvoice() {
        /* Removing Default_Rental_Resource__c from Company Setup
        List<Sales_Invoice__c> theSIList = new List<Sales_Invoice__c>();
        List<Sales_Invoice_Line__c> theSILList = new List<Sales_Invoice_Line__c>();
        List<Rental_Order__c> theROList = new List<Rental_Order__c>();
        Sales_Invoice__c theSI;
        Set<Id> SIIdSet = new Set<Id>();
        Sales_Invoice_Line__c theSIL;
        Integer Counter = 0;
        lastDateOfLastMonth = date.parse(lastDateOfLastMonthValue);

        String closedString = 'Closed';
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Rental_Order__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Drop_Off_T_M__r.Name, Drop_Off_T_M_Line__r.Name, Pickup_T_M__r.Name, Pickup_T_M_Line__r.Name, Sales_Order__r.Account_Executives__c, ';
        strQuery += ' Resource__r.Name, Sales_Order__r.Name, Sales_Order__r.Site_Name__c, Sales_Order__r.Site_Street__c, Sales_Order__r.Site_City__c,  ';
        strQuery += ' Sales_Order__r.Site_State__c, Sales_Order__r.Site_Phone_No__c, Sales_Order__r.Site_Country__c, ';
        strQuery += ' Sales_Order__r.Tax_Area__c, ';
        strQuery += ' Sales_Order__r.Site_Contact__c, Sales_Order__r.Site_Postal_Code__c, Sales_Order__r.Site_Email_Address__c, Sales_Order__r.Tax_Liable__c ';
        
        strQuery += ' FROM Rental_Order__c WHERE Document_Status__c !=: closedString AND (Last_Invoice_Date__c <: lastDateOfLastMonth OR Last_Invoice_Date__c = null)';
        strQuery += ' AND Drop_Off_Date__c != null';
        System.debug('<==strQuery==>'+strQuery+'<==closedString==>'+closedString +'<==closedString==>'+lastDateOfLastMonth);
        theROList = Database.query(strQuery);
        
        
        Set<Id> setAccount = new Set<Id>();
        if(theROList != null && theROList.size() > 0) {
            for (Rental_Order__c RO : theROList) {
                if (!string.isEmpty(RO.Bill_to_Customer__c)) {
                    setAccount.add(RO.Bill_to_Customer__c);
                }
            }
            SalesInvoiceMgmt.mapAccount = new Map<Id, Account>([
                SELECT Id, Name, Billing_Contact__c, Billing_Contact__r.FirstName, Billing_Contact__r.LastName, BillingStreet, BillingCity,
                BillingStateCode, BillingPostalCode, BillingCountryCode,
                ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode,
                ShippingCountry,
                Payment_Term__c, Payment_Term__r.Name,Salesperson__c,Salesperson__r.Name,
                Tax_Liable__c, Tax_Area__c, Tax_Area__r.Name
                FROM Account
                WHERE Id IN :setAccount
            ]);
            
            Savepoint sp = database.setSavePoint();
            
            system.debug('theROList***' + theROList);
            theSIList = new List<Sales_Invoice__c>();
            for(Rental_Order__c theRO : theROList) {
                theSI = new Sales_Invoice__c();
                theSI.Bill_To_Customer__c = theRO.Bill_to_Customer__c;
                // Need to bulkify
                theSI = SalesInvoiceMgmt.validateBillToCustomer(theSI);
                theSI.Contact__r = null;
                theSI.Tax_Area__r = null;
                theSI.Salesperson__r = null;
                theSI.Bill_to_Customer__r = null;
                //theSI.Tax_Area__c = theRO.Tax_Area__c;
                theSI.Rental_Order__c = theRO.Id;
                theSI.Rental_Invoice__c = true;
              if (theRO.Last_Invoice_Date__c != null){
                  theSI.Last_Invoice_Date__c = theRO.Last_Invoice_Date__c;
              } else {
               if (theRO.Drop_Off_Date__c != null) {
                      theSI.Last_Invoice_Date__c = theRO.Drop_Off_Date__c;
                  }
              }
                theSI.Rent_Billing_Amount__c = theRO.Billing_Amount__c;
                theSI.Sales_Order__c = theRO.Sales_Order__c;
                theSI.Service_Center__c = theRO.Service_Center__c;
                theSI.Subsidiary_Company__C = theRO.Subsidiary_Company__c;
                theSI.Account_Executive__c = theRO.Sales_Order__r.Account_Executives__c;
                theSI.Completed_Date__c = lastDateOfLastMonth;
                theSI.Invoice_Date__c = lastDateOfLastMonth;
                theSI.Site_Name__c = theRO.Sales_Order__r.Site_Name__c;
                theSI.Site_Street__c = theRO.Sales_Order__r.Site_Street__c;
                theSI.Site_City__c = theRO.Sales_Order__r.Site_City__c;
                theSI.Site_State__c = theRO.Sales_Order__r.Site_State__c;
                theSI.Site_Postal_Code__c = theRO.Sales_Order__r.Site_Postal_Code__c;
                theSI.Site_Country__c = theRO.Sales_Order__r.Site_Country__c;
                theSI.Site_Contact__c = theRO.Sales_Order__r.Site_Contact__c;
                theSI.Site_Phone_No__c = theRO.Sales_Order__r.Site_Phone_No__c;
                theSI.Site_Email_Address__c = theRO.Sales_Order__r.Site_Email_Address__c;
                theSI.Document_Status__c = 'Open'; 
                
                Counter += 1;

                theSIList.add(theSI);

                // Need to create a SIL per SI
                // Default rental resources
                // Unit Price = Billing Amount
                // Quantity = last month end date - last invoice date
            }
            
            if(theSIList != null && theSIList.size() > 0) {
                try {
                    insert theSIList;
                } catch (exception e) {
                    // Rollback
                    Database.Rollback(sp);
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
                    System.debug('****ashish' + ' six ' + e.getmessage());
                }
            }
            
            SalesInvoiceMgmt.mapResource = new Map<Id, Resource__c>([
                SELECT Name, Unit_of_Measure__c, Unit_of_Measure__r.Name, Employee_Type__c, Description__c,
                Category__c, Tax_Group__c, Unit_Cost__c
                FROM Resource__c
                WHERE Id =:CompanySetup.Default_Rental_Resource__c
            ]);
            
            system.debug('CompanySetup.Default_Rental_Resource__c***' + CompanySetup.Default_Rental_Resource__c);            
            for(Sales_Invoice__c SI : theSIList) {
                SIIdSet.add(SI.Id);
            }

            for(Sales_Invoice__c SI : theSIList) {
                system.debug('scott1.5/' + SI);
                theSIL = new Sales_Invoice_Line__c();
                theSIL.Sales_Invoice__c = SI.Id;
                theSIL.Resource__c = CompanySetup.Default_Rental_Resource__c;
                theSIL = SalesInvoiceMgmt.updateSIL(SI, theSIL, 'theResource');
                theSIL.Unit_Price__c = theSI.Rent_Billing_Amount__c;
                theSIL = SalesInvoiceMgmt.updateSIL(SI, theSIL, 'theUnitPrice');
                theSIL.Quantity__c = -lastDateOfLastMonth.daysBetween(theSI.Last_Invoice_Date__c);
                theSIL = SalesInvoiceMgmt.updateSIL(SI, theSIL, 'theQuantity');
                theSIL.Rental_Order__c = theSI.Rental_Order__c;
                theSIL.Tax_Group__c = 'TX';
                if (theSIL.Quantity__c != 0 && theSIL.Quantity__c != null){
                    theSILList.add(theSIL);
                }
            }
            
            if(theSILList != null && theSILList.size() > 0) {
                try {
                    insert theSILList;
                } catch (exception e) {
                    // Rollback
                    Database.Rollback(sp);
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
                }
            }
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'You have successfully created ' + Counter + ' rental invoices.'));
        }
         */
        
        return null;
    }

    public PageReference returnBack() {
        //PageReference pageref = new PageReference('/apex/Administration');
        PageReference pageref = new PageReference('/a0c');
        pageref.setRedirect(true);
        return pageref;
    }
}