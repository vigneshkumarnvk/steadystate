global with sharing class CreatePOController {
    public  ApexPages.StandardSetController setCon;
    Set<Id> selectedProductIds;
    public List<Purchase_Price__c> selectedProductList{get;set;}
    global Company_Setup__c theCompanySetup {get; set;}
    public List<Purchase_Line__c> thePLList{get; set;}
    public Purchase_Order__c thePO;
    public String errMsg = '';
    public User theUser{get;set;}
    public static String note {get;set;}
    public List<SelectOption> ServiceCenterOptions { set; get; }
    
    global CreatePOController(ApexPages.StandardSetController controller) {
        setCon = controller;
        selectedProductIds = new Set<Id>();
        selectedProductList = new List<Purchase_Price__c>();
        for (Purchase_Price__c  theProduct : (Purchase_Price__c[])setCon.getSelected() )
        {
            selectedProductIds.add(theProduct.Id);
        }

        theCompanySetup = CompanyMgmt.getCompanySetup();

        InitServiceCenterOptions();

        selectUser();
        selectSelectedProducts();
        validateProducts();
    }
    
     global CreatePOController(ApexPages.StandardController controller) {
        
    }
    
    private void InitServiceCenterOptions() {
        this.ServiceCenterOptions = new List<SelectOption>();
        this.ServiceCenterOptions.add(new SelectOption('', '--None--'));
        for (Service_Center__c sc : [SELECT Id, Name, Description__c FROM Service_Center__c WHERE No_PO_s_Allowed__c != true ORDER BY Name]) {
            this.ServiceCenterOptions.add(new SelectOption(sc.Name, (sc.Description__c == null ? '' : sc.Description__c) + ' (' + sc.Name + ')'));
        }
    }
    
    private boolean validateProducts() {
        if (selectedProductList.size() == 0) {
            errMsg = 'Please select at least one product.'; 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, errMsg)); 
            return false;
        }
        else if(selectedProductList != null && selectedProductList.size() > 0){
            String account = selectedProductList[0].Account__c;
            for (Purchase_Price__c theProduct : selectedProductList)
            {
                if (theProduct.Account__c != account)
                {
                    errMsg = 'Please select Products of the same account.'; 
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, errMsg)); 
                    return false;
                }
            }
        } else {
            errMsg = 'Please select Products of the same account.';  
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, errMsg)); 
            return false;
        }
        
        errMsg = '';
        return true;
    }
    
    public void selectSelectedProducts() {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Purchase_Price__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        
        selectedProductList = new List<Purchase_Price__c>();
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ', Account__r.Name, Item__r.Name, Unit_of_Measure__r.Name ';
        strQuery += ' FROM Purchase_Price__c WHERE Id IN : selectedProductIds';

        selectedProductList = Database.query(strQuery);
    }

    public void selectUser() {
        theUser = [SELECT Id, FirstName, LastName, Phone, Service_Center__c FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
    }
    
    public PageReference createPO() {
        if(validateProducts()){
            if(String.isEmpty(note)){
                errMsg = 'Note field cannot be blank!'; ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errMsg));return null;
            }
            // Savepoint
            Savepoint sp = database.setSavepoint();
            try {
                if(string.isEmpty(errMsg)) {
                    thePO = new Purchase_Order__c();
                    thePO.Buy_from_Vendor__c = selectedProductList[0].Account__c;
                    thePO.Pay_to_Vendor__c = selectedProductList[0].Account__c;
                    PurchOrderMgmt.validateBuyFromVendor(thePO);
                    thePO.Document_Status__c = 'Open';
                    thePO.Note__c = note;
                    thePO.Delivery_Contact_Name__c = theUser.FirstName + ' ' + theUser.LastName;
                    thePO.Contact_Phone_No__c = theUser.Phone;
                    thePO.PO_Requestor__c = UserInfo.getUserId();
                    List<Service_Center__c> sc = [SELECT Id, Name, Subsidiary_Company__c,Code__c,State__c, Street__c,Postal_Code__c,Country__c,City__c FROM Service_Center__c WHERE Name =: theUser.Service_Center__c LIMIT 1];
                    if(!sc.isEmpty()){
                        thePO.Service_Center__c = sc[0].Id;
                        thePO.Service_Center__r = new Service_Center__c(Id = sc[0].Id, Name = sc[0].Name, Code__c = sc[0].Code__c);
                        thePO.Subsidiary_Company__c = sc[0].Subsidiary_Company__c;
                        thePO.Shipping_Street__c = sc[0].Street__c;
                        thePO.Shipping_City__c = sc[0].City__c;
                        thePO.Shipping_State__c = sc[0].State__c;
                        thePO.Shipping_Postal_Code__c = sc[0].Postal_Code__c;
                        thePO.Shipping_Country__c = sc[0].Country__c;
                    }

                    List<Subsidiary_Vendor__c> subVendor = [SELECT Id,Payment_Term__c FROM Subsidiary_Vendor__c WHERE Subsidiary_Company__c =: sc[0].Subsidiary_Company__c AND Account__c =: thePO.Buy_from_Vendor__c];
                    if (!subVendor.isEmpty()){
                        thePO.Subsidiary_Vendor_Account__c = subVendor[0].Id;
                        thePO.Payment_Term__c = subVendor[0].Payment_Term__c;
                    }

                    thePO.Id = null;
                    thePO = PurchOrderMgmt.nullRelationshipFields(thePO);
                    insert thePO;

                    Purchase_Line__c thePL;

                    if(selectedProductList.size() > 0) {
                        Integer i = 0;
                        thePLList = new List<Purchase_Line__c>();
                        for(Purchase_Price__c thePP : selectedProductList) {
                            i = i + 1;
                            thePL = new Purchase_Line__c();
                            thePL.Description__c = thePP.Name;
                            thePL.Vendor_Description__c = thePP.Vendor_Description__c;
                            thePL.Vendor_SKU__c = thePP.Vendor_SKU__c;
                            thePL.Direct_G_L_Account__c = false;
                            thePL.G_L_Account__c = thePP.Default_Indirect_G_L_Account__c;
                            thePL.Item__c = thePP.Id;
                            thePL.Purchase_Order__c = thePO.Id;
                            thePL.Line_No__c = i;
                            thePL.Quantity__c = thePP.Minimum_Quantity__c;
                            thePL.Received_Qty__c = 0;
                            thePL.Vendor_Account__c = thePO.Buy_from_Vendor__c;
                            thePL.Subsidiary_Company__c = thePO.Subsidiary_Company__c;
                            thePL.Service_Center__c = thePO.Service_Center__c;
                            thePL.Unit_Cost__c = thePP.Unit_Cost__c;
                            thePL.Unit_of_Measure__c = thePP.Unit_of_Measure__c;
                            thePL.Line_Cost__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(thePL.Unit_Cost__c) * companyMgmt.zeroIfNull(thePL.Quantity__c));
                            thePL.Tax__c = CompanyMgmt.halfUpTo2D(thePL.Line_Cost__c * (companyMgmt.zeroIfNull(thePL.Tax_Pct__c) / 100));
                            thePLList.add(thePL);
                        }
                        insert thePLList;
                    }
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, errMsg)); return null;
                }

                PageReference POPage = new PageReference('/' + thePO.Id);
                POPage.setRedirect(true);
                return POPage;
            } catch (exception e) {
                // Rollback
                Database.rollback(sp); ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage()));
            }
        }
        return null;
    }
    
    public pagereference returnBack() {
        PageReference PCPage = new PageReference('/a1S');
        PCPage.setRedirect(true);
        return PCPage;
    }
}