public with sharing class TMSignatureSchedulable implements Schedulable{
    public void execute(SchedulableContext sc) {
        System.Type objType = Type.forName('TMSignatureProcessSchedulable');
        Schedulable obj = (Schedulable)objType.newInstance();
        obj.execute(sc);
    }
}