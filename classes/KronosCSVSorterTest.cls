@IsTest
public class KronosCSVSorterTest {

    @IsTest
    static void testCSVSorting() {
      
        // Step 1: Prepare sample CSV data (Unsorted)
        String unsortedCSVData = 'Name,EIN,Date,Start Job Time,Site Start Time,Site End Time,Job End Time,Start Lunch Time,End Lunch Time,Rate,Labor Type,Pay Rule Name,Sales Order,D365 Project Id,Delete Indicator\n'
                              + '"Miles Ettinger","100027211","10/21/2024","09:00:00","","","14:00:00","","","0.0","Driver","IL & IN HYDRO 150 DIST 1","MD115360","P702.00024",""\n'
                              + '"Shaugh-Tai L. Fogg","100030300","10/15/2024","01:15:00","","","03:30:00","","","0.0","Driver","IL & IN HYDRO 150 DIST 1","MD115400","P702.00024","\n'
                              + '"Derrick Banks","100027197","10/10/2024","09:00:00","","","14:00:00","","","0.0","Driver","IL & IN HYDRO 150 DIST 1","MD115402","P702.00024",""\n'
                              + '"Aubrey Sekyi","100027238","10/21/2024","08:00:00","","","12:00:00","","","0.0","Foreman","IL & IN HYDRO 150 DIST 1","MD115414","P702.00024",""';
                              
  
        // Step 2: Call the sortCSVData method from CSVSorter
        String sortedCSVData = KronosCSVSorter.sortCSVData(unsortedCSVData);

        // Step 3: Define expected sorted CSV data
        String expectedSortedCSVData = 'Name,EIN,Date,Start Job Time,Site Start Time,Site End Time,Job End Time,Start Lunch Time,End Lunch Time,Rate,Labor Type,Pay Rule Name,Sales Order,D365 Project Id,Delete Indicator\n'
                                + '"Derrick Banks","100027197","10/10/2024","09:00:00","","","14:00:00","","","0.0","Driver","IL & IN HYDRO 150 DIST 1","MD115402","P702.00024",""\n'
                                + '"Miles Ettinger","100027211","10/21/2024","09:00:00","","","14:00:00","","","0.0","Driver","IL & IN HYDRO 150 DIST 1","MD115360","P702.00024",""\n'
                                + '"Aubrey Sekyi","100027238","10/21/2024","08:00:00","","","12:00:00","","","0.0","Foreman","IL & IN HYDRO 150 DIST 1","MD115414","P702.00024",""\n'
                                + '"Shaugh-Tai L. Fogg","100030300","10/15/2024","01:15:00","","","03:30:00","","","0.0","Driver","IL & IN HYDRO 150 DIST 1","MD115400","P702.00024","';
                              
        // Step 4: Assert the sorted result is as expected
        System.debug(sortedCSVData);
        System.assertEquals(expectedSortedCSVData, sortedCSVData, 'The CSV data should be sorted correctly.');
    }

    @IsTest
    static void testEmptyCSVData() {
        // Step 1: Prepare empty CSV data (header only)
        String emptyCSVData = 'Name,EIN,Date,Start Job Time,Site Start Time,Site End Time,Job End Time,Start Lunch Time,End Lunch Time,Rate,Labor Type,Pay Rule Name,Sales Order,D365 Project Id,Delete Indicator\n';

        // Step 2: Call the sortCSVData method from CSVSorter
        String sortedCSVData = KronosCSVSorter.sortCSVData(emptyCSVData);

        // Step 3: Assert the sorted result matches the input (no changes expected)
        System.assertEquals(emptyCSVData, sortedCSVData, 'Empty CSV data should remain unchanged.');
    }

    @IsTest
    static void testSingleLineCSVData() {
        // Step 1: Prepare a CSV with only one data line
        String singleLineCSVData = 'Name,EIN,Date,Start Job Time,Site Start Time,Site End Time,Job End Time,Start Lunch Time,End Lunch Time,Rate,Labor Type,Pay Rule Name,Sales Order,D365 Project Id,Delete Indicator\n'
                                 + 'Chin","100027629","10/12/2024","03:00:00","","","12:00:00","","","0.0","Field Technician","","RH108976","P701.00034","Delete"';

        // Step 2: Call the sortCSVData method from CSVSorter
        String sortedCSVData = KronosCSVSorter.sortCSVData(singleLineCSVData);

        // Step 3: Assert the sorted result matches the input (no changes expected)
        System.assertEquals(singleLineCSVData, sortedCSVData, 'Single-line CSV data should remain unchanged.');
    }


}