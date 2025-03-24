public with sharing class CompanyTriggerMgmt {
    // #GFERP-1035
    public static void CSInsertUpdate(List<Company_Setup__c> CSList, Boolean isInsert, Map<Id, Company_Setup__c> oldCSMap) {
        List<Company_Setup__c> theCSList = [SELECT Id FROM Company_Setup__c Limit 1];

        /* Handle this in field custom validation
        if (isInsert) {
            for (Company_Setup__c theCS : CSList) {
                if (theCSList != null && theCSList.size() > 0 && !Test.isRunningTest())
                    theCS.addError('Company Setup record already exist!');
            }
        }
        */

        if (!isInsert) {
            for (Company_Setup__c theCS : CSList) {
                if (theCS.Allow_Posting_From__c != null && theCS.Allow_Posting_From__c != null) {
                    if (theCS.Allow_Posting_From__c > theCS.Allow_Posting_To__c) {
                        theCS.Allow_Posting_From__c.adderror('Allow Posting From cannot be later than Allow Posting To.');
                    }
                }
            }
        }
    }

    public static void CSDelete(List<Company_Setup__c> CSList) {
        if (CompanyMgmt.allowToDeleteData != true) {
            for (Company_Setup__c theCS : CSList) {
                theCS.addError('You are not allowed to delete Company Setup record!');
            }
        }
    }

    public static void GLB_D(List<GL_Batch__c> theGLBList) {
        for (GL_Batch__c theGLB : theGLBList) {
            if (theGLB.No_of_Lines__c != 0) {
                theGLB.addError('You cannot delete GL Batch because it is used on GL Entry!');
            }
            if (theGLB.Sync_d__c == true) {
                theGLB.addError('You cannot delete GL Batch because it is Integrated!');
            }
            if (theGLB.Closed__c == true) {
                theGLB.addError('You cannot delete GL Batch because it is Closed!');
            }
        }
    }

    public static void GL_I_U_Trigger(GL_Entry__c[] GLList) {
        if (CompanyMgmt.systemCall != true) {
            for (GL_Entry__c theGL : GLList) {
                theGL.addError('You are not allowed to modify General Ledger Entry.');
            }
        }
    }

    public static void GL_D_Trigger(GL_Entry__c[] GLList) {
        if (CompanyMgmt.allowToDeleteData != true && CompanyMgmt.systemCall != true) {
            for (GL_Entry__c theGL : GLList) {
                theGL.addError('You are not allowed to delete General Ledger Entry.');
            }
        }
    }

    public static void GLA_D(List<GL_Account__c> theGLAList) {
        for (GL_Account__c theGLA : theGLAList) {
            if (theGLA.No_of_Lines__c != 0) {
                theGLA.addError('You cannot delete GL Account because it is used on GL Entry!');
            }
        }
    }
}