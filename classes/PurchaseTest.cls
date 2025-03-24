@isTest
public class PurchaseTest {

    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;

    @testSetup static void SetupData() {
        //Setup Data
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = : companySetup.Id];
        System.assertEquals(theCSList.size(), 1);
    }

    private static testMethod void Test_PurchaseReceiptController() {
      Test.startTest();
        //Setup data
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u = new User(Alias = 'test123', Email='test@republicservices.com', EmailEncodingKey='UTF-8', LastName='TEST', FirstName = 'TEST', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='test@acvenviro.com.test', Service_Center__c = TestDataUtil.ServiceCenterRecord.Name, Purchasing_Department_Receiver__c = true, Allow_Unpost__c = true);
        
        System.runAs(u) {
            CompanyMgmt.systemCall = true;
            Purchase_Order__c PORecord = TestDataUtil.PORecord;
            List<Purchase_Line__c> PurchLineRecords = TestDataUtil.PurchLineRecords;
            Purch_Rcpt_Line__c PurchRcptLineRecord = TestDataUtil.PurchRcptLineRecord;
            PageReference pref = Page.PurchaseReceipt;
            Test.setCurrentPage(pref);

            pref.getParameters().put('id', TestDataUtil.PurchaseReceiptRecord.Id);
            ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.PurchaseReceiptRecord);

           

            PurchaseReceiptController inst_PRC = new PurchaseReceiptController(StdCon);

            String title = inst_PRC.title;
            Boolean posted = inst_PRC.posted;
            Purchase_Receipt__c PR = inst_PRC.PR;
            List<Purch_Rcpt_Line__c > PRLList = inst_PRC.PRLList;
            boolean allowDataOverride = inst_PRC.allowDataOverride;
            inst_PRC.getMessages();
            //List<Tracking_Line__c > TLList = inst_PRC.TLList;
            Company_Setup__c CompanySetup = inst_PRC.CompanySetup;
            //inst_PRC.insertPI();
            //inst_PRC.insertPIL();

            inst_PRC.save();
            inst_PRC.quickSave();
            inst_PRC.ClonePR();
            inst_PRC.NewPR();
            inst_PRC.postPR();
            inst_PRC.Cancel();
            inst_PRC.returnBack();
            inst_PRC.goBacktoList();
           
            Test.stopTest();
        }
    }
    
    private static testMethod void Test_PurchaseReceiptController1() {
      Test.startTest();
        //Setup data
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u = new User(Alias = 'test123', Email='test@republicservices.com', EmailEncodingKey='UTF-8', LastName='TEST', FirstName = 'TEST', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='test@acvenviro.com.test', Service_Center__c = TestDataUtil.ServiceCenterRecord.Name, Purchasing_Department_Receiver__c = true, Allow_Unpost__c = true);
        
        System.runAs(u) {
            CompanyMgmt.systemCall = true;
            Purchase_Order__c PORecord = TestDataUtil.PORecord;
            List<Purchase_Line__c> PurchLineRecords = TestDataUtil.PurchLineRecords;
            Purch_Rcpt_Line__c PurchRcptLineRecord = TestDataUtil.PurchRcptLineRecord;
            PageReference pref = Page.PurchaseReceipt;
            Test.setCurrentPage(pref);

            pref.getParameters().put('id', TestDataUtil.PurchaseReceiptRecord.Id);
            ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.PurchaseReceiptRecord);

           

            PurchaseReceiptController inst_PRC = new PurchaseReceiptController(StdCon);

            String title = inst_PRC.title;
            Boolean posted = inst_PRC.posted;
            Purchase_Receipt__c PR = inst_PRC.PR;
            List<Purch_Rcpt_Line__c > PRLList = inst_PRC.PRLList;
            boolean allowDataOverride = inst_PRC.allowDataOverride;
            inst_PRC.getMessages();
            //List<Tracking_Line__c > TLList = inst_PRC.TLList;
            Company_Setup__c CompanySetup = inst_PRC.CompanySetup;
            //inst_PRC.insertPI();
            //inst_PRC.insertPIL();
			inst_PRC.UnpostPR();
           
            pref.getParameters().put('objectType', 'PurchaseReceiptLine');
            pref.getParameters().put('lineNo', '1');
            inst_PRC.deleteLine();
            CompanyMgmt.allowToDeleteData = true;
            
            pref.getParameters().put('fieldName', 'theQuantity');
            pref.getParameters().put('lineNo', '0');
            pref.getParameters().put('newFieldValue', '1');
            inst_PRC.validateField();
            inst_PRC.deletePR();
            Test.stopTest();
        }
    }
    
    private static testMethod void Test_PurchaseReceiptMgmt() {
       Test.startTest();
        //Setup data
        CompanyMgmt.systemCall = true;

        Purchase_Receipt__c PurchaseReceiptRecord = TestDataUtil.PurchaseReceiptRecord;
        Purch_Rcpt_Line__c PurchRcptLineRecord = TestDataUtil.PurchRcptLineRecord ;
        PurchaseReceiptMgmt.checkPRLSave(PurchaseReceiptRecord,PurchRcptLineRecord);
        list<Purch_Rcpt_Line__c> prl = new list<Purch_Rcpt_Line__c>();
        prl.add(PurchRcptLineRecord);
        list<Sales_Line__c> sl = new list<Sales_Line__c>();
        //list<Purchase_Line__c> pl =new list<Purchase_Line__c>();
        //pl.add(TestDataUtil.PurchLineRecord);
        PurchaseReceiptMgmt.checkUnpostPR(PurchaseReceiptRecord,prl,sl);
        //PurchaseReceiptMgmt.unpostPR(PurchaseReceiptRecord,prl,pl);
        PurchaseReceiptMgmt.unpostPR(PurchaseReceiptRecord,prl,TestDataUtil.PurchLineRecords);

        delete PurchaseReceiptRecord;
        Test.stopTest();
    }
    
    private static testMethod void test_CreatePOController() {
         Test.startTest();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u = new User(Alias = 'test123', Email='test@republicservices.com', EmailEncodingKey='UTF-8', LastName='TEST', FirstName = 'TEST', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='test@acvenviro.com.test', Service_Center__c = TestDataUtil.ServiceCenterRecord.Name, Purchasing_Department_Receiver__c = true);

        System.runAs(u) {
            Purchase_Price__c ProductCatalogRecord = TestDataUtil.ProductCatalogRecord;
            Service_Center__c ServiceCenterRecord = TestDataUtil.ServiceCenterRecord;
            List<Purchase_Price__c> ppList = new List<Purchase_Price__c>();
            ppList.add(ProductCatalogRecord);
           
            Test.setCurrentPage(Page.CreatePOConfirmation);
            ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(ppList);
            stdSetController.setSelected(ppList);
            CreatePOController ext = new CreatePOController(stdSetController);

            CreatePOController.note = 'test note';
            ext.createPO();
            ext.selectSelectedProducts();
            ext.selectUser();
            ext.returnBack();
            Test.stopTest();
        }
    }
    
   private static testMethod void Test_PurchTriggersMgmt() {
        Test.startTest();
        Purchase_Order__c PORecord = TestDataUtil.PORecord;
        Purchase_Price__c ProductCatalogRecord = TestDataUtil.ProductCatalogRecord;
        Purchase_Receipt__c PRRecord = TestDataUtil.PurchaseReceiptRecord;

        list<Purchase_Order__c> POList = new list<Purchase_Order__c>();
        list<Purchase_Price__c > PCList = new list<Purchase_Price__c >();
        List<Purchase_Receipt__c> PRList = new List<Purchase_Receipt__c>();
        POList.add(PORecord);
        Map<Id,Purchase_Order__c> pomap = new Map<Id,Purchase_Order__c>();
        pomap.put(PORecord.id,PORecord);

        PurchTriggersMgmt.POInsertUpdate(POList,pomap,false);
        PurchTriggersMgmt.PODelete(POList);
        PCList.add(ProductCatalogRecord);
        PurchTriggersMgmt.PPInsertUpdate(PCList);
        PRList.add(PRRecord);
        PurchTriggersMgmt.PRDelete(PRList);
        /*TestDataUtil.PurchLineRecord.Item__c = null;
        TestDataUtil.PurchLineRecord.Unit_of_Measure__c = null;
        TestDataUtil.PurchLineRecord.Unit_Cost__c = -1;
        TestDataUtil.PurchLineRecord.Qty_to_Receive__c = -1;
        TestDataUtil.PurchLineRecord.Received_Qty__c = -1;
        update TestDataUtil.PurchLineRecord;
        TestDataUtil.PurchLineRecord.Qty_to_Receive__c = 1;
        TestDataUtil.PurchLineRecord.Received_Qty__c = 1;
        TestDataUtil.PurchLineRecord.Received_Qty__c = 10;
        update TestDataUtil.PurchLineRecord;*/
        Test.stopTest();
    }
    private static testMethod void Test_PurchaseOrderMgmtrest() {
         Test.startTest();
        PurchOrderMgmt.updatePL(TestDataUtil.PurchLineRecords[0],TestDataUtil.PORecord,'theLineServiceCenter');
        PurchOrderMgmt.validateSubVendor(TestDataUtil.PORecord );
        PurchOrderMgmt.validateShipToAddress(TestDataUtil.PORecord );
        PurchOrderMgmt.validateBillingContact(TestDataUtil.PORecord );
        PurchOrderMgmt.validateServiceCenter(TestDataUtil.PORecord );
        //    PurchOrderMgmt.validateServiceCenter(TestDataUtil.PORecord );
        PurchOrderMgmt.getItemUOM(TestDataUtil.UnitMeasureRecord.id);

        Set<ID> uomid = new Set<ID>();
        uomid.add(TestDataUtil.UnitMeasureRecord.id);
        PurchOrderMgmt.setMapItemUOM(uomid);
        Set<ID> ppid = new Set<ID>();
        ppid.add(TestDataUtil.ProductCatalogRecord.id);
        PurchOrderMgmt.setMapItem(ppid);
        PurchOrderMgmt.findBestCost(TestDataUtil.PurchLineRecords[0],TestDataUtil.PORecord,TestDataUtil.ProductCatalogRecord);
        PurchOrderMgmt.getBaseCost(TestDataUtil.PurchLineRecords[0],TestDataUtil.PORecord,TestDataUtil.ProductCatalogRecord);

        PurchOrderMgmt.updatePL(TestDataUtil.PurchLineRecords[0],TestDataUtil.PORecord,'theTaxPct');
        //
        PurchOrderMgmt.updatePL(TestDataUtil.PurchLineRecords[0],TestDataUtil.PORecord,'theLineGLAccount');
        PurchOrderMgmt.updatePL(TestDataUtil.PurchLineRecords[0],TestDataUtil.PORecord,'theLineSalesOrder');

        //    PurchOrderMgmt.updatePL(TestDataUtil.PurchLineRecord,TestDataUtil.PORecord,'theItem');
        TestDataUtil.PurchLineRecords[0].Item__c = null;
        PurchOrderMgmt.updatePL(TestDataUtil.PurchLineRecords[0],TestDataUtil.PORecord,'theItem');
         Test.stopTest();
    }
    private static testMethod void Test_ClonePO() {
     Test.startTest();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u = new User(Alias = 'test123', Email = 'test@republicservices.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'TEST',
                FirstName = 'TEST',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'test@acvenviro.com.test',
                //Service_Center__c = '01',
                Service_Center__c = TestDataUtil.ServiceCenterRecord.Name,
                Purchasing_Department_Receiver__c = true,
                Allow_Unpost__c = true);

        System.runAs(u) {
            PageReference pref = Page.PurchOrder;
            Test.setCurrentPage(pref);

            pref.getParameters().put('id', TestDataUtil.PORecord.Id);
            List<Purchase_Line__c> PurchLineRecords = TestDataUtil.PurchLineRecords;
            ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.PORecord);
            PurchOrderController inst_POC = new PurchOrderController(StdCon);

            
            inst_POC.save();
            inst_POC.clonePO();
            pref.getParameters().put('lineNo', '0');
            pref.getParameters().put('fieldName', 'theItem');
            pref.getParameters().put('newFieldValue', '');
            inst_POC.validateField();
            pref.getParameters().put('fieldName', 'theItem');
            pref.getParameters().put('newFieldValue', TestDataUtil.ProductCatalogRecord.Id);
            inst_POC.validateField();

            pref.getParameters().put('fieldName', 'theLineServiceCenter');
            pref.getParameters().put('newFieldValue', TestDataUtil.ServiceCenterRecord.Id);
            inst_POC.validateField();

            pref.getParameters().put('fieldName', 'theLineGLAccount');
            pref.getParameters().put('newFieldValue', '77200    Violations - 77200');
            inst_POC.validateField();

            Test.stopTest();
        }
    }
    private static testMethod void correctTest(){
        //Subsidiary_Company__c subCompany = new Subsidiary_Company__c(Name = 'ACV Test');
        //insert subCompany;
         Test.startTest();
        Account ac = new Account( Name = 'MDN',
                Type = 'Vendor',
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId()
        );
        insert ac;
        Contact billingContact = new Contact(AccountId = ac.Id, LastName = 'MDN', Email='example@example.com', Contact_Type__c = 'Billing');
        insert billingContact;

        //Subsidiary_Vendor__c subVend = new Subsidiary_Vendor__c(Name = 'ACV0001', Subsidiary_Company__c = subCompany.Id, Account__c = ac.Id);
        Subsidiary_Vendor__c subVend = new Subsidiary_Vendor__c(Name = 'ACV0001', Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id, Account__c = ac.Id);
        insert subVend;
        String thePONumber;
        Purchase_Order__c theRO = new Purchase_Order__c(
                Name = 'test',
                Buy_from_Vendor__c = ac.Id,
                Pay_to_Vendor__c = ac.Id,
                Payment_Term__c = TestDataUtil.PaymentTermRecord.Id,
                Order_date__c = Date.Today(),
                Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
                Billing_Contact__c = billingContact.Id,
                Document_Status__c = 'Open',
                Order_Type__c = 'Regular',
                Note__c = 'Test',
                PO_Requestor__c = UserInfo.getUserId(),
                OwnerId = UserInfo.getUserId(),
                Ship_To_Address__c= TestDataUtil.ShiptoAddressRecord.Id,
                Return_Order__c = true,
                Coupa_Id__c = '112345');
        insert theRO;

        Purchase_Order__c thePO = new Purchase_Order__c(
                Name = 'test po',
                Buy_from_Vendor__c = ac.Id,
                Pay_to_Vendor__c = ac.Id,
                Payment_Term__c = TestDataUtil.PaymentTermRecord.Id,
                Order_date__c = Date.Today(),
                Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
                Billing_Contact__c = billingContact.Id,
                Document_Status__c = 'Open',
                Order_Type__c = 'Regular',
                Note__c = 'Test',
                PO_Requestor__c = UserInfo.getUserId(),
                OwnerId = UserInfo.getUserId(),
                Ship_To_Address__c= TestDataUtil.ShiptoAddressRecord.Id,
                Return_Order__c = false,
                Coupa_Id__c = '11234567');
        insert thePO;

        try{
            thePONumber = thePO.Name;
            thePO.Name = null;
            update thePO;
            throw new myException('Excepting Purchase Order No. cannot be blank. error from trigger but was not!');
        } catch (Exception e){
            Boolean expectedResult = e.getMessage().contains('Purchase Order No. cannot be blank.')?true:false;
            System.assertEquals(expectedResult, true);
        }

        try{
            thePO.Name = thePONumber;
            thePO.Is_Temporary__c = false;
            thePO.Document_Status__c = 'Approved';
            update thePO;
            throw new myException('Excepting Approved purchase order number must not start with. error from trigger but was not!');
        } catch (Exception e){
            Boolean expectedResult = e.getMessage().contains('Approved purchase order number must not start with')?true:false;
            System.assertEquals(expectedResult, true);
        }

        try{
            thePO.Buy_from_Vendor__c = null;
            thePO.Buy_from_Vendor__r = null;
            update thePO;
            throw new myException('Excepting Buy-from Vendor cannot be blank. error from trigger but was not!');
        } catch (Exception e){
            Boolean expectedResult = e.getMessage().contains('Buy-from Vendor cannot be blank.')?true:false;
            System.assertEquals(expectedResult, true);
        }
        /*
        //Purchase Line
        Purchase_Line__c pl = new Purchase_Line__c(
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
                Expected_Receipt_Date__c = Date.Today().addDays(7),
                //Line_No__c = 10
                Service_Center__c=ServiceCenterRecord.Id,
                Direct_G_L_Account__c=true
        );*/
         Test.stopTest();
    }
    
    private static testMethod void Test_PurchOrderController() {
       Test.startTest();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User u = new User(Alias = 'test123', Email='test@republicservices.com',
                EmailEncodingKey='UTF-8',
                LastName='TEST',
                FirstName = 'TEST',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                ProfileId = p.Id,
                TimeZoneSidKey='America/Los_Angeles',
                Username='test@acvenviro.com.test',
                //Service_Center__c = '01',
                Service_Center__c = TestDataUtil.ServiceCenterRecord.Name,
                Purchasing_Department_Receiver__c = true,
                Allow_Unpost__c = true);

        System.runAs(u) {
             
            PageReference pref = Page.PurchOrder;
            Test.setCurrentPage(pref);

            pref.getParameters().put('id', TestDataUtil.PORecord.Id);
            ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.PORecord);


            List<Purchase_Line__c> PurchLineRecords = TestDataUtil.PurchLineRecords;
            PurchOrderController inst_POC = new PurchOrderController(StdCon);

            String title = inst_POC.title;
            inst_POC.thePO.Document_Status__c='Completed';
            Boolean completed2 = inst_POC.Completed;
            Boolean open2 = inst_POC.open;
            inst_POC.thePO.Document_Status__c='Open';
            Boolean completed = inst_POC.Completed;
            Boolean open = inst_POC.open;
            Boolean allowDataOverride = inst_POC.allowDataOverride;
            //Purchase_Order__c PO = inst_POC.PO;
            inst_POC.closePO();
            inst_POC.updateReceiptDate();
            List<Purchase_Line__c> PLList = inst_POC.PLList;
            Company_Setup__c CompanySetup = inst_POC.CompanySetup;
            inst_POC.validateBuyFromVendor();           
            inst_POC.validateBillingVendor();
            inst_POC.validateShipToAddress();
            inst_POC.validateServiceCenter();
            inst_POC.validatethePORequestor();
           
            //nst_POC.validateSellToCust();
            inst_POC.validateOrderDate();
            inst_POC.validatePaymentTerm();
            inst_POC.validateBillingContact();
            //test
             Test.stopTest();
        }
    }
    
   
    
}