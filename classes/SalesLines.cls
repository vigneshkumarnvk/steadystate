public class SalesLines extends fflib_SObjectDomain implements ISalesLines{

    public static Map<Id, Sales_Order__c> mapSalesOrders = new Map<Id, Sales_Order__c>();

    public static ISalesLines newInstance(List<Sales_Line__c> sObjectList) {
        return (ISalesLines) Application.Domain.newInstance(sObjectList);
    }
    public SalesLines(List<Sales_Line__c> sObjectList) {
        super(sObjectList);
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new SalesLines(sObjectList);
        }
    }

    public void updateSalesLinesForBillAsLumpSumAllAction() {
        updateSLBillAsLumpSum();
        updateSLTaxPct();
        updateSLTotal();
    }

    public void updateSLBillAsLumpSum() {
        for (Sales_Line__c theSL : (List<Sales_Line__c>) Records) {
            if(theSL.Category__c != 'Bundled' && theSL.Bill_as_Lump_Sum__c != true && !theSL.System_Calculated_Line__c){
                theSL.Bill_as_Lump_Sum__c = true;
                if(theSL.Category__c == 'Labor') {
                    //Ticket#15685
                    if(CompanyMgmt.zeroIfNull(theSL.Regular_Rate__c) > 0) theSL.xRegular_Rate__c = theSL.Regular_Rate__c;
                    if(CompanyMgmt.zeroIfNull(theSL.Overtime_Rate__c) > 0) theSL.xOvertime_Rate__c = theSL.Overtime_Rate__c;
                    if(CompanyMgmt.zeroIfNull(theSL.Premium_Rate__c) > 0) theSL.xPremium_Rate__c = theSL.Premium_Rate__c;
                    if(CompanyMgmt.zeroIfNull(theSL.Unit_Price__c) > 0) theSL.xUnit_Price__c = theSL.Unit_Price__c;
                    theSL.Regular_Rate__c = 0;
                    theSL.Premium_Rate__c = 0;
                    theSL.Overtime_Rate__c = 0;
                    theSL.Unit_Price__c = 0;
                } else {
                    if(CompanyMgmt.zeroIfNull(theSL.Unit_Price__c) > 0) theSL.xUnit_Price__c = theSL.Unit_Price__c; //Ticket#15685
                    theSL.Unit_Price__c = 0;
                }
            }
        }
    }

    public void updateSLTaxPct() {
        for (Sales_Line__c theSL : (List<Sales_Line__c>) Records) {
            Sales_Order__c theSO = mapSalesOrders.get(theSL.Sales_Order__c);
            if (theSO.Tax_Liable__c && theSL.Tax_Group__c != null) {
                theSL.Tax_Pct__c = CompanyMgmt.getSalesTax(theSO.Tax_Area__c, theSL.Tax_Group__c);
            }
            else {
                theSL.Tax_Pct__c = 0;
            }
        }
    }

    public void updateSLTotal() {
        for (Sales_Line__c theSL : (List<Sales_Line__c>) Records) {
            if (theSL.Category__c != 'Labor' && theSL.Category__c != 'Equipment'){
                theSL.Line_Cost__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(theSL.Unit_Cost__c) * CompanyMgmt.zeroIfNull(theSL.Quantity__c));
                theSL.Line_Amount__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(theSL.Unit_Price__c) * CompanyMgmt.zeroIfNull(theSL.Quantity__c));
            } else {
                theSL.Line_Cost__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(theSL.Unit_Cost__c) * CompanyMgmt.zeroIfNull(theSL.Quantity__c) * CompanyMgmt.zeroIfNull(theSL.UOM_Qty__c));
                theSL.Line_Amount__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(theSL.Unit_Price__c) * CompanyMgmt.zeroIfNull(theSL.Quantity__c) * CompanyMgmt.zeroIfNull(theSL.UOM_Qty__c));
            }
            Decimal Markup = 0;
            if(theSL.Category__c != ResourceService.SUBCONTRACTORS_CATEGORY) {
                if (theSL.Markup_Option__c == '%') Markup = theSL.Line_Amount__c * CompanyMgmt.zeroIfNull(theSL.Markup__c) / 100;
                if (theSL.Markup_Option__c == 'Amount') Markup = CompanyMgmt.zeroIfNull(theSL.Markup__c);
            }
            theSL.Line_Amount__c += Markup;
            theSL.Tax__c = CompanyMgmt.halfUpTo2D(theSL.Line_Amount__c * CompanyMgmt.zeroIfNull(theSL.Tax_Pct__c) / 100);
            theSL.Line_Amt_Incl_Tax__c = theSL.Line_Amount__c + theSL.Tax__c;
            theSL.Profit_Margin__c = theSL.Line_Amount__c - theSL.Line_Cost__c;
        }
    }
}