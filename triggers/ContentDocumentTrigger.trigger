/*
 *  Ticket#19950
 *      Not allow to delete emailed content document.
 */
trigger ContentDocumentTrigger on ContentDocument (before delete) {
    if(Trigger.isBefore && Trigger.isDelete){
        if(ContentDocumentsService.isContentDocumentEmailed(Trigger.oldMap.keySet()) == true){
            Trigger.old[0].addError('Cannot delete document that have been emailed to customer.');
        }
    }
}