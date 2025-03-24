public class PurchOrderApprovalProcess{
    private Purchase_Order__c thePO;
    private List<Approval_Setup_Step__c> theApprovalTree;
    private Map<Id, Decimal> approvalTreeUserIdandAmtMap = new Map<Id, Decimal>();
    private Boolean selfApproved = false;
    private Map<Decimal, Approval_Setup_Step__c> approvalTreeWithLevelMap = new Map<Decimal, Approval_Setup_Step__c>();
    private Set<Decimal> approvalLevelSets;
    private Integer ApprovalTreeSize = 0;

    public PurchOrderApprovalProcess(Purchase_Order__c purchaseOrder){
        thePO = purchaseOrder;
        getApprovalTree();
        createApprovalTreeWithLevelMap();
        CompanyMgmt.systemCall = true;
    }

    private void getApprovalTree(){
        theApprovalTree = [SELECT Id, Name, User__c, Level__c, Service_Center__c, Amount__c, User__r.Name
        FROM Approval_Setup_Step__c WHERE Service_Center__c =: thePO.Service_Center__c AND Type__c =: thePO.Order_Type__c ORDER BY Level__c];

        ApprovalTreeSize = theApprovalTree.size();

        if (ApprovalTreeSize == 0) {
            thePO.addError('Approval step setup does not exist for service center ' + thePO.Service_Center__r.Name);
        }
    }

    private void createApprovalTreeWithLevelMap(){
        if(ApprovalTreeSize > 0){
            for(Approval_Setup_Step__c approvalSetup : theApprovalTree){
                approvalTreeWithLevelMap.put(approvalSetup.Level__c, approvalSetup);
            }
            approvalLevelSets = approvalTreeWithLevelMap.keySet();
        }
    }

    public void getApprovalTreeWithAmount(){
        if(ApprovalTreeSize > 0){
            for(Approval_Setup_Step__c approvalSetup : theApprovalTree){
                approvalTreeUserIdandAmtMap.put(approvalSetup.User__c, approvalSetup.Amount__c);
            }
        }
    }

    public Decimal getNextStep(){
        Decimal approvalStep = 0;
        if (String.isEmpty(thePO.Approval_Status__c) || (thePO.Approval_Status__c == null)){
            if (approvalTreeWithLevelMap.isEmpty()){
                throw (Exception) new myException('Approval setup does not exit for the service center ' + thePO.Service_Center__r.Name);
            } else {
                //set first approval level
                Integer i = 0;
                for (Decimal approvalLevel : approvalLevelSets){
                    i += 1;
                    Approval_Setup_Step__c approvalSetupStep = approvalTreeWithLevelMap.get(approvalLevel);
                    if((approvalSetupStep.User__c != thePO.OwnerId)||(ApprovalTreeSize == i)) {
                        approvalStep = approvalLevel;
                        break;
                    }
                }
            }
        } else {
            if(thePO.Approval_Status__c.isNumeric()){
                Decimal approvedStep = Decimal.valueOf(thePO.Approval_Status__c);
                Integer i = 0;
                for (Decimal approvalLevel : approvalLevelSets){
                    i += 1;
                    if(approvalLevel > approvedStep) {
                        Approval_Setup_Step__c approvalSetupStep = approvalTreeWithLevelMap.get(approvalLevel);
                        if((approvalSetupStep.User__c != thePO.OwnerId)||(ApprovalTreeSize == i)){
                            approvalStep = approvalLevel;
                            break;
                        }
                    }
                }
            } else {
                throw (Exception) new myException('Invalid Approval Step: ' + thePO.Approval_Status__c);
            }
        }

        return approvalStep;
    }

    public Decimal getLastStep(){
        return theApprovalTree[theApprovalTree.size() - 1].Level__c;
    }

    public void submitApprovalRequest(){
        getApprovalTreeWithAmount();
        Decimal currentStep = 0;
        //if PO owner is one of the approver
        if (approvalTreeUserIdandAmtMap.containsKey(thePO.OwnerId) && thePO.Order_Type__c.toUpperCase() != 'CAPEX'){
            for(Decimal mapKey: approvalTreeWithLevelMap.keySet()){
                Approval_Setup_Step__c approvalSetupStep = approvalTreeWithLevelMap.get(mapKey);
                if (approvalSetupStep.User__c == thePO.OwnerId){
                    if(thePO.Approval_Status__c == null){
                        thePO.Approval_Status__c = String.valueOf(approvalSetupStep.Level__c);
                    }
                    currentStep = getNextStep();

                    //if the PO owner is the last approver
                    if(approvalSetupStep.Level__c == getLastStep()){
                        thePO.Pending_Approval_Step__c = String.valueOf(approvalSetupStep.Level__c);
                        selfApproved = true;
                        approvePO();
                    }
                }
            }
        } else {
            currentStep = getNextStep();
            if((thePO.Order_Type__c.toUpperCase() == 'CAPEX') && (currentStep == getLastStep())){
                Approval_Setup_Step__c approvalSetupStep = approvalTreeWithLevelMap.get(currentStep);
                if(approvalSetupStep.User__c == thePO.OwnerId){
                    thePO.Pending_Approval_Step__c = String.valueOf(approvalSetupStep.Level__c);
                    selfApproved = true;
                    approvePO();

                    //reset currentStep
                    currentStep = 0;
                }
            }
        }

        if(currentStep > 0 || Test.isRunningTest()){
            Savepoint sp = Database.setSavepoint();
            try{
                thePO.Document_Status__c = 'Pending Approval';
                thePO.Pending_Approval_Step__c = String.valueOf(currentStep);
                if(Test.isRunningTest()){
                    thePO.Pending_Approval_From__c = 'Test';
                } else {
                    thePO.Pending_Approval_From__c = approvalTreeWithLevelMap.get(currentStep).User__r.Name;
                }
                thePO.Approval_Step_Completed__c = false;
                update thePO;

                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setObjectId(thePO.Id);
                req.setProcessDefinitionNameOrId('SC15_REG');
                req.setSkipEntryCriteria(true);
                if(Test.isRunningTest()) {
                    req.setNextApproverIds(new Id[]{UserInfo.getUserId()});
                } else {
                    req.setNextApproverIds(new Id[]{approvalTreeWithLevelMap.get(currentStep).User__c});
                }
                Approval.ProcessResult result = Approval.process(req);

            } catch (Exception e){
                Database.rollback(sp);
                throw e;
            }
        }

        if(!selfApproved){
            lockPO();
        }
    }

    public void resubmitForApproval(){
        thePO.Document_Status__c = 'Pending Approval';
        thePO.Approved_Amount__c = 0;
        thePO.Approval_Step_Completed__c = false;
        thePO.Approval_Status__c = null;
        thePO.Pending_Approval_Step__c = null;
        thePO.Is_Temporary__c = true;
        update thePO;

        submitApprovalRequest();
    }

    public void approvePO(){
        thePO.Approval_Status__c = thePO.Pending_Approval_Step__c;
        update thePO;
        Boolean lastStep = false;
        if(!approvalTreeWithLevelMap.isEmpty() && thePO.Order_Type__c.toUpperCase() == 'REGULAR'){
            Approval_Setup_Step__c approvalSetupStep = approvalTreeWithLevelMap.get(Decimal.valueOf(thePO.Approval_Status__c));
            if(CompanyMgmt.zeroIfNull(approvalSetupStep.Amount__c) >= CompanyMgmt.zeroIfNull(thePO.Order_Cost_Incl_Tax__c)){
                lastStep = true;
            }
        }

        if(thePO.Approval_Status__c == String.valueOf(getLastStep()) || lastStep){

            Map<String, Numbering_Series__c> mapNumberSeries, tempNumberSeriesMap = new Map<String, Numbering_Series__c>();
            Numbering_Series__c theNumberingSeries, tempNumberingSeries;

            mapNumberSeries = CompanyMgmt.getNumber('Purchase Order');
            theNumberingSeries = mapNumberSeries.get('Purchase Order');

            tempNumberSeriesMap = CompanyMgmt.getNumber('PO Temp Number');
            tempNumberingSeries = tempNumberSeriesMap.get('PO Temp Number');

            Purchase_Order__c po = [SELECT Id, Name, Service_Center__r.Name, Service_Center__r.Code__c FROM Purchase_Order__c WHERE Id =: thePO.Id];

            //System.debug('############Steven ' + thePO.Name + '----' + thePO.Is_Temporary__c);
            //System.debug('############Steven ' + thePO.Name + '----' + thePO.Is_Temporary__c + '-------' + thePO.Name.containsIgnoreCase(tempNumberingSeries.Prefix__c));

            //fix po number not assigned when a new po is saved + submitted for approval at the same time and the approver is the current user <<
            //if(thePO.Is_Temporary__c == true && thePO.Name.containsIgnoreCase(tempNumberingSeries.Prefix__c)){
            if ((thePO.Is_Temporary__c == true && thePO.Name != null && thePO.Name.containsIgnoreCase(tempNumberingSeries.Prefix__c))
                || (thePO.Name == null && selfApproved == true)){
            //fix po number not assigned when a new po is saved + submitted for approval at the same time and the approver is the current user >>
            
                //System.debug('#########Steven ' + thePO.Is_Temporary__c + '......' + tempNumberingSeries.Prefix__c);
                thePO.Name = po.Service_Center__r.Code__c
                        + theNumberingSeries.Separator__c
                        + String.valueOf(theNumberingSeries.Last_Number_Used__c);
            }

            thePO.Document_Status__c = 'Approved';
            thePO.Approved_Amount__c = thePO.Order_Cost_Incl_Tax__c;
            thePO.Approval_Step_Completed__c = true;
            thePO.Is_Temporary__c = false;
            update thePO;
            update mapNumberSeries.values();
            sendApprovedNotification();
        } else{
            submitApprovalRequest();
        }
    }

    public void lockPO(){
        Approval.LockResult lr = Approval.lock(thePO, false);
        if(!lr.isSuccess()){
            for(Database.Error err : lr.getErrors()){
                thePO.addError(err.getStatusCode() + ': ' + err.getMessage());
            }
        }
    }

    public void sendApprovedNotification(){
        Map<String, String> userEmailMap = new Map<String, String>();
        if(String.isNotEmpty(thePO.PO_Requestor__r.Email)){
            userEmailMap.put(thePO.PO_Requestor__r.Name, thePO.PO_Requestor__r.Email);
        }

        if (thePO.PO_Requestor__c != thePO.OwnerId || Test.isRunningTest()){
            User theUser = [SELECT Id, Name, Email FROM User WHERE Id =: thePO.OwnerId];
            if(String.isNotEmpty(theUser.Email)){
                userEmailMap.put(theUser.Name, theUser.Email);
            }
        }

        String emailSubject = thePO.Name + ' Approved / ' + thePO.Buy_from_Vendor__r.Name + ' / $' + thePO.Order_Cost_Incl_Tax__c;


        String approvalCommentHtml = '<br />Comments: <br /><br /><table><tbody>';

        ApprovalComment approvalComment = new ApprovalComment();
        approvalComment.recordID = thePO.Id;
        List<ApprovalComment.ApprovalCommentWrap> approvalCommentWraps = new List<ApprovalComment.ApprovalCommentWrap>();
        approvalCommentWraps = approvalComment.approvalCommensWraps;
        for(ApprovalComment.ApprovalCommentWrap approvalCommentWrap : approvalCommentWraps){
            approvalCommentHtml += '<tr>' +
                    '<td> ' +
                    approvalCommentWrap.actor + ':' +
                    '</td>' +
                    '<td> ' +
                    approvalCommentWrap.comment +
                    '</td>' +
                    '</tr>';
        }
        approvalCommentHtml += '</tbody></table>';


        for(String userType : userEmailMap.keySet()){
            String htmlBody = thePO.Name + ' Approved <br/>Vendor: ' + thePO.Buy_from_Vendor__r.Name + '<br/>Amount: $' + thePO.Order_Cost_Incl_Tax__c + '<br/>Please click <a href=\'' + Url.getSalesforceBaseUrl().getHost() + '/' + thePO.Id +  '\'>here</a> to open the purchase order.';
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            htmlBody += approvalCommentHtml;
            String[] addresses = new List<String>();
            addresses.add(userEmailMap.get(userType));
            email.setSubject(emailSubject);
            email.setToAddresses(addresses);
            email.setHtmlBody(htmlBody);

            Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ email });
        }
    }

    //public static List<String> checkSubmitForApproval(Purchase_Order__c thePO, List<Purchase_Line__c> thePLList) {
    public static void checkSubmitForApproval(Purchase_Order__c thePO, List<Purchase_Line__c> thePLList) {
        //List<String> errorList = new List<String>();
        //Ticket 13388 >>
        Set<String> scIds = new Set<String>();
        Map<String, Service_Center__c> scIdMap = new Map<String, Service_Center__c>();

        for(Purchase_Line__c pl : thePLList){
            if(!scIds.contains(pl.Service_Center__c)){
                scIds.add(pl.Service_Center__c);
            }
        }

        List<Service_Center__c> scLst = [SELECT Id, Name, PO_Allow_Blank_SO_with_Direct_GL_Account__c FROM Service_Center__c WHERE Id IN :scIds];
        for(Service_Center__c sc:scLst){
            scIdMap.put(sc.Id, sc);
        }
        //Ticket 13388 <<
        if (thePO.Service_Center__c == null){
            throw new DataException('Service Center cannot be blank');
            //errorList.add('Service Center cannot be blank');
        }

        if ((thePO.Document_Status__c != 'Open') && (thePO.Document_Status__c != 'Pending Approval') && thePO.Document_Status__c != 'Rejected') {
            throw new DataException('Purchase Order already been approved!');
            //errorList.add('Purchase Order already been approved!');
        }

        List<Approval_Setup_Step__c> approvalSteps = [SELECT Id FROM Approval_Setup_Step__c WHERE Service_Center__c = :thePO.Service_Center__c AND Type__c =: thePO.Order_Type__c];
        if (approvalSteps.isEmpty()) {
            throw new DataException('Approval step setup does not exist for service center ' + thePO.Service_Center__r.Name);
            //errorList.add('Approval step setup does not exist for service center ' + thePO.Service_Center__r.Name);
        }

        Integer lineCount = 0;
        for (Purchase_Line__c pl : thePLList) {
            if (String.isNotEmpty(pl.Item__c)) {
                if (String.isEmpty(pl.G_L_Account__c) && (thePO.Inter_co_Account__c == false)) {
                    throw new DataException('Line ' + pl.Line_No__c + ': G/L Account must not be blank.');
                    //errorList.add('Line ' + pl.Line_No__c + ': G/L Account must not be blank.');
                }

                if(pl.Direct_G_L_Account__c == true && pl.Sales_Order__c == null && scIdMap.get(pl.Service_Center__c).PO_Allow_Blank_SO_with_Direct_GL_Account__c != true){
                    throw new DataException('Line ' + pl.Line_No__c + ': Sales Order field must not be blank when direct G/L Account is used!');
                    //errorList.add('Line ' + pl.Line_No__c + ': Sales Order field must not be blank when direct G/L Account is used!');
                }

                lineCount++;
            }
            
        }
        if (lineCount == 0) {
            throw new DataException('There is nothing to submit.');
            //errorList.add('There is nothing to submit.');
        }
        //return errorList;
    }
}