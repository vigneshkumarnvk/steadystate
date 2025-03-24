public with sharing class InterCompanyCostTrackingController {
    private ApexPages.StandardController standardController;
    private ApexPages.StandardSetController standardSetController;
    public String startingDateValue {get;set;}
    public String endingDateValue {get;set;}
    public User theUser { get; set; }
    public Boolean renderedButton {get;set;}
    public transient List<TM_Line__c> interCompanyTmLines {get; set;}

    public InterCompanyCostTrackingController(ApexPages.StandardController controller){
        standardController = controller;

        if(CompanyMgmt.getVFPageName() == 'InterCompanyCostTrackingExcel' || Test.isRunningTest()){
            startingDateValue = ApexPages.currentPage().getParameters().get('startingDate');
            endingDateValue = ApexPages.currentPage().getParameters().get('endingDate');
            preparePageData();
        }

    }

    public InterCompanyCostTrackingController(ApexPages.StandardSetController controller){
        standardSetController = controller;
        startingDateValue = Date.today().month() + '/' + Date.today().day() + '/' + Date.today().year();
        endingDateValue = startingDateValue;
        selectUser();
        renderedButton = true;
    }

    private void selectUser() {
        theUser = [SELECT Id, Name, FirstName, LastName, Phone, Service_Center__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    }

    public void checkDates(){
        System.debug('start: ' + startingDateValue);
        System.debug('end: ' + endingDateValue);
        Date startingDate = Date.parse(startingDateValue);
        Date endingDate = Date.parse(endingDateValue);
        //Integer noOfDays = startingDate.daysBetween(endingDate);
        if (startingDate > endingDate) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Days between Starting Date and Ending Date cannot be more than ' +  + ' days.'));
            renderedButton = false; return;
        }
        renderedButton = true;
    }

    public PageReference showInterCompanyCost(){
        try {
           preparePageData();
        } catch (Exception e) {
            System.debug('Error: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

    public PageReference saveAsExcel(){
        try{
            PageReference pageReference = new PageReference('/apex/InterCompanyCostTrackingExcel');
            pageReference.getParameters().put('startingDate', startingDateValue);
            pageReference.getParameters().put('endingDate', endingDateValue);
            pageReference.setRedirect(true);
            return pageReference;
        } catch (Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }

    public void preparePageData(){
            interCompanyTmLines = new List<TM_Line__c>();
            interCompanyTmLines = TMLinesSelector.newInstance().selectInterCompanyLineByScheduledDateRange(Date.parse(startingDateValue), Date.parse(endingDateValue));

            //map key => T&M SC:TM Line SC:Category
            Map<String,Decimal> intercoTMLineWithTotal = new Map<String, Decimal>();
            Map<String, List<TM_Line__c>> intercoTMLineByTMSCResSCAndCategory = new Map<String, List<TM_Line__c>>();

            for(TM_Line__c tmLine:interCompanyTmLines){
                String mapKey = tmLine.TM__r.Service_Center__r.Name + ':' + tmLine.Service_Center__r.Name + ':' + tmLine.Category__c;
                Decimal lineCost = 0;
                if(tmLine.TM__r.Status__c == 'Fully Invoiced' && String.isBlank(tmLine.Billing_Worksheet_Line__c)){
                    lineCost = CompanyMgmt.zeroIfNull(tmLine.Line_Cost__c);
                } else {
                    lineCost = CompanyMgmt.zeroIfNull(tmLine.Billing_Worksheet_Line__r.Line_Cost__c);
                }

                System.debug('Info: ' +  mapKey + ' **TM ' + tmLine.TM__r.Name + ' - '  + tmLine.Category__c + ' - ' + lineCost);

                if(intercoTMLineWithTotal.containsKey(mapKey)){
                    intercoTMLineWithTotal.put(mapKey, intercoTMLineWithTotal.get(mapKey) + lineCost);
                } else {
                    intercoTMLineWithTotal.put(mapKey, lineCost);
                }

                if(intercoTMLineByTMSCResSCAndCategory.containsKey(mapKey)){
                    List<TM_Line__c> interCoTmLines = intercoTMLineByTMSCResSCAndCategory.get(mapKey);
                    interCoTmLines.add(tmLine);
                    intercoTMLineByTMSCResSCAndCategory.put(mapKey, interCoTmLines);
                } else{
                    intercoTMLineByTMSCResSCAndCategory.put(mapKey, new List<TM_Line__c>{tmLine});
                }
            }

            List<InterCoCostWrap> interCoCostWraps = new List<InterCompanyCostTrackingController.InterCoCostWrap>();
            for(String mapKey: intercoTMLineByTMSCResSCAndCategory.keySet()){
                //0 => T&M Service Center, 1 => Resource Service Center, 2 => Category
                String[] keyElement = mapKey.split(':');
                InterCoCostWrap interCoCostWrap = new InterCoCostWrap();
                interCoCostWrap.description = 'Service Center ' + keyElement[0] +' Due to Service Center ' + keyElement[1];
                interCoCostWrap.category = keyElement[2];
                interCoCostWrap.totalCost = intercoTMLineWithTotal.get(mapKey);
                System.debug('Info: total cost ' + mapKey + ' -- ' + interCoCostWrap.totalCost);
                List<TM_Line__c> tmLines = intercoTMLineByTMSCResSCAndCategory.get(mapKey);
                /*
                for(TM_Line__c tmLine : tmLines){
                    if(tmLine.TM__r.Status__c == 'Fully Invoiced' && String.isBlank(tmLine.Billing_Worksheet_Line__c)){
                        tmLine.Billing_Worksheet_Line__r = new Billing_Worksheet_Line__c(
                                Cost_Qty__c = tmLine.Cost_Qty__c,
                                Line_Cost__c = tmLine.Line_Cost__c,
                                Unit_Cost__c = tmLine.Unit_Cost__c
                                );
                    }
                }
                 */
                interCoCostWrap.tmLines = tmLines;
                interCoCostWraps.add(interCoCostWrap);
            }

            interCoCostWrapList = interCoCostWraps;
    }

    public class InterCoCostWrap {
        /*
        private AggregateResult ar;
        public String description { get{ return (String)ar.get('Description'); } }
        public Decimal totalCost {get{ return ((Decimal)ar.get('TotalCost')).setScale(2);}}
        public String category {get {return (String)ar.get('Category__c'); }}
        public InterCoCostWrap(AggregateResult ar){
            this.ar = ar;
        */
        public String description {get; set;}
        public Decimal totalCost {get;set;}
        public String category {get;set;}
        public List<TM_Line__c> tmLines {get; set;}
    }

    public transient List<InterCoCostWrap> interCoCostWrapList { get;set; }
}