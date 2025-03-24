public class KronosCSVSorter {
    // Wrapper class to store CSV data for sorting
    public class CSVLine implements Comparable {
        public String rsgEin;
        public String workDate;
        public String jobStartTime;
        public String deleteIndicator;
        public String originalLine;

        // Constructor to parse a CSV line
        public CSVLine(String csvLine) {
            List<String> fields = csvLine.split(',');

            // Assign fields accordingly (adjust indices based on your CSV structure)
            rsgEin = fields[1];
            workDate = fields[2]; // Assume date is in yyyy-MM-dd format
            jobStartTime = fields[3]; // Assuming the time is in HH:mm:ss format
            deleteIndicator = fields[14];
            originalLine = csvLine; // Keep the original line for reconstruction
        }

        // Implement the Comparable interface for sorting
        public Integer compareTo(Object compareToObj) {
            CSVLine other = (CSVLine) compareToObj;

            Integer result = rsgEin.compareTo(other.rsgEin);
            if (result == 0) {
                result = workDate.compareTo(other.workDate);
                if (result == 0) {
                    result = jobStartTime.compareTo(other.jobStartTime);
                    if (result == 0) {
                        result = deleteIndicator.compareTo(other.deleteIndicator);
                    }
                }
            }
            return result;
        }
    }

    // Method to sort the CSV data
    public static String sortCSVData(String csvData) {
        // Step 1: Split the CSV data into lines
        List<String> lines = csvData.split('\n');

        if(lines.size() < 2) {
            return csvData; // nothing to sort
        }

        // Step 2: Remove and store the header
        String header = lines[0];
        lines.remove(0); // Remove the header for sorting

        // Step 3: Convert each CSV line into a CSVLine object
        List<CSVLine> csvLines = new List<CSVLine>();
        for (String line : lines) {
            csvLines.add(new CSVLine(line));
        }

        // Step 4: Sort the list of CSVLine objects
        csvLines.sort(); // This uses the compareTo method in CSVLine class

        // Step 5: Reconstruct the sorted CSV data with the header
        List<String> sortedLines = new List<String>();
        for (CSVLine csvLine : csvLines) {
            sortedLines.add(csvLine.originalLine);
        }

        // Combine header and sorted lines into a single CSV string
        String sortedCsvData = header + '\n' + String.join(sortedLines, '\n');
        return sortedCsvData;
    }
}