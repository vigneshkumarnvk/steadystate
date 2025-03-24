/**********************************************************
* Page Name: CustomLookupController
* Author: Ashish
* Date: 14-May-2017
* Requirement # Request Id:
* Description: Apex Controller  for all Lookups
**********************************************************/
/*
 *  Ticket#19962
 *      - add special scenario lookup for Bill-to Customer when cloning quote.
 *          - add function selectBillingToOnCloneSO();
 *          - update function fetchSpecialScenario();
 */
public with sharing class CustomLookupController {
    public List<SObject> sobjList {get; set;}
    public List<String> fieldapiname{get; set;}
    public String sObjectName { get; set; }
    public String sObjectLabel { get; set; }
    public String LinkFieldName { get; set; }
    public String FieldSetName { get; set; }
    private String filterString;
    public Boolean fltr1 { get; set; }
    public Boolean fltr2 { get; set; }
    public Boolean fltr3 { get; set; }
    public Boolean fltr4 { get; set; }
    public Boolean fltr5 { get; set; }
    public Boolean fltr6 { get; set; }
    public Boolean fltr7 { get; set; }
    private Integer validParm;
    private transient Map<String, String> Parameters {get; set;}
    private transient Map<String, String> FieldValueMap {get; set;}
    private transient Map<String, String> FieldOperationMap {get; set;}
    private transient Map<String, String> FieldTypeMap {get; set;}

    public String calledFrom{get;set;}
    public String calledFor{get;set;}
    public String controllingValue{get; set;}
    public Boolean isSpecialScenario { get; set; }
    @TestVisible
    private transient Map<String, String> SpecialFieldValueMap {get; set;}
    private transient Map<String, String> SpecialFieldOperationMap {get; set;}
    private transient Map<String, String> SpecialFieldTypeMap {get; set;}

    public String filterInput { get; set; }
    public String selFilterField { get; set; }
    public String selFilterOp { get; set; }
    Map<String, String> mapfieldAndLabel = new Map<String, String>();
    Map<String, Schema.DisplayType> mapfieldAndType = new Map<String, Schema.DisplayType>();
    String MaxRows = '';
    public Integer originalSizeOfList { get; set; }
    public String queryFieldNames;
    public Integer maxLookupRows { get; set; }
    public String orderBy { get; set; }
    
    private Map<String, String> SetupFields = new Map<String, String>{ // W-000394
            'topFilter' => 'topFilter',
            'LookupObject' => 'LookupObject',
            'LinkFieldName' => 'LinkFieldName',
            'ElementId' => 'ElementId',
            'LookupNameId' => 'LookupNameId',
            'FieldSetName' => 'FieldSetName',
            'LookupType' => 'LookupType',
            'invokefrm' => 'invokefrm',
            'RunValidation' => 'RunValidation',
            'ValidateFunction' => 'ValidateFunction',
            'fltr1' => 'fltr1',
            'fltr2' => 'fltr2',
            'fltr3' => 'fltr3',
            'fltr4' => 'fltr4',
            'fltr5' => 'fltr5',
            'fltr6' => 'fltr6',
            'fltr7' => 'fltr7',
            'calledFrom' => 'calledFrom',
            'calledFor' => 'calledFor',
            'isSpecialScenario' => 'isSpecialScenario',
            'controllingValue' => 'controllingValue',
            'orderBy' => 'orderBy'
    };

    public CustomLookupController() {
        originalSizeOfList = 0;
        filterString = '';
        validParm = 0;
        FieldValueMap = new Map<String, String>();
        FieldTypeMap = new Map<String, String>();
        FieldOperationMap = new Map<String, String>();
        queryFieldNames = '';

        SpecialFieldValueMap = new Map<String, String>();
        SpecialFieldTypeMap = new Map<String, String>();
        SpecialFieldOperationMap = new Map<String, String>();

        Parameters = ApexPages.currentPage().getParameters();
        for(String s:Parameters.keySet()) Parameters.put(s,String.escapeSingleQuotes(Parameters.get(s))); //sanitized Info Security
        sObjectName = String.escapeSingleQuotes(Parameters.get('LookupObject'));//sanitized Info Security
        LinkFieldName = String.escapeSingleQuotes(Parameters.get('LinkFieldName'));//sanitized Info Security
        FieldSetName = String.escapeSingleQuotes(Parameters.get('FieldSetName'));//sanitized Info Security

        if(Parameters.containsKey('orderBy')){
            orderBy = String.escapeSingleQuotes(Parameters.get('orderBy'));
            System.debug('Info orderBy ' + orderBy);
        }
        
        MaxRows = getMaxLookUpRows();
        fltr1 = Parameters.get('fltr1').equalsIgnoreCase('true');
        fltr2 = Parameters.get('fltr2').equalsIgnoreCase('true');
        fltr3 = Parameters.get('fltr3').equalsIgnoreCase('true');
        fltr4 = Parameters.get('fltr4').equalsIgnoreCase('true');
        fltr5 = Parameters.get('fltr5').equalsIgnoreCase('true');
        fltr6 = Parameters.get('fltr6').equalsIgnoreCase('true');
        fltr7 = Parameters.get('fltr7').equalsIgnoreCase('true');

        if (String.isEmpty(Parameters.get('calledFrom'))) {
            calledFrom = '';
        } else {
            calledFrom = String.escapeSingleQuotes(Parameters.get('calledFrom'));
        }

        if(String.isEmpty(Parameters.get('calledFor'))) {
            calledFor = '';
        } else {
            calledFor = String.escapeSingleQuotes(Parameters.get('calledFor'));
        }

        if(String.isEmpty(Parameters.get('isSpecialScenario'))) {
            isSpecialScenario = false;
        } else {
            isSpecialScenario = Parameters.get('isSpecialScenario').equalsIgnoreCase('true');
        }

        for (String flds : Parameters.keySet()) {
            if (SetupFields.get(flds) == null) {
                if (!flds.endsWith('_Special')) {
                    if (flds.endsWith('_Operation')) {
                        FieldOperationMap.put(flds, Parameters.get(flds));
                    } else if (flds.endsWith('_Type')) {
                        FieldTypeMap.put(flds, Parameters.get(flds));
                    } else {
                        FieldValueMap.put(flds, Parameters.get(flds));
                        if (Parameters.get(flds) != '') validParm++;
                    }
                } else {
                    if (flds.endsWith('_Operation_Special')) {
                        SpecialFieldOperationMap.put(flds, Parameters.get(flds));
                    } else if (flds.endsWith('_Type_Special')) {
                        SpecialFieldTypeMap.put(flds, Parameters.get(flds));
                    } else {
                        SpecialFieldValueMap.put(flds, Parameters.get(flds));
                    }
                }
            }
        }
        getData();
        
        maxLookupRows = Integer.valueOf(MaxRows);
    }

    public void getData() {
        MaxRows = getMaxLookUpRows();
        
        FieldSetName = String.escapeSingleQuotes(FieldSetName);//sanitized Info Security
        sObjectName = String.escapeSingleQuotes(sObjectName);//sanitized Info Security
        List<Schema.FieldSetMember> Fieldset = readFieldSet(FieldSetName, sObjectName);
        Integer cnt = 1;
        fieldapiname = new List<String>();
        filterString = '';
        // Generating Filter String
        if (FieldValueMap.size() > 0) {
            for (String fld : FieldValueMap.keySet()) {

                if (FieldValueMap.get(fld) != '') {

                    filterString = filterString + ' ' + fld + ' ';

                    //Adding Operation
                    if (FieldOperationMap.get(fld + '_Operation') == '=') {
                        filterString = filterString + ' = ';
                    } else if (FieldOperationMap.get(fld + '_Operation') == 'Like') {
                        filterString = filterString + ' Like ';
                    } else {
                        filterString = filterString + ' ' + FieldOperationMap.get(fld + '_Operation') + ' ';
                    }

                    //Adding Value
                    if (FieldTypeMap.get(fld + '_Type') == 'String' && FieldOperationMap.get(fld + '_Operation') == 'Like') {
                        filterString = filterString + '\'%' + String.escapeSingleQuotes(FieldValueMap.get(fld)) + '%\'';
                    } else if (FieldTypeMap.get(fld + '_Type') == 'String' && FieldOperationMap.get(fld + '_Operation') != 'Like') {
                        filterString = filterString + '\'' + FieldValueMap.get(fld) + '\'';
                    } else if (((FieldTypeMap.get(fld + '_Type') == 'Integer') || (FieldTypeMap.get(fld + '_Type') == 'Boolean')) && (FieldOperationMap.get(fld + '_Operation') == 'Like')) {
                        filterString = filterString + '\'%' + String.escapeSingleQuotes(FieldValueMap.get(fld)) + '%\'';
                    } else if (((FieldTypeMap.get(fld + '_Type') == 'Integer') || (FieldTypeMap.get(fld + '_Type') == 'Boolean')) && (FieldOperationMap.get(fld + '_Operation') != 'Like')) {
                        filterString = filterString + ' ' + FieldValueMap.get(fld) + ' ';
                    } else if (((FieldTypeMap.get(fld + '_Type') == 'Date')) && (FieldOperationMap.get(fld + '_Operation') != 'Like')) {
                        filterString = filterString + ' ' + FieldValueMap.get(fld) + ' ';
                    } else if (FieldTypeMap.get(fld + '_Type') == 'Includes') {
                        filterString = filterString + ' (\'' + FieldValueMap.get(fld) + '\') ';// Ticket# AES-401
                    }

                    //checking for AND Condition
                    if (cnt < validParm) {
                        filterString = filterString + ' AND ' ;
                        cnt++;
                    }
                } else {
                    if (FieldTypeMap.get(fld + '_Type') == 'String' && FieldOperationMap.get(fld + '_Operation') != 'Like') {
                        filterString = filterString + ' ' + fld + ' ';
                        if (FieldOperationMap.get(fld + '_Operation') == '=') {
                            filterString = filterString + ' = ';
                        } else {
                            filterString = filterString + ' ' + FieldOperationMap.get(fld + '_Operation') + ' ';
                        }
                        filterString = filterString + '\'' + FieldValueMap.get(fld) + '\'';

                        if (cnt < validParm) {
                            filterString = filterString + ' AND ' ;
                        }
                    }
                }
            }
        }

        if (!isSpecialScenario) {
            String query = 'SELECT ';
            for (Schema.FieldSetMember f : Fieldset) {
                fieldapiname.add(f.getFieldPath());
                query += f.getFieldPath() + ', ';
                queryFieldNames += f.getFieldPath() + ', ';
                
                mapfieldAndLabel.put(f.getFieldPath(), f.getLabel());
                mapfieldAndType.put(f.getFieldPath(), f.getType());
            }
            
            queryFieldNames += 'ID ';
            
            if (filterString != '') {
                if(String.isNotBlank(orderBy)){
                    query += ' ID FROM ' + sObjectName + ' WHERE ' + filterString + ' ORDER BY ' + orderBy + ' LIMIT ' + MaxRows;
                } else {
                    query += ' ID FROM ' + sObjectName + ' WHERE ' + filterString + ' ORDER BY Name LIMIT ' + MaxRows;
                }
            } else {
                query += ' ID FROM ' + sObjectName + ' LIMIT ' + MaxRows;
            }
            System.debug('Info: query: ' + query);
            sobjList = new List<SObject>();
            sobjList = Database.query(query);
        } else {
            fetchSpecialScenario(Fieldset);
        }

        originalSizeOfList = sobjList.size();
        if (sobjList.size() == Integer.valueOf(MaxRows)) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'Returned Results > ' + MaxRows + '. Limit Results First!'); ApexPages.addMessage(myMsg);
        }

    }

    public  List<Schema.FieldSetMember> readFieldSet(String fieldSetName, String ObjectName) {
        ObjectName = Misc.convertObjectdName(ObjectName);
        fieldSetName = Misc.converFieldSetdName(fieldSetName);

        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
        Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(ObjectName);
        Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
        sObjectLabel = DescribeSObjectResultObj.getLabelPlural();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.fieldSets.getMap().get(fieldSetName);
        return fieldSetObj.getFields();
    }

    @TestVisible
    private void fetchSpecialScenario(List<Schema.FieldSetMember> Fieldset) {
        if (!String.isEmpty(calledFrom) && !String.isEmpty(calledFor)) {
            if(calledFrom == 'CloneSalesOrder'){
                if (calledFor == 'BillToLookup') {
                    selectBillingToOnCloneSO(Fieldset);
                }
            }
            /*
            if (calledFrom == 'TM') {
                if (calledFor == 'EquipmentResourceLookup') {
                    selectEquipmentLookupOnTM(Fieldset);
                }

                if (calledFor == 'LaborResourceLookup') {
                    selectLaborLookupOnTM(Fieldset);
                }

                if(calledFor == 'LUOMLookUp' || calledFor == 'EUOMLookUp' || calledFor == 'LumpUOMLookUp'){
                    selectResourceTypeUOMs(Fieldset);
                } else if (calledFor == 'MUOMLookUp' || calledFor == 'SUOMLookUp' || calledFor == 'WUOMLookUp' ||
                          calledFor == 'DUOMLookUp') {
                    selectResourceUOMs(Fieldset);
                } else if (calledFor == 'ResourceTypeUOMLookup'){
                    selectResourceTypeUOMList(Fieldset);
                } else if (calledFor == 'ContractLineLookup'){
                    selectContractLineOnTM(Fieldset);
                }
            }

            if (calledFrom == 'SalesOrder') {
                if(calledFor == 'LLUOMLookUp' || calledFor == 'ELUOMLookUp' || calledFor == 'LumpUOMLookUp'){
                    selectResourceTypeUOMs(Fieldset);
                } else if(calledFor == 'MLUOMLookUp' || calledFor == 'WUOMLookUp' || calledFor == 'MiscUOMLookUp') {
                    selectResourceUOMs(Fieldset);
                } else if (calledFor == 'ContractLookUp') { //AES-440
                    selectContractAndCorporateContract (Fieldset);
                } else if (calledFor == 'BillToCustomerLookUp'){
                    selectBillToCustomer(Fieldset);
                } else if (calledFor == 'ResourceTypeUOMLookup'){
                    selectResourceTypeUOMList(Fieldset);
                } else if (calledFor == 'ResourceUOMLookup'){
                    selectResourceUOMList(Fieldset);
                } else if (calledFor == 'ContainerSizeLookup'){
                    selectContainerSize(Fieldset);
                } else if (calledFor == 'WeightVolumeLookup'){
                    selectWeightVolume(Fieldset);
                }
            }


            System.debug('Info: calledFrom ' + calledFrom);
            System.debug('Info: calledFor ' + calledFor);
            if(calledFrom == 'FieldActivityLog'){
                if (calledFor == 'FALEquipmentLookup'){
                    System.debug('Info: FieldActivityLog FALEquipment ');
                    selectFALEquipmentList(Fieldset);
                }
            }
             */
        }
    }

    @TestVisible
    private void selectLaborLookupOnTM(List<Schema.FieldSetMember> Fieldset) {
        /*
        String scheduledDateValue;
        Date scheduledDate;

        if (SpecialFieldValueMap.containsKey('ScheduleDate_Special')) {
            scheduledDateValue = String.valueOf(SpecialFieldValueMap.get('ScheduleDate_Special'));
        }

        if (String.isNotEmpty(scheduledDateValue)) {
            scheduledDate = Date.parse(scheduledDateValue);
        }

        String strWhereClause = ' WHERE (Start_Date__c = null OR Start_Date__c <= :scheduledDate) ' +
                ' AND (End_Date__c = null OR End_Date__c >= :scheduledDate) ';

        String query = 'SELECT ';
        for (Schema.FieldSetMember f : Fieldset) {
            fieldapiname.add(f.getFieldPath());
            query += f.getFieldPath() + ', ';
        }
        if (filterString != '') {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' AND ' + filterString + ' ORDER BY Name LIMIT ' + MaxRows;
        } else {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' LIMIT ' + MaxRows;
        }

        sobjList = new List<SObject>();

        sobjList = Database.query(query);
         */
    }

    /*
    @TestVisible
    private void selectEquipmentLookupOnTM(List<Schema.FieldSetMember> Fieldset) {
        String scheduledDateValue;
        Date scheduledDate;
        List<TM_Line__c> theRentalTMLList = new List<TM_Line__c>();
        List<Resource_Off__c> theAllResourceOffList = new List<Resource_Off__c>();
        List<Rental_Order__c> theAllRentalOrdersList = new List<Rental_Order__c>();

        Set<String> setResourceTML = new Set<String>();
        Set<String> setRentalTML = new Set<String>();
        Set<String> setResourceOff = new Set<String>();
        Set<String> setRentalOrders = new Set<String>();

        if (SpecialFieldValueMap.containsKey('ScheduleDate_Special')) {
            scheduledDateValue = String.valueOf(SpecialFieldValueMap.get('ScheduleDate_Special'));

            if(!String.isEmpty(scheduledDateValue)) {
                scheduledDate = Date.parse(scheduledDateValue);
                theRentalTMLList = ResourceMgmt.selectRentalTML(scheduledDateValue, null);
                if (theRentalTMLList != null && theRentalTMLList.size() > 0) {
                    for (TM_Line__c theTML : theRentalTMLList) {
                        setRentalTML.add(theTML.Resource__c);
                    }
                }

                theAllResourceOffList = ResourceMgmt.selectAllResourceOff(scheduledDateValue, null);
                if (theAllResourceOffList != null && theAllResourceOffList.size() > 0) {
                    for (Resource_Off__c theResourceOff : theAllResourceOffList) {
                        setResourceOff.add(theResourceOff.Resource__c);
                    }
                }

                theAllRentalOrdersList = ResourceMgmt.selectAllRentalOrders(scheduledDateValue, null);
                if (theAllRentalOrdersList != null && theAllRentalOrdersList.size() > 0) {
                    for (Rental_Order__c theRO : theAllRentalOrdersList) {
                        setRentalOrders.add(theRO.Resource__c);
                    }
                }
            }
        }

        String strWhereClause = ' WHERE Id NOT IN: setResourceTML AND Id NOT IN: setRentalTML ' +
                ' AND Id NOT IN: setResourceOff AND Id NOT IN: setRentalOrders ' +
                ' AND (Start_Date__c = null OR Start_Date__c <= :scheduledDate) ' +
                ' AND (End_Date__c = null OR End_Date__c >= :scheduledDate) ';

        String query = 'SELECT ';
        for (Schema.FieldSetMember f : Fieldset) {
            fieldapiname.add(f.getFieldPath());
            query += f.getFieldPath() + ', ';
        }
        if (filterString != '') {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' AND ' + filterString + ' ORDER BY Name LIMIT 1000';
        } else {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' ORDER BY Name LIMIT 1000';
        }

        sobjList = new List<SObject>();

        sobjList = Database.query(query);
    }
     */

    /*
    @TestVisible
    private void selectResourceTypeUOMList(List<Schema.FieldSetMember> Fieldset) {
        String ResourceTypeId;
        List<String> lstUOM = new List<String>();

        if(SpecialFieldValueMap.containsKey('ResourceType_Special')) {
            ResourceTypeId = String.valueOf(SpecialFieldValueMap.get('ResourceType_Special'));
            if(!String.isEmpty(ResourceTypeId)){
                List<ResourceTypeUOMAssociation__c> resourceTypeUOMAssociations =
                        ResourceTypeUnitOfMeasuresSelector.newInstance().selectByResTypeId(new Set<Id>{ResourceTypeId});

                for(ResourceTypeUOMAssociation__c resourceTypeUOMAssociation:resourceTypeUOMAssociations){
                    lstUOM.add(resourceTypeUOMAssociation.Unit_of_Measure__c);
                }
            }
        }

        String strWhereClause = ' WHERE Id IN: lstUOM';

        String query = 'SELECT ';
        for (Schema.FieldSetMember f : Fieldset ) {
            fieldapiname.add(f.getFieldPath());
            query += f.getFieldPath() + ', ';
        }
        if (filterString != '') {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' AND ' + filterString + ' ORDER BY Name LIMIT 1000';
        } else {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' ORDER BY Name LIMIT 1000';
        }

        sobjList = new List<SObject>();

        sobjList = Database.query(query);
    }
     */

    /*
    @TestVisible
    private void selectContainerSize(List<Schema.FieldSetMember> Fieldset){
        Id resId;
        List<Id> lstUOM = new List<Id>();

        for(String s: SpecialFieldValueMap.keySet()){
            System.debug('Info: s ' + s);
            System.debug('Info: s Value ' + SpecialFieldValueMap.get(s));
        }

        if(SpecialFieldValueMap.containsKey('Resource_Special')) {
            resId = String.valueOf(SpecialFieldValueMap.get('Resource_Special'));
            Id weightVolumeId;
            if(SpecialFieldValueMap.containsKey('UnitWeightVolume_Special')){
                String s = String.valueOf(SpecialFieldValueMap.get('UnitWeightVolume_Special'));
                if(String.isNotBlank(s)) weightVolumeId = s;
            }

            System.debug('Info: weightVolumeId ' + weightVolumeId);
            System.debug('Info: redId ' + resId);
            if(!String.isEmpty(resId)){
                List<ResourceUOMAssociation__c> resourceUOMAssociations =
                        ResourceUnitOfMeasuresSelector.newInstance().selectByResId(new Set<Id>{resId});

                if(String.isNotBlank(controllingValue)){
                    if(controllingValue == EnumUtil.CostMethod.CONTAINER.name() == true){
                        for(ResourceUOMAssociation__c resourceUOMAssociation:resourceUOMAssociations){
                            lstUOM.add(resourceUOMAssociation.Unit_of_Measure__c);
                        }
                    } else if(controllingValue == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name() == true) {
                        for (ResourceUOMAssociation__c resourceUOMAssociation : resourceUOMAssociations) {
                            if (resourceUOMAssociation.Container_Size__c != null && resourceUOMAssociation.Unit_of_Measure__c == weightVolumeId) lstUOM.add(resourceUOMAssociation.Container_Size__c);
                        }
                    }
                }

                if(lstUOM.size() == 0){
                    for(Unit_of_Measure__c uom: UnitOfMeasuresSelector.newInstance().selectContainerSizes()){
                        lstUOM.add(uom.Id);
                    }
                }
            }
        }

        String strWhereClause = ' WHERE Id IN: lstUOM';

        String query = 'SELECT ';
        for (Schema.FieldSetMember f : Fieldset ) {
            fieldapiname.add(f.getFieldPath());
            query += f.getFieldPath() + ', ';
        }
        if (filterString != '') {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' AND ' + filterString + ' ORDER BY Name LIMIT 1000';
        } else {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' ORDER BY Name LIMIT 1000';
        }

        sobjList = new List<SObject>();

        sobjList = Database.query(query);
    }

    @TestVisible
    private void selectWeightVolume(List<Schema.FieldSetMember> Fieldset){
        Id resId;
        List<Id> lstUOM = new List<Id>();
        if(SpecialFieldValueMap.containsKey('Resource_Special')) {
            resId = String.valueOf(SpecialFieldValueMap.get('Resource_Special'));

            if(!String.isEmpty(resId)){
                List<ResourceUOMAssociation__c> resourceUOMAssociations =
                        ResourceUnitOfMeasuresSelector.newInstance().selectByResId(new Set<Id>{resId});

                if(String.isNotBlank(controllingValue)){
                    if(controllingValue == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name() == true) {
                        for (ResourceUOMAssociation__c resourceUOMAssociation : resourceUOMAssociations) {
                            lstUOM.add(resourceUOMAssociation.Unit_of_Measure__c);
                        }
                    }
                }

                if(lstUOM.size() == 0){
                    for(Unit_of_Measure__c uom: UnitOfMeasuresSelector.newInstance().selectWeightVolumes()){
                        lstUOM.add(uom.Id);
                    }
                }
            }
        }

        String strWhereClause = ' WHERE Id IN: lstUOM';

        String query = 'SELECT ';
        for (Schema.FieldSetMember f : Fieldset ) {
            fieldapiname.add(f.getFieldPath());
            query += f.getFieldPath() + ', ';
        }
        if (filterString != '') {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' AND ' + filterString + ' ORDER BY Name LIMIT 1000';
        } else {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' ORDER BY Name LIMIT 1000';
        }

        sobjList = new List<SObject>();

        sobjList = Database.query(query);
    }
     */

    /*
    @TestVisible
    private void selectResourceUOMList(List<Schema.FieldSetMember> Fieldset) {
        Id resId;
        List<Id> lstUOM = new List<Id>();

        if(SpecialFieldValueMap.containsKey('Resource_Special')) {
            resId = String.valueOf(SpecialFieldValueMap.get('Resource_Special'));
            if(!String.isEmpty(resId)){
                List<ResourceUOMAssociation__c> resourceUOMAssociations =
                        ResourceUnitOfMeasuresSelector.newInstance().selectByResId(new Set<Id>{resId});

                for(ResourceUOMAssociation__c resourceUOMAssociation:resourceUOMAssociations){
                    lstUOM.add(resourceUOMAssociation.Unit_of_Measure__c);
                }
            }
        }

        String strWhereClause = ' WHERE Id IN: lstUOM';

        String query = 'SELECT ';
        for (Schema.FieldSetMember f : Fieldset ) {
            fieldapiname.add(f.getFieldPath());
            query += f.getFieldPath() + ', ';
        }
        if (filterString != '') {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' AND ' + filterString + ' ORDER BY Name LIMIT 1000';
        } else {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' ORDER BY Name LIMIT 1000';
        }

        sobjList = new List<SObject>();

        sobjList = Database.query(query);
    }
     */

    @TestVisible
    private void selectResourceTypeUOMs(List<Schema.FieldSetMember> Fieldset) {
        /*
        String ResourceTypeId;
        List<String> lstUOM = new List<String>();

        if (SpecialFieldValueMap.containsKey('ResourceType_Special')) {
            ResourceTypeId = String.valueOf(SpecialFieldValueMap.get('ResourceType_Special'));
            if(!String.isEmpty(ResourceTypeId)) {
                Resource_Type__c theResourceType = CompanyMgmt.getResourceType(ResourceTypeId);

                lstUOM.add(theResourceType.Unit_of_Measure__c);
                lstUOM.add(theResourceType.Unit_of_Measure1__c);
                lstUOM.add(theResourceType.Unit_of_Measure2__c);
                lstUOM.add(theResourceType.Unit_of_Measure3__c);
                lstUOM.add(theResourceType.Unit_of_Measure4__c);
            }
        }

        String strWhereClause = ' WHERE Id IN: lstUOM';

        String query = 'SELECT ';
        for (Schema.FieldSetMember f : Fieldset) {
            fieldapiname.add(f.getFieldPath());
            query += f.getFieldPath() + ', ';
        }
        if (filterString != '') {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' AND ' + filterString + ' ORDER BY Name LIMIT 1000';
        } else {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' ORDER BY Name LIMIT 1000';
        }

        sobjList = new List<SObject>();

        sobjList = Database.query(query);
         */
    }

    /*
    @TestVisible
    private void selectResourceUOMs(List<Schema.FieldSetMember> Fieldset) {
        String ResourceId;
        List<String> lstUOM = new List<String>();

        if (SpecialFieldValueMap.containsKey('Resource_Special')) {
            ResourceId = String.valueOf(SpecialFieldValueMap.get('Resource_Special'));
            if(!String.isEmpty(ResourceId)) {
                Resource__c theResource = CompanyMgmt.getResource(ResourceId);

                lstUOM.add(theResource.Unit_of_Measure__c);
                lstUOM.add(theResource.Unit_of_Measure1__c);
                lstUOM.add(theResource.Unit_of_Measure2__c);
                lstUOM.add(theResource.Unit_of_Measure3__c);
                lstUOM.add(theResource.Unit_of_Measure4__c);
            }
        }

        String strWhereClause = ' WHERE Id IN: lstUOM';

        String query = 'SELECT ';
        for (Schema.FieldSetMember f : Fieldset) {
            fieldapiname.add(f.getFieldPath());
            query += f.getFieldPath() + ', ';
        }
        if (filterString != '') {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' AND ' + filterString + ' ORDER BY Name LIMIT 1000';
        } else {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' ORDER BY Name LIMIT 1000';
        }

        sobjList = new List<SObject>();

        sobjList = Database.query(query);
    }
     */
        
    // AES-440
    /*
    private void selectContractAndCorporateContract(List<Schema.FieldSetMember> Fieldset) {
        String selectedAccountId;
        List<String> lstAccountId = new List<String>();
        if(SpecialFieldValueMap.containsKey('AccountId_Special')) {
            selectedAccountId = String.valueOf(SpecialFieldValueMap.get('AccountId_Special'));
            if (String.isNotBlank(selectedAccountId)){
                lstAccountId = selectedAccountId.split(',');
            }
        }

        String strWhereClause = ' WHERE Id IN (SELECT Contract__c FROM Account_Contract_Association__c WHERE Account__c IN: lstAccountId AND Contract__r.Status != \'Inactive\')';
        //String strWhereClause = ' WHERE AccountId IN: lstAccountId AND Status != \'Inactive\'';
        String query = 'SELECT ';
        for (Schema.FieldSetMember f : Fieldset ) {
            fieldapiname.add(f.getFieldPath());
            query += f.getFieldPath() + ', ';
        }
        if (filterString != '') {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' AND ' + filterString + ' ORDER BY Name LIMIT 1000';
        } else {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' ORDER BY Name LIMIT 1000';
        }

        sobjList = new List<SObject>();
        sobjList = Database.query(query);

    }
     */

    /*
    private void selectBillToCustomer(List<Schema.FieldSetMember> Fieldset) {
        String selectedSubsidiaryCompanyId;
        if(SpecialFieldValueMap.containsKey('Subsidiary_Company__c_Special')) {
            selectedSubsidiaryCompanyId = String.valueOf(SpecialFieldValueMap.get('Subsidiary_Company__c_Special'));
        }

        String strWhereClause = ' WHERE Subsidiary_Company__c =: selectedSubsidiaryCompanyId';
        String query = 'SELECT ';
        for (Schema.FieldSetMember f : Fieldset ) {
            fieldapiname.add(f.getFieldPath());
            query += f.getFieldPath() + ', ';
        }
        if (filterString != '') {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' AND ' + filterString + ' ORDER BY Name LIMIT 1000';
        } else {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' AND Type = \'Customer\' AND Customer_Status__c = \'Active\' ORDER BY Name LIMIT 1000';
        }

        sobjList = new List<SObject>();
        sobjList = Database.query(query);
    }
     */

    /*
    @TestVisible
    private void selectContractLineOnTM(List<Schema.FieldSetMember> Fieldset) {
        String scheduledDateValue;
        Date scheduledDate;

        if (SpecialFieldValueMap.containsKey('ScheduleDate_Special')) {
            scheduledDateValue = String.valueOf(SpecialFieldValueMap.get('ScheduleDate_Special'));
        }

        if (String.isNotEmpty(scheduledDateValue)) {
            scheduledDate = Date.parse(scheduledDateValue);
        }

        String strWhereClause = ' WHERE (Blocked__c = false OR End_Date__c >= :scheduledDate) ';

        String query = 'SELECT ';
        for (Schema.FieldSetMember f : Fieldset) {
            fieldapiname.add(f.getFieldPath());
            query += f.getFieldPath() + ', ';
        }
        if (filterString != '') {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' AND ' + filterString + ' ORDER BY Name LIMIT ' + MaxRows;
        } else {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' LIMIT ' + MaxRows;
        }

        sobjList = new List<SObject>();

        sobjList = Database.query(query);
    }
     */
    @TestVisible
    private void selectBillingToOnCloneSO(List<Schema.FieldSetMember> Fieldset){
        String covertToDocumentType;

        if (SpecialFieldValueMap.containsKey('CovertToDocumentType_Special')) {
            covertToDocumentType = String.valueOf(SpecialFieldValueMap.get('CovertToDocumentType_Special'));
        }

        if(covertToDocumentType == 'Quote') {
            String strWhereClause = ' WHERE (Type = \'Customer\' OR Type = \'Prospect\') ';
            String query = 'SELECT ';
            for (Schema.FieldSetMember f : Fieldset) {
                fieldapiname.add(f.getFieldPath());
                query += f.getFieldPath() + ', ';
            }
            if (filterString != '') {
                query += 'ID FROM ' + sObjectName + strWhereClause + ' AND ' + filterString + ' ORDER BY Name LIMIT ' + MaxRows;
            } else {
                query += 'ID FROM ' + sObjectName + strWhereClause + ' LIMIT ' + MaxRows;
            }

            sobjList = new List<SObject>();
            //System.debug('Info: selectBillingToOnCloneSO ' + query);
            sobjList = Database.query(query);
        }
    }
    
    public List<SelectOption> lstFilterOperator {
        get {
            if (lstFilterOperator == null) {
                lstFilterOperator = new List<SelectOption>();
                lstFilterOperator.add(new SelectOption('contains', 'contains'));
                lstFilterOperator.add(new SelectOption('equals', 'equals'));
                lstFilterOperator.add(new SelectOption('not contains', 'not contains'));
                lstFilterOperator.add(new SelectOption('greater than or equal', 'greater than or equal'));
                lstFilterOperator.add(new SelectOption('less than or equal', 'less than or equal'));
            }
            return lstFilterOperator;
        }
        set;
    }

    public List<SelectOption> lstFilterField {
        get {
            String strValue = '';
            if (lstFilterField == null) {
                lstFilterField = new List<SelectOption>();
                for (String fieldName : fieldapiname) {
                    strValue = getFieldSearchName(fieldName);

                    lstFilterField.add(new SelectOption(strValue, mapfieldAndLabel.get(fieldName)));
                }
            }
            return lstFilterField;
        }
        set;
    }

    public PageReference search() {

        String query = 'SELECT ' + queryFieldNames + ' FROM ' + sObjectName;

        if (!String.isEmpty(filterString)) {
            query += ' WHERE ' + filterString;
        } else {
            query += ' WHERE Id <> null ';
        }

        if (!String.isEmpty(selFilterField) && !String.isEmpty(filterInput)) {
            Schema.DisplayType fielddataType = mapfieldAndType.get(selFilterField);
            switch on fielddataType {
                when DATE, DATETIME {
                    Date myDate = Date.parse(filterInput);
                    String formattedMyDate = String.valueOf(myDate.year());

                    if (myDate.month() < 10) {
                        formattedMyDate = formattedMyDate + '-0' + String.valueOf(myDate.month());
                    } else {
                        formattedMyDate = formattedMyDate + '-' + String.valueOf(myDate.month());
                    }

                    if (myDate.day() < 10) {
                        formattedMyDate = formattedMyDate + '-0' + String.valueOf(myDate.day());
                    } else {
                        formattedMyDate = formattedMyDate + '-' + String.valueOf(myDate.day());
                    }

                    if (selFilterOp == 'equals') {
                        query += ' AND ' + selFilterField + '  = ' + formattedMyDate;
                    } else if (selFilterOp == 'contains') {
                        query += ' AND ' + selFilterField + '  = ' + formattedMyDate;
                    } else if (selFilterOp == 'not contains') {
                        query += ' AND ' + selFilterField + '  != ' + formattedMyDate;
                    } else if (selFilterOp == 'greater than or equal') {
                        query += ' AND ' + selFilterField + '  >= ' + formattedMyDate;
                    } else if (selFilterOp == 'less than or equal') {
                        query += ' AND ' + selFilterField + '  <= ' + formattedMyDate;
                    }
                }
                when DOUBLE, INTEGER, PERCENT {
                    if (selFilterOp == 'contains' || selFilterOp == 'not contains') {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contains & Not contains operation only valid on string field!'));
                        return null;
                    }
                    if (selFilterOp == 'equals') {
                        query += ' AND ' + selFilterField + '  = ' + String.escapeSingleQuotes(filterInput);
                    } else if (selFilterOp == 'contains') {
                        query += ' AND ' + selFilterField + '  LIKE \'%' + String.escapeSingleQuotes(filterInput) + '%\'';
                    } //else if (selFilterOp == 'not equal to') {
                    else if (selFilterOp == 'not contains') {
                        query += ' AND  (NOT ' + selFilterField + '  LIKE \'%' + String.escapeSingleQuotes(filterInput) + '%\')';
                    } else if (selFilterOp == 'greater than or equal') {
                        query += ' AND ' + selFilterField + '  >= ' + String.escapeSingleQuotes(filterInput);
                    } else if (selFilterOp == 'less than or equal') {
                        query += ' AND ' + selFilterField + '  <= ' + String.escapeSingleQuotes(filterInput);
                    }
                }
                when else {
                    if (selFilterOp == 'equals') {
                        query += ' AND ' + selFilterField + '  = \'' + String.escapeSingleQuotes(filterInput) + '\'';
                    } else if (selFilterOp == 'contains') {
                        query += ' AND ' + selFilterField + '  LIKE \'%' + String.escapeSingleQuotes(filterInput) + '%\'';
                    } //else if (selFilterOp == 'not equal to') {
                    else if (selFilterOp == 'not contains') {
                        query += ' AND  (NOT ' + selFilterField + '  LIKE \'%' + String.escapeSingleQuotes(filterInput) + '%\')';
                    } else if (selFilterOp == 'greater than or equal') {
                        query += ' AND ' + selFilterField + '  >= \'' + String.escapeSingleQuotes(filterInput) + '%\'';
                    } else if (selFilterOp == 'less than or equal') {
                        query += ' AND ' + selFilterField + '  <= \'' + String.escapeSingleQuotes(filterInput) + '%\'';
                    }
                }
            }
        }

        query += ' ORDER BY Name LIMIT ' + MaxRows;

        sobjList = new List<SObject>();
        sobjList = Database.query(query);

        if (sobjList.size() == Integer.valueOf(MaxRows)) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'Returned Results > ' + MaxRows + '. Limit Results First!'); ApexPages.addMessage(myMsg);
            return null;
        }

        return null;
    }

    private String getFieldSearchName(String pFieldName) {
        Schema.DisplayType fielddataType = mapfieldAndType.get(pFieldName);
        //handle special fields
        if (pFieldName.toLowerCase() == 'ownerid') {
            return 'Owner.Name';
        }

        if (fielddataType == Schema.DisplayType.REFERENCE) {
            pFieldName = pFieldName.replace('__c', '__r.Name') ;
        }

        return pFieldName;
    }

    /*
    @TestVisible
    private void selectFALEquipmentList(List<Schema.FieldSetMember> Fieldset) {
        Id tmId;
        Set<Id> equipmentResId = new Set<Id>();
        System.debug('Info: SpecialFieldValueMap ' + SpecialFieldValueMap);
        if(SpecialFieldValueMap.containsKey('FALEquipment_Special')) {
            tmId = String.valueOf(SpecialFieldValueMap.get('FALEquipment_Special'));
            System.debug('Info: tmId ' + tmId);
            if(!String.isEmpty(tmId)){
                List<TM_Line__c> tmLines = [SELECT Id, Resource__c FROM TM_Line__c WHERE TM__c = :tmId AND Category__c = 'Equipment' AND Resource__c != NULL];
                for(TM_Line__c tmLine:tmLines){
                    equipmentResId.add(tmLine.Resource__c);
                }
            }
        }

        String strWhereClause = ' WHERE Id IN: equipmentResId';

        String query = 'SELECT ';
        for (Schema.FieldSetMember f : Fieldset ) {
            fieldapiname.add(f.getFieldPath());
            query += f.getFieldPath() + ', ';
        }
        if (filterString != '') {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' AND ' + filterString + ' ORDER BY Name LIMIT 1000';
        } else {
            query += 'ID FROM ' + sObjectName + strWhereClause + ' ORDER BY Name LIMIT 1000';
        }

        sobjList = new List<SObject>();

        sobjList = Database.query(query);
    }
     */

    private String getMaxLookUpRows() {
        switch on sObjectName.toLowerCase(){
            when 'account'{
                return String.valueOf(Label.Account_Max_Lookup_Rows);
            }
            when 'item__c'{
                return String.valueOf(Label.Item_Max_Lookup_Rows);
            }
            when 'purchase_price__c'{
                return String.valueOf(Label.Product_Catalog_Max_Lookup_Rows);
            }
            when else {
                return String.valueOf(Label.Max_Lookup_Rows);
            }
        }
    }
}