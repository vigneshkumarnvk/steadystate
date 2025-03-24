public with sharing class ACVSalesLineController {
    @AuraEnabled
    //fix.null.fields << 
    //public static Sales_Line__c newSalesLine(String JSONSalesOrder, String category, Integer lineNo) {
    //job task <<
    //public static String newSalesLine(String JSONSalesOrder, String category, Integer lineNo) {
    public static String newSalesLine(String JSONSalesOrder, String JSONJobTask, String category, Integer nextSalesLineNo) {
    //job task >>
    //fix.null.fields >>
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            //job task <<
            Sales_Order_Job_Task__c jobTask = (Sales_Order_Job_Task__c)JSON.deserialize(JSONJobTask, Sales_Order_Job_Task__c.class);
            //job task >>

            //fix.null.fields <<
            //return SalesLinesService.newSalesLine(salesOrder, category, lineNo);
            //job task <<
            //Sales_Line__c salesLine = SalesLinesService.newSalesLine(salesOrder, category, lineNo);
            Sales_Line__c salesLine = SalesLinesService.newSalesLine(salesOrder, jobTask, category, nextSalesLineNo);
            //job task >>
            return JSON.serialize(salesLine);
            //fix.null.fields >>
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }


    @AuraEnabled
    //fix.null.fields <<
    //public static Sales_Line__c validateCategory(String JSONSalesOrder, String JSONSalesLine) {
    public static String validateCategory(String JSONSalesOrder, String JSONSalesLine) {
    //fix.null.fields >>
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            Sales_Line__c salesLine = (Sales_Line__c)JSON.deserialize(JSONSalesLine, Sales_Line__c.class);

            //job task <<
            SalesLinesService.initStaticVariables(salesOrder, salesLine);
            //job task >>

            salesLine = SalesLinesService.validateCategory(salesOrder, salesLine);

            //fix.null.fields <<
            //return salesLine;
            return JSON.serialize(salesLine);
            //fix.null.fields >>
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    //fix.null.fields <<
    //public static Sales_Line__c validateResourceType(String JSONSalesOrder, String JSONSalesLine) {
    //job task <<
    //public static String validateResourceType(String JSONSalesOrder, String JSONSalesLine) {
    //ticket 19130 05.13.2023 <<
    //public static String validateResourceType(String JSONSalesOrder, String JSONJobTask, String JSONSalesLine, Integer nextSalesLineNo) {
    public static String validateResourceType(String JSONSalesOrder, String JSONJobTaskWrapper, String JSONSalesLine, Integer nextSalesLineNo) {
    //ticket 19130 05.13.2023 >>
    //job task >>
    //fix.null.fields >>
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            //job task <<
            //ticket 19130 05.13.2023 <<
            //Sales_Order_Job_Task__c jobTask = (Sales_Order_Job_Task__c)JSON.deserialize(JSONJobTask, Sales_Order_Job_Task__c.class);
            ACVSalesOrderJobTaskWrapper jobTaskWrapper = (ACVSalesOrderJobTaskWrapper)JSON.deserialize(JSONJobTaskWrapper, ACVSalesOrderJobTaskWrapper.class);
            //ticket 19130 05.13.2023 >>
            //job task >>
            Sales_Line__c salesLine = (Sales_Line__c)JSON.deserialize(JSONSalesLine, Sales_Line__c.class);

            //job task <<
            //ticket 19130 05.13.2023 <<
            //SalesLinesService.initStaticVariables(salesOrder, salesLine);
            jobTaskWrapper.SalesLines.add(salesLine);
            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrapper);
            //ticket 19130 05.13.2023 >>
            //job task >>

            SalesLinesService.validateResourceType(salesOrder, salesLine);
            //if (1==1) throw new DataException('----------- ' + salesLine.Unit_Price__c);
            SalesLinesService.assignResourceTypeUOM(salesLine);

            //job task <<
            salesLine = SalesLinesService.explodeSalesLineDetails(salesOrder, salesLine);

            //ticket 19130 05.13.2023 <<
            /*
            List<Sales_Line__c> childLines = SalesLinesService.calculatePresumptiveChildLines(salesOrder, jobTask, salesLine, nextSalesLineNo);
            childLines = SalesLinesService.explodeSalesLineDetails(salesOrder, childLines);
            if (childLines.size() > 0) {
                salesLine = (Sales_Line__c) JSONUtils.attachListToParent(salesLine, childLines, 'Child_Lines__r');
            }
            */

            salesLine = SalesLinesService.calculatePresumptiveChildLines(salesOrder, jobTaskWrapper, salesLine, nextSalesLineNo);
            //ticket 19130 05.13.2023 >>

            //ticket 19130 06.07.2023 <<
            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrapper);

            Map<Integer, Sales_Line__c> mapChildSalesLinesByLineNo = new Map<Integer, Sales_Line__c>();
            for (Integer i = 0; i < jobTaskWrapper.SalesLines.size(); i++) {
                Sales_Line__c salesLine2 = jobTaskWrapper.SalesLines[i];
                if (salesLine2.Is_Child_Resource__c == true && (salesLine2.Category__c == 'Labor' || salesLine2.Category__c == 'Equipment') && (salesLine2.Sales_Line_Details__r == null || salesLine2.Sales_Line_Details__r.size() ==0)) {
                    //equipment schedule lines >>
                    if (salesLine2.Unit_of_Measure__r.Hours_UOM__c == true) {
                        if (salesOrder.Estimated_Job_Start_Time__c != null && salesOrder.Estimated_Job_End_Time__c != null) {
                            salesLine2.UOM_Qty__c = TimeUtils.calculateHours(salesOrder.Estimated_Job_Start_Time__c, salesOrder.Estimated_Job_End_Time__c);
                        }
                    }

                    salesLine2 = SalesLinesService.explodeSalesLineDetails(salesOrder, salesLine2);
                    mapChildSalesLinesByLineNo.put(salesLine2.Line_No__c.intValue(), salesLine2);
                }
            }
            
            Map<String,Object> salesLineMap = new Map<String, Object>();
            salesLineMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(salesLine));
            Map<String,Object> salesChildLinesMap = new Map<String, Object>();
            salesChildLinesMap = salesLineMap.containsKey('Sales_Child_Lines__r')?(Map<String,Object>)salesLineMap.get('Sales_Child_Lines__r'):new Map<String,Object>();
            List<Sales_Parent_Child_Relation__c> salesParentChildRelationList = new List<Sales_Parent_Child_Relation__c>();
            List<Object> salesParentChildList = new List<Object>();
           	salesParentChildList = salesChildLinesMap != null && salesChildLinesMap.containsKey('records')? (List<Object>)salesChildLinesMap.get('records'): new List<Object>();
            for(Object salesParentChild:salesParentChildList){
                salesParentChildRelationList.add((Sales_Parent_Child_Relation__c)JSON.deserialize(JSON.serialize(salesParentChild), Sales_Parent_Child_Relation__c.class));
            }
            
            if (salesParentChildRelationList.size() >0) {
                for (Sales_Parent_Child_Relation__c relation : salesLine.Sales_Child_Lines__r) {
                    if (relation.Child_Line__r != null) {
                        if (mapChildSalesLinesByLineNo.containsKey(relation.Child_Line__r.Line_No__c.intValue())) {
                            relation.Child_Line__r = mapChildSalesLinesByLineNo.get(relation.Child_Line__r.Line_No__c.intValue());
                        }
                    }
                }
            }

            //ticket 19130 06.07.2023 >>
            //job task >>

            SalesLinesService.calculateLineTotals(salesOrder, salesLine);

            //fix.null.fields <<
            //return salesLine;
            return JSON.serialize(salesLine);
            //fix.null.fields >>
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //job task <<
    @AuraEnabled
    public static String calculateLineTotals(String JSONSalesOrder, String JSONSalesLine) {
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            Sales_Line__c salesLine = (Sales_Line__c)JSON.deserialize(JSONSalesLine, Sales_Line__c.class);
            SalesLinesService.calculateLineTotals(salesOrder, salesLine);
            return JSON.serialize(salesLine);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    //job task >>

    @AuraEnabled
    //fix.null.fields <<
    //public static Sales_Line__c validateResource(String JSONSalesOrder, String JSONSalesLine) {
    //job task <<
    //public static String validateResource(String JSONSalesOrder, String JSONSalesLine) {
    //ticket 19130 05.03.2023 <<
    //public static String validateResource(String JSONSalesOrder, String JSONJobTask, String JSONSalesLine, Integer nextSalesLineNo) {
    public static String validateResource(String JSONSalesOrder, String JSONJobTaskWrapper, String JSONSalesLine, Integer nextSalesLineNo) {
    //ticket 19130 05.03.2023 >>
    //job task >>
    //fix.null.fields >>
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            //job task <<
            //ticket 19130 05.03.2023 <<
            //Sales_Order_Job_Task__c jobTask = (Sales_Order_Job_Task__c)JSON.deserialize(JSONJobTask, Sales_Order_Job_Task__c.class);
            ACVSalesOrderJobTaskWrapper jobTaskWrapper = (ACVSalesOrderJobTaskWrapper)JSON.deserialize(JSONJobTaskWrapper, ACVSalesOrderJobTaskWrapper.class);
            //ticket 19130 05.03.2023 >>
            //job task >>
            Sales_Line__c salesLine = (Sales_Line__c)JSON.deserialize(JSONSalesLine, Sales_Line__c.class);

            //job task <<
            //ticket 19130 05.03.2023 <<
            //SalesLinesService.initStaticVariables(salesOrder, salesLine);
            jobTaskWrapper.SalesLines.add(salesLine);
            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrapper);
            //ticket 19130 05.03.2023 >>
            //job task >>

            SalesLinesService.validateResource(salesOrder, salesLine);
            SalesLinesService.assignResourceUOM(salesLine);

            //ticket 19130 05.03.2023 <<
            /*
            //job task <<
            List<Sales_Line__c> childLines = SalesLinesService.calculatePresumptiveChildLines(salesOrder, jobTask, salesLine, nextSalesLineNo);

            //ticket 19789 <<
            childLines = SalesLinesService.explodeSalesLineDetails(salesOrder, childLines);
            //ticket 19789 >>

            if (childLines.size() > 0) {
                //attach child lines to the parent line
                salesLine = (Sales_Line__c)JSONUtils.attachListToParent(salesLine, childLines, 'Child_Lines__r');
            }
            //job task >>
            */
            salesLine = SalesLinesService.calculatePresumptiveChildLines(salesOrder, jobTaskWrapper, salesLine, nextSalesLineNo);
            //ticket 19130 05.03.2023 >>

            //ticket 19130 06.07.2023 <<
            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrapper);

            Map<Integer, Sales_Line__c> mapChildSalesLinesByLineNo = new Map<Integer, Sales_Line__c>();
            for (Integer i = 0; i < jobTaskWrapper.SalesLines.size(); i++) {
                Sales_Line__c salesLine2 = jobTaskWrapper.SalesLines[i];
                if (salesLine2.Is_Child_Resource__c == true && (salesLine2.Category__c == 'Labor' || salesLine2.Category__c == 'Equipment') && (salesLine2.Sales_Line_Details__r == null || salesLine2.Sales_Line_Details__r.size() ==0)) {
                    //equipment schedule lines >>
                    if (salesLine2.Unit_of_Measure__r.Hours_UOM__c == true) {
                        if (salesOrder.Estimated_Job_Start_Time__c != null && salesOrder.Estimated_Job_End_Time__c != null) {
                            salesLine2.UOM_Qty__c = TimeUtils.calculateHours(salesOrder.Estimated_Job_Start_Time__c, salesOrder.Estimated_Job_End_Time__c);
                        }
                    }

                    salesLine2 = SalesLinesService.explodeSalesLineDetails(salesOrder, salesLine2);
                    mapChildSalesLinesByLineNo.put(salesLine2.Line_No__c.intValue(), salesLine2);
                }
            }
            System.debug('salesLine.Sales_Child_Lines__r=====>'+JSON.serialize(salesLine));
            Map<String,Object> salesLineMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serialize(salesLine));
            Map<String,Object> salesChildLinesMap = salesLineMap.containsKey('Sales_Child_Lines__r')?(Map<String,Object>)salesLineMap.get('Sales_Child_Lines__r'):new Map<String,Object>();
            List<Sales_Parent_Child_Relation__c> salesParentChildRelationList = new List<Sales_Parent_Child_Relation__c>();
			System.debug('salesLine=====>'+JSON.serialize(salesChildLinesMap));
            List<Object> salesParentChildList = salesChildLinesMap != null && salesChildLinesMap.containsKey('records')? (List<Object>)salesChildLinesMap.get('records'): new List<Object>();
            for(Object salesParentChild:salesParentChildList){
                salesParentChildRelationList.add((Sales_Parent_Child_Relation__c)JSON.deserialize(JSON.serialize(salesParentChild), Sales_Parent_Child_Relation__c.class));
            }
            
            if (salesParentChildRelationList.size() >0) {
                for (Sales_Parent_Child_Relation__c relation : salesLine.Sales_Child_Lines__r) {
                    if (relation.Child_Line__r != null) {
                        if (mapChildSalesLinesByLineNo.containsKey(relation.Child_Line__r.Line_No__c.intValue())) {
                            relation.Child_Line__r = mapChildSalesLinesByLineNo.get(relation.Child_Line__r.Line_No__c.intValue());
                        }
                    }
                }
            }

            //ticket 19130 06.07.2023 >>

            SalesLinesService.calculateLineTotals(salesOrder, salesLine);

            //fix.null.fields <<
            //return salesLine;
            return JSON.serialize(salesLine);
            //fix.null.fields >>
        }
        catch(exception ex) {
            System.debug('e=====>'+ex.getLineNumber());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //ticket 19130 05.13.2023 <<
    /*
    //job task <<
    @AuraEnabled
    public static String calculatePresumptiveChildLines(String JSONSalesOrder, String JSONJobTask, String JSONSalesLine, Integer nextSalesLineNo) {
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            Sales_Order_Job_Task__c jobTask = (Sales_Order_Job_Task__c)JSON.deserialize(JSONJobTask, Sales_Order_Job_Task__c.class);
            Sales_Line__c salesLine = (Sales_Line__c)JSON.deserialize(JSONSalesLine, Sales_Line__c.class);

            SalesLinesService.initStaticVariables(salesOrder,  salesLine);
            List<Sales_Line__c> childLines = SalesLinesService.calculatePresumptiveChildLines(salesOrder, jobTask, salesLine, nextSalesLineNo);
            return JSON.serialize(childLines);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    //job task >>
    */
    //ticket 19130 05.13.2023 >>

    @AuraEnabled
    //fix.null.fields <<
    //public static Sales_Line__c validateNumberOfDays(String JSONSalesOrder, String JSONSalesLine) {
    public static String validateNumberOfDays(String JSONSalesOrder, String JSONSalesLine) {
    //fix.null.fields >>
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            Sales_Line__c salesLine = (Sales_Line__c)JSON.deserialize(JSONSalesLine, Sales_Line__c.class);

            //job task <<
            SalesLinesService.initStaticVariables(salesOrder, salesLine);
            //job task >>

            //equipment schedule lines <<
            //if (salesLine.Category__c == 'Labor') { //explode
            if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment') {
            //equipment schedule lines >>
                if (salesLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                    if (salesOrder.Estimated_Job_Start_Time__c != null && salesOrder.Estimated_Job_End_Time__c != null) {
                        salesLine.UOM_Qty__c = TimeUtils.calculateHours(salesOrder.Estimated_Job_Start_Time__c, salesOrder.Estimated_Job_End_Time__c);
                    }
                }
                //job task <<
                //salesLine = explodeSalesLineDetails(salesOrder, salesLine);
                salesLine = SalesLinesService.explodeSalesLineDetails(salesOrder, salesLine);
                //job task >>
            }

            SalesLinesService.calculateLineTotals(salesOrder, salesLine);

            //fix.null.fields <<
            //return salesLine;
            return JSON.serialize(salesLine);
            //fix.null.fields >>
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    //fix.null.fields <<
    //public static Sales_Line__c validateUnitOfMeasure(String JSONSalesOrder, String JSONSalesLine) {
    public static String validateUnitOfMeasure(String JSONSalesOrder, String JSONSalesLine) {
    //fix.null.fields >>
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            Sales_Line__c salesLine = (Sales_Line__c)JSON.deserialize(JSONSalesLine, Sales_Line__c.class);

            //job task <<
            SalesLinesService.initStaticVariables(salesOrder, salesLine);
            //job task >>

            SalesLinesService.validateUnitOfMeasure(salesOrder, salesLine);

            //job task <<
            //salesLine = recalculateSalesLineDetails(salesOrder, salesLine, true);
            SalesLinesService.recalculateSalesLineDetails(salesOrder, salesLine, false); //don't recalculate hours
            //job task >>

            SalesLinesService.calculateLineTotals(salesOrder, salesLine);

            //fix.null.fields <<
            //return salesLine;
            return JSON.serialize(salesLine);
            //fix.null.fields >>
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*
        Ticket#17051 - Init. sales lines service's static variable from the caller.
     */
    @AuraEnabled
    //fix.null.fields <<
    //public static Sales_Line__c calculatePriceAndCost(String JSONSalesOrder, String JSONSalesLine) {
    public static String calculatePriceAndCost(String JSONSalesOrder, String JSONSalesLine) {
    //fix.null.fields >>
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            Sales_Line__c salesLine = (Sales_Line__c)JSON.deserialize(JSONSalesLine, Sales_Line__c.class);

            //job task <<
            //SalesLinesService.initStaticVariables(new Map<Sales_Order__c, List<Sales_Line__c>>{ salesOrder => new List<Sales_Line__c>{ salesLine }});
            SalesLinesService.initStaticVariables(salesOrder, salesLine);
            //job task >>

            SalesLinesService.calcUnitPrice(salesOrder, salesLine);
            SalesLinesService.calcUnitCost(salesOrder, salesLine);

            //job task << not needed
            //salesLine = recalculateSalesLineDetails(salesOrder, salesLine, false);
            //job task >>

            SalesLinesService.calculateLineTotals(salesOrder, salesLine);

            //fix.null.fields <<
            //return salesLine;
            return JSON.serialize(salesLine);
            //fix.null.fields >>
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //job task <<  obsolete function
    /*
    @AuraEnabled
    //fix.null.fields <<
    //public static List<Sales_Line__c> calculateAllSalesLinesTotals(String JSONSalesOrder, String JSONSalesLines) {
    public static String calculateAllSalesLinesTotals(String JSONSalesOrder, String JSONSalesLines) {
    //fix.null.fields >>
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            List<Sales_Line__c> salesLines = (List<Sales_Line__c>)JSON.deserialize(JSONSalesLines, List<Sales_Line__c>.class);

            for (Sales_Line__c salesLine : salesLines) {
                SalesLinesService.calculateLineTotals(salesOrder, salesLine);
            }

            //rollup lump sum
            for (Sales_Line__c salesLine : salesLines) {
                if (salesLine.Category__c == 'Lump Sum') {
                    salesLine.Rolled_up_Unit_Price__c = 0;
                    for (Sales_Line__c salesLine2 : salesLines) {
                        if (salesLine2.Bill_as_Lump_Sum__c == true && salesLine2.Bundle_Line__r != null && salesLine2.Bundle_Line__r.Line_No__c == salesLine.Line_No__c) {
                            salesLine.Rolled_up_Unit_Price__c += salesLine2.xLine_Amount__c;
                            salesLine.Line_Cost__c += salesLine2.xLine_Cost__c;
                        }
                    }
                    if (salesLine.Rolled_up_Unit_Price__c > salesLine.Unit_Price__c) {
                        salesLine.Unit_Price__c = salesLine.Rolled_up_Unit_Price__c;
                    }
                    SalesLinesService.calculateLineTotals(salesOrder, salesLine);
                }
            }

            //fix.null.fields <<
            //return  salesLines;
            return JSON.serialize(salesLines);
            //fix.null.fields >>
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    */
    //job task >>

    @AuraEnabled
    //fix.null.fields <<
    //public static Sales_Line__c calculateSalesLine(String JSONSalesOrder, String JSONSalesLine) {
    public static String calculateSalesLine(String JSONSalesOrder, String JSONSalesLine, Boolean recalculateHours) {
    //fix.null.fields >>
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            Sales_Line__c salesLine = (Sales_Line__c)JSON.deserialize(JSONSalesLine, Sales_Line__c.class);

            //job task <<
            //salesLine = recalculateSalesLineDetails(salesOrder, salesLine, false);
            SalesLinesService.initStaticVariables(salesOrder, salesLine);
            SalesLinesService.recalculateSalesLineDetails(salesOrder, salesLine, recalculateHours);
            //job task >>
            SalesLinesService.calculateLineTotals(salesOrder, salesLine);

            //fix.null.fields <<
            //return salesLine;
            return JSON.serialize(salesLine);
            //fix.null.fields >>
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    //job task >>
    public static Integer getNextSalesLineNo(ACVSalesOrderJobTaskWrapper jobTaskWrapper, Integer nextSalesLineNo) {
        for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
            if (nextSalesLineNo < salesLine.Line_No__c.intValue()) {
                nextSalesLineNo = salesLine.Line_No__c.intValue();
            }
        }
        nextSalesLineNo++;
        return nextSalesLineNo;
    }
    //job task >>

    @AuraEnabled
    public static String getCostPlusMESResourceId() {
        ResourceConfig__mdt config = [SELECT Value__c FROM ResourceConfig__mdt WHERE DeveloperName = 'CostPlusMESResourceId' LIMIT 1];
        return config.Value__c;
    }

    public static void CostPlusMESResourceId() {
        String value = 'a0rf4000001ZQVmAAO';
        String devName = 'CostPlusMESResourceId';

    }

    public static void CostPlusMESResourceId2() {
        system.debug('method to test metadata value');
    }

    public static void CostPlusMESDevName() {
        system.debug('method to get devname');
    }

    //job task <<
    /*
    private static Sales_Line__c explodeSalesLineDetails(Sales_Order__c salesOrder, Sales_Line__c salesLine) {
        List<Sales_Line__c> salesLines = new List<Sales_Line__c> { salesLine };
        if (salesLines[0].Category__c == 'Labor') {
            SalesLinesService.explodeSalesLineDetails(salesOrder, salesLines);
        }
        return salesLines[0];
    }
    */
    //job task >>

    //job task <<
    /*
    @AuraEnabled
    //fix.null.fields <<
    //public static Sales_Line__c explodeSalesLineDetails(String JSONSalesOrder, String JSONSalesLine) {
    //job task <<
    //public static String explodeSalesLineDetails(String JSONSalesOrder, String JSONSalesLine) {
    public static String explodeSalesLineDetails(String JSONSalesOrder, String JSONSalesLine) {
    //job task >>
    //fix.null.fields >>
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            Sales_Line__c salesLine = (Sales_Line__c)JSON.deserialize(JSONSalesLine, Sales_Line__c.class);


            //job task <<
            //salesLine = explodeSalesLineDetails(salesOrder, salesLine);
            SalesLinesService.initStaticVariables(salesOrder, salesLine);
            salesLine = SalesLinesService.explodeSalesLineDetails(salesOrder, salesLine);
            //job task >>
            SalesLinesService.calculateLineTotals(salesOrder, salesLine);
            //fix.null.fields <<
            //return salesLine;
            return JSON.serialize(salesLine);
            //fix.null.fields >>
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    */
    //job task >>

    //job task <<
    /*
    private static Sales_Line__c recalculateSalesLineDetails(Sales_Order__c salesOrder, Sales_Line__c salesLine, Boolean recalculateHours) {
        List<Sales_Line__c> salesLines = new List<Sales_Line__c> { salesLine };
        if (salesLines[0].Category__c == 'Labor') {
            SalesLinesService.recalculateSalesLineDetails(salesOrder, salesLine, recalculateHours);
        }
        return salesLines[0];
    }
    */
    //job task >>

    //job task << obsolete function
    /*
    @AuraEnabled
    //fix.null.fields <<
    //public static Sales_Line__c recalculateSalesLineDetails(String JSONSalesOrder, String JSONSalesLine) {
    public static String recalculateSalesLineDetails(String JSONSalesOrder, String JSONSalesLine, Boolean calcuateHours) {
    //fix.null.fields >>
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            Sales_Line__c salesLine = (Sales_Line__c)JSON.deserialize(JSONSalesLine, Sales_Line__c.class);

            salesLine = recalculateSalesLineDetails(salesOrder, salesLine, calcuateHours);

            SalesLinesService.calculateLineTotals(salesOrder, salesLine);
            //fix.null.fields <<
            //return salesLine;
            return JSON.serialize(salesLine);
            //fix.null.fields >>
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    */
    //job task >>
     @AuraEnabled
    public static List<String> getValidUOMs(String billUnitCode) {
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