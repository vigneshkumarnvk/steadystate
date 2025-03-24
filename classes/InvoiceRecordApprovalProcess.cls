public class InvoiceRecordApprovalProcess {
    /*
     * Ticket#16912
     * add approval comment
     */
    private Sales_Invoice__c invoiceRecord;
    private List<Sales_Invoice_Line__c> salesInvoiceLines = new List<Sales_Invoice_Line__c>(); //Ticket#16182
    private static List<Approval_Tree__c> approvalTrees = new List<Approval_Tree__c>();
    private static Map<Decimal, Approval_Tree__c> approvalTreesByLevel = new Map<Decimal, Approval_Tree__c>();
    private Boolean isSelfApproved = false;
    private Boolean isApprovalNeeeded = true;
    private static Map<Id, Decimal> approvalProfitMarginByUserIds = new Map<Id, Decimal>();
    private Map<Id, String> tmNamesByIds = new Map<Id, String>();
    public Boolean isInitialApprovalRequest {get; set;}
    public String approvalComment {get; set;}

    public InvoiceRecordApprovalProcess(Sales_Invoice__c invoiceRecord){
        this.invoiceRecord = invoiceRecord;
        salesInvoiceLines = SalesInvoiceLinesSelector.newInstance().selectByInvoiceId(this.invoiceRecord.Id); //Ticket#16182
        this.setApprovalTree();
        this.initApprovalTreeMaps();
    }

    public void setApprovalTree(){
        String docType = '';

        if (this.invoiceRecord.Worksheet__c == true) {
            docType = EnumUtil.ApprovalTreeDocType.SALES_INVOICE.name();
        } else if (this.invoiceRecord.Worksheet__c == false && this.invoiceRecord.Credit_Memo__c == false){
            docType = EnumUtil.ApprovalTreeDocType.SALES_INVOICE.name();
        }

        Map<String, List<Approval_Tree__c>> approvalTreesByDocTypeSvcCtrSOType =
                ApprovalTreesSelector.newInstance().selectByDocTypeWithApprovalTreesByDocTypeScvCtrSOType(docType);
        //System.debug('Info: approvalTreesByDocTypeSvcCtrSOType ' + approvalTreesByDocTypeSvcCtrSOType);
        String keyString = docType + ':' + this.invoiceRecord.Service_Center__c + ':' + this.invoiceRecord.Sales_Order__r.Sales_Order_Type__c;
        //System.debug('Info: keyString 1 ' + keyString);
        if(!approvalTreesByDocTypeSvcCtrSOType.containsKey(keyString)){
            keyString = docType + ':' + 'null:' + this.invoiceRecord.Sales_Order__r.Sales_Order_Type__c;
            //System.debug('Info: keyString 2 ' + keyString);
            if(!approvalTreesByDocTypeSvcCtrSOType.containsKey(keyString)){
                keyString = docType + ':' + this.invoiceRecord.Service_Center__c + ':null';
                //System.debug('Info: keyString 3 ' + keyString);
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
            throw (Exception) new DataException(docType + ' Approval step setup does not exist for service center ' + this.invoiceRecord.Service_Center__r.Name);
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
        Decimal approvedStep = CompanyMgmt.zeroIfNull(this.invoiceRecord.Approved_Level__c);
        Integer i = 0;
        for(Decimal level:approvalTreesByLevel.keySet()){
            i += 1;
            if(level > approvedStep){
                Approval_Tree__c approvalTree = approvalTreesByLevel.get(level);
                if(approvalTree.Approver__c != this.invoiceRecord.OwnerId || approvalTreesByLevel.size() == i){
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
        //System.debug('Info: submitApprovalRequest begin >>');
        //System.debug('Info: isInitialApprovalRequest ' + isInitialApprovalRequest);
        if(this.invoiceRecord.Document_Status__c != 'Open'){
            throw new DataException('You can only submit invoice with Open status for approval!');
        }

        Decimal nextLevel = 0;
        Decimal approvedProfitMargin = CompanyMgmt.zeroIfNull(this.invoiceRecord.Approved_Profit_Margin__c);
        //System.debug('Info: submitApprovalRequest approvedProfitMargin: ' + approvedProfitMargin);
        if(this.invoiceRecord.Worksheet__c == true){
            List<Sales_Invoice__c> parentInvoices = SalesInvoicesSelector.newInstance().selectById(new Set<Id>{this.invoiceRecord.Parent_Record__c});
            if(parentInvoices.size() > 0) approvedProfitMargin = CompanyMgmt.zeroIfNull(parentInvoices[0].Approved_Profit_Margin__c);
            //System.debug('Info: submitApprovalRequest Worksheet approvedProfitMargin: ' + approvedProfitMargin);
        } else {
            Set<Id> tmLineIds = new Set<Id>();
            //Ticket#16182
            //for(Sales_Invoice_Line__c salesInvoiceLine: this.invoiceRecord.Sales_Invoice_Lines__r){
            for(Sales_Invoice_Line__c salesInvoiceLine: salesInvoiceLines){
                if(salesInvoiceLine.TM_Line__c != null) {
                    tmLineIds.add(salesInvoiceLine.TM_Line__c);
                }
            }
            List<Sales_Invoice_Line__c> approvedCreditMemoWorksheets = SalesInvoiceLinesSelector.newInstance().selectApprovedCreditMemoWorksheetByTMLineIds(tmLineIds);

            if(approvedCreditMemoWorksheets.size() > 0){
                approvedProfitMargin = CompanyMgmt.zeroIfNull(approvedCreditMemoWorksheets[0].Sales_Invoice__r.Approved_Profit_Margin__c);
                //System.debug('Info: approvedCreditMemoWorksheets approvedProfitMargin ' + approvedProfitMargin);
                //System.debug('Info: submitApprovalRequest with Existing Worksheet Linked approvedProfitMargin: ' + approvedProfitMargin);
            }

            /*
            else {
                if(this.invoiceRecord.Sales_Order__r.Approval_Status__c == EnumUtil.ApprovalStatus.Approved.name()
                        && isInitialApprovalRequest == true
                        && this.invoiceRecord.Contract__c == null){
                    approvedProfitMargin = CompanyMgmt.zeroIfNull(this.invoiceRecord.Sales_Order__r.Approved_Profit_Margin__c);
                    System.debug('Info: Approved Sales Order approvedProfitMargin ' + approvedProfitMargin);
                }
            }
             */
        }

        //System.debug('Info: approvedProfitMargin ' + approvedProfitMargin);

        if(isApprovalNeeded(this.invoiceRecord.Invoice_Amount__c, this.invoiceRecord.Invoice_Profit_Prct__c, approvedProfitMargin) == true) {
            //if document owner is one of the approver
            if (approvalProfitMarginByUserIds.containsKey(this.invoiceRecord.OwnerId)) {
                //System.debug('Info: document owner is one of the approver ' + approvalProfitMarginByUserIds);
                Boolean processed = false;
                for (Decimal level : approvalTreesByLevel.keySet()) {
                    Approval_Tree__c approvalTree = approvalTreesByLevel.get(level);
                    if (approvalTree.Approver__c == this.invoiceRecord.OwnerId) {
                        if (this.invoiceRecord.Approved_Level__c == null) this.invoiceRecord.Approved_Level__c = level;

                        //System.debug('Info: document owner is one of the approver Approved Level ' + this.invoiceRecord.Approved_Level__c);
                        nextLevel = calcNextStep();
                        //System.debug('Info: document owner is one of the approver nextLevel ' + nextLevel);

                        //document owner is the last owner
                        if (approvalTree.Level__c == getLastLevel() || CompanyMgmt.zeroIfNull(approvalTree.Approval_Margin_Pct__c) < CompanyMgmt.zeroIfNull(this.invoiceRecord.Invoice_Profit_Prct__c)){
                            this.invoiceRecord.Pending_Approval_Level__c = approvalTree.Level__c;
                            this.isSelfApproved = true;
                            if(processed == false){
                                approveRecord();
                                processed = true;
                            }
                            nextLevel = 0;
                            //System.debug('Info: document owner is the last owner ' + nextLevel);
                        }
                    }
                }
            } else {
                nextLevel = calcNextStep();
                //System.debug('Info: nextLevel ' + nextLevel);
                if (nextLevel == getLastLevel()) {
                    Approval_Tree__c approvalTree = approvalTreesByLevel.get(nextLevel);
                    if (approvalTree.Approver__c == this.invoiceRecord.OwnerId) {
                        this.invoiceRecord.Pending_Approval_Level__c = approvalTree.Level__c;
                        this.isSelfApproved = true;
                        approveRecord();
                        nextLevel = 0;
                    }
                }
            }

            if (nextLevel > 0) {
                Savepoint sp = Database.setSavepoint();
                try {
                    this.invoiceRecord.Approval_Status__c = EnumUtil.ApprovalStatus.PENDING_APPROVAL.name();
                    this.invoiceRecord.Pending_Approval_Level__c = nextLevel;
                    this.invoiceRecord.Pending_Approval_From__c = approvalTreesByLevel.get(nextLevel).Approver__r.Name;
                    this.invoiceRecord.Approved__c = false;
                    this.invoiceRecord.Approval_Step_Completed__c = false;
                    this.invoiceRecord.Approval_Date__c = null;
                    update this.invoiceRecord;

                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();

                        if(String.isNotBlank(approvalComment)){
                            req.setComments(approvalComment);
                        }

                    req.setObjectId(this.invoiceRecord.Id);
                    req.setProcessDefinitionNameOrId('InvoiceAndCreditMemo');
                    req.setSkipEntryCriteria(true);
                    if (Test.isRunningTest()) req.setNextApproverIds(new Id[]{
                            UserInfo.getUserId()
                    }); else req.setNextApproverIds(new Id[]{
                            approvalTreesByLevel.get(nextLevel).Approver__c
                    });
                    Approval.ProcessResult result = Approval.process((Approval.ProcessRequest) req);

                } catch (Exception e) {
                    Database.rollback(sp);
                    throw e;
                }
            }
        } else {
            approveRecord();
        }

        if(this.invoiceRecord.Approved__c != true) lockRecord();
    }

    public void approveRecord(){
        //System.debug('Info: approveRecord Begin >> ');
        //System.debug('Info: approveRecord Begin Approved Level ' + this.invoiceRecord.Approved_Level__c);
        //System.debug('Info: approveRecord Begin Pending Approval Level ' + this.invoiceRecord.Approved_Level__c);

        this.invoiceRecord.Approved_Level__c = this.invoiceRecord.Pending_Approval_Level__c;
        update this.invoiceRecord;

        //System.debug('Info: approveRecord Begin Approved Level ' + this.invoiceRecord.Approved_Level__c);
        //System.debug('Info: approveRecord isApprovalNeeeded ' + this.isApprovalNeeeded);

        Boolean lastLevel = false;
        if(this.isApprovalNeeeded == true){
            //check next approval step
            if(approvalTreesByLevel.containsKey(this.invoiceRecord.Approved_Level__c + 1)){
                Approval_Tree__c approvalTree = approvalTreesByLevel.get(this.invoiceRecord.Approved_Level__c + 1);
                if(CompanyMgmt.zeroIfNull(approvalTree.Approval_Margin_Pct__c) <= CompanyMgmt.zeroIfNull(this.invoiceRecord.Invoice_Profit_Prct__c)){
                    lastLevel = true;
                }
            } else {
                lastLevel = true;
            }
        }

        //System.debug('Info: approveRecord lastLevel ' + lastLevel);

        if(this.invoiceRecord.Approved_Level__c == getLastLevel() || lastLevel || isApprovalNeeeded == false){
            this.invoiceRecord.Approval_Status__c = EnumUtil.ApprovalStatus.Approved.name();
            this.invoiceRecord.Approved_Amount__c = this.invoiceRecord.Invoice_Amt_Incl_Tax__c;
            this.invoiceRecord.Approved_Profit_Margin__c = this.invoiceRecord.Invoice_Profit_Prct__c;
            this.invoiceRecord.Approval_Date__c = Date.today();
            this.invoiceRecord.Approved__c = true;

            Sales_Invoice__c creditMemo = new Sales_Invoice__c();
            if(this.invoiceRecord.Worksheet__c == true){
                Sales_Invoice__c parentInvoice = SalesInvoicesSelector.newInstance().selectByIdWithSILinesForReverse(new Set<Id>{this.invoiceRecord.Parent_Record__c})[0];
                List<Sales_Invoice_Line__c> parentInvoiceLines = new List<Sales_Invoice_Line__c>();
                parentInvoiceLines = SalesInvoiceLinesSelector.newInstance().selectByInvoiceId(parentInvoice.Id);
                creditMemo = SalesInvoicesService.createCreditMemo(parentInvoice, this.invoiceRecord.Id);
                if(creditMemo.Id != null){
                    List<Sales_Invoice__c> creditMemos = SalesInvoicesSelector.newInstance().selectById(new Set<Id>{creditMemo.Id});
                    if(creditMemos.size() > 0){
                        creditMemo = creditMemos[0];
                        this.invoiceRecord.Reversed_by_CM_No__c = creditMemo.Id;
                    }
                }
                //Ticket#16182
                //for(Sales_Invoice_Line__c salesInvoiceLine : parentInvoice.Sales_Invoice_Lines__r){
                for(Sales_Invoice_Line__c salesInvoiceLine : parentInvoiceLines){
                    if(salesInvoiceLine.TM__c != null){
                        tmNamesByIds.put(salesInvoiceLine.TM__c, salesInvoiceLine.TM__r.Name);
                    }
                }
            }

            update this.invoiceRecord;

            if(this.invoiceRecord.Worksheet__c == true) sendApprovedNotification(creditMemo);
            else sendApprovedNotification(this.invoiceRecord);

        } else {
            submitApprovalRequest();
        }
    }

    public void lockRecord(){
        Approval.LockResult lr = Approval.lock(this.invoiceRecord, false);
        if(!lr.isSuccess()){
            for(Database.Error err : lr.getErrors()){
                throw (Exception) new DataException(err.getStatusCode() + ': ' + err.getMessage());
            }
        }
    }

    public void sendApprovedNotification(Sales_Invoice__c record){
        if(isInitialApprovalRequest != true || this.invoiceRecord.Worksheet__c == true){
            //System.debug('Info: sendApprovedNotification ' + record.Name);
            Map<String, String> userEmailMap = new Map<String, String>();
            List<User> owners = UsersSelector.newInstance().selectById(new Set<Id>{this.invoiceRecord.OwnerId});
            userEmailMap.put(owners[0].Name, owners[0].Email);
            String docType = this.invoiceRecord.Worksheet__c == true ? 'Credit Memo Worksheet' : 'Sales Invoice';

            String emailSubject = docType + '# ' + this.invoiceRecord.Name + ' Approved / ' + this.invoiceRecord.Bill_to_Customer__r.Name + ' / $' + this.invoiceRecord.Invoice_Amt_Incl_Tax__c;
            String instanceUrl = Url.getSalesforceBaseUrl().getHost();
            String recordUrlMsg = '';
            if(this.invoiceRecord.Worksheet__c == false){
                recordUrlMsg = '<p>Please click <a href=\'' + instanceUrl + '/' + this.invoiceRecord.Id +  '\'>here</a> to open the ' + docType +' record.</p>';
            } else {
                recordUrlMsg = '<p>Credit Memo # <b>' + record.Name + '</b> is created! Please click <a href=\'' + instanceUrl + '/' + record.Id +  '\'>here</a> to open the record.</p>';
                if(tmNamesByIds.size() > 0){
                    recordUrlMsg += '<p>Following T&Ms will be affected after the credit memo is posted! Please review and </p>';
                    for(Id mapKey : tmNamesByIds.keySet()){
                        recordUrlMsg += 'Please click <a href=\'' + instanceUrl + '/' + mapKey +  '\'>here</a> to open the T&M No. ' + tmNamesByIds.get(mapKey) + '<br/>';
                    }
                }
            }

            List<ApprovalComment.ApprovalCommentWrap> approvalCommentWraps = new List<ApprovalComment.ApprovalCommentWrap>();
            ApprovalComment approvalComment = new ApprovalComment(this.invoiceRecord.Id);
            approvalCommentWraps = approvalComment.approvalCommensWraps;

            if(approvalCommentWraps.size() > 0){
                recordUrlMsg += '<table><tbody><tr>' +
                        '<th colspan="3" style="text-align: left">Approval Comments</th>' +
                        '</tr><tr>' +
                        '<td style="width: 150px; border-bottom: black solid 1px;">By</td>' +
                        '<td style="width: 300px; border-bottom: black solid 1px;">Comment</td>' +
                        '<td style="width: 200px; border-bottom: black solid 1px;">Date/Time</td></tr>';

                for(ApprovalComment.ApprovalCommentWrap approvalCommentWrap : approvalCommentWraps){
                    recordUrlMsg += '<tr><td>' + approvalCommentWrap.actor + '</td>' +
                            '<td>' + approvalCommentWrap.comment + '</td>' +
                            '<td>' + approvalCommentWrap.createdDate + '</td></tr>';
                }

                recordUrlMsg += '</tbody></table>';
            }

            for(String userType : userEmailMap.keySet()){
                String htmlBody = docType + '# ' + this.invoiceRecord.Name + ' Approved <br/>Customer: ' +
                        this.invoiceRecord.Bill_to_Customer__r.Name +
                        '<br/>Service Center: ' + this.invoiceRecord.Service_Center__r.Name +
                        '<br/>Entered By: ' + this.invoiceRecord.CreatedBy.Name +
                        '<br/>Amount: $' + this.invoiceRecord.Invoice_Amt_Incl_Tax__c +
                        recordUrlMsg;
                //'<br/>Please click <a href=\'' + URL.getSalesforceBaseUrl().getHost() + '/' + this.invoiceRecord.Id +  '\'>here</a> to open the sales record.';
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

                String[] addresses = new List<String>();
                addresses.add(userEmailMap.get(userType));
                email.setSubject(emailSubject);
                email.setToAddresses(addresses);
                email.setHtmlBody(htmlBody);

                Messaging.SendEmailResult[] r = Messaging.sendEmail((List<Messaging.Email>) new Messaging.SingleEmailMessage[]{ email });
            }
        }
    }

    public Boolean isApprovalNeeded(Decimal totalSalesAmt, Decimal totalMargin, Decimal approvedMargin){
        //System.debug('Info: 1 isApprovalNeeded total sales Amount ' + totalSalesAmt + ' total Margin ' + totalMargin + ' approved margin ' + approvedMargin);
        if(CompanyMgmt.zeroIfNull(approvedMargin) != 0){
            if(isInitialApprovalRequest == true){
                if(approvalTreesByLevel.containsKey(1) == true){
                    if(CompanyMgmt.zeroIfNull(totalMargin) >= CompanyMgmt.zeroIfNull(approvalTreesByLevel.get(1).Approval_Margin_Pct__c)){
                        isApprovalNeeeded = false;
                        return false;
                    }
                }
            }

            if(CompanyMgmt.zeroIfNull(totalMargin) >= approvedMargin){
                isApprovalNeeeded = false;
                //System.debug('Info: 2 isApprovalNeeded total sales Amount ' + totalSalesAmt + ' total Margin ' + totalMargin + ' approved margin ' + approvedMargin + ' is approval needed ' + isApprovalNeeeded);
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
        //System.debug('Info: isApprovalNeeded total sales Amount ' + totalSalesAmt + ' total Margin ' + totalMargin + ' approved margin ' + approvedMargin);
        isApprovalNeeeded = true;
        return true;
    }
}