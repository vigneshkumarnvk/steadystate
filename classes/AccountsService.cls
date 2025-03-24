global class AccountsService {
    public static final String PO_FORMAT_ALPHANUMERICAL = 'ALPHANUMERICAL';
    public static final String PO_FORMAT_NUMERICAL = 'NUMERICAL';
    public static final String PO_FORMAT_NAME_OF_CONTACT = 'NAME_OF_CONTACT';
    public static final String INVOICE_SUBMISSION_CHANNEL_EMAIL = 'EMAIL';
    public static final String INVOICE_SUBMISSION_CHANNEL_INVOICE_PORTAL = 'INVOICE_PORTAL';
    public static final String INVOICE_SUBMISSION_CHANNEL_MAIL = 'HARD_COPY_SUBMITTAL';
    public static final String INVOICE_EMAIL_CONTACT_TYPE_AP = 'BILLING';
    public static final String INVOICE_EMAIL_CONTACT_TYPE_SITE = 'SITE';
    public static final String INVOICE_EMAIL_CONTACT_TYPE_EXECUTIVE = 'EXECUTIVE';
    public static final String INVOICE_EMAIL_CONTACT_TYPE_SALES = 'SALES';
    public static final String INVOICE_EMAIL_CONTACT_TYPE_QUOTE = 'QUOTE';
    public static final String INVOICE_EMAIL_CONTACT_TYPE_PURCHASE = 'PURCHASE';
    public static final String INVOICE_BACKUP_TYPE_INVOICE = 'INVOICE';
    public static final String INVOICE_BACKUP_TYPE_TM = 'TM';
    public static final String INVOICE_BACKUP_TYPE_MANIFEST_WEIGHT_TICKET = 'MANIFEST_WEIGHT_TICKET';
    public static final String INVOICE_BACKUP_TYPE_CERTIFIED_PAYROLL = 'CERTIFIED_PAYROLL';
    public static final String INVOICE_BACKUP_TYPE_SPILL_REPORT_WITH_PICTURES = 'SPILL_REPORT_WITH_PICTURES';
    public static final String INVOICE_BACKUP_TYPE_MARK_UP_VENDOR_INVOICE_OR_RECEIPT = 'MARK_UP_VENDOR_INVOICE_OR_RECEIPT';
    public static final String INVOICE_BACKUP_TYPE_CUSTOMER_SPECIFIC_DOCUMENTATION = 'CUSTOMER_SPECIFIC_DOCUMENTATION';
    public static final String LINE_BREAK_CHAR = '\r\n';
    //public static final String systemLineSeparator = '---DO NOT DELETE THIS LINE OR ADD INSTRUCTION AFTER THIS LINE---';

    global static void validatePONumberFormat(Account account, String poNumber){
        system.debug('Inside validate method>>>>'+account.PO_Number_Type__c);
        if((String.isNotBlank(account.PO_Number_Type__c) || account.PO_Required__c == true)){
            if(String.isNotBlank(poNumber) && poNumber.length() < 4){
                throw new DataException('PO Number must be at least four characters long!');
            }
           if(String.isNotBlank(poNumber) && poNumber.length() > 20){
                throw new DataException('PO Number should not be more than 20 characters!');
            } 
            // US141334
            // if(account.PO_Number_Type__c == PO_FORMAT_ALPHANUMERICAL){
            //     if(isPONumberValid(poNumber) == false){
            //         throw new DataException('PO number: ' + poNumber + 'is not valid! It must contains at least one letter and one number!');
            //     }
            //     /*
            //     if(String.isNotBlank(account.PO_Number_Format__c)) {
            //         if(isPONumberValid(poNumber, account.PO_Number_Format__c) == false){
            //             throw new DataException('PO number: ' + poNumber + 'is not valid! Accepted PO number format is: ' + account.PO_Number_Format__c);
            //         }
            //     } else {
            //         if (poNumber.isAlphanumeric() == false) {
            //             throw new DataException('PO number: ' + poNumber + 'is not valid! It can only contains letters or number for customer ' + account.Name);
            //         }
            //     }
            //      */
            // } else if (account.PO_Number_Type__c == PO_FORMAT_NUMERICAL){
            //     if(isValidNumericPONumber(poNumber) == false){
            //         throw new DataException('PO number: ' + poNumber + 'is not valid! It can only contains number, spaces, dashes, periods and the pound sign!');
            //     }
            // } else if (account.PO_Number_Type__c == PO_FORMAT_NAME_OF_CONTACT){
            //     if(poNumber.isAlphaSpace() == false){
            //         throw new DataException('PO number: ' + poNumber + 'is not valid! It can only contains letters or spaces!');
            //     }
            // }
            // US141334
        }
    }

    // global static Boolean isPONumberValid (String poNumber){
    //     Boolean isValid = true;
    //     /*
    //     if(poNumber.length() != acceptedPONumberFormat.length()){
    //         throw new DataException(poNumber + ' ( ' + poNumber.length() + ' characters)' + ' does not match to accept PO format ' + acceptedPONumberFormat + ' ( ' + acceptedPONumberFormat.length() + ' characters)');
    //     }
    //     List<String> acceptedCharSet = new List<String>();
    //     acceptedCharSet = acceptedPONumberFormat.split('');
    //      */
    //     List<String> inputCharSet = new List<String>();
    //     inputCharSet = poNumber.split('');
    //     Integer numbersCount = 0;
    //     Integer lettersCount = 0;
    //     for(Integer i=0; i < inputCharSet.size(); i++){
    //         String inputChar = inputCharSet.get(i);
    //         if(inputChar.isAlpha() == true) {
    //             lettersCount += 1;
    //         }
    //         if(inputChar.isNumeric() == true){
    //             numbersCount += 1;
    //         }
    //         /*
    //         String acceptChar = acceptedCharSet.get(i);
    //         if(acceptChar == 'X'){
    //             if(inputChar.isAlpha() == false){
    //                 isValid = false;
    //                 break;
    //             }
    //         } else if(acceptChar == '0'){
    //             if(inputChar.isNumeric() == false){
    //                 isValid = false;
    //                 break;
    //             }
    //         } else {
    //             if(inputChar != acceptChar){
    //                 isValid = false;
    //                 break;
    //             }
    //         }
    //          */
    //     }

    //     if(numbersCount <= 0 || lettersCount <= 0){
    //         isValid = false;
    //     }

    //     return isValid;
    // }

    // global static Boolean isValidNumericPONumber(String poNumber){
    //     Boolean isValid = true;
    //     List<String> inputCharSet = new List<String>();
    //     inputCharSet = poNumber.split('');
    //     for(Integer i=0; i < inputCharSet.size(); i++){
    //         String inputChar = inputCharSet.get(i);
    //         if(inputChar.isNumericSpace() == false) {
    //             if(inputChar != '-' && inputChar != '#' && inputChar != '.'){
    //                 isValid = false;
    //             }
    //         }
    //     }
    //     return isValid;
    // }

    global static String generateContactTypeFilterString(String contactTypes){
        String filterString = '';
        if(String.isNotBlank(contactTypes)){
            if(contactTypes.contains(';')){
                for(String contactType : contactTypes.split(';')){
                    filterString = filterString + '\'' + contactType  + '\',';
                }
            } else {
                filterString = '\'' + contactTypes  + '\'';
            }
        }
        filterString = filterString.removeEnd(',');
        if(String.isNotBlank(filterString)) {
            filterString = '(' + filterString + ')';
        }
        return filterString;
    }

    global static String generateCustomerBillingVerbose(String poNumberType, String invoiceContactType, String invoiceSubmissionChannel, String invoicePortal, String invoiceBackupDocType, String custSpecDoc){
        /*
        String newBillingInstruction = '';
        if(String.isNotBlank(billingInstruction)){
            newBillingInstruction = billingInstruction;
        }

        if (String.isNotBlank(billingInstruction) && billingInstruction.containsIgnoreCase(systemLineSeparator)){
            newBillingInstruction = billingInstruction.substringBefore(systemLineSeparator);
        }
        newBillingInstruction += systemLineSeparator;
        String systemCreatedInstruction = lineBreakChar;
         */
        String lineBreakChar = '\r\n';
        String systemCreatedInstruction = '';
        if(String.isNotBlank(poNumberType)){
            String s = 'Customer PO Number Type: ' + poNumberType;
            /*
            if(String.isNotBlank(poNumberFormat)){
                s = s + ' Format: ' + poNumberFormat;
            }
             */
            systemCreatedInstruction = systemCreatedInstruction + s + lineBreakChar;
        }
        if(String.isNotBlank(invoiceContactType)){
            String s = 'Invoice Contact Type: ' + invoiceContactType;
            systemCreatedInstruction = systemCreatedInstruction + s + lineBreakChar;
        }
        if(String.isNotBlank(invoiceBackupDocType)){
            String s = 'Invoice Backup Document Type: ' + invoiceBackupDocType;
            if(invoiceBackupDocType.containsIgnoreCase(AccountsService.INVOICE_BACKUP_TYPE_CUSTOMER_SPECIFIC_DOCUMENTATION) && String.isNotBlank(custSpecDoc)){
                s = s + lineBreakChar + 'Customer Specific Documentation: ' + custSpecDoc;
            }
            System.debug('Info: s ' + s);
            systemCreatedInstruction = systemCreatedInstruction + s + lineBreakChar;
        }
        if(String.isNotBlank(invoiceSubmissionChannel)){
            String s = 'Invoice Submission Channel: ' + invoiceSubmissionChannel;
            systemCreatedInstruction = systemCreatedInstruction + s + lineBreakChar;
            if(invoiceSubmissionChannel.containsIgnoreCase(AccountsService.INVOICE_SUBMISSION_CHANNEL_INVOICE_PORTAL) && String.isNotBlank(invoicePortal)){
                s = 'Invoice submission portal: ' + invoicePortal;
                systemCreatedInstruction = systemCreatedInstruction + s + lineBreakChar;
            }
        }
        /*
        newBillingInstruction += systemCreatedInstruction;
        return newBillingInstruction;
         */
        return systemCreatedInstruction;
    }

    global static String generateCustomerBillingInstructions(Account account){
        String customerBillingInstruction = '';
        if(String.isNotBlank(account.Customer_Billing_Instructions__c)){
            customerBillingInstruction = customerBillingInstruction + account.Customer_Billing_Instructions__c;
        }

        if(String.isNotBlank(account.Billing_Instructions__c)){
            customerBillingInstruction = customerBillingInstruction + LINE_BREAK_CHAR + account.Billing_Instructions__c;
        }

        return customerBillingInstruction;
    }
}