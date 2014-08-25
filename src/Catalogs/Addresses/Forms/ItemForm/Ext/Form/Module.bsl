
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If NOT Object.Ref = Catalogs.Addresses.EmptyRef() Then
		Items.Owner.ReadOnly = True;
	EndIf;

	
	If Object.Owner.Vendor = True Then
		Items.RemitTo.Visible = True;
	Else
		Items.RemitTo.Visible = False;
	EndIf;
	
	CF1AName = Constants.CF1AName.Get();
	If CF1AName <> "" Then
		Items.CF1String.Title = CF1AName;
	EndIf;
	
	CF2AName = Constants.CF2AName.Get();
	If CF2AName <> "" Then
		Items.CF2String.Title = CF2AName;
	EndIf;

	CF3AName = Constants.CF3AName.Get();
	If CF3AName <> "" Then
		Items.CF3String.Title = CF3AName;
	EndIf;

	
	CF4AName = Constants.CF4AName.Get();
	If CF4AName <> "" Then
		Items.CF4String.Title = CF4AName;
	EndIf;

	CF5AName = Constants.CF5AName.Get();
	If CF5AName <> "" Then
		Items.CF5String.Title = CF5AName;
	EndIf;
	
EndProcedure

&AtClient
Procedure DefaultBillingOnChange(Item)
	DefaultBillingOnChangeAtServer();
EndProcedure

&AtServer
Procedure DefaultBillingOnChangeAtServer()
	
	billQuery = New Query("SELECT
	         | Addresses.Ref
	         |FROM
	         | Catalog.Addresses AS Addresses
	         |WHERE
	         | Addresses.DefaultBilling = TRUE
	         | AND Addresses.Owner.Ref = &Ref");
	 billQuery.SetParameter("Ref", object.Owner.Ref);     
	 billResult = billQuery.Execute();
	 addr = billResult.Unload();
	 
	 If (NOT billResult.IsEmpty()) AND object.DefaultBilling = True AND addr[0].Ref <> object.Ref Then
	  Message("Another address is already set as the default billing address.");
	  object.DefaultBilling = False;
  EndIf;
  
EndProcedure

&AtClient
Procedure DefaultShippingOnChange(Item)
	DefaultShippingOnChangeAtServer();
EndProcedure

&AtServer
Procedure DefaultShippingOnChangeAtServer()
	
	shipQuery = New Query("SELECT
	         | Addresses.Ref
	         |FROM
	         | Catalog.Addresses AS Addresses
	         |WHERE
	         | Addresses.DefaultShipping = TRUE
	         | AND Addresses.Owner.Ref = &Ref");
	       
	 shipQuery.SetParameter("Ref", object.Owner.Ref);
	 shipResult = shipQuery.Execute();
	 addr = shipResult.Unload();
	 
	 If (NOT shipResult.IsEmpty()) AND object.DefaultShipping = True AND addr[0].Ref <> object.Ref Then
	  Message("Another address is already set as the default shipping address.");
	  object.DefaultShipping = False;
  EndIf;
  
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If NOT Object.Ref = Catalogs.Addresses.EmptyRef() Then
		Items.Owner.ReadOnly = True;
	EndIf;
	
	////  create account in zoho and contact
	//If Constants.zoho_auth_token.Get() <> "" Then
	//	If Object.NewObject = True Then
	//		ThisAction = "create";
	//	Else
	//		ThisAction = "update";
	//	EndIf;
	//	ZohoThisContact(ThisAction);
	//	If Object.DefaultBilling = True Then		
	//		SetZohoDefaultBilling();	
	//	EndIf;
	//	If Object.DefaultShipping = True Then		
	//		SetZohoDefaultShipping();	
	//	EndIf;
	//EndIf;

EndProcedure


//Procedure SetZohoDefaultBilling()
//	
//	idQuery = new Query("SELECT
//							|	zoho_accountCodeMap.zoho_id
//							|FROM
//							|	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
//							|WHERE
//							|	zoho_accountCodeMap.acs_api_code = &acs_api_code");
//					   
//	idQuery.SetParameter("acs_api_code", string(Object.Owner.Ref.UUID()));
//	queryResult = idQuery.Execute();
//	If NOT queryResult.IsEmpty() Then
//		queryResultobj = queryResult.Unload();
//		zohoID = queryResultobj[0].zoho_id;
//	
//		PathDef = "crm.zoho.com/crm/private/xml/Accounts/";
//		billstreet = Object.AddressLine1;
//		If Object.AddressLine2 <> "" Then
//			billstreet = billstreet + ", " + Object.AddressLine2;
//		EndIf;
//		If Object.AddressLine3 <> "" Then
//			billstreet = billstreet + ", " + Object.AddressLine3;
//		EndIf;
//		AccountXML = "<Accounts>"
//			+ "<row no=""1"">"
//			+ "<FL val=""Billing Street"">" + billstreet + "</FL>"
//			+ "<FL val=""Billing City"">" + Object.City + "</FL>"
//			+ "<FL val=""Billing State"">" + String(Object.State) + "</FL>"
//			+ "<FL val=""Billing Code"">" + Object.ZIP + "</FL>"
//			+ "<FL val=""Billing Country"">" + String(Object.Country) + "</FL>"
//			+ "<FL val=""Fax"">" + Object.Fax + "</FL>"
//			+ "<FL val=""Phone"">" + Object.Phone + "</FL>"
//			+ "</row>"
//			+ "</Accounts>";

//		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + zohoID;
//			
//		URLstring = PathDef + "updateRecords?" + AuthHeader + "&xmlData=" + AccountXML;
//		
//		HeadersMap = New Map();			
//		HTTPRequest = New HTTPRequest("", HeadersMap);	
//		SSLConnection = New OpenSSLSecureConnection();
//		HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
//		Result = HTTPConnection.Post(HTTPRequest);
//	EndIf;
//	
//EndProcedure

//Procedure SetZohoDefaultShipping()
//	
//	idQuery = new Query("SELECT
//							|	zoho_accountCodeMap.zoho_id
//							|FROM
//							|	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
//							|WHERE
//							|	zoho_accountCodeMap.acs_api_code = &acs_api_code");
//					   
//	idQuery.SetParameter("acs_api_code", string(Object.Owner.Ref.UUID()));
//	queryResult = idQuery.Execute();
//	If NOT queryResult.IsEmpty() Then
//		queryResultobj = queryResult.Unload();
//		zohoID = queryResultobj[0].zoho_id;
//	
//		PathDef = "crm.zoho.com/crm/private/xml/Accounts/";
//		shipstreet = Object.AddressLine1;
//		If Object.AddressLine2 <> "" Then
//			shipstreet = shipstreet + ", " + Object.AddressLine2;
//		EndIf;
//		If Object.AddressLine3 <> "" Then
//			shipstreet = shipstreet + ", " + Object.AddressLine3;
//		EndIf;
//		AccountXML = "<Accounts>"
//			+ "<row no=""1"">"
//			+ "<FL val=""Shipping Street"">" + shipstreet + "</FL>"
//			+ "<FL val=""Shipping City"">" + Object.City + "</FL>"
//			+ "<FL val=""Shipping State"">" + String(Object.State) + "</FL>"
//			+ "<FL val=""Shipping Code"">" + Object.ZIP + "</FL>"
//			+ "<FL val=""Shipping Country"">" + String(Object.Country) + "</FL>"
//			+ "</row>"
//			+ "</Accounts>";

//		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + zohoID;
//			
//		URLstring = PathDef + "updateRecords?" + AuthHeader + "&xmlData=" + AccountXML;
//		
//		HeadersMap = New Map();			
//		HTTPRequest = New HTTPRequest("", HeadersMap);	
//		SSLConnection = New OpenSSLSecureConnection();
//		HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
//		Result = HTTPConnection.Post(HTTPRequest);
//	EndIf;
//	
//	EndProcedure

//Procedure ZohoThisContact(action)
//	PathDef = "https://crm.zoho.com/crm/private/json/Contacts/";
//	
//	If action = "create" Then
//		
//		strStreet = Object.AddressLine1;
//		If Object.AddressLine2 <> "" Then
//			strStreet = strStreet + ", " + Object.AddressLine2;
//		EndIf;
//		If Object.AddressLine3 <> "" Then
//			strStreet = strStreet + ", " + Object.AddressLine3;
//		EndIf;
//		
//		//zoho requires a last name for contacts
//		If Object.LastName = "" Then
//			strLastName = Object.Description;
//		Else
//			strLastName = Object.LastName;
//		EndIf;
//		
//		idQuery = new Query("SELECT
//							|	zoho_accountCodeMap.zoho_id
//							|FROM
//							|	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
//							|WHERE
//							|	zoho_accountCodeMap.acs_api_code = &acs_api_code");
//					   
//		idQuery.SetParameter("acs_api_code", string(Object.Owner.Ref.UUID()));
//		queryResult = idQuery.Execute().Unload();
//			
//		ContactXML = "<Contacts>"
//				+ "<row no=""1"">"
//				+ "<FL val=""Salutation"">" + Object.Salutation + "</FL>"
//				+ "<FL val=""First Name"">" + Object.FirstName + "</FL>"
//				+ "<FL val=""Last Name"">" + strLastName + "</FL>"
//				+ "<FL val=""Description"">" + Object.Notes + "</FL>"
//				+ "<FL val=""Email"">" + Object.Email + "</FL>"
//				+ "<FL val=""Fax"">" + Object.Fax + "</FL>"
//				+ "<FL val=""Mobile"">" + Object.Cell + "</FL>"
//				+ "<FL val=""Phone"">" + Object.Phone + "</FL>"
//				+ "<FL val=""Title"">" + Object.JobTitle + "</FL>"
//				+ "<FL val=""Department"">" + Object.CF1String + "</FL>" //ferguson department
//				+ "<FL val=""Mailing Street"">" + strStreet + "</FL>"
//				+ "<FL val=""Mailing City"">" + Object.City + "</FL>"
//				+ "<FL val=""Mailing State"">" + String(Object.State) + "</FL>"
//				+ "<FL val=""Mailing Zip"">" + Object.Zip + "</FL>"
//				+ "<FL val=""Mailing Country"">" + String(Object.Country) + "</FL>"
//				+ "<FL val=""ACCOUNTID"">" + queryResult[0].zoho_id + "</FL>"
//				+ "</row>"
//				+ "</Contacts>";
//				
//		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() +"&scope=crmapi&";
//		
//		URLstring = PathDef + "insertRecords?" + AuthHeader + "xmlData=" + ContactXML;
//		
//		ConnectionSettings = New Structure;
//		Connection = InternetConnectionClientServer.CreateConnection(URLstring, ConnectionSettings).Result;
//		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
//		ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
//			
//		newRecord = Catalogs.zoho_contactCodeMap.CreateItem();
//		newRecord.acs_api_code = Object.Ref.UUID();
//		newRecord.zoho_id = ResultBodyJSON.response.result.recorddetail.FL[0].content;
//		newRecord.Write();
//		
//	EndIf;
//	
//	If action = "update" Then //AND Object.Description <> "Primary" Then
//		
//		// using http request so no need for https:// anymore
//		PathDef = "crm.zoho.com/crm/private/xml/Contacts/";
//		
//		strStreet = Object.AddressLine1;
//		If Object.AddressLine2 <> "" Then
//			strStreet = strStreet + ", " + Object.AddressLine2;
//		EndIf;
//		If Object.AddressLine3 <> "" Then
//			strStreet = strStreet + ", " + Object.AddressLine3;
//		EndIf;

//		If Object.LastName = "" Then
//			strLastName = Object.Description;
//		Else
//			strLastName = Object.LastName;
//		EndIf;
//		
//		idQuery = new Query("SELECT
//							|	zoho_contactCodeMap.zoho_id
//							|FROM
//							|	Catalog.zoho_contactCodeMap AS zoho_contactCodeMap
//							|WHERE
//							|	zoho_contactCodeMap.acs_api_code = &acs_api_code");
//					   
//		idQuery.SetParameter("acs_api_code", string(Object.Ref.UUID()));
//		queryResult = idQuery.Execute();
//		queryResultobj = queryResult.Unload();
//					
//		zohoID = queryResultobj[0].zoho_id;
//		
//		idQuery = new Query("SELECT
//							|	zoho_accountCodeMap.zoho_id
//							|FROM
//							|	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
//							|WHERE
//							|	zoho_accountCodeMap.acs_api_code = &acs_api_code");
//					   
//		idQuery.SetParameter("acs_api_code", string(Object.Owner.Ref.UUID()));
//		queryResult = idQuery.Execute().Unload();
//					
//		ContactXML = "<Contacts>"
//				+ "<row no=""1"">"
//				+ "<FL val=""Salutation"">" + Object.Salutation + "</FL>"
//				+ "<FL val=""First Name"">" + Object.FirstName + "</FL>"
//				+ "<FL val=""Last Name"">" + strLastName + "</FL>"
//				+ "<FL val=""Description"">" + Object.Notes + "</FL>"
//				+ "<FL val=""Email"">" + Object.Email + "</FL>"
//				+ "<FL val=""Fax"">" + Object.Fax + "</FL>"
//				+ "<FL val=""Mobile"">" + Object.Cell + "</FL>"
//				+ "<FL val=""Phone"">" + Object.Phone + "</FL>"
//				+ "<FL val=""Title"">" + Object.JobTitle + "</FL>"
//				+ "<FL val=""Department"">" + Object.CF1String + "</FL>" //ferguson department
//				+ "<FL val=""Mailing Street"">" + strStreet + "</FL>"
//				+ "<FL val=""Mailing City"">" + Object.City + "</FL>"
//				+ "<FL val=""Mailing State"">" + String(Object.State) + "</FL>"
//				+ "<FL val=""Mailing Zip"">" + Object.Zip + "</FL>"
//				+ "<FL val=""Mailing Country"">" + String(Object.Country) + "</FL>"
//				+ "<FL val=""ACCOUNTID"">" + queryResult[0].zoho_id + "</FL>"
//				+ "</row>"
//				+ "</Contacts>";

//		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + zohoID;
//			
//		URLstring = PathDef + "updateRecords?" + AuthHeader + "&xmlData=" + ContactXML;
//		
//		HeadersMap = New Map();			
//		HTTPRequest = New HTTPRequest("", HeadersMap);	
//		SSLConnection = New OpenSSLSecureConnection();
//		HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
//		Result = HTTPConnection.Post(HTTPRequest);		
//				
//			//ConnectionSettings = New Structure;
//			//Connection = InternetConnectionClientServer.CreateConnection(URLstring, ConnectionSettings).Result;
//			//ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
//			//ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
//				
//			//RunApp(URLstring);
//		//EndIf;
//				
//	EndIf; 	
//EndProcedure




