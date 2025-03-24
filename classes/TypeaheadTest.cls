@isTest
private class TypeaheadTest{

    Static testMethod void ValidatesearchRecords() {     
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        List<String>fieldNames = new List<String>();
        fieldNames.add('ID');
        fieldNames.add('Name');        
        Typeahead.searchRecords('Name','Account',fieldNames,'Name','','',200,True);
        Typeahead.searchRecords('Name','Account',fieldNames,'Name','','',200,False);  
        Typeahead TH = new Typeahead();
        //TH.theCompanySetup=null;
        List<Company_Setup__c> theCompanySetupList = [SELECT Id FROM Company_Setup__c WHERE Id = :companySetup.Id];
        System.assertEquals(theCompanySetupList.Size(), 1);
    }
    
    Static testMethod void ValidateIDNamesearch() {  
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;   
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;   
        Account a = new Account();
        a.Name = 'Test Account'; 
        insert a;
        Typeahead.getRecordNameById('Account',a.ID);    
        Typeahead.getRecordIdByName('Account','Test Account'); 
        List<Company_Setup__c> theCompanySetupList = [SELECT Id FROM Company_Setup__c WHERE Id = :companySetup.Id];
        System.assertEquals(theCompanySetupList.Size(), 1);
    }    
            
    Static testMethod void ValidategetFieldIdMap() {    
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;    
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;        
        Typeahead.getFieldIdMap('Bin_Content__c');
        Typeahead.getFieldIdMap('Account','Name'); 
        Typeahead.getFieldIdMap('Bin_Content__c','Available__c'); 
        Typeahead.getSFieldIdMap();   
        Typeahead.getSObjectIdMap();  
        List<Company_Setup__c> theCompanySetupList = [SELECT Id FROM Company_Setup__c WHERE Id = :companySetup.Id];
        System.assertEquals(theCompanySetupList.Size(), 1);
    }     
    /* 0101617 
    Static testMethod void ValidatesearchRecords2() {     
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        List<String>fieldNames =New List<String>();
        fieldNames.add('ID');
        fieldNames.add('Name');        
        CloneTypeahead.searchRecords('Name','Account',fieldNames,'Name','','',200,True);
        CloneTypeahead.searchRecords('Name','Account',fieldNames,'Name','','',200,False);  
        CloneTypeahead TH=new CloneTypeahead();
        TH.theCompanySetup=null;
        List<Company_Setup__c> theCompanySetupList = [SELECT Id FROM Company_Setup__c WHERE Id = :companySetup.Id];
        System.assertEquals(theCompanySetupList.Size(), 1);
    }
    
    Static testMethod void ValidateIDNamesearch2() {  
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;   
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;   
        Account a = new Account();
        a.Name = 'Test Account'; 
        insert a;
        CloneTypeahead.getRecordNameById('Account',a.ID);    
        CloneTypeahead.getRecordIdByName('Account','Test Account'); 
        List<Company_Setup__c> theCompanySetupList = [SELECT Id FROM Company_Setup__c WHERE Id = :companySetup.Id];
        System.assertEquals(theCompanySetupList.Size(), 1);
    }    
            
    Static testMethod void ValidategetFieldIdMap2() {    
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;    
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;        
        CloneTypeahead.getFieldIdMap('Bin_Content__c');
        CloneTypeahead.getFieldIdMap('Account','Name'); 
        CloneTypeahead.getFieldIdMap('Bin_Content__c','Available__c'); 
        CloneTypeahead.getSFieldIdMap();   
        CloneTypeahead.getSObjectIdMap();  
        List<Company_Setup__c> theCompanySetupList = [SELECT Id FROM Company_Setup__c WHERE Id = :companySetup.Id];
        System.assertEquals(theCompanySetupList.Size(), 1);
    } 
    */
    
}