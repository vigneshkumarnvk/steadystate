/***********************************************************************************************************
* Name         :   rsgTriggerStrategy
* Description  :   This class will dynamically apply the appropriate object specfic trigger handler based on the configuration 
  information stored in the custom metadata otherwise fall back on the existing 
  different behaviors to the trigger execution based on the context in which the trigger is executed. 
  Here are the steps to implement the Strategy pattern in apex trigger framework :
  1. Leverage the existing interface - ITriggerHandler that has all the common behaviour for all the strategies. 
  2. Implement the ITriggerHandler interface in each of the Sobject handler.
  3. Use the rsgTrigger_Configuration_Setting__mdt custom metadata to configure the strategies for each object trigger handler.
     You can create a separate record for each trigger handler that you want to configure like 
     
Action	   rsgTrigger Configuration Setting Name	Object Name		Operation Type	Event Type	Trigger Handler Name	
Edit | Del	 	SalesOrder_BeforeUpdate				Sales_Order__c	update			before		SalesOrder_BeforeUpdateTriggerHandler
Edit | Del	 	SalesOrder_AfterUpdate				Sales_Order__c	update			after		SalesOrder_AfterUpdateTriggerHandler	
Edit | Del	 	SalesOrder_AfterInsert	 			Sales_Order__c	insert			after		SalesOrder_AfterInsertTriggerHandler 

* Modification Log:
* Developer                 Date                   Description
* ----------------------------------------------------------------------------------------------------------
* Harika Madapathi         07/22/2023             68128 - Tech Debt: Update Trigger Framework for SalesOrder object
***********************************************************************************************************/
public with sharing class rsgTriggerStrategy {
    private static Map<String, Set<Id>> handlerClassNameSobjectIds = new Map<String, Set<Id>>();
    public static void executeTriggerHandler(System.TriggerOperation triggerEvent){ 
        Type triggerType;  
        ITriggerHandler triggerHandler;   
        rsgTrigger_Configuration_Setting__mdt rsgTtriggerConfigurationSetting = getHandlerNameFromTriggerConfigurationSettings(
            getObjectName(trigger.isDelete ? trigger.old.getSObjectType() :trigger.new.getSObjectType()),
            //Eg. value for triggerEvent is 'AFTER_INSERT'
            getEventType(JSON.serialize(triggerEvent)),
            getOperationType(JSON.serialize(triggerEvent)));
        
        if(rsgTtriggerConfigurationSetting != null && String.isNotBlank(rsgTtriggerConfigurationSetting.Trigger_Handler_Name__c)) {
            triggerType = Type.forName(rsgTtriggerConfigurationSetting.Trigger_Handler_Name__c);
            triggerHandler = (ITriggerHandler)triggerType.newInstance();
            Boolean isRecursive = contextRecursiveLogic(rsgTtriggerConfigurationSetting.Trigger_Handler_Name__c, Trigger.newMap);
            if(!isRecursive) {
                System.debug('rsgTriggerStrategy mainEntry >> ' + rsgTtriggerConfigurationSetting.Trigger_Handler_Name__c);
                triggerHandler.mainEntry();
                if(Trigger.isAfter){
                    triggerHandler.updateObjects();
                }
            }else{
                System.debug('rsgTriggerStrategy inProgressEntry >> ' + rsgTtriggerConfigurationSetting.Trigger_Handler_Name__c);
                triggerHandler.inProgressEntry();
            }
        } 
    }
    
    public static rsgTrigger_Configuration_Setting__mdt getHandlerNameFromTriggerConfigurationSettings(String objectName, String operationType, String eventType) {   
        return [SELECT Trigger_Handler_Name__c FROM rsgTrigger_Configuration_Setting__mdt 
                WHERE Object_Name__c = : objectName 
                AND Operation_Type__c = : operationType
                AND Event_Type__c = : eventType  
                AND IsActive__c = : TRUE
                LIMIT 1
               ];
    } 
    
    private static String getObjectName(SObjectType triggerType) {
        return String.valueOf(triggerType).toLowercase();
    }
    
    private static String getOperationType(String triggerEvent) {
        return triggerEvent.replace('"','').substringBefore('_').toLowercase();
    }
    
    private static String getEventType(String triggerEvent) {
        return triggerEvent.replace('"','').substringAfter('_').toLowercase();
    }
    //Handles the exact static nature of trigger context
    private static Boolean contextRecursiveLogic(String className, Map<Id,Sobject> newMap){   
        /*
            NOTE: When a record is inserted, for any workflow rules that meets the criteria and cause a field update.
            Its observed that its causing an update of record. Therefore, it does not cause recursion of
            insert triggers. 
            
            Hence, newMap coming in as blank is fine as it ends up calling mainEntry all time.
            The assumption is its the same case with Delete and UNDELETE trigger handler. 
            
            That leaves only update triggers causing recursion and we should be good
        */
        set<Id> newset = new set<Id>();

        if(newMap <> null){
            newset = newMap.Keyset().clone();
        }

        //This is first time call and stores classname and Ids
        // 200 - assume first batch
        if(handlerClassNameSobjectIds.get(className) == null && newset.size() >0){
            handlerClassNameSobjectIds.put(className, newset.clone());
            return false;
        }

        //We need to add newset to classNameIds to determine if its recursive due to workflow updates
        // before count and after count on classNameIds should match if its recursive, else not recursive
        // 50 - assume second batch , third and so on
        if(handlerClassNameSobjectIds.get(className) != null && newset.size() >0){
            integer beforecount = handlerClassNameSobjectIds.get(className).size();
            handlerClassNameSobjectIds.get(className).addAll(newset.clone());
            if(beforecount == handlerClassNameSobjectIds.get(className).size()){
                System.debug('Trigger fall into recursive loop due to workflow field updates');
                return true;
            }else{
                System.debug('Resetting the static values for the second trigger batch');
                handlerClassNameSobjectIds.put(className, newset.clone());
                return false;           
            }
        }
        return false;
    }
}
