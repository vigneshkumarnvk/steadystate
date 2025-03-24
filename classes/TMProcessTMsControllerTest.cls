@isTest
public class TMProcessTMsControllerTest {
    @testSetup static void SetupData() {
        //Setup Data
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        TM__c testTMRecord = TestDataUtil.TMRecord;
        TM_Line__c testTMLineLaborRecord = TestDataUtil.TMLineLaborRecord;
        TM_Line__c TMLineEquipmentRecord = TestDataUtil.TMLineEquipmentRecord;
        User testUserRecord = TestDataUtil.UserRecord;
        Sales_Invoice__c testSalInvoiceRerd = TestDataUtil.SalesInvoiceRecord;
        CompanyMgmt.byPassTrigger = false;
        
    }
    private static testMethod void Test_TMProcessTMsController(){
        TMProcessTMsController testTMProcCls = new TMProcessTMsController();
        TM__c testTMRecord = [SELECT Id FROM TM__c LIMIT 1];
        TM_Line__c TMLineEquipmentRecord = [SELECT Id FROM TM_Line__c LIMIT 1];
        List<SelectOption> lstFilterOperator = testTMProcCls.lstFilterOperator;
        List<SelectOption> lstFilterField = testTMProcCls.lstFilterField;
        String sortBy = testTMProcCls.sortBy;
        String sortDirection = testTMProcCls.sortDirection;
        List<String> lstFields = testTMProcCls.lstFields;
        testTMProcCls.searchTM();
        Test.startTest();
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;        
        //testTMProcCls.changeStatusTo = 'Confirmed';
        System.assert(testTMProcCls.theTMListPerStatus.size() == 1);
        testTMProcCls.theTMListPerStatus[0].isSelected = true;
        testTMProcCls.ScheduleTMs();
        //TMLineEquipmentRecord.Drop_Off_Rental__c = true;
        //update TMLineEquipmentRecord;
        testTMProcCls.setStatus();
        testTMProcCls.setStatusToVoid();
        testTMProcCls.setOrderBy();
        testTMProcCls.AddEmergencyTMs();
        //testTMProcCls.theTMListPerStatus[0].isSelected = true;
        
        testTMProcCls.manualCloseTM();
        testTMRecord.Ready_to_Close__c = True;
        update testTMRecord;
        TMProcessTMsController.TMPerStatusWrapper tmwrap = new TMProcessTMsController.TMPerStatusWrapper(true,testTMRecord);
        testTMProcCls.theTMListPerStatus.add(tmwrap);
        testTMProcCls.reopenTM();
        testTMProcCls.CheckReadyToClose();
        testTMProcCls.RemoveFromClose();
        testTMProcCls.GoToReadyToBillPDF();
        testTMProcCls.returnToOpenTMs();
        testTMProcCls.ReloadByStatus();
        testTMProcCls.GoToFieldTMMultiplePDF();
        testTMProcCls.firstpageStatusWrap();
        ProcessTMPerStatusWrapperPagination PaginationByStatus = new ProcessTMPerStatusWrapperPagination(testTMProcCls.theTMListPerStatus,5);
        //testTMProcCls.lastpageStatusWrap();
        //testTMProcCls.previouspageStatusWrap();
        //testTMProcCls.nextpageStatusWrap();
        Pagereference pgref = Page.TM;
        Test.setCurrentPage(pgref);
        pgref.getParameters().put('selectedTMIds', testTMRecord.Id);
        testTMProcCls.CreateInvoiceFromProcessTM();
        testTMProcCls.CreateSIFromProcessTM();
        testTMProcCls.returnToProcessTM();
        testTMProcCls.returnToProcessTMDummy();
        Test.stopTest();
    }
    private static testMethod void Test_TMCreateInvoiceService(){
        /* Depreciated
TM__c testTMRecord = [SELECT Id,Sales_Order__c, Site_Contact_2__c, Site_Contact_2__r.Name, Bill_To_Customer__c,
Account_Executive__c, Customer_PO_No__c, Service_Center__c, Subsidiary_Company__c, Site_Name__c,
Site_Street__c, Site_City__c, Site_State__c, Site_Phone_No__c, Site_Country__c, Site_Contact__c,
Site_Email_Address__c, Contact__c, Tax_Liable__c, Tax_Area__c, Contract__c,Billing_Instructions__c,
Site_Scope__c, Internal_Comments__c,Site_Postal_Code__c
FROM TM__c LIMIT 1];
List<TM_Line__c> testTMLList = [SELECT Id, Invoiced__c, Overtime_Hours__c, Premium_Rate__c, Use_Premium_Rate__c,
Overtime_Rate__c, Premium_Hours__c, Regular_Rate__c, Regular_Hours__c, Line_Amt_Incl_Tax__c, Line_Amount__c,
Unit_Cost__c,Line_Cost__c, Hour__c, Quantity__c, TM__r.Scheduled_Date__c, Resource_Type__r.Name,
Service_Center__r.Equipment_Fleet_No_Not_Required__c, Resource_Type__r.Fleet_No_Required__c,
Bill_as_Lump_Sum__c, Non_Billable__c, BOL_Manifest__c, Tax_Pct__c, Tax__c, TM__c, Category__c,
Unit_of_Measure__c, Tax_Group__c, Resource_Type__c, Resource__c, Description__c, Cost_Qty__c FROM TM_Line__c];

Sales_Invoice__c testSalInvoiceRerd = [SELECT Id FROM Sales_Invoice__c LIMIT 1];
TMCreateInvoiceService.insertSI(testTMRecord);
string invoiceNote;
TMCreateInvoiceService.insertSIL(testSalInvoiceRerd, testTMRecord, testTMLList, invoiceNote);
*/
    }
    
    private static testMethod void Test_ProcessTMPerStatusWrapperPagination() {
        TM__c TMRecord = [SELECT Id FROM TM__c LIMIT 1];
        
        TMRecord.Ready_to_Close__c = true;
        update TMRecord;
        Test.startTest();
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        List<TMProcessTMsController.TMPerStatusWrapper> testTMProList = new List<TMProcessTMsController.TMPerStatusWrapper>();
        TMProcessTMsController.TMPerStatusWrapper tmwrap = new TMProcessTMsController.TMPerStatusWrapper(true, TMRecord);
        testTMProList.add(tmwrap);
        
        ProcessTMPerStatusWrapperPagination testProTMPerStWrapPag = new ProcessTMPerStatusWrapperPagination(testTMProList, 1);
        
        testProTMPerStWrapPag.next();
        testProTMPerStWrapPag.previous();
        testProTMPerStWrapPag.getDisableNext();
        testProTMPerStWrapPag.getDisablePrevious();
        testProTMPerStWrapPag.pageNumber();
        testProTMPerStWrapPag.getAll();
        testProTMPerStWrapPag.getpage(5);
        testProTMPerStWrapPag.getStartIndex();
        testProTMPerStWrapPag.getEndIndex();
        TMProcessTMsController con = new TMProcessTMsController();
        con.pageNumberStatusWrap = 0;       
        con.hasNextpageStatusWrap = false;
        con.hasPreviouspageStatusWrap= false;
        con.getEndIndexStatusWrap= 0;
        con.getStartIndexStatusWrap= 0;
        con.getTotalRecordsStatusWrap= 0;
        try
        {
            con.lastpageStatusWrap();
        }
        Catch(Exception e)
        {
            
        }
        
        Test.stopTest();
        
    }
    
     private static testMethod void Test_ProcessTMPerStatusWrapperPagination1() {
         try
        {
            TMProcessTMsController con = new TMProcessTMsController();
            con.nextpageStatusWrap();
        }
        Catch(Exception e)
        {
            
        }
        
     }
     private static testMethod void Test_ProcessTMPerStatusWrapperPagination2() {
         try
        {
            TMProcessTMsController con = new TMProcessTMsController();
            con.previouspageStatusWrap();
        }
        Catch(Exception e)
        {
            
        }
        
     }
    //test
}