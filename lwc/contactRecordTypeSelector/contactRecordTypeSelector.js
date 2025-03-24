/**
 * @description       : 
 * @author            : Pavithra Periyasamy
 * @group             : 
 * Modifications Log 
 * Ver   Date         Author         Modification
 * 1.0   07-05-2024   Pavithra P     US117360: [Continued] Salesforce - "Create Contact" Custom Component to accommodate Contact Lookup function
**/

import { LightningElement, wire, api } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import CONTACT_OBJECT from "@salesforce/schema/Contact";
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from "lightning/navigation";
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import getRecordTypesForUser from '@salesforce/apex/WorkOrderAttachmentInfo.getRecordTypesForUser';



export default class ContactRecordTypeSelector extends NavigationMixin(LightningElement) {
  @api recordId;
  @api objectApiName;
  @api accountId; // Account Id passed to this component


  selectedRecordTypeValue = '';
  selectedRecordTypeName;
  options = [];
  recordTypeInfo;
  recordPageUrl;
  isModalOpen = false;

  currentPageReference;
recordId = '';

  userId = Id;
  userProfileValue = false;

  connectedCallback(){

    console.log('-----RecordId'+this.recordId);
    console.log('------AccountId'+this.accountId);
  }

  handleCancel(){
    console.log('cancelling');
  }

  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    this.isModalOpen = false;
    this.selectedRecordTypeValue = '';

    this.currentPageReference = currentPageReference;
    if (this.currentPageReference.state) {
      this.selectedRecordTypeValue = '';
      let recId = this.currentPageReference.state.c__recordId;
      this.recordId = recId != null && recId != undefined && recId != "" ? recId : "";
    }
  }

  @wire(getRecordTypesForUser)
  wiredRecordTypes({ error, data }) {
    if (data) {
      try {
        this.options = data.map(option => ({
          label: option.label,
          value: option.value
        }));
        this.options.reverse(); 
        console.log('Options:', JSON.stringify(this.options)); // Debugging line
      } catch (e) {
        console.error('Error processing record type data:', e);
      }
    } else if (error) {
      console.error('Error fetching record types: ', error);
    }
  }

  handleChange(event) {
    this.selectedRecordTypeValue = event.detail.value;
    this.selectedRecordTypeName = this.options.find(option => option.value === this.selectedRecordTypeValue)?.label;
  }
  //Handling Next
  handleNext() {

    let isValid = this.validateInput();
    console.log('RecordType Id ' + this.selectedRecordTypeValue + '\n isValid ' + isValid);
    if (isValid) {
      if (this.selectedRecordTypeName == 'Contacts') {
        this.isModalOpen = true;
        //this.navigateToComponent();
      } else {
        let urlWithParameters = `/lightning/o/Contact/new?&recordTypeId=` + this.selectedRecordTypeValue + `&defaultFieldValues=AccountId=${this.recordId}`;
        this[NavigationMixin.Navigate]({
          type: "standard__webPage",
          attributes: {
            url: urlWithParameters
          },
        },
          true,
        );
      }
    }

  }

  validateInput() {
    var inputCmp = this.template.querySelector('.inputCmp');
    var value = this.selectedRecordTypeValue;
    // is input valid text?
    if (value === undefined || value == "") {
      inputCmp.setCustomValidity('Please select a record type to proceed Next');
      inputCmp.reportValidity();
      return false;
    } else {
      inputCmp.setCustomValidity(''); // if there was a custom error before, reset it
      inputCmp.reportValidity();
      return true;
    }

  }
  handleCancel() {
    if (this.recordId != '') {
      //navigateToRecordpage();
      this[NavigationMixin.Navigate](
        {
          type: 'standard__recordPage',
          attributes: {
            recordId: this.recordId,
            actionName: 'view',
          },
        },
        false,
      );

    } else {
      this.navigateToListView();
    }
    this.isModalOpen = false;
  }
  navigateToListView() {
    // Navigate to the Contact object's Recent list view.
    this[NavigationMixin.Navigate]({
      type: "standard__objectPage",
      attributes: {
        objectApiName: "Contact",
        actionName: "list",
      },
      state: {
        filterName: "Recent",
      },
    });
  }

  handleCloseModal() {
    this.isModalOpen = false;
  }

}