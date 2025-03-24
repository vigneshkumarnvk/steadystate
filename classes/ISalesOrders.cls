public interface ISalesOrders extends fflib_ISObjectDomain{
    void updateConvertCountAndQuoteStatus(fflib_ISObjectUnitOfWork uow);
    void initStaticVariables(); //W-000405
    //void checkBeforeClone(Id targetCustId); //W-000405
    void checkBeforeClone(Id targetCustId, String targetDocType); //W-000405
    void checkBeforeConvert(); //W-00405
}