public class ApprovalTreesSelector extends fflib_SObjectSelector{

    public static ApprovalTreesSelector newInstance(){
        return (ApprovalTreesSelector) Application.Selector.newInstance(Approval_Tree__c.SObjectType);
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
                Approval_Tree__c.Id,
                Approval_Tree__c.Name,
                Approval_Tree__c.Service_Center__c,
                Approval_Tree__c.Sales_Order_Type__c,
                Approval_Tree__c.Document_Type__c,
                Approval_Tree__c.Approver__c,
                Approval_Tree__c.Level__c,
                Approval_Tree__c.Approval_Margin_Pct__c
        };
    }

    public SObjectType getSObjectType(){
        return Approval_Tree__c.SObjectType;
    }

    public override String getOrderBy(){
        return 'Document_Type__c, Service_Center__r.Name, Sales_Order_Type__r.Name, Level__c';
    }

    public List<Approval_Tree__c> selectApprovalTreesByDocType(String docType){
        String queryString = newQueryFactory().selectField('Approver__r.Name')
                .setCondition('Document_Type__c = :docType')
                .addOrdering('Level__c', fflib_QueryFactory.SortOrder.ASCENDING)
                .addOrdering('Service_Center__r.Name', fflib_QueryFactory.SortOrder.ASCENDING)
                .addOrdering('Sales_Order_Type__r.Name', fflib_QueryFactory.SortOrder.ASCENDING)
                .toSOQL();

        return (List<Approval_Tree__c>) Database.query(queryString);
    }

    public Map<String, List<Approval_Tree__c>> selectByDocTypeWithApprovalTreesByDocTypeScvCtrSOType(String docType){
        Map<String, List<Approval_Tree__c>>  approvalTreesByDocTypeScvCtrSOType = new Map<String, List<Approval_Tree__c>>();
        for(Approval_Tree__c approvalTree:selectApprovalTreesByDocType(docType)){

            String keyStr = approvalTree.Document_Type__c.toUpperCase() + ':' + approvalTree.Service_Center__c + ':' + approvalTree.Sales_Order_Type__c;
            if(approvalTreesByDocTypeScvCtrSOType.containsKey(keyStr)){
                List<Approval_Tree__c> approvalTrees = approvalTreesByDocTypeScvCtrSOType.get(keyStr);
                approvalTrees.add(approvalTree);
                approvalTreesByDocTypeScvCtrSOType.put(keyStr, approvalTrees);
            } else {
                approvalTreesByDocTypeScvCtrSOType.put(keyStr, new List<Approval_Tree__c>{approvalTree});
            }
        }

        return approvalTreesByDocTypeScvCtrSOType;
    }

    public List<Approval_Tree__c> getApprovalTreeByDocTypeBySrvCtrByOrderType(String docType, Id srvCtr, Id orderType) {
        Map<String, List<Approval_Tree__c>> approvalTreesByDocTypeSvcCtrSOType =
                ApprovalTreesSelector.newInstance().selectByDocTypeWithApprovalTreesByDocTypeScvCtrSOType(docType);

        //System.debug('Info: approvalTreesByDocTypeSvcCtrSOType ' + approvalTreesByDocTypeSvcCtrSOType);
        List<Approval_Tree__c> approvalTrees = new List<Approval_Tree__c>();
        String keyString = docType + ':' + srvCtr + ':' + orderType;

        //System.debug('Info: keyString 1' + keyString);
        if(!approvalTreesByDocTypeSvcCtrSOType.containsKey(keyString)){
            keyString = docType + ':' + 'null:' + orderType;
            //System.debug('Info: keyString 2' + keyString);
            if(!approvalTreesByDocTypeSvcCtrSOType.containsKey(keyString)){
                keyString = docType + ':' + srvCtr + ':null';
                //System.debug('Info: keyString 3' + keyString);
                if(approvalTreesByDocTypeSvcCtrSOType.containsKey(keyString)){
                    approvalTrees = approvalTreesByDocTypeSvcCtrSOType.get(keyString);
                    //System.debug('Info: approvalTrees 3 ' + approvalTrees);
                }
            } else {
                approvalTrees = approvalTreesByDocTypeSvcCtrSOType.get(keyString);
                //System.debug('Info: approvalTrees 2 ' + approvalTrees);
            }
        } else {
            approvalTrees = approvalTreesByDocTypeSvcCtrSOType.get(keyString);
            //System.debug('Info: approvalTrees 1 ' + approvalTrees);
        }
        return approvalTrees;
    }
}