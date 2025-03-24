/**
 * Created by Kevin on 12/18/2019.
 */

public with sharing class JSONUtils {

    public static SObject attachListToParent(SObject parent, List<SObject> children, String parentSideRelationshipName)
    {
        String targetJson = JSON.serialize(parent);

        /*
        String childrenJson = '"' + parentSideRelationshipName + '" : {';
        childrenJson += '"totalSize" : ' + children.size() + ',';
        childrenJson += '"done" : true,';
        childrenJson += '"records" : ' + JSON.serialize(children);
        childrenJson += '}';

        targetJson = targetJson.substring(0, targetJson.length()-1) + ',' + childrenJson + '}';
        */
        //return (SObject)JSON.deserialize(targetJson, SObject.class);
        //SObject obj = (SObject)JSON.deserialize(targetJson, SObject.class);
        SObject obj = (SObject)JSON.deserialize(targetJson.substring(0, targetJson.length()-1) + ','
                + '"' + parentSideRelationshipName + '" : {'
                + '"totalSize" : ' + children.size() + ','
                + '"done" : true,'
                + '"records" : ' + JSON.serialize(children)
                + '}' +
                '}', SObject.class);
        targetJson = null; //free memory from heap
        //childrenJson = null; //free memory from heap
        return obj;
    }
}