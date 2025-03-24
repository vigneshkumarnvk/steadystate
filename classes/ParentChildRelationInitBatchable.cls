//ticket 19130 - init data for the mod

/*
//sales line
    Init sales parent child relation from sales line Parent_Line__c
    Wizard_Question_Answered__c - ignore - should be true


//tm lines
    Init TM parent child relation from TM Line Parent_Line__c
    Wizard_Question_Answered__c = true if Confirmed + Mobile Review?
    Parent_Line__c?
    Is_Child_Resource__c = true if Parent_Line__c != null ? Open + Scheduled + Confirmed


//job task template Line
    UID__c
    Is_Child_Resource__c
    UOM_Qty__c = 1 ?
    Dereferenced_Child_Resource__c = false;l
*/

public with sharing class ParentChildRelationInitBatchable implements Database.Batchable<SObject>{

    public String SObjectName { set; get; }
    public String Target { set; get; }

    public ParentChildRelationInitBatchable(String sObjectName, String target) {
        this.SObjectName = sObjectName;
        this.Target = target;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String queryString;
        if (this.SObjectName == 'Sales_Line__c') {
            if (this.Target == 'WizardQuestion') {
                queryString = 'SELECT Id FROM Sales_Line__c WHERE Sales_Order__r.Document_Status__c = \'Open\' AND Wizard_Question_Answered__c != TRUE AND CreatedDate >= 2023-01-01T00:00:00.000Z';
            }
            else if (this.Target == 'Relation') {
                queryString = 'SELECT Id, Parent_Line__c FROM Sales_Line__c WHERE TempParentChildInit__c != TRUE AND Parent_Line__c != NULL';
            }
        }
        else if (this.SObjectName == 'TM_Line__c') {
            if (this.Target == 'WizardQuestion') {
                queryString = 'SELECT Id FROM TM_Line__c WHERE (TM__r.Status__c = \'Mobile Review\' OR TM__r.Status__c = \'Confirmed\') AND Wizard_Question_Answered__c != TRUE';
            }
            else if (this.Target == 'Relation') {
                queryString = 'SELECT Id, Parent_Line__c FROM TM_Line__c WHERE TempParentChildInit__c != TRUE AND Parent_Line__c != NULL';
            }
        }
        if (queryString == null) {
            throw new DataException('You must specify SObjectName and Target.');
        }
        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext bc, List<SObject> records) {
        Savepoint sp = Database.setSavepoint();
        try {
            if (this.SObjectName == 'Sales_Line__c') {
                if (this.Target == 'WizardQuestion') {
                    for (Sales_Line__c salesLine : (List<Sales_Line__c>) records) {
                        salesLine.Wizard_Question_Answered__c = true;
                    }
                    CompanyMgmt.byPassTrigger = true;
                    CompanyMgmt.byPassLineTrigger = true;
                    update records;
                }
                else if (this.Target == 'Relation') {
                    List<Sales_Line__c> salesLinesToUpdate = new List<Sales_Line__c>();
                    List<Sales_Parent_Child_Relation__c> relations = new List<Sales_Parent_Child_Relation__c>();
                    for (Sales_Line__c salesLine : (List<Sales_Line__c>) records) {
                        if (salesLine.Parent_Line__c != null) {
                            Sales_Parent_Child_Relation__c relation = new Sales_Parent_Child_Relation__c();
                            relation.Parent_Line__c = salesLine.Parent_Line__c;
                            relation.Child_Line__c = salesLine.Id;
                            relations.add(relation);
                            salesLine.Is_Child_Resource__c = true;
                            salesLine.TempParentChildInit__c = true;
                            salesLinesToUpdate.add(salesLine);
                        }
                    }

                    CompanyMgmt.byPassTrigger = true;
                    CompanyMgmt.byPassLineTrigger = true;
                    insert relations;
                    update salesLinesToUpdate;
                }
            }
            else if (this.SObjectName == 'TM_Line__c') {
                if (this.Target == 'WizardQuestion') {
                    for (TM_Line__c tmLine : (List<TM_Line__c>) records) {
                        tmLine.Wizard_Question_Answered__c = true;
                    }
                    CompanyMgmt.byPassTrigger = true;
                    CompanyMgmt.byPassLineTrigger = true;
                    update records;
                }
                else if (this.Target == 'Relation') {
                    List<TM_Line__c> tmLinesToUpdate = new List<TM_Line__c>();
                    List<TM_Parent_Child_Relation__c> relations = new List<TM_Parent_Child_Relation__c>();
                    for (TM_Line__c tmLine : (List<TM_Line__c>) records) {
                        if (tmLine.Parent_Line__c != null) {
                            TM_Parent_Child_Relation__c relation = new TM_Parent_Child_Relation__c();
                            relation.Parent_Line__c = tmLine.Parent_Line__c;
                            relation.Child_Line__c = tmLine.Id;
                            relations.add(relation);
                            tmLine.Is_Child_Resource__c = true;
                            tmLine.TempParentChildInit__c = true;
                            tmLinesToUpdate.add(tmLine);
                        }
                    }
                    CompanyMgmt.byPassTrigger = true;
                    CompanyMgmt.byPassLineTrigger = true;
                    insert relations;
                    update tmLinesToUpdate;
                }
            }
        }
        catch (Exception ex) {
            Database.rollback(sp);
        }
    }

    public void finish(Database.BatchableContext bc) {

    }

}