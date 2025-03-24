/**
 * Created by Kevin on 2/27/2020.
 */

public with sharing class UserServiceCenterController {
    public static Boolean SkipTrigger { set; get; }

    @AuraEnabled
    public static User getUser(Id userId) {
        try {
            List<User> users = [SELECT Id, Name FROM User WHERE Id = :userId];
            if (users.size() > 0) {
                return users[0];
            }
            else {
                throw new DataException('Invalid user id: ' + userId + '.');
            }
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String getUserServiceCenters(Id userId) {
        try {
            List<User_Service_Center__c> userServiceCenters = [SELECT Id, Name, User__c, User__r.Name, Service_Center__c, Service_Center__r.Name, Default__c, Manager_of_SC__c FROM User_Service_Center__c WHERE User__c = :userId ORDER BY Service_Center__r.Name];
            return JSON.serialize(userServiceCenters);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String addAllServiceCenters(String JSONUser, String JSONUserServiceCenters) {
        try {
            User user = (User)JSON.deserialize(JSONUser, User.class);
            List<User_Service_Center__c> userServiceCenters = (List<User_Service_Center__c>)JSON.deserialize(JSONUserServiceCenters, List<User_Service_Center__c>.class);

            Map<String, User_Service_Center__c> mapUserServiceCentersByName = new Map<String, User_Service_Center__c>();
            for (User_Service_Center__c userServiceCenter : userServiceCenters) {
                mapUserServiceCentersByName.put(userServiceCenter.Service_Center__r.Name, userServiceCenter);
            }

            List<Service_Center__c> serviceCenters = [SELECT Id, Name FROM Service_Center__c ORDER BY Name];
            for (Service_Center__c serviceCenter : serviceCenters) {
                if (!mapUserServiceCentersByName.containsKey(serviceCenter.Name)) {
                    userServiceCenters.add(new User_Service_Center__c(Name = serviceCenter.Name, Service_Center__c = serviceCenter.Id, Service_Center__r = serviceCenter, User__c = user.Id, User__r = user, Manager_of_SC__c = false));
                }
            }
            return JSON.serialize(userServiceCenters);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void deleteUserServiceCenter(Id userServiceCenterId) {
        try {
            delete [SELECT Id FROM User_Service_Center__c WHERE Id = :userServiceCenterId];
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String saveUserServiceCenters(Id userId, String JSONUserServiceCenters) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<User_Service_Center__c> userServiceCenters = (List<User_Service_Center__c>)JSON.deserialize(JSONUserServiceCenters, List<User_Service_Center__c>.class);

            Set<Id> uscIds = new Set<Id>();
            for (User_Service_Center__c userServiceCenter : [SELECT Id FROM User_Service_Center__c WHERE User__c = :userId]) {
                uscIds.add(userServiceCenter.Id);
            }

            for (User_Service_Center__c userServiceCenter : userServiceCenters) {
                if (userServiceCenter.Id != null) {
                    if (uscIds.contains(userServiceCenter.Id)) {
                        uscIds.remove(userServiceCenter.Id);
                    }
                }
            }

            if (uscIds.size() > 0) {
                delete [SELECT Id FROM User_Service_Center__c WHERE User__c = :userId AND Id IN :uscIds];
            }

            upsert userServiceCenters;

            return getUserServiceCenters(userId);
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage());
        }
    }
}