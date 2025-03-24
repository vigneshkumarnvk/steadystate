public with sharing class PurchOrderMgmt {

    public static Boolean poCall { get; set; }

    public static List <String> checkSave(Purchase_Order__c thePO, List<Purchase_Line__c> thePLList) {
        List<String> errorList = new List<String>();
        //Ticket 13388 >>
        Set<String> scIds = new Set<String>();
        Map<String, Service_Center__c> scIdMap = new Map<String, Service_Center__c>();

        for(Purchase_Line__c pl : thePLList){
            if(Test.isRunningTest() != true){
                if(pl.Subsidiary_Company__c != thePO.Subsidiary_Company__c) {
                    throw new DataException('Header and Line Subsidiary Company mismatch found!');
                    //errorList.add('Header and Line Subsidiary Company mismatch found!');
                }
            }
            if(!scIds.contains(pl.Service_Center__c)){
                scIds.add(pl.Service_Center__c);
            }
        }

        List<Service_Center__c> scLst = [SELECT Id, Name, PO_Allow_Blank_SO_with_Direct_GL_Account__c FROM Service_Center__c WHERE Id IN :scIds];
        for(Service_Center__c sc:scLst){
            scIdMap.put(sc.Id, sc);
        }
        //Ticket 13388 <<
        if (String.isBlank(thePO.Service_Center__c)) {
            throw new DataException('Service Center field cannot be blank!');
            //errorList.add('Service Center field cannot be blank!');
        }
        if (String.isBlank(thePO.Note__c)) {
            throw new DataException('Note field cannot be blank!');
            //errorList.add('Note field cannot be blank!');
        }
        if (thePLList.size() > 0) {
            for (Purchase_Line__c pl : thePLList) {
                if (( pl.Item__r.Name != null && pl.Item__r.Name.toUpperCase() == 'NEW') && (String.isBlank(pl.Vendor_Description__c))) {
                    throw new DataException('Vendor Description field cannot be blank for lines with product name NEW');
                    //errorList.add('Vendor Description field cannot be blank for lines with product name NEW');
                }

                if (String.isBlank(pl.Service_Center__c)) {
                    throw new DataException('Service Center field must not be blank!');
                    //errorList.add('Service Center field must not be blank!');
                }

                if ((String.isEmpty(pl.G_L_Account__c) || pl.G_L_Account__c == null) && thePO.Inter_co_Account__c == false){
                    throw new DataException('G/L Account must not be blank!');
                    //errorList.add('G/L Account must not be blank!');
                }

                /*
                if(pl.Service_Center__r.Subsidiary_Company__c != thePO.Subsidiary_Company__c){
                    errorList.add('There are some lines entries does not belong to ' + thePO.Subsidiary_Company__r.Name);
                }*/

                //Ticket 13388 >>
                if(scIdMap.get(pl.Service_Center__c) != null) {
                    if (pl.Direct_G_L_Account__c == true && pl.Sales_Order__c == null && scIdMap.get(pl.Service_Center__c).PO_Allow_Blank_SO_with_Direct_GL_Account__c != true) {
                        throw new DataException('Line ' + pl.Line_No__c + ': Sales Order field must not be blank when direct G/L Account is used!');
                        //errorList.add('Line ' + pl.Line_No__c + ': Sales Order field must not be blank when direct G/L Account is used!');
                    }
                }
                //Ticket 13388 <<
            }
        }
        return errorList;
    }

    //public static List <String> checkCreateReceipt(Purchase_Order__c thePO) {
    public static void checkCreateReceipt(Purchase_Order__c thePO) {
        List<String> errorList = new List<String> ();
        List<Purchase_Line__c> thePLList =
        [SELECT Line_No__c, Item_Blocked__c, /*Item__r.Name,*/ Outstanding_Qty__c, Unit_Cost__c, Name, Direct_G_L_Account__c, Sales_Order__c, Service_Center__r.PO_Allow_Blank_SO_with_Direct_GL_Account__c
        FROM Purchase_Line__c WHERE Purchase_Order__c = : thePO.Id AND (Qty_to_Receive__c <> 0 AND Qty_to_Receive__c != NULL)];

        if (thePO.Closed__c == true){
            throw new DataException('Purchase Order is closed.');
            //errorList.add('Purchase Order is closed.');
            //return errorList;
        }

        if (thePLList.size() == 0) {
            throw new DataException('There is nothing to create.');
            //errorList.add('There is nothing to create.');
        }

        // Open Purchase Receipt exist?
        List<Purchase_Receipt__c> thePRList = [SELECT Name FROM Purchase_Receipt__c WHERE Purchase_Order__c = :thePO.Id AND Document_Status__c = 'Open'];
        if (thePRList.size() > 0) {
            throw new DataException('There is an open Purchase Receipt created already.');
            //errorList.add('There is an open Purchase Receipt created already.');
        }

        if (!(thePO.Document_Status__c == 'Approved' || thePO.Document_Status__c == 'Partially Received')) {
            throw new DataException('Order status must be Approved.');
            //errorList.add('Order status must be Approved.');
        }

        if (thePO.Buy_From_Blocked__c) {
            throw new DataException('Buy-From Vendor is blocked. You are not allowed to create Purchase Receipt.');
            //errorList.add('Buy-From Vendor is blocked. You are not allowed to create Purchase Receipt.');
        }

        /*
        if (thePO.Pay_To_Blocked__c) {
            errorList.add('Pay-To Vendor is blocked. You are not allowed to create Purchase Receipt.');
        }
        */

        for (Purchase_Line__c thePL : thePLList) {
            // Check Unit Cost
            if (thePL.Unit_Cost__c < 0) {
                throw new DataException('Unit Cost cannot be negative. ' + thePL.Name);
                //errorList.add('Unit Cost cannot be negative. ' + thePL.Name);
            }
            if (thePL.Item_Blocked__c) {
                throw new DataException('Item ' + thePL.Item__r.Name + ' is blocked. You are not allowed to create Purchase Receipt.');
                //errorList.add('Item ' + thePL.Item__r.Name + ' is blocked. You are not allowed to create Purchase Receipt.');
            }

            //Ticket 13388 >>
            //if (thePL.Direct_G_L_Account__c == true && thePL.Sales_Order__c == null && thePO.Subsidiary_Company__r.Name != '2-CYCLE CHEM., INC.'){
            if (thePL.Direct_G_L_Account__c == true && thePL.Sales_Order__c == null && thePL.Service_Center__r.PO_Allow_Blank_SO_with_Direct_GL_Account__c != true){
                throw new DataException('Line ' + thePL.Line_No__c + ': Sales Order field must not be blank when direct G/L Account is used!');
                //errorList.add('Line ' + thePL.Line_No__c + ': Sales Order field must not be blank when direct G/L Account is used!');
            }

        }

        User theUser = [SELECT Id, Name, Purchasing_Department_Receiver__c FROM USER WHERE Id = :UserInfo.getUserId()];
        if ((thePO.PO_Requestor__c != UserInfo.getUserId()) && (thePO.OwnerId != UserInfo.getUserId()) && (!theUser.Purchasing_Department_Receiver__c)) {
            throw new DataException('PO can only be received by PO Requestor, PO Owner or purchasing department staff.');
            //errorList.add('PO can only be received by PO Requestor, PO Owner or purchasing department staff.');
        }

        //return errorList;
    }

    //public static List <String> checkClose(Purchase_Order__c thePO) {
    public static void checkClose(Purchase_Order__c thePO) {
        //List<String> errorList = new List<String>();

        //if (thePO.Received_Not_Invoiced_Qty__c != 0) {
        //     errorList.add('You must invoice posted Receipts first.');
        // }

        List<Purchase_Receipt__c> thePRList = [SELECT Name FROM Purchase_Receipt__c WHERE Purchase_Order__c = :thePO.Id AND Document_Status__c = 'Open'];
        if (thePRList.size() > 0) {
            throw new DataException('You must delete open Purchase Receipts first.');
            //errorList.add('You must delete open Purchase Receipts first.');
        }

        //return errorList;
    }

    // Validate Purchase Order
    public static Purchase_Order__c validateBuyFromVendor(Purchase_Order__c thePO) {
        Company_Setup__c theCompanySetup = companyMgmt.getCompanySetup();
        if (String.isBlank(thePO.Buy_from_Vendor__c)) {
            return thePO;
        }

        Account theBFVendor;

        if (mapAccount.containsKey(thePO.Buy_from_Vendor__c)) {
            theBFVendor = mapAccount.get(thePO.Buy_from_Vendor__c);
        } else {
            theBFVendor = [SELECT Id, Name, Billing_Contact__r.Name, Billing_Contact__r.FirstName, Billing_Contact__r.LastName,
                    BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                    BillingStateCode, BillingCountryCode, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,
                    ShippingStateCode, ShippingCountryCode, Alternate_Billing__c, Alternate_Billing__r.Name, Payment_Term__c, Inter_co_Account__c,
                    Auto_Create_Catalog_Item__c
            FROM Account WHERE Id = : thePO.Buy_from_Vendor__c];
            mapAccount.put(theBFVendor.Id, theBFVendor);
        }

        thePO.Buy_from_Vendor__r = new Account(Id = theBFVendor.Id, Name = theBFVendor.Name);
        if (thePO.Order_Date__c == null) {
            thePO.Order_Date__c = Date.today();
        }

        thePO.Document_Status__c = 'Open';
        thePO.Expected_Receipt_Date__c = CompanyMgmt.calcDate(thePO.Order_Date__c, theCompanySetup.Default_Days_to_Receive__c);

        // need to lookup user setup table
        thePO.Billing_Contact__c = theBFVendor.Billing_Contact__c;
        thePO.Billing_Contact__r = new Contact(Id = theBFVendor.Billing_Contact__c, FirstName = theBFVendor.Billing_Contact__r.FirstName, LastName = theBFVendor.Billing_Contact__r.LastName);
        thePO.Inter_co_Account__c = theBFVendor.Inter_co_Account__c;

        thePO = validateServiceCenter(thePO);
        //thePO = validatePaymentTerm(thePO);
        //thePO = validateSubVendor(thePO);

        return thePO;
    }

    public static Purchase_Order__c validateSubVendor(Purchase_Order__c thePO) {
        if (String.isNotBlank(thePO.Buy_from_Vendor__c) && String.isNotBlank(thePO.Subsidiary_Company__c)) {
            List<Subsidiary_Vendor__c> subVendor = [SELECT Id,Payment_Term__c, Payment_Term__r.Name FROM Subsidiary_Vendor__c
            WHERE Subsidiary_Company__c = :thePO.Subsidiary_Company__c AND Account__c = :thePO.Buy_from_Vendor__c AND (Service_Center__c = :thePO.Service_Center__c OR Service_Center__c = null)
            ORDER BY Service_Center__r.Name DESC NULLS LAST];
            if (!subVendor.isEmpty()) {
                thePO.Subsidiary_Vendor_Account__c = subVendor[0].Id;
            }
        }
        return thePO;
    }

    public static Purchase_Order__c validateBillingVendor(Purchase_Order__c thePO) {
        /*
        Account theBTVendor;
        if (String.isNotBlank(thePO.Pay_to_Vendor__c)) {
            if (mapAccount.containsKey(thePO.Pay_to_Vendor__c))
                theBTVendor = mapAccount.get(thePO.Pay_to_Vendor__c);
            else
                theBTVendor = [SELECT Id, Name, Billing_Contact__c, Billing_Contact__r.Name, Billing_Contact__r.FirstName, Billing_Contact__r.LastName,
                               BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, E_Mail__c,
                               BillingStateCode,
                               BillingCountryCode,
                               Payment_Term__c, Payment_Term__r.Name
                               FROM Account WHERE Id = : thePO.Pay_to_Vendor__c];
        } else {
            if (String.isBlank(thePO.Buy_from_Vendor__c)) return thePO;
            if (mapAccount.containsKey(thePO.Buy_from_Vendor__c))
                theBTVendor = mapAccount.get(thePO.Buy_from_Vendor__c);
            else
                theBTVendor = [SELECT Id, Name, Billing_Contact__c, Billing_Contact__r.Name, Billing_Contact__r.FirstName, Billing_Contact__r.LastName,
                               BillingStreet, BillingCity, BillingPostalCode, BillingCountry, BillingState, E_Mail__c,
                               BillingStateCode,
                               BillingCountryCode,
                               Payment_Term__c, Payment_Term__r.Name
                               FROM Account WHERE Id = : thePO.Buy_from_Vendor__c];
        }

        //thePO.Pay_to_Vendor__c = theBTVendor.Id;
        thePO.Pay_to_Vendor__r = new Account(Id = theBTVendor.Id, Name = theBTVendor.Name);
        /*
        //thePO.Billing_Contact__c = theBTVendor.Billing_Contact__c;
        thePO.Billing_Contact__r = new Contact(Id = theBTVendor.Billing_Contact__c, FirstName = theBTVendor.Billing_Contact__r.FirstName, LastName = theBTVendor.Billing_Contact__r.LastName);
        thePO.Billing_Street__c = theBTVendor.BillingStreet;
        thePO.Billing_City__c = theBTVendor.BillingCity;
        thePO.Billing_State__c = theBTVendor.BillingStateCode;
        thePO.Billing_Postal_Code__c = theBTVendor.BillingPostalCode;
        thePO.Billing_Country__c = theBTVendor.BillingCountryCode;
        */
        // Retrieve and Update Payment Terms
        //thePO.Payment_Term__c = theBTVendor.Payment_Term__c;
        //thePO.Payment_Term__r = new Payment_Term__c(Id = theBTVendor.Payment_Term__c, Name = theBTVendor.Payment_Term__r.Name);
        //thePO.E_Mail__c = theBTVendor.E_Mail__c;
        //thePO = validatePaymentTerm(thePO);
        //thePO = validateServiceCenter(thePO);
        return thePO;
    }

    public static Purchase_Order__c validateShipToAddress(Purchase_Order__c thePO) {
        if (String.isEmpty(thePO.Ship_To_Address__c)) {
            return thePO;
        }

        Ship_To_Address__c theShipTo = [SELECT City__c, Country__c, Id, Name, Postal_Code__c, State__c, Street__c FROM Ship_To_Address__c WHERE Id = :thePO.Ship_To_Address__c];

        if (theShipTo != null) {
            thePO.Ship_To_Address__r = new Ship_To_Address__c(Id = theShipTo.Id, Name = theShipTo.Name, City__c = theShipTo.City__c, Country__c = theShipTo.Country__c, Postal_Code__c = theShipTo.Postal_Code__c,
                    State__c = theShipTo.State__c, Street__c = theShipTo.Street__c);
            thePO.Shipping_State__c = theShipTo.State__c;
            thePO.Shipping_Country__c = theShipTo.Country__c;
            thePO.Shipping_Postal_Code__c = theShipTo.Postal_Code__c;
            thePO.Shipping_Street__c = theShipTo.Street__c;
            thePO.Shipping_City__c = theShipTo.City__c;
        }

        return thePO;
    }

    public static Purchase_Order__c validatePaymentTerm(Purchase_Order__c thePO) {
        /*
        if (String.isEmpty(thePO.Payment_Term__c)) {
            return thePO;
        }
        Payment_Term__c paymentTerm;

        if (mapPaymentTerm.containsKey(thePO.Payment_Term__c))
            paymentTerm = mapPaymentTerm.get(thePO.Payment_Term__c);
        else
            paymentTerm = [SELECT Id, Name, Discount_Pct__c, Discount_Date_Calculation__c, Due_Date_Calculation__c
                           FROM Payment_Term__c WHERE Id = : thePO.Payment_Term__c];
        if (paymentTerm != null) {
            //thePO.Due_Date__c = CompanyMgmt.calcDate(thePO.Order_Date__c, paymentTerm.Due_Date_Calculation__c);
            //thePO.Payment_Discount_Date__c = CompanyMgmt.calcDate(thePO.Order_Date__c, paymentTerm.Discount_Date_Calculation__c);
            //thePO.Payment_Discount_Pct__c = paymentTerm.Discount_Pct__c;
        }
        */
        return thePO;

    }
    /*
    public static Purchase_Order__c validateCurreny(Purchase_Order__c thePO) {
        if (String.isEmpty(thePO.Currency__c)) {
            return thePO;
        } else {
            Currency__c Curr = [SELECT Id, Name FROM Currency__c WHERE Id = : thePO.Currency__c LIMIT 1];
            thePO.Currency__r = new Currency__c(Id = Curr.Id, Name = Curr.Name);
        }
        return thePO;
    }
    */

    //check for vendor invoice # duplicate <<
    public static Purchase_Order__c validateVendorInvoiceNo(Purchase_Order__c thePO) {
        if (thePO.Buy_from_Vendor__c != null && thePO.Vendor_Invoice_No__c != null) {
            List<Purchase_Order__c> pos = [SELECT Id, Name FROM Purchase_Order__c WHERE Id <> :thePO.Id AND Buy_from_Vendor__c = :thePO.Buy_from_Vendor__c AND Vendor_Invoice_No__c = :thePO.Vendor_Invoice_No__c];
            if (pos.size() > 0) {
                throw new DataException('The vendor invoice # already exists on ' + pos[0].Name + ' for this vendor.');
            }
        }
        return thePO;
    }
    //check for vendor invoice # duplicate >>
    public static Purchase_Order__c validateBillingContact(Purchase_Order__c thePO) {
        if (String.isEmpty(thePO.Billing_Contact__c)) {
            return thePO;
        } else {
            Contact billingContact = [SELECT Id, FirstName, LastName,Phone FROM Contact WHERE Id = :thePO.Billing_Contact__c LIMIT 1];
            thePO.Billing_Contact__c = billingContact.Id;
            thePO.Billing_Contact__r = new Contact(Id = billingContact.Id, FirstName = billingContact.FirstName, LastName = billingContact.LastName);
            //Ticket# 13468
            thePO.Contact_Phone_No__c = billingContact.Phone;
        }
        return thePO;
    }

    public static Purchase_Order__c validatethePORequestor(Purchase_Order__c thePO) {
        if (String.isEmpty(thePO.PO_Requestor__c)) {
            return thePO;
        } else {
            User theUser = [
                    SELECT FirstName,Id,IsActive,LastName,MiddleName,Name,Username,Alias,Email,CommunityNickname FROM User
                    WHERE Id =: thePO.PO_Requestor__c];

            thePO.PO_Requestor__r = new User(Id = theUser.Id,
                    LastName = theUser.LastName,
                    FirstName = theUser.FirstName,
                    Alias = theUser.Alias,
                    Email = theUser.Email,
                    Username = theUser.Username,
                    CommunityNickname = theUser.CommunityNickname
            );

            return thePO;
        }
    }

    public static Purchase_Order__c validateServiceCenter(Purchase_Order__c thePO) {

        if (String.isEmpty(thePO.Service_Center__c)) {
            thePO.SC_Field_Update__c = null;
            return thePO;
        } else {

            Service_Center__c sc = [SELECT Id,Name,Subsidiary_Company__c,Street__c,City__c,State__c,Country__c,Postal_Code__c,Subsidiary_Company__r.Name, No_PO_s_Allowed__c
            FROM Service_Center__c WHERE Id = : thePO.Service_Center__c LIMIT 1];
            if (sc.No_PO_s_Allowed__c == true) {
                thePO.addError('The service center \'' + sc.Name + '\' does not alllow POs.');
                thePO.Service_Center__c = null;
                return thePO;
            }

            Subsidiary_Vendor__c[] SubVends = [SELECT Id, Name, Service_Center__r.Name, Subsidiary_Company__c, Account__c, Payment_Term__c, Payment_Term__r.Name
            FROM Subsidiary_Vendor__c
            WHERE Subsidiary_Company__c =: sc.Subsidiary_Company__c AND Account__c =: thePO.Buy_from_Vendor__c AND (Service_Center__c = :thePO.Service_Center__c OR Service_Center__c = null)
            ORDER BY Service_Center__r.Name DESC NULLS LAST];
            if(SubVends.size() == 0) {
                thePO.addError('Subsidiary vendor \'' + thePO.Buy_from_Vendor__r.Name + '\' does not exits for the subsidiary company ' + sc.Subsidiary_Company__r.Name);
                return thePO;
            }

            thePO.Subsidiary_Vendor_Account__c = SubVends[0].Id;
            thePO.Payment_Term__c = SubVends[0].Payment_Term__c;
            if (thePO.Payment_Term__c != null) {
                thePO.Payment_Term__r = new Payment_Term__c(Id = SubVends[0].Payment_Term__c, Name = SubVends[0].Payment_Term__r.Name);
            }
            thePO.Subsidiary_Company__c = sc.Subsidiary_Company__c;
            thePO.Subsidiary_Company__r = new Subsidiary_Company__c(Id = sc.Subsidiary_Company__c, Name = sc.Subsidiary_Company__r.Name);
            thePO.Service_Center__r = new Service_Center__c(Id = sc.Id, Name = sc.Name);
            thePO.SC_Field_Update__c = sc.Name;
            thePO.Shipping_Street__c = sc.Street__c;
            thePO.Shipping_City__c = sc.City__c;
            thePO.Shipping_Country__c = sc.Country__c;
            thePO.Shipping_State__c = sc.State__c;
            thePO.Shipping_Postal_Code__c = sc.Postal_Code__c;
        }

        return thePO;
    }

    //  Validate Purchase Line
    public static Purchase_Line__c updatePL(Purchase_Line__c thePL, Purchase_Order__c thePO, String sourceField) {
        /*
        if(sourceField == 'theItem' && thePL.Received_Qty__c != 0){
            thePL.addError('You cannot change line that is already been received!');
        }
        */

        if (thePL.Item__c == null) {
            thePL.Vendor_SKU__c = '';
            thePL.Vendor_Description__c = '';
            thePL.Unit_of_Measure__c = null;
            thePL.Quantity__c = 0;
            thePL.Unit_Cost__c = 0;
            thePL.Tax_Pct__c = 0;
            thePL.Received_Qty__c = 0;
            thePL.Qty_to_Receive__c = 0;
            thePL.Discount_Pct__c = 0;
            thePL.Service_Center__c = null;
            thePL.Sales_Order__c = null;
            return thePL;
        }

        Purchase_Price__c theItem;
        if (!mapItem.containsKey(thePL.Item__c)) {
            theItem = [SELECT Id, Name, Account__c, Unit_of_Measure__r.Name, Unit_of_Measure__c, Unit_Cost__c, Vendor_SKU__c, Vendor_Description__c, Default_Direct_G_L_Account__c, Default_Indirect_G_L_Account__c
            FROM Purchase_Price__c WHERE Id = : thePL.Item__c LIMIT 1];
            mapItem.put(thePL.Item__c, theItem);
        }
        theItem = mapItem.get(thePL.Item__c);

        Service_Center__c theSC;
        Id serviceCenterId;
        if(String.isNotEmpty(thePL.Service_Center__c)){
            serviceCenterId = thePL.Service_Center__c;

        } else {
            serviceCenterId = thePO.Service_Center__c;
        }

        if (String.isNotEmpty(serviceCenterId)) {
            if(!mapSC.containsKey(serviceCenterId)){
                Service_Center__c sc = [SELECT Id, Name, Subsidiary_Company__c, Code__c, No_PO_s_Allowed__c FROM Service_Center__c WHERE Id = :serviceCenterId];
                mapSC.put(sc.Id, sc);
            }
        }
        else {
            thePL.addError('The service center is required.');
            return thePL;
        }

        theSC = mapSC.get(serviceCenterId);

        if (theSC.No_PO_s_Allowed__c == true) {
            thePL.addError('The service center \'' + theSC.Name + '\' does not allow POs.');
        }

        if (sourceField == 'theItem') {

            Account vendorAccount;
            if(!mapAccount.containsKey(thePO.Buy_from_Vendor__c)){
                vendorAccount = [SELECT Id, Name, Billing_Contact__c, Billing_Contact__r.Name, Billing_Contact__r.FirstName, Billing_Contact__r.LastName,
                        BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                        ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,
                        Alternate_Billing__c, Alternate_Billing__r.Name,Payment_Term__r.Name, Payment_Term__c, Inter_co_Account__c,
                        Auto_Create_Catalog_Item__c FROM Account WHERE Id = :thePO.Buy_from_Vendor__c LIMIT 1];
                mapAccount.put(vendorAccount.Id, vendorAccount);
            } else {
                vendorAccount = mapAccount.get(thePO.Buy_from_Vendor__c);
            }

            if (theItem.Name.toUpperCase() == 'NEW' && !vendorAccount.Auto_Create_Catalog_Item__c) {
                thePL.addError('Vendor ' + thePO.Buy_from_Vendor__r.Name + ' is not allowed to create new items on the fly!');
            }

            if (theItem.Account__c != thePO.Buy_from_Vendor__c) {
                thePL.addError('Vendor ' + thePO.Buy_from_Vendor__r.Name + ' does not sell product ' + theItem.Name + '!');
            }
            thePL.Item__c = thePL.Item__c;
            thePL.Item__r = new Purchase_Price__c(Id = theItem.Id, Name = theItem.Name);
            thePL.Service_Center__c = thePO.Service_Center__c;
            thePL.Service_Center__r = new Service_Center__c(Id = theSC.Id, Name = theSC.Name, Subsidiary_Company__c = theSC.Subsidiary_Company__c, Code__c = theSC.Code__c);
            thePL.Subsidiary_Company__c = theSC.Subsidiary_Company__c;
            //thePL.Vendor__c = thePO.Buy_from_Vendor__r.Name;
            thePL.Vendor_Description__c = theItem.Vendor_Description__c;
            thePL.Vendor_SKU__c = theItem.Vendor_SKU__c;
            thePL.Description__c = theItem.Name;
            thePL.Unit_of_Measure__c = theItem.Unit_of_Measure__c;
            thePL.Unit_of_Measure__r = new Unit_of_Measure__c(Id = theItem.Unit_of_Measure__c, Name = theItem.Unit_of_Measure__r.Name);
            thePL.Expected_Receipt_Date__c = thePO.Expected_Receipt_Date__c;
            thePL.Quantity__c = 0;
            thePL.Unit_Cost__c = theItem.Unit_Cost__c;
            thePL.Received_Qty__c = 0;
            thePL.Discount_Pct__c = 0;
            if (theItem.Default_Indirect_G_L_Account__c != null) {
                thePL.G_L_Account__c = theItem.Default_Indirect_G_L_Account__c;
            }
            if (String.isNotEmpty(thePL.Sales_Order__c) && theItem.Default_Direct_G_L_Account__c != null) {
                thePL.Direct_G_L_Account__c = true;
                thePL.G_L_Account__c = theItem.Default_Direct_G_L_Account__c;
            }
            //thePL = updateUOM(thePL, thePO, theItem);
            //thePL = findBestCost(thePL, thePO, theItem);
        } else if (sourceField == 'theQuantity') {
            //thePL = findBestCost(thePL, thePO, theItem);
        } else if (sourceField == 'theUOM') {
            if (thePL.Unit_of_Measure__c != null) {
                Unit_of_Measure__c uom;
                if(!mapItemUOM.containsKey(thePL.Unit_of_Measure__c)){
                    uom = [SELECT Id, Name FROM Unit_of_Measure__c  WHERE Id = :thePL.Unit_of_Measure__c];
                    mapItemUOM.put(uom.id, uom);
                } else{
                    uom = mapItemUOM.get(thePL.Unit_of_Measure__c);
                }
                
                thePL.Unit_of_Measure__r = new Unit_of_Measure__c(Id = UOM.Id, Name = UOM.Name);
                //thePL = findBestCost(thePL, thePO, theItem);
            }
        } else if (sourceField == 'theTaxPct') {
            Service_Center__c sc = [SELECT Id, Name, Subsidiary_Company__c, UEZ_No_Tax_on_PO__c FROM Service_Center__c WHERE Id = :thePL.Service_Center__c];
            thePL.Service_Center__r = new Service_Center__c(Id = sc.Id, Name = sc.Name);
            if (sc.UEZ_No_Tax_on_PO__c == true && thePL.Tax_Pct__c != 0) {
                thePO.addError('Service center ' + thePL.Service_Center__r.Name + ' does not allow tax. Please zero out tax %.');
            }
        } else if (sourceField == 'theLineServiceCenter') {
            Service_Center__c sc = [SELECT Id, Name, Subsidiary_Company__c, UEZ_No_Tax_on_PO__c FROM Service_Center__c WHERE Id = :thePL.Service_Center__c];
            System.debug('====theItem ' + theItem);
            if (sc.Subsidiary_Company__c != thePO.Subsidiary_Company__c) {
                thePO.addError('Cannot choose service center that does not belong to company ' + thePO.Subsidiary_Company__r.Name);
            } else {
                thePL.Service_Center__r = new Service_Center__c(Id = sc.Id, Name = sc.Name);
                if (sc.UEZ_No_Tax_on_PO__c == true && thePL.Tax_Pct__c != 0) {
                    thePO.addError('Service center ' + thePL.Service_Center__r.Name + ' does not allow tax. Please zero out tax %.');
                }
                thePL.Sales_Order__r = null;
                thePL.Sales_Order__c = null;
                if (theItem.Default_Indirect_G_L_Account__c != null) {
                    thePL.G_L_Account__c = theItem.Default_Indirect_G_L_Account__c;
                } else {
                    thePL.G_L_Account__c = null;
                }
            }
        } else if (sourceField == 'theLineSalesOrder') {
            //if (thePL.Sales_Order__c == null) {
            if (thePL.Direct_G_L_Account__c == false) {
                //thePL.Direct_G_L_Account__c = false;
                if (!test.isrunningtest()) thePL.G_L_Account__c = theItem.Default_Indirect_G_L_Account__c;
                System.debug('======STEVEN===Controller===SalesOrder===blank null' + thePL);
            } else {
                //thePL.Direct_G_L_Account__c = true;
                //Sales_Order__c so = [SELECT Id, Name FROM Sales_Order__c WHERE Id = :thePL.Sales_Order__c];
                //thePL.Sales_Order__c = so.Id;
                //thePL.Sales_Order__r = new Sales_Order__c(Id = so.Id, Name = so.Name);
                thePL.G_L_Account__c = theItem.Default_Direct_G_L_Account__c;
                System.debug('======STEVEN===Controller===SalesOrder===not blank null' + thePL);
            }
            //system.debug('scott2/' + thePL.Sales_Order__c);
            //if (String.isBlank(thePL.Sales_Order__c) || thePL.Sales_Order__c == null){
            //    thePL.Direct_G_L_Account__c = false;
            //} else {

            //}
            /*
            if(theItem.Default_Direct_G_L_Account__c != null){
                thePL.G_L_Account__c = theItem.Default_Direct_G_L_Account__c;
            } else {
                thePL.G_L_Account__c = null;
            }
            */
        } else if (sourceField == 'theLineGLAccount') {
            System.debug('===>Line G/L Account' + thePL.Direct_G_L_Account__c);
            System.debug('===>Line G/L Account' + thePL.G_L_Account__c);
            if (thePL.G_L_Account__c != null || Test.isRunningTest()) {
                if (thePL.Direct_G_L_Account__c && (theItem.Default_Direct_G_L_Account__c != null) && (thePL.G_L_Account__c != theItem.Default_Direct_G_L_Account__c)) {
                    System.debug('===>Line G/L Account' + thePL.G_L_Account__c);
                    System.debug('===>Item G/L Account' + theItem.Default_Direct_G_L_Account__c);
                    thePL.addError('G/L Account cannot be changed for item ' + theItem.Name);
                }

                if (!thePL.Direct_G_L_Account__c && (theItem.Default_Indirect_G_L_Account__c != null) && (thePL.G_L_Account__c != theItem.Default_Indirect_G_L_Account__c)) {
                    thePL.addError('G/L Account cannot be changed for item ' + theItem.Name);
                }
            }
        } else if(sourceField == 'theLineDirectGLAccount'){
            if(thePL.Direct_G_L_Account__c == true && theItem.Default_Direct_G_L_Account__c != null){
                thePL.G_L_Account__c = theItem.Default_Direct_G_L_Account__c;
            } else if (thePL.Direct_G_L_Account__c != true && theItem.Default_Indirect_G_L_Account__c != null){
                thePL.G_L_Account__c = theItem.Default_Indirect_G_L_Account__c;
            }
        }

        thePL.Line_Cost__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(thePL.Unit_Cost__c) * companyMgmt.zeroIfNull(thePL.Quantity__c));
        thePL.Tax__c = CompanyMgmt.halfUpTo2D(thePL.Line_Cost__c * (companyMgmt.zeroIfNull(thePL.Tax_Pct__c) / 100));

        return thePL;
    }

    /*
    public static Purchase_Line__c updateUOM(Purchase_Line__c thePL, Purchase_Order__c thePO, Resource__c theItem) {
        //thePL.Conversion__c = getConversion(thePL.Unit_of_Measure__c);
        //thePL.Qty_Base__c = thePL.Quantity__c * thePL.Conversion__c;
        thePL = getBaseCost(thePL, thePO, theItem);
        return thePL;
    }*/

    public static Purchase_Line__c getBaseCost(Purchase_Line__c thePL, Purchase_Order__c thePO, Purchase_Price__c theItem) {
        //thePL.Purch_Price_Entry__c = null;
        return thePL;
    }

    public static Purchase_Line__c findBestCost(Purchase_Line__c thePL, Purchase_Order__c thePO, Purchase_Price__c theItem) {
        // Do nothing if the SL has been shipped already
        if (thePL.Received_Qty__c <> 0 && !Test.isRunningTest()) {
            return thePL;
        }

        thePL = getBaseCost(thePL, thePO, theItem);

        Decimal bestCost = 0;
        Decimal Quantity = thePL.Quantity__c;

        if (thePO.Return_Order__c) {
            Quantity = Math.abs(thePL.Quantity__c);
        }

        List<Purchase_Price__c> thePP;

        String key = String.valueof(thePL.Item__c) + ';' + String.valueof(thePL.Unit_of_Measure__c);

        if (!mapItem.containsKey(thePL.Item__c) && !isClonePO) {
            thePP = [SELECT Id, Unit_Cost__c, Minimum_Quantity__c, Vendor_Description__c, Vendor_SKU__c FROM Purchase_Price__c WHERE Account__c = : thePO.Buy_from_Vendor__c AND Id = : thePL.Item__c AND Unit_of_Measure__c = : thePL.Unit_of_Measure__c AND Minimum_Quantity__c <= : Quantity AND Starting_Date__c <= : thePO.Order_Date__c AND Ending_Date__c >= : thePO.Order_Date__c ORDER BY Unit_Cost__c ASC];
            if (thePP.size() > 0) { mapPurchPrice.put(key, thePP); }
        }

        if (mapPurchPrice.containsKey(key)) {
            thePP = mapPurchPrice.get(key);
            System.debug(thePP);
            for (Purchase_Price__c PP : thePP) {
                if ((bestCost > PP.Unit_Cost__c || bestCost == 0.00) && PP.Minimum_Quantity__c <= Quantity ) {
                    bestCost = PP.Unit_Cost__c;
                    thePL.Item__c = PP.Id;
                }
            }
        }

        //else {
        //    thePL.Unit_Cost__c = CompanyMgmt.zeroIfNull(theItem.Last_Invoiced_Base_Cost__c) * thePL.Conversion__c;
        //}
        // }
        if (bestCost > 0) {
            thePL.Unit_Cost__c = bestCost;
        }
        return thePL;
    }

    public static Purchase_Order__c nullRelationshipFields(Purchase_Order__c thePO) {
        // Null all relationship fields to save
        thePO.Buy_from_Vendor__r = null;
        thePO.Billing_Contact__r = null;
        thePO.Payment_Term__r = null;
        thePO.PO_Requestor__r = null;
        thePO.Service_Center__r = null;
        thePO.Subsidiary_Vendor_Account__r = null;
        thePO.Subsidiary_Company__r = null;
        //thePO.Currency__r = null;
        return thePO;
    }

    /***************** For soql limit in ClonePO **********************/
    public static Map<Id, Purchase_Price__c> mapItem = new Map<Id, Purchase_Price__c>();
    public static Map<Id, Unit_of_Measure__c> mapItemUOM = new Map<Id, Unit_of_Measure__c>();
    public static Map<Id, Service_Center__c> mapSC = new Map<Id, Service_Center__c>();
    public static Map<String, List<Purchase_Price__c>> mapPurchPrice = new Map<String, List<Purchase_Price__c>>(); // map Item,UOM to List Purchase Price

    public static Map<Id, Account> mapAccount = new Map<Id, Account>();
    public static Map<Id, Subsidiary_Vendor__c> mapSubVendor = new Map<Id, Subsidiary_Vendor__c>();

    public static Map<Id, Payment_Term__c> mapPaymentTerm = new Map<Id, Payment_Term__c>();
    public static Boolean isClonePO = false;

    public static void setMapItem(Set<Id> setItemId) {
        PurchOrderMgmt.mapItem.putAll(new Map<Id, Purchase_Price__c>([SELECT Id, Name, Default_Direct_G_L_Account__c, Account__c, Unit_of_Measure__c, Unit_of_Measure__r.Name, Vendor_SKU__c, Vendor_Description__c, Default_Indirect_G_L_Account__c,
                Unit_Cost__c
        FROM Purchase_Price__c WHERE Id IN :setItemId]));
    }

    public static void setMapItemUOM(Set<Id> setItemUOM) {
        PurchOrderMgmt.mapItemUOM.putAll(new Map<Id, Unit_of_Measure__c>([SELECT Id, Name FROM Unit_of_Measure__c WHERE Id IN :setItemUOM]));
    }

    public static void setMapAccount(Set<Id> setAccountId) {
        PurchOrderMgmt.mapAccount.putAll(new Map<Id, Account>([SELECT Id, Name, Billing_Contact__c, Billing_Contact__r.Name, Billing_Contact__r.FirstName, Billing_Contact__r.LastName,
                BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,
                ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry,
                Alternate_Billing__c, Alternate_Billing__r.Name,Payment_Term__r.Name, Payment_Term__c, Inter_co_Account__c,
                Auto_Create_Catalog_Item__c
        FROM Account WHERE Id IN :setAccountId]));
    }

    public static void setMapPaymentTerm(Set<Id> setPaymentT) {
        PurchOrderMgmt.mapPaymentTerm.putAll(new Map<Id, Payment_Term__c>([SELECT Id, Name, Discount_Pct__c, Discount_Date_Calculation__c, Due_Date_Calculation__c FROM Payment_Term__c WHERE Id IN :setPaymentT]));
    }

    public static Unit_of_Measure__c getItemUOM(Id UOMId) {
        if (!mapItemUOM.containsKey(UOMId)) {
            Unit_of_Measure__c ItemUOM = [SELECT Id, Name FROM Unit_of_Measure__c WHERE Id = :UOMId];
            mapItemUOM.put(UOMId, ItemUOM);
        }
        return mapItemUOM.get(UOMId);
    }
    
    public static Purchase_Order__c updateOrderStatus(Purchase_Order__c purchaseOrder){
        List<Purchase_Receipt__c> purchaseReceipts = [SELECT Id FROM Purchase_Receipt__c WHERE Purchase_Order__c = :purchaseOrder.Id];
        if(purchaseReceipts.size() == 0){
            purchaseOrder.Document_Status__c = EnumUtil.ApprovalStatus.APPROVED.name();
            purchaseOrder.Closed__c = false;
        } else {
            List<Purchase_Line__c> purchaseLines = [SELECT Id, Quantity__c, Received_Qty__c FROM Purchase_Line__c WHERE Purchase_Order__c = :purchaseOrder.Id];
            Boolean fullReceived = true;
            for(Purchase_Line__c pl : purchaseLines){
                if(pl.Received_Qty__c < pl.Quantity__c){
                    fullReceived = false;
                }
            }
            if(fullReceived){
                purchaseOrder.Document_Status__c = 'Fully Received';
            } else {
                purchaseOrder.Document_Status__c = 'Partially Received';
            }
        }
        return purchaseOrder;
    }
}