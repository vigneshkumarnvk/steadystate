/**
 * Created by Steven on 5/2/2018.
 */

public class CmpApprovalURL {
    public String recId {get; set;}

    public String urlStr{
        get{
            return CreateApprovalURL.generateApprovalURL(recId);
        }
    }
}