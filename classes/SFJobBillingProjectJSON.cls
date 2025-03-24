/*
* Class Name: SFJobBillingProjectJSON
* Summary  : Details format send to EQAI

* Modification Log :
* Developer                 Date                   Description
--------------------------------------------------------------------------------------------------------------               
Sanjana Ravichandran           15/04/2024         76997: new billing project within EQAI from Salesforce "Job Billing Project"
Sanjana Ravichandran		   26/04/2024		  Update the JSON based on new mapping sheet
Sanjana Ravichandran 		   05-15-2024 		  Added Invoice Backup Document field in the JSON
Vennila Paramasivam			05/20/2024				 Task 88134: Added 'SF Job Level - ' infront of sales order name.
Sathish Rosekumar			05/21/2024			  Made the default value as '99' if territory code for account executive is null
Vennila Paramasivam			05/24/2024			  Added Role.
Pavithra Periyasamy			02/24/2025           US142143: Salesforce : Replace PO_Number_Type__c with PO_Required__c Field
*************************************************************************************************************/
public class SFJobBillingProjectJSON {
    Public String  D365CustomerId;
    Public DateTime  DateAdded;
    Public DateTime  DateModified;
    Public String EmployeeId;
    Public String SalesforceJobBillingProjectCsid;
    Public DateTime SalesforceSalesOrderCloseDate;
    Public String ReopenFlag;
    Public String contact_ID;
    Public String MailToBillToAddressFlag;
    Public String TermsCode;
    Public String ProjectName;
    Public String InvoiceComment1;
    Public String InvoiceComment2;
    Public String InvoiceComment3;
    Public String InvoiceComment4;
    Public String InvoiceComment5;
    Public String added_by;
    Public String modified_by;
    Public String InvoicePackageContent;
    Public String PORequiredFlag;
    Public String DistributionMethod;
    Public String EManifestFeeOption;
    Public String AllFacilitiesFlag;
    Public String PrintWosWithStartDateFlag;
    Public String InsuranceSurchargeFlag;
    Public Integer RegionId;
    Public String CustBillXContDistributionMethod;
    Public String CustBillXContInvoicePackageContent;
    Public String CustomerBillingTerritoryStatus;
    Public String CustomerBillingTerritoryType;
    Public Integer BusinessSegmentUid1;
    Public Integer BusinessSegmentUid2;
    Public String CustomerBillingTerritoryCode;
    Public String CusBilXContactEmail;
    //Public String CusBilXContactName;
    Public String RsgEin;
    Public String InvoiceFlag;
    Public String EManifestFlag;
    Public String RecordType;
    Public String SalesforceInvoiceCSID;
    Public String InvoiceBackupDocument;
    Public String BreakCode1;
    Public String BreakCode2;
    Public String BreakCode3;
    Public String EbillingFlag;
    Public Integer CompanyId;
    Public Integer ProfitCenterId;
    Public String Role;
    Public String SalesforceSoQuoteId;
    
    
    public SFJobBillingProjectJSON(Sales_order__c salesOrderRec, String employeeId, Boolean isReOpen,String salesInvoiceCSID, map<String,String>  company_Id_EQIMap, map<String,String> profit_Ctr_Id_EQIMap){
        this.SalesforceInvoiceCSID = salesInvoiceCSID;
        this.D365CustomerId= (salesOrderRec.Bill_to_Customer_No__c!=null && salesOrderRec.Bill_to_Customer_No__r.Sage_Customer_No__c!=null)? salesOrderRec.Bill_to_Customer_No__r.Sage_Customer_No__c:null;
                 
        this.DateAdded = salesOrderRec.CreatedDate;
        this.DateModified = salesOrderRec.LastModifiedDate;
        this.EmployeeId = employeeId;
        this.SalesforceJobBillingProjectCsid = salesOrderRec.CSID__c;
        this.ReopenFlag = isReOpen?'T': salesOrderRec.Document_Status__c == 'Closed' ? 'F':null;
        this.SalesforceSalesOrderCloseDate = this.ReopenFlag == 'F'?salesOrderRec.Close_Date__c:null;
        this.contact_ID = salesOrderRec.Bill_to_Contact__r.Name +'-'+ salesOrderRec.Bill_to_Contact__r.Email ;
        if(salesOrderRec.Bill_to_Customer_No__c!=null && salesOrderRec.Bill_to_Customer_No__r.Invoice_Submission_Channels__c!=null){
            if(salesOrderRec.Bill_to_Customer_No__r.Invoice_Submission_Channels__c == 'EMAIL'){
                this.MailToBillToAddressFlag ='F';
            }
            else 
                if(salesOrderRec.Bill_to_Customer_No__r.Invoice_Submission_Channels__c=='HARD_COPY_SUBMITTAL'){
                    this.MailToBillToAddressFlag ='T';
                }
            else
                if(salesOrderRec.Bill_to_Customer_No__r.Invoice_Submission_Channels__c=='INVOICE_PORTAL'){
                    this.MailToBillToAddressFlag = null;
                }
        }
        if(salesOrderRec.Service_Center__c != null && salesOrderRec.Service_Center__r.Name != null && company_Id_EQIMap !=null && company_Id_EQIMap.containskey(salesOrderRec.Service_Center__r.Name)) CompanyId = Integer.valueOf(company_Id_EQIMap.get(salesOrderRec.Service_Center__r.Name));
        if(salesOrderRec.Service_Center__c != null && salesOrderRec.Service_Center__r.Name != null && profit_Ctr_Id_EQIMap !=null && profit_Ctr_Id_EQIMap.containskey(salesOrderRec.Service_Center__r.Name)) ProfitCenterId = Integer.valueOf(profit_Ctr_Id_EQIMap.get(salesOrderRec.Service_Center__r.Name));
        
        this.TermsCode=(salesOrderRec.Payment_Term__c!=null && salesOrderRec.Payment_Term__r.EQAI_Terms_Code__c != null)?salesOrderRec.Payment_Term__r.EQAI_Terms_Code__c:null;
        if(
            salesOrderRec.Bill_to_Customer_No__c!=null &&
            salesOrderRec.Bill_to_Customer_No__r.Payment_Term__c != null
            && salesOrderRec.Bill_to_Customer_No__r.Payment_Term__r.EQAI_Terms_Code__c != null && 
            salesOrderRec.Payment_Term__c!=null && 
            salesOrderRec.Payment_Term__r.EQAI_Terms_Code__c != null
        ){
            if(salesOrderRec.Bill_to_Customer_No__r.Payment_Term__r.EQAI_Terms_Code__c != salesOrderRec.Payment_Term__r.EQAI_Terms_Code__c){
                this.TermsCode = salesOrderRec.Payment_Term__r.EQAI_Terms_Code__c;
            }else{
                this.TermsCode = null;
            }
        }else{
            this.TermsCode = null;
        }
        
        this.ProjectName = salesOrderRec.Name != null? 'SF Job Level - '+salesOrderRec.Name:null;
        if (salesOrderRec.Internal_Comments__c != null) {
            List<String> commentSegments = splitComments(salesOrderRec.Internal_Comments__c);
            for (Integer i = 0; i < Math.min(commentSegments.size(), 5); i++) {
                String fieldName = 'InvoiceComment' + (i + 1);
                if (i == 0) {
                    this.InvoiceComment1 = commentSegments[i];
                } else if (i == 1) {
                    this.InvoiceComment2 = commentSegments[i];
                } else if (i == 2) {
                    this.InvoiceComment3 = commentSegments[i];
                } else if (i == 3) {
                    this.InvoiceComment4 = commentSegments[i];
                } else if (i == 4) {
                    this.InvoiceComment5 = commentSegments[i];
                }
            }
        }
        this.modified_by =salesOrderRec.LastModifiedBy.Name;
        this.added_by = salesOrderRec.CreatedBy.Name;
        this.CustomerBillingTerritoryCode = salesOrderRec.Account_Executives__c != null?
            salesOrderRec.Account_Executives__r.Territory_Code__c != null?salesOrderRec.Account_Executives__r.Territory_Code__c:'99':null;
        
        this.RsgEin = (salesOrderRec.Account_Executives__c != null && salesOrderRec.Account_Executives__r.Internal_Contact__c)
            ?salesOrderRec.Account_Executives__r.RSG_EIN__c
            : null; 
        
        //this.CusBilXContactName = salesOrderRec.Bill_to_Contact__r.Name;
        this.CusBilXContactEmail = salesOrderRec.Bill_to_Contact__r.Email;
        this.InvoicePackageContent = 'C';
        this.DistributionMethod = 'M';
        this.EManifestFeeOption = 'C';
        this.AllFacilitiesFlag = 'T';
        this.PrintWosWithStartDateFlag = 'T';
        this.InsuranceSurchargeFlag = 'T';
        this.RegionId = 2;
        //88092
        this.CustBillXContDistributionMethod = 'A';
        //88092
        this.CustBillXContInvoicePackageContent ='C';
        this.CustomerBillingTerritoryStatus = 'A';
        this.CustomerBillingTerritoryType = 'T';
        this.BusinessSegmentUid1 = 1;
        this.BusinessSegmentUid2 = 2;
        this.InvoiceFlag ='S';
        this.RecordType = 'B';
        this.EManifestFlag = 'T'; 
        this.InvoiceBackupDocument = salesOrderRec.Bill_to_Customer_No__r.Invoice_Backup_Documents__c;
       // this.InvoiceBackupDocument = 'Invoice';        
        if(salesOrderRec.Bill_to_Customer_No__r!=null && (salesOrderRec.Bill_to_Customer_No__r.PO_Number_Type__c!=null || salesOrderRec.Bill_to_Customer_No__r.PO_Required__c)){
            //if(salesOrderRec.Bill_to_Customer_No__r.PO_Number_Type__c == 'ALPHANUMERICAL' ||salesOrderRec.Bill_to_Customer_No__r.PO_Number_Type__c=='NUMERICAL' || salesOrderRec.Bill_to_Customer_No__r.PO_Number_Type__c=='NAME_OF_CONTACT'){
                this.PORequiredFlag ='T'; 
                this.BreakCode1 = 'B';
                this.BreakCode2 = 'P';
                this.BreakCode3 = 'I';
            //}
        }else{
            	this.PORequiredFlag ='F';
                this.BreakCode1 = 'B';
                this.BreakCode2 = 'I';
                this.BreakCode3 = 'N';  
            }
        this.EbillingFlag = (salesOrderRec.Bill_to_Customer_No__c!=null && salesOrderRec.Bill_to_Customer_No__r.Invoice_Portal__c!=null)? 'T':'F';
 		this.SalesforceSoQuoteId = salesOrderRec.Name;
        //88158
        this.Role = (salesOrderRec.Bill_to_Contact__c != null)?salesOrderRec.Bill_to_Contact__r.Title:null; 
   
    }
    
    private static List<String> splitComments(String comments) {
        List<String> segments = new List<String>();
        while (comments.length() > 80) {
            segments.add(comments.substring(0, 80));
            comments = comments.substring(80);
        }
        segments.add(comments);
        return segments;
    }
}