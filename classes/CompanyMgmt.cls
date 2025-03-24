/*************************************************************************************************
* Name         :  CompanyMgmt
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan      10-13-2024             US127188 - Salesforce - Modifications to allow ESIC Surcharge Type 
*************************************************************************************************/
public with sharing class CompanyMgmt {
    //job task <<
    public static Company_Setup__c companySetup { get; }
    //job task >>

    // public flag
    // Set in Classes when Save, or Post 
    public static Boolean systemCall { get; set; }
    //Need this flag to bypass some trigger codes in order reduce SOQL
    //Only 200 records are processed at one time in trigger
    public static Boolean massCreateInvoice { get; set; }
    // Users cannot delete ledger entris or closed documents
    // This flag can be set in Developer Console Anonymous Windows for future compression routines   
    public static Boolean allowToDeleteData { get; set; }
    //By pass trigger code flag
    public static Boolean byPassTrigger {get; set;}
    //Make after trigger is only run once
    public static Boolean approvalCall{get; set;}
    /////////////////////////////////////////////////
    public static Boolean byPassLineTrigger{get; set;}

    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();

    public static Map<String, Decimal> mapSalesTax = new Map<String, Decimal>();
    public static Map<Id, Resource_Type__c> mapResourceType = new Map<Id, Resource_Type__c>();
    public static Map<Id, Resource__c> mapResource = new Map<Id, Resource__c>();
    public static Map<Id, Unit_of_Measure__c> mapUnitOfMeasures = new Map<Id, Unit_of_Measure__c>();
    /////////////////////////////////////////////////
    // Check special permissions
    // Need to be very careful of the use of it to preserve data integration
    public static Boolean allowDataOverride() {
        System.debug('User Info::' + UserInfo.getName());
        Special_Permissions__c theCustSett = Special_Permissions__c.getvalues(UserInfo.getName());
        System.debug('Custom Setting :: ' + theCustSett);
        if (theCustSett != null && theCustSett.Permitted__c && theCustSett.Permitted_Date__c == Date.today()) {
            return true;
        } else {
            return false;
        }
    }

    public static decimal zeroIfNull(decimal num) {

        if (num == null) num = 0;
        return num;
    }

    public static decimal halfUpTo2D(decimal num) {
        if (num == null) num = 0; else num = num.setScale(2, RoundingMode.HALF_UP);
        return num;
    }

    public static decimal halfUpTo3D(decimal num) {
        if (num == null) num = 0; else num = num.setScale(3, RoundingMode.HALF_UP);
        return num;
    }

    public static decimal halfUpTo5D(decimal num) {
        if (num == null) num = 0; else num = num.setScale(5, RoundingMode.HALF_UP);
        return num;
    }

    public static Boolean checkPostingDate(date postingDate) {
        Company_Setup__c companySetup = [SELECT Allow_Posting_From__c, Allow_Posting_To__c FROM Company_Setup__c LIMIT 1];

        if (companySetup.Allow_Posting_From__c != null && companySetup.Allow_Posting_To__c != null &&
                postingDate >= companySetup.Allow_Posting_From__c && postingDate <= companySetup.Allow_Posting_To__c) {
            return true;
        }

        return false;
    }

    public static Company_Setup__c getCompanySetup() {
        //job task <<
        if (companySetup != null) {
            return  companySetup;
        }
        //job task >>

        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Company_Setup__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ', Default_Field_Remediation_Resource__r.Name, Default_Waste_Disposal_Resource__r.Name, Default_Transportation_Resource__r.Name, Default_Fuel_Surcharge_Resource__r.Name ' ;
        strQuery += ', Default_Lump_Sum_Resource__r.Name, Default_Misc_Charges_Taxes_Resource__r.Name, Default_Subcontractor_Resource__r.Name,Default_Inter_Co_Tax_Area__r.Name ';
        strQuery += ', Default_Field_Remediation_Resource__r.Unit_Cost__c, Default_Waste_Disposal_Resource__r.Unit_Cost__c, Default_Transportation_Resource__r.Unit_Cost__c, Default_Fuel_Surcharge_Resource__r.Unit_Cost__c ' ;
        strQuery += ', Default_Lump_Sum_Resource__r.Unit_Cost__c, Default_Misc_Charges_Taxes_Resource__r.Unit_Cost__c, Default_Subcontractor_Resource__r.Unit_Cost__c ';
        strQuery += ', Default_Energy_Insurance_Resource__r.Name, Default_Energy_Insurance_Resource__r.Description__c, Default_Fuel_Surcharge_Resource__r.Description__c,Default_ESIC_Surcharge_Resource__r.Description__c '; // W-000021
        //aura <<
        strQuery += ', Default_Energy_Insurance_Resource__r.Unit_of_Measure__c, Default_Energy_Insurance_Resource__r.Unit_of_Measure__r.Name';
        strQuery += ', Default_Fuel_Surcharge_Resource__r.Unit_of_Measure__c, Default_Fuel_Surcharge_Resource__r.Unit_of_Measure__r.Name';
        strQuery += ', Default_ESIC_Surcharge_Resource__r.Unit_of_Measure__c, Default_ESIC_Surcharge_Resource__r.Unit_of_Measure__r.Name';
        strQuery += ', Default_Lump_Sum_Resource__r.Description__c, Default_Lump_Sum_Resource__r.Unit_of_Measure__c, Default_Lump_Sum_Resource__r.Unit_of_Measure__r.Name';
        strQuery += ', Default_Subcontractor_Resource__r.Description__c, Default_Subcontractor_Resource__r.Unit_of_Measure__c, Default_Subcontractor_Resource__r.Unit_of_Measure__r.Name';
        //job task <<
        strQuery += ', Default_Safety_Plan_Resource__r.Name, Default_Safety_Plan_Resource__r.Description__c, Default_Safety_Plan_Resource__r.Unit_of_Measure__c';
        strQuery += ', Default_Manifest_Fee_Resource__r.Name, Default_Manifest_Fee_Resource__r.Description__c, Default_Manifest_Fee_Resource__r.Unit_of_Measure__c, Default_Manifest_Fee_Resource__r.Unit_of_Measure__r.Name,' +
                'Default_Manifest_Fee_Resource__r.Unit_Cost__c';
        //job task >>
        //Ticket#20496 >>
        strQuery += ', Default_Billing_Rule__r.Name, Default_Billing_Rule__r.Enable_Weekly_Total_Calculation__c';
        //Ticket#20496 <<
        strQuery += ', Quote_Default_Payment_Term__r.Name';
        //aura >>
        strQuery += ' FROM Company_Setup__c LIMIT 1';

        //job task <<
        //return Database.query(strQuery);
        companySetup = Database.query(strQuery);
        return companySetup;
        //job task >>
    }

    public static date calcDate(date baseDate, decimal dateCalc) {
        if (baseDate == null) {
            baseDate = date.today();
        }

        if (dateCalc != null) {
            return baseDate.addDays(integer.valueOf(dateCalc));
        } else {
            return baseDate;
        }
    }

    public static Boolean checkUnpostPermission() {
        User theUser = [SELECT Allow_Unpost__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        return theUser.Allow_Unpost__c;
    }

    public static Map<String, Numbering_Series__c> getNumber(string InputName) {
        // System.debug('<==InputName==>'+InputName);
				
        // to override user permission to allow update on numbering series
        systemCall = true;

        Numbering_Series__c theNumberingSeries;
        Decimal LastNumberUsed;

        // Only Get is Numbering Series is not got yet (not in the memory yet)
        // This is done to bulkify code
        if (mapNumberSeries.get(InputName) == null) {
            for (Numbering_Series__c theNS : [SELECT Id,Name,Prefix__c, Separator__c, Last_Number_Used__c FROM Numbering_Series__c WHERE Name = :InputName LIMIT 1 FOR UPDATE]) {
                mapNumberSeries.put(theNS.Name, theNS);
                System.debug('Running Query');
            }
        }

        // System.debug(mapNumberSeries);

        theNumberingSeries = mapNumberSeries.get(InputName);
        LastNumberUsed = CompanyMgmt.zeroIfNull(theNumberingSeries.Last_Number_Used__c) + 1;
        theNumberingSeries.Last_Number_Used__c = LastNumberUsed;

        if (theNumberingSeries.Prefix__c == null) theNumberingSeries.Prefix__c = '';
        if (theNumberingSeries.Separator__c == null) theNumberingSeries.Separator__c = '';
        mapNumberSeries.put(InputName, theNumberingSeries) ;
        return mapNumberSeries;

        // return theNumberingSeries.Prefix__c + theNumberingSeries.Separator__c + String.valueOf(LastNumberUsed);
    }

    public static Decimal getSalesTax(String taxArea, String taxGroup) {
        string myKey = taxArea + ';' + taxGroup;
        List<Tax_Detail__c> theTDList = new List<Tax_Detail__c>();
        List<Tax_Detail__c> theTDList2;
        Decimal taxPct = 0;

        /*theTDList = [SELECT Tax_Pct__c FROM Tax_Detail__c
        WHERE Tax_Area__c = :taxArea AND Tax_Group__c = :taxGroup];

        system.debug('scott3/' + theTDList + '/' + taxArea + '/' + taxGroup);

        for (Integer i = 0; i < theTDList.size(); i++) {
            taxPct += theTDList[i].Tax_Pct__c;
        }*/
        //job task <<
        /*
        if(!mapSalesTax.containsKey(myKey)) {
            for (Tax_Detail__c theTaxDetail : [SELECT Tax_Pct__c, Tax_Area__c, Tax_Group__c FROM Tax_Detail__c WHERE Tax_Area__c = :taxArea AND Tax_Group__c =: taxGroup]) {
                if(string.isEmpty(theTaxDetail.Tax_Area__c) || string.isEmpty(theTaxDetail.Tax_Group__c)) {
                    continue;
                }
                if (mapSalesTax.get(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c) == null) {
                    mapSalesTax.put(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c, theTaxDetail.Tax_Pct__c);
                }
                else {
                    mapSalesTax.put(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c, mapSalesTax.get(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c) + theTaxDetail.Tax_Pct__c);
                }
            }
        }
        */
        if (string.isEmpty(taxArea) || string.isEmpty(taxGroup)) {
            mapSalesTax.put(myKey, 0);
        }
        else {
            if (!mapSalesTax.containsKey(myKey)) {
                for (Tax_Detail__c theTaxDetail : [SELECT Tax_Pct__c, Tax_Area__c, Tax_Group__c FROM Tax_Detail__c WHERE Tax_Area__c = :taxArea AND Tax_Group__c = :taxGroup]) {
                    if (mapSalesTax.get(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c) == null) {
                        mapSalesTax.put(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c, theTaxDetail.Tax_Pct__c);
                    } else {
                        mapSalesTax.put(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c, mapSalesTax.get(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c) + theTaxDetail.Tax_Pct__c);
                    }
                }
            }
        }
        //job task >>

        if (mapSalesTax.containsKey(myKey)) {
            taxPct = mapSalesTax.get(myKey);
        } else {
            taxPct = 0;
        }

        return taxPct;
    }

    public static string getVFPageName() {
    
        if(test.isrunningtest()) Return 'Test';
        
        String pageName = ApexPages.CurrentPage().getUrl();
        pageName = pageName.replaceFirst('/apex/', '');
        pageName = EncodingUtil.urlEncode(pageName, 'UTF-8');
        string[] pageNameExtra = pageName.split('%3F', 0);
        pageName = pageNameExtra[0];
        return pageName;
    }

    public static Decimal CheckGLConsistency(List<GL_Entry__c> theGLList) {
        Decimal totalAmount = 0;

        for (Integer i = 0; i < theGLList.size(); i++) {
            totalAmount += CompanyMgmt.halfUpTo2D(theGLList[i].Amount__c);
        }

        return totalAmount;
    }

    public static List<GL_Entry__c> getBatchId(List<GL_Entry__c> theGLList, Id SubsidiaryId) {
        Id GLBatchId;
        List<GL_Batch__c> theGLBatchList = new List<GL_Batch__c>();
        List<GL_Batch__c> theGLBatchUpdateList = new List<GL_Batch__c>();
        Company_Setup__c theCompanySetup = getCompanySetup();

        // Get Batch Id
        theGLBatchList = [
                SELECT Id, Name, No_of_Lines__c
                FROM GL_Batch__c
                WHERE Closed__c = false AND Subsidiary_Company__c =:SubsidiaryId
                ORDER BY Name DESC
        ];

        if (theGLBatchList != null && theGLBatchList.size() > 0) {
            //system.debug('scott' + '/' + theGLBatchList[0].Name + '/' + theGLBatchList[0].GL_Entries__r.size());
            if ((theGLBatchList[0].No_of_Lines__c + theGLList.size()) > theCompanySetup .GL_Integration_Batch_Size__c) {
                GL_Batch__c theGLBatch = new GL_Batch__c();
                theGLBatch.Subsidiary_Company__c = SubsidiaryId;
                insert theGLBatch;
                GLBatchId = theGLBatch.Id;
            } else {
                GLBatchId = theGLBatchList[0].Id;
            }
            // Create a new batch
        } else {
            GL_Batch__c theGLBatch = new GL_Batch__c();
            theGLBatch.Subsidiary_Company__c = SubsidiaryId;
            insert theGLBatch;
            GLBatchId = theGLBatch.Id;
        }

        for (Integer i = 0; i < theGLList.size(); i++) {
            theGLList[i].GL_Batch__c = GLBatchId;
        }

        // close other open batches
        theGLBatchList = [
                SELECT Id, Total_Amount__c, No_of_Lines__c
                FROM GL_Batch__c
                WHERE Closed__c = false AND Id != :GLBatchId AND Subsidiary_Company__c =: SubsidiaryId
                ORDER BY Name DESC
        ];

        for (GL_Batch__c theGLB : theGLBatchList) {
            //List<GL_Entry__c> theGLList2 = new List<GL_Entry__c>();
            //theGLList2 = theGLB.GL_Entries__r;
            if (theGLB.Total_Amount__c == 0) {
                theGLB.Closed__c = true;
                theGLB.Description__c = 'Total ' + theGLB.No_of_Lines__c + ' records. Closed at ' + System.now();
                theGLBatchUpdateList.add(theGLB);
            }
        }
        update theGLBatchUpdateList;

        // return
        return theGLList;
    }

    public static List<String> checkDeleteGLB(GL_Batch__c theGLB) {
        List<String> errorList = new List<String>();
        if (CompanyMgmt.systemCall != true) {
            errorList.add('You are not allowed to delete GL Batch.');
        } else if (theGLB.Closed__c == true) {
            errorList.add('You cannot delete GL Batch because it is closed.');
        } else if (theGLB.No_of_Lines__c != 0) {
            errorList.add('You cannot delete GL Batch because it is used on GL Entry.');
        }
        return errorList;
    }

    public static dateTime convertLocalDatetime(dateTime inputDateTime) {
        Datetime localDateTime;
        if (inputDateTime != null) {
            Integer offset = UserInfo.getTimezone().getOffset(inputDateTime);
            localDateTime = inputDateTime.addSeconds(offset / 1000);
        } else {
            localDateTime = null;
        }
        return localDateTime;
    }
    // Ticket AES-416
    public static Resource_Type__c getResourceType(Id RTId) {
        Resource_Type__c theResourceType;
        if (!mapResourceType.containsKey(RTId)) {
            theResourceType = [
                SELECT Id, Name, Description__c, Fleet_No_Required__c, Unit_of_Measure__c, Unit_of_Measure1__c, Unit_of_Measure2__c, Unit_of_Measure3__c, Unit_of_Measure4__c,
                Silver_ER_Rate__c, Silver_ER_Rate1__c, Silver_ER_Rate2__c, Silver_ER_Rate3__c, Silver_ER_Rate4__c, 
                Silver_Rate__c, Silver_Rate1__c, Silver_Rate2__c, Silver_Rate3__c, Silver_Rate4__c, 
                Gold_ER_Rate__c, Gold_ER_Rate1__c, Gold_ER_Rate2__c, Gold_ER_Rate3__c, Gold_ER_Rate4__c,
                Gold_Rate__c, Gold_Rate1__c, Gold_Rate2__c, Gold_Rate3__c, Gold_Rate4__c ,
                Platinum_ER_Rate__c, Platinum_ER_Rate1__c, Platinum_ER_Rate2__c, Platinum_ER_Rate3__c, Platinum_ER_Rate4__c,
                Platinum_Rate__c, Platinum_Rate1__c, Platinum_Rate2__c, Platinum_Rate3__c, Platinum_Rate4__c, Unit_Cost__c,
                Unit_of_Measure__r.Name,Unit_Cost1__c, Unit_Cost2__c, Unit_Cost3__c, Unit_Cost4__c, Fuel_Fired_Equipment__c
                FROM Resource_Type__c
                WHERE Id = :RTId
                LIMIT 1
            ];
            mapResourceType.put(RTId, theResourceType);
            //SalesOrderMgmt.mapResourceType = mapResourceType;
            //SalesOrderController.mapResourceType = mapResourceType;
            //CustomLookupController.mapResourceType = mapResourceType;
        }
        theResourceType = mapResourceType.get(RTId);

        return theResourceType;
    }
    
    public static Resource__c getResource(Id RId) {
        Resource__c theResource;
        if (!mapResource.containsKey(RId)) {
            theResource = [
                SELECT Id, Name, Description__c, Service_Center__c, Resource_Type__c, Resource_Type__r.Name, 
                Unit_of_Measure__c, Unit_of_Measure__r.Name,Unit_of_Measure1__c, Unit_of_Measure2__c, Unit_of_Measure3__c, Unit_of_Measure4__c,
                Silver_ER_Rate__c, Silver_ER_Rate1__c, Silver_ER_Rate2__c, Silver_ER_Rate3__c, Silver_ER_Rate4__c, 
                Silver_Rate__c, Silver_Rate1__c, Silver_Rate2__c, Silver_Rate3__c, Silver_Rate4__c, 
                Gold_ER_Rate__c, Gold_ER_Rate1__c, Gold_ER_Rate2__c, Gold_ER_Rate3__c, Gold_ER_Rate4__c,
                Gold_Rate__c, Gold_Rate1__c, Gold_Rate2__c, Gold_Rate3__c, Gold_Rate4__c ,
                Platinum_ER_Rate__c, Platinum_ER_Rate1__c, Platinum_ER_Rate2__c, Platinum_ER_Rate3__c, Platinum_ER_Rate4__c,
                Platinum_Rate__c, Platinum_Rate1__c, Platinum_Rate2__c, Platinum_Rate3__c, Platinum_Rate4__c, Unit_Cost__c,
                        Unit_Cost1__c, Unit_Cost2__c, Unit_Cost3__c, Unit_Cost4__c
                FROM Resource__c
                WHERE Id = :RId
                LIMIT 1
            ];
            mapResource.put(RId, theResource);

            //SalesOrderMgmt.mapResource = mapResource;
            //SalesOrderController.mapResource = mapResource;
            //CustomLookupController.mapResource = mapResource;
        }
        theResource = mapResource.get(RId);

        return theResource;
    }

    public static Unit_of_Measure__c getUnitOfMeasures(Id RId) {
        Unit_of_Measure__c theUnitOfMeasure;
        if (!mapUnitOfMeasures.containsKey(RId)) {
            theUnitOfMeasure = [
                    SELECT Id, Name, Hours_UOM__c
                    FROM Unit_of_Measure__c
                    WHERE Id = :RId
                    LIMIT 1
            ];
            mapUnitOfMeasures.put(RId, theUnitOfMeasure);
        }
        theUnitOfMeasure = mapUnitOfMeasures.get(RId);

        return theUnitOfMeasure;
    }
    
    //ticket 21113 <<
    public static Boolean getEmailDeliverability() {
        Boolean turnedOn = false;
        try {
            Messaging.reserveSingleEmailCapacity(0);
            turnedOn = true;
        }
        catch (System.NoAccessException e) {
        }

        return turnedOn;
    }
    //ticket 21113 >>
}