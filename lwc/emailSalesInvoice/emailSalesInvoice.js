import { LightningElement, api, track } from 'lwc';
import BaseLWC from "c/baseLWC"; //derive from the baseLWC component

import getSalesInvoice from '@salesforce/apex/EmailHandler.getSalesInvoice';
import initInvoiceEmailMessage from '@salesforce/apex/EmailHandler.initInvoiceEmailMessage';
import getJobTasks from '@salesforce/apex/FileUploadHandler.getJobTasks';
import saveInvoiceFormat from '@salesforce/apex/FileUploadHandler.saveInvoiceFormat';

export default class EmailSalesInvoice extends BaseLWC {
    //properties
    @api recordId;
    @track isRecordWired = false;
    @track isEmailMessageInitialized = false;
    @track errorMessage;
    @track invoice;
    @api jobTasks;
    @track actionInProgress;
    emailMessage = {};

    //event handlers
    connectedCallback() {
        this.actionInProgress = true;
        let methods = [];
        methods.push(this.getInvoice.bind(this));
        methods.push(this.getJobTasks.bind(this));
        methods.push(this.initEmailMessage.bind(this));
        this.callApexMethods(methods, () => {
            this.actionInProgress = false;
        }, (error) => {
            this.actionInProgress = false;
            this.showToastEvent("Error", error, "error");
        });
    }

    getInvoice(resolve, reject) {
        this.callApexMethod(getSalesInvoice,{ "recordId": this.recordId }, (result) => {
            this.invoice = result;
            this.errorMessage = null;
            if (this.invoice.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c) {
                this.errorMessage = 'Email function is disabled for this service center';
            }
            else {
                if (this.invoice.Approval_Status__c != 'Approved') {
                    this.errorMessage = 'Email function is not available because this Invoice is not approved.';
                }
                else if (this.invoice.Document_Status__c != 'Posted') {
                    this.errorMessage = 'Email function is not available because this Invoice is not posted.';
                }
                else if (!this.invoice.Contact__c) {
                    this.errorMessage = 'Email function is not available because this Invoice does not have a contact specified.';
                }
                else if (!this.invoice.Contact__r.Email) {
                    this.errorMessage = 'Email function is not available because the Invoice\'s contact does not have Email populated.';
                }
            }
             

            if (this.errorMessage) {
                if (reject) {
                    reject(this.errorMessage);
                }
            }
            else {
                if (resolve) {
                    resolve();
                }
            }
        });
    }

    getJobTasks(resolve, reject) {
        this.callApexMethod(getJobTasks,{ recordId: this.recordId}, (result) => {
            this.jobTasks = result;
            this.jobTasks.forEach(function(jobTask) {
                jobTask.label = 'Task #' + jobTask.Task_No__c + ' - ' + jobTask.Name;
            });
            resolve();
        });
    }

    initEmailMessage(resolve, reject) {
        this.callApexMethod(initInvoiceEmailMessage,{ "recordId": this.recordId }, (result) => {
            this.emailMessage = JSON.parse(JSON.stringify(result));
            this.isEmailMessageInitialized= true;
            if (resolve) {
                resolve();
            }
        }, (error) => {
            if (reject) {
                reject(error);
            }
        });
    }

    //getters and setters
    get printTypeOptions(){
        return [
            {label: 'Detail', value: 'Detail'},
            {label: 'Summary', value: 'Summary'},
            {label: 'By Date by Category', value: 'By Date by Category'}
        ]
    }

    reportParameterCallback = this.getReportParameters.bind(this);
    async getReportParameters() { //wait for the job task print option to be saved before returning the parameters
        await saveInvoiceFormat({ "JSONJobTasks": JSON.stringify(this.jobTasks) });
        return  { "id": this.recordId }
    }

    handleInvoiceFormatChange(event) {
        let name = event.target.name;
        let value = event.target.value;
        for (let i = 0; i < this.jobTasks.length; i++) {
            if (this.jobTasks[i].Id === name) {
                this.jobTasks[i].Invoice_Format__c = value;
                break;
            }
        }
    }

    get getFilename() {
        return 'Invoice#' + this.invoice.Name;
    }

    //functions
    handleFieldChange(event) {
        if (event.target.type == 'checkbox') {
            this[event.target.name] = event.target.checked;
        }
        else {
            this[event.target.name] = event.target.value;
        }
    }
}