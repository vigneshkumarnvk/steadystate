import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRelatedFiles from '@salesforce/apex/FileUploadHandler.getRelatedFiles';
import getCustomMetadataRecords from '@salesforce/apex/WorkOrderAttachmentInfo.getCustomMetadataRecords';
import getDocumentTypeID from '@salesforce/apex/WorkOrderAttachmentInfo.getDocumentTypeID';
import getFileContent from '@salesforce/apex/AttachmentHandler.getFileContent';
import createCaseWithParentId from '@salesforce/apex/SalesInvoiceWorkOrderService.createCaseWithParentId';
import updateStatusInSalesOrder from '@salesforce/apex/SendEQAIBillingPackageCtrl.updateStatusInSalesOrder';
import updateSalesInvoice from '@salesforce/apex/WorkOrderAttachmentInfo.updateSalesInvoice';

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import sourceSystem from '@salesforce/label/c.source_system';

const FIELDS = ['Sales_Invoice__c.Service_Center__r.Name', 'Sales_Invoice__c.Bill_to_Customer__r.National_Account__c', 'Sales_Invoice__c.Bill_to_Customer__r.Retail__c', 'Sales_Invoice__c.Bill_to_Customer__r.MSG__c', 'Sales_Invoice__c.Bill_to_Customer__r.MsgRetailNational__c', 'Sales_Invoice__c.Bill_to_Customer__r.Prevent_Billing_Project__c', 'Sales_Invoice__c.Sales_Order__r.EQAI_Billing_Project_Id__c'];

export default class MyComponent extends LightningElement {
    @api recordId;
    @api channel;
    boundary = 'boundary_string';
    apiKey;
    apiToken;
    records;
    serviceCenter;
    profitCtrId;
    companyId;
    company;
    profitId;
    empId;
    API_Extension__c;
    salesforce_invoice_CSID;
    invoicechannel;
    msgRetailNational;
    msgCustomer;
    retailCustomer;
    nationAccount;
    preventBPFlag;
    billingProjectId;
    labels = {
        sourceSystem: sourceSystem
    };

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredSalesInvoice({ error, data }) {
        if (data) {
            this.serviceCenter = getFieldValue(data, 'Sales_Invoice__c.Service_Center__r.Name');
            this.msgRetailNational = getFieldValue(data, 'Sales_Invoice__c.Bill_to_Customer__r.MsgRetailNational__c');
            this.preventBPFlag = getFieldValue(data, 'Sales_Invoice__c.Bill_to_Customer__r.Prevent_Billing_Project__c');
            this.billingProjectId = getFieldValue(data, 'Sales_Invoice__c.Sales_Order__r.EQAI_Billing_Project_Id__c');
            this.msgCustomer = getFieldValue(data, 'Sales_Invoice__c.Bill_to_Customer__r.MSG__c');
            this.retailCustomer = getFieldValue(data, 'Sales_Invoice__c.Bill_to_Customer__r.Retail__c');
            this.nationAccount = getFieldValue(data, 'Sales_Invoice__c.Bill_to_Customer__r.National_Account__c');
            console.log(this.msgRetailNational);
            console.log(this.msgCustomer);
            console.log(this.retailCustomer);
            console.log(this.nationAccount);
            console.log(this.billingProjectId);
            this.fetchCustomMetadata();
        } else if (error) {
            console.error('Error fetching account:', JSON.stringify(error));
        }
    }

    fetchCustomMetadata() {
        if (this.serviceCenter) {
            getCustomMetadataRecords()
                .then(result => {
                    if (result && result.length > 0) {
                        this.records = result;
                        this.apiToken = this.records[0].API_Token__c;
                        this.apiKey = this.records[0].API_Key__c;
                        this.API_Extension__c = this.records[0].API_Extension__c;
                        this.companyId = parseInt(this.records[0].company_Id_EQIMap[this.serviceCenter]);
                        this.profitCtrId = parseInt(this.records[0].profit_Ctr_Id_EQIMap[this.serviceCenter]);
                        this.empId = this.records[0].employeeId;
                    }
                })
                .catch(error => {
                    console.error('Error: ', error);
                });
        }
    }

    @api
    async makeCallout() {
        this.salesforce_invoice_CSID = this.recordId;
        this.invoicechannel = this.channel;
        const fileUploadPromises = [];

        try {
            const relatedFiles = await this.getRelatedFiles(this.recordId);
            console.log("Concatenated relatedFiles:", relatedFiles);
            if (!relatedFiles || relatedFiles.length === 0 || relatedFiles === null) {

                this.toastEventFire('Success', 'The Billing Package has been submitted to EQAI.', 'Success', 'dismissible');

                console.log(this.msgRetailNational);
                console.log('preventBP', this.preventBPFlag);
                console.log('nationAccount', this.nationAccount);
                console.log('retailCustomer', this.retailCustomer);
                console.log('msgCustomer', this.msgCustomer);
                console.log(this.billingProjectId);
                if ((this.invoicechannel === 'Email' || this.invoicechannel === 'EMAIL') && (this.preventBPFlag === false) && (this.billingProjectId === '' || this.billingProjectId === null)) {
                    await this.updateDocumentType();
                    const closeQA = new CustomEvent('close');
                    this.dispatchEvent(closeQA);
                }
                else {
                    await this.updateSalesInvoice();
                    const closeQA = new CustomEvent('close1');
                    this.dispatchEvent(closeQA);
                }
                return;
            } else {
                let isSuccess = false;
                let finalErrorMessage = '';
                for (const file of relatedFiles) {
                    const attachmentChunks = await this.getFileContentFromApex(file.ContentDocumentId);
                    const concatenatedBase64 = attachmentChunks[0].fileData;
                    const fileName = `${attachmentChunks[0].fileName}.${attachmentChunks[0].fileExtension}`;
                    const fileType = await this.getDocumentTypeIDFromApex(file.Document_Type_fileupload__c);
                    const requestPayload = this.constructRequestPayload(this.salesforce_invoice_CSID, this.companyId, this.profitCtrId, fileType, fileName, this.labels.sourceSystem, concatenatedBase64, this.empId);
                    console.log('requestPayload', requestPayload);
                    try {
                        const response = await this.getAttachmentPostCalloutResponse(this.API_Extension__c, requestPayload, 'POST', this.apiKey, this.apiToken);
                        // Task#77453
                        console.log('response::' + response);
                        if (response.includes('Integration Successful')) {

                            isSuccess = true;
                        } else {
                            await this.createCaseIfError(this.recordId, 'Error in file upload', response, 'Error in File Upload');
                            let errorMessageParts = response.split(';');
                            let generalErrorMessage = errorMessageParts.shift();
                            finalErrorMessage = generalErrorMessage + '\n';
                            for (let i = 0; i < errorMessageParts.length - 1; i++) {
                                finalErrorMessage += (i + 1) + '.' + errorMessageParts[i];
                                if (i < errorMessageParts.length - 1) {
                                    finalErrorMessage += '\n';
                                }
                            }
                            isSuccess = false;
                            console.log(finalErrorMessage);

                        }

                    } catch (error) {
                        console.error('Error:', error.message);
                    }
                }
                if (isSuccess) {

                    this.toastEventFire('Success', 'The Billing Package has been submitted to EQAI.', 'Success', 'dismissible');
                    // const closeQA = new CustomEvent('close');
                    // this.dispatchEvent(closeQA);
                    console.log('this.invoicechannel===>' + this.invoicechannel);
                    if ((this.invoicechannel === 'Email' || this.invoicechannel === 'EMAIL') && (this.preventBPFlag === false) && (this.billingProjectId === '' || this.billingProjectId === null)) {
                        await this.updateDocumentType();
                        console.log('success  ===>');
                        const closeQA = new CustomEvent('close');
                        this.dispatchEvent(closeQA);
                    }
                    else {
                        console.log('invoice fail  ===>');
                        // this.updateSalesInvoice();
                        await this.updateSalesInvoice();
                        const closeQA = new CustomEvent('close1');
                        this.dispatchEvent(closeQA);
                        console.log('sucess--->');
                    }
                } else {
                    console.log('checkfail');
                    this.toastEventFire('Error', finalErrorMessage, 'Error', 'sticky');
                    console.log('test close');

                    const closeQA = new CustomEvent('close1');
                    this.dispatchEvent(closeQA);

                    
                }

            }
        } catch (error) {
            console.error('Error:', error);
        }

        await Promise.all(fileUploadPromises);
    }


    async updateDocumentType() {
        try {
            console.log('this.invoicechannel1   ===>');
            await updateStatusInSalesOrder({ salesInvoiceId: this.recordId });
        } catch (error) {
            console.error('Error updating document type:', error);
            throw error;
        }
    }
    async updateSalesInvoice() {
        try {

            await updateSalesInvoice({ salesInvoiceId: this.recordId });
        } catch (error) {
            console.error('Error updating document type:', error);
            throw error;
        }
    }
    async getRelatedFiles(salesInvoiceId) {
        try {
            const result = await getRelatedFiles({ parentId: salesInvoiceId });
            return result;
        } catch (error) {
            throw error;
        }
    }

    async createCaseIfError(recordId, caseSubject, response, requestPayload) {
        console.log('createcase method called')
        try {
            // Assuming createCaseWithParentId is defined elsewhere and properly handles the passed object
            await createCaseWithParentId({
                parentId: recordId,
                subject: caseSubject,
                caseDescription: response,
                httpRequest: requestPayload
            });

        } catch (error) {
            // Log the error and re-throw it for further handling
            console.error('Error creating case', error);
            throw error;
        }
    }

    async getDocumentTypeIDFromApex(documentType) {
        try {
            const documentTypeID = await getDocumentTypeID({ documentType });
            return documentTypeID;
        } catch (error) {
            console.error('Error fetching document type ID:', error);
            return null;
        }
    }

    async getFileContentFromApex(recordId) {
        try {
            const attachmentData = await getFileContent({ parentId: recordId });
            return attachmentData;
        } catch (error) {
            console.error('Error fetching file content:', error);
            return null;
        }
    }

    constructRequestPayload(invoiceCSID, company, profitId, fileType, fileName, sourceSystem, attachmentHex, employId) {
        return JSON.stringify({
            salesforce_invoice_CSID: invoiceCSID,
            company_id: company,
            profit_ctr_id: profitId,
            document_type_id: fileType,
            file_name: fileName,
            source_system: sourceSystem,
            attachment_hex: attachmentHex,
            employee_id: employId,
        });
    }

    async getAttachmentPostCalloutResponse(endPointURL, requestBody, methodType, Key, Token) {
        try {
            const response = await fetch(endPointURL, {
                method: methodType,
                headers: {
                    'Content-Type': 'application/json',
                    'x-api-key': Key,
                    'x-secret-token': Token
                },
                body: requestBody
            });
            const responseData = await response.text();
            console.log('Response:', responseData);
            return responseData;
        } catch (error) {
            console.error(error.message);
            console.error("Response object:", error.response);
        }
    }

    // Task#77453
    toastEventFire(title, msg, variant, mode) {
        console.log('Inside toast Method');
        const toastEvent = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
            mode: mode,
        });
        this.dispatchEvent(toastEvent);
    }
}