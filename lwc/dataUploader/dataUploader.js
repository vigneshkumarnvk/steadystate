import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";
import hasPermission from '@salesforce/customPermission/Upload_Contract_Lines';
import executeDataUploadBatch from '@salesforce/apex/DataUploadHandler.executeDataUploadBatch';
export default class DataUploader extends LightningElement {

    @api recordId;
    @api objectApiName;
    error;
    data;
    jobId;
    message;
    isFileUploaded = false;
    header = 'Upload Contract Lines'

    get acceptedFormats() {
        return ['.csv'];
    }

    get isPermissionEnabled() {
        return hasPermission;
    }

    handleUploadfinished(event) {
        const uploadedFiles = event.detail.files;
        executeDataUploadBatch({
            recordId: this.recordId,
            contVerId: uploadedFiles[0].contentVersionId,
            objectName: 'Contract_Line__c'
        })
            .then(result => {
                if (result == 'Empty') {
                    this.isFileUploaded = true;
                    this.showNotification('Error!', 'File is Empty', 'error', 'dismissible');
                }
                else if (result != null) {
                    this.isFileUploaded = true;
                    this.jobId = result;
                    this.showNotification('Success!', 'Contract lines are being processed. You will receive an email once the upload is complete.', 'success', 'dismissible');
                } else {
                    this.isFileUploaded = true;
                    this.showNotification('Error!', 'File type should be csv', 'error', 'dismissible');
                }
            })
            .catch(error => {
                console.error('Error:', error);
                this.error = error.body.message;
                this.showNotification('Error!', error.body.message, 'error', 'dismissible');
            });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showNotification(titleText, messageText, variant, mode) {
        this.dispatchEvent(new CloseActionScreenEvent());
        const evt = new ShowToastEvent({
            title: titleText,
            message: messageText,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
    }
}