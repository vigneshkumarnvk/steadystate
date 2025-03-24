import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import BaseLWC from "c/baseLWC";
import { loadStyle } from 'lightning/platformResourceLoader';
import FileUploadCSS from '@salesforce/resourceUrl/FileUploadCSS';
import fetchUploadedFiles from '@salesforce/apex/CustomNotesAndAttachment.fetchUploadedFiles';
import getObjectName from '@salesforce/apex/CustomNotesAndAttachment.getObjectInfo';
import FILE_PREFIX from "@salesforce/schema/ContentVersion.Custom_N_A_fileupload__c";

export default class CustomNotesAndAttachment extends NavigationMixin(BaseLWC) {

    @api recordId;
    @api objectApiName;
    objectInfo;
    files;
    filesCount = 0;
    displayFiles;
    records;
    recordName;
    error;
    isLoading = false;

    //Predefined Value for the field in ContentVersion Object to handle xustom logic
    fileFieldName = FILE_PREFIX.fieldApiName;
    fileNamePrefix = "CustomNotesAndAttachment";

    @wire(CurrentPageReference)
    getCurrentPageReference(currentPageRef) {
        if (currentPageRef) {
            //Used to refresh the files displayed in the UI on clicking back button
            if (typeof this.displayUploadedFiles === 'function') {  //Check wehether metods exists
                this.displayUploadedFiles();
            }
        }
    }

    connectedCallback() {
        //CSS from static resource for file upload
        Promise.all([
            loadStyle(this, FileUploadCSS)
        ]);
        this.isLoading = true;                
        this.displayUploadedFiles();
    }

    @wire(getObjectName, { recordId: '$recordId' })
    wiredData({ error, data }) {
        if (data) {
            this.objectInfo = data;
            this.error = undefined;
        } else if (error) {
            this.objectInfo = undefined;
            console.error('Error:', error);
            this.error = error.body.message;
            this.showToastEvent('', error.body.message, 'error', '');
        }
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        this.showToastEvent('', uploadedFiles.length + (uploadedFiles.length == 1 ? ' file' : ' files') + ' was added to the ' + this.objectInfo.labelName + '.', 'success', '');
        this.displayUploadedFiles();
    }

    displayUploadedFiles() {
        if (this.recordId) {
            fetchUploadedFiles({ recordId: this.recordId })
                .then(result => {
                    if (result != null && result.length != 0) {
                        this.files = this.processUploadedFiles(result);
                        this.displayFiles = this.files.slice(0, 6);
                        this.filesCount = result.length > 6 ? '6+' : result.length;
                        this.error = undefined;
                    } else {
                        this.displayFiles = undefined;
                        this.filesCount = 0;
                        this.files = false;
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    this.error = error.body.message;
                    this.showToastEvent('', error.body.message, 'error', '');
                });
        }
        this.isLoading = false;
    }

    previewHandler(event) {
        this.previewFile(event.target.dataset.id);
    }

    //Call the component by passing values in the url
    handleViewAll(event) {
        this.isLoading = true;

        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__customNotesAndAttachmentDataTable'
            },
            state: {
                c__recordId: this.recordId,
                c__objectApiName: this.objectInfo.objectApiName,
                c__objectPluralName: this.objectInfo.pluralName,
                c__objectName: this.objectInfo.labelName,
                c__recordName: this.objectInfo.recordName
            }
        });
        this.isLoading = false;
    }

    processUploadedFiles(files) {
        //Process data to display in UI as needed
        return files.map(file => ({
            ...file,
            dynamicIconName: file.FileExtension ? this.getIconByFileExtension(file.FileExtension) : '',
            formatedDate: file.CreatedDate ? new Intl.DateTimeFormat('en-US', { year: 'numeric', month: 'short', day: 'numeric' }).format(new Date(file.CreatedDate)) : '',
            formattedSize: file.ContentSize ? this.getFormattedSize(file.ContentSize, 2) : '',
        }));
    }

    //formats the contentsize of document
    @api
    getFormattedSize(bytes, decimals) {
        if (bytes == 0) return '0 Bytes';
        var k = 1024,
            dm = decimals || 2,
            sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
            i = Math.floor(Math.log(bytes) / Math.log(k));
        return Math.round((bytes / Math.pow(k, i)).toFixed(dm)) + sizes[i];
    }

    //return iconName base on the file format
    @api
    getIconByFileExtension(fileFormat) {
        switch (fileFormat) {
            case 'csv':
                return 'doctype:csv';
            case 'txt':
                return 'doctype:txt';
            case 'xlsx':
            case 'xls':
                return 'doctype:excel';
            case 'png':
            case 'jpg':
            case 'jpeg':
                return 'doctype:image';
            case 'pdf':
                return 'doctype:pdf';
            case 'docx':
                return 'doctype:word';
            case 'html':
                return 'doctype:html';
            case 'ppt':
                return 'doctype:ppt';
            case 'zip':
                return 'doctype:zip';
            case 'xml':
                return 'doctype:xml';
            default:
                return 'doctype:unknown';
        }
    }
}