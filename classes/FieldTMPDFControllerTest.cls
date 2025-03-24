@isTest
private class FieldTMPDFControllerTest {
    private static testMethod void test() {
        NewTestData.createTestData();
        Test.startTest();

        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);

        List<Signature__c> signatures = new List<Signature__c>();
        Signature__c supervisor = new Signature__c();
        supervisor.TM__c = tm.Id;
        supervisor.Name = 'supervisor';
        supervisor.Print_Name__c = 'SUPER';
        supervisor.Signer_Role__c = 'Supervisor';
        supervisor.Signature_Date__c = System.today();
        signatures.add(supervisor);

        Signature__c customer = new Signature__c();
        customer.TM__c = tm.Id;
        customer.Name = 'Customer A';
        customer.Signer_Role__c = 'Customer A';
        customer.Print_Name__c = 'Customer';
        customer.Accept_Terms_and_Conditions__c = true;
        customer.Signature_Date__c = System.today();
        signatures.add(customer);

        Signature__c customer2 = new Signature__c();
        customer2.TM__c = tm.Id;
        customer2.Name = 'Customer B';
        customer2.Signer_Role__c = 'Customer B';
        customer2.Print_Name__c = 'Customer';
        customer2.Accept_Terms_and_Conditions__c = true;
        customer2.Signature_Date__c = System.today();
        signatures.add(customer2);
        insert signatures;

        List<Attachment> attachments = new List<Attachment>();
        Attachment attachment1 = new Attachment();
        attachment1.ParentId = supervisor.Id;
        attachment1.Name = 'signature';
        attachment1.Body = Blob.valueOf('123');
        attachment1.ContentType = 'image/png';
        attachment1.IsPrivate = false;
        attachments.add(attachment1);

        Attachment attachment2 = new Attachment();
        attachment2.ParentId = customer.Id;
        attachment2.Name = 'signature';
        attachment2.Body = Blob.valueOf('123');
        attachment2.ContentType = 'image/png';
        attachment2.IsPrivate = false;
        attachments.add(attachment2);

        Attachment attachment3 = new Attachment();
        attachment3.ParentId = customer2.Id;
        attachment3.Name = 'signature';
        attachment3.Body = Blob.valueOf('123');
        attachment3.ContentType = 'image/png';
        attachment3.IsPrivate = false;
        attachments.add(attachment3);

        insert attachments;


        PageReference pdfPage = Page.NewFieldTMPDF;
        Test.setCurrentPage(pdfPage);
        ApexPages.currentPage().getParameters().put('id', tm.Id);
        FieldTMPDFController fieldTMPDFController = new FieldTMPDFController();

        Test.stopTest();
    }
}