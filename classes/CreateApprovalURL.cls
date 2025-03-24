public class CreateApprovalURL {
    public static String generateApprovalURL(String recordId){
        String url = '';

        List <ProcessInstanceWorkitem> workItemList = [SELECT Id From ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: recordId ORDER BY CreatedDate DESC];

        if(workItemList.size() > 0){
            String hostStr = System.URL.getSalesforceBaseUrl().getHost();
            List<String> strList = hostStr.split('\\.');
            if(strList.size() > 0){
                String customDomain = hostStr.split('\\.')[0];
                if(customDomain.endsWith('--c')){
                    customDomain = customDomain.removeEnd('--c');
                }
                url = 'https://' + customDomain + '.lightning.force.com/lightning/r/ProcessInstanceWorkitem/' + workItemList[0].Id + '/view';
            }
        }

        return url;
    }
}