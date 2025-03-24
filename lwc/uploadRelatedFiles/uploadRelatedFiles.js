import { api, track, wire } from 'lwc';
import { updateRecord, deleteRecord } from "lightning/uiRecordApi";
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

import BaseLWC from "c/baseLWC";


import getDocuments from '@salesforce/apex/FileUploadHandler.getRelatedFiles';
import processUploadedDocuments from '@salesforce/apex/FileUploadHandler.processUploadedDocuments';
import CONTENT_VERSION_OBJECT from '@salesforce/schema/ContentVersion';
import Type_FIELD from '@salesforce/schema/ContentVersion.Document_Type_fileupload__c';

const actions = [
    {label: 'Preview', name: 'preview_file'},
    {label: 'Delete', name: 'delete_file'}
];

const columns = [
    {label: 'Title', fieldName: 'Title', editable: true, cellAttributes: { class: { fieldName: 'format'} }},
    {label: 'Type', fieldName: 'FileExtension', initialWidth: 80 },
    {label: 'Doc Type', fieldName: 'Document_Type_fileupload__c', initialWidth: 160 },
    {
        type: 'action',
        typeAttributes: {rowActions: actions},
    }
];

export default class UploadRelatedFiles extends BaseLWC {
    @api recordId;
    @track columns = columns;
    @track attachments = [];
    @track selectedFiles = [];
    @track files = [];
    @track pendingSave = true;
    @track isFetched = false;
    @track isLoaded = true;
    @track documentType ;
    @track draftValues = [];
    renderedCallback() {
        if(!this.isFetched && this.recordId != null){
            this.getAllRelatedFiles();
        }
    }

    @wire(getObjectInfo, { objectApiName: CONTENT_VERSION_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: Type_FIELD})
    typePicklistValues;


    get isDocumentDisabled(){
        
        return (this.pendingSave||!this.documentType);
    }
    
    get acceptedFilesFormat() {
        return ['.pdf', '.doc', '.docx', '.jpg', '.png', '.jpeg', '.xlsx', '.xls', '.csv', '.zip', '.tiff'];
    }

    
    handleUploadFinished(event){
        this.isLoaded = false;
        const uploadedFiles = event.detail.files;
        processUploadedDocuments({uploadedFileResponse: JSON.stringify(uploadedFiles),documentType: this.documentType})
            .then(result => {
                //this.isLoaded = false;
                this.showToastEvent("Success", "Files have been uploaded.", "success");
                return this.getAllRelatedFiles();
            })
            .catch(error => {
                this.isLoaded = true;
                this.showToastEvent("Error", error.body.message, "error");
            });
    }


    async getAllRelatedFiles(contentDocumentId){
        this.isFetched = true;
        this.documentType = null;
        this.selectedFiles =[];
        await getDocuments({ "parentId": this.recordId })
            .then(data => {
                this.files = data;
                this.isLoaded =true;
                this.pendingSave = true;
                if (contentDocumentId) {
                    this.files.forEach(file => {
                        if (file.ContentDocumentId == contentDocumentId) {
                            file.format = 'slds-text-color_success';
                        }
                    });
                }
            })
            .catch(error => {
                this.files = undefined;
                this.isLoaded =true;

                this.showToastEvent("Error", error.body.message, "error");
            });
    }



    handleRowAction(event){
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'preview_file':
                this.previewFile(row.ContentDocumentId);
                break;
            case 'delete_file':
                this.deleteFile(row);
                break;
            default:
        }
    }
    
    deleteFile(file){
        this.isLoaded = false;
        deleteRecord(file.ContentDocumentId)
            .then(() => {
                //update attachments
                for (let i = 0; i < this.attachments.length; i++) {
                    if (this.attachments[i].ContentDocumentId == file.ContentDocumentId) {
                        this.attachments.splice(i, 1);
                        i--;
                    }
                }
                this.showToastEvent("Success", "File has been deleted.", "success");
                return this.getAllRelatedFiles();

            })
            .catch(error => {
                this.isLoaded = true;
                let errors = [];
                if (error.body.output && error.body.output.errors) {
                    error.body.output.errors.forEach((err) => {
                        errors.push(err.message);
                    });
                }
                else if (error.body.message) {
                    errors.push(error.body.message);
                }
                this.showToastEvent("Error", errors.join('\n'), "error");
            });
    }

    handleRowSave(event){
        this.isLoaded = true;
        this.draftValues = event.detail.draftValues;
        //convert the draft values to the record ready format
        const records = event.detail.draftValues.slice().map(draftValue => {
            const fields = Object.assign({}, draftValue);
            return { fields };
        });
        
        //create a queue of record updates
        const promises = records.map(record => updateRecord(record)); //create an array to update all updated rows
        Promise.all(promises).then(() => {
            this.isLoaded = false;
            this.pendingSave = false;
            this.showToastEvent("Success", "Changes have been saved.", "success");
            this.draftValues=[]
            return this.getAllRelatedFiles();
        }).then(result => {
            //update attachments
            let filesById = new Map(this.files.map(file => {
                return [file.ContentDocumentId, file];
            }));

            this.attachments.forEach(attachment => {
                if (filesById.has(attachment.ContentDocumentId)) {
                    attachment.Title = filesById.get(attachment.ContentDocumentId).Title;
                }
            });
        }).catch(error => {
            this.isLoaded = false;
            this.showToastEvent("Error", error.body.message, "error");
        })
    }

    handleRowCancel() {
        this.pendingSave = true;
        this.documentType = null;
        this.draftValues = [];
    }

    previewAttachment(event) {
        let file = { "ContentDocumentId": event.currentTarget.dataset.id }
        this.previewFile(file.ContentDocumentId);
    }

    //getters and setters
    get printTypeOptions() {
        return [
            { label: 'Detail', value: 'Detail' },
            { label: 'Consolidated', value: 'Consolidated' }
        ];
    }

    get documentTypeCategories() {
        return this.typePicklistValues.data.values.filter((docType) => docType.label != 'Merge')
    }
    handleDocumentTypeChange(event) {
        this.documentType = event.target.value;
        this.pendingSave = false;
    }
    

}