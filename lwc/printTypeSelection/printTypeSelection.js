//ticket 19127 <<
//import {LightningElement, api} from 'lwc';
import {LightningElement, api, wire, track} from 'lwc';
import getJobTasks from'@salesforce/apex/FileUploadHandler.getJobTasks';
//ticket 19127 >>

export default class PrintTypeSelection extends LightningElement {
    //ticket 19127 <<
    //@api printType = 'TM Detail';
    @api recordId;
    @api jobTasks;
    //ticket 19127 >>

    get printTypeOptions(){
        return [
            {label: 'Detail', value: 'Detail'},
            {label: 'Summary', value: 'Summary'},
            {label: 'By Date by Category', value: 'By Date by Category'}
        ]
    }

    //ticket 19127 <<
    connectedCallback() {
        getJobTasks({ recordId: this.recordId} )
            .then(result => {
                this.jobTasks = result;
                /*
                this.jobTasks.forEach(function(jobTask) {
                    //jobTask.label = 'Task #' + jobTask.Task_No__c + ' - ' + jobTask.Name;
                    jobTask.label = 'Task #' + jobTask.Task_No__c + ' - ' + jobTask.Name;
                });
                 */
            }).catch(error => {
            alert(error.body.message);
        });
    }
    //ticket 19127 >>

    //ticket 19127 <<
    /*
    handleChange(event){
        this.printType = event.target.value;
        //Create the event with the data
        const selectedEvent = new CustomEvent("printtypevaluechange", {
            detail: this.printType
        });

        //Dispatches the event.
        this.dispatchEvent(selectedEvent);
    }
    */
    handleInvoiceFormatChange(event) {
        let name = event.target.name;
        let value = event.target.value;
        for (var i = 0; i < this.jobTasks.length; i++) {
            if (this.jobTasks[i].Id === name) {
                this.jobTasks[i].Invoice_Format__c = value;
                break;
            }
        }
    }
    //ticket 19127 >>
    handlePrintOrderChange(event) {
        let name = event.target.name;
        let value = event.target.value;
        for (var i = 0; i < this.jobTasks.length; i++) {
            if (this.jobTasks[i].Id === name) {
                this.jobTasks[i].Print_Order__c = value;
                break;
            }
        }
    }
}