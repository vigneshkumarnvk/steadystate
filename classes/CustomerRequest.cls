/*************************************************************************************************
* Name         :  CustomerRequest
* Description  :  
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Sanjana Ravichandran     02-07-2025             US140550: Salesforce: Create New Customer in SF from EQAI
***********************************************************************************************************/
public class CustomerRequest {

    public class CustomerInfo {
        public String customer_ID;
        public String cust_name;
        public String cust_addr1;
        public String cust_city;
        public String cust_state;
        public String cust_zip_code;
        public String cust_country;
        public String cust_phone;
        public String cust_fax;
        public String terms_code;
        public String web_access_flag;
        public String cust_website;
        public String eq_flag;
        public String cust_naics_code;
        public String bill_to_addr1;
        public String bill_to_city;
        public String bill_to_state;
        public String bill_to_zip_code;
        public String bill_to_country;
        public Decimal credit_limit;
        public String national_account_flag;
        public String ax_customer_id;
        public String msg_customer_flag;
        public String retail_customer_flag;
        public String d365_customer_classification_group;
        public String Salesforce_Account_CSID;
        public String sfdc_billing_package_flag;
        public String PO_required_flag;
        public String territory_code;
        public String cust_status;
    }
}