public with sharing class StringUtil {
    public static String extractLogoURLFromRichTextLogoField(String richTextFieldInString){
        String logoUrl = '';
        if(String.isNotBlank(richTextFieldInString)){
            logoUrl = richTextFieldInString.substringBetween('<img src="', '" alt="');
        }
        return logoURL.unescapeHtml4();
    }
}