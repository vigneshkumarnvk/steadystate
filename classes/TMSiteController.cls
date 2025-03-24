public without sharing class TMSiteController {
    @AuraEnabled
    public static String getSignature(String token) {
        try {
            Site_Access__c siteAccess = SiteAccessController.getSiteAccess('TMSignature', token);
            if (siteAccess == null) {
                throw new DataException('You don\'t have access to this page or your token has expired. Please contact Republic Services customer service for assistance.');
            }

            //ticket 21770 <<
            //List<Signature_Request__c> signatureRequests = [SELECT Id, Print_Name__c, Email__c, Accept_Terms_and_Conditions__c, Signed__c, Signature_Date__c, Site_Access_Token__c FROM Signature_Request__c WHERE Site_Access__r.Token__c = :token];
            //ticket 21113 <<
            //List<Signature_Request__c> signatureRequests = [SELECT Id, Print_Name__c, Email__c, Accept_Terms_and_Conditions__c, Terms_and_Conditions__c, Signed__c, Signature_Date__c, Site_Access_Token__c FROM Signature_Request__c WHERE Site_Access__r.Token__c = :token];
            List<Signature_Request__c> signatureRequests = [SELECT Id, Related_To_Object_Name__c, Related_To_Id__c, Print_Name__c, Email__c, Accept_Terms_and_Conditions__c, Terms_and_Conditions__c, Signed__c, Signature_Date__c, Site_Access_Token__c, Declined__c, Customer_PO_No__c, Customer_Comment__c FROM Signature_Request__c WHERE Site_Access__r.Token__c = :token AND Voided__c != TRUE];
            //ticket 21113 >>
            //ticket 21770 >> 

            if (signatureRequests.size() > 0) {
                Signature_Request__c signatureRequest = signatureRequests[0];
                SignatureWrapper signatureWrapper = new SignatureWrapper();
                signatureWrapper.AcceptTerms = signatureRequest.Accept_Terms_and_Conditions__c;
                signatureWrapper.PrintName = signatureRequest.Print_Name__c;
                signatureWrapper.Email = signatureRequest.Email__c;
                signatureWrapper.SiteAccessToken = signatureRequest.Site_Access_Token__c;
                signatureWrapper.Signed = signatureRequest.Signed__c;
                signatureWrapper.SignatureDate = signatureRequest.Signature_Date__c;

                //ticket 21113 <<
                signatureWrapper.RelatedToId = signatureRequest.Related_To_Id__c;
                signatureWrapper.RelatedToObjectName = signatureRequest.Related_To_Object_Name__c;
                signatureWrapper.Declined = signatureRequest.Declined__c;
                signatureWrapper.CustomerPONo = signatureRequest.Customer_PO_No__c;
                signatureWrapper.CustomerComment = signatureRequest.Customer_Comment__c;
                //ticket 21113 >>

                //ticket 21770 <<
                if (signatureRequests[0].Terms_and_Conditions__c != null) {
                    signatureWrapper.TermsAndConditions = signatureRequests[0].Terms_and_Conditions__c;
                }
                //ticket 21770 >>
                List<Attachment> attachments = [SELECT Id, Name, ParentId, Body FROM Attachment WHERE ParentId = :signatureRequest.Id];
                if (attachments.size() > 0) {
                    signatureWrapper.SignatureData = EncodingUtil.base64Encode(attachments[0].Body);
                }

                return JSON.serialize(signatureWrapper);
            }
            else {
                //ticket 21113 <<
                //throw new DataException('System is unable to locate the request record for you. Please contact Republic Services customer service for assistance.');
                throw new DataException('The signature request is no longer valid. Please contact Republic Services customer service for assistance.');
                //ticket 21113 >>
            }
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String saveSignature(String JSONSignatureWrapper) {
        Savepoint sp = Database.setSavepoint();
        try {
            SignatureWrapper signatureWrapper = (SignatureWrapper)JSON.deserialize(JSONSignatureWrapper, SignatureWrapper.Class);

            List<Signature_Request__c> signatureRequests = [SELECT Id FROM Signature_Request__c WHERE Site_Access_Token__c = :signatureWrapper.SiteAccessToken];

            if (signatureRequests.size() > 0) {
                Signature_Request__c signatureRequest = signatureRequests[0];
                signatureRequest.Signature_Date__c = Datetime.now();

                //ticket 21113 <<
                //signatureRequest.Signed__c = true;
                signatureRequest.Declined__c = signatureWrapper.Declined;
                signatureRequest.Customer_PO_No__c = signatureWrapper.CustomerPONo;
                signatureRequest.Customer_Comment__c = signatureWrapper.CustomerComment;
                if (signatureWrapper.Declined == true) {
                    signatureWrapper.Signed = false;
                }
                else {
                    signatureWrapper.Signed = true;
                }
                signatureRequest.Signed__c = signatureWrapper.Signed;
                //ticket 21113 >>

                //additional signature request changes <<
                signatureRequest.Signature_Pending__c = true;
                signatureRequest.PDF_Email_Pending__c = true;
                //additional signature request changes >>
                signatureRequest.Accept_Terms_and_Conditions__c = signatureWrapper.AcceptTerms;
                signatureRequest.Print_Name__c = signatureWrapper.PrintName;
                signatureRequest.Email__c = signatureWrapper.Email;
                signatureRequest.IP_Address__c = signatureWrapper.IPAddress;
                update signatureRequest;

                if (signatureWrapper.SignatureData != null) {
                    Attachment attachment;
                    List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :signatureRequest.Id LIMIT 1];
                    if (attachments.size() > 0) {
                        attachment = attachments[0];
                    } else {
                        attachment = new Attachment();
                        attachment.ParentId = signatureRequest.Id;
                    }
                    attachment.Body = EncodingUtil.base64Decode(signatureWrapper.SignatureData);
                    attachment.ContentType = 'image/png';
                    attachment.Name = 'customer signature';
                    attachment.IsPrivate = false;
                    upsert attachment;
                }
            }
            return getSignature(signatureWrapper.SiteAccessToken);
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage());
        }
    }
}