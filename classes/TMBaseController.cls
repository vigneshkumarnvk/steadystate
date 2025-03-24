public with sharing class TMBaseController {
    @AuraEnabled
    public static String getTMLines(Id tmId, String category) {
        try {
            //ticket 19130 05.03.23 <<
            //List<TM_Job_Task__c> jobTasks = [SELECT Id, Name, Line_No__c, Task_No__c FROM TM_Job_Task__c WHERE TM__c = :tmId ORDER BY Line_No__c];
            List<TM_Job_Task__c> jobTasks = [SELECT Id, Name, Line_No__c, Task_No__c, Sales_Order_Job_Task__c FROM TM_Job_Task__c WHERE TM__c = :tmId ORDER BY Line_No__c];
            //ticket 19130 05.03.23 >>

            List<String> filters = new List<String>();
            filters.add('TM__c = :tmId');
            if (category != null) {
                filters.add('Category__c = :category');
            }

            String queryString = 'SELECT ' + String.join(getTMLineFields(), ',');
            queryString += ' FROM TM_Line__c';
            queryString += ' WHERE ' + String.join(filters, ' AND ');
            queryString += ' ORDER BY TM_Job_Task__r.Line_No__c, Resource_Type__r.Name, Resource__r.Name, Line_No__c';
            List<TM_Line__c> tmLines = (List<TM_Line__c>)Database.query(queryString);

            ACVTMWrapper tmWrapper = new ACVTMWrapper(null, jobTasks, tmLines);

            //get next tm line no
            Integer nextTMLineNo = 0;
            List<TM_Line__c> tmLines2 = [SELECT Line_No__c FROM TM_Line__c WHERE TM__c = :tmId ORDER BY Line_No__c DESC LIMIT 1];
            if (tmLines2.size() > 0) {
                nextTMLineNo = tmLines2[0].Line_No__c.intValue();
            }
            nextTMLineNo++;

            for (ACVTMJobTaskWrapper jobTaskWrapper : tmWrapper.JobTaskWrappers) {
                jobTaskWrapper.NextTMLineNo = nextTMLineNo;
            }

            return JSON.serialize(tmWrapper.JobTaskWrappers);
        }
        catch(exception ex) {
            throw ex;
        }
    }

    //ticket 19130 << move to MobileTMController
    /*
    //!!!this save function does not handle deleted lines. This function is called by the signature page to save new lines added from the wizard.
    public static void SaveTMAndLines(String JSONTM, String JSONJobTaskWrappers) {
        Savepoint sp = Database.setSavepoint();
        try {
            TM__c tm = (TM__c)JSON.deserialize(JSONTM, TM__c.class);
            List<ACVTMJobTaskWrapper> jobTaskWrappers = (List<ACVTMJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVTMJobTaskWrapper>.class);
            upsert tm;

            List<TM_Line__c> tmLines = initTMLinesFromWrapper(tm, jobTaskWrappers);
            if (tmLines.size() > 0) {
                upsert tmLines;
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }
    */
    //ticket 19130 >>

    public static List<TM_Line__c> initTMLinesFromWrapper(TM__c tm, List<ACVTMJobTaskWrapper> jobTaskWrappers) {
        Company_Setup__c companySetup = CompanyMgmt.getCompanySetup();

        Integer nextTMLineNo = 0;
        for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (Integer i = 0; i < jobTaskWrapper.TMLines.size(); i++) {
                TM_Line__c tmLine = jobTaskWrapper.TMLines[i];

                //fix subcontract line bug <<
                if (tmLine.Category__c == 'Subcontractors' && tmLine.Resource__c == null) {
                    tmLine.Resource__c = companySetup.Default_Subcontractor_Resource__c;
                }
                //fix subcontract line bug >>

                //remove empty lines
                if (tmLine.Resource_Type__c == null && tmLine.Resource__c == null && tmLine.Description__c == null) {
                    jobTaskWrapper.TMLines.remove(i);
                    i--;
                }
                else {
                    if (tmLine.Line_No__c > nextTMLineNo) {
                        nextTMLineNo = tmLine.Line_No__c.intValue();
                    }
                }
            }
        }

        if (tm.Id != null) {
            List<TM_Line__c> tmLines = [SELECT Line_No__c FROM TM_Line__c WHERE TM__c = :tm.Id ORDER BY Line_No__c DESC];
            if (tmLines.size() > 0) {
                nextTMLineNo = tmLines[0].Line_No__c.intValue() ;
            }
        }
        nextTMLineNo++;

        for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                if (tmLine.Id == null) {
                    tmLine.TM__c = tm.Id;
                }
                if (tmLine.TM_Job_Task__c == null) {
                    tmLine.TM_Job_Task__c = jobTaskWrapper.JobTask.Id;
                    //ticket 19130 05.03.23 <<
                    tmLine.TM_Job_Task__r = jobTaskWrapper.JobTask;
                    //ticket 19130 05.03.23 >>
                }
                if (tmLine.Line_No__c == null || tmLine.Line_No__c == 0) {
                    nextTMLineNo++;
                    tmLine.Line_No__c = nextTMLineNo;
                }
            }
        }

        List<TM_Line__c> tmLines = new List<TM_Line__c>();
        for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            tmLines.addAll(jobTaskWrapper.TMLines);
        }
        return tmLines;
    }

    public static List<String> getTMLineFields() {
        List<String> fields = new List<String>();
        fields.add('Id');
        fields.add('Name');
        fields.add('Line_No__c');
        fields.add('Category__c');
        fields.add('Resource_Type__c');
        fields.add('Resource_Type__r.Name');
        fields.add('Resource_Type__r.Description__c');
        fields.add('Resource_Type__r.Fleet_No_Required__c');
        fields.add('Resource_Type__r.Rental_Resource_Type__c');
        fields.add('Resource__c');
        fields.add('Resource__r.Name');
        fields.add('Resource__r.Description__c');
        fields.add('Resource_Name__c');
        fields.add('Service_Center__c');
        fields.add('Service_Center__r.Name');
        fields.add('Unit_of_Measure__c');
        fields.add('Unit_of_Measure__r.Name');
        fields.add('Unit_of_Measure__r.Hours_UOM__c');
        fields.add('Description__c');
        fields.add('Job_Start_Time__c');
        fields.add('Job_End_Time__c');
        fields.add('Site_Start_Time__c');
        fields.add('Site_End_Time__c');
        fields.add('Lunch_Start_Time__c');
        fields.add('Lunch_End_Time__c');
        fields.add('Total_Job_Hours__c');
        fields.add('Total_Site_Hours__c');
        fields.add('Quantity__c');
        fields.add('Facility__c');
        fields.add('Facility__r.Name');
        fields.add('BOL_Manifest__c');
        fields.add('Linked_Line__c');
        fields.add('Linked_Line__r.Line_No__c');
        fields.add('Linked_Line__r.Resource_Name__c');
        fields.add('TM__c');
        fields.add('TM__r.Name');
        fields.add('TM_Job_Task__c');
        fields.add('TM_Job_Task__r.Name');
        fields.add('TM_Job_Task__r.Line_No__c');
        //ticket 19130 05.03.23 <<
        fields.add('TM_Job_Task__r.Sales_Order_Job_Task__c');
        //ticket 19130 05.03.23 >>
        //ticket 19586 <<
        fields.add('System_Calculated_Line__c');
        //ticket 19586 >>
        //ticket 19725 <<
        fields.add('LastModifiedDate');
        //ticket 19725 >>
        //ticket 19130 <<
        fields.add('Wizard_Question_Answered__c');
        fields.add('Is_Child_Resource__c');
        fields.add('Approval_Id__c');
        //US129137
        fields.add('EQAI_Bill_Unit_Code__c');
        //ticket 19130 >>
        return fields;
    }
}