import { LightningElement } from 'lwc';
import LightningConfirm from 'lightning/confirm';

export default class QuoteOrder_LOA_Reminder extends LightningElement {

    connectedCallback() {
        this.handleLightningConfirm();
    }

    async handleLightningConfirm() {
        const result = await LightningConfirm.open({
            message: 'The Sales Quote/Order is over $30,000. Please follow the Company\'s Environmental Solutions Levels of Authority Policy.',
            variant: 'header',
            label: 'Warning!',
            theme: 'warning'
        });
        if (result != '' || result != undefined) {
            this.dispatchEvent(new CustomEvent(
                'getLWCResult',
                {
                    detail: { result: result },
                    bubbles: true,
                    composed: true,
                }
            ));
        }
    }
}