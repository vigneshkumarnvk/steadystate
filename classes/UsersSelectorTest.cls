@IsTest
private class UsersSelectorTest {

    @IsTest
    private static void test(){
        UsersSelector.newInstance().selectById(new Set<Id>{UserInfo.getUserId()});
    }
}