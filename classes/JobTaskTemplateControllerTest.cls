@isTest
private class JobTaskTemplateControllerTest {
    private static testMethod void test() {
        NewTestData.createTestData();
        Test.startTest();

        Job_Task_Template__c jobTaskTemplate = NewTestData.mapJobTaskTemplateWrappersByName.get('Field Services').JobTaskTemplate;
        String JSONJobTaskTemplateWrapper = JobTaskTemplateController.getJobTaskTemplate(jobTaskTemplate.Id);
        JobTaskTemplateWrapper jobTaskTemplateWrapper = (JobTaskTemplateWrapper)JSON.deserialize(JSONJobTaskTemplateWrapper, JobTaskTemplateWrapper.class);

        JobTaskTemplateController.getJobTaskTemplateLines(jobTaskTemplate.Id);

        //ticket 19130 <<
        /*
        for (Job_Task_Template_Line__c templateLine : jobTaskTemplateWrapper.JobTaskTemplateLines) {
            if (templateLine.Category__c == 'Labor') {
                String JSONChildLines = JobTaskTemplateController.calculatePresumptiveChildLines(JSON.serialize(templateLine), 100);
                break;
            }
        }
        */
        //ticket 19130 >>

        JobTaskTemplateController.saveJobTaskTemplate(JSON.serialize(jobTaskTemplateWrapper.JobTaskTemplate), JSON.serialize(jobTaskTemplateWrapper.JobTaskTemplateLines));

        Test.stopTest();
    }
}