/*
 * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
 * Description: Class to contain methods to create access token to another org
 * Date: 24/4/2019
 */
public class AP_CreateToken {
    private string cKey=Label.Consumer_key;
    private string cSecret=Label.Consumer_Secret;
    private string uName=Label.Username;
    private string passwd=Label.Password+Label.Security_Token;
    private string endpointUrl = Label.EndpointUrl;
    
    public class responseWrapper{
        
        public string id;
        public string access_token;
        public string instance_url;
        
    }
    
    public string getRequestToken(){
        string reqBody='grant_type=password&client_id='+cKey+'&client_secret='+cSecret+'&username='+uName+'&password='+passwd;                                    
        
        Http h=new Http();
        HttpRequest req=new HttpRequest();
        req.setBody(reqBody);
        req.setMethod('POST');
        req.setEndpoint(endpointUrl+'services/oauth2/token');
        
        HttpResponse hresp=h.send(req);
        responseWrapper wResp=(responseWrapper) JSON.deserialize(hresp.getBody(),responseWrapper.class);
        system.debug('Instance url: '+wResp.instance_url);
        system.debug('session id: '+wResp.access_token);
        return wResp.access_token;
    }
}