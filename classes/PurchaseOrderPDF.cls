public with sharing class PurchaseOrderPDF {
    //private final Purchase_Order__c objPO {get;set;}
    public ApexPages.StandardController sController;
    public Purchase_Order__c thePO {get; set;}
    public List<Purchase_Line__c> thePLList {get; set;}
    public Company_Setup__c theCompanySetup {get; set;}
    private String POId;
    public Decimal totalDiscount {get; set;}
    public Decimal subtotal {get; set;}
    public Decimal totalTax {get; set;}
    public Decimal totalAmount {get; set;}
    public Decimal totalAmtInclTax {get; set;}
    public Decimal taxAmount {get; set;}
    public Decimal freightAmount { get; set; }
    public String createdByName {get; set;}
    public String approvedByName { get; set; }
    public String shippingName {get; set;}
    public String docTitle {get; set;}

    public PurchaseOrderPDF(ApexPages.StandardController controller) {
//        String Message;
//        if (!Message.contains('Insufficient read access to')) {
            sController = controller;
            //this.objPO = (Purchase_Order__c)controller.getRecord();
            POId = ApexPages.CurrentPage().getParameters().get('id');
            theCompanySetup = CompanyMgmt.getCompanySetup();

            selectPO();

            if ((thePO.Document_Status__c == 'Open') || (thePO.Document_Status__c == 'Pending Approval')){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.WARNING, 'Cannot print document before order is approved!'));
                thePO = null;
            } else {
                ApexPages.currentPage().getHeaders().put('content-disposition', 'inline; filename=' + thePO.Name + '.pdf');
                selectPLList();
            }
//        } else {
//            Message += 'You must fix permissions before continue.';
//            //throw new myexception(Message);
//        }
    }

    private void selectPO() {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Purchase_Order__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Billing_Contact__r.Name,Pay_to_Vendor__r.Name, Buy_from_Vendor__r.Name,Buy_from_Vendor__r.Phone,Buy_from_Vendor__r.E_Mail__c,Buy_from_Vendor__r.Federal_ID_No__c,' +
                    'Payment_Term__r.Name, PO_Requestor__r.Name, Subsidiary_Company__r.Name, Service_Center__r.Name,Service_Center__r.Description__c,Service_Center__r.Street__c, Service_Center__r.City__c,' +
                'Service_Center__r.State__C, Service_Center__r.Country__c, Service_Center__r.Postal_Code__c,Subsidiary_Company__r.Display_Name__c,Subsidiary_Vendor_Account__r.Billing_Street__c,' +
                'Subsidiary_Vendor_Account__r.Billing_City__c,Subsidiary_Vendor_Account__r.Billing_State__c,Subsidiary_Vendor_Account__r.Billing_Postal_Code__c,' +
                'Subsidiary_Vendor_Account__r.Phone__c,Service_Center__r.Phone__c,Billing_Contact__r.Email';
        strQuery += ' FROM Purchase_Order__c WHERE Id =: POId';
        thePO = Database.query(strQuery);
        freightAmount = companyMgmt.zeroIfNull(thePO.Estimated_Freight_Amount__c);
        totalDiscount = thePO.Order_Discount__c.setScale(2, RoundingMode.HALF_UP);        
        totalAmount = thePO.Order_Cost__c.setScale(2, RoundingMode.HALF_UP);
        totalAmtInclTax = thePO.Order_Cost_Incl_Tax__c.setScale(2, RoundingMode.HALF_UP) + freightAmount;
        taxAmount = thePO.Order_Tax_Amount__c.setScale(2, RoundingMode.HALF_UP);
        User createdBy = [SELECT Id, Name FROM User WHERE Id =: thePO.OwnerId LIMIT 1];
        createdByName = createdBy.Name;
        approvedByName = thePO.Pending_Approval_From__c;
        shippingName = theCompanySetup.Name;
    }

    private void selectPLList() {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Purchase_Line__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Item__r.Name,Unit_of_Measure__r.Name,Service_Center__r.Name, Sales_Order__r.Name' ;
        strQuery += ' FROM Purchase_Line__c WHERE Purchase_Order__c =: POId ORDER BY Line_No__c ';
        thePLList = Database.query(strQuery);

        for (Purchase_Line__c objPL : thePLList) {
            objPL.Unit_Cost__c = setScale(objPL.Unit_Cost__c);
            objPL.Discount__c = setScale(objPL.Discount__c);
            objPL.Line_Cost__c = setScale(objPL.Line_Cost__c);
        }
    }

    private Decimal setScale(Decimal val) {
        if (val != null) {
            return val.setScale(2, RoundingMode.HALF_UP);
        }
        return val;
    }

}