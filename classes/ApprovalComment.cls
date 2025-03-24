public class ApprovalComment {

    public Id recordID {get; set;}

    public ApprovalComment(){}

    public ApprovalComment(Id recordId){
        this.recordID = recordId;
    }

    public class ApprovalCommentWrap{
        public String actor{get; set;}
        public String status{get; set;}
        public String comment{get; set;}
        public Datetime createdDate{get; set;}
    }

    public List<ApprovalCommentWrap> approvalCommensWraps{
        get{
            List<ApprovalCommentWrap> approvalCommentWraps = new List<ApprovalCommentWrap>();
            if(recordID != null){
                String recordAPIName = recordId.getSobjectType().getDescribe().getName();
                Id targetObjectId = null;
                if(recordAPIName == 'ProcessInstanceStep'){
                    ProcessInstanceStep processInstanceStep = [SELECT Id, ProcessInstanceId FROM ProcessInstanceStep WHERE Id = :recordId LIMIT 1];
                    ProcessInstance processInstance = [SELECT Id, TargetObjectId FROM ProcessInstance WHERE Id = :processInstanceStep.ProcessInstanceId LIMIT 1];
                    targetObjectId = processInstance.TargetObjectId;
                } else {
                    targetObjectId = recordId;
                }

                String objectName = targetObjectId.getSobjectType().getDescribe().getName();
                switch on objectName {
                    when 'Sales_Order__c'{
                        Sales_Order__c salesOrder = [SELECT Id,
                        (SELECT Id, Actor.Name, StepStatus, Comments, CreatedDate
                        FROM ProcessSteps
                        WHERE Comments != null
                        ORDER BY CreatedDate DESC)
                        FROM Sales_Order__c WHERE Id = :targetObjectId LIMIT 1];

                        for(ProcessInstanceHistory processInstanceHistory: salesOrder.ProcessSteps){
                            ApprovalCommentWrap approvalCommentWrap = new ApprovalCommentWrap();
                            approvalCommentWrap.actor = processInstanceHistory.Actor.Name;
                            approvalCommentWrap.status = processInstanceHistory.StepStatus;
                            approvalCommentWrap.comment = processInstanceHistory.Comments;
                            approvalCommentWrap.createdDate = TimeUtils.getDatetimeInUserTZ(processInstanceHistory.CreatedDate);
                            approvalCommentWraps.add(approvalCommentWrap);
                        }
                    }
                    when 'Sales_Invoice__c' {
                        Sales_Invoice__c salesInvoice = [SELECT Id,
                        (SELECT Id, CreatedDate, StepStatus, Comments, Actor.Name
                        FROM ProcessSteps
                        WHERE Comments != null
                        ORDER BY CreatedDate DESC)
                        FROM Sales_Invoice__c WHERE Id = :targetObjectId LIMIT 1];
                        for(ProcessInstanceHistory processInstanceHistory: salesInvoice.ProcessSteps){
                            ApprovalCommentWrap approvalCommentWrap = new ApprovalCommentWrap();
                            approvalCommentWrap.actor = processInstanceHistory.Actor.Name;
                            approvalCommentWrap.status = processInstanceHistory.StepStatus;
                            approvalCommentWrap.comment = processInstanceHistory.Comments;
                            approvalCommentWrap.createdDate = TimeUtils.getDatetimeInUserTZ(processInstanceHistory.CreatedDate);
                            approvalCommentWraps.add(approvalCommentWrap);
                        }
                    }
                    when 'Purchase_Order__c' {
                        Purchase_Order__c purchaseOrder = [SELECT Id,
                        (SELECT Id, CreatedDate, StepStatus, Comments, Actor.Name
                        FROM ProcessSteps
                        WHERE Comments != null
                        ORDER BY CreatedDate DESC)
                        FROM Purchase_Order__c WHERE Id = :targetObjectId LIMIT 1];
                        for(ProcessInstanceHistory processInstanceHistory: purchaseOrder.ProcessSteps){
                            ApprovalCommentWrap approvalCommentWrap = new ApprovalCommentWrap();
                            approvalCommentWrap.actor = processInstanceHistory.Actor.Name;
                            approvalCommentWrap.status = processInstanceHistory.StepStatus;
                            approvalCommentWrap.comment = processInstanceHistory.Comments;
                            approvalCommentWrap.createdDate = TimeUtils.getDatetimeInUserTZ(processInstanceHistory.CreatedDate);
                            approvalCommentWraps.add(approvalCommentWrap);
                        }
                    }
                    when else {

                    }
                }
            }
            return approvalCommentWraps;
        }
    }
}