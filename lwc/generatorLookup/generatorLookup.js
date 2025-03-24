import { LightningElement, wire, api, track } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import GENERATOR_MESSAGE_CHANNEL from '@salesforce/messageChannel/GeneratorMessageChannel__c';
import GENERATOR_MESSAGE_CHANNEL_FOR_CREATE from '@salesforce/messageChannel/GeneratorMessageChannelForCreate__c';
import SALES_ORDER_SITE_FIELD_CONTROL_CHANNEL from '@salesforce/messageChannel/SalesOrderSiteFieldControlChannel__c';
import getGeneratorLookup from "@salesforce/apex/GeneratorLookupController.getGeneratorLookup";

const DATATABLE_PAGE_SIZE = 10;
export default class GeneratorLookup extends LightningElement {
    @api name = 'Generator Lookup';
    @api epaId;
    @api siteName;
    @api siteStreet;
    @api siteCity;
    @api siteState;
    @api sitePostalCode;
    @api mode;

    @track selectedRowData = [];
    @track disabledSelect = true;
    @track _epaId = '';
    @track _siteName = '';
    @track _siteStreet = '';
    @track _siteCity = '';
    @track _siteState = '';
    @track _sitePostalCode = '';

    searchAllResults = [];
    searchResults = [];
    showError = false;
    showSpinner = false;
    errorMessage = '';
    showDatatable = false;
    showCloseButton = false;
    helpTextDisplay = true;

    searchResultColumns = [
        { id : '1', label : 'Site Location', fieldName: 'siteLocation', type: 'text', initialWidth: 130},
        { id : '2', label : 'EPA Id', fieldName: 'epaId', type: 'text', initialWidth: 150 },
        { id : '3', label : 'Name', fieldName: 'name', type: 'text', initialWidth: 300 },
        { id : '4', label : 'Street Address', fieldName: 'streetAddress', type: 'text', initialWidth: 300 },
        { id : '5', label : 'City', fieldName: 'city', type: 'text', initialWidth: 100 },
        { id : '6', label : 'State', fieldName: 'state', type: 'text', initialWidth: 100 },
        { id : '7', label : 'Zip', fieldName: 'zip', type: 'text', initialWidth: 100 },
        { id : '8', label : 'Business Phone', fieldName: 'businessPhone', type: 'text', initialWidth: 100 },
        { id : '9', label : 'NAICS Id', fieldName: 'naicsId', type: 'integer', initialWidth: 100 },
        { id : '10', label : 'EQAI Generator Id', fieldName: 'eqaiGeneratorId', type: 'integer', initialWidth: 100 }
    ];
    searchRightFields = [
        { id: '1', label: 'EPA ID :', value: '' },
        { id: '2', label: 'Site Name :', value: '' },
        { id: '3', label: 'Site Street :', value: '' }
    ];
    searchLeftFields = [
        { id: '4', label: 'Site City :', value: '',required: false },
        { id: '5', label: 'Site State :', value: '',required: false },
        { id: '6', label: 'Site Postal Code :', value: '',required: false }
    ];

    @wire(MessageContext) messageContext;

    connectedCallback(){
        this.getModel();
    }

    getModel(){
        this.showSpinner = true;
        if (this.mode === 'create'){
            this.showCloseButton = true;
        }
        this.searchRightFields = this.searchRightFields.map(inputItem => {
            if(inputItem.id === '1'){
                this._epaId = this.epaId;
                inputItem.value = this.epaId;
            } else if (inputItem.id === '2'){
                this._siteName = this.siteName;
                inputItem.value = this.siteName;
            } else if (inputItem.id === '3'){
                this._siteStreet = this.siteStreet;
                inputItem.value = this.siteStreet;
            } 
            return inputItem;
        });
        this.searchLeftFields = this.searchLeftFields.map(inputItem => {
            if (inputItem.id === '4'){
                this._siteCity = this.siteCity;
                inputItem.value = this.siteCity;
            } else if (inputItem.id === '5'){
                this._siteState = this.siteState;
                inputItem.value = this.siteState;
            } else if (inputItem.id === '6'){
                this._sitePostalCode = this.sitePostalCode;
                inputItem.value = this.sitePostalCode;
            }
            return inputItem;
        });
        this.showSpinner = false;
    }

    getGeneratorLookup(generatorModel){
        this.showSpinner = true;
        this.errorMessage = '';
        this.showError = false;
        this.showDatatable = false;
        this.searchAllResults = [];
        getGeneratorLookup( { model: generatorModel })
        .then((result) => {
            if (result.generatorStateResult && result.generatorStateResult.length > 0) {
                this.searchAllResults = result.generatorStateResult;
                this.showDatatable = result.generatorStateResult.length > 0;
                this.searchResults = this.searchAllResults;
            } else {
                this.errorMessage = 'No data found';
                this.showError = true;
                this.showDatatable = false;
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
        if (this.mode === 'create'){
            publish(this.messageContext, GENERATOR_MESSAGE_CHANNEL_FOR_CREATE, messagePayload);
        } else {
            publish(this.messageContext, GENERATOR_MESSAGE_CHANNEL, messagePayload);
        }
    }

    handleInputChange(event) {
        const fieldId = event.target.dataset.fieldId;
        const fieldValue = event.target.value;
        if (fieldId === '1') {
            this._epaId = fieldValue; 
        } else if (fieldId === '2') {
            this._siteName = fieldValue;
        } else if (fieldId === '3') {
            this._siteStreet = fieldValue;
        } else if (fieldId === '4') { 
            this._siteCity = fieldValue;
        } else if (fieldId === '5') {   
            this._siteState = fieldValue;
        } else if (fieldId === '6') {
            this._sitePostalCode = fieldValue;
        } 
    }

    handleSearchResult(){
        this.handleEnableFields();
        let generatorModel = {};
        this.showError = false;
        this.errorMessage = '';
        if (this.validateGeneratorLookUp()){
            generatorModel.epaId = this._epaId;
            generatorModel.generatorName = this._siteName;
            generatorModel.generatorAddress = this._siteStreet;
            generatorModel.generatorCity = this._siteCity;
            generatorModel.generatorZipCode = this._sitePostalCode;
            generatorModel.generatorState = this._siteState;
            this.getGeneratorLookup(generatorModel);
        } else {
            //this.errorMessage = 'Please enter at least one value to search on'
            this.errorMessage ='Please enter EPA ID or City and State when entering a Site Generator search';
            this.helpTextDisplay = false;
            this.showError = true;
        }
    }

    validateGeneratorLookUp() {
        let isEPAIdFilled = false;
        let isCityStateFilled = true;
        this.template.querySelectorAll('lightning-input').forEach(element => {
            if(element.label.trim() == 'EPA ID :'){
                if (element.value && element.value.trim() !== '') {
                    isEPAIdFilled  = true;
                }
            }

            if(element.label.trim() == 'Site City :' || element.label.trim() == 'Site State :'){
                if (element.value.trim() == '') {
                    //isAnyFieldFilled = false;
                    isCityStateFilled = false;
                }
            }
        });

        return isEPAIdFilled || isCityStateFilled;
    }

    handleClear() {
       this.showSpinner = true;
       this.template.querySelectorAll('lightning-input').forEach(element => element.value = '');
       this.errorMessage = ''
       this.showError = false;
       this.helpTextDisplay = true;
       this.showDatatable = false;
       this.showSpinner = false;
       this._epaId = ''; 
       this._siteName = '';
       this._siteStreet = '';
       this._siteCity = '';
       this._siteState = '';
       this._sitePostalCode = '';
    }

    handleClose() {
        publish(this.messageContext, GENERATOR_MESSAGE_CHANNEL_FOR_CREATE, { dataToSend : 'close' });
     }

     
    handleEnableFields() {
        publish(this.messageContext, SALES_ORDER_SITE_FIELD_CONTROL_CHANNEL, { fieldsVisible : true });
    }
}