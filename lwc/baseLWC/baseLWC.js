import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LightningConfirm from "lightning/confirm";
import { NavigationMixin } from "lightning/navigation";

export default class BaseLWC extends NavigationMixin(LightningElement) {
    @api
    //when using callApexMethod, the caller should always use the arrow function for the successCallback and the errorCallback.
    callApexMethod(apexMethod, params, successCallback, errorCallback) {
        apexMethod(params).then(data => {
            if (successCallback) {
                successCallback(data);
            }
        }).catch(error => {
            let errorMessage;
            if (error) {
                if (error.body) {
                    errorMessage = error.body.message;
                } else if (error.message) {
                    errorMessage = error.message;
                } else {
                    errorMessage = error;
                }
            }
            else {
                errorMessage = 'Unexpected error'
            }

            if (errorCallback) {
                errorCallback(errorMessage);
            }
            else {
                this.showToastEvent("callApexMethod Error", errorMessage, "error");
            }
        });
    }

    @api
    callApexMethods(methods, successCallback, errorCallback) {
        let errorOccurred = false;
        let firstError = null;

        methods.reduce((returnedPromise, method) => {
            return returnedPromise.then(() => {
                if (!errorOccurred) {
                    return new Promise((resolve, reject) => {
                        try {
                            method(resolve, reject);
                        } catch (error) {
                            reject(error);
                        }
                    }).catch(error => {
                        errorOccurred = true;
                        firstError = error;
                    });
                }
            });
        }, Promise.resolve()).then(() => {
            if (!errorOccurred) {
                if (successCallback) {
                    successCallback();
                }
            }
            else {
                let errorMessage;
                if (firstError.body) {
                    errorMessage = firstError.body.message;
                } else if (firstError.message) {
                    errorMessage = firstError.message;
                } else {
                    errorMessage = firstError;
                }

                if (errorCallback) {
                    errorCallback(errorMessage);
                } else {
                    this.showToastEvent("callApexMethod Error", errorMessage, "error");
                }
            }
        });
    }

    @api
    previewFile(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: recordId
            }
        })
    }

    @api
    showToastEvent(title, message, variant, mode) {
        if (!mode) mode = 'dismissible';

        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode
            })
        );
    }

    @api
    navigateToListView(objectApiName, filterName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: objectApiName,
                actionName: 'list'
            },
            state: {
                filterName: filterName
            }
        });
    }

    @api
    navigateToRecordView_EditPage(recordId, objectApiName, actionName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: objectApiName, // objectApiName is optional
                actionName: actionName  //'edit' or 'view'
            }
        });
    }

    @api
    formatBytes(bytes, decimals) {
        if (bytes == 0) return '0 Bytes';
        var k = 1024,
            dm = decimals || 2,
            sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
            i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + sizes[i];
    }
}