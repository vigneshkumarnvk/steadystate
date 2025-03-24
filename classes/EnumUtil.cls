global class EnumUtil {

    global enum PricingSource{
        BASE,
        SALES_ORDER,
        SALES_QUOTE,
        CONTRACT
    }

    global enum QuoteType{
        ONE_TIME,
        RECURRENCE
    }

    global enum QuoteStatus{
        PENDING,
        WON,
        LOST,
        CANCELED
    }

    global enum TimeRateCode{
        REG,
        OT,
        DT
    }

    global enum CostMethod{
        UNIT_WEIGHT_VOL,
        CONTAINER
    }

    global enum ApprovalTreeDocType{
        SALES_ORDER,
        PURCHASE_ORDER,
        SALES_QUOTE,
        CREDIT_MEMO,
        SALES_INVOICE
    }

    global enum DocumentStatus{
        OPEN,
        CLOSED
    }

    global enum ApprovalStatus{
        DRAFT,
        PENDING_APPROVAL,
        APPROVED,
        REJECTED
    }

    global enum Operator{
        LESS_THAN_OR_EQUAL,
        GREATER_THAN
    }
}