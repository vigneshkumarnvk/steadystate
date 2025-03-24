public with sharing class USPSAddressValidator {
    public String USPS_USERID { set; get; }
    public USPSAddress Address2Check { set; get; }
    public USPSAddress SuggestedAddress { set; get; }
    
    public void ValidateAddress() {
        if (this.Address2Check.CanCheckAddress() == true) {
            this.SuggestedAddress = USPS.CheckAddress(this.Address2check, USPS_USERID);
        }
    }


}