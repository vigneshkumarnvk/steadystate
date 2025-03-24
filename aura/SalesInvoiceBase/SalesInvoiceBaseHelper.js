({
    calculateSalesInvoice : function(component, event, salesInvoice, jobTaskWrappers) {
        var params = { "JSONSalesInvoice": JSON.stringify(salesInvoice), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };
        this.callServerMethod(component, event, "c.calculateSalesInvoice", params, function(response) {
            var jobTaskWrappers = JSON.parse(response);
            component.set("v.jobTaskWrappers", jobTaskWrappers);
        })
    },
    sortInvoiceLines : function(invoiceLines) {
        let sorts = [
            { fieldName: 'Category__c', ascending: true, custom: ['Labor', 'Equipment', 'Materials', 'Subcontractors', 'Waste Disposal', 'Misc. Charges And Taxes', 'Demurrage', 'Bundled']},
            { fieldName: 'Line_No__c', ascending: true, custom: null },
        ];
        this.sortLines(invoiceLines, sorts);
        this.hierarchySort(invoiceLines);
    },
    sortLines : function(objList, sorts) {
        objList.sort(function(a, b) {
            return sort(a, b, sorts, 0);
        });

        function sort(a, b, sorts, sortIndex) {
            var fieldName = sorts[sortIndex].fieldName;
            var custom = sorts[sortIndex].custom;
            var ascending = sorts[sortIndex].ascending;

            var val1;
            var val2;
            if (custom != null) {
                val1 = custom.indexOf(a[fieldName]);
                val2 = custom.indexOf(b[fieldName]);
            }
            else {
                val1 = a[fieldName];
                val2 = b[fieldName];
            }

            var order = 0;
            if (val1 > val2) {
                order = 1;
            } else if (val1 < val2) {
                order = -1;
            }
            else {
                if (sortIndex < sorts.length - 1) {
                    sortIndex++;
                    order = sort(a, b, sorts, sortIndex);
                }
            }

            if (ascending != true) {
                order = order * -1;
            }
            return order;
        };
    },
    hierarchySort : function(salesLines) {
        var mapChildLinesByParentLineNo = new Map();
        for (var i = 0; i < salesLines.length; i++) {
            var salesLine = salesLines[i];
            if (salesLine.Bundle_Line__r != null) {
                var parentLineNo = salesLine.Bundle_Line__r.Line_No__c;
                var children;
                if (mapChildLinesByParentLineNo.has(parentLineNo)) {
                    children = mapChildLinesByParentLineNo.get(parentLineNo);
                }
                else {
                    var children = [];
                    mapChildLinesByParentLineNo.set(parentLineNo, children);
                }
                children.push(salesLine);
            }
        }

        var salesLines2 = [];
        for (var i = 0; i < salesLines.length; i++) {
            var salesLine = salesLines[i];

            if (!salesLine.Bundle_Line__r) {
                salesLines2.push(salesLine);
                //push child lines
                if (mapChildLinesByParentLineNo.has(salesLine.Line_No__c)) {
                    var children = mapChildLinesByParentLineNo.get(salesLine.Line_No__c);
                    children.forEach(function(child) {
                        salesLines2.push(child);
                    })
                }
            }
        }

        //assign the ordered list back to salesLines
        for (var i = 0; i < salesLines.length; i++) {
            salesLines[i] = salesLines2[i];
        }
    },
});