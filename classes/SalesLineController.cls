public with sharing class SalesLineController {
    /*
    private final ApexPages.StandardController theController;
	private String orderId;
    private String salesLineId;
    private Sales_Line__c theSL;
    public SalesLineController(ApexPages.StandardController controller) {
        theController = controller;
        salesLineId = ApexPages.CurrentPage().getParameters().get('id');
        selectSL();
        orderId = theSL.Sales_Order__c;
    }
    
    private void selectSL() {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Sales_Line__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Sales_Line__c WHERE Id =: salesLineId';
        theSL = Database.query(strQuery);
    }

    public PageReference cancel() {
        return theController.cancel();

    }
    
    public PageReference returnToSO() {
        PageReference SO = new PageReference('/' + orderId);
        SO.setRedirect(true);
        return SO;
    }
    */
}