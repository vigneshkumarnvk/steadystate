/*************************************************************************************************
* Name         :  ACVTMController
* Description  :  T&M Creation
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
  Shahwaz Khan              02-20-2024             78352: Salesforce - When Choosing Facility on SQ vs SO
  Shahwaz Khan              03-11-2024             Bug80870:3rd Party Restriction Impact on Group B Service Centers
  Andrew Simons             06-12-2024             Salesforce - added method for retrieving resource custom metadata
  Shahwaz Khan              08-20-2024             US115867:Salesforce - Un-invoiced reason code picklist.
*************************************************************************************************/
public with sharing class ACVTMController {
    public static Company_Setup__c defaultCompanySetup;

    @AuraEnabled
    public static String getVariables() {
        try {
            Map<String, Object> setupData = new Map<String, Object>();
            User user = [SELECT Id, Name, Username, Super_User__c, Service_Center__c, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
            Service_Center__c serviceCenter = new Service_Center__c();
            for (Service_Center__c sc : [SELECT Id, Name, Description__c, Subsidiary_Company__c, Subsidiary_Company__r.Name, Temporary__c FROM Service_Center__c WHERE Name = :user.Service_Center__c OR Temporary__c = TRUE]) {
                if (sc.Name == user.Service_Center__c) {
                    setupData.put('UserServiceCenter', sc);
                } 
                if (sc.Temporary__c == true) {
                    setupData.put('TemporaryServiceCenter', sc);
                }
            }
            setupData.put('User', user);
            return JSON.serialize(setupData);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String getSalesOrder(Id salesOrderId, Id salesOrderJobTaskId) {
        try {
            List<Sales_Order__c> salesOrders = SalesOrdersSelector.newInstance().selectById(new Set<Id> { salesOrderId });
            Sales_Order__c salesOrder;
            if (salesOrders.size() > 0) {
                salesOrder = salesOrders[0];
            }

            if (salesOrder.Bill_to_Customer_No__c == null) {
                throw new DataException('Bill-to customer is blank.');
            }

            Set<Id> salesOrderIds = new Set<Id>();
            Set<Id> jobTaskIds = new Set<Id>();
            salesOrderIds.add(salesOrderId);
            if (salesOrderJobTaskId != null) {
                jobTaskIds.add(salesOrderJobTaskId);
            }
            List<Sales_Order_Job_Task__c> jobTasks = SalesOrderJobTasksSelector.newInstance().selectByJobTaskId(salesOrderIds, jobTaskIds);
            List<Sales_Line__c> salesLines = SalesLinesSelector.newInstance().selectLinesByJobTaskId(salesOrderIds, jobTaskIds);

            //remove system created misc. charge lines and manifest fee lines
            for (Integer i = 0; i < salesLines.size(); i++) {
                if (salesLines[i].System_Calculated_Line__c == true) {
                    salesLines.remove(i);
                    i--;
                }
            }

            ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(salesOrder, jobTasks, salesLines);
            return JSON.serialize(salesOrderWrapper);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String getSalesOrderJobTasks(Id salesOrderId) {
        try {
            Sales_Order__c salesOrder = [SELECT Id, Name FROM Sales_Order__c WHERE Id = :salesOrderId LIMIT 1];
            List<Sales_Order_Job_Task__c> salesOrderJobTasks = [SELECT Id, Name, Task_No__c FROM Sales_Order_Job_Task__c WHERE Sales_Order__c = :salesOrderId];

            return '{"SalesOrder":' + JSON.serialize(salesOrder) + ', "JobTasks":' + JSON.serialize(salesOrderJobTasks) + '}';
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
    public static String getCostPlusMESResourceId() {
        ResourceConfig__mdt config = [SELECT Value__c FROM ResourceConfig__mdt WHERE DeveloperName = 'CostPlusMESResourceId' LIMIT 1];
        return config.Value__c;
    }

    /*
    @AuraEnabled
    public static String getSalesOrderJobTask(Id salesOrderId, Id jobTaskId) {
        try {
            List<Sales_Order_Job_Task__c> jobTasks = SalesOrderJobTasksSelector.newInstance().selectById(new Set<Id>{ jobTaskId });
            List<Sales_Line__c> salesLines = SalesLinesSelector.newInstance().selectLinesByJobTaskId(salesOrderId, new Set<Id>{ jobTaskId });

            //remove system created misc. charge lines and manifest fee lines
            for (Integer i = 0; i < salesLines.size(); i++) {
                if (((salesLines[i].Category__c == 'Misc. Charges And Taxes' || salesLines[i].Category__c == 'Waste Disposal')
                        && salesLines[i].System_Calculated_Line__c == true) || salesLines[i].Category__c == 'Lump Sum') {
                    salesLines.remove(i);
                    i--;
                }
            }

            ACVSalesOrderJobTaskWrapper jobTaskWrapper = new ACVSalesOrderJobTaskWrapper(jobTasks[0], salesLines);
            return JSON.serialize(jobTaskWrapper);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }*/

    @AuraEnabled
    public static String getTM(Id tmId) {
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

            return JSON.serialize(tmWrapper);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static Id createTMFromSalesOrder(Id salesOrderId, String JSONSalesOrderJobTaskWrappers) {
        try {
            List<ACVSalesOrderJobTaskWrapper> salesOrderJobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONSalesOrderJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);

            ACVTMWrapper tmWrapper = TMsService.createTMFromSalesOrder(salesOrderId, salesOrderJobTaskWrappers);

            TM__c tm = tmWrapper.TM;
            List<ACVTMJobTaskWrapper> jobTaskWrappers = tmWrapper.JobTaskWrappers;
            Integer nextTMLineNo = getNextTMLineNo(jobTaskWrappers);

            //calculate manifest fee line/rinse out line
            calculateTM(tm, jobTaskWrappers, nextTMLineNo);

            saveTM(tm, jobTaskWrappers);
            return tm.Id;
        }
        catch(exception ex) {
                        system.debug('ex'+ex.getMessage());
		String errorMessage = ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')? ex.getMessage().substring( ex.getMessage().indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 'FIELD_CUSTOM_VALIDATION_EXCEPTION,'.length()): ex.getMessage();
		throw new AuraHandledException(errorMessage);
        }
    }

    @AuraEnabled
    //ticket 19130 <<
    //public static String createTMJobTasksFromSalesOrder(String JSONTM, String JSONSalesOrderJobTaskWrappers, Integer nextJobTaskLineNo, Integer nextTMLineNo) {
    public static String createTMJobTasksFromSalesOrder(String JSONTM, String JSONTMJobTaskWrappers, String JSONSalesOrderJobTaskWrappers, Integer nextJobTaskLineNo, Integer nextTMLineNo) {
        //ticket 19130 >>
        try {
            TM__c tm = (TM__c)JSON.deserialize(JSONTM, TM__c.class);
            //ticket 19130 <<
            List<ACVTMJobTaskWrapper> tmJobTaskWrappers = (List<ACVTMJobTaskWrapper>)JSON.deserialize(JSONTMJobTaskWrappers, List<ACVTMJobTaskWrapper>.class);
            //ticket 19130 >>
            List<ACVSalesOrderJobTaskWrapper> salesOrderJobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONSalesOrderJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);

            if (tm.Sales_Order__c == null) {
                throw new DataException('Sales order must not be blank on the T&M.');
            }

            List<Sales_Order__c> salesOrders = SalesOrdersSelector.newInstance().selectById(new Set<Id>{ tm.Sales_Order__c });
            Sales_Order__c salesOrder = salesOrders[0];

            //ticket 19130 <<
            //List<ACVTMJobTaskWrapper> jobTaskWrappers = TMsService.createTMJobTasksFromSalesOrder(salesOrder, salesOrderJobTaskWrappers, tm, nextJobTaskLineNo, nextTMLineNo);
            List<ACVTMJobTaskWrapper> jobTaskWrappers = TMsService.createTMJobTasksFromSalesOrder(salesOrder, salesOrderJobTaskWrappers, tm, tmJobTaskWrappers, nextJobTaskLineNo, nextTMLineNo);
            //ticket 19130 >>
            Integer nextTMLineNo2 = getNextTMLineNo(jobTaskWrappers);
            if (nextTMLineNo < nextTMLineNo2) { //nextTMLineNo can be bigger than nextTMLineNo2 if TM has multiple job tasks
                nextTMLineNo = nextTMLineNo2;
            }

            //calculate manifest fee line/rinse out line
            calculateTM(tm, jobTaskWrappers, nextTMLineNo);

            return JSON.serialize(jobTaskWrappers);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String createTMLinesFromSalesOrder(String JSONSalesOrderJobTaskWrapper, String JSONTM, String JSONTMJobTaskWrapper, Integer nextJobTaskLineNo, Integer nextTMLineNo) {
        try {
            TM__c tm = (TM__c)JSON.deserialize(JSONTM, TM__c.class);
            ACVSalesOrderJobTaskWrapper salesOrderJobTaskWrapper = (ACVSalesOrderJobTaskWrapper)JSON.deserialize(JSONSalesOrderJobTaskWrapper, ACVSalesOrderJobTaskWrapper.class);
            ACVTMJobTaskWrapper tmJobTaskWrapper = (ACVTMJobTaskWrapper)JSON.deserialize(JSONTMJobTaskWrapper, ACVTMJobTaskWrapper.class);

            if (tm.Sales_Order__c == null) {
                throw new DataException('Sales order must not be blank on the T&M.');
            }

            List<Sales_Order__c> salesOrders = SalesOrdersSelector.newInstance().selectById(new Set<Id>{ tm.Sales_Order__c });
            Sales_Order__c salesOrder = salesOrders[0];

            TMsService.createTMLinesFromSalesOrder(salesOrder, salesOrderJobTaskWrapper, tm, tmJobTaskWrapper, nextTMLineNo);
            Integer nextTMLineNo2 = getNextTMLineNo(new List<ACVTMJobTaskWrapper> { tmJobTaskWrapper });
            if (nextTMLineNo < nextTMLineNo2) { //nextTMLineNo can be bigger than nextTMLineNo2 if TM has multiple job tasks
                nextTMLineNo = nextTMLineNo2;
            }
            //calculate manifest fee line/rinse out line

            calculateTM(tm, tmJobTaskWrapper, nextTMLineNo);

            return JSON.serialize(tmJobTaskWrapper);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String calculateTMJobTasks(String JSONTM, String JSONJobTaskWrappers) {
        try {
            TM__c tm = (TM__c)JSON.deserialize(JSONTM, TM__c.class);
            List<ACVTMJobTaskWrapper> jobTaskWrappers = (List<ACVTMJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVTMJobTaskWrapper>.class);

            Integer nextTMLineNo = 0;
            for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                    if (tmLine.Line_No__c.intValue() > nextTMLineNo) {
                        nextTMLineNo = tmLine.Line_No__c.intValue();
                    }
                }
            }
            nextTMLineNo++;

            calculateTM(tm, jobTaskWrappers, nextTMLineNo);

            return JSON.serialize(jobTaskWrappers);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String calculateTMJobTask(String JSONTM, String JSONJobTaskWrapper, Integer nextTMLineNo) {
        try {
            TM__c tm = (TM__c)JSON.deserialize(JSONTM, TM__c.class);
            ACVTMJobTaskWrapper jobTaskWrapper = (ACVTMJobTaskWrapper)JSON.deserialize(JSONJobTaskWrapper, ACVTMJobTaskWrapper.class);

            List<ACVTMJobTaskWrapper> jobTaskWrappers = new List<ACVTMJobTaskWrapper>{ jobTaskWrapper };
            calculateTM(tm, jobTaskWrappers, nextTMLineNo);
            jobTaskWrapper = jobTaskWrappers[0];
            return JSON.serialize(jobTaskWrapper);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static void calculateTM(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper, Integer nextTMLineNo) {
        List<ACVTMJobTaskWrapper> jobTaskWrappers = new List<ACVTMJobTaskWrapper>{ jobTaskWrapper };
        calculateTM(tm, jobTaskWrappers, nextTMLineNo);
        jobTaskWrapper = jobTaskWrappers[0];
    }

    private static void calculateTM(TM__c tm, List<ACVTMJobTaskWrapper> jobTaskWrappers, Integer nextTMLineNo) {

        TMLLinesService.initStaticVariables(tm, jobTaskWrappers);

        //create flat pay lines - move to front end
        /*
        for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            TMLLinesService.createFlatPayLines(tm, jobTaskWrapper, nextTMLineNo);
            nextTMLineNo = getNextTMLineNo(jobTaskWrappers);
        }*/

        //create safety plan line for first TM
        for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            //duplicated safety plan line issue <<
            //TMLLinesService.createSafetyPlanLine(tm, jobTaskWrapper, nextTMLineNo);
            //nextTMLineNo = getNextTMLineNo(jobTaskWrappers);
            Integer lineCount = jobTaskWrapper.TMLines.size();
            TMLLinesService.createSafetyPlanLine(tm, jobTaskWrapper, nextTMLineNo);
            if (jobTaskWrapper.TMLines.size() > lineCount) {
                nextTMLineNo = getNextTMLineNo(jobTaskWrappers);
                break;
            }
            //duplicated safety plan line issue >>

        }

        for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            TMLLinesService.calculateManifestFeeLine(tm, jobTaskWrapper, nextTMLineNo);
            nextTMLineNo = getNextTMLineNo(jobTaskWrappers);
        }

        for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            TMLLinesService.calculateRinseOutFeeLine(tm, jobTaskWrapper, nextTMLineNo);
            nextTMLineNo = getNextTMLineNo(jobTaskWrappers);
        }
    }

    @AuraEnabled
    //ticket 19674 <<
    //public static String validateSalesOrder(String JSONTM) {
    public static String validateSalesOrder(String JSONTM, String JSONJobTaskWrappers) {
        //ticket 19674 >>
        Savepoint sp = Database.setSavepoint();
        try {
            TM__c tm = (TM__c)JSON.deserialize(JSONTM, TM__c.class);
            //ticket 19674 <<
            List<ACVTMJobTaskWrapper> jobTaskWrappers = (List<ACVTMJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVTMJobTaskWrapper>.class);
            //ticket 19674 >>

            List<Sales_Order__c> salesOrders = [SELECT Id, Name, Bill_to_Customer_No__c, Bill_to_Customer_No__r.Name, Site_City__c, Site_Contact__c,
                    Sales_Order_Type__c, Sales_Order_Type__r.Job_Task_Template__c, Emergency_Sales_Order__c,Bill_to_Contact__c,
                    Site_Country__c, Site_Email_Address__c, Site_Name__c, Site_Phone_No__c, Contract__c, Contract__r.Name, Contract__r.ContractNumber,
                    From_Sales_Quote__c, From_Sales_Quote__r.Name, Site_Postal_Code__c, Site_Scope__c, Site_State__c, Site_Street__c, Customer_PO_No__c,
                    Alternate_Site_Address__c, Alternate_Site_Address__r.Name, Site_Contact_2__c, Site_Contact_2__r.Name,
                    Service_Center__c, Service_Center__r.Name, Service_Center__r.Equipment_Fleet_No_Not_Required__c,
                    Subsidiary_Company__c, Subsidiary_Company__r.Name,Contract__r.EndDate, Contract__r.Status
            FROM Sales_Order__c
            WHERE Id = :tm.Sales_Order__c
            ];

            if (salesOrders.size() > 0) {
                Sales_Order__c salesOrder = salesOrders[0];

                //Ticket#20749
                if(tm.Scheduled_Date__c != null && salesOrder.Contract__c != null){
                    if (salesOrder.Contract__r.Status != 'Activated') {
                        throw new DataException('Contract associated with sales order is not activated.');
                    }
                    if (tm.Scheduled_Date__c > salesOrder.Contract__r.EndDate){
                        throw new DataException('Contract linked with sales order expired on ' + salesOrder.Contract__r.EndDate);
                    }
                }

                tm.Sales_Order__r = new Sales_Order__c(Id = salesOrder.Id, Name = salesOrder.Name, Sales_Order_Type__c = salesOrder.Sales_Order_Type__c, Sales_Order_Type__r = salesOrder.Sales_Order_Type__r);
                tm.Contract__c = salesOrder.Contract__c;
                tm.Contract__r = salesOrder.Contract__r;
                tm.From_Sales_Quote__c = salesOrder.From_Sales_Quote__c;
                tm.From_Sales_Quote__r = salesOrder.From_Sales_Quote__r;
                tm.Bill_to_Customer__c = salesOrder.Bill_to_Customer_No__c;
                tm.Bill_to_Customer__r = salesOrder.Bill_to_Customer_No__r;
                tm.Contact__c = salesOrder.Bill_to_Contact__c;
                tm.Service_Center__c = salesOrder.Service_Center__c;
                tm.Service_Center__r = salesOrder.Service_Center__r;
                tm.Subsidiary_Company__c = salesOrder.Subsidiary_Company__c;
                tm.Subsidiary_Company__r = salesOrder.Subsidiary_Company__r;
                tm.Alternate_Site_Address__c = salesOrder.Alternate_Site_Address__c;
                tm.Alternate_Site_Address__r = salesOrder.Alternate_Site_Address__r;
                tm.Site_City__c = salesOrder.Site_City__c;
                tm.Site_Contact__c = salesOrder.Site_Contact__c;
                tm.Site_Contact_2__c = salesOrder.Site_Contact_2__c;
                tm.Site_Contact_2__r = salesOrder.Site_Contact_2__r;
                tm.Site_Country__c = salesOrder.Site_Country__c;
                tm.Site_Email_Address__c = salesOrder.Site_Email_Address__c;
                tm.Site_Name__c = salesOrder.Site_Name__c;
                tm.Site_Phone_No__c = salesOrder.Site_Phone_No__c;
                tm.Site_Postal_Code__c = salesOrder.Site_Postal_Code__c;
                tm.Site_Scope__c = salesOrder.Site_Scope__c;
                tm.Site_State__c = salesOrder.Site_State__c;
                tm.Site_Street__c = salesOrder.Site_Street__c;
                tm.Customer_PO_No__c = salesOrder.Customer_PO_No__c;
            }

            //ticket 19674 <<
            //return JSON.serialize(tm);
            Integer nextTMLineNo = getNextTMLineNo(jobTaskWrappers);
            calculateTM(tm, jobTaskWrappers, nextTMLineNo);

            ACVTMWrapper tmWrapper = new ACVTMWrapper(tm, jobTaskWrappers);
            return JSON.serialize(tmWrapper);
            //ticket 19674 >>
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*
    @AuraEnabled
    public static String validateResourceType(String JSONTM, String JSONJobTaskWrapper, Integer nextTMLineNo) {
        try {
            TM__c tm = (TM__c)JSON.deserialize(JSONTM, TM__c.class);
            ACVTMJobTaskWrapper jobTaskWrapper = (ACVTMJobTaskWrapper)JSON.deserialize(JSONJobTaskWrapper, ACVTMJobTaskWrapper.class);

            TMLLinesService.initStaticVariables(tm, jobTaskWrapper);
            TMLLinesService.calculatePresumptiveTMLines(tm, jobTaskWrapper, nextTMLineNo);

            return JSON.serialize(jobTaskWrapper);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String validateResource(String JSONTM, String JSONJobTaskWrapper, Integer nextTMLineNo) {
        try {
            TM__c tm = (TM__c)JSON.deserialize(JSONTM, TM__c.class);
            ACVTMJobTaskWrapper jobTaskWrapper = (ACVTMJobTaskWrapper)JSON.deserialize(JSONJobTaskWrapper, ACVTMJobTaskWrapper.class);

            TMLLinesService.initStaticVariables(tm, jobTaskWrapper);
            TMLLinesService.calculatePresumptiveTMLines(tm, jobTaskWrapper, nextTMLineNo);
            return JSON.serialize(jobTaskWrapper);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }*/

    @AuraEnabled
    public static String validateResourceType(String JSONTM, String JSONTMLine) {
        try {
            TM__c tm = (TM__c) JSON.deserialize(JSONTM, TM__c.class);
            TM_Line__c tmLine = (TM_Line__c) JSON.deserialize(JSONTMLine, TM_Line__c.class);

            TMLLinesService.initStaticVariables(tm, tmLine);
            TMLLinesService.validateResourceType(tm, tmLine);
            //TMLLinesService.setDescription(tm, tmLine); //update tm line description
            return JSON.serialize(tmLine);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String validateResource(String JSONTM, String JSONTMLine) {
        try {
            TM__c tm = (TM__c) JSON.deserialize(JSONTM, TM__c.class);
            TM_Line__c tmLine = (TM_Line__c) JSON.deserialize(JSONTMLine, TM_Line__c.class);

            TMLLinesService.initStaticVariables(tm, tmLine);
            TMLLinesService.validateResource(tm, tmLine);
            //TMLLinesService.setDescription(tm, tmLine); //update tm line description
            return JSON.serialize(tmLine);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String validateUnitOfMeasure(String JSONTM, String JSONTMLine) {
        try {
            TM__c tm = (TM__c) JSON.deserialize(JSONTM, TM__c.class);
            TM_Line__c tmLine = (TM_Line__c) JSON.deserialize(JSONTMLine, TM_Line__c.class);

            TMLLinesService.initStaticVariables(tm, tmLine);
            TMLLinesService.validateUnitOfMeasure(tm, tmLine);
            //TMLLinesService.setDescription(tm, tmLine); //update tm line description
            return JSON.serialize(tmLine);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //ticket 19130 05.13.2023 <<
    /*
    @AuraEnabled
    public static String validateResourceTypeOrResource(String JSONTM, String JSONJobTask, String JSONTMLine, Integer nextTMLineNo) {
        try {
            TM__c tm = (TM__c) JSON.deserialize(JSONTM, TM__c.class);
            TM_Job_Task__c jobTask = (TM_Job_Task__c) JSON.deserialize(JSONJobTask, TM_Job_Task__c.class);
            TM_Line__c tmLine = (TM_Line__c) JSON.deserialize(JSONTMLine, TM_Line__c.class);

            TMLLinesService.initStaticVariables(tm, tmLine);
            List<TM_Line__c> childLines = TMLLinesService.calculatePresumptiveChildLines(tm, jobTask, tmLine, nextTMLineNo);

            Map<Id, TM_Line__c> mapTMChildLinesByResourceId = new Map<Id, TM_Line__c>();
            for (TM_Line__c childLine : childLines) {
                Id resourceId;
                if (childLine.Category__c == 'Labor' || childLine.Category__c == 'Equipment' || childLine.Category__c == 'Bundled') {
                    resourceId = childLine.Resource_Type__c;
                }
                else {
                    resourceId = childLine.Resource__c;
                }
                mapTMChildLinesByResourceId.put(resourceId, childLine);
                if (nextTMLineNo < childLine.Line_No__c.intValue()) {
                    nextTMLineNo = childLine.Line_No__c.intValue();
                }
            }
            nextTMLineNo++;

            Id resourceId;
            if (tmLine.Category__c == 'Labor' || tmLine.Category__c == 'Equipment' || tmLine.Category__c == 'Bundled') {
                resourceId = tmLine.Resource_Type__c;
            }
            else {
                resourceId = tmLine.Resource__c;
            }

            List<Sales_Line__c> parentSalesLines = [SELECT Id, Line_No__c, Category__c, Resource_Type__c, Resource__c, (SELECT Id, Child_Line__c, Child_Line__r.Category__c, Child_Line__r.Resource_Type__c, Child_Line__r.Resource_Type__r.Name, Child_Line__r.Resource__c, Child_Line__r.Resource__r.Name FROM Sales_Child_Lines__r) FROM Sales_Line__c WHERE Sales_Order_Job_Task__c = :jobTask.Sales_Order_Job_Task__c AND (Resource_Type__c = :resourceId OR Resource__c = :resourceId) ORDER BY Line_No__c LIMIT 1];
            if (parentSalesLines.size() > 0) {
                Sales_Line__c parentSalesLine = parentSalesLines[0];

                Set<Id> salesChildLineIds = new Set<Id>();
                for (Sales_Parent_Child_Relation__c salesChildRelation : parentSalesLine.Sales_Child_Lines__r) {
                    salesChildLineIds.add(salesChildRelation.Child_Line__c);
                }
                Map<Id, Sales_Line__c> mapSalesChildLinesById = new Map<Id, Sales_Line__c>();
                for (Sales_Line__c salesLine : [SELECT Id, Category__c, Resource_Type__c, Resource_Type__r.Name, Resource__c, Resource__r.Name, Description__c, Unit_of_Measure__c, Unit_of_Measure__r.Name, Sales_Order__r.Service_Center__c, Sales_Order__r.Service_Center__r.Name FROM Sales_Line__c WHERE Id IN :salesChildLineIds]) {
                    mapSalesChildLinesById.put(salesLine.Id, salesLine);
                }

                for (Sales_Parent_Child_Relation__c salesChildRelation : parentSalesLine.Sales_Child_Lines__r) {
                    Id childResourceId;
                    if (salesChildRelation.Child_Line__r.Category__c == 'Labor' || salesChildRelation.Child_Line__r.Category__c == 'Equipment' || salesChildRelation.Child_Line__r.Category__c == 'Bundled') {
                        childResourceId = salesChildRelation.Child_Line__r.Resource_Type__c;
                    }
                    else {
                        childResourceId = salesChildRelation.Child_Line__r.Resource__c;
                    }
                    if (!mapTMChildLinesByResourceId.containsKey(childResourceId)) { // add a child line for the child resource
                        Sales_Line__c salesChildLine = mapSalesChildLinesById.get(salesChildRelation.Child_Line__c);

                        TM_Line__c childLine = new TM_Line__c();
                        childLine.Line_No__c = nextTMLineNo;
                        childLine.TM__c = tm.Id;
                        childLine.TM_Job_Task__c = jobTask.Id;
                        childLine.TM_Job_Task__r = jobTask;
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
                        childLines.add(childLine);
                        nextTMLineNo++;

                        mapTMChildLinesByResourceId.put(childResourceId, childLine);
                    }
                }
            }
            return JSON.serialize(childLines);
        } catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    */
    @AuraEnabled
    public static String validateResourceTypeOrResource(String JSONTM, String JSONJobTaskWrapper, String JSONTMLine, Integer nextTMLineNo) {
        try {
            TM__c tm = (TM__c) JSON.deserialize(JSONTM, TM__c.class);
            ACVTMJobTaskWrapper jobTaskWrapper = (ACVTMJobTaskWrapper) JSON.deserialize(JSONJobTaskWrapper, ACVTMJobTaskWrapper.class);
            TM_Line__c tmLine = (TM_Line__c) JSON.deserialize(JSONTMLine, TM_Line__c.class);

            //use the Wizard_Question_Answered__c flag to calculate child resources for the tmLine only.
            for (Integer i = 0; i < jobTaskWrapper.TMLines.size(); i++) {
                if (jobTaskWrapper.TMLines[i].Line_No__c == tmLine.Line_No__c) {
                    jobTaskWrapper.TMLines[i].Wizard_Question_Answered__c = false;
                }
                else {
                    jobTaskWrapper.TMLines[i].Wizard_Question_Answered__c = true;
                }
            }

            List<ACVTMJobTaskWrapper> jobTaskWrappers = new List<ACVTMJobTaskWrapper>{ jobTaskWrapper };
            TMsService.calculateChildResources(tm, jobTaskWrappers);
            for (Integer i = 0; i < jobTaskWrapper.TMLines.size(); i++) {
                if (jobTaskWrapper.TMLines[i].Line_No__c == tmLine.Line_No__c) {
                    tmLine = jobTaskWrapper.TMLines[i];
                    break;
                }
            }

            return JSON.serialize(tmLine);
        } catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    //ticket 19130 05.13.2023 >>

    @AuraEnabled
    public static Id saveTMHeader(String JSONTM) {
        try {
            TM__c tm = (TM__c) JSON.deserialize(JSONTM, TM__c.class);
            upsert tm;
            return tm.Id;
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String saveTM(String JSONTM, String JSONJobTaskWrappers) {
        try {
            TM__c tm = (TM__c) JSON.deserialize(JSONTM, TM__c.class);
            List<ACVTMJobTaskWrapper> jobTaskWrappers = (List<ACVTMJobTaskWrapper>) JSON.deserialize(JSONJobTaskWrappers, List<ACVTMJobTaskWrapper>.class);
            //if (1==1) throw new DataException('** ' + jobTaskWrappers[0].TMLines.size());
            saveTM(tm, jobTaskWrappers);
            //return tm.Id;
            return getTM(tm.Id);
        }
        catch(exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public static void saveTM(TM__c tm, List<ACVTMJobTaskWrapper> jobTaskWrappers) {
        defaultCompanySetup = CompanyMgmt.getCompanySetup();
        Savepoint sp = Database.setSavepoint();
        try {
            Sales_Order__c salesOrder;
            if (tm.Sales_Order__c != null) {
                List<Sales_Order__c> salesOrders = SalesOrdersSelector.newInstance().selectById(new Set<Id>{ tm.Sales_Order__c });
                if (salesOrders.size() > 0) {
                    salesOrder = salesOrders[0];
                    //System.debug('Info: tm.Status__c ' + tm.Status__c + '...' + tm.Scheduled_Date__c + ' --- ' + salesOrder.Contract__r.EndDate);
                    //Ticket#20749 roll back 11/15/2021
                    /*
                    if (tm.Status__c == 'Confirmed' && tm.Scheduled_Date__c != null && salesOrder.Contract__c != null) {
                        if (tm.Scheduled_Date__c > salesOrder.Contract__r.EndDate){
                            throw new DataException('Contract expired on ' + salesOrder.Contract__r.EndDate);
                        }
                    }
                     */
                }
            }

            ACVTMWrapper tmWrapper = new ACVTMWrapper(tm, jobTaskWrappers);
            List<TM_Job_Task__c> jobTasks = tmWrapper.getJobTasks();
            List<TM_Line__c> tmLines = tmWrapper.getTMLines();

            //TM data check <<
            Map<Id, Datetime> mapTMLineModifiedDatesById = new Map<Id, Datetime>();
            //TM data check >>

            //ticket 19130 <<
            //set the wizard question answered to false if resource type, resource, qty or uom changed <<
            Set<Id> tmLineIds2 = new Set<Id>();
            //set the wizard question answered to false if resource type, resource, qty or uom changed >>
            //ticket 19130 >>

            //remove blank lines
            for (Integer i = 0; i < tmLines.size(); i++) {
                Boolean removeLine = false;
                if (tmLines[i].Category__c == 'Subcontractors') {
                    if (tmLines[i].Description__c == null) {
                        removeLine = true;
                    }
                } else if (tmLines[i].Resource_Type__c == null && tmLines[i].Resource__c == null) {
                    removeLine = true;
                }

                //TM data check <<
                if (tmLines[i].Id != null) {
                    mapTMLineModifiedDatesById.put(tmLines[i].Id, tmLines[i].LastModifiedDate);
                    //ticket 19130 <<
                    //set the wizard question answered to false if resource type, resource, qty or uom changed <<
                    tmLineIds2.add(TMLines[i].Id);
                    //set the wizard question answered to false if resource type, resource, qty or uom changed >>
                    //ticket 19130 >>
                }
                //TM data check >>

                if (removeLine) {
                    tmLines.remove(i);
                    i--;
                }
            }

            //TM data check <<
            List<TM_Line__c> oldTMLines = [SELECT Id, Line_No__c, LastModifiedDate FROM TM_Line__c WHERE TM__c = :tm.Id AND Id IN :mapTMLineModifiedDatesById.keySet()];
            for (TM_Line__c oldTMLine : oldTMLines) {
                if (mapTMLineModifiedDatesById.containsKey(oldTMLine.Id)) {
                    if (mapTMLineModifiedDatesById.get(oldTMLine.Id) < oldTMLine.LastModifiedDate) {
                        throw new DataException('T&M lines have been modified after you retrieved the data. Please refresh page and try again.');
                    }
                }
            }
            //TM data check >>

            //ticket 19130 <<
            //set the wizard question answered to false if resource type, resource, qty or uom changed <<
            if (tm.Status__c == 'Open' || tm.Status__c == 'Scheduled' || tm.Status__c == 'Mobile Review') {
                Map<Id, TM_Line__c> mapTMLinesById = new Map<Id, TM_Line__c>();
                for (TM_Line__c tmLine : [SELECT Id, Resource_Type__c, Resource__c, Quantity__c, Unit_of_Measure__c FROM TM_Line__c WHERE Id IN :tmLineIds2]) {
                    mapTMLinesById.put(tmLine.Id, tmLine);
                }

                Map<Integer, TM_Line__c> mapTMLinesByLineNo = new Map<Integer, TM_Line__c>();
                Map<Integer, List<Integer>> mapParentLineNosByChildLineNo = new Map<Integer, List<Integer>>();
                for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                        mapTMLinesByLineNo.put(tmLine.Line_No__c.intValue(), tmLine);

                        if (tmLine.TM_Child_Lines__r != null) {
                            for (TM_Parent_Child_Relation__c relation : tmLine.TM_Child_Lines__r) {
                                if (relation.Child_Line__r != null) {
                                    List<Integer> parentLineNos;
                                    if (mapParentLineNosByChildLineNo.containsKey(relation.Child_Line__r.Line_No__c.intValue())) {
                                        parentLineNos = mapParentLineNosByChildLineNo.get(relation.Child_Line__r.Line_No__c.intValue());
                                    } else {
                                        parentLineNos = new List<Integer>();
                                        mapParentLineNosByChildLineNo.put(relation.Child_Line__r.Line_No__c.intValue(), parentLineNos);
                                    }
                                    parentLineNos.add(relation.Parent_Line__r.Line_No__c.intValue());
                                }
                            }
                        }
                    }
                }

                for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                        if (mapTMLinesById.containsKey(tmLine.Id)) {
                            TM_Line__c xTmLine = mapTMLinesById.get(tmLine.Id);
                            if (tmLine.Resource_Type__c != xTmLine.Resource_Type__c || tmLine.Resource__c != xTmLine.Resource__c || tmLine.Quantity__c != xTmLine.Quantity__c || tmLine.Unit_of_Measure__c != xTmLine.Unit_of_Measure__c) {
                                tmLine.Wizard_Question_Answered__c = false;

                                if (tmLine.Is_Child_Resource__c != true) { //is a parent line
                                    for (TM_Parent_Child_Relation__c relation : tmLine.TM_Child_Lines__r) {
                                        if (relation.Child_Line__r != null) {
                                            if (mapTMLinesByLineNo.containsKey(relation.Child_Line__r.Line_No__c.intValue())) {
                                                mapTMLinesByLineNo.get(relation.Child_Line__r.Line_No__c.intValue()).Wizard_Question_Answered__c = false;
                                            }
                                        }
                                    }
                                }
                                else { //is a child line
                                    for (TM_Line__c tmLine2 : jobTaskWrapper.TMLines) {
                                        if (mapParentLineNosByChildLineNo.containsKey(tmLine2.Line_No__c.intValue())) {
                                            for (Integer parentLineNo : mapParentLineNosByChildLineNo.get(tmLine2.Line_No__c.intValue())) {
                                                if (mapTMLinesByLineNo.containsKey(parentLineNo)) {
                                                    mapTMLinesByLineNo.get(parentLineNo).Wizard_Question_Answered__c = false;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                mapTMLinesByLineNo = null; //release memory
                mapParentLineNosByChildLineNo = null;
            }

            //set the wizard question answered to false if resource type, resource, qty or uom changed >>
            //ticket 19130 >>
            Id xSalesOrderId;
            if (tm.Id != null) {
                //TM data check <<
                //List<TM__c> tms = [SELECT Sales_Order__c FROM TM__c WHERE Id = :tm.Id];
                List<TM__c> tms = [SELECT Id, Sales_Order__c, LastModifiedDate FROM TM__c WHERE Id = :tm.Id];
                if (tms.size() == 0) {
                    throw new DataException('T&M ' + tm.Id + 'does not exist');
                }
                if (tm.LastModifiedDate < tms[0].LastModifiedDate) {
                    throw new DataException('T&M has been modified after you retrieved the data. Please refresh page and try again');
                }
                //TM data check >>
                if (tms.size() > 0) {
                    xSalesOrderId = tms[0].Sales_Order__c;
                }

                Set<Id> jobTaskIds = new Set<Id>();
                for (TM_Job_Task__c jobTask : TMJobTasksSelector.newInstance().selectByTMId(new Set<Id>{ tm.Id })) {
                    jobTaskIds.add(jobTask.Id);
                }

                for (TM_Job_Task__c jobTask : jobTasks) {
                    if (jobTask.Id != null) {
                        if (jobTaskIds.contains(jobTask.Id)) {
                            jobTaskIds.remove(jobTask.Id);
                        }
                    }
                }
                if (jobTaskIds.size() > 0) {
                    delete [SELECT Id FROM TM_Job_Task__c WHERE TM__c = :tm.Id AND Id IN :jobTaskIds];
                }

                Set<Id> tmLineIds = new Set<Id>();
                for (TM_Line__c tmLine : TMLinesSelector.newInstance().selectByTmId(new Set<Id>{ tm.Id })) {
                    tmLineIds.add(tmLine.Id);
                }
                for (TM_Line__c tmLine : tmLines) {
                    if (tmLine.Id != null) {
                        if (tmLineIds.contains(tmLine.Id)) {
                            tmLineIds.remove(tmLine.Id);
                        }
                    }
                }

                if (tmLineIds.size() > 0) {
                    //ticket 19130 <<
                    //delete [SELECT Id FROM TM_Line__c WHERE TM__c = :tm.Id AND Id IN :tmLineIds];
                    delete [SELECT Id FROM TM_Parent_Child_Relation__c WHERE Child_Line__c IN :tmLineIds AND Child_Line__r.Invoiced__c != TRUE];
                    delete [SELECT Id FROM TM_Line__c WHERE TM__c = :tm.Id AND Id IN :tmLineIds AND Invoiced__c != TRUE];
                    //ticket 19130 >>
                }

                Set<Id> flatPayIds = new Set<Id>();
                for (Resource_Flat_Pay__c flatPay : [SELECT Id FROM Resource_Flat_Pay__c WHERE T_M__c = :tm.Id]) {
                    flatPayIds.add(flatPay.Id);
                }
                for (TM_Line__c tmLine : tmLines) {
                    if (tmLine.Resource_Flat_Pays1__r != null) {
                        for (Resource_Flat_Pay__c flatPay : tmLine.Resource_Flat_Pays1__r) {
                            if (flatPay.Id != null) {
                                if (flatPayIds.contains(flatPay.Id)) {
                                    flatPayIds.remove(flatPay.Id);
                                }
                            }
                        }
                    }
                }
                if (flatPayIds.size() > 0) {
                    delete [SELECT Id FROM Resource_Flat_Pay__c WHERE T_M__c = :tm.Id AND Id IN :flatPayIds];
                }
            }

            if (tm.Status__c == 'Confirmed') {
                TimesheetMgmt TMMgmt = new TimesheetMgmt();
                Set<Id> resourceIds = new Set<Id>();
                Set<Id> tmLinesIds = new Set<Id>();
                Map<String, Map<Time, Time>> mapTimeEntries = new Map<String, Map<Time, Time>>();
                Map<Id, String> mapResourceNames = new Map<Id, String>();
                Map<String, Set<String>> workedItemByResIdAndDate = new Map<String, Set<String>>(); //Ticket#19920
                for (TM_Line__c tmLine : tmLines) {
                    //Ticket#24946 >>
                    Boolean identicalJobTimesDetected = false;
                    if(tmLine.Job_Start_Time__c == tmLine.Site_Start_Time__c && tmLine.Site_Start_Time__c == tmLine.Site_End_Time__c && tmLine.Site_End_Time__c == tmLine.Job_End_Time__c){
                        identicalJobTimesDetected = true;
                    }
                    //Ticket#24946 <<
                    if (tmLine.Service_Center__r.Temporary__c != true
                            && (tmLine.Category__c == 'Labor' || tmLine.Category__c == 'Equipment')
                            //&& tmLine.Resource__r.Non_Payroll_Labor_Resource__c == false
                            && tmLine.Resource__r.Bypass_Time_Overlap_Checking__c == false //Ticket#22307
                            && identicalJobTimesDetected == false //Ticket#24946
                            && !String.isEmpty(tmLine.Resource__c)) {
                        mapTimeEntries = TMMgmt.updateResTimeEntryMap(mapTimeEntries, tm.Scheduled_Date__c, tm.Scheduled_Date__c, tm.Scheduled_Date__c,
                                tmLine.Job_Start_Time__c, tmLine.Job_End_Time__c, tmLine.Resource__c, mapResourceNames, workedItemByResIdAndDate);
                        resourceIds.add(tmLine.Resource__c);
                        tmLinesIds.add(tmLine.Id);
                    }
                }

                if (resourceIds.size() > 0 && mapTimeEntries.size() > 0) {
                    TMMgmt.checkTimeEntryOverlap(resourceIds, mapTimeEntries, tm.Scheduled_Date__c, tm.Scheduled_Date__c, tmLinesIds);
                }
            }

            //fix to overcome the validation in TMTriggersMgmt where it tries to pull the TM Lines from database and validate
            //if new tm upsert now, else update later after line insert/update
            if (tm.Id == null) {
                insert tm;
            }

            //insert job tasks
            Map<Integer, TM_Job_Task__c> mapJobTasksByLineNo = new Map<Integer, TM_Job_Task__c>();
            for (TM_Job_Task__c jobTask : jobTasks) {
                if (jobTask.TM__c == null) {
                    jobTask.TM__c = tm.Id;
                }
                mapJobTasksByLineNo.put(jobTask.Line_No__c.intValue(), jobTask);
            }
            upsert mapJobTasksByLineNo.values();

            //populate id fields
            for (TM_Line__c tmLine : tmLines) {
                //Lunch Time validation Ticket#23935 >>
                if(tmLine.Category__c == ResourceService.LABOR_CATEGORY) {
                    Boolean isValid = TMLLinesService.isLunchTimeValid(tmLine.Job_Start_Time__c, tmLine.Job_End_Time__c, tmLine.Lunch_Start_Time__c, tmLine.Lunch_End_Time__c, tmLine.Site_Start_Time__c, tmLine.Site_End_Time__c);
                    if (isValid == false) {
                        throw new DataException('Lunch times entered are not valid. Please make sure lunch times are either within the job start and job end times / job start and site start times / site start and site end times / or site end and job end times. T&M: ' + tm.Name + ' Line No: ' + tmLine.Line_No__c);
                    } else {
                        isValid = TMLLinesService.lunchTimeCheckForKronos(tmLine.Job_Start_Time__c, tmLine.Job_End_Time__c, tmLine.Site_Start_Time__c, tmLine.Site_End_Time__c, tmLine.Lunch_Start_Time__c, tmLine.Lunch_End_Time__c);
                        if (isValid == false) {
                            throw new DataException('Lunch start times entered are not valid. Please make sure lunch start/end time is not the same as job start, site start, site end and job end times. T&M: ' + tm.Name + ' Line No: ' + tmLine.Line_No__c);
                        }
                    }
                }
                //Lunch Time validation Ticket#23935 <<

                if (tmLine.TM__c == null) {
                    tmLine.TM__c = tm.Id;
                }

                if (tmLine.TM_Job_Task__c == null) {
                    if (tmLine.TM_Job_Task__r == null) {
                        throw new DataException('TM Job Task object on the T&M line ' + tmLine.Line_No__c + ' is not specified.');
                    }
                    if (mapJobTasksByLineNo.containsKey(tmLine.TM_Job_Task__r.Line_No__c.intValue())) {
                        TM_Job_Task__c jobTask = mapJobTasksByLineNo.get(tmLine.TM_Job_Task__r.Line_No__c.intValue());
                        tmLine.TM_Job_Task__c = jobTask.Id;
                        tmLine.TM_Job_Task__r = jobTask;
                    }
                }

                if (tmLine.Category__c == 'Subcontractors' && tmLine.Resource__c == null) {
                    tmLine.Resource__c = defaultCompanySetup.Default_Subcontractor_Resource__c;
                }
                //Ticket#19647 Blank out Quote Line or Sales Line if it does not belong to the Quote/Order in the header.
                if(String.isNotBlank(tmLine.Sales_Line__c)){
                    if(tm.Sales_Order__c == null){
                        tmLine.Sales_Line__c = null;
                    } else if (tm.Sales_Order__c != tmLine.Sales_Line__r.Sales_Order__c) {
                        tmLine.Sales_Line__c = null;
                    }
                }
                if(String.isNotBlank(tmLine.Quote_Line__c)) {
                    if (tm.From_Sales_Quote__c == null) {
                        tmLine.Quote_Line__c = null;
                    } else if (tm.From_Sales_Quote__c != tmLine.Quote_Line__r.Sales_Order__c) {
                        tmLine.Quote_Line__c = null;
                    }
                }
                //Ticket#19647
            }


            //insert lines without the relationship fields to the TM line objects first
            Map<Integer, TM_Line__c> mapTMLinesByLineNo = new Map<Integer, TM_Line__c>();
            Map<Integer, TM_Line__c> mapLinkedTMLinesByLineNo = new Map<Integer, TM_Line__c>();
            for (TM_Line__c tmLine : tmLines) {
                if (tmLine.Line_No__c == null) {
                    throw new DataException('T&M line is missing line #: ' + tmLine.Category__c);
                }

                //ticket 19130 <<
                /*
                if (tmLine.Parent_Line__r != null || tmLine.Linked_Line__r != null) {
                    mapLinkedTMLinesByLineNo.put(tmLine.Line_No__c.intValue(), tmLine.clone(true, true));
                    tmLine.Parent_Line__c = null;
                    tmLine.Parent_Line__r = null;
                    tmLine.Linked_Line__c = null;
                    tmLine.Linked_Line__r = null;
                }
                */
                if (tmLine.Linked_Line__r != null) {
                    mapLinkedTMLinesByLineNo.put(tmLine.Line_No__c.intValue(), tmLine.clone(true, true));
                    tmLine.Linked_Line__c = null;
                    tmLine.Linked_Line__r = null;
                }
                //ticket 19130 >>
                //ticket 19130 05.13.2023 <<
                if (mapTMLinesByLineNo.containsKey(tmLine.Line_No__c.intValue())) {
                    throw new DataException('Job task ' + tmLine.TM_Job_Task__r.Name + ': line # ' + tmLine.Line_No__c.intValue() + ' - ' + tmLine.Category__c + ' already exists.');
                }
                //ticket 19130 05.13.2023 >>
                mapTMLinesByLineNo.put(tmLine.Line_No__c.intValue(), tmLine);
            }

            CompanyMgmt.byPassTrigger = true;
            //CompanyMgmt.byPassLineTrigger = true; need to run the validation on the TMLTrigger, like lunch time validation
            upsert mapTMLinesByLineNo.values();
            //CompanyMgmt.byPassLineTrigger = false;
            CompanyMgmt.byPassTrigger = false;

            //ticket 19130 <<
            List<Id> relationToDeleteIds = new List<Id>();
            Map<String, TM_Parent_Child_Relation__c> mapExistingRelationsByKey = new Map<String, TM_Parent_Child_Relation__c>();
            for (TM_Parent_Child_Relation__c relation : [SELECT Id, Parent_Line__c, Child_Line__c FROM TM_Parent_Child_Relation__c WHERE Parent_Line__r.TM__c = :tm.Id]) {
                String key = relation.Parent_Line__c + ':' + relation.Child_Line__c;
                if (!mapExistingRelationsByKey.containsKey(key)) {
                    mapExistingRelationsByKey.put(key, relation);
                } else {
                    relationToDeleteIds.add(relation.Id); //duplicated parent-child if exists
                }
            }

            List<TM_Parent_Child_Relation__c> relationsToUpsert = new List<TM_Parent_Child_Relation__c>();
            for (TM_Line__c tmLine : tmLines) {
                //Ticket#23028 >>
                //copy TM Parent Child relation to a list instead of using tmLine.TM_Child_Lines__r, to avoid 'Aggregate query has too many rows for direct assignment, use FOR loop' error.
                List<TM_Parent_Child_Relation__c> tmParentChildRelations = new List<TM_Parent_Child_Relation__c>();
                for(TM_Parent_Child_Relation__c tmParentChildRelation : tmLine.TM_Child_Lines__r){
                    tmParentChildRelations.add(tmParentChildRelation);
                }

                for (TM_Parent_Child_Relation__c relation : tmParentChildRelations) {
                    if (relation.Child_Line__r != null) {
                        TM_Line__c parentLine = mapTMLinesByLineNo.get(relation.Parent_Line__r.Line_No__c.intValue());
                        TM_Line__c childLine = mapTMLinesByLineNo.get(relation.Child_Line__r.Line_No__c.intValue());
                        if (childLine == null) {
                            throw new DataException('Line #' + parentLine.Line_No__c + ': child relation is null, child line #' + relation.Child_Line__r.Line_No__c);
                        }
                        String key = parentLine.Id + ':' + childLine.Id;

                        TM_Parent_Child_Relation__c relationToUpsert = new TM_Parent_Child_Relation__c();
                        if (mapExistingRelationsByKey.containsKey(key)) {
                            relationToUpsert.Id = mapExistingRelationsByKey.get(key).Id;
                            mapExistingRelationsByKey.remove(key);
                        } else {
                            relationToUpsert.Parent_Line__c = parentLine.Id;
                            relationToUpsert.Parent_Line__r = new TM_Line__c(Id = parentLine.Id);
                        }
                        relationToUpsert.Child_Line__c = childLine.Id;
                        relationToUpsert.Child_Line__r = new TM_Line__c(Id = childLine.Id);
                        relationsToUpsert.add(relationToUpsert);
                    }
                }
                /*
                if (tmLine.TM_Child_Lines__r != null && tmLine.TM_Child_Lines__r.size() > 0) {
                    for (TM_Parent_Child_Relation__c relation : tmLine.TM_Child_Lines__r) {
                        TM_Line__c parentLine = mapTMLinesByLineNo.get(relation.Parent_Line__r.Line_No__c.intValue());
                        TM_Line__c childLine = mapTMLinesByLineNo.get(relation.Child_Line__r.Line_No__c.intValue());
                        if (childLine == null) {
                            throw new DataException('Line #' + parentLine.Line_No__c + ': child relation is null, child line #' + relation.Child_Line__r.Line_No__c);
                        }
                        String key = parentLine.Id + ':' + childLine.Id;

                        TM_Parent_Child_Relation__c relationToUpsert = new TM_Parent_Child_Relation__c();
                        if (mapExistingRelationsByKey.containsKey(key)) {
                            relationToUpsert.Id = mapExistingRelationsByKey.get(key).Id;
                            mapExistingRelationsByKey.remove(key);
                        } else {
                            relationToUpsert.Parent_Line__c = parentLine.Id;
                            relationToUpsert.Parent_Line__r = new TM_Line__c(Id = parentLine.Id);
                        }
                        relationToUpsert.Child_Line__c = childLine.Id;
                        relationToUpsert.Child_Line__r = new TM_Line__c(Id = childLine.Id);
                        relationsToUpsert.add(relationToUpsert);
                    }
                }
                 */
                //Ticket#23028 <<
            }
            if(relationsToUpsert.size() > 0) {
                upsert relationsToUpsert;
            }

            if (mapExistingRelationsByKey.size() > 0) {
                for (TM_Parent_Child_Relation__c relation : mapExistingRelationsByKey.values()) {
                    relationToDeleteIds.add(relation.Id);
                }
            }
            if (relationToDeleteIds.size() > 0) {
                delete [SELECT Id FROM TM_Parent_Child_Relation__c WHERE Id IN :relationToDeleteIds];
            }

            //ticket 19130 >>

            List<TM_Line__c> tmLineLinksToUpdate = new List<TM_Line__c>();
            for (TM_Line__c tmLine : tmLines) {
                if (mapLinkedTMLinesByLineNo.containsKey(tmLine.Line_No__c.intValue())) {
                    TM_Line__c linkedTMLine = mapLinkedTMLinesByLineNo.get(tmLine.Line_No__c.intValue());

                    //ticket 19130 <<
                    /*
                    if (linkedTMLine.Parent_Line__r != null || linkedTMLine.Linked_Line__r != null) {
                        if (linkedTMLine.Parent_Line__r != null) {
                            if (mapTMLinesByLineNo.containsKey(linkedTMLine.Parent_Line__r.Line_No__c.intValue())) {
                                TM_Line__c parentLine = mapTMLinesByLineNo.get(linkedTMLine.Parent_Line__r.Line_No__c.intValue());
                                tmLine.Parent_Line__c = parentLine.Id;
                                tmLine.Parent_Line__r = new TM_Line__c(Id = parentLine.Id);
                            }
                            else {
                                tmLine.Parent_Line__c = null;
                                tmLine.Parent_Line__r = null;
                            }
                        }
                    */
                    //ticket 19130 >>
                    if (linkedTMLine.Linked_Line__r != null) {
                        if (mapTMLinesByLineNo.containsKey(linkedTMLine.Linked_Line__r.Line_No__c.intValue())) {
                            TM_Line__c linkedLine = mapTMLinesByLineNo.get(linkedTMLine.Linked_Line__r.Line_No__c.intValue());
                            tmLine.Linked_Line__c = linkedLine.Id;
                            tmLine.Linked_Line__r = new TM_Line__c(Id = linkedLine.Id);
                        }
                        else {
                            tmLine.Linked_Line__c = null;
                            tmLine.Linked_Line__r = null;
                        }
                    }
                    tmLineLinksToUpdate.add(tmLine);
                    //ticket 19130 <<
                    //}
                    //ticket 19130 >>
                }
            }
            if (tmLineLinksToUpdate.size() > 0) {
                CompanyMgmt.byPassTrigger = true;
                CompanyMgmt.byPassLineTrigger = true;
                update tmLineLinksToUpdate;
                CompanyMgmt.byPassLineTrigger = false;
                CompanyMgmt.byPassTrigger = false;
            }

            //resource flat pay lines
            List<Resource_Flat_Pay__c> flatPays = new List<Resource_Flat_Pay__c>();
            for (TM_Line__c tmLine : mapTMLinesByLineNo.values()) {
                if (tmLine.Resource_Flat_Pays1__r != null) {
                    for (Resource_Flat_Pay__c flatPay : tmLine.Resource_Flat_Pays1__r) {
                        if (flatPay.T_M__c == null) {
                            flatPay.T_M__c = tmLine.TM__c;
                            flatPay.T_M__r = new TM__c(Id = tmLine.TM__c);
                        }
                        if (flatPay.T_M_Line__c == null) {
                            flatPay.T_M_Line__c = tmLine.Id;
                            flatPay.T_M_Line__r = new TM_Line__c(Id = tmLine.Id);
                        }
                        flatPays.add(flatPay);
                    }
                }
            }
            if (flatPays.size() > 0) {
                upsert flatPays;
            }

            //update TM Status <<
            Boolean allLinesInvoiced = true;
            if(tmLines.size() == 0){
                allLinesInvoiced = false;
            }

            for (TM_Line__c tmLine : tmLines) {
                if (tmLine.Invoiced__c != true) {
                    allLinesInvoiced = false;
                    break;
                }
            }

            if (tm.Status__c == 'Confirmed') {
                if (allLinesInvoiced == true) {
                    tm.Status__c = 'Fully Invoiced';
                }
            }
            else if (tm.Status__c == 'Fully Invoiced') {
                if (allLinesInvoiced != true) {
                    tm.Status__c  = 'Confirmed';
                }
            }
            //update TM Status >>

            //if (tm.Id != null) { tm.Id should never be null at this point.
            if(tm.Status__c == 'Fully Invoiced' && allLinesInvoiced == true){
                CompanyMgmt.systemCall = true;
                update tm;

            } else {
                update tm;
            }
            //}

            //handle open invoices due to the change of the sales order field
            if (tm.Sales_Order__c != xSalesOrderId && tm.Sales_Invoice__c != null) {
                List<TM__c> tms = [
                        SELECT Id, (SELECT Id FROM TM_Lines__r)
                        FROM TM__c
                        WHERE Sales_Invoice__c = :tm.Sales_Invoice__c AND Sales_Invoice__r.Document_Status__c = 'Open' AND Sales_Invoice__r.Credit_Memo__c <> TRUE
                ];

                if (tms.size() > 0) {
                    List<TM__c> tmsToUpdate = new List<TM__c>();
                    List<TM_Line__c>
                            tmLinesToUpdate = new List<TM_Line__c>();
                    for (TM__c xTm : tms) {
                        xTm.Sales_Invoice__c = null;
                        tmsToUpdate.add(xTm);

                        for (TM_Line__c xTmLine : xTm.TM_Lines__r) {
                            xTmLine.Invoiced__c = false;
                            tmLinesToUpdate.add(xTmLine);
                        }
                    }

                    if (tmsToUpdate.size() > 0) {
                        CompanyMgmt.byPassTrigger = true;
                        CompanyMgmt.byPassLineTrigger = true;
                        update tmsToUpdate;
                        update tmLinesToUpdate;
                        delete [SELECT Id FROM Sales_Invoice__c WHERE Id = :tm.Sales_Invoice__c];
                        CompanyMgmt.byPassLineTrigger = false;
                        CompanyMgmt.byPassTrigger = false;
                    }
                }
            }

        }
        catch(exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            Database.rollback(sp);
            throw ex;
        }
    }

    private static Integer getNextTMLineNo(List<ACVTMJobTaskWrapper> jobTaskWrappers) {
        Integer nextTMLineNo = 0;
        for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                if (nextTMLineNo < tmLine.Line_No__c) {
                    nextTMLineNo = tmLine.Line_No__c.intValue();
                }
            }
        }
        nextTMLineNo++;
        return nextTMLineNo;
    }

    @AuraEnabled
    public static String prepareWizardQuestions(String JSONTM, String JSONJobTaskWrappers) {
        try {
            TM__c tm = (TM__c)JSON.deserialize(JSONTM, TM__c.class);
            List<ACVTMJobTaskWrapper> jobTaskWrappers = (List<ACVTMJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVTMJobTaskWrapper>.class);
            //Map<Integer, List<Job_Task_Template_Line__c>> mapQuestionsByTaskIndex = prepareWizardQuestions(tm, jobTaskWrappers);
            Map<Integer, List<Map<String, Object>>> mapQuestionsByTaskIndex = prepareWizardQuestions(tm, jobTaskWrappers);
            return JSON.serialize(mapQuestionsByTaskIndex);
        }
        catch(Exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*version 1
    public static Map<Integer, List<Job_Task_Template_Line__c>> prepareWizardQuestions(List<ACVTMJobTaskWrapper> JobTaskWrappers) {
        Map<Integer, List<Job_Task_Template_Line__c>> mapQuestionsByTaskIndex = new Map<Integer, List<Job_Task_Template_Line__c>>();

        Set<Id> jobTaskTemplateIds = new Set<Id>();
        for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            if (jobTaskWrapper.JobTask.Job_Task_Template__c != null) {
                jobTaskTemplateIds.add(jobTaskWrapper.JobTask.Job_Task_Template__c);
            }
        }

        //retrieve child template lines
        Map<Id, Map<String, Job_Task_Template_Line__c>> mapJobTaskTemplateLines = new Map<Id, Map<String, Job_Task_Template_Line__c>>();
        for (Job_Task_Template_Line__c jobTaskTemplateLine : JobTaskTemplateLinesSelector.newInstance().selectByTemplateId(jobTaskTemplateIds, null)) {
            Map<String, Job_Task_Template_Line__c> mapTemplateLinesByParentChildKey;
            if (mapJobTaskTemplateLines.containsKey(jobTaskTemplateLine.Job_Task_Template__c)) {
                mapTemplateLinesByParentChildKey = mapJobTaskTemplateLines.get(jobTaskTemplateLine.Job_Task_Template__c);
            }
            else {
                mapTemplateLinesByParentChildKey = new Map<String, Job_Task_Template_Line__c>();
                mapJobTaskTemplateLines.put(jobTaskTemplateLine.Job_Task_Template__c, mapTemplateLinesByParentChildKey);
            }

            Id parentResourceId;
            if (jobTaskTemplateLine.Category__c == 'Labor' || jobTaskTemplateLine.Category__c == 'Equipment' || jobTaskTemplateLine.Category__c == 'Lump Sum') {
                parentResourceId = jobTaskTemplateLine.Resource_Type__c;
            }
            else {
                parentResourceId = jobTaskTemplateLine.Resource__c;
            }

            if (jobTaskTemplateLine.Job_Task_Template_Lines__r != null) {
                for (Job_Task_Template_Line__c childTemplateLine : jobTaskTemplateLine.Job_Task_Template_Lines__r) {
                    Id childResourceId;
                    if (childTemplateLine.Category__c == 'Labor' || childTemplateLine.Category__c == 'Equipment' || childTemplateLine.Category__c == 'Lump Sum') {
                        childResourceId = childTemplateLine.Resource_Type__c;
                    }
                    else {
                        childResourceId = childTemplateLine.Resource__c;
                    }

                    String parentChildKey = parentResourceId + ';' + childResourceId;
                    mapTemplateLinesByParentChildKey.put(parentChildKey, childTemplateLine);
                }
            }
        }

        for (Integer i = 0; i < jobTaskWrappers.size(); i++) {
            ACVTMJobTaskWrapper jobTaskWrapper = jobTaskWrappers[i];

            //group child sales lines with 0 quantity by parent line no
            Map<Integer, List<TM_Line__c>> mapChildTMLinesByParentLineNo = new Map<Integer, List<TM_Line__c>>();
            for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                if (tmLine.Parent_Line__r != null && tmLine.Parent_Line__r.Line_No__c != null) {
                    if (tmLine.Quantity__c == null || tmLine.Quantity__c == 0) {
                        Integer parentLineNo = tmLine.Parent_Line__r.Line_No__c.intValue();
                        List<TM_Line__c> childTMLines;
                        if (mapChildTMLinesByParentLineNo.containsKey(parentLineNo)) {
                            childTMLines = mapChildTMLinesByParentLineNo.get(parentLineNo);
                        } else {
                            childTMLines = new List<TM_Line__c>();
                            mapChildTMLinesByParentLineNo.put(parentLineNo, childTMLines);
                        }
                        childTMLines.add(tmLine);
                    }
                }
            }

            List<Job_Task_Template_Line__c> questions = new List<Job_Task_Template_Line__c>();
            if (mapChildTMLinesByParentLineNo.size() > 0) {
                if (jobTaskWrapper.JobTask.Job_Task_Template__c == null) {
                    for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                        Integer tmLineNo = tmLine.Line_No__c.intValue();
                        if (mapChildTMLinesByParentLineNo.containsKey(tmLineNo)) {
                            String parentResourceDescription = tmLine.Description__c;
                            List<TM_Line__c> childTMLines = mapChildTMLinesByParentLineNo.get(tmLineNo);
                            for (TM_Line__c childTMLine : childTMLines) {
                                String childResourceDescription = childTMLine.Description__c;

                                Job_Task_Template_Line__c jobTaskTemplateLine = new Job_Task_Template_Line__c();
                                jobTaskTemplateLine.Line_No__c = childTMLine.Line_No__c.intValue(); //use TM line no for template line no, the line will be used to update jobTaskWrapper tm lines later in the lightning component
                                jobTaskTemplateLine.Category__c = childTMLine.Category__c;
                                jobTaskTemplateLine.Resource_Type__c = childTMLine.Resource_Type__c;
                                jobTaskTemplateLine.Resource_Type__r = childTMLine.Resource_Type__r;
                                jobTaskTemplateLine.Resource__c = childTMLine.Resource__c;
                                jobTaskTemplateLine.Resource__r = childTMLine.Resource__r;
                                jobTaskTemplateLine.Description__c = childTMLine.Description__c;
                                jobTaskTemplateLine.Unit_of_Measure__c = childTMLine.Unit_of_Measure__c;
                                jobTaskTemplateLine.Unit_of_Measure__r = childTMLine.Unit_of_Measure__r;
                                jobTaskTemplateLine.Cost_Method__c = childTMLine.Cost_Method__c;
                                jobTaskTemplateLine.Unit_Weight_Vol__c = childTMLine.Unit_Weight_Vol__c;
                                jobTaskTemplateLine.Unit_Weight_Vol__r = childTMLine.Unit_Weight_Vol__r;
                                jobTaskTemplateLine.Container_Size__c = childTMLine.Container_Size__c;
                                jobTaskTemplateLine.Container_Size__r = childTMLine.Container_Size__r;
                                jobTaskTemplateLine.Question__c = 'Did you use ' + childResourceDescription + '?';
                                questions.add(jobTaskTemplateLine);
                            }
                        }
                    }
                }
                else {
                    if (mapJobTaskTemplateLines.containsKey(jobTaskWrapper.JobTask.Job_Task_Template__c)) {
                        Map<String, Job_Task_Template_Line__c> mapTemplateLinesByParentChildKey = mapJobTaskTemplateLines.get(jobTaskWrapper.JobTask.Job_Task_Template__c);

                        Map<Integer, TM_Line__c> mapTMLinesByLineNo = new Map<Integer, TM_Line__c>();
                        for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                            mapTMLinesByLineNo.put(tmLine.Line_No__c.intValue(), tmLine);
                        }

                        for (TM_Line__c childTMLine : jobTaskWrapper.TMLines) {
                            if (childTMLine.Parent_Line__r != null && childTMLine.Parent_Line__r.Line_No__c != null) {
                                if (childTMLine.Quantity__c == null || childTMLine.Quantity__c == 0) {
                                    TM_Line__c parentTMLine = mapTMLinesByLineNo.get(childTMLine.Parent_Line__r.Line_No__c.intValue());
                                    Id parentResourceId;
                                    if (parentTMLine.Category__c == 'Labor' || parentTMLine.Category__c == 'Equipment' || parentTMLine.Category__c == 'Lump Sum') {
                                        parentResourceId = parentTMLine.Resource_Type__c;
                                    } else {
                                        parentResourceId = parentTMLine.Resource__c;
                                    }
                                    Id childResourceId;
                                    if (childTMLine.Category__c == 'Labor' || childTMLine.Category__c == 'Equipment' || childTMLine.Category__c == 'Lump Sum') {
                                        childResourceId = childTMLine.Resource_Type__c;
                                    } else {
                                        childResourceId = childTMLine.Resource__c;
                                    }

                                    String parentChildKey = parentResourceId + ';' + childResourceId;
                                    if (mapTemplateLinesByParentChildKey.containsKey(parentChildKey)) {
                                        Job_Task_Template_Line__c jobTaskTemplateLine = mapTemplateLinesByParentChildKey.get(parentChildKey);
                                        String childResourceDescription = childTMLine.Description__c;

                                        Job_Task_Template_Line__c question = new Job_Task_Template_Line__c();
                                        question.Line_No__c = childTMLine.Line_No__c.intValue(); //use TM line no for template line no, the line will be used to update jobTaskWrapper tm lines later in the lightning component
                                        question.Category__c = childTMLine.Category__c;
                                        question.Resource_Type__c = childTMLine.Resource_Type__c;
                                        question.Resource_Type__r = childTMLine.Resource_Type__r;
                                        question.Resource__c = childTMLine.Resource__c;
                                        question.Resource__r = childTMLine.Resource__r;
                                        question.Description__c = childTMLine.Description__c;
                                        question.Unit_of_Measure__c = childTMLine.Unit_of_Measure__c;
                                        question.Unit_of_Measure__r = childTMLine.Unit_of_Measure__r;
                                        question.Cost_Method__c = childTMLine.Cost_Method__c;
                                        question.Unit_Weight_Vol__c = childTMLine.Unit_Weight_Vol__c;
                                        question.Unit_Weight_Vol__r = childTMLine.Unit_Weight_Vol__r;
                                        question.Container_Size__c = childTMLine.Container_Size__c;
                                        question.Container_Size__r = childTMLine.Container_Size__r;
                                        if (jobTaskTemplateLine.Question__c != null) {
                                            question.Question__c = jobTaskTemplateLine.Question__c;
                                        } else {
                                            question.Question__c = 'Did you use ' + childResourceDescription + '?';
                                        }
                                        questions.add(question);
                                    }
                                }
                            }
                        }
                    }
                }

                if (questions.size() > 0) {
                    mapQuestionsByTaskIndex.put(i, questions); //by job task wrapper index
                }
            }
        }
        return mapQuestionsByTaskIndex;
    }
    */

    //ticket 19130 05.13.2023 <<
    private static Map<Integer, List<Map<String, Object>>> prepareWizardQuestions(TM__c tm, List<ACVTMJobTaskWrapper> jobTaskWrappers) {
        Set<Id> tmLineIds = new Set<Id>();
        for (Integer i = 0; i < jobTaskWrappers.size(); i++) {
            ACVTMJobTaskWrapper jobTaskWrapper = jobTaskWrappers[i];
            for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                if (tmLine.Id != null) {
                    tmLineIds.add(tmLine.Id);
                }
            }
        }

        //set the wizard question answered to false if resource type, resource, qty or uom changed <<
        Map<Id, TM_Line__c> mapxTMLinesById = new Map<Id, TM_Line__c>();
        for (TM_Line__c tmLine : [SELECT Id, Resource_Type__c, Resource__c, Quantity__c, Unit_of_Measure__c FROM TM_Line__c WHERE Id IN :tmLineIds]) {
            mapxTMLinesById.put(tmLine.Id, tmLine);
        }
        for (Integer i = 0; i < jobTaskWrappers.size(); i++) {
            ACVTMJobTaskWrapper jobTaskWrapper = jobTaskWrappers[i];
            for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                if (tmLine.Invoiced__c != true) {
                    if (mapxTMLinesById.containsKey(tmLine.Id)) {
                        TM_Line__c xTmLine = mapxTMLinesById.get(tmLine.Id);
                        if (tmLine.Resource_Type__c != xTmLine.Resource_Type__c || tmLine.Resource__c != xTmLine.Resource__c || tmLine.Quantity__c != xTmLine.Quantity__c || tmLine.Unit_of_Measure__c != xTmLine.Unit_of_Measure__c) {
                            tmLine.Wizard_Question_Answered__c = false;
                        }
                    }
                }
            }
        }
        //set the wizard question answered to false if resource type, resource, qty or uom changed <<

        TMsService.calculateChildResources(tm, jobTaskWrappers);
        Map<Integer, List<Map<String, Object>>> mapQuestionsByTaskIndex = new Map<Integer, List<Map<String, Object>>>();
        for (Integer i = 0; i < jobTaskWrappers.size(); i++) {
            ACVTMJobTaskWrapper jobTaskWrapper = jobTaskWrappers[i];

            //group parent lines by child resource
            Map<Integer, TM_Line__c> mapTMLinesByLineNo = new Map<Integer, TM_Line__c>();
            for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                mapTMLinesByLineNo.put(tmLine.Line_No__c.intValue(), tmLine);
            }

            //set wizard question answered, loop the lines twice to set Wizard_Question_Answered__c for level 1 and level 2 child resources
            for (Integer j = 0; j < 2; j++) {
                for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                    if (tmLine.TM_Child_Lines__r != null && tmLine.TM_Child_Lines__r.size() > 0) {
                        for (TM_Parent_Child_Relation__c relation : tmLine.TM_Child_Lines__r) {
                            if (relation.Child_Line__r != null) {
                                TM_Line__c childTMLine = mapTMLinesByLineNo.get(relation.Child_Line__r.Line_No__c.intValue());
                                if (tmLine.Wizard_Question_Answered__c != true) {
                                    childTMLine.Wizard_Question_Answered__c = false;
                                }
                            }
                        }
                    }
                }
            }

            Map<Integer, List<TM_Line__c>> mapParentLinesByChildLineNo = new Map<Integer, List<TM_Line__c>>();
            for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                if (tmLine.TM_Child_Lines__r != null && tmLine.TM_Child_Lines__r.size() > 0) {
                    for (TM_Parent_Child_Relation__c relation : tmLine.TM_Child_Lines__r) {                        
                        if(relation.Child_Line__c != null) {
                            TM_Line__c childTMLine = mapTMLinesByLineNo.get(relation.Child_Line__r.Line_No__c.intValue());

                            List<TM_Line__c> parentLines;
                            if (mapParentLinesByChildLineNo.containsKey(childTMLine.Line_No__c.intValue())) {
                                parentLines = mapParentLinesByChildLineNo.get(childTMLine.Line_No__c.intValue());
                            } else {
                                parentLines = new List<TM_Line__c>();
                                mapParentLinesByChildLineNo.put(childTMLine.Line_No__c.intValue(), parentLines);
                            }
                            parentLines.add(tmLine);
                        }
                    }
                }
            }

            List<Map<String, Object>> questions = new List<Map<String, Object>>();
            for (Integer childLineNo : mapParentLinesByChildLineNo.keySet()) {
                TM_Line__c childTMLine = mapTMLinesByLineNo.get(childLineNo);

                if (childTMLine.Wizard_Question_Answered__c != true) {
                    Map<String, Object> question = questionMap(childTMLine);
                   /* question.put('Line_No__c', childTMLine.Line_No__c.intValue());
                    question.put('Category__c', childTMLine.Category__c);
                    question.put('Resource_Type__c', childTMLine.Resource_Type__c);
                    question.put('Resource_Type__r', childTMLine.Resource_Type__r);
                    question.put('Resource__c', childTMLine.Resource__c);
                    question.put('Resource__r', childTMLine.Resource__r);
                    question.put('Description__c', childTMLine.Description__c);
                    question.put('Unit_of_Measure__c', childTMLine.Unit_of_Measure__c);
                    question.put('Unit_of_Measure__r', childTMLine.Unit_of_Measure__r);*/
                    /*Waste001
                    question.put('Cost_Method__c', childTMLine.Cost_Method__c);
                    question.put('Unit_Weight_Vol__c', childTMLine.Unit_Weight_Vol__c);
                    question.put('Unit_Weight_Vol__r', childTMLine.Unit_Weight_Vol__r);
                    question.put('Container_Size__c', childTMLine.Container_Size__c);
                    question.put('Container_Size__r', childTMLine.Container_Size__r);
                     */
                  /*  question.put('Resource_Type_UOM__c', childTMLine.Resource_Type_UOM__c);
                    question.put('Resource_Type_UOM__r', childTMLine.Resource_Type_UOM__r);
                    question.put('Resource_UOM__c', childTMLine.Resource_UOM__c);
                    question.put('Resource_UOM__r', childTMLine.Resource_UOM__r);
                    question.put('Contract_Line__c', childTMLine.Contract_Line__c);
                    question.put('Contract_Line__r', childTMLine.Contract_Line__r);
                    question.put('Quantity__c', childTMLine.Quantity__c);
                    question.put('Wizard_Question_Answered__c', childTMLine.Wizard_Question_Answered__c);
                    //ticket 19130 <<
                    //String questionDescription = 'Update quantity for the child resource "' + childTMLine.Description__c + '"?';
                    String questionDescription = 'Would you like to update the Quantity for, "' + childTMLine.Description__c + '"?';
                    //ticket 19130 >>

                    question.put('Question__c', questionDescription);*/
                    questions.add(question);

                    Boolean isLevel2ChildResource = false;
                    List<Object> relations = new List<Object>();
                    for (TM_Line__c parentTMLine : mapParentLinesByChildLineNo.get(childLineNo)) {
                        TM_Line__c childLine = new TM_Line__c();
                        childLine.Id = childTMLine.Id;
                        childLine.Line_No__c = childTMLine.Line_No__c;

                        TM_Line__c parentLine = formParentTMLine(parentTMLine);
                        /*
                            new TM_Line__c();
                        parentLine.Id = parentTMLine.Id;
                        parentLine.Line_No__c = parentTMLine.Line_No__c;
                        parentLine.Category__c = parentTMLine.Category__c;
                        parentLine.Resource_Type__c = parentTMLine.Resource_Type__c;
                        parentLine.Resource_Type__r = parentTMLine.Resource_Type__r;
                        parentLine.Resource__c = parentTMLine.Resource__c;
                        parentLine.Resource__r = parentTMLine.Resource__r;
                        parentLine.Description__c = parentTMLine.Description__c;
                        parentLine.Unit_of_Measure__c = parentTMLine.Unit_of_Measure__c;
                        parentLine.Unit_of_Measure__r = parentTMLine.Unit_of_Measure__r;
                        parentLine.Quantity__c = parentTMLine.Quantity__c;
                        parentLine.Sales_Line__c= parentTMLine.Sales_Line__c;*/

                        Map<String, Object> relation = new Map<String, Object>();
                        relation.put('Child_Line__r', childLine);
                        relation.put('Parent_Line__r', parentLine);
                        relations.add(relation);

                        if (isLevel2ChildResource != true) {
                            if (parentTMLine.Is_Child_Resource__c == true) {
                                isLevel2ChildResource = true;
                            }
                        }
                    }
                    question.put('Level2', isLevel2ChildResource);
                    question.put('Parent_Lines__r', new Map<String, Object>{ 'records' => relations });
                }
            }
            if (questions.size() > 0) {
                //sort questions by leve 1 child resources and then level 2 child resources
                List<Map<String, Object>> orderedQuestions = sortQuestions(questions);
                    /*new List<Map<String, Object>>();
                for (Integer j = 0; j < questions.size(); j++) {
                    Map<String, Object> question = questions[j];
                    if (question.get('Level2') != true) {
                        orderedQuestions.add(question);
                        questions.remove(j);
                        j--;
                    }
                }
                orderedQuestions.addAll(questions);*/
                mapQuestionsByTaskIndex.put(i, orderedQuestions); //by job task wrapper index
            }
        }
        return mapQuestionsByTaskIndex;
    }
    
    public static TM_Line__c formParentTMLine(TM_Line__c parentTMLine){
        TM_Line__c parentLine= new TM_Line__c();
        parentLine.Id = parentTMLine.Id;
        parentLine.Line_No__c = parentTMLine.Line_No__c;
        parentLine.Category__c = parentTMLine.Category__c;
        parentLine.Resource_Type__c = parentTMLine.Resource_Type__c;
        parentLine.Resource_Type__r = parentTMLine.Resource_Type__r;
        parentLine.Resource__c = parentTMLine.Resource__c;
        parentLine.Resource__r = parentTMLine.Resource__r;
        parentLine.Description__c = parentTMLine.Description__c;
        parentLine.Unit_of_Measure__c = parentTMLine.Unit_of_Measure__c;
        parentLine.Unit_of_Measure__r = parentTMLine.Unit_of_Measure__r;
        parentLine.Quantity__c = parentTMLine.Quantity__c;
        parentLine.Sales_Line__c= parentTMLine.Sales_Line__c;
        return parentLine;
    }
    public static List<Map<String, Object>> sortQuestions(List<Map<String, Object>> questions){
        List<Map<String, Object>> orderedQuestions = new List<Map<String, Object>>();
        
        for (Integer j = 0; j < questions.size(); j++) {
            Map<String, Object> question = questions[j];
            if (question.get('Level2') != true) {
                orderedQuestions.add(question);
                questions.remove(j);
                j--;
            }
        }
        orderedQuestions.addAll(questions);
        return orderedQuestions;
    }
    public static Map<String, Object> questionMap(TM_Line__c childTMLine){
         Map<String, Object> question = new Map<String, Object>();
                    question.put('Line_No__c', childTMLine.Line_No__c.intValue());
                    question.put('Category__c', childTMLine.Category__c);
                    question.put('Resource_Type__c', childTMLine.Resource_Type__c);
                    question.put('Resource_Type__r', childTMLine.Resource_Type__r);
                    question.put('Resource__c', childTMLine.Resource__c);
                    question.put('Resource__r', childTMLine.Resource__r);
                    question.put('Description__c', childTMLine.Description__c);
                    question.put('Unit_of_Measure__c', childTMLine.Unit_of_Measure__c);
                    question.put('Unit_of_Measure__r', childTMLine.Unit_of_Measure__r);
                    /*Waste001
                    question.put('Cost_Method__c', childTMLine.Cost_Method__c);
                    question.put('Unit_Weight_Vol__c', childTMLine.Unit_Weight_Vol__c);
                    question.put('Unit_Weight_Vol__r', childTMLine.Unit_Weight_Vol__r);
                    question.put('Container_Size__c', childTMLine.Container_Size__c);
                    question.put('Container_Size__r', childTMLine.Container_Size__r);
                     */
                    question.put('Resource_Type_UOM__c', childTMLine.Resource_Type_UOM__c);
                    question.put('Resource_Type_UOM__r', childTMLine.Resource_Type_UOM__r);
                    question.put('Resource_UOM__c', childTMLine.Resource_UOM__c);
                    question.put('Resource_UOM__r', childTMLine.Resource_UOM__r);
                    question.put('Contract_Line__c', childTMLine.Contract_Line__c);
                    question.put('Contract_Line__r', childTMLine.Contract_Line__r);
                    question.put('Quantity__c', childTMLine.Quantity__c);
                    question.put('Wizard_Question_Answered__c', childTMLine.Wizard_Question_Answered__c);
                    //ticket 19130 <<
                    //String questionDescription = 'Update quantity for the child resource "' + childTMLine.Description__c + '"?';
                    String questionDescription = 'Would you like to update the Quantity for, "' + childTMLine.Description__c + '"?';
                    //ticket 19130 >>

                    question.put('Question__c', questionDescription);
	return question;
    }
    //ticket 19130 05.13.2023 >>
    //Task#78352 //Bug#80870
    @AuraEnabled(cacheable=true)
    public static Boolean getThirdFacility(String salesOrderId)
    {
        List<Sales_Line__c> salesLines=New List<Sales_Line__c>();
        Date thrdPartyValDate = Date.valueOf(label.SO_3rd_Party_Facility_Check);
        salesLines = [Select Id from Sales_Line__c Where Sales_Order__c=:salesOrderId 
                      AND Sales_Order__r.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c=true 
                      AND Facility__r.Third_Party_Facility__c = true AND CreatedDate >= :thrdPartyValDate ];
        if(salesLines.size()>0)
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    //US115867
    @AuraEnabled 
    public static Map<String, String> getUnvoicedPicklist(String sObjectName){
        Map<String, String> options = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = TM__c.Un_invoiced_Reason_Code__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            options.put(p.getValue(), p.getLabel());
        }
        system.debug('options'+options);
        return options;
    }
    
    @AuraEnabled
    public static List<String> getValidBillUnitCode(String billUnitCode) {
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