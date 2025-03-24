/*
* Class Name: ContractBillingProjectJSON
* Summary  : Details format send to EQAI

* Modification Log :
* Developer                 Date                   Description
--------------------------------------------------------------------------------------------------------------               
Sathish Rosekumar           14/02/2024              75101 - Send Contract Details to EQAI
Shahwaz Khan                21/02/2024              Bug#78506 Billing project - Payment term value is missing in JSON which needs to send to EQAI from SF
Sanjana 					05/04/2024              Requirement 80445: Salesforce - Update "SF Contract Billing Project" JSON
Sanjana						04/23/2024				Requirement 85160: Salesforce - Contract Level Billing Projects - PO Required Field - Pull from Salesforce Account
Sanjana						04/26/2024			    Requirement 84934: Salesforce - Update Contract Billing Project Data Mapping & JSON
*************************************************************************************************************/
public class ContractBillingProjectJSON {
    Public String D365CustomerId;
    Public String MailToBillToAddressFlag;
    Public Integer RegionId;
    Public String TermsCode;
    Public DateTime DateAdded;
    Public DateTime DateModified;
    Public String SalesforceContractNumber;
    Public String ProjectName;
    Public String EmployeeId;
    Public String PORequiredFlag;
    Public String AddedBy;
    Public String ModifiedBy;
    Public String CustomerBillingTerritoryCode;
    Public String InvoiceComment1;
    Public String InvoiceComment2;
    Public String InvoiceComment3;
    Public String InvoiceComment4;
    Public String InvoiceComment5;
    Public String RsgEin;
    Public String BreakCode1;
    Public String BreakCode2;
    Public String BreakCode3;
    Public Integer EmanifestFee;
    Public String InvoiceCopyFlag;
    Public String CusbilxcontactEmail;
    Public String CusbilxcontactName;
    Public String EbillingFlag;
    
    
    
    public ContractBillingProjectJSON(Contract contractRecord, String employeeId,Contact billToContact) {
        // this.D365CustomerId = 'C300439';
        this.D365CustomerId= (contractRecord.Account!=null && contractRecord.Account.Sage_Customer_No__c!=null)? contractRecord.Account.Sage_Customer_No__c:null;
        if(contractRecord.Account!=null && contractRecord.Account.Invoice_Submission_Channels__c!=null){
            if(contractRecord.Account.Invoice_Submission_Channels__c == 'EMAIL'){
                this.MailToBillToAddressFlag ='F';
            }
            else 
                if(contractRecord.Account.Invoice_Submission_Channels__c=='HARD_COPY_SUBMITTAL'){
                    this.MailToBillToAddressFlag ='T';
                }
            else
                if(contractRecord.Account.Invoice_Submission_Channels__c=='INVOICE_PORTAL'){
                    this.MailToBillToAddressFlag = null;
                }
        }
        this.RegionId = 2;
        //Bug#78506
        this.TermsCode=(contractRecord.Payment_Term__c!=null && contractRecord.Payment_Term__r.EQAI_Terms_Code__c != null)?contractRecord.Payment_Term__r.EQAI_Terms_Code__c:null;
        this.DateAdded = contractRecord.CreatedDate;
        this.DateModified = contractRecord.LastModifiedDate;
        this.SalesforceContractNumber = contractRecord.ContractNumber != null? contractRecord.ContractNumber:null;
        this.ProjectName = contractRecord.Name != null? contractRecord.Name:null;
        this.EmployeeId = employeeId;
        if(contractRecord.Account!=null && contractRecord.Account.PO_Number_Type__c!=null){
            if(contractRecord.Account.PO_Number_Type__c == 'ALPHANUMERICAL' ||contractRecord.Account.PO_Number_Type__c=='NUMERICAL' || contractRecord.Account.PO_Number_Type__c=='NAME_OF_CONTACT'){
                this.PORequiredFlag ='T'; 
                this.BreakCode1 = 'B';
        		this.BreakCode2 = 'P';
        		this.BreakCode3 = 'I';
            }else if(contractRecord.Account.PO_Number_Type__c == 'None'){
              this.BreakCode1 = 'B';
        		this.BreakCode2 = 'I';
        		this.BreakCode3 = 'N';  
            }
        }
        
        if (contractRecord.Internal_Comments__c != null) {
            List<String> commentSegments = splitComments(contractRecord.Internal_Comments__c);
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
        this.CusbilxcontactName = billToContact.Name; 
        this.CusbilxcontactEmail = billToContact.Email;
        this.CustomerBillingTerritoryCode = (contractRecord.Account.Account_Executive__c != null && 
                                                contractRecord.Account.Account_Executive__r.Territory_Code__c != null)
            ? contractRecord.Account.Account_Executive__r.Territory_Code__c
            : null;
        this.ModifiedBy =contractRecord.LastModifiedBy.Name;
        this.AddedBy = contractRecord.CreatedBy.Name;
        this.RsgEin = (contractRecord.Account != null && contractRecord.Account.Account_Executive__r != null && contractRecord.Account.Account_Executive__r.Internal_Contact__c)
            ?contractRecord.Account.Account_Executive__r.RSG_EIN__c
            : null; 
        this.EmanifestFee = null;
        this.InvoiceCopyFlag = 'T';
        this.EbillingFlag = (contractRecord.Account != null && contractRecord.Account.Invoice_Portal__c != null) ? 'T':'F';
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