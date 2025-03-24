({
    search : function(component, event, keyword, callback) {
        var useStaticOption = component.get("v.useStaticOption");
        var staticOptions = component.get("v.staticOptions");
        if (useStaticOption) {
            component.set("v.result", staticOptions);
        }
        else {

            var sObjectName = component.get("v.SObjectName");
            var fields = new Array();

            var columns = component.get("v.columns");
            for (var i = 0; i < columns.length; i++) {
                fields.push(columns[i].fieldName);
            }

            var queryFields = component.get("v.queryFields");
            for (var i = 0; i < queryFields.length; i++) {
                fields.push(queryFields[i]);
            }

            var keyFields = component.get("v.keyFields");
            for (var i = 0; i < keyFields.length; i++) {
                fields.push(keyFields[i]);
            }

            var pillFieldName = component.get("v.pill.fieldName");
            if (pillFieldName != null) {
                fields.push(pillFieldName);
            }

            var pillExpr = component.get("v.pill.expression");
            if (pillExpr != null) {
                var pat = '[^{\}]+(?=})';
                var reg = RegExp(pat, 'g');
                var match;
                while ((match = reg.exec(pillExpr)) !== null) {
                    //fix null <<
                    //fields.push(match[0]);
                    if (match[0] != null) {
                        fields.push(match[0]);
                    }
                    //fix null >>
                }
            }

            var fieldsToSearch = component.get("v.fieldsToSearch");
            var initialFilter = component.get("v.initialFilter");
            var filterString = component.get("v.filter");
            var filtersString = component.get("v.filters");

            var filters = [];
            if (keyword) {
                if (filterString) {
                    filters.push(filterString);
                }
            }
            else {
                if (initialFilter) {
                    filters.push(initialFilter);
                }
                else if (filterString) {
                    filters.push(filterString);
                }
            }

            if (filtersString) {
                var filterList = JSON.parse(filtersString);
                if (Array.isArray(filterList)) {
                    filters = filters.concat(filterList);
                }
                else {
                    filters.push(filterList);
                }
            }

            var fetchLimit = component.get("v.fetchLimit");
            var sorting = component.get("v.sort");
            var message = '';
            var action = component.get("c.fetchRecords");
            var params = {
                "sObjectName": sObjectName,
                "fields": fields,
                "fieldsToSearch": fieldsToSearch,
                "keyFields": keyFields,
                //"filter": filter,
                "filters": filters,
                "sorting": sorting,
                "keyword": keyword,
                "fetchLimit": fetchLimit
            };
            var spinner = component.find("spinner");
            $A.util.removeClass(spinner, "slds-hide");
            this.callServerMethod(component, event, "c.fetchRecords", params, function (records) {
                $A.util.addClass(spinner, "slds-hide");
                component.set("v.result", records);
                if (callback) {
                    callback();
                }
            }, function (err) {
                throw Error(err);
            }, true);
        }
    },
    navigateToRecord : function(component, event) {
        var record = component.get("v.value");
        if (record != null && !Array.isArray(record)) {
            var navigationService = component.find("navigationService");
            var pageReference = {
                "type": "standard__recordPage", //example for opening a record page, see bottom for other supported types
                "attributes": {
                    "recordId": record.Id, //place your record id here that you wish to open
                    "actionName": "view"
                }
            }

            navigationService.generateUrl(pageReference).then(
                $A.getCallback(function(url) {
                    window.open(url,'_blank'); //this opens the page in a separate tab
                }),
                $A.getCallback(function(error) {
                    alert('error: ' + error);
                })
            );
        }
    },
    newRecordPage : function(component, event) {
        var newRecordComponentName = component.get("v.newRecordComponentName");
        if (newRecordComponentName != null) {
            var params;
            var newRecordParams = component.get("v.newRecordParams");
            if (newRecordParams != null) {
                params = newRecordParams;
            }
            var method = component.get("v.newRecordCreateMethod");
            var buttons = [];
            buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
            buttons.push({ "label": 'Create', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": method, "callback": this.newRecordCreateCallback.bind(this, component, event) }});
            this.openModal(component, event, 'New Record', null, buttons, newRecordComponentName, params, null);
        }
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },
    newRecordCreateCallback : function(component, event, record) {
        this.addLookupRecord(component, event, record);
        this.closeModal(component, event);
    },
    addLookupRecord : function(component, event, record) {
        var records = component.get("v.records");
        if (records == null) {
            throw 'Unknown exception. Please reload the page.'
        }
        records.push(record);
        component.set("v.keyword", null);
        component.set("v.records", records);
        this.initValueFromRecords(component, event);
        this.fireOnChangeEvent(component, event);
    },
    removeLookupRecord : function(component, event, recordId) {
        var records = component.get("v.records");
        for (var i = 0; i < records.length; i++) {
            if (recordId === records[i].Id) {
                records.splice(i, 1);
                i--;
            }
        }
        component.set("v.records", records);
        this.initValueFromRecords(component, event);
        this.fireOnChangeEvent(component, event);
    },
    initRecordsFromValue : function(component, event) {
        var value = component.get("v.value");
        var allowMultipleValues = component.get("v.allowMultipleValues");
        var records = [];

        if (allowMultipleValues) {
            if (value != null) {
                records = Array.from(value);
            }
        }
        else {
            if (value != null) {
                records.push(value);
            }
        }
        component.set("v.records", records);
        this.refreshPill(component, event);
    },
    initValueFromRecords : function(component, event) {
        var records = component.get("v.records");
        var pills = component.get("v.pills");
        var allowMultipleValues = component.get("v.allowMultipleValues");

        //update value
        var value;
        if (allowMultipleValues == true) {
            value = records;
        }
        else {
            if (records.length > 0) {
                value = records[0];
            }
        }
        component.set("v.value", value);
        this.refreshPill(component, event);
    },
    refreshPill : function(component, event) {
        //update pills
        var records = component.get("v.records");

        var pills = [];
        var pill = component.get("v.pill");
        var fieldName = pill.fieldName;
        var pillExpr = pill.expression;

        for (var i = 0; i < records.length; i++) {
            if (records[i] != null) {
                var record = records[i];

                if (pillExpr != null) {
                    var pat = '[^{\}]+(?=})';
                    var reg = RegExp(pat, 'g');
                    var match;
                    var expr = pillExpr;
                    while ((match = reg.exec(pillExpr)) !== null) {
                        var fieldValue = this.getFieldValue(record, match[0]);
                        expr = expr.replace('{' + match[0] + '}', fieldValue);
                    }
                    pills.push({ id: record.Id, label: expr });
                }
                else if (fieldName != null) {
                    var fieldValue = this.getFieldValue(record, fieldName);
                    pills.push({ id: record.Id, label: fieldValue });
                }
            }
        }
        component.set("v.pills", pills);

        var allowMultipleValues = component.get("v.allowMultipleValues");
        if (records && records.length > 0) {
            if (allowMultipleValues == true) {
                this.showLookupPillAndInput(component, event);
            }
            else {
                this.showLookupPill(component, event);
            }
            this.hideLookupContainer(component, event);
        }
        else {
            this.showLookupInput(component, event);
        }
    },
    getFieldValue : function(record, fieldName) {
        var fieldValue;
        var obj = record;
        var fields = fieldName.split('.');
        for (var i = 0; i < fields.length; i++) {
            var field = obj[fields[i]];
            if (typeof(field) == 'object') {
                obj = field;
            }
            else {
                fieldValue = field;
                break;
            }
        }

        if (!fieldValue) {
            fieldValue = '';//record.Id;
        }
        return fieldValue;
    },
    fireOnChangeEvent : function(component, event) {
        //throw the event to the parent component
        var onchange = component.getEvent("onchange");
        var records = component.get("v.records");

        var record;
        if (records && records.length > 0) {
            record = records[0];
        }

        var name = component.get("v.name");
        onchange.setParams({ "name": name, "records": records, "record": record });
        onchange.fire();

        //dispatch a DOM change event //for use in FlexDataTable, event are bubbled to the parent element
        var container = component.find("lookup-container");
        var element = container.getElement();
        if (element != null) {
            var event = new CustomEvent('change', { bubbles: true, cancelable: true, detail: { record: JSON.stringify(record), records: JSON.stringify(records) }});
            element.dispatchEvent(event);
        }
    },
    fireOnFocusEvent : function(component, event) {
        //dispatch a DOM change event //for use in FlexDataTable, event are bubbled to the parent element
        var container = component.find("lookup-container");
        var element = container.getElement();
        if (element != null) {
            var event = new CustomEvent('focusin', {bubbles: true, cancelable: true, detail: {}});
            element.dispatchEvent(event);
        }
    },
    fireOnBlurEvent : function(component, event) {
        //dispatch a DOM change event //for use in FlexDataTable, event are bubbled to the parent element
        var container = component.find("lookup-container");
        var element = container.getElement();
        if (element != null) {
            var focused = component.get("v.focused");
            if (focused == true) {
                //var event = new CustomEvent('focusout', {bubbles: true, cancelable: true, detail: {}});
                //element.dispatchEvent(event);
                component.set("v.focused", false);
                var onblur = component.getEvent("onblur");
                onblur.fire();
            }
        }
    },
    showLookupContainer : function(component, event) {
        this.fireOnFocusEvent(component, event);
        var lookupContainer = component.find("lookup-container");
        var lookupInput = component.find("lookup-input");
        $A.util.addClass(lookupContainer, 'slds-is-open');
        $A.util.removeClass(lookupContainer, 'slds-is-close');

        var top = lookupContainer.getElement().getBoundingClientRect().top;
        var left = lookupContainer.getElement().getBoundingClientRect().left;
        var bottom = lookupContainer.getElement().getBoundingClientRect().bottom;
        var height = lookupContainer.getElement().getBoundingClientRect().height;
        var width = lookupContainer.getElement().getBoundingClientRect().width;
        var lookupInputTop = lookupInput.getElement().getBoundingClientRect().top;
        var lookupInputHeight = lookupInput.getElement().getBoundingClientRect().height;

        var vh = Math.max(document.documentElement.clientHeight, window.innerHeight || 0);
        var datatable = component.get("v.datatable");
        var dropdown = component.find("dropdown");
        if (top > (vh / 1.5)) {
            $A.util.removeClass(dropdown, "slds-dropdown");
            $A.util.addClass(dropdown, "slds-dropdown_bottom");
            //$A.util.addClass(dropdown, "dropdown-bottom");


        } else {
            $A.util.addClass(dropdown, "slds-dropdown");
            $A.util.removeClass(dropdown, "slds-dropdown_bottom");
            //$A.util.removeClass(dropdown, "dropdown-bottom");
        }
        $A.util.addClass(dropdown, "slds-dropdown_left");
        $A.util.removeClass(dropdown, "slds-dropdown_right");


        //temp fix for displaying dropdown in datatable, fixed position does not work in the modal correctly <<

        if (datatable == true) {
            dropdown.getElement().style.position = 'fixed'; //to position the dropdown relative to the viewport
            dropdown.getElement().style.left = left + 'px';
            if (top > (vh / 1.5)) {
                dropdown.getElement().style.bottom = (vh-lookupInputTop) + 'px';
                dropdown.getElement().style.transform = '';
                dropdown.getElement().style.top = null;
            }
            else {
                dropdown.getElement().style.top = bottom + 'px';
                dropdown.getElement().style.bottom = null;
            }
            var dropdownWidth = dropdown.getElement().getBoundingClientRect().width;
            $A.util.addClass(dropdown, "slds-dropdown");
            $A.util.removeClass(dropdown, "slds-dropdown_bottom");
            $A.util.removeClass(dropdown, "dropdown-bottom");
        }
        else {
            var dropdownWidth = Math.max(dropdown.getElement().getBoundingClientRect().width, lookupContainer.getElement().getBoundingClientRect().width);
            dropdown.getElement().style.width = dropdownWidth + 'px';
            if (top > (vh / 1.5)) {
                dropdown.getElement().style.bottom = (lookupInputHeight + 5) + 'px';
            }
        }
        //temp fix for displaying dropdown in datatable >>
        component.set("v.focused" , true);
    },
    hideLookupContainer : function(component, event) {
        //$A.util.addClass(component.find("spinner"), "slds-hide");

        var lookupContainer = component.find("lookup-container");
        $A.util.addClass(lookupContainer, 'slds-is-close');
        $A.util.removeClass(lookupContainer, 'slds-is-open');

        //expand the columns width
        var dropdown = component.find("dropdown");
        $A.util.removeClass(dropdown, 'lookup-full-width');

        this.fireOnBlurEvent(component, event);
    },
    showLookupPill : function(component, event) {
        //$A.util.addClass(component.find("spinner"), "slds-hide");

        var lookupPill = component.find("lookup-pill");
        $A.util.addClass(lookupPill, 'slds-show');
        $A.util.removeClass(lookupPill, 'slds-hide');

        var lookupInput = component.find("lookup-input");
        $A.util.addClass(lookupInput, 'slds-hide');
        $A.util.removeClass(lookupInput, 'slds-show');
    },
    showLookupInput : function(component, event) {
        var lookupPill = component.find("lookup-pill");
        $A.util.addClass(lookupPill, 'slds-hide');
        $A.util.removeClass(lookupPill, 'slds-show');

        var lookupInput = component.find("lookup-input");
        $A.util.addClass(lookupInput, 'slds-show');
        $A.util.removeClass(lookupInput, 'slds-hide');
    },
    showLookupPillAndInput : function(component, event) {
        var lookupPill = component.find("lookup-pill");
        $A.util.addClass(lookupPill, 'slds-show');
        $A.util.removeClass(lookupPill, 'slds-hide');

        var lookupInput = component.find("lookup-input");
        $A.util.addClass(lookupInput, 'slds-show');
        $A.util.removeClass(lookupInput, 'slds-hide');
    },
    hideKeyboard : function (component, event) {
        setTimeout(function() {

            //creating temp field
            var field = document.createElement('input');
            field.setAttribute('type', 'text');
            //hiding temp field from peoples eyes
            //-webkit-user-modify is nessesary for Android 4.x
            field.setAttribute('style', 'position:absolute; top: 0px; opacity: 0; -webkit-user-modify: read-write-plaintext-only; left:0px;');
            document.body.appendChild(field);

            //adding onfocus event handler for out temp field
            field.onfocus = function(){
                //this timeout of 200ms is necessary for Android 2.3.x
                setTimeout(function() {

                    field.setAttribute('style', 'display:none;');
                    setTimeout(function() {
                        document.body.removeChild(field);
                        document.body.focus();
                    }, 14);

                }, 200);
            };
            //focusing it
            field.focus();

        }, 50);
    },
    addListeners : function(component) {
        var container = component.find("lookup-container");
        if (container && container.getElement()) {
            container.getElement().addEventListener("click", function (event) {
                //05.05.2020 -- don't stop propagation
                //event.stopPropagation(); //stop click event bubbling
                //05.05.2020 -- use click event to control menu popup outside of the parent overflow container

                /* move to fireOnChangeEvent function
                var element = container.getElement();
                var event = new CustomEvent('change', {bubbles: true, cancelable: true});
                element.dispatchEvent(event);
                component.set("v.valueChanged", false);
                 */
            });
        }
    }
})