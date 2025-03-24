import { LightningElement, api, track } from 'lwc';
import { CloseActionScreenEvent } from "lightning/actions";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import lwcCloneAndScheduleTM from '@salesforce/apex/LWCTMController.cloneAndScheduleTM';

export default class TmCloneAndSchedule extends NavigationMixin(LightningElement) {
    @api recordId;
    @track scheduleDate;
    @track isLoaded = true;

    handleScheduleDateChange(event){
        if(event.target.name === 'scheduleDate'){
            this.scheduleDate = event.target.value;
        }
    }

    handleCancel(event){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleCloneAndSchedule(event) {
        const isInputValid = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        if (isInputValid) {
            this.isLoaded = false;
            lwcCloneAndScheduleTM({tmId: this.recordId, scheduledDate: this.scheduleDate})
                .then(result => {
                    this.isLoaded = true;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'T&M Successfully Cloned and Scheduled',
                            message: 'You have successfully cloned and scheduled T&M!',
                            variant: 'Success',
                        }),
                    );
                    this.dispatchEvent(new CloseActionScreenEvent());
                    console.log('result: ' + JSON.stringify(result));
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: result,
                            objectApiName: 'TM__c',
                            actionName: 'view'
                        }
                    });
                })
                .catch(error =>{
                    this.isLoaded = true;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error cloning T&M',
                            message: error.body.message,
                            variant: 'error',
                        }),
                    );
                });
        }
    }
}