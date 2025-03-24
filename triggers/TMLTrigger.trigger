trigger TMLTrigger on TM_Line__c (before insert, before update, before delete, after delete) {
	if(CompanyMgmt.byPassLineTrigger == true){
		return;
	}
	if(Trigger.isBefore) {
	    if(Trigger.isInsert || Trigger.isUpdate) {
	        TMTriggersMgmt.TMLInsertUpdate(Trigger.new, Trigger.oldMap, Trigger.isInsert);
	    }

	    if (CompanyMgmt.byPassTrigger != true) {
	        if (Trigger.isUpdate) {
	            Set<Id> tmIds = new Set<Id>();
	            for (TM_Line__c tmLine : Trigger.new) {
	                TM_Line__c xtmLine = Trigger.oldMap.get(tmLine.Id);
	                if (xtmLine.TM_Job_Task__c != null && xtmLine.TM_Job_Task__c != tmLine.TM_Job_Task__c) {
	                    tmIds.add(tmLine.TM__c);
	                }
	            }
	            if (tmIds.size() > 0) {
	                List<Signature__c> signatures = [SELECT Id FROM Signature__c WHERE TM__c IN :tmIds AND Voided__c != TRUE];
	                for (Signature__c signature : signatures) {
	                    signature.Voided__c = true;
	                    signature.Void_Reason__c = 'T&M job task changed.';
	                }
	                if (signatures.size() > 0) {
	                    update signatures;
	                }
	            }
	        }
	    }
	
	    if(Trigger.isDelete) {
			//Kronos >>
			Set<Id> deletedTMLineIds = new Set<Id>();
			for (TM_Line__c tmLine : Trigger.old) {
				if (tmLine.Category__c == ResourceService.LABOR_CATEGORY && tmLine.Service_Center__r.Temporary__c != true) {
					deletedTMLineIds.add(tmLine.Id);
				}
			}
			if (deletedTMLineIds.size() > 0) {
				KronosTimeClockService.processDeletedTMLines(deletedTMLineIds);
			}
			//Kronos <<
	        TMTriggersMgmt.TMLDelete(Trigger.old, Trigger.oldMap);
	    }
	}
}