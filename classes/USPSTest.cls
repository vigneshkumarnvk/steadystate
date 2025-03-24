public with sharing class USPSTest {

    // When this is set, it will trigger the lookup on the address to the USPS
    public string USPSUserIDCode {get; set;}

    public final Account CurrentAccount {get; set;}
    
    public USPSTest(ApexPages.StandardController stdController) {
        
        USPSUserIDCode = '';
        this.CurrentAccount = (Account)stdController.getRecord();
        
        //CurrentAccount.BillingStreet = '6406 Ivy Lane';
        //CurrentAccount.BillingCity = 'Greenbelt';
        //CurrentAccount.BillingStateCode = 'MD';
        //CurrentAccount.BillingPostalCode = '20770';       
        
    } // constructor
    
    public pagereference validate() {
        
        // if the address validation hasn't been triggered, trigger it here
        if (USPSUserIDCode == '') {

            // Confirm you have an address before setting the code
            // without an address, the component won't actually do anything
            if (CurrentAccount.BillingStreet != '' && CurrentAccount.BillingStreet != null) {               
                if ((CurrentAccount.BillingPostalCode != '') || ((CurrentAccount.BillingCity != '') && (CurrentAccount.BillingState != '')))  {
                    
                    USPSUserIDCode  = ''; //'<<<<<< INSERT YOUR ID HERE >>>>>>';
                    
                    return null;            
                } // have city and state OR Zip
                                
            } // Address1 != ''
            
        } // USPSUserIDCode == ''

        // Add any other form validation or save code here
        return null;
                        
    } // validate
    
} // end class USPSTest