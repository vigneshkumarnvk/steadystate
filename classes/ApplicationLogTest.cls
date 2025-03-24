/*************************************************************************************************
* Name         :  
* Description  :  ApplicationLogTest Test Class for ApplicationLog
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Pavithra P				07-23-2024			   US118581 - Salesforce - Add integration log.
***********************************************************************************************************/
@isTest
private class ApplicationLogTest {

    @isTest
    static void testApplicationLog() {
        // TO DO: implement unit test
        try{
            Contact con = new Contact();
            insert con;
        }catch(Exception e){
            ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
    logData.className = 'ApplicationlogTest';
    logData.message = 'Exception occured while inserting new contact' + e.getMessage();
    logData.serviceRequest = 'Insert Contact';
    logData.serviceResponse = 'Inserted new Contact';
    logData.endpoint = 'test.test.com';
    ApplicationLog.startLog(JSON.serialize(logData));
    ApplicationLog.resetLog();
        }
    }

    
}