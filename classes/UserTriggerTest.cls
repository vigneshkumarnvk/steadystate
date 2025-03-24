@isTest
private class UserTriggerTest {
    private static testMethod void test() {
        List<UserRole> rs = new List<UserRole>();
        rs.add(new UserRole(Name = 'AE', DeveloperName = 'AE'));
        rs.add(new UserRole(Name = 'SP', DeveloperName = 'SP'));
        rs.add(new UserROle(Name = 'RU', DeveloperName = 'RU'));
        insert rs;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        
        List<User> us = new List<User>();
        us.add(new User(Alias = 'ae', Email='ae@republicservices.com', EmailEncodingKey='UTF-8', LastName='AE', FirstName = 'AE', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='ae@acvtestorg.com', UserRoleId = rs[0].Id));
        us.add(new User(Alias = 'sp', Email='sp@republicservices.com', EmailEncodingKey='UTF-8', LastName='SP', FirstName = 'SP', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='sp@acvtestorg.com', UserRoleId = rs[1].Id));
        us.add(new User(Alias = 'ru', Email='ru@republicservices.com', EmailEncodingKey='UTF-8', LastName='RU', FirstName = 'RU', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='ru@acvtestorg.com', UserRoleId = rs[2].Id));
        insert us;
        
        us[1].UserRoleId = rs[1].Id;
        update us[1];
        //test
    }
}