/*
    Depreciated replated with MobileTMController.cls
 */
public with sharing class Mobile_TMController {
    /*
    //cache <<
    @AuraEnabled
    public static String getVersion() {
        return  CompanySettingUtil.acvSetting.Mobile_TM_Version_No__c;
    }
    //cache >>
    
    @AuraEnabled
    public static String getSalesOrder(Id salesOrderId) {
        try {
            List<Sales_Order__c> salesOrders = [SELECT Id, Payment_Term__r.Name, Any_Deviations__c, Shippable_Containers__c, First_Hour_Of_Loading__c, Overtime_Rate_Description__c, Rate_Time_Definitions__c, Charges_For_Labor__c,
                    Waste_Disposal_And_Ancillary__c, Characterization_Of_Waste__c, Generate_Before_Final__c, Lab_Packs_Rate__c, Cylinders_Require_Evaluation__c, Manifest_And_Profile__c, Net_Due_Day__c, Applicable_Taxes_Quote__c,
                    Client_Is_Responsible__c, In_The_Event__c, Quote_Valid_30__c, Unless_Superseded__c
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

    //validate resource type
    @AuraEnabled
    public static String validateResourceType(String JSONTMLine) {
        try {
            TM_Line__c tmLine = (TM_Line__c)JSON.deserialize(JSONTMLine, TM_Line__c.class);
            List<TM__c> tms = TMsSelector.newInstance().selectByIds(new Set<Id>{ tmLine.TM__c });
            TMLLinesService.validateResourceType(tms[0], tmLine);
            return JSON.serialize(tmLine);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    //validate resource type

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
                task.ActivityDate = system.today().addDays(1);
                task.Description = 'Service Rating: ' + Integer.valueOf(rating.Rating__c) + ' stars\nCustomer Notes: ' + rating.Customer_Review__c;
                task.Status = 'Open';
                task.WhatId = rating.TM__c;
                insert task;
            }
        }
    }

    @AuraEnabled
    public static TM__c GetData(Id tmId) {
        return [SELECT Id, Name, Customer_Comments__c, Sales_Order__c,
                Service_Center__c, Service_Center__r.Id, Service_Center__r.Name, Job_Complete__c, Site_Email_Address__c,
                Field_TM_PDF_Sent__c, Field_TM_PDF_Saved__c, Field_TM_PDF_Recipient__c, Bill_to_Customer__r.Requires_2_Signatures_on_TM__c,
        (SELECT Id, Name, Category__c, Tax_Group__c,  Resource__c, Resource__r.Id, Resource__r.Name, Resource_Name__c,
                Resource__r.Description__c, Resource_Type__c, Resource_Type__r.Name, Service_Center__c, Service_Center__r.Id, Service_Center__r.Name,
                Job_Start_Time__c, Job_End_Time__c, Site_Start_Time__c, Site_End_Time__c, Lunch_Start_Time__c, Lunch_End_Time__c,
                Quantity__c, Unit_of_Measure__c, Unit_of_Measure__r.Id, Unit_of_Measure__r.Name,
                Description__c, Facility__c, Facility__r.Name, BOL_Manifest__c, Linked_Line__c, Linked_Line__r.Resource_Name__c, Resource_Type__r.Fleet_No_Required__c
        FROM TM_Lines__r) FROM TM__c WHERE Id = :tmId];
    }

    @AuraEnabled
    public static TM__c GetTMDetail(Id tmId) {
        try {
            List<TM__c> tms = [SELECT Id, Name, Scheduled_Date__c, Status__c, Customer_Po_No__c, Service_Center__c, Service_Center__r.Id, Service_Center__r.Name,
                    Sales_Order__c, Sales_Order__r.Name, Sales_Order__r.Sales_Order_Type__c, Sales_Order__r.Sales_Order_Type__r.Name, Sales_Order__r.Sales_Order_Type__r.Description__c,
                    Contact__c, Contact__r.Id, Contact__r.LastName, Contact__r.FirstName, Contact__r.Name, Site_Contact_2__c, Site_Contact_2__r.Name,
                    Bill_to_Customer__c, Bill_to_Customer__r.Name, Bill_to_Customer__r.BillingStreet, Bill_to_Customer__r.BillingCity, Bill_to_Customer__r.BillingStateCode, Bill_to_Customer__r.BillingPostalCode, Bill_to_Customer__r.BillingCountryCode,
                    Site_Name__c, Site_Street__c, Site_City__c, Site_State__c, Site_Postal_Code__c, Site_Country__c, Site_Phone_No__c, Site_Email_Address__c, Site_Scope__c,
                    Customer_Comments__c, Mobile_TM__c, Job_Complete__c, Bill_to_Customer__r.Requires_2_Signatures_on_TM__c
            FROM TM__c WHERE Id = :tmId];
            if (tms.size() > 0) {
                return tms[0];
            }
            return null;
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static Resource__c GetResource(Id serviceCenterId, Id resourceTypeId, String resourceNo) {
        List<Resource__c> resources = [SELECT Id, Name FROM Resource__c WHERE Service_Center__c = :serviceCenterId AND Resource_Type__c = :resourceTypeId AND Name = :resourceNo];
        if (resources.size() > 0) {
            return resources[0];
        }
        return null;
    }

    @AuraEnabled
    public static List<String> GetTermsAndConditions(Id soId) {
        List<String> terms = new List<String>();
        List<Sales_Order__c> sos = [SELECT Id, Payment_Term__r.Name, Any_Deviations__c, Shippable_Containers__c, First_Hour_Of_Loading__c, Overtime_Rate_Description__c, Rate_Time_Definitions__c, Charges_For_Labor__c,
                Waste_Disposal_And_Ancillary__c, Characterization_Of_Waste__c, Generate_Before_Final__c, Lab_Packs_Rate__c, Cylinders_Require_Evaluation__c, Manifest_And_Profile__c, Net_Due_Day__c, Applicable_Taxes_Quote__c,
                Client_Is_Responsible__c, In_The_Event__c, Quote_Valid_30__c, Unless_Superseded__c
        FROM Sales_Order__c WHERE Id =:soId];
        if (sos.size() > 0) {
            Sales_Order__c so = sos[0];
            if(so.Any_Deviations__c == true) {
                terms.add('This quoted estimate is provided based upon information provided by or gathered at customer’s location. Any deviations from this quotation will be invoiced based upon actual labor, materials, and/or disposal services provided by ACV and will be billed at a time and materials basis.');
            }
            if (so.Shippable_Containers__c == true) {
                terms.add('This quotation is contingent upon customer providing free and easy access to the work area. Drums/containers must be in DOT shippable containers.');
            }
            if (so.First_Hour_Of_Loading__c == true) {
                terms.add('"The first hour of loading/unloading is at no charge; thereafter, demurrage rates apply at $100.00 / hr.');
            }
            if (so.Overtime_Rate_Description__c == true) {
                terms.add('An overtime rate of 1.5 times the listed rate will be charged for hours worked over 8 hours in a day, all hours before 7:00am, after 3:30pm, on weekdays and all day Saturday. Double time will apply to all hours worked on Sunday and ACV Holidays. ACV Holidays include: New Year\'s Day, President\'s Day, Memorial Day, Independence Day, Labor Day, Thanksgiving Day,The day after Thanksgiving, and Christmas Day.');
            }
            if (so.Rate_Time_Definitions__c == true) {
                terms.add('Rate Time Definitions a. The day rate, where applicable, is defined as twelve hours. b. After 12 hours and up to 24 hours, the Hourly Rate will apply. If no Hourly Rate is stated in theRate sheet for an item, it will be calculated as the Day Rate divided by 12.');
            }
            if (so.Charges_For_Labor__c == true) {
                terms.add('Charges for labor and equipment will be invoiced on a portal to portal basis from start to completion of the job, for loading and unloading and mobilization and demobilization of equipment and materials. Minimum call out time is four hours per person and per piece of equipment. This includes onsite and offsite labor and equipment.');
            }
            if (so.Waste_Disposal_And_Ancillary__c == true) {
                terms.add('Waste disposal and/or ancillary supplies not listed on this quote will be quoted after a representative sample is obtained and an approved TSDF is located (for waste); Ancillary supplies required and used will be billed in accordance with ACV standard rates sheet.');
            }
            if (so.Characterization_Of_Waste__c == true) {
                terms.add('This quotation is based on the generator’s characterization of the waste and the ACV assigned Process Code. Waste materials that are received and do not conform to the assigned Process Code may be subject to re-coding and correction of charges.');
            }
            if (so.Generate_Before_Final__c == true) {
                terms.add('The invoice for work referenced above may be generated before final disposal information has been received. If your waste is classified as off-specification upon receipt, you will be notified, and an additional invoice will be generated for any unexpected costs.');
            }
            if (so.Lab_Packs_Rate__c == true) {
                terms.add('Lab packs rates do not include explosives, potentially explosive, radioactive, temperature sensitive or infectious material; ACV may furnish a separate quotation for any high-hazard work, if requested. ACV reserves the right to decline receipt of any material that cannot be disposed of in a lawful manner or if no legal disposal options exist.');
            }
            if (so.Cylinders_Require_Evaluation__c == true) {
                terms.add('Cylinders require evaluation and approval by an authorized ACV representative prior to shipment. Cylinders must be in DOT shippable condition, be marked with original stenciling, labels and/or tags, and valves must be operational. Cylinders not meeting ACV approval and the aforementioned conditions may be subject to additional charges.');
            }
            if (so.Manifest_And_Profile__c == true) {
                terms.add('Manifest and Profile preparation require a $25.00 dollar fee for the first waste product. An additional $5.00 dollar will be incurred for each additional waste product up to four total waste products per manifest or Bill of Lading. In addition, profile fees from disposal facilities are charged at invoice cost plus 30%.');
            }
            if (so.Net_Due_Day__c == true) {
                terms.add('Net due ' + so.Payment_Term__r.Name + ' days with prior credit approval unless modified by executed purchase order or contract. Finance charges of one and one half (1.5) percent per month will be due on payments past due after thirty days from date of invoice.');
            }
            if (so.Applicable_Taxes_Quote__c == true) {
                terms.add('Applicable Taxes, including local, state and federal taxes and/ or fees are not included in the quoted rates and will be applied to each invoice as applicable.');
            }
            if (so.Client_Is_Responsible__c == true) {
                terms.add('Client is responsible for time, material, and disposal charges to decontaminate utilized equipment if necessary. Said charges will be at ACV standard T&M rates and disposal cost plus 30%.');
            }
            if (so.In_The_Event__c == true) {
                terms.add('In the event legal or other action is required to collect unpaid invoice balances, Customer agrees to pay all costs of collection, including reasonable attorneys\' fees and agrees to the laws, jurisdiction, and venue of the state of New Jersey.');
            }
            if (so.Quote_Valid_30__c == true) {
                terms.add('This Quotation is valid for 30 days. Pricing is based on the current market capacity, conditions, and Government regulations. If a significant market-wide pricing, capacity or regulatory change affects our pricing, this quotation is subject to change.');
            }
            if (so.Unless_Superseded__c == true) {
                terms.add('Unless superseded by a fully executed agreement with terms that conflict, additional terms & conditions located at https://www.acvenviro.com/terms-and-conditions/ are hereby incorporated by reference and are agreed to and acknowledged by customer.');
            }
        }
        return terms;
    }

    @AuraEnabled
    public static void DeleteTMLine(Id tmlId) {
        try {
            delete [SELECT Id FROM TM_Line__c WHERE Id = :tmlId];
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void ChangeToScheduled(Id tmId) {
        Savepoint sp = Database.setSavepoint();
        try {
            TM__c tm = [SELECT Id, Status__c FROM TM__c WHERE Id = :tmId];
            if (tm.Status__c == 'Mobile Review') {
                tm.Status__c = 'Scheduled';
                update tm;
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
    public static TM__c SaveTM(String data) {
        Savepoint sp = Database.setSavepoint();
        try {
            TM__c tm = (TM__c)JSON.deserialize(data, TM__c.class);
            tm.Mobile_TM__c = true;
            update tm;

            return tm;
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static List<TM_Line__c> saveTMLines(String data) {
        Savepoint sp = database.setSavepoint();

        try {
            Set<Id> deletedRecIds = new Set<Id>();
            List<Object> lines = (List<Object>)JSON.deserializeUntyped(data);

            //fix subcontract line bug <<
            Company_Setup__c companySetup = CompanyMgmt.getCompanySetup();
            //fix subcontract line bug >>

            for (Integer i = 0 ; i < lines.size(); i++) {
                Object line = lines[i];
                Map<String, Object> fields = (Map<String, Object>)line;

                if ((Boolean)fields.get('Deleted') != true ) {
                    String category = (String)fields.get('Category__c');
                    //System.debug('*** category: ' + category);
                    if (category == 'Labor' || category == 'Equipment') {
                        //system.debug('*** resource type = ' + (String)fields.get('Resource_Type__c'));
                        if ((String)fields.get('Resource_Type__c') == null) {
                            fields.put('Deleted', true);
                        }
                    }
                    else if (category == 'Materials' || category == 'Waste Disposal') {
                        //system.debug('*** resource = ' + (String)fields.get('Resource__c'));
                        if ((String)fields.get('Resource__c') == null) {
                            fields.put('Deleted', true);
                        }
                    }
                }

                if ((Boolean)fields.get('Deleted') == true ) {
                    if (fields.get('Id') != null) {
                        deletedRecIds.add((Id)fields.get('Id'));
                    }

                    lines.remove(i);
                    i--;
                }
            }


            if (deletedRecIds.size() > 0) {
                delete [SELECT Id FROM TM_Line__c WHERE Id IN :deletedRecIds];
            }

            //List<TM_Line__c> tmls = (List<TM_Line__c>)JSON.deserialize(data, List<TM_Line__c>.class);
            List<TM_Line__c> tmls = (List<TM_Line__c>)JSON.deserialize(JSON.serialize(lines), List<TM_Line__c>.class);

            //fix subcontract line bug <<
            for (TM_Line__c tml : tmls) {
                if (tml.Category__c == 'Subcontractors' && tml.Resource__c == null) {
                    tml.Resource__c = companySetup.Default_Subcontractor_Resource__c;
                }
            }
            //fix subcontract line bug >>

            if (tmls.size() > 0) {
                List<TM__c> tms = [SELECT Id, Name, Tax_Area__c, Tax_Liable__c, Status__c,
                        From_Sales_Quote__c, Contract__c, Bill_to_Customer__c, Scheduled_Date__c, Emergency_TM__c,
                        Sales_Order__c, Sales_Order__r.Pay_Rule__c, Rate_Sheet__c,Service_Center__c, Contact__c,
                (SELECT Id, Line_No__c FROM TM_Lines__r ORDER BY Line_No__c DESC) FROM TM__c WHERE Id = :tmls[0].TM__c LIMIT 1];
                if (tms.size() == 0) {
                    throw new DataException('T&M ' + tmls[0].TM__c + ' is not found.');
                }

                TM__c tm = tms[0];
                Integer lastLineNo = 0;
                if (tm.TM_Lines__r.size() > 0) {
                    lastLineNo = tm.TM_Lines__r[0].Line_No__c.intValue();
                }

                for (Integer i = 0; i < tmls.size(); i++) {
                    TM_Line__c tml = tmls[i];
                    if (tml.Line_No__c == null) {
                        lastLineNo++;
                        tml.Line_No__c = lastLineNo;
                    }

                    if (tml.Id == null) { //init TM__r for calling functions from TMLLinesService
                        tml.TM__r = tm;
                    }
                }

                if (tmls.size() > 0) {
                    List<TM_Line__c> newTmls = new List<TM_Line__c>();
                    for (TM_Line__c tml : tmls) {
                        if (tml.Id == null) {
                            newTmls.add(tml);
                        }

                        //empty billing start time and end time to recaclulate the hours
                        if (tml.Category__c == 'Labor' || tml.Category__c == 'Equipment') {
                            tml.Billing_Start_Time__c = null;
                            tml.Billing_End_Time__c = null;
                        }
                    }

                    if (newTmls.size() > 0) { //validate for new lines only.
                        TMLLinesService.validateTMLinesResourceType(newTmls);
                        TMLLinesService.validateTMLinesUnitOfMeasure(newtmls);
                    }

                    TMLLinesService.validateTMLinesRestOfFields(tmls);

                    TMLLinesService.initStaticVariables(new Map<TM__c, List<TM_Line__c>>{tm => tmls});
                    for(TM_Line__c tmLine: tmls){
                        TMLLinesService.calcUnitPrice(tm, tmLine);
                        TMLLinesService.calcUnitCost(tm, tmLine);
                    }
                    TMLLinesService.calcTotals(new Map<TM__c, List<TM_Line__c>>{tm => tmls});
                    upsert tmls;
                }
                tm.Mobile_TM__c = true;
                update tm;
            }
            return tmls;
        }
        catch(exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            database.rollback(sp);
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static void processPdf(Id tmId) {
        try {
            List<TM__c> tms = [SELECT Name, Bill_to_Customer__r.Requires_2_Signatures_on_TM__c, Status__c, Mobile_TM__c,
                    Field_TM_PDF_Saved__c, Field_TM_PDF_Sent__c, Field_TM_PDF_Recipient__c,
                    Accept_Terms_and_Conditions__c, Customer_Not_Available__c FROM TM__c WHERE Id = :tmId];

            if (tms.size() == 0) {
                throw new DataException('TM ' + tmId + ' is not found.');
            }
            TM__c tm = tms[0];

            Integer signedCount = 0;
            Integer signatureRequestCount = 0;
            Integer customerNACount = 0;
            Boolean acceptTermsAndConditions = false;

            List<Signature__c> signatures = SignaturesSelector.newInstance().selectByRoles(new Set<Id>{ tm.Id }, new List<String>{ 'Customer A', 'Customer B' });
            for (Signature__c signature : signatures) {
                if (signature.Signed__c == true) {
                    signedCount++;
                } else if (signature.Request_Signature__c == true) {
                    signatureRequestCount++;
                } else if (signature.Customer_Not_Available__c == true) {
                    customerNACount++;
                }

                if (signature.Accept_Terms_and_Conditions__c == true) {
                    acceptTermsAndConditions = true;
                }
            }

            Integer signaturesNeeded = 1;
            if (tm.Bill_to_Customer__r.Requires_2_Signatures_on_TM__c == true) {
                signaturesNeeded = 2;
            }
            Boolean allSigned = (signedCount + customerNACount == signaturesNeeded);


            if (signatureRequestCount > 0) {
                sendSignatureRequestEmail(tm, signatures);
                if (tm.Status__c == 'Scheduled') {
                    tm.Status__c = 'Mobile Review';
                    tm.Mobile_TM__c = true;
                }
                tm.Signature_Request_Pending__c = true;
                update tm;
            }
            else {
                processFieldTMPDF(tm, signatures);

                tm.Accept_Terms_and_Conditions__c = acceptTermsAndConditions;
                if (tm.Status__c == 'Scheduled') {
                    tm.Status__c = 'Mobile Review';
                    tm.Mobile_TM__c = true;
                    update tm;
                }
            }
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public static void sendSignatureRequestEmail(TM__c tm, List<Signature__c> signatures) {
        Savepoint sp = Database.setSavepoint();
        try {
            if (getEmailDeliverability() != true) return;

            Set<Id> signatureIds = new Set<Id>();
            for (Signature__c signature : signatures) {
                signatureIds.add(signature.Id);
            }

            List<Signature__c> signaturesToRequest = [SELECT Id, Signature_Request__c, Email__c, Print_Name__c FROM Signature__c WHERE TM__c = :tm.Id AND Voided__c != TRUE
                AND Request_Signature__c = TRUE AND Signature_Request_Email_Sent__c != TRUE AND Signature_Request__r.Signed__c != TRUE];

            if (signaturesToRequest.size() > 0) {
                List<EmailTemplate> emailTemplates = [SELECT Id FROM EmailTemplate WHERE Name = 'T&M Signature Request Email'];
                if (emailTemplates.size() == 0) {
                    throw new DataException('Email template "T&M Signature Request Email" must be set up to send signature requests.');
                }
                Id emailTemplateId = emailTemplates[0].Id;

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
                }
                attachment.body = pdf;
                upsert attachment;

                List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
                for (Signature__c signature : signaturesToRequest) {
                    List<String> recipients = new List<String>{ signature.Email__c };
                    messages.add(createEmail(signature.Id, emailTemplateId, recipients, tm.Name, pdf));
                }

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
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    public static void processFieldTMPDF(TM__c tm, List<Signature__c> signatures) {
        Blob pdf = GenerateFieldTMPDF(tm.Id);

        if (tm.Field_TM_PDF_Saved__c != true) {
            SaveFieldTMPDF(tm, pdf);
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

    private static Blob GenerateFieldTMPDF(Id tmId) {
        Blob pdf;
        if (Test.isRunningTest()) {
            pdf = Blob.valueOf('test');
        } else {
            PageReference pageRef = new PageReference('/apex/TMFieldPDF2');
            pageRef.getParameters().put('id', tmId);
            pageRef.setRedirect(true);
            pdf = pageRef.getContent();
        }
        return pdf;
    }
    //signature request
    
    public static void SaveFieldTMPDF(TM__c tm, Blob pdf) {
        Savepoint sp = Database.setSavepoint();
        try {
            Attachment attachment;
            String filename = tm.Name + '_signature_request.pdf';
            List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :tm.Id AND Name = :filename];
            if (attachments.size() > 0) {
                attachment = attachments[0];
            }
            else {
                attachment = new Attachment(ParentId = tm.Id);
            }
            attachment.body = pdf;
            attachment.Name = tm.Name + ' ' + System.now().format('yyyy_MM_dd_hh_mm_ss') + '.pdf';
            upsert attachment;

            tm.Field_TM_PDF_Saved__c = true;
            CompanyMgmt.ByPassTrigger = true;
            update tm;
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    public static Messaging.SingleEmailMessage createEmail(Id whatId, Id emailTemplateId, List<String> recipients, String filename, Blob pdf) {
        Id prodOrgId = '00Df40000000Ns9';
        List<String> allowedSandboxRecipients = new List<String>();
        allowedSandboxRecipients.add('swang@micro-datanet.com');
        allowedSandboxRecipients.add('kchen@micro-datanet.com');
        allowedSandboxRecipients.add('kchen@goldfinchcloudsolutions.com');
        allowedSandboxRecipients.add('dscerbo@acvenviro.com');
        allowedSandboxRecipients.add('jmarcotte@acvenviro.com');
        allowedSandboxRecipients.add('rvandra@acvenviro.com');
        allowedSandboxRecipients.add('mrooney@acvenviro.com');
        allowedSandboxRecipients.add('mbrajer@acvenviro.com');
        allowedSandboxRecipients.add('ssheppard@acvenviro.com');

        if (!userInfo.getOrganizationId().contains(prodOrgId)) {
            for (String recipient : recipients) {
                if (!allowedSandboxRecipients.contains(recipient)) {
                    throw new DataException('Recipient email address "' + recipient + '" is not allowed in the sandbox. Email is not sent. Allowed email addresses: ' + String.join(allowedSandboxRecipients, '; '));
                }
            }
        }

        OrgWideEmailAddress orgWideEmailAddr = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'ACV Salesforce' LIMIT 1];

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
     */
}