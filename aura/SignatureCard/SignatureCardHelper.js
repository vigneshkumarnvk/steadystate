({
    getData : function(component, event, refresh) {
        var tmId = component.get("v.tmId");
        var params = { "tmId": tmId };
        this.callServerMethod(component, event, "c.GetData", params, function(data){
            component.set("v.data", data);

            //component.set("v.siteEmailAddress", data.Site_Email_Address__c);

            component.set("v.customerASignatureWrapper.Email", data.Site_Email_Address__c);

            var laborData = [];
            var equipmentData = [];
            var materialData = [];
            var wasteDisposalData = [];
            var costPlusData = [];

            data.TotalLaborHours = 0;
            data.TotalEquipmentHours = 0;
            //05.17.2019 <<
            var midnight = this.timeToInteger('24:00:00');
            //05.17.2019 >>
            if (data.TM_Lines__r != null) {
                for (var i = 0; i < data.TM_Lines__r.length; i++) {
                    var row = data.TM_Lines__r[i];

                    if (row.Resource_Type__r) {
                        row.ResourceTypeName = row.Resource_Type__r.Name;
                    }
                    //resource name <<
                    /*
                    if (row.Resource__r) {
                        row.ResourceName = row.Resource__r.Name;
                    }
                    */
                    row.ResourceName = row.Resource_Name__c;
                    //resource name >>
                    if (row.Unit_of_Measure__r) {
                        row.UnitOfMeasureName = row.Unit_of_Measure__r.Name;
                    }

                    if (row.Facility__r) {
                        row.FacilityName = row.Facility__r.Name;
                    }

                    switch (row.Category__c) {
                        case 'Labor':
                            if (row.Job_End_Time__c != null && row.Job_Start_Time__c != null) {
                                //05.17.2019 <<
                                //var timeValue = row.Job_End_Time__c - row.Job_Start_Time__c;
                                var timeValue;
                                if (row.Job_Start_Time__c > row.Job_End_Time__c) {
                                    timeValue = (midnight - row.Job_Start_Time__c) + row.Job_End_Time__c;
                                } else {
                                    timeValue = row.Job_End_Time__c - row.Job_Start_Time__c;
                                }
                                //05.17.2019 >>

                                //12.30.2019 <<
                                if (row.Lunch_Start_Time__c != null && row.Lunch_End_Time__c != null) {
                                    if (row.Lunch_End_Time__c > row.Lunch_Start_Time__c) {
                                        timeValue = timeValue - (row.Lunch_End_Time__c - row.Lunch_Start_Time__c);
                                    }
                                }
                                //12.30.2019 >>

                                data.TotalLaborHours += timeValue;

                                row.Hours = this.timeToHours(timeValue);
                            }
                            row.Job_Start_Time__c = this.integerToTime(row.Job_Start_Time__c);
                            row.Job_End_Time__c = this.integerToTime(row.Job_End_Time__c);
                            row.Site_Start_Time__c = this.integerToTime(row.Site_Start_Time__c);
                            row.Site_End_Time__c = this.integerToTime(row.Site_End_Time__c);
                            row.Lunch_Start_Time__c = this.integerToTime(row.Lunch_Start_Time__c);
                            row.Lunch_End_Time__c = this.integerToTime(row.Lunch_End_Time__c);
                            laborData.push(row);
                            break;
                        case 'Equipment':
                            if (row.Job_End_Time__c != null && row.Job_Start_Time__c != null) {
                                //05.17.2019 <<
                                var timeValue;
                                if (row.Job_Start_Time__c > row.Job_End_Time__c) {
                                    timeValue = (midnight - row.Job_Start_Time__c) + row.Job_End_Time__c;
                                } else {
                                    timeValue = row.Job_End_Time__c - row.Job_Start_Time__c;
                                }
                                //05.17.2019 >>

                                data.TotalEquipmentHours += timeValue;
                            }
                            row.Job_Start_Time__c = this.integerToTime(row.Job_Start_Time__c);
                            row.Job_End_Time__c = this.integerToTime(row.Job_End_Time__c);
                            equipmentData.push(row);
                            break;
                        case 'Materials':
                            materialData.push(row);
                            break;
                        case 'Waste Disposal':
                            wasteDisposalData.push(row);
                            break;
                        case 'Subcontractors':
                            costPlusData.push(row);
                            break;
                    }
                }
            }

            data.TotalLaborHours = this.timeToString(data.TotalLaborHours);
            data.TotalEquipmentHours = this.timeToString(data.TotalEquipmentHours);

            component.set("v.laborData", laborData);
            component.set("v.laborData", laborData);
            component.set("v.equipmentData", equipmentData);
            component.set("v.materialData", materialData);
            component.set("v.wasteDisposalData", wasteDisposalData);
            component.set("v.costPlusData", costPlusData);
            component.set("v.pendingChangesStatus", "");

            if (refresh) {
                this.showToast(component, 'success', 'T&M', 'Page refreshed!', 'dismissible');
            }
        });
    },
    saveData : function(component, event) {
        var tmId = component.get("v.tmId");
        var data = component.get("v.data");
        //remove TM_Lines__r, only header is needed
        delete data.TM_Lines__r;
        var params = { "data": JSON.stringify(data) };
        this.callServerMethod(component, event, "c.SaveTM", params, function(data){
            this.getData(component, event, false);
            this.showToast(component, 'success', 'T&M', 'Your changes are saved!', 'dismissible');
        });
    },
    processPDF : function(component, event) {
        var data = component.get("v.data");
        if (data.Field_TM_PDF_Sent__c != true || data.Field_TM_PDF_Saved__c != true) {
            this.showToast(component, 'info', 'T&M', 'Processing field T&M PDF...', 'dismissible');
            var params = { "tmId": data.Id};
            this.callServerMethod(component, event, "c.processPdf", params, function(data) {
                this.showToast(component, 'success', 'Field T&M PDF', 'Completed!', 'dismissible');
            }, function (err) {
                this.showToast(component, 'error', 'Field T&M PDF', err, 'dismissible');
            });
        }
    },
    confirmRefresh : function(component, event) {
        var pendingChangesStatus = component.get("v.pendingChangesStatus");
        if (pendingChangesStatus == 'Pending_Changes') {
            var buttons = [];
            buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
            buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.refreshCallback.bind(this, component, event) }});
            this.openModal(component, event, 'Refresh', 'You have unsaved changes! Are you sure you want to refresh this page?', buttons, null, null, null);
        }
        else {
            this.refresh(component, event);
        }
    },
    refreshCallback : function(component, event) {
        this.refresh(component, event);
        this.closeModal(component, event);
    },
    refresh : function(component, event) {
        this.getData(component, event, true);
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },
    showTermsDialog : function(component, event) {
        var salesOrderId = component.get("v.tm.Sales_Order__c");
        var buttons = [];
        buttons.push({ "label": 'Close', "variant": 'brand', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        var params = { "salesOrderId": salesOrderId };
        this.openModal(component, event, 'Terms and Conditions', null, buttons, "c:MobileTMTerms", params, "large");
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },
    integerToTime : function(time) {
        var d = new Date();
        d.setHours(0, 0, 0, 0);
        if (time) {
            var time = time / 1000;
            var h = Math.floor(time / 60 / 60);
            var time = (time % (60 * 60));
            var m = Math.floor(time / 60);
            var s = (time % 60);

            d.setHours(h);
            d.setMinutes(m);
            d.setSeconds(s);
            return d.getTime();
        }
        else {
            return null;
        }
    },
    timeToHours : function(timeValue) {
        if (timeValue)   {
            var h = timeValue / 1000 / 60 / 60.0;
            return h;
        }
        else {
            return 0;
        }
    },
    timeToInteger : function(timeString) {
        var time = 0;
        if (timeString) {
            var arr = timeString.split(':');
            var h = arr[0];
            var m = arr[1];
            var s = arr[2];
            time = (h * 60 * 60 + m * 60 + parseInt(s)) * 1000;
        }
        return time;
    },
    timeToString : function(timeValue) {
        var timeString;
        if (timeValue != null) {
            var timeValue = timeValue / 1000;
            var h = Math.floor(timeValue / 60 / 60);
            var timeValue = (timeValue % (60 * 60));
            var m = Math.floor(timeValue / 60);
            var s = (timeValue % 60);

            var hours = h < 10 ? '0' + h : h;
            var minutes = m < 10 ? '0' + m : m;
            var seconds = s < 10 ? '0' + s : s;

            timeString = parseInt(hours) + ' hours';
            if (m != 0) {
                timeString += ' ' + minutes + ' minutes';
            }
        }
        return timeString;
    },
    showSurvey : function(component, event, customerName, email) {
        var tm = component.get("v.tm");
        var params = { "tmId": tm.Id, "customerName": customerName, "customerEmail": email };
        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Save', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "saveServiceRating", "callback": this.showSurveyCallback.bind(this, component, event) }});
        this.openModal(component, event, 'Customer Feedback', null, buttons, 'c:TMServiceRating', params, "large");
    },
    showSurveyCallback : function(component, event) {
        this.closeModal(component, event);
        this.showToast(component, 'success', 'Customer Feedback', 'Thank you for your feedback.', 'dismissible');
    }
})