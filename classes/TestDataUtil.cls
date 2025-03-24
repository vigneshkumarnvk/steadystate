public class TestDataUtil {
    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    public static User UserRec = [SELECT Id, FirstName, LastName, Phone, Service_Center__c FROM User WHERE Id = : UserInfo.getUserId() LIMIT 1];

    public static Account AccountRecord {
        get{
            if (AccountRecord == null) {
                AccountRecord = new Account();
                AccountRecord.Name = 'Cannon Group 3';
                AccountRecord.AccountNumber = '01-1231232';
                AccountRecord.BillingStreet = '123 ABC Street';
                AccountRecord.BillingCity = 'New York';
                AccountRecord.BillingStateCode = 'NY';
                AccountRecord.BillingPostalCode = '10002';
                AccountRecord.BillingCountryCode = 'US';
                AccountRecord.Customer_Type__c = 'AUTOMOBILE';
                //AccountRecord.Account_Executive__c = SalespersonRecord.Id;
                AccountRecord.Subsidiary_Company__c = SubsidiaryCompanyRecord.Id;
                //AccountRecord.Service_Center__c = ServiceCenterRecord.Id;
                AccountRecord.Estimated_Amount__c = 100000;
                AccountRecord.PO_Number_Type__c = 'ALPHANUMERICAL';
                AccountRecord.Invoice_Email_Contact_Types__c = 'BILLING';
                AccountRecord.Invoice_Backup_Documents__c = 'Invoice';
                AccountRecord.Invoice_Submission_Channels__c = 'EMAIL';
                //AccountRecord.Name = generateRandomString(10);
                AccountRecord.Payment_Term__c = PaymentTermRecord.Id;
                AccountRecord.Tax_Area__c = TaxAreaRecord.Id;
                AccountRecord.Auto_Create_Catalog_Item__c = true;
                //AccountRecord.Shipping_Agent__c = ShippingAgentRecord.Id;
                //AccountRecord.Billing_Contact__c = ContactRecord.Id;
                AccountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
                insert AccountRecord;

                //AccountRecord.Billing_Contact__c = Contact2Record.Id;
                //update AccountRecord;
                List<Account> theAccList = [SELECT Id From Account WHERE Id = : AccountRecord.Id];
                System.assertEquals(theAccList.size(), 1);
            }
            return AccountRecord;
        }
        private set;

    }

    public static Account corporateAccountRecord{
        get{
            if(corporateAccountRecord == null){
                corporateAccountRecord = new Account();
                corporateAccountRecord.Name = 'Cannon Corporate';
                corporateAccountRecord.AccountNumber = 'C-03123123';
                corporateAccountRecord.Type = 'Corporate';
                corporateAccountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Corporate').getRecordTypeId();
                insert corporateAccountRecord;
            }
            return corporateAccountRecord;
        }

        private set;
    }

    public static Account customerAccountRecord {
        
        get{
            if (customerAccountRecord == null) {
                customerAccountRecord = new Account();
                customerAccountRecord.Name = 'Cannon Group';
                customerAccountRecord.AccountNumber = '01-00000001';
                customerAccountRecord.Payment_Term__c = PaymentTermRecord.Id;
                customerAccountRecord.Tax_Area__c = TaxAreaRecord.Id;
                customerAccountRecord.BillingStreet = 'test Street';
                customerAccountRecord.Billingcity = 'test City';
                customerAccountRecord.BillingState = 'Colorado';
                customerAccountRecord.BillingStateCode = 'CO';
                customerAccountRecord.BillingCountryCode = 'US';
                customerAccountRecord.Billingpostalcode = 'test postalcode';
                customerAccountRecord.Customer_Type__c = 'UTILITIES';
                customerAccountRecord.Account_Executive__c = SalespersonRecord.id;
                customerAccountRecord.Salesperson__c = SalespersonRecord.id;
                customerAccountRecord.Subsidiary_Company__c = subsidiarycompanyRecord.id;
                customerAccountRecord.Parent = corporateAccountRecord;
                customerAccountRecord.ParentId = corporateAccountRecord.Id;
                customerAccountRecord.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
                insert customerAccountRecord;
                List<Account> theAccList = [SELECT Id From Account WHERE Id = : customerAccountRecord.Id];
                System.assertEquals(theAccList.size(), 1);
            }
            return customerAccountRecord;
        }
        private set;
    }

    public static Account customerAccountRecord2 {

        get{
            if (customerAccountRecord2 == null) {
                customerAccountRecord2 = new Account();
                customerAccountRecord2.Name = 'Account 2';
                customerAccountRecord2.AccountNumber = '01-00000002';
                customerAccountRecord2.Payment_Term__c = PaymentTermRecord.Id;
                customerAccountRecord2.Tax_Area__c = TaxAreaRecord.Id;
                customerAccountRecord2.BillingStreet = '1 Main';
                customerAccountRecord2.Billingcity = 'Cranford';
                customerAccountRecord2.BillingState = 'New York';
                customerAccountRecord2.BillingStateCode = 'NY';
                customerAccountRecord2.BillingCountryCode = 'US';
                customerAccountRecord2.Billingpostalcode = '11220';
                customerAccountRecord2.Customer_Type__c = 'UTILITIES';
                customerAccountRecord2.Account_Executive__c = SalespersonRecord.id;
                customerAccountRecord2.Salesperson__c = SalespersonRecord.id;
                customerAccountRecord2.Subsidiary_Company__c = subsidiarycompanyRecord.id;
                customerAccountRecord2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
                insert customerAccountRecord2;
            }
            return customerAccountRecord2;
        }
        private set;
    }

    public static Salesperson__c SalespersonRecord {
        get{
            if (SalespersonRecord == null) {
                SalespersonRecord = new Salesperson__c();
                SalespersonRecord.Name = 'London Postmaster';
                SalespersonRecord.Account_Executive__c = true;
                SalespersonRecord.First_Name__c = 'firstname';
                SalespersonRecord.Last_Name__c = 'lastname';
                SalespersonRecord.Status__c = 'Active';
                SalespersonRecord.Salesperson_Code__c = 'HOU';
                SalespersonRecord.User__c = userinfo.getuserid();
                insert SalespersonRecord ;
            }
            return SalespersonRecord ;
        }
        private set;
    }

    public static Account Account2Record {
        get{
            if (Account2Record == null) {
                Account2Record = new Account();
                Account2Record.Name = 'London Postmaster';
                Account2Record.AccountNumber = '01-1231231';
                Account2Record.Payment_Term__c = PaymentTermRecord.Id;
                Account2Record.Tax_Area__c = TaxAreaRecord.Id;
                insert Account2Record ;
                List<Account> theAccList = [SELECT Id From Account WHERE Id = : Account2Record.Id];
                System.assertEquals(theAccList.size(), 1);
            }
            return Account2Record ;
        }
        private set;
    }

    public static Account VendorAccount {
        get{
            if (VendorAccount == null) {
                VendorAccount = new Account();
                VendorAccount.Name = 'London Postmaster';
                VendorAccount.Type = 'Vendor';
                VendorAccount.Payment_Term__c = PaymentTermRecord.Id;
                VendorAccount.Auto_Create_Catalog_Item__c = true;
                insert VendorAccount ;
                List<Account> theAccList = [SELECT Id From Account WHERE Id = : VendorAccount.Id];
                System.assertEquals(theAccList.size(), 1);
            }
            return VendorAccount ;
        }
        private set;
    }

    public static Subsidiary_Vendor__c SubsidiaryVendorAccount {
        get {
            if (SubsidiaryVendorAccount == null) {
                SubsidiaryVendorAccount = new Subsidiary_Vendor__c(Name = 'ACV0001', Subsidiary_Company__c = SubsidiaryCompanyRecord.Id, Account__c = VendorAccount.Id);
                insert SubsidiaryVendorAccount;
            }
            return SubsidiaryVendorAccount;
        }
        private set;
    }

    public static Purchase_Order__c PORecord {
        get {
            if (PORecord == null) {

                //Subsidiary_Company__c subCompany = new Subsidiary_Company__c(Name = 'ACV Test');
                //insert subCompany;
                Subsidiary_Company__c subCompany = SubsidiaryCompanyRecord;

                /*
                Account ac = new Account( Name = 'MDN',
                        Type = 'Vendor',
                        RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId()
                );
                insert ac;
                */
                Account ac = VendorAccount;

                Contact billingContact = new Contact(AccountId = ac.Id, LastName = 'MDN', Email = 'example@example.com', Contact_Type__c = 'Billing');
                insert billingContact;

                /*
                Subsidiary_Vendor__c subVend = new Subsidiary_Vendor__c(Name = 'ACV0001', Subsidiary_Company__c = subCompany.Id, Account__c = ac.Id);
                insert subVend;
                */
                
                PORecord = new Purchase_Order__c(
                    Name = 'test',
                    Buy_from_Vendor__c = ac.Id,
                    Pay_to_Vendor__c = ac.Id,
                    //Currency__c = CurrencyRecord.Id,
                    Payment_Term__c = PaymentTermRecord.Id,
                    Order_date__c = Date.Today(),
                    Service_Center__c = ServiceCenterRecord.Id,
                    Billing_Contact__c = billingContact.Id,
                    Document_Status__c = 'Open',
                    Order_Type__c = 'Regular',
                    Note__c = 'Test',
                    PO_Requestor__c = UserInfo.getUserId(),
                    OwnerId = UserInfo.getUserId(),
                    //Approval_Status__c = '1'
                    Ship_To_Address__c = ShiptoAddressRecord.Id,
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                    //Subsidiary_Vendor_Account__c = subVend.Id
                    Subsidiary_Vendor_Account__c = SubsidiaryVendorAccount.Id,
                    Coupa_Id__c = '1111'
                );
                insert PORecord;
            }
            return PORecord;
        }
        private set;
    }

    public static Purchase_Line__c PurchLineRecord {
        get {
            if (PurchLineRecord == null) {
                PurchLineRecord = new Purchase_Line__c(
                    Purchase_Order__c = PORecord.Id,
                    Quantity__c = 2,
                    Item__c = ProductCatalogRecord.Id,
                    //Qty_Base__c = 2,
                    //Conversion__c = 1,
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Received_Qty__c = 1,
                    //Received_Qty_Base__c = 1,
                    //Invoiced_Qty__c = 0,
                    Unit_Cost__c = 20,
                    Line_Cost__c = 40,
                    Qty_to_Receive__c = 0,
                    G_L_Account__c = '55500',
                    Expected_Receipt_Date__c = Date.Today().addDays(7),
                    //Line_No__c = 10
                    Service_Center__c = ServiceCenterRecord.Id,
                    Direct_G_L_Account__c = true,
                    Vendor_Account__c = VendorAccount.Id,
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id
                );
                insert PurchLineRecord;
            }
            return PurchLineRecord;
        }
        private set;
    }

    public static List<Purchase_Line__c> PurchLineRecords {
        get {
            if (PurchLineRecords == null) {
                PurchLineRecords = new List<Purchase_Line__c>();
                PurchLineRecords.add(new Purchase_Line__c(
                    Purchase_Order__c = PORecord.Id,
                    Sales_Order__c = SalesOrderRecord.Id,
                    Quantity__c = 2,
                    Item__c = ProductCatalogRecord.Id,
                    //Qty_Base__c = 2,
                    //Conversion__c = 1,
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Received_Qty__c = 1,
                    //Received_Qty_Base__c = 1,
                    //Invoiced_Qty__c = 0,
                    Unit_Cost__c = 20,
                    Line_Cost__c = 40,
                    Qty_to_Receive__c = 1,
                    G_L_Account__c = '55500',
                    Expected_Receipt_Date__c = Date.Today().addDays(7),
                    //Line_No__c = 10,
                    Service_Center__c = ServiceCenterRecord.Id,
                    Direct_G_L_Account__c = true,
                    Vendor_Account__c = VendorAccount.Id, //AccountRecord.Id,
                    Vendor_Description__c = 'Test Item',
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id
                ));

                PurchLineRecords.add(new Purchase_Line__c(
                    Purchase_Order__c = PORecord.Id,
                    Sales_Order__c = SalesOrderRecord.Id,
                    Quantity__c = 2,
                    Item__c = NewProductCatalogRecord.Id,
                    //Qty_Base__c = 2,
                    //Conversion__c = 1,
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Received_Qty__c = 1,
                    //Received_Qty_Base__c = 1,
                    //Invoiced_Qty__c = 0,
                    Unit_Cost__c = 20,
                    Line_Cost__c = 40,
                    Qty_to_Receive__c = 0,
                    Expected_Receipt_Date__c = Date.Today().addDays(7),
                    //Line_No__c = 10
                    Service_Center__c = ServiceCenterRecord.Id,
                    G_L_Account__c = '55500',
                    Direct_G_L_Account__c = true,
                    Vendor_Account__c = VendorAccount.Id, //AccountRecord.Id,
                    Vendor_Description__c = 'Test Item',
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id
                ));
                insert PurchLineRecords;
            }
            return PurchLineRecords;
        }
        private set;
    }


    public static Unit_of_Measure__c UnitMeasureRecord {
        get {
            if (UnitMeasureRecord == null) {
                List<Unit_of_Measure__c> uoms = [SELECT Id, Name FROM Unit_of_Measure__c WHERE Name = 'Day'];
                if (uoms.size() > 0) {
                    UnitMeasureRecord = uoms[0];
                }
                else {
                    UnitMeasureRecord = new Unit_of_Measure__c( Name = 'Day',  Description__c = 'Day', Hours_UOM__c = false );
                    insert UnitMeasureRecord;
                }
            }
            return UnitMeasureRecord;
        }
        private set;
    }

    public static Unit_of_Measure__c HRUnitMeasureRecord {
        get {
            if (HRUnitMeasureRecord == null) {
                List<Unit_of_Measure__c> uoms = [SELECT Id, Name FROM Unit_of_Measure__c WHERE Name = 'HR'];
                if (uoms.size() > 0) {
                    HRUnitMeasureRecord = uoms[0];
                }
                else {
                    HRUnitMeasureRecord = new Unit_of_Measure__c( Name = 'HR',  Description__c = 'Hours', Hours_UOM__c = true );
                    insert HRUnitMeasureRecord;
                }
            }
            return HRUnitMeasureRecord;
        }
        private set;
    }

    public static Payment_Term__c PaymentTermRecord {
        get {
            if (PaymentTermRecord == null) {
                PaymentTermRecord = new Payment_Term__c(
                    Name = '14 DAYS',
                    Discount_Pct__c = 0,
                    Discount_Date_Calculation__c = 0,
                    Due_Date_Calculation__c = 0
                );
                insert PaymentTermRecord;
            }
            return PaymentTermRecord;
        }
        private set;
    }

    public static Tax_Area__c TaxAreaRecord {
        get{
            if (TaxAreaRecord == null) {
                TaxAreaRecord = new Tax_Area__c ();
                TaxAreaRecord.Name = 'NJ';
                TaxAreaRecord.Sales_Tax_Account__c = GLAccountRecord.id;
                insert TaxAreaRecord;
            }
            return TaxAreaRecord ;
        }
        private set;
    }

    public static Tax_Jurisdiction__c TaxJurisdictionRecord {
        get{
            if (TaxJurisdictionRecord == null) {
                TaxJurisdictionRecord = new Tax_Jurisdiction__c();
                TaxJurisdictionRecord.Name = 'NJ';
                TaxJurisdictionRecord.Tax_Area__c = TaxAreaRecord.Id;
                insert TaxJurisdictionRecord;
            }
            return TaxJurisdictionRecord;
        }
        private set;
    }

    public static Tax_Detail__c TaxDetailRecord {
        get{
            if (TaxDetailRecord == null) {
                TaxDetailRecord = new Tax_Detail__c();
                TaxDetailRecord.Name = 'NJ';
                TaxDetailRecord.Tax_Area__c = TaxAreaRecord.Id;
                TaxDetailRecord.Tax_Jurisdiction__c = TaxJurisdictionRecord.Id;
                TaxDetailRecord.Tax_Group__c = 'TX';
                TaxDetailRecord.Tax_Pct__c = 0.625;
                insert TaxDetailRecord;
            }
            return TaxDetailRecord;
        }
        private set;
    }

    public static Currency__c CurrencyRecord {
        get {
            if (CurrencyRecord == null) {
                CurrencyRecord = new Currency__c(
                    Name = 'USD'
                );
                insert CurrencyRecord;
            }
            return CurrencyRecord;
        }
        private set;
    }

    public static Contact Contact2Record {
        get{
            if (Contact2Record == null) {
                Contact2Record = new Contact();
                Contact2Record.FirstName = 'John';
                Contact2Record.LastName = 'Smith';
                Contact2Record.MailingStreet = '123 ABC Ave' + '\n' + 'Suite 123';
                Contact2Record.MailingStateCode = 'NY';
                Contact2Record.MailingState = 'New York';
                Contact2Record.MailingCity = 'New York';
                Contact2Record.MailingCountry = 'United States';
                Contact2Record.MailingCountryCode = 'US';
                Contact2Record.MailingPostalCode = '10002';
                Contact2Record.Contact_Type__c = 'Site;Quote;Billing;Purchase;Executive;Sales';
                Contact2Record.Email = 'test@test.com';
                Contact2Record.AccountId = AccountRecord.Id;
                insert Contact2Record;
            }
            return Contact2Record;
        }
        private set;
    }

    public static Numbering_Series__c NumberingSeriesRecord {
        get {
            if (NumberingSeriesRecord == null) {
                NumberingSeriesRecord = new Numbering_Series__c(
                    Name = 'SO',
                    Prefix__c = 'SO',
                    Separator__c = '-',
                    Last_Number_Used__c = 10000
                );
                insert NumberingSeriesRecord;
            }
            return NumberingSeriesRecord;
        }
        private set;
    }

    public static Company_Setup__c CompanySetupRecord {
        get {
            if (CompanySetupRecord == null) {
                CompanySetupRecord = new Company_Setup__c(
                    //Name = userinfo.getOrganizationname(),
                    Name = 'Default',
                    //Days_to_Receive__c = 7,
                    //Days_to_Ship__c = 2,
                    Lines_to_Insert__c = 5,
                    //Lot_Days_to_Expire__c = 365,
                    //Payment_Term__c = PaymentTermRecord.Id,
                    //Warehouse__c = WarehouseRecord.Id,
                    //Currency__c = CurrencyRecord.Id,
                    Allow_Posting_From__c = Date.newInstance(2015, 1, 1),
                    Allow_Posting_To__c = Date.newInstance(2019, 1, 1),
                    //Account_AP__c = GLAccountRecord.Id,
                    //Account_AR__c = GLAccountRecord.Id,
                    //Account_Capacity_Expense__c = GLAccountRecord.Id,
                    //Account_Capacity_Variance__c = GLAccountRecord.Id,
                    //Account_COGS__c = GLAccountRecord.Id,
                    //Account_Finished_Good_Inventory__c = GLAccountRecord.Id,
                    //Account_Inventory_Adjustment__c = GLAccountRecord.Id,
                    //Account_Material_Variance__c = GLAccountRecord.Id,
                    //Account_Purchase_Price_Variance__c = GLAccountRecord.Id,
                    //Account_Sales__c = GLAccountRecord.Id,
                    //Account_WIP_Inventory__c = GLAccountRecord.Id,
                    //Account_Sales_Tax_Payable__c = GLAccountRecord.Id,
                    //Account_Raw_Material_Inventory__c = GLAccountRecord.Id,
                    //Account_Purchase__c = GLAccountRecord.Id,
                    //Account_Sales_Discount__c = GLAccountRecord.Id,
                    //Fiscal_Year_Type__c = '445',
                    //Fiscal_Year_Start_Month__c = 'April',
                    //Fiscal_Start_Date__c = Date.ValueOf('2017-09-01')
                    Company_Pay_Rule__c = companyPayRuleRecord.Id
                );
                insert CompanySetupRecord;

                Numbering_Series__c theNS;
                List<Numbering_Series__c> theNSList = new List<Numbering_Series__c>();

                theNS = new Numbering_Series__c();
                theNS.Name = 'JOB01';
                theNS.Prefix__c = 'NJ';
                theNS.Separator__c = '-';
                theNS.Last_Number_Used__c = 1000000;
                theNSList.add(theNS);

                theNS = new Numbering_Series__c();
                theNS.Name = 'PO Temp Number';
                theNS.Prefix__c = 'PO';
                theNS.Separator__c = '-';
                theNS.Last_Number_Used__c = 1000000;
                theNSList.add(theNS);

                theNS = new Numbering_Series__c();
                theNS.Name = 'Purchase Order';
                theNS.Prefix__c = 'PO';
                theNS.Separator__c = '-';
                theNS.Last_Number_Used__c = 1000000;
                theNSList.add(theNS);

                theNS = new Numbering_Series__c();
                theNS.Name = 'Purchase Receipt';
                theNS.Prefix__c = 'PR';
                theNS.Separator__c = '-';
                theNS.Last_Number_Used__c = 1000000;
                theNSList.add(theNS);

                theNS = new Numbering_Series__c();
                theNS.Name = 'Return Purchase Order';
                theNS.Prefix__c = 'PRO';
                theNS.Separator__c = '-';
                theNS.Last_Number_Used__c = 1000000;
                theNSList.add(theNS);

                theNS = new Numbering_Series__c();
                theNS.Name = 'Sales Invoice';
                theNS.Prefix__c = 'SI';
                theNS.Separator__c = '-';
                theNS.Last_Number_Used__c = 1000000;
                theNSList.add(theNS);

                theNS = new Numbering_Series__c();
                theNS.Name = 'Credit Memo';
                theNS.Prefix__c = 'CR';
                theNS.Separator__c = '-';
                theNS.Last_Number_Used__c = 1000000;
                theNSList.add(theNS);

                theNS = new Numbering_Series__c();
                theNS.Name = 'Sales Order';
                theNS.Prefix__c = 'SO';
                theNS.Separator__c = '-';
                theNS.Last_Number_Used__c = 1000000;
                theNSList.add(theNS);

                theNS = new Numbering_Series__c();
                theNS.Name = 'SC01 TM No.';
                theNS.Prefix__c = 'TMEL';
                theNS.Separator__c = '-';
                theNS.Last_Number_Used__c = 1000000;
                theNSList.add(theNS);

                theNS = new Numbering_Series__c();
                theNS.Name = 'T&M';
                theNS.Prefix__c = 'TM';
                theNS.Separator__c = '-';
                theNS.Last_Number_Used__c = 1000000;
                theNSList.add(theNS);

                theNS = new Numbering_Series__c();
                theNS.Name = 'Timesheet';
                theNS.Prefix__c = 'T';
                theNS.Separator__c = '-';
                theNS.Last_Number_Used__c = 1000000;
                theNSList.add(theNS);

                theNS = new Numbering_Series__c();
                theNS.Name = 'Payroll';
                theNS.Prefix__c = 'P';
                theNS.Separator__c = '-';
                theNS.Last_Number_Used__c = 1000000;
                theNSList.add(theNS);

                theNS = new Numbering_Series__c();
                theNS.Name = 'Contract Line';
                theNS.Prefix__c = 'CL';
                theNS.Separator__c = '-';
                theNS.Last_Number_Used__c = 1000000;
                theNSList.add(theNS);

                theNS = new Numbering_Series__c();
                theNS.Name = 'Rental Order';
                theNS.Prefix__c = 'RO';
                theNS.Separator__c = '-';
                theNS.Last_Number_Used__c = 1000000;
                theNSList.add(theNS);

                theNS = new Numbering_Series__c();
                theNS.Name = 'Contract Line';
                theNS.Prefix__c = 'CL';
                theNS.Separator__c = '-';
                theNS.Last_Number_Used__c = 1000000;
                theNSList.add(theNS);                

                insert theNSList;
                
                CompanySetupRecord.Default_Waste_Disposal_Resource__c = ResourceEquipmentRecord.Id;
                CompanySetupRecord.Default_Manifest_Fee_Resource__c = ResourceEquipmentRecord.Id;
                CompanySetupRecord.Default_Lump_Sum_Resource__c = ResourceEquipmentRecord.Id;
                CompanySetupRecord.Default_Misc_Charges_Taxes_Resource__c = ResourceEquipmentRecord.Id;
                CompanySetupRecord.Default_Subcontractor_Resource__c = ResourceEquipmentRecord.Id;
                CompanySetupRecord.Default_Transportation_Resource__c = ResourceTransportationRecord.Id;
                CompanySetupRecord.Default_Fuel_Surcharge_Resource__c = ResourceFuelRecord.Id;
                CompanySetupRecord.Default_Energy_Insurance_Resource__c = ResourceFuelRecord.Id;
                CompanySetupRecord.Default_Rental_Resource__c = ResourceRentalRecord.Id;
                CompanySetupRecord.Equipment_Inter_co_Due_from_Account__c = GLAccountRecord.Id;
                CompanySetupRecord.Labor_Inter_co_Due_from_Account__c = GLAccountRecord.Id;
                CompanySetupRecord.Equipment_Inter_co_Due_to_Account__c = GLAccountRecord.Id;
                CompanySetupRecord.Labor_Inter_co_Due_to_Account__c = GLAccountRecord.Id;
                CompanySetupRecord.Default_Billing_Rule__c = billingRule.Id;
                update CompanySetupRecord;
            }
            return CompanySetupRecord;
        }
        private set;
    }

    public static Subsidiary_Company__c SubsidiaryCompanyRecord {
        get {
            if (SubsidiaryCompanyRecord == null) {
                List<Subsidiary_Company__c> subsidiaryCompanies =
                    [SELECT Name, Display_Name__c, QtC_Enabled__c FROM Subsidiary_Company__c WHERE Name = '1-REPUBLIC SERVICES'];
                if(subsidiaryCompanies.size() > 0){
                    SubsidiaryCompanyRecord = subsidiaryCompanies[0];
                } else {
                    SubsidiaryCompanyRecord = new Subsidiary_Company__c(
                            Name = '1-REPUBLIC SERVICES',
                            Display_Name__c = 'SO',
                            QtC_Enabled__c = true
                    );
                    insert SubsidiaryCompanyRecord;
                }
            }
            return SubsidiaryCompanyRecord;
        }
        private set;
    }

    public static Resource_Type__c ResourceTypeRecord {
        get {
            if (ResourceTypeRecord == null) {
                ResourceTypeRecord = new Resource_Type__c(
                    Name = 'Field Tech',
                    Description__c = 'Field Tech',
                    Category__c = 'Labor',
                    Unit_of_Measure__c = UnitMeasureRecord.id,
                    Unit_of_Measure1__c = UnitMeasureRecord.Id,
                    Unit_of_Measure2__c = UnitMeasureRecord.Id,
                    Unit_of_Measure3__c = UnitMeasureRecord.Id,
                    Unit_of_Measure4__c = UnitMeasureRecord.Id
                );
                insert ResourceTypeRecord;
            }
            return ResourceTypeRecord;
        }
        private set;
    }

    public static Resource_Type__c ResourceTypeEquipmentRecord {
        get {
            if (ResourceTypeEquipmentRecord == null) {
                ResourceTypeEquipmentRecord = new Resource_Type__c(
                    Name = 'BOOM TRAILER',
                    Description__c = 'Boom Trailer',
                    Category__c = 'Equipment',
                    Charge_Rinse_Out_Fee__c = true,
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Unit_of_Measure1__c = UnitMeasureRecord.Id,
                    Unit_of_Measure2__c = UnitMeasureRecord.Id,
                    Unit_of_Measure3__c = UnitMeasureRecord.Id,
                    Unit_of_Measure4__c = UnitMeasureRecord.Id
                );
                insert ResourceTypeEquipmentRecord ;
            }
            return ResourceTypeEquipmentRecord ;
        }
        private set;
    }


    public static Resource_Type__c ResourceTypeLumpSumRecord {
        get {
            if (ResourceTypeLumpSumRecord == null) {
                ResourceTypeLumpSumRecord = new Resource_Type__c(
                    Name = 'Labor and Equipment Bundled',
                    Description__c = 'Labor and Equipment Bundled',
                    Category__c = 'Bundled',
                    Unit_of_Measure__c = UnitMeasureRecord.id
                );
                insert ResourceTypeLumpSumRecord  ;
            }
            return ResourceTypeLumpSumRecord ;
        }
        private set;
    }
        
    /* No material resource type
    public static Resource_Type__c ResourceTypeMaterialRecord {
        get {
            if (ResourceTypeMaterialRecord== null) {
                ResourceTypeEquipmentRecord= new Resource_Type__c(
                    Name = 'BOOM TRAILER',
                    Description__c = 'Boom Trailer',
                    Category__c='Materials',
                    Unit_of_Measure__c=UnitMeasureRecord.id
                );
                insert ResourceTypeEquipmentRecord ;
            }
            return ResourceTypeEquipmentRecord ;
        } private set;
    }

    public static Resource_Type__c ResourceTypeSubcontractorRecord {
        get {
            if (ResourceTypeSubcontractorRecord == null) {
                ResourceTypeSubcontractorRecord = new Resource_Type__c(
                    Name = 'BOOM TRAILER',
                    Description__c = 'Boom Trailer',
                    Category__c='Subcontractors'
                );
                insert ResourceTypeSubcontractorRecord;
            }
            return ResourceTypeSubcontractorRecord;
        } private set;
    } */

    public static Resource__c ResourceRecord {
        get {
            if (ResourceRecord == null) {
                ResourceRecord = new Resource__c(
                    Name = 'TRAN_1',
                    Fleet_Number__c = 'TR8',
                    Status__c = 'Active',
                    Plate_Number__c = 'TDF19Q',
                    Plate_State__c = 'NJ',
                    Make__c = 'Car Mate',
                    //Ticket 13360 >>
                    //Vehicle_Year__c = 2000,
                    //Ticket 13360 <<
                    VIN__c = '5A3U616D1YL005502',
                    Country__c = 'US',
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                    Service_Center__c = ServiceCenterRecord.Id,
                    Rent_Company__c = 'CVI',
                    Resource_Type__c = ResourceTypeRecord.Id,
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Unit_of_Measure1__c = UnitMeasureRecord.Id,
                    Unit_of_Measure2__c = UnitMeasureRecord.Id,
                    Unit_of_Measure3__c = UnitMeasureRecord.Id,
                    Unit_of_Measure4__c = UnitMeasureRecord.Id,
                    Tax_Group__c = 'NT',
                    Non_Payroll_Labor_Resource__c = false
                );
                insert ResourceRecord;
            }
            return ResourceRecord;
        }
        private set;
    }
    
    public static Resource__c ResourceTransportationRecord {
        get {
            if (ResourceTransportationRecord == null) {
                ResourceTransportationRecord = new Resource__c(
                    Name = 'TRAN2',
                    Fleet_Number__c = 'TR7',
                    Status__c = 'Active',
                    Plate_Number__c = 'TDF19P',
                    Plate_State__c = 'NJ',
                    Make__c = 'Car Mate',
                    //Ticket 13360 >>
                    //Vehicle_Year__c = 2000,
                    //Ticket 13360 <<
                    VIN__c = '5A3U616D1YL005502A',
                    Country__c = 'US',
                    Category__c = 'Demurrage',
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                    Service_Center__c = ServiceCenterRecord.Id,
                    Rent_Company__c = 'CVI',
                    Unit_of_Measure__c = UnitMeasureRecord.id,
                    RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId()
                );
                insert ResourceTransportationRecord;
            }
            return ResourceTransportationRecord;
        }
        private set;
    }

    public static Resource__c ResourceDemurrageRecord {
        get {
            if (ResourceDemurrageRecord == null) {
                ResourceDemurrageRecord = new Resource__c(
                        Name = 'DEMURRAGE',
                        Fleet_Number__c = 'TR7',
                        Status__c = 'Active',
                        Plate_Number__c = 'TDF19P',
                        Plate_State__c = 'NJ',
                        Make__c = 'Car Mate',
                        //Ticket 13360 >>
                        //Vehicle_Year__c = 2000,
                        //Ticket 13360 <<
                        VIN__c = '5A3U616D1YL005502B',
                        Country__c = 'US',
                        Category__c = 'Demurrage',
                        Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                        Service_Center__c = ServiceCenterRecord.Id,
                        Rent_Company__c = 'CVI',
                        Unit_of_Measure__c = UnitMeasureRecord.id,
                        RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId()
                );
                insert ResourceDemurrageRecord;
            }
            return ResourceDemurrageRecord;
        }
        private set;
    }

    public static Resource__c ResourceFuelRecord {
        get {
            if (ResourceFuelRecord == null) {
                ResourceFuelRecord = new Resource__c(
                    Name = 'Fuel',
                    Fleet_Number__c = 'TR7',
                    Status__c = 'Active',
                    Plate_Number__c = 'TDF19P',
                    Plate_State__c = 'NJ',
                    Make__c = 'Car Mate',
                    //Ticket 13360 >>
                    //Vehicle_Year__c = 2000,
                    //Ticket 13360 <<
                    VIN__c = '5A3U616D1YL005502C',
                    Country__c = 'US',
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                    Service_Center__c = ServiceCenterRecord.Id,
                    Rent_Company__c = 'CVI',
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId()
                );
                insert ResourceFuelRecord ;
            }
            return ResourceFuelRecord ;
        }
        private set;
    }

    public static Resource__c ResourceLaborRecord {
        get {
            if (ResourceLaborRecord == null) {
                ResourceLaborRecord = new Resource__c(
                    Name = 'TR7',
                    Fleet_Number__c = 'TR7',
                    Status__c = 'Active',
                    Plate_Number__c = 'TDF19P',
                    Plate_State__c = 'NJ',
                    Make__c = 'Car Mate',
                    //Ticket 13360 >>
                    //Vehicle_Year__c = 2000,
                    //Ticket 13360 <<
                    VIN__c = '5A3U616D1YL005502E',
                    Country__c = 'US',
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                    Service_Center__c = ServiceCenterRecord.Id,
                    Rent_Company__c = 'CVI',
                    Resource_Type__c = ResourceTypeRecord.Id,
                    Category__c = 'Labor',
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Unit_of_Measure1__c = UnitMeasureRecord.Id,
                    Unit_of_Measure2__c = UnitMeasureRecord.Id,
                    Unit_of_Measure3__c = UnitMeasureRecord.Id,
                    Unit_of_Measure4__c = UnitMeasureRecord.Id,
                    Employee_Type__c = 'Employee' ,
                    Non_Payroll_Labor_Resource__c = false
                );
                insert ResourceLaborRecord;
            }
            return ResourceLaborRecord;
        }
        private set;
    }

    public static Resource__c ResourceEquipmentRecord {
        get {
            if (ResourceEquipmentRecord == null) {
                ResourceEquipmentRecord = new Resource__c(
                    Name = 'REREquipment',
                    Category__c = 'Equipment',
                    Fleet_Number__c = 'TR7',
                    Status__c = 'Available',
                    Plate_Number__c = 'TDF19P',
                    Plate_State__c = 'NJ',
                    Make__c = 'Car Mate',
                    //Ticket 13360 >>
                    //Vehicle_Year__c = 2000,
                    //Ticket 13360 <<
                    VIN__c = '5A3U616D1YL005502F',
                    Country__c = 'US',
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                    Service_Center__c = ServiceCenterRecord.Id,
                    Rent_Company__c = 'CVI',
                    Resource_Type__c = ResourceTypeEquipmentRecord.Id,
                    Unit_of_Measure__c = UnitMeasureRecord.id,
                    RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Equipment').getRecordTypeId()
                );
                insert ResourceEquipmentRecord;
            }
            return ResourceEquipmentRecord;
        }
        private set;
    }

    public static Resource__c ResourceRentalRecord {
        get {
            if (ResourceRentalRecord == null) {
                ResourceRentalRecord = new Resource__c(
                        Name = 'RESRental',
                        Status__c = 'Active',
                        Category__c = 'Misc. Charges And Taxes',
                        Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                        Service_Center__c = ServiceCenterRecord.Id,
                        Unit_of_Measure__c = UnitMeasureRecord.id,
                        RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId()
                );
                insert ResourceRentalRecord;
            }
            return ResourceRentalRecord;
        }
        private set;
    }
    
    public static Resource__c ResourceLumpSumRecord {
        get {
            if (ResourceLumpSumRecord == null) {
                ResourceLumpSumRecord = new Resource__c(
                    Name = 'RESLumpsum',
                    Fleet_Number__c = 'TR7',
                    Status__c = 'Active',
                    Plate_Number__c = 'TDF19P',
                    Plate_State__c = 'NJ',
                    Make__c = 'Car Mate',
                    Category__c = 'Bundled',
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                    Service_Center__c = ServiceCenterRecord.Id,
                    Rent_Company__c = 'CVI',
                    Resource_Type__c = ResourceTypeLumpSumRecord.Id,
                    Unit_of_Measure__c = UnitMeasureRecord.id,
                    RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId()
                );
                insert ResourceLumpSumRecord ;
            }
            return ResourceLumpSumRecord ;
        }
        private set;
    }

    public static Resource__c ResourceMaterialRecord {
        get {
            if (ResourceMaterialRecord == null) {
                ResourceMaterialRecord = new Resource__c(
                    Name = 'RERMaterial',
                    Fleet_Number__c = 'TR7',
                    Status__c = 'Active',
                    Plate_Number__c = 'TDF19P',
                    Plate_State__c = 'NJ',
                    Make__c = 'Car Mate',
                    //Ticket 13360 >>
                    //Vehicle_Year__c = 2000,
                    //Ticket 13360 <<
                    VIN__c = '5A3U616D1YL005502G',
                    Country__c = 'US',
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                    //Service_Center__c = ServiceCenterRecord.Id,
                    Rent_Company__c = 'CVI',
                    Category__c = 'Materials',
                    //Resource_Type__c = ResourceTypeMaterialRecord.Id,
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Unit_of_Measure1__c = UnitMeasureRecord.Id,
                    Unit_of_Measure2__c = UnitMeasureRecord.Id,
                    Unit_of_Measure3__c = UnitMeasureRecord.Id,
                    Unit_of_Measure4__c = UnitMeasureRecord.Id,
                    RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Material').getRecordTypeId()
                );
                insert ResourceMaterialRecord;
            }
            return ResourceMaterialRecord;
        }
        private set;
    }

    public static Resource__c ResourceWasteDisposalRecord {
        get {
            if (ResourceWasteDisposalRecord == null) {
                ResourceWasteDisposalRecord = new Resource__c(
                    Name = 'RERWasteDisposal',
                    Fleet_Number__c = 'TR7',
                    Status__c = 'Active',
                    Plate_Number__c = 'TDF19P',
                    Plate_State__c = 'NJ',
                    Make__c = 'Car Mate',
                    //Ticket 13360 >>
                    //Vehicle_Year__c = 2000,
                    //Ticket 13360 <<
                    VIN__c = '5A3U616D1YL005502H',
                    Country__c = 'US',
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                    Service_Center__c = ServiceCenterRecord.Id,
                    Rent_Company__c = 'CVI',
                    Category__c = 'Waste Disposal',
                    //Resource_Type__c = ResourceTypeMaterialRecord.Id,
                    Unit_of_Measure__c = UnitMeasureRecord.id,
                    RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId()
                );
                insert ResourceWasteDisposalRecord;
            }
            return ResourceWasteDisposalRecord;
        }
        private set;
    }
    
    public static Resource__c ResourceSubcontractorRecord {
        get {
            if (ResourceSubcontractorRecord == null) {
                ResourceSubcontractorRecord = new Resource__c(
                    Name = 'RERSubcontractor',
                    Fleet_Number__c = 'TR7',
                    Status__c = 'Active',
                    Plate_Number__c = 'TDF19P',
                    Plate_State__c = 'NJ',
                    Make__c = 'Car Mate',
                    //Ticket 13360 >>
                    //Vehicle_Year__c = 2000,
                    //Ticket 13360 <<
                    VIN__c = '5A3U616D1YL005502I',
                    Country__c = 'US',
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                    Service_Center__c = ServiceCenterRecord.Id,
                    Rent_Company__c = 'CVI',
                    Resource_Type__c = ResourceTypeRecord.Id,
                    Unit_of_Measure__c = UnitMeasureRecord.id,
                    RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Subcontractors').getRecordTypeId()
                );
                insert ResourceSubcontractorRecord ;
            }
            return ResourceSubcontractorRecord ;
        }
        private set;
    }

    public static Service_Center__c ServiceCenterRecord {

        get {
            if (ServiceCenterRecord == null) {
                List<Service_Center__c> scs = [SELECT Id, Name, Code__c, City__c, Street__c, Postal_Code__c, State__c, Country__c, Description__c, Subsidiary_Company__c , TM_No_Series__c, Max_No_of_Emergency_T_M__c, Temporary__c FROM Service_Center__c WHERE Code__c='01'];
                if (scs.size() > 0) {
                    ServiceCenterRecord = scs[0];
                }
                else {
                    mapNumberSeries = companyMgmt.getNumber('PO Temp Number');
                    theNumberingSeries = mapNumberSeries.get('PO Temp Number');
                    ServiceCenterRecord = new Service_Center__c(
                        Name = UserRec.Service_Center__c,
                        Description__c = 'SC01 Elizabeth, NJ Ops',
                        Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                        TM_No_Series__c = theNumberingSeries.Id,
                        Sales_Order_No_Series__c = theNumberingSeries.Id,
                        //Sales_Order_No_Series__c = '',
                        Max_No_of_Emergency_T_M__c = 2,
                        Code__c = '01',
                        City__c = 'Elizabeth',
                        Street__c = '201 South First St.',
                        Postal_Code__c = '07206',
                        State__c = 'NJ',
                        Country__c = 'US',
                        Temporary__c = true
    
                    );
                    insert ServiceCenterRecord;
                }
            }
            return ServiceCenterRecord;
        }
        private set;
    }

    public static Purchase_Price__c ProductCatalogRecord {

        get {
            if (ProductCatalogRecord == null) {
                ProductCatalogRecord = new Purchase_Price__c(
                    Account__c = VendorAccount.Id,
                    Vendor_Description__c = 'Test Vendor Description',
                    Name = '3 x 10 Mat',
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Unit_Cost__c = 4.09,
                    Vendor_SKU__c = '84035',
                    Default_Indirect_G_L_Account__c = '52100'

                );
                insert ProductCatalogRecord;
            }
            return ProductCatalogRecord;
        }
        private set;
    }

    public static Purchase_Price__c NewProductCatalogRecord {

        get {
            if (NewProductCatalogRecord == null) {
                NewProductCatalogRecord = new Purchase_Price__c(
                    Account__c = VendorAccount.Id,
                    Name = 'NEW',
                    Vendor_Description__c = 'Test Vendor Description',
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Unit_Cost__c = 4.09,
                    Vendor_SKU__c = 'NEW',
                    //    Item__c=ProductCatalogRecord.Id
                    Default_Indirect_G_L_Account__c = '52100'

                );
                insert NewProductCatalogRecord;
            }
            return NewProductCatalogRecord;
        }
        private set;
    }

    public static Purchase_Price__c ProductCatalogRecord2 {

        get {
            if (ProductCatalogRecord2 == null) {
                ProductCatalogRecord2 = new Purchase_Price__c(
                    Account__c = VendorAccount.Id, //AccountRecord.Id,
                    Name = '3 x 10 Mat',
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Unit_Cost__c = 4.09,
                    Vendor_SKU__c = '84035',
                    Item__c = ProductCatalogRecord.Id,
                    Default_Indirect_G_L_Account__c = '52100',
                    Vendor_Description__c = 'Test Vendor Description'
                );
                insert ProductCatalogRecord2;
            }
            return ProductCatalogRecord2;
        }
        private set;
    }

    public static Approval_Setup_Step__c ApprovalSetupStepRecord {

        get {
            if (ApprovalSetupStepRecord == null) {
                ApprovalSetupStepRecord = new Approval_Setup_Step__c(
                    Name = '01',
                    Amount__c = 100,
                    Level__c = 2,
                    Service_Center__c = ServiceCenterRecord.Id,
                    Type__c = 'Regular',
                    User__c = UserInfo.getUserId()

                );
                insert ApprovalSetupStepRecord;
            }
            return ApprovalSetupStepRecord;
        }
        private set;
    }

    public static Purchase_Receipt__c PurchaseReceiptRecord {
        get {
            if (PurchaseReceiptRecord == null) {
                PurchaseReceiptRecord = new Purchase_Receipt__c(
                    Name = 'Test',
                    Purchase_Order__c = PORecord.Id,
                    //Warehouse__c = WarehouseRecord.Id,
                    Buy_from_Vendor__c = AccountRecord.Id,
                    Document_Status__c = 'Open',
                    Expected_Receipt_Date__c = Date.Today().addDays(7),
                    Actual_Receipt_Date__c = Date.Today(),
                    Posting_Date__c = Date.today(),
                    Service_Center__c = ServiceCenterRecord.Id
                );
                insert PurchaseReceiptRecord ;
            }
            return PurchaseReceiptRecord ;
        }
        private set;
    }

    public static Purch_Rcpt_Line__c PurchRcptLineRecord {
        get {
            if (PurchRcptLineRecord == null) {
                PurchRcptLineRecord = new Purch_Rcpt_Line__c(
                    Receipt__c = PurchaseReceiptRecord.Id,
                    Item__c = ProductCatalogRecord.Id,
                    Quantity__c = 1,
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Expected_Receipt_Date__c = Date.Today().addDays(7),
                    Purchase_Line__c = PurchLineRecords[0].Id
                );
                insert PurchRcptLineRecord;
            }
            return PurchRcptLineRecord;
        }
        private set;
    }

    public static Purch_Rcpt_Line__c PurchRcptLineRecord2 {
        get {
            if (PurchRcptLineRecord2 == null) {
                PurchRcptLineRecord2 = new Purch_Rcpt_Line__c(
                    Receipt__c = PurchaseReceiptRecord.Id,
                    Item__c = ResourceRecord.Id,
                    Quantity__c = 1,
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Expected_Receipt_Date__c = Date.Today().addDays(7),
                    Purchase_Line__c = PurchLineRecords[0].Id
                );
                insert PurchRcptLineRecord2;
            }
            return PurchRcptLineRecord2;
        }
        private set;
    }

    public static Sales_Line__c SalesLineRecord {
        get{
            if (SalesLineRecord == null) {
                SalesLineRecord = new Sales_Line__c();
                SalesLineRecord.Line_No__c = 1;
                SalesLineRecord.Description__c = 'Test item 2';
                SalesLineRecord.Unit_of_Measure__c = UnitMeasureRecord.Id;
                SalesLineRecord.Quantity__c = 1000;
                SalesLineRecord.UOM_Qty__c = 11;
                SalesLineRecord.Regular_Hours__c = 5;
                SalesLineRecord.Overtime_Hours__c= 4;
                SalesLineRecord.Premium_Hours__c = 3;
                SalesLineRecord.Regular_Day__c = 1;
                SalesLineRecord.Overtime_Day__c= 1;
                SalesLineRecord.Premium_Day__c = 1;
                SalesLineRecord.Number_of_Day__c = 3;
                SalesLineRecord.Category__c = 'Labor';
                //SalesLineRecord.Resource__c = ResourceRecord.Id;
                SalesLineRecord.Sales_Order__c = SalesOrderRecord.Id;
                SalesLineRecord.Contract_Line__c = ContractLineRecord.id;
                SalesLineRecord.Resource_Type__c = ResourceTypeRecord.id;

                insert SalesLineRecord;
            }
            return SalesLineRecord;
        }
        private set;
    }

    public static Sales_Line__c SalesContractLineRecord {
        get{
            if (SalesContractLineRecord == null) {
                SalesContractLineRecord = new Sales_Line__c();
                SalesContractLineRecord.Line_No__c = 1;
                SalesContractLineRecord.Description__c = 'Test item';
                SalesContractLineRecord.Quantity__c = 1100;
                SalesContractLineRecord.Category__c = 'Subcontractors';
                SalesContractLineRecord.Resource__c = ResourceRecord.Id;
                SalesContractLineRecord.Sales_Order__c = SalesOrderRecord.Id;
                SalesContractLineRecord.Unit_of_Measure__c = UnitMeasureRecord.Id;
                SalesContractLineRecord.Contract_Line__c = ContractLineRecord.id;
                insert SalesContractLineRecord;
            }
            //System.debug('salesline returned-->' + SalesContractLineRecord);
            return SalesContractLineRecord;
        }
        private set;
    }

    public static Sales_Line__c SalesEquipmentLineRecord {
        get{
            if (SalesEquipmentLineRecord == null) {
                SalesEquipmentLineRecord = new Sales_Line__c();
                SalesEquipmentLineRecord.Line_No__c = 1;
                SalesEquipmentLineRecord.Description__c = 'Test item2';
                SalesEquipmentLineRecord.Quantity__c = 1100;
                SalesEquipmentLineRecord.UOM_Qty__c = 10;
                SalesEquipmentLineRecord.Category__c = 'Equipment';
                SalesEquipmentLineRecord.Unit_of_Measure__c = UnitMeasureRecord.Id;
                //SalesEquipmentLineRecord.Resource__c = ResourceRecord.Id;
                SalesEquipmentLineRecord.Sales_Order__c = SalesOrderRecord.Id;
                SalesEquipmentLineRecord.Contract_Line__c = ContractLineRecord.id;
                SalesEquipmentLineRecord.Resource_Type__c = ResourceTypeRecord.id;
                insert SalesEquipmentLineRecord;
            }
            //System.debug('salesline returned-->' + SalesEquipmentLineRecord);
            return SalesEquipmentLineRecord;
        }
        private set;
    }

    public static Sales_Line__c SalesMaterialLineRecord {
        get{
            if (SalesMaterialLineRecord == null) {
                SalesMaterialLineRecord = new Sales_Line__c();
                SalesMaterialLineRecord.Line_No__c = 1;
                SalesMaterialLineRecord.Description__c = 'Test item';
                SalesMaterialLineRecord.Unit_of_Measure__c = UnitMeasureRecord.Id;
                SalesMaterialLineRecord.Quantity__c = 1100;
                SalesMaterialLineRecord.Category__c = 'Materials';
                SalesMaterialLineRecord.Resource__c = ResourceRecord.Id;
                SalesMaterialLineRecord.Sales_Order__c = SalesOrderRecord.Id;
                SalesMaterialLineRecord.Contract_Line__c = ContractLineRecord.id;
                insert SalesMaterialLineRecord;
            }
            //System.debug('salesline returned-->' + SalesMaterialLineRecord);
            return SalesMaterialLineRecord;
        }
        private set;
    }

    public static Sales_Line__c SalesWasteLineRecord {
        get{
            if (SalesWasteLineRecord == null) {
                SalesWasteLineRecord = new Sales_Line__c();
                SalesWasteLineRecord.Line_No__c = 1;
                SalesWasteLineRecord.Description__c = 'Test item';
                SalesWasteLineRecord.Quantity__c = 1100;
                SalesWasteLineRecord.Category__c = 'Waste Disposal';
                SalesWasteLineRecord.Resource__c = ResourceRecord.Id;
                SalesWasteLineRecord.Unit_of_Measure__c = UnitMeasureRecord.Id;
                SalesWasteLineRecord.Sales_Order__c = SalesOrderRecord.Id;
                SalesWasteLineRecord.Contract_Line__c = ContractLineRecord.id;
                insert SalesWasteLineRecord;
            }
            //System.debug('salesline returned-->' + SalesWasteLineRecord);
            return SalesWasteLineRecord;
        }
        private set;
    }

    public static Sales_Line__c SalesLumpSumLineRecord {
        get{
            if (SalesLumpSumLineRecord == null) {
                SalesLumpSumLineRecord = new Sales_Line__c();
                SalesLumpSumLineRecord.Line_No__c = 1;
                SalesLumpSumLineRecord.Description__c = 'Test item';
                SalesLumpSumLineRecord.Quantity__c = 1100;
                SalesLumpSumLineRecord.Category__c = 'Bundled';
                SalesLumpSumLineRecord.Resource__c = ResourceRecord.Id;
                SalesLumpSumLineRecord.Unit_of_Measure__c = UnitMeasureRecord.Id;
                SalesLumpSumLineRecord.Sales_Order__c = SalesOrderRecord.Id;
                SalesLumpSumLineRecord.Contract_Line__c = ContractLineRecord.id;
                insert SalesLumpSumLineRecord;
            }
            //System.debug('salesline returned-->' + SalesLumpSumLineRecord);
            return SalesLumpSumLineRecord;
        }
        private set;
    }

    public static Sales_Line__c SalesMiscLineRecord {
        get{
            if (SalesMiscLineRecord == null) {
                SalesMiscLineRecord = new Sales_Line__c();
                SalesMiscLineRecord.Line_No__c = 1;
                SalesMiscLineRecord.Description__c = 'Test item';
                SalesMiscLineRecord.Quantity__c = 1100;
                SalesMiscLineRecord.Category__c = 'Misc. Charges And Taxes';
                SalesMiscLineRecord.Resource__c = ResourceRecord.Id;
                SalesMiscLineRecord.Unit_of_Measure__c = UnitMeasureRecord.Id;
                SalesMiscLineRecord.Sales_Order__c = SalesOrderRecord.Id;
                SalesMiscLineRecord.Contract_Line__c = ContractLineRecord.id;
                insert SalesMiscLineRecord;
            }
            //System.debug('salesline returned-->' + SalesMiscLineRecord);
            return SalesMiscLineRecord;
        }
        private set;
    }
    
    public static Sales_Line__c SalesDemurrageLineRecord {
        get{
            if (SalesDemurrageLineRecord == null) {
                SalesDemurrageLineRecord = new Sales_Line__c();
                SalesDemurrageLineRecord.Line_No__c = 1;
                SalesDemurrageLineRecord.Description__c = 'Test item';
                SalesDemurrageLineRecord.Quantity__c = 1100;
                SalesDemurrageLineRecord.Category__c = 'Demurrage';
                SalesDemurrageLineRecord.Resource__c = ResourceRecord.Id;
                SalesDemurrageLineRecord.Unit_of_Measure__c = UnitMeasureRecord.Id;
                SalesDemurrageLineRecord.Sales_Order__c = SalesOrderRecord.Id;
                SalesDemurrageLineRecord.Contract_Line__c = ContractLineRecord.id;
                insert SalesDemurrageLineRecord;
            }
            //System.debug('salesline returned-->' + SalesDemurrageLineRecord);
            return SalesDemurrageLineRecord;
        }
        private set;
    }

    public static Sales_Order__c SalesOrderRecord {
        get {
            if (SalesOrderRecord == null) {
                SalesOrderRecord = new Sales_Order__c();
                SalesOrderRecord.Name = 'NJ57506-01-2080';
                SalesOrderRecord.Surcharge_Type__c = 'N/A';
                SalesOrderRecord.Document_Type__c = 'Sales Order';
                SalesOrderRecord.Bill_to_Customer_No__c = customerAccountRecord.id;
                SalesOrderRecord.Service_Center__c = ServiceCenterRecord.Id;
                SalesOrderRecord.Sales_Order_Type__c = SalesOrdertypeRecord.id;
                SalesOrderRecord.Subsidiary_Company__c = subsidiarycompanyRecord.id;
                SalesOrderRecord.Project_Coordinator__c = SalespersonRecord.Id;
                SalesOrderRecord.Estimated_Job_Start_Date__c = Date.newInstance(2018,1,1);
                
                //Terms and conditions <<
                SalesOrderRecord.Any_Deviations__c = true;
                SalesOrderRecord.Shippable_Containers__c = true;
                SalesOrderRecord.First_Hour_Of_Loading__c = true;
                SalesOrderRecord.Overtime_Rate_Description__c = true;
                SalesOrderRecord.Rate_Time_Definitions__c = true;
                SalesOrderRecord.Charges_For_Labor__c = true;
                SalesOrderRecord.Waste_Disposal_And_Ancillary__c = true;
                SalesOrderRecord.Characterization_Of_Waste__c = true;
                SalesOrderRecord.Generate_Before_Final__c = true;
                SalesOrderRecord.Lab_Packs_Rate__c = true;
                SalesOrderRecord.Cylinders_Require_Evaluation__c = true;
                SalesOrderRecord.Manifest_And_Profile__c = true;
                SalesOrderRecord.Net_Due_Day__c = true;
                SalesOrderRecord.Applicable_Taxes_Quote__c = true;
                SalesOrderRecord.Client_Is_Responsible__c = true;
                SalesOrderRecord.In_The_Event__c = true;
                SalesOrderRecord.Quote_Valid_30__c = true;
                SalesOrderRecord.Unless_Superseded__c = true;
                SalesOrderRecord.Charge_Rinse_Out_Fee__c = true;
                //Terms and conditions >>
                insert SalesOrderRecord;
            }
            return SalesOrderRecord;
        }
        private set;
    }

    public static Sales_Order__c SalesOrderRecordCSA {
        get {
            if (SalesOrderRecordCSA == null) {
                SalesOrderRecordCSA = new Sales_Order__c();
                SalesOrderRecordCSA.Name = 'NJ57506-01-2083';
                SalesOrderRecordCSA.Document_Type__c = 'Sales Order';
                SalesOrderRecordCSA.Surcharge_Type__c = 'N/A';
                SalesOrderRecordCSA.Site_Name__c = 'Test SIte Name xx';
                SalesOrderRecordCSA.Create_Site_Address__c = True;
                SalesOrderRecordCSA.Estimated_Job_Start_Date__c = Date.newInstance(2018,1,1);
                SalesOrderRecordCSA.Duration__c = 1;
                SalesOrderRecordCSA.Bill_to_Customer_No__c = customerAccountRecord.id;
                SalesOrderRecordCSA.Service_Center__c = ServiceCenterRecord.Id;
                SalesOrderRecordCSA.Sales_Order_Type__c = SalesOrdertypeRecord.id;
                SalesOrderRecordCSA.Subsidiary_Company__c = subsidiarycompanyRecord.id;
                SalesOrderRecordCSA.Project_Coordinator__c = SalespersonRecord.Id;
                SalesOrderRecordCSA.Contract__c = TestDataUtil.ContractRecordCustomer.Id;
                insert SalesOrderRecordCSA;
            }
            return SalesOrderRecordCSA;
        }
        private set;
    }

    public static Sales_Order__c SalesQuoteRecordCSA {
        get {
            if (SalesQuoteRecordCSA == null) {
                SalesQuoteRecordCSA = new Sales_Order__c();
                SalesQuoteRecordCSA.Name = 'NJ57506-01-2083';
                SalesQuoteRecordCSA.Document_Type__c = 'Sales Quote';
                SalesQuoteRecordCSA.Surcharge_Type__c = 'N/A';
                SalesQuoteRecordCSA.Site_Name__c = 'Test SIte Name xx';
                SalesQuoteRecordCSA.Create_Site_Address__c = True;
                SalesQuoteRecordCSA.Bill_to_Customer_No__c = customerAccountRecord.id;
                SalesQuoteRecordCSA.Service_Center__c = ServiceCenterRecord.Id;
                SalesQuoteRecordCSA.Sales_Order_Type__c = SalesOrdertypeRecord.id;
                SalesQuoteRecordCSA.Subsidiary_Company__c = subsidiarycompanyRecord.id;
                SalesQuoteRecordCSA.Project_Coordinator__c = SalespersonRecord.Id;
                SalesQuoteRecordCSA.Contract__c = TestDataUtil.ContractRecordCustomer.Id;
                insert SalesQuoteRecordCSA;
            }
            return SalesQuoteRecordCSA;
        }
        private set;
    }

    public static Sales_Order_Type__c SalesOrdertypeRecord {
        get {
            if (SalesOrdertypeRecord == null) {
                SalesOrdertypeRecord = new Sales_Order_Type__c(Description__c = 'test description');
                //insert SalesOrdertypeRecord;
                insert SalesOrdertypeRecord;
            }
            return SalesOrdertypeRecord;
        }
        private set;
    }

    public static Ship_To_Address__c ShiptoAddressRecord {
        get {
            if (ShiptoAddressRecord == null) {
                ShiptoAddressRecord = new Ship_To_Address__c(Name = 'test address', City__c = 'city', Country__c = 'US', State__c = 'CO', Postal_Code__c = 'pc', Street__c = 'street');
                //insert ShiptoAddressRecord;
                insert ShiptoAddressRecord;
            }
            return ShiptoAddressRecord;
        }
        private set;
    }

    public static Subsidiary_Vendor__c SubsidiaryRecord {
        get {
            if (SubsidiaryRecord == null) {
                SubsidiaryRecord = new Subsidiary_Vendor__c(Name = 'test address', Account__c = AccountRecord.Id, Billing_City__c = '', Billing_Country__c = 'US', Billing_State__c = 'CO', Billing_Postal_Code__c = 'pc', Billing_Street__c = 'street', Payment_Term__c = PaymentTermRecord.ID, Subsidiary_Company__c = subsidiarycompanyRecord.id);
                //insert SubsidiaryRecord;
                insert SubsidiaryRecord;
            }
            return SubsidiaryRecord;
        }
        private set;
    }

    public static Sales_Invoice__c SalesInvoiceRecord {
        get {
            if (SalesInvoiceRecord == null) {
                SalesInvoiceRecord = new Sales_Invoice__c(
                    Bill_to_Customer__c = AccountRecord.Id,
                    Salesperson__c = SalespersonRecord.Id,
                    Account_Executive__c = SalespersonRecord.Id,
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                    Tax_Area__c = TaxAreaRecord.Id,
                    Service_Center__c = ServiceCenterRecord.Id,
                    Document_Status__c = 'Open',
                    Sales_Order__c = SalesOrderRecord.Id,
                    Payment_Term__c = PaymentTermRecord.Id,
                    Contact__c = Contact2Record.Id
                );
                insert SalesInvoiceRecord;
            }
            return SalesInvoiceRecord;
        }
        private set;

    }
    
    public static Sales_Invoice__c SalesInvoiceCMRecord {
        get {
            if (SalesInvoiceCMRecord == null) {
                SalesInvoiceCMRecord = new Sales_Invoice__c(
                    Bill_to_Customer__c = AccountRecord.Id,
                    Salesperson__c = SalespersonRecord.Id,
                    Account_Executive__c = SalespersonRecord.Id,
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                    Tax_Area__c = TaxAreaRecord.Id,
                    Service_Center__c = ServiceCenterRecord.Id,
                    Document_Status__c = 'Open',
                    Sales_Order__c = SalesOrderRecord.Id,
                    Payment_Term__c = PaymentTermRecord.Id,
                    Credit_Memo__c = True
                );
                insert SalesInvoiceCMRecord;
            }
            return SalesInvoiceCMRecord;
        }
        private set;

    }
    
    public static Sales_Invoice_Line__c SalesInvoiceLineCMRecord {
        get {
            if (SalesInvoiceLineCMRecord == null) {
                SalesInvoiceLineCMRecord = new Sales_Invoice_Line__c(
                    Sales_Invoice__c = SalesInvoiceCMRecord.Id,
                    Resource__c = ResourceRecord.Id,
                    Category__c = 'Labor',
                    Description__c = 'Test',
                    Line_No__c = 5,
                    Quantity__c = -5,
                    Unit_Price__c = 2,
                    Line_Amount__c = 0,
                    Line_Amt_Incl_Tax__c = 0,
                    Tax__c = 0,
                    Tax_Group__c = 'NT',
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    TM_Line__c = TMLineLaborRecord.id,
                    TM__c = TMRecord.id
                );
                insert SalesInvoiceLineCMRecord;
            }
            return SalesInvoiceLineCMRecord;
        }
        private set;

    }

    public static Sales_Invoice_Line__c SalesInvoiceLineRecord {
        get {
            if (SalesInvoiceLineRecord == null) {
                SalesInvoiceLineRecord = new Sales_Invoice_Line__c(
                    Sales_Invoice__c = SalesInvoiceRecord.Id,
                    Resource__c = ResourceRecord.Id,
                    Category__c = 'Labor',
                    Description__c = 'Test',
                    Line_No__c = 5,
                    Quantity__c = 5,
                    Unit_Price__c = 2,
                    Line_Amount__c = 0,
                    Line_Amt_Incl_Tax__c = 0,
                    Tax__c = 0,
                    Tax_Group__c = 'NT',
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    TM_Line__c = TMLineLaborRecord.id,
                    TM__c = TMRecord.id
                );
                insert SalesInvoiceLineRecord;
            }
            return SalesInvoiceLineRecord;
        }
        private set;

    }

    public static TM__c TMRecord {
        get {
            if (TMRecord == null) {
                TMRecord = new TM__c(
                    //Bill_to_Customer__c = AccountRecord.Id,
                    Bill_to_Customer__c = customerAccountRecord.Id,
                    Project_Coordinator__c = SalespersonRecord.Id,
                    Account_Executive__c = SalespersonRecord.Id,
                    Prevailing_Wage_Job__c = true,
                    Certified_PW_Job__c = true,
                    Service_Center__c = ServiceCenterRecord.Id,
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                    Tax_Area__c = TaxAreaRecord.Id,
                    Sales_Order__c = SalesOrderRecord.Id,
                    Scheduled_Date__c = Date.today().addDays(-7),
                    Status__c = 'Open',
                    Contract__c = ContractRecordCustomer.Id
                );
                insert TMRecord;
            }
            return TMRecord;
        }
        private set;

    }

    public static TM__c TMConfirmedRecord {
        get {
            if (TMConfirmedRecord == null) {
                TMConfirmedRecord = new TM__c(
                    Bill_to_Customer__c = customerAccountRecord.Id,
                    Project_Coordinator__c = SalespersonRecord.Id,
                    Account_Executive__c = SalespersonRecord.Id,
                    Prevailing_Wage_Job__c = true,
                    Certified_PW_Job__c = true,
                    Service_Center__c = ServiceCenterRecord.Id,
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                    Tax_Area__c = TaxAreaRecord.Id,
                    Sales_Order__c = SalesOrderRecord.Id,
                    Scheduled_Date__c = Date.today().addDays(-7),
                    Status__c = 'Confirmed'
                );
                insert TMConfirmedRecord;
            }
            return TMConfirmedRecord;
        }
        private set;

    }

    public static TM_Line__c TMLineLaborRecord {
        get{
            if (TMLineLaborRecord == null) {
                TMLineLaborRecord = new TM_Line__c(
                    Line_No__c = 1,
                    Description__c = 'Test item',
                    Quantity__c = 1650,
                    Category__c = 'Labor',
                    TM__c = TMRecord.Id,
                    Resource_Type__c = ResourceTypeRecord.Id,
                    Service_Center__c = ServiceCenterRecord.Id,
                    Resource__c = ResourceLaborRecord.Id,
                    Total_Site_Hours__c = 1650,
                    Regular_Hours__c = 550,
                    Regular_Rate__c = 1,
                    Overtime_Rate__c = 1,
                    Overtime_Hours__c = 550,
                    Premium_Hours__c = 550,
                    Premium_Rate__c = 1,
                    Unit_Price__c = 1,
                    Hour__c = 1650,
                    Tax_Group__c = 'TX',
                    Unit_of_Measure__c = UnitMeasureRecord.Id, //Added to add missing field
                    Job_Start_Time__c = system.now().addHours(-8).Time(),
                    Job_End_Time__c = system.now().Time()
                );
                insert TMLineLaborRecord;
            }
            //System.debug('tmline returned-->' + TMLineLaborRecord);
            return TMLineLaborRecord;
        }
        private set;
    }

    public static TM_Line__c TMLineDemurrageRecord {
        get{
            if (TMLineDemurrageRecord == null) {
                TMLineDemurrageRecord = new TM_Line__c(
                    Line_No__c = 2,
                    Description__c = 'Test E',
                    Quantity__c = 1100,
                    Category__c = 'Demurrage',
                    TM__c = TMRecord.Id,
                    Resource__c = ResourceDemurrageRecord.Id,
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Total_Site_Hours__c = 1100,
                    Regular_Hours__c = 550,
                    Overtime_Hours__c = 550,
                    Tax_Group__c = 'NT',
                    Resource_Type__c = null
                );
                insert TMLineDemurrageRecord;
            }
            //System.debug('tmline returned-->' + TMLineDemurrageRecord);
            return TMLineDemurrageRecord;
        }
        private set;
    }


    public static TM_Line__c TMLineSubcontractorsRecord {
        get{
            if (TMLineSubcontractorsRecord  == null) {
                TMLineSubcontractorsRecord = new TM_Line__c(
                    Line_No__c = 2,
                    Description__c = 'Test E',
                    Quantity__c = 1100,
                    Category__c = 'Subcontractors',
                    TM__c = TMRecord.Id,
                    Resource__c = ResourceSubcontractorRecord.Id,
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Total_Site_Hours__c = 1100,
                    Regular_Hours__c = 550,
                    Overtime_Hours__c = 550,
                    Tax_Group__c = 'NT'
                );
                insert TMLineSubcontractorsRecord ;
            }
            //System.debug('tmline returned-->' + TMLineSubcontractorsRecord );
            return TMLineSubcontractorsRecord ;
        }
        private set;
    }

    public static TM_Line__c TMLineMisChargeRecord {
        get{
            if (TMLineMisChargeRecord == null) {
                TMLineMisChargeRecord = new TM_Line__c(
                    Line_No__c = 2,
                    Description__c = 'Test E',
                    Quantity__c = 1100,
                    Category__c = 'Misc. Charges And Taxes',
                    TM__c = TMRecord.Id,
                    //Resource_Type__c = ResourceTypeRecord.Id,
                    Resource__c = ResourceRentalRecord.Id,
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Total_Site_Hours__c = 1100,
                    Regular_Hours__c = 550,
                    Overtime_Hours__c = 550,
                    Tax_Group__c = 'NT'
                );
                insert TMLineMisChargeRecord;
            }
            //System.debug('tmline returned-->' + TMLineMisChargeRecord);
            return TMLineMisChargeRecord;
        }
        private set;
    }

    public static TM_Line__c TMLineLumpSumRecord {
        get{
            if (TMLineLumpSumRecord == null) {
                TMLineLumpSumRecord = new TM_Line__c(
                    Line_No__c = 2,
                    Description__c = 'Test E',
                    Quantity__c = 1100,
                    Category__c = 'Bundled',
                    TM__c = TMRecord.Id,
                    Resource_Type__c = ResourceTypeLumpSumRecord.Id,
                    Resource__c = ResourceLumpSumRecord.Id,
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Total_Site_Hours__c = 1100,
                    Regular_Hours__c = 550,
                    Overtime_Hours__c = 550,
                    Tax_Group__c = 'NT'
                );
                insert TMLineLumpSumRecord ;
            }
            //System.debug('tmline returned-->' + TMLineLumpSumRecord );
            return TMLineLumpSumRecord ;
        }
        private set;
    }

    public static TM_Line__c TMLineWasteDisposalRecord {
        get{
            if (TMLineWasteDisposalRecord == null) {
                TMLineWasteDisposalRecord = new TM_Line__c(
                    Line_No__c = 2,
                    Description__c = 'Test E',
                    Quantity__c = 1100,
                    Category__c = 'Waste Disposal',
                    TM__c = TMRecord.Id,
                    Resource__c = ResourceWasteDisposalRecord.Id,
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Total_Site_Hours__c = 1100,
                    Regular_Hours__c = 550,
                    Overtime_Hours__c = 550,
                    Tax_Group__c = 'NT'
                );
                insert TMLineWasteDisposalRecord ;
            }
            //System.debug('tmline returned-->' + TMLineWasteDisposalRecord );
            return TMLineWasteDisposalRecord ;
        }
        private set;
    }
    
    public static TM_Line__c TMLineMaterialRecord {
        get{
            if (TMLineMaterialRecord == null) {
                TMLineMaterialRecord = new TM_Line__c(
                    Line_No__c = 2,
                    Description__c = 'Test E',
                    Quantity__c = 1100,
                    Category__c = 'Materials',
                    TM__c = TMRecord.Id,
                    Resource__c = ResourceMaterialRecord.Id,
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Total_Site_Hours__c = 1100,
                    Regular_Hours__c = 550,
                    Overtime_Hours__c = 550,
                    Tax_Group__c = 'NT'
                );
                insert TMLineMaterialRecord ;
            }
            //System.debug('tmline returned-->' + TMLineMaterialRecord );
            return TMLineMaterialRecord ;
        }
        private set;
    }

    public static TM_Line__c TMLineEquipmentRecord {
        get{
            if (TMLineEquipmentRecord == null) {
                TMLineEquipmentRecord = new TM_Line__c(
                    Line_No__c = 2,
                    Description__c = 'Test E',
                    Quantity__c = 1100,
                    Category__c = 'Equipment',
                    TM__c = TMRecord.Id,
                    Resource_Type__c = ResourceTypeEquipmentRecord.Id,
                    Service_Center__c = ServiceCenterRecord.Id,
                    Resource__c = ResourceEquipmentRecord.Id,
                    Total_Site_Hours__c = 1100,
                    Regular_Hours__c = 550,
                    Overtime_Hours__c = 550,
                    Tax_Group__c = 'TX',
                    Unit_of_Measure__c = UnitMeasureRecord.Id, //Added to add missing field
                    Job_Start_Time__c = system.now().addHours(-8).Time(),
                    Job_End_Time__c = system.now().Time()
                );
                insert TMLineEquipmentRecord;
            }
            //System.debug('tmline returned-->' + TMLineEquipmentRecord);
            return TMLineEquipmentRecord;
        }
        private set;
    }
    /*
        public static Resource_Type__c ResourceTypeRecord {
            get {
                if (ResourceTypeRecord == null) {
                    ResourceTypeRecord = new Resource_Type__c(
                        Name = 'JPTest',
                        Description__c = 'JPTest',
                        Unit_of_Measure__c = UnitMeasureRecord.Id
                    );
                    insert ResourceTypeRecord;
                }
                return ResourceTypeRecord;
            } private set;

        }
    */
    /*public static Equipment_Group__c EquipmentGroupRecord {
        get {
            if (EquipmentGroupRecord == null) {
                EquipmentGroupRecord = new Equipment_Group__c(
                    Name = 'EquipmentGroupTest',
                    Description__c = 'EquipmentGroupTest'
                );
                insert EquipmentGroupRecord;
            }
            return EquipmentGroupRecord;
        } private set;

    }

    public static Resource_Type__c ResourceTypeRecord {
        get {
            if (ResourceTypeRecord == null) {
                ResourceTypeRecord = new Resource_Type__c(
                    Name = 'EquipmentTypeTest',
                    Description__c = 'EquipmentTypeTest',
                    Unit_of_Measure__c = UnitMeasureRecord.Id,
                    Equipment_Group__c = EquipmentGroupRecord.Id
                );
                insert ResourceTypeRecord;
            }
            return ResourceTypeRecord;
        } private set;

    }*/


    public static GL_Account__c GLAccountRecord {
        get {
            List<GL_Account__c> GLAccountRecordList = [Select Id From GL_Account__c Where Name =: 'GLAccountRecordTest'];
            if (GLAccountRecordList.size() == 0 ) {
                GLAccountRecord = new GL_Account__c(
                    Name = 'GLAccountRecordTest',
                        Description__c = 'Test GL Account'
                );
                insert GLAccountRecord ;
                return GLAccountRecord ;
            }
            return GLAccountRecordList[0] ;
        }
        private set;

    }

    public static GL_Entry__c GLEntryRecord {
        get {
            if (GLEntryRecord == null) {
                GLEntryRecord = new GL_Entry__c(
                    GL_Account__c = GLAccountRecord.id,
                    Account__c = AccountRecord.Id,
                    Amount__c = 100,
                    Payment_Term__c = PaymentTermRecord.Id,
                    GL_Batch__c = GLBatchRecord.id
                );
                insert GLEntryRecord ;
            }
            return GLEntryRecord ;
        }
        private set;

    }

    public static GL_Batch__c GLBatchRecord {
        get {
            if (GLBatchRecord == null) {
                GLBatchRecord = new GL_Batch__c (
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.id
                );
                insert GLBatchRecord ;
            }
            return GLBatchRecord ;
        }
        private set;

    }

    public static Timesheet__c TimesheetRecord {
        get {
            if (TimesheetRecord == null) {
                TimesheetRecord = new Timesheet__c (
                    Name = 'Test TimesheetName',
                    Resource__c = ResourceLaborRecord.Id,
                    //Service_Center__c=ServiceCenterRecord.Id,
                    Status__c = 'Approved',
                    Week_No__c = WeekNumberRecord.Id
                );
                insert TimesheetRecord ;
            }
            return TimesheetRecord ;
        }
        private set;
    }

    public static Week_Number__c WeekNumberRecord {
        get {
            if (WeekNumberRecord == null) {
                WeekNumberRecord = new Week_Number__c (
                    Name = '2018/01',
                    Week_Start_Date__c = Date.Today().toStartofWeek(),
                    Week_End_Date__c = Date.Today().toStartofWeek().Adddays(7),
                    Week_No__c = '01',
                    Year__c = String.valueof(Date.Today().Year())
                );
                insert WeekNumberRecord ;
            }
            return WeekNumberRecord ;
        }
        private set;

    }

    public static Payroll__c PayrollRecord {
        get {
            if (PayrollRecord == null) {
                PayrollRecord = new Payroll__c (
                    Name = 'Test Payroll',
                    End_Date__c = Date.Today().addMonths(1).toStartofMonth().addDays(-1),
                    Start_Date__c = Date.Today().toStartofMonth(),
                    //Timesheet__c=TimesheetRecord.Id,
                    //Service_Center__c=ServiceCenterRecord.Id,
                    Week_Number__c = WeekNumberRecord.id
                );
                insert PayrollRecord ;
            }
            return PayrollRecord ;
        }
        private set;

    }

    public static Contract  ContractRecord {
        get {
            if (ContractRecord == null) {
                ContractRecord = new Contract  (
                    Name = 'Test ContractRecord',
                    AccountId = AccountRecord.Id,
                    StartDate = Date.Today().AddDays(-200),
                    Status = 'Draft',
                    Subsidiary__c = '1-REPUBLIC SERVICES'
                );
                insert ContractRecord ;
                ContractRecord.Status = 'Activated';
            }
            return ContractRecord ;
        }
        private set;
    }

    public static Contract  ContractRecordCustomer {
        get {
            if (ContractRecordCustomer == null) {
                ContractRecordCustomer = new Contract  (
                    Name = 'Test ContractRecord',
                    AccountId = customerAccountRecord.Id,
                    StartDate = Date.Today().AddDays(-200),
                    Status = 'Draft',
                    Subsidiary__c = '1-REPUBLIC SERVICES'
                );
                insert ContractRecordCustomer;
                ContractRecordCustomer.Status = 'Activated';
                update ContractRecordCustomer;
            }
            return ContractRecordCustomer;
        }
        private set;
    }

    public static Contract_Line__c ContractLineRecord {
        get {
            ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = resourceTypeUOMAssociationRec;
            if (ContractLineRecord == null) {
                ContractLineRecord = new Contract_Line__c (
                    Name = 'Test ContractLine',
                    Contract__c = ContractRecord.Id,
                    Premium_Rate__c = 10,
                    Resource__c = ResourceRecord.Id,
                    Resource_Type__c = ResourceTypeRecord.id,
                    Unit_of_Measure__c = UnitMeasureRecord.id
                );
                insert ContractLineRecord ;
            }
            return ContractLineRecord ;
        }
        private set;
    }

    public static Site_Address__c SiteAddressRecord {
        get {
            if (SiteAddressRecord == null) {
                SiteAddressRecord = new Site_Address__c (
                    Name = 'Test SiteAddress',
                    Customer__c = customerAccountRecord.Id
                );
                insert SiteAddressRecord ;
            }
            return SiteAddressRecord ;
        }
        private set;

    }

    public static Payroll_Line__c PayrollLineRecord {
        get {
            if (PayrollLineRecord == null) {
                PayrollLineRecord = new Payroll_Line__c (
                    Payroll__c = PayrollRecord.Id,
                    Pay_Rate__c = 10,
                    Job_Position__c = ResourceTypeRecord.id,
                    Amount__c = 100,
                    //Resource__c=ResourceLaborRecord.Id,
                    //TM__c=TMRecord.id,
                    //Sales_Order__c=SalesOrderRecord.Id,
                    T_M_Line__c = null
                );
                insert PayrollLineRecord ;
            }
            return PayrollLineRecord ;
        }
        private set;

    }

    public static Rental_Order__c RentalOrderRecord {
        get {
            if (RentalOrderRecord == null) {
                RentalOrderRecord = new Rental_Order__c (
                    Name = 'Rental Test',
                    Billing_Amount__c = 10,
                    Billing_Type__c = 'Monthly',
                    Bill_to_Customer__c = AccountRecord.Id,
                    Document_Status__c = 'Open',
                    Drop_Off_T_M__c = TMRecord.id,
                    Resource__c = ResourceRecord.Id,
                    Drop_Off_T_M_Line__c = TMLineLaborRecord.Id,
                    Pickup_T_M__c = TMRecord.id,
                    Pickup_T_M_Line__c = TMLineLaborRecord.Id,
                    Sales_Order__c = SalesOrderRecord.Id,
                    Service_Center__c = ServiceCenterRecord.Id,
                    Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
                    Last_Invoice_Date__c = Date.Today().AddDays(-60),
                    Drop_Off_Date__c = Date.Today()
                );
                insert RentalOrderRecord ;
            }
            return RentalOrderRecord ;
        }
        private set;
    }

    public static Timesheet_Line__c TimesheetLineRecord {
        get {
            if (TimesheetLineRecord == null) {
                TimesheetLineRecord = new Timesheet_Line__c (
                    Customer_Name__c = 'TimesheetLine Test',
                    Line_Amount__c = 10,
                    Line_No__c = 0,
                    Rate__c = 10,
                    Prevailing_Wage_Job__c = true,
                    Time_Type_Code__c = 'REG',
                    Sales_Order__c = SalesOrderRecord.Id,
                    Sales_Order_Service_Center__c = ServiceCenterRecord.Id,
                    TM__c = TMRecord.Id,
                    T_M_Line__c = TMLineLaborRecord.Id,
                    Timesheet__c = TimesheetRecord.Id,
                    Time_Type__c = 'Job Time',
                    Work_as_Resource_Type__c = ResourceTypeRecord.Id,
                    Resource__c = ResourceRecord.Id,
                    Scheduled_Date__c = Date.today(),
                    Start_Time__c = Time.newInstance(8, 0, 0, 0),
                    End_Time__c = Time.newInstance(12, 0, 0, 0)
                );
                insert TimesheetLineRecord ;
            }
            return TimesheetLineRecord ;
        }
        private set;
    }

    public static Resource_Off__c ResourceOffRecord {
        get{
            if (ResourceOffRecord == null) {
                ResourceOffRecord = new Resource_Off__c();
                ResourceOffRecord.Date__c = Date.Today();
                ResourceOffRecord.Start_Time__c = Time.newInstance(8, 0, 0, 0);
                ResourceOffRecord.End_Time__c = Time.newInstance(20, 0, 0, 0);
                ResourceOffRecord.Hours__c = 12;
                ResourceOffRecord.Resource__c = ResourceRecord.Id;
                ResourceOffRecord.Off_Type__c = OffTypeRecord2.Id;
                ResourceOffRecord.Shop_Time_Category__c = 'Physical';
                insert ResourceOffRecord;
            }
            return ResourceOffRecord;
        }
        private set;
    }

    public static Resource_Flat_Pay__c ResourceFlatPayRecord {
        get {
            if (ResourceFlatPayRecord == null) {
                ResourceFlatPayRecord = new Resource_Flat_Pay__c (
                    Rate__c = 10,
                    Rate_Type__c = 'PDL',
                    T_M_Line__c = TMLineLaborRecord.Id,
                    //Resource_No__c=TMLineLaborRecord.id,
                    T_M__c = TMRecord.Id
                );
                insert ResourceFlatPayRecord ;
            }
            return ResourceFlatPayRecord ;
        }
        private set;
    }

    public static Off_Type__c OffTypeRecord {
        get {
            if (OffTypeRecord == null) {
                OffTypeRecord = new Off_Type__c (
                    Name = 'Other',
                    Equipment__c = True,
                    Map_to_Time_Type__c = 'Other'
                );
                insert OffTypeRecord ;
            }
            return OffTypeRecord ;
        }
        private set;
    }

    public static Off_Type__c OffTypeRecord2 {
        get {
            if (OffTypeRecord2 == null) {
                OffTypeRecord2 = new Off_Type__c (
                    Name = 'Shop Time',
                    Equipment__c = True,
                    Map_to_Time_Type__c = 'Shop Time'
                );
                insert OffTypeRecord2 ;
            }
            return OffTypeRecord2 ;
        }
        private set;
    }

    public static Document DocumentRecord {
        get {
            if (DocumentRecord == null) {
                DocumentRecord = new Document(
                    Body = Blob.valueOf('Testing'),
                    ContentType = 'application/pdf',
                    DeveloperName = 'mydocument',
                    IsPublic = true,
                    Name = 'FB Image',
                    FolderId = [SELECT Id FROM Folder WHERE Name = 'Shared Documents' limit 1].id
                );
                insert DocumentRecord ;
            }
            return DocumentRecord ;
        }
        private set;
    }

    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx + 1);
        }
        return randStr;
    }
    
    public static User UserRecord {
        get {
            if (UserRecord == null) {
                Profile profileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
                List<User> users = [SELECT Id, LastName, FirstName, Email, Username, ProfileId, Service_Center__c FROM User WHERE Username = 'jason.liveston12@examplebox.com' LIMIT 1];
                if(users.size() > 0){
                    UserRecord = users[0];
                } else {
                    UserRecord = new User(LastName = 'LIVESTON',
                               FirstName='JASON',
                               Alias = 'jliv',
                               Email = 'jason.liveston@republicservices.com',
                               Username = 'jason.liveston12@republicservices.com',
                               ProfileId = profileId.id,
                               TimeZoneSidKey = 'GMT',
                               LanguageLocaleKey = 'en_US',
                               EmailEncodingKey = 'UTF-8',
                               LocaleSidKey = 'en_US',
                               Service_Center__c = ServiceCenterRecord.Name//'Deep Green'
                               );
                    insert UserRecord ;
                }
            }
            return UserRecord ;
        }
        private set;
    }

    public static OrganizationConfigurations__c OrganizationConfigurationsRecord {
        get {
            if (OrganizationConfigurationsRecord == null) {
                OrganizationConfigurationsRecord = new OrganizationConfigurations__c(
                    Data_Admin_Public_Group__c = 'Data Admin'                  
                );
                insert OrganizationConfigurationsRecord;
            }
            return OrganizationConfigurationsRecord;
        }
        private set;
    }

    public static List<Accounting_Period__c> AccountingPeriodRecords {
        get {
            if (AccountingPeriodRecords == null) {
                AccountingPeriodRecords = new List<Accounting_Period__c>();
                for (Integer y = 2016; y <= 2018; y++) {
                    for (Integer p = 1; p < 12; p++) {
                        Date startDate = Date.newInstance(y, p, 1);
                        Date endDate = startDate.addMonths(1).addDays(-1);
                        Boolean newFiscalYear = (p == 1);
                        AccountingPeriodRecords.add(new Accounting_Period__c(
                            Name = String.valueof(startDate),
                            Start_Date__c = startDate,
                            End_Date__c = endDate,
                            Fiscal_Year__c = y, 
                            Fiscal_Period__c = p,
                            New_Fiscal_Year__c = newFiscalYear                  
                        ));
                    }
                }
                
                insert AccountingPeriodRecords;
            }
            return AccountingPeriodRecords;
        }
        private set;
    }
    
    public static List<Customer_Ledger_Entry__c> CustomerLedgerEntryRecords {
        get {
            if (CustomerLedgerEntryRecords == null) {
                CustomerLedgerEntryRecords = new List<Customer_Ledger_Entry__c>();
                for(Integer i = 0; i<= 6; i++) {
                    CustomerLedgerEntryRecords.add(new Customer_Ledger_Entry__c(
                        Name = String.valueOf(i), 
                        NAV_ID__c = String.valueOf(i), 
                        Customer__c = customerAccountRecord.Id, 
                        Posting_Date__c = system.today().addMonths(-i*4), 
                        Subsidiary_Company__c = SubsidiaryCompanyRecord.Id, 
                        Amount__c = 100, 
                        Amount_LCY__c = 100, 
                        Remaining_Amount__c = 100, 
                        Remaining_Amount_LCY__c = 100, 
                        Sales_Lcy__c = 100, 
                        Service_Center__c = ServiceCenterRecord.Id, 
                        Document_Type__c = 'Invoice',
                        Closed_at_Date__c = system.today().addMonths(-i * 3)
                    ));
                }
                insert CustomerLedgerEntryRecords;
            }
            return CustomerLedgerEntryRecords;
        }
        private set;
    }
    
    public static Group GroupRecord {
        get{
            if (GroupRecord == null) {
                GroupRecord = new Group();
                GroupRecord.Name = 'Data Admin';
                GroupRecord.DeveloperName = 'Data_Admin';
                insert GroupRecord ;
            }
            return GroupRecord ;
        }
        private set;
    }
    
    public static GroupMember GroupMemberRecord {
        get{
            if (GroupMemberRecord == null) {
                GroupMemberRecord = new GroupMember();
                GroupMemberRecord.GroupId = GroupRecord.Id;
                GroupMemberRecord.UserOrGroupId = UserInfo.getUserId();
                insert GroupMemberRecord ;
            }
            return GroupMemberRecord ;
        }
        private set;
    }

    public static List<Sales_Invoice_Line__C> SalesInvoiceLineRecords {
        get {
            if (SalesInvoiceLineRecords == null) {
                SalesInvoiceLineRecords = new List<Sales_Invoice_Line__C>();
                Sales_Invoice_Line__C SalesInvoiceLineRecord1 = new Sales_Invoice_Line__c(
                        Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
                        Resource__c = TestDataUtil.ResourceRecord.Id,
                        Category__c = 'Equipment',
                        Description__c = 'Test',
                        Line_No__c = 5,
                        Quantity__c = 5,
                        Unit_Price__c = 2,
                        Line_Amount__c = 0,
                        Line_Amt_Incl_Tax__c = 0,
                        Tax__c = 0,
                        Tax_Group__c = 'NT',
                        Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
                        TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
                        TM__c = TestDataUtil.TMRecord.id
                );

                SalesInvoiceLineRecords.add(SalesInvoiceLineRecord1);

                Sales_Invoice_Line__C SalesInvoiceLineRecord2 = new Sales_Invoice_Line__c(
                        Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
                        Resource__c = TestDataUtil.ResourceRecord.Id,
                        Category__c = 'Bundled',
                        Description__c = 'Test',
                        Line_No__c = 5,
                        Quantity__c = 5,
                        Unit_Price__c = 2,
                        Line_Amount__c = 0,
                        Line_Amt_Incl_Tax__c = 0,
                        Tax__c = 0,
                        Tax_Group__c = 'NT',
                        Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
                        TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
                        TM__c = TestDataUtil.TMRecord.id
                );

                SalesInvoiceLineRecords.add(SalesInvoiceLineRecord2);

                Sales_Invoice_Line__C SalesInvoiceLineRecord3 = new Sales_Invoice_Line__c(
                        Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
                        Resource__c = TestDataUtil.ResourceRecord.Id,
                        Category__c = 'Materials',
                        Description__c = 'Test',
                        Line_No__c = 5,
                        Quantity__c = 5,
                        Unit_Price__c = 2,
                        Line_Amount__c = 0,
                        Line_Amt_Incl_Tax__c = 0,
                        Tax__c = 0,
                        Tax_Group__c = 'NT',
                        Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
                        TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
                        TM__c = TestDataUtil.TMRecord.id
                );

                SalesInvoiceLineRecords.add(SalesInvoiceLineRecord3);

                Sales_Invoice_Line__C SalesInvoiceLineRecord4 = new Sales_Invoice_Line__c(
                        Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
                        Resource__c = TestDataUtil.ResourceRecord.Id,
                        Category__c = 'Subcontractors',
                        Description__c = 'Test',
                        Line_No__c = 5,
                        Quantity__c = 5,
                        Unit_Price__c = 2,
                        Line_Amount__c = 0,
                        Line_Amt_Incl_Tax__c = 0,
                        Tax__c = 0,
                        Tax_Group__c = 'NT',
                        Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
                        TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
                        TM__c = TestDataUtil.TMRecord.id
                );

                SalesInvoiceLineRecords.add(SalesInvoiceLineRecord4);

                Sales_Invoice_Line__C SalesInvoiceLineRecord5 = new Sales_Invoice_Line__c(
                        Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
                        Resource__c = TestDataUtil.ResourceRecord.Id,
                        Category__c = 'Waste Disposal',
                        Description__c = 'Test',
                        Line_No__c = 5,
                        Quantity__c = 5,
                        Unit_Price__c = 2,
                        Line_Amount__c = 0,
                        Line_Amt_Incl_Tax__c = 0,
                        Tax__c = 0,
                        Tax_Group__c = 'NT',
                        Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
                        TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
                        TM__c = TestDataUtil.TMRecord.id
                );

                SalesInvoiceLineRecords.add(SalesInvoiceLineRecord5);

                Sales_Invoice_Line__C SalesInvoiceLineRecord6 = new Sales_Invoice_Line__c(
                        Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
                        Resource__c = TestDataUtil.ResourceRecord.Id,
                        Category__c = 'Demurrage',
                        Description__c = 'Test',
                        Line_No__c = 5,
                        Quantity__c = 5,
                        Unit_Price__c = 2,
                        Line_Amount__c = 0,
                        Line_Amt_Incl_Tax__c = 0,
                        Tax__c = 0,
                        Tax_Group__c = 'NT',
                        Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
                        TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
                        TM__c = TestDataUtil.TMRecord.id
                );

                SalesInvoiceLineRecords.add(SalesInvoiceLineRecord6);

                Sales_Invoice_Line__C SalesInvoiceLineRecord7 = new Sales_Invoice_Line__c(
                        Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
                        Resource__c = TestDataUtil.ResourceRecord.Id,
                        Category__c = 'Misc. Charges And Taxes',
                        Description__c = 'Test',
                        Line_No__c = 5,
                        Quantity__c = 5,
                        Unit_Price__c = 2,
                        Line_Amount__c = 0,
                        Line_Amt_Incl_Tax__c = 0,
                        Tax__c = 0,
                        Tax_Group__c = 'NT',
                        Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
                        TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
                        TM__c = TestDataUtil.TMRecord.id,
                        Resource_Type__c = TestDataUtil.ResourceTypeRecord.id
                );

                SalesInvoiceLineRecords.add(SalesInvoiceLineRecord7);

                insert SalesInvoiceLineRecords;
            }
            return SalesInvoiceLineRecords;
        }
        private set;
    }

    public static Holiday__c holidayRecord{
        get{
            if(holidayRecord == null){
                holidayRecord = new Holiday__c();
                holidayRecord.Name = 'Christmas';
                holidayRecord.Date__c = Date.newInstance(2019, 12, 25);
                holidayRecord.Holiday__c = 'Christmas';
                holidayRecord.Holiday_Name_Map__c = 'Christmas';
                insert holidayRecord;
            }
            return holidayRecord;
        }
    }

    public static Pay_Rule__c companyPayRuleRecord{
        get{
            if(companyPayRuleRecord == null){
                companyPayRuleRecord = new Pay_Rule__c();
                companyPayRuleRecord.Name = 'Company Default';
                companyPayRuleRecord.Pay_Holiday__c = true;
                companyPayRuleRecord.Work_Before_or_After_Holiday_to_Qualify__c = true;
                insert companyPayRuleRecord;
            }
            return companyPayRuleRecord;
        }
        private set;
    }

    public static Pay_Rule_Holiday__c payRuleHolidayRecord{
        get{
            if(payRuleHolidayRecord == null){
                payRuleHolidayRecord = new Pay_Rule_Holiday__c();
                payRuleHolidayRecord.Pay_Rule__c = companyPayRuleRecord.Id;
                payRuleHolidayRecord.Name = 'Christmas';
                payRuleHolidayRecord.Holiday__c = 'Christmas';
                payRuleHolidayRecord.Pay_Code__c = 'DBT';
                insert payRuleHolidayRecord;
            }
            return payRuleHolidayRecord;
        }
        private set;
    }

    public static Pay_Rule__c pwPayRuleRecord{
        get{
            if(companyPayRuleRecord == null){
                companyPayRuleRecord = new Pay_Rule__c();
                companyPayRuleRecord.Name = 'PW Payrule';
                companyPayRuleRecord.Type__c = 'Prevailing Wage';
                companyPayRuleRecord.Pay_Travel_Time__c = true;
                insert companyPayRuleRecord;
            }
            return companyPayRuleRecord;
        }
        private set;
    }

    public static Pay_Rule_Line__c pwPayRuleLineRecord{
        get{
            if(pwPayRuleLineRecord == null){
                pwPayRuleLineRecord = new Pay_Rule_Line__c();
                pwPayRuleLineRecord.Pay_Rule__c = pwPayRuleRecord.Id;
                pwPayRuleLineRecord.Resource_Type__c = ResourceTypeRecord.Id;
                pwPayRuleLineRecord.Rate__c = 32;
                pwPayRuleLineRecord.Daily_OT_After_Num_of_Hours__c = 8;
                pwPayRuleLineRecord.Overtime_Rate_Multiple__c = 1.5;
                pwPayRuleLineRecord.Double_Time_Rate_Multiple__c = 2;
                pwPayRuleLineRecord.Sunday_Pay_Code__c = 'OT';
                pwPayRuleLineRecord.Holidays_with_Overtime_Pay__c = 'Christmas';
                insert pwPayRuleLineRecord;
            }
            return pwPayRuleLineRecord;
        }
        private set;
    }

    public static ResourceTypeUOMAssociation__c resourceTypeUOMAssociationRec{
        get{
            if(resourceTypeUOMAssociationRec == null){
                resourceTypeUOMAssociationRec = new ResourceTypeUOMAssociation__c();
                resourceTypeUOMAssociationRec.Resource_Type__c = ResourceTypeRecord.Id;
                resourceTypeUOMAssociationRec.Unit_of_Measure__c = UnitMeasureRecord.Id;
                resourceTypeUOMAssociationRec.Name = UnitMeasureRecord.Name;
                resourceTypeUOMAssociationRec.Unit_Price__c = 50;
                resourceTypeUOMAssociationRec.ER_Unit_Price__c = 50;
                resourceTypeUOMAssociationRec.Unit_Cost__c = 10;
                insert resourceTypeUOMAssociationRec;
            }
            return resourceTypeUOMAssociationRec;
        }
        private set;
    }

    public static ResourceTypeUOMAssociation__c equipmentResourceTypeUOMAssociationRec{
        get{
            if(equipmentResourceTypeUOMAssociationRec == null){
                equipmentResourceTypeUOMAssociationRec = new ResourceTypeUOMAssociation__c();
                equipmentResourceTypeUOMAssociationRec.Resource_Type__c = ResourceTypeEquipmentRecord.Id;
                equipmentResourceTypeUOMAssociationRec.Unit_of_Measure__c = UnitMeasureRecord.Id;
                equipmentResourceTypeUOMAssociationRec.Name = UnitMeasureRecord.Name;
                equipmentResourceTypeUOMAssociationRec.Unit_Price__c = 10;
                equipmentResourceTypeUOMAssociationRec.ER_Unit_Price__c = 10;
                equipmentResourceTypeUOMAssociationRec.Unit_Cost__c = 4;
                insert equipmentResourceTypeUOMAssociationRec;
            }
            return equipmentResourceTypeUOMAssociationRec;
        }
        private set;
    }

    public static ResourceUOMAssociation__c resourceUOMAssociationRec{
        get{
            if(resourceUOMAssociationRec == null){
                resourceUOMAssociationRec = new ResourceUOMAssociation__c();
                resourceUOMAssociationRec.Resource__c = ResourceRecord.Id;
                resourceUOMAssociationRec.Unit_of_Measure__c = UnitMeasureRecord.Id;
                resourceUOMAssociationRec.Name = UnitMeasureRecord.Name;
                resourceUOMAssociationRec.Unit_Price__c = 100;
                resourceUOMAssociationRec.ER_Unit_Price__c = 100;
                resourceUOMAssociationRec.Unit_Cost__c = 20;
                insert resourceUOMAssociationRec;
            }
            return resourceUOMAssociationRec;
        }
        private set;
    }

    public static ResourceUOMAssociation__c materialResourceUOMAssociationRec{
        get{
            if(materialResourceUOMAssociationRec == null){
                materialResourceUOMAssociationRec = new ResourceUOMAssociation__c();
                materialResourceUOMAssociationRec.Resource__c = ResourceMaterialRecord.Id;
                materialResourceUOMAssociationRec.Unit_of_Measure__c = UnitMeasureRecord.Id;
                materialResourceUOMAssociationRec.Unit_Price__c = 100;
                materialResourceUOMAssociationRec.ER_Unit_Price__c = 100;
                materialResourceUOMAssociationRec.Unit_Cost__c = 20;
                insert materialResourceUOMAssociationRec;
            }
            return materialResourceUOMAssociationRec;
        }
        private set;
    }

    public static ResourceUOMAssociation__c wasteResourceUOMAssociationRec{
        get{
            if(wasteResourceUOMAssociationRec == null){
                wasteResourceUOMAssociationRec = new ResourceUOMAssociation__c();
                wasteResourceUOMAssociationRec.Resource__c = ResourceWasteDisposalRecord.Id;
                wasteResourceUOMAssociationRec.Unit_of_Measure__c = UnitMeasureRecord.Id;
                wasteResourceUOMAssociationRec.Unit_Price__c = 100;
                wasteResourceUOMAssociationRec.ER_Unit_Price__c = 100;
                wasteResourceUOMAssociationRec.Unit_Cost__c = 20;
                insert wasteResourceUOMAssociationRec;
            }
            return wasteResourceUOMAssociationRec;
        }
        private set;
    }

    public static Rate_Sheet__c rateSheetRec{
        get{
            if(rateSheetRec == null){
                rateSheetRec = new Rate_Sheet__c();
                rateSheetRec.Name = 'ACV Rate';
                insert rateSheetRec;
            }
            return rateSheetRec;
        }
        private set;
    }

    public static Rate_Sheet_Line__c rateSheetLineRec{
        get{
            if(rateSheetLineRec == null){
                rateSheetLineRec = new Rate_Sheet_Line__c();
                rateSheetLineRec.Rate_Sheet__c = rateSheetRec.Id;
                rateSheetLineRec.Resource_Type__c = ResourceTypeRecord.Id;
                rateSheetLineRec.Unit_of_Measure__c = UnitMeasureRecord.Id;
                rateSheetLineRec.Unit_Price__c = 100;
                rateSheetLineRec.ER_Unit_Price__c = 100;
                rateSheetLineRec.Unit_Cost__c = 50;
                rateSheetLineRec.Default__c = true;
                insert rateSheetLineRec;
            }
            return rateSheetLineRec;
        }
        private set;
    }

    public static Rate_Sheet_Line__c rateSheetLineMaterialRec{
        get{
            if(rateSheetLineMaterialRec == null){
                rateSheetLineMaterialRec = new Rate_Sheet_Line__c();
                rateSheetLineMaterialRec.Rate_Sheet__c = rateSheetRec.Id;
                rateSheetLineMaterialRec.Resource__c = ResourceMaterialRecord.Id;
                rateSheetLineMaterialRec.Unit_of_Measure__c = UnitMeasureRecord.Id;
                rateSheetLineMaterialRec.Unit_Price__c = 100;
                rateSheetLineMaterialRec.ER_Unit_Price__c = 100;
                rateSheetLineMaterialRec.Unit_Cost__c = 50;
                rateSheetLineMaterialRec.Default__c = true;
                insert rateSheetLineMaterialRec;
            }
            return rateSheetLineMaterialRec;
        }
        private set;
    }

    public static Billing_Rule__c billingRule{
        get{
            if(billingRule == null){
                //billing rules
                billingRule = new Billing_Rule__c();
                billingRule.Name = 'Company Default';
                billingRule.Holidays_Bill_in_DT_Rate__c = 'Christmas Day Company';
                billingRule.Holidays_Bill_in_OT_Rate__c = 'Thanksgiving';
                billingRule.Sunday_Rate_Code__c = EnumUtil.TimeRateCode.DT.name();
                billingRule.Saturday_Rate_Code__c = EnumUtil.TimeRateCode.OT.name();
                billingRule.Quote_Order_Assumption__c = 'PortalBasisAdv;LumpSum;DailyRate;OvertimeRate;PortalBasis';
                insert billingRule;

                //billing rule lines
                List<Billing_Rule_Line__c> billingRuleLines = new List<Billing_Rule_Line__c>();
                Billing_Rule_Line__c billingRuleLine = new Billing_Rule_Line__c();
                billingRuleLine.Billing_Rule__c = billingRule.Id;
                billingRuleLine.Billing_Rule__r = billingRule;
                billingRuleLine.Calculation_Type__c = 'Time_Based';
                billingRuleLine.Day__c = 'Monday';
                billingRuleLine.Rate_Code__c = 'OT';
                billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
                billingRuleLine.End_Time__c = Time.newInstance(7,30,0,0);
                billingRuleLines.add(billingRuleLine);

                billingRuleLine = new Billing_Rule_Line__c();
                billingRuleLine.Billing_Rule__c = billingRule.Id;
                billingRuleLine.Billing_Rule__r = billingRule;
                billingRuleLine.Calculation_Type__c = 'Time_Based';
                billingRuleLine.Day__c = 'Monday';
                billingRuleLine.Rate_Code__c = 'REG';
                billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
                billingRuleLine.End_Time__c = Time.newInstance(15,30,0,0);
                billingRuleLine.Hours_After_Number_of_Hours__c = 8;
                billingRuleLine.Rate_Code_After_Number_of_Hours__c = 'OT';
                billingRuleLines.add(billingRuleLine);

                billingRuleLine = new Billing_Rule_Line__c();
                billingRuleLine.Billing_Rule__c = billingRule.Id;
                billingRuleLine.Billing_Rule__r = billingRule;
                billingRuleLine.Calculation_Type__c = 'Time_Based';
                billingRuleLine.Day__c = 'Monday';
                billingRuleLine.Rate_Code__c = 'OT';
                billingRuleLine.Start_Time__c = Time.newInstance(15,30,0,0);
                billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
                billingRuleLines.add(billingRuleLine);

                billingRuleLine = new Billing_Rule_Line__c();
                billingRuleLine.Billing_Rule__c = billingRule.Id;
                billingRuleLine.Billing_Rule__r = billingRule;
                billingRuleLine.Calculation_Type__c = 'Hour_Based';
                billingRuleLine.Day__c = 'Tuesday';
                billingRuleLine.Number_of_Hours__c = 8;
                billingRuleLine.Rate_Code__c = 'REG';
                billingRuleLine.Rate_Code_for_Remaining_Hours__c = 'OT';
                billingRuleLines.add(billingRuleLine);

                billingRuleLine = new Billing_Rule_Line__c();
                billingRuleLine.Billing_Rule__c = billingRule.Id;
                billingRuleLine.Billing_Rule__r = billingRule;
                billingRuleLine.Calculation_Type__c = 'Time_Based';
                billingRuleLine.Day__c = 'Wednesday';
                billingRuleLine.Rate_Code__c = 'REG';
                billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
                billingRuleLine.End_Time__c = Time.newInstance(15,0,0,0);
                billingRuleLines.add(billingRuleLine);

                billingRuleLine = new Billing_Rule_Line__c();
                billingRuleLine.Billing_Rule__c = billingRule.Id;
                billingRuleLine.Billing_Rule__r = billingRule;
                billingRuleLine.Calculation_Type__c = 'Time_Based';
                billingRuleLine.Day__c = 'Wednesday';
                billingRuleLine.Rate_Code__c = 'DT';
                billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
                billingRuleLine.End_Time__c = Time.newInstance(7,0,0,0);
                billingRuleLines.add(billingRuleLine);

                billingRuleLine = new Billing_Rule_Line__c();
                billingRuleLine.Billing_Rule__c = billingRule.Id;
                billingRuleLine.Billing_Rule__r = billingRule;
                billingRuleLine.Calculation_Type__c = 'Time_Based';
                billingRuleLine.Day__c = 'Wednesday';
                billingRuleLine.Rate_Code__c = 'DT';
                billingRuleLine.Start_Time__c = Time.newInstance(15,0,0,0);
                billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
                billingRuleLines.add(billingRuleLine);

                billingRuleLine = new Billing_Rule_Line__c();
                billingRuleLine.Billing_Rule__c = billingRule.Id;
                billingRuleLine.Billing_Rule__r = billingRule;
                billingRuleLine.Calculation_Type__c = 'Time_Based';
                billingRuleLine.Day__c = 'Thursday';
                billingRuleLine.Rate_Code__c = 'REG';
                billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
                billingRuleLine.End_Time__c = Time.newInstance(15,0,0,0);
                billingRuleLines.add(billingRuleLine);

                billingRuleLine = new Billing_Rule_Line__c();
                billingRuleLine.Billing_Rule__c = billingRule.Id;
                billingRuleLine.Billing_Rule__r = billingRule;
                billingRuleLine.Calculation_Type__c = 'Time_Based';
                billingRuleLine.Day__c = 'Thursday';
                billingRuleLine.Rate_Code__c = 'DT';
                billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
                billingRuleLine.End_Time__c = Time.newInstance(7,0,0,0);
                billingRuleLines.add(billingRuleLine);

                billingRuleLine = new Billing_Rule_Line__c();
                billingRuleLine.Billing_Rule__c = billingRule.Id;
                billingRuleLine.Billing_Rule__r = billingRule;
                billingRuleLine.Calculation_Type__c = 'Time_Based';
                billingRuleLine.Day__c = 'Thursday';
                billingRuleLine.Rate_Code__c = 'DT';
                billingRuleLine.Start_Time__c = Time.newInstance(15,0,0,0);
                billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
                billingRuleLines.add(billingRuleLine);

                billingRuleLine = new Billing_Rule_Line__c();
                billingRuleLine.Billing_Rule__c = billingRule.Id;
                billingRuleLine.Billing_Rule__r = billingRule;
                billingRuleLine.Calculation_Type__c = 'Hour_Based';
                billingRuleLine.Day__c = 'Friday';
                billingRuleLine.Number_of_Hours__c = 8;
                billingRuleLine.Rate_Code__c = 'REG';
                billingRuleLine.Hours_After_Number_of_Hours__c = 3;
                billingRuleLine.Rate_Code_After_Number_of_Hours__c = 'OT';
                billingRuleLine.Rate_Code_for_Remaining_Hours__c = 'DT';
                billingRuleLines.add(billingRuleLine);

                billingRuleLine = new Billing_Rule_Line__c();
                billingRuleLine.Billing_Rule__c = billingRule.Id;
                billingRuleLine.Billing_Rule__r = billingRule;
                billingRuleLine.Calculation_Type__c = 'Day_Based';
                billingRuleLine.Day__c = 'Saturday';
                billingRuleLine.Rate_Code__c = 'OT';
                billingRuleLines.add(billingRuleLine);
                insert billingRuleLines;
            }
            return billingRule;
        }
        private set;
    }

}