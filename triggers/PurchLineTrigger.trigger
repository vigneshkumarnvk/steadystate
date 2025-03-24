trigger PurchLineTrigger on Purchase_Line__c (before insert, before update, before delete, after delete, after insert, after update ) {
    if(CompanyMgmt.byPassLineTrigger != true) {
        if (Trigger.isBefore) {
            Map<Id, List<Purch_Rcpt_Line__c>> mapWRLList = new Map<Id, List<Purch_Rcpt_Line__c>>();
            Map<Id, Decimal> mapPRLQty = new Map<Id, Decimal>();
            Decimal TotalQty;

            if (Trigger.isDelete) {
                List<Purchase_Line__c> PLList = Trigger.old;
                for (Purch_Rcpt_Line__c thePRL : [SELECT Id,Name,Purchase_Line__c FROM Purch_Rcpt_Line__c WHERE Purchase_Line__c IN :PLList]) {
                    if (mapWRLList.get(thePRL.Purchase_Line__c) == null) {
                        mapWRLList.put(thePRL.Purchase_Line__c, new List<Purch_Rcpt_Line__c>());
                    }
                    mapWRLList.get(thePRL.Purchase_Line__c).add(thePRL);
                }
                PurchTriggersMgmt.PLDelete(PLList, mapWRLList);
            } else if (Trigger.isInsert || Trigger.isUpdate) {
                List<Purchase_Line__c> PLList = Trigger.new;
                Set<Id> purchaseLineIds = new Set<Id>();
                for(Purchase_Line__c purchaseLine : PLList){
                    if(purchaseLine.Id != null){
                        purchaseLineIds.add(purchaseLine.Id);
                    }
                }
                
                if(purchaseLineIds.size() > 0) {
                    for (Purch_Rcpt_Line__c thePRL : [SELECT Id,Name,Quantity__c,Purchase_Line__c FROM Purch_Rcpt_Line__c WHERE Purchase_Line__c IN :purchaseLineIds AND Receipt__r.Document_Status__c = 'Open']) {
                        if (mapWRLList.get(thePRL.Purchase_Line__c) == null) {
                            mapWRLList.put(thePRL.Purchase_Line__c, new List<Purch_Rcpt_Line__c>());
                        }
                        mapWRLList.get(thePRL.Purchase_Line__c).add(thePRL);
                        if (mapPRLQty.get(thePRL.Purchase_Line__c) == null) {
                            TotalQty = CompanyMgmt.zeroIfNull(thePRL.Quantity__c);
                            mapPRLQty.put(thePRL.Purchase_Line__c, TotalQty);
                        } else {
                            mapPRLQty.put(thePRL.Purchase_Line__c, mapPRLQty.get(thePRL.Purchase_Line__c) + thePRL.Quantity__c);
                        }
                    }

                    PurchTriggersMgmt.PLInsertUpdate(PLList, Trigger.oldMap, mapWRLList, mapPRLQty, Trigger.isInsert);

                }

                //Update Po sync flag
                List<Id> poIds = new List<Id>();
                if (Trigger.isInsert) {
                    for (Purchase_Line__c pl : Trigger.new) {
                        poIds.add(pl.Purchase_Order__c);
                    }
                }
                if (Trigger.isUpdate) {
                    for (Purchase_Line__c pl : Trigger.new) {
                        Purchase_Line__c xpl = Trigger.oldMap.get(pl.Id);
                        //nav-sf 01.20.20 <<
                        /*
                        if (pl.Item__c != xpl.Item__c || pl.Quantity__c != xpl.Quantity__c || pl.G_L_Account__c != xpl.G_L_Account__c || pl.Sales_Order__c != xpl.Sales_Order__c
                                || pl.Service_Center__c != xpl.Service_Center__c || pl.Unit_Cost__c != xpl.Unit_Cost__c) {
                            poIds.add(pl.Purchase_Order__c);
                        }
                        */
                        if (pl.Item__c != xpl.Item__c || pl.Unit_of_Measure__c != pl.Unit_of_Measure__c || pl.Quantity__c != xpl.Quantity__c || pl.G_L_Account__c != xpl.G_L_Account__c || pl.Sales_Order__c != xpl.Sales_Order__c
                                || pl.Service_Center__c != xpl.Service_Center__c || pl.Unit_Cost__c != xpl.Unit_Cost__c) {
                            poIds.add(pl.Purchase_Order__c);
                            pl.Synced__c = false;
                        }
                        //nav-sf 01.20.20 >>
                    }
                }

                List<Purchase_Order__c> pos = [SELECT Id, Sync_d__c FROM Purchase_Order__c WHERE Id IN :poIds];
                if (pos.size() > 0) {
                    for (Purchase_Order__c po : pos) {
                        po.Sync_d__c = false;
                    }
                    update pos;
                }
            }
        } else if (Trigger.isAfter) {
            Set<Id> updatedRecordIds = new Set<Id>();
            if (Trigger.isDelete) {
                Map<String, List<Purchase_Line__c>> mpls = new Map<String, List<Purchase_Line__c>>(); //by mapping
                for (Purchase_Line__c pl : [SELECT Id, Purchase_Order__c, Purchase_Order__r.Document_Status__c, Subsidiary_Company__r.Name FROM Purchase_Line__c WHERE Id IN :Trigger.oldMap.keySet() ALL ROWS]) {
                    if (pl.Purchase_Order__r.Document_Status__c == 'Approved' || pl.Purchase_Order__r.Document_Status__c == 'Partially Received' || pl.Purchase_Order__r.Document_Status__c == 'Fully Received') {
                        updatedRecordIds.add(pl.Purchase_Order__c);
                    }
                    String mappingName = '';
                    if (pl.Subsidiary_Company__r.Name == '1-REPUBLIC SERVICES') {
                        mappingName = 'Purchase Order Line Delete (Outbound) - ACV Enviro';
                    } else if (pl.Subsidiary_Company__r.Name == '2-CYCLE CHEM., INC.') {
                        mappingName = 'Purchase Order Line Delete (Outbound) - Cycle Chem';
                    }
                    if (String.isNotEmpty(mappingName)) {
                        List<Purchase_Line__c> pls;
                        if (mpls.containsKey(mappingName)) {
                            pls = mpls.get(mappingName);
                        } else {
                            pls = new List<Purchase_Line__c>();
                            mpls.put(mappingName, pls);
                        }
                        pls.add(pl);
                    }
                }

                for (String mappingName : mpls.keySet()) {
                    INTG.INTG_GlobalAPIs.TrackDeleted(mappingName, mpls.get(mappingName));
                }
            } else {
                for (Purchase_Line__c pl : [SELECT Id, Purchase_Order__c, Purchase_Order__r.Document_Status__c FROM Purchase_Line__c WHERE Id IN :Trigger.newMap.keySet()]) {
                    if (pl.Purchase_Order__r.Document_Status__c == 'Approved' || pl.Purchase_Order__r.Document_Status__c == 'Partially Received' || pl.Purchase_Order__r.Document_Status__c == 'Fully Received') {
                        updatedRecordIds.add(pl.Purchase_Order__c);
                    }
                }
            }

            if (updatedRecordIds.size() > 0) {
                Map<Id, Purchase_Order__c> purchaseOrdersByIds = new Map<Id, Purchase_Order__c>();
                purchaseOrdersByIds.putAll([SELECT Id, Document_Status__c, (SELECT Id, Quantity__c, Received_Qty__c FROM Purchase_Lines__r) FROM Purchase_Order__c WHERE Id IN :updatedRecordIds]);

                Set<Id> poIdWithReceipt = new Set<Id>();
                for (Purchase_Receipt__c purchaseReceipt : [SELECT Id, Purchase_Order__c FROM Purchase_Receipt__c WHERE Purchase_Order__c IN :updatedRecordIds ORDER BY Purchase_Order__c]) {
                    poIdWithReceipt.add(purchaseReceipt.Purchase_Order__c);
                }

                List<Purchase_Order__c> purchaseOrdersToUpdate = new List<Purchase_Order__c>();
                for (Purchase_Order__c purchaseOrder : purchaseOrdersByIds.values()) {
                    if (poIdWithReceipt.contains(purchaseOrder.Id)) {
                        Decimal totalOrderedQty = 0;
                        Decimal totalReceivedQty = 0;
                        for (Purchase_Line__c pl : purchaseOrder.Purchase_Lines__r) {
                            totalOrderedQty += CompanyMgmt.zeroIfNull(pl.Quantity__c);
                            totalReceivedQty += CompanyMgmt.zeroIfNull(pl.Received_Qty__c);
                        }

                        if (totalReceivedQty == 0) {
                            if (purchaseOrder.Document_Status__c == 'Partially Received' || purchaseOrder.Document_Status__c == 'Fully Received') {
                                purchaseOrder.Document_Status__c = 'Approved';
                                purchaseOrdersToUpdate.add(purchaseOrder);
                            }
                        } else if (totalOrderedQty > totalReceivedQty) {
                            if (purchaseOrder.Document_Status__c == 'Fully Received' || purchaseOrder.Document_Status__c == 'Approved') {
                                purchaseOrder.Document_Status__c = 'Partially Received';
                                purchaseOrdersToUpdate.add(purchaseOrder);
                            }
                        } else if (totalReceivedQty == totalOrderedQty) {
                            if (purchaseOrder.Document_Status__c == 'Partially Received' || purchaseOrder.Document_Status__c == 'Approved') {
                                purchaseOrder.Document_Status__c = 'Fully Received';
                                purchaseOrdersToUpdate.add(purchaseOrder);
                            }
                        }
                    } else {
                        if (purchaseOrder.Document_Status__c == 'Partially Received' || purchaseOrder.Document_Status__c == 'Fully Received') {
                            purchaseOrder.Document_Status__c = 'Approved';
                            purchaseOrdersToUpdate.add(purchaseOrder);
                        }
                    }
                }

                if (purchaseOrdersToUpdate.size() > 0) {
                    update purchaseOrdersToUpdate;
                }
            }
        }
    }
}