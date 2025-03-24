@IsTest
private class ServiceCentersSelectorTest {

    @IsTest
    private static void test(){

        Numbering_Series__c theNS;
        List<Numbering_Series__c> theNSList = new List<Numbering_Series__c>();

        theNS = new Numbering_Series__c();
        theNS.Name = 'JOB01';
        theNS.Prefix__c = 'NJ';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);
        theNS = new Numbering_Series__c();

        Subsidiary_Company__c subC = new Subsidiary_Company__c(
                Name = '1-REPUBLIC SERVICES',
                Display_Name__c = 'SO'
        );
        insert subC;

        Service_Center__c sc = new Service_Center__c(
                Name = '01',
                Description__c = 'SC01 Elizabeth, NJ Ops',
                Subsidiary_Company__c = subC.Id,
                TM_No_Series__c = theNSList[0].Id,
                //Sales_Order_No_Series__c = theNumberingSeries.Id,
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
        insert sc;

        ServiceCentersSelector selector = new ServiceCentersSelector();
        selector.selectById(new Set<Id>{sc.Id});
        selector.selectAll();
        selector.selectByName(sc.name);
    }
}