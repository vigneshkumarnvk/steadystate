import { LightningElement, api, track } from 'lwc';
import BaseLWC from "c/baseLWC"; //derive from the baseLWC component

import getSalesQuote from '@salesforce/apex/EmailHandler.getSalesQuote';
import initQuoteEmailMessage from '@salesforce/apex/EmailHandler.initQuoteEmailMessage';
import createQuoteSignatureRequest from '@salesforce/apex/SignatureRequestController.createQuoteSignatureRequest';
import updateSignatureRequest from '@salesforce/apex/SignatureRequestController.UpdateSignatureRequest';
import saveQuotePDFReportParameters from '@salesforce/apex/EmailHandler.saveQuotePDFReportParameters';


export default class EmailSalesQuote extends BaseLWC  {
    //properties
    @api recordId;
    @track isEmailMessageInitialized = false;
    @track errorMessage;
    @track quote = {};
    @track actionInProgress;
    emailMessage = {};
    printType = 'Detail';
    printEstimatedJobDuration;
    signatureRecord = {};

    //event handlers
    connectedCallback() {
        this.actionInProgress = true;
        let methods = [];
        methods.push(this.getQuote.bind(this));
        methods.push(this.initEmailMessage.bind(this));
        this.callApexMethods(methods, () => {
            this.actionInProgress = false;
        }, (error) => {
            this.actionInProgress = false;
            this.showToastEvent("Error", error, "error");
        });
    }

    getQuote(resolve, reject) {
        this.callApexMethod(getSalesQuote,{ "recordId": this.recordId }, (result) => {
            this.quote = result;
            this.errorMessage = null;
            if (this.quote.Document_Type__c != 'Sales Quote') {
                this.errorMessage = 'Email function is not available for sales orders.';
            } else if (this.quote.Approval_Status__c != 'Approved') {
                this.errorMessage = 'Email function is not available because this Quote has not been approved.';
            } else if (!this.quote.Quote_Contact__c) {
                this.errorMessage = 'Email function is not available because the Quote Contact is not specified.';
            } else if (!this.quote.Quote_Contact__r.Email) {
                this.errorMessage = 'Email function is not available because the Quote Contact\'s Email is blank.';
            }

            if (this.errorMessage) {
                if (reject) {
                    reject(this.errorMessage);
                }
            }
            else {
                if (resolve) {
                    this.printType = this.quote.Report_Parameter_Print_Type__c;
                    this.printEstimatedJobDuration = this.quote.Report_Parameter_Print_Estimate_Duration__c;
                    resolve();
                }
            }
        });
    }

    initEmailMessage(resolve, reject) {
        this.callApexMethod(initQuoteEmailMessage,{ "recordId": this.recordId }, (result) => {
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
    get printTypeOptions() {
        return [
            { label: 'Detail', value: 'Detail' },
            { label: 'Consolidated', value: 'Consolidated' }
        ];
    }

    reportParameterCallback = this.getReportParameters.bind(this);
    async getReportParameters() {
        const reportParameters = {
            "id": this.recordId,
            "printType": this.printType,
            "printEstimatedDuration": (this.printEstimatedJobDuration == true)
        }
        await saveQuotePDFReportParameters(reportParameters);
        return reportParameters;
    }

    beforeSendEmailActionCallback = this.beforeSendEmailAction.bind(this);
    beforeSendEmailAction(resolve, reject) {
        this.signatureRecord = null;
        //get email body from the child component
        let _emailMessage = this.template.querySelector('c-email-document').emailMessage;
        this.callApexMethod(createQuoteSignatureRequest, { "quoteId": this.recordId }, (result) => {
            this.signatureRecord = JSON.parse(result);
            _emailMessage.mailBody = _emailMessage.mailBody.replace(/[a-z0-9]{8}\-[a-z0-9]{4}\-[a-z0-9]{4}\-[a-z0-9]{4}\-[a-z0-9]{12}/g, this.signatureRecord.Site_Access_Token__c);
            this.emailMessage.mailBody = _emailMessage;
            resolve();
        }, (error) => {
            reject(error);
        });
    }

    afterSendEmailActionCallback = this.afterSendEmailAction.bind(this);
    afterSendEmailAction(resolve, reject) {
        this.callApexMethod(updateSignatureRequest,{ "JSONSignature": JSON.stringify(this.signatureRecord) }, () => {
            resolve();
        }, (error) => {
            reject(error);
        });
    }


    get getFilename() {
        return this.quote.Name;
    }

    //functions
    handleFieldChange(event) {
        const { name, type, value, checked } = event.target;
        if (type == 'checkbox') {
            this[name] = checked;
        }
        else {
            this[name] = value;
        }
    }
}