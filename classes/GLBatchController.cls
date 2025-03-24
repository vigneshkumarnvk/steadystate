public with sharing class GLBatchController {
    /*
    private final ApexPages.StandardController theController;
    private String GLBId;
    private GL_Batch__c theGLB;

    public GLBatchController(ApexPages.StandardController controller) {
        String Message;
        theController = controller;
        GLBId = ApexPages.CurrentPage().getParameters().get('id');
        if (!String.IsBlank(GLBId)) {
            selectGLB();
        } else {
            theGLB = new GL_Batch__c();
        }
    }

    private void selectGLB() {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.GL_Batch__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM GL_Batch__c WHERE Id =: GLBId';
        theGLB = Database.query(strQuery);
    }

    public PageReference deleteGLB() {
// Savepoint
        Savepoint sp = database.setSavePoint();
        try {
//Check errors
            List<String> errorList = new List<String>();
            errorList = CompanyMgmt.checkDeleteGLB(theGLB);
            if (errorList.size() > 0) {
                for (Integer i = 0; i < errorList.size(); i++) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, errorList[i]));
                }
                return null;
            } else {
                delete theGLB;
                return new ApexPages.Action('{!List}').invoke();
            }
        } catch (exception e) {
//Rollback
            Database.Rollback(sp);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
            return null;
        }
    }

    public PageReference returnBack() {
        return theController.view();
    }
    */
}