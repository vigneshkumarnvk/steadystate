import { LightningElement, api, wire, track} from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";

import processKronosTimePunch from '@salesforce/apex/LWCResourceController.processKronosTimePunch';
import isUserAdmin from '@salesforce/apex/ResourceController.isSystemAdmin';

import LABOR_NAME from '@salesforce/schema/Resource__c.Description__c';
import EMPLOYEE_NO from '@salesforce/schema/Resource__c.Name';
const fields = [LABOR_NAME, EMPLOYEE_NO];

export default class ResourceProcessKronosTimePunch extends LightningElement {
    @api recordId;
    isLoaded = true;
    actionType = 'processEntries'
    startDate;
    endDate;
    confirmationMsg = '';
    disabledMsg = '';
    isAdmin = false;
    showDisabledModal = false;
    
    @wire(isUserAdmin)
    wiredIsUserAdmin({ error, data }) {
        console.log(data);
        if (data) {
            console.log(data);
            this.isAdmin = data;
            this.isloaded = true;
            this.showDisabledModal = false;
        } else if (error) {
            this.isloaded = true;
            console.error('Error checking user admin status: ', error);
        }
    }

    connectedCallback() {
        if(!this.isAdmin) {
            this.showDisabledModal = true;
            this.disabledMsg = 'This functionality is disabled for your profile.  Please contact your System Administrator if you need access.'
        }
    }

    handleDisabledModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }


    @wire(getRecord, {recordId: '$recordId', fields})
    laborResource;

    get name(){
        return getFieldValue(this.laborResource.data, LABOR_NAME);
    }

    get employeeNo(){
        return getFieldValue(this.laborResource.data, EMPLOYEE_NO);
    }

    get actionTypeOptions() {
        return [
            {label: 'Manually Process Time Punch Entries', value: 'processEntries'},
            {label: 'Remove Time Punch Entries', value: 'removeEntries'},
        ];
    }

    handleChange(event) {
        const field = event.target.name;
        if(field === 'startDate') {
            this.startDate = event.target.value;
        } else if (field === 'endDate') {
            this.endDate = event.target.value;
        } else if (field === 'actionType') {
            this.actionType = event.detail.value;
        }
        if(this.actionType === 'processEntries'){
            this.confirmationMsg = 'Are you sure want to manually process Kronos time punch entries for ' + this.name +  '(' + this.employeeNo + ')'+ ' for time period: ' + this.startDate + ' - ' + this.endDate;
        } else if (this.actionType === 'removeEntries'){
            this.confirmationMsg = 'Are you sure want to remove Kronos time punch entries for ' + this.name +  '(' + this.employeeNo + ')' + ' for time period: ' + this.startDate + ' - ' + this.endDate;
        }
    }

    handleClick(event){
        const field = event.target.name;
        if(field === 'okButton') {
            this.handleSuccess(event);
        } else if (field === 'cancelButton'){
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    isInputValid(){
        let isValid = true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        return isValid;
    }

    handleSuccess(e) {
        //Close the modal window and display a success toast
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Kronos time punch processed!',
                variant: 'success'
            })
        );
    }

    handleShowModal() {
        if(this.isInputValid()) {
            const modal = this.template.querySelector('c-lwc-modal');
            modal.show();
        }
    }

    handleCancelModal() {
        const modal = this.template.querySelector('c-lwc-modal');
        modal.hide();
    }

    processKronosTimePunch(event){
        this.isLoaded = false;

        processKronosTimePunch({actionType: this.actionType,  resourceId: this.recordId, startDate: this.startDate, endDate: this.endDate})
            .then(result => {
                this.isLoaded = true;
                this.handleSuccess(event);
            })
            .catch(error => {
                console.log('Error: ' + JSON.stringify(error));
                this.isLoaded = true;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error while processing Kronos entries',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            });
    }
}