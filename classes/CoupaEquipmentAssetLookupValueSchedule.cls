global class CoupaEquipmentAssetLookupValueSchedule implements Schedulable {
    global void execute(SchedulableContext sc){
        CoupaEquipmentAssetSyncBatch coupaEquipmentAssetSyncBatch = new CoupaEquipmentAssetSyncBatch();
        Database.executeBatch(coupaEquipmentAssetSyncBatch, 5);

    }
}