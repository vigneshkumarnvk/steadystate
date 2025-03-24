global with sharing class TMLLinesService {

    global static void initStaticVariables(Map<TM__c, List<TM_Line__c>> tmLinesByTms){
        service().initStaticVariables(tmLinesByTms);
    }

    //job task <<<
    global static void initStaticVariables(TM__c tm, List<ACVTMJobTaskWrapper> jobTaskWrappers) {
        List<TM_Line__c> tmLines = new List<TM_Line__c>();
        for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            tmLines.addAll(jobTaskWrapper.TMLines);
        }
        Map<TM__c, List<TM_Line__c>> tmLinesByTms = new Map<TM__c, List<TM_Line__c>>();
        tmLinesByTms.put(tm, tmLines);
        service().initStaticVariables(tmLinesByTms);
    }

    global static void initStaticVariables(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper) {
        initStaticVariables(tm, new List<ACVTMJobTaskWrapper>{ jobTaskWrapper });
    }

    global static void initStaticVariables(TM__c tm, TM_Line__c tmLine) {
        ACVTMJobTaskWrapper jobTaskWrapper = new ACVTMJobTaskWrapper();
        jobTaskWrapper.TMLines.add(tmLine);
        initStaticVariables(tm, jobTaskWrapper);
    }
    //job task >>

    global static void populateLinesInfo(Map<TM__c, List<TM_Line__c>> tmLinesByTMs){
        service().populateLinesInfo(tmLinesByTMs);
    }

    global static void validateTMLinesRestOfFields(List<TM_Line__c> theTMLList){
        service().validateTMLinesRestOfFields(theTMLList);
    }

    global static void validateTMLinesUnitOfMeasure(List<TM_Line__c> theTMLList){
        service().validateTMLinesUnitOfMeasure(theTMLList);
    }

    global static void validateTMLinesResourceType(List<TM_Line__c> theTMLList){
        service().validateTMLinesResourceType(theTMLList);
    }

    global static Map<Id, String> retrieveContractLinesTMDescription(List<TM_Line__c> theTMLList){
        return service().retrieveContractLinesTMDescription(theTMLList);
    }

    global static void calcTotals(Map<TM__c, List<TM_Line__c>> tmLinesByTms){
        service().calcTotals(tmLinesByTms);
    }

    global static void calcLineCost(Map<TM__c, List<TM_Line__c>> tmLinesByTms){
        service().calcLineCost(tmLinesByTms);
    }

    global static void calcUnitCost(TM__c tm, TM_Line__c tmLine){
        service().calcUnitCost(tm, tmLine);
    }

    global static void calcUnitPrice(TM__c tm, TM_Line__c tmLine){
        service().calcUnitPrice(tm, tmLine);
    }

    global static void validateResourceType(TM__c tm, TM_Line__c tmLine){
        service().initStaticVariables(new Map<TM__c, List<TM_Line__c>>{tm => new List<TM_Line__c>{tmLine}});
        service().validateResourceType(tm, tmLine);
    }
    // Added by TA461964 for too many soql issues
    global static void validateTMResourceType(TM__c tm, TM_Line__c tmLine){
        service().validateResourceType(tm, tmLine);
    }
    // Added by TA461964 for too many soql issues
    global static void validateTMRTStaticVariables(Map<TM__c, List<TM_Line__c>> tmlineMap)
    {
    	service().initStaticVariables(tmlineMap);   
    }

    global static void validateResourceType(TM__c tm, TM_Line__c tmLine, Boolean initStaticMapData){
        if(initStaticMapData == true){
            service().initStaticVariables(new Map<TM__c, List<TM_Line__c>>{tm => new List<TM_Line__c>{tmLine}});
        }
        service().validateResourceType(tm, tmLine);
    }

    global static void validateResource(TM__c tm, TM_Line__c tmLine){
        service().initStaticVariables(new Map<TM__c, List<TM_Line__c>>{tm => new List<TM_Line__c>{tmLine}});
        service().validateResource(tm, tmLine);
    }

    //Ticket#18265
    global static void validateContractLine(TM__c tm, TM_Line__c tmLine){
        service().initStaticVariables(new Map<TM__c, List<TM_Line__c>>{tm => new List<TM_Line__c>{tmLine}});
        service().validateContractLine(tm, tmLine);
    }

    global static Boolean isCalcBaseOnResType(String lineCategory){
        return service().isCalcBaseOnResType(lineCategory);
    }

    //Ticket#18747 check lunch time
    global static Boolean isLunchTimeValid(Time jobStartTime, Time jobEndTime, Time lunchStartTime, Time lunchEndTime, Time siteStartTime, Time siteEndTime){
        Boolean isValid = true;
        if(jobStartTIme != null && jobEndTime != null && lunchStartTime != null && lunchEndTime != null && siteStartTime != null && siteEndTime != null){
            //normal shift job
            if(jobStartTIme < jobEndTime){
                if(lunchEndTime > jobEndTime || lunchStartTime < jobStartTIme || lunchEndTime < jobStartTime || (lunchStartTime < siteEndTime && lunchEndTime > siteEndTime) || (lunchStartTime > jobStartTime && lunchStartTime < siteStartTime && lunchEndTime > siteStartTime)){
                    return false;
                }
            }
            if(jobEndTime == TimeUtils.midNight()){
                if(lunchStartTime < jobStartTime || lunchEndTime < jobStartTime){
                    return false;
                }
            }

            //overnight shift job
            if(jobStartTime >= jobEndTime){
                if(lunchStartTime < jobStartTime){
                    if(lunchStartTime > jobEndTime || lunchEndTime > jobEndTime) {
                        return false;
                    }
                }
            }

            Decimal totalJobHours = TimeUtils.calculateHours(jobStartTime, jobEndTime);
            Decimal totalLunchHours = TimeUtils.calculateHours(lunchStartTime, lunchEndTime);
            if(totalLunchHours > totalJobHours){
                return false;
            }
        }
        return isValid;
    }

    /*
     *  Ticket#21547
     *  Ticket#22112
     *      - Prevent site hour greater than the job hour.
     *  Ticket#23385
     *      - Prevent total travel time is greater than total job hours.
     */
    global static Boolean isJobAndSiteTimeValid(Time jobStartTime, Time jobEndTime, Time siteStartTime, Time siteEndTime){
        Boolean isValid = true;
        if(jobStartTime != null && jobEndTime != null && siteStartTime != null && siteEndTime != null){
            if(siteStartTime < jobStartTime && (jobEndTime > jobStartTime || jobStartTime == jobEndTime) && jobEndTime != TimeUtils.midNight()){
                isValid = false;
            }
            if(siteEndTime < siteStartTime){
                if(TimeUtils.calculateHours(siteStartTime, siteEndTime) > TimeUtils.calculateHours(jobStartTime, jobEndTime)) {
                    isValid = false;
                }
            }
            if(jobStartTime != siteStartTime){
                Decimal travelToSite = TimeUtils.calculateHours(jobStartTime, siteEndTime);
                Decimal totalJobTime = TimeUtils.calculateHours(jobStartTime, jobEndTime);
                if(travelToSite > totalJobTime){
                    isValid = false;
                }
            }
            if(siteEndTime != jobEndTime){
                Decimal travelFromSite = TimeUtils.calculateHours(siteEndTime, jobEndTime);
                Decimal totalJobTime = TimeUtils.calculateHours(jobStartTime, jobEndTime);
                if(travelFromSite > totalJobTime){
                    isValid = false;
                }
            }
        }
        return isValid;
    }

    //PW Travel Hours Cost
    global static Decimal calculateTravelHours(TM_Line__c tmLine){
        Decimal travelHours = 0;
        if(tmLine.Category__c == ResourceService.LABOR_CATEGORY){
            if(tmLine.Job_Start_Time__c != null && tmLine.Site_Start_Time__c != null && tmLine.Job_Start_Time__c != tmLine.Site_Start_Time__c){
                travelHours = TimeUtils.calculateHours(tmLine.Job_Start_Time__c, tmLine.Site_Start_Time__c);
            }

            if(tmLine.Site_End_Time__c != null && tmLine.Job_End_Time__c != null && tmLine.Site_End_Time__c != tmLine.Job_End_Time__c){
                travelHours = travelHours + TimeUtils.calculateHours(tmLine.Site_End_Time__c, tmLine.Job_End_Time__c);
            }
        }
        return travelHours;
    }

    /*
        Lunch time checking for Kronos
        Ticket#23365 - add lunch end time to the checking
     */
    global static Boolean lunchTimeCheckForKronos(Time jobStartTime, Time jobEndTime, Time siteStartTime, Time siteEndTime, Time lunchStartTime, Time lunchEndTime){
        Boolean isValid = true;
        if(jobStartTime != null && jobEndTime != null && siteStartTime != null && siteEndTime != null && lunchStartTime != null){
            if(lunchStartTime == jobStartTime || lunchStartTime == jobEndTime || lunchStartTime == siteStartTime || lunchStartTime == siteEndTime){
                isValid = false;
            }

            if(lunchEndTime == jobEndTime || lunchEndTime == siteEndTime){
                isValid = false;
            }
        }
        return isValid;
    }

    //job task <<
    global static void validateUnitOfMeasure(TM__c tm, TM_Line__c tmLine) {
        //ticket 18178 <<
        service().initStaticVariables(new Map<TM__c, List<TM_Line__c>>{tm => new List<TM_Line__c>{tmLine}});
        service().validateUnitOfMeasure(tm, tmLine);
        //ticket 18178 >>
    }

    //Ticket#24525
    global static void validateUnitOfMeasure(TM__c tm, TM_Line__c tmLine, Boolean initVariable){
        if(initVariable == true){
            service().initStaticVariables(new Map<TM__c, List<TM_Line__c>>{tm => new List<TM_Line__c>{tmLine}});
        }
        service().validateUnitOfMeasure(tm, tmLine);
    }
    //ticket 19130 05.13.23 <<
    /*
    global static List<TM_Line__c> calculatePresumptiveChildLines(TM__c tm, TM_Job_Task__c jobTask, TM_Line__c tmLine, Integer nextTMLineNo) {
        return service().calculatePresumptiveChildLines(tm, jobTask, tmLine, nextTMLineNo);
    }
    */
    global static TM_Line__c calculatePresumptiveChildLines(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper, TM_Line__c tmLine, Integer nextTMLineNo) {
        return service().calculatePresumptiveChildLines(tm, jobTaskWrapper, tmLine, nextTMLineNo);
    }
    //ticket 19130 05.13.2023 >>

    /*
    global static void createFlatPayLines(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper, Integer nextTMLineNo) {
        service().createFlatPayLines(tm, jobTaskWrapper, nextTMLineNo);
    }
     */

    global static void createSafetyPlanLine(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper, Integer nextTMLineNo) {
        service().createSafetyPlanLine(tm, jobTaskWrapper, nextTMLineNo);
    }

    global static void calculateManifestFeeLine(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper, Integer nextTMLineNo) {
        service().calculateManifestFeeLine(tm, jobTaskWrapper, nextTMLineNo);
    }
    global static void calculateRinseOutFeeLine(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper, Integer nextTMLineNo) {
        service().calculateRinseOutFeeLine(tm, jobTaskWrapper, nextTMLineNo);
    }
    //job task >>

    private static ITMLLinesService service(){
        return (ITMLLinesService) Application.Service.newInstance(ITMLLinesService.class);
    }
}