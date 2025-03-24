/*************************************************************************************************
* Name         :  ContactEQAIService 
* Description  :  Apex Class for API call out of the work order Quote Service
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Vennila Paramasivam		07/08/2024				Whenever a Contact insert/update it will sync to EQAI
* Andrew Simons             09-23-2024              US125732:add middle name, fax, salutation, suffix
* Shahwaz Khan              16/12/2024              Salesforce - Incl. web_access_flag field in contact sync integration (SF -> EQAI)
****************************************************************************************************************************************/
public class ContactEQAIServiceJson {
    Public string ContactCompany;
    Public string SalesforceContactCsid;
    Public string D365CustomerId;
    Public string ContactType;
    Public string EmployeeId;
    Public string FirstName;
    Public string LastName;
    Public string Title;
    Public string ContactAddr1;
    Public string ContactCity;
    Public string ContactState;
    Public string ContactZipCode;
    Public string ContactCountry;
    Public string Phone;
    Public string Mobile;
    Public string Email;
    Public string ContactCustomerStatus;
    Public string EmailFlag;
    Public string WebAccessFlag;
    Public string name;
    Public string ContactIdClone;
    Public string Fax;
    Public string Salutation;
    Public string Suffix;
    Public string MiddleName;
    //Public string web_access_flag;
    
    public static Map<String,String> countryCodeMap;
    public static Boolean isSkipValidation = false;
    
    Public ContactEQAIServiceJson(Contact con, String RSGEINNumber, String event)
    {
        if(con.AccountId!=Null)
        {
            D365CustomerId = con.Account.Sage_Customer_No__c;
            ContactCompany = con.Account.Name;
        }
        else
        {
            D365CustomerId = '';
            ContactCompany = '';
            
        }

        ContactIdClone = con.EQAI_Contact_Id__c;
        SalesforceContactCsid = con.id;
        ContactType = (con.Contact_Type__c!=null)?con.Contact_Type__c:'';
        EmployeeId = (RSGEINNumber!=null)?RSGEINNumber:'';
        FirstName = (con.FirstName!=null)?con.FirstName:'';
        LastName = (con.LastName!=null)?con.LastName:'';
        Title = (con.Title!=null)?con.Title:'';
        ContactAddr1 = (con.MailingStreet!=null)?String.valueOf(con.MailingStreet):'';
        if(ContactAddr1!='' && ContactAddr1.length() > 35)
        {
            ContactAddr1 = ContactAddr1.subString(0,34);
        }
        ContactCity = (con.MailingCity!=null)?con.MailingCity:'';
        ContactState = (con.MailingStateCode!=null)?con.MailingStateCode:'';
        ContactZipCode = (con.MailingPostalCode!=null)?con.MailingPostalCode:'';
        if(con.MailingCountry != null){        
            ContactCountry = (!(countryCodeMap.isempty())) && countryCodeMap.containskey(con.MailingCountry) ? countryCodeMap.get(con.MailingCountry):con.MailingCountry;          
        }else{
            ContactCountry = '';          
        }
        Fax = (con.Fax!=null)?con.Fax:'';
        Salutation = (con.Salutation!=null)?con.Salutation:'';
        Suffix = (con.Suffix!=null)?con.Suffix:'';
        MiddleName = (con.MiddleName!=null)?con.MiddleName:'';
        Phone = (con.Phone!=null)?con.Phone:'';
        Mobile = (con.MobilePhone!=null)?con.MobilePhone:'';        
        Email = (con.Email!=null)?con.Email:'';
        //web_access_flag = con.COR2_Portal_Contact__c?'T' :'F';
        if(con.Blocked__c == False)
            ContactCustomerStatus = 'A';
        else
            ContactCustomerStatus = 'I'; 
        EmailFlag = 'T';
        WebAccessFlag = con.COR2_Portal_Contact__c?'T' :'F';
        if(event == 'Update')
            name = con.name;
    }
}