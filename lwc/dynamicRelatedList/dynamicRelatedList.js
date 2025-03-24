import { LightningElement, wire, api, track } from 'lwc';
import BaseLWC from "c/baseLWC";
import { deleteRecord, getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import SO_NAME_FIELD from "@salesforce/schema/Sales_Order__c.Name";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import { getRelatedListRecords } from 'lightning/uiRelatedListApi';

const SO_FIELDS = [SO_NAME_FIELD];

export default class DynamicRelatedList extends NavigationMixin(BaseLWC) {

    //fetches value from url
    isViewAll = false;

    @api recordId;
    @api objectApiName;

    error;
    columns;
    records = [];
    parentObjectInfo;
    relatedObjectInfo;
    relatedObjectApiName;
    title;
    recordCount;
    modal;
    header;
    content;
    rId;
    rName;
    recordUrl;
    sortedByLabel;
    sortedBy;
    sortedDirection;
    relatedListId;
    queryFields;
    whereCondition;
    sortBy;
    pageSize;
    hasRendered = false;

    connectedCallback() {
        if (this.objectApiName == 'Sales_Order__c') {
            this.initSalesOrder();
        }
    }

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageRef) {
        if (currentPageRef) {
            if (currentPageRef.state.c__recordId) {
                this.recordId = currentPageRef.state.c__recordId;
            }
            if (currentPageRef.state.c__objectApiName) {
                this.objectApiName = currentPageRef.state.c__objectApiName;
            }
            if (currentPageRef.state.c__isViewAll) {
                this.isViewAll = currentPageRef.state.c__isViewAll;
            }
        }
    }

    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    objectInfo;

    @wire(getObjectInfo, { objectApiName: '$relatedObjectApiName' })
    relatedObjectInfo;

    get iconName() {
        if (this.relatedObjectInfo.data) {
            const iconUrl = this.relatedObjectInfo.data.themeInfo.iconUrl.split('.png')[0];
            const urlParams = iconUrl.split("/");
            const len = urlParams.length;
            return urlParams[len - 2] + ':' + urlParams[len - 1].split("_")[0];
        }
        return '';
    }

    get labelPlural() {
        if (this.objectInfo.data) {
            return this.objectInfo.data.labelPlural;
        }
        return '';
    }

    @wire(getRecord, { recordId: "$recordId", fields: SO_FIELDS })
    recordInfo;

    get name() {
        return getFieldValue(this.recordInfo.data, SO_NAME_FIELD);
    }

    get hasRelatedRecords() {
        if (typeof (this.recordCount) === 'string') {
            return true;
        }
        return this.recordCount > 0 ? true : false;
    }

    @wire(getRelatedListRecords, {
        parentRecordId: '$recordId',
        relatedListId: '$relatedListId',
        fields: '$queryFields',
        where: '$whereCondition',
        sortBy: '$sortBy',
        pageSize: '$pageSize',
    })
    relatedListRecords({ error, data }) {
        if (data) {
            this.recordUrl = '/' + this.recordId;
            if (this.objectApiName == 'Sales_Order__c') {
                this.records = data.records.map(item => {
                    const record = {};
                    for (const key in item.fields) {
                        if (key == 'Id') {
                            record['NameLink'] = '/' + item.fields[key].value;
                        }
                        if (key == 'Bill_to_Customer_No__r') {
                            record['Bill_to_Customer_No__c'] = item.fields?.Bill_to_Customer_No__r?.displayValue;
                        }
                        if (key == 'Project_Coordinator__r') {
                            record['Project_Coordinator__c'] = item.fields?.Project_Coordinator__r?.displayValue;
                        }
                        record[key] = item.fields[key].value;
                    }
                    return record;
                });
                this.recordCount = this.records.length;
                if (!this.isViewAll && this.recordCount > 3) {
                    this.records.splice(3);
                    this.recordCount = '3+';
                }
                this.error = undefined;
            }
        } else if (error) {
            this.error = error;
            this.recordCount = 0;
            this.records = undefined;
        }
    }

    renderedCallback() {
        if (!this.hasRendered) {
            this.modal = this.template.querySelector('c-lwc-modal');
        }
    }

    initSalesOrder() { //Initialize the values needed if the compnent is placed in Quote/Order RelatedList
        const ACTIONS = [
            { label: 'Edit', name: 'edit' },
            { label: 'Delete', name: 'delete' }
        ];

        const COLUMNS = [
            {
                label: 'No', fieldName: 'NameLink', type: 'url', sortable: this.isViewAll, hideDefaultActions: !this.isViewAll,
                typeAttributes: { label: { fieldName: 'Name' } }
            },
            { label: 'Bill-to Customer', fieldName: 'Bill_to_Customer_No__c', sortable: this.isViewAll, hideDefaultActions: !this.isViewAll },
            { label: 'Project Manager', fieldName: 'Project_Coordinator__c', sortable: this.isViewAll, hideDefaultActions: !this.isViewAll },
            { label: 'Quote Date', fieldName: 'Quote_Date__c', sortable: this.isViewAll, hideDefaultActions: !this.isViewAll },
            { label: 'Quote Status', fieldName: 'Quote_Status__c', sortable: this.isViewAll, hideDefaultActions: !this.isViewAll },
            {
                type: 'action',
                typeAttributes: { rowActions: ACTIONS },
            },
        ];
        this.columns = COLUMNS;

        this.relatedListId = 'Sales_Orders__r';
        this.queryFields = ['Sales_Order__c.Id', 'Sales_Order__c.Name',
            'Sales_Order__c.Bill_to_Customer_No__r.Name', 'Sales_Order__c.Project_Coordinator__r.Name',
            'Sales_Order__c.Quote_Date__c', 'Sales_Order__c.Quote_Status__c'];
        this.whereCondition = '';
        this.sortBy = ['Sales_Order__c.Name'];
        //this.pageSize = 1;
        this.title = 'Related Sales Orders';
        this.relatedObjectApiName = 'Sales_Order__c';
        this.sortedByLabel = 'No';
        this.header = 'Delete Order';
        this.content = 'Are you sure you want to delete this Order?';
    }

    handleCancel() {
        if (this.modal) {
            this.modal.hide(); // Hide the modal
        }
    }

    handleDelete() {
        this.isLoading = true;
        this.handleCancel();
        deleteRecord(this.rId)
            .then(() => {
                let objectName;
                if (this.objectApiName == 'Sales_Order__c') {
                    objectName = 'Order';
                }
                this.showToastEvent('', objectName + " '" + this.rName + "' was deleted.", 'success', '');
            })
            .catch((error) => {
                this.error = error.body.message;
                this.showToastEvent('', error.body?.output?.errors?.[0]?.message ?? error.body.message, 'error', '');
            });
        this.isLoading = false;
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        switch (action.name) {
            case 'edit':
                this.navigateToRecordView_EditPage(row.Id, '', 'edit');
                break;
            case 'delete':
                this.rId = row.Id;
                this.rName = row.Name;
                if (this.modal) {
                    this.modal.show(); //calling lwc modal component
                }
                break;
            default:
        }
    }

    navigateToRecentListView() {
        this.navigateToListView(this.objectApiName, 'Recent');
    }

    handleViewAll() {
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__dynamicRelatedList'
            },
            state: {
                c__recordId: this.recordId,
                c__objectApiName: this.objectApiName,
                c__isViewAll: true
            }
        });
    }

    handleColumnSorting(event) {
        let fieldName = event.detail.fieldName;
        let sortDirection = event.detail.sortDirection;
        if (this.objectInfo.data && this.objectApiName == 'Sales_Order__c') {
            if (fieldName == 'NameLink') {
                fieldName = 'Name';
            }
            if (fieldName == 'Name' && this.sortedDirection == 'asc') {
                sortDirection = 'desc';
            }
            this.sortedByLabel = this.objectInfo.data.fields?.[fieldName].label;
        }        
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
        this.sortData(this.sortedBy, this.sortedDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.records));
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = direction === "asc" ? 1 : -1;
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : "";
            y = keyValue(y) ? keyValue(y) : "";
            return isReverse * ((x > y) - (y > x));
        });
        this.records = parseData;
    }
}