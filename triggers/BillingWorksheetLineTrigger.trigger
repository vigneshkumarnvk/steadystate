trigger BillingWorksheetLineTrigger on Billing_Worksheet_Line__c (before insert, before update, after insert, after update, after delete) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Set<Id> tmLinesIdsNeedToBeUpdated = new Set<Id>(); //Ticket#24817
            Set<Id> uomIds =  new set<Id>();
            Set<Id> resourceIds = new Set<Id>();
            //data check
            for (Billing_Worksheet_Line__c worksheetLine : Trigger.new) {
                worksheetLine.TM_Line_Id__c = worksheetLine.TM_Line__c;
                worksheetLine.UID__c = worksheetLine.Sales_Order__c + ':' + worksheetLine.Line_No__c.intValue();
				uomIds.add(worksheetLine.unit_of_measure__c);
                resourceIds.add(worksheetLine.Resource__c);
                //Ticket#24817 >>
                if(Trigger.isUpdate){
                    Billing_Worksheet_Line__c oldLine = Trigger.oldMap.get(worksheetLine.Id);
                    if(worksheetLine.Category__c == ResourceService.LABOR_CATEGORY && worksheetLine.Resource_Type__c != oldLine.Resource_Type__c){
                        tmLinesIdsNeedToBeUpdated.add(worksheetLine.TM_Line__c);
                    }
                }
                //Ticket#24817 <<
            }
            //Ticket#24817 >>
            if(tmLinesIdsNeedToBeUpdated.size() > 0){
                BillingWorksheetService.reopenKronosProcessedTMLinesByIds(tmLinesIdsNeedToBeUpdated);
            }
            //Ticket#24817 <<
            //
           // Ticket 85225 - Mapping Unit Cost and Price based on used Resource Type 
           Map<Id, Resource__c> resourceMap = new Map<Id, Resource__c>();
            Set<Id> resourceTypeIds = new Set<Id>();
           for(Resource__c resRec : [Select id, Resource_Type__c from Resource__c where id IN : resourceIds ])
                                     
           {
			      resourceMap.put(resRec.id, resRec);   
               	  resourceTypeIds.add(resRec.Resource_Type__c);
           }
                
            Map<String, List<ResourceTypeUOMAssociation__c>> resUOMMap = new Map<String, List<ResourceTypeUOMAssociation__c>>();
            System.debug('BWL++++++++++++');
            for(ResourceTypeUOMAssociation__c resUOM : [SELECT Id, Unit_Cost__c, Unit_Price__c, Unit_of_Measure__c, Resource_Type__c 
                                                        FROM ResourceTypeUOMAssociation__c WHERE Resource_Type__c IN :resourceTypeIds])
            {
              if(resUOMMap.containsKey(resUOM.Resource_Type__c))
                  resUOMMap.get(resUOM.Resource_Type__c).add(resUOM);
              else
                  resUOMMap.put(resUOM.Resource_Type__c, new List<ResourceTypeUOMAssociation__c>{resUOM});                  
            }
            
           //[SELECT Id, Resource__c, Resource__r.Resource_Type__c,Unit_of_Measure__c FROM 
                                                 //  	Billing_Worksheet_Line__c WHERE Id IN :bwlIds])
            
            for(Billing_Worksheet_Line__c currRec : Trigger.new) 
            {
                if(resourceMap.containsKey(currRec.Resource__c))
                {
                    if(resUOMMap.containsKey(resourceMap.get(currRec.Resource__c).Resource_Type__c))
                    {
                         for(ResourceTypeUOMAssociation__c resUOM : resUOMMap.get(resourceMap.get(currRec.Resource__c).Resource_Type__c))
                        {
                            if(resUOM.Unit_of_Measure__c == currRec.Unit_of_Measure__c)
                            {
                                System.debug('BWL++++++++++++' + resUOM.Unit_Cost__c);
                              //  currRec.Unit_Cost__c = resUOM.Unit_Cost__c;
                              //  currRec.Unit_Price__c = resUOM.Unit_Price__c;
                            }
                        }
                    }
                }
            }
        }
    }
    else if (Trigger.isAfter) {
        if (CompanyMgmt.byPassTrigger == true || BillingWorksheetController.ByPassTrigger == true) {
            return;
        }

        if (CompanyMgmt.systemCall != true) {
            throw new DataException('You cannot modify  worksheet line from the worksheet line page. Please use Billing Worksheet.');
        }

        if (Trigger.isDelete) {
            for (Billing_Worksheet_Line__c worksheetLine : Trigger.old) {
                if (worksheetLine.Invoiced__c == true) {
                    worksheetLine.addError('You cannot delete worksheet line ' + worksheetLine.Line_No__c + ' because it has been invoiced.');
                }
                if ((worksheetLine.Category__c == 'Labor' || worksheetLine.Category__c == 'Equipment') && worksheetLine.Is_Temporary_Service_Center__c != true) {
                    worksheetLine.addError('You cannot delete none temporary labor and equipment lines.');
                }
            }
        }
    }
}
