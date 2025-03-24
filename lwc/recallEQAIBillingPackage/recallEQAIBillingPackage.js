import { LightningElement, wire, api} from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from "lightning/actions";
import updateDocumentStatus from '@salesforce/apex/RecallEQAIBillingPackageCtrl.updateDocumentStatus';

export default class RecallEQAIBillingPackage extends LightningElement {


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

        updateDocumentStatus({ invoiceId: this.recordId })
            .then(result => {
                if(result === 'Open') {
                    const event = new ShowToastEvent({
                        title: 'The sales invoice document status has been updated to "Open"',
                        variant: 'success'
                    })
                    this.dispatchEvent(event);
                    this.dispatchEvent(new CloseActionScreenEvent);
            } else {
                const event = new ShowToastEvent({
                    title: 'You have already recalled the EQAI Billing Package.',
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