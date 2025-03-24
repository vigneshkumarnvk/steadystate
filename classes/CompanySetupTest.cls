@IsTest
private class CompanySetupTest {

    @IsTest
    private static void testBehavior(){
        Company_Setup__c companySetup = new Company_Setup__c(Name='DEFAULT');
        insert companySetup;

        //Company_Setup__c companySetup2 = new Company_Setup__c(Name='DEFAULT');
        try{
            companySetup.Allow_Posting_From__c = Date.today();
            companySetup.Allow_Posting_To__c = Date.today().addDays(-1);
            update companySetup;
            //insert companySetup2;
            throw new myException('Excepting Allow Posting From cannot be later than Allow Posting To error from trigger but was not!');
        } catch (Exception e){
            Boolean expectedResult = e.getMessage().contains('Allow Posting From cannot be later than Allow Posting To.')?true:false;
            System.assertEquals(expectedResult, true);
        }

        CompanyMgmt.allowToDeleteData = false;
        try{
            delete companySetup;

            throw new myException('Excepting You are not allowed to delete Company Setup record! error message but was not!');
        } catch (Exception e){
            Boolean expectedResult = e.getMessage().contains('You are not allowed to delete Company Setup record!')?true:false;
            System.assertEquals(expectedResult, true);
        }
    }

        
    @isTest
    private static void testGetSandboxEmailRecipients(){
        CompanySettingUtil.getSandboxEmailRecipients();
    }
}