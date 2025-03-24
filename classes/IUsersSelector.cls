public interface IUsersSelector extends fflib_ISObjectSelector{
    List<User> selectById(Set<Id> idSet);
}