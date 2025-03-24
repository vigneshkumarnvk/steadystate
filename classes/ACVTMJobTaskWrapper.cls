global with sharing class ACVTMJobTaskWrapper {
    @AuraEnabled
    public TM_Job_Task__c JobTask { set; get; }

    @AuraEnabled
    public List<TM_Line__c> TMLines { set; get; }

    @AuraEnabled
    public Boolean Collapsed { set; get; }

    //use this variable to return TM line no
    @AuraEnabled
    public Integer NextTMLineNo { set; get; }

    //deleted lines <<
    @AuraEnabled
    public List<TM_Line__c> DeletedTMLines { set; get; }
    //deleted tm lines >>

    public ACVTMJobTaskWrapper() {
        this.TMLines = new List<TM_Line__c>();

        //deleted tm lines <<
        this.DeletedTMLines = new List<TM_Line__c>();
        //deleted tm lines >>
    }

    public ACVTMJobTaskWrapper(TM_Job_Task__c jobTask, List<TM_Line__c> tmLines) {
        this.JobTask = jobTask;
        this.TMLines = tmLines;

        //deleted tm lines <<
        this.DeletedTMLines = new List<TM_Line__c>();
        //deleted tm lines >>
    }
}