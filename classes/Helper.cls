public with sharing class Helper {

    public static void EmailGroupUsers(String publicGroup, String subject, String message) {
        List<String> addrs = GetEmailAddresses(publicGroup);
        if (addrs.size() > 0) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(addrs);
            mail.setSubject(subject);
            mail.setPlainTextBody(message);
            Messaging.sendEmail(new Messaging.SingleEmailMEssage[] { mail });
        }        
    }
    
    public static List<String> GetEmailAddresses(String groupName) {
        List<String> addrs = new List<String>();
        List<Id> userIds = new List<Id>();
        String userType = Schema.SObjectType.User.getKeyPrefix();
        List<Group> gs = [SELECT (SELECT userOrGroupId from GroupMembers) FROM Group WHERE Name = :groupName];
        if (gs.size() > 0) {
            for (GroupMember gm : gs[0].GroupMembers) {
                if (((String)gm.userOrGroupId).startsWith(userType)) {
                    userIds.add(gm.userOrGroupId);
                }
            }
            
            User[] users = [SELECT Email FROM User WHERE Id IN :userIds];
            for (User u : users) {
                addrs.add(u.Email);
            }
        }
        return addrs;
    }
}