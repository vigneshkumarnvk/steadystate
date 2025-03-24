/*************************************************************************************************
* Name         :  ContactRequest
* Description  :  
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Shahwaz Khan             05-07-2024             US116369:Create Contacts Triggered from EQAI to Salesforce
* Shahwaz Khan             05-07-2024             US116368:Edit Existing Contacts Triggered from EQAI to Salesforce
* Andrew Simons            09-23-2024             US125732:add middle name, fax, salutation, suffix
* Shahwaz Khan             16/12/2024             Salesforce - Incl. web_access_flag field in contact sync integration (SF -> EQAI)
***********************************************************************************************************/
public class ContactRequest {
    public List<ContactInfo> contacts;
    public class ContactInfo {
        public String contact_company; // Optional
        public String customer_id;// Optional
        public String ax_customer_id;
        public String SF_Contact_CSID;
        public String contact_customer_role;
        public String first_name;
        public String last_name;
        public String title;
        public String contact_addr1;
        public String contact_city;
        public String contact_state;
        public String contact_zip_code;
        public String contact_country;
        public String phone;
        public String mobile;
        public String email;
        public String contact_status;
        public Integer contact_ID;
        public String added_by;
        public String modified_by;
        public datetime modified_date; // Optional
        public datetime added_date; // Optional
        public String middle_name;
        public String fax;
        public String salutation;
        public String suffix;
        //Public String web_access_flag;
        Public String WebAccessFlag;
    }
}