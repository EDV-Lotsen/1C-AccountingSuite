


Procedure ZohoThisPriceLevel(action)
	PathDef = "https://crm.zoho.com/crm/private/json/PriceBooks/";
	
	If action = "create" Then
			
		PBXML = "<PriceBooks>"
				+ "<row no=""1"">"
				+ "<FL val=""Price Book Name"">" + Object.Description + "</FL>"
				+ "</row>"
				+ "</PriceBooks>";
				
		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() +"&scope=crmapi&";
		
		URLstring = PathDef + "insertRecords?" + AuthHeader + "xmlData=" + PBXML;
		
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring, ConnectionSettings).Result;
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
		ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
			
		newRecord = Catalogs.zoho_pricebookCodeMap.CreateItem();
		newRecord.acs_api_code = Object.Ref.UUID();
		newRecord.zoho_id = ResultBodyJSON.response.result.recorddetail.FL[0].content;
		newRecord.Write();
		
	EndIf;
	
	If action = "update" Then
		
		// using http request so no need for https:// anymore
		PathDef = "crm.zoho.com/crm/private/xml/PriceBooks/";
		
		
		idQuery = new Query("SELECT
							|	zoho_pricebookCodeMap.zoho_id
							|FROM
							|	Catalog.zoho_pricebookCodeMap AS zoho_pricebookCodeMap
							|WHERE
							|	zoho_pricebookCodeMap.acs_api_code = &acs_api_code");
					   
		idQuery.SetParameter("acs_api_code", string(Object.Ref.UUID()));
		queryResult = idQuery.Execute();
		queryResultobj = queryResult.Unload();
		
		zohoID = queryResultobj[0].zoho_id;
						
		PBXML = "<PriceBooks>"
				+ "<row no=""1"">"
				+ "<FL val=""Price Book Name"">" + Object.Description + "</FL>"
				+ "</row>"
				+ "</PriceBooks>";

		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + zohoID;
			
		URLstring = PathDef + "updateRecords?" + AuthHeader + "&xmlData=" + PBXML;
		
		HeadersMap = New Map();			
		HTTPRequest = New HTTPRequest("", HeadersMap);	
		SSLConnection = New OpenSSLSecureConnection();
		HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
		Result = HTTPConnection.Post(HTTPRequest);		
								
	EndIf; 	
EndProcedure


&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	//  create price book in zoho
	If Constants.zoho_auth_token.Get() <> "" Then
		If Object.NewObject = True Then
			ThisAction = "create";
		Else
			ThisAction = "update";
		EndIf;
		ZohoThisPriceLevel(ThisAction);                                                          
	EndIf;

EndProcedure

