import { LightningElement,api,track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSalesOrder from '@salesforce/apex/ACVSalesOrderController.getSalesOrder';

export default class ShowMessageFromEQAI extends LightningElement {
    @api recordId;
    @track resultInfo;

    connectedCallback(){
      
      setTimeout(() => {
        getSalesOrder({ "salesOrderId": this.recordId })
        .then(data => {
          let result = JSON.parse(data);
            if(
                result.SalesOrder!= null &&
                result.SalesOrder.EQAI_Response__c != null &&
                result.SalesOrder.EQAI_Response__c.includes('Error')
              ){
                const event = new ShowToastEvent({
                  title: 'Error',
                  message:  result.SalesOrder.EQAI_Response__c ,
                  variant: 'error',
                  mode: 'sticky'
              });
              this.dispatchEvent(event);
          }
        })
        .catch(error => {
          
        });
      }, "8000");
      
    }
    
     
}