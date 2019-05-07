/*
 * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
 * Description: Class to contain methods to create custom objects records
 * Date: 24/4/2019
 */
public class AP_CreateRecord {
    final static string ENDPOINT_URL = Label.EndpointUrl;
    
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: method to create records for list of custom object name
    * Arguments: List of string customObjNameList
    * Date: 24/4/2019
    */
    public static void createCustomRecord(List<String> customObjNameList){
        string accToken;
        
        string endPoint=ENDPOINT_URL+'services/data/v45.0/composite/sobjects';
        
        AP_CreateToken tokenClass = new AP_CreateToken();
        accToken = tokenClass.getRequestToken();
        
        if(accToken!='')
        {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPoint);
            req.setMethod('POST');
            req.setHeader('Authorization','Bearer '+accToken);
            req.setHeader('Content-Type', 'application/json');
            
            
            req.setBody(jsonBodyGenerator(customObjNameList));
            Http httpReq = new Http();
            HttpResponse res = httpReq.send(req);
            String jsonResponse = res.getBody();
            System.debug('createCustomRecord_Reponse: ' + jsonResponse);
            //testing part to get response
            //List<String> recordIdList = new List<String>();
            if(res!=null){
                //String newResponse = '{"responseList" : '+ jsonResponse +'}';
                compositeResponseWrapper compositeResWrapp = (compositeResponseWrapper)JSON.deserialize(jsonResponse,compositeResponseWrapper.class);
                //String wrapJson = jsonResponse.substring(1, jsonResponse.length());
                //List<String> recordResponseList = (List<String>)JSON.deserializeUntyped(jsonResponse);
                //Map<String,responseWrapper> recordResponseList = (Map<String,responseWrapper>)JSON.deserializeUntyped(wrapJson);
                /*for(Integer i= 0;i<resWrapp.responseList.size();i++){
                    recordIdList.add(resWrapp.responseList[i].Id);
                }*/
                //AP_ContentVersion.createFiles();
                //System.debug('recordIdList: '+recordIdList);
            }
        }
    }
    
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: method to create JSON String from list of customObjName
    * Arguments: List of string customObjNameList
    * Date: 24/4/2019
    */
    public static String jsonBodyGenerator(List<String> customObjNameList){
        String jsonString =
            '{"allOrNone" : true,'+
            '"compositeRequest" : [';
        for(Integer i =0;i<customObjNameList.size();i++){
            jsonString = jsonString +
                '{'+
                '"method":"POST",'+
                '"url" : "/services/data/v45.0/sobjects/'+customObjNameList[i] +'__c",'+
                '"referenceId" :"'+customObjNameList[i]+'_Version1",'+
                '"body" : {"Name" : "' + customObjNameList[i] +'_Version1"}' +
                '}';
            if(i<customObjNameList.size()-1){
                jsonString = jsonString +
                    ',';
            }else{
                jsonString = jsonString +
                    ']'+
                    '}';
            }
        }
        return jsonString;
    }
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: Wrapper class to get response from createCustomRecord
    * Date: 24/4/2019
    */
    public class responseWrapper{
        Integer httpStatusCode;
        String referenceId;
        bodyWrapper body;
        headerWrapper httpHeaders;
        public responseWrapper(){
            body = new bodyWrapper();
            httpHeaders = new headerWrapper();
        }
    }
    public class bodyWrapper{
        String id;
        boolean success;
        List<errorWrapper> errors;
    }
    public class headerWrapper{
        String location;
    }
    public class errorWrapper{
        String statusCode;
        String message;
        List<String> fields;
    }
    public class compositeResponseWrapper{
        List<responseWrapper> compositeResponse;
    }
}