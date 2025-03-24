public class SortableRecord implements Comparable {
    public SObject Record;
    public static String FieldName;
    public static Boolean Descending;
    public static String FieldDataType;

    public SortableRecord(SObject record) {
        this.Record = record;
    }

    public Integer compareTo(Object compareTo) {
        SortableRecord xCompareToRecord = (SortableRecord)compareTo;

        Object value = this.Record.get(FieldName);
        Object xvalue = xCompareToRecord.record.get(FieldName);
        
        Integer returnValue = 0;
        switch on FieldDataType {
            when 'DATE' {
                if ((Date)value > (Date)xValue) {
                    returnValue = 1;
                } else if ((Date)value < (Date)xValue) {
                    returnValue = -1;
                }
            }
            when 'DATETIME' {
                if ((DateTime)value > (DateTime)xValue) {
                    returnValue = 1;
                } else if ((DateTime)value < (DateTime)xValue) {
                    returnValue = -1;
                }
            }
            when 'DOUBLE' {
                if ((Double)value  > (Double)xValue) {
                    returnValue = 1;
                } else if ((Double)value < (Double)xValue) {
                    returnValue = -1;
                }
            }
            when 'ID' {
                if ((Id)value  > (Id)xValue) {
                    returnValue = 1;
                } else if ((Id)value < (Id)xValue) {
                    returnValue = -1;
                }
            }
            when 'INTEGER' {
                if ((Integer)value > (Integer)xValue) {
                    returnValue = 1;
                } else if ((Integer)value < (Integer)xValue) {
                    returnValue = -1;
                }
            }
            when 'STRING' {
                if ((String)value > (String)xValue) {
                    returnValue = 1;
                } else if ((String)value < (String)xValue) {
                    returnValue = -1;
                }
            }
            when 'TIME' {
                if ((Time)value > (Time)xValue) {
                    returnValue = 1;
                } else if ((Time)value < (Time)xValue) {
                    returnValue = -1;
                }
            }
        }

        if (Descending == true) {
            returnValue = returnValue * -1;
        }
        return returnValue;
    }

}