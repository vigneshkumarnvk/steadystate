/*************************************************************************************************
* Name         :  MobileTMController 
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Shahwaz Khan              09-10-2024             US128845 : SF - Profile field and Manifest Lookup behind Advanced Disposal flag
* Sanjana Ravichandran		01-24-2024			   US140219: [Unplanned] Salesforce - Add D365 Project ID to T&M when Present on Sales Order
*************************************************************************************************/
public with sharing class MobileTMController {

    //cache control <<
    @AuraEnabled
    public static String getVersion() {
        return  CompanySettingUtil.acvSetting.Mobile_TM_Version_No__c;
    }
    //cache control >>

    @AuraEnabled
    public static String validateResourceType(String JSONTMLine) {
        try {
            TM_Line__c tmLine = (TM_Line__c)JSON.deserialize(JSONTMLine, TM_Line__c.class);
            List<TM__c> tms = TMsSelector.newInstance().selectByIds(new Set<Id>{ tmLine.TM__c });
            if (tms.size() == 0) {
                throw new DataException('T&M line ' + tmLine.Line_No__c + ' is not associated with a T&M.' + tmLine.TM__c);
            }
            TMLLinesService.validateResourceType(tms[0], tmLine);
            return JSON.serialize(tmLine);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //ticket 18178 <<
    @AuraEnabled
    public static String validateResource(String JSONTMLine) {
        try {
            TM_Line__c tmLine = (TM_Line__c)JSON.deserialize(JSONTMLine, TM_Line__c.class);
            List<TM__c> tms = TMsSelector.newInstance().selectByIds(new Set<Id>{ tmLine.TM__c });
            if (tms.size() == 0) {
                throw new DataException('T&M line ' + tmLine.Line_No__c + ' is not associated with a T&M.' + tmLine.TM__c);
            }
            TMLLinesService.validateResource(tms[0], tmLine);
            return JSON.serialize(tmLine);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String validateUnitOfMeasure(String JSONTMLine) {
        try {
            TM_Line__c tmLine = (TM_Line__c)JSON.deserialize(JSONTMLine, TM_Line__c.class);
            List<TM__c> tms = TMsSelector.newInstance().selectByIds(new Set<Id>{ tmLine.TM__c });
            if (tms.size() == 0) {
                throw new DataException('T&M line ' + tmLine.Line_No__c + ' is not associated with a T&M.' + tmLine.TM__c);
            }
            TMLLinesService.validateUnitOfMeasure(tms[0], tmLine);
            return JSON.serialize(tmLine);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    //ticket 18178 >>

    /*
     *  //Ticket#24559 add Default_Billing_Rule_To_Display__c to sales order query
     */
    @AuraEnabled
    public static String getSalesOrder(Id salesOrderId) {
        try {
            List<Sales_Order__c> salesOrders = [SELECT Id, Payment_Term__r.Name, Any_Deviations__c, Shippable_Containers__c, First_Hour_Of_Loading__c, Overtime_Rate_Description__c, Rate_Time_Definitions__c, Charges_For_Labor__c,
                    Waste_Disposal_And_Ancillary__c, Characterization_Of_Waste__c, Generate_Before_Final__c, Lab_Packs_Rate__c, Cylinders_Require_Evaluation__c, Manifest_And_Profile__c, Net_Due_Day__c, Applicable_Taxes_Quote__c,
                    Client_Is_Responsible__c, In_The_Event__c, Quote_Valid_30__c, Unless_Superseded__c, Term_Conditions_Opt20__c,
                    Service_Center__r.Term_Conditions_Opt1__c,Service_Center__r.Term_Conditions_Opt2__c,
                    Service_Center__r.Term_Conditions_Opt3__c,Service_Center__r.Term_Conditions_Opt4__c,Service_Center__r.Term_Conditions_Opt5__c,
                    Service_Center__r.Term_Conditions_Opt6__c,Service_Center__r.Term_Conditions_Opt7__c,Service_Center__r.Term_Conditions_Opt8__c,
                    Service_Center__r.Term_Conditions_Opt9__c,Service_Center__r.Term_Conditions_Opt10__c,Service_Center__r.Term_Conditions_Opt11__c,
                    Service_Center__r.Term_Conditions_Opt12__c,Service_Center__r.Term_Conditions_Opt13__c,Service_Center__r.Term_Conditions_Opt14__c,
                    Service_Center__r.Term_Conditions_Opt15__c,Service_Center__r.Term_Conditions_Opt16__c,Service_Center__r.Term_Conditions_Opt17__c,
                    Service_Center__r.Term_Conditions_Opt18__c,Service_Center__r.Term_Conditions_Opt19__c, Service_Center__r.Term_Conditions_Opt20__c,
                    Default_Billing_Rule_To_Display__c
            FROM Sales_Order__c WHERE Id =:salesOrderId];
            if (salesOrders.size() > 0) {
                return JSON.serialize(salesOrders[0]);
            }
            return null;
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String getJobTaskTemplateQuestionLines(Id jobTaskTemplateId) {
        try {
            List<Job_Task_Template_Line__c> jobTaskTemplateLines = JobTaskTemplateLinesSelector.newInstance().selectByTemplateId(new Set<Id>{ jobTaskTemplateId }, null);
            return JSON.serialize(jobTaskTemplateLines);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String getServiceRating(Id tmId) {
        try {
            List<TM_Service_Rating__c> ratings = [SELECT Id, Name, TM__c, TM__r.Service_Center__c,
                    TM__r.Service_Center__r.TM_Service_Rep__c, TM__r.Service_Center__r.TM_Service_Rep__r.Email,
                    TM__r.Name, Rating__c, Customer_Review__c, Customer_Name__c, Customer_Email__c, LastModifiedDate FROM TM_Service_Rating__c WHERE TM__c = :tmId];
            if (ratings.size() > 0) {
                return JSON.serialize(ratings[0]);
            }
            return null;
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void saveServiceRating(String JSONServiceRating) {
        try {
            TM_Service_Rating__c rating = (TM_Service_Rating__c)JSON.deserialize(JSONServiceRating, TM_Service_Rating__c.class);
            if (rating.Rating__c <= 2) {
                createLowRatingTask(rating);
            }
            upsert rating;
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static void createLowRatingTask(TM_Service_Rating__c rating) {
        //task record type <<
        //List<TM__c> tms = [SELECT Name, Service_Center__r.TM_Service_Rep__c FROM TM__c WHERE Id = :rating.TM__c];
        List<TM__c> tms = [SELECT Name, Bill_to_Customer__c, Service_Center__r.TM_Service_Rep__c FROM TM__c WHERE Id = :rating.TM__c];
        //task record type >>
        if (tms.size() > 0) {
            TM__c tm = tms[0];
            //task record type <<
            Id recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Customer Rating').getRecordTypeId();
            //task record type >>
            if (tm.Service_Center__r != null && tm.Service_Center__r.TM_Service_Rep__c != null) {
                Id assigneeId = tm.Service_Center__r.TM_Service_Rep__c;
                Task task = new Task();
                //task record type <<
                task.RecordTypeId = recordTypeId;
                task.Account__c = tm.Bill_to_Customer__c;
                //task record type <<
                task.Subject = 'Low Customer Rating on T&M ' + tm.Name;
                task.OwnerId = assigneeId;
                task.Priority = 'Normal';
                task.ActivityDate = system.today();
                task.Description = 'Customer\'s feedback:\n' + rating.Customer_Review__c;
                task.Status = 'Open';
                task.WhatId = rating.TM__c;
                insert task;
            }
        }
    }

    @AuraEnabled
    //cache control <<
    //public static String getTMs(String ownership, Date scheduledDate, String keyword) {
    public static String getTMs(String ownership, Date scheduledDate, String keyword, String version) {
        //cache control >>
        try {
            //cache <<
            String currentVersion = CompanySettingUtil.acvSetting.Mobile_TM_Version_No__c;
            if (version != null && version != currentVersion) {
                throw new DataException('VERSION_ERROR');
            }
            //cache >>

            //schedule date filter
            Date today = system.today();
            List<String> filterSet1 = new List<String>();
            filterSet1.add('Status__c=\'Scheduled\'');
            if (scheduledDate != null) {
                filterSet1.add('Scheduled_Date__c = :scheduledDate');
            }
            String filterGroup1 = '(' + String.join(filterSet1, ' AND ') + ') OR (Status__c=\'Mobile Review\' AND Scheduled_Date__c = :today) OR (Status__c=\'Open\' AND Emergency_TM__c=TRUE)';

            //keyword filter
            List<String> keywordFilters = new List<String>();
            if (String.isNotEmpty(keyword)) {
                String[] fieldNames = new String[] { 'Name', 'Sales_Order__r.Name', 'Bill_to_Customer__r.Name', 'Site_Name__c', 'Site_Street__c', 'Site_Contact__c', 'Site_City__c', 'Site_Postal_Code__c', 'Site_Phone_No__c', 'PO_Reference_No__c' };
                for (String fieldName : fieldNames) {
                    keywordFilters.add(fieldName + ' LIKE \'%' + String.escapeSingleQuotes(keyword) + '%\'');
                }
            }
            String filterGroup2 = String.join(keywordFilters, ' OR ');

            //My TMs
            List<Id> resourceIds = new List<Id>();
            for (Resource__c resource : [SELECT Id FROM Resource__c WHERE User__c = :userInfo.getUserId()]) {
                resourceIds.add(resource.Id);
            }
            Set<Id> tmIds = new Set<Id>();
            String resourceQueryString = 'SELECT Id, TM__c FROM TM_Line__c WHERE Resource__c IN : resourceIds AND (TM__r.Status__c=\'Scheduled\' OR TM__r.Status__c =\'Mobile Review\')';
            for (TM_Line__c tml : Database.query(resourceQueryString)) {
                tmIds.add(tml.TM__c);
            }
            String filterGroup3 = 'Id IN :tmIds';

            //All TMs
            List<Id> scIds = new List<Id>();
            for (User_Service_Center__c usc : [SELECT Service_Center__c FROM User_Service_Center__c WHERE User__c = :userInfo.getUserId()]) {
                scIds.add(usc.Service_Center__c);
            }
            String filterGroup4 = 'Service_Center__c IN :scIds';

            //concatenate filters
            List<String> filters = new List<String>();
            filters.add('(' + filterGroup1 + ')');
            if (String.isNotEmpty(filterGroup2)) {
                filters.add('(' + filterGroup2 + ')');
            }

            if (ownership == 'MyTMs') {
                filters.add(filterGroup3);
            }
            else {
                filters.add('((' + filterGroup3 + ') OR (' + filterGroup4 + '))');
            }

            String queryString = 'SELECT Id, Name, Sales_Order__r.Name, Emergency_TM__c, Service_Center__c, Service_Center__r.Name, Scheduled_Date__c, Status__c, Bill_to_Customer__r.Name, Site_Street__c, Site_Contact__c, Site_City__c, Site_Postal_Code__c, D365_Project_ID__c';
            queryString += ' FROM TM__c';
            queryString += ' WHERE ' + String.join(filters, ' AND ');
            queryString += ' ORDER BY Scheduled_Date__c DESC LIMIT 100';

            List<TM__c> tms = (List<TM__c>)Database.query(queryString);
            return JSON.serialize(tms);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String getTM(Id tmId) {
        try {
            String queryString = 'SELECT ' + String.join(getTMFields(), ',') + ' FROM TM__c WHERE Id = :tmId';
            List<TM__c> tms = (List<TM__c>)Database.query(queryString);
            return JSON.serialize(tms[0]);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String getJobTaskWrappers(Id tmId) {
        try {
            List<TM__c> tms = TMsSelector.newInstance().selectByIds(new Set<Id> { tmId });
            TM__c tm;
            if (tms.size() > 0) {
                tm = tms[0];
            }
            List<TM_Job_Task__c> jobTasks = TMJobTasksSelector.newInstance().selectByTMId(new Set<Id> { tmId });
            List<TM_Line__c> tmLines = TMLinesSelector.newInstance().selectWithFlatPaysByTmId(new set<Id> { tmId }, null);

            Integer nextTMLineNo = 0;
            for (TM_Line__c tmLine : tmLines) {
                if (tmLine.Line_No__c.intValue() > nextTMLineNo) {
                    nextTMLineNo = tmLine.Line_No__c.intValue();
                }
            }

            ACVTMWrapper tmWrapper = new ACVTMWrapper(tm, jobTasks, tmLines);
            for (ACVTMJobTaskWrapper jobTaskWrapper : tmWrapper.JobTaskWrappers) {
                jobTaskWrapper.NextTMLineNo = nextTMLineNo;
            }

            return JSON.serialize(tmWrapper.JobTaskWrappers);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String getTMLines(Id tmId, String category) {
        try {
            return TMBaseController.getTMLines(tmId, category);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String saveTM(String JSONTM, String category, String JSONJobTaskWrappers) {
        Savepoint sp = Database.setSavepoint();
        try {
            TM__c tm = (TM__c)JSON.deserialize(JSONTM, TM__c.class);
            List<ACVTMJobTaskWrapper> jobTaskWrappers;
            if (JSONJobTaskWrappers != null) {
                jobTaskWrappers = (List<ACVTMJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVTMJobTaskWrapper>.class);
            }

            if (tm != null) {
                tm.Mobile_TM__c = true;
                if(tm.Mobile_First_Save_At__c == null){
                    tm.Mobile_First_Save_At__c = System.now();
                }
                upsert tm;
            }

            if (jobTaskWrappers != null) {
                if (category == null) {
                    throw new DataException('System error: category is missing for the save function.');
                }

                //deleted lines <<
                /*
                List<Id> tmlIds = new List<Id>();
                for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                        if (tmLine.Id != null) {
                            tmlIds.add(tmLine.Id);
                        }
                    }
                }

                if (tm.Id != null) {
                    if (tmlIds.size() > 0) {
                        delete [SELECT Id FROM TM_Line__c WHERE TM__c = :tm.Id AND Category__c = :category AND System_Calculated_Line__c != TRUE AND Id NOT IN :tmlIds];
                    }
                }
                */
                Set<Id> deletedTMLineIds = new Set<Id>();
                for (Integer i = 0; i < jobTaskWrappers.size(); i++) {
                    if (jobTaskWrappers[i].DeletedTMLines != null) {
                        for (Integer j = 0; j < jobTaskWrappers[i].DeletedTMLines.size(); j++) {
                            TM_Line__c tmLine = jobTaskWrappers[i].DeletedTMLines[j];
                            if (tmLine.Id != null) {
                                deletedTMLineIds.add(tmLine.Id);
                            }
                        }
                    }
                }

                Set<Id> tmLineIds = new Set<Id>();
                for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                        if (tmLine.Id != null) {
                            tmLineIds.add(tmLine.Id);
                        }
                    }
                }

                List<TM_Line__c> tmLines = TMBaseController.initTMLinesFromWrapper(tm, jobTaskWrappers);

                //find lines removed due to blank resource type, resource and description by initTMLinesFromWrapper()
                Set<Id> tmLineIds2 = new Set<Id>();
                for (TM_Line__c tmLine : tmLines) {
                    if (tmLine.Id != null) {
                        tmLineIds2.add(tmLine.Id);
                    }
                }
                tmLineIds.removeAll(tmLineIds2);
                deletedTMLineIds.addAll(tmLineIds);

                List<TM_Parent_Child_Relation__c> relationsToDelete = [SElECT Id FROM TM_Parent_Child_Relation__c WHERE Child_Line__c IN :deletedTMLineIds];
                if (deletedTMLineIds.size() > 0) {
                    delete [SELECT Id FROM TM_Line__c WHERE TM__c = :tm.Id AND Category__c = :category AND Id IN :deletedTMLineIds];
                }

                //ticket 19725 <<
                Map<Id, TM_Line__c> mapTMLinesById = new Map<Id, TM_Line__c>();
                //ticket 19130 <<
                //for (TM_Line__c tmLine : [SELECT Id, LastModifiedDate FROM TM_Line__c WHERE TM__c = :tm.Id AND Category__c = :category AND Id IN :tmLineIds2]) {
                for (TM_Line__c tmLine : [SELECT Id, Resource__c, Resource_Type__c, Service_Center__c, Unit_of_Measure__c, Quantity__c, LastModifiedDate FROM TM_Line__c WHERE TM__c = :tm.Id AND Category__c = :category AND Id IN :tmLineIds2]) {
                    //ticket 19130 >>
                    mapTMLinesById.put(tmLine.Id, tmLine);
                }

                //ticket 19130 <<
                Boolean lineChangesDetected = false;
                //ticket 19130 >>
                for (TM_Line__c tmLine : tmLines) {
                    if (tmLine.Id != null) {
                        if (mapTMLinesById.containsKey(tmLine.Id)) {
                            TM_Line__c xTMLine = mapTMLinesById.get(tmLine.Id);
                            //ticket 19130 05.13.2023 <<
                            /*
                            if (tmLine.LastModifiedDate >= xTMLine.LastModifiedDate) {
                                mapTMLinesById.remove(tmLine.Id);
                            }
                            */
                            if (tmLine.LastModifiedDate < xTMLine.LastModifiedDate) {
                                throw new DataException('T&M line #' + tmLine.Line_No__c + ' has been modified after you retrieved the data. Please refresh the page and try again. ' + tmLine.LastModifiedDate + ' < ' + xTMLine.LastModifiedDate);
                            }
                            else {
                                mapTMLinesById.remove(tmLine.Id);
                            }
                            //ticket 19130 05.13.2023 >>

                            //ticket 19130 <<
                            if (tmLine.Resource_Type__c != xTMLine.Resource_Type__c || tmLine.Resource__c != xTMLine.Resource__c
                                    || tmLine.Service_Center__c != xTMLine.Service_Center__c || tmLine.Unit_of_Measure__c != xTMLine.Unit_of_Measure__c
                                    || tmLine.Quantity__c != xTMLine.Quantity__c) {
                                tmLine.Wizard_Question_Answered__c = false;
                                lineChangesDetected = true;
                            }
                            //ticket 19130 >>
                        }
                    }
                    //ticket 19130 <<
                    else {
                        lineChangesDetected = true;
                    }
                    //ticket 19130 >>
                }

                if (mapTMLinesById.size() > 0) {
                    throw new DataException('T&M lines have been modified after you retrieved the data. Please refresh the page and try again.');
                }

                //ticket 19130 05.13.2023 << move the relationship deletion after the line modified checking to avoid the last modified date of the tm line gets auto updated by the master-detail relationship
                delete relationsToDelete;
                //ticket 19130 05.13.2023 >>

                //ticket 19130 <<
                if (deletedTMLineIds.size() > 0) {
                    lineChangesDetected = true;
                }
                if (lineChangesDetected == true) {
                    List<Signature__c> signatures = [SELECT Id FROM Signature__c WHERE TM__c = :tm.Id AND Voided__c != true];
                    for (Signature__c signature : signatures) {
                        signature.Voided__c = true;
                        signature.Void_Reason__c = 'Line update by Supervisor';
                    }
                    update signatures;
                }
                //ticket 19130 >>

                //update equipment lines by equipment operator <<
                if (category == 'Labor') {
                    //ticket 19130 <<
                    //List<TM_Line__c> equipmentLines = [SELECT Id, Linked_Line__r.Line_No__c, Unit_of_Measure__r.Hours_UOM__c FROM TM_Line__c WHERE TM__c = :tm.Id AND Category__c = 'Equipment' AND Invoiced__c != TRUE AND Linked_Line__c != NULL];
                    List<TM_Line__c> equipmentLines = [SELECT Id, Line_No__c, Category__c, Resource_Type__c, Resource__c, TM_Job_Task__c, TM_Job_Task__r.Sales_Order_Job_Task__c, Linked_Line__r.Line_No__c, Unit_of_Measure__r.Hours_UOM__c FROM TM_Line__c WHERE TM__c = :tm.Id AND Category__c = 'Equipment' AND Invoiced__c != TRUE AND Linked_Line__c != NULL];
                    //ticket 19130 >>

                    if (equipmentLines.size() > 0) {
                        Map<Integer, TM_Line__c> mapLaborLinesByLineNo = new Map<Integer, TM_Line__c>();
                        for (TM_Line__c tmLine : tmLines) {
                            mapLaborLinesByLineNo.put(tmLine.Line_No__c.intValue(), tmLine);
                        }

                        //ticket 19130 <<
                        Map<Id, TM_Line__c> mapTMEquipmentLinesById = new Map<Id, TM_Line__c>();
                        for (TM_Line__c tmLine : tmLines) {
                            if (tmLine.Id != null && tmLine.Category__c == 'Equipment') {
                                mapTMEquipmentLinesById.put(tmLine.Id, tmLine);
                            }
                        }
                        //ticket 19130 >>

                        for (TM_Line__c equipmentLine : equipmentLines) {
                            if (equipmentLine.Linked_Line__r != null) {
                                if (mapLaborLinesByLineNo.containsKey(equipmentLine.Linked_Line__r.Line_No__c.intValue())) {
                                    TM_Line__c laborLine = mapLaborLinesByLineNo.get(equipmentLine.Linked_Line__r.Line_No__c.intValue());
                                    if (laborLine.Job_Start_Time__c != null && laborLine.Job_End_Time__c != null) {
                                        equipmentLine.Job_Start_Time__c = laborLine.Job_Start_Time__c;
                                        equipmentLine.Job_End_Time__c = laborLine.Job_End_Time__c;
                                        equipmentLine.Total_Job_Hours__c = laborLine.Total_Job_Hours__c;
                                        if (equipmentLine.Unit_of_Measure__r != null && equipmentLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                                            equipmentLine.Quantity__c = equipmentLine.Total_Job_Hours__c;
                                        } else {
                                            equipmentLine.Quantity__c = 1;
                                        }

                                        //ticket 19130 <<
                                        //tmLines.add(equipmentLine);
                                        if (mapTMEquipmentLinesById.containsKey(equipmentLine.Id)) {
                                            mapTMEquipmentLinesById.put(equipmentLine.Id, equipmentLine);
                                        }
                                        else {
                                            tmLines.add(equipmentLine);
                                        }
                                        //ticket 19130 >>
                                    }
                                }
                            }
                        }
                    }
                }

                //update equipment lines by equipment operator >>

                //ticket 19130 05.03.23 <<
                Map<Id, Map<Id, TM_Line__c>> mapTMLinesByResourceIdByJobTaskId = new Map<Id, Map<Id, TM_Line__c>>();
                List<TM_Line__c> allTMLines = [SELECT Id, Line_No__c, TM_Job_Task__c, TM_Job_Task__r.Sales_Order_Job_Task__c, Category__c, Resource_Type__c, Resource__c FROM TM_Line__c WHERE TM__c = :tm.Id ORDER BY Line_No__c];

                allTMLines.addAll(tmLines);

                Integer nextTMLineNo = 0;
                Set<Id> resourceIds = new Set<Id>();
                Set<Id> salesOrderJobTaskIds = new Set<Id>();
                for (TM_Line__c tmLine : allTMLines) {
                    Map<Id, TM_Line__c> mapTMLinesByResourceId;
                    if (mapTMLinesByResourceIdByJobTaskId.containsKey(tmLine.TM_Job_Task__c)) {
                        mapTMLinesByResourceId = mapTMLinesByResourceIdByJobTaskId.get(tmLine.TM_Job_Task__c);
                    }
                    else {
                        mapTMLinesByResourceId = new Map<Id, TM_Line__c>();
                        mapTMLinesByResourceIdByJobTaskId.put(tmLine.TM_Job_Task__c, mapTMLinesByResourceId);
                    }

                    Id resourceId;
                    if (tmLine.Category__c == 'Labor' || tmLine.Category__c == 'Equipment') {
                        resourceId = tmLine.Resource_Type__c;
                    }
                    else {
                        resourceId = tmLine.Resource__c;
                    }
                    if (!mapTMLinesByResourceId.containsKey(resourceId)) {
                        mapTMLinesByResourceId.put(resourceId, tmLine);
                    }
                    resourceIds.add(resourceId);
                    salesOrderJobTaskIds.add(tmLine.TM_Job_Task__r.Sales_Order_Job_Task__c);

                    if (nextTMLineNo < tmLine.Line_No__c.intValue()) {
                        nextTMLineNo = tmLine.Line_No__c.intValue();
                    }
                }
                nextTMLineNo++;

                Map<Id, Map<Id, Sales_Line__c>> mapSalesLinesByResourceIdByJobTaskId = new Map<Id, Map<Id, Sales_Line__c>>();
                Map<Id, Map<Id, Sales_Line__c>> mapSalesLinesByIdByJobTaskId = new Map<Id, Map<Id, Sales_Line__c>>();
                for (Sales_Line__c salesLine : [SELECT Id, Line_No__c, Sales_Order_Job_Task__c, Category__c, Resource_Type__c, Resource_Type__r.Name, Resource__c, Resource__r.Name, Description__c, Unit_of_Measure__c, Unit_of_Measure__r.Name, Sales_Order__r.Service_Center__c, Sales_Order__r.Service_Center__r.Name,
                (SELECT Id, Child_Line__c, Child_Line__r.Category__c, Child_Line__r.Resource_Type__c, Child_Line__r.Resource_Type__r.Name, Child_Line__r.Resource__c, Child_Line__r.Resource__r.Name FROM Sales_Child_Lines__r) FROM Sales_Line__c WHERE Sales_Order_Job_Task__c IN :salesOrderJobTaskIds]) {
                    Map<Id, Sales_Line__c> mapSalesLinesById;
                    if (mapSalesLinesByIdByJobTaskId.containsKey(salesLine.Sales_Order_Job_Task__c)) {
                        mapSalesLinesById = mapSalesLinesByIdByJobTaskId.get(salesLine.Sales_Order_Job_Task__c);
                    } else {
                        mapSalesLinesById = new Map<Id, Sales_Line__c>();
                        mapSalesLinesByIdByJobTaskId.put(salesLine.Sales_Order_Job_Task__c, mapSalesLinesById);
                    }
                    mapSalesLinesById.put(salesLine.Id, salesLine);


                    Id resourceId;
                    if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment' || salesLine.Category__c == 'Bundled') {
                        resourceId = salesLine.Resource_Type__c;
                    } else {
                        resourceId = salesLine.Resource__c;
                    }
                    Map<Id, Sales_Line__c> mapSalesLinesByResourceId;
                    if (mapSalesLinesByResourceIdByJobTaskId.containsKey(salesLine.Sales_Order_Job_Task__c)) {
                        mapSalesLinesByResourceId = mapSalesLinesByResourceIdByJobTaskId.get(salesLine.Sales_Order_Job_Task__c);
                    } else {
                        mapSalesLinesByResourceId = new Map<Id, Sales_Line__c>();
                        mapSalesLinesByResourceIdByJobTaskId.put(salesLine.Sales_Order_Job_Task__c, mapSalesLinesByResourceId);
                    }
                    if (!mapSalesLinesByResourceId.containsKey(resourceId)) {
                        mapSalesLinesByResourceId.put(resourceId, salesLine);
                    }
                }

                List<TM_Line__c> childLinesToAdd = new List<TM_Line__c>();
                for (Integer i = 0; i < tmLines.size(); i++) {
                    TM_Line__c tmLine = tmLines[i];
                    if (tmLine.Id == null) { //insert child resource for new TM lines only
                        if (mapSalesLinesByResourceIdByJobTaskId.containsKey(tmLine.TM_Job_Task__r.Sales_Order_Job_Task__c)) {
                            Map<Id, Sales_Line__c> mapSalesLinesByResourceId = mapSalesLinesByResourceIdByJobTaskId.get(tmLine.TM_Job_Task__r.Sales_Order_Job_Task__c);
                            Map<Id, Sales_Line__c> mapSalesLinesById = mapSalesLinesByIdByJobTaskId.get(tmLine.TM_Job_Task__r.Sales_Order_Job_Task__c);
                            Map<Id, TM_Line__c> mapTMChildLinesByResourceId = mapTMLinesByResourceIdByJobTaskId.get(tmLine.TM_Job_Task__c);

                            Id resourceId;
                            if (tmLine.Category__c == 'Labor' || tmLine.Category__c == 'Equipment' || tmLine.Category__c == 'Bundled') {
                                resourceId = tmLine.Resource_Type__c;
                            } else {
                                resourceId = tmLine.Resource__c;
                            }
                            if (mapSalesLinesByResourceId.containsKey(resourceId)) {
                                Sales_Line__c salesLine = mapSalesLinesByResourceId.get(resourceId);
                                List<TM_Parent_Child_Relation__c> relations = new List<TM_Parent_Child_Relation__c>();
                                for (Sales_Parent_Child_Relation__c salesChildRelation : salesLine.Sales_Child_Lines__r) {
                                    Id childResourceId;
                                    if (salesChildRelation.Child_Line__r.Category__c == 'Labor' || salesChildRelation.Child_Line__r.Category__c == 'Equipment' || salesChildRelation.Child_Line__r.Category__c == 'Bundled') {
                                        childResourceId = salesChildRelation.Child_Line__r.Resource_Type__c;
                                    }
                                    else {
                                        childResourceId = salesChildRelation.Child_Line__r.Resource__c;
                                    }
                                    TM_Line__c childLine;
                                    if (!mapTMChildLinesByResourceId.containsKey(childResourceId)) { // add a child line for the child resource
                                        Sales_Line__c salesChildLine = mapSalesLinesById.get(salesChildRelation.Child_Line__c);

                                        childLine = new TM_Line__c();
                                        childLine.Line_No__c = nextTMLineNo;
                                        childLine.TM__c = tm.Id;
                                        childLine.TM_Job_Task__c = tmLine.TM_Job_Task__c;
                                        childLine.TM_Job_Task__r = tmLine.TM_Job_Task__r;
                                        childLine.Category__c = salesChildLine.Category__c;
                                        childLine.Resource_Type__c = salesChildLine.Resource_Type__c;
                                        childLine.Resource_Type__r = salesChildLine.Resource_Type__r;
                                        childLine.Resource__c = salesChildLine.Resource__c;
                                        childLine.Resource__r = salesChildLine.Resource__r;
                                        childLine.Unit_of_Measure__c = salesChildLine.Unit_of_Measure__c;
                                        childLine.Unit_of_Measure__r = salesChildLine.Unit_of_Measure__r;
                                        childLine.Description__c = salesChildLine.Description__c;
                                        childLine.Quantity__c = 0;
                                        if (childLine.Category__c == 'Labor' || childLine.Category__c == 'Equipment') {
                                            childLine.Service_Center__c = salesChildLine.Sales_Order__r.Service_Center__c;
                                            childLine.Service_Center__r = salesChildLine.Sales_Order__r.Service_Center__r;
                                        }
                                        childLine.Is_Child_Resource__c = true;
                                        childLine.Sales_Line__c = salesChildLine.Id;
                                        childLinesToAdd.add(childLine);
                                        nextTMLineNo++;

                                        mapTMChildLinesByResourceId.put(childResourceId, childLine);
                                    }
                                    else {
                                        childLine = mapTMChildLinesByResourceId.get(childResourceId);
                                    }

                                    TM_Parent_Child_Relation__c relation = new TM_Parent_Child_Relation__c();
                                    relation.Parent_Line__c = tmLine.Id; //should be null
                                    relation.Parent_Line__r = new TM_Line__c(Line_No__c = tmLine.Line_No__c);
                                    relation.Child_Line__c = childLine.Id; //should be null;
                                    relation.Child_Line__r = new TM_Line__c(Line_No__c = childLine.Line_No__c);
                                    relations.add(relation);
                                }
                                if (relations.size() > 0) {
                                    tmLines[i] = (TM_Line__c) JSONUtils.attachListToParent(tmLine, relations, 'TM_Child_Lines__r');
                                }
                            }
                        }
                    }
                }

                tmLines.addAll(childLinesToAdd);
                //ticket 19130 05.03.23 >>
                if (tmLines.size() > 0) {
                    CompanyMgmt.systemCall = false;
                    upsert tmLines;

                    //update parent child relations
                    Map<Integer, TM_Line__c> mapTMLinesByLineNo = new Map<Integer, TM_Line__c>();
                    for (TM_Line__c tmLine : tmLines) {
                        if (mapTMLinesByLineNo.containsKey(tmLine.Line_No__c.intValue())) {
                            throw new DataException('Duplicate T&M Line No. detected: ' + tmLine.Line_No__c.intValue());
                        }
                        mapTMLinesByLineNo.put(tmLine.Line_No__c.intValue(), tmLine);
                    }

                    //ticket 19130 05.03.23 <<
                    for (Map<Id, TM_Line__c> mapTMLinesByResourceId : mapTMLinesByResourceIdByJobTaskId.values()) {
                        for (TM_Line__c tmLine : mapTMLinesByResourceId.values()) {
                            if (!mapTMLinesByLineNo.containsKey(tmLine.Line_No__c.intValue())) {
                                mapTMLinesByLineNo.put(tmLine.Line_No__c.intValue(), tmLine);
                            }
                        }
                    }
                    //ticket 19130 05.03.23 >>
                    List<TM_Parent_Child_Relation__c> relationsToInsert = new List<TM_Parent_Child_Relation__c>();
                    for (TM_Line__c tmLine : tmLines) {
                        if (tmLine.TM_Child_Lines__r != null) {
                            for (TM_Parent_Child_Relation__c relation : tmLine.TM_Child_Lines__r) {
                                TM_Line__c childTMLine = mapTMLinesByLineNo.get(relation.Child_Line__r.Line_No__c.intValue());

                                relation.Parent_Line__c = tmLine.Id;
                                relation.Parent_Line__r.Id = tmLine.Id;
                                relation.Child_Line__c = childTMLine.Id;
                                relation.Child_Line__r.Id = childTMLine.Id;
                                relationsToInsert.add(relation);
                            }
                        }
                    }
                    insert relationsToInsert;
                }
            }
            //deleted lines <<
            return getTMLines(tm.Id, category);
            //deleted lines >>
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void SaveTMHeader(String JSONTM) {
        try {
            TM__c tm = (TM__c)JSON.deserialize(JSONTM, TM__c.class);
            update tm;
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void SaveTMAndLines(String JSONTM, String JSONJobTaskWrappers) {
        try {
            //ticket 19130 <<
            /*
            TMBaseController.SaveTMAndLines(JSONTM, JSONJobTaskWrappers);
            */
            Savepoint sp = Database.setSavepoint();
            try {
                TM__c tm = (TM__c)JSON.deserialize(JSONTM, TM__c.class);
                List<ACVTMJobTaskWrapper> jobTaskWrappers = (List<ACVTMJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVTMJobTaskWrapper>.class);
                upsert tm;

                List<TM_Line__c> tmLines = TMBaseController.initTMLinesFromWrapper(tm, jobTaskWrappers);

                if (tmLines.size() > 0) {
                    upsert tmLines;
                }

                Map<Integer, TM_Line__c> mapTMLinesByLineNo = new Map<Integer, TM_Line__c>();
                for (TM_Line__c tmLine : tmLines) {
                    mapTMLinesByLineNo.put(tmLine.Line_No__c.intValue(), tmLine);
                }

                List<Id> relationToDeleteIds = new List<Id>();
                Map<String, TM_Parent_Child_Relation__c> mapParentChildRelationsByKey = new Map<String, TM_Parent_Child_Relation__c>();
                for (TM_Parent_Child_Relation__c relation : [SELECT Id, Parent_Line__c, Child_Line__c FROM TM_Parent_Child_Relation__c WHERE Parent_Line__r.TM__c = :tm.Id]) {
                    String key = relation.Parent_Line__c + ';' + relation.Child_Line__c;
                    if (!mapParentChildRelationsByKey.containsKey(key)) {
                        mapParentChildRelationsByKey.put(key, relation);
                    }
                    else {
                        relationToDeleteIds.add(relation.Id); //duplicated parent-child
                    }
                }

                Map<String, TM_Parent_Child_Relation__c> mapRelationsToUpsertByKey = new Map<String, TM_Parent_Child_Relation__c>();
                for (TM_Line__c tmLine : tmLines) {
                    if (tmLine.TM_Child_Lines__r != null && tmLine.TM_Child_Lines__r.size() > 0) {
                        for (TM_Parent_Child_Relation__c relation : tmLine.TM_Child_Lines__r) {
                            TM_Line__c parentLine = mapTMLinesByLineNo.get(relation.Parent_Line__r.Line_No__c.intValue());
                            TM_Line__c childLine = mapTMLinesByLineNo.get(relation.Child_Line__r.Line_No__c.intValue());
                            if (childLine == null) {
                                throw new DataException('Line #' + parentLine.Line_No__c + ': child relation is null, child line #' + relation.Child_Line__r.Line_No__c );
                            }
                            String key = parentLine.Id + ';' + childLine.Id;
                            TM_Parent_Child_Relation__c relationToUpsert = new TM_Parent_Child_Relation__c();
                            if (mapParentChildRelationsByKey.containsKey(key)) {
                                relationToUpsert.Id = mapParentChildRelationsByKey.get(key).Id;
                                mapParentChildRelationsByKey.remove(key);
                            } else {
                                relationToUpsert.Parent_Line__c = parentLine.Id;
                                relationToUpsert.Parent_Line__r = new TM_Line__c(Id = parentLine.Id);
                            }
                            relationToUpsert.Child_Line__c = childLine.Id;
                            relationToUpsert.Child_Line__r = new TM_Line__c(Id = childLine.Id);

                            if (!mapParentChildRelationsByKey.containsKey(key)) {
                                mapRelationsToUpsertByKey.put(key, relationToUpsert);
                            }
                            else {
                                throw new DataException('Parent child relationship already exists: ' + key);
                            }
                        }
                    }
                }
                upsert mapRelationsToUpsertByKey.values();

                for (TM_Parent_Child_Relation__c relation : mapParentChildRelationsByKey.values()) {
                    relationToDeleteIds.add(relation.Id);
                }
                if (relationToDeleteIds.size() > 0) {
                    delete [SELECT Id FROM TM_Parent_Child_Relation__c WHERE Id IN :relationToDeleteIds];
                }
            }
            catch(exception ex) {
                Database.rollback(sp);
                throw ex;
            }
            //ticket 19130 >>
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String changeToScheduled(Id tmId) {
        Savepoint sp = Database.setSavepoint();
        try {
            TM__c tm = [SELECT Id, Status__c FROM TM__c WHERE Id = :tmId];
            if (tm.Status__c == 'Mobile Review') {
                tm.Status__c = 'Scheduled';
                update tm;
                return getTM(tm.Id);
            }
            else {
                throw new DataException('You can only change status from Mobile Review to Scheduled.');
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage());
        }
    }


    @AuraEnabled
    public static void processPDF(Id tmId) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<TM__c> tms = [SELECT Name, Bill_to_Customer__r.Requires_2_Signatures_on_TM__c, Status__c, Mobile_TM__c,
                    Field_TM_PDF_Saved__c, Field_TM_PDF_Sent__c, Field_TM_PDF_Recipient__c, Mobile_First_Save_At__c,
                    Accept_Terms_and_Conditions__c, Customer_Not_Available__c FROM TM__c WHERE Id = :tmId];

            if (tms.size() == 0) {
                throw new DataException('TM ' + tmId + ' is not found.');
            }
            TM__c tm = tms[0];

            List<Signature__c> signed = new List<Signature__c>();
            List<Signature__c> requests = new List<Signature__c>();
            List<Signature__c> unavailable = new List<Signature__c>();
            Boolean acceptTermsAndConditions = false;

            Integer signaturesNeeded = 1;
            if (tm.Bill_to_Customer__r.Requires_2_Signatures_on_TM__c == true) {
                signaturesNeeded = 2;
            }
            
            List<Signature__c> signatures = SignaturesSelector.newInstance().selectByRoles(new Set<Id>{ tm.Id }, new List<String>{ 'Customer A', 'Customer B' });
            for (Signature__c signature : signatures) {
                if (signature.Signed__c == true) {
                    signed.add(signature);
                } else if (signature.Request_Signature__c == true) {
                    requests.add(signature);
                } else if (signature.Customer_Not_Available__c == true) {
                    unavailable.add(signature);
                }

                if (signature.Accept_Terms_and_Conditions__c == true) {
                    acceptTermsAndConditions = true;
                }
            }

            //ticket 21113 <<
            Blob pdf = GenerateFieldTMPDF(tm.Id);
            //ticket 29960 >>
            //SaveFieldTMPDF(tm, pdf);
            String filename = tm.Name + ' ' + System.now().format('yyyy_MM_dd_hh_mm_ss');
            if (signed.size() > 0) {
                filename += '_Signed';
            }
            filename += '.pdf';
            SaveFieldTMPDF(tm, pdf, filename);
            //ticket 29960 >>
            //ticket 21113 >>

            Id mobileReviewRecordTypeId = Schema.SObjectType.TM__c.getRecordTypeInfosByName().get('Mobile Review').getRecordTypeId();
            //if (requests.size() + unavailable.size() > 0) {
            if (requests.size() > 0) {
                if (requests.size() > 0) {
                    sendSignatureRequestEmail(tm, signatures, pdf);
                    tm.Signature_Request_Pending__c = true;
                }
                /* disabled --> this is not for live yet
                if (unavailable.size() > 0) {
                    createRequestSignatureTask(unavailable);
                }
                */
                if (tm.Status__c == 'Scheduled') {
                    tm.Status__c = 'Mobile Review';
                    tm.RecordTypeId = mobileReviewRecordTypeId;
                    tm.Mobile_TM__c = true;
                    if(tm.Mobile_First_Save_At__c == null){
                        tm.Mobile_First_Save_At__c = System.now();
                    }
                }

                update tm;
            }
            //new signature request changes >>
            else {
                processFieldTMPDF(tm, signatures);
                
                tm.Accept_Terms_and_Conditions__c = acceptTermsAndConditions;
                if (tm.Status__c == 'Scheduled') {
                    tm.Status__c = 'Mobile Review';
                    tm.RecordTypeId = mobileReviewRecordTypeId;
                    tm.Mobile_TM__c = true;
                    if(tm.Mobile_First_Save_At__c == null){
                        tm.Mobile_First_Save_At__c = System.now();
                    }
                    update tm;
                }
            }
        }
        catch(Exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //ticket 21113 <<
    //public static void sendSignatureRequestEmail(TM__c tm, List<Signature__c> signatures) {
    public static void sendSignatureRequestEmail(TM__c tm, List<Signature__c> signatures, Blob pdf) {
    //ticket 21113 >>
        Savepoint sp = Database.setSavepoint();
        try {
            if (getEmailDeliverability() != true) return;

            Set<Id> signatureIds = new Set<Id>();
            for (Signature__c signature : signatures) {
                signatureIds.add(signature.Id);
            }

            List<Signature__c> signaturesToRequest = [SELECT Id, Signature_Request__c,  Signer_Role__c, Email__c, Print_Name__c FROM Signature__c WHERE TM__c = :tm.Id AND Voided__c != TRUE
            AND Request_Signature__c = TRUE AND Signature_Request_Email_Sent__c != TRUE AND Signature_Request__r.Signed__c != TRUE];

            if (signaturesToRequest.size() > 0) {
                List<EmailTemplate> emailTemplates = [SELECT Id FROM EmailTemplate WHERE Name = 'T&M Signature Request Email'];
                if (emailTemplates.size() == 0) {
                    throw new DataException('Email template "T&M Signature Request Email" must be set up to send signature requests.');
                }
                Id emailTemplateId = emailTemplates[0].Id;

                //ticket 21113 <<
                /*
                Blob pdf = generateFieldTMPDF(tm.Id);

                //save attachment
                String filename = tm.Name + '_signature_request.pdf';
                List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :tm.Id AND Name = :filename];
                Attachment attachment;
                if (attachments.size() > 0) {
                    attachment = attachments[0];
                }
                else {
                    attachment = new Attachment();
                    attachment.ParentId = tm.Id;
                    attachment.Name = filename;
                    attachment.IsPrivate = false;
                }
                attachment.body = pdf;
                upsert attachment;
                */
                //ticket 21113 >>
                
                List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
                for (Signature__c signature : signaturesToRequest) {
                    if (signature.Signature_Request__c == null) {
                        SignatureWrapper signatureWrapper = SignaturePadController.getSignatureWrapper(tm.Id, signature.Signer_Role__c);
                        Signature_Request__c signatureRequest = SignaturePadController.requestSignature(signatureWrapper);
                        signature.Signature_Request__c = signatureRequest.Id;
                        update signature;
                    }

                    List<String> recipients = new List<String>{ signature.Email__c };
                    if (testRecipients(recipients) == true) {
                        messages.add(createEmail(signature.Id, emailTemplateId, recipients, tm.Name, pdf));
                    }
                }

                if (messages.size() > 0) {
                    List<Signature_Request__c> signatureRequestsToUpdate = new List<Signature_Request__c>();
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                    for (Integer i = 0; i < results.size(); i++) {
                        if (results[i].success == true) {
                            Signature__c signature = signaturesToRequest[i];
                            Signature_Request__c signatureRequest = new Signature_Request__c(Id = signature.Signature_Request__c);
                            signatureRequest.Request_Date__c = Datetime.now();
                            signatureRequest.Request_Email_Sent__c = true;
                            signatureRequest.Request_Date__c = Datetime.now();
                            signatureRequestsToUpdate.add(signatureRequest);
                        }
                    }
                    update signatureRequestsToUpdate;
                }
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    public static void processFieldTMPDF(TM__c tm, List<Signature__c> signatures) {
        Blob pdf = GenerateFieldTMPDF(tm.Id);

        if (tm.Field_TM_PDF_Saved__c != true) {
            //ticket 29960 >>
            //SaveFieldTMPDF(tm, pdf);
            SaveFieldTMPDF(tm, pdf, tm.Name + System.now().format('yyyyMMddhhmmss') + '.pdf');
            //ticket 29960 <<
        }

        if (getEmailDeliverability() != true) return;

        List<String> recipients = new List<String>();
        for (Signature__c signature : signatures) {
            if (signature.Email__c != null) {
                if (!recipients.contains(signature.Email__c)) {
                    recipients.add(signature.Email__c);
                }
            }
        }

        if (tm.Field_TM_PDF_Sent__c != true && recipients.size() > 0) {
            List<EmailTemplate> emailTemplates = [SELECT Id FROM EmailTemplate WHERE Name = 'T&M Field PDF Email'];
            if (emailTemplates.size() == 0) {
                throw new DataException('Email template "T&M Field PDF Email" must be set up to send the pdf to customers.');
            }
            Id emailTemplateId = emailTemplates[0].Id;
            List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
            if (testRecipients(recipients) == true) {
                messages.add(createEmail(tm.Id, emailTemplateId, recipients, tm.Name, pdf));
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                if (results.size() > 0) {
                    Messaging.SendEmailResult result = results[0];
                    if (result.success) {
                        tm.Field_TM_PDF_Sent__c = true;
                        CompanyMgmt.ByPassTrigger = true;
                        update tm;
                        CompanyMgmt.ByPassTrigger = false;
                    } else {
                        throw new DataException(String.join(result.getErrors(), ';'));
                    }
                }
            }
        }
    }
    
    //ticket 21113 <<
    public static void sendFieldTMPDF(TM__c tm, Blob pdf) {
        List<Signature__c> signatures = [SELECT Id, Email__c, Request_Signature__c, Signed__c FROM Signature__c WHERE TM__c = :tm.Id AND Voided__c != TRUE];
        //ticket 21113 >>
        if (getEmailDeliverability() == true) {
            List<String> recipients = new List<String>();
            for (Signature__c signature : signatures) {
                if (signature.Email__c != null) {
                    if (!recipients.contains(signature.Email__c)) {
                        recipients.add(signature.Email__c);
                    }
                }
            }

            if (testRecipients(recipients) == true) {
                Integer signedCount = 0;
                Integer requestCount = 0;
                for (Signature__c signature : signatures) {
                    if (signature.Signed__c == true) {
                        signedCount++;
                    }
                    else if (signature.Request_Signature__c == true) {
                        requestCount++;
                    }
                }
                String emailTemplateName = 'T&M Field PDF Email';
                List<EmailTemplate> emailTemplates = [SELECT Id FROM EmailTemplate WHERE Name = :emailTemplateName];
                if (emailTemplates.size() == 0) {
                    throw new DataException('Email template "T&M Field PDF Email" must be set up to send the pdf to customers.');
                }
                //additional signature request changes >>

                Id emailTemplateId = emailTemplates[0].Id;
                List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

                messages.add(createEmail(tm.Id, emailTemplateId, recipients, tm.Name, pdf));
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                if (results.size() > 0) {
                    Messaging.SendEmailResult result = results[0];
                    if (result.success) {
                        tm.Field_TM_PDF_Sent__c = true;
                    }
                    else {
                        throw new DataException(String.join(result.getErrors(), ';'));
                    }
                }
            }
        }
    }
    //ticket 21113 >>

    private static Boolean getEmailDeliverability() {
        Boolean turnedOn = false;
        try {
            Messaging.reserveSingleEmailCapacity(0);
            turnedOn = true;
        }
        catch (System.NoAccessException e) {
        }

        return turnedOn;
    }

    public static Blob GenerateFieldTMPDF(Id tmId) {
        Blob pdf;
        if (Test.isRunningTest()) {
            pdf = Blob.valueOf('test');
        } else {
            PageReference pageRef = new PageReference('/apex/NewFieldTMPDF');
            pageRef.getParameters().put('id', tmId);
            pageRef.setRedirect(true);
            pdf = pageRef.getContentAsPDF();
        }
        //sleep for 2 seconds for PDF to generate
        Long startTime = DateTime.now().getTime();
        Long finishTime = DateTime.now().getTime();
        while ((finishTime - startTime) < 2000) {
            finishTime = DateTime.now().getTime();
        }
        return pdf;
    }
    //signature request

  
    //ticket 29960 >>
    //public static void SaveFieldTMPDF(TM__c tm, Blob pdf) {
    public static void SaveFieldTMPDF(TM__c tm, Blob pdf, String filename) {
    //ticket 29960 <<
        Savepoint sp = Database.setSavepoint();
        try {
            Attachment attachment;
            //ticket 29960 >>
            //String filename = tm.Name + '_signature_request.pdf';
            //ticket 29960 <<
            List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :tm.Id AND Name = :filename];
            if (attachments.size() > 0) {
                attachment = attachments[0];
            }
            else {
                attachment = new Attachment(ParentId = tm.Id, IsPrivate = false, Name = filename);
            }
            attachment.body = pdf;
            //ticket 29960 >>
            //attachment.Name = tm.Name + ' ' + System.now().format('yyyy_MM_dd_hh_mm_ss') + '.pdf';
            attachment.Name = filename;
            //ticket 29960 <<
            upsert attachment;

            tm.Field_TM_PDF_Saved__c = true;
            CompanyMgmt.ByPassTrigger = true;
            update tm;
            CompanyMgmt.ByPassTrigger = false;
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }
    //signature request >>

    public static Boolean testRecipients(List<String> recipients) {
        //additional signature request changes <<
        if (recipients.size() == 0) {
            return false;
        }
        //additional signature request changes >>

        Boolean ok = true;

        Id prodOrgId = '00Df40000000Ns9';
        List<String> allowedSandboxRecipients = new List<String>();
        allowedSandboxRecipients.add('swang@micro-datanet.com');
        allowedSandboxRecipients.add('swang@goldfinchcloudsolutions.com');
        allowedSandboxRecipients.add('kchen@micro-datanet.com');
        allowedSandboxRecipients.add('kchen@goldfinchcloudsolutions.com');
        allowedSandboxRecipients.add('dscerbo@acvenviro.com');
        allowedSandboxRecipients.add('jmarcotte@acvenviro.com');
        allowedSandboxRecipients.add('rvandra@acvenviro.com');
        allowedSandboxRecipients.add('mrooney@acvenviro.com');
        allowedSandboxRecipients.add('mbrajer@acvenviro.com');
        allowedSandboxRecipients.add('ssheppard@acvenviro.com');

         if(Test.isRunningTest())
            return ok;
        if (!userInfo.getOrganizationId().contains(prodOrgId)) {
            for (String recipient : recipients) {
                if (!allowedSandboxRecipients.contains(recipient.toLowerCase())) {
                    ok = false;
                    break;
                }
            }
        }

        return ok;
    }

    public static Messaging.SingleEmailMessage createEmail(Id whatId, Id emailTemplateId, List<String> recipients, String filename, Blob pdf) {
        OrgWideEmailAddress orgWideEmailAddr = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Republic Services' LIMIT 1]; //Ticket#25097

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setWhatId(whatId);
        message.setToAddresses(recipients);
        message.setTreatTargetObjectAsRecipient(true);
        message.setOrgWideEmailAddressId(orgWideEmailAddr.Id);
        message.setTemplateId(emailTemplateId);

        //generate email subject and body from the template
        Savepoint sp = Database.setSavepoint();
        Contact contact = new Contact(LastName='DummyContact');
        contact.Contact_Type__c = 'Site';
        contact.Email = 'dummyemail@fromdummycontact.com';
        insert contact;
        message.setTargetObjectId(contact.Id);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ message });
        Database.rollback(sp);

        //create a message utilizing the email subject and body
        Messaging.SingleEmailMessage messageToSend = new Messaging.SingleEmailMessage();
        messageToSend.setOrgWideEmailAddressId(message.getOrgWideEmailAddressId());
        messageToSend.setToAddresses(message.getToAddresses());
        messageToSend.setPlainTextBody(message.getPlainTextBody());
        messageToSend.setHtmlBody(message.getHtmlBody());
        messageToSend.setSubject(message.getSubject());
        messageToSend.setWhatId(message.getWhatId());
        messageToSend.setSaveAsActivity(true);

        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(filename + '.pdf');
        attachment.setBody(pdf);
        messageToSend.setFileAttachments(new Messaging.EmailFileAttachment[]{ attachment });

        return messageToSend;
    }
    //signature request >>


    public static List<String> getTMFields() {
        List<String> fields = new List<String>();
        fields.add('Id');
        fields.add('Name');
        fields.add('Scheduled_Date__c');
        fields.add('Status__c');
        fields.add('Customer_Po_No__c');
        fields.add('Service_Center__c');
        fields.add('Service_Center__r.Name');
        fields.add('Sales_Order__c');
        fields.add('Sales_Order__r.Name');
        fields.add('Sales_Order__r.Sales_Order_Type__r.Name');
        fields.add('Sales_Order__r.Sales_Order_Type__r.Description__c');
        fields.add('Sales_Order__r.Sales_Order_Type__r.Job_Task_Template__c');
        fields.add('Contact__c');
        fields.add('Contact__r.LastName');
        fields.add('Contact__r.FirstName');
        fields.add('Contact__r.Name');
        fields.add('Site_Contact_2__c');
        fields.add('Site_Contact_2__r.Name');
        fields.add('Bill_to_Customer__c');
        fields.add('Bill_to_Customer__r.Name');
        fields.add('Bill_to_Customer__r.BillingStreet');
        fields.add('Bill_to_Customer__r.BillingCity');
        fields.add('Bill_to_Customer__r.BillingStateCode');
        fields.add('Bill_to_Customer__r.BillingPostalCode');
        fields.add('Bill_to_Customer__r.BillingCountryCode');
        fields.add('Bill_to_Customer__r.Requires_2_Signatures_on_TM__c');
        fields.add('Bill_to_Customer__r.Contact_Type_Filter__c'); //Ticket#21357
        fields.add('Site_Name__c');
        fields.add('Site_Street__c');
        fields.add('Site_City__c');
        fields.add('Site_State__c');
        fields.add('Site_Postal_Code__c');
        fields.add('Site_Country__c');
        fields.add('Site_Phone_No__c');
        fields.add('Site_Email_Address__c');
        fields.add('Site_Scope__c');
        fields.add('Customer_Comments__c');
        fields.add('Mobile_TM__c');
        fields.add('Emergency_TM__c');
        fields.add('Job_Complete__c');
        fields.add('Field_TM_PDF_Sent__c');
        fields.add('Field_TM_PDF_Saved__c');
        fields.add('Field_TM_PDF_Recipient__c');
        fields.add('Mobile_First_Save_At__c');
        fields.add('Display_Company_Name__c'); //Ticket#21540
        fields.add('Service_Center__r.Advanced_Disposal__c'); // US128845
        fields.add('D365_Project_ID__c');//US140219
        return fields;
    }
    
@AuraEnabled
public static List<String> getValidBillUnitCode(String billUnitCode) {
    System.debug(billUnitCode);
   List<String> validUOMs = new List<String>();
        
        if (String.isNotBlank(billUnitCode)) {
            List<Sales_Line_EQAI_Mapping__mdt> mappings = [
                SELECT Salesforce_Field_Value__c 
                FROM Sales_Line_EQAI_Mapping__mdt
                WHERE EQAI_Field_Value__c = :billUnitCode
            ];
            
            for (Sales_Line_EQAI_Mapping__mdt mapping : mappings) {
                validUOMs.add(mapping.Salesforce_Field_Value__c);
            }
        }
        system.debug('validUOMs'+validUOMs);
        return validUOMs;
    }

}