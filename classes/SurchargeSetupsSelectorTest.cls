@IsTest
private class SurchargeSetupsSelectorTest {
    @IsTest
    private static void test(){
        Subsidiary_Company__c subsidiaryCompany = new Subsidiary_Company__c(
                Name = 'ACV',
                Display_Name__c = 'ACV'
        );
        insert subsidiaryCompany;

        Surcharge_Setup__c ss = new Surcharge_Setup__c(
                Name = 'Default',
                Surcharge_Type__c = 'EEC Fee',
                Surcharge_Pct__c = 10,
                Effective_Date__c = Date.today(),
                Subsidiary_Company__c = subsidiaryCompany.Id
        );

        insert  ss;
        SurchargeSetupsSelector.newInstance().selectByTypeAndEffectiveDate(Date.today(), ss.Surcharge_Type__c);
        SurchargeSetupsSelector.newInstance().selectByTypeAndEffectiveDate(Date.newInstance(1990,02,03), ss.Surcharge_Type__c);
        SurchargeSetupsSelector.newInstance().selectByEffectiveDate(Date.today());
        SurchargeSetupsSelector.newInstance().selectByTypeAndEffectiveDate(Date.today(), ss.Surcharge_Type__c, subsidiaryCompany.Id);
        SurchargeSetupsSelector.newInstance().selectByTypeAndEffectiveDate(Date.today(), subsidiaryCompany.Id);
    }
    //test
}