/**
 * Created by Kevin on 12/17/2019.
 */

public with sharing class BillingLine {
    public Integer LineNumber { set; get; }
    public Id BillingRuleId { set; get; }

    //billing rule mapping <<
    /*
    public Boolean PortalBasisAssumption { set; get; }
    public Boolean OvertimeRateAssumption { set; get; }
    public Boolean DailyRateAssumption { set; get; }
    public Boolean LumpSumAssumption { set; get; }
    */ 
    //billing rule mapping >>

    public Date ScheduleDate { set; get; }
    public Time StartTime { set; get; }
    public Time EndTime { set; get; }
    public Time LunchStartTime { set; get; }
    public Time LunchEndTime { set; get; }
    public Boolean IncludeLunch { set; get; }
    public Decimal Quantity { set; get; }
    public Decimal UOMQty { set; get; }
    public Id UnitOfMeasureId { set; get; }

    public Decimal UnitPrice { set; get; }
    public Decimal RegularRate { set; get; }
    public Decimal OvertimeRate { set; get; }
    public Decimal DoubleTimeRate { set; get; }
    public Decimal UnitCost { set; get; }
    public Decimal TaxPercent { set; get; }

    public Id ContractId { set; get; }
    public String TMStatus { set; get; } //specifically for TM

    public Decimal RegularHours { set; get; }
    public Decimal OvertimeHours { set; get; }
    public Decimal DoubleTimeHours { set; get; }

    public Unit_of_Measure__c UnitOfMeasure { set; get; }
    public Billing_Rule__c BillingRule { set; get; }

    //rate.code.fix <<
    public String DayRateCode { set; get; }
    //rate.code.fix >>

    //Ticket#20496
    public Id resourceId {get; set;}
    public Id weekNumberId {get; set;}
    //Ticket#20496

    public Decimal Hours {
        get {
            if (this.StartTime != null && this.EndTime != null) {
                return TimeUtils.calculateHours(this.StartTime, this.EndTime);
            }
            else {
                if (this.UnitOfMeasure.Hours_UOM__c == true) {
                    if (this.UOMQty != null) {
                        return this.UOMQty;
                    }
                    return 0;
                }
                else {
                    return 0;
                }
            }
        }
    }

    public Decimal TaxAmount {
        get {
            return CompanyMgmt.halfUpTo2D(this.LineAmount * this.TaxPercent);
        }
    }

    public Decimal LineAmount {
        get {
            if (this.UnitOfMeasure.Hours_UOM__c == true) {
                return CompanyMgmt.halfUpTo2D(this.RegularRate * this.RegularHours)
                        + CompanyMgmt.halfUpTo2D(this.OvertimeRate * this.OvertimeHours)
                        + CompanyMgmt.halfUpTo2D(this.DoubleTimeRate + this.DoubleTimeHours);
            }
            else {
                return  CompanyMgmt.halfUpTo2D(this.Quantity * this.UOMQty * this.UnitPrice);
            }
        }
    }

    public  Decimal LineAmountIncludingTax {
        get {
            return  this.LineAmount + this.TaxAmount;
        }
    }

    public Decimal LineCost {
        get {
            if (this.UnitOfMeasure.Hours_UOM__c == true) {
                return CompanyMgmt.halfUpTo2D(this.Quantity * this.Hours * this.UnitCost);
            }
            else {
                return CompanyMgmt.halfUpTo2D(this.Quantity * this.UnitCost * this.UOMQty);
            }
        }
    }
}