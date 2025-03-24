/*
    Ticket#20079 - new field Payment_Term__c
 */
public class ContractsSelector extends fflib_SObjectSelector implements IContractsSelector{

    public static IContractsSelector newInstance(){
        return (IContractsSelector) Application.Selector.newInstance(Contract.SObjectType);
    }

    public SObjectType getSObjectType() {
        return Contract.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
                Contract.Id,
                Contract.Name,
                Contract.ContractNumber,
                Contract.Status,
                Contract.AccountId,
                Contract.StartDate,
                Contract.EndDate,
                Contract.ContractTerm,
                Contract.Fuel_Surcharge_Pct__c,
                Contract.Energy_Insurance__c,
                Contract.Billing_Rule__c,
                Contract.Allow_Lunch_Time_on_Equipment__c,
                Contract.Billing_Instructions__c,
                Contract.Internal_Comments__c,
                Contract.Has_Lump_Sum_Lines__c,
                Contract.Surcharge_Type__c,
                Contract.Surcharge_Pct__c,
                Contract.Override_Remittance_on_Invoice__c,
                Contract.Remittance_Name__c,
                Contract.Remittance_Address_1__c,
                Contract.Remittance_Address_2__c,
                Contract.EFT_To_Bank_Name__c,
                Contract.EFT_Address_1__c,
                Contract.EFT_Address_2__c,
                Contract.Checking_Account_1__c,
                Contract.Checking_Account_2__c,
                Contract.Remittance_Phone__c,
                Contract.Logo__c,
                Contract.Payment_Term__c,
                Contract.Subsidiary__c, //Ticket#20977
                Contract.Description, //Ticket#28846
                Contract.SpecialTerms //Ticket#28846
        };
    }

    public List<Contract> selectById(Set<Id> idSet){
        return (List<Contract>) Database.query(newQueryFactory()
                .selectField('Billing_Rule__r.Name')
                .selectField('Billing_Rule__r.Quote_Order_Assumption__c')
                .selectField('Billing_Rule__r.Enable_Weekly_Total_Calculation__c') //Ticket#20496
                .selectField('Payment_Term__r.Name')
                .setCondition('Id IN :idSet').toSOQL());
    }

    /*
        Ticket#17949 Account Contract Association
    */
    public List<Contract> selectActivatedContractsByIds(Set<Id> contractIds){
        return (List<Contract>) Database.query(newQueryFactory()
                .selectField('Billing_Rule__r.Name')
                .selectField('Billing_Rule__r.Quote_Order_Assumption__c')
                .selectField('Payment_Term__r.Name')
                .selectField('Billing_Rule__r.Enable_Weekly_Total_Calculation__c') //Ticket#20496                
                .setCondition('Id IN :contractIds AND Status = \'Activated\'').toSOQL());
    }

    public List<Contract> selectByIdsWithLines(Set<Id> ids){
        fflib_QueryFactory contractQueryFactory = newQueryFactory();
        new ContractLinesSelector().addQueryFactorySubselect(contractQueryFactory);
        String strQuery = contractQueryFactory.setCondition('Id IN :ids').toSOQL();
        return Database.query(strQuery);
    }

    public List<Contract> selectByIdWithBillingRule(Set<Id> contractIds){
        fflib_QueryFactory contractQueryFactory = newQueryFactory()
                .selectField('Billing_Rule__r.Name')
                .selectField('Billing_Rule__r.Enable_Weekly_Total_Calculation__c'); //Ticket#20496

        new BillingRulesSelector().configureQueryFactoryFields(
                contractQueryFactory,
                Contract.Billing_Rule__c.getDescribe().getRelationshipName());

        return Database.query(
                contractQueryFactory.setCondition('Id IN :contractIds').toSOQL());
    }

    public List<Contract> selectBillingInstructionsById(Set<Id> idSet){
        return (List<Contract>) Database.query(
                newQueryFactory(true).
                        selectField(Contract.Id).
                        selectField(Contract.Billing_Instructions__c).
                        selectField(Contract.Internal_Comments__c).
                        setCondition(' Id IN :idSet').
                        toSOQL());
    }

    /*
        Ticket#17949 Account Contract Association
     */
    public List<Contract> selectByAccountId(Set<Id> accountIds) {
        Set<Id> contractIds = getAssociatedContractIdByAccountId(accountIds);
        return selectActivatedContractsByIds(contractIds);
    }

    /*
        Ticket#17949 Account Contract Association
    */
    public List<Account_Contract_Association__c> selectAccountContractAssociationByAccountId(Set<Id> accountIds){
        List<Account_Contract_Association__c> accountContractAssociations = new List<Account_Contract_Association__c>();
        accountContractAssociations = [SELECT Id, Contract__c, Account__c FROM Account_Contract_Association__c WHERE Account__c IN :accountIds];
        return accountContractAssociations;
    }

    /*
        Ticket#17949 Account Contract Association
    */
    public Set<Id> getAssociatedContractIdByAccountId(Set<Id> accountIds){
        Set<Id> contractIds = new Set<Id>();
        for(Account_Contract_Association__c accountContractAssociation : selectAccountContractAssociationByAccountId(accountIds)){
            contractIds.add(accountContractAssociation.Contract__c);
        }
        return contractIds;
    }

    /*
        Ticket#17949 Account Contract Association
     */
    public List<Account_Contract_Association__c> selectAccountContractAssociationByAcctIdAndConttractId(Id accountId, Id contractId){
        List<Account_Contract_Association__c> accountContractAssociations = new List<Account_Contract_Association__c>();
        accountContractAssociations = [SELECT Id, Contract__c, Account__c FROM Account_Contract_Association__c WHERE Account__c =:accountId AND Contract__c = :contractId];
        return accountContractAssociations;
    }
}