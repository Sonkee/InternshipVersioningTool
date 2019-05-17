/*
 * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
 * Description: Class to contain methods for Push functionality
 * Date: 13/05/2019
 */
public class AP_PushSetting {
    final static String ENDPOINT_URL = Label.EndpointUrl;
    final static String SEPARATION_STRING = 'A_RANDOM_STRING';
    /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: 
    * Arguments: String apexType, Id apexId
    * Date: 13/05/2019
    */
    public static void getClassName(String apexType, Id apexId){
        String queryStr = 'SELECT Id, Name, Body FROM '+apexType+' WHERE Id=\''+apexId+'\' limit 1';
        //01p26000000d8ZYAAY
        //06825000000GEVmAAO
        
        List<SObject> sObjectList = new List<SObject>();
        sObjectList = Database.query(queryStr);
        Schema.SObjectType sObjectType = sObjectList.getSObjectType();
        
        if (sObjectType == ApexClass.sObjectType){
            List<ApexClass> apexList = new List<ApexClass>();
            apexList = (List<ApexClass>)sObjectList;
            System.debug('Name and body: '+apexList[0].Name+', '+apexList[0].body);
            createNewVersion(apexList[0].Name,apexList[0].body);
        }else if (sObjectType == ApexTrigger.sObjectType){
            List<ApexTrigger> triggerList = new List<ApexTrigger>();
            triggerList = (List<ApexTrigger>)sObjectList;
            createNewVersion(triggerList[0].Name,triggerList[0].body);
        }
    }
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: Method to create new version(file and records) of code
    * Arguments: String className, String codeBody
    * Date: 14/05/2019
    */
    public static void createNewVersion(String className, String codeBody){
        String latestVersion = getLatestVersion(className);
        //from latest version, add one to it
        String versionNum = latestVersion.substringAfter('Version');
        Integer newIntVersion = integer.valueOf(versionNum)+1;
        String newVersion = String.valueOf(newIntVersion);
        
        String fileId = createNewVersionFile(className,newVersion,codeBody);
        //get contentDocumentId and create new version record
        System.debug('fileId and name:'+fileId+', '+className);
        
        String contentDocumentId;
        String recordId;
        String responseJs = createRecord(className,fileId);
        CompositeWrapper responseWrap = (CompositeWrapper)Json.deserialize(responseJs, CompositeWrapper.class);
        for(CompositeResponseWrapper bodyList : responseWrap.compositeResponse){
            if(bodyList.referenceId=='NewFileInfo'){
                contentDocumentId = bodyList.body.ContentDocumentId;
            }
            if(bodyList.referenceId=='NewRecord'){
                recordId = bodyList.body.Id;
            }
        }
        System.debug('contentDocumentId:'+contentDocumentId+', recordId: '+recordId);
        if(contentDocumentId!=null && recordId!=null){
            createNewLink(contentDocumentId,recordId);
        }
    }
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: Method to query all records for Object ClassName via http request
    * Arguments: String className
    * Return: String latest Version record name
    * Date: 13/05/2019
    */
    public static String getLatestVersion(String className){
        String queryStr = 'SELECT Id, Name, CreatedDate FROM '+className+'__c ORDER BY CreatedDate DESC LIMIT 1';
        String encoded = EncodingUtil.urlEncode(queryStr, 'UTF-8');
        
        String reqEndpoint = ENDPOINT_URL+'services/data/v45.0/query?q='+encoded;
        string accToken;
        AP_CreateToken tokenClass = new AP_CreateToken();
        accToken = tokenClass.getRequestToken();
        
        String recordName;
        if(accToken!=''){
            HttpRequest req = new HttpRequest();
            req.setEndpoint(reqEndpoint);
            req.setMethod('GET');
            req.setHeader('Authorization','Bearer '+accToken);
            
            Http httpReq = new Http();
            HttpResponse res = httpReq.send(req);
            String jsonResponse = res.getBody();
            queryReturnResponseWrapper QRRW = (queryReturnResponseWrapper)Json.deserialize(jsonResponse, queryReturnResponseWrapper.class);
            recordName = QRRW.records[0].Name;
        }
        return recordName;
    }
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: Wrapper class to get query response from getAllVersions method
    * Date: 14/05/2019
    */
    public class attributesWrapper {
        string type;
        string url;
    }
    public class recordWrapper {
        attributesWrapper attributes;
        String Name;
        String Id;
        String CreatedDate;
        public recordWrapper (){
            attributes = new attributesWrapper();
        }
    }
    public class queryReturnResponseWrapper{
        String done;
        String totalSize;
        list<recordWrapper> records ;
    }
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: Method to create new version(file only) of code
    * Arguments: String className, String versionNumber, String codeBody
    * Return: Id of file
    * Date: 14/05/2019
    */
    public static Id createNewVersionFile(String className, String versionNumber, String codeBody){
        String reqEndpoint = ENDPOINT_URL+'services/data/v45.0/sobjects/ContentVersion';
        string accToken;
        AP_CreateToken tokenClass = new AP_CreateToken();
        accToken = tokenClass.getRequestToken();
        Id contentVersionId;
        if(accToken!=''){
            HttpRequest req = new HttpRequest();
            req.setEndpoint(reqEndpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'multipart/form-data; boundary=' + SEPARATION_STRING);
            req.setHeader('Authorization','Bearer '+accToken);
            
            String header = '--'+ SEPARATION_STRING + '\nContent-Disposition: form-data; name="entity_content";\nContent-Type: application/json\n\n';
            String jsonBody = '{\n'+
            	'"PathOnClient" : "'+className+'_Version'+versionNumber+'.txt"\n'+
                '}\n\n';
            String jsonStringDown = '--'+ SEPARATION_STRING +
                '\nContent-Type: text/plain\n'+
                'Content-Disposition: form-data; name="VersionData"; filename="'+className+'_Version'+versionNumber+'.txt"\n\n' +
                codeBody+'\n\n'+
                '--'+ SEPARATION_STRING +'--';
            String jsonString = header + jsonBody + jsonStringDown;
            System.debug('new version file, jsonString:'+jsonString);
            req.setBody(jsonString);
            
            Http httpReq = new Http();
            HttpResponse res = httpReq.send(req);
            String jsonResponse = res.getBody();
            System.debug('new version file:'+jsonResponse);
            responseWrapper responseWrap = (responseWrapper)Json.deserialize(jsonResponse, responseWrapper.class);
            if(responseWrap.success ==true){
                contentVersionId = responseWrap.Id;
            }
        }
        return contentVersionId;
    }
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: Wrapper Class for http response from createNewVersionFile method
    * Date: 14/05/2019
    */
    public class responseWrapper{
        String Id;
        boolean success;
    }
    
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: Method to get contentDocumentId and create new record
    * Arguments: String className, String fileId
    * Date: 14/05/2019
    */
    public static String createRecord(String className, String fileId){
        String reqEndpoint = ENDPOINT_URL+'services/data/v45.0/composite';
        string accToken;
        String responseJson;
        AP_CreateToken tokenClass = new AP_CreateToken();
        accToken = tokenClass.getRequestToken();
        
        if(accToken!=''){
            HttpRequest req = new HttpRequest();
            req.setEndpoint(reqEndpoint);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization','Bearer '+accToken);
            req.setMethod('POST');
            String jsonGen = createRecordJsonGen(className,fileId);
            req.setBody(jsonGen);
            
            Http httpReq = new Http();
            HttpResponse res = httpReq.send(req);
            responseJson = res.getBody();
        }
        return responseJson;
    }
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: Method to create the JSON body for method createRecord
    * Arguments: String className, String fileId
    * Date: 14/05/2019
    */
    public static String createRecordJsonGen(String className, String fileId){
        String jsonStr =
            '{"allOrNone" : true,\n'+
            '"compositeRequest" : [{\n'+
            '"method" : "GET",\n'+
            '"referenceId" : "NewFileInfo",\n'+
            '"url" : "/services/data/v45.0/sobjects/ContentVersion/'+fileId+'"\n'+
            '},{\n'+
            '"method" : "POST",\n'+
            '"url" : "/services/data/v45.0/sobjects/'+className+'__c",\n'+
            '"referenceId" : "NewRecord",\n'+
            '"body" : {\n'+
            '"Name" : "@{NewFileInfo.Title}"\n'+
            '}\n'+
            '}]\n'+
            '}';
        return jsonStr;
    }
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: Wrapper class to get http response from method createRecord
    * Date: 17/05/2019
    */
    public class bodyWrapper{
        String Id;
        String Name;
        String ContentDocumentId;
        String title;
    }
    public class CompositeResponseWrapper{
        String referenceId;
        Integer httpStatusCode;
        AP_PushSetting.bodyWrapper body;
        public CompositeResponseWrapper(){
            body =  new AP_PushSetting.bodyWrapper();
        }
        
    }
    public class CompositeWrapper{
        List<CompositeResponseWrapper> compositeResponse;
    }
    /*
    public static void dummyMethod(){
        String contentDocumentId;
        String recordId;
        String responseJs = createRecord('AP_DummyClass','06825000000GEVmAAO');
        CompositeWrapper responseWrap = (CompositeWrapper)Json.deserialize(responseJs, CompositeWrapper.class);
        for(CompositeResponseWrapper bodyList : responseWrap.compositeResponse){
            if(bodyList.referenceId=='NewFileInfo'){
                contentDocumentId = bodyList.body.ContentDocumentId;
            }
            if(bodyList.referenceId=='NewRecord'){
                recordId = bodyList.body.Id;
            }
        }
        if(!String.isEmpty(contentDocumentId) && !String.isEmpty(recordId)){
            createNewLink(contentDocumentId,recordId);
        }
    }*/
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: Wrapper class to get http response from method createRecord
    * Date: 17/05/2019
    */
    public static void createNewLink(String contentDocumentId, String recordId){
        String reqEndpoint = ENDPOINT_URL+'services/data/v45.0/sobjects/ContentDocumentLink';
        string accToken;
        String responseJson;
        AP_CreateToken tokenClass = new AP_CreateToken();
        accToken = tokenClass.getRequestToken();
        
        if(accToken!=''){
            HttpRequest req = new HttpRequest();
            req.setEndpoint(reqEndpoint);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization','Bearer '+accToken);
            req.setMethod('POST');
            req.setBody(createLinkJSONBody(contentDocumentId,recordId));
            
            Http httpReq = new Http();
            HttpResponse res = httpReq.send(req);
            responseJson = res.getBody();
            System.debug('createNewLink: '+responseJson);
        }
    }
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: Method to generate body for request in method createNewLink
    * Date: 17/05/2019
    */
    public static String createLinkJSONBody(String contentDocumentId, String recordId){
        String jsonBody = 
            '{\n'+
            '"ContentDocumentId" : "'+contentDocumentId+'",\n'+
            '"LinkedEntityId" : "'+recordId+'",\n'+
            '"ShareType" : "V"\n'+
            '}';
        System.debug('jsonBody(create link): '+jsonBody);
        return jsonBody;
    }
}