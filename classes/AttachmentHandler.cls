/*************************************************************************************************
* Name         :  AttachmentHandler 
* Description  :  Apex class to query the metadata and pass to LWC
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Sanjana	      02-14-2024           Created this wrapper class to process the files in chunks
* Sathish	      03-15-2024           converted the excel and doc file to pdf
* Sathish	      04-05-2024           added the one more condition for conversion from doc to pdf
*************************************************************************************************/
public class AttachmentHandler {
    
    
    private static final Integer Chunk_Size = 10;
    
    @AuraEnabled(cacheable=true)
    public static List<FileWrapper> getFileContent(Id parentId) {
        Set<Id> contentDocIds = new Set<Id>();
        contentDocIds.add(parentId);
        List<FileWrapper> fileWrappers = new List<FileWrapper>();
        Map<Id,String> contentVersionIdByPdfDocURL = new Map<Id,String>();
        Map<Id,String> contentVersionIdByContentDocURL = new Map<Id,String>();
        
        for (
            ContentDistribution distribution: [Select Id,ContentDownloadUrl,PdfDownloadUrl,ContentVersionId From ContentDistribution
                                               where ContentDocumentId IN :contentDocIds]
        ){
            contentVersionIdByPdfDocURL.put(distribution.ContentVersionId,distribution.PdfDownloadUrl);
            contentVersionIdByContentDocURL.put(distribution.ContentVersionId,distribution.ContentDownloadUrl);
        }
        
        List<ContentVersion> contentVersions = [SELECT Title,VersionData,FileExtension FROM ContentVersion WHERE ContentDocumentId IN:contentDocIds ORDER BY CreatedDate DESC];
        
        
        system.debug('contentVersions'+contentVersions);
        for (Integer i = 0; i < contentVersions.size(); i += Chunk_Size) {
            List<ContentVersion> Chunk = new List<ContentVersion>();
            for (Integer j = i; j < Math.min(i + Chunk_Size, contentVersions.size()); j++) {
                Chunk.add(contentVersions[j]);
            }
            fileWrappers.addAll(processChunks(Chunk, contentVersionIdByContentDocURL,contentVersionIdByPdfDocURL));
        }
        
        
        return fileWrappers;
    }
    
    public static List<FileWrapper> processChunks(
        List<ContentVersion> Chunk,Map<Id,String> contentVersionIdByContentDocURL,
        Map<Id,String> contentVersionIdByPdfDocURL
    ) {
        List<FileWrapper> fileWrappers = new List<FileWrapper>();
        
        for (ContentVersion contentVersion : Chunk) {
            Blob versionData = contentVersion.VersionData;
            String extensionType = contentVersion.FileExtension;
            if(contentVersion.FileExtension == 'docx' || contentVersion.FileExtension == 'doc'){
                versionData = new PageReference(contentVersionIdByPdfDocURL.get(contentVersion.Id)).getContentAsPDF();
                extensionType = 'pdf';
            }
            if(contentVersion.FileExtension == 'xlsx'){
                versionData = convertFileToPdf(contentVersion,contentVersionIdByContentDocURL);
                extensionType = 'pdf';
                
            }
            fileWrappers.add(new FileWrapper(contentVersion.Title, EncodingUtil.base64Encode(versionData), extensionType));
        }
        return fileWrappers;
    }
    
    public static Blob convertFileToPdf(ContentVersion contentVersion,Map<Id,String> contentVersionIdByContentDocURL){
        
        if(Test.isRunningTest()){
            return null;
        }else{
            String pdfURL=FileUploadHandler.convertFilesToPdf(contentVersionIdByContentDocURL.get(contentVersion.Id));
            return convertPdfByDocURL(contentVersion,pdfURL); 
        }
        
    }
    
    public static Blob convertPdfByDocURL(ContentVersion contentVersion,String pdfURL){
        Company_Setting__mdt companySetting = CompanySettingUtil.acvSetting;
        
        Api2PdfClient client =  new Api2PdfClient(companySetting.API2PDF_Key__c);
        
        String endpointURL = '';
        if(Test.isRunningTest()){
            endpointURL = 'https://acvenviro--sathishacv.sandbox.my.salesforce.com/';
        }else{
            Api2PdfResponse pdfResponse = client.mergePdf(new List<String>{pdfURL}, true, contentVersion.Title);
            endpointURL = pdfResponse.getPdf();
        }
        Http http = new Http();
        HttpRequest request = new HttpRequest(); 
        request.setEndpoint(endpointURL); 
        request.setHeader('contentType', 'application/json');
        request.setMethod('GET');
        HttpResponse resp = http.send(request);
        return resp.getBodyAsBlob();
    }
    public class FileWrapper {
        @AuraEnabled public String fileName;
        @AuraEnabled public String fileData;
        @AuraEnabled public String fileExtension;
        
        public FileWrapper(String fileName, String fileData, String fileExtension) {
            
            this.fileName = fileName;
            this.fileData = fileData;
            this.fileExtension = fileExtension;
        }
    }
    @AuraEnabled
    public static List<ContentVersion> getRelatedFiles(Id parentId){
        Set<Id> contentDocIds = new Set<Id>();
        for(ContentDocumentLink cntLink: [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId =: parentId]){
            contentDocIds.add(cntLink.ContentDocumentId);
        }
        if(contentDocIds.size() > 0){
            return [SELECT Id, Title, ContentDocumentId, FileExtension, Document_Type_fileupload__c, VersionData FROM ContentVersion WHERE ContentDocumentId IN :contentDocIds ORDER BY CreatedDate DESC];
        } else {
            return null;
        }
    }
}