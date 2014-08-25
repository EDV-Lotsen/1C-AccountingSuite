Procedure zoho_ThisItem(action, Ref) Export
	 
	PathDef = "https://crm.zoho.com/crm/private/json/Products/";

	If action = "create" Then
		//taxable field needs to be string true or false
		If Ref.Taxable = True Then
			strTax = "true";
		Else
			strTax = "false";
		EndIf;
		
		ItemXML = "<Products>"
				+ "<row no=""1"">"
				+ "<FL val=""Product Name"">" + Ref.Description + "</FL>"
				+ "<FL val=""Product Code"">" + Ref.Code + "</FL>"
				+ "<FL val=""Taxable"">" + strTax + "</FL>"
				+ "<FL val =""Product Category"">" + Ref.Category.Ref.Description + "</FL>"
				+ "<FL val =""Unit Price"">" + StrReplace(String(Ref.Price),",","") + "</FL>"
				+ "<FL val =""Usage Unit"">" + Ref.UnitSet.DefaultReportUnit.Ref.Description + "</FL>"
				+ "</row>"
				+ "</Products>";
				
		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() +"&scope=crmapi&";
		
		URLstring = PathDef + "insertRecords?" + AuthHeader + "xmlData=" + ItemXML;
		
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring, ConnectionSettings).Result;
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
		ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
			
		newRecord = Catalogs.zoho_productCodeMap.CreateItem();
		newRecord.acs_api_code = Ref.Ref.UUID();
		newRecord.zoho_id = ResultBodyJSON.response.result.recorddetail.FL[0].content;
		newRecord.Write();
		
	EndIf;
	
	If action = "update" Then
		
		// using http request so no need for https:// anymore
		PathDef = "crm.zoho.com/crm/private/xml/Products/";
		
		//taxable field needs to be string true or false
		If Ref.Taxable = True Then
			strTax = "true";
		Else
			strTax = "false";
		EndIf;
		
		idQuery = new Query("SELECT
							|	zoho_productCodeMap.zoho_id
							|FROM
							|	Catalog.zoho_productCodeMap AS zoho_productCodeMap
							|WHERE
							|	zoho_productCodeMap.acs_api_code = &acs_api_code");
					   
		idQuery.SetParameter("acs_api_code", string(Ref.Ref.UUID()));
		queryResult = idQuery.Execute();
		queryResultobj = queryResult.Unload();
		
		zohoID = queryResultobj[0].zoho_id;
			
		ItemXML = "<Products>"
				+ "<row no=""1"">"
				+ "<FL val=""Product Name"">" + Ref.Description + "</FL>"
				+ "<FL val=""Product Code"">" + Ref.Code + "</FL>"
				+ "<FL val=""Taxable"">" + strTax + "</FL>"
				+ "<FL val =""Product Category"">" + Ref.Category.Ref.Description + "</FL>"
				+ "<FL val =""Unit Price"">" + StrReplace(String(Ref.Price),",","") + "</FL>"
				+ "<FL val =""Usage Unit"">" + Ref.UnitSet.DefaultReportUnit.Ref.Description + "</FL>"
				+ "</row>"
				+ "</Products>";

		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + zohoID;
			
		URLstring = PathDef + "updateRecords?" + AuthHeader + "&xmlData=" + ItemXML;
		
		HeadersMap = New Map();			
		HTTPRequest = New HTTPRequest("", HeadersMap);	
		SSLConnection = New OpenSSLSecureConnection();
		HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
		Result = HTTPConnection.Post(HTTPRequest);		
				
				
	EndIf; 
	
EndProcedure