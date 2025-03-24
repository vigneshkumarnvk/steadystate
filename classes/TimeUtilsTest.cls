@IsTest
private class TimeUtilsTest {

    static testMethod void testConvertStrToTime(){
        String timeStr = '09:35';
        String badTimeStr = '0934';
        Time goodTime = TimeUtils.convertStrToTime(timeStr);
        System.assertEquals(goodTime, Time.newInstance(9,35,0,0));
        Time nullTime = TimeUtils.convertStrToTime(badTimeStr);
        System.assertEquals(nullTime, null);
    }

    @IsTest
    private static void testCalculateHours(){
        Time startTime = Time.newInstance(0,0,0,0);
        Time endTime = Time.newInstance(0,0,0,0);
        System.assertEquals(24, TimeUtils.calculateHours(startTime, endTime));

        endTime = Time.newInstance(15,0,0,0);
        System.assertEquals(15, TimeUtils.calculateHours(startTime, endTime));

        startTime = Time.newInstance(16,0,0,0);
        System.assertEquals(23, TimeUtils.calculateHours(startTime, endTime));

        startTime = null;
        System.assertEquals(0, TimeUtils.calculateHours(startTime, endTime));

    }

    @IsTest
    private static void testIsCorssedMidNight(){
        Time startTime = Time.newInstance(5,0,0,0);
        Time endTime = Time.newInstance(4,0,0,0);
        System.assertEquals(true, TimeUtils.isCorssedMidNight(startTime, endTime));

        endTime = Time.newInstance(15,0,0,0);
        System.assertEquals(false, TimeUtils.isCorssedMidNight(startTime, endTime));
    }

    @IsTest
    private static void testIsWeekend(){
        System.assertEquals(false, TimeUtils.isWeekend('Monday'));
        System.assertEquals(true, TimeUtils.isWeekend('Sunday'));
    }

    @IsTest
    private static void testTimeEntryNeeded(){
        Date testDate = Date.valueOf('2019-01-01');
        Date endDate = Date.valueOf('2019-01-01');
        Time startTime = Time.newInstance(5,0,0,0);
        Time endTime = Time.newInstance(4,0,0,0);

        Integer numOfEntriesNeeded = TimeUtils.timeEntryNeeded(testDate, endDate, startTime, endTime, false);
        System.assertEquals(1, numOfEntriesNeeded);

        numOfEntriesNeeded = TimeUtils.timeEntryNeeded(testDate, endDate, startTime, endTime, true);
        System.assertEquals(2, numOfEntriesNeeded);
    }

    @IsTest
    private static void testAddDaysWithOutWeekend(){
        Date testDate = Date.valueOf('2019-01-01');

        Date resultDate = TimeUtils.addDaysWithOutWeekend(testDate, 7, false);
        System.assertEquals(Date.valueOf('2019-01-10'), resultDate);

        testDate = resultDate;
        resultDate = TimeUtils.addDaysWithOutWeekend(testDate, 7, true);
        System.assertEquals(Date.valueOf('2019-01-01'), resultDate);
    }
}