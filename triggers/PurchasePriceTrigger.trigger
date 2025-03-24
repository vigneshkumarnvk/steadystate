/**
 * Created by Steven on 2/28/2018.
 */

trigger PurchasePriceTrigger on Purchase_Price__c (before insert, before update, before delete) {
    if(Trigger.isInsert || Trigger.isUpdate){
            /*
            for(Purchase_Price__c pp: Trigger.new){
                if(pp.Name == 'NEW'){
                    pp.addError('NEW is a reserved product name, please use a different name!');
                }
            }
            */
    }
}