public class SalesRecordApprovalProcess {
    private Sales_Order__c salesRecord;
    private static List<Approval_Tree__c> approvalTrees = new List<Approval_Tree__c>();
    private static Map<Decimal, Approval_Tree__c> approvalTreesByLevel = new Map<Decimal, Approval_Tree__c>();
    private Boolean isSelfApproved = false;
    private Boolean isApprovalNeeeded = true;
    private static Map<Id, Decimal> approvalProfitMarginByUserIds = new Map<Id, Decimal>();
    public Boolean initialApprovalRequest { get; set; }

    public SalesRecordApprovalProcess(Sales_Order__c salesRecord){
        this.salesRecord  = salesRecord;
        this.setApprovalTree();
        this.initApprovalTreeMaps();
        this.initialApprovalRequest = false;
    }

    public void setApprovalTree(){
        String docType = '';
        if (this.salesRecord.Document_Type__c == 'Sales Quote') {
            docType = EnumUtil.ApprovalTreeDocType.SALES_QUOTE.name();
        } else if (this.salesRecord.Document_Type__c == 'Sales Order') {
            docType = EnumUtil.ApprovalTreeDocType.SALES_ORDER.name();
        }

        Map<String, List<Approval_Tree__c>> approvalTreesByDocTypeSvcCtrSOType =
                ApprovalTreesSelector.newInstance().selectByDocTypeWithApprovalTreesByDocTypeScvCtrSOType(docType);
        String keyString = docType + ':' + this.salesRecord.Service_Center__c + ':' + this.salesRecord.Sales_Order_Type__c;
        if(!approvalTreesByDocTypeSvcCtrSOType.containsKey(keyString)){
            keyString = docType + ':' + 'null:' + this.salesRecord.Sales_Order_Type__c;
            if(!approvalTreesByDocTypeSvcCtrSOType.containsKey(keyString)){
                keyString = docType + ':' + this.salesRecord.Service_Center__c + ':null';
                if(approvalTreesByDocTypeSvcCtrSOType.containsKey(keyString)){
                    approvalTrees = approvalTreesByDocTypeSvcCtrSOType.get(keyString);
                }
            } else {
                approvalTrees = approvalTreesByDocTypeSvcCtrSOType.get(keyString);
            }
        } else {
            approvalTrees = approvalTreesByDocTypeSvcCtrSOType.get(keyString);
        }

        if(approvalTrees.size() == 0){
            throw new DataException(this.salesRecord.Document_Type__c + ' Approval step setup does not exist for service center ' + this.salesRecord.Service_Center__r.Name);
        }
    }

    public void initApprovalTreeMaps(){

        for(Approval_Tree__c approvalTree:approvalTrees){
            approvalTreesByLevel.put(approvalTree.Level__c, approvalTree);
            approvalProfitMarginByUserIds.put(approvalTree.Approver__c, approvalTree.Approval_Margin_Pct__c);
        }
    }

    public Decimal calcNextStep(){
        Decimal nextStep = 0;
        Decimal approvedStep = CompanyMgmt.zeroIfNull(this.salesRecord.Approved_Level__c);
        Integer i = 0;
        for(Decimal level:approvalTreesByLevel.keySet()){
            i += 1;
            if(level > approvedStep){
                Approval_Tree__c approvalTree = approvalTreesByLevel.get(level);
                if(approvalTree.Approver__c != this.salesRecord.CreatedById || approvalTreesByLevel.size() == i){
                    nextStep = level;
                    break;
                }
            }
        }
        return nextStep;
    }

    public Decimal getLastLevel(){
        return approvalTrees[approvalTrees.size() - 1].Level__c;
    }

    public void submitApprovalRequest(){
        Decimal nextLevel = 0;
        //if(isApprovalNeeded(this.salesRecord.Total_Amount__c, this.salesRecord.Total_Margin_Pct__c, this.salesRecord.Approved_Profit_Margin__c) == true) {
        if(isApprovalNeeded(this.salesRecord.Order_Total_Amount__c, this.salesRecord.Total_Margin_Pct__c, this.salesRecord.Approved_Profit_Margin__c) == true) {
            //if document owner is one of the approver
            if (approvalProfitMarginByUserIds.containsKey(this.salesRecord.CreatedById)) {
                for (Decimal level : approvalTreesByLevel.keySet()) {
                    Approval_Tree__c approvalTree = approvalTreesByLevel.get(level);
                    if (approvalTree.Approver__c == this.salesRecord.CreatedById) {
                        if (this.salesRecord.Approved_Level__c == null) this.salesRecord.Approved_Level__c = level;
                        //if (isApprovalNeeded(this.salesRecord.Total_Amount__c, this.salesRecord.Total_Margin_Pct__c, approvalTree.Approval_Margin_Pct__c) == false) {
                        if (isApprovalNeeded(this.salesRecord.Order_Total_Amount__c, this.salesRecord.Total_Margin_Pct__c, approvalTree.Approval_Margin_Pct__c) == false) {
                            this.salesRecord.Approved_Level__c = approvalTree.Level__c;
                            this.isSelfApproved = true;
                            this.isApprovalNeeeded = false;
                            approveRecord();
                            break;
                        }

                        nextLevel = calcNextStep();

                        //document owner is the last owner
                        if (approvalTree.Level__c == getLastLevel()) {
                            this.salesRecord.Pending_Approval_Level__c = approvalTree.Level__c;
                            this.isSelfApproved = true;
                            approveRecord();
                        }
                    }
                }
            } else {
                nextLevel = calcNextStep();
                if (nextLevel == getLastLevel()) {
                    Approval_Tree__c approvalTree = approvalTreesByLevel.get(nextLevel);
                    if (approvalTree.Approver__c == this.salesRecord.CreatedById) {
                        this.salesRecord.Pending_Approval_Level__c = approvalTree.Level__c;
                        this.isSelfApproved = true;
                        approveRecord();
                        nextLevel = 0;
                    }
                }
            }

            if (nextLevel > 0) {
                try {
                    this.salesRecord.Approval_Status__c = EnumUtil.ApprovalStatus.PENDING_APPROVAL.name();
                    this.salesRecord.Pending_Approval_Level__c = nextLevel;
                    this.salesRecord.Pending_Approval_From__c = approvalTreesByLevel.get(nextLevel).Approver__r.Name;
                    this.salesRecord.Approved__c = false;
                    this.salesRecord.Approval_Step_Completed__c = false;
                    this.salesRecord.Get_Next_Approver__c = false;
                    this.salesRecord.Approved_Date__c = null; //Ticket#24688
                    update this.salesRecord;

                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                    req.setObjectId(this.salesRecord.Id);
                    req.setProcessDefinitionNameOrId('QuoteAndOrder');
                    req.setSkipEntryCriteria(true);
                    if (Test.isRunningTest()) req.setNextApproverIds(new Id[]{
                            UserInfo.getUserId()
                    }); else req.setNextApproverIds(new Id[]{
                            approvalTreesByLevel.get(nextLevel).Approver__c
                    });
                    Approval.ProcessResult result = Approval.process(req);

                } catch (Exception e) {
                    throw e;
                }
            }
        } else {
            approveRecord();
        }

        if(this.salesRecord.Approved__c != true) lockRecord();
    }
    
    public void reassignApprovalRequest(){
        try {
            fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
            if (this.salesRecord.Pending_Approval_Level__c != getLastLevel()) {
                this.salesRecord.Approved_Level__c = this.salesRecord.Pending_Approval_Level__c;
                Decimal nextLevel = calcNextStep();
                this.salesRecord.Pending_Approval_Level__c = nextLevel;
                this.salesRecord.Pending_Approval_From__c = approvalTreesByLevel.get(nextLevel).Approver__r.Name;
                this.salesRecord.Get_Next_Approver__c = false;
                uow.registerDirty(this.salesRecord);
                List<ProcessInstance> processInstances = [
                        SELECT
                                ElapsedTimeInDays,
                                ElapsedTimeInHours,
                                ElapsedTimeInMinutes,
                                Id,
                                Status,
                                TargetObjectId
                        FROM ProcessInstance
                        WHERE TargetObjectId = :this.salesRecord.Id AND Status = 'Pending'
                ];

                if (processInstances.size() > 0) {
                    List<ProcessInstanceWorkitem> processInstanceWorkitems = [
                            SELECT
                                    ActorId,
                                    ElapsedTimeInDays,
                                    ElapsedTimeInHours,
                                    ElapsedTimeInMinutes,
                                    Id,
                                    ProcessInstanceId
                            FROM ProcessInstanceWorkitem
                            WHERE ProcessInstanceId = :processInstances[0].Id
                    ];

                    if (processInstanceWorkitems.size() > 0) {
                        ProcessInstanceWorkitem processInstanceWorkitem = processInstanceWorkitems[0];
                        processInstanceWorkitem.ActorId = approvalTreesByLevel.get(nextLevel).Approver__c;
                        //ProcessInstanceWorkitem is not supported by UOW.
                        update processInstanceWorkitem;
                    }
                }
            }
            uow.commitWork();
        } catch (Exception e){
            throw e;
        }
    }

    public void approveRecord(){
        this.salesRecord.Approved_Level__c = this.salesRecord.Pending_Approval_Level__c;
        this.salesRecord.Get_Next_Approver__c = false;
        update this.salesRecord;

        Boolean lastLevel = false;
        if(this.isApprovalNeeeded == true){
            //check next approval step
            if(approvalTreesByLevel.containsKey(this.salesRecord.Approved_Level__c + 1)){
                Approval_Tree__c approvalTree = approvalTreesByLevel.get(this.salesRecord.Approved_Level__c + 1);
            if(CompanyMgmt.zeroIfNull(approvalTree.Approval_Margin_Pct__c) <= CompanyMgmt.zeroIfNull(this.salesRecord.Total_Margin_Pct__c)){
                lastLevel = true;
            }
            } else {
                lastLevel = true;
            }
        }

        if(this.salesRecord.Approved_Level__c == getLastLevel() || lastLevel || isApprovalNeeeded == false){
            this.salesRecord.Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name();
            //this.salesRecord.Approved_Amount__c = this.salesRecord.Total_Amount_Incl_Tax__c;
            this.salesRecord.Approved_Amount__c = this.salesRecord.Order_Total_Amount_Incl_Tax__c;
            this.salesRecord.Approved_Profit_Margin__c = this.salesRecord.Total_Margin_Pct__c;
            this.salesRecord.Approved__c = true;
            this.salesRecord.Approved_Date__c = System.today(); //Ticket#24688
            this.salesRecord.Approval_Step_Completed__c = false;
            update this.salesRecord;
            sendApprovedNotification();
        } else {
            submitApprovalRequest();
        }
    }

    public void lockRecord(){
        Approval.LockResult lr = Approval.lock(this.salesRecord, false);
        if(!lr.isSuccess()){
            for(Database.Error err : lr.getErrors()){
                throw new DataException(err.getStatusCode() + ': ' + err.getMessage());
                //salesRecord.addError();
            }
        }
    }

    public void sendApprovedNotification(){
        if(initialApprovalRequest != true){
            Map<String, String> userEmailMap = new Map<String, String>();
            List<User> owners = UsersSelector.newInstance().selectById(new Set<Id>{this.salesRecord.CreatedById});
            userEmailMap.put(owners[0].Name, owners[0].Email);

            Sales_Order__c salesRecord = SalesOrdersSelector.newInstance().selectByIdWithLinesAndProcessSteps(new Set<Id>{this.salesRecord.Id})[0];
            String approvalCommentHtml = '<br />Comments: <br /><br /><table><tbody>';

            for(ProcessInstanceHistory processInstanceHistory: salesRecord.ProcessSteps){
                approvalCommentHtml += '<tr>' +
                        '<td> ' +
                        processInstanceHistory.Actor.Name + ':' +
                        '</td>' +
                        '<td> ' +
                        processInstanceHistory.Comments +
                        '</td>' +
                        '</tr>';
                //approvalComment.add(processInstanceHistory.Actor.Name + ': ' + processInstanceHistory.Comments);
            }
            approvalCommentHtml += '</tbody></table>';

            //String emailSubject = this.salesRecord.Name + ' Approved / ' + this.salesRecord.Bill_to_Customer_No__r.Name + ' / $' + this.salesRecord.Total_Amt_Incl_Tax__c;
            //String emailSubject = salesRecord.Name + ' Approved / ' + salesRecord.Bill_to_Customer_No__r.Name + ' / $' + salesRecord.Total_Amount_Incl_Tax__c;
            String emailSubject = salesRecord.Name + ' Approved / ' + salesRecord.Bill_to_Customer_No__r.Name + ' / $' + salesRecord.Order_Total_Amount_Incl_Tax__c;

            for(String userType : userEmailMap.keySet()){
                //String htmlBody = salesRecord.Name + ' Approved <br/>Customer: ' + salesRecord.Bill_to_Customer_No__r.Name + '<br/>Amount: $' + salesRecord.Total_Amount_Incl_Tax__c + '<br/>Please click <a href=\'' + URL.getSalesforceBaseUrl().getHost() + '/' + salesRecord.Id +  '\'>here</a> to open the record.';
                String htmlBody = salesRecord.Name + ' Approved <br/>Customer: ' + salesRecord.Bill_to_Customer_No__r.Name + '<br/>Amount: $' + salesRecord.Order_Total_Amount_Incl_Tax__c + '<br/>Please click <a href=\'' + URL.getSalesforceBaseUrl().getHost() + '/' + salesRecord.Id +  '\'>here</a> to open the record.';
                htmlBody += approvalCommentHtml;
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

                String[] addresses = new List<String>();
                addresses.add(userEmailMap.get(userType));
                email.setSubject(emailSubject);
                email.setToAddresses(addresses);
                email.setHtmlBody(htmlBody);

                Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ email });
            }
        }
    }

    public Boolean isApprovalNeeded(Decimal totalSalesAmt, Decimal totalMargin, Decimal approvedMargin){
        if(CompanyMgmt.zeroIfNull(approvedMargin) != 0){
            if(CompanyMgmt.zeroIfNull(totalMargin) > approvedMargin){
                isApprovalNeeeded = false;
                return false;
            }
        } else {
            if(approvalTreesByLevel.size() > 0){
                for(Approval_Tree__c approvalTree:approvalTreesByLevel.values()){
                    //get the first level.
                    if(approvalTree.Approval_Margin_Pct__c <= totalMargin){
                        isApprovalNeeeded = false;
                        return false;
                    }
                    break;
                }
            }
        }

        isApprovalNeeeded = true;
        return true;
    }

    public void setApprovalStatusOnSave(){
        if(this.salesRecord.Approval_Status__c != EnumUtil.ApprovalStatus.PENDING_APPROVAL.name()){
            Decimal minProfitMargin = 0;
            if(approvalTreesByLevel.containsKey(1)){
                minProfitMargin = CompanyMgmt.zeroIfNull(approvalTreesByLevel.get(1).Approval_Margin_Pct__c);
            }
            Decimal approvedMargin = CompanyMgmt.zeroIfNull(this.salesRecord.Approved_Profit_Margin__c);
            Decimal totalProfitMargin = CompanyMgmt.zeroIfNull(this.salesRecord.Total_Margin_Pct__c);

            if (totalProfitMargin >= minProfitMargin
                    || (totalProfitMargin >= approvedMargin && this.salesRecord.Approval_Status__c == EnumUtil.ApprovalStatus.APPROVED.name()))
            {
                this.salesRecord.Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name();
                this.salesRecord.Approved_Profit_Margin__c = totalProfitMargin;
                //this.salesRecord.Approved_Amount__c = CompanyMgmt.zeroIfNull(this.salesRecord.Total_Amount_Incl_Tax__c);
                this.salesRecord.Approved_Amount__c = CompanyMgmt.zeroIfNull(this.salesRecord.Order_Total_Amount_Incl_Tax__c);
                this.salesRecord.Approved__c = true;
                this.salesRecord.Approval_Step_Completed__c = false;
                this.salesRecord.Pending_Approval_Level__c = null;
                this.salesRecord.Pending_Approval_From__c = null;
            } else {
                this.salesRecord.Approval_Status__c = EnumUtil.ApprovalStatus.DRAFT.name();
                this.salesRecord.Approved_Amount__c = null;
                this.salesRecord.Approved_Profit_Margin__c = null;
                this.salesRecord.Approved__c = false;
                this.salesRecord.Approved_Level__c = null;
                this.salesRecord.Pending_Approval_From__c = null;
                this.salesRecord.Pending_Approval_Level__c = null;
            }
        }
    }
}