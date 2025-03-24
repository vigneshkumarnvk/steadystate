/************************************************************************
 Class Name   : CloneSalesOrderHelper.js
 Created Date : 12/12/2023
 Description  :
 Author       : Steven
 Contributors  :
 ***************************** Update Logs *****************************
 ***********************************************************************
 */
({
 getData : function(component, event) {
  let recordId = component.get("v.recordId");
  if (recordId) {
   let params = {"recordId" : recordId};
   this.callServerMethod(component, event, "c.getData", params, function (response){
    let result = JSON.parse(response);
    component.set("v.setupData", result);
    component.set("v.salesOrder", result.salesOrder);
    component.set("v.selectedServiceCenter", result.selectedServiceCenterId);
    component.set("v.selectedBillTo", result.billToCustomer);
   });
  }
 },
 clone : function (component, event){
  let selectedCloneToRecordType = component.get("v.selectedCloneToRecordType");
  let sourceRecordId = component.get("v.recordId");
  let jobDescription = component.get("v.jobDescription");
  let poNum = component.get("v.poNumber");
  let selectedServiceCenter = component.get("v.selectedServiceCenter");
  let billToCustomer = component.get("v.selectedBillTo");
  console.log(' >> billToCustomer' + billToCustomer);
  let selectedBillToId = billToCustomer.Id;
  let selectedBillParentId = billToCustomer.ParentId;
     let paramObj = {'sourceRecordId':sourceRecordId,'selectedCloneToRecordType':selectedCloneToRecordType,'selectedServiceCenter':selectedServiceCenter,'selectedBillToId':selectedBillToId,'selectedBillParentId':selectedBillParentId,'jobDescription':jobDescription,'poNum':poNum};
  this.callServerMethod(component, event, "c.cloneSalesOrder", paramObj, function (result){
   if(result){
    component.find("navigation").navigate({
     "type" : "standard__recordPage",
     "attributes": {
      "recordId"      : result,
      "actionName"    : "view"
     }
    }, true);
   }
  }, function (error){
   this.showToast(component, "Error", error, "error", "dismissible");
  });
 },
 validateCustomer : function (component, event, record){
  let params = {"billToId" : record.Id};
  this.callServerMethod(component, event, "c.validateBillToCust", params, function (result){
   component.set("v.selectedBillTo", record);
  }, function (error){
   component.set("v.selectedBillTo", null);
   component.set("v.salesOrder.Bill_to_Customer_No__r", null);
   this.showToast(component, "Error", error, "error", "dismissible");
  });
 }
});