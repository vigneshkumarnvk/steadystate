public class Application {
    public static final fflib_Application.UnitOfWorkFactory UnitOfWork =
            new fflib_Application.UnitOfWorkFactory(
                    new List<SObjectType> {
                            Sales_Order__c.SObjectType,
                            Sales_Line__c.SObjectType,
                            Sales_Invoice__c.SObjectType,
                            TM__c.SObjectType,
                            Sales_Invoice_Line__c.SObjectType,
                            TM_Line__c.SObjectType
                    });

    // Configure and create the ServiceFactory for this Application
    public static final fflib_Application.ServiceFactory Service =
            new fflib_Application.ServiceFactory(
                    new Map<Type, Type> {
                            ISalesLinesService.class => SalesLinesServiceImpl.class,
                            ITMsService.class => TMsServiceImpl.class,
                            ITMLLinesService.class => TMLLinesServiceImpl.class,
                            ISalesOrdersService.class => SalesOrdersServiceImpl.class,
                            ISalesInvoicesService.class => SalesInvoicesServiceImpl.class,
                            IBillingWorksheetService.class => BillingWorksheetServiceImpl.class, //job task <<
                            ISalesInvoiceLinesService.class => SalesInvoiceLinesServiceImpl.class //job task <<
                    });

    // Configure and create the SelectorFactory for this Application
    // Type t = Type.forName(cs.className__c);
    public static final fflib_Application.SelectorFactory Selector =
            new fflib_Application.SelectorFactory(
                    new Map<SObjectType, Type>{
                            Account.SObjectType => AccountsSelector.class,
                            Approval_Tree__c.SObjectType => ApprovalTreesSelector.class,
                            Billing_Rule__c.SObjectType => BillingRulesSelector.class,
                            Contract.SObjectType => ContractsSelector.class,
                            Contract_Line__c.SObjectType => ContractLinesSelector.class,
                            Contact.SObjectType => ContactsSelector.class,
                            Facility__c.SObjectType => FacilitiesSelector.class,
                            Holiday__c.SObjectType => HolidaysSelector.class,
                            Job_Task_Template__c.SObjectType => JobTaskTemplatesSelector.class, //job task
                            Job_Task_Template_Line__c.SObjectType => JobTaskTemplateLinesSelector.class, //job task
                            Pricing_Rate_Sheet_Association__c.SObjectType => PriceListSelector.class,
                            Pay_Rule__c.SObjectType => PayRulesSelector.class,
                            Presumptive_Resource__c.SObjectType => PresumptiveResourcesSelector.class, //job task
                            Resource_Type__c.SObjectType => ResourceTypesSelector.class,
                            Resource__c.SObjectType => ResourcesSelector.class,
                            ResourceUOMAssociation__c.SObjectType => ResourceUnitOfMeasuresSelector.class,
                            Resource_Off__c.SObjectType => ResourceOffsSelector.class,
                            ResourceTypeUOMAssociation__c.SObjectType => ResourceTypeUnitOfMeasuresSelector.class,
                            Rate_Sheet_Line__c.SObjectType => RatesheetLinesSelector.class,
                            Rate_Sheet__c.SObjectType => RateSheetsSelector.class,
                            Service_Center__c.SObjectType => ServiceCentersSelector.class,
                            Surcharge_Setup__c.SObjectType => SurchargeSetupsSelector.class,
                            Subsidiary_Vendor__c.SObjectType => SubsidiaryVendorsSelector.class,
                            Sales_Order__c.SObjectType => SalesOrdersSelector.class,
                            Sales_Line__c.SObjectType => SalesLinesSelector.class,
                            Sales_Order_Type__c.SObjectType => SalesOrderTypesSelector.class,
                            Sales_Invoice__c.SObjectType => SalesInvoicesSelector.class,
                            Sales_Invoice_Line__c.SObjectType => SalesInvoiceLinesSelector.class,
                            Sales_Order_Job_Task__c.SObjectType => SalesOrderJobTasksSelector.class, //job task
                            TM__c.SObjectType => TMsSelector.class,
                            TM_Line__c.SObjectType => TMLinesSelector.class,
                            TM_Job_Task__c.SObjectType => TMJobTasksSelector.class, //job task
                            User.SObjectType => UsersSelector.class,
                            Unit_of_Measure__c.SObjectType => UnitOfMeasuresSelector.class,
                            Billing_Worksheet_Line__c.SObjectType => BillingWorksheetLinesSelector.class, //job task
                            Sales_Invoice_Job_Task__c.SObjectType => SalesInvoiceJobTasksSelector.class, //job task
                            Signature__c.SObjectType => SignaturesSelector.class, //signature request
                            Operating_Expense__c.SObjectType => OperatingExpensesSelector.class //Operating Expense Mod, Ticket#24560
                    });

    // Configure and create the DomainFactory for this Application
    public static final fflib_Application.DomainFactory Domain =
            new fflib_Application.DomainFactory(
                    Application.Selector,
                    new Map<SObjectType, Type>{
                            Sales_Invoice__c.SObjectType => SalesInvoices.Constructor.class,
                            Sales_Order__c.SObjectType => SalesOrders.Constructor.class,
                            TM__c.SObjectType => TMs.Constructor.class,
                            Sales_Line__c.SObjectType => SalesLines.Constructor.class,
                            TM_Line__c.SObjectType => TMLines.Constructor.class,
                            Account.SObjectType => Accounts.Constructor.class
                    });
}