/**
 * Created by Steven on 5/4/2018.
 */

@IsTest
private class CmpApprovalURLTest {
    @IsTest
    static void testBehavior() {

        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;

        Subsidiary_Company__c subCompany = new Subsidiary_Company__c(Name = 'ACV Test');
        insert subCompany;

        Account ac = new Account( Name = 'MDN',
                        Type = 'Vendor',
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId()
        );
        insert ac;
        System.debug('ac==>'+ac);
        /*
        Service_Center__c sc = new Service_Center__c(
                Name = '01',
                Subsidiary_Company__c = subCompany.Id,
                Code__c = '01'
        );
        insert sc;
        */
        Subsidiary_Vendor__c subVend = new Subsidiary_Vendor__c(Name = 'ACV0001', Subsidiary_Company__c = subCompany.Id, Account__c = ac.Id);
        insert subVend;
        Purchase_Order__c thePO;
        System.debug('ac==>'+ac.RecordTypeId);
        String reordtye=[Select Recordtype.Name from Account where Id=:ac.id].Recordtype.Name;
        System.debug('reordtye==>'+reordtye);
        try{
            thePO = new Purchase_Order__c(
                Name = '01-00000001',
                Buy_from_Vendor__c = ac.Id,
                Pay_to_Vendor__c = ac.Id,
                Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
                OwnerId = UserInfo.getUserId(),
                PO_Requestor__c = UserInfo.getUserId(),
                Order_Type__c = 'Regular',
                Note__c = 'Test PO',
                Coupa_Id__c = '1123'
            );
            insert thePO;
        } catch (Exception e){

        }

        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval');
        req1.setObjectId(thePO.Id);
        req1.setProcessDefinitionNameOrId('SC15_REG');
        req1.setSkipEntryCriteria(true);
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});

        Approval.ProcessResult result = Approval.process(req1);

        System.assert(result.isSuccess());

        System.assertEquals(
                'Pending', result.getInstanceStatus(),
                'Instance Status' + result.getInstanceStatus());

        List<Id> newWorkItemIds = result.getNewWorkitemIds();

        CmpApprovalURL appURL = new CmpApprovalURL();
        appURL.recId = thePO.Id;

        String hostStr = System.URL.getSalesforceBaseUrl().getHost();
        String url = '';
        List<String> strList = hostStr.split('\\.');
        if(strList.size() > 0) {
            String customDomain = hostStr.split('\\.')[0];
            if (customDomain.endsWith('--c')) {
                customDomain = customDomain.removeEnd('--c');
            }
            url = 'https://' + customDomain + '.lightning.force.com/lightning/r/ProcessInstanceWorkitem/' + newWorkItemIds[0] + '/view';
        }

        System.assertEquals(appURL.urlStr, url);

    }
}