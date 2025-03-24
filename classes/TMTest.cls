@IsTest
public class TMTest {
    
    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    @TestSetup static void SetupData() {
        //Setup Data
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord; 
        //TM
        TM__c TMRecord = TestDataUtil.TMRecord;
        //TM Line

        TM_Line__c TMLineLaborRecord = TestDataUtil.TMLineLaborRecord;
        TM_Line__c TMLineEquipmentRecord = TestDataUtil.TMLineEquipmentRecord;
        TM_Line__c TMLineMaterialRecord = TestDataUtil.TMLineMaterialRecord ;
        TM_Line__c TMLineSubcontractorsRecord = TestDataUtil.TMLineSubcontractorsRecord ;
        TM_Line__c TMLineWasteDisposalRecord = TestDataUtil.TMLineWasteDisposalRecord ;
        TM_Line__c TMLineDemurrageRecord = TestDataUtil.TMLineDemurrageRecord;
        TM_Line__c TMLineLumpSumRecord = TestDataUtil.TMLineLumpSumRecord ;
        TM_Line__c TMLineMiscRecord = TestDataUtil.TMLineMisChargeRecord ;
        //Others
        Resource__c eqRes = TestDataUtil.ResourceEquipmentRecord;
        Resource_Type__c ResourceTypeRecord = TestDataUtil.ResourceTypeRecord;
        Service_Center__c sc = TestDataUtil.ServiceCenterRecord;
        Tax_Area__c TaxAreaRecord = TestDataUtil.TaxAreaRecord;
        Tax_Jurisdiction__c taxJurisdiction = TestDataUtil.TaxJurisdictionRecord;
        Tax_Detail__c taxDetail = TestDataUtil.TaxDetailRecord;
        Unit_of_Measure__c uom = TestDataUtil.UnitMeasureRecord;
        Resource__c transRes = TestDataUtil.ResourceTransportationRecord;
        Contract_Line__c ContractLineRecord = TestDataUtil.ContractLineRecord;
        Site_Address__c SiteAddressRecord = TestDataUtil.SiteAddressRecord;
        Contract  ContractRecord = TestDataUtil.ContractRecord;
        Sales_Order__c SalesOrderRecord = TestDataUtil.SalesOrderRecord;
        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        Sales_Line__c SalesEquipmentLineRecord = TestDataUtil.SalesEquipmentLineRecord;
        Sales_Line__c SalesWasteLineRecord = TestDataUtil.SalesWasteLineRecord;
        ResourceUOMAssociation__c resourceUOMAssociation = TestDataUtil.resourceUOMAssociationRec;
        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = : companySetup.Id];
        System.assertEquals(theCSList.size(), 1);
        CompanyMgmt.byPassTrigger = false;
    }
    
    
    private static testMethod void Test_TMController() {
        
        TM__c TMRecord = [Select Id From TM__c Limit 1]; 
        Resource_Type__c ResourceTypeRecord = [Select Id From Resource_Type__c Limit 1];
        Tax_Area__c TaxAreaRecord = [Select Id From Tax_Area__c Limit 1];
        Test.startTest();
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        PageReference pref = Page.TM;
        Test.setCurrentPage(pref);
        pref.getParameters().put('id', TMRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TMRecord);

        TMController inst_TM = new TMController(StdCon);
        String title = inst_TM.title;
        TM__c TM = inst_TM.TM;
        pref.getParameters().put('newFieldValue', TaxAreaRecord.Id);
        //inst_TM.validateTaxArea();

        inst_TM.validateTaxLiable();
        inst_TM.validateContact();
        inst_TM.validateSalespeople();


        inst_TM.validateServiceCenter();
        List<TM_Line__c> SLList = inst_TM.TMLList;
        /*
        List<TM_Line__c> TMLListLabor = inst_TM.TMLListLabor;

        List<TM_Line__c> TMLListEquipment = inst_TM.TMLListEquipment;
        List<TM_Line__c> TMLListMaterials = inst_TM.TMLListMaterials;
        List<TM_Line__c> TMLListSubcontractors = inst_TM.TMLListSubcontractors;
        List<TM_Line__c> TMLListWasteDisposal = inst_TM.TMLListWasteDisposal;
        List<TM_Line__c> TMLListDemurrage = inst_TM.TMLListDemurrage;
        List<TM_Line__c> TMLListLumpSum = inst_TM.TMLListLumpSum;
        List<TM_Line__c> TMLListMisc = inst_TM.TMLListMisc;
         */
        
        inst_TM.cancel();
        inst_TM.editcancel();
        inst_TM.returnBack();

        pref.getParameters().put('objectType', 'TMLine');
        pref.getParameters().put('lineCategory', 'Labor');
        inst_TM.AddLine();

        pref.getParameters().put('objectType', 'TMLine');
        pref.getParameters().put('lineCategory', 'Waste Disposal');
        inst_TM.AddLine();
        
        pref.getParameters().put('lineCategory', 'Bundled');
        inst_TM.AddLine();

        pref.getParameters().put('lineCategory', 'Misc. Charges And Taxes');
        inst_TM.AddLine();        
        pref.getParameters().put('lineCategory', 'Demurrage');
        inst_TM.AddLine();
        pref.getParameters().put('lineCategory', 'Subcontractors');
        inst_TM.AddLine();

        /*
        pref.getParameters().put('lineCategory', 'TempEquipment');
        inst_TM.AddLine();


        inst_TM.theTMLList[0].Billing_Start_Time__c = Time.newInstance(12,0,0,0);
        pref.getParameters().put('objectType', 'TMLine');
        pref.getParameters().put('displayId', String.valueOf(inst_TM.theTMLList[0].Line_No__c));
        pref.getParameters().put('lineType', 'Labor');
        pref.getParameters().put('timeType', 'BillingTime');
        inst_TM.copyTime();
        
        inst_TM.theTMLList[0].Site_Start_Time__c = Time.newInstance(8,0,0,0);
        inst_TM.theTMLList[0].Site_End_Time__c = Time.newInstance(16,0,0,0);
        inst_TM.theTMLList[0].Lunch_Start_Time__c = Time.newInstance(12,0,0,0);
        inst_TM.theTMLList[0].Lunch_End_Time__c = Time.newInstance(12,30,0,0);
        pref.getParameters().put('objectType', 'TMLine');
        pref.getParameters().put('displayId', String.valueOf(inst_TM.theTMLList[0].Line_No__c));
        pref.getParameters().put('lineType', 'Labor');
        pref.getParameters().put('timeType', '');
        inst_TM.copyTime();
        
        pref.getParameters().put('objectType', 'TMLine');
        pref.getParameters().put('lineCategory', inst_TM.theTMLList[0].Category__c);
        pref.getParameters().put('displayId', String.valueOf(inst_TM.theTMLList[0].Line_No__c));
        inst_TM.DeleteLine();

        
        //inst_TM.theTMLListLabor = TMLListLabor; 
        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('newFieldValue', ' ');
        inst_TM.validateField();


        pref.getParameters().put('fieldName', 'theJobPosition');
        pref.getParameters().put('newFieldValue', ResourceTypeRecord.Id);
        inst_TM.validateField();

        pref.getParameters().put('fieldName', 'theEquipment');
        pref.getParameters().put('newFieldValue', '1');
        inst_TM.validateField();
         */


//        pref.getParameters().put('newFieldValue', TaxAreaRecord.Id);
//        inst_TM.validateTaxArea();
//        pref.getParameters().remove('id');
//        StdCon = new ApexPages.StandardController(new TM__c());
//        inst_TM = new TMController(StdCon);
//
//        PageReference pageref = Page.TM;
//        CompanyMgmt.byPassTrigger = false;
        Test.stopTest();
    }
    

    private static testMethod void Test_TMController2() {
        
        TM__c TMRecord = [Select Id, Name,Status__c,Tax_Liable__c, Tax_Area__c, Scheduled_Date__c, Sales_Order__r.Pay_Rule__c, Sales_Order__c,
                Reviewed_By__c, Reviewed_Date__c, Reviewed_At_Status__c From TM__c Limit 1];
        Service_Center__c ServiceCenterRecord = [Select Id,Name,Max_No_of_Emergency_T_M__c,Subsidiary_Company__c, Blocked__c From Service_Center__c Limit 1];

        Test.startTest();
        PageReference pref = Page.TM;
        Test.setCurrentPage(pref);
        
        pref.getParameters().put('id', TMRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TMRecord);
        TMController inst_TM = new TMController(StdCon);  
        List<SelectOption> filterFieldOptn = inst_TM.filterFieldOptn;
        List<TM_Line__c> theAllTMLList = [Select Id From TM_Line__c];      
        inst_TM.theAllTMLList = theAllTMLList;
        List<TM__c> theTMList = [Select Id From TM__c]; 
        inst_TM.theTMList = theTMList;
        inst_TM.filterInput = 'test'; 
        inst_TM.selFilterField = 'test';
        inst_TM.theTMList = theTMList;
        inst_TM.selectAllTML(); 
        inst_TM.selectTmList();  
        inst_TM.scheduledDateValue = null; 
        inst_TM.selectTmList();  
        inst_TM.scheduledDateValue = '10/11/1983';   
        inst_TM.invoiceNote = 'test note';
        inst_TM.setNextDate();
        inst_TM.setPreviousDate();
        inst_TM.deleteTMConfirmation();
        //inst_TM.cloneTM();
        inst_TM.ReloadByStatus();
        inst_TM.returnToOpenTMs();
        inst_TM.theTMListPerStatus = new List<TMController.TMPerStatusWrapper>();
        inst_TM.GoToFieldTMMultiplePDF();        
        inst_TM.ScheduleTMs();
        inst_TM.CheckReadyToClose();  
        inst_TM.RemoveFromClose();
        inst_TM.AddEmergencyTMs();   
        inst_TM.theReadyTobillTMList=new List<TMController.TMReadyToBillWrapper>();  
        TMController.changeStatusTo='test';
        inst_TM.theTMList = new List<TM__c>();
        inst_TM.theTMList.add(TMRecord);
        Decimal a = inst_TM.TMLTotal;  
        a=inst_TM.TMLTotal = 10;  
        inst_TM.TMLTaxTotal = 10;
        inst_TM.TMLSubtotal = 10;
        inst_TM.TMLTotalMisc = 10;
        inst_TM.TMLTaxTotalMisc = 10;
        inst_TM.TMLSubtotalMisc = 10; 
        inst_TM.TMLTotalLumpSum = 10;                                                   
        inst_TM.TMLTotalDemurrage = 10;                                                   
        inst_TM.TMLTotalDemurrage = 10;                                                   
        inst_TM.TMLSubtotalDemurrage = 10;                                                   
        inst_TM.TMLTotalWasteDisposal = 10;                                                   
        inst_TM.TMLTaxTotalWasteDisposal = 10; 
        inst_TM.TMLSubtotalWasteDisposal = 10;
        inst_TM.TMLTotalSubcontractors = 10;                                                                                                                                                                                                       
        inst_TM.TMLTaxTotalSubcontractors = 10; 
        inst_TM.TMLTaxTotalSubcontractors = 10; 
        inst_TM.TMLSubtotalSubcontractors = 10; 
        inst_TM.TMLTotalMaterials = 10;  
        inst_TM.TMLTaxTotalMaterials = 10;  
        inst_TM.TMLSubtotalMaterials = 10;  
        inst_TM.TMLTotalEquipment = 10;  
        inst_TM.TMLTaxTotalEquipment = 10; 
        inst_TM.TMLSubtotalEquipment = 10; 
        inst_TM.TMLTotalLabor = 10; 
        inst_TM.TMLTaxTotalLabor = 10; 
        inst_TM.TMLSubtotalLabor = 10; 
        List<TM_Line__c> theTMLListMisc = inst_TM.theTMLListMisc; 
        List<SelectOption> lstFilterOperator = inst_TM.lstFilterOperator;
        List<SelectOption> lstFilterField = inst_TM.lstFilterField;
        inst_TM.deleteLine(); 
        inst_TM.setStatus();
        //////////pagination Testing///////////////////
        List<TMController.TMPerStatusWrapper> TMWList = new List<TMController.TMPerStatusWrapper>(); 
        
        for (Integer i = 0; i < 25; i++) {
            TMController.TMPerStatusWrapper rec = new TMController.TMPerStatusWrapper(true,TMRecord); 
            TMWList.add(rec);
        } 
        
        inst_TM.PaginationByStatus = new TMPerStatusWrapperPagination(TMWList, 2);
        
        inst_TM.theTMListPerStatus = inst_TM.PaginationByStatus.beginning();          
        inst_TM.PaginationByStatus.beginning();        
        inst_TM.nextpageStatusWrap();
        
        inst_TM.PaginationByStatus.beginning();                    
        inst_TM.firstpageStatusWrap();  
        Integer fv = inst_TM.getTotalRecordsStatusWrap;                 
        fv = inst_TM.getEndIndexStatusWrap;  
        fv = inst_TM.getEndIndexStatusWrap; 
        inst_TM.DeleteTM();
        inst_TM.setStatusToVoid();
        inst_TM.searchTM();
        String SD = inst_TM.sortBy;
        String SB = inst_TM.sortDirection;
        Integer SE = inst_TM.getStartIndexStatusWrap;
        Integer EE = inst_TM.getEndIndexStatusWrap ; 
        Integer PN = inst_TM.pageNumberStatusWrap;         
        Boolean HPP = inst_TM.hasPreviouspageStatusWrap; 
        Boolean HNP = inst_TM.hasNextpageStatusWrap;
        pref.getParameters().put('selectedTMIds', TMRecord.Id); 
        inst_TM.PrintBillingTM();
        inst_TM.GoToReadyToBillPDF();             
        Company_Setup__c CompanySetup = inst_TM.CompanySetup;
        inst_TM.validateAltSiteAddress();
        inst_TM.validateStartTime(); 
        inst_TM.selectAllTMs();
        inst_TM.PrintFieldTM();
        inst_TM.returnToProcessTM();
        inst_TM.CreateSIFromProcessTM();
        inst_TM.CreateInvoiceFromProcessTM(); 
        inst_TM.theSC = ServiceCenterRecord;  
        inst_TM.AddEmergencyTMs(); 
        TM_Line__c theTML = [Select Id From TM_Line__c Where Category__c =: 'Labor'];
        System.debug('###TML In TestClass ' + theTML);
        theTML.Site_Start_Time__c=Time.newInstance(18, 30, 2, 20);
        theTML.Job_Start_Time__c=Time.newInstance(18, 30, 2, 20);
        theTML.Job_End_Time__c=Time.newInstance(20, 30, 2, 20);
        
        update theTML;
        
        Test.stopTest();                                    
    }
    
    private static testMethod void Test_TMController3() {
        TM__c TMRecord = [Select Id, Site_Scope__c, Billing_Instructions__c, Internal_Comments__c, Status__c,Sales_Order__r.Billing_Rule_Not_Required__c, Sales_Order__r.Manifest_And_Profile__c, Tax_Liable__c,Tax_Area__c,Sales_Order__r.Charge_Rinse_Out_Fee__c From TM__c Limit 1];
        Service_Center__c ServiceCenterRecord = [Select Id,Name,Max_No_of_Emergency_T_M__c,Subsidiary_Company__c From Service_Center__c Limit 1];

        PageReference pref = Page.TM;
        Test.setCurrentPage(pref);
        pref.getParameters().put('id', TMRecord.Id);
        pref.getParameters().put('objectType', 'TMLine');  
        pref.getParameters().put('displayId', '0');                        
        pref.getParameters().put('selectedTMIds', TMRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TMRecord);
        TMController inst_TM = new TMController();  
        inst_TM.theTM = TMRecord;
        inst_TM.invoiceNote = 'test note';
        Test.startTest();
        inst_TM.CreateSI();
        inst_TM.editTM();
        inst_TM.CreateInvoice();
        List<TM__c> theTMList = [Select Id,Lump_Sum_Order__c,Bill_To_Customer__c,Sales_Order__c,Subsidiary_Company__c,Tax_Area__c, Sales_Order__r.Billing_Rule_Not_Required__c, Sales_Order__r.Manifest_And_Profile__c,Tax_Liable__c
                                 ,Service_Center__c,Sales_Invoice__c,Status__c,Name,Site_Scope__c,Billing_Instructions__c, Internal_Comments__c, Sales_Order__r.Charge_Rinse_Out_Fee__c From TM__c];
        inst_TM.theTMList = theTMList;
        inst_TM.CreateSIfromList();
        inst_TM.setOrderBy();
        List<String> lstFields = inst_TM.lstFields;

        List<TM_Line__c> theTMLList = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Resource_Type__c,Resource__c,Service_Center__c, Tax__c
                                       ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c,Category__c,Resource__r.Resource_Type__c,Unit_of_Measure__c,System_Calculated_Line__c From TM_Line__c];
        
        inst_TM.theTMLList = theTMLList;
        inst_TM.copyTime();
        inst_TM.save();
        inst_TM.quickSave();
        inst_TM.editSave();
        inst_TM.editQuickSave(); 
        inst_TM.quickSave2();     
        inst_TM.tmId = TMRecord.id; 
        String TMStatus = inst_TM.TMStatus;
        String NextStatus = inst_TM.NextStatus;
        Test.stopTest();
    }    
    
    private static testMethod void Test_TMController4() {
        TM__c TMRecord = [SELECT Id,Billing_Instructions__c,Site_Scope__c,Internal_Comments__c,
                Sales_Order__r.Billing_Rule_Not_Required__c, Status__c, Sales_Order__r.Manifest_And_Profile__c,
                Tax_Liable__c,Tax_Area__c,Sales_Order__r.Charge_Rinse_Out_Fee__c, Name, Scheduled_Date__c,
                Sales_Order__r.Pay_Rule__c, Sales_Order__c, Reviewed_By__c,
                Reviewed_Date__c, Reviewed_At_Status__c, Project_Manager_Reviewed__c
        FROM TM__c LIMIT 1];

        PageReference pref = Page.TM;
        Test.setCurrentPage(pref);
        
        pref.getParameters().put('id', TMRecord.Id);
        pref.getParameters().put('objectType', 'TMLine');
        pref.getParameters().put('displayId', '0');
        //      pref.getParameters().put('lineType', 'Labor');
        pref.getParameters().put('selectedTMIds', TMRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TMRecord);
        TMController inst_TM = new TMController();
        
        try{
            Boolean hn = inst_TM.hasNextpage;
        } catch(Exception exe){}
        try{
            Boolean hp = inst_TM.hasPreviouspage;
        } catch(Exception exe){}
        try{
            Integer hr = inst_TM.getStartIndex;
        } catch(Exception exe){}
        try{
            Integer hr1 = inst_TM.getEndIndex;
        } catch(Exception exe){}
        try{
            Integer hr2 = inst_TM.getTotalRecords;
        } catch(Exception exe){}
        
        try{
            Integer pn = inst_TM.pageNumber;
        } catch(Exception exe){}
        
        
        List<SelectOption> selOpts = inst_TM.lstFilterOperator;
        List<SelectOption> selOpts2 = inst_TM.lstFilterField;
        
        inst_TM.theTM = TMRecord;
        inst_TM.CreateSI();
        inst_TM.editTM();
        inst_TM.CreateInvoice();
        //inst_TM.CreateSIfromList();
        inst_TM.setOrderBy();
        inst_TM.updateHours();
        //inst_TM.cloneAndSchedule();
        inst_TM.reopenTM();
        inst_TM.manualCloseTM();
        List<String> lstFields = inst_TM.lstFields;
        Test.startTest();
        List<TM_Line__c> theTMLList = New List<TM_Line__c>();
        TM_Line__c theTML = [Select Id,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c, Tax__c
                             ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c,Resource__r.Resource_Type__c,System_Calculated_Line__c From TM_Line__c Where Category__c =: 'Labor'];
        
        
        theTML.Job_Start_Time__c = Time.newInstance(1, 2, 3, 0);
        theTML.Job_End_Time__c = Time.newInstance(1, 2, 3, 0);
        theTML.Site_Start_Time__c = Time.newInstance(1, 2, 3, 0);
        theTML.Site_End_Time__c = Time.newInstance(1, 2, 3, 0);
        theTML.Lunch_Start_Time__c = Time.newInstance(1, 2, 3, 0);
        theTML.Lunch_End_Time__c = Time.newInstance(1, 2, 3, 0);
        
        update theTML;
        theTMLList.add(theTML);
        inst_TM.theTMLList = theTMLList;
        
        inst_TM.tmId = TMRecord.id;
        inst_TM.msave();
        inst_TM.saveAndChangeStatus();
        inst_TM.saveRoster();
        inst_TM.PrintFieldMultiplePDF2();
        /*
        List<TM_Line__c > TMLFieldListWasteDisposal = inst_TM.TMLFieldListWasteDisposal;
        List<TM_Line__c > TMLFieldListSubcontractors = inst_TM.TMLFieldListSubcontractors;
        List<TMController.TMLWithNote > TMLFieldListMaterials = inst_TM.TMLFieldListMaterials;
        List<TMController.TMLWithNote > TMLFieldListEquipment = inst_TM.TMLFieldListEquipment;
        List<TM_Line__c > TMLFieldListLaborNotes = inst_TM.TMLFieldListLaborNotes;
        List<TM_Line__c > TMLFieldListLabor = inst_TM.TMLFieldListLabor;
         */
        Test.stopTest();
    }
    
    private static testMethod void Test_validateFields() {
        TM__c TMRecord = [Select Id,Status__c From TM__c Limit 1];
        Resource_Type__c ResourceTypeRecord = [Select Id From Resource_Type__c Limit 1]; 
        Resource__c ResourceRecord = [Select Id From Resource__c Limit 1]; 
        Unit_of_Measure__c UnitMeasureRecord = [Select Id From Unit_of_Measure__c Limit 1]; 
        Service_Center__c ServiceCenterRecord = [Select Id,Name,Max_No_of_Emergency_T_M__c,Subsidiary_Company__c From Service_Center__c Limit 1];
        Test.startTest();
        PageReference pref = Page.TM;
        Test.setCurrentPage(pref);
        
        pref.getParameters().put('id', TMRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TMRecord);

        TMController inst_TM = new TMController();  
        inst_TM.theTM = TMRecord;
        
        inst_TM.theTMLListLabor = [Select Id,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                             ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c,Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Labor'];
        

        pref.getParameters().put('lineNo', '0');        
        pref.getParameters().put('fieldName', 'theServiceCenter');
        pref.getParameters().put('newFieldValue', ServiceCenterRecord.Id);           
        inst_TM.validateField(); 
        pref.getParameters().put('newFieldValue', '');           
        inst_TM.validateField();  
        pref.getParameters().put('newFieldValue', 'Invalid');           
        inst_TM.validateField();  
        
        
        pref.getParameters().put('lineNo', '0');        
        pref.getParameters().put('fieldName', 'theJobPosition');
        pref.getParameters().put('newFieldValue', ResourceTypeRecord.Id );           
        inst_TM.validateField(); 
        pref.getParameters().put('newFieldValue', '');           
        inst_TM.validateField();  
        pref.getParameters().put('newFieldValue', 'Invalid');           
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLResource');
        pref.getParameters().put('newFieldValue', ResourceRecord.Id );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '');
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', 'Invalid');
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theRegularHour');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theOvertimeHours');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '88' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', null );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '7777');
        inst_TM.validateField();
        
        
        pref.getParameters().put('fieldName', 'theRegularRate');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '10' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theOvertimeRate');
        pref.getParameters().put('newFieldValue', null );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '7777');
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'thePremiumRate');
        pref.getParameters().put('newFieldValue', null );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '7777');
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theTaxGroup');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theTaxGroup');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('fieldName', 'theLunchStartTime');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLunchStartTime');
        pref.getParameters().put('newFieldValue', '1:2' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLunchStartTime');
        pref.getParameters().put('newFieldValue', '1002' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLunchEndTime');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLunchEndTime');
        pref.getParameters().put('newFieldValue', '1:2' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLunchEndTime');
        pref.getParameters().put('newFieldValue', '1002' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theBillingStartTime');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theBillingStartTime');
        pref.getParameters().put('newFieldValue', '1:2' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theBillingStartTime');
        pref.getParameters().put('newFieldValue', '1002' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theBillingEndTime');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theBillingEndTime');
        pref.getParameters().put('newFieldValue', '1:2' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theBillingEndTime');
        pref.getParameters().put('newFieldValue', '1002' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theJobStartTime');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theJobEndTime');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theJobStartTime');
        pref.getParameters().put('newFieldValue', '1:2' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theJobStartTime');
        pref.getParameters().put('newFieldValue', '1002' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theSiteStartTime');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theSiteEndTime');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theSiteStartTime');
        pref.getParameters().put('newFieldValue', '1:2' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theSiteStartTime');
        pref.getParameters().put('newFieldValue', '1002' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLContractLine');
        pref.getParameters().put('newFieldValue', Null );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLContractLine');
        pref.getParameters().put('newFieldValue', '7777');
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theUsePremiumRate');
        pref.getParameters().put('newFieldValue', null );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '7777');
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theBillSiteTime');
        pref.getParameters().put('newFieldValue', null );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '7777');
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLunch');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', null );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLBillasLumpSum');
        pref.getParameters().put('newFieldValue', 'false' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLNonBillable');
        pref.getParameters().put('newFieldValue', 'false' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theOvertimeHour');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'thePremiumHours');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'thePremiumRate');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theOvertimeRate');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLUnitPrice');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLQuantity');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        Test.stopTest();
    }
    
    private static testMethod void Test_validateFields2() {
        TM__c TMRecord = [Select Id,Status__c From TM__c Limit 1];
        TM_Line__c TMLineRecord = [Select Id,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                             ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c,Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Equipment'];

        Resource_Type__c ResourceTypeRecord = [Select Id From Resource_Type__c Limit 1]; 
        Resource__c ResourceRecord = [Select Id From Resource__c Limit 1]; 
        Unit_of_Measure__c UnitMeasureRecord = [Select Id From Unit_of_Measure__c Limit 1]; 
        Service_Center__c ServiceCenterRecord = [Select Id,Name,Max_No_of_Emergency_T_M__c,Subsidiary_Company__c From Service_Center__c Limit 1];
        Test.startTest();
        PageReference pref = Page.TM;
        Test.setCurrentPage(pref);
        
        pref.getParameters().put('id', TMRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TMRecord);
        
        Unit_of_Measure__c uom = UnitMeasureRecord;
        
        TMController inst_TM = new TMController();
        inst_TM.theTM = TMRecord;
        
        inst_TM.theTMLListEquipment = new List<TM_Line__c>{TMLineRecord};
        
        
        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theEquipment');
        pref.getParameters().put('newFieldValue', ResourceTypeRecord.Id );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '');
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', 'Invalid');
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theEServiceCenter');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theEResource');
        pref.getParameters().put('newFieldValue', ResourceRecord.Id );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '');
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', 'Invalid');
        inst_TM.validateField();
        
        
        pref.getParameters().put('fieldName', 'theESiteStartTime');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.theTMLListEquipment[0].Category__c = 'Equipment';
        inst_TM.theTMLListEquipment[0].Regular_Hours__c = 0;
        inst_TM.theTMLListEquipment[0].Overtime_Hours__c = 0;
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1:2' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theESiteEndTime');
        pref.getParameters().put('newFieldValue', '1:2' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1002' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theEUOM');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        inst_TM.validateField();
        
        
        pref.getParameters().put('fieldName', 'theEBillingStartTime');
        pref.getParameters().put('newFieldValue', '05:00' );
        pref.getParameters().put('fieldName', 'theEBillingEndTime');
        pref.getParameters().put('newFieldValue', '05:00' );
        inst_TM.theTMLListEquipment[0].Include_Lunch_Y_N__c = true;
        inst_TM.validateField();
        inst_TM.theTMLListEquipment[0].Lunch_Start_Time__c = Time.newInstance(12,0,0,0);
        inst_TM.theTMLListEquipment[0].Lunch_End_Time__c = Time.newInstance(12,30,0,0);
        inst_TM.validateField();
        inst_TM.theTMLListEquipment[0].Lunch_Start_Time__c = Time.newInstance(12,0,0,0);
        inst_TM.theTMLListEquipment[0].Lunch_End_Time__c = Time.newInstance(13,0,0,0);
        inst_TM.validateField();
        inst_TM.theTMLListEquipment[0].Lunch_Start_Time__c = Time.newInstance(12,0,0,0);
        inst_TM.theTMLListEquipment[0].Lunch_End_Time__c = Time.newInstance(13,30,0,0);
        inst_TM.validateField();
        
        
        pref.getParameters().put('fieldName', 'theEBillasLumpSum');
        pref.getParameters().put('newFieldValue', null );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '7777');
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theEQuantity');
        pref.getParameters().put('newFieldValue', null );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '7777');
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theEUnitPrice');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theETaxGroup');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theEContractLine');
        pref.getParameters().put('newFieldValue', null );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '7777');
        inst_TM.validateField();
        pref.getParameters().put('fieldName', 'theENonBillable');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', 'false');
        inst_TM.validateField();
        
        
    }
    
    private static testMethod void Test_validateFields3() {
        TM__c TMRecord = [Select Id,Status__c From TM__c Limit 1];
        Resource_Type__c ResourceTypeRecord = [Select Id From Resource_Type__c Limit 1]; 
        Resource__c ResourceRecord = [Select Id From Resource__c Limit 1]; 
        Unit_of_Measure__c UnitMeasureRecord = [Select Id From Unit_of_Measure__c Limit 1]; 
        Service_Center__c ServiceCenterRecord = [Select Id,Name,Max_No_of_Emergency_T_M__c,Subsidiary_Company__c From Service_Center__c Limit 1];
        Test.startTest();
        PageReference pref = Page.TM;
        Test.setCurrentPage(pref);
        
        pref.getParameters().put('id', TMRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TMRecord);
        
        Unit_of_Measure__c uom = UnitMeasureRecord;
        TM_Line__c TMLineMaterialRecord =   [Select Id,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                             ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Materials'];
        
        
        
        TMController inst_TM = new TMController();
        inst_TM.theTM = TMRecord;
        
        inst_TM.theTMLListMaterials = New List<TM_Line__c>();
        inst_TM.theTMLListMaterials.add(TMLineMaterialRecord);
        
        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theMResource');
        pref.getParameters().put('newFieldValue', ResourceRecord.Id );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '');
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', 'Invalid');
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theMQuantity');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theMUOM');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theMUnitPrice');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theMTaxGroup');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theMBillasLumpSum');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theMNonBillable');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theMContractLine');
        pref.getParameters().put('newFieldValue', Null );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '7777');
        inst_TM.validateField();
        Test.stopTest();
    }
    
    private static testMethod void Test_validateFields4() {
        TM__c TMRecord = [Select Id,Status__c, Scheduled_Date__c, Service_Center__c, Rate_Sheet__c, From_Sales_Quote__c,Sales_Order__c,Contract__c,Bill_to_Customer__c,Tax_Liable__c,Tax_Area__c From TM__c Limit 1];
        Resource_Type__c ResourceTypeRecord = [Select Id From Resource_Type__c Limit 1]; 
        Resource__c ResourceRecord = [Select Id From Resource__c Limit 1]; 
        Unit_of_Measure__c UnitMeasureRecord = [Select Id From Unit_of_Measure__c Limit 1]; 
        Service_Center__c ServiceCenterRecord = [Select Id,Name,Max_No_of_Emergency_T_M__c,Subsidiary_Company__c From Service_Center__c Limit 1];
        PageReference pref = Page.TM;
        Test.setCurrentPage(pref);
        
        pref.getParameters().put('id', TMRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TMRecord);
        
        Unit_of_Measure__c uom = UnitMeasureRecord;
        
        
        Test.startTest();
        TMController inst_TM = new TMController();
        inst_TM.theTM = TMRecord;
        
        inst_TM.theTMLListSubcontractors =  [Select Id, Name, Resource__c, TM__r.Scheduled_Date__c, TM__c, TM__r.Name, Category__c, Line_No__c, Job_Start_Time__c,
                Job_End_Time__c, Site_Start_Time__c, Site_End_Time__c, Pick_Up_Rental__c,Resource_Type__r.Fleet_No_Required__c,
                Service_Center__r.Equipment_Fleet_No_Not_Required__c, Quantity__c, Unit_Price__c, Line_Amount__c, Service_Center__c,
                Resource__r.Non_Payroll_Labor_Resource__c,Resource_Name__c,To_Invoice__c, Invoiced__c,
                Bill_as_Lump_Sum__c, Non_Billable__c, Line_Amt_Incl_Tax__c, TM__r.Sales_Order__r.Portal_Basis__c,
                TM__r.Sales_Order__r.Portal_Basis_Adv__c, TM__r.Sales_Order__r.Overtime_Rate__c,
                TM__r.Sales_Order__r.Lump_Sum__c, TM__r.Sales_Order__r.Daily_Rate__c,Billing_Start_Time__c,
                Billing_End_Time__c, Resource__r.Status__c, Resource__r.Out_of_Service_Date__c, Resource__r.Name,
                Unit_of_Measure__c,Regular_Rate__c,Premium_Rate__c, Overtime_Rate__c, Lunch_Start_Time__c, Lunch_End_Time__c,
                Cost_Method__c, Facility__c, Container_Size__c, Min_Sell_Qty__c, Unit_Weight_Vol__c,
                Markup__c, Cost_Qty__c, Tax_Group__c, Tax_Pct__c, Line_Cost__c, Markup_Option__c, Tax__c,
                Regular_Hours__c, Overtime_Hours__c, Premium_Hours__c, Pricing_Source_2__c, Contract_Line__c,
                Sales_Line__c, Description__c,Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Subcontractors'];
        
        inst_TM.theTMLListWasteDisposal =  [Select Id, Name, Resource__c, TM__r.Scheduled_Date__c, TM__c, TM__r.Name, Category__c, Line_No__c, Job_Start_Time__c,
                Job_End_Time__c, Site_Start_Time__c, Site_End_Time__c, Pick_Up_Rental__c,Resource_Type__r.Fleet_No_Required__c,
                Service_Center__r.Equipment_Fleet_No_Not_Required__c, Quantity__c, Unit_Price__c, Line_Amount__c, Service_Center__c,
                Resource__r.Non_Payroll_Labor_Resource__c,Resource_Name__c,To_Invoice__c, Invoiced__c,
                Bill_as_Lump_Sum__c, Non_Billable__c, Line_Amt_Incl_Tax__c, TM__r.Sales_Order__r.Portal_Basis__c,
                TM__r.Sales_Order__r.Portal_Basis_Adv__c, TM__r.Sales_Order__r.Overtime_Rate__c,
                TM__r.Sales_Order__r.Lump_Sum__c, TM__r.Sales_Order__r.Daily_Rate__c,Billing_Start_Time__c,
                Billing_End_Time__c, Resource__r.Status__c, Resource__r.Out_of_Service_Date__c, Resource__r.Name,
                Unit_of_Measure__c,Regular_Rate__c,Premium_Rate__c, Overtime_Rate__c, Lunch_Start_Time__c, Lunch_End_Time__c,
                Cost_Method__c, Facility__c, Container_Size__c, Min_Sell_Qty__c, Unit_Weight_Vol__c,
                Markup__c, Cost_Qty__c, Tax_Group__c, Tax_Pct__c, Line_Cost__c, Markup_Option__c, Tax__c,
                Regular_Hours__c, Overtime_Hours__c, Premium_Hours__c, Pricing_Source_2__c, Contract_Line__c,
                Sales_Line__c, Description__c,Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Waste Disposal'];
        
        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theSResource');
        pref.getParameters().put('newFieldValue', ResourceRecord.ID );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '');
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', 'Invalid');
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theSQuantity');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theSUOM');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theSUnitPrice');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theSMarkup');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theSMarkupOption');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theSTaxGroup');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        
        pref.getParameters().put('fieldName', 'theWResource');
        pref.getParameters().put('newFieldValue', ResourceRecord.ID );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '');
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', 'Invalid');
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theWQuantity');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theWUOM');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theWUnitPrice');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theWMarkupOption');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theWMarkup');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theWTaxGroup');
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        Test.stopTest();
    }
    
    private static testMethod void Test_validateFields5() {
        TM__c TMRecord = [Select Id,Status__c, Scheduled_Date__c, Service_Center__c, Rate_Sheet__c, From_Sales_Quote__c,Sales_Order__c,Contract__c,Bill_to_Customer__c,Tax_Liable__c,Tax_Area__c From TM__c Limit 1];
        Unit_of_Measure__c UnitMeasureRecord = [Select Id From Unit_of_Measure__c Limit 1];
        Resource__c ResourceTransportationRecord = [Select Id From Resource__c Where Name =: 'TRAN2' Limit 1];
        PageReference pref = Page.TM;
        Test.setCurrentPage(pref);
        
        pref.getParameters().put('id', TMRecord.Id);
        
        
        TMController inst_TM = new TMController();
        inst_TM.theTM = TMRecord;
        List<TM_Line__c> testTMLList = [Select Id,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                             ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c,Resource__r.Resource_Type__c From TM_Line__c];

        Test.startTest();
        inst_TM.theTMLListDemurrage = testTMLList;
//        inst_TM.theTMLListLumpSum = testTMLList;
//        inst_Tm.theTMLListMisc = testTMLList;
    
        
        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theDResource');
        pref.getParameters().put('newFieldValue', ResourceTransportationRecord.Id );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '');
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', 'Invalid');
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theDSiteStartTime');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1:2' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theDSiteEndTime');
        pref.getParameters().put('newFieldValue', '1:2' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1002' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theDQuantity');
        pref.getParameters().put('newFieldValue', null );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '7777');
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theDUOM');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.ID );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theDUnitPrice');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();

        pref.getParameters().put('fieldName', 'theDTaxGroup');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        
        //Ticket#18265
        pref.getParameters().put('fieldName', 'theTMLDemurrageContractLine');
        pref.getParameters().put('newFieldValue', '');
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '7777');
        inst_TM.validateField();
        
        /*
        pref.getParameters().put('fieldName', 'theLumpSumResourceType');
        pref.getParameters().put('newFieldValue', '');
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', ResourceTypeRecord.Id);
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLumpQuantity');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLumpUOM');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLumpUnitPrice');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLumpSumContractLine');
        pref.getParameters().put('newFieldValue', '');
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '7777');
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theLumpTaxGroup');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        
        
        pref.getParameters().put('fieldName', 'theMiscQuantity');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theMiscUOM');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theMiscUnitPrice');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        
        pref.getParameters().put('fieldName', 'theMiscTaxGroup');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        */
        Test.stopTest();
    }

    private static testMethod void Test_validateFields_LumpSumSection() {
        TM__c TMRecord = [Select Id,Status__c,From_Sales_Quote__c,Sales_Order__c,Contract__c,Bill_to_Customer__c,Tax_Liable__c,Tax_Area__c From TM__c Limit 1];
        Resource_Type__c ResourceTypeRecord = [Select Id From Resource_Type__c Limit 1];
        Unit_of_Measure__c UnitMeasureRecord = [Select Id From Unit_of_Measure__c Limit 1];
        PageReference pref = Page.TM;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', TMRecord.Id);

        TMController inst_TM = new TMController();
        inst_TM.theTM = TMRecord;
        List<TM_Line__c> testTMLList = [Select Id,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c
                ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c,Resource__r.Resource_Type__c From TM_Line__c];

        inst_TM.theTMLListLumpSum = testTMLList;


        Test.startTest();
        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theLumpSumResourceType');
        pref.getParameters().put('newFieldValue', '');
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', ResourceTypeRecord.Id);
        inst_TM.validateField();

        pref.getParameters().put('fieldName', 'theLumpQuantity');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();

        pref.getParameters().put('fieldName', 'theLumpUOM');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        inst_TM.validateField();

        pref.getParameters().put('fieldName', 'theLumpUnitPrice');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();

        pref.getParameters().put('fieldName', 'theLumpSumContractLine');
        pref.getParameters().put('newFieldValue', '');
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '7777');
        inst_TM.validateField();

        pref.getParameters().put('fieldName', 'theLumpTaxGroup');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        Test.stopTest();
    }

    private static testMethod void Test_validateFields_MiscSection() {
        TM__c TMRecord = [Select Id,Name,Status__c,From_Sales_Quote__c,Scheduled_Date__c,Sales_Order__c,Contract__c,
                Bill_to_Customer__c,Tax_Liable__c,Tax_Area__c, Emergency_TM__c, Billing_Rule_Id__c,Sales_Order__r.Billing_Rule_Not_Required__c From TM__c Limit 1];
        Unit_of_Measure__c UnitMeasureRecord = [Select Id From Unit_of_Measure__c Limit 1];

        PageReference pref = Page.TM;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', TMRecord.Id);

        TMController inst_TM = new TMController();
        inst_TM.theTM = TMRecord;
        List<TM_Line__c> testTMLList = [Select Id,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c, Resource__r.Resource_Type__c
                ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c,Regular_Hours__c, Overtime_Hours__c, Premium_Hours__c, Unit_of_Measure__c, Hour__c,Billing_End_Time__c, Billing_Start_Time__c,Unit_Price__c
                ,Unit_Cost__c, Markup_Option__c, Markup__c, Tax__c, Line_Amount__c, Line_Amt_Incl_Tax__c,
                Cost_Method__c,Min_Sell_Qty__c,Facility__c,Container_Size__c,Unit_Weight_Vol__c,
                Tax_Group__c, Cost_Qty__c, Tax_Pct__c, Line_Cost__c FROM TM_Line__c];

        inst_Tm.theTMLListMisc = testTMLList;

        Test.startTest();
        pref.getParameters().put('lineNo', '0');

        pref.getParameters().put('fieldName', 'theMiscQuantity');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();

        pref.getParameters().put('fieldName', 'theMiscUOM');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        inst_TM.validateField();

        pref.getParameters().put('fieldName', 'theMiscUnitPrice');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();

        pref.getParameters().put('fieldName', 'theMiscTaxGroup');
        pref.getParameters().put('newFieldValue', '' );
        inst_TM.validateField();
        pref.getParameters().put('newFieldValue', '1' );
        inst_TM.validateField();
        Test.stopTest();
    }

    private static testMethod void Test_TMMgmt() {
        Test.startTest();
        TM__c TMRecord = [Select Id,Status__c,Sales_Order__r.Site_Contact_2__c, From_Sales_Quote__c,Sales_Order__c,Contract__c,Bill_to_Customer__c,Tax_Liable__c,Tax_Area__c From TM__c Limit 1];
        Service_Center__c ServiceCenterRecord = [Select Id,Name,Max_No_of_Emergency_T_M__c,Subsidiary_Company__c From Service_Center__c Limit 1];
        TM_Line__c TMLRecord = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                             ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c,Unit_of_Measure__c,Resource__r.Resource_Type__c,Unit_Price__c,Unit_Cost__c,Quantity__c,
                Markup_Option__c, Markup__c, Tax__c, Line_Amount__c, Line_Amt_Incl_Tax__c, Tax_Group__c, Cost_Qty__c, Tax_Pct__c, Line_Cost__c,
                Min_Sell_Qty__c, Cost_Method__c, Container_Size__c, Unit_Weight_Vol__c From TM_Line__c Where Category__c =: 'Labor' Limit 1];
        Contract_Line__c ContractLineRecord = [Select Id From Contract_Line__c Limit 1];
        Site_Address__c SiteAddressRecord = [Select Id From Site_Address__c Limit 1];
        String Timestr ='';
        TMMgmt.validateTime(Timestr);
        Timestr ='1:2:22';
        TMMgmt.validateTime(Timestr); 
        TMMgmt.validateSalesOrder(TMRecord);        
        TM__C TMrec = TMRecord;
        TMrec.Project_Coordinator__c = null;
        TMrec.Account_Executive__c = null;
        TMrec.Status__c = 'Void';        
        update TMrec;
        TMMgmt.validateSalespeople(TMrec);
        TM_Line__c TML = TMLRecord;
        TML.Service_Center__c = ServiceCenterRecord.Id;
        update TML;
        TMMgmt.updateTML(TML,TMRecord,'theServiceCenter');
        TMMgmt.updateTML(TML,TMRecord,'theBillingStartTime'); 
        TML.Regular_Hours__c = 0;
        TML.Overtime_Hours__c = 0;
        TML.Premium_Hours__c = 0;
        TML.Unit_Price__c = 0;
        update TML;   
        TMMgmt.updateTML(TML,TMRecord,'theQuantity');  
        TMMgmt.updateTML(TMLRecord ,TMRecord,'theUOM');
        TMMgmt.updateTML(TMLRecord ,TMRecord,'theOvertimeHour'); 
        TML.Contract_Line__c = ContractLineRecord.id;
        update TML;
        TMMgmt.updateTML(TMLRecord ,TMRecord,'theLContractLine');
        TMMgmt.updateTML(TMLRecord ,TMRecord,'theMContractLine');
        TMMgmt.updateTML(TMLRecord ,TMRecord,'theBillSiteTime');
        TMMgmt.updateTML(TMLRecord , TMRecord, 'theLBillasLumpSum');
        TMMgmt.updateTML(TMLRecord , TMRecord, 'theEBillasLumpSum');
        TMMgmt.updateTML(TMLRecord , TMRecord, 'theSiteStartTime');
        TMMgmt.updateTML(TMLRecord , TMRecord, 'theSiteStartTime');
        TMrec.Alternate_Site_Address__c = SiteAddressRecord.id;   
        //TMrec.T_M_Completed__c=True;
        update TMrec;
        Test.stopTest();
    }
    
    
    private static testMethod void Test_TMMgmt2() {
        Test.startTest();
        TM__c TMRecord = [Select Id,Status__c,From_Sales_Quote__c,Sales_Order__c,Contract__c,Bill_to_Customer__c,Tax_Liable__c,Tax_Area__c,Service_Center__c, Sales_Order__r.Site_Contact_2__c From TM__c Limit 1];
        TM_Line__c TMLRecord = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c
                                ,Unit_Cost__c, Markup_Option__c, Markup__c, Tax__c, Tax_Group__c, Cost_Qty__c, Tax_Pct__c, Line_Cost__c,
                                Min_Sell_Qty__c, Cost_Method__c, Container_Size__c, Unit_Weight_Vol__c From TM_Line__c Where Category__c =: 'Equipment' Limit 1];
        Contract  ContractRecord = [Select Id From Contract Limit 1];
        TM_Line__c TMLLaborRecord = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,
                Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c,
                TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c, Scheduled_Date__c,
                Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c,
                Unit_Cost__c, Markup_Option__c, Markup__c, Tax__c, Tax_Group__c, Cost_Qty__c, Tax_Pct__c,
                Min_Sell_Qty__c, Cost_Method__c, Container_Size__c, Unit_Weight_Vol__c, Line_Cost__c From TM_Line__c Where Category__c =: 'Labor' Limit 1];
        
        Site_Address__c SiteAddressRecord = [Select Id From Site_Address__c Limit 1];
        String Timestr = '';
        TMMgmt.validateTime(Timestr);
        Timestr = '1:2:22';
        TMMgmt.validateTime(Timestr);
        TM__C TMrec = TMRecord;
        TMMgmt.validateSalesOrder(TMRec);
        List<TM__c> theTMList = New List<TM__c>();
        
        theTMList.add(TMrec);
        List<TM_Line__c> theTMLList = New List<TM_Line__c>();
        TM_Line__c TMEL = TMLRecord;
        
        TMMgmt.checkCreateInvoice(theTMList, theTMLList);
        theTMLList.add(TMEL);
        TMMgmt.checkCreateInvoice(theTMList, theTMLList);
        //TMMgmt.validateTMCompleted(TMrec);
        TM__C TMconfrec = TMRecord ;
        Map<Id, TM__c> oldTMMap = new Map<Id, TM__c>();
        oldTMMap.put(TMconfrec.Id,TMconfrec);   
        
        TMTriggersMgmt.TMInsertUpdate(theTMList,oldTMMap,True);
        
        
        TMMgmt.validateTaxArea(TMrec);
        
        TMMgmt.setPricing(TMLLaborRecord,TMRecord);
        
        TMMgmt.nullRelationshipFields(TMRecord);
    
        TMRecord.Alternate_Site_Address__c = SiteAddressRecord.Id;
        TMMgmt.validateAltSiteAddress(TMRecord);
        TMMgmt.updateTML(TMLLaborRecord,TMRecord, 'theLQuantity');
        Test.stopTest();
    }
    
    private static testMethod void Test_ShceduledTM() {
        Test.startTest();
        TM__c TMRecord = [Select Id,Status__c,From_Sales_Quote__c, Sales_Order__r.Site_Contact_2__c, Sales_Order__c,
                Contract__c,Bill_to_Customer__c,Tax_Liable__c,Tax_Area__c,Service_Center__c, Scheduled_Date__c,
                Rate_Sheet__c
                From TM__c Limit 1];
        TM_Line__c TMEquipmentLineRec = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c,
                                Cost_Method__c, Facility__c, Container_Size__c, Min_Sell_Qty__c, Unit_Weight_Vol__c
                                From TM_Line__c Where Category__c =: 'Equipment' Limit 1];
        Contract  ContractRecord = [Select Id From Contract Limit 1];
        TM_Line__c TMELaborLineRec = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                    ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                     Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                     Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c,
                                    Cost_Method__c, Facility__c, Container_Size__c, Min_Sell_Qty__c, Unit_Weight_Vol__c
                                From TM_Line__c Where Category__c =: 'Labor' Limit 1];
        

        TMRecord.Status__C = 'Confirmed';
        List<TM__c> theTMList = New List<TM__c>();
        theTMList.add(TMRecord);
        
        Map<Id, TM__c> oldTMMap=New Map<Id, TM__c>();
        TM__C TMRec2 = TMRecord.clone();
        TMRec2.Status__c = 'Scheduled';
        oldTMMap.put(TMRecord.Id,TMrec2); 
        
        TMTriggersMgmt.TMInsertUpdate(theTMList,oldTMMap,False);
        Test.stopTest();
    }
    
    private static testMethod void Test_TMMgmt3() {
        Test.startTest();
        TM__c TMRecord = [Select Id,Status__c,Emergency_TM__c,From_Sales_Quote__c,Sales_Order__c,Contract__c,Tax_Liable__c,Tax_Area__c,Service_Center__c,Bill_to_Customer__c, Sales_Order__r.Site_Contact_2__c From TM__c Limit 1];
        TM_Line__c TMEquipmentLineRec = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Equipment' Limit 1];
        Contract  ContractRecord = [Select Id From Contract Limit 1];
        TM_Line__c TMELaborLineRec = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                    ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                     Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                     Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Labor' Limit 1];
       
        
        /*TM__c TMRecord = new TM__c(
            Bill_to_Customer__c = TestDataUtil.AccountRecord.Id,
            Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id,
            Account_Executive__c = TestDataUtil.SalespersonRecord.Id,
            Prevailing_Wage_Job__c = true,
            Certified_PW_Job__c = true,
            Contract__c=ContractRecord.Id,
            Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id,
            Tax_Area__c = TestDataUtil.TaxAreaRecord.Id,
            Sales_Order__c = TestDataUtil.SalesOrderRecord.Id,
            Scheduled_Date__c = Date.today().addDays(-7),
            Status__c = 'Open',
            Emergency_TM__c = true
        );
        insert TMRecord;
        TM_Line__c   TMLineLaborRecord = new TM_Line__c(
            Line_No__c = 1,
            Description__c = 'Test item',
            Quantity__c = 1100,
            Category__c= 'Labor',
            TM__c= TMRecord.Id,
            Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id,
            Resource__c = TestDataUtil.ResourceLaborRecord.Id,
            Total_Site_Hours__c = 1100,
            Hour__c=1100,
            Regular_Hours__c = 550,
            Regular_Rate__c = 1,
            Overtime_Rate__c= 1,
            Overtime_Hours__c = 550,
            Tax_Group__c='TX',
            Service_Center__c=TestDataUtil.ServiceCenterRecord.Id,
            Unit_of_Measure__c=TestDataUtil.UnitMeasureRecord.Id
        );
        insert TMLineLaborRecord;*/
        
        TMMgmt.setPricing(TMELaborLineRec,TMRecord);
        
        Account a = [
            SELECT Id, Name, Pricing_Group__c
            FROM Account
            WHERE Id = :TMRecord.Bill_to_Customer__c
            LIMIT 1
        ];
        a.Pricing_Group__c = 'Gold';
        TMMGmt.mapAccount.put(TMRecord.Bill_to_Customer__c, a);
        TMMgmt.setPricing(TMELaborLineRec,TMRecord);
        
        a.Pricing_Group__c = 'Platinum';
        TMMGmt.mapAccount.put(TMRecord.Bill_to_Customer__c, a);
        TMMgmt.setPricing(TMELaborLineRec,TMRecord);
        Test.stopTest();
    }
    
    private static testMethod void Test_TMMgmt4() {
        
        Test.startTest();
        TM__c TMRecord = [Select Id,Status__c,Emergency_TM__c,From_Sales_Quote__c,Sales_Order__c,Contract__c,Tax_Liable__c,Tax_Area__c,Service_Center__c,Bill_to_Customer__c, Sales_Order__r.Site_Contact_2__c From TM__c Limit 1];
        TM_Line__c TMEquipmentLineRec = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Equipment' Limit 1];
        Contract  ContractRecord = [Select Id From Contract Limit 1];
        TM_Line__c TMELaborLineRec = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                    ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                     Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                     Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Labor' Limit 1];
       
        
        
        /*TM__c TMRecord = new TM__c(
            Bill_to_Customer__c = TestDataUtil.AccountRecord.Id,
            Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id,
            Account_Executive__c = TestDataUtil.SalespersonRecord.Id,
            Prevailing_Wage_Job__c = true,
            Certified_PW_Job__c = true,
            Contract__c=ContractRecord.Id,
            Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id,
            Tax_Area__c = TestDataUtil.TaxAreaRecord.Id,
            Sales_Order__c = TestDataUtil.SalesOrderRecord.Id,
            Scheduled_Date__c = Date.today().addDays(-7),
            Status__c = 'Open'
        );
        insert TMRecord;
        TM_Line__c   TMLineLaborRecord = new TM_Line__c(
            Line_No__c = 1,
            Description__c = 'Test item',
            Quantity__c = 1100,
            Category__c= 'Labor',
            TM__c= TMRecord.Id,
            Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id,
            Resource__c = TestDataUtil.ResourceLaborRecord.Id,
            Total_Site_Hours__c = 1100,
            Hour__c=1100,
            Regular_Hours__c = 550,
            Regular_Rate__c = 1,
            Overtime_Rate__c= 1,
            Overtime_Hours__c = 550,
            Tax_Group__c='TX',
            Service_Center__c=TestDataUtil.ServiceCenterRecord.Id,
            Unit_of_Measure__c=TestDataUtil.UnitMeasureRecord.Id
        );
        insert TMLineLaborRecord;*/
        
        TMMgmt.setPricing(TMELaborLineRec,TMRecord);
        
        Account a = [
            SELECT Id, Name, Pricing_Group__c
            FROM Account
            WHERE Id = :TMRecord.Bill_to_Customer__c
            LIMIT 1
        ];
        a.Pricing_Group__c = 'Gold';
        TMMGmt.mapAccount.put(TMRecord.Bill_to_Customer__c, a);
        TMMgmt.setPricing(TMELaborLineRec,TMRecord);
        
        a.Pricing_Group__c = 'Platinum';
        TMMGmt.mapAccount.put(TMRecord.Bill_to_Customer__c, a);
        TMMgmt.setPricing(TMELaborLineRec,TMRecord);
    }
    
    private static testMethod void Test_TMMgmt5() {
        Test.startTest();
        TM__c TMRecord = [Select Id,Status__c,Emergency_TM__c,From_Sales_Quote__c,Sales_Order__c,Contract__c,Tax_Liable__c,Tax_Area__c,Service_Center__c,Bill_to_Customer__c, Sales_Order__r.Site_Contact_2__c From TM__c Limit 1];
        TM_Line__c TMLineEquipmentRecord = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Equipment' Limit 1];
        Contract  ContractRecord = [Select Id From Contract Limit 1];
        Resource_Type__c ResourceTypeRecord = [Select Id,Unit_of_Measure__c From Resource_Type__c Limit 1]; 
        TM_Line__c TMELaborLineRec = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                    ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                     Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                     Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Labor' Limit 1];
       
        
        
        /*Contract  ContractRecord= TestDataUtil.ContractRecord;
        
        TM__c TMRecord = new TM__c(
            Bill_to_Customer__c = TestDataUtil.AccountRecord.Id,
            Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id,
            Account_Executive__c = TestDataUtil.SalespersonRecord.Id,
            Prevailing_Wage_Job__c = true,
            Certified_PW_Job__c = true,
            Contract__c=ContractRecord.Id,
            Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id,
            Tax_Area__c = TestDataUtil.TaxAreaRecord.Id,
            Sales_Order__c = TestDataUtil.SalesOrderRecord.Id,
            Scheduled_Date__c = Date.today().addDays(-7),
            Status__c = 'Open'
        );
        insert TMRecord;
        
        TM_Line__c TMLineEquipmentRecord = new TM_Line__c(
            Line_No__c = 2,
            Description__c = 'Test E',
            Quantity__c = 1100,
            Category__c = 'Equipment',
            TM__c = TMRecord.Id,
            // Resource_Type__c = ResourceTypeRecord.Id,
            Resource_Type__c = TestDataUtil.ResourceTypeEquipmentRecord.Id,
            Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
            Resource__c = TestDataUtil.ResourceEquipmentRecord.Id,
            Total_Site_Hours__c = 1100,
            Regular_Hours__c = 550,
            Overtime_Hours__c = 550,
            Tax_Group__c = 'TX',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id//Added to add missing field
        );
        insert TMLineEquipmentRecord;
        
        Contract_Line__c ContractLineRecord = new Contract_Line__c (
            Name='Test ContractLine',
            Contract__c=ContractRecord.Id,
            Premium_Rate__c=10,
            Resource_Type__c=TMLineEquipmentRecord.Resource_Type__c,
            Resource__c=TestDataUtil.ResourceEquipmentRecord.Id,
            
            Unit_of_Measure__c=TMLineEquipmentRecord.Unit_of_Measure__c
        );
        insert ContractLineRecord ;*/
        TMLineEquipmentRecord.Resource_Type__c = ResourceTypeRecord.Id;
        update TMLineEquipmentRecord;
        TMMgmt.setPricing(TMLineEquipmentRecord,TMRecord);
        
        Test.stopTest();
        
    }
    
    private static testMethod void Test_TMMgmt6() {
        Test.startTest();
        TM__c TMRecord = [Select Id,Status__c,Emergency_TM__c,From_Sales_Quote__c,Sales_Order__c,Contract__c,Tax_Liable__c,Tax_Area__c,Service_Center__c,Bill_to_Customer__c, Sales_Order__r.Site_Contact_2__c From TM__c Limit 1];
        TM_Line__c TMLineEquipmentRecord = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Equipment' Limit 1];
        Contract  ContractRecord = [Select Id From Contract Limit 1];
        Resource_Type__c ResourceTypeRecord = [Select Id,Unit_of_Measure__c From Resource_Type__c Limit 1]; 
        TM_Line__c TMELaborLineRec = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                    ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                     Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                     Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Labor' Limit 1];
      
        
        /*TM__c TMRecord = new TM__c(
            Bill_to_Customer__c = TestDataUtil.AccountRecord.Id,
            Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id,
            Account_Executive__c = TestDataUtil.SalespersonRecord.Id,
            Prevailing_Wage_Job__c = true,
            Certified_PW_Job__c = true,
            Contract__c=ContractRecord.Id,
            Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id,
            Tax_Area__c = TestDataUtil.TaxAreaRecord.Id,
            Sales_Order__c = TestDataUtil.SalesOrderRecord.Id,
            Scheduled_Date__c = Date.today().addDays(-7),
            Status__c = 'Open'
        );
        insert TMRecord;
        
        TM_Line__c TMLineEquipmentRecord = new TM_Line__c(
            Line_No__c = 2,
            Description__c = 'Test E',
            Quantity__c = 1100,
            Category__c = 'Equipment',
            TM__c = TMRecord.Id,
            // Resource_Type__c = ResourceTypeRecord.Id,
            Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
            Resource_Type__c = TestDataUtil.ResourceTypeEquipmentRecord.Id,
            Resource__c = TestDataUtil.ResourceEquipmentRecord.Id,
            Total_Site_Hours__c = 1100,
            Regular_Hours__c = 550,
            Overtime_Hours__c = 550,
            Tax_Group__c = 'TX',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id//Added to add missing field
        );
        insert TMLineEquipmentRecord;*/
        TMLineEquipmentRecord.Resource_Type__c = ResourceTypeRecord.Id;
        update TMLineEquipmentRecord;
        TMMgmt.setPricing(TMLineEquipmentRecord,TMRecord);
        
        Account a = [
            SELECT Id, Name, Pricing_Group__c
            FROM Account
            WHERE Id = :TMRecord.Bill_to_Customer__c
            LIMIT 1
        ];
        a.Pricing_Group__c = 'Gold';
        TMMGmt.mapAccount.put(TMRecord.Bill_to_Customer__c, a);
        TMMgmt.setPricing(TMLineEquipmentRecord,TMRecord);
        
        a.Pricing_Group__c = 'Platinum';
        TMMGmt.mapAccount.put(TMRecord.Bill_to_Customer__c, a);
        TMMgmt.setPricing(TMLineEquipmentRecord,TMRecord);
        Test.stopTest();
    }
    
    private static testMethod void Test_TMMgmt7() {
        
        Test.startTest();
        TM__c TMRecord = [Select Id,Status__c,Emergency_TM__c,From_Sales_Quote__c,Sales_Order__c,Contract__c,Tax_Liable__c,Tax_Area__c,Service_Center__c,Bill_to_Customer__c, Sales_Order__r.Site_Contact_2__c From TM__c Limit 1];
        TM_Line__c TMLineEquipmentRecord = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Equipment' Limit 1];
        Contract  ContractRecord = [Select Id From Contract Limit 1];
        Resource_Type__c ResourceTypeRecord = [Select Id,Unit_of_Measure__c From Resource_Type__c Limit 1]; 
        TM_Line__c TMELaborLineRec = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                    ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                     Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                     Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Labor' Limit 1];
      
        
        
        /*TM__c TMRecord = new TM__c(
            Bill_to_Customer__c = TestDataUtil.AccountRecord.Id,
            Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id,
            Account_Executive__c = TestDataUtil.SalespersonRecord.Id,
            Prevailing_Wage_Job__c = true,
            Certified_PW_Job__c = true,
            Contract__c=ContractRecord.Id,
            Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id,
            Tax_Area__c = TestDataUtil.TaxAreaRecord.Id,
            Sales_Order__c = TestDataUtil.SalesOrderRecord.Id,
            Scheduled_Date__c = Date.today().addDays(-7),
            Status__c = 'Open',
            Emergency_TM__c = true
        );
        insert TMRecord;
        
        TM_Line__c TMLineEquipmentRecord = new TM_Line__c(
            Line_No__c = 2,
            Description__c = 'Test E',
            Quantity__c = 1100,
            Category__c = 'Equipment',
            TM__c = TMRecord.Id,
            // Resource_Type__c = ResourceTypeRecord.Id,
            Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
            Resource_Type__c = TestDataUtil.ResourceTypeEquipmentRecord.Id,
            Resource__c = TestDataUtil.ResourceEquipmentRecord.Id,
            Total_Site_Hours__c = 1100,
            Regular_Hours__c = 550,
            Overtime_Hours__c = 550,
            Tax_Group__c = 'TX',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id//Added to add missing field
        );
        insert TMLineEquipmentRecord;*/
        TMLineEquipmentRecord.Resource_Type__c = ResourceTypeRecord.Id;
        update TMLineEquipmentRecord;
        TMMgmt.setPricing(TMLineEquipmentRecord,TMRecord);
        
        Account a = [
            SELECT Id, Name, Pricing_Group__c
            FROM Account
            WHERE Id = :TMRecord.Bill_to_Customer__c
            LIMIT 1
        ];
        a.Pricing_Group__c = 'Gold';
        TMMGmt.mapAccount.put(TMRecord.Bill_to_Customer__c, a);
        TMMgmt.setPricing(TMLineEquipmentRecord,TMRecord);
        
        a.Pricing_Group__c = 'Platinum';
        TMMGmt.mapAccount.put(TMRecord.Bill_to_Customer__c, a);
        TMMgmt.setPricing(TMLineEquipmentRecord,TMRecord);
        Test.stopTest();
    }
    
    static testMethod void Test_TMMgmt8() {
        Test.startTest();
        TM__c TMRecord = [Select Id,Name,Bill_to_Customer__r.Payment_Term__c,Status__c,Emergency_TM__c,From_Sales_Quote__c,
                Sales_Order__c,Contract__c,Tax_Liable__c,Tax_Area__c,Service_Center__c,Bill_to_Customer__c,
                Sales_Order__r.Site_Contact_2__c, Bill_to_Customer__r.AccountNumber,Sales_Order__r.Billing_Rule_Not_Required__c
                From TM__c Limit 1];
        TM_Line__c TMLineDemurrageRecord = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,Cost_Method__c, Min_Sell_Qty__c, Facility__c, Container_Size__c, Unit_Weight_Vol__c,
                                Unit_Cost__c, Markup_Option__c, Markup__c, Tax__c, Tax_Group__c, Cost_Qty__c, Tax_Pct__c, Line_Cost__c,
                                Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Demurrage' Limit 1];
        Contract  ContractRecord = [Select Id From Contract Limit 1];
        Resource_Type__c ResourceTypeRecord = [Select Id,Unit_of_Measure__c From Resource_Type__c Limit 1]; 
        TM_Line__c TMLineLaborRecord = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,
                Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c,
                TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                TM__r.Sales_Order__r.Portal_Basis_Adv__c, TM__r.Sales_Order__r.Overtime_Rate__c,
                Unit_Cost__c, Markup_Option__c, Markup__c, Tax__c, Tax_Group__c, Cost_Qty__c, Tax_Pct__c, Line_Cost__c,
                TM__r.Sales_Order__r.Portal_Basis__c, TM__r.Sales_Order__r.Daily_Rate__c, TM__r.Sales_Order__r.Lump_Sum__c,
                Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c,
                Cost_Method__c, Min_Sell_Qty__c, Facility__c, Container_Size__c, Unit_Weight_Vol__c
                                    From TM_Line__c Where Category__c =: 'Labor' Limit 1];
        Sales_Line__c  SalesLineRecord = [Select Id From Sales_Line__c Limit 1];
        Sales_Order__c  SalesOrderRecord = [Select Id From Sales_Order__c Limit 1];
        Contract_Line__c  ContractLineRecord = [Select Id From Contract_Line__c Limit 1];
        TM__c theTM = TMRecord;
        TM_Line__c theTML = TMLineLaborRecord;
        List<TM__c> theTMList = new List<TM__c>();
        List<TM_Line__c> theTMLList = new List<TM_Line__c>();
        theTMList.add(theTM);
        theTMLList.add(theTML);
        
        theTML.Quantity__c = 0;
        theTML.Bill_as_Lump_Sum__c = true;
        theTML.Line_Amount__c = 1;
        TMMgmt.checkCreateInvoice(theTMList, theTMLList);
        /*test
        theTM.Contact__c = TestDataUtil.Contact2Record.Id;
        TMMgmt.validateContact(theTM);
         */
        
        String sourceField = 'theResource';
        TMMgmt.updateTML(theTML, theTM, sourceField);
        /*
        sourceField = 'TimeValidation';
        theTML.Regular_Hours__c = 0;
        theTML.Overtime_Hours__c = 0;
        theTML.Premium_Hours__c = 0;
        TMMgmt.updateTML(theTML, theTM, sourceField);
        TM_Line__c theTMLDemurrage = TMLineDemurrageRecord;
        theTMLDemurrage.Regular_Hours__c = 0;
        theTMLDemurrage.Overtime_Hours__c = 0;
        TMMgmt.updateTML(theTMLDemurrage, theTM, 'theSiteStartTime');
        Contract_Line__c contractLine = ContractLineRecord;
        theTMLDemurrage.Contract_Line__c = contractLine.Id;
        TMMgmt.updateTML(theTMLDemurrage, theTM, 'theLContractLine');
        theTML.Bill_as_Lump_Sum__c = true;
        TMMgmt.updateTML(theTML, theTM, 'theLBillasLumpSum');
        TMMgmt.updateTML(theTML, theTM, 'theEBillasLumpSum');
        theTML.Bill_as_Lump_Sum__c = false;
        theTML.Contract_Line__c = null;
        TMMgmt.updateTML(theTML, theTM, 'theLBillasLumpSum');
        theTML.Bill_Site_Time__c = true;
        theTML.Include_Lunch_Y_N__c = true;
        theTM.Tax_Liable__c = true;
        theTML.Tax_Group__c = 'NY';
        TMMgmt.updateTML(theTML, theTM, 'TimeValidation');
        theTML.Bill_Site_Time__c = true;
         */
        TMMgmt.populateBillingTimeInfo(theTML, theTM);
        /*
        Unit_of_Measure__c uom = TMMgmt.mapUnitOfMeasures.get(theTML.Unit_of_Measure__c);
        uom.Hours_UOM__c = true;
        TMMgmt.calculateQuantity(theTML);
        TMMgmt.mapUnitOfMeasures.remove(theTML.Unit_of_Measure__c);
        TMMgmt.calculateUnitPrice(theTML);
         */
        
        
        Sales_Line__c salesLine = SalesLineRecord;
        salesLine.Unit_of_Measure__c = theTML.Unit_of_Measure__c;
        salesLine.Unit_Price__c = 1;
        update salesLine;
        /*
        theTML.Sales_Line__c = salesLine.Id;
        TMMgmt.setPricing(theTML, theTM);
        TM_Line__c tmlDemurrage = TMLineDemurrageRecord;
        tmlDemurrage.sales_line__c = salesLine.Id;
        tmlDemurrage.Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
        TMMgmt.setPricing(tmlDemurrage, theTM);
        theTML.Sales_Line__c = null;
        Sales_Order__c theSO = SalesOrderRecord;
        theSO = TMMgmt.mapSalesOrder.get(theTM.Sales_Order__c);
        theSO.Emergency_Sales_Order__c = true;
        Account acct = TMMgmt.mapAccount.get(theTM.Bill_to_Customer__c);
        acct.Pricing_Group__c = 'Silver';
        TMMgmt.setPricing(theTML, theTM);
        acct.Pricing_Group__c = 'Gold';
        TMMgmt.setPricing(theTML, theTM);
        acct.Pricing_Group__c = 'Platinum';
        TMMgmt.setPricing(theTML, theTM);
         */
        Test.stopTest();
    }
    
    private static testMethod void Test_AddScheduleTMConfirmation() {
        Test.startTest();
        TM__c TMRecord = [Select Id,Name,Bill_to_Customer__r.Payment_Term__c,Status__c,Emergency_TM__c,From_Sales_Quote__c,Sales_Order__c,Contract__c,Tax_Liable__c,Tax_Area__c,Service_Center__c,Bill_to_Customer__c, Sales_Order__r.Site_Contact_2__c From TM__c Limit 1];
        System.debug('TMID==>' + TMRecord.Id);
        Test.setCurrentPageReference(new PageReference('Page.AddScheduleTMConfirmation'));
        System.currentPageReference().getParameters().put('selectedTMId', TMRecord.Id);
        AddScheduleTMConfirmationController a = new AddScheduleTMConfirmationController();
        a.returnToOpenTMs();
        a.changeStatusToSchedule();
        DateTime d = Date.Today() ;
        a.scheduledDateValue =  d.format('MM/dd/yyyy') ;
        a.changeStatusToSchedule();
        Test.stopTest();
    }
    
    private static testMethod void Test_TMWrapperPagination() {
        Test.startTest();
        TM__c TMRecord = [Select Id,Name,Bill_to_Customer__r.Payment_Term__c,Status__c,Emergency_TM__c,From_Sales_Quote__c,Sales_Order__c,Contract__c,Tax_Liable__c,Tax_Area__c,Service_Center__c,Bill_to_Customer__c, Sales_Order__r.Site_Contact_2__c From TM__c Limit 1];
        
        List<String> subMenuItems = new List<String>();
        subMenuItems.add('test');
        List<string> labor = new List<string>();
        labor.add('test');
        List<string> equipment = new List<string>();
        equipment.add('test');
        TMController.TMWrapper tmr = new TMController.TMWrapper(subMenuItems, TMRecord, labor, equipment, True, 'test' );
        List<TMController.TMWrapper> Records = new List<TMController.TMWrapper>();
        
        for (Integer I = 0; I < 25; I++) Records.add(tmr);
        
        TMWrapperPagination pmwp = New TMWrapperPagination(Records, 1);
        pmwp.beginning();
        pmwp.next();
        pmwp.previous();
        pmwp.getDisableNext();
        pmwp.getDisablePrevious();
        pmwp.pageNumber();
        pmwp.getAll();
        pmwp.getpage(1);
        pmwp.getStartIndex();
        pmwp.getEndIndex();
        Test.stopTest();
        
    }
    
    private static testMethod void Test_TMTriggersMgmt() {
        Test.startTest();
        TM__c TMRecord = [Select Id,Name,Bill_to_Customer__r.Payment_Term__c,Status__c,Emergency_TM__c,From_Sales_Quote__c,Sales_Order__c,Contract__c,Tax_Liable__c,Tax_Area__c,Service_Center__c,Bill_to_Customer__c, Sales_Order__r.Site_Contact_2__c From TM__c Limit 1];
        TM_Line__c TMLineEquipmentRecord = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Equipment' Limit 1];
        Contract  ContractRecord = [Select Id From Contract Limit 1];
        Resource_Type__c ResourceTypeRecord = [Select Id,Unit_of_Measure__c From Resource_Type__c Limit 1]; 
        TM_Line__c TMLineLaborRecord = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                    ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                     Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                     Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Labor' Limit 1];
        TM_Line__c TMLineWaterDisposalRecord = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                    ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                     Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                     Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Waste Disposal' Limit 1];
        Sales_Line__c SalesEquipmentLineRecord = [Select Id From Sales_Line__c Where Category__c =: 'Equipment' Limit 1];
        Sales_Line__c SalesWasteLineRecord = [Select Id From Sales_Line__c Where Category__c =: 'Waste Disposal' Limit 1];
        Sales_Line__c SalesLineRecord = [Select Id From Sales_Line__c Where Category__c =: 'Labor' Limit 1];
        Sales_Order__c  SalesOrderRecord = [Select Id From Sales_Order__c Limit 1];
        Contract_Line__c  ContractLineRecord = [Select Id From Contract_Line__c Limit 1];
        
        TM__C TMrec = TMRecord;
        TMrec.Status__c='Scheduled';
        Update TMrec;     
        List<TM__c> theTMList = New List<TM__c>();
        theTMList.add(TMrec);
        SalesLineRecord.Contract_Regular_Rate__c=10;
        update SalesLineRecord; 
        List<TM_Line__c> theTMLList = new List<TM_Line__c>();
        TM_Line__c TMEL = TMLineEquipmentRecord;
        TM_Line__c TMELL = TMLineLaborRecord ;  
        TM_Line__c TMELD = TMLineWaterDisposalRecord ;
        theTMLList.add(TMEL);
                theTMLList.add(TMELL);
        theTMLList.add(TMELD);

        TMELL.Quote_Line__c = SalesLineRecord.id ;
        TMELL.Job_Start_Time__c = Time.newInstance(18, 30, 2, 20);        
        TMELL.Job_End_Time__c = Time.newInstance(18, 30, 2, 20);
        TMEL.Job_Start_Time__c = Time.newInstance(18, 30, 3, 20);
        TMEL.Job_End_Time__c = Time.newInstance(18, 30, 2, 20);
        TMELD.Job_Start_Time__c = Time.newInstance(18, 30, 3, 20);
        TMELD.Job_End_Time__c = Time.newInstance(18, 30, 2, 20);
        
        TMELL.Regular_Rate__c = null; 
        TMELL.Overtime_Rate__c = 0; 
        TMELL.Resource_Type__c = null;                             
        TMEL.Quote_Line__c = SalesEquipmentLineRecord.Id ;
        //TMEL.Unit_of_Measure__c = null;
        //TMELL.Unit_of_Measure__c = null;
        //TMELD.Unit_of_Measure__c = null;
        TMELD.Quote_Line__c = SalesWasteLineRecord.Id ;
        
        update TMEL;
        //update TMELL;
        update TMELD;                
        TM__C TMconfrec = TMRecord.clone(True,True,False,True);          
        TMconfrec.Status__c = 'Confirmed';
        //Update TMconfrec;
        Map<Id, TM__c> oldTMMap = new Map<Id, TM__c>();
        oldTMMap.put(TMconfrec.Id, TMconfrec);
        
        Map<Id, TM_Line__c> TMLMap = new Map<Id, TM_Line__c>(); 
        TMLMap.put(TMEL.Id,TMEL );   
        TMLMap.put(TMELL.Id,TMELL ); 
        TMLMap.put(TMELD.Id,TMELD );                              
        TMTriggersMgmt.TMInsertUpdate(theTMList,oldTMMap,True);     
                TMTriggersMgmt.TMLDelete(theTMLList,TMLMap);
        CompanyMgmt.systemCall= false;
        TMTriggersMgmt.TMLInsertUpdate(theTMLList,TMLMap,false);
        theTMLList[0].Invoiced__c = true;
        TMTriggersMgmt.TMLInsertUpdate(theTMLList,TMLMap,false);        
        Test.stopTest();        
    }    
    
    private static testMethod void Test_TMTriggersMgmt2() {
        Test.startTest(); 
        TM__c TMRecord = [Select Id,Name,Bill_to_Customer__r.Payment_Term__c,Status__c,Emergency_TM__c,From_Sales_Quote__c,Sales_Order__c,Contract__c,Tax_Liable__c,Tax_Area__c,Service_Center__c,Bill_to_Customer__c, Sales_Order__r.Site_Contact_2__c From TM__c Limit 1];
        
        TM__C TMrec = TMRecord;
        TMrec.Status__c='Scheduled';
        Update TMrec;
                
        //test Field TM PDF Send/Save
        //signature request <<
        //Signature__c sig = new Signature__c(Name='customer_signature', Email__c = 'kchen@micro-datanet.com', Related_To_Id__c = TMRecord.Id, Related_To_Object_Name__c = 'TM__c', Print_Name__c = 'c', Accept_Terms_and_Conditions__c = TRUE);
        Signature__c sig = new Signature__c(Name='customer_signature', Signer_Role__c='Customer A', Email__c = 'kchen@micro-datanet.com', TM__c = TMRecord.Id, Print_Name__c = 'c', Accept_Terms_and_Conditions__c = TRUE);
        //signature request >>
        insert sig;
        

        TM__C TMrecSch = TMrec.clone(True,True,False,True);
        TMrecSch.Project_Manager_Reviewed__c = true;
        TMrec.Status__c='Confirmed';
        //Update TMrec;  
        
        List<TM__c> theTMList = New List<TM__c>();
        theTMList.add(TMrec);               
        
        //TM__C TMconfrec = TestDataUtil.TMConfirmedRecord ;
        TM__C TMconfrec = TMRecord.clone(True,True,False,True);          
        TMconfrec.Status__c = 'Confirmed';
        //Update TMconfrec;
        
        Map<Id, TM__c> oldTMMap = new Map<Id, TM__c>();
        
        oldTMMap.put(TMrecSch.Id,TMrecSch);         

		Map<Id, TM__c> newTMMap = new Map<Id, TM__c>();
        
        newTMMap.put(TMrec.Id,TMrec); 
        TMTriggersMgmt.TMInsertUpdate(theTMList,oldTMMap,True);  
        theTMList[0].Status__c = 'Void';
        TMTriggersMgmt.TMInsertUpdate(theTMList,oldTMMap,True);
        theTMList[0].Status__c = 'Mobile Review';
        TMTriggersMgmt.TMInsertUpdate(theTMList,oldTMMap,True);
        theTMList[0].Status__c = 'Fully Invoiced';
        TMTriggersMgmt.TMInsertUpdate(theTMList,oldTMMap,True);
        theTMList[0].Status__c = 'Partially Invoiced';
        TMTriggersMgmt.TMInsertUpdate(theTMList,oldTMMap,True);
        theTMList[0].Status__c = 'Ready to Bill';
        TMTriggersMgmt.TMInsertUpdate(theTMList,oldTMMap,True);
        theTMList[0].Status__c = 'Received By Billing';
        theTMList[0].Sales_Order__c = null;
        TMTriggersMgmt.TMInsertUpdate(theTMList,oldTMMap,True);
        theTMList[0].Mobile_TM__c = true;
        CompanyMgmt.systemCall = false;
        TMTriggersMgmt.TMInsertUpdate(theTMList,oldTMMap,false);
        theTMList[0].Status__c='Scheduled';
        oldTMMap.get(theTMList[0].Id).Status__c = 'Open';
        TMTriggersMgmt.updateSalesOrderFromTMMap(theTMList,newTMMap,oldTMMap);
        TMTriggersMgmt.isTMHeaderUpdated(TMrec,TMrecSch);
        Test.stopTest();        
    }

    private static testMethod void testTMTriggersMgmtTMLInsertUpdate(){
        TM__c TMRecord = [SELECT Id,Status__c,From_Sales_Quote__c,Sales_Order__c,Contract__c,Bill_to_Customer__c,Tax_Liable__c,Tax_Area__c FROM TM__c LIMIT 1];
        TMRecord.Status__c = 'Confirmed';
        CompanyMgmt.byPassTrigger = true;
        update TMRecord;
        CompanyMgmt.byPassTrigger = false;
        List<TM_Line__c> testTMLList = [SELECT Id,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c
                ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c,Resource__r.Resource_Type__c FROM TM_Line__c];

        Test.startTest();
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        TM_Line__c tmLine = testTMLList[0];
        tmLine.Invoiced__c = true;
        try {
            update tmLine;
        } catch (Exception e){
            System.debug(e);
        }
        Test.stopTest();
    }

    private static testMethod  void testTMLinesServiceImpl() {

        TM__c tm = [SELECT Id, Contract__c, Sales_Order__c, (SELECT Id, TM__c, Category__c, Description__c, Contract_Line__c, Resource_Type__c, Resource__c, Unit_of_Measure__c FROM TM_Lines__r) FROM TM__c WHERE Contract__c != NULL LIMIT 1];
        List<Resource__c> laborResLst = [SELECT Id, Description__c, Service_Center__c, Pay_Rule__c, Pay_Rule__r.Type__c, Pay_Rule__r.Mon_Sun_Work_Week__c, Resource_Type__c FROM Resource__c Limit 1];
        Set<Id> payRuleIdSet = new Set<Id>();
        for(Resource__c res : laborResLst){
            payRuleIdSet.add(res.Pay_Rule__c);
        }
        TM_Line__c tmLine = tm.TM_Lines__r[0];
        Id contractId = tmLine.Contract_Line__c;
        Id resId = tmLine.Resource__c;
        Id uomId = tmLine.Unit_of_Measure__c;
        TMLLinesServiceImpl serviceImpl = new TMLLinesServiceImpl();
        serviceImpl.getContractLine(contractId, resId, uomId);
        serviceImpl.getContractLine(tm, tmLine);
        serviceImpl.getSalesLineByLineDesc('I am on the way');
        serviceImpl.assignResourceTypeUOM(tmLine);
        serviceImpl.assignResourceUOM(tmLine);
        serviceImpl.getRateSheetLine('test',tmLine,'a0uVW000005s2l7');
        serviceImpl.setPayRuleLinesByResTypeIdsByPayRuleIdsMap(payRuleIdSet);
        serviceImpl.calcLineTotals(tm,tmLine);
        serviceImpl.getUnitCost('Labor','a0uVW000005s2l7','a0uVW000005s2l7'); 
    }
    
    private static testMethod void Test_TMTriggersMgmt5() {
        Test.startTest(); 
        TM__c TMRecord = [Select Id,Name,Bill_to_Customer__r.Payment_Term__c,Status__c,Emergency_TM__c,From_Sales_Quote__c,Sales_Order__c,Contract__c,Tax_Liable__c,Tax_Area__c,Service_Center__c,Bill_to_Customer__c, Sales_Order__r.Site_Contact_2__c From TM__c Limit 1];
        
        TM__C TMrec = TMRecord;
        TMrec.Status__c='Scheduled';
        Update TMrec;
                
        //test Field TM PDF Send/Save
        //signature request <<
        //Signature__c sig = new Signature__c(Name='customer_signature', Email__c = 'kchen@micro-datanet.com', Related_To_Id__c = TMRecord.Id, Related_To_Object_Name__c = 'TM__c', Print_Name__c = 'c', Accept_Terms_and_Conditions__c = TRUE);
        Signature__c sig = new Signature__c(Name='customer_signature', Signer_Role__c='Customer A', Email__c = 'kchen@micro-datanet.com', TM__c = TMRecord.Id, Print_Name__c = 'c', Accept_Terms_and_Conditions__c = TRUE);
        //signature request >>
        insert sig;
        

        TM__C TMrecSch = TMrec.clone(True,True,False,True);          
        TMrecSch.Status__c='Open';
        //Update TMrec;  
        
        List<TM__c> theTMList = New List<TM__c>();
        theTMList.add(TMrec);               
        
    
        //Update TMconfrec;
        
        Map<Id, TM__c> oldTMMap = new Map<Id, TM__c>();
        oldTMMap.put(TMrecSch.Id,TMrecSch);         

		Map<Id, TM__c> newTMMap = new Map<Id, TM__c>();
        newTMMap.put(TMrec.Id,TMrec); 
        TMTriggersMgmt.updateSalesOrderFromTMMap(theTMList,newTMMap,oldTMMap);
        Test.stopTest();        
    }
     private static testMethod void Test_TMTriggersMgmt7() {
        Test.startTest(); 
        TM__c TMRecord = [Select Id,Name,Bill_to_Customer__r.Payment_Term__c,Status__c,Emergency_TM__c,From_Sales_Quote__c,Sales_Order__c,Contract__c,Tax_Liable__c,Tax_Area__c,Service_Center__c,Bill_to_Customer__c, Sales_Order__r.Site_Contact_2__c From TM__c Limit 1];
 		   Signature__c supervisor = new Signature__c();
        supervisor.TM__c = TMRecord.Id;
        supervisor.Name = 'supervisor';
        supervisor.Print_Name__c = 'SUPER';
        supervisor.Signer_Role__c = 'Supervisor';
        supervisor.Signature_Date__c = System.today();
         insert supervisor;
         TM__C TMrec = TMRecord;
        TMrec.Status__c='Confirmed';
        //Update TMrec;
        
        //test Field TM PDF Send/Save
        //signature request <<
        //Signature__c sig = new Signature__c(Name='customer_signature', Email__c = 'kchen@micro-datanet.com', Related_To_Id__c = TMRecord.Id, Related_To_Object_Name__c = 'TM__c', Print_Name__c = 'c', Accept_Terms_and_Conditions__c = TRUE);
        Signature__c sig = new Signature__c(Name='customer_signature', Signer_Role__c='Customer A', Email__c = 'kchen@micro-datanet.com', TM__c = TMRecord.Id, Print_Name__c = 'c', Accept_Terms_and_Conditions__c = TRUE);
        //signature request >>
        insert sig;
        

        TM__C TMrecSch = TMrec.clone(True,True,False,True);          
        TMrecSch.Status__c='Open';
        //Update TMrec;  
        
        List<TM__c> theTMList = New List<TM__c>();
        theTMList.add(TMrec);               
        
    
        //Update TMconfrec;
        
        Map<Id, TM__c> oldTMMap = new Map<Id, TM__c>();
        oldTMMap.put(TMrecSch.Id,TMrecSch);         

		Map<Id, TM__c> newTMMap = new Map<Id, TM__c>();
        newTMMap.put(TMrec.Id,TMrec); 
        TMTriggersMgmt.updateSalesOrderFromTMMap(theTMList,newTMMap,oldTMMap);
         TMTriggersMgmt.createBillingWorksheetLinesFromTM(new Set<TM__c>(theTMList),theTMList);
         TMTriggersMgmt.updateSignatures(new Set<Id>{TMRecord.Id});
        Test.stopTest();        
    }
    
    private static testMethod void Test_TMTriggersMgmt9() {
        Test.startTest();
        TM__c TMRecord = [Select Id,Name,Bill_to_Customer__r.Payment_Term__c,Status__c,Emergency_TM__c,From_Sales_Quote__c,Sales_Order__c,Contract__c,Tax_Liable__c,Tax_Area__c,Service_Center__c,Bill_to_Customer__c, Sales_Order__r.Site_Contact_2__c From TM__c Limit 1];
        TM_Line__c TMLineEquipmentRecord = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Equipment' Limit 1];
        Contract  ContractRecord = [Select Id From Contract Limit 1];
        Resource_Type__c ResourceTypeRecord = [Select Id,Unit_of_Measure__c From Resource_Type__c Limit 1]; 
        TM_Line__c TMLineLaborRecord = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                    ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                     Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                     Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Labor' Limit 1];
        TM_Line__c TMLineWaterDisposalRecord = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                                    ,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                     Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                     Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c, Resource__r.Resource_Type__c From TM_Line__c Where Category__c =: 'Waste Disposal' Limit 1];
        Sales_Line__c SalesEquipmentLineRecord = [Select Id From Sales_Line__c Where Category__c =: 'Equipment' Limit 1];
        Sales_Line__c SalesWasteLineRecord = [Select Id From Sales_Line__c Where Category__c =: 'Waste Disposal' Limit 1];
        Sales_Line__c SalesLineRecord = [Select Id From Sales_Line__c Where Category__c =: 'Labor' Limit 1];
        Sales_Order__c  SalesOrderRecord = [Select Id From Sales_Order__c Limit 1];
        Contract_Line__c  ContractLineRecord = [Select Id From Contract_Line__c Limit 1];
        
        TM__C TMrec = TMRecord;
       
        try{
             TMrec.Status__c='Closed';
          Update TMrec;   
        }catch(Exception e){
            
        }
         try{
             TMrec.Status__c='Fully Invoiced';
          Update TMrec;   
        }catch(Exception e){
            
        }   
         try{
             TMrec.Status__c = null;
        TMrec.Print_Site_Name__c = true;
        TMrec.Site_Name__c = null;
          Update TMrec;   
        }catch(Exception e){
            
        }   
        TMrec.Id = null;
        TMrec.Service_Center__c = null;
        TMrec.Subsidiary_Company__c = null;
        
        try{
          insert TMrec;   
        }catch(Exception e){
            
        }
        
        Test.stopTest();        
    } 
}