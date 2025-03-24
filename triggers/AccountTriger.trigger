/*************************************************************************************************
* Name         :  AccountTriger
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan      04-10-2024              84498: Account Name Validation 
* Prabhu Rathakrishnan      08-07-2024              US116306 : Updates to Opportunities and Sales Quotes - Post Group B
* Pavithra Periyasamy       10-03-2024              US124701 - [Continued] [Continued] [Unplanned] - Update - Salesforce Assign Multiple Salespeople to an Account and Sales Orders
* Andrew Simons             11-11-2024              US130968 - Removed Customer Type validation trigger logic
*************************************************************************************************/
trigger AccountTriger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (CompanyMgmt.byPassTrigger == true) return;
    
    List<Id> setOfSalesPersonIds = new list<Id>();
    //Id venRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
    if (Trigger.isBefore) {
        String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
        User currentUser = [SELECT Id, Allow_to_Change_Account_Owner__c FROM User WHERE Id = :UserInfo.getUserId()];

        if (Trigger.isInsert || Trigger.isUpdate) {
            Set<Id> aeIds = new Set<Id>();
            Set<Id> oIds = new Set<Id>();
            for (Account acct : Trigger.new) {
                if (acct.Type == 'Customer') {
                    if (acct.API_Call__c != true && profileName != 'System Administrator') {
                        if (acct.Name == null || acct.BillingStreet == null || acct.BillingCity == null || acct.BillingStateCode == null || acct.BillingPostalCode == null || acct.BillingCountryCode == null || acct.Account_Executive__c == null || acct.Subsidiary_Company__c == null) {
                            acct.addError('Required fields: Account Name, Billing Street, Billing City, Billing State, Billing Postal Code, Billing Country, Customer Type, Account Executive, Subsidiary Company');
                        }
                    }
                }

                //Ticket#21211 >>
                if(acct.Inter_co_Account__c == true && acct.InterCo__c == true){
                    acct.addError('Account can only be an Inter-Co or an Intra-Co account!');
                }

                if(acct.Inter_co_Account__c == true && acct.Tax_Liable__c == true){
                    acct.addError('Intra-Co account is not tax liable!');
                }
                //Ticket#21211 <<

                //Ticket# AES-404
                if (acct.Type == 'Prospect' && !Test.isRunningTest()) {
                    if (acct.API_Call__c != true && profileName != 'System Administrator') {
                        if (acct.Name == null || acct.BillingStreet == null || acct.BillingCity == null || acct.BillingStateCode == null || acct.BillingPostalCode == null || acct.BillingCountryCode == null || acct.Account_Executive__c == null || acct.Subsidiary_Company__c == null) {
                            acct.addError('Required fields: Account Name, Billing Street, Billing City, Billing State, Billing Postal Code, Billing Country, Account Executive, Subsidiary Company');
                        }
                    }
                }

                //replace '\n' with '\r\n' - issue with web service, \r gets truncated during web service calls
                if (acct.BillingStreet != null) {
                    if (acct.BillingStreet.contains('\n') && !acct.BillingStreet.contains('\r\n')) {
                        acct.BillingStreet = acct.BillingStreet.replace('\n', '\r\n');
                    }
                }

                if (acct.Account_Executive__c != null) {
                    if (!aeIds.contains(acct.Account_Executive__c)) {
                        aeIds.add(acct.Account_Executive__c);
                    }
                }
                if (!oIds.contains(acct.OwnerId)) {
                    oIds.add(acct.OwnerId);
                }

                if(acct.Account_Executive_Ids__c != null){
                    setOfSalesPersonIds.addall(acct.Account_Executive_Ids__c.split(','));
                }
                //Billing Instruction >>
                if(String.isBlank(acct.Invoice_Email_Contact_Types__c)){
                    acct.Invoice_Email_Contact_Types__c = AccountsService.INVOICE_EMAIL_CONTACT_TYPE_AP;
                } else {
                    if(acct.Invoice_Email_Contact_Types__c.containsIgnoreCase(AccountsService.INVOICE_EMAIL_CONTACT_TYPE_AP) == false){
                        acct.Invoice_Email_Contact_Types__c += ';' + AccountsService.INVOICE_EMAIL_CONTACT_TYPE_AP;
                    }
                }
                //84498
                if(!String.isBlank(acct.Name)){
                    if(Trigger.isInsert)
                        acct.Name = (acct.Name).toUpperCase();
                    else{
                        Account oacct = Trigger.oldMap.get(acct.Id);
                        if(!String.isBlank(oacct.Name)){
                            if(!(oacct.Name).equals((acct.Name).toUpperCase())){
                                acct.Name = (acct.Name).toUpperCase();
                            }
                        }
                        
                    }
                }
                acct.BillingStreet = !String.isBlank(acct.BillingStreet) ? acct.BillingStreet.toUpperCase() : '';
                acct.BillingCity = !String.isBlank(acct.BillingCity) ? acct.BillingCity.toUpperCase() : '';
                acct.Contact_Type_Filter__c = AccountsService.generateContactTypeFilterString(acct.Invoice_Email_Contact_Types__c);

                if(String.isBlank(acct.Invoice_Backup_Documents__c)){
                    acct.Invoice_Backup_Documents__c = AccountsService.INVOICE_BACKUP_TYPE_INVOICE;
                } else {
                    if(acct.Invoice_Backup_Documents__c.containsIgnoreCase(AccountsService.INVOICE_BACKUP_TYPE_INVOICE) == false){
                        acct.Invoice_Backup_Documents__c += ';' + AccountsService.INVOICE_BACKUP_TYPE_INVOICE;
                    }
                }

                /*
                if(String.isNotBlank(acct.Invoice_Email_Contact_Types__c)){
                    acct.Contact_Type_Filter__c = AccountsService.generateContactTypeFilterString(acct.Invoice_Email_Contact_Types__c);
                } else {
                    if(Trigger.oldMap != null && Trigger.oldMap.containsKey(acct.Id) == true) {
                        if (String.isNotBlank(Trigger.oldMap.get(acct.Id).Contact_Type_Filter__c)) {
                            acct.Contact_Type_Filter__c = null;
                        }
                    }
                }
                 */

                acct.Customer_Billing_Instructions__c = AccountsService.generateCustomerBillingVerbose(
                        acct.PO_Number_Type__c,
                        acct.Invoice_Email_Contact_Types__c,
                        acct.Invoice_Submission_Channels__c,
                        acct.Invoice_Portal__c,
                        acct.Invoice_Backup_Documents__c,
                        acct.Customer_Specific_Documentation__c);
                if(acct.Customer_Specific_Documentation__c != null)
                    acct.Customer_Billing_Instructions__c += 'Customer Specific Documentation:'+acct.Customer_Specific_Documentation__c;
                if(acct.Billing_Instructions__c != null)
                    acct.Customer_Billing_Instructions__c += 'Billing Instructions:'+acct.Billing_Instructions__c;

                /*
                acct.Billing_Instructions__c = AccountsService.generateBillingInstruction(
                        acct.PO_Number_Type__c,
                        acct.PO_Number_Format__c,
                        acct.Invoice_Email_Contact_Type__c,
                        acct.Invoice_Submission_Channel__c,
                        acct.Invoice_Portal__c,
                        acct.Invoice_Backup__c,
                        acct.Billing_Instructions__c);
                 */
                //Billing Instruction <<
            }

            //assign account by AE
            Map<Id, Salesperson__c> mUsers1 = new Map<Id, Salesperson__c>();
            Map<Id, Salesperson__c> mUsers2 = new Map<Id, Salesperson__c>();
            for (Salesperson__c sp : [SELECT Id, User__c FROM Salesperson__c WHERE (Id IN :aeIds AND User__c != NULL) OR User__c IN :oIds]) {
                mUsers1.put(sp.Id, sp);  //map by salesperson id
                mUsers2.put(sp.User__c, sp); //map by user id
            }

            Map<Id, Salesperson__c> salesPersonRecords = new Map<Id, Salesperson__c>();
            if(!setOfSalesPersonIds.isEmpty()){
                for(Salesperson__c sp : [SELECT Id, Name FROM Salesperson__c WHERE Id IN :setOfSalesPersonIds]){
                    salesPersonRecords.put(sp.Id,sp);
                }                
            }
            if (Trigger.isInsert) {
                for (Account acct : Trigger.new) {
                    if (acct.Type == 'Corporate' && acct.AccountNumber == null) {
                        acct.AccountNumber = AutoNumberController.GetNextNumber('Corporate No. Series');
                    }

                    //assign owner & AE
                    if (acct.Account_Executive__c != null) {
                        if (mUsers1.get(acct.Account_Executive__c) != null) {
                            acct.OwnerId = mUsers1.get(acct.Account_Executive__c).User__c; //assign owner by AE
                        }
                    }
                    else {
                        if (mUsers2.get(acct.OwnerId) != null) {
                            acct.Account_Executive__c = mUsers2.get(acct.OwnerId).Id; //assign AE by owner
                        }
                    }

                    AssignRecordType(acct);
                    //US124701
                    if(acct.Account_Executive_Ids__c != null && !setOfSalesPersonIds.isEmpty()){
                        acct.Account_Executives__c = AccountTriggersMgmt.updateAccountExecutives(acct.Account_Executive_Ids__c,salesPersonRecords);
                    }
                    
                }
            }

            Set<Id> acctIdsWithNewNAVAcctNo = new Set<Id>(); //Ticket#19831
            if (Trigger.isUpdate) {
                for (Account acct : Trigger.new) {
                    Account oacct = Trigger.oldMap.get(acct.Id);
                    if (acct.Type != oacct.Type && oacct.Type == 'Customer') {
                        if (profileName != 'System Administrator') {
                            acct.Type.addError('You must be a system administrator to change customer account type.');
                        }
                    }

                    //assign owner & AE
                    if (acct.Account_Executive__c != null && acct.Account_Executive__c !=  oacct.Account_Executive__c) {
                        if (mUsers1.get(acct.Account_Executive__c) != null) {
                            acct.OwnerId = mUsers1.get(acct.Account_Executive__c).User__c; //update Owner base on AE
                        }
                    }
                    else if (acct.OwnerId != oacct.OwnerId) { //
                        if (profileName != 'System Administrator' && currentUser.Allow_to_Change_Account_Owner__c != true) { //if owner changes verify privilege
                            acct.Owner.addError('You must be a system administrator to change owner.');
                        }
                        if (mUsers2.get(acct.OwnerId) != null) {
                            acct.Account_Executive__c = mUsers2.get(acct.OwnerId).Id;
                        }
                    }

                    //update sync flag only if integrated fields are modified
                    if (acct.API_Call__c != true){
                        if (acct.Name != oacct.Name || acct.BillingStreet != oacct.BillingStreet || acct.BillingCity != oacct.BillingCity || acct.BillingStateCode != oacct.BillingStateCode || acct.BillingPostalCode != oacct.BillingPostalCode
                                || acct.BillingCountryCode != oacct.BillingCountryCode || acct.Phone != oacct.Phone || acct.Fax != oacct.Fax
                                || acct.Website != oacct.Website || acct.ParentId != oacct.ParentId || acct.Salesperson__c != oacct.Salesperson__c || acct.Account_Executive__c != oacct.Account_Executive__c
                                || acct.Customer_Status__c != oacct.Customer_Status__c) {
                            acct.In_Sync__c = false;
                        }
                    }
                    acct.API_Call__c = false;

                    AssignRecordType(acct);

                    //Ticket#13807 AES-394 >>
                    if(acct.Type == 'Customer'){
                        if(String.isBlank(acct.Sage_Customer_No__c) || acct.Customer_Status__c == 'Inactive'){
                            acct.Emergency__c = true;
                        } else {
                            acct.Emergency__c = false;
                        }
                    }
                    //Ticket#13807 AES-394 <<

                    //Ticket#19831 >>
                    if(acct.AccountNumber != oacct.AccountNumber && String.isBlank(oacct.AccountNumber)){
                        acctIdsWithNewNAVAcctNo.add(acct.Id);
                    }
                    //Ticket#19831 >>
                    //US124701
                    if(acct.Account_Executive_Ids__c != oacct.Account_Executive_Ids__c && !setOfSalesPersonIds.isEmpty()){
                        acct.Account_Executives__c = AccountTriggersMgmt.updateAccountExecutives(acct.Account_Executive_Ids__c,salesPersonRecords);
                    }
                }
                //Ticket#19831 >>
                if(acctIdsWithNewNAVAcctNo.size() > 0){
                    List<Sales_Order__c> salesOrders = [SELECT Id, Sync_d__c FROM Sales_Order__c WHERE Document_Type__c = 'Sales Order' AND Bill_to_Customer_No__c IN :acctIdsWithNewNAVAcctNo];
                    if(salesOrders.size() > 0) {
                        for (Sales_Order__c salesOrder : salesOrders) {
                            salesOrder.Sync_d__c = false;
                        }
                        CompanyMgmt.byPassTrigger = true;
                        CompanyMgmt.byPassLineTrigger = true;
                        update salesOrders;
                    }
                }
                //Ticket#19831 >>
            }
        }
        if (Trigger.isDelete) {
            for (Account acct : Trigger.old) {
                if (acct.Type == 'Customer') {
                    if (profileName != 'System Administrator') {
                        acct.addError('You must be a system administrator to delete customer accounts.');
                    }
                }
            }
        }
        
    }
    else if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            List<Id> custIds = new List<Id>();
            for (Account acct : Trigger.new) {
                if (acct.Type == 'Customer') {
                    if (acct.ParentId != null) {
                        custIds.add(acct.Id);
                    }
                }
                else if (acct.Type == 'Corporate') {
                    if (acct.ParentId != null) {
                        acct.ParentId.addError('A corporate account must not have parent account.');
                    }
                }
            }

            Map<Id, Account> accts = new Map<Id, Account>();
            for (Account cust : [SELECT Id, ParentId, Parent.Type FROM Account WHERE Id IN :custIds]) {
                accts.put(cust.Id, cust);
            }

            for (Account cust : Trigger.new) {
                if (accts.containsKey(cust.Id)) {
                    if (accts.get(cust.Id).Parent.Type != 'Corporate') {
                        cust.ParentId.addError('The parent acocunt must be a corporate account.');
                    }
                }
            }

            AccountTriggersMgmt.accountInsertUpdate(Trigger.new, Trigger.oldMap, Trigger.isInsert);
        }
    }

    private void AssignRecordType(Account acct) {
        if (acct.Type == 'Customer') {
            //acct.RecordTypeId = '012f4000000MDXd';
            acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        }
        else if (acct.Type == 'Corporate') {
            //acct.RecordTypeId = '012f4000000MDWz';
            acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Corporate').getRecordTypeId();
            acct.NAV_ID__c = 'Corporate;' + acct.AccountNumber;
        }
        else if (acct.Type == 'Vendor') {
            acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        }
        else {
            //acct.RecordTypeId = '012f4000000MDX4';
            acct.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        }
    }
}