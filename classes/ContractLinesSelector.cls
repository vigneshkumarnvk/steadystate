public class ContractLinesSelector extends fflib_SObjectSelector implements IContractLinesSelector{

    public static IContractLinesSelector newInstance() {
        return (IContractLinesSelector) Application.Selector.newInstance(Contract_Line__c.SObjectType);
    }

    public Schema.SObjectType getSObjectType() {
        return Contract_Line__c.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
                Contract_Line__c.Id,
                Contract_Line__c.Name,
                Contract_Line__c.Resource__c,
                Contract_Line__c.Resource_Type__c,
                Contract_Line__c.Contract__c,
                Contract_Line__c.Resource_Category__c,
                Contract_Line__c.Resource_Type_Category__c,
                Contract_Line__c.Unit_of_Measure__c,
                Contract_Line__c.Regular_Rate__c,
                Contract_Line__c.Overtime_Rate__c,
                Contract_Line__c.Premium_Rate__c,
                Contract_Line__c.Customer_Description__c,
                Contract_Line__c.Customer_Item_No__c,
                Contract_Line__c.Customer_Overtime_Description__c,
                Contract_Line__c.Customer_Overtime_Item_No__c,
                Contract_Line__c.Customer_Premium_Description__c,
                Contract_Line__c.Customer_Premium_Item_No__c,
                Contract_Line__c.Min_Sell_Qty__c,
                Contract_Line__c.Min_Sell_Qty_Container_Size__c,
                Contract_Line__c.Facility__c,
                Contract_Line__c.Default__c,
                Contract_Line__c.Blocked__c,
                Contract_Line__c.End_Date__c
        };
    }

    public Map<Id, Contract_Line__c> selectTMDescriptionById (Set<Id> idSet){
        return new Map<Id, Contract_Line__c>((List<Contract_Line__c>) System.Database.query(
                newQueryFactory().selectField(Contract_Line__c.T_M_Description__c).setCondition('Id IN :idSet').toSOQL()));
    }

    public List<Contract_Line__c> selectById(Set<Id> idSet){
        return (List<Contract_Line__c>) Database.query(newQueryFactory()
                .selectField('Unit_of_Measure__r.Id')
                .selectField('Unit_of_Measure__r.Name')
                .setCondition('Id IN :idSet').toSOQL());
    }

    public List<Contract_Line__c> selectLinesByContractId(Set<Id> idSet) {
        return (List<Contract_Line__c>) Database.query(newQueryFactory()
                .selectField('Unit_of_Measure__r.Id')
                .selectField('Unit_of_Measure__r.Name')
                //aura <<
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                //aura >>
                .selectField('Resource__r.Name')
                .selectField('Resource_Type__r.Name')
                .setCondition('Contract__c IN :idSet').toSOQL());
    }

    public List<Contract_Line__c> selectLinesByContractIdByWorkDate(Set<Id> idSet, Date workDate){
        return (List<Contract_Line__c>) Database.query(newQueryFactory()
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Resource__r.Name')
                .selectField('Resource_Type__r.Name')
                //job task <<
                .selectField('Contract__r.Name')
                .selectField('Contract__r.ContractNumber')
                //job task >>
                .setCondition('Contract__c IN :idSet AND (Blocked__c = false OR End_Date__c >= :workDate)')
                .setOrdering('End_Date__c', fflib_QueryFactory.SortOrder.ASCENDING, false)
                .addOrdering('Name', fflib_QueryFactory.SortOrder.ASCENDING)
                .toSOQL());
    }

    /*
        Key format ContractId:ResourceType:UOM
     */
    public Map<String, Contract_Line__c> selectLinesWithContractIdResTypeAndUOMByContractId(Set<Id> contractIdSet){
        List<Contract_Line__c> contractLines = selectLinesByContractId(contractIdSet);
        Map<String, Contract_Line__c> linesWithContractIdResTypeAndUOM = new Map<String, Contract_Line__c>();
        for (Contract_Line__c contractLine : contractLines) {
            if(contractLine.Resource_Type__c != null){
                String mapKey = contractLine.Contract__c + ':' + contractLine.Resource_Type__c + ':' + contractLine.Unit_of_Measure__c;
                linesWithContractIdResTypeAndUOM.put(mapKey, contractLine);
            }
        }

        System.debug('Info: selectLinesWithContractIdResTypeAndUOMByContractId ' + linesWithContractIdResTypeAndUOM);
        return linesWithContractIdResTypeAndUOM;
    }

    /*
        Key format ContractId:Resource:UOM
     */
    public Map<String, Contract_Line__c> selectLinesWithContractIdResAndUOMByContractId(Set<Id> contractIdSet){
        List<Contract_Line__c> contractLines = selectLinesByContractId(contractIdSet);
        Map<String, Contract_Line__c> linesWithContractIdResAndUOM = new Map<String, Contract_Line__c>();
        for (Contract_Line__c contractLine : contractLines) {
            if(contractLine.Resource__c != null){
                String mapKey = contractLine.Contract__c + ':' + contractLine.Resource__c + ':' + contractLine.Unit_of_Measure__c;
                linesWithContractIdResAndUOM.put(mapKey, contractLine);
            }
        }
        System.debug('Info: linesWithContractIdResAndUOM ' + linesWithContractIdResAndUOM);
        return linesWithContractIdResAndUOM;
    }

    public Map<String, Contract_Line__c> mapLineByContractResORResourceTypeAndUOM(Set<Id> contractIds){
        Map<String, Contract_Line__c> lineByContractByResORResTypeByUOM = new Map<String, Contract_Line__c>();
        for(Contract_Line__c contractLine :selectLinesByContractId(contractIds)){
            String mapKey = '';
            if(contractLine.Resource__c != null){
                mapKey = mapKey = contractLine.Contract__c + ':' + contractLine.Resource__c + ':' + contractLine.Unit_of_Measure__c;
            }

            if(contractLine.Resource_Type__c != null && contractLine.Resource__c == null){
                mapKey = contractLine.Contract__c + ':' + contractLine.Resource_Type__c + ':' + contractLine.Unit_of_Measure__c;
            }
            if(String.isNotBlank(mapKey)) lineByContractByResORResTypeByUOM.put(mapKey, contractLine);
        }

        return lineByContractByResORResTypeByUOM;
    }
}