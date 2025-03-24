public with sharing class AddScheduleTMConfirmationController {
    List<String> lstselectedTMIds;
    public List<TM__c> theTMList { get; set; }
    public String scheduledDateValue { get; set; }
    public String ClosingNote {get; set;} //Ticket# 13461
    public String SetStatusTo {get; set;} //Ticket# 13461
    public String ActionType {get; set;} //Ticket# 13619

    public AddScheduleTMConfirmationController() {
        String selectedTMId = ApexPages.currentPage().getParameters().get('selectedTMId');
        //system.debug('selectedTMId***' + selectedTMId);
        SetStatusTo = ApexPages.currentPage().getParameters().get('setStatus');
        ActionType = ApexPages.currentPage().getParameters().get('actionType');
        //System.debug('setStatusTo=== ' + SetStatusTo);
        lstselectedTMIds = new List<String>();
        lstselectedTMIds = selectedTMId.split(',');
        //system.debug('lstselectedTMIds***' + lstselectedTMIds);

        selectTMList();
    }

    /*
     *  Ticket#21357 add Contact__r.Blocked__c and Site_Contact_2__r.Blocked__c into query.
     */
    private void selectTMList() {
        theTMList = new List<TM__c>();

        Map<String, Schema.SObjectField> fields = Schema.SObjectType.TM__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' ,Sales_Order__r.Name, Bill_to_Customer__r.Name,' +
                'Service_Center__r.Blocked__c, Service_Center__r.Name, Contact__r.Blocked__c, Site_Contact_2__r.Blocked__c';
        strQuery += ' FROM TM__c ';
        strQuery += '  WHERE Id IN: lstselectedTMIds';
        theTMList = Database.query(strQuery);
    }

    public PageReference returnToOpenTMs() {
        PageReference redirectPage = new PageReference('/apex/ProcessTM?flterByStatus=Open');
        redirectPage.setRedirect(true);
        return redirectPage;
    }

    public PageReference changeStatusToSchedule() {
        if (String.isEmpty(scheduledDateValue)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Schedule Date cannot be left blank.'));
            return null;
        } else {

            for(TM__c theTM : theTMList) {
                theTM.Scheduled_Date__c = Date.parse(scheduledDateValue);
                theTM.Status__c = 'Scheduled';
            }
        }

        try {
            update theTMList;
        } catch (Exception e) {
            System.debug('Error: List of TM not updated due to-->' + e);
            return null;
        }

        PageReference redirectPage = new PageReference('/apex/ProcessTM?flterByStatus=Open');
        redirectPage.setRedirect(true);
        return redirectPage;
    }

    /*
        Ticket#13461
     */
    public PageReference manuallyCloseTM(){
        if(String.isNotBlank(ClosingNote.trim()) == true){
            for(TM__c theTM:theTMList){
                theTM.Note__c = ClosingNote;
                theTM.Manual_Closed_By__c = UserInfo.getUserId();
                theTM.Manual_Closed_At__c = Datetime.now();
                theTM.Status__c = 'Closed';
                theTM.Ready_to_Close__c = true;
            }

            Savepoint sp = Database.setSavepoint();

            try{
                CompanyMgmt.systemCall = true;
                update theTMList;
                CompanyMgmt.systemCall = false;

                PageReference redirectPage = new PageReference('/apex/ProcessTM?filterByStatus=Open');
                redirectPage.setRedirect(true);
                return redirectPage;
            } catch (Exception e){
                Database.rollback(sp);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getStackTraceString()));
                return null;
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Closing Note field must not be blank!'));
            return null;
        }
    }

    /*
        Ticket#13461
     */
    public PageReference openTM(){
        for(TM__c theTM:theTMList){
            theTM.Note__c = null;
            theTM.Manual_Closed_By__c = null;
            theTM.Manual_Closed_At__c = null;
            theTM.Status__c = 'Ready to Bill';
            theTM.Ready_to_Close__c = false;
        }

        Savepoint sp = Database.setSavepoint();

        try{
            update theTMList;

            PageReference redirectPage = new PageReference('/apex/ProcessTM?filterByStatus=Ready to Bill');
            redirectPage.setRedirect(true);
            return redirectPage;
        } catch (Exception e){
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getStackTraceString()));
            return null;
        }
    }

    /*
    Ticket#13619
     */
    //job task <<
    /*
    public PageReference cloneAndScheduleTM(){
        if (String.isEmpty(scheduledDateValue)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Schedule Date cannot be left blank.'));
            return null;
        } else {
            //Prepare TM Id set for bulk query
            Set<Id> tmIdSet = new Set<Id>();
            for(TM__c theTM:theTMList){
                tmIdSet.add(theTM.Id);
            }

            List<TM_Line__c> existTMLineLst = TMLinesSelector.newInstance().selectByTmId(tmIdSet);

            //Create map for existing T&M with their lines
            Map<Id, List<TM_Line__c>> tmAndTMLineMap = new Map<Id, List<TM_Line__c>>();
            for(TM_Line__c theTML : existTMLineLst){
                if(tmAndTMLineMap.containsKey(theTML.TM__c)){
                    List<TM_Line__c> tmLineLst = tmAndTMLineMap.get(theTML.TM__c);
                    tmLineLst.add(theTML);
                    tmAndTMLineMap.put(theTML.TM__c, tmLineLst);
                } else {
                    tmAndTMLineMap.put(theTML.TM__c, new List<TM_Line__c>{theTML});
                }
            }

            //Clone and schedule T&M
            List<TM__c> newTMLst = new List<TM__c>();
            List<TM_Line__c> newTMLLst = new List<TM_Line__c>();

            //Set Savepoint
            Savepoint sp = Database.setSavepoint();
            try{
                for(TM__c theTM : theTMList) {
                    if(theTM.Service_Center__r.Blocked__c == true){
                        throw new DataException('Service center ' + theTM.Service_Center__r.Name + ' is deactivated!');
                    }
                    TM__c newTM = theTM.clone(false, true, false, false);
                    newTM.Name = null;
                    String[] dateArray = new String[3];
                    dateArray = scheduledDateValue.split('/', 3);
                    String scheduleDateStr = dateArray[2] + '-' + dateArray[0] + '-' + dateArray[1];
                    newTM.Scheduled_Date__c = Date.valueOf(scheduleDateStr);
                    newTM.Status__c = 'Scheduled';
                    newTM.Ready_to_Close__c = false;
                    newTM.Sales_Invoice__c = null;
                    newTM.Confirmed_Date__c = null;
                    newTM.Confirmed_By__c = null;
                    newTM.Mobile_TM__c = false;
                    newTM.Job_Complete__c = false;
                    newTM.Old_Id__c = theTM.Id;

                    //field TM PDF <<
                    newTM.Mobile_TM__c = false;
                    newTM.Accept_Terms_And_Conditions__c = false;
                    newTM.Field_TM_PDF_Sent__c = false;
                    newTM.Field_TM_PDF_Saved__c = false;
                    newTM.Customer_Comments__c = null;
                    newTM.Customer_Not_Available__c = false;
                    //field TM PDF >>

                    newTMLst.add(newTM);
                }

                if(newTMLst.size() > 0){
                    insert newTMLst;
                }

                for(TM__c newTM : newTMLst){
                    if(tmAndTMLineMap.containsKey(newTM.Old_Id__c)){
                        List<TM_Line__c> tmLineLst = tmAndTMLineMap.get(newTM.Old_Id__c);
                        for(TM_Line__c tmlLine : tmLineLst){
                            TM_Line__c newTMLine = tmlLine.clone(false,true,false,false);
                            newTMLine.TM__c = newTM.Id;
                            newTMLine.Category__c = tmlLine.Category__c;
                            newTMLine.Tax_Group__c = tmlLine.Tax_Group__c;
                            newTMLine.Resource_Type__c = tmlLine.Resource_Type__c;
                            newTMLine.Resource__c = tmlLine.Resource__c;
                            newTMLine.Resource_Name__c = tmlLine.Resource_Name__c;
                            newTMLine.Description__c = tmlLine.Description__c;
                            newTMLine.Service_Center__c = tmlLine.Service_Center__c;
                            newTMLine.Unit_of_Measure__c = tmlLine.Unit_of_Measure__c;
                            newTMLine.Line_No__c = tmlLine.Line_No__c;
                            newTMLine.Contract_Line__c = tmlLine.Contract_Line__c;
                            if(String.isNotBlank(tmlLine.Contract_Line__c)){
                                if(TMLLinesService.isCalcBaseOnResType(tmlLine.Category__c) == true) {
                                    if(tmlLine.Resource_Type__r.Name != tmlLine.Contract_Line__r.Resource_Type__r.Name){
                                        newTMLine.Contract_Line__c = null;
                                    }
                                } else {
                                    if(tmlLine.Resource__r.Name != tmlLine.Contract_Line__r.Resource__r.Name){
                                        newTMLine.Contract_Line__c = null;
                                    }
                                }
                            }
                            if(tmlLine.Category__c != 'Labor' && tmlLine.Category__c != 'Equipment'){
                                newTMLine.Quantity__c = tmlLine.Quantity__c;
                            } else {
                                newTMLine.Quantity__c = 0;
                                newTMLine.Regular_Hours__c = null;
                                newTMLine.Overtime_Hours__c = null;
                                newTMLine.Premium_Hours__c = null;
                                newTMLine.Cost_Qty__c = 0;
                            }
                            newTMLine.Job_Start_Time__c = null;
                            newTMLine.Job_End_Time__c = null;
                            newTMLine.Site_Start_Time__c = null;
                            newTMLine.Site_End_Time__c = null;
                            newTMLine.Total_Job_Hours__c = 0;
                            newTMLine.Total_Site_Hours__c = 0;
                            newTMLine.Billing_End_Time__c = null;
                            newTMLine.Billing_Start_Time__c = null;
                            newTMLine.Hour__c = 0;
                            newTMLine.Lunch_End_Time__c = null;
                            newTMLine.Lunch_Start_Time__c = null;
                            newTMLine.Lunch__c = null;
                            newTMLine.Sales_Line__c = tmlLine.Sales_Line__c;
                            newTMLine.Regular_Rate__c = tmlLine.Regular_Rate__c;
                            newTMLine.Premium_Rate__c = tmlLine.Premium_Rate__c;
                            newTMLine.Overtime_Rate__c = tmlLine.Overtime_Rate__c;
                            newTMLine.Markup_Option__c = tmlLine.Markup_Option__c;
                            newTMLine.Markup__c = tmlLine.Markup__c;
                            newTMLine.Invoiced__c = false;
                            if (newTMLine.Category__c == 'Labor'){
                                newTMLine.Unit_Price__c = tmlLine.Regular_Rate__c;
                            } else {
                                newTMLine.Unit_Price__c = tmlLine.Unit_Price__c;
                            }
                            newTMLLst.add(newTMLine);
                        }
                    }
                }

                if(newTMLLst.size() > 0){
                    //Insert new TM Lines
                    insert newTMLLst;
                }
            } catch (Exception e){
                //rollback if error
                Database.rollback(sp);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() + e.getStackTraceString()));
                return null;
            }

            Map<TM__c, List<TM_Line__c>> tmLinesByTms = new Map<TM__c, List<TM_Line__c>>();
            Map<Id, TM__c> tmsByIds = new Map<Id, TM__c>();
            for(TM__c tm : newTMLst){
                tmLinesByTms.put(tm, new List<TM_Line__c>{});
                tmsByIds.put(tm.Id, tm);
            }

            for(TM_Line__c tmLine : newTMLLst){
                List<TM_Line__c> tmLines = new List<TM_Line__c>();
                if(tmsByIds.containsKey(tmLine.TM__c)){
                    TM__c tm = tmsByIds.get(tmLine.TM__c);
                    if(tmLinesByTms.containsKey(tm)) {
                        tmLines = tmLinesByTms.get(tm);
                    }
                    tmLines.add(tmLine);
                    tmLinesByTms.put(tm, tmLines);
                }
            }

            TMLLinesService.populateLinesInfo(tmLinesByTms);

            //Redirect to daily roster page
            PageReference redirectPage = new PageReference('/apex/DailyRoster?scheduledDate=' + scheduledDateValue);
            redirectPage.setRedirect(true);
            return redirectPage;
        }
    }
    */
    /*
    public PageReference cloneAndScheduleTM(){
        if (String.isEmpty(scheduledDateValue)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Schedule Date cannot be left blank.'));
            return null;
        }

        Savepoint sp = Database.setSavepoint();
        try {
            //Prepare TM Id set for bulk query
            Set<Id> tmIds = new Set<Id>();
            Set<Id> salesOrderIds = new Set<Id>(); //Ticket#19849
            for (TM__c tm : theTMList) {
                tmIds.add(tm.Id);
                salesOrderIds.add(tm.Sales_Order__c);
            }

            //Ticket#19849 >>
            List<Sales_Order__c> salesOrders = [SELECT Id, Name, Document_Status__c FROM Sales_Order__c WHERE Id IN :salesOrderIds AND Document_Status__c = 'Closed'];
            if(salesOrders.size() > 0){
                String errorMsg = 'T&M cannot be cloned because linked sales orders is closed. Sales Order No.: ';
                for(Sales_Order__c salesOrder : salesOrders){
                    errorMsg = errorMsg + salesOrder.Name + ', ';
                }
                errorMsg = errorMsg.removeEnd(', ');
                throw new DataException(errorMsg);
            }
            //Ticket#19849 >>

            //Clone and schedule T&M
            Map<Id, TM__c> mapNewTMsByOldTMId = new Map<Id, TM__c>();
            for (TM__c tm : theTMList) {
                TM__c newTM = tm.clone(false, true, false, false);
                newTM.Name = null;
                String[] dateArray = new String[3];
                dateArray = scheduledDateValue.split('/', 3);
                String scheduleDateStr = dateArray[2] + '-' + dateArray[0] + '-' + dateArray[1];
                newTM.Scheduled_Date__c = Date.valueOf(scheduleDateStr);
                newTM.Status__c = 'Scheduled';
                newTM.Ready_to_Close__c = false;
                newTM.Sales_Invoice__c = null;
                newTM.Confirmed_Date__c = null;
                newTM.Confirmed_by__c = null;
                newTM.Mobile_TM__c = false;
                newTM.Job_Complete__c = false;
                newTM.Mobile_First_Save_At__c = null;
                newTM.Old_Id__c = tm.Id;

                //field TM PDF <<
                newTM.Mobile_TM__c = false;
                newTM.Accept_Terms_and_Conditions__c = false;
                newTM.Field_TM_PDF_Sent__c = false;
                newTM.Field_TM_PDF_Saved__c = false;
                newTM.Customer_Comments__c = null;
                newTM.Customer_Not_Available__c = false;
                //field TM PDF >>

                mapNewTMsByOldTMId.put(tm.Id, newTM);
            }
            //CompanyMgmt.byPassTrigger = true;
            insert mapNewTMsByOldTMId.values();
            //CompanyMgmt.byPassTrigger = false;

            //insert job task
            List<TM_Job_Task__c> jobTasks = new List<TM_Job_Task__c>();
            Map<Id, Map<Integer, TM_Job_Task__c>> mapNewJobTasksByLineNoByOldTMId = new Map<Id, Map<Integer, TM_Job_Task__c>>();
            for (TM_Job_Task__c jobTask : TMJobTasksSelector.newInstance().selectByTMId(tmIds)) {
                TM__c newTM = mapNewTMsByOldTMId.get(jobTask.TM__c);
                TM_Job_Task__c newJobTask = jobTask.clone(false, true, false, false);
                newJobTask.TM__c = newTM.Id;
                newJobTask.TM__r = new TM__c(Id = newTM.Id);
                jobTasks.add(newJobTask);

                Map<Integer, TM_Job_Task__c> mapNewJobTasksByLineNo;
                if (mapNewJobTasksByLineNoByOldTMId.containsKey(jobTask.TM__c)) {
                    mapNewJobTasksByLineNo = mapNewJobTasksByLineNoByOldTMId.get(jobTask.TM__c);
                }
                else {
                    mapNewJobTasksByLineNo = new Map<Integer, TM_Job_Task__c>();
                    mapNewJobTasksByLineNoByOldTMId.put(jobTask.TM__c, mapNewJobTasksByLineNo);
                }
                mapNewJobTasksByLineNo.put(jobTask.Line_No__c.intValue(), newJobTask);
            }
            //CompanyMgmt.byPassTrigger = true;
            insert jobTasks;
            //CompanyMgmt.byPassTrigger = false;

            //tm lines
            Map<Id, Map<Integer, TM_Line__c>> mapNewTMLinesByLineNoByTMId = new Map<Id, Map<Integer, TM_Line__c>>();
            //ticket 19130 <<
            Map<Id, Map<Integer, TM_Line__c>> mapOldTMLinesByLineNoByNewTMId = new Map<Id, Map<Integer, TM_Line__c>>();
            List<TM_Line__c> newTMLines = new List<TM_Line__c>();
            //ticket 19130 >>

            //duplicated safety plan lines issue <<
            //for (TM_Line__c tmLine : TMLinesSelector.newInstance().selectByTmId(tmIds, null)) {
            List<String> filters = new List<String>();
            filters.add('System_Calculated_Line__c<>TRUE');
            for (TM_Line__c tmLine : TMLinesSelector.newInstance().selectByTmId(tmIds, filters)) {
            //duplicated safety plan lines issue >>

                TM__c newTM = mapNewTMsByOldTMId.get(tmLine.TM__c);
                TM_Job_Task__c newJobTask = mapNewJobTasksByLineNoByOldTMId.get(tmLine.TM__c).get(tmLine.TM_Job_Task__r.Line_No__c.intValue());

                Map<Integer, TM_Line__c> mapNewTMLinesByLineNo;
                if (mapNewTMLinesByLineNoByTMId.containsKey(newTM.Id)) {
                    mapNewTMLinesByLineNo = mapNewTMLinesByLineNoByTMId.get(newTM.Id);
                }
                else {
                    mapNewTMLinesByLineNo = new Map<Integer, TM_Line__c>();
                    mapNewTMLinesByLineNoByTMId.put(newTM.Id, mapNewTMLinesByLineNo);
                }

                //ticket 19130 <<
                Map<Integer, TM_Line__c> mapOldTMLinesByLineNo;
                if (mapOldTMLinesByLineNoByNewTMId.containsKey(newTM.Id)) {
                    mapOldTMLinesByLineNo = mapOldTMLinesByLineNoByNewTMId.get(newTM.Id);
                }
                else {
                    mapOldTMLinesByLineNo = new Map<Integer, TM_Line__c>();
                    mapOldTMLinesByLineNoByNewTMId.put(newTM.Id, mapOldTMLinesByLineNo);
                }
                mapOldTMLinesByLineNo.put(tmLine.Line_No__c.intValue(), tmLine);
                //ticket 19130 >>

                TM_Line__c newTMLine = tmLine.clone(false, true, false, false);
                newTMLine.TM__c = newTM.Id;
                newTMLine.TM_Job_Task__c = newJobTask.Id;
                newTMLine.Category__c = tmLine.Category__c;
                newTMLine.Tax_Group__c = tmLine.Tax_Group__c;
                newTMLine.Resource_Type__c = tmLine.Resource_Type__c;
                newTMLine.Resource__c = tmLine.Resource__c;
                newTMLine.Resource_Name__c = tmLine.Resource_Name__c;
                newTMLine.Description__c = tmLine.Description__c;
                newTMLine.Service_Center__c = tmLine.Service_Center__c;
                newTMLine.Unit_of_Measure__c = tmLine.Unit_of_Measure__c;
                newTMLine.Line_No__c = tmLine.Line_No__c;
                newTMLine.Contract_Line__c = tmLine.Contract_Line__c;
                if (tmLine.Category__c != 'Labor' && tmLine.Category__c != 'Equipment') {
                    newTMLine.Quantity__c = tmLine.Quantity__c;
                } else {
                    newTMLine.Quantity__c = 0;
                    newTMLine.Regular_Hours__c = null;
                    newTMLine.Overtime_Hours__c = null;
                    newTMLine.Premium_Hours__c = null;
                    newTMLine.Cost_Qty__c = 0;
                }
                newTMLine.Job_Start_Time__c = null;
                newTMLine.Job_End_Time__c = null;
                newTMLine.Site_Start_Time__c = null;
                newTMLine.Site_End_Time__c = null;
                newTMLine.Total_Job_Hours__c = 0;
                newTMLine.Total_Site_Hours__c = 0;
                newTMLine.Billing_End_Time__c = null;
                newTMLine.Billing_Start_Time__c = null;
                newTMLine.Hour__c = 0;
                newTMLine.Lunch_End_Time__c = null;
                newTMLine.Lunch_Start_Time__c = null;
                newTMLine.Lunch__c = null;
                newTMLine.Sales_Line__c = tmLine.Sales_Line__c;
                newTMLine.Regular_Rate__c = tmLine.Regular_Rate__c;
                newTMLine.Premium_Rate__c = tmLine.Premium_Rate__c;
                newTMLine.Overtime_Rate__c = tmLine.Overtime_Rate__c;
                newTMLine.Markup_Option__c = tmLine.Markup_Option__c;
                newTMLine.Markup__c = tmLine.Markup__c;
                newTMLine.Invoiced__c = false;
                newTMLine.Billing_Worksheet_Line__c = null;
                if (newTMLine.Category__c == 'Labor') {
                    newTMLine.Unit_Price__c = tmLine.Regular_Rate__c;
                } else {
                    newTMLine.Unit_Price__c = tmLine.Unit_Price__c;
                }

                //ticket 19130 <<
                newTMLine.Is_Child_Resource__c = tmLine.Is_Child_Resource__c;
                newTMLine.Dereferenced_Child_Resource__c = tmLine.Dereferenced_Child_Resource__c;
                newTMLines.add(newTMLine);
                //ticket 19130 >>

                mapNewTMLinesByLineNo.put(newTMLine.Line_No__c.intValue(), newTMLine);
            }

            //ticket 19130 <<
            insert newTMLines;

            List<TM_Line__c> newTMLinesToUpdate = new List<TM_Line__c>();
            List<TM_Parent_Child_Relation__c> relationsToInsert = new List<TM_Parent_Child_Relation__c>();
            for (Id tmId : mapOldTMLinesByLineNoByNewTMId.keySet()) {
                Map<Integer, TM_Line__c> mapOldTMLinesByLineNo = mapOldTMLinesByLineNoByNewTMId.get(tmId);
                Map<Integer, TM_Line__c> mapNewTMLinesByLineNo = mapNewTMLinesByLineNoByTMId.get(tmId);
                for (TM_Line__c oldTMLine : mapOldTMLinesByLineNo.values()) {
                    TM_Line__c newTmLine = mapNewTMLinesByLineNo.get(oldTMLine.Line_No__c.intValue());
                    Boolean updateLine = false;
                    if (oldTMLine.Bundle_Line__r != null) {
                        Integer bundleLineNo = oldTMLine.Bundle_Line__r.Line_No__c.intValue();
                        newTMLine.Bundle_Line__c = mapNewTMLinesByLineNo.get(bundleLineNo).Id;
                        updateLine = true;
                    }

                    if (oldTMLine.Linked_Line__r != null) {
                        Integer linkedLineNo = oldTMLine.Linked_Line__r.Line_No__c.intValue();
                        newTMLine.Linked_Line__c = mapNewTMLinesByLineNo.get(linkedLineNo).Id;
                        updateLine = true;
                    }

                    if (updateLine) {
                        newTMLinesToUpdate.add(newTMLine);
                    }

                    if (oldTMLine.TM_Child_Lines__r != null) {
                        for (TM_Parent_Child_Relation__c xRelation : oldTMLine.TM_Child_Lines__r) {
                            TM_Parent_Child_Relation__c relation = new TM_Parent_Child_Relation__c();
                            TM_Line__c newChildTMLine = mapNewTMLinesByLineNo.get(xRelation.Child_Line__r.Line_No__c.intValue());
                            relation.Parent_Line__c = newTMLine.Id;
                            relation.Child_Line__c = newChildTMLine.Id;
                            relationsToInsert.add(relation);
                        }
                    }
                }
            }
            update newTMLinesToUpdate;
            insert relationsToInsert;
            //ticket 19130 >>
            //insert bundle line first
            List<TM_Line__c> bundleLinesToInsert = new List<TM_Line__c>();
            for (Map<Integer, TM_Line__c> mapNewTMLinesByLineNo : mapNewTMLinesByLineNoByTMId.values()) {
                Set<Integer> bundleLineNos = new Set<Integer>();
                for (TM_Line__c tmLine : mapNewTMLinesByLineNo.values()) {
                    if (tmLine.Bundle_Line__r != null) {
                        bundleLineNos.add(tmLine.Bundle_Line__r.Line_No__c.intValue());
                    }
                }

                for (TM_Line__c tmLine : mapNewTMLinesByLineNo.values()) {
                    if (bundleLineNos.contains(tmLine.Line_No__c.intValue())) {
                        bundleLinesToInsert.add(tmLine);
                    }
                }
            }
            if (bundleLinesToInsert.size() > 0) {
                //CompanyMgmt.byPassTrigger = true;
                //CompanyMgmt.byPassLineTrigger = true;
                upsert bundleLinesToInsert;
                //CompanyMgmt.byPassTrigger = false;
                //CompanyMgmt.byPassLineTrigger = false;
            }

            //insert parent lines next
            List<TM_Line__c> parentLinesToInsert = new List<TM_Line__c>();
            for (Map<Integer, TM_Line__c> mapNewTMLinesByLineNo : mapNewTMLinesByLineNoByTMId.values()) {
                Set<Integer> parentLineNos = new Set<Integer>();
                for (TM_Line__c tmLine : mapNewTMLinesByLineNo.values()) {
                    if (tmLine.Parent_Line__r != null) {
                        parentLineNos.add(tmLine.Parent_Line__r.Line_No__c.intValue());
                    }
                }

                for (TM_Line__c tmLine : mapNewTMLinesByLineNo.values()) {
                    if (parentLineNos.contains(tmLine.Line_No__c.intValue())) {
                        parentLinesToInsert.add(tmLine);
                    }
                }
            }
            if (parentLinesToInsert.size() > 0) {
                //CompanyMgmt.byPassTrigger = true;
                //CompanyMgmt.byPassLineTrigger = true;
                upsert parentLinesToInsert;
                //CompanyMgmt.byPassTrigger = false;
                //CompanyMgmt.byPassLineTrigger = false;
            }

            //insert linked lines next
            List<TM_Line__c> linkedLinesToInsert = new List<TM_Line__c>();
            for (Map<Integer, TM_Line__c> mapNewTMLinesByLineNo : mapNewTMLinesByLineNoByTMId.values()) {
                Set<Integer> linkedLineNos = new Set<Integer>();
                for (TM_Line__c tmLine : mapNewTMLinesByLineNo.values()) {
                    if (tmLine.Linked_Line__r != null) {
                        linkedLineNos.add(tmLine.Linked_Line__r.Line_No__c.intValue());
                    }
                }

                for (TM_Line__c tmLine : mapNewTMLinesByLineNo.values()) {
                    if (linkedLineNos.contains(tmLine.Line_No__c.intValue())) {
                        linkedLinesToInsert.add(tmLine);
                    }
                }
            }
            if (linkedLinesToInsert.size() > 0) {
                ///CompanyMgmt.byPassTrigger = true;
                //CompanyMgmt.byPassLineTrigger = true;
                upsert linkedLinesToInsert;
                //CompanyMgmt.byPassTrigger = false;
                //CompanyMgmt.byPassLineTrigger = false;
            }

            //update bundled, child and linked lines
            //List<TM_Line__c> tmLines = new List<TM_Line__c>();
            for (Id tmId : mapNewTMLinesByLineNoByTMId.keySet()) {
                Map<Integer, TM_Line__c> mapNewTMLinesByLineNo = mapNewTMLinesByLineNoByTMId.get(tmId);
                for (Integer lineNo : mapNewTMLinesByLineNo.keySet()) {
                    TM_Line__c tmLine = mapNewTMLinesByLineNo.get(lineNo);

                    if (tmLine.Bundle_Line__r != null) {
                        TM_Line__c bundleLine = mapNewTMLinesByLineNo.get(tmLine.Bundle_Line__r.Line_No__c.intValue());
                        tmLine.Bundle_Line__c = bundleLine.Id;
                        tmLine.Bundle_Line__r = new TM_Line__c(Id = bundleLine.Id, Line_No__c = bundleLine.Line_No__c);
                    }
                    if (tmLine.Parent_Line__r != null) {
                        TM_Line__c parentLine = mapNewTMLinesByLineNo.get(tmLine.Parent_Line__r.Line_No__c.intValue());
                        tmLine.Parent_Line__c = parentLine.Id;
                        tmLine.Parent_Line__r = new TM_Line__c(Id = parentLine.Id, Line_No__c = parentLine.Line_No__c);
                    }
                    if (tmLine.Linked_Line__r != null) {
                        TM_Line__c linkedLine = mapNewTMLinesByLineNo.get(tmLine.Linked_Line__r.Line_No__c.intValue());
                        tmLine.Linked_Line__c = linkedLine.Id;
                        tmLine.Linked_Line__r = new TM_Line__c(Id = linkedLine.Id, Line_No__c = linkedLine.Line_No__c);
                    }
                    //tmLines.add(tmLine);
                }
            }

            //duplicated safety plan lines issue <<
            Map<TM__c, List<TM_Line__c>> mapTMLinesByTM = new Map<TM__c, List<TM_Line__c>>();
            Map<TM__c, List<ACVTMJobTaskWrapper>> mapJobTaskWrappersByTM = new Map<TM__c, List<ACVTMJobTaskWrapper>>();
            Map<Id, Integer> mapNextTMLineNosByTMId = new Map<Id, Integer>();
            for (Id oldTMId : mapNewTMsByOldTMId.keySet()) {
                TM__c newTM = mapNewTMsByOldTMId.get(oldTMId);
                List<TM_Job_Task__c> newTMJobTasks = mapNewJobTasksByLineNoByOldTMId.get(oldTMId).values();
                List<TM_Line__c> newTMLines = mapNewTMLinesByLineNoByTMId.get(newTM.Id).values();

                //ticket 19130 <<
                Map<Integer, TM_Line__c> mapNewTMLinesByLineNo = mapNewTMLinesByLineNoByTMId.get(newTM.Id);
                mapTMLinesByTM.put(newTM, mapNewTMLinesByLineNo.values());
                ACVTMWrapper tmWrapper = new ACVTMWrapper(newTM, newTMJobTasks, mapNewTMLinesByLineNo.values());
                mapJobTaskWrappersByTM.put(tmWrapper.TM, tmWrapper.JobTaskWrappers);
                //ticket 19130 >>



                Integer nextTMLineNo = 0;
                for (TM_Line__c newTmLine : newTMLines) {
                    if (nextTMLineNo < newTMLine.Line_No__c.intValue()) {
                        nextTMLineNo = newTmLine.Line_No__c.intValue();
                    }
                }
                nextTMLineNo++;
                mapNextTMLineNosByTMId.put(newTM.Id, nextTMLineNo);
            }

            TMLLinesService.initStaticVariables(mapTMLinesByTM);

            List<TM_Line__c> tmLines = new List<TM_Line__c>();
            for (TM__c newTM : mapJobTaskWrappersByTM.keySet()) {
                Integer nextTMLineNo = mapNextTMLineNosByTMId.get(newTM.Id);
                List<ACVTMJobTaskWrapper> jobTaskWrappers = mapJobTaskWrappersByTM.get(newTM);

                for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    Integer lineCount = jobTaskWrapper.TMLines.size();
                    TMLLinesService.createSafetyPlanLine(newTM, jobTaskWrapper, nextTMLineNo);
                    if (jobTaskWrapper.TMLines.size() > lineCount) {
                        nextTMLineNo++;
                        break;
                    }
                }

                for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    Integer lineCount = jobTaskWrapper.TMLines.size();
                    TMLLinesService.calculateManifestFeeLine(newTM, jobTaskWrapper, nextTMLineNo);
                    if (jobTaskWrapper.TMLines.size() > lineCount) {
                        nextTMLineNo++;
                    }
                }

                for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    Integer lineCount = jobTaskWrapper.TMLines.size();
                    TMLLinesService.calculateRinseOutFeeLine(newTM, jobTaskWrapper, nextTMLineNo);
                    if (jobTaskWrapper.TMLines.size() > lineCount) {
                        nextTMLineNo++;
                    }
                }

                //insert tm line to tmLines list
                for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                        tmLines.add(tmLine);
                    }
                }
            }
            //duplicated safety plan lines issue >>

            upsert tmLines;

            //Redirect to daily roster page
            PageReference redirectPage = new PageReference('/apex/DailyRoster?scheduledDate=' + scheduledDateValue);
            redirectPage.setRedirect(true);
            return redirectPage;
        }
        catch(Exception ex) {
            Database.rollback(sp);
            ApexPages.addMessages(ex);
            return null;
        }
    }
     */

    public PageReference cloneAndScheduleTM(){
        if (String.isEmpty(scheduledDateValue)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Schedule Date cannot be left blank.'));
            return null;
        }

        try {
            TMsService.cloneAndSchedule(theTMList, scheduledDateValue);
            //Redirect to daily roster page
            PageReference redirectPage = new PageReference('/apex/DailyRoster?scheduledDate=' + scheduledDateValue);
            redirectPage.setRedirect(true);
            return redirectPage;
        } catch (Exception ex){
            ApexPages.addMessages(ex);
            return null;
        }
    }
}