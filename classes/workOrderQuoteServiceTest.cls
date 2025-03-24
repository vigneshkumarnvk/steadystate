/*************************************************************************************************
* Name         :  WorkOrderQuoteServiceTest 
* Description  :  Test Class for WorkOrderQuoteService Apex Class
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Praneeth Yalamati         08-17-2023             US94501: Create Work Order in EQAI when Convert Quote to Order button is pressed
* Praneeth Yalamati         09-29-2023             US97345: WorkOrderQuoteDetail JSON Updates
* Praneeth Yalamati         10-06-2023             US97655: ACV: WorkOrderQuoteDetail JSON updates for Tasks. 	
*************************************************************************************************/
@IsTest
public class workOrderQuoteServiceTest implements HttpCalloutMock  {
    
    @TestSetup static void setupData(){
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;

        Billing_Rule__c br = new Billing_Rule__c(
                Holidays_Bill_in_DT_Rate__c = 'Christmas Day Company',
                Holidays_Bill_in_OT_Rate__c = 'Thanksgiving',
                Sunday_Rate_Code__c = EnumUtil.TimeRateCode.DT.name(),
                Saturday_Rate_Code__c = EnumUtil.TimeRateCode.OT.name()
        );
        insert br;

        List<Billing_Rule_Line__c> billingRuleLines = new List<Billing_Rule_Line__c>();

        Billing_Rule_Line__c billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,30,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,30,0,0);
        billingRuleLine.Hours_After_Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code_After_Number_of_Hours__c = 'OT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,30,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Hour_Based';
        billingRuleLine.Day__c = 'Tuesday';
        billingRuleLine.Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Rate_Code_for_Remaining_Hours__c = 'OT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Hour_Based';
        billingRuleLine.Day__c = 'Friday';
        billingRuleLine.Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Hours_After_Number_of_Hours__c = 3;
        billingRuleLine.Rate_Code_After_Number_of_Hours__c = 'OT';
        billingRuleLine.Rate_Code_for_Remaining_Hours__c = 'DT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Day_Based';
        billingRuleLine.Day__c = 'Saturday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLines.add(billingRuleLine);

        if(billingRuleLines.size() > 0){
            insert billingRuleLines;
        }

        companySetup.Default_Billing_Rule__c = br.Id;
        update companySetup;

    }

    @IsTest
    private static void testWorkOrderQuoteHeaderInfo(){  
    
        Test.setMock(HttpCalloutMock.class, new workOrderQuoteServiceTest());
        Test.StartTest();
        Subsidiary_Company__c subsidiaryCompany =
            new Subsidiary_Company__c(
                Name = '1-REPUBLIC SERVICES TEST',
                Display_Name__c = 'REPUBLIC SERVICES TEST'
            );
        insert subsidiaryCompany;
        Service_Center__c sc = new Service_Center__c(
            Name = '011 TEST',
            Description__c = 'SC01 Elizabeth, NJ Ops',
            Subsidiary_Company__c = subsidiaryCompany.Id,
            //TM_No_Series__c = theNumberingSeries.Id,
            //Sales_Order_No_Series__c = theNumberingSeries.Id,
           
            Max_No_of_Emergency_T_M__c = 2,
            Code__c = '01 TEST',
            City__c = 'Elizabeth TEST',
            Street__c = '201 South First St. TEST',
            Postal_Code__c = '121001',
            State__c = 'NJ',
            Country__c = 'US',
            Include_SO_in_EQAI_Invoice_Integration__c = true
            
        );
        insert sc;
        Sales_Order__c salesOrder = TestDataUtil.SalesOrderRecordCSA;  
        salesOrder.Service_Center__c = sc.Id;
        update salesOrder; 
        Test.StopTest();
        WorkOrderQuoteHeaderJSON  QuoteHeaderRecord = new WorkOrderQuoteHeaderJSON(salesOrder,null,null,null,'12345');
        String response  = WorkOrderQuoteService.WorkOrderQuoteHeaderInfo(salesOrder.Id);
       // System.assertEquals(response ,'200');
    
    }
    
    @IsTest
    private static void testWorkOrderQuoteDetailsInfo(){
    
        Test.setMock(HttpCalloutMock.class, new workOrderQuoteServiceTest());
        Test.StartTest();       
        
             Subsidiary_Company__c subC = new Subsidiary_Company__c(
                    Name = '1-ACV ENVIRO081223',
                    Display_Name__c = '081223'
            );
            
            Sales_Order__c salesOrder = TestDataUtil.SalesOrderRecordCSA;      
        	
        	Salesperson__c salesPerson = TestDataUtil.SalespersonRecord;
            salesPerson.Territory_Code__c = 'test123';
            salesPerson.Internal_Contact__c = true;  
            update salesPerson;
        
        	salesOrder.Account_Executives__c = salesPerson.id;
        	update salesOrder;
        
            Unit_of_Measure__c uom = new Unit_of_Measure__c( Name = 'HOUR',  Description__c = '081223' );
            insert uom;
            Resource_Type__c rt = new Resource_Type__c(
                    Name = 'Field Tech',
                    Description__c = 'Field Tech',
                    Category__c = 'Labor',
                    Unit_of_Measure__c = uom.Id
            );
            insert rt;
            Resource__c r = new Resource__c(
                    Name = 'TR7',
                    Fleet_Number__c = 'TR7',
                    Status__c = 'Active',
                    Plate_Number__c = 'TDF19P',
                    Plate_State__c = 'NJ',
                    Make__c = 'Car Mate',
                    VIN__c = '5A3U616D1YL005502',
                    Country__c = 'US',
                    Subsidiary_Company__c = subC.Id,
                    Rent_Company__c = 'CVI',
                    Resource_Type__c = rt.Id,
                    Category__c = 'Labor',
                    Unit_of_Measure__c = uom.Id,
                    Employee_Type__c = 'Employee' ,
                    Non_Payroll_Labor_Resource__c = false
            );
            insert r;
            Sales_Line__c theSL = new Sales_Line__c(
                Line_No__c = 1,
                Description__c = 'Test item',
                Unit_of_Measure__c = uom.Id,
                Quantity__c = 1100,
                UOM_Qty__c = 10,
                Regular_Hours__c = 10,
                Category__c = 'Labor',
                Sales_Order__c = salesOrder.Id,
                Resource_Type__c = rt.Id,
                 Regular_Rate__c = 10,
                Overtime_Rate__c=10,
                Unit_Cost__c=10,
                Premium_Rate__c=10,
                Number_of_Day__c = 1
            );
            insert theSL;            
            Sales_Order__c orderRecord = [ Select Id,Pay_Rule__r.Name,Payment_Term__r.Name,Project_Coordinator__r.Name,Service_Center__r.Name,Subsidiary_Company__r.Name,Tax_Area__r.Name,Account_Executives__c,Account_Executives__r.Name,Bill_to_Contact__r.Name,Bill_to_Contact__c,Bill_to_Customer_No__c,Bill_to_Customer_No__r.Name,City__c,Country__c,Estimated_Job_End_Date__c,Estimated_Job_End_Time__c,Estimated_Job_Start_Date__c,Estimated_Job_Start_Time__c,CMR_Description__c,Name,Order_Total_Amount__c,Order_Total_Amount_Incl_Tax__c,Order_Total_Tax__c,Pay_Rule__c,Payment_Term__c,Phone_No__c,Postal_Code__c,Prevailing_Wage_Job__c,Project_Coordinator__c,Site_Scope__c,Service_Center__c,Site_City__c,Site_Country__c,Site_Postal_Code__c,Site_State__c,Site_Street__c,State__c,Subsidiary_Company__c,Tax_Area__c,Tax_Liable__c,Total_Cost__c,
            (select Id,Sales_Order__r.Name,Category__c,Number_of_Day__c,Description__c,Premium_Hours__c,Premium_Rate__c,Line_Amount__c,Line_Amt_Incl_Tax__c,Line_Cost__c,Line_No__c,Markup__c,Markup_Option__c,Overtime_Hours__c,Overtime_Rate__c,
            Quantity__c,Regular_Hours__c,Regular_Rate__c,Resource__c,Resource_Type__c,Tax__c,Tax_Pct__c,Tax_Group__c,Unit_Cost__c,Unit_of_Measure__c,Unit_of_Measure__r.Name,
            Unit_Price__c,UOM_Qty__c,Resource__r.Resource_Class_Code__c,Resource__r.External_ID__c,Resource_Type__r.External_ID__c,Resource_Type__r.Resource_Class_Code__c,
            Resource_Type__r.EQAI_Supply__c,Bundle_Line__c,Bundle_Line__r.Name,Sales_Order_Job_Task__c ,Sales_Order_Job_Task__r.Name  from Sales_Lines__r)
            from Sales_Order__c Where Id = :salesOrder.Id]; 
            
        Test.StopTest();
        WorkOrderQuoteDetailsJSON QuoteDetailsRecord = new WorkOrderQuoteDetailsJSON(theSL, 0, 0, null, null,'123');
                
        String response = WorkOrderQuoteService.WorkOrderQuoteDetailsInfo(orderRecord,0,0,'123');
    
    }
     @IsTest
    private static void testWorkOrderQuoteDetailsInfo2(){
    
        Test.setMock(HttpCalloutMock.class, new workOrderQuoteServiceTest());
        Test.StartTest();       
        
             Subsidiary_Company__c subC = new Subsidiary_Company__c(
                    Name = '1-ACV ENVIRO081223',
                    Display_Name__c = '081223'
            );
            
            Sales_Order__c salesOrder = TestDataUtil.SalesOrderRecordCSA;        
            Unit_of_Measure__c uom = new Unit_of_Measure__c( Name = '123',  Description__c = '081223' );
            insert uom;
            Resource_Type__c rt = new Resource_Type__c(
                    Name = 'Field Tech',
                    Description__c = 'Field Tech',
                    Category__c = 'Labor',
                    Unit_of_Measure__c = uom.Id
            );
            insert rt;
            Resource__c r = new Resource__c(
                    Name = 'TR7',
                    Fleet_Number__c = 'TR7',
                    Status__c = 'Active',
                    Plate_Number__c = 'TDF19P',
                    Plate_State__c = 'NJ',
                    Make__c = 'Car Mate',
                    VIN__c = '5A3U616D1YL005502',
                    Country__c = 'US',
                    Subsidiary_Company__c = subC.Id,
                    Rent_Company__c = 'CVI',
                    Resource_Type__c = rt.Id,
                    Category__c = 'Labor',
                    Unit_of_Measure__c = uom.Id,
                    Employee_Type__c = 'Employee' ,
                    Non_Payroll_Labor_Resource__c = false
            );
            insert r;
            Sales_Line__c theSL = new Sales_Line__c(
                Line_No__c = 1,
                Description__c = 'Test item',
                Unit_of_Measure__c = uom.Id,
                Quantity__c = 1100,
                UOM_Qty__c = 10,
                Regular_Hours__c = 10,
                Category__c = 'Labor',
                Sales_Order__c = salesOrder.Id,
                Resource_Type__c = rt.Id,
                 Regular_Rate__c = 0,
                Overtime_Rate__c=0,
                Unit_Cost__c=10,
                Premium_Rate__c=10,
                Number_of_Day__c = 1
            );
            insert theSL;            
            Sales_Order__c orderRecord = [ Select Id,Pay_Rule__r.Name,Payment_Term__r.Name,Project_Coordinator__r.Name,Service_Center__r.Name,Subsidiary_Company__r.Name,Tax_Area__r.Name,Account_Executives__c,Account_Executives__r.Name,Bill_to_Contact__r.Name,Bill_to_Contact__c,Bill_to_Customer_No__c,Bill_to_Customer_No__r.Name,City__c,Country__c,Estimated_Job_End_Date__c,Estimated_Job_End_Time__c,Estimated_Job_Start_Date__c,Estimated_Job_Start_Time__c,CMR_Description__c,Name,Order_Total_Amount__c,Order_Total_Amount_Incl_Tax__c,Order_Total_Tax__c,Pay_Rule__c,Payment_Term__c,Phone_No__c,Postal_Code__c,Prevailing_Wage_Job__c,Project_Coordinator__c,Site_Scope__c,Service_Center__c,Site_City__c,Site_Country__c,Site_Postal_Code__c,Site_State__c,Site_Street__c,State__c,Subsidiary_Company__c,Tax_Area__c,Tax_Liable__c,Total_Cost__c,
            (select Id,Sales_Order__r.Name,Category__c,Number_of_Day__c,Description__c,Premium_Hours__c,Premium_Rate__c,Line_Amount__c,Line_Amt_Incl_Tax__c,Line_Cost__c,Line_No__c,Markup__c,Markup_Option__c,Overtime_Hours__c,Overtime_Rate__c,
            Quantity__c,Regular_Hours__c,Regular_Rate__c,Resource__c,Resource_Type__c,Tax__c,Tax_Pct__c,Tax_Group__c,Unit_Cost__c,Unit_of_Measure__c,Unit_of_Measure__r.Name,
            Unit_Price__c,UOM_Qty__c,Resource__r.Resource_Class_Code__c,Resource_Type__r.EQAI_Supply__c,Resource__r.External_ID__c,Resource_Type__r.External_ID__c,Resource_Type__r.Resource_Class_Code__c,Bundle_Line__c,Bundle_Line__r.Name,Sales_Order_Job_Task__c ,Sales_Order_Job_Task__r.Name  from Sales_Lines__r)
            from Sales_Order__c Where Id = :salesOrder.Id]; 
            
        Test.StopTest();
        WorkOrderQuoteDetailsJSON QuoteDetailsRecord = new WorkOrderQuoteDetailsJSON(theSL, 0, 0, null, null,'123');
                
        String response = WorkOrderQuoteService.WorkOrderQuoteDetailsInfo(orderRecord,0,0,'123');
        System.assertEquals(response ,'200');
    
    }
    
     @IsTest
    private static void testWorkOrderQuoteDetailsInfo1(){
    
        Test.setMock(HttpCalloutMock.class, new workOrderQuoteServiceTest());
        Test.StartTest();       
        
             Subsidiary_Company__c subC = new Subsidiary_Company__c(
                    Name = '1-ACV ENVIRO081223',
                    Display_Name__c = '081223'
            );
            
            Sales_Order__c salesOrder = TestDataUtil.SalesOrderRecordCSA;        
            Unit_of_Measure__c uom = new Unit_of_Measure__c( Name = '12345',  Description__c = '081223' );
            insert uom;
            Resource_Type__c rt = new Resource_Type__c(
                    Name = 'Tracktor',
                    Description__c = 'Tracktor',
                    Category__c = 'Equipment',
                    Unit_of_Measure__c = uom.Id
            );
            insert rt;
            Resource__c r = new Resource__c(
                    Name = 'TR7',
                    Fleet_Number__c = 'TR7',
                    Status__c = 'Active',
                    Plate_Number__c = 'TDF19P',
                    Plate_State__c = 'NJ',
                    Make__c = 'Car Mate',
                    VIN__c = '5A3U616D1YL005502',
                    Country__c = 'US',
                    Subsidiary_Company__c = subC.Id,
                    Rent_Company__c = 'CVI',
                    Resource_Type__c = rt.Id,
                    Category__c = 'Equipment',
                    Unit_of_Measure__c = uom.Id,
                    Employee_Type__c = 'Employee' ,
                    Non_Payroll_Labor_Resource__c = false
            );
            insert r;
            Sales_Line__c theSL = new Sales_Line__c(
                Line_No__c = 1,
                Description__c = 'Test item',
                Unit_of_Measure__c = uom.Id,
                Quantity__c = 1100,
                UOM_Qty__c = 10,
                Regular_Hours__c = 10,
                Category__c = 'Equipment',
                Sales_Order__c = salesOrder.Id,
                Resource_Type__c = rt.Id,               
                Unit_Price__c = 10,
                Number_of_Day__c = 1
            );
            insert theSL;            
            Sales_Order__c orderRecord = [ Select Id,Bill_to_Customer_No__r.Sage_Customer_No__c ,Pay_Rule__r.Name,Payment_Term__r.Name,Project_Coordinator__r.Name,Service_Center__r.Name,Subsidiary_Company__r.Name,Tax_Area__r.Name,Account_Executives__c,Account_Executives__r.Name,Bill_to_Contact__r.Name,Bill_to_Contact__c,Bill_to_Customer_No__c,Bill_to_Customer_No__r.Name,City__c,Country__c,Estimated_Job_End_Date__c,Estimated_Job_End_Time__c,Estimated_Job_Start_Date__c,Estimated_Job_Start_Time__c,CMR_Description__c,Name,Order_Total_Amount__c,Order_Total_Amount_Incl_Tax__c,Order_Total_Tax__c,Pay_Rule__c,Payment_Term__c,Phone_No__c,Postal_Code__c,Prevailing_Wage_Job__c,Project_Coordinator__c,Site_Scope__c,Service_Center__c,Site_City__c,Site_Country__c,Site_Postal_Code__c,Site_State__c,Site_Street__c,State__c,Subsidiary_Company__c,Tax_Area__c,Tax_Liable__c,Total_Cost__c,
            (select Id,Sales_Order__r.Name,Category__c,Number_of_Day__c,Description__c,Premium_Hours__c,Premium_Rate__c,Line_Amount__c,Line_Amt_Incl_Tax__c,Line_Cost__c,Line_No__c,Markup__c,Markup_Option__c,Overtime_Hours__c,Overtime_Rate__c,
            Quantity__c,Regular_Hours__c,Regular_Rate__c,Resource__c,Resource_Type__c,Tax__c,Tax_Pct__c,Tax_Group__c,Unit_Cost__c,Unit_of_Measure__c,Unit_of_Measure__r.Name,
            Unit_Price__c,UOM_Qty__c,Resource_Type__r.EQAI_Supply__c,Resource__r.Resource_Class_Code__c,Resource_Type__r.Resource_Class_Code__c,Resource__r.External_ID__c,Resource_Type__r.External_ID__c,Bundle_Line__c,Bundle_Line__r.Name,Sales_Order_Job_Task__c ,Sales_Order_Job_Task__r.Name  from Sales_Lines__r)
            from Sales_Order__c Where Id = :salesOrder.Id]; 
            
        Test.StopTest();
        WorkOrderQuoteDetailsJSON QuoteDetailsRecord = new WorkOrderQuoteDetailsJSON(theSL, 0, 0, null, null,'123');
                
        String response = WorkOrderQuoteService.WorkOrderQuoteDetailsInfo(orderRecord,0,0,'123');
        System.assertEquals(response ,'200');
    
    }
     @IsTest
    private static void testWorkOrderQuoteDetailsInfo3(){
    
        Test.setMock(HttpCalloutMock.class, new workOrderQuoteServiceTest());
        Test.StartTest();       
        
             Subsidiary_Company__c subC = new Subsidiary_Company__c(
                    Name = '1-ACV ENVIRO081223',
                    Display_Name__c = '081223'
            );
            
            Sales_Order__c salesOrder = TestDataUtil.SalesOrderRecordCSA;        
            Unit_of_Measure__c uom = new Unit_of_Measure__c( Name = '12345',  Description__c = '081223' );
            insert uom;
            Resource_Type__c rt = new Resource_Type__c(
                    Name = 'Tracktor',
                    Description__c = 'Tracktor',
                    Category__c = 'Equipment',
                    Unit_of_Measure__c = uom.Id,
                	EQAI_Supply__c = True
            );
            insert rt;
            Resource__c r = new Resource__c(
                    Name = 'TR7',
                    Fleet_Number__c = 'TR7',
                    Status__c = 'Active',
                    Plate_Number__c = 'TDF19P',
                    Plate_State__c = 'NJ',
                    Make__c = 'Car Mate',
                    VIN__c = '5A3U616D1YL005502',
                    Country__c = 'US',
                    Subsidiary_Company__c = subC.Id,
                    Rent_Company__c = 'CVI',
                    Resource_Type__c = rt.Id,
                    Category__c = 'Equipment',
                    Unit_of_Measure__c = uom.Id,
                    Employee_Type__c = 'Employee' ,
                    Non_Payroll_Labor_Resource__c = false
            );
            insert r;
            Sales_Line__c theSL = new Sales_Line__c(
                Line_No__c = 1,
                Description__c = 'Test item',
                Unit_of_Measure__c = uom.Id,
                Quantity__c = 1100,
                UOM_Qty__c = 10,
                Regular_Hours__c = 10,
                Category__c = 'Equipment',
                Sales_Order__c = salesOrder.Id,
                Resource_Type__c = rt.Id,               
                Unit_Price__c = 10,
                Number_of_Day__c = 1
            );
            insert theSL;            
            Sales_Order__c orderRecord = [ Select Id,Pay_Rule__r.Name,Payment_Term__r.Name,Project_Coordinator__r.Name,Service_Center__r.Name,Subsidiary_Company__r.Name,Tax_Area__r.Name,Account_Executives__c,Account_Executives__r.Name,Bill_to_Contact__r.Name,Bill_to_Contact__c,Bill_to_Customer_No__c,Bill_to_Customer_No__r.Name,City__c,Country__c,Estimated_Job_End_Date__c,Estimated_Job_End_Time__c,Estimated_Job_Start_Date__c,Estimated_Job_Start_Time__c,CMR_Description__c,Name,Order_Total_Amount__c,Order_Total_Amount_Incl_Tax__c,Order_Total_Tax__c,Pay_Rule__c,Payment_Term__c,Phone_No__c,Postal_Code__c,Prevailing_Wage_Job__c,Project_Coordinator__c,Site_Scope__c,Service_Center__c,Site_City__c,Site_Country__c,Site_Postal_Code__c,Site_State__c,Site_Street__c,State__c,Subsidiary_Company__c,Tax_Area__c,Tax_Liable__c,Total_Cost__c,
            (select Id,Sales_Order__r.Name,Category__c,Number_of_Day__c,Description__c,Premium_Hours__c,Premium_Rate__c,Line_Amount__c,Line_Amt_Incl_Tax__c,Line_Cost__c,Line_No__c,Markup__c,Markup_Option__c,Overtime_Hours__c,Overtime_Rate__c,
            Quantity__c,Regular_Hours__c,Regular_Rate__c,Resource__c,Resource_Type__c,Tax__c,Tax_Pct__c,Tax_Group__c,Unit_Cost__c,Unit_of_Measure__c,Unit_of_Measure__r.Name,
            Unit_Price__c,UOM_Qty__c,Resource_Type__r.EQAI_Supply__c,Resource__r.Resource_Class_Code__c,Resource_Type__r.Resource_Class_Code__c,Resource__r.External_ID__c,Resource_Type__r.External_ID__c,Bundle_Line__c,Bundle_Line__r.Name,Sales_Order_Job_Task__c ,Sales_Order_Job_Task__r.Name  from Sales_Lines__r)
            from Sales_Order__c Where Id = :salesOrder.Id]; 
            
        Test.StopTest();
        WorkOrderQuoteDetailsJSON QuoteDetailsRecord = new WorkOrderQuoteDetailsJSON(theSL, 0, 0, null, null,'123');
                
        String response = WorkOrderQuoteService.WorkOrderQuoteDetailsInfo(orderRecord,0,0,'123');
        System.assertEquals(response ,'200');
    
    }
    
    @TestVisible
    Public HTTPResponse respond(HTTPRequest req){
            try{
           
            HttpResponse res= new HttpResponse();
            res.setHeader('Content-Type','application/json');            
            res.setHeader('x-api-key','Key');
            res.setHeader('x-secret-token','Token');
            res.setBody('Integration Successful');
            res.setStatusCode(200);
            res.setStatus('OK');            
            return res;
            
        }catch(Exception ex){
                System.debug('ERROR message>>>'+ex.getMessage()+' Error Line Number>>> '+ex.getLineNumber());
        }
            return null;
         }
     @IsTest
    private static void testCreateCaseWithParentId(){  
    
        Test.StartTest();
        Sales_Order__c salesOrder = TestDataUtil.SalesOrderRecordCSA;            
        WorkOrderQuoteService.createCaseWithParentId(salesOrder.Id,'Error','check','Request');
        Test.StopTest();
    }
    @IsTest
    private static void testWorkOrderQuoteOrderAdvancedDisposal(){
    
        Test.setMock(HttpCalloutMock.class, new workOrderQuoteServiceTest());
        Test.StartTest();       
        Service_Center__c scRecord = TestDataUtil.ServiceCenterRecord;
        scRecord.Include_SO_in_EQAI_Invoice_Integration__c = true;
        scRecord.Advanced_Disposal__c = true;
        update scRecord;
        Subsidiary_Company__c subC = new Subsidiary_Company__c(
            Name = '1-ACV ENVIRO081223',
            Display_Name__c = '081223'
        );
        
        Sales_Order__c salesOrder = TestDataUtil.SalesOrderRecordCSA; 
        salesOrder.Site_Scope__c = 'test scope';
        salesOrder.Surcharge_Type__c = 'N/A';
        salesOrder.Document_Type__c = 'Sales Order';
        salesOrder.Site_Name__c = 'MDN Test';
        salesOrder.Site_Street__c = '108 SOUTH PARK STREET';
        salesOrder.Site_City__c = 'New York';
        salesOrder.Site_State__c = 'NY';
        salesOrder.Site_Postal_Code__c = '123456';
        salesOrder.Site_Phone_No__c = '0123456789';
        salesOrder.Site_Country__c = 'US';
        salesOrder.Bill_to_Customer_No__c = TestDataUtil.customerAccountRecord.Id;
        salesOrder.Service_Center__c = TestDataUtil.ServiceCenterRecord.Id;
        salesOrder.Sales_Order_Type__c = TestDataUtil.SalesOrdertypeRecord.Id;
        salesOrder.Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id;
        salesOrder.Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id;
        salesOrder.Total_Margin_Pct__c = 10;
        salesOrder.Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name();
        salesOrder.Approved__c = true;
        salesOrder.Approved_Profit_Margin__c = 40;
        salesOrder.Estimated_Job_Start_Date__c = Date.newInstance(2019,10,25);
        salesOrder.OwnerId = UserInfo.getUserId();
        salesOrder.EqaiGeneratorId__c = 343003;
        update salesOrder;
        
        Unit_of_Measure__c uom = new Unit_of_Measure__c( Name = '12345',  Description__c = '081223' );
        insert uom;
        Resource_Type__c rt = new Resource_Type__c(
            Name = 'Tracktor',
            Description__c = 'Tracktor',
            Category__c = 'Equipment',
            Unit_of_Measure__c = uom.Id,
            EQAI_Supply__c = True
        );
        insert rt;
        Resource__c r = new Resource__c(
            Name = 'TR7',
            Fleet_Number__c = 'TR7',
            Status__c = 'Active',
            Plate_Number__c = 'TDF19P',
            Plate_State__c = 'NJ',
            Make__c = 'Car Mate',
            VIN__c = '5A3U616D1YL005502',
            Country__c = 'US',
            Subsidiary_Company__c = subC.Id,
            Rent_Company__c = 'CVI',
            Resource_Type__c = rt.Id,
            Category__c = 'Equipment',
            Unit_of_Measure__c = uom.Id,
            Employee_Type__c = 'Employee' ,
            Non_Payroll_Labor_Resource__c = false
        );
        insert r;
        Sales_Line__c theSL = new Sales_Line__c(
            Line_No__c = 1,
            Description__c = 'Test item',
            Unit_of_Measure__c = uom.Id,
            Quantity__c = 1100,
            UOM_Qty__c = 10,
            Regular_Hours__c = 10,
            Category__c = 'Waste Disposal',
            Sales_Order__c = salesOrder.Id,
            //Resource_Type__c = rt.Id,               
            Unit_Price__c = 10,
            Number_of_Day__c = 1
        );
        insert theSL;            
        /* Sales_Order__c orderRecord = [ Select Id,Bill_to_Customer_No__r.Sage_Customer_No__c ,Pay_Rule__r.Name,Payment_Term__r.Name,Project_Coordinator__r.Name,Service_Center__r.Name,Subsidiary_Company__r.Name,Tax_Area__r.Name,Account_Executives__c,Account_Executives__r.Name,Bill_to_Contact__r.Name,Bill_to_Contact__c,Bill_to_Customer_No__c,Bill_to_Customer_No__r.Name,City__c,Country__c,Estimated_Job_End_Date__c,Estimated_Job_End_Time__c,Estimated_Job_Start_Date__c,Estimated_Job_Start_Time__c,CMR_Description__c,Name,Order_Total_Amount__c,Order_Total_Amount_Incl_Tax__c,Order_Total_Tax__c,Pay_Rule__c,Payment_Term__c,Phone_No__c,Postal_Code__c,Prevailing_Wage_Job__c,Project_Coordinator__c,Site_Scope__c,Service_Center__c,Site_City__c,Site_Country__c,Site_Postal_Code__c,Site_State__c,Site_Street__c,State__c,Subsidiary_Company__c,Tax_Area__c,Tax_Liable__c,Total_Cost__c,
(select Id,Sales_Order__r.Name,Category__c,Number_of_Day__c,Description__c,Premium_Hours__c,Premium_Rate__c,Line_Amount__c,Line_Amt_Incl_Tax__c,Line_Cost__c,Line_No__c,Markup__c,Markup_Option__c,Overtime_Hours__c,Overtime_Rate__c,
Quantity__c,Regular_Hours__c,Regular_Rate__c,Resource__c,Resource_Type__c,Tax__c,Tax_Pct__c,Tax_Group__c,Unit_Cost__c,Unit_of_Measure__c,Unit_of_Measure__r.Name,
Unit_Price__c,UOM_Qty__c,Resource_Type__r.EQAI_Supply__c,Resource__r.Resource_Class_Code__c,Resource_Type__r.Resource_Class_Code__c,Resource__r.External_ID__c,Resource_Type__r.External_ID__c,Bundle_Line__c,Bundle_Line__r.Name,Sales_Order_Job_Task__c ,Sales_Order_Job_Task__r.Name  from Sales_Lines__r)
from Sales_Order__c Where Id = :salesOrder.Id]; */        
        //Quering the Sales Order & Sales Lines object data by the salesOrderId
             Sales_Order__c orderRecord = [ Select Id,Surcharge_Amount__c,Contract__c ,Site_Address_Changed__c ,Surcharge_Type__c ,From_Sales_Quote__c ,Customer_PO_No__c,Internal_Comments__c ,Customer_Billing_Instructions__c ,D365_Project_ID__c,Billing_Instructions__c,Contract_Name__c,Surcharge_Pct__c,Contract_Surcharge_Type__c,EqaiGeneratorId__c,Site_Phone_No__c,EPA_ID__c,Bill_to_Customer_No__r.AccountNumber,  Bill_to_Customer_No__r.Sage_Customer_No__c ,Pay_Rule__r.Name,Payment_Term__r.Name,Project_Coordinator__r.Name,
                                                Service_Center__r.Name,Subsidiary_Company__r.Name,Tax_Area__r.Name,Account_Executives__c,Account_Executives__r.Name,
                                                Bill_to_Contact__r.Name,Bill_to_Contact__c,Bill_to_Customer_No__c,Bill_to_Customer_No__r.Name,City__c,Country__c,
                                                Estimated_Job_End_Date__c,Estimated_Job_End_Time__c,Estimated_Job_Start_Date__c,Estimated_Job_Start_Time__c,
                                                CMR_Description__c,Name,Order_Total_Amount__c,Order_Total_Amount_Incl_Tax__c,Order_Total_Tax__c,Pay_Rule__c,
                                                Payment_Term__c,Sales_Order_Type__r.Work_Order_Type_ID__c,Phone_No__c,Postal_Code__c,Prevailing_Wage_Job__c,Project_Coordinator__c,Site_Scope__c,Service_Center__c,
                                                Site_City__c,Site_Name__c,Site_Country__c,Site_Postal_Code__c,Site_State__c,Site_Street__c,State__c,Subsidiary_Company__c,Tax_Area__c,
                                                Tax_Liable__c,Total_Cost__c,Alternate_Site_Address__c,SO_sent_to_EQAI__c,SO_Submitted_to_EQAI__c,CreatedBy.Name,
                                                Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c, Service_Center__r.Advanced_Disposal__c,Contract__r.ContractNumber,EQAI_Billing_Project_Id__c,
                                                (SELECT Id,Category__c,Number_of_Day__c,Description__c,Premium_Hours__c,Premium_Rate__c,Line_Amount__c,Line_Amt_Incl_Tax__c,
                                                Line_Cost__c,Line_No__c,Markup__c,Markup_Option__c,Overtime_Hours__c,Overtime_Rate__c,Quantity__c,Regular_Hours__c,
                                                Regular_Rate__c,Resource__c,Resource_Type__c,Tax__c,Tax_Pct__c,Tax_Group__c,Unit_Cost__c,Unit_of_Measure__c,Unit_of_Measure__r.Name,
                                                Unit_Price__c,Name,xUnit_Cost__c,
                                                UOM_Qty__c,Resource__r.Resource_Class_Code__c,Resource__r.EQAI_Other__c,Resource_Type__r.Resource_Class_Code__c,Sales_Order__r.Name,Bundle_Line__c,
                                                Bundle_Line__r.Name,Bundle_Line__r.Resource_Type__c,Bundle_Line__r.Resource_Type__r.Name,Sales_Order_Job_Task__r.Name,
                                                Sales_Order_Job_Task__c,Resource__r.CSID__c,Resource__r.name,Resource__r.External_ID__c,
                                                Resource_Type__r.External_ID__c,Resource_Type__r.EQAI_Supply__c from Sales_Lines__r Order by Bundle_Line__c NULLS FIRST)
                                                from Sales_Order__c Where Id = :salesOrder.Id];
        System.debug('orderRecord >> '+orderRecord.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c);    
        Test.StopTest();
       // WorkOrderQuoteDetailsJSON QuoteDetailsRecord = new WorkOrderQuoteDetailsJSON(theSL, 0, 0, null, null,'123');
        EQAI_API_URL_Extensions__mdt getWOHeaderInfo = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='getWorkOrderHeaderInfo'];
         SalesInvoiceWOHeaderJSON  invoiceHeaderJson = new SalesInvoiceWOHeaderJSON(orderRecord ,null,null,null,'123');  
        String workOrderHeaderResponse = WorkOrderQuoteService.getPostCalloutResponseContents(getWOHeaderInfo.API_Extension__c, System.Json.serialize(invoiceHeaderJson),'POST',getWOHeaderInfo.API_Key__c,getWOHeaderInfo.API_Token__c);
        String response  = WorkOrderQuoteService.WorkOrderQuoteHeaderInfo(salesOrder.Id);
       //String response = WorkOrderQuoteService.WorkOrderQuoteDetailsInfo(orderRecord,0,0,'123');
        //System.assertEquals(response ,'200');
    }
}
