Public Class TMWrapperPagination {

    //List to store all the TMController.TMWrapper according to requirement
    public List<TMController.TMWrapper> RecordList = new list<TMController.TMWrapper>();
    //List to show the limited records on the page
    public List<TMController.TMWrapper> WrapperListToShow = new List<TMController.TMWrapper>();

    //Navigation variables
    public Integer counter = 0;   //TO track the number of records parsed
    public Integer limitSize = 25;     //Number of records to be displayed
    public Integer totalSize = 0;  //To Store the total number of records available
    public Integer currStartIndex = 0;  //To Store the current Start Index
    public Integer currEndIndex = 0;  //To Store the current End Index      

    //Initialization
    public TMWrapperPagination(List<TMController.TMWrapper> Records, Integer PageSize) {

        WrapperListToShow = new list<TMController.TMWrapper>();

        //Initialize Pagization Size
        limitSize = 25;
        //Initialize Pagization Counter
        counter = 0;
        //Initialize Pagization List
        RecordList = Records;
        //Store the total size
        totalSize = RecordList.size();

        System.debug('totalSize==>' + totalSize);
        System.debug('limitSize==>' + limitSize);
        System.debug('counter==>' + counter);

        //Intial adding of Soject to WrapperListToShow
        //check the total records are more than limitSize and assign the records
        if ((counter + limitSize) <= totalSize) {

            for (Integer i = 0; i < limitSize; i++) WrapperListToShow.add(RecordList.get(i));

        } else {

            for (Integer i = 0; i < totalSize; i++) WrapperListToShow.add(RecordList.get(i));

        }
    }

    //Navigation methods
    public List<TMController.TMWrapper> beginning() {

        WrapperListToShow.clear();
        counter = 0;
        currStartIndex=0;
        if ((counter + limitSize) <= totalSize) {

            for (Integer i = 0; i < limitSize; i++) WrapperListToShow.add(RecordList.get(i));
            currEndIndex=limitSize;
        } else {

            for (Integer i = 0; i < totalSize; i++) WrapperListToShow.add(RecordList.get(i));           
            currEndIndex=totalSize;
        }
        return WrapperListToShow;
    }

    public List<TMController.TMWrapper> next() {

        WrapperListToShow.clear();
        counter = counter + limitSize;
        currStartIndex=counter+1;  
              
        System.debug('counter==>' + counter);
        if ((counter + limitSize) <= totalSize) {
        
            currEndIndex=counter + limitSize;  
            for (Integer i = counter; i < (counter + limitSize); i++) WrapperListToShow.add(RecordList.get(i));          

        } else {
        
            currEndIndex=totalSize; 
            for (Integer i = counter; i < totalSize; i++) WrapperListToShow.add(RecordList.get(i));           

        }
        return WrapperListToShow;
    }

    public List<TMController.TMWrapper> previous() {

        WrapperListToShow.clear();

        counter = counter - limitSize;
        
        currStartIndex=counter; 
        currEndIndex=counter + limitSize; 
                
        for (Integer i = counter; i < (counter + limitSize); i++) WrapperListToShow.add(RecordList.get(i));

        return WrapperListToShow;
    }

    public List<TMController.TMWrapper> last() {

        WrapperListToShow.clear();

        System.debug('Start counter==>' + counter);
        System.debug('end counter==>' + totalSize);

        if (math.mod(totalSize, limitSize) == 0) counter = limitSize * ((totalSize / limitSize) - 1);

        else if (math.mod(totalSize, limitSize) != 0) counter = limitSize * ((totalSize / limitSize));

        System.debug('Start counter==>' + counter);
        System.debug('end counter==>' + totalSize);
        
        currStartIndex=counter; 
        currEndIndex=totalSize ;         

        for (Integer i = counter - 1; i < totalSize - 1; i++) WrapperListToShow.add(RecordList.get(i));

        return WrapperListToShow;
    }

    public Boolean getDisableNext() {

        if ((counter + limitSize) >= totalSize)
            return true ; else
                return false ;
    }

    public Boolean getDisablePrevious() {

        if (counter == 0)
            return true ; else
                return false ;
    }

    public Integer pageNumber() {

        return (counter / limitSize) + 1;

    }

    public List<TMController.TMWrapper> getAll() {

        WrapperListToShow.clear();

        WrapperListToShow.addAll(RecordList);

        return WrapperListToShow;
    }

    public List<TMController.TMWrapper> getpage(Integer PageNum) {

        WrapperListToShow.clear();
        Integer StartIndex = (PageNum - 1) * limitSize;
        Integer EndIndex;

        if (StartIndex + limitSize > totalSize) EndIndex = totalSize; else EndIndex = StartIndex + limitSize;

        for (Integer i = StartIndex; i < EndIndex; i++) WrapperListToShow.add(RecordList.get(i));

        return WrapperListToShow;
    }
    
    public Integer getStartIndex() {
    
        Return currStartIndex;
    
    }
    
    public Integer getEndIndex() {
    
        Return currEndIndex;
    
    }    

}