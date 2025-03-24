import { LightningElement, wire, api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import createCaseRecord from '@salesforce/apex/RecallSubmittedEQAIBillingPackageCtrl.createCaseRecord';
import { CloseActionScreenEvent } from "lightning/actions";

export default class recallSubmittedEQAIBillingPackageRequest extends LightningElement {
   
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        if(currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            if(!this.recordId) {
                console.error('Record Id not found');
            }
        }
    }

    connectedCallback() {

        // Call the Apex method to create the Case record
        createCaseRecord({ invoiceId: this.recordId })
            .then(result => {
                console.log(result);
                if(result === 'Success') {
                    const event = new ShowToastEvent({
                        title: 'A case has been successfully created to recall the submitted EQAI Billing Package.',
                        variant: 'success'
                    })
                    this.dispatchEvent(event);
                    this.dispatchEvent(new CloseActionScreenEvent);
            } else {
                const event = new ShowToastEvent({
                    title: 'A case has already been created for this Sales Invoice.',
                    variant: 'error'
                })
                this.dispatchEvent(event);
                this.dispatchEvent(new CloseActionScreenEvent);
            }
        })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                })
            )
            this.dispatchEvent(new CloseActionScreenEvent);
        });      
    }
}