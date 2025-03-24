/**
 * Created by Kevin on 1/29/2020.
 */
@IsTest
public with sharing class NewTestData {
    public static final String TEST_COMPANY_SETUP_NAME = 'Company Default';
    public static final String TEST_USER_NAME = 'user1@acvenviro.com';
    public static final String COMPANY_NAME = '1-ACV ENVIRO';
    public static final String SERVICE_CENTER_NAME = '02';
    public static final String TEST_TM_NAME_01 = 'TM1';
    public static final String TEST_SO_NAME_01 = 'SO1';
    public static final String TEST_SQ_NAME = 'SQ1';
    public static final String TEST_EMPLOYEE_NAME_DAVID = 'DAVID';
    public static final String TEST_EQUIPMENT_NAME = 'TL-1155';
    public static final String RESOURCE_TYPE_CONTRACTED = 'CONTRACT RESOURCE TYPE';
    public static final String RESOURCE_TYPE_ORDER = 'ORDER RESOURCE TYPE';
    public static final String RESOURCE_TYPE_QUOTE = 'QUOTE RESOURCE TYPE';
    public static final String RESOURCE_TYPE_SC_RATESHEET = 'SC RATESHEET RESOURCE TYPE';
    public static final String RESOURCE_TYPE_COMPANY_RATESHEET = 'COMPANY RATESHEET RESOURCE TYPE';
    public static final String RESOURCE_TYPE_COMPANY_DEFAULT = 'DEFAULT RATE RESOURCE TYPE';
    public static final String RESOURCE_CONTRACTED = 'CONTRACT RESOURCE';
    public static final String RESOURCE_ORDER = 'ORDER RESOURCE';
    public static final String RESOURCE_QUOTE = 'QUOTE RESOURCE';
    public static final String RESOURCE_SC_RATESHEET = 'SC RATESHEET RESOURCE';
    public static final String RESOURCE_COMPANY_RATESHEET = 'COMPANY RATESHEET RESOURCE';
    public static final String RESOURCE_COMPANY_DEFAULT = 'DEFAULT RATE RESOURCE';
    public static final String COMPANY_PRICE_LIST = 'COMPANY PRICE LIST';
    public static final String SC_PRICE_LIST = 'SC PRICE LIST';
    public static final String TM_PRICE_LIST = 'TM PRICE LIST';
    public static final String JOB_TEMPLATE_NAME = 'Field Services';
    public static OrganizationConfigurations__c orgConfig = new OrganizationConfigurations__c();
    public static Map<String, User> mapUsersByName = new Map<String, User>();
    public static Map<Date, Accounting_Period__c> mapAccountingPeriodsByStartDate = new Map<Date, Accounting_Period__c>();
    public static Map<String, GL_Account__c> mapGLAccountsByName = new Map<String, GL_Account__c>();
    public static Map<String, Subsidiary_Company__c> mapSubsidiaryCompaniesByName = new Map<String, Subsidiary_Company__c>();
    public static Map<String, Numbering_Series__c> mapNumberingSeriesByName = new Map<String, Numbering_Series__c>();
    public static Map<String, Currency__c> mapCurrenciesByName = new Map<String, Currency__c>();
    public static Map<String, ServiceCenterWrapper> mapServiceCenterWrappersByName = new Map<String, ServiceCenterWrapper>();
    public static Map<String, Facility__c> mapFacilitiesByName = new Map<String, Facility__c>();
    public static Map<String, Unit_of_Measure__c> mapUnitOfMeasuresByName = new Map<String, Unit_of_Measure__c>();
    public static Map<String, ResourceTypeWrapper> mapResourceTypeWrappersByName = new Map<String, ResourceTypeWrapper>();
    public static Map<String, Job_Position__c> mapJobPositionsByName = new Map<String, Job_Position__c>();
    public static Map<String, Employee__c> mapEmployeesByName = new Map<String, Employee__c>();
    public static Map<String, ResourceWrapper> mapResourceWrappersByName = new Map<String, ResourceWrapper>();
    public static Map<String, PayRuleWrapper> mapPayRuleWrappersByName = new Map<String, NewTestData.PayRuleWrapper>();
    public static Map<String, Map<String, Pay_Rule_Line__c>> mapPayRuleLinesByResourceTypeByRule;
    public static Map<String, Map<String, Pay_Rule_Holiday__c>> mapPayRuleHolidaysByNameByRule;
    public static Company_Setup__c companySetup = new Company_Setup__c();
    public static Company_Setting__mdt companySetting = new Company_Setting__mdt();
    public static Map<String, Payment_Term__c> mapPaymentTermsByName = new Map<String, Payment_Term__c>();
    public static Map<String, TaxAreaWrapper> mapTaxAreaWrappersByName = new Map<String, NewTestData.TaxAreaWrapper>();
    public static Map<String, Salesperson__c> mapSalespeopleByName = new Map<String, Salesperson__c>();
    public static Map<String, AccountWrapper> mapAccountWrappersByName = new Map<String, AccountWrapper>();
    public static Map<String, Pricing__c> mapPriceListsByName = new Map<String, Pricing__c>();
    public static Map<String, RateSheetWrapper> mapRateSheetWrappersByName = new Map<String, RateSheetWrapper>();
    public static Map<String, BillingRuleWrapper> mapBillingRuleWrappersByName = new Map<String, NewTestData.BillingRuleWrapper>();
    public static Map<String, ContractWrapper> mapContractWrappersByName = new Map<String, NewTestData.ContractWrapper>();
    public static Map<String, Sales_Order_Type__c> mapSalesOrderTypesByName = new Map<String, Sales_Order_Type__c>();
    public static Map<String, Sales_Order__c> mapSalesOrdersByName = new Map<String, Sales_Order__c>();
    public static Map<String, JobTaskTemplateWrapper> mapJobTaskTemplateWrappersByName = new Map<String, JobTaskTemplateWrapper>();
    public static Map<String, TM__c> mapTMsByName = new Map<String, TM__c>();
    public static Map<Id, Sales_Order_Job_Task__c> mapSalesOrderJobTaskBySalesOrderId = new Map<Id, Sales_Order_Job_Task__c>();
    public static Map<Id, Map<String, Sales_Line__c>> mapSalesLinesBySalesOrderIdByCategory = new Map<Id, Map<String, Sales_Line__c>>();
    public static Map<Id, Map<String, TM_Line__c>> mapTMLinesByTMIdByCategory = new Map<Id, Map<String, TM_Line__c>>();
    public static Map<String, Resource__c> mapResourceByName = new Map<String, Resource__c>();
    public static Map<String, Resource_Type__c> mapResourceTypesByName = new Map<String, Resource_Type__c>();
    public static Map<String, Rate_Sheet__c> mapRateSheetsByName = new Map<String, Rate_Sheet__c>();
    public static Map<String, Sales_Invoice__c> mapSalesInvoicesByName = new Map<String, Sales_Invoice__c>();
    public static Map<Id, List<Billing_Worksheet_Line__c>> mapBillingWorksheetLinesByOrderId = new Map<Id, List<Billing_Worksheet_Line__c>>();

    public static testMethod void createTestData() {
        //Organization Configuration Settings >>>>>>>>>>>>
        initOrganizationConfigurations();

        //Users >>>>>>>>>>
        initUsers();

        //Accounting Periods >>>>>>>>>>>>
        initAccountingPeriods();

        //GL Accounts >>>>>>>>>>>>
        initGlAccounts();

        //Subsidiary Company >>>>>>>>>>>>
        initSubsidiaryCompanies();

        //Numbering Series >>>>>>>>>>>>
        initNumberingSeries();

        //Currency >>>>>>>>>>>>
        initCurrencies();

        //Service Centers
        initServiceCenters();

        //Facilities >>>>>>>>>>
        initFacilities();

        //Unit of Measures >>>>>>>>>>>>
        initUnitOfMeasures();

        //Resource Types >>>>>>>>>>>>
        initResourceTypes();

        //Job Positions >>>>>>>>>>
        initJobPositions();

        //Employees >>>>>>>>>>
        initEmployees();

        //Resources >>>>>>>>>>>>
        initResources();

        //Presumptive Resources
        initPresumptiveResources();

        //Job Task Templates
        initJobTaskTemplates();

        //Pay Rules >>>>>>>>>>>>
        initPayRules();

        //Payment Terms >>>>>>>>>>>>
        initPaymentTerms();

        //Tax Areas >>>>>>>>>>>>
        initTaxAreas();

        //Salespeople >>>>>>>>>>>>
        initSalespeople();

        //Accounts >>>>>>>>>>>>
        initAccounts();

        //Price Lists >>>>>>>>>>
        initPriceLists();

        //Rate Sheets >>>>>>>>>>
        initRateSheets();

        //Price List Rate Sheet >>>>>>>>>>

        //Billing Rules >>>>>>>>>>
        initBillingRules();

        //Company Setup >>>>>>>>>>>>
        initCompanySetup();

        //Init Company Setting >>>>>>>>
        initCompanySetting();

        //Contracts >>>>>>>>>>
        initContracts();

        //Sales Order Types >>>>>>>>>>
        initSalesOrderTypes();

        //Sales Orders >>>>>>>>>>
        initSalesQuote();

        //Sales Orders >>>>>>>>>>
        initSalesOrders();

        //TMs  >>>>>>>>>>
        initTMs();

        //Billing Worksheet Line >>>>>>>
        initBillingWorksheetLines();

        //Sales invoices
        initSalesInvoices();
    }

    //------------------------------------------------------------------------------------------------------------------
    //Organization Configuration Settings >>>>>>>>>>>>
    private static void initOrganizationConfigurations() {
        orgConfig.Data_Admin_Public_Group__c = 'Data Admin';
        insert orgConfig;
    }

    //Users >>>>>>>>>>
    private static void initUsers() {
        List<User> users = new List<User>();

        Profile profile = [SELECT Id FROM Profile WHERE Name='ACV Standard User'];

        User user1 = new User();
        user1.Alias = 'user1';
        user1.Email = 'user1@republicservices.com';
        user1.EmailEncodingKey = 'UTF-8';
        user1.LastName = 'Smith';
        user1.FirstName = 'User1';
        user1.LanguageLocaleKey = 'en_US';
        user1.LocaleSidKey = 'en_US';
        user1.ProfileId = profile.Id;
        user1.TimeZoneSidKey = 'America/New_York';
        user1.UserName='user1@acvenviro.com';
        user1.BDD__c = 'BDD2';
        user1.Manager_of_SC__c = '02';
        user1.Service_Center__c = '02';
        users.add(user1);

        insert users;

        mapUsersByName.put(user1.UserName, user1);
    }

    //Accounting Periods >>>>>>>>>>>>
    private static void initAccountingPeriods() {
        for (Integer y = system.today().year() - 1; y <= system.today().year() + 1; y++) {
            for (Integer p = 1; p < 12; p++) {
                Date startDate = Date.newInstance(y, p, 1);
                Date endDate = startDate.addMonths(1).addDays(-1);
                Boolean newFiscalYear = (p == 1);
                Accounting_Period__c accountingPeriod = new Accounting_Period__c();
                accountingPeriod.Name = String.valueof(startDate);
                accountingPeriod.Start_Date__c = startDate;
                accountingPeriod.End_Date__c = endDate;
                accountingPeriod.Fiscal_Year__c = y;
                accountingPeriod.Fiscal_Period__c = p;
                accountingPeriod.New_Fiscal_Year__c = newFiscalYear;
                mapAccountingPeriodsByStartDate.put(accountingPeriod.Start_Date__c, accountingPeriod);
            }
        }
        insert mapAccountingPeriodsByStartDate.values();
    }

    //GL Accounts >>>>>>>>>>>>
    private static void initGlAccounts() {
        GL_Account__c receivableGlAccount = new GL_Account__c();
        receivableGlAccount.Name = '12000';
        receivableGlAccount.Description__c = 'Accounts Receivable';
        mapGLAccountsByName.put(receivableGlAccount.Name, receivableGlAccount);

        GL_Account__c payableGlAccount = new GL_Account__c();
        payableGlAccount.Name = '22000';
        payableGlAccount.Description__c = 'Accounts Payable';
        mapGLAccountsByName.put(payableGlAccount.Name, payableGlAccount);

        GL_Account__c salesTaxGlAccount = new GL_Account__c();
        salesTaxGlAccount.Name = '23000';
        salesTaxGlAccount.Description__c = 'Sales Tax';
        mapGLAccountsByName.put(salesTaxGlAccount.Name, salesTaxGlAccount);

        GL_Account__c interCompanyGLAccount = new GL_Account__c();
        interCompanyGLAccount.Name = '24000';
        interCompanyGLAccount.Description__c = 'Inter Company';
        mapGLAccountsByName.put(interCompanyGLAccount.Name, interCompanyGLAccount);

        GL_Account__c salesGLAccount = new GL_Account__c();
        salesGLAccount.Name = '25000';
        salesGLAccount.Description__c = 'Sales';
        mapGLAccountsByName.put(salesGLAccount.Name, salesGLAccount);

        GL_Account__c retainageGLAccount = new GL_Account__c();
        retainageGLAccount.Name = '12061';
        retainageGLAccount.Description__c = 'A/R Retainage Current';
        mapGLAccountsByName.put(retainageGLAccount.Name, retainageGLAccount);

        insert mapGLAccountsByName.values();
    }

    //Subsidiary Company >>>>>>>>>>>>
    private static void initSubsidiaryCompanies() {
        Subsidiary_Company__c subsidiaryCompany = new Subsidiary_Company__c();
        subsidiaryCompany.Name = COMPANY_NAME;
        subsidiaryCompany.Display_Name__c = 'ACV Enviro';
        subsidiaryCompany.QtC_Enabled__c = true;
        subsidiaryCompany.Website__c = 'example.com';
        subsidiaryCompany.Watermark__c = '/resources/';
        mapSubsidiaryCompaniesByName.put(subsidiaryCompany.Name, subsidiaryCompany);

        insert mapSubsidiaryCompaniesByName.values();
    }

    //Numbering Series >>>>>>>>>>>>
    private static void initNumberingSeries() {
        Map<String, String> series = new Map<String, String>();
        series.put('JOB01', 'NJ');
        series.put('PO Temp Number', 'PO');
        series.put('Purchase Order', 'PO');
        series.put('Purchase Receipt', 'PR');
        series.put('Return Purchase Order', 'PRO');
        series.put('Sales Invoice', 'SI');
        series.put('Credit Memo', 'CR');
        series.put('Sales Order', 'SO');
        series.put('SC01 TM No.', 'TMEL');
        series.put('T&M', 'TM');
        series.put('Timesheet', 'T');
        series.put('Contract Line', 'CL');
        series.put('Rental Order', 'RO');

        for (String name : series.keySet()) {
            Numbering_Series__c ns = new Numbering_Series__c();
            ns.Name = name;
            ns.Prefix__c = 'NUM';
            ns.Separator__c = '-';
            ns.Last_Number_Used__c = 1000000;
            mapNumberingSeriesByName.put(ns.Name, ns);
        }
        insert mapNumberingSeriesByName.values();
    }

    //Currencies >>>>>>>>>>>>
    private static void initCurrencies() {
        Currency__c cur = new Currency__c();
        cur.Name = 'USD';
        cur.Currency_Code__c = 'USD';
        mapCurrenciesByName.put(cur.Name, cur);

        insert mapCurrenciesByName.values();
    }

    //Service Centers >>>>>>>>>>
    private static void initServiceCenters() {
        //service centers
        List<Service_Center__c> serviceCenters = new List<Service_Center__c>();

        Subsidiary_Company__c subsidiaryCompany = mapSubsidiaryCompaniesByName.get('1-ACV ENVIRO');
        Numbering_Series__c tmNumberingSeries = mapNumberingSeriesByName.get('T&M');
        Numbering_Series__c salesOrderNumberingSeries = mapNumberingSeriesByName.get('Sales Order');

        Service_Center__c serviceCenter02 = new Service_Center__c();
        serviceCenter02.Name = '02';
        serviceCenter02.Code__c = '02';
        serviceCenter02.Subsidiary_Company__c = subsidiaryCompany.Id;
        serviceCenter02.Street__c = '600 Cenco Boulevard';
        serviceCenter02.City__c = 'Clayton';
        serviceCenter02.State__c = 'NJ';
        serviceCenter02.Postal_Code__c = '08312';
        serviceCenter02.Country__c = 'US';
        serviceCenter02.TM_No_Series__c = tmNumberingSeries.Id;
        serviceCenter02.Sales_Order_No_Series__c = salesOrderNumberingSeries.Id;
        serviceCenter02.TM_Service_Rep__c = mapUsersByName.get(TEST_USER_NAME).Id;
        serviceCenter02.TM_Service_Rep__r = mapUsersByName.get(TEST_USER_NAME);
        serviceCenter02.Enable_Kronos_Integration__c = true;
        serviceCenter02.Logo__c= '<img src=" Republic Services " alt="';
        serviceCenter02.Website__c= 'www.RepublicServices.com';
        serviceCenter02.PA_Rep_Sign_Col_Label__c='Test';
        serviceCenters.add(serviceCenter02);

        insert serviceCenters;

        //approval trees
        List<Approval_Tree__c> approvalTrees = new List<Approval_Tree__c>();

        User approver = mapUsersByName.get('user1@acvenviro.com');

        Approval_Tree__c approvalTree = new Approval_Tree__c();
        approvalTree.Name = 'SO-02-1';
        approvalTree.Service_Center__c = serviceCenter02.Id;
        approvalTree.Service_Center__r = serviceCenter02;
        approvalTree.Document_Type__c = 'Sales_Order';
        approvalTree.Level__c = 1;
        approvalTree.Approval_Margin_Pct__c = 30;
        approvalTree.Approver__c = approver.Id;
        approvalTree.Approver__r = approver;
        approvalTrees.add(approvalTree);

        insert approvalTrees;

        //add to the map
        ServiceCenterWrapper serviceCenterWrapper02 = new ServiceCenterWrapper(serviceCenter02);
        serviceCenterWrapper02.addApprovalTree(approvalTrees);
        mapServiceCenterWrappersByName.put(serviceCenterWrapper02.ServiceCenter.Name, serviceCenterWrapper02);
    }

    //Facilities >>>>>>>>>>
    private static void initFacilities() {
        Facility__c facility = new Facility__c();
        facility.Name = 'Elizabeth';
        mapFacilitiesByName.put(facility.Name, facility);

        insert mapFacilitiesByName.values();
    }

    //Unit of Measures >>>>>>>>>>>>
    private static void initUnitOfMeasures() {
        Unit_of_Measure__c hourUnitOfMeasure = new Unit_of_Measure__c();
        hourUnitOfMeasure.Name = 'HR';
        hourUnitOfMeasure.Hours_UOM__c = true;
        mapUnitOfMeasuresByName.put(hourUnitOfMeasure.Name, hourUnitOfMeasure);

        Unit_of_Measure__c eachUnitOfMeasure = new Unit_of_Measure__c();
        eachUnitOfMeasure.Name = 'EA';
        mapUnitOfMeasuresByName.put(eachUnitOfMeasure.Name, eachUnitOfMeasure);

        Unit_of_Measure__c dayUnitOfMeasure = new Unit_of_Measure__c();
        dayUnitOfMeasure.Name = 'DAY';
        mapUnitOfMeasuresByName.put(dayUnitOfMeasure.Name, dayUnitOfMeasure);

        Unit_of_Measure__c weightVolumeUnitOfMeasure = new Unit_of_Measure__c();
        weightVolumeUnitOfMeasure.Name = 'P';
        weightVolumeUnitOfMeasure.Weight_Volume__c = true;
        mapUnitOfMeasuresByName.put(weightVolumeUnitOfMeasure.Name, weightVolumeUnitOfMeasure);

        Unit_of_Measure__c container5UnitOfMeasure = new Unit_of_Measure__c();
        container5UnitOfMeasure.Name = '5';
        container5UnitOfMeasure.Container_Size__c = true;
        mapUnitOfMeasuresByName.put(container5UnitOfMeasure.Name, container5UnitOfMeasure);

        Unit_of_Measure__c container55UnitOfMeasure = new Unit_of_Measure__c();
        container55UnitOfMeasure.Name = '55';
        container55UnitOfMeasure.Container_Size__c = true;
        mapUnitOfMeasuresByName.put(container55UnitOfMeasure.Name, container55UnitOfMeasure);

        insert mapUnitOfMeasuresByName.values();
    }

    //Resource Types >>>>>>>>>>>>
    private static void initResourceTypes() {
        //resource types
        List<Resource_Type__c> resourceTypes = new List<Resource_Type__c>();

        Unit_of_Measure__c hourUnitOfMeasure = mapUnitOfMeasuresByName.get('HR');
        Unit_of_Measure__c eachUnitOfMeasure = mapUnitOfMeasuresByName.get('EA');

        Resource_Type__c laborResourceType = new Resource_Type__c();
        laborResourceType.Category__c = 'Labor';
        laborResourceType.Name = 'Labor';
        laborResourceType.Inter_co_Cost__c = 29;
        laborResourceType.Unit_Cost__c = 29;
        laborResourceType.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        resourceTypes.add(laborResourceType);
        mapResourceTypesByName.put('Labor', laborResourceType);

        Resource_Type__c fieldTechResourceType = new Resource_Type__c();
        fieldTechResourceType.Category__c = 'Labor';
        fieldTechResourceType.Name = 'Field Tech';
        fieldTechResourceType.Inter_co_Cost__c = 29;
        fieldTechResourceType.Unit_Cost__c = 29;
        fieldTechResourceType.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        resourceTypes.add(fieldTechResourceType);
        mapResourceTypesByName.put('FT', fieldTechResourceType);

        Resource_Type__c contractedResourceType = new Resource_Type__c();
        contractedResourceType.Category__c = ResourceService.LABOR_CATEGORY;
        contractedResourceType.Name = RESOURCE_TYPE_CONTRACTED;
        contractedResourceType.Inter_co_Cost__c = 29;
        contractedResourceType.Unit_Cost__c = 29;
        contractedResourceType.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        resourceTypes.add(contractedResourceType);
        mapResourceTypesByName.put(RESOURCE_TYPE_CONTRACTED, contractedResourceType);

        Resource_Type__c quotedResourceType = new Resource_Type__c();
        quotedResourceType.Category__c = ResourceService.LABOR_CATEGORY;
        quotedResourceType.Name = RESOURCE_TYPE_QUOTE;
        quotedResourceType.Inter_co_Cost__c = 29;
        quotedResourceType.Unit_Cost__c = 29;
        quotedResourceType.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        resourceTypes.add(quotedResourceType);
        mapResourceTypesByName.put(RESOURCE_TYPE_QUOTE, quotedResourceType);

        Resource_Type__c orderResourceType = new Resource_Type__c();
        orderResourceType.Category__c = ResourceService.LABOR_CATEGORY;
        orderResourceType.Name = RESOURCE_TYPE_ORDER;
        orderResourceType.Inter_co_Cost__c = 30;
        orderResourceType.Unit_Cost__c = 30;
        orderResourceType.Fuel_Fired_Equipment__c = true;
        orderResourceType.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        resourceTypes.add(orderResourceType);
        mapResourceTypesByName.put(RESOURCE_TYPE_ORDER, orderResourceType);

        Resource_Type__c scResourceType = new Resource_Type__c();
        scResourceType.Category__c = ResourceService.LABOR_CATEGORY;
        scResourceType.Name = RESOURCE_TYPE_SC_RATESHEET;
        scResourceType.Inter_co_Cost__c = 30;
        scResourceType.Unit_Cost__c = 30;
        scResourceType.Fuel_Fired_Equipment__c = true;
        scResourceType.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        resourceTypes.add(scResourceType);
        mapResourceTypesByName.put(RESOURCE_TYPE_SC_RATESHEET, scResourceType);

        Resource_Type__c companyResourceType = new Resource_Type__c();
        companyResourceType.Category__c = ResourceService.LABOR_CATEGORY;
        companyResourceType.Name = RESOURCE_TYPE_COMPANY_RATESHEET;
        companyResourceType.Inter_co_Cost__c = 30;
        companyResourceType.Unit_Cost__c = 30;
        companyResourceType.Fuel_Fired_Equipment__c = true;
        companyResourceType.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        resourceTypes.add(companyResourceType);
        mapResourceTypesByName.put(RESOURCE_TYPE_COMPANY_RATESHEET, companyResourceType);

        Resource_Type__c defaultResourceType = new Resource_Type__c();
        defaultResourceType.Category__c = ResourceService.LABOR_CATEGORY;
        defaultResourceType.Name = RESOURCE_TYPE_COMPANY_DEFAULT;
        defaultResourceType.Inter_co_Cost__c = 30;
        defaultResourceType.Unit_Cost__c = 30;
        defaultResourceType.Fuel_Fired_Equipment__c = true;
        defaultResourceType.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        resourceTypes.add(defaultResourceType);
        mapResourceTypesByName.put(RESOURCE_TYPE_COMPANY_DEFAULT, defaultResourceType);

        Resource_Type__c equipmentResourceType = new Resource_Type__c();
        equipmentResourceType.Category__c = ResourceService.EQUIPMENT_CATEGORY;
        equipmentResourceType.Name = 'Equipment';
        equipmentResourceType.Inter_co_Cost__c = 30;
        equipmentResourceType.Unit_Cost__c = 30;
        equipmentResourceType.Charge_Rinse_Out_Fee__c = true;
        equipmentResourceType.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        resourceTypes.add(equipmentResourceType);
        mapResourceTypesByName.put('Equipment', equipmentResourceType);

        Resource_Type__c lumpSumResourceType = new Resource_Type__c();
        lumpSumResourceType.Category__c = 'Bundled';
        lumpSumResourceType.Name = 'Bundled';
        lumpSumResourceType.Inter_co_Cost__c = 0;
        lumpSumResourceType.Unit_Cost__c = 0;
        lumpSumResourceType.Unit_of_Measure__c = eachUnitOfMeasure.Id;
        resourceTypes.add(lumpSumResourceType);
        mapResourceTypesByName.put('Bundled', lumpSumResourceType);

        insert resourceTypes;

        //resource type uom associations
        List<ResourceTypeUOMAssociation__c> laborResourceTypeUOMAssociations = new List<ResourceTypeUOMAssociation__c>();
        List<ResourceTypeUOMAssociation__c> resourceTypeUOMAssociations = new List<ResourceTypeUOMAssociation__c>();
        List<ResourceTypeUOMAssociation__c> fieldTechTypeUOMAssociations = new List<ResourceTypeUOMAssociation__c>();

        //not used Map<String, ResourceTypeUOMAssociation__c> mapAssociationsByUOM = new Map<String, ResourceTypeUOMAssociation__c>();

        for(String resourceType:mapResourceTypesByName.keySet()){
            Resource_Type__c resourceType2 = mapResourceTypesByName.get(resourceType);
            ResourceTypeUOMAssociation__c association = new ResourceTypeUOMAssociation__c();
            association.Name = resourceType2.Name + '-HR';
            association.Resource_Type__c = resourceType2.Id;
            association.Resource_Type__r = resourceType2;
            association.Unit_of_Measure__c = resourceType2.Unit_of_measure__c;
            association.Unit_Price__c = 46;
            association.ER_Unit_Price__c = 54;
            association.Unit_Cost__c = 29;
            resourceTypeUOMAssociations.add(association);
        }

        ResourceTypeUOMAssociation__c association = new ResourceTypeUOMAssociation__c();
        association.Name = 'HR';
        association.Resource_Type__c = laborResourceType.Id;
        association.Resource_Type__r = laborResourceType;
        association.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        association.Unit_of_Measure__r = hourUnitOfMeasure;
        association.Unit_Price__c = 46;
        association.ER_Unit_Price__c = 54;
        association.Unit_Cost__c = 29;
        laborResourceTypeUOMAssociations.add(association);

        association = new ResourceTypeUOMAssociation__c();
        association.Name = 'DAY';
        association.Resource_Type__c = laborResourceType.Id;
        association.Resource_Type__r = laborResourceType;
        association.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        association.Unit_of_Measure__r = hourUnitOfMeasure;
        association.Unit_Price__c = 46;
        association.ER_Unit_Price__c = 54;
        association.Unit_Cost__c = 29;
        laborResourceTypeUOMAssociations.add(association);
        resourceTypeUOMAssociations.add(association);

        association = new ResourceTypeUOMAssociation__c();
        association.Name = 'HR';
        association.Resource_Type__c = fieldTechResourceType.Id;
        association.Resource_Type__r = fieldTechResourceType;
        association.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        association.Unit_of_Measure__r = hourUnitOfMeasure;
        association.Unit_Price__c = 40;
        association.ER_Unit_Price__c = 60;
        association.Unit_Cost__c = 20;
        fieldTechTypeUOMAssociations.add(association);

        association = new ResourceTypeUOMAssociation__c();
        association.Name = 'HR';
        association.Resource_Type__c = equipmentResourceType.Id;
        association.Resource_Type__r = equipmentResourceType;
        association.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        association.Unit_of_Measure__r = hourUnitOfMeasure;
        association.Unit_Price__c = 46;
        association.ER_Unit_Price__c = 54;
        association.Unit_Cost__c = 29;
        laborResourceTypeUOMAssociations.add(association);

        insert resourceTypeUOMAssociations;

        //add to the map
        ResourceTypeWrapper laborResourceTypeWrapper = new ResourceTypeWrapper(laborResourceType);
        laborResourceTypeWrapper.addResourceTypeUOMAssociations(laborResourceTypeUOMAssociations);
        mapResourceTypeWrappersByName.put(laborResourceTypeWrapper.ResourceType.Name, laborResourceTypeWrapper);

        ResourceTypeWrapper fieldTechResourceTypeWrapper = new ResourceTypeWrapper(fieldTechResourceType);
        fieldTechResourceTypeWrapper.addResourceTypeUOMAssociations(fieldTechTypeUOMAssociations);
        mapResourceTypeWrappersByName.put('FT', fieldTechResourceTypeWrapper);

        ResourceTypeWrapper equipmentResourceTypeWrapper = new ResourceTypeWrapper(equipmentResourceType);
        mapResourceTypeWrappersByName.put(equipmentResourceTypeWrapper.ResourceType.Name, equipmentResourceTypeWrapper);

        ResourceTypeWrapper lumpSumResourceTypeWrapper = new ResourceTypeWrapper(lumpSumResourceType);
        mapResourceTypeWrappersByName.put(lumpSumResourceTypeWrapper.ResourceType.Name, lumpSumResourceTypeWrapper);
    }

    //Job Positions >>>>>>>>>>
    private static void initJobPositions() {
        Job_Position__c jobPosition = new Job_Position__c();
        jobPosition.Name = 'Field Technician';
        mapJobPositionsByName.put(jobPosition.Name, jobPosition);

        insert mapJobPositionsByName.values();
    }

    //Employees >>>>>>>>>>
    private static void initEmployees() {
        Job_Position__c jobPosition = mapJobPositionsByName.get('Field Technician');
        Service_Center__c serviceCenter = mapServiceCenterWrappersByname.get('02').ServiceCenter;

        Employee__c employee = new Employee__c();
        employee.Name = TEST_EMPLOYEE_NAME_DAVID;
        employee.Employee_Type__c = 'Employee';
        employee.Resource_Name__c = 'David Smith';
        employee.State__c = 'NY';
        employee.First_Name__c = 'David';
        employee.Last_Name__c = 'Smith';
        employee.Email__c = 'david.smith@test.email.com';
        employee.Job_Position__c = jobPosition.Id;
        employee.Job_Position__r = jobPosition;
        employee.Service_Center__c = serviceCenter.Id;
        employee.Service_Center__r = serviceCenter;
        employee.Status__c = 'Active';

        mapEmployeesByName.put(employee.Name, employee);

        insert mapEmployeesByName.values();
    }

    //Resources >>>>>>>>>>>>
    private static void initResources() {
        List<Resource__c> resources = new List<Resource__c>();

        Resource_Type__c laborResourceType = mapResourceTypeWrappersByName.get('Labor').ResourceType;
        Resource_Type__c equipmentResourceType = mapResourceTypeWrappersByName.get('Equipment').ResourceType;
        Unit_of_Measure__c hourUnitOfMeasure = mapUnitOfMeasuresByName.get('HR');
        Unit_of_Measure__c eachUnitOfMeasure = mapUnitOfMeasuresByName.get('EA');
        Unit_of_Measure__c container5UnitOfMeasure = mapUnitOfMeasuresByName.get('5');
        Unit_of_Measure__c container55UnitOfMeasure = mapUnitOfMeasuresByName.get('55');
        Unit_of_Measure__c weightVolumeUnitOfMeasure = mapUnitOfMeasuresByName.get('P');
        Service_Center__c serviceCenter = mapServiceCenterWrappersByname.get('02').ServiceCenter;
        GL_Account__c salesGLAccount = mapGLAccountsByName.get('25000');
        //Employee__c employee = mapEmployeesByName.get('DAVID');
        //Job_Position__c jobPosition = mapJobPositionsByName.get('Field Technician');
        Facility__c facility = mapFacilitiesByName.get('Elizabeth');

        //labor
        Resource__c laborResource = new Resource__c();
        laborResource.Category__c = 'Labor';
        laborResource.Name = 'Labor';
        //laborResource.Employee__c = employee.Id;
        laborResource.RSG_EIN__c = '10000001';
        //laborResource.Employee__r = employee;
        //laborResource.Employee_Code__c = jobPosition.Id;
        //laborResource.Employee_Code__r = jobPosition;
        laborResource.Employee_No__c = 'DAVID';
        laborResource.Job_Title__c = 'Field Supervisor';
        laborResource.Resource_Type__c = laborResourceType.Id;
        laborResource.Service_Center__c = serviceCenter.Id;
        laborResource.Employee_Type__c = 'Employee';
        laborResource.Non_Payroll_Labor_Resource__c = false;
        laborResource.FLSA__c = 'Non-Exempt';
        laborResource.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        laborResource.Blocked__c = false;
        laborResource.Status__c = 'Active';
        laborResource.Tax_Group__c = 'TX';
        laborResource.Unit_Cost__c = 0;
        laborResource.Kronos_Time_Punch_Enabled__c = true;
        laborResource.Kronos_Time_Punch_Start_Date__c = Date.today();
        laborResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Labor').getRecordTypeId();
        mapResourceByName.put(TEST_EMPLOYEE_NAME_DAVID, laborResource);

        Resource__c orderLaborResource = new Resource__c();
        Resource_Type__c resourceType = mapResourceTypesByName.get(RESOURCE_TYPE_ORDER);
        orderLaborResource.Category__c = ResourceService.LABOR_CATEGORY;
        orderLaborResource.Name = RESOURCE_TYPE_ORDER;
        orderLaborResource.Employee_No__c = RESOURCE_TYPE_ORDER;
        orderLaborResource.Job_Title__c = RESOURCE_TYPE_ORDER;
        orderLaborResource.Resource_Type__c = resourceType.Id;
        orderLaborResource.Service_Center__c = serviceCenter.Id;
        orderLaborResource.Employee_Type__c = 'Employee';
        orderLaborResource.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        orderLaborResource.Blocked__c = false;
        orderLaborResource.Status__c = 'Active';
        orderLaborResource.Tax_Group__c = 'TX';
        orderLaborResource.Unit_Cost__c = 0;
        orderLaborResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get(ResourceService.LABOR_CATEGORY).getRecordTypeId();
        mapResourceByName.put(RESOURCE_TYPE_ORDER, laborResource);
        resources.add(laborResource);

        Resource__c contractedLaborResource = new Resource__c();
        resourceType = mapResourceTypesByName.get(RESOURCE_TYPE_CONTRACTED);
        contractedLaborResource.Category__c = ResourceService.LABOR_CATEGORY;
        contractedLaborResource.Name = RESOURCE_TYPE_CONTRACTED;
        contractedLaborResource.Employee_No__c = 'CONRATE';
        contractedLaborResource.Job_Title__c = RESOURCE_TYPE_CONTRACTED;
        contractedLaborResource.Resource_Type__c = resourceType.Id;
        contractedLaborResource.Service_Center__c = serviceCenter.Id;
        contractedLaborResource.Employee_Type__c = 'Employee';
        contractedLaborResource.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        contractedLaborResource.Blocked__c = false;
        contractedLaborResource.Status__c = 'Active';
        contractedLaborResource.Tax_Group__c = 'TX';
        contractedLaborResource.Unit_Cost__c = 0;
        contractedLaborResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get(ResourceService.LABOR_CATEGORY).getRecordTypeId();
        mapResourceByName.put(RESOURCE_TYPE_CONTRACTED, contractedLaborResource);
        resources.add(contractedLaborResource);

        Resource__c scLaborResource = new Resource__c();
        resourceType = mapResourceTypesByName.get(RESOURCE_TYPE_SC_RATESHEET);
        scLaborResource.Category__c = ResourceService.LABOR_CATEGORY;
        scLaborResource.Name = RESOURCE_TYPE_SC_RATESHEET;
        scLaborResource.Employee_No__c = 'SCLABOR';
        scLaborResource.Job_Title__c = RESOURCE_TYPE_SC_RATESHEET;
        scLaborResource.Resource_Type__c = resourceType.Id;
        scLaborResource.Service_Center__c = serviceCenter.Id;
        scLaborResource.Employee_Type__c = 'Employee';
        scLaborResource.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        scLaborResource.Blocked__c = false;
        scLaborResource.Status__c = 'Active';
        scLaborResource.Tax_Group__c = 'TX';
        scLaborResource.Unit_Cost__c = 0;
        scLaborResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get(ResourceService.LABOR_CATEGORY).getRecordTypeId();
        mapResourceByName.put(RESOURCE_TYPE_SC_RATESHEET, scLaborResource);
        resources.add(scLaborResource);

        Resource__c companyLaborResource = new Resource__c();
        resourceType = mapResourceTypesByName.get(RESOURCE_TYPE_COMPANY_RATESHEET);
        companyLaborResource.Category__c = ResourceService.LABOR_CATEGORY;
        companyLaborResource.Name = RESOURCE_TYPE_COMPANY_RATESHEET;
        companyLaborResource.Employee_No__c = 'COMRATELABOR';
        companyLaborResource.Job_Title__c = RESOURCE_TYPE_COMPANY_RATESHEET;
        companyLaborResource.Resource_Type__c = resourceType.Id;
        companyLaborResource.Service_Center__c = serviceCenter.Id;
        companyLaborResource.Employee_Type__c = 'Employee';
        companyLaborResource.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        companyLaborResource.Blocked__c = false;
        companyLaborResource.Status__c = 'Active';
        companyLaborResource.Tax_Group__c = 'TX';
        companyLaborResource.Unit_Cost__c = 0;
        companyLaborResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get(ResourceService.LABOR_CATEGORY).getRecordTypeId();
        mapResourceByName.put(RESOURCE_TYPE_COMPANY_RATESHEET, companyLaborResource);
        resources.add(companyLaborResource);

        Resource__c defaultLaborResource = new Resource__c();
        resourceType = mapResourceTypesByName.get(RESOURCE_TYPE_COMPANY_DEFAULT);
        defaultLaborResource.Category__c = ResourceService.LABOR_CATEGORY;
        defaultLaborResource.Name = RESOURCE_TYPE_COMPANY_DEFAULT;
        defaultLaborResource.Employee_No__c = 'COMDEFAULT';
        defaultLaborResource.Job_Title__c = RESOURCE_TYPE_COMPANY_DEFAULT;
        defaultLaborResource.Resource_Type__c = resourceType.Id;
        defaultLaborResource.Service_Center__c = serviceCenter.Id;
        defaultLaborResource.Employee_Type__c = 'Employee';
        defaultLaborResource.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        defaultLaborResource.Blocked__c = false;
        defaultLaborResource.Status__c = 'Active';
        defaultLaborResource.Tax_Group__c = 'TX';
        defaultLaborResource.Unit_Cost__c = 0;
        defaultLaborResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get(ResourceService.LABOR_CATEGORY).getRecordTypeId();
        mapResourceByName.put(RESOURCE_TYPE_COMPANY_DEFAULT, defaultLaborResource);
        resources.add(defaultLaborResource);

        //equipment
        Resource__c equipmentResource = new Resource__c();
        equipmentResource.Category__c = 'Equipment';
        equipmentResource.Name = 'Equipment';
        equipmentResource.Fleet_Number__c = 'TL-1155';
        equipmentResource.Plate_Number__c = 'TVL29R';
        equipmentResource.Make__c = 'Haulmark';
        equipmentResource.Model__c = 'TS6X12DS2';
        equipmentResource.Vehicle_Year__c = '2013';
        equipmentResource.Resource_Type__c = equipmentResourceType.Id;
        equipmentResource.Service_Center__c = serviceCenter.Id;
        equipmentResource.Employee_Type__c = 'Employee';
        equipmentResource.Unit_of_Measure__c = eachUnitOfMeasure.Id;
        equipmentResource.Blocked__c = false;
        equipmentResource.Status__c = 'Available';
        equipmentResource.Tax_Group__c = 'TX';
        equipmentResource.Unit_Cost__c = 0;
        equipmentResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Equipment').getRecordTypeId();
        mapResourceByName.put(TEST_EQUIPMENT_NAME, equipmentResource);
        resources.add(equipmentResource);

        //material
        Resource__c materialResource = new Resource__c();
        materialResource.Category__c = 'Materials';
        materialResource.Name = 'Material';
        materialResource.Unit_of_Measure__c = eachUnitOfMeasure.Id;
        materialResource.Blocked__c = false;
        materialResource.Tax_Group__c = 'TX';
        materialResource.Unit_Cost__c = 17.50;
        materialResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Material').getRecordTypeId();
        resources.add(materialResource);

        //subcontractor
        Resource__c subcontractorResource = new Resource__c();
        subcontractorResource.Category__c = 'Subcontractors';
        subcontractorResource.Name = 'Subcontractor';
        subcontractorResource.Unit_of_Measure__c = eachUnitOfMeasure.Id;
        subcontractorResource.Blocked__c = false;
        subcontractorResource.Tax_Group__c = 'TX';
        subcontractorResource.Unit_Cost__c = 17.50;
        subcontractorResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Subcontractors').getRecordTypeId();
        resources.add(subcontractorResource);

        //lump sum
        Resource__c lumpSumResource = new Resource__c();
        lumpSumResource.Category__c = 'Bundled';
        lumpSumResource.Name = 'Bundled';
        lumpSumResource.Unit_of_Measure__c = eachUnitOfMeasure.Id;
        lumpSumResource.Blocked__c = false;
        lumpSumResource.Tax_Group__c = 'TX';
        lumpSumResource.Unit_Cost__c = 0;
        lumpSumResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId();
        resources.add(lumpSumResource);

        //misc
        Resource__c miscChargeResource = new Resource__c();
        miscChargeResource.Category__c = 'Misc. Charges And Taxes';
        miscChargeResource.Name = 'Rental';
        miscChargeResource.Unit_of_Measure__c = eachUnitOfMeasure.Id;
        miscChargeResource.Blocked__c = false;
        miscChargeResource.Tax_Group__c = 'TX';
        miscChargeResource.Unit_Cost__c = 0;
        miscChargeResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId();
        resources.add(miscChargeResource);

        //demurrage
        Resource__c demurrageResource = new Resource__c();
        demurrageResource.Category__c = 'Demurrage';
        demurrageResource.Name = 'Transportation';
        demurrageResource.Unit_of_Measure__c = eachUnitOfMeasure.Id;
        demurrageResource.Blocked__c = false;
        demurrageResource.Tax_Group__c = 'TX';
        demurrageResource.Unit_Cost__c = 0;
        demurrageResource.Fleet_Number__c = 'TR7';
        demurrageResource.Status__c = 'Active';
        demurrageResource.Make__c = 'Car Mate';
        demurrageResource.VIN__c = '5A3U616D1YL005502';
        demurrageResource.Country__c = 'US';
        demurrageResource.Service_Center__c = serviceCenter.Id;
        demurrageResource.Rent_Company__c = 'CVI';
        demurrageResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId();
        resources.add(demurrageResource);

        //waste disposal
        Resource__c wasteDisposalResource = new Resource__c();
        wasteDisposalResource.Category__c = 'Waste Disposal';
        wasteDisposalResource.Name = 'Waste Disposal';
        wasteDisposalResource.Unit_of_Measure__c = container5UnitOfMeasure.Id;
        wasteDisposalResource.Blocked__c = false;
        wasteDisposalResource.Status__c = 'Active';
        wasteDisposalResource.Tax_Group__c = 'TX';
        wasteDisposalResource.Unit_Cost__c = 0;
        wasteDisposalResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId();
        resources.add(wasteDisposalResource);

        //manifest fee
        Resource__c manifestFeeResource = new Resource__c();
        manifestFeeResource.Category__c = 'Waste Disposal';
        manifestFeeResource.Name = 'Manifest Fee';
        manifestFeeResource.Unit_of_Measure__c = eachUnitOfMeasure.Id;
        manifestFeeResource.Status__c = 'Active';
        manifestFeeResource.Tax_Group__c = 'TX';
        manifestFeeResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId();
        resources.add(manifestFeeResource);

        //fuel surcharge
        Resource__c fuelSurchargeResource = new Resource__c();
        fuelSurchargeResource.Category__c = 'Misc. Charges And Taxes';
        fuelSurchargeResource.Name = 'Fuel Surcharge';
        fuelSurchargeResource.Unit_of_Measure__c = eachUnitOfMeasure.Id;
        fuelSurchargeResource.Tax_Group__c = 'TX';
        fuelSurchargeResource.Sales_GL_Account__c = salesGLAccount.Id;
        fuelSurchargeResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId();
        resources.add(fuelSurchargeResource);

        //EEC Fee
        Resource__c energyInsuranceResource = new Resource__c();
        energyInsuranceResource.Category__c = 'Misc. Charges And Taxes';
        energyInsuranceResource.Name = 'EEC Fee';
        energyInsuranceResource.Unit_of_Measure__c = eachUnitOfMeasure.Id;
        energyInsuranceResource.Tax_Group__c = 'TX';
        energyInsuranceResource.Sales_GL_Account__c = salesGLAccount.Id;
        energyInsuranceResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId();
        resources.add(energyInsuranceResource);

        //rinse out fee
        Resource__c rinseOutFeeResource = new Resource__c();
        rinseOutFeeResource.Category__c = 'Misc. Charges And Taxes';
        rinseOutFeeResource.Name = 'Rinse Out Fee';
        rinseOutFeeResource.Unit_of_Measure__c = eachUnitOfMeasure.Id;
        rinseOutFeeResource.Tax_Group__c = 'TX';
        rinseOutFeeResource.Sales_GL_Account__c = salesGLAccount.Id;
        rinseOutFeeResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId();
        resources.add(rinseOutFeeResource);

        //fixed price job resource
        Resource__c fixedPriceJobResource = new Resource__c();
        fixedPriceJobResource.Category__c = 'Misc. Charges And Taxes';
        fixedPriceJobResource.Name = 'Fixed Price Job';
        fixedPriceJobResource.Unit_of_Measure__c = eachUnitOfMeasure.Id;
        fixedPriceJobResource.Tax_Group__c = 'TX';
        fixedPriceJobResource.Sales_GL_Account__c = salesGLAccount.Id;
        fixedPriceJobResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId();
        resources.add(fixedPriceJobResource);

        //retainage resource
        Resource__c retainageResource = new Resource__c();
        retainageResource.Category__c = 'Misc. Charges And Taxes';
        retainageResource.Name = 'Retainage Resource';
        retainageResource.Unit_of_Measure__c = eachUnitOfMeasure.Id;
        retainageResource.Tax_Group__c = 'TX';
        retainageResource.Sales_GL_Account__c = salesGLAccount.Id;
        retainageResource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId();
        resources.add(retainageResource);

        insert resources;
        //resource uom associations
        Map<String, List<ResourceUOMAssociation__c>> mapResourceUOMAssociationsByResourceName = new Map<String, List<ResourceUOMAssociation__c>>();

        //material
        ResourceUOMAssociation__c materialUOMAssociation = new ResourceUOMAssociation__c();
        materialUOMAssociation.Name = 'EA';
        materialUOMAssociation.Resource__c = materialResource.Id;
        materialUOMAssociation.Unit_of_Measure__c = eachUnitOfMeasure.Id;
        materialUOMAssociation.Unit_Price__c = 200;
        materialUOMAssociation.ER_Unit_Price__c = 200;
        materialUOMAssociation.Unit_Cost__c = 75;
        mapResourceUOMAssociationsByResourceName.put('Material', new List<ResourceUOMAssociation__c>{ materialUOMAssociation });

        //waste disposal
        ResourceUOMAssociation__c wasteDisposalAssociation = new ResourceUOMAssociation__c();
        wasteDisposalAssociation.Name = 'P/55';
        wasteDisposalAssociation.Resource__c = wasteDisposalResource.Id;
        wasteDisposalAssociation.Resource__r = wasteDisposalResource;
        wasteDisposalAssociation.Unit_of_Measure__c = weightVolumeUnitOfMeasure.Id;
        wasteDisposalAssociation.Unit_of_Measure__r = weightVolumeUnitOfMeasure;
        wasteDisposalAssociation.Unit_Price__c = 0.85;
        wasteDisposalAssociation.ER_Unit_Price__c = 285.88;
        wasteDisposalAssociation.Unit_Cost__c = 0.68;
        wasteDisposalAssociation.Container_Size__c = container55UnitOfMeasure.Id;
        wasteDisposalAssociation.Container_Size__r = container55UnitOfMeasure;
        wasteDisposalAssociation.Min_Sell_Qty__c = 285.88;
        wasteDisposalAssociation.Facility__c = facility.Id;
        mapResourceUOMAssociationsByResourceName.put('Waste Disposal', new List<ResourceUOMAssociation__c>{ wasteDisposalAssociation });

        //rinse out fee UOMs
        ResourceUOMAssociation__c rinseOutFeeUOMAssociation = new ResourceUOMAssociation__c();
        rinseOutFeeUOMAssociation.Name = 'EA';
        rinseOutFeeUOMAssociation.Resource__c = rinseOutFeeResource.Id;
        rinseOutFeeUOMAssociation.Unit_of_Measure__c = eachUnitOfMeasure.Id;
        rinseOutFeeUOMAssociation.Unit_Price__c = 200;
        rinseOutFeeUOMAssociation.ER_Unit_Price__c = 200;
        rinseOutFeeUOMAssociation.Unit_Cost__c = 75;
        mapResourceUOMAssociationsByResourceName.put('Rinse Out Fee', new List<ResourceUOMAssociation__c>{ rinseOutFeeUOMAssociation });

        //fixed price job UOMs
        ResourceUOMAssociation__c fixedPriceJobUOMAssociation = new ResourceUOMAssociation__c();
        fixedPriceJobUOMAssociation.Name = 'EA';
        fixedPriceJobUOMAssociation.Resource__c = fixedPriceJobResource.Id;
        fixedPriceJobUOMAssociation.Unit_of_Measure__c = eachUnitOfMeasure.Id;
        fixedPriceJobUOMAssociation.Unit_Price__c = 0;
        fixedPriceJobUOMAssociation.ER_Unit_Price__c = 0;
        fixedPriceJobUOMAssociation.Unit_Cost__c = 0;
        mapResourceUOMAssociationsByResourceName.put('Fixed Price Job', new List<ResourceUOMAssociation__c>{ fixedPriceJobUOMAssociation });

        //retainage resource uom
        ResourceUOMAssociation__c retainageResourceUOMAssociation = new ResourceUOMAssociation__c();
        retainageResourceUOMAssociation.Name = 'EA';
        retainageResourceUOMAssociation.Resource__c = retainageResource.Id;
        retainageResourceUOMAssociation.Unit_of_Measure__c = eachUnitOfMeasure.Id;
        retainageResourceUOMAssociation.Unit_Price__c = 0;
        retainageResourceUOMAssociation.ER_Unit_Price__c = 0;
        retainageResourceUOMAssociation.Unit_Cost__c = 0;
        mapResourceUOMAssociationsByResourceName.put('Retainage Resource', new List<ResourceUOMAssociation__c>{ retainageResourceUOMAssociation });

        List<ResourceUOMAssociation__c> resourceUOMAssociations = new List<ResourceUOMAssociation__c>();
        for (List<ResourceUOMAssociation__c> associations : mapResourceUOMAssociationsByResourceName.values()) {
            resourceUOMAssociations.addAll(associations);
        }
        insert resourceUOMAssociations;

        //add to the map
        ResourceWrapper laborResourceWrapper = new ResourceWrapper(laborResource);
        mapResourceWrappersByName.put(laborResourceWrapper.Resource.Name, laborResourceWrapper);

        ResourceWrapper equipmentResourceWrapper = new ResourceWrapper(equipmentResource);
        mapResourceWrappersByName.put(equipmentResourceWrapper.Resource.Name, equipmentResourceWrapper);

        ResourceWrapper materialResourceWrapper = new ResourceWrapper(materialResource);
        materialResourceWrapper.addResourceUOMAssociations(mapResourceUOMAssociationsByResourceName.get('Material'));
        mapResourceWrappersByName.put(materialResourceWrapper.Resource.Name, materialResourceWrapper);

        ResourceWrapper subcontractorResourceWrapper = new ResourceWrapper(subcontractorResource);
        mapResourceWrappersByName.put(subcontractorResourceWrapper.Resource.Name, subcontractorResourceWrapper);

        ResourceWrapper lumpSumResourceWrapper = new ResourceWrapper(lumpSumResource);
        mapResourceWrappersByName.put(lumpSumResourceWrapper.Resource.Name, lumpSumResourceWrapper);

        ResourceWrapper miscChargeResourceWrapper = new ResourceWrapper(miscChargeResource);
        mapResourceWrappersByName.put(miscChargeResourceWrapper.Resource.Name, miscChargeResourceWrapper);

        ResourceWrapper demurrageResourceWrapper = new ResourceWrapper(demurrageResource);
        mapResourceWrappersByName.put(demurrageResourceWrapper.Resource.Name, demurrageResourceWrapper);

        ResourceWrapper wasteDisposalResourceWrapper = new ResourceWrapper(wasteDisposalResource);
        wasteDisposalResourceWrapper.addResourceUOMAssociations(mapResourceUOMAssociationsByResourceName.get('Waste Disposal'));
        mapResourceWrappersByName.put(wasteDisposalResourceWrapper.Resource.Name, wasteDisposalResourceWrapper);

        ResourceWrapper manifestFeeResourceWrapper = new ResourceWrapper(manifestFeeResource);
        mapResourceWrappersByName.put(manifestFeeResourceWrapper.Resource.Name, manifestFeeResourceWrapper);

        ResourceWrapper fuelSurchargeResourceWrapper = new ResourceWrapper(fuelSurchargeResource);
        mapResourceWrappersByName.put(fuelSurchargeResourceWrapper.Resource.Name, fuelSurchargeResourceWrapper);

        ResourceWrapper energyInsuranceResourceWrapper = new ResourceWrapper(energyInsuranceResource);
        mapResourceWrappersByName.put(energyInsuranceResourceWrapper.Resource.Name, energyInsuranceResourceWrapper);

        ResourceWrapper rinseOutFeeResourceWrapper = new ResourceWrapper(rinseOutFeeResource);
        rinseOutFeeResourceWrapper.addResourceUOMAssociations(mapResourceUOMAssociationsByResourceName.get('Rinse Out Fee'));
        mapResourceWrappersByName.put(rinseOutFeeResourceWrapper.Resource.Name, rinseOutFeeResourceWrapper);

        ResourceWrapper fixedPriceJobResourceWrapper = new ResourceWrapper(fixedPriceJobResource);
        fixedPriceJobResourceWrapper.addResourceUOMAssociations(mapResourceUOMAssociationsByResourceName.get('Fixed Price Job'));
        mapResourceWrappersByName.put(fixedPriceJobResourceWrapper.Resource.Name, fixedPriceJobResourceWrapper);

        ResourceWrapper retainageResourceWrapper = new ResourceWrapper(retainageResource);
        retainageResourceWrapper.addResourceUOMAssociations(mapResourceUOMAssociationsByResourceName.get('Retainage Resource'));
        mapResourceWrappersByName.put(retainageResourceWrapper.Resource.Name, retainageResourceWrapper);
    }

    //Presumptive Resources >>>>>>>>>>>>
    private static void initPresumptiveResources() {
        List<Presumptive_Resource__c> presumptiveResources = new List<Presumptive_Resource__c>();
        Presumptive_Resource__c presumptiveResource = new Presumptive_Resource__c();
        ResourceTypeWrapper parentResourceTypeWrapper = mapResourceTypeWrappersByName.get('Labor');
        ResourceWrapper childMaterialResourceWrapper = mapResourceWrappersByName.get('Material');
        presumptiveResource.Parent_Resource_Type__c = parentResourceTypeWrapper.ResourceType.Id;
        presumptiveResource.Child_Resource__c = childMaterialResourceWrapper.Resource.Id;
        presumptiveResource.Child_Unit_of_Measure__c = childMaterialResourceWrapper.mapResourceUOMAssociationsByName.get('EA').Unit_of_Measure__c;
        presumptiveResources.add(presumptiveResource);

        presumptiveResource = new Presumptive_Resource__c();
        ResourceTypeWrapper childEquipmentResourceTypeWrapper = mapResourceTypeWrappersByName.get('Equipment');
        presumptiveResource.Parent_Resource_Type__c = parentResourceTypeWrapper.ResourceType.Id;
        presumptiveResource.Child_Resource_Type__c = childEquipmentResourceTypeWrapper.ResourceType.Id;
        presumptiveResource.Child_Unit_of_Measure__c = mapUnitOfMeasuresByName.get('HR').Id;
        presumptiveResources.add(presumptiveResource);
        insert presumptiveResources;
    }

    //Pay Rules >>>>>>>>>>>>
    private static void initPayRules() {
        //pay rules
        List<Pay_Rule__c> payRules = new List<Pay_Rule__c>();

        Pay_Rule__c companyPayRule = new Pay_Rule__c();
        companyPayRule.Name = 'Company Default';
        companyPayRule.Pay_Holiday__c = true;
        companyPayRule.Work_Before_or_After_Holiday_to_Qualify__c = true;
        payRules.add(companyPayRule);

        Pay_Rule__c prevailingWagePayRule = new Pay_Rule__c();
        prevailingWagePayRule.Name = 'Prevailing Wage';
        prevailingWagePayRule.Type__c = 'Prevailing Wage';
        prevailingWagePayRule.Pay_Travel_Time__c = true;
        payRules.add(prevailingWagePayRule);

        Pay_Rule__c pwPayRuleWithDetailLines = new Pay_Rule__c();
        pwPayRuleWithDetailLines.Name = 'PW Pay Rule with Detail Lines';
        pwPayRuleWithDetailLines.Type__c = 'Prevailing Wage';
        pwPayRuleWithDetailLines.Pay_Travel_Time__c = true;
        pwPayRuleWithDetailLines.Use_Pay_Rule_Line_Detail_for_Hour_Calc__c = true;
        payRules.add(pwPayRuleWithDetailLines);

        insert payRules;

        //pay rule lines
        List<Pay_Rule_Line__c> prevailingWagePayRuleLines = new List<Pay_Rule_Line__c>();
        List<Pay_Rule_Line__c> pwPayRuleLines = new List<Pay_Rule_Line__c>();
        Resource_Type__c laborResourceType = mapResourceTypeWrappersByName.get('Labor').ResourceType;
        Resource_Type__c fieldTechResourceType = mapResourceTypeWrappersByName.get('FT').ResourceType;

        Pay_Rule_Line__c prevailingWagePayRuleLine = new Pay_Rule_Line__c();
        prevailingWagePayRuleLine.Pay_Rule__c = prevailingWagePayRule.Id;
        prevailingWagePayRuleLine.Pay_Rule__r = prevailingWagePayRule;
        prevailingWagePayRuleLine.Resource_Type__c = laborResourceType.Id;
        prevailingWagePayRuleLine.Resource_Type__r = laborResourceType;
        prevailingWagePayRuleLine.Rate__c = 32;
        prevailingWagePayRuleLine.Fringe__c = 20;
        prevailingWagePayRuleLine.OT_Fringe_Amount__c = 30;
        prevailingWagePayRuleLine.DT_Fringe_Amount__c = 40;
        prevailingWagePayRuleLine.Daily_OT_After_Num_of_Hours__c = 8;
        prevailingWagePayRuleLine.Overtime_Rate_Multiple__c = 1.5;
        prevailingWagePayRuleLine.Double_Time_Rate_Multiple__c = 2;
        prevailingWagePayRuleLine.Sunday_Pay_Code__c = 'DBT';
        prevailingWagePayRuleLine.Holidays_with_Overtime_Pay__c = 'Labor Day';
        prevailingWagePayRuleLine.Holiday_with_Double_Time_Pay__c = 'Christmas Day Company';
        prevailingWagePayRuleLine.Eligible_Holidays__c = 'Labor Day;Christmas Day Company';
        pwPayRuleLines.add(prevailingWagePayRuleLine);
        prevailingWagePayRuleLines.add(prevailingWagePayRuleLine);

        Pay_Rule_Line__c fieldTechPWLine = new Pay_Rule_Line__c();
        fieldTechPWLine.Pay_Rule__c = prevailingWagePayRule.Id;
        fieldTechPWLine.Pay_Rule__r = prevailingWagePayRule;
        fieldTechPWLine.Resource_Type__c = fieldTechResourceType.Id;
        fieldTechPWLine.Resource_Type__r = fieldTechResourceType;
        fieldTechPWLine.Rate__c = 32;
        fieldTechPWLine.Fringe__c = 20;
        fieldTechPWLine.OT_Fringe_Amount__c = 30;
        fieldTechPWLine.DT_Fringe_Amount__c = 40;
        fieldTechPWLine.Before_Time__c = Time.newInstance(7,0,0,0);
        fieldTechPWLine.Time_Before_Pay_Code__c = 'O/T';
        fieldTechPWLine.After_Time__c = Time.newInstance(16,0,0,0);
        fieldTechPWLine.Time_After_Pay_Code__c = 'DBT';
        fieldTechPWLine.Overtime_Rate_Multiple__c = 1.5;
        fieldTechPWLine.Double_Time_Rate_Multiple__c = 2;
        fieldTechPWLine.Sunday_Pay_Code__c = 'DBT';
        fieldTechPWLine.Holidays_with_Overtime_Pay__c = 'Labor Day';
        fieldTechPWLine.Holiday_with_Double_Time_Pay__c = 'Christmas Day Company';
        fieldTechPWLine.Eligible_Holidays__c = 'Labor Day;Christmas Day Company';
        pwPayRuleLines.add(fieldTechPWLine);
        prevailingWagePayRuleLines.add(fieldTechPWLine);

        Pay_Rule_Line__c pwPayRuleLineWithDetailLines = new Pay_Rule_Line__c();
        pwPayRuleLineWithDetailLines.Pay_Rule__c = pwPayRuleWithDetailLines.Id;
        pwPayRuleLineWithDetailLines.Pay_Rule__r = pwPayRuleWithDetailLines;
        pwPayRuleLineWithDetailLines.Resource_Type__c = laborResourceType.Id;
        pwPayRuleLineWithDetailLines.Resource_Type__r = laborResourceType;
        pwPayRuleLineWithDetailLines.Rate__c = 32;
        pwPayRuleLineWithDetailLines.Fringe__c = 20;
        pwPayRuleLineWithDetailLines.OT_Fringe_Amount__c = 30;
        pwPayRuleLineWithDetailLines.DT_Fringe_Amount__c = 40;
        pwPayRuleLineWithDetailLines.Overtime_Rate_Multiple__c = 1.5;
        pwPayRuleLineWithDetailLines.Double_Time_Rate_Multiple__c = 2;
        pwPayRuleLineWithDetailLines.Holidays_with_Overtime_Pay__c = 'Labor Day';
        pwPayRuleLineWithDetailLines.Holiday_with_Double_Time_Pay__c = 'Christmas Day Company';
        pwPayRuleLineWithDetailLines.Eligible_Holidays__c = 'Labor Day;Christmas Day Company';
        prevailingWagePayRuleLines.add(pwPayRuleLineWithDetailLines);

        insert prevailingWagePayRuleLines;

        List<Pay_Rule_Line_Detail__c> payRuleLineDetails = new List<Pay_Rule_Line_Detail__c>();
        Pay_Rule_Line_Detail__c hoursBasedpayRuleLineDetail = new Pay_Rule_Line_Detail__c();
        hoursBasedpayRuleLineDetail.Pay_Rule_Line__c = pwPayRuleLineWithDetailLines.Id;
        hoursBasedpayRuleLineDetail.Calculation_Type__c = 'Hour_Based';
        hoursBasedpayRuleLineDetail.Day__c = 'Monday';
        hoursBasedpayRuleLineDetail.Number_of_Hours__c = 8;
        hoursBasedpayRuleLineDetail.Rate_Code__c = 'REG';
        hoursBasedpayRuleLineDetail.Hours_After_Number_of_Hours__c = 2;
        hoursBasedpayRuleLineDetail.Rate_Code_After_Number_of_Hours__c = 'OT';
        hoursBasedpayRuleLineDetail.Rate_Code_for_Remaining_Hours__c = 'DT';
        payRuleLineDetails.add(hoursBasedpayRuleLineDetail);

        Pay_Rule_Line_Detail__c dayBasedpayRuleLineDetail = new Pay_Rule_Line_Detail__c();
        dayBasedpayRuleLineDetail.Pay_Rule_Line__c = pwPayRuleLineWithDetailLines.Id;
        dayBasedpayRuleLineDetail.Calculation_Type__c = 'Day_Based';
        dayBasedpayRuleLineDetail.Day__c = 'Sunday';
        dayBasedpayRuleLineDetail.Rate_Code__c = 'DT';
        payRuleLineDetails.add(dayBasedpayRuleLineDetail);

        Pay_Rule_Line_Detail__c timeBasedPayRuleLineDetail = new Pay_Rule_Line_Detail__c();
        timeBasedPayRuleLineDetail.Pay_Rule_Line__c = pwPayRuleLineWithDetailLines.Id;
        timeBasedPayRuleLineDetail.Calculation_Type__c = 'Time_Based';
        timeBasedPayRuleLineDetail.Day__c = 'Tuesday';
        timeBasedPayRuleLineDetail.Start_Time__c = Time.newInstance(7,0,0,0);
        timeBasedPayRuleLineDetail.End_Time__c = Time.newInstance(15,0,0,0);
        timeBasedPayRuleLineDetail.Rate_Code__c = 'REG';
        payRuleLineDetails.add(timeBasedPayRuleLineDetail);

        Pay_Rule_Line_Detail__c timeBasedPayRuleLineDetailOT = new Pay_Rule_Line_Detail__c();
        timeBasedPayRuleLineDetailOT.Pay_Rule_Line__c = pwPayRuleLineWithDetailLines.Id;
        timeBasedPayRuleLineDetailOT.Calculation_Type__c = 'Time_Based';
        timeBasedPayRuleLineDetailOT.Day__c = 'Tuesday';
        timeBasedPayRuleLineDetailOT.Start_Time__c = Time.newInstance(0,0,0,0);
        timeBasedPayRuleLineDetailOT.End_Time__c = Time.newInstance(7,0,0,0);
        timeBasedPayRuleLineDetailOT.Rate_Code__c = 'OT';
        payRuleLineDetails.add(timeBasedPayRuleLineDetailOT);

        Pay_Rule_Line_Detail__c timeBasedPayRuleLineDetailDT = new Pay_Rule_Line_Detail__c();
        timeBasedPayRuleLineDetailDT.Pay_Rule_Line__c = pwPayRuleLineWithDetailLines.Id;
        timeBasedPayRuleLineDetailDT.Calculation_Type__c = 'Time_Based';
        timeBasedPayRuleLineDetailDT.Day__c = 'Tuesday';
        timeBasedPayRuleLineDetailDT.Start_Time__c = Time.newInstance(15,0,0,0);
        timeBasedPayRuleLineDetailDT.End_Time__c = Time.newInstance(23,0,0,0);
        timeBasedPayRuleLineDetailDT.Rate_Code__c = 'DT';
        payRuleLineDetails.add(timeBasedPayRuleLineDetailDT);

        insert payRuleLineDetails;

        //pay rule holidays
        List<Pay_Rule_Holiday__c> companyPayRuleHolidays = new List<Pay_Rule_Holiday__c>();

        Pay_Rule_Holiday__c christmasPayRuleHoliday = new Pay_Rule_Holiday__c();
        christmasPayRuleHoliday.Pay_Rule__c = companyPayRule.Id;
        christmasPayRuleHoliday.Name = 'Christmas';
        christmasPayRuleHoliday.Pay_Code__c = 'DBT';
        companyPayRuleHolidays.add(christmasPayRuleHoliday);

        Pay_Rule_Holiday__c laborDayPayRuleHoliday = new Pay_Rule_Holiday__c();
        laborDayPayRuleHoliday.Pay_Rule__c = companyPayRule.Id;
        laborDayPayRuleHoliday.Name = 'Labor Day';
        laborDayPayRuleHoliday.Pay_Code__c = 'O/T';
        companyPayRuleHolidays.add(laborDayPayRuleHoliday);

        insert companyPayRuleHolidays;

        //Holiday
        List<Holiday__c> holidays = new List<Holiday__c>();
        Holiday__c holiday = new Holiday__c();
        holiday.Name = 'Labor Day';
        holiday.Holiday_Name_Map__c = 'Labor Day';
        holiday.Date__c = Date.today().addDays(-1);
        holidays.add(holiday);
        Holiday__c christmas = new Holiday__c();
        christmas.Name = 'Christmas';
        christmas.Holiday_Name_Map__c = 'Christmas Day Company';
        christmas.Date__c = Date.today().addDays(1);
        holidays.add(christmas);

        insert holidays;

        //add to the map
        PayRuleWrapper companyPayRuleWrapper = new PayRuleWrapper(companyPayRule);
        companyPayRuleWrapper.addPayRuleHolidays(companyPayRuleHolidays);
        mapPayRuleWrappersByName.put(companyPayRuleWrapper.PayRule.Name, companyPayRuleWrapper);

        PayRuleWrapper prevailingPayRuleWrapper = new PayRuleWrapper(prevailingWagePayRule);
        prevailingPayRuleWrapper.addPayRuleLines(pwPayRuleLines);
        mapPayRuleWrappersByName.put(prevailingPayRuleWrapper.PayRule.Name, prevailingPayRuleWrapper);

        PayRuleWrapper pwPayRuleWithDetailWrapper = new PayRuleWrapper(pwPayRuleWithDetailLines);
        pwPayRuleWithDetailWrapper.addPayRuleLines(new List<Pay_Rule_Line__c>{pwPayRuleLineWithDetailLines});
        mapPayRuleWrappersByName.put(pwPayRuleWithDetailLines.Name, pwPayRuleWithDetailWrapper);
    }

    //Company Setup >>>>>>>>>>>>
    private static void initCompanySetup() {
        Resource__c wasteDisposalResource = mapResourceWrappersByName.get('Waste Disposal').Resource;
        Resource__c manifestFeeResource = mapResourceWrappersByName.get('Manifest Fee').Resource;
        Resource__c lumpSumResource = mapResourceWrappersByName.get('Bundled').Resource;
        Resource__c miscChargeResource = mapResourceWrappersByName.get('Rental').Resource;
        Resource__c subcontractorResource = mapResourceWrappersByName.get('Subcontractor').Resource;
        Resource__c demurrageResource = mapResourceWrappersByName.get('Transportation').Resource;
        Resource__c fuelSurchargeResource = mapResourceWrappersByName.get('Fuel Surcharge').Resource;
        Resource__c energyInsuranceResource = mapResourceWrappersByName.get('EEC Fee').Resource;
        GL_Account__c interCompanyGLAccount = mapGlAccountsByName.get('24000');
        Billing_Rule__c companyBillingRule = mapBillingRuleWrappersByName.get('Company Default').BillingRule;
        Pay_Rule__c companyPayRule = mapPayRuleWrappersByName.get('Company Default').PayRule;
        Pricing__c defaultPriceList = mapPriceListsByName.get(COMPANY_PRICE_LIST);

        companySetup.Name = 'Default';
        companySetup.Lines_to_Insert__c = 5;
        companySetup.Allow_Posting_From__c = Date.newInstance(system.today().year(), 1, 1);
        companySetup.Allow_Posting_To__c = Date.newInstance(system.today().year(), 12, 31);
        companySetup.Default_Billing_Rule__c = companyBillingRule.Id;
        companySetup.Default_Billing_Rule__r = companyBillingRule;
        companySetup.Price_List__c = defaultPriceList.Id;
        companySetup.Price_List__r = defaultPriceList;
        companySetup.Company_Pay_Rule__c = companyPayRule.Id;
        companySetup.Default_Waste_Disposal_Resource__c = wasteDisposalResource.Id;
        companySetup.Default_Manifest_Fee_Resource__c = manifestFeeResource.Id;
        companySetup.Default_Lump_Sum_Resource__c = lumpSumResource.Id;
        companySetup.Default_Misc_Charges_Taxes_Resource__c = miscChargeResource.Id;
        companySetup.Default_Safety_Plan_Resource__c = miscChargeResource.Id;
        companySetup.Default_Subcontractor_Resource__c = subcontractorResource.Id;
        companySetup.Default_Transportation_Resource__c = demurrageResource.Id;
        companySetup.Default_Fuel_Surcharge_Resource__c = fuelSurchargeResource.Id;
        companySetup.Default_Energy_Insurance_Resource__c = energyInsuranceResource.Id;
        companySetup.Default_Rental_Resource__c = miscChargeResource.Id;
        companySetup.Equipment_Inter_co_Due_from_Account__c = interCompanyGLAccount.Id;
        companySetup.Equipment_Inter_co_Due_to_Account__c = interCompanyGLAccount.Id;
        companySetup.Labor_Inter_co_Due_from_Account__c = interCompanyGLAccount.Id;
        companySetup.Labor_Inter_co_Due_to_Account__c = interCompanyGLAccount.Id;
        companySetup.Overtime_Unit_Cost_Multiplier__c = 1.3;
        companySetup.Double_Time_Unit_Cost_Multiplier__c = 1.6;


        insert companySetup;
    }

    //Payment Terms >>>>>>>>>>>>
    private static void initPaymentTerms() {
        Payment_Term__c paymentTerm = new Payment_Term__c();
        paymentTerm.Name = 'NET 30';
        paymentTerm.Discount_Pct__c = 0;
        paymentTerm.Discount_Date_Calculation__c = 0;
        paymentTerm.Due_Date_Calculation__c = 0;
        mapPaymentTermsByName.put(paymentTerm.Name, paymentTerm);

        insert mapPaymentTermsByName.values();
    }

    //Tax Areas >>>>>>>>>>>>
    private static void initTaxAreas() {
        //tax areas
        List<Tax_Area__c> taxAreas = new List<Tax_Area__c>();

        GL_Account__c salesTaxGLAccount = mapGlAccountsByName.get('23000');

        Tax_Area__c taxArea1 = new Tax_Area__c();
        taxArea1.Name = 'NJ';
        taxArea1.Sales_Tax_Account__c = salesTaxGlAccount.Id;
        taxAreas.add(taxArea1);
        insert taxAreas;

        //tax jurisdictions
        List<Tax_Jurisdiction__c> taxJurisdictions = new List<Tax_Jurisdiction__c>();
        Tax_Jurisdiction__c taxJurisdiction1 = new Tax_Jurisdiction__c();
        taxJurisdiction1.Name = 'NJ';
        taxJurisdiction1.Tax_Area__c = taxArea1.Id;
        taxJurisdiction1.Tax_Area__r = taxArea1;
        taxJurisdictions.add(taxJurisdiction1);
        insert taxJurisdictions;

        //tax details
        List<Tax_Detail__c> taxDetails = new List<Tax_Detail__c>();
        Tax_Detail__c taxDetail1 = new Tax_Detail__c();
        taxDetail1.Name = 'NJ';
        taxDetail1.Tax_Area__c = taxJurisdiction1.Tax_Area__c;
        taxDetail1.Tax_Area__r = taxJurisdiction1.Tax_Area__r;
        taxDetail1.Tax_Jurisdiction__c = taxJurisdiction1.Id;
        taxDetail1.Tax_Jurisdiction__r = taxJurisdiction1;
        taxDetail1.Tax_Group__c = 'TX';
        taxDetail1.Tax_Pct__c = 0.625;
        taxDetails.add(taxDetail1);
        insert taxDetails;

        //add to the map
        TaxAreaWrapper taxAreaWrapper = new TaxAreaWrapper(taxArea1);
        taxAreaWrapper.addTaxJurisdiction(taxJurisdiction1);
        taxAreaWrapper.addTaxDetail(taxJurisdiction1.Name, taxDetail1);
        mapTaxAreaWrappersByName.put(taxAreaWrapper.TaxArea.Name, taxAreaWrapper);
    }

    //Salespeople >>>>>>>>>>>>
    private static void initSalespeople() {
        Salesperson__c salesperson = new Salesperson__c();
        salesperson.Name = 'Salesperson';
        salesperson.First_Name__c = 'Kelly';
        salesperson.Last_Name__c = 'Menzel';
        salesperson.Salesperson_Code__c = '06-RAF';
        salesperson.AR_Email__c = true;
        salesperson.Status__c = 'Active';
        mapSalespeopleByName.put(salesperson.Name, salesperson);

        Salesperson__c accountExecutive = new Salesperson__c();
        accountExecutive.Name = 'Account Executive';
        accountExecutive.First_Name__c = 'Matto';
        accountExecutive.Last_Name__c = 'Portuesi';
        accountExecutive.Salesperson_Code__c = '06-POR';
        accountExecutive.AR_Email__c = true;
        accountExecutive.Account_Executive__c = true;
        accountExecutive.Status__c = 'Active';
        mapSalespeopleByName.put(accountExecutive.Name, accountExecutive);

        insert mapSalespeopleByName.values();
    }

    //Accounts >>>>>>>>>>>>
    private static void initAccounts() {
        List<Account> accounts = new List<Account>();

        Salesperson__c salesperson = mapSalespeopleByName.get('Salesperson');
        Salesperson__c accountExecutive = mapSalespeopleByName.get('Account Executive');
        Payment_Term__c paymentTerm = mapPaymentTermsByName.get('NET 30');
        Tax_Area__c taxArea = mapTaxAreaWrappersByName.get('NJ').TaxArea;
        Subsidiary_Company__c subsidiaryCompany = mapSubsidiaryCompaniesByName.get('1-ACV ENVIRO');

        //Customer
        Account customer = new Account();
        customer.Name = 'Customer';
        customer.AccountNumber = '01-0000001';
        customer.Type = 'Customer';
        customer.Payment_Term__c = paymentTerm.Id;
        customer.Tax_Area__c = taxArea.Id;
        customer.BillingStreet = '123 ABC Ave' + '\n' + 'Suite 123';
        customer.BillingState = 'New York';
        customer.BillingStateCode = 'NY';
        customer.BillingCity = 'New York';
        customer.BillingCountry = 'United States';
        customer.BillingCountryCode = 'US';
        customer.BillingPostalCode = '10002';
        customer.Customer_Type__c = 'UTILITIES';
        customer.Account_Executive__c = accountExecutive.Id;
        customer.Salesperson__c = salesperson.Id;
        customer.Subsidiary_Company__c = subsidiaryCompany.Id;
        customer.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        customer.PO_Number_Type__c = 'NUMERICAL';
        accounts.add(customer);

        Account customer2 = new Account();
        customer2.Name = 'Customer 2';
        customer2.AccountNumber = '01-0000002';
        customer2.Type = 'Customer 2';
        customer2.Payment_Term__c = paymentTerm.Id;
        customer2.Tax_Area__c = taxArea.Id;
        customer2.BillingStreet = '123 ABC Ave' + '\n' + 'Suite 123';
        customer2.BillingState = 'New York';
        customer2.BillingStateCode = 'NY';
        customer2.BillingCity = 'New York';
        customer2.BillingCountry = 'United States';
        customer2.BillingCountryCode = 'US';
        customer2.BillingPostalCode = '10002';
        customer2.Customer_Type__c = 'UTILITIES';
        customer2.Account_Executive__c = accountExecutive.Id;
        customer2.Salesperson__c = salesperson.Id;
        customer2.Subsidiary_Company__c = subsidiaryCompany.Id;
        customer2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        customer2.PO_Number_Type__c = 'NUMERICAL';
        accounts.add(customer2);

        //Vendor
        Account vendor = new Account();
        vendor.Name = 'Vendor';
        vendor.AccountNumber = 'V00001';
        vendor.Type = 'Vendor';
        vendor.Payment_Term__c = paymentTerm.Id;
        vendor.Auto_Create_Catalog_Item__c = true;
        vendor.BillingStreet = '123 ABC Ave' + '\n' + 'Suite 123';
        vendor.BillingState = 'New York';
        vendor.BillingStateCode = 'NY';
        vendor.BillingCity = 'New York';
        vendor.BillingCountry = 'United States';
        vendor.BillingCountryCode = 'US';
        vendor.BillingPostalCode = '10002';
        vendor.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        accounts.add(vendor);

        insert accounts;

        //contacts
        List<Contact> contacts = new List<Contact>();

        Contact customerContact = new Contact();
        customerContact.AccountId = customer.Id;
        customerContact.Account = customer;
        customerContact.FirstName = 'John';
        customerContact.LastName = 'Smith';
        customerContact.MailingStreet = '123 ABC Ave' + '\n' + 'Suite 123';
        customerContact.MailingStateCode = 'NY';
        customerContact.MailingState = 'New York';
        customerContact.MailingCity = 'New York';
        customerContact.MailingCountry = 'United States';
        customerContact.MailingCountryCode = 'US';
        customerContact.MailingPostalCode = '10002';
        customerContact.Contact_Type__c = 'Site;Quote;Billing;Purchase;Executive;Sales';
        contacts.add(customerContact);

        insert contacts;

        //site addresses
        List<Site_Address__c> siteAddresses = new List<Site_Address__c>();

        Site_Address__c siteAddress = new Site_Address__c();
        siteAddress.Name = 'Site A';
        siteAddress.Site_Street__c = '123 ABC Ave';
        siteAddress.Site_City__c = 'New York';
        siteAddress.Site_State__c = 'NY';
        siteAddress.Site_Postal_Code__c = '10002';
        siteAddress.Site_Country__c = 'US';
        siteAddress.Contact__c = customerContact.Id;
        siteAddress.Customer__c = customer.Id;
        siteAddresses.add(siteAddress);

        insert siteAddresses;

        //subsidiary vendors
        List<Subsidiary_Vendor__c> subsidiaryVendors = new List<Subsidiary_Vendor__c>();

        Map<String, Subsidiary_Vendor__c> mapSubsidiaryVendorsByName = new Map<String, Subsidiary_Vendor__c>();
        Subsidiary_Vendor__c subsidiaryVendor = new Subsidiary_Vendor__c();
        subsidiaryVendor.Name = 'Subsidiary Vendor';
        subsidiaryVendor.Subsidiary_Company__c = subsidiaryCompany.Id;
        subsidiaryVendor.Account__c = vendor.Id;
        subsidiaryVendors.add(subsidiaryVendor);

        insert subsidiaryVendors;

        //add to the map
        AccountWrapper customerWrapper = new AccountWrapper(customer);
        customerWrapper.addContact(customerContact);
        customerWrapper.addSiteAddress(siteAddress);
        mapAccountWrappersByName.put(customerWrapper.Account.Name, customerWrapper);

        AccountWrapper customer2Wrapper = new AccountWrapper(customer2);
        mapAccountWrappersByName.put(customer2Wrapper.Account.Name, customer2Wrapper);

        AccountWrapper vendorWrapper = new AccountWrapper(vendor);
        vendorWrapper.addSubsidiaryVendor(subsidiaryVendor);
        mapAccountWrappersByName.put(vendorWrapper.Account.Name, vendorWrapper);
    }

    //Price List
    private static void initPriceLists() {
        Pricing__c priceList1 = new Pricing__c();
        priceList1.Name = COMPANY_PRICE_LIST;
        mapPriceListsByName.put(priceList1.Name, priceList1);
        Pricing__c scPriceList = new Pricing__c();
        scPriceList.Name = SC_PRICE_LIST;
        mapPriceListsByName.put(scPriceList.Name, scPriceList);
        insert mapPriceListsByName.values();
    }

    //Rate Sheets >>>>>>>>>>
    private static void initRateSheets() {
        //rate sheets
        List<Rate_Sheet__c> rateSheets = new List<Rate_Sheet__c>();

        Rate_Sheet__c rateSheet1 = new Rate_Sheet__c();
        rateSheet1.Name = COMPANY_PRICE_LIST;
        mapRateSheetsByName.put(COMPANY_PRICE_LIST, rateSheet1);

        Rate_Sheet__c scRateSheet = new Rate_Sheet__c();
        scRateSheet.Name = SC_PRICE_LIST;
        mapRateSheetsByName.put(SC_PRICE_LIST, scRateSheet);

        Rate_Sheet__c tmRateSheet = new Rate_Sheet__c();
        tmRateSheet.Name = TM_PRICE_LIST;
        mapRateSheetsByName.put(TM_PRICE_LIST, tmRateSheet);
        insert mapRateSheetsByName.values();

        //rate sheet lines
        List<Rate_Sheet_Line__c> rateSheetLines = new List<Rate_Sheet_Line__c>();
        for (ResourceTypeWrapper resourceTypeWrapper : mapResourceTypeWrappersByName.values()) {
            Resource_Type__c resourceType = resourceTypeWrapper.ResourceType;
            Rate_Sheet_Line__c rateSheetLine = new Rate_Sheet_Line__c();
            rateSheetLine.Rate_Sheet__c = rateSheet1.Id;
            rateSheetLine.Resource_Type__c = resourceType.Id;
            rateSheetLine.Resource_Type__r = resourceType;
            rateSheetLine.Unit_of_Measure__c = resourceType.Unit_of_Measure__c;
            rateSheetLine.Unit_of_Measure__r = resourceType.Unit_of_Measure__r;
            rateSheetLine.Unit_Price__c = 100;
            rateSheetLine.ER_Unit_Price__c = 100;
            rateSheetLine.Unit_Cost__c = 50;
            rateSheetLine.Default__c = true;
            rateSheetLines.add(rateSheetLine);
        }

        for (ResourceWrapper resourceWrapper : mapResourceWrappersByName.values()) {
            Resource__c resource = resourceWrapper.Resource;
            Rate_Sheet_Line__c rateSheetLine = new Rate_Sheet_Line__c();
            rateSheetLine.Rate_Sheet__c = rateSheet1.Id;
            rateSheetLine.Resource__c = resource.Id;
            rateSheetLine.Resource__r = resource;
            rateSheetLine.Unit_of_Measure__c = resource.Unit_of_Measure__c;
            rateSheetLine.Unit_of_Measure__r = resource.Unit_of_Measure__r;
            rateSheetLine.Unit_Price__c = 100;
            rateSheetLine.ER_Unit_Price__c = 100;
            rateSheetLine.Unit_Cost__c = 50;
            rateSheetLine.Default__c = true;
            rateSheetLines.add(rateSheetLine);
        }

        Resource_Type__c resourceType = mapResourceTypesByName.get(RESOURCE_TYPE_COMPANY_RATESHEET);
        Rate_Sheet_Line__c rateSheetLine = new Rate_Sheet_Line__c();
        rateSheetLine.Rate_Sheet__c = rateSheet1.Id;
        rateSheetLine.Resource_Type__c = resourceType.Id;
        rateSheetLine.Resource_Type__r = resourceType;
        rateSheetLine.Unit_of_Measure__c = resourceType.Unit_of_Measure__c;
        rateSheetLine.Unit_of_Measure__r = resourceType.Unit_of_Measure__r;
        rateSheetLine.Unit_Price__c = 100;
        rateSheetLine.ER_Unit_Price__c = 100;
        rateSheetLine.Unit_Cost__c = 50;
        rateSheetLine.Default__c = true;
        rateSheetLines.add(rateSheetLine);

        //SC Ratesheet Line
        resourceType = mapResourceTypesByName.get(RESOURCE_TYPE_SC_RATESHEET);
        rateSheetLine = new Rate_Sheet_Line__c();
        rateSheetLine.Rate_Sheet__c = scRateSheet.Id;
        rateSheetLine.Resource_Type__c = resourceType.Id;
        rateSheetLine.Resource_Type__r = resourceType;
        rateSheetLine.Unit_of_Measure__c = resourceType.Unit_of_Measure__c;
        rateSheetLine.Unit_of_Measure__r = resourceType.Unit_of_Measure__r;
        rateSheetLine.Unit_Price__c = 100;
        rateSheetLine.ER_Unit_Price__c = 100;
        rateSheetLine.Unit_Cost__c = 50;
        rateSheetLine.Default__c = true;
        rateSheetLines.add(rateSheetLine);

        insert rateSheetLines;

        //pricing rate sheet associations
        List<Pricing_Rate_Sheet_Association__c> pricingRateSheetAssociations = new List<Pricing_Rate_Sheet_Association__c>();
        //Company Ratesheet association
        Pricing_Rate_Sheet_Association__c pricingRateSheetAssociation1 = new Pricing_Rate_Sheet_Association__c();
        pricingRateSheetAssociation1.Pricing__c = mapPriceListsByName.get(COMPANY_PRICE_LIST).Id;
        pricingRateSheetAssociation1.Rate_Sheet__c = rateSheet1.Id;
        pricingRateSheetAssociation1.Effective_Date__c = System.today().addDays(-30);
        pricingRateSheetAssociations.add(pricingRateSheetAssociation1);

        //SC Ratesheet association
        pricingRateSheetAssociation1 = new Pricing_Rate_Sheet_Association__c();
        pricingRateSheetAssociation1.Pricing__c = mapPriceListsByName.get(SC_PRICE_LIST).Id;
        pricingRateSheetAssociation1.Rate_Sheet__c = scRateSheet.Id;
        pricingRateSheetAssociation1.Effective_Date__c = System.today().addDays(-30);
        pricingRateSheetAssociations.add(pricingRateSheetAssociation1);

        insert pricingRateSheetAssociations;

        //add to the map
        RateSheetWrapper rateSheetWrapper1 = new RateSheetWrapper(rateSheet1);
        rateSheetWrapper1.addRateSheetLines(rateSheetLines);
        rateSheetWrapper1.addPricingRateSheetAssociations(pricingRateSheetAssociations);
        mapRateSheetWrappersByName.put(rateSheetWrapper1.RateSheet.Name, rateSheetWrapper1);
    }

    //Price List Rate Sheet >>>>>>>>>>

    //Contracts >>>>>>>>>>
    private static void initContracts() {
        //contracts
        List<Contract> contracts = new List<Contract>();

        Account customer = mapAccountWrappersByName.get('Customer').Account;
        Billing_Rule__c billingRule = mapBillingRuleWrappersByName.get('Company Default').BillingRule;

        Contract contract1 = new Contract();
        contract1.Name = 'Contract';
        contract1.AccountId = customer.Id;
        contract1.StartDate = System.today().addDays(-200);
        contract1.ContractTerm = 14;
        contract1.Status = 'Draft';
        contract1.Subsidiary__c = '1-ACV ENVIRO';
        contract1.Surcharge_Type__c = 'Fuel Surcharge';
        contract1.Surcharge_Pct__c = 10;
        contract1.Billing_Rule__c = billingRule.Id;
        contract1.Billing_Rule__r = billingRule;
        contract1.Logo__c= '<img src=" Republic Services " alt="';
        contracts.add(contract1);
        insert contracts;

        for (Contract contract2 : contracts) {
            contract2.Status = 'Activated';
        }
        update contracts;

        //contract lines
        List<Contract_Line__c> contractLines = new List<Contract_Line__c>();

        Resource_Type__c laborResourceType = mapResourceTypeWrappersByName.get('Labor').ResourceType;
        Resource_Type__c resourceType = mapResourceTypesByName.get(RESOURCE_TYPE_CONTRACTED);
        Resource__c  laborResource = mapResourceWrappersByName.get('Labor').Resource;
        Unit_of_Measure__c hourUnitOfMeasure = mapUnitOfMeasuresByName.get('HR');

        Contract_Line__c contractLine1 = new Contract_Line__c();
        contractLine1.Contract__c = contract1.Id;
        contractLine1.Premium_Rate__c = 10;
        contractLine1.Resource__c = laborResource.Id;
        contractLine1.Resource_Type__c = laborResourceType.Id;
        contractLine1.Unit_of_Measure__c = hourUnitOfMeasure.Id;
        contractLines.add(contractLine1);

        Contract_Line__c contractLine2 = new Contract_Line__c();
        contractLine2.Contract__c = contract1.Id;
        contractLine2.Premium_Rate__c = 10;
        contractLine2.Resource_Type__c = resourceType.Id;
        contractLine2.Unit_of_Measure__c = resourceType.Unit_of_Measure__c;
        contractLines.add(contractLine2);

        insert contractLines;

        //add to the map
        ContractWrapper contractWrapper1 = new ContractWrapper(contract1);
        contractWrapper1.addContractLines(contractLines);
        mapContractWrappersByName.put(contractWrapper1.Contract.Name, contractWrapper1);
    }

    //Billing Rules >>>>>>>>>>
    private static void initBillingRules() {
        //billing rules
        List<Billing_Rule__c> billingRules = new List<Billing_Rule__c>();
        Billing_Rule__c billingRule1 = new Billing_Rule__c();
        billingRule1.Name = 'Company Default';
        billingRule1.Holidays_Bill_in_DT_Rate__c = 'Christmas Day Company';
        billingRule1.Holidays_Bill_in_OT_Rate__c = 'Thanksgiving';
        billingRule1.Sunday_Rate_Code__c = EnumUtil.TimeRateCode.DT.name();
        billingRule1.Saturday_Rate_Code__c = EnumUtil.TimeRateCode.OT.name();
        billingRule1.Quote_Order_Assumption__c = 'PortalBasisAdv;LumpSum;DailyRate;OvertimeRate;PortalBasis;DefaultBillingRule2023;LumpSum2023';
        billingRules.add(billingRule1);
        insert billingRules;

        //billing rule lines
        List<Billing_Rule_Line__c> billingRuleLines = new List<Billing_Rule_Line__c>();
        Billing_Rule_Line__c billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule1.Id;
        billingRuleLine.Billing_Rule__r = billingRule1;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,30,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule1.Id;
        billingRuleLine.Billing_Rule__r = billingRule1;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,30,0,0);
        billingRuleLine.Hours_After_Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code_After_Number_of_Hours__c = 'OT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule1.Id;
        billingRuleLine.Billing_Rule__r = billingRule1;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,30,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule1.Id;
        billingRuleLine.Billing_Rule__r = billingRule1;
        billingRuleLine.Calculation_Type__c = 'Hour_Based';
        billingRuleLine.Day__c = 'Tuesday';
        billingRuleLine.Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Rate_Code_for_Remaining_Hours__c = 'OT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule1.Id;
        billingRuleLine.Billing_Rule__r = billingRule1;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule1.Id;
        billingRuleLine.Billing_Rule__r = billingRule1;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule1.Id;
        billingRuleLine.Billing_Rule__r = billingRule1;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule1.Id;
        billingRuleLine.Billing_Rule__r = billingRule1;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule1.Id;
        billingRuleLine.Billing_Rule__r = billingRule1;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule1.Id;
        billingRuleLine.Billing_Rule__r = billingRule1;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule1.Id;
        billingRuleLine.Billing_Rule__r = billingRule1;
        billingRuleLine.Calculation_Type__c = 'Hour_Based';
        billingRuleLine.Day__c = 'Friday';
        billingRuleLine.Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Hours_After_Number_of_Hours__c = 3;
        billingRuleLine.Rate_Code_After_Number_of_Hours__c = 'OT';
        billingRuleLine.Rate_Code_for_Remaining_Hours__c = 'DT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule1.Id;
        billingRuleLine.Billing_Rule__r = billingRule1;
        billingRuleLine.Calculation_Type__c = 'Day_Based';
        billingRuleLine.Day__c = 'Saturday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLines.add(billingRuleLine);

        insert billingRuleLines;

        //add to the map
        BillingRuleWrapper billingRuleWrapper1 = new BillingRuleWrapper(billingRule1);
        billingRuleWrapper1.addBillingRuleLines(billingRuleLines);
        mapBillingRuleWrappersByName.put(billingRuleWrapper1.BillingRule.Name, billingRuleWrapper1);
    }

    //Template >>>>>>>>>>
    private static void initJobTaskTemplates() {
        Job_Task_Template__c jobTaskTemplate = new Job_Task_Template__c();
        jobTaskTemplate.Name = JOB_TEMPLATE_NAME;
        insert jobTaskTemplate;

        List<Job_Task_Template_Line__c> jobTaskTemplateLines = new List<Job_Task_Template_Line__c>();
        Job_Task_Template_Line__c jobTaskTemplateLine1 = new Job_Task_Template_Line__c();
        jobTaskTemplateLine1.Job_Task_Template__c = jobTaskTemplate.Id;
        jobTaskTemplateLine1.Line_No__c = 1;
        jobTaskTemplateLine1.Category__c = 'Labor';
        ResourceTypeWrapper laborResourceTypeWrapper = mapResourceTypeWrappersByName.get('Labor');
        jobTaskTemplateLine1.Resource_Type__c = laborResourceTypeWrapper.ResourceType.Id;
        jobTaskTemplateLine1.Description__c = laborResourceTypeWrapper.ResourceType.Description__c;
        jobTaskTemplateLine1.Unit_of_Measure__c = laborResourceTypeWrapper.mapResourceTypeUOMAssociations.get('HR').Unit_of_Measure__c;
        jobTaskTemplateLine1.Quantity__c = 1;
        jobTaskTemplateLines.add(jobTaskTemplateLine1);

        Job_Task_Template_Line__c jobTaskTemplateLine2 = new Job_Task_Template_Line__c();
        jobTaskTemplateLine2.Job_Task_Template__c = jobTaskTemplate.Id;
        jobTaskTemplateLine2.Line_No__c = 2;
        jobTaskTemplateLine2.Category__c = 'Materials';
        ResourceWrapper materialResourceWrapper = mapResourceWrappersByName.get('Material');
        jobTaskTemplateLine2.Resource__c = materialResourceWrapper.Resource.Id;
        jobTaskTemplateLine2.Description__c = materialResourceWrapper.Resource.Description__c;
        jobTaskTemplateLine2.Unit_of_Measure__c = materialResourceWrapper.mapResourceUOMAssociationsByName.get('EA').Unit_of_Measure__c;
        jobTaskTemplateLine2.Quantity__c = 1;
        jobTaskTemplateLines.add(jobTaskTemplateLine2);

        Job_Task_Template_Line__c jobTaskTemplateLine3 = new Job_Task_Template_Line__c();
        jobTaskTemplateLine3.Job_Task_Template__c = jobTaskTemplate.Id;
        jobTaskTemplateLine3.Line_No__c = 3;
        jobTaskTemplateLine3.Category__c = 'Equipment';
        ResourceTypeWrapper equipmentResourceTypeWrapper = mapResourceTypeWrappersByName.get('Equipment');
        jobTaskTemplateLine3.Resource_Type__c = equipmentResourceTypeWrapper.ResourceType.Id;
        jobTaskTemplateLine3.Description__c = equipmentResourceTypeWrapper.ResourceType.Description__c;
        jobTaskTemplateLine3.Unit_of_Measure__c = mapUnitOfMeasuresByName.get('HR').Id;
        jobTaskTemplateLine3.Quantity__c = 1;
        jobTaskTemplateLines.add(jobTaskTemplateLine3);




        insert jobTaskTemplateLines;
        jobTaskTemplateLine2.Parent_Line__c = jobTaskTemplateLine1.Id;
        jobTaskTemplateLine3.Parent_Line__c = jobTaskTemplateLine1.Id;
        update jobTaskTemplateLines;

        JobTaskTemplateWrapper jobTaskTemplateWrapper = new JobTaskTemplateWrapper(jobTaskTemplate);
        jobTaskTemplateWrapper.addJobTaskTemplateLines(jobTaskTemplateLines);
        mapJobTaskTemplateWrappersByName.put(jobTaskTemplate.Name, jobTaskTemplateWrapper);
    }

    //Sales Order Types >>>>>>>>>>
    private static void initSalesOrderTypes() {
        Sales_Order_Type__c salesOrderType1 = new Sales_Order_Type__c();
        salesOrderType1.Name = 'Field Services';
        salesOrderType1.Description__c = 'Field Services';
        salesOrderType1.Code__c = '1';
        salesOrderType1.Emergency_Response__c = true;
        salesOrderType1.Job_Task_Template__c = mapJobTaskTemplateWrappersByName.get('Field Services').JobTaskTemplate.Id;
        mapSalesOrderTypesByName.put(salesOrderType1.Name, salesOrderType1);

        Sales_Order_Type__c salesOrderType2 = new Sales_Order_Type__c();
        salesOrderType2.Name = 'Emergency Response';
        salesOrderType2.Description__c = 'Emergency Response';
        salesOrderType2.Emergency_Response__c = true;
        salesOrderType2.Code__c = '1';
        mapSalesOrderTypesByName.put(salesOrderType2.Name, salesOrderType2);

        insert mapSalesOrderTypesByName.values();
    }

    //Sales Orders >>>>>>>>>>
    private static void initSalesOrders() {
        List<Sales_Order__c> salesOrders = new List<Sales_Order__c>();

        Billing_Rule__c billingRule = mapBillingRuleWrappersByName.get('Company Default').BillingRule;
        AccountWrapper customerWrapper = mapAccountWrappersByName.get('Customer');
        Service_Center__c serviceCenter = mapServiceCenterWrappersByName.get('02').ServiceCenter;
        Sales_Order_Type__c salesOrderType = mapSalesOrderTypesByName.get('Field Services');
        Subsidiary_Company__c subsidiaryCompany = mapSubsidiaryCompaniesByName.get('1-ACV ENVIRO');
        Contract contract = mapContractWrappersByName.get('Contract').Contract;
        Salesperson__c projectCoordinator = mapSalespeopleByName.get('Salesperson');
        Salesperson__c accountExecutive = mapSalespeopleByName.get('Account Executive');
        Payment_Term__c paymentTerm = mapPaymentTermsByName.get('NET 30');
        TaxAreaWrapper taxAreaWrapper = mapTaxAreaWrappersByName.get('NJ');
        Rate_Sheet__c rateSheet = mapRateSheetWrappersByName.get(COMPANY_PRICE_LIST).RateSheet;

        Sales_Order__c salesOrder1 = new Sales_Order__c();
        salesOrder1.Name = TEST_SO_NAME_01;
        salesOrder1.Document_Type__c = 'Sales Order';
        salesOrder1.Document_Status__c = 'Open';
        salesOrder1.Subsidiary_Company__c = subsidiaryCompany.Id;
        salesOrder1.Service_Center__c = serviceCenter.Id;
        salesOrder1.Sales_Order_Type__c = salesOrderType.Id;
        salesOrder1.Rate_Sheet__c = rateSheet.Id;
        salesOrder1.Quote_Date__c = system.today();
        salesOrder1.Bill_to_Customer_No__c = customerWrapper.Account.Id;
        salesOrder1.Bill_to_Customer_No__r = customerWrapper.Account;
        salesOrder1.Customer_PO_No__c = '12345';
        salesOrder1.Bill_to_Contact__c = customerWrapper.mapContactByName.get('John Smith').Id;
        salesOrder1.Quote_Contact__c = customerWrapper.mapContactByName.get('John Smith').Id;
        salesOrder1.Project_Coordinator__c = projectCoordinator.Id;
        salesOrder1.Account_Executives__c = accountExecutive.Id;
        salesOrder1.Payment_Term__c = paymentTerm.Id;
        salesOrder1.Surcharge_Type__c = 'EEC Fee';
        salesOrder1.Surcharge_Pct__c = 11;
        salesOrder1.Contract__c = contract.Id;
        salesOrder1.Estimated_Job_Start_Date__c = system.today();
        salesOrder1.Duration__c = 2;
        salesOrder1.Estimated_Job_Start_Time__c = Time.newInstance(8, 0, 0, 0);
        salesOrder1.Estimated_Job_End_Time__c = Time.newInstance(16, 0, 0, 0);
        salesOrder1.Job_Description__c = 'Test';
        salesOrder1.Billing_Rule__c = billingRule.Id;
        salesOrder1.Tax_Area__c = taxAreaWrapper.TaxArea.Id;
        salesOrder1.Tax_Liable__c = true;
        salesOrder1.Site_Scope__c = 'scope text';
        salesOrder1.Manifest_And_Profile__c = true;
        salesOrder1.Charge_Rinse_Out_Fee__c = true;
        salesOrder1.From_Sales_Quote__c = mapSalesOrdersByName.get('SQ1').Id;
        salesOrders.add(salesOrder1);

        insert salesOrders;

        //sales order job task
        List<Sales_Order_Job_Task__c> jobTasks = new List<Sales_Order_Job_Task__c>();
        Sales_Order_Job_Task__c jobTask1 = new Sales_Order_Job_Task__c();
        jobTask1.Sales_Order__c = salesOrder1.Id;
        jobTask1.Billing_Type__c = 'Fixed Price';
        jobTask1.Fixed_Price_Surcharge_Option__c = 'Fixed Price Does Not Include Surcharge';
        jobTask1.Line_No__c = 1;
        jobTask1.Task_No__c = 1;
        jobTask1.Name = 'Field Service';
        jobTasks.add(jobTask1);
        insert jobTasks;
        mapSalesOrderJobTaskBySalesOrderId.put(salesOrder1.Id, jobTask1);

        //sales order lines
        List<Sales_Line__c> salesLines = new List<Sales_Line__c>();
        Map<String, Sales_Line__c> salesLineByCategory = new Map<String, Sales_Line__c>();
        Resource_Type__c lumpSumResourceType = mapResourceTypeWrappersByName.get(ResourceService.LUMP_SUM_CATEGORY).ResourceType;

        Sales_Line__c lumpSumSalesLine = new Sales_Line__c();
        lumpSumSalesLine.Sales_Order__c = salesOrder1.Id;
        lumpSumSalesLine.Sales_Order_Job_Task__c = jobTask1.Id;
        lumpSumSalesLine.Line_No__c = 1;
        lumpSumSalesLine.Category__c = ResourceService.LUMP_SUM_CATEGORY;
        lumpSumSalesLine.Resource_Type__c = lumpSumResourceType.Id;
        lumpSumSalesLine.Unit_of_Measure__c = lumpSumResourceType.Unit_of_Measure__c;
        lumpSumSalesLine.Quantity__c = 1;
        lumpSumSalesLine.Unit_Price__c = 100;
        lumpSumSalesLine.xUnit_Price__c = 100;
        lumpSumSalesLine.Unit_Cost__c = 50;
        lumpSumSalesLine.xUnit_Cost__c = 50;
        lumpSumSalesLine.Tax_Group__c = 'TX';
        lumpSumSalesLine.Tax_Pct__c = 8;
        salesLines.add(lumpSumSalesLine);
        salesLineByCategory.put(ResourceService.LUMP_SUM_CATEGORY, lumpSumSalesLine);

        //labor
        Resource_Type__c laborResourceType = mapResourceTypeWrappersByName.get(ResourceService.LABOR_CATEGORY).ResourceType;
        Sales_Line__c laborSalesLine = new Sales_Line__c();
        laborSalesLine.Sales_Order__c = salesOrder1.Id;
        laborSalesLine.Sales_Order_Job_Task__c = jobTask1.Id;
        laborSalesLine.Line_No__c = 2;
        laborSalesLine.Category__c = ResourceService.LABOR_CATEGORY;
        laborSalesLine.Resource_Type__c = laborResourceType.Id;
        laborSalesLine.Unit_of_Measure__c = laborResourceType.Unit_of_Measure__c;
        laborSalesLine.Quantity__c = 1;
        laborSalesLine.Number_of_Day__c = 1;
        laborSalesLine.UOM_Qty__c = 8;
        laborSalesLine.Unit_Price__c = 100;
        laborSalesLine.xUnit_Price__c = 100;
        laborSalesLine.Unit_Cost__c = 50;
        laborSalesLine.xUnit_Cost__c = 50;
        laborSalesLine.Tax_Group__c = 'TX';
        laborSalesLine.Tax_Pct__c = 8;
        laborSalesLine.Regular_Rate__c = 100;
        laborSalesLine.Overtime_Rate__c = 150;
        laborSalesLine.Premium_Rate__c = 200;
        salesLines.add(laborSalesLine);
        salesLineByCategory.put(ResourceService.LABOR_CATEGORY, laborSalesLine);

        Resource_Type__c salesOrderResourceType = mapResourceTypesByName.get(RESOURCE_TYPE_ORDER);
        Sales_Line__c laborOrderLine = new Sales_Line__c();
        laborOrderLine.Sales_Order__c = salesOrder1.Id;
        laborOrderLine.Sales_Order_Job_Task__c = jobTask1.Id;
        laborOrderLine.Line_No__c = 6;
        laborOrderLine.Category__c = ResourceService.LABOR_CATEGORY;
        laborOrderLine.Resource_Type__c = salesOrderResourceType.Id;
        laborOrderLine.Unit_of_Measure__c = salesOrderResourceType.Unit_of_Measure__c;
        laborOrderLine.Quantity__c = 1;
        laborOrderLine.Number_of_Day__c = 1;
        laborOrderLine.UOM_Qty__c = 8;
        laborOrderLine.Unit_Price__c = 100;
        laborOrderLine.xUnit_Price__c = 100;
        laborOrderLine.Unit_Cost__c = 50;
        laborOrderLine.xUnit_Cost__c = 50;
        laborOrderLine.Tax_Group__c = 'TX';
        laborOrderLine.Tax_Pct__c = 8;
        laborOrderLine.Regular_Rate__c = 100;
        laborOrderLine.Overtime_Rate__c = 150;
        laborOrderLine.Premium_Rate__c = 200;
        salesLines.add(laborOrderLine);
        salesLineByCategory.put(ResourceService.LABOR_CATEGORY + RESOURCE_TYPE_ORDER, laborOrderLine);

        Sales_Line__c laborSalesLine2 = new Sales_Line__c();
        laborSalesLine2 = new Sales_Line__c();
        laborSalesLine2.Sales_Order__c = salesOrder1.Id;
        laborSalesLine2.Sales_Order_Job_Task__c = jobTask1.Id;
        laborSalesLine2.Line_No__c = 5;
        laborSalesLine2.Category__c = ResourceService.LABOR_CATEGORY;
        laborSalesLine2.Resource_Type__c = laborResourceType.Id;
        //laborSalesLine2.Unit_of_Measure__c = mapUnitOfMeasuresByName.get('DAY').Id;
        laborSalesLine2.Unit_of_Measure__c = laborResourceType.Unit_of_Measure__c;
        laborSalesLine2.Quantity__c = 1;
        laborSalesLine2.Number_of_Day__c = 1;
        laborSalesLine2.UOM_Qty__c = 8;
        laborSalesLine2.Unit_Price__c = 100;
        laborSalesLine2.xUnit_Price__c = 100;
        laborSalesLine2.Unit_Cost__c = 50;
        laborSalesLine2.xUnit_Cost__c = 50;
        laborSalesLine2.Tax_Group__c = 'TX';
        laborSalesLine2.Tax_Pct__c = 8;
        laborSalesLine2.Regular_Rate__c = 100;
        laborSalesLine2.Overtime_Rate__c = 150;
        laborSalesLine2.Premium_Rate__c = 200;
        salesLines.add(laborSalesLine2);

        //waste disposal
        ResourceWrapper wasteDisposalResourceWrapper = mapResourceWrappersByName.get(ResourceService.WASTE_DISPOSAL_CATEGORY);
        Facility__c facility = mapFacilitiesByName.get('Elizabeth');
        ResourceUOMAssociation__c resourceUOMAssociation = wasteDisposalResourceWrapper.mapResourceUOMAssociationsByName.get('P/55');

        Sales_Line__c wasteDisposalSalesLine = new Sales_Line__c();
        wasteDisposalSalesLine.Sales_Order__c = salesOrder1.Id;
        wasteDisposalSalesLine.Sales_Order_Job_Task__c = jobTask1.Id;
        wasteDisposalSalesLine.Line_No__c = 3;
        wasteDisposalSalesLine.Category__c = ResourceService.WASTE_DISPOSAL_CATEGORY;
        //wasteDisposalSalesLine.Resource__c = wasteDisposalResourceWrapper.Resource.Id;
        wasteDisposalSalesLine.Resource__c = resourceUOMAssociation.Resource__c;
        //wasteDisposalSalesLine.Unit_of_Measure__c = wasteDisposalResourceWrapper.Resource.Unit_of_Measure__c;
        wasteDisposalSalesLine.Unit_of_Measure__c = resourceUOMAssociation.Unit_of_Measure__c;
        
        wasteDisposalSalesLine.Cost_Method__c = 'Unit_Weight_Vol';
        wasteDisposalSalesLine.Resource_UOM__c = resourceUOMAssociation.Id;
        wasteDisposalSalesLine.Unit_Weight_Vol__c = resourceUOMAssociation.Unit_of_Measure__c;
        wasteDisposalSalesLine.Container_Size__c = resourceUOMAssociation.Container_Size__c;
        wasteDisposalSalesLine.Facility__c = facility.Id;
        wasteDisposalSalesLine.Quantity__c = 1;
        wasteDisposalSalesLine.Min_Sell_Qty__c = 1;
        wasteDisposalSalesLine.Unit_Price__c = 100;
        wasteDisposalSalesLine.xUnit_Price__c = 100;
        wasteDisposalSalesLine.Unit_Cost__c = 50;
        wasteDisposalSalesLine.xUnit_Cost__c = 50;
        wasteDisposalSalesLine.Tax_Group__c = 'TX';
        wasteDisposalSalesLine.Tax_Pct__c = 8;
        salesLines.add(wasteDisposalSalesLine);
        salesLineByCategory.put(ResourceService.WASTE_DISPOSAL_CATEGORY, wasteDisposalSalesLine);

        //Equipment wrapper
        Resource_Type__c equipmentResourceType = mapResourceTypeWrappersByName.get(ResourceService.EQUIPMENT_CATEGORY).ResourceType;

        Sales_Line__c equipmentLine = new Sales_Line__c();
        equipmentLine.Sales_Order__c = salesOrder1.Id;
        equipmentLine.Sales_Order_Job_Task__c = jobTask1.Id;
        equipmentLine.Line_No__c = 4;
        equipmentLine.Category__c = ResourceService.EQUIPMENT_CATEGORY;
        equipmentLine.Resource_Type__c = equipmentResourceType.Id;
        equipmentLine.Unit_of_Measure__c = equipmentResourceType.Unit_of_Measure__c;
        equipmentLine.Quantity__c = 1;
        equipmentLine.Number_of_Day__c = 1;
        equipmentLine.UOM_Qty__c = 8;
        equipmentLine.Unit_Price__c = 100;
        equipmentLine.xUnit_Price__c = 100;
        equipmentLine.Unit_Cost__c = 50;
        equipmentLine.xUnit_Cost__c = 50;
        equipmentLine.Tax_Group__c = 'TX';
        equipmentLine.Tax_Pct__c = 8;
        salesLines.add(equipmentLine);
        salesLineByCategory.put(ResourceService.EQUIPMENT_CATEGORY, equipmentLine);
        mapSalesLinesBySalesOrderIdByCategory.put(salesOrder1.Id, salesLineByCategory);
        insert salesLines;

        //bundle the labor line to the lump sum line
        laborSalesLine.Bundle_Line__c = lumpSumSalesLine.Id;
        laborSalesLine.Bill_as_Lump_Sum__c = true;
        laborSalesLine.Bundle_Line__r = new Sales_Line__c(Id = lumpSumSalesLine.Id, Line_No__c = lumpSumSalesLine.Line_No__c);
        update laborSalesLine;

        //sales line details
        List<Sales_Line_Detail__c> salesLineDetails = new List<Sales_Line_Detail__c>();

        Sales_Line_Detail__c salesLineDetail = new Sales_Line_Detail__c();
        salesLineDetail.Sales_Line__c = laborSalesLine.Id;
        salesLineDetail.Scheduled_Date__c = salesOrder1.Estimated_Job_Start_Date__c;
        salesLineDetail.Start_Time__c = salesOrder1.Estimated_Job_Start_Time__c;
        salesLineDetail.End_Time__c = salesOrder1.Estimated_Job_End_Time__c;
        salesLineDetail.Quantity__c = laborSalesLine.Quantity__c;
        salesLineDetail.Unit_of_Measure__c = laborSalesLine.Unit_of_Measure__c;
        salesLineDetail.UOM_Qty__c = laborSalesLine.UOM_Qty__c;
        salesLineDetail.Regular_Rate__c = laborSalesLine.Regular_Rate__c;
        salesLineDetail.Overtime_Rate__c = laborSalesLine.Overtime_Rate__c;
        salesLineDetail.Premium_Rate__c = laborSalesLine.Premium_Rate__c;
        salesLineDetail.Unit_Cost__c = laborSalesLine.Unit_Cost__c;
        salesLineDetail.Line_Amount__c = CompanyMgmt.halfUpTo2D(salesLineDetail.Quantity__c * salesLineDetail.Regular_Rate__c * salesLineDetail.UOM_Qty__c);
        salesLineDetail.Line_Cost__c = CompanyMgmt.halfUpTo2D(salesLineDetail.Quantity__c * salesLineDetail.Unit_Cost__c);
        salesLineDetails.add(salesLineDetail);

        Sales_Line_Detail__c salesLineDetail2 = new Sales_Line_Detail__c();
        salesLineDetail2.Sales_Line__c = laborSalesLine2.Id;
        salesLineDetail2.Scheduled_Date__c = salesOrder1.Estimated_Job_Start_Date__c;
        salesLineDetail2.Start_Time__c = salesOrder1.Estimated_Job_Start_Time__c;
        salesLineDetail2.End_Time__c = salesOrder1.Estimated_Job_End_Time__c;
        salesLineDetail2.Quantity__c = laborSalesLine2.Quantity__c;
        salesLineDetail2.Unit_of_Measure__c = laborSalesLine2.Unit_of_Measure__c;
        salesLineDetail2.UOM_Qty__c = laborSalesLine2.UOM_Qty__c;
        salesLineDetail2.Regular_Rate__c = laborSalesLine2.Regular_Rate__c;
        salesLineDetail2.Overtime_Rate__c = laborSalesLine2.Overtime_Rate__c;
        salesLineDetail2.Premium_Rate__c = laborSalesLine2.Premium_Rate__c;
        salesLineDetail2.Unit_Cost__c = laborSalesLine2.Unit_Cost__c;
        salesLineDetail2.Line_Amount__c = CompanyMgmt.halfUpTo2D(salesLineDetail2.Quantity__c * salesLineDetail2.Regular_Rate__c * salesLineDetail2.UOM_Qty__c);
        salesLineDetail2.Line_Cost__c = CompanyMgmt.halfUpTo2D(salesLineDetail2.Quantity__c * salesLineDetail2.Unit_Cost__c);
        salesLineDetail2.Day_Rate_Code__c = EnumUtil.TimeRateCode.REG.name();
        salesLineDetails.add(salesLineDetail2);

        insert salesLineDetails;

        //add to the map
        JSONUtils.attachListToParent(laborSalesLine, salesLineDetails, 'Sales_Line_Details__r');
        mapSalesOrdersByName.put(salesOrder1.Name, salesOrder1);
    }

    private static void initSalesQuote() {
        List<Sales_Order__c> salesOrders = new List<Sales_Order__c>();

        Billing_Rule__c billingRule = mapBillingRuleWrappersByName.get('Company Default').BillingRule;
        AccountWrapper customerWrapper = mapAccountWrappersByName.get('Customer');
        Service_Center__c serviceCenter = mapServiceCenterWrappersByName.get('02').ServiceCenter;
        Sales_Order_Type__c salesOrderType = mapSalesOrderTypesByName.get('Field Services');
        Subsidiary_Company__c subsidiaryCompany = mapSubsidiaryCompaniesByName.get('1-ACV ENVIRO');
        Contract contract = mapContractWrappersByName.get('Contract').Contract;
        Salesperson__c projectCoordinator = mapSalespeopleByName.get('Salesperson');
        Salesperson__c accountExecutive = mapSalespeopleByName.get('Account Executive');
        Payment_Term__c paymentTerm = mapPaymentTermsByName.get('NET 30');
        TaxAreaWrapper taxAreaWrapper = mapTaxAreaWrappersByName.get('NJ');
        Rate_Sheet__c rateSheet = mapRateSheetWrappersByName.get(COMPANY_PRICE_LIST).RateSheet;

            
        Sales_Order__c salesOrder1 = new Sales_Order__c();
        salesOrder1.Name = 'SQ1';
        salesOrder1.Document_Type__c = 'Sales Quote';
        salesOrder1.Document_Status__c = 'Open';
        salesOrder1.Subsidiary_Company__c = subsidiaryCompany.Id;
        salesOrder1.Service_Center__c = serviceCenter.Id;
        salesOrder1.Sales_Order_Type__c = salesOrderType.Id;
        salesOrder1.Rate_Sheet__c = rateSheet.Id;
        salesOrder1.Quote_Date__c = system.today();
        salesOrder1.Bill_to_Customer_No__c = customerWrapper.Account.Id;
        salesOrder1.Bill_to_Customer_No__r = customerWrapper.Account;
        salesOrder1.Bill_to_Contact__c = customerWrapper.mapContactByName.get('John Smith').Id;
        salesOrder1.Quote_Contact__c = customerWrapper.mapContactByName.get('John Smith').Id;
        salesOrder1.Project_Coordinator__c = projectCoordinator.Id;
        salesOrder1.Account_Executives__c = accountExecutive.Id;
        salesOrder1.Payment_Term__c = paymentTerm.Id;
        salesOrder1.Surcharge_Type__c = 'EEC Fee';
        salesOrder1.Surcharge_Pct__c = 11;
        salesOrder1.Contract__c = contract.Id;
        salesOrder1.Estimated_Job_Start_Date__c = system.today();
        salesOrder1.Duration__c = 2;
        salesOrder1.Estimated_Job_Start_Time__c = Time.newInstance(8, 0, 0, 0);
        salesOrder1.Estimated_Job_End_Time__c = Time.newInstance(16, 0, 0, 0);
        salesOrder1.Job_Description__c = 'Test';
        salesOrder1.Billing_Rule__c = billingRule.Id;
        salesOrder1.Tax_Area__c = taxAreaWrapper.TaxArea.Id;
        salesOrder1.Tax_Liable__c = true;
        salesOrder1.Site_Scope__c = 'scope text';
        salesOrder1.Manifest_And_Profile__c = true;
        salesOrder1.Charge_Rinse_Out_Fee__c = true;
        salesOrder1.Order_Description__c = 'order description';
        salesOrders.add(salesOrder1);
        insert salesOrders;
        
        Signature__c signature = new Signature__c ();
        signature.Signer_Role__c = 'Customer A';
        signature.Voided__c =False;
		signature.Signed__c =True;
        signature.Print_Name__c = 'Test User';
        signature.Customer_PO_No__c= 'Test PONumber';
        signature.Signature_Date__c = Date.today(); 
        signature.Sales_Order__c=salesOrder1.Id;
        insert signature;
        
        //Attachments attachment = new Attachment();
        Attachment attachment2 = new Attachment();
        attachment2.ParentId = signature.Id;
        attachment2.Name = 'signature';
        attachment2.Body = Blob.valueOf('123');
        attachment2.ContentType = 'image/png';
        attachment2.IsPrivate = false;
        //attachments.add(attachment2);
        insert attachment2; 
        
	    
        
        //sales order job task
        List<Sales_Order_Job_Task__c> jobTasks = new List<Sales_Order_Job_Task__c>();
        Sales_Order_Job_Task__c jobTask1 = new Sales_Order_Job_Task__c();
        jobTask1.Sales_Order__c = salesOrder1.Id;
        jobTask1.Billing_Type__c = 'Fixed Price';
        jobTask1.Fixed_Price_Surcharge_Option__c = 'Fixed Price Does Not Include Surcharge';
        jobTask1.Line_No__c = 1;
        jobTask1.Task_No__c = 1;
        jobTask1.Name = 'Field Service';
        jobTasks.add(jobTask1);
        insert jobTasks;

        //sales order lines
        List<Sales_Line__c> salesLines = new List<Sales_Line__c>();

        Resource_Type__c lumpSumResourceType = mapResourceTypeWrappersByName.get('Bundled').ResourceType;

        Sales_Line__c lumpSumSalesLine = new Sales_Line__c();
        lumpSumSalesLine.Sales_Order__c = salesOrder1.Id;
        lumpSumSalesLine.Sales_Order_Job_Task__c = jobTask1.Id;
        lumpSumSalesLine.Line_No__c = 1;
        lumpSumSalesLine.Category__c = 'Bundled';
        lumpSumSalesLine.Resource_Type__c = lumpSumResourceType.Id;
        lumpSumSalesLine.Unit_of_Measure__c = lumpSumResourceType.Unit_of_Measure__c;
        lumpSumSalesLine.Quantity__c = 1;
        lumpSumSalesLine.Unit_Price__c = 100;
        lumpSumSalesLine.xUnit_Price__c = 100;
        lumpSumSalesLine.Unit_Cost__c = 50;
        lumpSumSalesLine.xUnit_Cost__c = 50;
        lumpSumSalesLine.Tax_Group__c = 'TX';
        lumpSumSalesLine.Tax_Pct__c = 8;
        salesLines.add(lumpSumSalesLine);

        //labor
        Resource_Type__c laborResourceType = mapResourceTypeWrappersByName.get('Labor').ResourceType;

        Sales_Line__c laborSalesLine = new Sales_Line__c();
        laborSalesLine.Sales_Order__c = salesOrder1.Id;
        laborSalesLine.Sales_Order_Job_Task__c = jobTask1.Id;
        laborSalesLine.Line_No__c = 2;
        laborSalesLine.Category__c = 'Labor';
        laborSalesLine.Resource_Type__c = laborResourceType.Id;
        laborSalesLine.Unit_of_Measure__c = laborResourceType.Unit_of_Measure__c;
        laborSalesLine.Quantity__c = 1;
        laborSalesLine.Number_of_Day__c = 1;
        laborSalesLine.UOM_Qty__c = 8;
        laborSalesLine.Unit_Price__c = 100;
        laborSalesLine.xUnit_Price__c = 100;
        laborSalesLine.Unit_Cost__c = 50;
        laborSalesLine.xUnit_Cost__c = 50;
        laborSalesLine.Tax_Group__c = 'TX';
        laborSalesLine.Tax_Pct__c = 8;
        laborSalesLine.Regular_Rate__c = 100;
        laborSalesLine.Overtime_Rate__c = 150;
        laborSalesLine.Premium_Rate__c = 200;
        salesLines.add(laborSalesLine);

        //waste disposal
        ResourceWrapper wasteDisposalResourceWrapper = mapResourceWrappersByName.get('Waste Disposal');
        Facility__c facility = mapFacilitiesByName.get('Elizabeth');
        ResourceUOMAssociation__c resourceUOMAssociation = wasteDisposalResourceWrapper.mapResourceUOMAssociationsByName.get('P/55');

        Sales_Line__c wasteDisposalSalesLine = new Sales_Line__c();
        wasteDisposalSalesLine.Sales_Order__c = salesOrder1.Id;
        wasteDisposalSalesLine.Sales_Order_Job_Task__c = jobTask1.Id;
        wasteDisposalSalesLine.Line_No__c = 3;
        wasteDisposalSalesLine.Category__c = 'Waste Disposal';
        wasteDisposalSalesLine.Resource__c = wasteDisposalResourceWrapper.Resource.Id;
        wasteDisposalSalesLine.Unit_of_Measure__c = wasteDisposalResourceWrapper.Resource.Unit_of_Measure__c;
        wasteDisposalSalesLine.Cost_Method__c = 'Unit_Weight_Vol';
        wasteDisposalSalesLine.Resource_UOM__c = resourceUOMAssociation.Id;
        wasteDisposalSalesLine.Unit_Weight_Vol__c = resourceUOMAssociation.Unit_of_Measure__c;
        wasteDisposalSalesLine.Container_Size__c = resourceUOMAssociation.Container_Size__c;
        wasteDisposalSalesLine.Facility__c = facility.Id;
        wasteDisposalSalesLine.Quantity__c = 1;
        wasteDisposalSalesLine.Min_Sell_Qty__c = 1;
        wasteDisposalSalesLine.Unit_Price__c = 100;
        wasteDisposalSalesLine.xUnit_Price__c = 100;
        wasteDisposalSalesLine.Unit_Cost__c = 50;
        wasteDisposalSalesLine.xUnit_Cost__c = 50;
        wasteDisposalSalesLine.Tax_Group__c = 'TX';
        wasteDisposalSalesLine.Tax_Pct__c = 8;
        salesLines.add(wasteDisposalSalesLine);

        //Equipment wrapper
        Resource_Type__c equipmentResourceType = mapResourceTypeWrappersByName.get('Equipment').ResourceType;

        Sales_Line__c equipmentLine = new Sales_Line__c();
        equipmentLine.Sales_Order__c = salesOrder1.Id;
        equipmentLine.Sales_Order_Job_Task__c = jobTask1.Id;
        equipmentLine.Line_No__c = 4;
        equipmentLine.Category__c = 'Equipment';
        equipmentLine.Resource_Type__c = equipmentResourceType.Id;
        equipmentLine.Unit_of_Measure__c = equipmentResourceType.Unit_of_Measure__c;
        equipmentLine.Quantity__c = 1;
        equipmentLine.Number_of_Day__c = 1;
        equipmentLine.UOM_Qty__c = 8;
        equipmentLine.Unit_Price__c = 100;
        equipmentLine.xUnit_Price__c = 100;
        equipmentLine.Unit_Cost__c = 50;
        equipmentLine.xUnit_Cost__c = 50;
        equipmentLine.Tax_Group__c = 'TX';
        equipmentLine.Tax_Pct__c = 8;
        salesLines.add(equipmentLine);
        insert salesLines;

        //bundle the labor line to the lump sum line
        laborSalesLine.Bundle_Line__c = lumpSumSalesLine.Id;
        update laborSalesLine;

        //sales line details
        List<Sales_Line_Detail__c> salesLineDetails = new List<Sales_Line_Detail__c>();

        Sales_Line_Detail__c salesLineDetail = new Sales_Line_Detail__c();
        salesLineDetail.Sales_Line__c = laborSalesLine.Id;
        salesLineDetail.Scheduled_Date__c = salesOrder1.Estimated_Job_Start_Date__c;
        salesLineDetail.Start_Time__c = salesOrder1.Estimated_Job_Start_Time__c;
        salesLineDetail.End_Time__c = salesOrder1.Estimated_Job_End_Time__c;
        salesLineDetail.Quantity__c = laborSalesLine.Quantity__c;
        salesLineDetail.Unit_of_Measure__c = laborSalesLine.Unit_of_Measure__c;
        salesLineDetail.UOM_Qty__c = laborSalesLine.UOM_Qty__c;
        salesLineDetail.Regular_Rate__c = laborSalesLine.Regular_Rate__c;
        salesLineDetail.Overtime_Rate__c = laborSalesLine.Overtime_Rate__c;
        salesLineDetail.Premium_Rate__c = laborSalesLine.Premium_Rate__c;
        salesLineDetail.Unit_Cost__c = laborSalesLine.Unit_Cost__c;
        salesLineDetail.Line_Amount__c = CompanyMgmt.halfUpTo2D(salesLineDetail.Quantity__c * salesLineDetail.Regular_Rate__c * salesLineDetail.UOM_Qty__c);
        salesLineDetail.Line_Cost__c = CompanyMgmt.halfUpTo2D(salesLineDetail.Quantity__c * salesLineDetail.Unit_Cost__c);
        salesLineDetails.add(salesLineDetail);

        insert salesLineDetails;

        //add to the map
        JSONUtils.attachListToParent(laborSalesLine, salesLineDetails, 'Sales_Line_Details__r');
        mapSalesOrdersByName.put(salesOrder1.Name, salesOrder1);
    }

    private static void initCompanySetting(){
        Resource__c rinseOutFeeResource = mapResourceWrappersByName.get('Rinse Out Fee').Resource;
        Resource__c fixedPriceJobResource = mapResourceWrappersByName.get('Fixed Price Job').Resource;
        Resource__c retainageResource = mapResourceWrappersByName.get('Retainage Resource').Resource;
        GL_Account__c retainageGLAccount = mapGLAccountsByName.get('12061');

        Company_Setting__mdt acvSetting = new Company_Setting__mdt();
        acvSetting.Label = 'AVC';
        acvSetting.DeveloperName = 'ACV';
        acvSetting.Name__c = 'ACV Enviro';
        acvSetting.Retainage_Receivable_GL_Account_Id__c = retainageGLAccount.Id;
        acvSetting.Default_Retainage_Resource_Id__c = retainageResource.Id;
        acvSetting.Fixed_Price_Job_Resource__c = fixedPriceJobResource.Id;
        acvSetting.Rinse_Out_Fee_Resource_Id__c = rinseOutFeeResource.Id;
        //update acvSetting;
    }

    private static void initTMs() {
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        List<TM__c> tms = new List<TM__c>();

        Sales_Order__c salesOrder = mapSalesOrdersByName.get(TEST_SO_NAME_01);

        TM__c tm = new TM__c();
        tm.Sales_Order__c = salesOrder.Id;
        tm.Bill_to_Customer__c = salesOrder.Bill_to_Customer_No__c;
        tm.Bill_to_Customer__r = salesOrder.Bill_to_Customer_No__r;
        tm.Scheduled_Date__c = System.today();
        tm.Status__c  = 'Open';
        tm.Tax_Area__c = salesOrder.Tax_Area__c;
        tm.From_Sales_Quote__c = salesOrder.From_Sales_Quote__c;
        tm.Project_Coordinator__c = salesOrder.Project_Coordinator__c;
        tm.Account_Executive__c = salesOrder.Account_Executives__c;
        tm.Service_Center__c = salesOrder.Service_Center__c;
        tm.Subsidiary_Company__c = salesOrder.Subsidiary_Company__c;
        tm.Contract__c = salesOrder.Contract__c;
        tm.Contact__c = salesOrder.Bill_to_Contact__c;
        tm.Site_Contact__c = salesOrder.Site_Contact__c;
        tm.Tax_Liable__c = salesOrder.Tax_Liable__c;
        tm.Site_Scope__c = salesOrder.Site_Scope__c;
        tms.add(tm);

        for(Integer i = 1; i < 7; i++){
            TM__c tm2 = new TM__c();
            tm2 = tm.clone(false);
            tm2.Status__c = TMsService.CONFIRMED_STATUS;
            tm2.Scheduled_Date__c = System.today().addDays(i);
            tms.add(tm2);
        }

        insert tms;

        List<TM_Job_Task__c> jobTasks = new List<TM_Job_Task__c>();
        Sales_Order_Job_Task__c salesOrderJobTask = mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        TM_Job_Task__c jobTask = new TM_Job_Task__c();
        jobTask.TM__c = tm.Id;
        jobTask.Name = salesOrderJobTask.Name;
        jobTask.Line_No__c = salesOrderJobTask.Line_No__c;
        jobTask.Billing_Type__c = salesOrderJobTask.Billing_Type__c;
        jobTask.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
        jobTasks.add(jobTask);

        for(TM__c tm2 : tms){
            if(tm2.Id != tm.Id){
                TM_Job_Task__c tmJobTask = new TM_Job_Task__c();
                tmJobTask.TM__c = tm2.Id;
                tmJobTask.Name = salesOrderJobTask.Name;
                tmJobTask.Line_No__c = salesOrderJobTask.Line_No__c;
                tmJobTask.Billing_Type__c = salesOrderJobTask.Billing_Type__c;
                tmJobTask.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
                jobTasks.add(tmJobTask);
            }
        }

        insert jobTasks;

        List<TM_Line__c> tmLines = new List<TM_Line__c>();
        Map<String, TM_Line__c> tmLineByCategory = new Map<String, TM_Line__c>();
        Sales_Line__c salesLine = mapSalesLinesBySalesOrderIdByCategory.get(salesOrder.Id).get(ResourceService.LABOR_CATEGORY);
        TM_Line__c tmLine = new TM_Line__c();
        tmLine.TM__c = tm.Id;
        tmLine.TM_Job_Task__c = jobTask.Id;
        tmLine.Line_No__c = 1;
        tmLine.Category__c = salesLine.Category__c;
        tmLine.Service_Center__c = tm.Service_Center__c;
        tmLine.Resource_Type__c = salesLine.Resource_Type__c;
        tmLine.Resource__c = mapResourceByName.get(TEST_EMPLOYEE_NAME_DAVID).Id;
        tmLine.Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
        tmLine.Quantity__c = 1;
        tmLine.Invoiced__c = true;
        tmLine.Description__c = salesLine.Description__c;
        tmLine.Sales_Line__c = salesLine.Id;
        tmLine.Job_Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
        tmLine.Job_End_Time__c = salesOrder.Estimated_Job_End_Time__c;
        tmLine.Site_Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
        tmLine.Site_End_Time__c = salesOrder.Estimated_Job_End_Time__c;
        tmLines.add(tmLine);
        tmLineByCategory.put(ResourceService.LABOR_CATEGORY, tmLine);

        for(TM_Job_Task__c tmJobTask : jobTasks) {
            if (tmJobTask.Id != jobTask.Id) {
                TM_Line__c tmLine2 = new TM_Line__c();
                tmLine2 = tmLine.clone(false);
                tmLine2.TM__c = tmJobTask.TM__c;
                tmLine2.TM_Job_Task__c = tmJobTask.Id;
                tmLine2.Job_Start_Time__c = Time.newInstance(8,0,0,0);
                tmLine2.Site_Start_Time__c = Time.newInstance(9,0,0,0);
                tmLine2.Site_End_Time__c = Time.newInstance(15,0,0,0);
                tmLine2.Job_End_Time__c = Time.newInstance(16,0,0,0);
                tmLine2.Lunch_Start_Time__c = Time.newInstance(12,0,0,0);
                tmLine2.Lunch_End_Time__c = Time.newInstance(12,30,0,0);
                tmLine2.Quantity__c = 7.5;
                tmLines.add(tmLine2);
            }
        }

        salesLine = mapSalesLinesBySalesOrderIdByCategory.get(salesOrder.Id).get(ResourceService.EQUIPMENT_CATEGORY);
        tmLine = new TM_Line__c();
        tmLine.TM__c = tm.Id;
        tmLine.TM_Job_Task__c = jobTask.Id;
        tmLine.Line_No__c = 2;
        tmLine.Category__c = salesLine.Category__c;
        tmLine.Resource_Type__c = salesLine.Resource_Type__c;
        tmLine.Resource__c = mapResourceByName.get(TEST_EQUIPMENT_NAME).Id;
        tmLine.Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
        tmLine.Quantity__c = 1;
        tmLine.Description__c = salesLine.Description__c;
        tmLine.Sales_Line__c = salesLine.Id;
        tmLine.Job_Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
        tmLine.Job_End_Time__c = salesOrder.Estimated_Job_End_Time__c;
        tmLines.add(tmLine);
        tmLineByCategory.put(ResourceService.EQUIPMENT_CATEGORY, tmLine);

        salesLine = mapSalesLinesBySalesOrderIdByCategory.get(salesOrder.Id).get(ResourceService.LUMP_SUM_CATEGORY);
        tmLine = new TM_Line__c();
        tmLine.TM__c = tm.Id;
        tmLine.TM_Job_Task__c = jobTask.Id;
        tmLine.Line_No__c = 3;
        tmLine.Category__c = salesLine.Category__c;
        tmLine.Resource_Type__c = salesLine.Resource_Type__c;
        tmLine.Resource__c = salesLine.Resource__c;
        tmLine.Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
        tmLine.Quantity__c = 1;
        tmLine.Description__c = salesLine.Description__c;
        tmLine.Sales_Line__c = salesLine.Id;
        tmLine.Job_Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
        tmLine.Job_End_Time__c = salesOrder.Estimated_Job_End_Time__c;
        tmLines.add(tmLine);
        tmLineByCategory.put(ResourceService.LUMP_SUM_CATEGORY, tmLine);

        salesLine = mapSalesLinesBySalesOrderIdByCategory.get(salesOrder.Id).get(ResourceService.WASTE_DISPOSAL_CATEGORY);
        tmLine = new TM_Line__c();
        tmLine.TM__c = tm.Id;
        tmLine.TM_Job_Task__c = jobTask.Id;
        tmLine.Line_No__c = 4;
        tmLine.Category__c = salesLine.Category__c;
        tmLine.Resource_Type__c = salesLine.Resource_Type__c;
        tmLine.Resource__c = salesLine.Resource__c;
        tmLine.Cost_Method__c = salesLine.Cost_Method__c;
        tmLine.Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
        tmLine.Container_Size__c = salesLine.Container_Size__c;
        tmLine.Unit_Weight_Vol__c = salesLine.Unit_Weight_Vol__c;
        tmLine.Quantity__c = 1;
        tmLine.Description__c = salesLine.Description__c;
        tmLine.Sales_Line__c = salesLine.Id;
        tmLine.Job_Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
        tmLine.Job_End_Time__c = salesOrder.Estimated_Job_End_Time__c;
        tmLines.add(tmLine);
        tmLineByCategory.put(ResourceService.WASTE_DISPOSAL_CATEGORY, tmLine);

        salesLine = mapSalesLinesBySalesOrderIdByCategory.get(salesOrder.Id).get(ResourceService.LABOR_CATEGORY + RESOURCE_TYPE_ORDER);
        tmLine = new TM_Line__c();
        tmLine.TM__c = tm.Id;
        tmLine.TM_Job_Task__c = jobTask.Id;
        tmLine.Line_No__c = 5;
        tmLine.Category__c = salesLine.Category__c;
        tmLine.Resource_Type__c = salesLine.Resource_Type__c;
        tmLine.Resource__c = mapResourceByName.get(RESOURCE_TYPE_ORDER).Id;
        tmLine.Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
        tmLine.Quantity__c = 1;
        tmLine.Description__c = salesLine.Description__c;
        tmLine.Sales_Line__c = salesLine.Id;
        tmLine.Job_Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
        tmLine.Job_End_Time__c = salesOrder.Estimated_Job_End_Time__c;
        tmLines.add(tmLine);
        tmLineByCategory.put(ResourceService.LABOR_CATEGORY+RESOURCE_TYPE_ORDER, tmLine);

        Resource_Type__c resourceType = mapResourceTypesByName.get(RESOURCE_TYPE_COMPANY_RATESHEET);
        Resource__c resource = mapResourceByName.get(RESOURCE_TYPE_COMPANY_RATESHEET);
        tmLine = new TM_Line__c();
        tmLine.TM__c = tm.Id;
        tmLine.TM_Job_Task__c = jobTask.Id;
        tmLine.Line_No__c = 6;
        tmLine.Category__c = ResourceService.LABOR_CATEGORY;
        tmLine.Resource_Type__c = resourceType.Id;
        tmLine.Resource__c = resource.Id;
        tmLine.Unit_of_Measure__c = resourceType.Unit_of_Measure__c;
        tmLine.Quantity__c = 1;
        tmLine.Description__c = resourceType.Name;
        tmLine.Job_Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
        tmLine.Job_End_Time__c = salesOrder.Estimated_Job_End_Time__c;
        tmLines.add(tmLine);
        tmLineByCategory.put(ResourceService.LABOR_CATEGORY+RESOURCE_TYPE_COMPANY_RATESHEET, tmLine);

        resourceType = mapResourceTypesByName.get(RESOURCE_TYPE_SC_RATESHEET);
        resource = mapResourceByName.get(RESOURCE_TYPE_SC_RATESHEET);
        tmLine = new TM_Line__c();
        tmLine.TM__c = tm.Id;
        tmLine.TM_Job_Task__c = jobTask.Id;
        //ticket 19130 <<
        //tmLine.Line_No__c = 6;
        tmLine.Line_No__c = 7;
        //ticket 19130 >>
        tmLine.Category__c = ResourceService.LABOR_CATEGORY;
        tmLine.Resource_Type__c = resourceType.Id;
        tmLine.Resource__c = resource.Id;
        tmLine.Unit_of_Measure__c = resourceType.Unit_of_Measure__c;
        tmLine.Quantity__c = 1;
        tmLine.Description__c = resourceType.Name;
        tmLine.Job_Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
        tmLine.Job_End_Time__c = salesOrder.Estimated_Job_End_Time__c;
        tmLines.add(tmLine);
        tmLineByCategory.put(ResourceService.LABOR_CATEGORY+RESOURCE_TYPE_SC_RATESHEET, tmLine);

        resourceType = mapResourceTypesByName.get(RESOURCE_TYPE_COMPANY_DEFAULT);
        resource = mapResourceByName.get(RESOURCE_TYPE_COMPANY_DEFAULT);
        tmLine = new TM_Line__c();
        tmLine.TM__c = tm.Id;
        tmLine.TM_Job_Task__c = jobTask.Id;
        //ticket 19130 <<
        //tmLine.Line_No__c = 6;
        tmLine.Line_No__c = 8;
        //ticket 19130 >>
        tmLine.Category__c = ResourceService.LABOR_CATEGORY;
        tmLine.Resource_Type__c = resourceType.Id;
        tmLine.Resource__c = resource.Id;
        tmLine.Unit_of_Measure__c = resourceType.Unit_of_Measure__c;
        tmLine.Quantity__c = 1;
        tmLine.Description__c = resourceType.Name;
        tmLine.Job_Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
        tmLine.Job_End_Time__c = salesOrder.Estimated_Job_End_Time__c;
        tmLines.add(tmLine);
        tmLineByCategory.put(ResourceService.LABOR_CATEGORY+RESOURCE_TYPE_COMPANY_DEFAULT, tmLine);

        resourceType = mapResourceTypesByName.get(RESOURCE_TYPE_CONTRACTED);
        resource = mapResourceByName.get(RESOURCE_TYPE_CONTRACTED);
        tmLine = new TM_Line__c();
        tmLine.TM__c = tm.Id;
        tmLine.TM_Job_Task__c = jobTask.Id;
        //ticket 19130 <<
        //tmLine.Line_No__c = 6;
        tmLine.Line_No__c = 9;
        //ticket 19130 >>
        tmLine.Category__c = ResourceService.LABOR_CATEGORY;
        tmLine.Resource_Type__c = resourceType.Id;
        tmLine.Resource__c = resource.Id;
        tmLine.Unit_of_Measure__c = resourceType.Unit_of_Measure__c;
        tmLine.Quantity__c = 1;
        tmLine.Description__c = resourceType.Name;
        tmLine.Job_Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
        tmLine.Job_End_Time__c = salesOrder.Estimated_Job_End_Time__c;
        tmLines.add(tmLine);
        tmLineByCategory.put(ResourceService.LABOR_CATEGORY+RESOURCE_TYPE_CONTRACTED, tmLine);
        System.debug('Info: Data Setup tmLines.size ' + tmLines.size());
        for(TM_Line__c tmLine2 : tmLines){
            System.debug('Info: Data Setup tmLine2 ' + tmLine2);
        }
        insert tmLines;
        mapTMLinesByTMIdByCategory.put(tm.Id, tmLineByCategory);
        mapTMsByName.put(TEST_TM_NAME_01, tm);
    }

    private static void initBillingWorksheetLines() {
        List<Billing_Worksheet_Line__c> billingWorksheetLines = new List<Billing_Worksheet_Line__c>();
        Sales_Order__c salesOrder = mapSalesOrdersByName.get(TEST_SO_NAME_01);
        TM__c tm = mapTMsByName.get(TEST_TM_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);

        Billing_Worksheet_Line__c worksheetLine = new Billing_Worksheet_Line__c();
        TM_Line__c tmLine = mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.LABOR_CATEGORY);
        worksheetLine.Line_No__c = tmLine.Line_No__c;
        worksheetLine.TM__c = tm.Id;
        worksheetLine.TM__r = tm;
        worksheetLine.Category__c = tmLine.Category__c;
        worksheetLine.TM_Line__c = tmLine.Id;
        worksheetLine.TM_Line__r = new TM_Line__c(Id = tmLine.Id, Line_No__c = tmLine.Line_No__c);
        worksheetLine.TM_Job_Task__c = tmLine.TM_Job_Task__c;
        worksheetLine.Service_Center__c = tmLine.Service_Center__c;
        worksheetLine.Resource_Type__c = tmLine.Resource_Type__c;
        worksheetLine.Resource__c = tmLine.Resource__c;
        worksheetLine.Resource__r = tmLine.Resource__r;
        worksheetLine.Resource_Name__c = tmLine.Resource_Name__c;
        worksheetLine.Description__c = tmLine.Description__c;
        worksheetLine.Quantity__c = tmLine.Quantity__c;
        worksheetLine.Unit_of_Measure__c = tmLine.Unit_of_Measure__c;
        worksheetLine.Unit_of_Measure__r = tmLine.Unit_of_Measure__r;
        worksheetLine.Cost_Method__c = tmLine.Cost_Method__c;
        worksheetLine.Unit_Weight_Vol__c = tmLine.Unit_Weight_Vol__c;
        worksheetLine.Container_Size__c = tmLine.Container_Size__c;
        worksheetLine.Facility__c = tmLine.Facility__c;
        worksheetLine.BOL_Manifest__c = tmLine.BOL_Manifest__c;
        worksheetLine.Contract_Line__c = tmLine.Contract_Line__c;
        worksheetLine.Quote_Line__c = tmLine.Quote_Line__c;
        worksheetLine.Tax_Group__c = 'TX';
        worksheetLine.Tax_Pct__c = tmLine.Tax_Pct__c;
        worksheetLine.Fleet_No_Required__c = tmLine.Fleet_No_Required__c;
        worksheetLine.Fleet_No__c = tmLine.Fleet_No__c;
        worksheetLine.System_Calculated_Line__c = tmLine.System_Calculated_Line__c;
        worksheetLine.Flat_Pay_Line__c = tmLine.Flat_Pay_Line__c;
        worksheetLine.Sales_Line__c = tmLine.Sales_Line__c;
        worksheetLine.Sales_Bundle_Line__c = tmLine.Sales_Bundle_Line__c;
        worksheetLine.TM_Parent_Line__c = tmLine.Parent_Line__c;
        worksheetLine.TM_Parent_Line__r = tmLine.Parent_Line__r;
        worksheetLine.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
        worksheetLine.Sales_Order__c = salesOrder.Id;
        worksheetLine.Billing_Start_Time__c = tmLine.Job_Start_Time__c;
        worksheetLine.Billing_End_Time__c = tmLine.Job_End_Time__c;
        worksheetLine.Hour__c = TimeUtils.calculateHours(worksheetLine.Billing_Start_Time__c, worksheetLine.Billing_End_Time__c);
        worksheetLine.Regular_Hours__c = 0;
        worksheetLine.Overtime_Hours__c = 0;
        worksheetLine.Premium_Hours__c = 0;
        worksheetLine.Wizard_Question_Answered__c = false;
        worksheetLine.To_Invoice__c = true;
        billingWorksheetLines.add(worksheetLine);

        worksheetLine = new Billing_Worksheet_Line__c();
        tmLine = mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.EQUIPMENT_CATEGORY);
        worksheetLine.Line_No__c = tmLine.Line_No__c;
        worksheetLine.TM__c = tm.Id;
        worksheetLine.TM__r = tm;
        worksheetLine.Category__c = tmLine.Category__c;
        worksheetLine.TM_Line__c = tmLine.Id;
        worksheetLine.TM_Line__r = new TM_Line__c(Id = tmLine.Id, Line_No__c = tmLine.Line_No__c);
        worksheetLine.TM_Job_Task__c = tmLine.TM_Job_Task__c;
        worksheetLine.Service_Center__c = tmLine.Service_Center__c;
        worksheetLine.Resource_Type__c = tmLine.Resource_Type__c;
        worksheetLine.Resource__c = tmLine.Resource__c;
        worksheetLine.Resource__r = tmLine.Resource__r;
        worksheetLine.Resource_Name__c = tmLine.Resource_Name__c;
        worksheetLine.Description__c = tmLine.Description__c;
        worksheetLine.Quantity__c = tmLine.Quantity__c;
        worksheetLine.Unit_of_Measure__c = tmLine.Unit_of_Measure__c;
        worksheetLine.Unit_of_Measure__r = tmLine.Unit_of_Measure__r;
        worksheetLine.Cost_Method__c = tmLine.Cost_Method__c;
        worksheetLine.Unit_Weight_Vol__c = tmLine.Unit_Weight_Vol__c;
        worksheetLine.Container_Size__c = tmLine.Container_Size__c;
        worksheetLine.Facility__c = tmLine.Facility__c;
        worksheetLine.BOL_Manifest__c = tmLine.BOL_Manifest__c;
        worksheetLine.Contract_Line__c = tmLine.Contract_Line__c;
        worksheetLine.Quote_Line__c = tmLine.Quote_Line__c;
        worksheetLine.Tax_Group__c = 'TX';
        worksheetLine.Tax_Pct__c = tmLine.Tax_Pct__c;
        worksheetLine.Fleet_No_Required__c = tmLine.Fleet_No_Required__c;
        worksheetLine.Fleet_No__c = tmLine.Fleet_No__c;
        worksheetLine.System_Calculated_Line__c = tmLine.System_Calculated_Line__c;
        worksheetLine.Flat_Pay_Line__c = tmLine.Flat_Pay_Line__c;
        worksheetLine.Sales_Line__c = tmLine.Sales_Line__c;
        worksheetLine.Sales_Bundle_Line__c = tmLine.Sales_Bundle_Line__c;
        worksheetLine.TM_Parent_Line__c = tmLine.Parent_Line__c;
        worksheetLine.TM_Parent_Line__r = tmLine.Parent_Line__r;
        worksheetLine.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
        worksheetLine.Sales_Order__c = salesOrder.Id;
        worksheetLine.Billing_Start_Time__c = tmLine.Job_Start_Time__c;
        worksheetLine.Billing_End_Time__c = tmLine.Job_End_Time__c;
        worksheetLine.Regular_Hours__c = 0;
        worksheetLine.Overtime_Hours__c = 0;
        worksheetLine.Premium_Hours__c = 0;
        worksheetLine.Wizard_Question_Answered__c = false;
        worksheetLine.To_Invoice__c = true;
        billingWorksheetLines.add(worksheetLine);

        worksheetLine = new Billing_Worksheet_Line__c();
        tmLine = mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.WASTE_DISPOSAL_CATEGORY);
        worksheetLine.Line_No__c = tmLine.Line_No__c;
        worksheetLine.TM__c = tm.Id;
        worksheetLine.TM__r = tm;
        worksheetLine.Category__c = tmLine.Category__c;
        worksheetLine.TM_Line__c = tmLine.Id;
        worksheetLine.TM_Line__r = new TM_Line__c(Id = tmLine.Id, Line_No__c = tmLine.Line_No__c);
        worksheetLine.TM_Job_Task__c = tmLine.TM_Job_Task__c;
        worksheetLine.Service_Center__c = tmLine.Service_Center__c;
        worksheetLine.Resource_Type__c = tmLine.Resource_Type__c;
        worksheetLine.Resource__c = tmLine.Resource__c;
        worksheetLine.Resource__r = tmLine.Resource__r;
        worksheetLine.Resource_Name__c = tmLine.Resource_Name__c;
        worksheetLine.Description__c = tmLine.Description__c;
        worksheetLine.Quantity__c = tmLine.Quantity__c;
        worksheetLine.Unit_of_Measure__c = tmLine.Unit_of_Measure__c;
        worksheetLine.Unit_of_Measure__r = tmLine.Unit_of_Measure__r;
        worksheetLine.Cost_Method__c = tmLine.Cost_Method__c;
        worksheetLine.Unit_Weight_Vol__c = tmLine.Unit_Weight_Vol__c;
        worksheetLine.Container_Size__c = tmLine.Container_Size__c;
        worksheetLine.Facility__c = tmLine.Facility__c;
        worksheetLine.BOL_Manifest__c = tmLine.BOL_Manifest__c;
        worksheetLine.Contract_Line__c = tmLine.Contract_Line__c;
        worksheetLine.Quote_Line__c = tmLine.Quote_Line__c;
        worksheetLine.Tax_Group__c = 'TX';
        worksheetLine.Tax_Pct__c = tmLine.Tax_Pct__c;
        worksheetLine.Fleet_No_Required__c = tmLine.Fleet_No_Required__c;
        worksheetLine.Fleet_No__c = tmLine.Fleet_No__c;
        worksheetLine.System_Calculated_Line__c = tmLine.System_Calculated_Line__c;
        worksheetLine.Flat_Pay_Line__c = tmLine.Flat_Pay_Line__c;
        worksheetLine.Sales_Line__c = tmLine.Sales_Line__c;
        worksheetLine.Sales_Bundle_Line__c = tmLine.Sales_Bundle_Line__c;
        worksheetLine.TM_Parent_Line__c = tmLine.Parent_Line__c;
        worksheetLine.TM_Parent_Line__r = tmLine.Parent_Line__r;
        worksheetLine.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
        worksheetLine.Sales_Order__c = salesOrder.Id;
        worksheetLine.Regular_Hours__c = 0;
        worksheetLine.Overtime_Hours__c = 0;
        worksheetLine.Premium_Hours__c = 0;
        worksheetLine.Wizard_Question_Answered__c = false;
        worksheetLine.To_Invoice__c = true;
        billingWorksheetLines.add(worksheetLine);

        worksheetLine = new Billing_Worksheet_Line__c();
        tmLine = mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.LUMP_SUM_CATEGORY);
        worksheetLine.Line_No__c = tmLine.Line_No__c;
        worksheetLine.TM__c = tm.Id;
        worksheetLine.TM__r = tm;
        worksheetLine.Category__c = tmLine.Category__c;
        worksheetLine.TM_Line__c = tmLine.Id;
        worksheetLine.TM_Line__r = new TM_Line__c(Id = tmLine.Id, Line_No__c = tmLine.Line_No__c);
        worksheetLine.TM_Job_Task__c = tmLine.TM_Job_Task__c;
        worksheetLine.Service_Center__c = tmLine.Service_Center__c;
        worksheetLine.Resource_Type__c = tmLine.Resource_Type__c;
        worksheetLine.Resource__c = tmLine.Resource__c;
        worksheetLine.Resource__r = tmLine.Resource__r;
        worksheetLine.Resource_Name__c = tmLine.Resource_Name__c;
        worksheetLine.Description__c = tmLine.Description__c;
        worksheetLine.Quantity__c = tmLine.Quantity__c;
        worksheetLine.Unit_of_Measure__c = tmLine.Unit_of_Measure__c;
        worksheetLine.Unit_of_Measure__r = tmLine.Unit_of_Measure__r;
        worksheetLine.Cost_Method__c = tmLine.Cost_Method__c;
        worksheetLine.Unit_Weight_Vol__c = tmLine.Unit_Weight_Vol__c;
        worksheetLine.Container_Size__c = tmLine.Container_Size__c;
        worksheetLine.Facility__c = tmLine.Facility__c;
        worksheetLine.BOL_Manifest__c = tmLine.BOL_Manifest__c;
        worksheetLine.Contract_Line__c = tmLine.Contract_Line__c;
        worksheetLine.Quote_Line__c = tmLine.Quote_Line__c;
        worksheetLine.Tax_Group__c = 'TX';
        worksheetLine.Tax_Pct__c = tmLine.Tax_Pct__c;
        worksheetLine.Fleet_No_Required__c = tmLine.Fleet_No_Required__c;
        worksheetLine.Fleet_No__c = tmLine.Fleet_No__c;
        worksheetLine.System_Calculated_Line__c = tmLine.System_Calculated_Line__c;
        worksheetLine.Flat_Pay_Line__c = tmLine.Flat_Pay_Line__c;
        worksheetLine.Sales_Line__c = tmLine.Sales_Line__c;
        worksheetLine.Sales_Bundle_Line__c = tmLine.Sales_Bundle_Line__c;
        worksheetLine.TM_Parent_Line__c = tmLine.Parent_Line__c;
        worksheetLine.TM_Parent_Line__r = tmLine.Parent_Line__r;
        worksheetLine.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
        worksheetLine.Sales_Order__c = salesOrder.Id;
        worksheetLine.Regular_Hours__c = 0;
        worksheetLine.Overtime_Hours__c = 0;
        worksheetLine.Premium_Hours__c = 0;
        worksheetLine.Wizard_Question_Answered__c = false;
        worksheetLine.To_Invoice__c = true;
        billingWorksheetLines.add(worksheetLine);

        worksheetLine = new Billing_Worksheet_Line__c();
        tmLine = mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.LABOR_CATEGORY + RESOURCE_TYPE_ORDER);
        worksheetLine.Line_No__c = tmLine.Line_No__c;
        worksheetLine.TM__c = tm.Id;
        worksheetLine.TM__r = tm;
        worksheetLine.Category__c = tmLine.Category__c;
        worksheetLine.TM_Line__c = tmLine.Id;
        worksheetLine.TM_Line__r = new TM_Line__c(Id = tmLine.Id, Line_No__c = tmLine.Line_No__c);
        worksheetLine.TM_Job_Task__c = tmLine.TM_Job_Task__c;
        worksheetLine.Service_Center__c = tmLine.Service_Center__c;
        worksheetLine.Resource_Type__c = tmLine.Resource_Type__c;
        worksheetLine.Resource__c = tmLine.Resource__c;
        worksheetLine.Resource__r = tmLine.Resource__r;
        worksheetLine.Resource_Name__c = tmLine.Resource_Name__c;
        worksheetLine.Description__c = tmLine.Description__c;
        worksheetLine.Quantity__c = tmLine.Quantity__c;
        worksheetLine.Unit_of_Measure__c = tmLine.Unit_of_Measure__c;
        worksheetLine.Unit_of_Measure__r = tmLine.Unit_of_Measure__r;
        worksheetLine.Cost_Method__c = tmLine.Cost_Method__c;
        worksheetLine.Unit_Weight_Vol__c = tmLine.Unit_Weight_Vol__c;
        worksheetLine.Container_Size__c = tmLine.Container_Size__c;
        worksheetLine.Facility__c = tmLine.Facility__c;
        worksheetLine.BOL_Manifest__c = tmLine.BOL_Manifest__c;
        worksheetLine.Contract_Line__c = tmLine.Contract_Line__c;
        worksheetLine.Quote_Line__c = tmLine.Quote_Line__c;
        worksheetLine.Tax_Group__c = 'TX';
        worksheetLine.Tax_Pct__c = tmLine.Tax_Pct__c;
        worksheetLine.Fleet_No_Required__c = tmLine.Fleet_No_Required__c;
        worksheetLine.Fleet_No__c = tmLine.Fleet_No__c;
        worksheetLine.System_Calculated_Line__c = tmLine.System_Calculated_Line__c;
        worksheetLine.Flat_Pay_Line__c = tmLine.Flat_Pay_Line__c;
        worksheetLine.Sales_Line__c = tmLine.Sales_Line__c;
        worksheetLine.Sales_Bundle_Line__c = tmLine.Sales_Bundle_Line__c;
        worksheetLine.TM_Parent_Line__c = tmLine.Parent_Line__c;
        worksheetLine.TM_Parent_Line__r = tmLine.Parent_Line__r;
        worksheetLine.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
        worksheetLine.Sales_Order__c = salesOrder.Id;
        worksheetLine.Billing_Start_Time__c = tmLine.Job_Start_Time__c;
        worksheetLine.Billing_End_Time__c = tmLine.Job_End_Time__c;
        worksheetLine.Hour__c = TimeUtils.calculateHours(worksheetLine.Billing_Start_Time__c, worksheetLine.Billing_End_Time__c);
        worksheetLine.Regular_Hours__c = 0;
        worksheetLine.Overtime_Hours__c = 0;
        worksheetLine.Premium_Hours__c = 0;
        worksheetLine.Wizard_Question_Answered__c = false;
        worksheetLine.To_Invoice__c = true;

        worksheetLine = new Billing_Worksheet_Line__c();
        tmLine = mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.LABOR_CATEGORY + RESOURCE_TYPE_CONTRACTED);
        worksheetLine.Line_No__c = tmLine.Line_No__c;
        worksheetLine.TM__c = tm.Id;
        worksheetLine.TM__r = tm;
        worksheetLine.Category__c = tmLine.Category__c;
        worksheetLine.TM_Line__c = tmLine.Id;
        worksheetLine.TM_Line__r = new TM_Line__c(Id = tmLine.Id, Line_No__c = tmLine.Line_No__c);
        worksheetLine.TM_Job_Task__c = tmLine.TM_Job_Task__c;
        worksheetLine.Service_Center__c = tmLine.Service_Center__c;
        worksheetLine.Resource_Type__c = tmLine.Resource_Type__c;
        worksheetLine.Resource__c = tmLine.Resource__c;
        worksheetLine.Resource__r = tmLine.Resource__r;
        worksheetLine.Resource_Name__c = tmLine.Resource_Name__c;
        worksheetLine.Description__c = tmLine.Description__c;
        worksheetLine.Quantity__c = tmLine.Quantity__c;
        worksheetLine.Unit_of_Measure__c = tmLine.Unit_of_Measure__c;
        worksheetLine.Unit_of_Measure__r = tmLine.Unit_of_Measure__r;
        worksheetLine.Cost_Method__c = tmLine.Cost_Method__c;
        worksheetLine.Unit_Weight_Vol__c = tmLine.Unit_Weight_Vol__c;
        worksheetLine.Container_Size__c = tmLine.Container_Size__c;
        worksheetLine.Facility__c = tmLine.Facility__c;
        worksheetLine.BOL_Manifest__c = tmLine.BOL_Manifest__c;
        worksheetLine.Contract_Line__c = tmLine.Contract_Line__c;
        worksheetLine.Quote_Line__c = tmLine.Quote_Line__c;
        worksheetLine.Tax_Group__c = 'TX';
        worksheetLine.Tax_Pct__c = tmLine.Tax_Pct__c;
        worksheetLine.Fleet_No_Required__c = tmLine.Fleet_No_Required__c;
        worksheetLine.Fleet_No__c = tmLine.Fleet_No__c;
        worksheetLine.System_Calculated_Line__c = tmLine.System_Calculated_Line__c;
        worksheetLine.Flat_Pay_Line__c = tmLine.Flat_Pay_Line__c;
        worksheetLine.Sales_Line__c = tmLine.Sales_Line__c;
        worksheetLine.Sales_Bundle_Line__c = tmLine.Sales_Bundle_Line__c;
        worksheetLine.TM_Parent_Line__c = tmLine.Parent_Line__c;
        worksheetLine.TM_Parent_Line__r = tmLine.Parent_Line__r;
        worksheetLine.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
        worksheetLine.Sales_Order__c = salesOrder.Id;
        worksheetLine.Billing_Start_Time__c = tmLine.Job_Start_Time__c;
        worksheetLine.Billing_End_Time__c = tmLine.Job_End_Time__c;
        worksheetLine.Hour__c = TimeUtils.calculateHours(worksheetLine.Billing_Start_Time__c, worksheetLine.Billing_End_Time__c);
        worksheetLine.Regular_Hours__c = 0;
        worksheetLine.Overtime_Hours__c = 0;
        worksheetLine.Premium_Hours__c = 0;
        worksheetLine.Wizard_Question_Answered__c = false;
        worksheetLine.To_Invoice__c = true;

        worksheetLine = new Billing_Worksheet_Line__c();
        tmLine = mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.LABOR_CATEGORY + RESOURCE_TYPE_COMPANY_DEFAULT);
        worksheetLine.Line_No__c = tmLine.Line_No__c;
        worksheetLine.TM__c = tm.Id;
        worksheetLine.TM__r = tm;
        worksheetLine.Category__c = tmLine.Category__c;
        worksheetLine.TM_Line__c = tmLine.Id;
        worksheetLine.TM_Line__r = new TM_Line__c(Id = tmLine.Id, Line_No__c = tmLine.Line_No__c);
        worksheetLine.TM_Job_Task__c = tmLine.TM_Job_Task__c;
        worksheetLine.Service_Center__c = tmLine.Service_Center__c;
        worksheetLine.Resource_Type__c = tmLine.Resource_Type__c;
        worksheetLine.Resource__c = tmLine.Resource__c;
        worksheetLine.Resource__r = tmLine.Resource__r;
        worksheetLine.Resource_Name__c = tmLine.Resource_Name__c;
        worksheetLine.Description__c = tmLine.Description__c;
        worksheetLine.Quantity__c = tmLine.Quantity__c;
        worksheetLine.Unit_of_Measure__c = tmLine.Unit_of_Measure__c;
        worksheetLine.Unit_of_Measure__r = tmLine.Unit_of_Measure__r;
        worksheetLine.Cost_Method__c = tmLine.Cost_Method__c;
        worksheetLine.Unit_Weight_Vol__c = tmLine.Unit_Weight_Vol__c;
        worksheetLine.Container_Size__c = tmLine.Container_Size__c;
        worksheetLine.Facility__c = tmLine.Facility__c;
        worksheetLine.BOL_Manifest__c = tmLine.BOL_Manifest__c;
        worksheetLine.Contract_Line__c = tmLine.Contract_Line__c;
        worksheetLine.Quote_Line__c = tmLine.Quote_Line__c;
        worksheetLine.Tax_Group__c = 'TX';
        worksheetLine.Tax_Pct__c = tmLine.Tax_Pct__c;
        worksheetLine.Fleet_No_Required__c = tmLine.Fleet_No_Required__c;
        worksheetLine.Fleet_No__c = tmLine.Fleet_No__c;
        worksheetLine.System_Calculated_Line__c = tmLine.System_Calculated_Line__c;
        worksheetLine.Flat_Pay_Line__c = tmLine.Flat_Pay_Line__c;
        worksheetLine.Sales_Line__c = tmLine.Sales_Line__c;
        worksheetLine.Sales_Bundle_Line__c = tmLine.Sales_Bundle_Line__c;
        worksheetLine.TM_Parent_Line__c = tmLine.Parent_Line__c;
        worksheetLine.TM_Parent_Line__r = tmLine.Parent_Line__r;
        worksheetLine.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
        worksheetLine.Sales_Order__c = salesOrder.Id;
        worksheetLine.Billing_Start_Time__c = tmLine.Job_Start_Time__c;
        worksheetLine.Billing_End_Time__c = tmLine.Job_End_Time__c;
        worksheetLine.Hour__c = TimeUtils.calculateHours(worksheetLine.Billing_Start_Time__c, worksheetLine.Billing_End_Time__c);
        worksheetLine.Regular_Hours__c = 0;
        worksheetLine.Overtime_Hours__c = 0;
        worksheetLine.Premium_Hours__c = 0;
        worksheetLine.Wizard_Question_Answered__c = false;
        worksheetLine.To_Invoice__c = true;

        worksheetLine = new Billing_Worksheet_Line__c();
        tmLine = mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.LABOR_CATEGORY + RESOURCE_TYPE_SC_RATESHEET);
        worksheetLine.Line_No__c = tmLine.Line_No__c;
        worksheetLine.TM__c = tm.Id;
        worksheetLine.TM__r = tm;
        worksheetLine.Category__c = tmLine.Category__c;
        worksheetLine.TM_Line__c = tmLine.Id;
        worksheetLine.TM_Line__r = new TM_Line__c(Id = tmLine.Id, Line_No__c = tmLine.Line_No__c);
        worksheetLine.TM_Job_Task__c = tmLine.TM_Job_Task__c;
        worksheetLine.Service_Center__c = tmLine.Service_Center__c;
        worksheetLine.Resource_Type__c = tmLine.Resource_Type__c;
        worksheetLine.Resource__c = tmLine.Resource__c;
        worksheetLine.Resource__r = tmLine.Resource__r;
        worksheetLine.Resource_Name__c = tmLine.Resource_Name__c;
        worksheetLine.Description__c = tmLine.Description__c;
        worksheetLine.Quantity__c = tmLine.Quantity__c;
        worksheetLine.Unit_of_Measure__c = tmLine.Unit_of_Measure__c;
        worksheetLine.Unit_of_Measure__r = tmLine.Unit_of_Measure__r;
        worksheetLine.Cost_Method__c = tmLine.Cost_Method__c;
        worksheetLine.Unit_Weight_Vol__c = tmLine.Unit_Weight_Vol__c;
        worksheetLine.Container_Size__c = tmLine.Container_Size__c;
        worksheetLine.Facility__c = tmLine.Facility__c;
        worksheetLine.BOL_Manifest__c = tmLine.BOL_Manifest__c;
        worksheetLine.Contract_Line__c = tmLine.Contract_Line__c;
        worksheetLine.Quote_Line__c = tmLine.Quote_Line__c;
        worksheetLine.Tax_Group__c = 'TX';
        worksheetLine.Tax_Pct__c = tmLine.Tax_Pct__c;
        worksheetLine.Fleet_No_Required__c = tmLine.Fleet_No_Required__c;
        worksheetLine.Fleet_No__c = tmLine.Fleet_No__c;
        worksheetLine.System_Calculated_Line__c = tmLine.System_Calculated_Line__c;
        worksheetLine.Flat_Pay_Line__c = tmLine.Flat_Pay_Line__c;
        worksheetLine.Sales_Line__c = tmLine.Sales_Line__c;
        worksheetLine.Sales_Bundle_Line__c = tmLine.Sales_Bundle_Line__c;
        worksheetLine.TM_Parent_Line__c = tmLine.Parent_Line__c;
        worksheetLine.TM_Parent_Line__r = tmLine.Parent_Line__r;
        worksheetLine.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
        worksheetLine.Sales_Order__c = salesOrder.Id;
        worksheetLine.Billing_Start_Time__c = tmLine.Job_Start_Time__c;
        worksheetLine.Billing_End_Time__c = tmLine.Job_End_Time__c;
        worksheetLine.Hour__c = TimeUtils.calculateHours(worksheetLine.Billing_Start_Time__c, worksheetLine.Billing_End_Time__c);
        worksheetLine.Regular_Hours__c = 0;
        worksheetLine.Overtime_Hours__c = 0;
        worksheetLine.Premium_Hours__c = 0;
        worksheetLine.Wizard_Question_Answered__c = false;
        worksheetLine.To_Invoice__c = true;

        worksheetLine = new Billing_Worksheet_Line__c();
        tmLine = mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.LABOR_CATEGORY + RESOURCE_TYPE_COMPANY_RATESHEET);
        worksheetLine.Line_No__c = tmLine.Line_No__c;
        worksheetLine.TM__c = tm.Id;
        worksheetLine.TM__r = tm;
        worksheetLine.Category__c = tmLine.Category__c;
        worksheetLine.TM_Line__c = tmLine.Id;
        worksheetLine.TM_Line__r = new TM_Line__c(Id = tmLine.Id, Line_No__c = tmLine.Line_No__c);
        worksheetLine.TM_Job_Task__c = tmLine.TM_Job_Task__c;
        worksheetLine.Service_Center__c = tmLine.Service_Center__c;
        worksheetLine.Resource_Type__c = tmLine.Resource_Type__c;
        worksheetLine.Resource__c = tmLine.Resource__c;
        worksheetLine.Resource__r = tmLine.Resource__r;
        worksheetLine.Resource_Name__c = tmLine.Resource_Name__c;
        worksheetLine.Description__c = tmLine.Description__c;
        worksheetLine.Quantity__c = tmLine.Quantity__c;
        worksheetLine.Unit_of_Measure__c = tmLine.Unit_of_Measure__c;
        worksheetLine.Unit_of_Measure__r = tmLine.Unit_of_Measure__r;
        worksheetLine.Cost_Method__c = tmLine.Cost_Method__c;
        worksheetLine.Unit_Weight_Vol__c = tmLine.Unit_Weight_Vol__c;
        worksheetLine.Container_Size__c = tmLine.Container_Size__c;
        worksheetLine.Facility__c = tmLine.Facility__c;
        worksheetLine.BOL_Manifest__c = tmLine.BOL_Manifest__c;
        worksheetLine.Contract_Line__c = tmLine.Contract_Line__c;
        worksheetLine.Quote_Line__c = tmLine.Quote_Line__c;
        worksheetLine.Tax_Group__c = 'TX';
        worksheetLine.Tax_Pct__c = tmLine.Tax_Pct__c;
        worksheetLine.Fleet_No_Required__c = tmLine.Fleet_No_Required__c;
        worksheetLine.Fleet_No__c = tmLine.Fleet_No__c;
        worksheetLine.System_Calculated_Line__c = tmLine.System_Calculated_Line__c;
        worksheetLine.Flat_Pay_Line__c = tmLine.Flat_Pay_Line__c;
        worksheetLine.Sales_Line__c = tmLine.Sales_Line__c;
        worksheetLine.Sales_Bundle_Line__c = tmLine.Sales_Bundle_Line__c;
        worksheetLine.TM_Parent_Line__c = tmLine.Parent_Line__c;
        worksheetLine.TM_Parent_Line__r = tmLine.Parent_Line__r;
        worksheetLine.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
        worksheetLine.Sales_Order__c = salesOrder.Id;
        worksheetLine.Billing_Start_Time__c = tmLine.Job_Start_Time__c;
        worksheetLine.Billing_End_Time__c = tmLine.Job_End_Time__c;
        worksheetLine.Hour__c = TimeUtils.calculateHours(worksheetLine.Billing_Start_Time__c, worksheetLine.Billing_End_Time__c);
        worksheetLine.Regular_Hours__c = 0;
        worksheetLine.Overtime_Hours__c = 0;
        worksheetLine.Premium_Hours__c = 0;
        worksheetLine.Wizard_Question_Answered__c = false;
        worksheetLine.To_Invoice__c = true;

        billingWorksheetLines.add(worksheetLine);

        insert billingWorksheetLines;

        mapBillingWorksheetLinesByOrderId.put(salesOrder.Id, billingWorksheetLines);
    }

    public static void initSalesInvoices() {
        Sales_Order__c salesOrder = mapSalesOrdersByName.get(TEST_SO_NAME_01);
        Sales_Order_Job_Task__c salesOrderJobTask = mapSalesOrderJobTaskBySalesOrderId.get(salesOrder.Id);
        Account billToCustomer = mapAccountWrappersByName.get(salesOrder.Bill_to_Customer_No__r.Name).Account;
        Payment_Term__c paymentTerm = mapPaymentTermsByName.get('NET 30');

        Sales_Invoice__c salesInvoice = new Sales_Invoice__c();
        salesInvoice.Name = 'INVOICE01';
        salesInvoice.Sales_Order__c = salesOrder.Id;
        salesInvoice.Document_Status__c = 'Open';
        salesInvoice.Bill_to_Customer__c = salesOrder.Bill_to_Customer_No__c;
        salesInvoice.Bill_to_Customer__r = salesOrder.Bill_to_Customer_No__r;
        salesInvoice.Street__c = billToCustomer.BillingStreet;
        salesInvoice.City__c = billToCustomer.BillingCity;
        salesInvoice.State__c = billToCustomer.BillingStateCode;
        salesInvoice.Postal_Code__c = billToCustomer.BillingPostalCode;
        salesInvoice.Country__c = billToCustomer.BillingCountryCode;
        salesInvoice.Salesperson__c = billToCustomer.Salesperson__c;
        salesInvoice.Payment_Term__c = billToCustomer.Payment_Term__c;
        //Ticket#15235 >>
        Decimal dueDateCalc = CompanyMgmt.zeroIfNull(paymentTerm.Due_Date_Calculation__c);
        if (String.isNotEmpty(salesOrder.Payment_Term__c)){
            salesInvoice.Payment_Term__c = salesOrder.Payment_Term__c;
            dueDateCalc = salesOrder.Payment_Term__r.Due_Date_Calculation__c;
        }
        //Ticket#15235 <<
        salesInvoice.Posting_Date__c = Date.today();
        salesInvoice.Account_Executive__c = salesOrder.Account_Executives__c;
        salesInvoice.Customer_PO_No__c = salesOrder.Customer_PO_No__c;
        salesInvoice.Service_Center__c = salesOrder.Service_Center__c;
        salesInvoice.Subsidiary_Company__c = salesOrder.Subsidiary_Company__c;
        salesInvoice.Invoice_Date__c = Date.today();
        salesInvoice.Due_Date__c = CompanyMgmt.calcDate(salesInvoice.Invoice_Date__c, dueDateCalc); //Ticket#15235
        salesInvoice.Contact__c = salesOrder.Bill_to_Contact__c;
        salesInvoice.Site_Contact_2__c = salesOrder.Site_Contact_2__c;
        salesInvoice.Site_Name__c = salesOrder.Site_Name__c;
        salesInvoice.Site_Street__c = salesOrder.Site_Street__c;
        salesInvoice.Site_City__c = salesOrder.Site_City__c;
        salesInvoice.Site_State__c = salesOrder.Site_State__c;
        salesInvoice.Site_Postal_Code__c = salesOrder.Site_Postal_Code__c;
        salesInvoice.Site_Country__c = salesOrder.Site_Country__c;
        salesInvoice.Site_Contact__c = salesOrder.Site_Contact__c;
        salesInvoice.Site_Phone_No__c = salesOrder.Site_Phone_No__c;
        salesInvoice.Site_Email_Address__c = salesOrder.Site_Email_Address__c;
        salesInvoice.Tax_Liable__c = salesOrder.Tax_Liable__c;
        salesInvoice.Tax_Area__c = salesOrder.Tax_Area__c;
        salesInvoice.Contract__c = salesOrder.Contract__c;
        salesInvoice.Surcharge_Type__c = salesOrder.Surcharge_Type__c;
        salesInvoice.Surcharge_Pct__c = salesOrder.Surcharge_Pct__c;
        salesInvoice.Billing_Instructions__c = salesOrder.Billing_Instructions__c;
        salesInvoice.Customer_Billing_Instructions__c = salesOrder.Customer_Billing_Instructions__c;
        salesInvoice.Internal_Comments__c = salesOrder.Internal_Comments__c;
        salesInvoice.Site_Scope__c = salesOrder.Site_Scope__c;
        // if(billToCustomer.Customer_Type__c == 'I/C'){
        //     salesInvoice.Approved__c = true;
        //     salesInvoice.Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name();
        // }
        mapSalesInvoicesByName.put(salesInvoice.Name, salesInvoice);
        insert mapSalesInvoicesByName.values();

        List<Sales_Invoice_Job_Task__c> salesInvoiceJobTasks = new List<Sales_Invoice_Job_Task__c>();
        Sales_Invoice_Job_Task__c salesInvoiceJobTask = new Sales_Invoice_Job_Task__c();
        salesInvoiceJobTask.Name = salesOrderJobTask.Name;
        salesInvoiceJobTask.Line_No__c = 1;
        salesInvoiceJobTask.Sales_Invoice__c = salesInvoice.Id;
        salesInvoiceJobTask.Billing_Type__c = salesOrderJobTask.Billing_Type__c;
        salesInvoiceJobTask.Tax_Group__c = salesOrderJobTask.Tax_Group__c;
        salesInvoiceJobTask.Tax_Pct__c = salesOrderJobTask.Tax_Pct__c;
        SalesInvoiceJobTask.Billing_Pct__c = salesOrderJobTask.Pct_To_Bill__c;
        SalesInvoiceJobTask.Billing_Amount__c = salesOrderJobTask.Amount_to_Bill__c;
        salesInvoiceJobTask.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
        salesInvoiceJobTasks.add(salesInvoiceJobTask);
        insert salesInvoiceJobTasks;

        List<Sales_Invoice_Line__c> salesInvoiceLines = BillingWorksheetServiceImpl.createSalesInvoiceLines(salesInvoice, salesInvoiceJobTask, mapBillingWorksheetLinesByOrderId.get(salesOrder.Id), 1);
        insert salesInvoiceLines;
    }

    //Wrapper Classes -------------------------------------------------------------------------------------------------------------------
    public class ServiceCenterWrapper {
        public Service_Center__c ServiceCenter { set; get; }
        public List<Approval_Tree__c> ApprovalTrees { set; get; }

        public ServiceCenterWrapper(Service_Center__c serviceCenter) {
            this.ServiceCenter = serviceCenter;
            this.ApprovalTrees = new List<Approval_Tree__c>();
        }

        public void addApprovalTree(List<Approval_Tree__c> aprApprovalTrees) {
            this.ApprovalTrees = aprApprovalTrees;
        }
    }

    public class AccountWrapper {
        public Account Account { set; get; }
        public Map<String, Site_Address__c> mapSiteAddressesByName { set; get; }
        public Map<String, Subsidiary_Vendor__c> mapSubsidiaryVendorsByName { set; get; }
        public Map<String, Contact> mapContactByName { set; get; }

        public AccountWrapper(Account account) {
            this.Account = account;
            this.mapSiteAddressesByName = new Map<String, Site_Address__c>();
            this.mapSubsidiaryVendorsByName = new Map<String, Subsidiary_Vendor__c>();
            this.mapContactByName = new Map<String, Contact>();
        }

        public void addSiteAddress(Site_Address__c siteAddress) {
            this.mapSiteAddressesByName.put(siteAddress.Name, siteAddress);
        }

        public void addSubsidiaryVendor(Subsidiary_Vendor__c subsidiaryVendor) {
            this.mapSubsidiaryVendorsByName.put(subsidiaryVendor.Name, subsidiaryVendor);
        }

        public void addContact(Contact contact) {
            this.mapContactByName.put(contact.FirstName + ' ' + contact.LastName, contact);
        }
    }

    public class ResourceTypeWrapper {
        public Resource_Type__c ResourceType { set; get; }
        public Map<String, ResourceTypeUOMAssociation__c> mapResourceTypeUOMAssociations = new Map<String, ResourceTypeUOMAssociation__c>();

        public ResourceTypeWrapper(Resource_Type__c resourceType) {
            this.ResourceType = resourceType;
            this.mapResourceTypeUOMAssociations = new Map<String, ResourceTypeUOMAssociation__c>();
        }

        public void addResourceTypeUOMAssociations(List<ResourceTypeUOMAssociation__c> resourceTypeUOMAssociations) {
            for (ResourceTypeUOMAssociation__c resourceTypeUOMAssociation : resourceTypeUOMAssociations) {
                this.mapResourceTypeUOMAssociations.put(resourceTypeUOMAssociation.Name, resourceTypeUOMAssociation);
            }
        }
    }

    public class ResourceWrapper {
        public Resource__c Resource { set; get; }
        public Map<String, ResourceUOMAssociation__c> mapResourceUOMAssociationsByName = new Map<String, ResourceUOMAssociation__c>();

        public ResourceWrapper(Resource__c resource) {
            this.Resource = resource;
            this.mapResourceUOMAssociationsByName = new Map<String, ResourceUOMAssociation__c>();
        }

        public void addResourceUOMAssociations(List<ResourceUOMAssociation__c> resourceUOMAssociations) {
            for (ResourceUOMAssociation__c resourceUOMAssociation : resourceUOMAssociations) {
                this.mapResourceUOMAssociationsByName.put(resourceUOMAssociation.Name, resourceUOMAssociation);
            }
        }
    }

    public class PayRuleWrapper {
        public Pay_Rule__c PayRule { set; get; }
        public List<Pay_Rule_Line__c> PayRuleLines { set; get; }
        public List<Pay_Rule_Holiday__c> PayRuleHolidays { set; get; }

        public PayRuleWrapper(Pay_Rule__c payRule) {
            this.PayRule = payRule;
            this.PayRuleLines = new List<Pay_Rule_Line__c>();
            this.PayRuleHolidays = new List<Pay_Rule_Holiday__c>();
        }

        public void addPayRuleLines(List<Pay_Rule_Line__c> payRuleLines) {
            this.PayRuleLines.addAll(payRuleLines);
        }

        public void addPayRuleHolidays(List<Pay_Rule_Holiday__c> payRuleHolidays) {
            this.PayRuleHolidays.addAll(payRuleHolidays);
        }
    }

    public class RateSheetWrapper {
        public Rate_Sheet__c RateSheet { set; get; }
        public List<Rate_Sheet_Line__c> RateSheetLines { set; get; }
        public List<Pricing_Rate_Sheet_Association__c> PricingRateSheetAssociations { set; get; }

        public RateSheetWrapper(Rate_Sheet__c rateSheet) {
            this.RateSheet = rateSheet;
            this.RateSheetLines = new List<Rate_Sheet_Line__c>();
            this.PricingRateSheetAssociations = new List<Pricing_Rate_Sheet_Association__c>();
        }

        public void addRateSheetLines(List<Rate_Sheet_Line__c> RateSheetLines) {
            this.RateSheetLines.addAll(RateSheetLines);
        }

        public void addPricingRateSheetAssociations(List<Pricing_Rate_Sheet_Association__c> pricingRateSheetAssociations) {
            this.PricingRateSheetAssociations = pricingRateSheetAssociations;
        }
    }

    public class ContractWrapper {
        public Contract Contract { set; get; }
        public List<Contract_Line__c> ContractLines = new List<Contract_Line__c>();

        public ContractWrapper(Contract billingRule) {
            this.Contract = billingRule;
            this.ContractLines = new List<Contract_Line__c>();
        }
        public void addContractLines(List<Contract_Line__c> contractLines) {
            this.ContractLines.addAll(contractLines);
        }
    }

    public class BillingRuleWrapper {
        public Billing_Rule__c BillingRule { set; get; }
        public List<Billing_Rule_Line__c> BillingRuleLines = new List<Billing_Rule_Line__c>();

        public BillingRuleWrapper(Billing_Rule__c billingRule) {
            this.BillingRule = billingRule;
            this.BillingRuleLines = new List<Billing_Rule_Line__c>();
        }

        public void addBillingRuleLines(List<Billing_Rule_Line__c> billingRuleLines) {
            this.BillingRuleLines.addAll(billingRuleLines);
        }
    }

    public class TaxAreaWrapper {
        public Tax_Area__c TaxArea { set; get; }
        public Map<String, TaxJurisdictionWrapper> mapTaxJurisdictionWrappersByName { set; get; }

        public TaxAreaWrapper(Tax_Area__c taxArea) {
            this.TaxArea = taxArea;
            this.mapTaxJurisdictionWrappersByName = new Map<String, TaxJurisdictionWrapper>();
        }

        public void addTaxJurisdiction(Tax_Jurisdiction__c taxJurisdiction) {
            this.mapTaxJurisdictionWrappersByName.put(taxJurisdiction.Name, new TaxJurisdictionWrapper(taxJurisdiction));
        }

        public void addTaxDetail(String jurisdictionName, Tax_Detail__c taxDetail) {
            this.mapTaxJurisdictionWrappersByName.get(jurisdictionName).addTaxDetail(taxDetail);
        }
    }

    public class TaxJurisdictionWrapper {
        public Tax_Jurisdiction__c TaxJurisdiction { set; get; }
        public Map<String, Tax_Detail__c> mapTaxDetailsByName { set; get; }

        public TaxJurisdictionWrapper(Tax_Jurisdiction__c taxJurisdiction) {
            this.TaxJurisdiction = taxJurisdiction;
            this.mapTaxDetailsByName = new Map<String, Tax_Detail__c>();
        }

        public void addTaxDetail(Tax_Detail__c taxDetail) {
            this.mapTaxDetailsByName.put(taxDetail.Tax_Jurisdiction__r.Name, taxDetail);
        }
    }


    public class JobTaskTemplateWrapper {
        public Job_Task_Template__c JobTaskTemplate { set; get; }
        public List<Job_Task_Template_Line__c> JobTaskTemplateLines { set; get; }

        public JobTaskTemplateWrapper(Job_Task_Template__c jobTaskTemplate) {
            this.JobTaskTemplate = jobTaskTemplate;
            this.JobTaskTemplateLines = new List<Job_Task_Template_Line__c>();
        }

        public void addJobTaskTemplateLines(List<Job_Task_Template_Line__c> jobTaskTemplateLines) {
            this.JobTaskTemplateLines.addAll(jobTaskTemplateLines);
        }
    }

    //test
}