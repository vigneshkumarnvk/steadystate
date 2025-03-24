/*
* Class Name: FileUploadHandler
* Summary  : Apex class for Merge and generate documents

* Modification Log :
 * Developer                 Date                   Description
--------------------------------------------------------------------------------------------------------------               
Sathish Rosekumar           01/10/2024              75108 - Merge document based on the user selection document type
Sanjana						01/10/2024				63067 - Added a field on content version query
Sathish Rosekumar			02/28/2024				78085 - restrict the document upload 
Sathish Rosekumar			03/15/2024				80070 - restrict the document upload upto 985kb 
*************************************************************************************************************/
public with sharing class FileUploadHandler {

    @AuraEnabled
    public static List<ContentVersion> getRelatedFiles(Id parentId){
        Set<Id> contentDocIds = new Set<Id>();
        for(ContentDocumentLink cntLink: [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: parentId]){
            contentDocIds.add(cntLink.ContentDocumentId);
        }
        if(contentDocIds.size() > 0){
            //ticket 19127 <<
            //return [SELECT Id, Title, ContentDocumentId, FileExtension FROM ContentVersion WHERE ContentDocumentId IN :contentDocIds];
            return [SELECT Id, Title, ContentDocumentId, FileExtension,Document_Type_fileupload__c,VersionData FROM ContentVersion WHERE ContentDocumentId IN :contentDocIds ORDER BY CreatedDate DESC];
            //ticket 19127 >>
        } else {
            return null;
        }
    }

    //ticket 19127 <<
    @AuraEnabled
    public static List<Sales_Invoice_Job_Task__c> getJobTasks(Id recordId){
        try {
            List<Sales_Invoice_Job_Task__c> jobTasks = [SELECT Id, Name, Task_No__c, Invoice_Format__c, Print_Order__c FROM Sales_Invoice_Job_Task__c WHERE Sales_Invoice__c = :recordId];
            return jobTasks;
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void saveInvoiceFormat(String JSONJobTasks) {
        try {
            System.debug(JSONJobTasks);
            Set<Decimal> printOrders = new Set<Decimal>();
            List<Sales_Invoice_Job_Task__c> jobTasks = (List<Sales_Invoice_Job_Task__c>)JSON.deserialize(JSONJobTasks, List<Sales_Invoice_Job_Task__c>.class);
            List<Sales_Invoice_Job_Task__c> jobTasksToUpdate = new List<Sales_Invoice_Job_Task__c>();
            for (Sales_Invoice_Job_Task__c jobTask : jobTasks) {
                if(jobTask.Print_Order__c != null) {
                    if (printOrders.contains(jobTask.Print_Order__c)) {
                        throw new DataException('ERROR: There are more than one job task assigned with Print Order ' + jobTask.Print_Order__c + ', please update the print order to continue!');
                    } else {
                        printOrders.add(jobTask.Print_Order__c);
                    }
                }
                jobTasksToUpdate.add(new Sales_Invoice_Job_Task__c(Id = jobTask.Id, Invoice_Format__c = jobTask.Invoice_Format__c, Print_Order__c = jobTask.Print_Order__c));
            }
            CompanyMgmt.byPassTrigger = true;
            update jobTasksToUpdate;
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    //ticket 19127 >>


    //ticket 19127 <<
    /*
    @AuraEnabled
    public static String generateAndSaveDocument(Id recordId, String invoiceType){
        try{
            String fileName = '';
            fileName = createAndSaveInvoicePDF(recordId, invoiceType);
            return fileName;
        } catch (Exception e){
            System.debug('Error: ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    */

    //ticket 21113 <<
    /*
    @AuraEnabled
    public static String generateAndSaveDocument(Id recordId){
        try{
            String fileName = '';
            fileName = createAndSaveInvoicePDF(recordId);
            return fileName;
        } catch (Exception e){
            //System.debug('Error: ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    */
    @AuraEnabled
    public static String generateAndSaveDocument(Id recordId, String reportName, String JSONReportParams, String fileName) {
        try {
            Map<String, String> params = (Map<String, String>)JSON.deserialize(JSONReportParams, Map<String, String>.class);
            return generatePDF(recordId, reportName, params, fileName);
        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    //ticket 21113 >>
    //ticket 19127 >>

    @AuraEnabled
    public static void processUploadedDocuments(String uploadedFileResponse,String documentType){
        try{
            JSONParser parser = JSON.createParser(uploadedFileResponse);
            Set<Id> contentDocumentIds = new Set<Id>();
            while(parser.nextToken() != null){
               
                if(parser.getText() == 'documentId'){
                    parser.nextToken();
                    system.debug('Token+++++++'+parser.getText());
                    contentDocumentIds.add(parser.getText());
                }
            }
            List<ContentVersion> contentVersions = [SELECT Id, Title FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds];
            for(ContentVersion contentVersion: contentVersions){
                contentVersion.Document_Type_fileupload__c = documentType;
                createContentDistribution(contentVersion.Title, contentVersion.Id);
            }
            if(!contentVersions.isEmpty()) {
                update contentVersions;
            }
        } 
        catch (Exception e){
            System.debug('Error: ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    //ticket 21113 << replace this function with the generic function "generatePDF"
    /*
    //ticket 19127 <<
    //private static String createAndSaveInvoicePDF(Id invoiceId, String invoiceType){
    private static String createAndSaveInvoicePDF(Id invoiceId){
        //ticket 19127 >>
        try{
            Blob fileContent;
            Sales_Invoice__c salesInvoice = [SELECT Id, Name FROM Sales_Invoice__c WHERE Id =: invoiceId LIMIT 1];
            PageReference pdf = new PageReference('/apex/NewSalesInvoicePDF');
            pdf.getParameters().put('id', invoiceId);
            //if(1==1) throw new DataException('invoiceType ' + invoiceType);
            //System.debug('Info createAndSaveInvoicePDF print Type: ' + invoiceType);
            //ticket 19127 <<
            //pdf.getParameters().put('InvoiceType', invoiceType);
            //ticket 19127 >>
            pdf.setRedirect(true);
            //ticket 19127 <<
            //fileContent = pdf.getContent();
            if (test.isRunningTest()) {
                fileContent = Blob.valueOf('pdf');
            }
            else {
                fileContent = pdf.getContent();
            }
            //ticket 19127 >>

            String fileName = 'Invoice#' + salesInvoice.Name + '_' + System.now().format('yyyyMMddhhmmss') + '.pdf';
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.ContentLocation = 'S';  //S specify this document is in SF, use E for external files
            contentVersion.PathOnClient = fileName;
            contentVersion.Title = fileName;
            contentVersion.VersionData = fileContent;
            insert contentVersion;

            //Link Content Version to content document
            Id contentDcouemntId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:contentVersion.Id].ContentDocumentId;
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = contentDcouemntId;
            contentDocumentLink.LinkedEntityId = salesInvoice.Id;
            contentDocumentLink.ShareType = 'I';
            //contentDocumentLink.Visibility = 'InternalUsers';
            insert contentDocumentLink;

            //generate public link
            createContentDistribution(fileName, contentVersion.Id);

            return fileName;
        } catch (Exception e){
            System.debug('Error: ' + e.getStackTraceString());
            throw e;
        }
    }
    */
    //ticket 21113 >>

    //ticket 21113 <<
    private static String generatePDF(Id recordId, String vfPageName, Map<String, String> params, String fileName){
        Savepoint sp = Database.setSavepoint();
        try{
            Blob fileContent;
            SObject record = Database.query('SELECT Id, Name FROM ' + recordId.getSobjectType().getDescribe().getName() + ' WHERE Id = :recordId LIMIT 1');
            PageReference pdf = new PageReference('/apex/' + vfPageName);
            pdf.getParameters().putAll(params);
            pdf.setRedirect(true);
            if (test.isRunningTest()) {
                fileContent = Blob.valueOf('pdf');
            }
            else {
                fileContent = pdf.getContent();
            }

            fileName += '_' + System.now().format('yyyyMMddhhmmss') + '.pdf';

            ContentVersion contentVersion = new ContentVersion();
            contentVersion.ContentLocation = 'S';  //S specify this document is in SF, use E for external files
            contentVersion.PathOnClient = fileName;
            contentVersion.Title = fileName;
            contentVersion.VersionData = fileContent;
            insert contentVersion;

            //Link Content Version to content document
            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:contentVersion.Id].ContentDocumentId;
            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.ContentDocumentId = contentDocumentId;
            contentDocumentLink.LinkedEntityId = record.Id;
            contentDocumentLink.ShareType = 'I';
            insert contentDocumentLink;

            //generate public link
            createContentDistribution(fileName, contentVersion.Id);

            return contentDocumentId;
        } catch (Exception ex){
            Database.rollback(sp);
            throw ex;
        }
    }
    //ticket 21113 >>

    @AuraEnabled
    public static String mergeDocuments(Id recordId, String contentDocumentIds, String documentType){
        try{
            JSONParser parser = JSON.createParser(contentDocumentIds);
            Map<Integer, String> contentDocumentByOrder = new Map<Integer, String>();
            while(parser.nextToken() != null){
                if(parser.getCurrentToken() == JSONToken.FIELD_NAME){
                    Integer keyValue = Integer.valueOf(parser.getText());
                    parser.nextToken();
                    contentDocumentByOrder.put(keyValue, parser.getText());
                    //System.debug('Info: mergeDocuments ' + keyValue + ' -- ' + parser.getText());
                }
            }

            //System.debug('Info: contentDocumentByOrder ' + contentDocumentByOrder);

            String fileName = '';
            if(contentDocumentByOrder.size() > 0){
                List<ContentDistribution> contentDistributions = new List<ContentDistribution>();
                contentDistributions = [SELECT Id, ContentDownloadUrl, Name, ContentDocumentId, LastModifiedDate, ContentVersionId
                FROM ContentDistribution
                WHERE ContentDocumentId IN :contentDocumentByOrder.values()
                ORDER BY LastModifiedDate DESC];
                //System.debug('Info: contentDistributions size: ' + contentDistributions.size());
                Map<Id, String> docUrlByContentDocIds = new Map<Id, String>();
                Map<Id, Id> contentVersionIdByDocId = new Map<Id, Id>();
                for (ContentDistribution contentDistribution : contentDistributions) {
                    if(docUrlByContentDocIds.containsKey(contentDistribution.ContentDocumentId)){
                        continue;
                    } else {
                        docUrlByContentDocIds.put(contentDistribution.ContentDocumentId, contentDistribution.ContentDownloadUrl);
                        contentVersionIdByDocId.put(contentDistribution.ContentDocumentId, contentDistribution.ContentVersionId);
                        //System.debug('Info: ContentDocumentId ' + contentDistribution.ContentDocumentId + ' --- ' + contentDistribution.ContentDownloadUrl);
                    }
                }

                for(ContentVersion contentVersion: [SELECT Id, FileExtension, ContentDocumentId FROM ContentVersion WHERE Id IN :contentVersionIdByDocId.values()]){
                    if(contentVersion.FileExtension != 'pdf' && docUrlByContentDocIds.containsKey(contentVersion.ContentDocumentId)){
                        String pdfUrl = convertFilesToPdf(docUrlByContentDocIds.get(contentVersion.ContentDocumentId));
                        //System.debug('Info: pdfURL ' + pdfUrl);
                        if(pdfUrl != ''){
                            docUrlByContentDocIds.put(contentVersion.ContentDocumentId, pdfUrl);
                        }
                    }
                }

                if(docUrlByContentDocIds.size() > 0){
                    List<String> orderedUrl = new List<String>();
                    for(Integer order:contentDocumentByOrder.keySet()){
                        String contentDocId = contentDocumentByOrder.get(order);
                        //System.debug('Info: order: ' + order + ' --- contentDocId ' + contentDocId);
                        if(docUrlByContentDocIds.containsKey(contentDocId)){
                            //System.debug('Info: orderedUrl: ' + docUrlByContentDocIds.get(contentDocId));
                            orderedUrl.add(docUrlByContentDocIds.get(contentDocId));
                        }
                    }
                    fileName = mergePDFs(recordId, orderedUrl,documentType);
                }
            }
            return fileName;
        } catch (Exception e){
            System.debug('Error: ' + e.getStackTraceString());
            throw e;
        }
    }

    @AuraEnabled
    public static void createContentDistribution(String contentDocIds){
        try{
            //System.debug('Info: contentDocId ' + contentDocIds);
            JSONParser parser = JSON.createParser(contentDocIds);
            Set<Id> contentDocumentIds = new Set<Id>();
            while(parser.nextToken() != null){
                if(parser.getCurrentToken() == JSONToken.FIELD_NAME){
                    parser.nextToken();
                    contentDocumentIds.add(parser.getText());
                }
            }

            //System.debug('Info: contentDocumentIds ' + contentDocumentIds);

            if(contentDocumentIds.size() > 0) {
                List<ContentDistribution> contentDistributions = new List<ContentDistribution>();
                contentDistributions = [
                        SELECT Id, ContentDownloadUrl, Name, ContentDocumentId, LastModifiedDate
                        FROM ContentDistribution
                        WHERE ContentDocumentId IN :contentDocumentIds
                        ORDER BY LastModifiedDate DESC
                ];
                //System.debug('Info: contentDistributions size: ' + contentDistributions.size());

                if (contentDistributions.size() < contentDocumentIds.size()) {
                    Set<Id> contentDocIdsWithCV = new Set<Id>();
                    for (ContentDistribution cd : contentDistributions) {
                        contentDocIdsWithCV.add(cd.ContentDocumentId);
                    }

                    Set<Id> contentDocsNeedContentDistribution = new Set<Id>();
                    for (String contentId : contentDocumentIds) {
                        if (contentDocIdsWithCV.contains(contentId) == false) {
                            contentDocsNeedContentDistribution.add(contentId);
                        }
                    }

                    List<ContentVersion> contentVersions = [SELECT Id, Title FROM ContentVersion WHERE ContentDocumentId IN :contentDocsNeedContentDistribution];
                    for (ContentVersion cv : contentVersions) {
                        createContentDistribution(cv.Title, cv.Id);
                    }
                }
            }
        } catch (Exception e){
            System.debug('Error: ' + e.getStackTraceString());
            throw e;
        }
    }

    private static String mergePDFs(Id recordId, List<String> documentUrls, String documentType){
        try{
            Company_Setting__mdt companySetting = CompanySettingUtil.acvSetting;
            if(String.isBlank(companySetting.API2PDF_Key__c)){
                throw new DataException('API2PDF API Key is not setup, please contact your system administrator!');
            }
            String fileName = '';
            //ticket 21113 <<
            //fileName = 'merged_invoice_' + System.now().format('yyyyMMddhhmmss') +'.pdf';
            fileName = 'merged_document_' + System.now().format('yyyyMMddhhmmss') +'.pdf';
            //ticket 21113 >>
            Api2PdfClient a2pClient = new Api2PdfClient(companySetting.API2PDF_Key__c);
            /*
            for(String docUrl:documentUrls){
                System.debug('Info: documentUrl: ' + docUrl);
            }
            System.debug('Info: documentUrls size: ' + documentUrls.size());
             */

            //ticket 21113 <<
           /* if (Test.isRunningTest()) {
                ContentVersion contentVersion= new ContentVersion(
                        Title = 'Test',
                        PathOnClient = 'Test.jpg',
                        VersionData = Blob.valueOf('Test Content Data'),
                        IsMajorVersion = true
                );
                insert contentVersion;

                Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
                return contentDocumentId;
            }*/
            //ticket 21113 >>

            Api2PdfResponse pdfResponse = a2pClient.mergePdf(documentUrls, true, fileName);
            //System.debug('Info: pdfResponse.getSuccess() ' + pdfResponse.getSuccess());
            if(pdfResponse.getSuccess()) {
                String pdfUrl = pdfResponse.getPdf();

                Http h = new Http();
                HttpRequest request = new HttpRequest();
                request.setEndpoint(pdfUrl);
                request.setHeader('contentType', 'application/json');
                request.setMethod('GET');
                HttpResponse resp = h.send(request);
                if (resp.getStatusCode() == 200) {
                    ContentVersion contentVersion = new ContentVersion();
                    contentVersion.ContentLocation = 'S';  //S specify this document is in SF, use E for external files
                    contentVersion.PathOnClient = fileName;
                    contentVersion.Title = fileName;
                    contentVersion.VersionData = resp.getBodyAsBlob();
                    contentVersion.Document_Type_fileupload__c = documentType;

                    insert contentVersion;

                    //Link Content Version to content document
                    Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
                    ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
                    contentDocumentLink.ContentDocumentId = contentDocumentId;
                    contentDocumentLink.LinkedEntityId = recordId;
                    contentDocumentLink.ShareType = 'I';
                    insert contentDocumentLink;

                    return contentDocumentId;
                } else {
                    throw new DataException(resp.getStatus());
                }
            } else {
                System.debug('Error: ' + pdfResponse.getError());
                throw new DataException(pdfResponse.getError());
            }
        } catch (Exception e){
            System.debug('Error: ' + e.getStackTraceString());
            throw e;
        }
    }
    
    public static String convertFilesToPdf(String fileUrl){
        try{
            Company_Setting__mdt companySetting = CompanySettingUtil.acvSetting;
            if(String.isBlank(companySetting.API2PDF_Key__c)){
                throw new DataException('API2PDF API Key is not setup, please contact your system administrator!');
            }

            String pdfUrl = '';
            Api2PdfClient client = new Api2PdfClient(companySetting.API2PDF_Key__c);
            Api2PdfResponse response = client.libreofficeConvert(fileUrl, false, '');
            if(response.getSuccess()) {
                pdfUrl = response.getPdf();
                System.debug('pdfURL====>'+pdfUrl);
                return pdfUrl;
            } else {
                System.debug('Error: ' + response.getError());
                throw new DataException(response.getError());
            }
        } catch (Exception ex){
            System.debug('Error: ' + ex.getStackTraceString());
            throw ex;
        }
    }

    private static void createContentDistribution(String fileName, Id contentVersionId){
        try{
            ContentDistribution contentDistribution = new ContentDistribution();
            contentDistribution.Name = fileName;
            contentDistribution.ContentVersionId = contentVersionId;
            contentDistribution.PreferencesAllowPDFDownload = true;
            contentDistribution.PreferencesAllowViewInBrowser = true;
            contentDistribution.PreferencesLinkLatestVersion = true;
            contentDistribution.PreferencesNotifyOnVisit = false;
            contentDistribution.PreferencesPasswordRequired = false;
            contentDistribution.PreferencesAllowOriginalDownload = true;
            insert contentDistribution;
        } catch (Exception e){
            System.debug('Error ' + e.getStackTraceString());
            throw e;
        }
    }
    //78085
     public static void validateDocumentFileSize(Set<Id> parentIds,List<ContentVersion> contentVersions){
         List<ContentVersion> updateContentVersion = new List<ContentVersion>();
            Map<Id,Decimal> recordIdWithTotalDocSizeMap = new Map<Id,Decimal>();
            for(ContentVersion conVer:[SELECT Id,ContentSize,FirstPublishLocationId from ContentVersion WHERE FirstPublishLocationId IN:parentIds ]){
                Decimal totalContentSize = recordIdWithTotalDocSizeMap.containsKey(conVer.FirstPublishLocationId)?
                    recordIdWithTotalDocSizeMap.get(conVer.FirstPublishLocationId) + conVer.ContentSize :
                conVer.ContentSize;
                
                recordIdWithTotalDocSizeMap.put(conVer.FirstPublishLocationId,totalContentSize);
            }
            for (ContentVersion contentVersion : contentVersions) { 
                Decimal totalContentSize = recordIdWithTotalDocSizeMap.get(contentVersion.FirstPublishLocationId);
                ContentVersion conVer = new ContentVersion();
                conVer.Id = contentVersion.Id;

                if(contentVersion.FileType == 'EXCEL_X' && contentVersion.ContentSize>Decimal.valueOf(System.Label.SI1MBFILEUPLOADVALIDATION)){
                    conVer.IsAllow1Mb__c = true;   
                    updateContentVersion.add(conVer);
                    continue;
                }
                if(totalContentSize> Decimal.valueOf(System.Label.SI50MBFILEUPLOADVALIDATION)){ 
                    conVer.IsAllow50__c = true;   
                    updateContentVersion.add(conVer);
                    continue;
                }
                if(contentVersion.ContentSize > Decimal.valueOf(System.Label.SI20MBFILEUPLOADVALIDATION)){
                    conVer.IsAllow20__c = true;   
                    updateContentVersion.add(conVer);
                }
            } 
            if(updateContentVersion.size()>0){
                update updateContentVersion;  
            }
     }
    
}