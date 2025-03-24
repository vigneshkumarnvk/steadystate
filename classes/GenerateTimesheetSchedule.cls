global class GenerateTimesheetSchedule implements Schedulable {
    global void execute(SchedulableContext sc){
        //for United States locale, the start of a week is always Sunday.
        Date processDate = System.today().toStartOfWeek();
        //calculate start of week Monday's date.(Previous Week)
        processDate = TimeUtils.toStartOfWeek(processDate);
        GenerateTimesheetBatch generateTimesheetBatch = new GenerateTimesheetBatch(processDate);
        Database.executeBatch(generateTimesheetBatch, 1);
    }
}