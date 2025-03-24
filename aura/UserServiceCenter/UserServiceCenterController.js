({
 handleDelete : function (component, event, helper) {
  var userServiceCenters = component.get("v.userServiceCenters");
  var rowIndex = component.get("v.index");
  for (var i = 0; i < userServiceCenters.length; i++) {
   if (i == rowIndex) {
    userServiceCenters.splice(i, 1);
    break;
   }
  }
  component.set("v.userServiceCenters", userServiceCenters);
 },
 handleServiceCenterChange : function (component, event, helper) {
  var userServiceCenter = component.get("v.userServiceCenter");
  if (userServiceCenter.Service_Center__r != null) {
   userServiceCenter.Service_Center__c = userServiceCenter.Service_Center__r.Id;
  } else {
   userServiceCenter.Service_Center__c = null;
  }
  component.set("v.userServiceCenter", userServiceCenter);
 },
 handleDefaultChange : function (component, event, helper) {
  var userServiceCenters = component.get("v.userServiceCenters");
  var userServiceCenter = component.get("v.userServiceCenter");
  var rowIndex = component.get("v.index");
  if (userServiceCenter.Default__c == true) {
   for (var i = 0; i < userServiceCenters.length; i++) {
    if (i != rowIndex && userServiceCenters[i].Default__c == true) {
     userServiceCenters[i].Default__c = false;
    }
   }
  }
  component.set("v.userServiceCenters", userServiceCenters);
 }
});