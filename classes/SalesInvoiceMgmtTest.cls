@IsTest
public class SalesInvoiceMgmtTest {
    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    @testSetup static void SetupData() {
        //Setup Data
        CompanyMgmt.byPassTrigger = true;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        Numbering_Series__c NumberingSeriesRecord = new Numbering_Series__c();
                   NumberingSeriesRecord.Name = 'PO Temp Number';
                   NumberingSeriesRecord.Prefix__c = 'SO';
                   NumberingSeriesRecord.Separator__c = '-';
                    NumberingSeriesRecord.Last_Number_Used__c = 10000;
               
                insert NumberingSeriesRecord;
        
            Numbering_Series__c NumberingSeriesRecord1 = new Numbering_Series__c();
                   NumberingSeriesRecord1.Name = 'Sales Invoice';
                   NumberingSeriesRecord1.Prefix__c = 'SO';
                   NumberingSeriesRecord1.Separator__c = '-';
                    NumberingSeriesRecord1.Last_Number_Used__c = 10000;
               
                insert NumberingSeriesRecord1;
        Sales_Invoice__c SalesInvoiceRecord = TestDataUtil.SalesInvoiceRecord;
        Service_Center__c ServiceCenterRecord = TestDataUtil.ServiceCenterRecord;
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        //GL_Account__c GLAccountRecord = TestDataUtil.GLAccountRecord;
        List<Sales_Invoice_Line__c> testSalesInvoiceLineRecords = TestDataUtil.SalesInvoiceLineRecords;
        Resource__c ResourceRecord = TestDataUtil.ResourceRecord;
        Resource_Type__c resourceTypeRecord = TestDataUtil.ResourceTypeRecord;
        GL_Entry__c GLEntryRecord = TestDataUtil.GLEntryRecord;
        Tax_Jurisdiction__c taxJurisdiction = TestDataUtil.TaxJurisdictionRecord;
        Tax_Detail__c taxDetail = TestDataUtil.TaxDetailRecord;
        Tax_Area__c taxArea = TestDataUtil.TaxAreaRecord;
        Sales_Order__c SalesOrderRecord = TestDataUtil.SalesOrderRecord;
        Account AccountRecord = TestDataUtil.AccountRecord;
        SalesPerson__c SalespersonRecord = TestDataUtil.SalespersonRecord;
        Subsidiary_Company__c SubsidiaryCompanyRecord = TestDataUtil.SubsidiaryCompanyRecord;
        Payment_Term__c PaymentTermRecord = TestDataUtil.PaymentTermRecord;
    	        CompanyMgmt.byPassTrigger = false;

    }
    
    private static testMethod void Test_SalesInvoiceMgmt() {
        
        Sales_Invoice__c SalesInvoiceRecord = [Select Id,Credit_Memo__c,Name From Sales_Invoice__c Limit 1];
        
        Sales_Invoice_Line__c SalesInvoiceLineRecord = [Select Id From Sales_Invoice_Line__c Limit 1];
        Tax_Area__c TaxAreaRecord = [Select Id,Sales_Tax_Account__c From Tax_Area__c Limit 1];
        Sales_Order__c SalesOrderRecord = [Select Id,Create_Site_Address__c From Sales_Order__c Limit 1];
        GL_Entry__c GLEntryRecord = [Select Id From GL_Entry__c Limit 1];
        
        Service_Center__c ServiceCenterRecord = [Select Id From Service_Center__c Limit 1];
        
       
        ServiceCenterRecord.Temporary__c = false;
        update ServiceCenterRecord;
        
        Resource__c resource = [Select Id from Resource__c limit 1];
        resource.Exclude_from_I_C_Cost_Calculation__c = false;
        update resource;
        
        Resource_type__c resourceType = [Select id from Resource_Type__c limit 1];
        
        GL_Account__c glacc = new GL_Account__c();
        glacc.name='Test GL';
        insert glacc;
        
        Sales_Invoice_Job_Task__c siJT = new Sales_Invoice_Job_Task__c();
        siJT.Sales_Invoice__c = SalesInvoiceRecord.id;
        siJT.Name='Test';
        siJT.Billing_Type__c = 'Fixed Price';
        insert siJT;
        
        
        resource.Post_Sale_to_Own_GL_Acct_When_Bundled__c = True;
        resource.Sales_GL_Account__c =glacc.id; 
        update resource;
        
        
        SalesInvoiceRecord.Posting_Date__c = Date.today();
        SalesInvoiceRecord.Tax_Area__c = TaxAreaRecord.id;
        SalesInvoiceRecord.Retainage_Amount__c = 1590;
        SalesInvoiceRecord.Document_Status__c ='Open';
        
        // SalesInvoiceRecord.Credit_Memo__c = True;
        //SalesInvoiceRecord.Reversed__c = True;
        //  SalesInvoiceRecord.Reversed_from_SI__c = SalesInvoiceRecord1.id;
        update SalesInvoiceRecord;
        Sales_Invoice__c SalesInvoiceRecord1 = [Select Id,Credit_Memo__c,Name,Bill_to_Customer__r.Inter_co_Account__c,Document_Status__c,Retainage_Invoice__c,
                                                Bill_to_Customer__r.InterCo__c,Service_Center__c,Subsidiary_Company__c,Service_Center__r.Name,Retainage_Amount__c,
                                                Invoice_Amt_Incl_Tax__c,Tax_Area__r.Sales_Tax_Account__c,Posting_Date__c From Sales_Invoice__c where Id=:SalesInvoiceRecord.Id];
        
        // SalesInvoiceRecord.Tax_Area__r.Sales_Tax_Account__c = 1000;
        SalesInvoiceLineRecord.Bill_as_Lump_Sum__c = True;
        SalesInvoiceLineRecord.xLine_Amount__c = 100;
        SalesInvoiceLineRecord.Resource__c = resource.id;
        SalesInvoiceLineRecord.Sales_Invoice_Job_Task__c=siJT.id;
        SalesInvoiceLineRecord.Service_Center__c = ServiceCenterRecord.id;
        SalesInvoiceLineRecord.Scheduled_Date__c = Date.today();
        SalesInvoiceLineRecord.Category__c = 'Labor';
        SalesInvoiceLineRecord.Quantity__c = 2;
        SalesInvoiceLineRecord.Resource_Type__c = resourceType.id;
        SalesInvoiceLineRecord.Line_Cost__c = 20;
        update SalesInvoiceLineRecord;
        
        Sales_Order__c SO = SalesOrderMgmt.validateCreateSiteAddress(SalesOrderRecord);
        SalesInvoiceMgmt.unpostCheck(SalesInvoiceRecord1);
        List<Sales_Invoice_Line__c> theSILList = new List<Sales_Invoice_Line__c>();
        theSILList.add(SalesInvoiceLineRecord);
        
        SalesInvoiceMgmt.updateGL(GLEntryRecord, SalesInvoiceRecord1, False);
        SalesInvoiceMgmt.postSI(theSILList, SalesInvoiceRecord1);
        try{
            SalesInvoiceMgmt.unpostSI(SalesInvoiceRecord1);     
        }catch(Exception e){
            
        }
        
        
          Test.startTest();
        SalesInvoiceRecord.Document_Status__c = 'Posted';
        SalesInvoiceRecord.Posting_Date__c = Date.today().addDays(-1);
        SalesInvoiceRecord.New_Posting_Date__c = Date.today();
        update SalesInvoiceRecord;
        Test.stopTest();
    }
    
    private static testMethod void Test_SalesInvoiceMgmt2() {
        Sales_Invoice__c SalesInvoiceRecord = [Select Id,Contact__r.Blocked__c From Sales_Invoice__c Where Credit_Memo__c =: False Limit 1];
        Sales_Invoice_Line__c SalesInvoiceLineRecord = [Select Id, Resource_Type__c From Sales_Invoice_Line__c WHERE Sales_Invoice__c =: SalesInvoiceRecord.Id Limit 1];
        Tax_Area__c TaxAreaRecord = [Select Id From Tax_Area__c Limit 1];
        Sales_Order__c SalesOrderRecord = [Select Id,Create_Site_Address__c From Sales_Order__c Limit 1];
        GL_Entry__c GLEntryRecord = [Select Id From GL_Entry__c Limit 1];
        Account AccountRecord = [Select Id From Account Limit 1];
        Salesperson__c SalespersonRecord = [Select Id From Salesperson__c Limit 1];
        Subsidiary_Company__c SubsidiaryCompanyRecord = [Select Id From Subsidiary_Company__c Limit 1];
        Service_Center__c ServiceCenterRecord = [Select Id From Service_Center__c Limit 1];
        Payment_Term__c PaymentTermRecord = [Select Id From Payment_Term__c Limit 1];
        SalesInvoiceRecord.Posting_Date__c = Date.newInstance(2020, 1, 1);
        SalesInvoiceRecord.Tax_Area__c = TaxAreaRecord.id;
        
        Test.startTest();
        Sales_Invoice__c reverseFromSI = new Sales_Invoice__c(
            Bill_to_Customer__c = AccountRecord.Id,
            Salesperson__c = SalespersonRecord.Id,
            Account_Executive__c = SalespersonRecord.Id,
            Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
            Tax_Area__c = TaxAreaRecord.Id,
            Service_Center__c = ServiceCenterRecord.Id,
            Document_Status__c = 'Open',
            Sales_Order__c = SalesOrderRecord.Id,
            Payment_Term__c = PaymentTermRecord.Id,
            Posting_Date__c = Date.newInstance(2021, 1, 1)
        );
        insert reverseFromSI;
        SalesInvoiceRecord.Reversed_from_SI__c = reverseFromSI.Id;
        update SalesInvoiceRecord;
        Account acc = AccountRecord;
        acc.Inter_co_Account__c = true;
        update acc;
         Resource_type__c resourceType = [Select id from Resource_Type__c limit 1];
        Sales_Invoice__c SalesInvoiceRecord1 = [Select Id,Document_Status__c,Reversed_from_SI__c,Invoice_Date__c,Bill_to_Customer__r.Inter_co_AR_Account__c,
                                                Bill_to_Customer__r.Inter_co_Revenue_Account__c,Contact__r.Blocked__c,Invoice_Amount__c,Misc_Invoice__c,
                                                Credit_Memo__c,Name,Tax_Area__r.Sales_Tax_Account__c,Posting_Date__c From Sales_Invoice__c where Id=:SalesInvoiceRecord.Id];
        SalesInvoiceLineRecord.Resource_Type__c = resourceType.Id;
        SalesInvoiceRecord1.Bill_To_Customer__r = acc;
        SalesInvoiceRecord1.Document_Status__c ='Open';
        SalesInvoiceRecord1.Invoice_Date__c=System.today();
        SalesInvoiceRecord1.Bill_to_Customer__r.Inter_co_AR_Account__c = acc.Id;
        SalesInvoiceRecord1.Bill_to_Customer__r.Inter_co_Revenue_Account__c = acc.Id;
        //SalesInvoiceRecord.Contact__r.Blocked__c = true;
        List<Sales_Invoice_Line__c> theSILList = new List<Sales_Invoice_Line__c>();
        theSILList.add(SalesInvoiceLineRecord);
        SalesInvoiceMgmt.checkPost(SalesInvoiceRecord1);
        SalesInvoiceRecord.Credit_Memo__c = true;
        SalesInvoiceMgmt.checkPost(SalesInvoiceRecord1);
        SalesInvoiceMgmt.nullRelationshipFields(reverseFromSI);
        salesInvoiceMgmt.setResourceType(theSILList[0],reverseFromSI);
        salesInvoiceMgmt.validateBillToCustomer(reverseFromSI);
        salesInvoiceMgmt.validateContact(SalesInvoiceRecord1);
        Test.stopTest();
        
    }
    private static testMethod void Test_SalesInvoiceMgmt1() {
        
        Sales_Invoice__c SalesInvoiceRecord = [Select Id,Credit_Memo__c From Sales_Invoice__c Limit 1];
        
        Sales_Invoice_Line__c SalesInvoiceLineRecord = [Select Id From Sales_Invoice_Line__c Limit 1];
        Tax_Area__c TaxAreaRecord = [Select Id From Tax_Area__c Limit 1];
        Sales_Order__c SalesOrderRecord = [Select Id,Create_Site_Address__c From Sales_Order__c Limit 1];
        GL_Entry__c GLEntryRecord = [Select Id From GL_Entry__c Limit 1];
        Service_Center__c ServiceCenterRecord = [Select Id From Service_Center__c Limit 1];
        
        
        ServiceCenterRecord.Temporary__c = false;
        update ServiceCenterRecord;
        
        Resource__c resource = [Select Id from Resource__c limit 1];
        resource.Exclude_from_I_C_Cost_Calculation__c = false;
        update resource;
        
        Resource_type__c resourceType = [Select id from Resource_Type__c limit 1];
        Test.startTest();
        GL_Account__c glacc = new GL_Account__c();
        glacc.name='Test GL';
        insert glacc;
        
        Sales_Invoice_Job_Task__c siJT = new Sales_Invoice_Job_Task__c();
        siJT.Sales_Invoice__c = SalesInvoiceRecord.id;
        siJT.Name='Test';
        siJT.Billing_Type__c = 'Fixed Price';
        insert siJT;
        
        
        resource.Post_Sale_to_Own_GL_Acct_When_Bundled__c = True;
        resource.Sales_GL_Account__c =glacc.id; 
        update resource;
        
        SalesInvoiceRecord.Posting_Date__c = Date.today();
        SalesInvoiceRecord.Tax_Area__c = TaxAreaRecord.id;
        //salesInvoiceRecord.Reversed_from_SI__c = reverseFromSI.id;
        SalesInvoiceRecord.Retainage_Amount__c =1590;
        // SalesInvoiceRecord.Retainage_Invoice__c = True;
        SalesInvoiceRecord.Service_Center__c = ServiceCenterRecord.id;
        SalesInvoiceRecord.Credit_Memo__c = True;
        
        update SalesInvoiceRecord;
        
        SalesInvoiceLineRecord.Bill_as_Lump_Sum__c = True;
        SalesInvoiceLineRecord.xLine_Amount__c = 100;
        SalesInvoiceLineRecord.Resource__c = resource.id;
        SalesInvoiceLineRecord.Sales_Invoice_Job_Task__c=siJT.id;
        SalesInvoiceLineRecord.Service_Center__c = ServiceCenterRecord.id;
        SalesInvoiceLineRecord.Scheduled_Date__c = Date.today();
        SalesInvoiceLineRecord.Category__c = 'Labor';
        SalesInvoiceLineRecord.Quantity__c = 2;
        SalesInvoiceLineRecord.Resource_Type__c = resourceType.id;
        update SalesInvoiceLineRecord;
        
        
        List<Sales_Invoice_Line__c> theSILList = new List<Sales_Invoice_Line__c>();
        theSILList.add(SalesInvoiceLineRecord);
        Sales_Invoice__c SalesInvoiceRecord1 = [Select Id,Credit_Memo__c,Name,Bill_to_Customer__r.Inter_co_Account__c,Document_Status__c,Retainage_Invoice__c,Reversed_from_SI__r.Retainage_Invoice__c,
                                                Bill_to_Customer__r.InterCo__c,Service_Center__c,Subsidiary_Company__c,Service_Center__r.Name,Retainage_Amount__c,Reversed__c,
                                                Invoice_Amt_Incl_Tax__c,Tax_Area__r.Sales_Tax_Account__c,Posting_Date__c From Sales_Invoice__c where Id=:SalesInvoiceRecord.Id];
        
        
        SalesInvoiceMgmt.postSI(theSILList, SalesInvoiceRecord1);
        try{
            SalesInvoiceMgmt.unpostSI(SalesInvoiceRecord1);
            
        }catch(Exception e){
            
        }
        SalesInvoiceMgmt.checkReverseSI(SalesInvoiceRecord1);
        
        
        Test.stopTest();
    }
    
    private static testMethod void Test_SalesInvoiceMgmt5() {
        
        Sales_Invoice__c SalesInvoiceRecord = [Select Id,Credit_Memo__c From Sales_Invoice__c Limit 1];
        
        Sales_Invoice_Line__c SalesInvoiceLineRecord = [Select Id From Sales_Invoice_Line__c Limit 1];
        Tax_Area__c TaxAreaRecord = [Select Id From Tax_Area__c Limit 1];
        Sales_Order__c SalesOrderRecord = [Select Id,Create_Site_Address__c From Sales_Order__c Limit 1];
        GL_Entry__c GLEntryRecord = [Select Id From GL_Entry__c Limit 1];
        Service_Center__c ServiceCenterRecord = [Select Id From Service_Center__c Limit 1];
        
        
        ServiceCenterRecord.Temporary__c = false;
        update ServiceCenterRecord;
        
        Resource__c resource = [Select Id from Resource__c limit 1];
        resource.Exclude_from_I_C_Cost_Calculation__c = false;
        update resource;
        
        Resource_type__c resourceType = [Select id from Resource_Type__c limit 1];
        Test.startTest();
        GL_Account__c glacc = new GL_Account__c();
        glacc.name='Test GL';
        insert glacc;
        
        Sales_Invoice_Job_Task__c siJT = new Sales_Invoice_Job_Task__c();
        siJT.Sales_Invoice__c = SalesInvoiceRecord.id;
        siJT.Name='Test';
        siJT.Billing_Type__c = 'Fixed Price';
        insert siJT;
        
        
        resource.Post_Sale_to_Own_GL_Acct_When_Bundled__c = True;
        resource.Sales_GL_Account__c =glacc.id; 
        update resource;
        
        SalesInvoiceRecord.Posting_Date__c = Date.today();
        SalesInvoiceRecord.Tax_Area__c = TaxAreaRecord.id;
        //salesInvoiceRecord.Reversed_from_SI__c = reverseFromSI.id;
        SalesInvoiceRecord.Retainage_Amount__c =1590;
        SalesInvoiceRecord.Retainage_Invoice__c = false;
        SalesInvoiceRecord.Service_Center__c = ServiceCenterRecord.id;
        SalesInvoiceRecord.Credit_Memo__c = True;
        // SalesInvoiceRecord.Invoice_Amt_Incl_Tax__c = 10;
        
        update SalesInvoiceRecord;
        
        SalesInvoiceLineRecord.Bill_as_Lump_Sum__c = True;
        SalesInvoiceLineRecord.xLine_Amount__c = 100;
        SalesInvoiceLineRecord.Line_Amt_Incl_Tax__c =100;
        SalesInvoiceLineRecord.Resource__c = resource.id;
        SalesInvoiceLineRecord.Sales_Invoice_Job_Task__c=siJT.id;
        SalesInvoiceLineRecord.Service_Center__c = ServiceCenterRecord.id;
        SalesInvoiceLineRecord.Scheduled_Date__c = Date.today();
        SalesInvoiceLineRecord.Category__c = 'Labor';
        SalesInvoiceLineRecord.Quantity__c = 2;
        SalesInvoiceLineRecord.Resource_Type__c = resourceType.id;
        SalesInvoiceLineRecord.Tax__c=100;
        update SalesInvoiceLineRecord;
        
        
        List<Sales_Invoice_Line__c> theSILList = new List<Sales_Invoice_Line__c>();
        theSILList.add(SalesInvoiceLineRecord);
        Sales_Invoice__c SalesInvoiceRecord1 = [Select Id,Credit_Memo__c,Invoice_Amount__c,Invoice_Date__c,Tax_Liable__c,Name,Invoice_Tax__c,Bill_to_Customer__r.Inter_co_Account__c,Document_Status__c,Retainage_Invoice__c,Reversed_from_SI__r.Retainage_Invoice__c,
                                                Bill_to_Customer__r.InterCo__c,Service_Center__c,Subsidiary_Company__c,Service_Center__r.Name,Retainage_Amount__c,Reversed__c,
                                                Invoice_Amt_Incl_Tax__c,NT_Amount__c,Payment_Term__c,Tax_Area__r.Sales_Tax_Account__c,Posting_Date__c From Sales_Invoice__c where Id=:SalesInvoiceRecord.Id];
        
         try{
        SalesInvoiceMgmt.postSI(theSILList, SalesInvoiceRecord1);
         }catch(Exception e){
            
        }
        try{
            SalesInvoiceMgmt.unpostCheck(SalesInvoiceRecord1);
            
        }catch(Exception e){
            
        }
        Test.stopTest();
    }
    
    private static testMethod void Test_SalesInvoiceMgmt7() {
        
        Sales_Invoice__c SalesInvoiceRecord = [Select Id,Credit_Memo__c From Sales_Invoice__c Limit 1];
        
        Sales_Invoice_Line__c SalesInvoiceLineRecord = [Select Id From Sales_Invoice_Line__c Limit 1];
        Tax_Area__c TaxAreaRecord = [Select Id From Tax_Area__c Limit 1];
        Sales_Order__c SalesOrderRecord = [Select Id,Create_Site_Address__c From Sales_Order__c Limit 1];
        GL_Entry__c GLEntryRecord = [Select Id From GL_Entry__c Limit 1];
        Service_Center__c ServiceCenterRecord = [Select Id From Service_Center__c Limit 1];
        
        GL_Account__c gla = new GL_Account__c(Name='10000', Description__c='Test Account');
        insert gla;
        
        Subsidiary_Company__c sbc = new Subsidiary_Company__c(Name='Test Sub');
        insert sbc;
        
        GL_Batch__c glb = new GL_Batch__c(Description__c='Test Batch', Subsidiary_Company__c=sbc.Id);
        insert glb;
        
        GL_Entry__c gle2 = new GL_Entry__c(Account_Type__c='Customer', Document_Date__c=Date.today(), Document_No__c='Test Doc 1', Document_Type__c='Invoice',
                                           GL_Account__c = gla.Id, Sales_Invoice__c=SalesInvoiceRecord.Id ,GL_Batch__c = glb.Id, Posting_Date__c=Date.today(), Amount__c = 1000);
        insert gle2;
        
        ServiceCenterRecord.Temporary__c = false;
        update ServiceCenterRecord;
        
        Resource__c resource = [Select Id from Resource__c limit 1];
        resource.Exclude_from_I_C_Cost_Calculation__c = false;
        update resource;
        
        Resource_type__c resourceType = [Select id from Resource_Type__c limit 1];
        Test.startTest();
        GL_Account__c glacc = new GL_Account__c();
        glacc.name='Test GL';
        insert glacc;
        
        Sales_Invoice_Job_Task__c siJT = new Sales_Invoice_Job_Task__c();
        siJT.Sales_Invoice__c = SalesInvoiceRecord.id;
        siJT.Name='Test';
        siJT.Billing_Type__c = 'Fixed Price';
        insert siJT;
        
        
        resource.Post_Sale_to_Own_GL_Acct_When_Bundled__c = True;
        resource.Sales_GL_Account__c =glacc.id; 
        update resource;
        
        SalesInvoiceRecord.Posting_Date__c = Date.today();
        SalesInvoiceRecord.Tax_Area__c = TaxAreaRecord.id;
        //salesInvoiceRecord.Reversed_from_SI__c = reverseFromSI.id;
        SalesInvoiceRecord.Retainage_Amount__c =1590;
        SalesInvoiceRecord.Retainage_Invoice__c = false;
        SalesInvoiceRecord.Service_Center__c = ServiceCenterRecord.id;
        SalesInvoiceRecord.Credit_Memo__c = True;
        SalesInvoiceRecord.Document_Status__c = 'Posted';
        // SalesInvoiceRecord.Invoice_Amt_Incl_Tax__c = 10;
        
        update SalesInvoiceRecord;
        
        SalesInvoiceLineRecord.Bill_as_Lump_Sum__c = True;
        SalesInvoiceLineRecord.xLine_Amount__c = 100;
        SalesInvoiceLineRecord.Line_Amt_Incl_Tax__c =100;
        SalesInvoiceLineRecord.Resource__c = resource.id;
        SalesInvoiceLineRecord.Sales_Invoice_Job_Task__c=siJT.id;
        SalesInvoiceLineRecord.Service_Center__c = ServiceCenterRecord.id;
        SalesInvoiceLineRecord.Scheduled_Date__c = Date.today();
        SalesInvoiceLineRecord.Category__c = 'Labor';
        SalesInvoiceLineRecord.Quantity__c = 2;
        SalesInvoiceLineRecord.Resource_Type__c = resourceType.id;
        SalesInvoiceLineRecord.Tax__c=100;
        update SalesInvoiceLineRecord;
        
        
        List<Sales_Invoice_Line__c> theSILList = new List<Sales_Invoice_Line__c>();
        theSILList.add(SalesInvoiceLineRecord);
        Sales_Invoice__c SalesInvoiceRecord1 = [Select Id,Credit_Memo__c,Invoice_Amount__c,Invoice_Date__c,Tax_Liable__c,Name,Invoice_Tax__c,Bill_to_Customer__r.Inter_co_Account__c,Document_Status__c,Retainage_Invoice__c,Reversed_from_SI__r.Retainage_Invoice__c,
                                                Bill_to_Customer__r.InterCo__c,Service_Center__c,Subsidiary_Company__c,Service_Center__r.Name,Retainage_Amount__c,Reversed__c,
                                                Invoice_Amt_Incl_Tax__c,NT_Amount__c,Payment_Term__c,Tax_Area__r.Sales_Tax_Account__c,Posting_Date__c From Sales_Invoice__c where Id=:SalesInvoiceRecord.Id];
        
        try{
            SalesInvoiceMgmt.unpostCheck(SalesInvoiceRecord1);
            
        }catch(Exception e){
            
        }
        
        Test.stopTest();
    }
    
    private static testMethod void Test_SalesInvoiceMgmt9() {
        
        Sales_Invoice__c SalesInvoiceRecord = [Select Id,Credit_Memo__c,Name From Sales_Invoice__c Limit 1];
        
        Sales_Invoice_Line__c SalesInvoiceLineRecord = [Select Id From Sales_Invoice_Line__c Limit 1];
        Tax_Area__c TaxAreaRecord = [Select Id,Sales_Tax_Account__c From Tax_Area__c Limit 1];
        
   
        
        Service_Center__c ServiceCenterRecord = [Select Id From Service_Center__c Limit 1];
        
        Test.startTest();
        ServiceCenterRecord.Temporary__c = false;
        update ServiceCenterRecord;
        
        Resource__c resource = [Select Id from Resource__c limit 1];
        resource.Exclude_from_I_C_Cost_Calculation__c = false;
        update resource;
        
        Resource_type__c resourceType = [Select id from Resource_Type__c limit 1];
        
        GL_Account__c glacc = new GL_Account__c();
        glacc.name='Test GL';
        insert glacc;
        
        Sales_Invoice_Job_Task__c siJT = new Sales_Invoice_Job_Task__c();
        siJT.Sales_Invoice__c = SalesInvoiceRecord.id;
        siJT.Name='Test';
        siJT.Billing_Type__c = 'Fixed Price';
        insert siJT;
        
        
        resource.Post_Sale_to_Own_GL_Acct_When_Bundled__c = True;
        resource.Sales_GL_Account__c =glacc.id; 
        update resource;
        
        
        
        SalesInvoiceRecord.Posting_Date__c = Date.today();
        SalesInvoiceRecord.Tax_Area__c = TaxAreaRecord.id;
        SalesInvoiceRecord.Retainage_Amount__c = 1590;
        SalesInvoiceRecord.Document_Status__c ='Open';
        SalesInvoiceRecord.Credit_Memo__c= true;
        
        // SalesInvoiceRecord.Credit_Memo__c = True;
        //SalesInvoiceRecord.Reversed__c = True;
        //  SalesInvoiceRecord.Reversed_from_SI__c = SalesInvoiceRecord1.id;
        update SalesInvoiceRecord;
        Sales_Invoice__c SalesInvoiceRecord1 = [Select Id,Credit_Memo__c,Name,Bill_to_Customer__r.Inter_co_Account__c,Document_Status__c,Retainage_Invoice__c,Reversed_from_SI__r.Retainage_Invoice__c,
                                                Bill_to_Customer__r.InterCo__c,Service_Center__c,Subsidiary_Company__c,Service_Center__r.Name,Retainage_Amount__c,
                                                Invoice_Amt_Incl_Tax__c,Tax_Area__r.Sales_Tax_Account__c,Posting_Date__c From Sales_Invoice__c where Id=:SalesInvoiceRecord.Id];
        // SalesInvoiceRecord.Tax_Area__r.Sales_Tax_Account__c = 1000;
        SalesInvoiceLineRecord.Bill_as_Lump_Sum__c = True;
        SalesInvoiceLineRecord.xLine_Amount__c = 100;
        SalesInvoiceLineRecord.Resource__c = resource.id;
        SalesInvoiceLineRecord.Sales_Invoice_Job_Task__c=siJT.id;
        SalesInvoiceLineRecord.Service_Center__c = ServiceCenterRecord.id;
        SalesInvoiceLineRecord.Scheduled_Date__c = Date.today();
        SalesInvoiceLineRecord.Category__c = 'Labor';
        SalesInvoiceLineRecord.Quantity__c = 2;
        SalesInvoiceLineRecord.Resource_Type__c = resourceType.id;
        SalesInvoiceLineRecord.Line_Cost__c = 20;
        update SalesInvoiceLineRecord;
        
        try{
            SalesInvoiceMgmt.unpostSI(SalesInvoiceRecord1);     
        }catch(Exception e){
            
        }
        
        
        Test.stopTest();
    }
    
     private static testMethod void Test_SalesInvoiceMgmt10() {
        
        Sales_Invoice__c SalesInvoiceRecord = [Select Id,Credit_Memo__c From Sales_Invoice__c Limit 1];
        
        Sales_Invoice_Line__c SalesInvoiceLineRecord = [Select Id From Sales_Invoice_Line__c Limit 1];
        Tax_Area__c TaxAreaRecord = [Select Id From Tax_Area__c Limit 1];
        Sales_Order__c SalesOrderRecord = [Select Id,Create_Site_Address__c From Sales_Order__c Limit 1];
        GL_Entry__c GLEntryRecord = [Select Id From GL_Entry__c Limit 1];
        Service_Center__c ServiceCenterRecord = [Select Id From Service_Center__c Limit 1];
        
        
        ServiceCenterRecord.Temporary__c = false;
        update ServiceCenterRecord;
        
        Resource__c resource = [Select Id from Resource__c limit 1];
        resource.Exclude_from_I_C_Cost_Calculation__c = false;
        update resource;
        
        Resource_type__c resourceType = [Select id from Resource_Type__c limit 1];
        Test.startTest();
        GL_Account__c glacc = new GL_Account__c();
        glacc.name='Test GL';
        insert glacc;
        
        Sales_Invoice_Job_Task__c siJT = new Sales_Invoice_Job_Task__c();
        siJT.Sales_Invoice__c = SalesInvoiceRecord.id;
        siJT.Name='Test';
        siJT.Billing_Type__c = 'Fixed Price';
        insert siJT;
        
        
        resource.Post_Sale_to_Own_GL_Acct_When_Bundled__c = True;
        resource.Sales_GL_Account__c =glacc.id; 
        update resource;
        
        SalesInvoiceRecord.Posting_Date__c = Date.today();  
        SalesInvoiceRecord.Tax_Area__c = TaxAreaRecord.id;
        //salesInvoiceRecord.Reversed_from_SI__c = reverseFromSI.id;
        SalesInvoiceRecord.Retainage_Amount__c =1590;
        SalesInvoiceRecord.Retainage_Invoice__c = false;
        SalesInvoiceRecord.Service_Center__c = ServiceCenterRecord.id;
        SalesInvoiceRecord.Credit_Memo__c = false;
         SalesInvoiceRecord.Retainage_Invoice__c = false;

        // SalesInvoiceRecord.Invoice_Amt_Incl_Tax_ _c = 10;
        
        update SalesInvoiceRecord;
        
        SalesInvoiceLineRecord.Bill_as_Lump_Sum__c = True;
        SalesInvoiceLineRecord.xLine_Amount__c = 100;
        SalesInvoiceLineRecord.Line_Amt_Incl_Tax__c =100;
        SalesInvoiceLineRecord.Resource__c = resource.id;
        SalesInvoiceLineRecord.Sales_Invoice_Job_Task__c=siJT.id;
        SalesInvoiceLineRecord.Service_Center__c = ServiceCenterRecord.id;
        SalesInvoiceLineRecord.Scheduled_Date__c = Date.today();
        SalesInvoiceLineRecord.Category__c = 'Labor';
        SalesInvoiceLineRecord.Quantity__c = 2;
        SalesInvoiceLineRecord.Resource_Type__c = resourceType.id;
        SalesInvoiceLineRecord.Tax__c=100;
        update SalesInvoiceLineRecord;
        
        
        List<Sales_Invoice_Line__c> theSILList = new List<Sales_Invoice_Line__c>();
        theSILList.add(SalesInvoiceLineRecord);
        Sales_Invoice__c SalesInvoiceRecord1 = [Select Id,Credit_Memo__c,Invoice_Amount__c,Invoice_Date__c,Tax_Liable__c,Name,Invoice_Tax__c,Bill_to_Customer__r.Inter_co_Account__c,Document_Status__c,Retainage_Invoice__c,Reversed_from_SI__r.Retainage_Invoice__c,
                                                Bill_to_Customer__r.InterCo__c,Service_Center__c,Subsidiary_Company__c,Service_Center__r.Name,Retainage_Amount__c,Reversed__c,
                                                Invoice_Amt_Incl_Tax__c,NT_Amount__c,Payment_Term__c,Tax_Area__r.Sales_Tax_Account__c,Posting_Date__c From Sales_Invoice__c where Id=:SalesInvoiceRecord.Id];
        
         try{
        SalesInvoiceMgmt.postSI(theSILList, SalesInvoiceRecord1);
         }catch(Exception e){
            
        }
        try{
            SalesInvoiceMgmt.unpostCheck(SalesInvoiceRecord1);
            
        }catch(Exception e){
            
        }
        Test.stopTest();
    }
    
     private static testMethod void Test_SalesInvoiceMgmt11() {
        
        Sales_Invoice__c SalesInvoiceRecord = [Select Id,Credit_Memo__c From Sales_Invoice__c Limit 1];
        
        Sales_Invoice_Line__c SalesInvoiceLineRecord = [Select Id From Sales_Invoice_Line__c Limit 1];
        Tax_Area__c TaxAreaRecord = [Select Id From Tax_Area__c Limit 1];
        Sales_Order__c SalesOrderRecord = [Select Id,Create_Site_Address__c From Sales_Order__c Limit 1];
        GL_Entry__c GLEntryRecord = [Select Id From GL_Entry__c Limit 1];
        Service_Center__c ServiceCenterRecord = [Select Id From Service_Center__c Limit 1];
        
        
        ServiceCenterRecord.Temporary__c = false;
        update ServiceCenterRecord;
        
        Resource__c resource = [Select Id from Resource__c limit 1];
        resource.Exclude_from_I_C_Cost_Calculation__c = false;
        update resource;
        
        Resource_type__c resourceType = [Select id from Resource_Type__c limit 1];
        Test.startTest();
        GL_Account__c glacc = new GL_Account__c();
        glacc.name='Test GL';
        insert glacc;
        
        Sales_Invoice_Job_Task__c siJT = new Sales_Invoice_Job_Task__c();
        siJT.Sales_Invoice__c = SalesInvoiceRecord.id;
        siJT.Name='Test';
        siJT.Billing_Type__c = 'Fixed Price';
        insert siJT;
        
        
        resource.Post_Sale_to_Own_GL_Acct_When_Bundled__c = True;
        resource.Sales_GL_Account__c =glacc.id; 
        update resource;
        
        SalesInvoiceRecord.Posting_Date__c = Date.today();  
        SalesInvoiceRecord.Tax_Area__c = TaxAreaRecord.id;
        //salesInvoiceRecord.Reversed_from_SI__c = reverseFromSI.id;
        SalesInvoiceRecord.Retainage_Amount__c =1590;
        SalesInvoiceRecord.Retainage_Invoice__c = false;
        SalesInvoiceRecord.Service_Center__c = ServiceCenterRecord.id;
        SalesInvoiceRecord.Credit_Memo__c = false;
         SalesInvoiceRecord.Retainage_Invoice__c = true;

        // SalesInvoiceRecord.Invoice_Amt_Incl_Tax_ _c = 10;
        
        update SalesInvoiceRecord;
        
        SalesInvoiceLineRecord.Bill_as_Lump_Sum__c = True;
        SalesInvoiceLineRecord.xLine_Amount__c = 100;
        SalesInvoiceLineRecord.Line_Amt_Incl_Tax__c =100;
        SalesInvoiceLineRecord.Resource__c = resource.id;
        SalesInvoiceLineRecord.Sales_Invoice_Job_Task__c=siJT.id;
        SalesInvoiceLineRecord.Service_Center__c = ServiceCenterRecord.id;
        SalesInvoiceLineRecord.Scheduled_Date__c = Date.today();
        SalesInvoiceLineRecord.Category__c = 'Labor';
        SalesInvoiceLineRecord.Quantity__c = 2;
        SalesInvoiceLineRecord.Resource_Type__c = resourceType.id;
        SalesInvoiceLineRecord.Tax__c=100;
        update SalesInvoiceLineRecord;
        
        
        List<Sales_Invoice_Line__c> theSILList = new List<Sales_Invoice_Line__c>();
        theSILList.add(SalesInvoiceLineRecord);
        Sales_Invoice__c SalesInvoiceRecord1 = [Select Id,Credit_Memo__c,Invoice_Amount__c,Invoice_Date__c,Tax_Liable__c,Name,Invoice_Tax__c,Bill_to_Customer__r.Inter_co_Account__c,Document_Status__c,Retainage_Invoice__c,Reversed_from_SI__r.Retainage_Invoice__c,
                                                Bill_to_Customer__r.InterCo__c,Service_Center__c,Subsidiary_Company__c,Service_Center__r.Name,Retainage_Amount__c,Reversed__c,
                                                Invoice_Amt_Incl_Tax__c,NT_Amount__c,Payment_Term__c,Tax_Area__r.Sales_Tax_Account__c,Posting_Date__c From Sales_Invoice__c where Id=:SalesInvoiceRecord.Id];
        
         try{
        SalesInvoiceMgmt.postSI(theSILList, SalesInvoiceRecord1);
         }catch(Exception e){
            
        }
        try{
            SalesInvoiceMgmt.unpostCheck(SalesInvoiceRecord1);
            
        }catch(Exception e){
            
        }
        Test.stopTest();
    }
    
    private static testMethod void Test_SalesInvoiceMgmt12() {
        
        Test.startTest();
        Sales_Invoice__c SalesInvoiceRecord = [Select Id,Credit_Memo__c,Bill_to_Customer__c,Sales_Order__c From Sales_Invoice__c Limit 1];
        
        Sales_Invoice_Line__c SalesInvoiceLineRecord = [Select Id,Service_Center__r.Temporary__c,Resource__r.Exclude_from_I_C_Cost_Calculation__c From Sales_Invoice_Line__c Limit 1];
        Tax_Area__c TaxAreaRecord = [Select Id From Tax_Area__c Limit 1];
        Sales_Order__c SalesOrderRecord = [Select Id,Create_Site_Address__c From Sales_Order__c Limit 1];
        GL_Entry__c GLEntryRecord = [Select Id From GL_Entry__c Limit 1];
        Service_Center__c ServiceCenterRecord = [Select Id From Service_Center__c Limit 1];
                Account AccountRecord = [Select Id From Account Limit 1];

        
        ServiceCenterRecord.Temporary__c = false;
        update ServiceCenterRecord;
        
        Resource__c resource = [Select Id from Resource__c limit 1];
        resource.Exclude_from_I_C_Cost_Calculation__c = false;
        update resource;
        
        Resource_type__c resourceType = [Select id from Resource_Type__c limit 1];
        GL_Account__c glacc = new GL_Account__c();
        glacc.name='Test GL';
        insert glacc;
        
        Sales_Invoice_Job_Task__c siJT = new Sales_Invoice_Job_Task__c();
        siJT.Sales_Invoice__c = SalesInvoiceRecord.id;
        siJT.Name='Test';
        siJT.Billing_Type__c = 'Fixed Price';
        insert siJT;
        Account acc = AccountRecord;
        acc.Inter_co_Account__c = true;
        update acc;
        
        resource.Post_Sale_to_Own_GL_Acct_When_Bundled__c = True;
        resource.Sales_GL_Account__c =glacc.id; 
        update resource;
        
        SalesInvoiceRecord.Posting_Date__c = Date.today();  
        SalesInvoiceRecord.Tax_Area__c = TaxAreaRecord.id;
        //salesInvoiceRecord.Reversed_from_SI__c = reverseFromSI.id;
        SalesInvoiceRecord.Retainage_Amount__c =1590;
        SalesInvoiceRecord.Retainage_Invoice__c = false;
        SalesInvoiceRecord.Service_Center__c = ServiceCenterRecord.id;
        SalesInvoiceRecord.Credit_Memo__c = false;
         SalesInvoiceRecord.Retainage_Invoice__c = true;

        // SalesInvoiceRecord.Invoice_Amt_Incl_Tax_ _c = 10;
        
        update SalesInvoiceRecord;
        
        SalesInvoiceLineRecord.Bill_as_Lump_Sum__c = True;
        SalesInvoiceLineRecord.xLine_Amount__c = 100;
        SalesInvoiceLineRecord.Line_Amt_Incl_Tax__c =100;
        SalesInvoiceLineRecord.Resource__c = resource.id;
        SalesInvoiceLineRecord.Sales_Invoice_Job_Task__c=siJT.id;
        SalesInvoiceLineRecord.Service_Center__c = ServiceCenterRecord.id;
        SalesInvoiceLineRecord.Scheduled_Date__c = Date.today();
        SalesInvoiceLineRecord.Category__c = 'Labor';
        SalesInvoiceLineRecord.Quantity__c = 2;
        SalesInvoiceLineRecord.Resource_Type__c = resourceType.id;
        SalesInvoiceLineRecord.Tax__c=100;
    
        update SalesInvoiceLineRecord;
        
          CompanyMgmt.systemCall = true;
        Retainage_Ledger_Entry__c retainageLedgerEntry = new Retainage_Ledger_Entry__c();
        retainageLedgerEntry.Closed_By_Invoice_No__c = SalesInvoiceRecord.Id;
        retainageLedgerEntry.Customer__c = SalesInvoiceRecord.Bill_to_Customer__c;
        retainageLedgerEntry.Sales_Order__c = SalesInvoiceRecord.Sales_Order__c;
        retainageLedgerEntry.Amount__c = 100;
        insert retainageLedgerEntry;
        
        List<Sales_Invoice_Line__c> theSILList = new List<Sales_Invoice_Line__c>();
        theSILList.add(SalesInvoiceLineRecord);
        Sales_Invoice__c SalesInvoiceRecord1 = [Select Id,Credit_Memo__c,Invoice_Amount__c,Bill_to_Customer__r.Inter_co_AR_Account__c,Invoice_Date__c,Tax_Liable__c,Name,Invoice_Tax__c,Bill_to_Customer__r.Inter_co_Account__c,Document_Status__c,Retainage_Invoice__c,Reversed_from_SI__r.Retainage_Invoice__c,
                                                Bill_to_Customer__r.InterCo__c,Service_Center__c,Subsidiary_Company__c,Service_Center__r.Name,Retainage_Amount__c,Reversed__c,
                                                Invoice_Amt_Incl_Tax__c,NT_Amount__c,Payment_Term__c,Tax_Area__r.Sales_Tax_Account__c,Posting_Date__c From Sales_Invoice__c where Id=:SalesInvoiceRecord.Id];
        SalesInvoiceRecord1.Bill_to_Customer__r.Inter_co_Account__c=true;
                    SalesInvoiceRecord1.Bill_to_Customer__r.Inter_co_Account__c=true;
        SalesInvoiceRecord1.Bill_to_Customer__r.Inter_co_AR_Account__c = acc.Id;
        SalesInvoiceRecord1.Bill_to_Customer__r.Inter_co_Revenue_Account__c= acc.Id;

         try{
        SalesInvoiceMgmt.postSI(theSILList, SalesInvoiceRecord1);
         }catch(Exception e){
            
        }
       
        Test.stopTest();
    }
    
    private static testMethod void Test_SalesInvoiceMgmt17() {
        
        Sales_Invoice__c SalesInvoiceRecord = [Select Id,Credit_Memo__c,Site_Scope__c,Misc_Invoice__c,Reversed_from_SI__c From Sales_Invoice__c Limit 1];
        
        Sales_Invoice_Line__c SalesInvoiceLineRecord = [Select Id From Sales_Invoice_Line__c Limit 1];
         SalesInvoiceMgmt.checkSave(SalesInvoiceRecord,new List<Sales_Invoice_Line__c>());
     }
     private static testMethod void Test_SalesInvoiceMgmt18() {
        
        Sales_Invoice__c SalesInvoiceRecord = [Select Id,Tax_Area__c From Sales_Invoice__c Limit 1];
        	System.debug('SalesInvoiceRecord===>'+SalesInvoiceRecord);
         SalesInvoiceMgmt.validateTaxArea(SalesInvoiceRecord);
     }
    private static testMethod void Test_SalesInvoiceMgmt19() {
        
        Sales_Invoice__c SalesInvoiceRecord = [Select Id,Credit_Memo__c,Site_Scope__c,Misc_Invoice__c,Reversed_from_SI__c,Tax_Liable__c From Sales_Invoice__c Limit 1];
        
        Sales_Invoice_Line__c SalesInvoiceLineRecord = [Select Id,Resource_Type__c,Tax_Group__c From Sales_Invoice_Line__c Limit 1];
        
        SalesInvoiceMgmt.updateSIL(SalesInvoiceRecord,SalesInvoiceLineRecord,'theJobPosition');
    }
    private static testMethod void Test_SalesInvoiceMgmt20() {
        
        Sales_Invoice__c SalesInvoiceRecord = [Select Id,Credit_Memo__c,Site_Scope__c,Misc_Invoice__c,Reversed_from_SI__c,Tax_Liable__c From Sales_Invoice__c Limit 1];
        
        Sales_Invoice_Line__c SalesInvoiceLineRecord = [Select Id,Resource_Type__c,Tax_Group__c,Resource__c From Sales_Invoice_Line__c Limit 1];
        
        SalesInvoiceMgmt.updateSIL(SalesInvoiceRecord,SalesInvoiceLineRecord,'theWResource');
    }
    //getEmailDeliverability
    private static testMethod void Test_SalesInvoiceMgmt21() {
        CompanyMgmt.getEmailDeliverability();
        CompanyMgmt.convertLocalDatetime(DateTime.now());
        List<String>chkdelete=CompanyMgmt.checkDeleteGLB(TestDataUtil.GLBatchRecord);
        Decimal getSalesTax=CompanyMgmt.getSalesTax('test','test');
        CompanyMgmt.allowDataOverride(); 
        decimal halfUpTo5D=CompanyMgmt.halfUpTo5D(10);
        decimal halfUpTo3D=CompanyMgmt.halfUpTo3D(10);
        CompanyMgmt.checkUnpostPermission();
        Unit_of_Measure__c unitOfMeasure = new Unit_of_Measure__c();
        unitOfMeasure = [SELECT Id, Hours_UOM__c FROM Unit_of_Measure__c LIMIT 1];
        CompanyMgmt.getUnitOfMeasures(unitOfMeasure.Id);
        
    }
}