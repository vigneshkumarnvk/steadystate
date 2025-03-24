public with sharing class SignaturePadController {
    @AuraEnabled
    //signature request <<
    /*
    public static String getSignature(String relatedToId, String filename) {
        try {
            SignatureWrapper signatureWrapper;
            List<Signature__c> signatures = [SELECT Id, Name, Related_To_Object_Name__c, Related_To_Id__c, Print_Name__c, Accept_Terms_and_Conditions__c,
                    Signature_Date__c, Email__c, Customer_Not_Available__c FROM Signature__c WHERE Related_To_Id__c = :relatedToId AND Name = :filename AND Voided__c <> TRUE];
            if (signatures.size() > 0) {
                Signature__c signature =  signatures[0];
                signatureWrapper = new SignatureWrapper(signature);
                if (signatureWrapper.NotAvailable != true) {
                    List<Attachment> attachments = [SELECT Id, Name, ParentId, Body FROM Attachment WHERE ParentId = :signatureWrapper.Id AND Name = :filename];
                    if (attachments.size() > 0) {
                        signatureWrapper.SignatureData = EncodingUtil.base64Encode(attachments[0].Body);
                    }
                }
            }
            else {
                signatureWrapper = new SignatureWrapper();
                signatureWrapper.TMId = relatedToId;
                signatureWrapper.Name = filename;
            }
            return JSON.serialize(signatureWrapper);
        }
        catch(exception ex) {
            AuraHandledException auraHandledException = new AuraHandledException(ex.getMessage());
            auraHandledException.setMessage(ex.getMessage());
            throw auraHandledException;
        }
    }
    */
    public static String getSignature(String tmId, String role) {
        try {
            SignatureWrapper signatureWrapper = getSignatureWrapper(tmId, role);
            return JSON.serialize(signatureWrapper);
        }
        catch(exception ex) {
            AuraHandledException auraHandledException = new AuraHandledException(ex.getMessage());
            auraHandledException.setMessage(ex.getMessage());
            throw auraHandledException;
        }
    }

    public static SignatureWrapper getSignatureWrapper(String tmId, String role) {
        SignatureWrapper signatureWrapper;
        List<Signature__c> signatures = SignaturesSelector.newInstance().selectByRoles(new Set<Id>{ tmId }, new List<String>{ role });

        if (signatures.size() > 0) {
            Signature__c signature =  signatures[0];
            signatureWrapper = new SignatureWrapper(signature);
            if (signatureWrapper.NotAvailable != true) {
                List<Attachment> attachments = [SELECT Id, Name, ParentId, Body FROM Attachment WHERE ParentId = :signatureWrapper.SignatureId ORDER BY CreatedDate LIMIT 1];
                if (attachments.size() > 0) {
                    signatureWrapper.SignatureData = EncodingUtil.base64Encode(attachments[0].Body);
                }
            }
        }
        else {
            signatureWrapper = new SignatureWrapper();
            signatureWrapper.TMId = tmId;
            signatureWrapper.Name = signatureWrapper.Name;
            signatureWrapper.SignerRole = role;
            //default supervisor name
            if (role == 'Supervisor') {
                signatureWrapper.PrintName = UserInfo.getName();
            }
        }
        return signatureWrapper;
    }

    @AuraEnabled
    public static String saveSignature(String JSONSignatureWrapper) {
        Savepoint sp = Database.setSavepoint();
        try {
            SignatureWrapper signatureWrapper = (SignatureWrapper)JSON.deserialize(JSONSignatureWrapper, SignatureWrapper.Class);
            signatureWrapper.Name = signatureWrapper.SignerRole;

            Signature__c signature = signatureWrapper.toRecord();
            signature.Signature_Date__c = Datetime.now();
            upsert signature;

            if (signatureWrapper.SignatureData != null) {
                Attachment attachment;
                List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :signatureWrapper.SignatureId ORDER BY CreatedDate LIMIT 1];
                if (attachments.size() > 0) {
                    attachment = attachments[0];
                } else {
                    attachment = new Attachment();
                    attachment.ParentId = signature.Id;
                }
                attachment.Body = EncodingUtil.base64Decode(signatureWrapper.SignatureData);
                attachment.ContentType = 'image/png';
                attachment.Name = signatureWrapper.SignerRole;
                attachment.IsPrivate = false;
                upsert attachment;
            }


            if (signatureWrapper.RequestSignature == true) {
                Signature_Request__c signatureRequest = requestSignature(signatureWrapper);
                signature.Signature_Request__c = signatureRequest.Id;
                update signature;
            }
            else {
                if (signatureWrapper.SignatureRequestId != null) {
                    Signature_Request__c signatureRequest = new Signature_Request__c(Id = signatureWrapper.SignatureRequestId);
                    signatureRequest.Voided__c = true;
                    update signatureRequest;
                }
            }

            return getSignature(signatureWrapper.TMId, signatureWrapper.SignerRole);
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public static Signature_Request__c requestSignature(SignatureWrapper signatureWrapper) {
        Signature_Request__c xSignatureRequest;
        if (signatureWrapper.SignatureRequestId != null) {
            List<Signature_Request__c> signatureRequests = [SELECT Id, Site_Access__c FROM Signature_Request__c WHERE Id = :signatureWrapper.SignatureRequestId];
            if (signatureRequests.size() > 0) {
                xSignatureRequest = signatureRequests[0];
            }
        }

        Signature_Request__c signatureRequest = new Signature_Request__c();
        //ticket 21113 <<
        signatureRequest.Related_To_Object_Name__c = 'TM__c';
        signatureRequest.Related_To_Id__c = signatureWrapper.TMId;
        //ticket 21113 >>
        if (xSignatureRequest != null) {
            signatureRequest.Id = xSignatureRequest.Id;
            signatureRequest.Site_Access__c = xSignatureRequest.Site_Access__c;
        }
        signatureRequest.Print_Name__c = signatureWrapper.PrintName;
        signatureRequest.Email__c = signatureWrapper.Email;

        //ticket 21770 <<
        TM__c tm = [SELECT Id, Sales_Order__r.Any_Deviations__c, Sales_Order__r.Shippable_Containers__c, Sales_Order__r.First_Hour_Of_Loading__c, Sales_Order__r.Overtime_Rate_Description__c,
                Sales_Order__r.Rate_Time_Definitions__c, Sales_Order__r.Charges_For_Labor__c, Sales_Order__r.Waste_Disposal_And_Ancillary__c, Sales_Order__r.Characterization_Of_Waste__c,
                Sales_Order__r.Generate_Before_Final__c, Sales_Order__r.Lab_Packs_Rate__c, Sales_Order__r.Cylinders_Require_Evaluation__c, Sales_Order__r.Manifest_And_Profile__c,
                Sales_Order__r.Net_Due_Day__c, Sales_Order__r.Applicable_Taxes_Quote__c, Sales_Order__r.Client_Is_Responsible__c, Sales_Order__r.In_The_Event__c, Sales_Order__r.Quote_Valid_30__c,
                Sales_Order__r.Unless_Superseded__c, Sales_Order__r.Payment_Term__r.Name, Sales_Order__r.Term_Conditions_Opt20__c
        FROM TM__c WHERE Id = :signatureWrapper.TMId LIMIT 1];
        String htmlTermsAndConditions = '<ul class="slds-list--dotted">';
        if (tm.Sales_Order__r.Any_Deviations__c) {
            htmlTermsAndConditions += '<li>This quoted estimate is provided based upon information provided by or gathered at customer’s location. Services provided will be charged at no less than the estimate. Charges incurred that exceed the cost estimate will be invoiced based upon actual labor, materials, and/or disposal services provided by Republic Services and will be billed at a time and materials basis.</li>';
        }
        if (tm.Sales_Order__r.Shippable_Containers__c) {
            htmlTermsAndConditions += '<li>This Quote is contingent upon Customer providing free and easy access to the work area. Drums/containers must be in DOT shippable containers.</li>';
        }
        if (tm.Sales_Order__r.First_Hour_Of_Loading__c) {
            htmlTermsAndConditions += '<li>The first 15 minutes of loading/unloading is at no charge; thereafter, demurrage rates apply at $195.00 / hr.</li>';
        }
        if (tm.Sales_Order__r.Overtime_Rate_Description__c) {
            htmlTermsAndConditions += '<li>An overtime rate of 1.5 times the listed rate will be charged for hours worked over 8 hours in a day, all hours before 7:00am, after 3:30pm, on weekdays and all day Saturday. Double time will apply to all hours worked on Sunday and Republic Services Holidays. Republic Services Holidays include: New Year\'s Day, President\'s Day, Memorial Day, Independence Day, Labor Day, Thanksgiving Day,The day after Thanksgiving, and Christmas Day.</li>';
        }
        if (tm.Sales_Order__r.Rate_Time_Definitions__c) {
            htmlTermsAndConditions += '<li>Rate Time Definitions a. The day rate, where applicable, is defined as twelve hours. b. After 12 hours and up to 24 hours, the Hourly Rate will apply. If no Hourly Rate is stated in theRate sheet for an item, it will be calculated as the Day Rate divided by 12.</li>';
        }
        if (tm.Sales_Order__r.Charges_For_Labor__c) {
            htmlTermsAndConditions += '<li>Charges for labor and equipment will be invoiced on a portal to portal basis from start to completion of the job, for loading and unloading and mobilization and demobilization of equipment and materials. Minimum call out time is four hours per person and per piece of equipment. This includes onsite and offsite labor and equipment.</li>';
        }
        if (tm.Sales_Order__r.Term_Conditions_Opt20__c) {
            htmlTermsAndConditions += '<li>Bundled rate is based upon our best estimate of project duration inclusive of labor, equipment, and materials. Charges incurred that exceed the cost estimate will be billed to the Client in half day increments.</li>';
        }
        if (tm.Sales_Order__r.Waste_Disposal_And_Ancillary__c) {
            htmlTermsAndConditions += '<li>Waste disposal and/or ancillary supplies not listed on this quote will be quoted after a representative sample is obtained and an approved TSDF is located (for waste); Ancillary supplies required and used will be billed in accordance with Republic Services standard rates sheet.</li>';
        }
        if (tm.Sales_Order__r.Characterization_Of_Waste__c) {
            htmlTermsAndConditions += '<li>This Quote is based on the generator’s characterization of the waste and the Republic Services assigned Process Code. Waste materials that are received and do not conform to the assigned Process Code may be subject to re-coding and correction of charges.</li>';
        }
        if (tm.Sales_Order__r.Generate_Before_Final__c) {
            htmlTermsAndConditions += '<li>The invoice for work referenced above may be generated before final disposal information has been received. If your waste is classified as off-specification upon receipt, you will be notified, and an additional invoice will be generated for any unexpected costs.</li>';
        }
        if (tm.Sales_Order__r.Lab_Packs_Rate__c) {
            htmlTermsAndConditions += '<li>Lab packs rates do not include explosives, potentially explosive, radioactive, temperature sensitive or infectious material; Republic Services may furnish a separate quotation for any high-hazard work, if requested. Republic Services reserves the right to decline receipt of any material that cannot be disposed of in a lawful manner or if no legal disposal options exist.</li>';
        }
        if (tm.Sales_Order__r.Cylinders_Require_Evaluation__c) {
            htmlTermsAndConditions += '<li>Cylinders require evaluation and approval by an authorized Republic Services representative prior to shipment. Cylinders must be in DOT shippable condition, be marked with original stenciling, labels and/or tags, and valves must be operational. Cylinders not meeting Republic Services approval and the aforementioned conditions may be subject to additional charges.</li>';
        }
        if (tm.Sales_Order__r.Manifest_And_Profile__c) {
            htmlTermsAndConditions += '<li>Manifest and Profile preparation require a $25.00 dollar fee for the first waste product. An additional $5.00 dollar will be incurred for each additional waste product up to four total waste products per manifest or Bill of Lading. In addition, profile fees from disposal facilities are charged at invoice cost plus 30%.</li>';
        }
        if (tm.Sales_Order__r.Net_Due_Day__c) {
            htmlTermsAndConditions += '<li>Net due ' + tm.Sales_Order__r.Payment_Term__r.Name + ' days with prior credit approval unless modified by executed purchase order or contract. Finance charges of one and one half (1.5) percent per month will be due on payments past due after thirty days from date of invoice.</li>';
        }
        if (tm.Sales_Order__r.Applicable_Taxes_Quote__c) {
            htmlTermsAndConditions += '<li>Applicable Taxes, including local, state and federal taxes and/ or fees are not included in the quoted rates and will be applied to each invoice as applicable.</li>';
        }
        if (tm.Sales_Order__r.Client_Is_Responsible__c) {
            htmlTermsAndConditions += '<li>Client is responsible for time, material, and disposal charges to decontaminate utilized equipment if necessary. Said charges will be at Republic Services\' standard T&amp;M rates and disposal cost plus 30%.</li>';
        }
        if (tm.Sales_Order__r.In_The_Event__c) {
            htmlTermsAndConditions += '<li>In the event legal or other action is required to collect unpaid invoice balances, Customer agrees to pay all costs of collection, including reasonable attorneys\' fees and agrees to the laws, jurisdiction, and venue of the state of New Jersey.</li>';
        }
        if (tm.Sales_Order__r.Quote_Valid_30__c) {
            htmlTermsAndConditions += '<li>This Quote is valid for 30 days. Pricing is based on the current market capacity, conditions, and Government regulations. If a significant market-wide pricing, capacity or regulatory change affects our pricing, this quote is subject to change.</li>';
        }
        if (tm.Sales_Order__r.Unless_Superseded__c) {
            htmlTermsAndConditions += '<li>Unless superseded by a fully executed agreement with terms that conflict, additional terms &amp; conditions located at https://www.republicservices.com/cms/documents/Environmental-Solutions/Environmental-Services-Terms-Conditions.pdf are hereby incorporated by reference and are agreed to and acknowledged by customer.</li>';
        }
        htmlTermsAndConditions += '</ul>';
        signatureRequest.Terms_and_Conditions__c = htmlTermsAndConditions;
        //ticket 21770 >>

        upsert signatureRequest;


        //ticket 21113 <<
        Integer tokenExpireHours = 48; // hours
        if (CompanySettingUtil.acvSetting.TM_Signature_Token_Expiration_Hours__c != null) {
            tokenExpireHours = CompanySettingUtil.acvSetting.TM_Signature_Token_Expiration_Hours__c.intValue();
        }
        //ticket 21113 >>

        if (signatureRequest.Site_Access__c == null) {
            //ticket 21113 <<
            //Site_Access__c siteAccess = SiteAccessController.createSiteAccess(signatureRequest.Id, 'TMSignature', Datetime.now().addHours(48));
            Site_Access__c siteAccess = SiteAccessController.createSiteAccess(signatureRequest.Id, 'TMSignature', Datetime.now().addHours(tokenExpireHours));
            //ticket 21113 >>
            signatureRequest.Site_Access__c = siteAccess.Id;
            update signatureRequest;
        }
        else {
            Site_Access__c siteAccess = [SELECT Id FROM Site_Access__c WHERE Id = :signatureRequest.Site_Access__c LIMIT 1];
            //ticket 21113 <<
            //siteAccess.Expiration_Date__c = Datetime.now().addHours(48);
            siteAccess.Expiration_Date__c = Datetime.now().addHours(tokenExpireHours);
            //ticket 21113 >>
            update siteAccess;
        }

        return signatureRequest;
    }
}