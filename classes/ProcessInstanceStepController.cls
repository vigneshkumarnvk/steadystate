public with sharing class ProcessInstanceStepController{

    /*
    public class processInstanceStepWrapper{
        @AuraEnabled public String documentType {get; set;}
        @AuraEnabled public String approvalStatus {get; set;}
        @AuraEnabled public Date createdDate {get; set;}
        @AuraEnabled public String submitter {get; set;}
        @AuraEnabled public String actualApprover {get; set;}
        @AuraEnabled public String assignedTo {get; set;}
    }
    */
    @AuraEnabled
    public static List<ProcessInstanceHistory> getProcessInstanceHistories(Id recordId){

        List<ProcessInstanceHistory> processInstanceHistories = new List<ProcessInstanceHistory>();

        if(recordId != null){
            String recordAPIName = recordId.getSobjectType().getDescribe().getName();
            Id targetObjectId = null;
            if(recordAPIName == 'ProcessInstanceStep'){
                ProcessInstanceStep processInstanceStep = [SELECT Id, ProcessInstanceId FROM ProcessInstanceStep WHERE Id = :recordId LIMIT 1];
                ProcessInstance processInstance = [SELECT Id, TargetObjectId FROM ProcessInstance WHERE Id = :processInstanceStep.ProcessInstanceId LIMIT 1];
                targetObjectId = processInstance.TargetObjectId;
            } else if(recordAPIName == 'ProcessInstanceWorkitem') {
                ProcessInstanceWorkitem processInstanceWorkitem = [SELECT Id, ProcessInstanceId FROM ProcessInstanceWorkitem WHERE Id = :recordId LIMIT 1];
                ProcessInstance processInstance = [SELECT Id, TargetObjectId FROM ProcessInstance WHERE Id = :processInstanceWorkitem.ProcessInstanceId LIMIT 1];
                targetObjectId = processInstance.TargetObjectId;
            } else {
                targetObjectId = recordId;
            }

            String sObjectAPIName = targetObjectId.getSobjectType().getDescribe().getName();

            switch on sObjectAPIName{
                when 'Sales_Order__c'{
                    List<Sales_Order__c> salesOrders = [SELECT Id, (SELECT Id, CreatedDate, StepStatus, Comments, Actor.Name FROM ProcessSteps WHERE Comments != null ORDER BY CreatedDate DESC) FROM Sales_Order__c WHERE Id = :targetObjectId];
                    if(salesOrders.size() > 0){
                        for(Sales_Order__c salesOrder:salesOrders){
                            for(ProcessInstanceHistory processInstanceHistory:salesOrder.ProcessSteps){
                                processInstanceHistories.add(processInstanceHistory);
                            }
                        }
                    }
                }
                when 'Sales_Invoice__c' {
                    List<Sales_Invoice__c> salesInvoices = [SELECT Id, (SELECT Id, CreatedDate, StepStatus, Comments, Actor.Name FROM ProcessSteps WHERE Comments != null ORDER BY CreatedDate DESC) FROM Sales_Invoice__c WHERE Id = :targetObjectId];
                    if(salesInvoices.size() > 0){
                        for(Sales_Invoice__c salesInvoice:salesInvoices){
                            for(ProcessInstanceHistory processInstanceHistory:salesInvoice.ProcessSteps){
                                processInstanceHistories.add(processInstanceHistory);
                            }
                        }
                    }
                }
                when 'Purchase_Order__c' {
                    List<Purchase_Order__c> purchaseOrders = [SELECT Id, (SELECT Id, CreatedDate, StepStatus, Comments, Actor.Name FROM ProcessSteps WHERE Comments != null ORDER BY CreatedDate DESC) FROM Purchase_Order__c WHERE Id = :targetObjectId];
                    if(purchaseOrders.size() > 0){
                        for(Purchase_Order__c purchaseOrder : purchaseOrders){
                            for(ProcessInstanceHistory processInstanceHistory:purchaseOrder.ProcessSteps){
                                processInstanceHistories.add(processInstanceHistory);
                            }
                        }
                    }
                }
                when else {

                }
            }
        }

        return processInstanceHistories;
    }

    /*
    @AuraEnabled
    public static processInstanceStepWrapper getProcessInstanceStep(Id recordId){
        List<ProcessInstanceStep> processInstanceSteps = new List<ProcessInstanceStep>();
        processInstanceStepWrapper processInstanceStepWrapper = new processInstanceStepWrapper();
        if(recordId != null){
            processInstanceSteps = [SELECT ActorId,
                    Comments,
                    CreatedById,
                    CreatedDate,
                    ElapsedTimeInDays,
                    ElapsedTimeInHours,
                    ElapsedTimeInMinutes,
                    Id,
                    OriginalActorId,
                    ProcessInstanceId,
                    StepNodeId,
                    StepStatus,
                    SystemModstamp
            FROM ProcessInstanceStep WHERE Id = :recordId];

            if(processInstanceSteps.size() > 0){
                ProcessInstanceStep processInstanceStep = new ProcessInstanceStep();
                processInstanceStep = processInstanceSteps[0];

                ProcessInstance processInstance = [SELECT Id, TargetObjectId FROM ProcessInstance WHERE Id = :processInstanceStep.ProcessInstanceId LIMIT 1];
                Id targetObjectId = processInstance.TargetObjectId;

                Map<Id, String> userNamesByIds = new Map<Id, String>();
                Set<Id> userIds = new Set<Id>();
                userIds.add(processInstanceStep.CreatedById);
                userIds.add(processInstanceStep.ActorId);
                userIds.add(processInstanceStep.OriginalActorId);
                for(User user : UsersSelector.newInstance().selectById(userIds)){
                    userNamesByIds.put(user.Id, user.Name);
                }

                processInstanceStepWrapper.documentType = targetObjectId.getSobjectType().getDescribe().getLabel();
                if(processInstanceStepWrapper.documentType == 'Sales Invoice'){
                    List<Sales_Invoice__c> salesInvoices = [SELECT Id, Worksheet__c FROM Sales_Invoice__c WHERE Id = :targetObjectId];
                    if(salesInvoices.size() > 0){
                        if(salesInvoices[0].Worksheet__c == true){
                            processInstanceStepWrapper.documentType = 'Credit Memo Worksheet';
                        }
                    }
                }
                processInstanceStepWrapper.documentType = processInstanceStepWrapper.documentType + ' Approval';
                processInstanceStepWrapper.approvalStatus = processInstanceStep.StepStatus;
                processInstanceStepWrapper.createdDate = Date.newInstance(processInstanceStep.CreatedDate.year(),
                        processInstanceStep.CreatedDate.month(),
                        processInstanceStep.CreatedDate.day());
                processInstanceStepWrapper.actualApprover = userNamesByIds.get(processInstanceStep.ActorId);
                processInstanceStepWrapper.assignedTo = userNamesByIds.get(processInstanceStep.OriginalActorId);
                processInstanceStepWrapper.submitter = userNamesByIds.get(processInstanceStep.CreatedById);
            }
        }

        return processInstanceStepWrapper;
    }

    @AuraEnabled
    public static processInstanceStepWrapper getProcessInstanceWorkitem(Id recordId){
        List<ProcessInstanceWorkitem> processInstanceWorkitems = new List<ProcessInstanceWorkitem>();
        processInstanceStepWrapper processInstanceStepWrapper = new processInstanceStepWrapper();
        if(recordId != null){
            processInstanceWorkitems = [SELECT
                    ActorId,
                    CreatedById,
                    CreatedDate,
                    ElapsedTimeInDays,
                    ElapsedTimeInHours,
                    ElapsedTimeInMinutes,
                    Id,
                    IsDeleted,
                    OriginalActorId,
                    ProcessInstanceId,
                    SystemModstamp
            FROM ProcessInstanceWorkitem WHERE Id = :recordId];

            if(processInstanceWorkitems.size() > 0){
                ProcessInstanceWorkitem processInstanceWorkitem = processInstanceWorkitems[0];

                Map<Id, String> userNamesByIds = new Map<Id, String>();
                Set<Id> userIds = new Set<Id>();
                userIds.add(processInstanceWorkitem.CreatedById);
                userIds.add(processInstanceWorkitem.ActorId);
                userIds.add(processInstanceWorkitem.OriginalActorId);
                for(User user : UsersSelector.newInstance().selectById(userIds)){
                    userNamesByIds.put(user.Id, user.Name);
                }

                ProcessInstance processInstance = [SELECT Id, TargetObjectId FROM ProcessInstance WHERE Id = :processInstanceWorkitem.ProcessInstanceId LIMIT 1];
                Id targetObjectId = processInstance.TargetObjectId;

                processInstanceStepWrapper.documentType = targetObjectId.getSobjectType().getDescribe().getLabel();
                if(processInstanceStepWrapper.documentType == 'Sales Invoice'){
                    List<Sales_Invoice__c> salesInvoices = [SELECT Id, Worksheet__c FROM Sales_Invoice__c WHERE Id = :targetObjectId];
                    if(salesInvoices.size() > 0){
                        if(salesInvoices[0].Worksheet__c == true){
                            processInstanceStepWrapper.documentType = 'Credit Memo Worksheet';
                        }
                    }
                }
                processInstanceStepWrapper.documentType = processInstanceStepWrapper.documentType + ' Approval';
                //processInstanceStepWrapper.approvalStatus = processInstanceStep.StepStatus;
                processInstanceStepWrapper.createdDate = Date.newInstance(processInstanceWorkitem.CreatedDate.year(),
                        processInstanceWorkitem.CreatedDate.month(),
                        processInstanceWorkitem.CreatedDate.day());
                processInstanceStepWrapper.actualApprover = userNamesByIds.get(processInstanceWorkitem.ActorId);
                processInstanceStepWrapper.assignedTo = userNamesByIds.get(processInstanceWorkitem.OriginalActorId);
                processInstanceStepWrapper.submitter = userNamesByIds.get(processInstanceWorkitem.CreatedById);
            }
        }

        return processInstanceStepWrapper;

    }

    @AuraEnabled
    public static String answerApproveWorkItem(Id workItemId, String action, String comment, String userId){
        //action:  Reject or Approve
        System.debug('Info: workItemId ' + workItemId);

        System.debug('Info: comment ' + comment);
        System.debug('Info: userId ' + userId);
        String processInstanceStepId = '';
        if(action == 'approve' || action == 'reject'){
            action = action.capitalize();
            System.debug('Info: action ' + action);
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setComments(comment);
            req.setAction(action);
            req.setWorkitemId(workItemId);
            Approval.ProcessResult result = Approval.process(req);

            if(result.isSuccess()){
                String processInstanceId = result.getInstanceId();
                System.debug('Info: processInstanceId ' + processInstanceId);
                List<ProcessInstanceStep> processInstanceSteps = [SELECT Id FROM ProcessInstanceStep WHERE ProcessInstanceId = :processInstanceId ORDER BY CreatedDate DESC LIMIT 1];
                if(processInstanceSteps.size() > 0){
                    processInstanceStepId = processInstanceSteps[0].Id;
                    System.debug('Info: processInstanceId step Id ' + processInstanceStepId);
                }
            }
        } else if(action == 'reassign') {
            List<ProcessInstanceWorkitem> processInstanceWorkitems = [
                    SELECT
                            ActorId,
                            ElapsedTimeInDays,
                            ElapsedTimeInHours,
                            ElapsedTimeInMinutes,
                            Id,
                            ProcessInstanceId
                    FROM ProcessInstanceWorkitem
                    WHERE Id = :workItemId
            ];

            if (processInstanceWorkitems.size() > 0) {
                ProcessInstanceWorkitem processInstanceWorkitem = processInstanceWorkitems[0];
                processInstanceWorkitem.ActorId = userId;
                //ProcessInstanceWorkitem is not supported by UOW.
                update processInstanceWorkitem;

                List<ProcessInstanceStep> processInstanceSteps = [SELECT Id FROM ProcessInstanceStep WHERE ProcessInstanceId = :processInstanceWorkitem.ProcessInstanceId ORDER BY CreatedDate DESC LIMIT 1];
                if(processInstanceSteps.size() > 0){
                    processInstanceStepId = processInstanceSteps[0].Id;
                    System.debug('Info: processInstanceId step Id ' + processInstanceStepId);
                }
            }
        }

        return processInstanceStepId;
    }
     */
}