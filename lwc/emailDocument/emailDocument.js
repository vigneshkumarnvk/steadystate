import { LightningElement, api, track, wire } from 'lwc';
import { getRecord, getFieldValue, updateRecord, deleteRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import BaseLWC from "c/baseLWC";

import USER_ID from '@salesforce/user/Id'
import USER_EMAIL_FIELD from '@salesforce/schema/User.Email';

import sendEmail from '@salesforce/apex/EmailHandler.sendEmail';
import getDocuments from '@salesforce/apex/FileUploadHandler.getRelatedFiles';
import generateAndSaveDocument from '@salesforce/apex/FileUploadHandler.generateAndSaveDocument';
import processUploadedDocuments from '@salesforce/apex/FileUploadHandler.processUploadedDocuments';
import createContentDistribution from '@salesforce/apex/FileUploadHandler.createContentDistribution';
import mergeDocuments from '@salesforce/apex/FileUploadHandler.mergeDocuments';
import LightningConfirm from "lightning/confirm";


const actions = [
    {label: 'Preview', name: 'preview_file'},
    {label: 'Delete', name: 'delete_file'}
];

const columns = [
    {label: 'Title', fieldName: 'Title', editable: true, cellAttributes: { class: { fieldName: 'format'} }},
    {label: 'Type', fieldName: 'FileExtension', initialWidth: 80 },
    {label: 'Order', fieldName: 'Order', type: 'number', editable: true, initialWidth: 80 },
    {
        type: 'action',
        typeAttributes: {rowActions: actions},
    }
];


export default class EmailDocument extends BaseLWC {
    @api recordId;
    @api reportName;
    @api reportOutputFilename;
    @api reportParametersCallback;
    @api enableTestMode = false;
    @api beforeSendEmailAction;
    @api afterSendEmailAction;
    @track _emailMessage;
    @track columns = columns;
    @track attachments = [];
    @track selectedFiles = [];
    @track files = [];
    @track pendingSave = false;
    @track actionInProgress = false;
    savedMailTo; //store the original mail to email address


    @wire(getRecord,{ recordId: USER_ID, fields: [USER_EMAIL_FIELD] }) userInfo;

    //this event fires when the component is inserted into the parent DOM
    connectedCallback() {
        this.getRelatedFiles();
    }

    get acceptedFilesFormat() {
        return ['.pdf', '.doc', 'docx', '.jpg', '.png', '.jpeg', '.xlsx', '.xls', '.csv', '.zip'];
    }

    @api
    set emailMessage(value) {
        this._emailMessage = {...value}
        this.savedMailTo = this._emailMessage.mailTo;
    }
    get emailMessage() {
        return this._emailMessage;
    }

    get isMailBodyEmpty() {
        return (!this._emailMessage.mailBody);
    }

    handleUploadFinished(event){
        this.actionInProgress = true;
        const uploadedFiles = JSON.stringify(event.detail.files);
        processUploadedDocuments({uploadedFileResponse: uploadedFiles,documentType: this.documentType})
            .then(result => {
                this.actionInProgress = false;
                this.showToastEvent("Success", "Files have been uploaded.", "success");
                return this.getRelatedFiles();
            })
            .catch(error => {
                this.actionInProgress = false;
                this.showToastEvent("Error", error.body.message, "error");
            });
    }

    handle_emailMessageChange(event) {
        try {
            const { name, type, value, checked } = event.target;
            if (type == 'checkbox') {
                this._emailMessage[name] = checked;
                if (name == 'isTest') {
                    if (checked == true) {
                        this._emailMessage.mailTo = getFieldValue(this.userInfo.data, USER_EMAIL_FIELD);
                    } else {
                        this._emailMessage.mailTo = this.savedMailTo;
                    }
                }
            }
            else {
                this._emailMessage[name] = value;
            }
        }
        catch (error) {
            alert(error);
        }
    }

    async getRelatedFiles(contentDocumentId){
        await getDocuments({ "parentId": this.recordId })
            .then(data => {
                this.files = data;
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
                this.showToastEvent("Error", error.body.message, "error");
            });
    }


    // Getting selected rows to perform any action
    handleRowSelection(event) {
        this.selectedFiles = event.detail.selectedRows;
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
        this.actionInProgress = true;
        deleteRecord(file.ContentDocumentId)
            .then(() => {
                //update attachments
                for (let i = 0; i < this.attachments.length; i++) {
                    if (this.attachments[i].ContentDocumentId == file.ContentDocumentId) {
                        this.attachments.splice(i, 1);
                        i--;
                    }
                }
                this.actionInProgress = false;
                this.showToastEvent("Success", "File has been deleted.", "success");
                return this.getRelatedFiles();

            })
            .catch(error => {
                this.actionInProgress = false;
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

    handleCellChange(event){
        if (event.detail.draftValues) {
            this.pendingSave = true;
            if (event.detail.draftValues[0].Order) {
                this.files.forEach(file => {
                    if (file.Id === event.detail.draftValues[0].Id) {
                        file.Order = event.detail.draftValues[0].Order;
                        event.target.draftValues = null; //cancel the cell change so the save button won't display
                        this.pendingSave = false;
                    }
                });
            }
        }
    }

    handleRowSave(event){
        this.actionInProgress = true;
        //convert the draft values to the record ready format
        const records = event.detail.draftValues.slice().map(draftValue => {
            const fields = Object.assign({}, draftValue);
            delete fields.Order; //remove non-field
            return { fields };
        });

        //create a queue of record updates
        const promises = records.map(record => updateRecord(record)); //create an array to update all updated rows
        Promise.all(promises).then(() => {
            this.actionInProgress = false;
            this.pendingSave = false;
            this.showToastEvent("Success", "Changes have been saved.", "success");
            return this.getRelatedFiles();
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
            this.actionInProgress = false;
            this.showToastEvent("Error", error.body.message, "error");
        })
    }

    handleRowCancel() {
        this.pendingSave = false;
    }

    attachToEmail() {

        for (let i = 0; i < this.selectedFiles.length; i++) {
            let file = this.selectedFiles[i];
            if (!this.attachments.some((attachment) => attachment.ContentDocumentId === file.ContentDocumentId)) {
                let attachment = {"Title": file.Title, "ContentDocumentId": file.ContentDocumentId}
                this.attachments.push(attachment);
            }
        }

        //clear checked rows
        this.selectedFiles = [];
        this.template.querySelector('lightning-datatable[data-id="files"]').selectedRows = [];
    }

    removeEmailAttachment(event) {
        for (let i = 0; i < this.attachments.length; i++) {
            if (this.attachments[i].ContentDocumentId === event.target.value) {
                this.attachments.splice(i, 1);
                i--;
            }
        }
    }

    previewAttachment(event) {
        let file = { "ContentDocumentId": event.currentTarget.dataset.id }
        this.previewFile(file.ContentDocumentId);
    }

    async confirmSendEmail() {
        let ok = [...this.template.querySelectorAll('lightning-input,lightning-input-rich-text')].reduce((valid, htmlElement) => {
            if (htmlElement.tagName === 'LIGHTNING-INPUT-RICH-TEXT') {
                return valid && (htmlElement.value);
            } else {
                htmlElement.reportValidity();
                return valid && htmlElement.checkValidity();
            }
        }, true);

        if (ok) {
            if (this.attachments.length == 0) {
                ok = false;
                this.showToastEvent("Error", "An attachment is required to send this email. Please select one or more files and attach to the email.", "error");
            }
            else {
                let contentDocumentIds = [];
                this.attachments.forEach(attachment => {
                    contentDocumentIds.push(attachment.ContentDocumentId);
                });
                this._emailMessage.contentDocumentIds = contentDocumentIds.join(';');
            }
        }

        if (ok) {
            let result = await LightningConfirm.open({
                label: "Send Email",
                message: 'Do you want to send the email now?',
                variant: 'headerless'
            });
            if (result == true) {
                this.actionInProgress = true;
                let methods = [];
                if (this.beforeSendEmailAction) {
                    methods.push(this.beforeSendEmailAction.bind(this));
                }
                methods.push(this.sendEmail.bind(this));
                if (this.afterSendEmailAction) {
                    methods.push(this.afterSendEmailAction.bind(this));
                }
                this.callApexMethods(methods, () => {
                    this.actionInProgress = false;
                    this.showToastEvent("Send Email", "Email has been sent.", "success");
                }, (error) => {
                    this.actionInProgress = false;
                    this.showToastEvent("Send Email Error", error, "error");
                });
            }
        }
    }

    sendEmail(resolve, reject) {
        this.callApexMethod(sendEmail, { "JSONEmailMessage": JSON.stringify(this._emailMessage) }, () => {
            this.attachments = [];
            resolve();
        }, (error) => {
            reject(error);
        });
    }

    showPrintDialog() {
        const modal = this.template.querySelector('.print-dialog');
        modal.show();
    }

    hidePrintDialog() {
        const modal = this.template.querySelector('.print-dialog');
        modal.hide();
    }

    handlePrint() {
        this.generateDocument();
        this.hidePrintDialog();
    }

    async generateDocument() {
        try {
            this.actionInProgress = true;
            const reportParams = await this.reportParametersCallback();
            this.callApexMethod(generateAndSaveDocument,{ recordId: this.recordId, reportName: this.reportName, JSONReportParams: JSON.stringify(reportParams), fileName: this.reportOutputFilename  }, (result) => {
                this.actionInProgress = false;
                this.showToastEvent("Success", "New pdf has been created.", "success");
                this.getRelatedFiles(result);
            }, (error) => {
                throw error;
            });
        }
        catch(error) {
            this.actionInProgress = false;
            this.showToastEvent("Error", error, 'error');
        }
    }

    mergeDocuments(){
        this.actionInProgress = true;
        let contentDocumentIds = {};
        let sortedContentDocumentIds = {};
        let undefinedOrder = 99999;
        try {
            if (this.selectedFiles.length < 2) {
                throw 'Please select at least 2 documents to merge.';
            }
            for (let i = 0; i < this.selectedFiles.length; i++) {
                let sequence = this.selectedFiles[i].Order;
                if (sequence === undefined) {
                    sequence = undefinedOrder
                    undefinedOrder--;
                }

                if (contentDocumentIds[sequence] !== undefined) {
                    throw 'Duplicate order number ' + sequence + ' found!';
                }

                let contentDocumentId = this.selectedFiles[i].ContentDocumentId;
                contentDocumentIds[sequence] = contentDocumentId;
            }

            Object.keys(contentDocumentIds).sort().forEach(function (key) {
                sortedContentDocumentIds[key] = contentDocumentIds[key];
            });

            createContentDistribution({ contentDocIds: JSON.stringify(sortedContentDocumentIds)}).then(result => {
                return mergeDocuments({ recordId: this.recordId, contentDocumentIds: JSON.stringify(sortedContentDocumentIds), documentType:null});
            }).then(result => {
                this.actionInProgress = false;
                this.showToastEvent("Success", "New document has been created.", "success");
                return this.getRelatedFiles(result);

            }).catch(error => {
                this.actionInProgress = false;
                this.showToastEvent("Error", error.body.message, "error");
            })

        } catch(err){
            this.actionInProgress = false;
            this.showToastEvent("Error", err, "error");
        }
    }
}