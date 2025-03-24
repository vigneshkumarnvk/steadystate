import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getContactLookup from '@salesforce/apex/ContactLookupController.getContactLookup';
import getAccountDetails from '@salesforce/apex/ContactLookupController.getAccountDetails';

export default class ContactLookupPage extends NavigationMixin(LightningElement) {
    @track leftFields = [
        { id: 'email', label: 'Email', value: '', required: true, isLookup: false },
        { id: 'customer', label: 'Customer', value: '', required: false, isLookup: true, name: '' }
    ];
    @track rightFields = [
        { id: 'firstName', label: 'First Name', value: '', required: false, isLookup: false },
        { id: 'lastName', label: 'Last Name', value: '', required: false, isLookup: false }
    ];
    @track accountBillingAddress = {
        street: '',
        city: '',
        country: '',
        state: '',
        postalCode: ''
        
    }
    @track searchResults = [];
    @track selectedContact = null;
    @track showDatatable = false;
    @track showError = false;
    @track errorMessage = '';
    @track showSpinner = false;
    @track showNextButton = false;
    @api recordId;
    @api selectedRecordTypeId;
   
    @track showNoResultsButton = false;
    columns = [
        {label: 'Contact ID', fieldName: 'ContactId', type:'text'},
        { label: 'First Name', fieldName: 'FirstName', type: 'text' },
        { label: 'Last Name', fieldName: 'LastName', type: 'text' },
        { label: 'Email', fieldName: 'Email', type: 'email' },
        { label: 'Customer', fieldName: 'ContactCompany', type: 'text' },
        { label: 'Phone', fieldName: 'Phone', type: 'phone' }
    ];

    @wire(CurrentPageReference)
    currentPageReference;

    connectedCallback() {
        console.log(this.recordId);
        console.log(this.selectedRecordTypeId);
        this.recordId = this.currentPageReference && this.currentPageReference.state.c__recordId ? this.currentPageReference.state.c__recordId : '';
        console.log('Record ID received from parent component: ' + this.recordId);
        this.fetchAccountBillingAddress();
        this.handleClear();
    }

    fetchAccountBillingAddress() {
        if (this.recordId) {
            getAccountDetails({ accountId: this.recordId })
                .then(result => {
                    if (result) {
                        this.accountBillingAddress.street = result.BillingStreet || '';
                        this.accountBillingAddress.city = result.BillingCity || '';
                        this.accountBillingAddress.country = result.BillingCountryCode || '';
                        this.accountBillingAddress.state = result.BillingStateCode || '';
                        this.accountBillingAddress.postalCode = result.BillingPostalCode || '';
                        console.log(this.accountBillingAddress);
                    }
                }).catch(error => {
                    console.error('Error fetching account Billing Address: '+error);
                });
        }
    }

    handleInputChange(event) {
        const fieldId = event.target.dataset.fieldId || event.target.dataset.id;
        const value = event.target.value.trim();
    
        let fieldToUpdate = this.leftFields.find(field => field.id === fieldId) || this.rightFields.find(field => field.id === fieldId);
        if (fieldToUpdate) {
            fieldToUpdate.value = value;
    
            if (fieldToUpdate.id === 'customer') {
                fieldToUpdate.name = value; 
    
                this.fetchCustomerName(value); 
            }
        }
    
        this.updateSearchCriteria();
    }
    

    updateSearchCriteria() {
        this.searchCriteria = {
            email: this.leftFields.find(field => field.id === 'email').value,
            firstName: this.rightFields.find(field => field.id === 'firstName').value,
            lastName: this.rightFields.find(field => field.id === 'lastName').value,
            customer: this.leftFields.find(field => field.id === 'customer').value // Use name property for customer
        };

        console.log('Updated Search Criteria:', this.searchCriteria); // Log updated criteria
    }

    handleLookup() {
        // Validate email field
        const emailField = this.leftFields.find(field => field.id === 'email');
        if (!emailField.value) {
            this.showError = true;
            this.errorMessage = 'Email is required.';
            this.showDatatable = false;
            this.showNextButton = false;
            this.showNoResultsButton = false;
            this.searchResults = [];
            return;
        }

        this.showSpinner = true;
        this.updateSearchCriteria();

        const criteria = JSON.stringify(this.searchCriteria);

        getContactLookup({ model: criteria })
            .then(result => {
                if (result && result.contactList) {
                    this.searchResults = result.contactList.map(contact => ({
                        ...contact,
                        'ContactCompany': contact.ContactCompany ? contact.ContactCompany : null     
                    }));
                    if (this.searchResults.length === 0) {

                        this.showError = true;
                        this.errorMessage = 'No results found.';
                        this.showNoResultsButton = true;
                        this.showNextButton = false;
                    } else {
                        this.showError = false;
                        this.errorMessage = '';
                        this.showNextButton = true;
                        this.showNoResultsButton = false;
                    }
                } else {
                    this.showError = true;
                    this.errorMessage = 'No results found.';
                    this.showNextButton = true;
                    this.showNoResultsButton = true; 
                    this.searchResults = [];
                }
                this.showDatatable = this.searchResults.length > 0;
            })
            .catch(error => {
                console.error('Error in handleLookup: ', error);
                this.showError = true;
                this.errorMessage = 'Error fetching lookup results.';
                this.showNextButton = false;
                this.showDatatable = false;
                this.showNoResultsButton = false;
                this.showSpinner = false;
            })
            .finally(() => {
                this.showSpinner = false;
            });
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.selectedContact = selectedRows[0];
        } else {
            this.selectedContact = null;
        }
    }

    handleNext() {
        const selectedRecordTypeId = this.selectedRecordTypeId;
        if (selectedRecordTypeId) {
            let defaultFieldValues = `AccountId=${this.recordId}`;
            if (this.selectedContact) {
                const contact = this.selectedContact;
                defaultFieldValues += `,FirstName=${contact.FirstName},LastName=${contact.LastName},Email=${contact.Email},Phone=${contact.Phone},EQAI_Contact_Id__c=${contact.ContactId}`;
            }
            defaultFieldValues += `,MailingStreet=${this.accountBillingAddress.street},MailingCity=${this.accountBillingAddress.city},MailingPostalCode=${this.accountBillingAddress.postalCode},MailingCountryCode=${this.accountBillingAddress.country},MailingStateCode=${this.accountBillingAddress.state}`;

            let urlWithParameters = `/lightning/o/Contact/new?&recordTypeId=${selectedRecordTypeId}&defaultFieldValues=${defaultFieldValues}`;

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: urlWithParameters
                }
            }, true);
        } else {
            let urlWithParameters = `/lightning/o/Contact/new?&recordTypeId=${this.selectedRecordTypeId}&defaultFieldValues=AccountId=${this.recordId}`;

            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: urlWithParameters
                }
            }, true);
        }
    }

    handleCreateNew() {
        let defaultFieldValues = `AccountId=${this.recordId}`;
        defaultFieldValues += `,MailingStreet=${this.accountBillingAddress.street},MailingCity=${this.accountBillingAddress.city},MailingPostalCode=${this.accountBillingAddress.postalCode},MailingCountryCode=${this.accountBillingAddress.country},MailingStateCode=${this.accountBillingAddress.state}`;
        let urlWithParameters = `/lightning/o/Contact/new?&recordTypeId=${this.selectedRecordTypeId}&defaultFieldValues=${defaultFieldValues}`;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: urlWithParameters
            },
        }, true);
    }

    handleClear() {
        // Clear input fields and reset their values
        this.leftFields.forEach(field => {
            field.value = '';
            if (field.id === 'customer') {
                field.name = ''; // Clear name property
            }
        });
        this.rightFields.forEach(field => {
            field.value = '';
        });

        // Reset UI state
        this.showDatatable = false;
        this.showNextButton = false;
        this.searchResults = [];
        this.selectedContact = null;
        this.showError = false;
        this.showNoResultsButton = false;
        this.errorMessage = '';

        // Clear any lingering field values in DOM (if necessary)
        let customerField = this.template.querySelector('[data-id="customer"]');
        if (customerField) {
            customerField.value = '';
        }
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    showErrorToast(message) {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }

    fetchCustomerName(accountId) {
        getAccountDetails({ accountId })
            .then(result => {
                if (result && result.Name) {
                    console.log(result);
                    this.leftFields.find(field => field.id === 'customer').value = result.Name;
                } else {
                    console.error('Customer name not found for the selected account.');
                }
            })
            .catch(error => {
                console.error('Error fetching customer name:', error);
            });
    }
    
    
}