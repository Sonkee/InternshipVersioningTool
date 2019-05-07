/*
 * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
 * Description: Class to contain methods for ContentVersion web service
 * Date: 25/4/2019
 */
public class AP_ContentVersion {
    final static String ENDPOINT_URL = Label.EndpointUrl;
    final static String SEPARATION_STRING = 'A_RANDOM_STRING';
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: Method to create ContentVersion records on another org
    * Date: 25/4/2019
    */
    public static void createFiles(){
        String reqEndpoint = ENDPOINT_URL+'services/data/v45.0/composite/sobjects';
        string accToken;
        AP_CreateToken tokenClass = new AP_CreateToken();
        accToken = tokenClass.getRequestToken();
        if(accToken!=''){
            HttpRequest req = new HttpRequest();
            req.setEndpoint(reqEndpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'multipart/form-data; boundary=' + SEPARATION_STRING);
            req.setHeader('Authorization','Bearer '+accToken);
            List<ApexClass> apexClassList = new List<ApexClass>();
            apexClassList = AP_CustomObjectCreation.getApexClass();
            String jsonStringUp = jsonBodyGenerator(apexClassList);
            String jsonStringDown = jsonBodyDataGenerator(apexClassList);
            String jsonString = jsonStringUp + '\n\n' + jsonStringDown;
            system.debug('jsonString:'+jsonString);
            req.setBody(jsonString);
            
            Http httpReq = new Http();
            HttpResponse res = httpReq.send(req);
            String jsonResponse = res.getBody();
            System.debug('createFiles_Response: ' + res.getBody());
            
            if(res!=null){
                List<Id> fileIdList = new List<Id>();
                String newResponse = '{"responseList":'+jsonResponse+'}';
                firstWrapper resWrapp = (firstWrapper)JSON.deserialize(newResponse,firstWrapper.class);
                for(Integer i= 0;i<resWrapp.responseList.size();i++){
                    fileIdList.add(resWrapp.responseList[i].Id);
                }
            }
        }
    }
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: Method to create the json string for composite part of body
    * Date: 25/4/2019
    */
    public static String jsonBodyGenerator(List<ApexClass> apexClassList){
        String jsonBody;
        String header = '--'+ SEPARATION_STRING + '\nContent-Disposition: form-data; name="collection";\nContent-Type: application/json\n\n';
        jsonBody = 
            '{\n"allOrNone" : false,\n'+
            '"records" : [\n';
        for(Integer i =0;i<apexClassList.size();i++){
            jsonBody = jsonBody +
                '{\n'+
                '"attributes" :\n'+
                '{\n'+
            	'"type" : "ContentVersion",\n'+
                '"binaryPartName" : "'+apexClassList[i].Name+'",\n'+
                '"binaryPartNameAlias" : "VersionData"\n'+
                '},\n' +
                '"PathOnClient" : "'+apexClassList[i].Name+'_Version1.txt"\n' + 
                '}';
            if(i<apexClassList.size()-1){
                jsonBody = jsonBody +
                    ',\n';
            }else{
                jsonBody = jsonBody +
                    '\n]\n'+
                    '}';
            }
        }
        jsonBody = header + jsonBody;
        return jsonBody;
    }
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: Method to create the json string for versiondata part
    * Date: 25/4/2019
    */
    public static String jsonBodyDataGenerator(List<ApexClass> apexClassList){
        String jsonBody = '';
        for(Integer i =0;i<apexClassList.size();i++){
            if(i<apexClassList.size()-1){
                jsonBody = jsonBody + '--'+ SEPARATION_STRING +
                    '\nContent-Disposition: form-data; name="'+apexClassList[i].Name+'"; filename="'+apexClassList[i].Name+'_Version1.txt"\n' + 
                    'Content-Type: text/plain\n\n'+
                    apexClassList[i].Body+'\n';   
            }else{
                jsonBody = jsonBody + '--'+ SEPARATION_STRING +
                    '\nContent-Disposition: form-data; name="'+apexClassList[i].Name+'"; filename="'+apexClassList[i].Name+'_Version1.txt"\n' + 
                    'Content-Type: text/plain\n\n'+
                    apexClassList[i].Body+'\n\n'+
                    '--'+ SEPARATION_STRING +'--';
            }
        }
        return jsonBody;
            
    }
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: Method to make an http query for ContentVersion from List of ContentVerison Id
    * Argument: List<Id> fileIdList
    * Date: 30/4/2019
    */
    public static void getContentVersion(List<String> fileIdList){
        String queryStr = 'select Id, Title, ContentDocumentID from ContentVersion where Id IN'+fileIdList;
        //String queryStr = 'select+Id,Title,ContentDocumentID+from+ContentVersion+where+Id+IN+(\'06825000000F1V7AAK\',\'06825000000F1V6AAK\',\'06825000000F1V5AAK\')';
        String encoded = EncodingUtil.urlEncode(queryStr, 'UTF-8');
        
        system.debug('encoded: '+encoded);
        String reqEndpoint = ENDPOINT_URL+'services/data/v45.0/query?q='+encoded;
        system.debug('reqEndpoint: '+reqEndpoint);
        string accToken;
        AP_CreateToken tokenClass = new AP_CreateToken();
        accToken = tokenClass.getRequestToken();
        if(accToken!=''){
            HttpRequest req = new HttpRequest();
            req.setEndpoint(reqEndpoint);
            req.setMethod('GET');
            req.setHeader('Authorization','Bearer '+accToken);
            
            Http httpReq = new Http();
            HttpResponse res = httpReq.send(req);
            String jsonResponse = res.getBody();
            //System.debug('query_Response: ' + res.getBody());
            Map<String,String> newResponseMap = new Map<String,String>();
            queryReturnResponseWrapper QRRW = (queryReturnResponseWrapper)Json.deserialize(jsonResponse, queryReturnResponseWrapper.class);
            for(recordWrapper recordList : QRRW.records){
                newResponseMap.put(recordList.Title,recordList.ContentDocumentId);
                //System.debug('Title:'+recordList.Title +', ContentDocumentId:'+recordList.ContentDocumentId);
            }
            System.debug('Map: '+newResponseMap);
        }
    }
    /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: Wrapper class to get response from createFiles method
    * Date: 30/4/2019
    */
    public class responseWrapper{
        String Id;
        List<errorWrapper> errors;
        boolean success;
    }
    public class errorWrapper{
        String statusCode;
        String message;
        List<String> fields;
    }
    public class firstWrapper{
        List<responseWrapper> responseList;
    }
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: Wrapper class to get query response from getContentVersion method
    * Date: 6/5/2019
    */
    public class attributesWrapper {
        string type;
        string url;
    }
    public class recordWrapper {
        attributesWrapper attributes;
        String Title;
        String Id;
        String ContentDocumentId;
        public recordWrapper (){
            attributes = new attributesWrapper();
        }
    }
    public class queryReturnResponseWrapper{
        String done;
        String totalSize;
        list<recordWrapper> records ;
    }
}