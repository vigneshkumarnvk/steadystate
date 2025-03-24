public interface ITMs extends fflib_ISObjectDomain{
    void updateCustomerPONumber(Map<Id, String> poToUpdateBySOIds, fflib_ISObjectUnitOfWork uow);
}