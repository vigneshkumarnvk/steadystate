({
    search : function(component, event, keyword, callback) {
        var useStaticOption = component.get("v.useStaticOption");
        if (useStaticOption) {
            component.set("v.showLookupSpinner", true);
            setTimeout($A.getCallback(function() {
                var staticOptions = component.get("v.staticOptions");
                if (staticOptions) {
                    component.set("v.staticOptionValues", staticOptions);
                    var staticOptionValues = JSON.parse(JSON.stringify(component.get("v.staticOptionValues")));
                    component.set("v.staticOptions", staticOptions); // need this line of code to avoid stack call overflow issue
                    component.set("v.result", staticOptionValues);
                    component.set("v.showLookupSpinner", false);
                } else {
                    component.set("v.showLookupSpinner", false);
                }
            }), 50);
        }
        else {
            var sObjectName = component.get("v.SObjectName");
            var tsdfApprovalCode =  component.get("v.tsdfApprovalCode");
            var params = {
                "tsdfApprovalCode":tsdfApprovalCode,
                "tmId":component.get("v.name")
            };
            component.set("v.showLookupSpinner", true);
            this.callServerMethod(component, event, "c.fetchRecords", params, function (records) {
                //$A.util.addClass(spinner, "slds-hide");
                component.set("v.result", records);
                component.set("v.showLookupSpinner", false);
                component.set("v.xKeyword", keyword);
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
        //var pills = component.get("v.pills");
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
                component.set("v.focused", false);
                var onblur = component.getEvent("onblur");
                onblur.fire();
            }
        }
    },
    showLookupContainer : function(component, event) {
        //console.log("--------------------------")
        var datatable = component.get("v.datatable");
        var lookupContainer = component.find("lookup-container");
        var lookupInput = component.find("lookup-input");
        var top = lookupContainer.getElement().getBoundingClientRect().top;
        var left = lookupContainer.getElement().getBoundingClientRect().left;
        var bottom = lookupContainer.getElement().getBoundingClientRect().bottom;
        var width = lookupContainer.getElement().getBoundingClientRect().width;
        var lookupInputTop = lookupInput.getElement().getBoundingClientRect().top;
        var lookupInputHeight = lookupInput.getElement().getBoundingClientRect().height;
        var vh = Math.max(document.documentElement.clientHeight, window.innerHeight || 0);

        var dropdownTop = 0;
        var dropdownBottom = 0;
        var dropdownLeft = left;
        var dropdownMinWidth = width;
        var dropdownOnBottom;
        if (top > (vh / 1.5)) {
            dropdownOnBottom = true;

            if (datatable == true) {
                dropdownBottom = (vh - lookupInputTop);
            }
            else {
                dropdownBottom = (lookupInputHeight + 5);
            }
        }
        else {
            dropdownOnBottom = false;
            dropdownTop = bottom;
        }

        //component.set("v.mouseOverInputBox", true);
        var dropdownbox = component.get("v.dropdownbox");
        //if (!dropdownbox || dropdownbox.get("v.closed") == true) {
        if (!dropdownbox) {
            //console.log("create component " + dropdownOnBottom + ', ' +  dropdownLeft + ',' + dropdownTop + ', ' + dropdownBottom)
            $A.createComponent(
                "c:LookupInputDropdownApproval",
                {
                    "aura:id": "dropdown",
                    "id": "dropdownBox" + Date.now(),
                    "columns": component.getReference("v.columns"),
                    "result": component.getReference("v.result"),
                    "showLookupSpinner": component.getReference("v.showLookupSpinner"),
                    "fixedPosition": datatable,
                    "dropdownLeft": dropdownLeft,
                    "dropdownTop": dropdownTop,
                    "dropdownBottom": dropdownBottom,
                    "dropdownMinWidth" : dropdownMinWidth,
                    "dropdownOnBottom": dropdownOnBottom,
                    "onclose": component.getReference("c.handleDropdownClose"),
                    "message":'No matching records found'
                },
                function (dropdown, status, errorMessage) {
                    if (status === 'SUCCESS') {
                        component.set("v.dropdownbox", dropdown);
                        //console.log("set v.dropdownbox" +  dropdown);
                        var dropdownContainer = component.find("dropdown-container");
                        var body = dropdownContainer.get("v.body");
                        body.push(dropdown);
                        dropdownContainer.set("v.body", body);
                        setTimeout($A.getCallback(function () {
                            dropdown.showDropdown();
                        }), 10);
                    } else if (status === 'INCOMPLETE') {
                        alert("no response from server or client is offline.");
                    } else if (status === 'ERROR') {
                        alert(errorMessage);
                    }
                }
            );
        }
        else {
            dropdownbox.showDropdown();
        }
    },
    hideLookupContainer : function(component, event) {
        var lookupContainer = component.find("lookup-container");
        $A.util.addClass(lookupContainer, 'slds-is-close');
        $A.util.removeClass(lookupContainer, 'slds-is-open');
        this.fireOnBlurEvent(component, event);
    },
    showLookupPill : function(component, event) {
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
    handleKeyStrokes : function(component, event) {
        //select the record if there is only one result when the enter key is pressed
        component.set("v.lastKeyStrokeTime", new Date());
        var keyword = component.get("v.keyword");

        var minimumChars = component.get("v.minimumChars");
        var helper = this;
        if(minimumChars == 0 || (keyword && keyword.length >= minimumChars)) {
            setTimeout($A.getCallback(
                function() {
                    if (event.which == 13) { // enter key
                        setTimeout(
                            $A.getCallback(function() {
                                helper.showLookupContainer(component, event);
                                helper.search(component, event, keyword, function() {
                                    var result = component.get("v.result");
                                    if (result && result.length == 1) {
                                        if (component.isValid()) {
                                            helper.addLookupRecord(component, event, result[0]);
                                            helper.hideKeyboard(component, event);
                                        }
                                    }
                                });
                            }), component.get("v.keypressInterval"));
                    }
                    else { //delay submit to capture all input to reduce traffic
                        var lastKeyStrokeTime = component.get("v.lastKeyStrokeTime");
                        if (new Date() - lastKeyStrokeTime > component.get("v.keypressInterval") ) {
                            helper.showLookupContainer(component, event);
                            helper.search(component, event, keyword);
                        }
                    }
                    //component.set("v.value",keyword);
                }
            ), component.get("v.keypressInterval"));
        }
        else{
            this.hideLookupContainer(component, event);
            component.set("v.result", null );
        }
    },
    hideKeyboard : function (component, event) {
        setTimeout(function() {

            //creating temp field
            var field = document.createElement('input');
            field.setAttribute('type', 'text');
            //hiding temp field from peoples eyes
            //-webkit-user-modify is necessary for Android 4.x
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
            });
        }
    },
    isTablet : function(component, event) {
        var browser = $A.get("$Browser");
        if (browser.isTablet == true || browser.isPhone == true || browser.isIPhone == true || browser.fromFactor == 'PHONE' || browser.fromFactor == 'TABLET') {
            return true;
        }
        return false;
    },
    closeDropdown : function(component, event) {
        this.resetAttributes(component);
        var dropdownbox = component.get("v.dropdownbox");
        if (dropdownbox) {
            dropdownbox.closeDropdown();
            component.set("v.dropdownbox", null);
        }
    },
    resetAttributes : function(component) {
        component.set("v.keyword", null);
        component.set("v.xKeyword", '!@#$%^*');
    }
})