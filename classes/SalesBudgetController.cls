public with sharing class SalesBudgetController {
    public Blob data { get; set; }
    public List<ImportError> ErrorList { set; get; }
    public List<ImportError> InvalidCustomerList { set; get; }
    public String Year { set; get; }
    public List<SelectOption> YearList { set; get; }
    public Boolean IgnoreBadCustomers { set; get; }
    

    public SalesBudgetController(ApexPages.StandardSetController sc) {
        this.ErrorList = new List<ImportError>();        
        this.InvalidCustomerList = new List<ImportError>();    
        this.Year = String.valueOf(System.today().year());
        this.IgnoreBadCustomers = false;
        this.YearList = new List<SelectOption>();
        for (Integer i = 2016; i < 2030; i++) {
            String year = String.valueOf(i);
            this.YearList.add(new SelectOption(year, year));
        }
    }
    
    public PageReference Import()
    {
        Savepoint sp = Database.setSavepoint();
        try{
            this.Import(BlobToString(data,'ISO-8859-1'));
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Budgets are imported successfully!'));
            return null;
        }
        catch(Exception e){
            Database.rollback(sp);
            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage());
            ApexPages.addMessage(errormsg);            
            return null;            
        }
    }  


    private void Import(String fileContent) {
        if (fileContent == null) {
            throw new DataException('Invalid file');
        }
        
        List<String> lines = fileContent.split('\r\n|\n'); 
        if (lines.size() <= 1) {
            throw new DataException('There is nothing to import.');
        }              

        String[] columnHeader = new String[] { 'Customer', 'Account Executive', 'Salesperson', 'Sales Budget 1', 'Sales Budget 2', 'Sales Budget 3', 'Sales Budget 4', 'Sales Budget 5', 'Sales Budget 6', 'Sales Budget 7', 'Sales Budget 8', 'Sales Budget 9', 'Sales Budget 10', 'Sales Budget 11', 'Sales Budget 12' };        
        String[] fileHeader = lines[0].split(',(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)', -1); 
        if (fileHeader.size() < columnHeader.size()) {
            throw new DataException('The file contains invalid data. Expected columns: ' + String.join(columnHeader, ', '));
        }
        for (Integer i = 0; i < columnHeader.size(); i++) {
            if (columnHeader[i] != fileHeader[i]) {
                throw new DataException('Unexpected column \'' + fileHeader[i] + '\'. Column  \'' + columnHeader[i] + '\' is expected.');                
            }
        }
        
        Map<String, Id> customers = new Map<String, Id>();
        for (Account acct : [SELECT Id, AccountNumber FROM Account WHERE Type = 'Customer']) {
            customers.put(acct.AccountNumber, acct.Id);
        }
        Integer selectedYear = Integer.valueOf(this.Year);                
        List<Sales_Budget__c> budgets = new List<Sales_Budget__c>();
        for (Integer i = 1; i < lines.size(); i++) {
            String[] column = lines[i].split(',(?=(?:[^\"]*\"[^\"]*\")*[^\"]*$)', -1); //handle comma in double quotes
            try
            {                
                String customerId;
                column[0] = column[0].replaceAll('^\"|\"$', ''); //remove leading and ending double quotes               
                if (customers.containsKey(column[0])) {
                    customerId = customers.get(column[0]);                
                    for (Integer j = 3; j < column.size(); j++) {
                        column[j] = column[j].replaceAll('^\"|\"$', '');
                        String amountText = column[j].replaceAll(',', '');   
                        if (String.isEmpty(amountText)) {
                            amountText = '0';
                        }
                        Decimal amount = Decimal.valueOf(amountText);
                        if (amount > 0) {
                            budgets.add(new Sales_Budget__c(Year__c = selectedYear, Period_No__c = String.valueOf(j - 3).leftPad(2, '0'), Customer__c = customerId, Amount__c = amount));
                        }
                    }
                }
                else {
                    if (this.IgnoreBadCustomers != true) {
                      throw new DataException('Invalid Customer: \'' + column[0] + '\'');
                    }
                    else {
                        this.InvalidCustomerList.add(new ImportError(i + 1, 'Invalid customer: ' + column[0] + '\''));
                        if (this.InvalidCustomerList.size() >= 1000) {
                            this.ErrorList.add(new ImportError(i +1, 'Not all invalid customers are displayed! Due to the system limitations, only first 1000 invalid customers are displayed.'));
                            break;
                        }
                    }
                }
            }
            catch(exception ex) {
                this.ErrorList.add(new ImportError(i + 1, ex.getMessage()));
                if (this.ErrorList.size() >= 300) {
                    break;
                }
            }
        }
        
        if (this.ErrorList.size() == 0) {
            if (budgets.size() > 0) {            
                Savepoint sp = Database.setSavepoint();
                try {
                    delete [SELECT Id FROM Sales_Budget__c WHERE Year__c = :selectedYear];
                    upsert budgets;
                }            
                catch(exception ex) {
                    Database.rollback(sp);
                    throw ex;
                }
            }
        }
        else {
            throw new DataException('Data Error!');
        }
    }
    
    public Integer ErrorCount {
        get {
            return this.ErrorList.Size();
        }
    }

    public Integer InvalidCustomerCount {
        get {
            return this.InvalidCustomerList.Size();
        }
    }
        
    private static String BlobToString(Blob data, String charSet){
        String hex = EncodingUtil.convertToHex(data);
        System.assertEquals(0, hex.length() & 1);
        final Integer bytesCount = hex.length() >> 1;
        String[] bytes = new String[bytesCount];
        for(Integer i = 0; i < bytesCount; ++i)
            bytes[i] =  hex.mid(i << 1, 2);
        if (bytes.size() > 0) {
            return EncodingUtil.urlDecode('%' + String.join(bytes, '%'), charSet);
        }
        return null;
    }
    
    private class ImportError {
        public Integer LineNumber { set; get; }
        public String ErrorMessage { set; get; }
        
        public ImportError(Integer line, String error) {
            this.LineNumber = line;
            this.ErrorMessage = error;
        }
    }
}