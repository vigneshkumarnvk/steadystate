public with sharing class SignatureRequestController {
    private final ApexPages.StandardController standardController;
    public TM__c TM { set; get; }
    public List<Signature__c> Signatures { set; get; }
    public List<Signature__c> PendingSignatures { set; get; }

    public SignatureRequestController(ApexPages.StandardController controller) {
        this.standardController = controller;

        Set<Id> tmIds = new Set<Id>{ controller.getId() };
        this.Signatures = new List<Signature__c>();
        this.PendingSignatures = new List<Signature__c>();

        //ticket 21770 <<
        //List<TM__c> tms = TMsSelector.newInstance().selectByIds(tmIds);
        List<TM__c> tms = [SELECT Id, Name, Bill_to_Customer__c, Bill_to_Customer__r.Requires_2_Signatures_on_TM__c, Signature_Request_Pending__c,
                Site_Contact_2__r.Name, Site_Email_Address__c, Last_Signature_Request_Date__c
        FROM TM__c WHERE Id IN :tmIds];
        //ticket 21770 >>

        if (tms.size() == 0) {
            return;
        }
        this.TM = tms[0];

        //ticket 21770 <<
        Map<String, Signature__c> mapSignaturesByRole = new Map<String, Signature__c>();
        //ticket 21770 >>

        List<Signature__c> ss = SignaturesSelector.newInstance().selectByRoles(tmIds, new List<String>{ 'Customer A', 'Customer B' });
        for (Integer i = 0; i < ss.size(); i++) {
            Signature__c signature = ss[i];
            //ticket 21770 <<
            /*
            if (signature.Request_Signature__c == true && signature.Signed__c != true) {
                if (signature.Signature_Request__r.Signed__c != true) {
                    this.Signatures.add(signature);
                }
                else {
                    this.PendingSignatures.add(signature);
                }
            }
            */
            if (signature.Customer_Not_Available__c == true) {
                if (signature.Signature_Request__r != null) {
                    if (signature.Signature_Request__r.Signed__c != true) {
                        this.Signatures.add(signature);
                    }
                    else {
                        this.PendingSignatures.add(signature);
                    }
                }
                else {
                    this.Signatures.add(signature);
                }
            }
            mapSignaturesByRole.put(signature.Signer_Role__c, signature);
            //ticket t21770 >>
        }


        //ticket 21770 <<
        Boolean siteContactUsed = false;
        if (!mapSignaturesByRole.containsKey('Customer A')){
            Signature__c signature = new Signature__c();
            signature.Name = 'Customer A';
            signature.Signer_Role__c = 'Customer A';
            signature.TM__c = tm.Id;
            signature.Customer_Not_Available__c = true;
            if (tm.Site_Contact_2__r != null && tm.Site_Contact_2__r.Name != null) {
                signature.Print_Name__c = tm.Site_Contact_2__r.Name;
                siteContactUsed = true;
            }
            if (tm.Site_Email_Address__c != null) {
                signature.Email__c = tm.Site_Email_Address__c;
                siteContactUsed = true;
            }
            this.Signatures.add(signature);
        }

        Boolean requiresDualSignatures = false;
        List<Account> accounts = [SELECT Id, Requires_2_Signatures_on_TM__c FROM Account WHERE Id = :tm.Bill_to_Customer__c];
        if (accounts.size() > 0) {
            requiresDualSignatures = accounts[0].Requires_2_Signatures_on_TM__c;
        }
        if (requiresDualSignatures == true) {
            if (!mapSignaturesByRole.containsKey('Customer B')) {
                Signature__c signature = new Signature__c();
                signature.Name = 'Customer B';
                signature.Signer_Role__c = 'Customer B';
                signature.TM__c = tm.Id;
                signature.Customer_Not_Available__c = true;
                if (siteContactUsed != true) {
                    if (tm.Site_Contact_2__r != null && tm.Site_Contact_2__r.Name != null) {
                        signature.Print_Name__c = tm.Site_Contact_2__r.Name;
                    }
                    if (tm.Site_Email_Address__c != null) {
                        signature.Email__c = tm.Site_Email_Address__c;
                    }
                }
                this.Signatures.add(signature);
            }
        }
        //ticket 21770 >>
    }


    public PageReference sendSignatureRequestEmail() {
        Savepoint sp = Database.setSavepoint();
        try {
            for (Signature__c signature : this.Signatures) {
                if (signature.Customer_Not_Available__c == true && signature.Request_Signature__c != true
                        && signature.Print_Name__c != null && signature.Email__c != null && signature.Signed__c != true) {
                    signature.Request_Signature__c = true;
                }
            }

            CompanyMgmt.byPassTrigger = true;
            this.TM.Signature_Request_Pending__c = true;
            this.TM.Last_Signature_Request_Date__c = Datetime.now();
            update this.TM;
            CompanyMgmt.byPassTrigger = false;

            //ticket 21770 <<
            //update this.Signatures;
            upsert this.Signatures;
            //ticket 21770 >>
            //additional signature request changes >>
        
            sendSignatureRequestEmail(this.TM, this.Signatures);
            return this.standardController.view().setRedirect(true);
        }
        catch(exception ex) {
            Database.rollback(sp);
            ApexPages.addMessages(ex);
            return null;
        }
    }

    public static void sendSignatureRequestEmail(TM__c tm, List<Signature__c> signatures) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Id> requestIds = new List<Id>();
            for (Signature__c signature : signatures) {
                requestIds.add(signature.Signature_Request__c);
            }

            List<Id> siteAccessIds = new List<Id>();
            List<Signature_Request__c> signatureRequests = [SELECT Id, Site_Access__c FROM Signature_Request__c WHERE Id IN :requestIds AND Voided__c != TRUE];
            for (Signature_Request__c signatureRequest : signatureRequests) {
                signatureRequest.Request_Email_Sent__c = false;
                siteAccessIds.add(signatureRequest.Site_Access__c);
            }
            update signatureRequests;

            List<Site_Access__c> siteAccesses = [SELECT Id, Expiration_Date__c FROM Site_Access__c WHERE Id IN :siteAccessIds];
            for (Site_Access__c siteAccess : siteAccesses) {
                siteAccess.Expiration_Date__c = Datetime.now().addHours(48);
            }
            update siteAccesses;

            //ticket 21113 <<
            //Mobile_TMController.sendSignatureRequestEmail(tm, signatures);
            //MobileTMController.sendSignatureRequestEmail(tm, signatures);
            Blob pdf = MobileTMController.GenerateFieldTMPDF(tm.Id);
            MobileTMController.sendSignatureRequestEmail(tm, signatures, pdf);
            //ticket 21113 >>
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    public PageReference processSignatureAndEmail() {
        try {
            Id profileId = UserInfo.getProfileId();
            String profileName=[Select Id, Name from Profile where Id=:profileId].Name;
            if (profileName != 'System Administrator') {
                throw new DataException('You must be a system administrator to run this routine.');
            }

            //ticket 21113 <<
            /*
            processSignature(this.TM);
            processEmailAsync(this.TM.Id); //use async to allow pdf to generate with the updated signature
            */
            List<Signature_Request__c> signatureRequests = [SELECT Id FROM Signature_Request__c WHERE Related_To_Id__c =: this.standardController.getId() AND Voided__c != TRUE AND Signed__c = TRUE AND Processed__c != TRUE];
            SignatureProcessController.processCustomerSignaturesByDocument(signatureRequests);
            //ticket 21113 >>
            return this.standardController.view().setRedirect(true);
        }
        catch(exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }
    }

    @future(callout=true)
    public static void processEmailAsync(Id tmId) {
        List<TM__c> tms = TMsSelector.newInstance().selectByIds(new Set<Id>{ tmId });
        if (tms.size() == 0) {
            return;
        }
        TM__c tm = tms[0];
        processEmail(tm);
    }

    public static void processSignature(TM__c tm) {
        List<String> roles = new List<String>{
                'Customer A', 'Customer B'
        };
        
        //ticket 21770 <<
        /*
        List<Signature__c> signatures = [
                SELECT Id, Signed__c, Signature_Request__c, Signature_Request__r.Signed__c,
                (SELECT Id FROM Attachments)
                FROM Signature__c
                WHERE TM__c = :tm.Id AND Signer_Role__c IN :roles AND Voided__c != TRUE
                AND Request_Signature__c = TRUE AND Signed__c != TRUE
        ];
        */
        List<Signature__c> signatures = [
                    SELECT Id, Signed__c, Signature_Request__c, Signature_Request__r.Signed__c, Signature_Request__r.Signature_Date__c,
                    (SELECT Id FROM Attachments)
                    FROM Signature__c
                    WHERE TM__c = :tm.Id AND Signer_Role__c IN :roles AND Voided__c != TRUE
                    AND Request_Signature__c = TRUE AND Signed__c != TRUE
                    AND Signature_Request__r.Signed__c = TRUE AND Signature_Request__r.Signature_Pending__c = TRUE
            ];
        //ticket 21770 >>

        Savepoint sp = Database.setSavepoint();
        try {
            //if new signatures are received
            if (signatures.size() > 0) {
                Map<Id, Signature__c> mapSignaturesByRequestId = new Map<Id, Signature__c>();
                List<Id> requestIds = new List<Id>();
                for (Signature__c signature : signatures) {
                    if (signature.Signature_Request__r.Signed__c == true && signature.Signed__c != true) {
                        mapSignaturesByRequestId.put(signature.Signature_Request__c, signature);
                    }
                }

                //move the signature attachments to the signature records
                List<Attachment> attachments = new List<Attachment>();
                List<Signature__c> signaturesToUpdate = new List<Signature__c>();
                for (Attachment attachment : [SELECT Id, Name, ParentId, Body, ContentType, IsPrivate FROM Attachment WHERE ParentId IN :mapSignaturesByRequestId.keySet()]) {
                    if (mapSignaturesByRequestId.containsKey(attachment.ParentId)) {
                        Signature__c signature = mapSignaturesByRequestId.get(attachment.ParentId);

                        Attachment newAttachment = attachment.clone(false, false);

                        if (signature.Attachments.size() > 0) {
                            newAttachment.Id = signature.Attachments[0].Id;
                        }
                        else {
                            newAttachment.ParentId = signature.Id;
                        }
                        newAttachment.Name = 'customer signature';
                        attachments.add(newAttachment);

                        signature.Customer_Not_Available__c = false;
                        signature.Signed__c = true;
                        
                        //ticket 21770 <<
                        signature.Signature_Date__c = signature.Signature_Request__r.Signature_Date__c;
                        //ticket 21770 >>
                        
                        signaturesToUpdate.add(signature);
                    }
                }
                upsert attachments;
                update signaturesToUpdate;
            }
        } catch (exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    public static void processEmail(TM__c tm) {
        //check if all requested signatures are received
        List<String> roles = new List<String>{
                'Customer A', 'Customer B'
        };

        List<Signature__c> signatures = [
                SELECT Id, Signed__c, Signature_Request__c, Signature_Request__r.Signed__c
                FROM Signature__c
                WHERE TM__c = :tm.Id AND Signer_Role__c IN :roles AND Voided__c != TRUE
                AND Request_Signature__c = TRUE AND Signed__c != TRUE
        ];

        Integer signedCount = 0;
        for (Signature__c signature : signatures) {
            if (signature.Signed__c == true) {
                signedCount++;
            }
        }

        Savepoint sp = Database.setSavepoint();
        try {
            if (signedCount == signatures.size()) {
                tm.Signature_Request_Pending__c = false;
                update tm;
                processFieldTMPDF(tm.Id);
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    //@future(callout=true)
    public static void processFieldTMPDF(Id tmId) {
        List<TM__c> tms = [SELECT Name, Bill_to_Customer__r.Requires_2_Signatures_on_TM__c, Status__c,
                Field_TM_PDF_Saved__c, Field_TM_PDF_Sent__c, Field_TM_PDF_Recipient__c,
                Accept_Terms_and_Conditions__c, Customer_Not_Available__c FROM TM__c WHERE Id = :tmId];

        if (tms.size() == 0) {
            throw new DataException('TM ' + tmId + ' is not found.');
        }
        TM__c tm = tms[0];

        List<Signature__c> signatures = SignaturesSelector.newInstance().selectByRoles(new Set<Id>{ tm.Id }, new List<String>{ 'Customer A', 'Customer B' });

        //job task <<
        //Mobile_TMController.processFieldTMPDF(tm, signatures);
        MobileTMController.processFieldTMPDF(tm, signatures);
        //job task >>
    }
    //ticket 21113 <<
    @AuraEnabled
    public static String createQuoteSignatureRequest(Id quoteId) {
        Savepoint sp = Database.setSavepoint();
        try {
            Sales_Order__c quote = [SELECT Id, Name, Quote_Contact__r.Name, Quote_Contact__r.Email, Bill_to_Customer_No__r.Name, Payment_Term__r.Name,
                    CreatedDate,
                    Any_Deviations__c, Shippable_Containers__c, First_Hour_Of_Loading__c, Overtime_Rate_Description__c, Rate_Time_Definitions__c,
                    Charges_For_Labor__c, Term_Conditions_Opt20__c, Waste_Disposal_And_Ancillary__c, Characterization_Of_Waste__c, Generate_Before_Final__c,
                    Lab_Packs_Rate__c, Cylinders_Require_Evaluation__c, Manifest_And_Profile__c, Net_Due_Day__c, Applicable_Taxes_Quote__c,
                    Surcharge_Type__c, Client_Is_Responsible__c, In_The_Event__c, Quote_Valid_30__c, Unless_Superseded__c,
                    Service_Center__r.Quote_Introductory_Paragraph__c, Service_Center__r.Quote_Closing_Paragraph__c, Service_Center__r.Phone__c,
                            Service_Center__r.Term_Conditions_Opt1__c, Service_Center__r.Term_Conditions_Opt2__c, Service_Center__r.Term_Conditions_Opt3__c,
                    Service_Center__r.Term_Conditions_Opt4__c, Service_Center__r.Term_Conditions_Opt5__c, Service_Center__r.Term_Conditions_Opt6__c,
                    Service_Center__r.Term_Conditions_Opt7__c, Service_Center__r.Term_Conditions_Opt8__c, Service_Center__r.Term_Conditions_Opt9__c,
                    Service_Center__r.Term_Conditions_Opt10__c, Service_Center__r.Term_Conditions_Opt11__c, Service_Center__r.Term_Conditions_Opt12__c,
                    Service_Center__r.Term_Conditions_Opt13__c, Service_Center__r.Term_Conditions_Opt14__c, Service_Center__r.Term_Conditions_Opt15__c,
                    Service_Center__r.Term_Conditions_Opt16__c, Service_Center__r.Term_Conditions_Opt17__c, Service_Center__r.Term_Conditions_Opt18__c,
                    Service_Center__r.Term_Conditions_Opt19__c, Service_Center__r.Term_Conditions_Opt20__c, Customer_PO_No__c

                FROM Sales_Order__c WHERE Id = :quoteId LIMIT 1];
            if (quote.Quote_Contact__r == null || quote.Quote_Contact__r.Email == null) {
                throw new DataException('Quote contact email is required to request signature.');
            }

            //void old requests
            List<Signature_Request__c> signatureRequests = new List<Signature_Request__c>();
            List<Signature__c> signatures = [SELECT Id, Signature_Request__c FROM Signature__c WHERE Sales_Order__c = :quoteId AND Voided__c != TRUE];
            for (Signature__c signature : signatures) {
                signature.Voided__c = true;
                signature.Void_Reason__c = 'Voided by new signature request';

                if (signature.Signature_Request__c != null) {
                    Signature_Request__c signatureRequest = new Signature_Request__c();
                    signatureRequest.Id = signature.Signature_Request__c;
                    signatureRequest.Voided__c = true;
                    signatureRequests.add(signatureRequest);
                }
            }
            update signatures;
            update signatureRequests;

            //create a new request
            Signature_Request__c signatureRequest = new Signature_Request__c();
            signatureRequest.Print_Name__c = quote.Quote_Contact__r.Name;
            signatureRequest.Email__c = quote.Quote_Contact__r.Email;
            signatureRequest.Related_To_Object_Name__c = 'Sales_Order__c';
            signatureRequest.Related_To_Id__c = quote.Id;
            signatureRequest.Customer_PO_No__c = quote.Customer_PO_No__c;

            //terms and conditions <<
            String termsAndConditions = '<p><b>TERMS &amp; CONDITIONS</b></p><br/>';
            if (quote.Service_Center__r.Quote_Introductory_Paragraph__c != null) {
                termsAndConditions += '<p>' + quote.Service_Center__r.Quote_TC_Introductory_Paragraph__c + '</p><br/>';
            }
            else {
                termsAndConditions += '<p>Except where superseded by an existing service agreement between Customer and an Republic Services entity, the terms and conditions below apply to this quoted business proposal.</p><br/>';
            }
            termsAndConditions += '<ul>';

            if (quote.Any_Deviations__c) {
                termsAndConditions += '<li>';
                if (quote.Service_Center__r.Term_Conditions_Opt1__c != null) {
                    termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt1__c;
                }
                else {
                    termsAndConditions += 'This quoted estimate is provided based upon information provided by or gathered at customer\'s location. Services provided will be charged at no less than the estimate. Charges incurred that exceed the cost estimate will be invoiced based upon actual labor, materials, and/or disposal services provided by Republic Services and will be billed at a time and materials basis.';
                }
                termsAndConditions += '</li>';
            }

            if (quote.Shippable_Containers__c) {
                termsAndConditions += '<li>';
                if (quote.Service_Center__r.Term_Conditions_Opt2__c != null) {
                    termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt2__c;
                }
                else {
                    termsAndConditions += 'This Quote is contingent upon Customer providing free and easy access to the work area. Drums/containers must be in DOT shippable containers.';
                }
                termsAndConditions += '</li>';
            }

            if (quote.First_Hour_Of_Loading__c) {
                termsAndConditions += '<li>';
                if (quote.Service_Center__r.Term_Conditions_Opt3__c != null) {
                    termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt3__c;
                }
                else {
                    if (quote.CreatedDate >= Datetime.newInstance(2023, 7, 14, 0, 0, 0)) {
                        termsAndConditions += 'The first 15 minutes of loading/unloading is at no charge; thereafter, demurrage rates apply at $195.00 / hr.';
                    } else {
                        termsAndConditions += 'The first hour of loading/unloading is at no charge; thereafter, demurrage rates apply at $126.00 / hr.';
                    }
                        /*
                    else if (quote.CreatedDate >= Datetime.newInstance(2021, 7, 12, 0, 0, 0) && quote.CreatedDate < Datetime.newInstance(2023, 6, 1, 0, 0, 0)) {
                        termsAndConditions += 'The first hour of loading/unloading is at no charge; thereafter, demurrage rates apply at $126.00 / hr.';
                    }

                    else {
                        termsAndConditions += 'The first hour of loading/unloading is at no charge; thereafter, demurrage rates apply at $100.00 / hr.';
                    }
                         */
                }
                termsAndConditions += '</li>';
            }

            if (quote.Overtime_Rate_Description__c) {
                termsAndConditions += '<li>';
                if (quote.Service_Center__r.Term_Conditions_Opt4__c != null) {
                    termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt4__c;
                }
                else {
                    termsAndConditions += 'An overtime rate of 1.5 times the listed rate will be charged for hours worked over 8 hours in a day, all hours before 7:00 am, after 3:30pm, on weekdays and all day Saturday. Double time will apply to all hours worked on Sunday and Republic Services Holidays. Republic Services Holidays include:'
                        + '<div style="padding: 0 60px;">'
                        + 'New Year\'s Day, President\'s Day, Memorial Day, Independence Day, Labor Day, Thanksgiving Day, The day after Thanksgiving, and Christmas Day.'
                        + '</div>';
                }
                termsAndConditions += '</li>';
            }

            if (quote.Rate_Time_Definitions__c) {
                termsAndConditions += '<li>';
                if (quote.Service_Center__r.Term_Conditions_Opt5__c != null) {
                    termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt5__c;
                }
                else {
                    termsAndConditions += 'Rate Time Definitions'
                        + '<div>'
                        + 'a. The day rate, where applicable, is defined as twelve hours.'
                        + '</div>'
                        + '<div>'
                        + 'b. After 12 hours and up to 24 hours, the Hourly Rate will apply. If no Hourly Rate is stated in the Rate sheet for an item, it will be calculated as the Day Rate divided by 12.'
                        + '</div>';
                }
                termsAndConditions += '</li>';
            }

            if(quote.Charges_For_Labor__c) {
                termsAndConditions += '<li>';
                if (quote.Service_Center__r.Term_Conditions_Opt6__c != null) {
                    termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt6__c;
                }
                else {
                    termsAndConditions += 'Charges for labor and equipment will be invoiced on a portal to portal basis from start to completion of the job, for loading and unloading and mobilization and demobilization of equipment and materials. Minimum call out time is four hours per person and per piece of equipment. This includes on-site and off-site labor and equipment.';
                }
                termsAndConditions += '</li>';
            }


            if (quote.Term_Conditions_Opt20__c) {
                termsAndConditions += '<li>';
                if (quote.Service_Center__r.Term_Conditions_Opt20__c != null) {
                    termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt20__c;
                }
                else {
                    termsAndConditions += 'Bundled rate is based upon our best estimate of project duration inclusive of labor, equipment, and materials. Charges incurred that exceed the cost estimate will be billed to the Client in half day increments.';
                }
                termsAndConditions += '</li>';
            }

            if (quote.Waste_Disposal_And_Ancillary__c) {
                termsAndConditions += '<li>';
                if (quote.Service_Center__r.Term_Conditions_Opt7__c != null) {
                    termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt7__c;
                }
                else {
                    termsAndConditions += 'Waste disposal and/or ancillary supplies not listed on this quote will be quoted after a representative sample is obtained and an approved TSDF is located (for waste) Ancillary supplies required and used will be billed in accordance with Republic Services standard rates sheet.';
                }
                termsAndConditions += '</li>';
            }

            if (quote.Characterization_Of_Waste__c) {
                termsAndConditions += '<li>';
                if (quote.Service_Center__r.Term_Conditions_Opt8__c != null) {
                    termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt8__c;
                }
                else {
                    termsAndConditions += 'This quotation is based on the generator’s characterization of the waste and the Republic Services assigned Process Code. Waste materials that are received and do not conform to the assigned Process Code may be subject to re-coding and correction of charges.';
                }
                termsAndConditions += '</li>';
            }

            if (quote.Generate_Before_Final__c) {
                termsAndConditions += '<li>';
                if (quote.Service_Center__r.Term_Conditions_Opt9__c != null) {
                    termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt9__c;
                }
                else {
                    termsAndConditions += 'The invoice for work referenced above may be generated before final disposal information has been received. If your waste is classified as off-specification upon receipt, you will be notified, and an additional invoice will be generated for any unexpected costs.';
                }
                termsAndConditions += '</li>';
            }

            if (quote.Lab_Packs_Rate__c) {
                termsAndConditions += '<li>';
                if (quote.Service_Center__r.Term_Conditions_Opt10__c != null) {
                    termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt10__c;
                }
                else {
                    termsAndConditions += 'Lab packs rates do not include explosives, potentially explosive, radioactive, temperature sensitive or infectious material; Republic Services may furnish a separate quotation for any high-hazard work, if requested. Republic Services reserves the right to decline receipt of any material that cannot be disposed of in a lawful manner or if no legal disposal options exist.';
                }
                termsAndConditions += '</li>';
            }

            if (quote.Cylinders_Require_Evaluation__c) {
                termsAndConditions += '<li>';
                if (quote.Service_Center__r.Term_Conditions_Opt11__c != null) {
                    termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt11__c;
                }
                else {
                    termsAndConditions += 'Cylinders require evaluation and approval by an authorized Republic Services representative prior to shipment. Cylinders must be in DOT shippable condition, be marked with original stenciling, labels and/or tags, and valves must be operational.  Cylinders not meeting Republic Services approval and the aforementioned conditions may be subject to additional charges.';
                }
                termsAndConditions += '</li>';
            }

            if (quote.Manifest_And_Profile__c) {
                termsAndConditions += '<li>';
                if (quote.Service_Center__r.Term_Conditions_Opt12__c != null) {
                    termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt12__c;
                }
                else {
                    termsAndConditions += 'A manifest fee of $20.00 per manifest will be added to each invoice. Any additional fees from disposal facilities are charged at invoice cost plus 30%.';
                }
                termsAndConditions += '</li>';
            }

            if (quote.Net_Due_Day__c && quote.Payment_Term__r != null) {
                termsAndConditions += '<li>';
                termsAndConditions += 'Net due ' + quote.Payment_Term__r.Name.replace('D','') + ' ';
                if (quote.Service_Center__r.Term_Conditions_Opt13__c != null) {
                    termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt13__c;
                }
                else {
                    termsAndConditions += 'days with prior credit approval unless modified by executed purchase order or contract. Finance charges of one and one half (1.5) percent per month will be due on payments past due after thirty days from date of invoice.';
                }
                termsAndConditions += '</li>';
            }

            if (quote.Applicable_Taxes_Quote__c) {
                termsAndConditions += '<li>';
                if (quote.Service_Center__r.Term_Conditions_Opt14__c != null) {
                    termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt14__c;
                }
                else {
                    termsAndConditions += 'Applicable Taxes, including local, state and federal taxes and/ or fees are not included in the quoted rates and will be applied to each invoice as applicable.';
                }
                termsAndConditions += '</li>';
            }

            if (quote.Surcharge_Type__c != null) {
                termsAndConditions += '<li>';
                if (quote.Surcharge_Type__c == 'Fuel Surcharge') {
                    termsAndConditions += 'Due to uncontrollable fluctuating fuel costs a fuel surcharge will be billed only on equipment that requires fuel and all transportation charges, based on the Department of Energy on Highway Diesel Fuel Prices (National Average). Please ask Republic Services representative for current rate at time of work.';
                }
                if (quote.Surcharge_Type__c == 'EEC Fee') {
                    termsAndConditions += ' An EEC fee will be added to your services. EEC is an environmental, energy & compliance fee. The EEC fluctuates monthly and will be charged as a percentage of all invoiced charges, excluding taxes. For more information about this fee, please visit www.republicservices.com/customer-support/fee-disclosures.';
                }
                termsAndConditions += '</li>';
            }

            if (quote.Client_Is_Responsible__c) {
                termsAndConditions += '<li>';
                if (quote.Service_Center__r.Term_Conditions_Opt15__c != null) {
                    termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt15__c;
                }
                else {
                    termsAndConditions += 'Customer is responsible for time, material, and disposal charges to decontaminate utilized equipment if necessary. Said charges will be at Republic Services\' standard T&amp;M rates and disposal cost plus 30%.';
                }
                termsAndConditions += '</li>';
            }

            // if (quote.In_The_Event__c) {
            //     termsAndConditions += '<li>';
            //     if (quote.Service_Center__r.Term_Conditions_Opt16__c != null) {
            //         termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt16__c;
            //     }
            //     else {
            //         termsAndConditions += 'In the event legal or other action is required to collect unpaid invoice balances, Customer agrees to pay all costs of collection, including reasonable attorneys’ fees and agrees to the laws, jurisdiction, and venue of the state of New Jersey.';
            //     }
            //     termsAndConditions += '</li>';
            // }

            if (quote.Quote_Valid_30__c) {
                termsAndConditions += '<li>';
                if (quote.Service_Center__r.Term_Conditions_Opt17__c != null) {
                    termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt17__c;
                }
                else {
                    termsAndConditions += 'This Quote is valid for 30 days.  Pricing is based on the current market capacity, conditions, and Government regulations. If a significant market-wide pricing, capacity or regulatory change affects our pricing, this quote is subject to change.';
                }
                termsAndConditions += '</li>';
            }

            // if (quote.Unless_Superseded__c) {
            //     termsAndConditions += '<li>';
            //     if (quote.Service_Center__r.Term_Conditions_Opt18__c != null) {
            //         termsAndConditions += quote.Service_Center__r.Term_Conditions_Opt18__c;
            //     }
            //     else {
            //         termsAndConditions += 'Unless superseded by a fully executed agreement with terms that conflict, additional terms &amp; conditions located at https://www.republicservices.com/cms/documents/Environmental-Solutions/Environmental-Services-Terms-Conditions.pdf are hereby incorporated by reference and are agreed to and acknowledged by customer.';
            //     }
            //     termsAndConditions += '</li>';
            // }

            termsAndConditions += '</ul>';

            if (quote.Service_Center__r.Quote_Closing_Paragraph__c != null) {
                termsAndConditions += '<div>' + quote.Service_Center__r.Quote_Closing_Paragraph__c + '</div>';
            }
            else {
                termsAndConditions += '<div>Republic Services appreciates the opportunity to work for you. We sincerely look forward to performing this project. Should you have any questions, please do not hesitate to call me directly at ' + quote.Service_Center__r.Phone__c + '.</div>';
            }

            termsAndConditions += '<br/><p><b>QUOTE ACCEPTANCE</b></p><br/>';
            termsAndConditions += '<p>THE ADDRESSEE OF THIS QUOTE IS THE "CUSTOMER". ALL SERVICES PROVIDED UNDER THIS QUOTE ARE SUBJECT TO REPUBLIC SERVICES’ ENVIRONMENTAL SERVICES TERMS AND CONDITIONS (“SERVICE TERMS”) INCORPORATED HEREIN BY THIS REFERENCE AND LOCATED AT: www.RepublicServices.com/ServiceTermsES. A HARD COPY OF THE SERVICE TERMS WILL BE PROVIDED UPON REQUEST. BY EXECUTING THIS QUOTE OR RECEIVING THE SERVICES, CUSTOMER ACKNOWLEDGES THAT IT AUTHORIZES REPUBLIC SERVICES TO PROVIDE THE SERVICES AND THAT IT HAS READ AND AGREES TO BE BOUND BY THE SERVICE TERMS. IF CUSTOMER HAS A VALID CONTRACT WITH REPUBLIC SERVICES THAT INCLUDES THE SCOPE OF SERVICES HEREIN, THE TERMS OF SUCH CONTRACT SHALL PREVAIL IN THE EVENT OF ANY CONFLICTS WITH THE SERVICE TERMS. NO TERMS OR CONDITIONS ON ANY CUSTOMER-PROVIDED DOCUMENT OR RELATED TO CUSTOMER’S VENDOR SET UP PROCESS SHALL APPLY. THIS QUOTE AND THE SERVICE TERMS OR CONTRACT, AS APPLICABLE, CONTAIN THE ENTIRE AGREEMENT OF THE PARTIES RELATED TO THE SERVICES INCLUDED IN THIS QUOTE. CUSTOMER’S UNDERSIGNED REPRESENTATIVE WARRANTS THAT HE/SHE HAS AUTHORITY TO BIND CUSTOMER TO THIS QUOTE.</p>';

            signatureRequest.Terms_and_Conditions__c = termsAndConditions;
            //terms and conditions >>

            insert signatureRequest;


            //Site_Access__c siteAccess = SiteAccessController.createSiteAccess(signatureRequest.Id, 'TMSignature', Datetime.now().addHours(48));
            Integer tokenExpireHours = 48;
            if (CompanySettingUtil.acvSetting.Quote_Signature_Token_Expiration_Hours__c != null) {
                tokenExpireHours = CompanySettingUtil.acvSetting.Quote_Signature_Token_Expiration_Hours__c.intValue();
            }
            Site_Access__c siteAccess = SiteAccessController.createSiteAccess(signatureRequest.Id, 'TMSignature', Datetime.now().addHours(tokenExpireHours));

            signatureRequest.Site_Access__c = siteAccess.Id;
            update signatureRequest;

            Signature__c signature = new Signature__c();
            signature.Sales_Order__c = quote.Id;
            signature.Email__c = quote.Quote_Contact__r.Email;
            signature.Name = quote.Name;
            signature.Related_To_Id__c = quote.Id;
            signature.Print_Name__c = quote.Quote_Contact__r.Name;
            signature.Related_To_Object_Name__c = 'Sales_Order__c';
            signature.Request_Signature__c = true;
            signature.Signature_Request__c = signatureRequest.Id;
            signature.Signer_Role__c = 'Customer A';

            insert signature;

            signature = [SELECT Id, Related_To_Object_Name__c, Related_To_Id__c, Sales_Order__c, Signature_Request__c, Site_Access_Token__c FROM Signature__c WHERE Id = :signature.Id LIMIT 1];
            return JSON.serialize(signature);
        }
        catch (Exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void UpdateSignatureRequest(String JSONSignature) {
        Savepoint sp = Database.setSavepoint();
        try {
            Signature__c signature = (Signature__c)JSON.deserialize(JSONSignature, Signature__c.class);
            Signature_Request__c signatureRequest = new Signature_Request__c(Id = signature.Signature_Request__c);
            signatureRequest.Request_Date__c = Datetime.now();
            signatureRequest.Request_Email_Sent__c = true;
            signatureRequest.Request_Date__c = Datetime.now();
            update signatureRequest;

            if (signature.Related_To_Object_Name__c == 'Sales_Order__c') {
                Sales_Order__c quote = new Sales_Order__c();
                quote.Id = signature.Sales_Order__c;
                quote.Signature_Request_Pending__c = true;
                quote.Signature_Request_Status__c = 'Pending Acceptance';
                CompanyMgmt.byPassTrigger = true;
                update quote;
            }
        }
        catch (Exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage());
        }
    }
    //ticket 21113 >>
}