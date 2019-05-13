/*
 * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
 * Description: Class to contain methods to create custom objects
 * Date: 24/4/2019
 */
public class AP_CustomObjectCreation {
    final static string USERNAME = Label.Username;
    final static string PASSWORD = Label.Password+Label.Security_Token;
    final static string ENDPOINT_URL = Label.EndpointUrl;
    
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: get list of apexclass
    * Date: 24/4/2019
    */
    public static List<ApexClass> getApexClass(){
        List<ApexClass> apexClassList = new List<ApexClass>();
        apexClassList = [SELECT Id, Name, body
                         FROM ApexClass
                         WHERE Name ='AP_DummyClass'
                         LIMIT 3];
        return apexClassList;
    }
    
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: method to get session id from org
    * Arguments: return String sessionId
    * Date: 24/4/2019
    */
    public static String getSessionId(){
        partnerSoapSforceCom.Soap newSoap = new partnerSoapSforceCom.Soap();
        String newEndpoint = ENDPOINT_URL+'services/Soap/u/v45.0';
        newSoap.endpoint_x = newEndpoint;
        partnerSoapSforceCom.LoginResult sessionId = newSoap.login(USERNAME, PASSWORD);

        return sessionId.sessionId;
    }
    
   /*
    * Author: Shawn Son-kee shawn.lim.v.son-kee@accenture.com
    * Description: method to create custom objects
    * Date: 24/4/2019
    */
    public static void createCustomObject(){
        MetadataService.MetadataPort metadataservice = new MetadataService.MetadataPort();
        String newEndpoint = ENDPOINT_URL+'services/Soap/m/45.0';
        metadataservice.endpoint_x = newEndpoint;
        metadataservice .SessionHeader = new MetadataService.SessionHeader_element();
        metadataservice .SessionHeader.sessionId = getSessionId();

        List<String> insertedObjectList = new List<String>();
        
        List<MetadataService.CustomObject>  newMetadata = new List<MetadataService.CustomObject>();
        for(ApexClass apexList : getApexClass()){
            MetadataService.CustomObject customobject = new MetadataService.CustomObject();
            
            customobject.fullName = apexList.Name +'__c';
            customobject.label = apexList.Name;
            customobject.pluralLabel = apexList.Name+'s';
            
            customObject.nameField = new MetadataService.CustomField();
            customobject.nameField.type_x = 'Text';
            customobject.nameField.label = 'Name';
            customobject.deploymentStatus = 'Deployed';
            customObject.sharingModel = 'ReadWrite';
            newMetadata.add(customobject);
            insertedObjectList.add(apexList.Name);
        }
        if(newMetadata.size()>0){
            metadataservice.createMetadata(newMetadata);
            AP_CreateRecord.createCustomRecord(insertedObjectList);
        }
    }
}