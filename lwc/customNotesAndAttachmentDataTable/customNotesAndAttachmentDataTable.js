import { LightningElement, api, wire, track } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import FileUploadCSS from '@salesforce/resourceUrl/FileUploadCSS';
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";
import fetchUploadedFiles from '@salesforce/apex/CustomNotesAndAttachment.fetchUploadedFiles';
import customNotesAndAttachment from "c/customNotesAndAttachment";
import FILE_PREFIX from "@salesforce/schema/ContentVersion.Custom_N_A_fileupload__c";

const actions = [
    { label: 'Download', name: 'download' },
    { label: 'View File Details', name: 'view_file_details' },
    { label: 'Upload New Version', name: 'upload_new_version' },
    { label: 'Edit File Details', name: 'edit_file_details' },
    { label: 'Delete', name: 'delete' },
];

export default class CustomNotesAndAttachmentDataTable extends NavigationMixin(customNotesAndAttachment) {

    //fetches value from url
    recordId;
    objectApiName;
    objectName;
    objectPluralName;
    recordName;

    data = [];
    record = {};
    error;
    modal;
    isLoading = false;
    deleteContentDocumentId;
    header;
    content;
    buttonLabel;
    filesCount;
    tempData;
    sortedBy;
    sortedDirection;
    sortedByLabel = 'Last Modified';
    isUploadNewVersion = false;
    @api buttonHide;    
    recordUrl;

    //Predefined Value for the field in ContentVersion Object to handle xustom logic
    fileFieldName = FILE_PREFIX.fieldApiName;
    fileNamePrefix = "CustomNotesAndAttachment";

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageRef) {
        if (currentPageRef) {
            this.recordId = currentPageRef.state.c__recordId;
            this.objectApiName = currentPageRef.state.c__objectApiName;
            this.objectName = currentPageRef.state.c__objectName;
            this.recordName = currentPageRef.state.c__recordName;
            this.objectPluralName = currentPageRef.state.c__objectPluralName;
            if (this.recordId && typeof this.displayUploadedFilesinTable === 'function') {
                this.displayUploadedFilesinTable();
            }
        }
    }

    get columns() {
        return [
            {
                label: 'Title', fieldName: 'FileTitle', type: 'button', sortable: true,
                typeAttributes: {
                    label: { fieldName: 'FileTitle' },
                    variant: "base",
                    name: "title_Preview",
                    iconName: { fieldName: 'DynamicIcon' },
                    iconClass: "slds-size_large"
                }
            },
            {
                label: 'Created By', fieldName: 'FileCreatedByUrl', type: 'url', sortable: true,
                typeAttributes: {
                    label: { fieldName: 'FileCreatedBy' },
                    value: 'FileCreatedBy'
                }
            },
            {
                label: 'Last Modified', fieldName: 'FormattedDate', type: 'date', sortable: true,
                typeAttributes: { day: 'numeric', month: 'numeric', year: 'numeric', hour: '2-digit', minute: '2-digit', hour12: true }
            },
            { label: 'Size', fieldName: 'ContentSize', sortable: true, },
            {
                type: 'action',
                typeAttributes: {
                    rowActions: actions,
                    class: 'slds-text-heading_medium'
                },
            },
        ]
    }

    get buttonHide() {
        return this.isUploadNewVersion ? 'slds-p-around_xx-small slds-hide' : 'slds-p-around_xx-small';
    }

    connectedCallback() {
        //CSS from static resource for file upload
        Promise.all([
            loadStyle(this, FileUploadCSS)
        ]);
        this.isLoading = true;
        this.displayUploadedFilesinTable();
    }

    renderedCallback() {
        this.modal = this.template.querySelector('c-lwc-modal');
    }

    handleColumnSorting(event) {
        const fieldName = event.detail.fieldName;
        const fieldNameMapping = {
            'FileTitle': 'Title',
            'FileCreatedByUrl': 'Created By',
            'FormattedDate': 'Last Modified',
            'ContentSize': 'Size',
        };
        this.sortedByLabel = fieldNameMapping[fieldName];
        this.sortedBy = fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.sortData(this.sortedBy, this.sortedDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.data));
        // Return the value stored in the field
        let keyValue = (a) => {
            if (fieldname == 'ContentSize') {
                return this.convertContentSizeToBytes(a[fieldname]); //convert to bytes to handle sorting
            }
            return a[fieldname];
        };
        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1 : -1;
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.data = parseData;
    }

    convertContentSizeToBytes(sizeString) {
        const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
        let match = sizeString.trim().match(/^(\d+(\.\d+)?)([a-zA-Z]+)$/);

        if (match) {
            let value = parseFloat(match[1]);
            let unit = match[3].toUpperCase();
            let unitIndex = units.indexOf(unit);
            if (unitIndex !== -1) {
                return value * Math.pow(1024, unitIndex);
            }
        }
    }

    displayUploadedFilesinTable() {
        if (this.recordId) {
            //Used as alternative to record view page of NavigationMixin. SInce component prevents navigation
            this.recordUrl = '/' + this.recordId;   
            fetchUploadedFiles({ recordId: this.recordId })
                .then(result => {
                    if (result != null) {
                        this.filesCount = result.length != 0 ? result.length : 0;
                        this.data = result.map(element => {
                            var obj = Object.assign({}, element);
                            obj.DynamicIcon = this.getIconByFileExtension(obj.FileExtension);
                            obj.amountColor = "datatable-orange";
                            obj.FileTitle = obj.Title;
                            obj.FileCreatedBy = obj.CreatedBy.Name;
                            obj.FileCreatedByUrl = '/' + obj.CreatedById;
                            obj.ContentSize = this.getFormattedSize(obj.ContentSize, 2);
                            obj.FormattedDate = obj.LastModifiedDate;
                            return obj;
                        });
                        this.sortedByLabel = 'Last Modified';
                    } else {
                        this.filesCount = 0;
                        this.data = undefined;                        
                        this.sortedByLabel = '';
                    }
                })
                .catch(error => {
                    console.error('Error:', error);
                    this.error = error.body.message;
                    this.showToastEvent('', error.body.message, 'error', '');
                });            
        }
        this.isLoading = false;
    }

    handleCancel() {
        if (this.modal) {
            this.modal.hide(); // Hide the modal
        }
    }

    handleDelete() {
        this.isLoading = true;
        this.handleCancel();
        deleteRecord(this.deleteContentDocumentId)
            .then(() => {
                this.displayUploadedFilesinTable();
                this.showToastEvent('', 'File was deleted.', 'success', '');
            })
            .catch((error) => {
                console.log('Error:', error);
                this.error = error.body.message;
                this.showToastEvent('', error.body.message, 'error', '');
            });
        this.isLoading = false;
    }

    handleRefresh() {
        this.displayUploadedFilesinTable();
    }

    handleUploadFinished(event) {
        this.handleCancel();
        const uploadedFiles = event.detail.files;
        this.showToastEvent('', uploadedFiles.length + (uploadedFiles.length == 1 ? ' file' : ' files') + ' was added to the ' + this.objectName + '.', 'success', '');
        this.displayUploadedFilesinTable();
    }

    navigateToRecentListView() {
        this.navigateToListView(this.objectApiName, 'Recent');
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const contentDocumentId = event.detail.row.ContentDocumentId;
        switch (actionName) {
            case 'preview', 'title_Preview':
                this.previewFile(contentDocumentId);
                break;
            case 'download':
                window.open('/sfc/servlet.shepherd/document/download/' + contentDocumentId + '?operationContext=S1');
                break;
            case 'view_file_details':
                this.navigateToRecordView_EditPage(contentDocumentId, '', 'view')
                break;
            case 'upload_new_version':
                this.fileNamePrefix = "CustomNotesAndAttachment -" + contentDocumentId;
                this.isUploadNewVersion = true;
                this.header = 'Upload New Version';
                this.content = ''
                if (this.modal) {
                    this.modal.show(); // Show the modal
                }
                break;
            case 'edit_file_details':
                this.navigateToRecordView_EditPage(contentDocumentId, '', 'edit');
                break;
            case 'delete':
                this.header = 'Delete File?';
                this.content = 'Deleting a file also removes it from any records or posts it\'s attached to.';
                this.buttonLabel = 'Delete';
                this.isUploadNewVersion = false;
                this.deleteContentDocumentId = contentDocumentId;
                if (this.modal) {
                    this.modal.show(); //calling lwc modal component
                }
                break;
            default:
        }
    }
}