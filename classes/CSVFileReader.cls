/******************************************************************************************************************
* Name         :  CSVFileReader 
* Description  :  Handles CSV file parsing.
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Vignesh Kumar N         01-15-2024             Initial Version
***********************************************************************************************************************/
public class CSVFileReader {
	public boolean EOF {
		get{
			if( this.position < this.csvStringLength )
				return false;
			else
				return true;
		}
	}		   
	private string csvString;
	private integer csvStringLength;
	private integer position = 0;	
	private static string COMMA = ',';
	private static string NL = '\n';
	private static string QUOTE = '"';
	private static string DOUBLE_QUOTE = '""';

	public CSVFileReader( string csvString ) {
		this.csvString = csvString;
		this.csvStringLength = csvString.length();
	}
	
	//To process line by line data from csv
	private integer ReadToLine(integer position, List<string> values){
		integer startPos = position;
		string currentValue;
		integer cAt, nlAt, foundAt;

		List<string> tmpValues = new List<string>();
		while (position < csvStringLength){
			cAt = this.csvString.indexOf( COMMA, position );
			nlAt = this.csvString.indexOf( NL, position );
			foundAt = Math.min( cAt, nlAt );
			if( foundAt == -1 )
					foundAt = Math.max( cAt, nlAt );
			if (foundAt == -1){
				currentValue = this.csvString.substring(startPos);
				position = this.csvStringLength;
			}else {
				currentValue = this.csvString.substring(startPos, foundAt );
				position = foundAt + 1;
			}
			currentValue = currentValue.trim();
			if( !currentValue.startsWith( QUOTE ) ){
				tmpValues.add( currentValue );
				if( foundAt == nlAt ) break;
				startPos = position;
			}else if( currentValue.endsWith( QUOTE ) && !currentValue.endsWith( DOUBLE_QUOTE ) ){
				if( currentValue.indexOf( DOUBLE_QUOTE ) == -1 )
					tmpValues.add( currentValue.substring( 1, currentValue.length() - 1 ) );
				else
					tmpValues.add( currentValue.substring( 1, currentValue.length() - 1 ).replace( DOUBLE_QUOTE, QUOTE ) );
					
				if( foundAt == nlAt )
					break;				
				startPos = position;
			}
		}
		values.addAll( tmpValues );
		return position;
	}

	//To process line by line data from csv
	public List<string> ReadLine(){
		List<string> values = new List<string>();
		this.position = this.ReadToLine( this.position, values );
		return values;
	}

	//To process line by line data from csv
	public static List<List<string>> Parse( string csvString ){
		List<List<string>> linesValues = new List<List<string>>();
		CSVFileReader reader = new CSVFileReader(csvString);
		while (!reader.EOF){
			List<string> actualValues = reader.ReadLine();   
			linesValues.Add(actualValues);
		}
		return linesValues;
	}
}