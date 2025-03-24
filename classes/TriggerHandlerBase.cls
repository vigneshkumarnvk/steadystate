/*
Added By : Harika Madapathi
Dated    : 07/22/2023
Summary  : Trigger framework interface - Trigger handler base class to be derived
           by trigger handler classes that implement actual logic. This class is added so that implementing class can
           define/implement interface method as and when required
           Trigger Framework class - Doesn't need to be updated to add more business use case to trigger logic.   

* Modification Log :
 * Developer                 Date                   Description
 * ----------------------------------------------------------------------------                 
 * Harika Madapathi         07/22/2023             68128 - Tech Debt: Update Trigger Framework for SalesOrder object
**************************************************************************************************************************/
public virtual with sharing class TriggerHandlerBase implements ITriggerHandler {
    protected Map<ID,sObject> updatesObjectMap=new map<ID,sObject>();
    
    public virtual void mainEntry(){}
    public virtual void inProgressEntry(){}
    public void updateObjects(){}
}