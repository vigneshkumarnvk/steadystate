public virtual class PaginationBase {
    public ApexPages.StandardSetController stdCon;   
    private String strQuery;
    public Integer PageSize;
    public String orderBy;
    public String orderBy_old;
    public String order;
    public String scName;
    
    public PaginationBase() {
        //Get Pagination Size
        Decimal pgSize = [SELECT No_of_Records__c FROM Company_Setup__c LIMIT 1].No_of_Records__c;
        PageSize = pgSize==null ? 10 : Integer.valueOf(pgSize);  
        if(String.isBlank(strQuery)) {
            setQuery('SELECT Id FROM Account LIMIT 1');
        }
        orderBy = 'Name';
        orderBy_old = orderBy;
        order = 'ASC';
    }
    
    public void setQuery(String sQry) {
        strQuery = sQry;
    }
    
    Public void fetchStdSetRecords() {         
        stdCon = new ApexPages.StandardSetController(Database.getQueryLocator(strQuery));                
        stdCon.setPageSize(pageSize);
    }
    
    
    // indicates whether there are more records after the current page set.
    public Boolean hasNext {
        get {
            return stdCon.getHasNext();
        } set;
    }
    
    // indicates whether there are more records before the current page set.
    public Boolean hasPrevious {
        get {
            return stdCon.getHasPrevious();
        } set;
    }
    
    // returns the page number of the current page set
    public Integer pageNumber {
        get {
            return stdCon.getPageNumber();
        } set;
    }
    
    // returns the first page of records
    public void first() {
        stdCon.first();
    }
    
    // returns the last page of records
    public void last() {
        stdCon.last();
    }
    
    // returns the previous page of records
    public void previous() {
        stdCon.previous();
    }
    
    // returns the next page of records
    public void next() {
        stdCon.next();
    }
    
    Public String paginationStat {
        get{
            Integer pageRangeStart = ((stdCon.getPageNumber()-1)*pagesize)+1;
            Integer pageRangeEnd = stdCon.getPageNumber()*pagesize;
            if(pageRangeEnd > stdCon.getResultSize()) {
                pageRangeEnd = stdCon.getResultSize();
            }
            return 'Showing  ' + pageRangeStart + '  to  ' + 
                pageRangeEnd + '  of  ' + stdCon.getResultSize() ;
        }
    }
    
    Public Boolean hasRecords{
        get{
            if(stdCon==null) return false;
            return stdCon.getResultSize()>0;
        }
    }
    
    public String sortBy{
        get{ return orderBy;}
    }
    
    public String sortDirection{
        get{ return order;}
    }
}