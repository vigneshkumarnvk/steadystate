@isTest
public class ResourceControllerTest {

	public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    @testSetup static void SetupData() {
        //Setup Data
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord; 
        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = : companySetup.Id];
        System.assertEquals(theCSList.size(), 1);
    }

    private static testMethod void Test_ResourceController() {
        Test.startTest();
    	PageReference pref = Page.PersonnelRoster;
        Test.setCurrentPage(pref);
        Resource__c ResourceRecord = TestDataUtil.ResourceRecord;
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.TMRecord);
        ResourceController inst_ROC = new ResourceController(StdCon);
        inst_ROC.filterInput = 'Test filter';
        inst_ROC.selFilterOp = 'Test selFilterOp';
        inst_ROC.calledFrom = 'Test calledFrom';
        inst_ROC.Next();
        inst_ROC.First();
        inst_ROC.Last();
        inst_ROC.Previous();  
        //List<String> emptyList = new List<String>();                         
        inst_ROC.stdCon.getHasPrevious();
        inst_ROC.stdCon.getHasNext();
        inst_ROC.stdCon.getPageNumber();                    
        inst_ROC.pageNumber = 1;  
        String ps = inst_ROC.paginationStat; 
        Boolean hn = inst_ROC.hasNext ; 
        Boolean hp = inst_ROC.hasPrevious;  
        Boolean hr = inst_ROC.hasRecords;                 
        Integer pn = inst_ROC.pageNumber; 
        List<SelectOption> selOpts = inst_ROC.lstFilterOperator;   
        List<SelectOption> selOpts2 = inst_ROC.lstFilterField; 
        List<ResourceController.ResourceWrapper> ResourceWrapList = inst_ROC.ResourceWrapList;              
        ////////////////////////////
        String sd=inst_ROC.sortDirection; 
        String sb=inst_ROC.sortBy; 
        inst_ROC.setOrderBy();    
        List<String> lstFields=inst_ROC.lstFields;  
        inst_ROC.category='Equipment';  
        lstFields=inst_ROC.lstFields;  
        inst_ROC.resourceOff(); 
        inst_ROC.setNextDate(); 
        inst_ROC.setPreviousDate();      
    }

    @isTest
    static void testIsSystemAdmin() {
        // Create a Profile for System Administrator
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        // Create a User with the System Administrator profile
        User sysAdminUser = new User(
            Username = 'sysadminandrewTest123@republicservices.com',
            LastName = 'JONES',
            Email = 'sysadmin@republicservices.com',
            Alias = 'sysadmin',
            ProfileId = sysAdminProfile.Id,
            UserRoleId = null,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert sysAdminUser;

        System.runAs(sysAdminUser) {
            Test.startTest();
            Boolean isAdmin = ResourceController.isSystemAdmin(); 
            Test.stopTest();
            System.assertEquals(true, isAdmin, 'The user should be identified as a System Administrator.');
        }
    }

    @isTest
    public static void testCostPlusMESResource() { 
        // Create a mock ResourceConfig__mdt record
        Test.startTest();
        ResourceConfig__mdt mockConfig = new ResourceConfig__mdt(); 
        mockConfig.DeveloperName ='CostPlusMESResourceId'; 
        mockConfig.Value__c = 'a0rf4000001ZQVmAAO'; 
            // insert mockConfig; 
            // Call the method under test 
        String resourceId = ResourceController.getCostPlusMESResourceId(); 
        Test.stopTest();
     
    }

}
