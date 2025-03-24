public with sharing class AsyncProcessor implements Queueable {

    public void execute(QueueableContext context) {
        //TODO: Create AppConfigSupport class, because class that implements queueable can not be update while job was queued,
        // the class should be controlled by custom setting or other means that does not require a metadata change
        //if (!AppConfigSupport.appEnabled) return; // On/off switch
        List<AsyncRequest__c> requests;
        try {
            /**
             * Error__c = false skip error,
             * CreatedById increase security, filter records that were created in current user context
             * class with sharing enhance security,
             * FOR UPDATE lock the record to avoid concurrency error
             */
            requests = [SELECT Id, AsyncType__c, Params__c, Params1__c, Params2__c
            FROM AsyncRequest__c
            WHERE Error__c = FALSE
            AND CreatedById = :UserInfo.getUserId()
            LIMIT 1
            FOR UPDATE];
            //TODO: Add ORDER BY to SOQL, surcharge line Asynchronous request may not be the last
        } catch (Exception ex) {
            return;
        }
        if (requests.size() == 0) return;

        AsyncRequest__c currentRequest = requests[0];

        try {
            /**
             * Central Async control : process different Async requests not just for creating sales invoice, future updateTMPrice can be moved here
             */
            if (currentRequest.AsyncType__c == 'Create Sales Invoice Lines') createSalesInvoice(currentRequest);
            if (currentRequest.AsyncType__c == 'Add Surcharge Line to Sales Invoice') addSurchargeLineToSalesInvoice(currentRequest);

            // Add more here

            delete currentRequest;
            Database.emptyRecycleBin(new List<Id>{currentRequest.Id});

        } catch (Exception ex) {
            currentRequest.Error__c = true;
            currentRequest.Error_Message__c = ex.getMessage();
            update currentRequest;
        }

        /** Check if there is more asynchronous request and chain it if there is one */
        List<AsyncRequest__c> moreRequests = [SELECT Id, AsyncType__c, Params__c, Params1__c, Params2__c
        FROM AsyncRequest__c
        WHERE Error__c = FALSE
        AND Id <> :currentRequest.Id
        AND CreatedById = :UserInfo.getUserId()
        LIMIT 1];

        if (moreRequests.size() == 0) return;

        try {
            enqueue(context.getJobId());
        } catch (Exception ex) {
            /** Exception happens typically because fo a chaining limit exception , try to queue it again*/
            tryToQueue();
        }

    }

    public static void enqueue(Id currentJoId) {
        List<AsyncApexJob> jobs = [SELECT Id, Status, ExtendedStatus
        FROM AsyncApexJob
        WHERE JobType = 'Queueable'
        AND (Status = 'Queued' OR Status = 'Holding')
        AND CreatedById = :UserInfo.getUserId()
        AND ApexClass.Name = 'AsyncProcessor'
        AND Id != :currentJoId
        LIMIT 1];
        if (jobs.size() == 1) return;
        System.enqueueJob(new AsyncProcessor());
    }

    @Future
    public static void tryToQueue() {
        //if(!AppConfigSupport.appEnabled) return; // On/off switch
        try {
            if (Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0) enqueue(null);
        } catch (Exception ex) {
            // Wait for someone else to make a request...
            // Or maybe use scheduled Apex?
        }
    }

    public void createSalesInvoice (AsyncRequest__c request) {
        Id salesInvoiceId = request.Params__c;
        List<Id> theTMLIds = request.Params1__c.split(',');
        TMsService.addLinesToSalesInvoiceAsync(salesInvoiceId, new Set<Id>(theTMLIds));
    }

    public void addSurchargeLineToSalesInvoice (AsyncRequest__c request) {
        Id salesInvoiceId = request.Params__c;
        TMsService.addSurchargeLineToSalesInvoiceAsync(salesInvoiceId);
    }
}