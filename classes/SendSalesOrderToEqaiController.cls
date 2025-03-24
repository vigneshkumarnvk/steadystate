/******************************************************************************************************
* Class Name: SendSalesOrderToEqaiController
* Description: It will send Sales Order and Sales Lines to EQAI when user submit [Send Sales Order to EQAI]
* 			   button on Sales Order.
* ***************************************************************************************************
* Owner		        Task #			Date		Description
* Andrew Simons                     2/12        Updated component to lightning component instead of vf page. 
* Andrew Simons     Task #71766     2/15        The SO_sent_to_EQAI__c is now set to true, regardless if integration is successful or failure. 
                                                This is to allow user to continue sales process (create T&M's) even if integration fails.
* Vennila P			78904		    2/19        Commented line #35 to 38 
  Shahwaz Khan      78352          02-20-2024  Salesforce - When Choosing Facility on SQ vs SO
  Shahwaz Khan      Bug80870       03-11-2024   3rd Party Restriction Impact on Group B Service Centers
* ******************************************************************************************************/

 public class SendSalesOrderToEqaiController {
     
  
    @AuraEnabled
    public static string sendSalesOrderToEQAI(Id recordId) {
        CompanyMgmt.systemCall = true;
        try { 
            List<Sales_Order__c> salesOrder = [SELECT ID, SO_sent_to_EQAI__c,Account_Executives__c,
                                               Account_Executives__r.Account_Executive__c,
                                               SO_Submitted_to_EQAI__c, Service_Center__c,  
                                               Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c,
                                               Name_of_Worker_Responsible__c, Worker_Responsible__c, 
                                               Estimated_Job_Start_Date__c  from Sales_Order__c 
                                               where Id=:recordId order by createddate DESC limit 1];
            User currUser = [SELECT profile.name FROM User WHERE id = :userinfo.getUserId() limit 1];
            String profileName = currUser.profile.name;
            //Bug#80870
            List<Sales_Line__c> salesLines=New List<Sales_Line__c>();
            Date thrdPartyValDate = Date.valueOf(label.SO_3rd_Party_Facility_Check);
            salesLines = [Select Id from Sales_Line__c Where Sales_Order__c=:recordId AND Facility__r.Third_Party_Facility__c = true 
                          AND Sales_Order__r.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c=true 
                          AND CreatedDate >= :thrdPartyValDate ];
            System.debug('salesLines++++++++++++' + salesLines);
            System.debug('thrdPartyValDate++++++++++' +thrdPartyValDate);
            if(salesOrder[0].Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c == false){
                return 'Service Center Disabled';
            }
            else if(salesOrder.size()>0 && salesOrder[0].Id != Null && salesOrder[0].SO_sent_to_EQAI__c == true)
            {
                return 'Sent to EQAI';
            }
            else if(salesOrder.size()>0 && salesOrder[0].Id != Null && salesOrder[0].SO_Submitted_to_EQAI__c == true && profileName != 'System Administrator')
            {
                return 'Sent to EQAI';
            }
            else if(salesOrder[0].Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c == true && (salesOrder[0].Worker_Responsible__c == null || salesOrder[0].Name_of_Worker_Responsible__c == null || salesOrder[0].Estimated_Job_Start_Date__c == null)) {
                return 'Missing Fields Required';
            }
            //Task#78352
            else if(salesLines.size()>0)
            {
                System.debug('3rdPartyFacility');
                return '3rdPartyFacility';
            }
            else if(salesOrder[0].Account_Executives__c != null && salesOrder[0].Account_Executives__r.Account_Executive__c != True)
            {
                return 'Salesperson is not AE';
            }
            else 
            {
                String response = workOrderQuoteService.workOrderQuoteHeaderInfo(recordId);
                //78904 
               /* Sales_Order__c so = salesOrder[0];
                so.SO_Submitted_to_EQAI__c = true;
                update so;*/
                return response;
            }
        }
        catch(exception ex) {
            System.Debug('Error::'+ex.getMessage());
            System.Debug('Error::'+ex.getLineNumber());            
            throw ex;
        }
    }
}