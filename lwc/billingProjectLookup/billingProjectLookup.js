import { LightningElement, wire, api, track } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import BILLING_PROJECT_LOOKUP_MESSAGE_CHANNEL from '@salesforce/messageChannel/BillingProjectLookupMessageChannel__c';
import getBillingPackageLookup from "@salesforce/apex/BillingProjectLookupController.getBillingPackageLookup";

const DATATABLE_PAGE_SIZE = 10;
export default class BillingProjectLookup extends LightningElement {
    @api name = 'Billing Project Lookup';
    @api helpText = 'PLEASE NOTE: When pre-selecting a Billing Project from EQAI, please make sure the billing contact, surcharge type, payment terms and other key billing attributes entered on the Sales Order do not conflict with the selected Billing Project.'
    @api mode;
    @api customerId;
    @api profitcenterId;
    @api companyId;
    @api serviceCenter;
    

    @track selectedRowData = [];
    @track disabledSelect = true;
    @track _customerId;
    @track _profitcenterId;
    @track _companyId;
    @track _serviceCenter;

    searchAllResults = [];
    searchResults = [];
    showError = false;
    showSpinner = false;
    errorMessage = '';
    showDatatable = false;
    showCloseButton = false;

    searchResultColumns = [
        { id : '1', label : 'Proj. ID', fieldName: 'projectId', type: 'text', initialWidth: 75 },
        { id : '2', label : 'Billing Project Name', fieldName: 'projectname', type: 'text', initialWidth: 150 },
        { id : '2', label : 'Fee', fieldName: 'fee', type: 'text', initialWidth: 75 },
        { id : '3', label : 'Status', fieldName: 'status', type: 'text', initialWidth: 100 },
        { id : '4', label : 'Purchase Order', fieldName: 'purchaseorder', type: 'text', initialWidth: 100 },
        { id : '5', label : 'Release', fieldName: 'release', type: 'text', initialWidth: 100 },
        { id : '6', label : 'PO Description', fieldName: 'podescription', type: 'text', initialWidth: 150 },
        { id : '7', label : 'PO Amount', fieldName: 'poamount', type: 'text', initialWidth: 150 },
        { id : '8', label : 'Start Date', fieldName: 'startdate', type: 'text', initialWidth: 100 },
        { id : '9', label : 'Expiration Date', fieldName: 'expirationdate', type: 'text', initialWidth: 150 },
        { id : '10', label : 'Link Reqd', fieldName: 'link', type: 'text', initialWidth: 100 },
        { id : '11', label : 'ES Territory', fieldName: 'esterritory', type: 'text', initialWidth: 150 },
        { id : '12', label : 'ES AE', fieldName: 'esae', type: 'text', initialWidth: 100 },
        { id : '13', label : 'FIS Territory', fieldName: 'fisterritory', type: 'text', initialWidth: 150 },
        { id : '14', label : 'FIS AE', fieldName: 'fisae', type: 'text', initialWidth: 100 },
        { id : '15', label : 'Distribution method', fieldName: 'distributionmethod', type: 'text', initialWidth: 150 },
        { id : '16', label : 'Contact Name', fieldName: 'contactname', type: 'text', initialWidth: 200 },
        { id : '17', label : 'Contact E-mail', fieldName: 'contactemail', type: 'text', initialWidth: 200 },
        { id : '18', label : 'Fee Type', fieldName: 'feetype', type: 'text', initialWidth: 100 },
        { id : '19', label : 'E-manifest Fee', fieldName: 'manifestfee', type: 'text', initialWidth: 150 }
    ];
    
    @wire(MessageContext) messageContext;

    connectedCallback(){
        this.getModel();
    }

    getModel(){
        this._customerId = this.customerId;
        this.showSpinner = true;
        if (this.mode === 'create'){
            this.showCloseButton = true;
        }
        this.showSpinner = false;
        this.getBillingPackageLookup();
    }

    getBillingPackageLookup(){
        this.showSpinner = true;
        this.errorMessage = '';
        this.showError = false;
        this.showDatatable = false;
        this.showCloseButton = false;
        this.searchAllResults = [];
        getBillingPackageLookup( { customerId: this.customerId,  serviceCenter : this.serviceCenter})
        .then((result) => {
            if (result.generatorStateResult && result.generatorStateResult.length > 0) {
                this.searchAllResults = result.generatorStateResult;
                this.showDatatable = result.generatorStateResult.length > 0;
                this.searchResults = this.searchAllResults;
                this.showCloseButton = true;
            } else {
                this.errorMessage = 'No data found';
                this.showError = true;
                this.showDatatable = false;
                this.showCloseButton = true;
            }
        })
        .catch((error) => {
            this.errorMessage = JSON.stringify(error.body.message);
            this.showError = true;
        })
        .finally( () => {
            this.showSpinner = false;
        })
    }

    handleRowSelection(event) {
        this.selectedRowData = [];
        let selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 1) {
            this.disabledSelect = false;
            let dtLookUp = this.template.querySelector('lightning-datatable');
            selectedRows = dtLookUp.selectedRows = dtLookUp.selectedRows.slice(1);
            this.selectedRowData = event.detail.selectedRows[event.detail.selectedRows.length - 1];
            event.preventDefault();
            return;
        } else {
            this.disabledSelect = false;
            this.selectedRowData = selectedRows[selectedRows.length - 1];
        }
    }

    handleSelect(event) {
        this.sendResponseToAura();
    }

    sendResponseToAura() {
        const messagePayload = {
            dataToSend : this.selectedRowData
        };
        publish(this.messageContext, BILLING_PROJECT_LOOKUP_MESSAGE_CHANNEL,messagePayload)
        
    }

    handleClose() {
        publish(this.messageContext, BILLING_PROJECT_LOOKUP_MESSAGE_CHANNEL, { dataToSend : 'close' });
     }
}