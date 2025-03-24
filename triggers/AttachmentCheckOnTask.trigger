trigger AttachmentCheckOnTask on ContentDocumentLink (after insert) {
    
     String tempParentId;
	Set<Id> setParentId = new Set<Id>();
	List<task> tasklst = new List<task>();
	
 for (ContentDocumentLink cdl : trigger.new ) {
			tempParentId = cdl.LinkedEntityId;
	 
			if (tempParentId.left(3) =='00T') {
				System.debug('Debug : found 00T');
				System.debug('Debug : content document id ' + cdl.ContentDocumentId );
				setParentId.add(cdl.LinkedEntityId);
			}
		}
	tasklst = [select Id , HasAttachement__c from task where Id IN :setParentId];
	 
	 For(task e : tasklst)
	 {
		e.HasAttachement__c = True;
	 }

	 update tasklst;
    

}