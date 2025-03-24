/************************************************************************
 Class Name   : CloneSalesOrderController.js
 Created Date : 12/12/2023
 Description  :
 Author       : Steven
 Contributors  :
 ***************************** Update Logs *****************************
 ***********************************************************************
 */
({
 doInit : function(component, event, helper) {
  helper.getData(component, event);
 },
 handleSelectCloneToTypeChange : function (component, event, helper){
  component.set("v.selectedCloneToRecordType", event.getSource().get("v.value"));
 },
 handleServiceCenterChange : function (component, event, helper){
  component.set("v.selectedServiceCenter", event.getSource().get("v.value"));
 },
 handleBillToCustomerChange : function (component, event, helper){
  let record = event.getParam("record");
  if(record){
   helper.validateCustomer(component, event, record);
  }
 },
 clone : function (component, event, helper){
  helper.clone(component, event);
 },
 handleClose : function (component, event, helper){
  $A.get("e.force:closeQuickAction").fire();
 }
});