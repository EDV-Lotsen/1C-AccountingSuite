Function ZohoJSONParser(InfoArray) Export
	ZohoData = New Map();
	
	For Each fl in InfoArray Do
		If fl.val = "Product Details" Then // this portion for Sales Orders
			ZohoLineItems = New Array();
	        Try
				For Each item in FL.product Do
					ZohoLineItemsData = New Map();
						For Each fl in item.FL Do
							ZohoLineItemsData.Insert(fl.val,fl.content);
						EndDo;
					ZohoLineItems.Add(ZohoLineItemsData);
				EndDo;
			Except
				ZohoLineItemsData2 = New Map();
					For Each fl in FL.product.FL Do
						ZohoLineItemsData2.Insert(fl.val,fl.content);
					EndDo;
				ZohoLineItems.Add(ZohoLineItemsData2);
			EndTry;
			
			ZohoData.Insert("Product Details", ZohoLineItems);
		Else
			ZohoData.Insert(fl.val,fl.content);
		EndIf;
		
	EndDo;	

	Return ZohoData;
EndFunction

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
				+ "<FL val=""Product Name"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Description) + "</FL>"
				+ "<FL val=""Product Code"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Code) + "</FL>"
				+ "<FL val=""Taxable"">" + zoho_Functions.Zoho_XMLEncoding(strTax) + "</FL>"
				+ "<FL val =""Product Category"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Category.Ref.Description) + "</FL>"
				+ "<FL val =""Unit Price"">" + zoho_Functions.Zoho_XMLEncoding(StrReplace(String(Ref.Price),",","")) + "</FL>"
				+ "<FL val =""Usage Unit"">" + zoho_Functions.Zoho_XMLEncoding(Ref.UnitSet.DefaultReportUnit.Ref.Description) + "</FL>"
				+ "</row>"
				+ "</Products>";
				
		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() +"&scope=crmapi&";
		
		URLstring = PathDef + "insertRecords?" + AuthHeader + "xmlData=" + ItemXML;
		
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring, ConnectionSettings).Result;
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
		ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
			
		newRecord = Catalogs.zoho_productCodeMap.CreateItem();
		newRecord.product_ref = Ref.Ref;
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
		                    |	zoho_productCodeMap.product_ref = &product_ref");
					   
		idQuery.SetParameter("product_ref", Ref.Ref );
		queryResult = idQuery.Execute();
		queryResultobj = queryResult.Unload();
		
		If queryResult.IsEmpty() Then
			zoho_ThisItem("create", Ref);
			Return;
		EndIf;
		
		zohoID = queryResultobj[0].zoho_id;
			
		ItemXML = "<Products>"
				+ "<row no=""1"">"
				+ "<FL val=""Product Name"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Description) + "</FL>"
				+ "<FL val=""Product Code"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Code) + "</FL>"
				+ "<FL val=""Taxable"">" + zoho_Functions.Zoho_XMLEncoding(strTax) + "</FL>"
				+ "<FL val =""Product Category"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Category.Ref.Description) + "</FL>"
				+ "<FL val =""Unit Price"">" + zoho_Functions.Zoho_XMLEncoding(StrReplace(String(Ref.Price),",","")) + "</FL>"
				+ "<FL val =""Usage Unit"">" + zoho_Functions.Zoho_XMLEncoding(Ref.UnitSet.DefaultReportUnit.Ref.Description) + "</FL>"
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

Procedure zoho_ThisPriceLevel(action, Ref) Export
	PathDef = "https://crm.zoho.com/crm/private/json/PriceBooks/";
	
	If action = "create" Then
			
		PBXML = "<PriceBooks>"
				+ "<row no=""1"">"
				+ "<FL val=""Price Book Name"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Description) + "</FL>"
				+ "</row>"
				+ "</PriceBooks>";
				
		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() +"&scope=crmapi&";
		
		URLstring = PathDef + "insertRecords?" + AuthHeader + "xmlData=" + PBXML;
		
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring, ConnectionSettings).Result;
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
		ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
			
		newRecord = Catalogs.zoho_pricebookCodeMap.CreateItem();
		newRecord.pricelevel_ref = Ref.Ref;
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
		                    |	zoho_pricebookCodeMap.pricelevel_ref = &pricelevel_ref");
					   
		idQuery.SetParameter("pricelevel_ref", Ref.Ref);
		queryResult = idQuery.Execute();
		queryResultobj = queryResult.Unload();
		
		If queryResult.IsEmpty() Then
			//no record must create price level
			PathDef = "https://crm.zoho.com/crm/private/json/PriceBooks/";
			
			PBXML = "<PriceBooks>"
				+ "<row no=""1"">"
				+ "<FL val=""Price Book Name"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Description) + "</FL>"
				+ "</row>"
				+ "</PriceBooks>";
				
			AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() +"&scope=crmapi&";
			
			URLstring = PathDef + "insertRecords?" + AuthHeader + "xmlData=" + PBXML;
			
			ConnectionSettings = New Structure;
			Connection = InternetConnectionClientServer.CreateConnection(URLstring, ConnectionSettings).Result;
			ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
			ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
				
			newRecord = Catalogs.zoho_pricebookCodeMap.CreateItem();
			newRecord.pricelevel_ref = Ref.Ref;
			newRecord.zoho_id = ResultBodyJSON.response.result.recorddetail.FL[0].content;
			newRecord.Write();
			
		Else
		
			zohoID = queryResultobj[0].zoho_id;
							
			PBXML = "<PriceBooks>"
					+ "<row no=""1"">"
					+ "<FL val=""Price Book Name"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Description) + "</FL>"
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
								
	EndIf; 	
EndProcedure

Procedure zoho_UpdatePricebook(PriceLevel, Product, Price) Export

	// using http request so no need for https:// anymore
	PathDef = "crm.zoho.com/crm/private/xml/PriceBooks/";
	
	idQuery = new Query("SELECT
						|	zoho_pricebookCodeMap.zoho_id
						|FROM
						|	Catalog.zoho_pricebookCodeMap AS zoho_pricebookCodeMap
						|WHERE
						|	zoho_pricebookCodeMap.pricelevel_ref = &pricelevel_ref");
				   
	idQuery.SetParameter("pricelevel_ref", PriceLevel.Ref);
	queryResult = idQuery.Execute();
	queryResultobj = queryResult.Unload();
	
	zohoID = queryResultobj[0].zoho_id;
	
	itemQuery = new Query("SELECT
	                      |	zoho_productCodeMap.zoho_id
	                      |FROM
	                      |	Catalog.zoho_productCodeMap AS zoho_productCodeMap
	                      |WHERE
	                      |	zoho_productCodeMap.product_ref = &product_ref");
				   
	itemQuery.SetParameter("product_ref", Product.Ref);
	queryResult = itemQuery.Execute();
	queryResultobj = queryResult.Unload();
	productID = queryResultobj[0].zoho_id;
					
	ProductXML = "<Products>"
			+ "<row no=""1"">"
			+ "<FL val=""PRODUCTID"">" + productID + "</FL>"
			+ "<FL val=""list_price"">" + zoho_Functions.Zoho_XMLEncoding(StrReplace(String(Price),",","")) + "</FL>"
			+ "</row>"
			+ "</Products>";

	AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + zohoID
					+ "&relatedModule=Products";
		
	URLstring = PathDef + "updateRelatedRecords?" + AuthHeader + "&xmlData=" + ProductXML;
	
	HeadersMap = New Map();			
	HTTPRequest = New HTTPRequest("", HeadersMap);	
	SSLConnection = New OpenSSLSecureConnection();
	HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
	Result = HTTPConnection.Post(HTTPRequest);

	
EndProcedure

Procedure zoho_ThisAccount(action, Ref) Export
	
	////// 
	PathDef = "https://crm.zoho.com/crm/private/json/Accounts/";
	
	If action = "create" Then
		
		AccountXML = "<Accounts>"
				+ "<row no=""1"">"
				+ "<FL val=""Account Name"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Description) + "</FL>"
				+ "<FL val=""Account Number"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Code) + "</FL>"
				+ "<FL val=""Account Type"">" + "Customer" + "</FL>"
				+ "<FL val=""Description"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Notes) + "</FL>"
				+ "<FL val=""Website"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Website) + "</FL>"
				+ "</row>"
				+ "</Accounts>";
				
		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() +"&scope=crmapi&";
		
		URLstring = PathDef + "insertRecords?" + AuthHeader + "xmlData=" + AccountXML;
		
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring, ConnectionSettings).Result;
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
		ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
			
		newRecord = Catalogs.zoho_accountCodeMap.CreateItem();
		newRecord.company_ref = Ref.Ref;
		newRecord.zoho_id = ResultBodyJSON.response.result.recorddetail.FL[0].content;
		newRecord.Write();
		
	EndIf;
	
	If action = "update" Then
		
		// using http request so no need for https:// anymore
		PathDef = "crm.zoho.com/crm/private/xml/Accounts/";
						
		idQuery = new Query("SELECT
		                    |	zoho_accountCodeMap.zoho_id
		                    |FROM
		                    |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
		                    |WHERE
		                    |	zoho_accountCodeMap.company_ref = &company_ref");
					   
		idQuery.SetParameter("company_ref", Ref.Ref);
		queryResult = idQuery.Execute();
		queryResultobj = queryResult.Unload();
		
		If queryResult.IsEmpty() Then
			zoho_ThisAccount("create", Ref);
			contactQuery = New Query("SELECT
			                         |	Addresses.Ref
			                         |FROM
			                         |	Catalog.Addresses AS Addresses
			                         |WHERE
			                         |	Addresses.Owner = &Ref
			                         |	AND Addresses.DefaultBilling = FALSE
			                         |	AND Addresses.DefaultShipping = FALSE");	
			contactQuery.SetParameter("Ref", Ref.Ref);
			contactResult = contactQuery.Execute();
			If NOT contactResult.IsEmpty() Then
				contactlist = contactResult.Unload();
				For i = 0 to contactlist.Count() - 1 Do
					zoho_Functions.ZohoThisContact("create", contactlist[i].Ref);
				EndDo;
			EndIf;
			Return;
		EndIf;
		
		zohoID = queryResultobj[0].zoho_id;
					
		AccountXML = "<Accounts>"
				+ "<row no=""1"">"
				+ "<FL val=""Account Name"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Description) + "</FL>"
				+ "<FL val=""Account Number"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Code) + "</FL>"
				+ "<FL val=""Description"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Notes) + "</FL>"
				+ "<FL val=""Account Type"">" + "Customer" + "</FL>"
				+ "<FL val=""Website"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Website) + "</FL>"
				+ "</row>"
				+ "</Accounts>";

		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + zohoID;
			
		URLstring = PathDef + "updateRecords?" + AuthHeader + "&xmlData=" + AccountXML;
		
		HeadersMap = New Map();			
		HTTPRequest = New HTTPRequest("", HeadersMap);	
		SSLConnection = New OpenSSLSecureConnection();
		HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
		Result = HTTPConnection.Post(HTTPRequest);		
				
	EndIf; 
	
EndProcedure

Procedure SetZohoDefaultBilling(Ref) Export
	
	idQuery = new Query("SELECT
	                    |	zoho_accountCodeMap.zoho_id
	                    |FROM
	                    |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
	                    |WHERE
	                    |	zoho_accountCodeMap.company_ref = &company_ref");
					   
	idQuery.SetParameter("company_ref", Ref.Owner.Ref);
	queryResult = idQuery.Execute();
	If NOT queryResult.IsEmpty() Then
		queryResultobj = queryResult.Unload();
		zohoID = queryResultobj[0].zoho_id;
	
		PathDef = "crm.zoho.com/crm/private/xml/Accounts/";
		billstreet = Ref.AddressLine1;
		If SessionParameters.TenantValue <> "1100674" Then
			If Ref.AddressLine2 <> "" Then
				billstreet = billstreet + ", " + Ref.AddressLine2;
			EndIf;
			If Ref.AddressLine3 <> "" Then
				billstreet = billstreet + ", " + Ref.AddressLine3;
			EndIf;
		EndIf;
		
		AccountXML = "<Accounts>"
			+ "<row no=""1"">"
			+ "<FL val=""Billing Street"">" + zoho_Functions.Zoho_XMLEncoding(billstreet) + "</FL>"
			+ "<FL val=""Billing Street 2"">" + zoho_Functions.Zoho_XMLEncoding(Ref.AddressLine2) + "</FL>" //ferguson custom
			+ "<FL val=""Billing Street3"">" + zoho_Functions.Zoho_XMLEncoding(Ref.AddressLine3) + "</FL>" //ferguson custom
			+ "<FL val=""Billing City"">" + zoho_Functions.Zoho_XMLEncoding(Ref.City) + "</FL>"
			+ "<FL val=""Billing State"">" + zoho_Functions.Zoho_XMLEncoding(String(Ref.State)) + "</FL>"
			+ "<FL val=""BillingState"">" + zoho_Functions.Zoho_XMLEncoding(String(Ref.State)) + "</FL>" //ferguson custom
			+ "<FL val=""Billing Code"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ZIP) + "</FL>"
			+ "<FL val=""Billing Country"">" + zoho_Functions.Zoho_XMLEncoding(String(Ref.Country)) + "</FL>"
			+ "<FL val=""BillingCountry"">" + zoho_Functions.Zoho_XMLEncoding(String(Ref.Country)) + "</FL>" // ferguson custom
			+ "<FL val=""Fax"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Fax) + "</FL>"
			+ "<FL val=""Phone"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Phone) + "</FL>"
			+ "</row>"
			+ "</Accounts>";

		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + zohoID;
			
		URLstring = PathDef + "updateRecords?" + AuthHeader + "&xmlData=" + AccountXML;
		
		HeadersMap = New Map();			
		HTTPRequest = New HTTPRequest("", HeadersMap);	
		SSLConnection = New OpenSSLSecureConnection();
		HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
		Result = HTTPConnection.Post(HTTPRequest);
	EndIf;
	
EndProcedure

Procedure SetZohoDefaultShipping(Ref) Export
	
	idQuery = new Query("SELECT
	                    |	zoho_accountCodeMap.zoho_id
	                    |FROM
	                    |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
	                    |WHERE
	                    |	zoho_accountCodeMap.company_ref = &company_ref");
					   
	idQuery.SetParameter("company_ref", Ref.Owner.Ref);
	queryResult = idQuery.Execute();
	If NOT queryResult.IsEmpty() Then
		queryResultobj = queryResult.Unload();
		zohoID = queryResultobj[0].zoho_id;
	
		PathDef = "crm.zoho.com/crm/private/xml/Accounts/";
		shipstreet = Ref.AddressLine1;
		If SessionParameters.TenantValue <> "1100674" Then
			If Ref.AddressLine2 <> "" Then
				shipstreet = shipstreet + ", " + Ref.AddressLine2;
			EndIf;
			If Ref.AddressLine3 <> "" Then
				shipstreet = shipstreet + ", " + Ref.AddressLine3;
			EndIf;
		EndIf;
	
		AccountXML = "<Accounts>"
			+ "<row no=""1"">"
			+ "<FL val=""Shipping Street"">" + zoho_Functions.Zoho_XMLEncoding(shipstreet) + "</FL>"
			+ "<FL val=""ShippingStreet2"">" + zoho_Functions.Zoho_XMLEncoding(Ref.AddressLine2) + "</FL>" //ferguson custom
			+ "<FL val=""Shipping Street3"">" + zoho_Functions.Zoho_XMLEncoding(Ref.AddressLine3) + "</FL>" //ferguson custom
			+ "<FL val=""Shipping City"">" + zoho_Functions.Zoho_XMLEncoding(Ref.City) + "</FL>"
			+ "<FL val=""Shipping State"">" + zoho_Functions.Zoho_XMLEncoding(String(Ref.State)) + "</FL>"
			+ "<FL val=""Shipping StatePick"">" + zoho_Functions.Zoho_XMLEncoding(String(Ref.State)) + "</FL>"//ferguson custom
			+ "<FL val=""Shipping Code"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ZIP) + "</FL>"
			+ "<FL val=""Shipping Country"">" + zoho_Functions.Zoho_XMLEncoding(String(Ref.Country)) + "</FL>"
			+ "<FL val=""ShippingCountry"">" + zoho_Functions.Zoho_XMLEncoding(String(Ref.Country)) + "</FL>" //ferguson custom
			+ "</row>"
			+ "</Accounts>";

		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + zohoID;
			
		URLstring = PathDef + "updateRecords?" + AuthHeader + "&xmlData=" + AccountXML;
		
		HeadersMap = New Map();			
		HTTPRequest = New HTTPRequest("", HeadersMap);	
		SSLConnection = New OpenSSLSecureConnection();
		HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
		Result = HTTPConnection.Post(HTTPRequest);
	EndIf;
	
	EndProcedure

Procedure ZohoThisContact(action, Ref) Export
	////// 
	PathDef = "https://crm.zoho.com/crm/private/json/Contacts/";
	
	If action = "create" Then
		
		strStreet = Ref.AddressLine1;
		If SessionParameters.TenantValue <> "1100674" Then
			If Ref.AddressLine2 <> "" Then
				strStreet = strStreet + ", " + Ref.AddressLine2;
			EndIf;
			If Ref.AddressLine3 <> "" Then
				strStreet = strStreet + ", " + Ref.AddressLine3;
			EndIf;
		EndIf;
		
		//zoho requires a last name for contacts
		If Ref.LastName = "" Then
			strLastName = Ref.Description;
		Else
			strLastName = Ref.LastName;
		EndIf;
		
		idQuery = new Query("SELECT
		                    |	zoho_accountCodeMap.zoho_id
		                    |FROM
		                    |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
		                    |WHERE
		                    |	zoho_accountCodeMap.company_ref = &company_ref");
					   
		idQuery.SetParameter("company_ref", Ref.Owner.Ref);
		queryResult = idQuery.Execute().Unload();
			
		ContactXML = "<Contacts>"
				+ "<row no=""1"">"
				+ "<FL val=""Salutation"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Salutation) + "</FL>"
				+ "<FL val=""First Name"">" + zoho_Functions.Zoho_XMLEncoding(Ref.FirstName) + "</FL>"
				+ "<FL val=""Last Name"">" + zoho_Functions.Zoho_XMLEncoding(strLastName) + "</FL>"
				+ "<FL val=""Description"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Notes) + "</FL>"
				+ "<FL val=""Department"">" + zoho_Functions.Zoho_XMLEncoding(Ref.CF1String) + "</FL>" //ferguson department
				+ "<FL val=""Email"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Email) + "</FL>"
				+ "<FL val=""Fax"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Fax) + "</FL>"
				+ "<FL val=""Mobile"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Cell) + "</FL>"
				+ "<FL val=""Phone"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Phone) + "</FL>"
				+ "<FL val=""Title"">" + zoho_Functions.Zoho_XMLEncoding(Ref.JobTitle) + "</FL>"
				+ "<FL val=""Mailing Street"">" + zoho_Functions.Zoho_XMLEncoding(strStreet) + "</FL>"
				+ "<FL val=""Mailing Street 2"">" + zoho_Functions.Zoho_XMLEncoding(Ref.AddressLine2) + "</FL>" //ferguson custom
				+ "<FL val=""Mailing Street3"">" + zoho_Functions.Zoho_XMLEncoding(Ref.AddressLine3) + "</FL>" // ferguson custom				
				+ "<FL val=""Mailing City"">" + zoho_Functions.Zoho_XMLEncoding(Ref.City) + "</FL>"
				+ "<FL val=""Mailing State"">" + zoho_Functions.Zoho_XMLEncoding(String(Ref.State)) + "</FL>"
				+ "<FL val=""MailingState"">" + zoho_Functions.Zoho_XMLEncoding(String(Ref.State)) + "</FL>" // ferguson custom
				+ "<FL val=""Mailing Zip"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Zip) + "</FL>"
				+ "<FL val=""Mailing Country"">" + zoho_Functions.Zoho_XMLEncoding(String(Ref.Country)) + "</FL>"
				+ "<FL val=""MailingCountry"">" + zoho_Functions.Zoho_XMLEncoding(String(Ref.Country)) + "</FL>" //ferguson custom
				+ "<FL val=""ACCOUNTID"">" + zoho_Functions.Zoho_XMLEncoding(queryResult[0].zoho_id) + "</FL>"
				+ "</row>"
				+ "</Contacts>";
				
		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() +"&scope=crmapi&";
		
		URLstring = PathDef + "insertRecords?" + AuthHeader + "xmlData=" + ContactXML;
		
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring, ConnectionSettings).Result;
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
		ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
			
		newRecord = Catalogs.zoho_contactCodeMap.CreateItem();
		newRecord.address_ref = Ref.Ref;
		newRecord.zoho_id = ResultBodyJSON.response.result.recorddetail.FL[0].content;
		newRecord.Write();
		
	EndIf;
	
	If action = "update" Then //AND Ref.Description <> "Primary" Then
		
		// using http request so no need for https:// anymore
		PathDef = "crm.zoho.com/crm/private/xml/Contacts/";
		
		strStreet = Ref.AddressLine1;
		If SessionParameters.TenantValue = "1100674" Then
			If Ref.AddressLine2 <> "" Then
				strStreet = strStreet + ", " + Ref.AddressLine2;
			EndIf;
			If Ref.AddressLine3 <> "" Then
				strStreet = strStreet + ", " + Ref.AddressLine3;
			EndIf;
		EndIf;

		If Ref.LastName = "" Then
			strLastName = Ref.Description;
		Else
			strLastName = Ref.LastName;
		EndIf;
		
		idQuery = new Query("SELECT
							|	zoho_contactCodeMap.zoho_id
							|FROM
							|	Catalog.zoho_contactCodeMap AS zoho_contactCodeMap
							|WHERE
							|	zoho_contactCodeMap.address_ref = &address_ref");
					   
		idQuery.SetParameter("address_ref", Ref.Ref);
		queryResult = idQuery.Execute();
		queryResultobj = queryResult.Unload();
		
		If queryResult.IsEmpty() Then
			ZohoThisContact("create", Ref);
			Return;
		EndIf;
					
		zohoID = queryResultobj[0].zoho_id;
		
		idQuery = new Query("SELECT
		                    |	zoho_accountCodeMap.zoho_id
		                    |FROM
		                    |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
		                    |WHERE
		                    |	zoho_accountCodeMap.company_ref = &company_ref");
					   
		idQuery.SetParameter("company_ref", Ref.Owner.Ref);
		queryResult = idQuery.Execute().Unload();
					
		ContactXML = "<Contacts>"
				+ "<row no=""1"">"
				+ "<FL val=""Salutation"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Salutation) + "</FL>"
				+ "<FL val=""First Name"">" + zoho_Functions.Zoho_XMLEncoding(Ref.FirstName) + "</FL>"
				+ "<FL val=""Last Name"">" + zoho_Functions.Zoho_XMLEncoding(strLastName) + "</FL>"
				+ "<FL val=""Description"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Notes) + "</FL>"
				+ "<FL val=""Department"">" + zoho_Functions.Zoho_XMLEncoding(Ref.CF1String) + "</FL>" //ferguson department
				+ "<FL val=""Email"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Email) + "</FL>"
				+ "<FL val=""Fax"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Fax) + "</FL>"
				+ "<FL val=""Mobile"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Cell) + "</FL>"
				+ "<FL val=""Phone"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Phone) + "</FL>"
				+ "<FL val=""Title"">" + zoho_Functions.Zoho_XMLEncoding(Ref.JobTitle) + "</FL>"
				+ "<FL val=""Mailing Street"">" + zoho_Functions.Zoho_XMLEncoding(strStreet) + "</FL>"
				+ "<FL val=""Mailing Street 2"">" + zoho_Functions.Zoho_XMLEncoding(Ref.AddressLine2) + "</FL>" //ferguson custom
				+ "<FL val=""Mailing Street3"">" + zoho_Functions.Zoho_XMLEncoding(Ref.AddressLine3) + "</FL>" // ferguson custom	
				+ "<FL val=""Mailing City"">" + zoho_Functions.Zoho_XMLEncoding(Ref.City) + "</FL>"
				+ "<FL val=""Mailing State"">" + zoho_Functions.Zoho_XMLEncoding(String(Ref.State)) + "</FL>"
				+ "<FL val=""MailingState"">" + zoho_Functions.Zoho_XMLEncoding(String(Ref.State)) + "</FL>" // ferguson custom
				+ "<FL val=""Mailing Zip"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Zip) + "</FL>"
				+ "<FL val=""Mailing Country"">" + zoho_Functions.Zoho_XMLEncoding(String(Ref.Country)) + "</FL>"
				+ "<FL val=""MailingCountry"">" + zoho_Functions.Zoho_XMLEncoding(String(Ref.Country)) + "</FL>" //ferguson custom
				+ "<FL val=""ACCOUNTID"">" + queryResult[0].zoho_id + "</FL>"
				+ "</row>"
				+ "</Contacts>";

		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + zohoID;
			
		URLstring = PathDef + "updateRecords?" + AuthHeader + "&xmlData=" + ContactXML;
		
		HeadersMap = New Map();			
		HTTPRequest = New HTTPRequest("", HeadersMap);	
		SSLConnection = New OpenSSLSecureConnection();
		HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
		Result = HTTPConnection.Post(HTTPRequest);		
								
	EndIf; 	
EndProcedure

Procedure ZohoThisSO(action, Ref) Export
	PathDef = "https://crm.zoho.com/crm/private/json/SalesOrders/";
	
	If action = "create" Then
						
		idQuery = new Query("SELECT
		                    |	zoho_accountCodeMap.zoho_id
		                    |FROM
		                    |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
		                    |WHERE
		                    |	zoho_accountCodeMap.company_ref = &company_ref");
					   
		idQuery.SetParameter("company_ref", Ref.Company.Ref);
		accountEx = idQuery.Execute();
		If accountEx.IsEmpty() Then
			Return;
		EndIf;
		idAccountResult = accountEx.Unload();
		
		//check if created from a quote in zoho
		quoteQuery = new Query("SELECT
		                       |	zoho_quoteCodeMap.zoho_id
		                       |FROM
		                       |	Catalog.zoho_QuoteCodeMap AS zoho_quoteCodeMap
		                       |WHERE
		                       |	zoho_quoteCodeMap.quote_ref = &quote_ref");
					   
		quoteQuery.SetParameter("quote_ref", Ref.BaseDocument.Ref);
		quotecheck = quoteQuery.Execute();
		If quotecheck.IsEmpty() Then
			quoteid = "";
		Else
			quoteResult = quotecheck.Unload();
			quoteid = quoteResult[0].zoho_id;
		EndIf;
		
		// check if delivery date was empty
		EmptyDate = Date("00010101");
		If EmptyDate = Ref.DeliveryDate Then
			delivery_date = "";
		Else
			delivery_date = Ref.DeliveryDate;
		EndIf;
		
		//SO information
		SOXML = "<SalesOrders>"
				+ "<row no=""1"">"
				+ "<FL val=""Subject"">" + "ACS_SO_" + zoho_Functions.Zoho_XMLEncoding(String(Ref.Number)) + "</FL>"
				+ "<FL val=""Description"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Memo) + "</FL>"
				+ "<FL val=""Terms and Conditions"">" + zoho_Functions.Zoho_XMLEncoding(Ref.EmailNote) + "</FL>"
				+ "<FL val=""Purchase Order"">" + zoho_Functions.Zoho_XMLEncoding(Ref.RefNum) + "</FL>"
				+ "<FL val=""Due Date"">" + zoho_Functions.Zoho_XMLEncoding(delivery_date) + "</FL>"
				+ "<FL val=""Sub Total"">" + StrReplace(String(Ref.LineSubtotal),",","") + "</FL>"
				+ "<FL val=""Discount"">" + StrReplace(String(-Ref.Discount),",","") + "</FL>"
				+ "<FL val=""Tax"">" + StrReplace(String(Ref.SalesTax),",","") + "</FL>"
				+ "<FL val=""Adjustment"">" + StrReplace(String(Ref.Shipping),",","") + "</FL>"
				+ "<FL val=""Grand Total"">" + StrReplace(String(Ref.DocumentTotal),",","") + "</FL>"
				+ "<FL val=""ACCOUNTID"">" + idAccountResult[0].zoho_id + "</FL>"
				+ "<FL val=""QUOTEID"">" + quoteid + "</FL>"
				+ "<FL val=""Product Details"">";
				
		// product details		
		count = 1;
		tempsubtotal = 0;
		For Each Lineitem in Ref.LineItems Do
			
			idQuery = new Query("SELECT
			                    |	zoho_productCodeMap.zoho_id
			                    |FROM
			                    |	Catalog.zoho_productCodeMap AS zoho_productCodeMap
			                    |WHERE
			                    |	zoho_productCodeMap.product_ref = &product_ref");
					   
			idQuery.SetParameter("product_ref", Lineitem.Product.Ref);
			productEx = idQuery.Execute();
			If productEx.IsEmpty() Then
				Return;
			EndIf;
			idProductResult = productEx.Unload();
								
			SOXML =	SOXML + "<product no=""" + count + """>"
				+ "<FL val=""Product Id"">" + idProductResult[0].zoho_id + "</FL>"
				+ "<FL val=""Quantity"">" + Lineitem.QtyUnits + "</FL>"
				+ "<FL val=""List Price"">" + StrReplace(String(Lineitem.PriceUnits),",","") + "</FL>"
				+ "<FL val=""Total"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
				+ "<FL val=""Total After Discount"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
				+ "<FL val=""Net Total"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
				+ "</product>";
				tempsubtotal = tempsubtotal + Lineitem.LineTotal; 
					
			count = count + 1;
	
		EndDo;
		SOXML = SOXML + "</FL>" + "<FL val=""Sub Total"">" + StrReplace(String(tempsubtotal),",","") + "</FL>";
		
		If SessionParameters.TenantValue <> "1100674" Then //AND SessionParameters.TenantValue <> "10" Then 
			//address detail
			//billto
			SOXML = SOXML
					+ "<FL val=""Billing Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine1) + "</FL>"
					+ "<FL val=""Billing City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.City) + "</FL>"
					+ "<FL val=""Billing State"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.State)) + "</FL>"
					+ "<FL val=""Billing Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.ZIP) + "</FL>"
					+ "<FL val=""Billing Country"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.Country)) + "</FL>";
			//shipto
			SOXML = SOXML
					+ "<FL val=""Shipping Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine1) + "</FL>"
					+ "<FL val=""Shipping City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.City) + "</FL>"
					+ "<FL val=""Shipping State"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.State)) + "</FL>"
					+ "<FL val=""Shipping Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.ZIP) + "</FL>"
					+ "<FL val=""Shipping Country"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.Country)) + "</FL>";
					
		Else
			//ferguson customs
			//billto
			If Ref.BillTo.Ref.FirstName <> "" AND Ref.BillTo.Ref.LastName <> "" Then
				custName = Ref.BillTo.Ref.FirstName + " " + Ref.BillTo.Ref.LastName;
			Else
				custName = Ref.BillTo.Ref.Description;
			EndIf;
			
			SOXML = SOXML
					+ "<FL val=""Customer Name Billing"">" + zoho_Functions.Zoho_XMLEncoding(custName) + "</FL>"
					+ "<FL val=""Billing Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine1) + "</FL>"
					+ "<FL val=""Billing Street 2"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine2) + "</FL>"
					+ "<FL val=""Billing City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.City) + "</FL>"
					+ "<FL val=""BillingState"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.State)) + "</FL>"
					+ "<FL val=""Billing Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.ZIP) + "</FL>"
					+ "<FL val=""BillingCountry"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.Country)) + "</FL>";
			//shipto
			If Ref.ShipTo.Ref.FirstName <> "" AND Ref.ShipTo.Ref.LastName <> "" Then
				custName = Ref.ShipTo.Ref.FirstName + " " + Ref.ShipTo.Ref.LastName;
			Else
				custName = Ref.ShipTo.Ref.Description;
			EndIf;

			SOXML = SOXML
					+ "<FL val=""Customer Name Shipping"">" + zoho_Functions.Zoho_XMLEncoding(custName) + "</FL>"
					+ "<FL val=""Shipping Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine1) + "</FL>"
					+ "<FL val=""Shipping Street 2"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine2) + "</FL>"
					+ "<FL val=""Shipping City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.City) + "</FL>"
					+ "<FL val=""ShippingState"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.State)) + "</FL>"
					+ "<FL val=""Shipping Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.ZIP) + "</FL>"
					+ "<FL val=""ShippingCountry"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.Country)) + "</FL>";
					
		EndIf;
					
		//dropshipto
		If Ref.DropshipShipTo <> Catalogs.Addresses.EmptyRef() Then
			
			idQuery = new Query("SELECT
			                    |	zoho_contactCodeMap.zoho_id
			                    |FROM
			                    |	Catalog.zoho_contactCodeMap AS zoho_contactCodeMap
			                    |WHERE
			                    |	zoho_contactCodeMap.address_ref = &address_ref");
					   
			idQuery.SetParameter("address_ref", Ref.DropshipShipTo.Ref);
			idQueryResult = idQuery.Execute();
			If idQueryResult.IsEmpty() Then
				contact_id = "";
			Else
				idContactResult = idQueryResult.Unload();
				contact_id = idContactResult[0].zoho_id;
			EndIf;
			
			SOXML = SOXML + "<FL val=""CONTACTID"">" + contact_id + "</FL>";
			
		EndIf;	
		
		SOXML = SOXML + "</row></SalesOrders>";
				
		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() +"&scope=crmapi&";
		
		URLstring = PathDef + "insertRecords?" + AuthHeader + "xmlData=" + SOXML;
		
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring, ConnectionSettings).Result;
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
		ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
			
		newRecord = Catalogs.zoho_SOCodeMap.CreateItem();
		newRecord.salesorder_ref = Ref.Ref;
		newRecord.zoho_id = ResultBodyJSON.response.result.recorddetail.FL[0].content;
		newRecord.Write();
		
	EndIf;
	
	If action = "update" Then
		
		// using http request so no need for https:// anymore
		PathDef = "crm.zoho.com/crm/private/xml/SalesOrders/";
		
		idQuery = new Query("SELECT
		                    |	zoho_SOCodeMap.zoho_id
		                    |FROM
		                    |	Catalog.zoho_SOCodeMap AS zoho_SOCodeMap
		                    |WHERE
		                    |	zoho_SOCodeMap.salesorder_ref = &salesorder_ref");
					   
		idQuery.SetParameter("salesorder_ref", Ref.Ref);
		queryResult = idQuery.Execute();
		
		If NOT queryResult.IsEmpty() Then
			
			queryResultobj = queryResult.Unload();
					
			zohoID = queryResultobj[0].zoho_id;
			
			idQuery = new Query("SELECT
			                    |	zoho_accountCodeMap.zoho_id
			                    |FROM
			                    |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
			                    |WHERE
			                    |	zoho_accountCodeMap.company_ref = &company_ref");
					   
			idQuery.SetParameter("company_ref", Ref.Company.Ref);
			accountEx = idQuery.Execute();
			If accountEx.IsEmpty() Then
				Return;
			EndIf;
			idAccountResult = accountEx.Unload();
			
				// check if delivery date was empty
			EmptyDate = Date("00010101");
			If EmptyDate = Ref.DeliveryDate Then
				delivery_date = "";
			Else
				delivery_date = Ref.DeliveryDate;
			EndIf;
			
			//SO information
			SOXML = "<SalesOrders>"
					+ "<row no=""1"">"
					+ "<FL val=""Description"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Memo) + "</FL>"
					+ "<FL val=""Terms and Conditions"">" + zoho_Functions.Zoho_XMLEncoding(Ref.EmailNote) + "</FL>"
					+ "<FL val=""Purchase Order"">" + zoho_Functions.Zoho_XMLEncoding(Ref.RefNum) + "</FL>"
					+ "<FL val=""Due Date"">" + zoho_Functions.Zoho_XMLEncoding(delivery_date) + "</FL>"
					+ "<FL val=""Adjustment"">" + StrReplace(String(Ref.Shipping),",","") + "</FL>"
					+ "<FL val=""Discount"">" + StrReplace(String(Ref.Discount),",","") + "</FL>"
					+ "<FL val=""Grand Total"">" + StrReplace(String(Ref.DocumentTotal),",","") + "</FL>"
					+ "<FL val=""ACCOUNTID"">" + idAccountResult[0].zoho_id + "</FL>"
					+ "<FL val=""Product Details"">";
							
			// product details		
			count = 1;
			tempsubtotal = 0;
			For Each Lineitem in Ref.LineItems Do
				
				idQuery = new Query("SELECT
				                    |	zoho_productCodeMap.zoho_id
				                    |FROM
				                    |	Catalog.zoho_productCodeMap AS zoho_productCodeMap
				                    |WHERE
				                    |	zoho_productCodeMap.product_ref = &product_ref");
						   
				idQuery.SetParameter("product_ref", Lineitem.Product.Ref);
				productEx = idQuery.Execute();
				If productEx.IsEmpty() Then
					Return;
				EndIf;
				idProductResult = productEx.Unload();
									
				SOXML =	SOXML + "<product no=""" + count + """>"
					+ "<FL val=""Product Id"">" + idProductResult[0].zoho_id + "</FL>"
					+ "<FL val=""Quantity"">" + Lineitem.QtyUnits + "</FL>"
					+ "<FL val=""List Price"">" + StrReplace(String(Lineitem.PriceUnits),",","") + "</FL>"
					+ "<FL val=""Total"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
					+ "<FL val=""Total After Discount"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
					+ "<FL val=""Net Total"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
					+ "</product>";
					tempsubtotal = tempsubtotal + Lineitem.LineTotal; 
						
				count = count + 1;
		
			EndDo;
			SOXML = SOXML + "</FL>" + "<FL val=""Sub Total"">" + StrReplace(String(tempsubtotal),",","") + "</FL>";

			
			If SessionParameters.TenantValue <> "1100674" Then //AND SessionParameters.TenantValue <> "10" Then 
				//address detail
				//billto
				SOXML = SOXML
						+ "<FL val=""Billing Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine1) + "</FL>"
						+ "<FL val=""Billing City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.City) + "</FL>"
						+ "<FL val=""Billing State"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.State)) + "</FL>"
						+ "<FL val=""Billing Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.ZIP) + "</FL>"
						+ "<FL val=""Billing Country"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.Country)) + "</FL>";
				//shipto
				SOXML = SOXML
						+ "<FL val=""Shipping Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine1) + "</FL>"
						+ "<FL val=""Shipping City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.City) + "</FL>"
						+ "<FL val=""Shipping State"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.State)) + "</FL>"
						+ "<FL val=""Shipping Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.ZIP) + "</FL>"
						+ "<FL val=""Shipping Country"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.Country)) + "</FL>";
						
			Else
				//ferguson customs
				//billto
				If Ref.BillTo.Ref.FirstName <> "" AND Ref.BillTo.Ref.LastName <> "" Then
					custName = Ref.BillTo.Ref.FirstName + " " + Ref.BillTo.Ref.LastName;
				Else
					custName = Ref.BillTo.Ref.Description;
				EndIf;
				
				SOXML = SOXML
						+ "<FL val=""Customer Name Billing"">" + zoho_Functions.Zoho_XMLEncoding(custName) + "</FL>"
						+ "<FL val=""Billing Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine1) + "</FL>"
						+ "<FL val=""Billing Street 2"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine2) + "</FL>"
						+ "<FL val=""Billing City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.City) + "</FL>"
						+ "<FL val=""BillingState"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.State)) + "</FL>"
						+ "<FL val=""Billing Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.ZIP) + "</FL>"
						+ "<FL val=""BillingCountry"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.Country)) + "</FL>";
				//shipto
				If Ref.ShipTo.Ref.FirstName <> "" AND Ref.ShipTo.Ref.LastName <> "" Then
					custName = Ref.ShipTo.Ref.FirstName + " " + Ref.ShipTo.Ref.LastName;
				Else
					custName = Ref.ShipTo.Ref.Description;
				EndIf;

				SOXML = SOXML
						+ "<FL val=""Customer Name Shipping"">" + zoho_Functions.Zoho_XMLEncoding(custName) + "</FL>"
						+ "<FL val=""Shipping Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine1) + "</FL>"
						+ "<FL val=""Shipping Street 2"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine2) + "</FL>"
						+ "<FL val=""Shipping City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.City) + "</FL>"
						+ "<FL val=""ShippingState"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.State)) + "</FL>"
						+ "<FL val=""Shipping Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.ZIP) + "</FL>"
						+ "<FL val=""ShippingCountry"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.Country)) + "</FL>";
			EndIf;
	
			//dropshipto
			If Ref.DropshipShipTo <> Catalogs.Addresses.EmptyRef() Then
			
				idQuery = new Query("SELECT
				                    |	zoho_contactCodeMap.zoho_id
				                    |FROM
				                    |	Catalog.zoho_contactCodeMap AS zoho_contactCodeMap
				                    |WHERE
				                    |	zoho_contactCodeMap.address_ref = &address_ref");
						   
				idQuery.SetParameter("address_ref", Ref.DropshipShipTo.Ref);
				idQueryResult = idQuery.Execute();
				If idQueryResult.IsEmpty() Then
					contact_id = "";
				Else
					idContactResult = idQueryResult.Unload();
					contact_id = idContactResult[0].zoho_id;
				EndIf;
				
				SOXML = SOXML + "<FL val=""CONTACTID"">" + contact_id + "</FL>";
							
			EndIf;
			
			SOXML = SOXML + "</row></SalesOrders>";
			
			AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + zohoID;
				
			URLstring = PathDef + "updateRecords?" + AuthHeader + "&xmlData=" + SOXML;
			
			HeadersMap = New Map();			
			HTTPRequest = New HTTPRequest("", HeadersMap);	
			SSLConnection = New OpenSSLSecureConnection();
			HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
			Result = HTTPConnection.Post(HTTPRequest);
		Else
			// no sales order to update in zoho;
			return;
		EndIf;
	EndIf;				
EndProcedure

Procedure ZohoThisQuote(action, Ref) Export
	PathDef = "https://crm.zoho.com/crm/private/json/Quotes/";
	
	If action = "create" Then
						
		idQuery = new Query("SELECT
		                    |	zoho_accountCodeMap.zoho_id
		                    |FROM
		                    |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
		                    |WHERE
		                    |	zoho_accountCodeMap.company_ref = &company_ref");
					   
		idQuery.SetParameter("company_ref", Ref.Company.Ref);
		accountEx = idQuery.Execute();
		If accountEx.IsEmpty() Then
			Return;
		EndIf;
		idAccountResult = accountEx.Unload();
		
		// check if expiration date was empty
		EmptyDate = Date("00010101");
		If EmptyDate = Ref.ExpirationDate Then
			expiration_date = "";
		Else
			expiration_date = Ref.ExpirationDate;
		EndIf;
		
		//quote information
		QuoteXML = "<Quotes>"
				+ "<row no=""1"">"
				+ "<FL val=""Subject"">" + "ACS_Quote_" + zoho_Functions.Zoho_XMLEncoding(String(Ref.Number)) + "</FL>"
				+ "<FL val=""Description"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Memo) + "</FL>"
				+ "<FL val=""Terms and Conditions"">" + zoho_Functions.Zoho_XMLEncoding(Ref.EmailNote) + "</FL>"
				+ "<FL val=""Valid Till"">" + zoho_Functions.Zoho_XMLEncoding(expiration_date) + "</FL>"
				+ "<FL val=""Sub Total"">" + StrReplace(String(Ref.LineSubtotal),",","") + "</FL>"
				+ "<FL val=""Discount"">" + StrReplace(String(-Ref.Discount),",","") + "</FL>"
				+ "<FL val=""Tax"">" + StrReplace(String(Ref.SalesTax),",","") + "</FL>"
				+ "<FL val=""Adjustment"">" + StrReplace(String(Ref.Shipping),",","") + "</FL>"
				+ "<FL val=""Grand Total"">" + StrReplace(String(Ref.DocumentTotal),",","") + "</FL>"
				+ "<FL val=""ACCOUNTID"">" + idAccountResult[0].zoho_id + "</FL>"
				+ "<FL val=""Product Details"">";
				
		// product details		
		count = 1;
		tempsubtotal = 0;
		For Each Lineitem in Ref.LineItems Do
			
			idQuery = new Query("SELECT
			                    |	zoho_productCodeMap.zoho_id
			                    |FROM
			                    |	Catalog.zoho_productCodeMap AS zoho_productCodeMap
			                    |WHERE
			                    |	zoho_productCodeMap.product_ref = &product_ref");
					   
			idQuery.SetParameter("product_ref", Lineitem.Product.Ref);
			productEx = idQuery.Execute();
			If productEx.IsEmpty() Then
				Return;
			EndIf;
			idProductResult = productEx.Unload();
								
			QuoteXML =	QuoteXML + "<product no=""" + count + """>"
				+ "<FL val=""Product Id"">" + idProductResult[0].zoho_id + "</FL>"
				+ "<FL val=""Quantity"">" + Lineitem.QtyUnits + "</FL>"
				+ "<FL val=""List Price"">" + StrReplace(String(Lineitem.PriceUnits),",","") + "</FL>"
				+ "<FL val=""Total"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
				+ "<FL val=""Total After Discount"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
				+ "<FL val=""Net Total"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
				+ "</product>";
				tempsubtotal = tempsubtotal + Lineitem.LineTotal; 
					
			count = count + 1;
	
		EndDo;
		QuoteXML = QuoteXML + "</FL>" + "<FL val=""Sub Total"">" + StrReplace(String(tempsubtotal),",","") + "</FL>";
		
		If SessionParameters.TenantValue <> "1100674" Then //AND SessionParameters.TenantValue <> "10" Then 
			//address detail
			//billto
			QuoteXML = QuoteXML
					+ "<FL val=""Billing Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine1) + "</FL>"
					+ "<FL val=""Billing City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.City) + "</FL>"
					+ "<FL val=""Billing State"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.State)) + "</FL>"
					+ "<FL val=""Billing Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.ZIP) + "</FL>"
					+ "<FL val=""Billing Country"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.Country)) + "</FL>";
			//shipto
			QuoteXML = QuoteXML
					+ "<FL val=""Shipping Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine1) + "</FL>"
					+ "<FL val=""Shipping City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.City) + "</FL>"
					+ "<FL val=""Shipping State"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.State)) + "</FL>"
					+ "<FL val=""Shipping Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.ZIP) + "</FL>"
					+ "<FL val=""Shipping Country"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.Country)) + "</FL>";
					
		Else
			//ferguson customs
			//billto
			If Ref.BillTo.Ref.FirstName <> "" AND Ref.BillTo.Ref.LastName <> "" Then
				custName = Ref.BillTo.Ref.FirstName + " " + Ref.BillTo.Ref.LastName;
			Else
				custName = Ref.BillTo.Ref.Description;
			EndIf;
			
			QuoteXML = QuoteXML
					+ "<FL val=""Customer Name Billing"">" + zoho_Functions.Zoho_XMLEncoding(custName) + "</FL>"
					+ "<FL val=""Billing Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine1) + "</FL>"
					+ "<FL val=""Billing Street 2"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine2) + "</FL>"
					+ "<FL val=""Billing City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.City) + "</FL>"
					+ "<FL val=""BillingState"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.State)) + "</FL>"
					+ "<FL val=""Billing Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.ZIP) + "</FL>"
					+ "<FL val=""BillingCountry"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.Country)) + "</FL>";
			//shipto
			If Ref.ShipTo.Ref.FirstName <> "" AND Ref.ShipTo.Ref.LastName <> "" Then
				custName = Ref.ShipTo.Ref.FirstName + " " + Ref.ShipTo.Ref.LastName;
			Else
				custName = Ref.ShipTo.Ref.Description;
			EndIf;

			QuoteXML = QuoteXML
					+ "<FL val=""Customer Name Shipping"">" + zoho_Functions.Zoho_XMLEncoding(custName) + "</FL>"
					+ "<FL val=""Shipping Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine1) + "</FL>"
					+ "<FL val=""Shipping Street 2"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine2) + "</FL>"
					+ "<FL val=""Shipping City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.City) + "</FL>"
					+ "<FL val=""ShippingState"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.State)) + "</FL>"
					+ "<FL val=""Shipping Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.ZIP) + "</FL>"
					+ "<FL val=""ShippingCountry"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.Country)) + "</FL>";
					
		EndIf;
					
		//dropshipto
		If Ref.DropshipShipTo <> Catalogs.Addresses.EmptyRef() Then
			
			idQuery = new Query("SELECT
			                    |	zoho_contactCodeMap.zoho_id
			                    |FROM
			                    |	Catalog.zoho_contactCodeMap AS zoho_contactCodeMap
			                    |WHERE
			                    |	zoho_contactCodeMap.address_ref = &address_ref");
					   
			idQuery.SetParameter("address_ref", Ref.DropshipShipTo.Ref);
			idQueryResult = idQuery.Execute();
			If idQueryResult.IsEmpty() Then
				contact_id = "";
			Else
				idContactResult = idQueryResult.Unload();
				contact_id = idContactResult[0].zoho_id;
			EndIf;
			
			QuoteXML = QuoteXML + "<FL val=""CONTACTID"">" + contact_id + "</FL>";
			
		EndIf;	
		
		QuoteXML = QuoteXML + "</row></Quotes>";
				
		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() +"&scope=crmapi&";
		
		URLstring = PathDef + "insertRecords?" + AuthHeader + "xmlData=" + QuoteXML;
		
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring, ConnectionSettings).Result;
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
		ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
			
		newRecord = Catalogs.zoho_QuoteCodeMap.CreateItem();
		newRecord.quote_ref = Ref.Ref;
		newRecord.zoho_id = ResultBodyJSON.response.result.recorddetail.FL[0].content;
		newRecord.Write();
		
	EndIf;
	
	If action = "update" Then
		// using http request so no need for https:// anymore
		PathDef = "crm.zoho.com/crm/private/xml/Quotes/";
		
		idQuery = new Query("SELECT
		                    |	zoho_QuoteCodeMap.zoho_id
		                    |FROM
		                    |	Catalog.zoho_QuoteCodeMap AS zoho_QuoteCodeMap
		                    |WHERE
		                    |	zoho_QuoteCodeMap.quote_ref = &quote_ref");
					   
		idQuery.SetParameter("quote_ref", Ref.Ref);
		queryResult = idQuery.Execute();
		
		If NOT queryResult.IsEmpty() Then
			
			queryResultobj = queryResult.Unload();
					
			zohoID = queryResultobj[0].zoho_id;
			
			idQuery = new Query("SELECT
			                    |	zoho_accountCodeMap.zoho_id
			                    |FROM
			                    |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
			                    |WHERE
			                    |	zoho_accountCodeMap.company_ref = &company_ref");
					   
			idQuery.SetParameter("company_ref", Ref.Company.Ref);
			accountEx = idQuery.Execute();
			If accountEx.IsEmpty() Then
				Return;
			EndIf;
			idAccountResult = accountEx.Unload();
			
				// check if expiration date was empty
			EmptyDate = Date("00010101");
			If EmptyDate = Ref.ExpirationDate Then
				expiration_date = "";
			Else
				expiration_date = Ref.ExpirationDate;
			EndIf;
			
			//quote information
			QuoteXML = "<Quotes>"
					+ "<row no=""1"">"
					+ "<FL val=""Description"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Memo) + "</FL>"
					+ "<FL val=""Terms and Conditions"">" + zoho_Functions.Zoho_XMLEncoding(Ref.EmailNote) + "</FL>"
					+ "<FL val=""Valid Till"">" + zoho_Functions.Zoho_XMLEncoding(expiration_date) + "</FL>"
					+ "<FL val=""Adjustment"">" + StrReplace(String(Ref.Shipping),",","") + "</FL>"
					+ "<FL val=""Discount"">" + StrReplace(String(Ref.Discount),",","") + "</FL>"
					+ "<FL val=""Grand Total"">" + StrReplace(String(Ref.DocumentTotal),",","") + "</FL>"
					+ "<FL val=""ACCOUNTID"">" + idAccountResult[0].zoho_id + "</FL>"
					+ "<FL val=""Product Details"">";
		
			// product details		
			count = 1;
			tempsubtotal = 0;
			For Each Lineitem in Ref.LineItems Do
				
				idQuery = new Query("SELECT
				                    |	zoho_productCodeMap.zoho_id
				                    |FROM
				                    |	Catalog.zoho_productCodeMap AS zoho_productCodeMap
				                    |WHERE
				                    |	zoho_productCodeMap.product_ref = &product_ref");
						   
				idQuery.SetParameter("product_ref", Lineitem.Product.Ref);
				productEx = idQuery.Execute();
				If productEx.IsEmpty() Then
					Return;
				EndIf;
				idProductResult = productEx.Unload();
									
				QuoteXML =	QuoteXML + "<product no=""" + count + """>"
					+ "<FL val=""Product Id"">" + idProductResult[0].zoho_id + "</FL>"
					+ "<FL val=""Quantity"">" + Lineitem.QtyUnits + "</FL>"
					+ "<FL val=""List Price"">" + StrReplace(String(Lineitem.PriceUnits),",","") + "</FL>"
					+ "<FL val=""Total"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
					+ "<FL val=""Total After Discount"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
					+ "<FL val=""Net Total"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
					+ "</product>";
					tempsubtotal = tempsubtotal + Lineitem.LineTotal; 
						
				count = count + 1;
		
			EndDo;
			QuoteXML = QuoteXML + "</FL>" + "<FL val=""Sub Total"">" + StrReplace(String(tempsubtotal),",","") + "</FL>";
			
			If SessionParameters.TenantValue <> "1100674" Then //AND SessionParameters.TenantValue <> "10" Then 
				//address detail
				//billto
				QuoteXML = QuoteXML
						+ "<FL val=""Billing Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine1) + "</FL>"
						+ "<FL val=""Billing City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.City) + "</FL>"
						+ "<FL val=""Billing State"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.State)) + "</FL>"
						+ "<FL val=""Billing Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.ZIP) + "</FL>"
						+ "<FL val=""Billing Country"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.Country)) + "</FL>";
				//shipto
				QuoteXML = QuoteXML
						+ "<FL val=""Shipping Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine1) + "</FL>"
						+ "<FL val=""Shipping City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.City) + "</FL>"
						+ "<FL val=""Shipping State"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.State)) + "</FL>"
						+ "<FL val=""Shipping Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.ZIP) + "</FL>"
						+ "<FL val=""Shipping Country"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.Country)) + "</FL>";
						
			Else
				//ferguson customs
				//billto
				If Ref.BillTo.Ref.FirstName <> "" AND Ref.BillTo.Ref.LastName <> "" Then
					custName = Ref.BillTo.Ref.FirstName + " " + Ref.BillTo.Ref.LastName;
				Else
					custName = Ref.BillTo.Ref.Description;
				EndIf;
				
				QuoteXML = QuoteXML
						+ "<FL val=""Customer Name Billing"">" + zoho_Functions.Zoho_XMLEncoding(custName) + "</FL>"
						+ "<FL val=""Billing Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine1) + "</FL>"
						+ "<FL val=""Billing Street 2"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine2) + "</FL>"
						+ "<FL val=""Billing City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.City) + "</FL>"
						+ "<FL val=""BillingState"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.State)) + "</FL>"
						+ "<FL val=""Billing Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.ZIP) + "</FL>"
						+ "<FL val=""BillingCountry"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.Country)) + "</FL>";
				//shipto
				If Ref.ShipTo.Ref.FirstName <> "" AND Ref.ShipTo.Ref.LastName <> "" Then
					custName = Ref.ShipTo.Ref.FirstName + " " + Ref.ShipTo.Ref.LastName;
				Else
					custName = Ref.ShipTo.Ref.Description;
				EndIf;

				QuoteXML = QuoteXML
						+ "<FL val=""Customer Name Shipping"">" + zoho_Functions.Zoho_XMLEncoding(custName) + "</FL>"
						+ "<FL val=""Shipping Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine1) + "</FL>"
						+ "<FL val=""Shipping Street 2"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine2) + "</FL>"
						+ "<FL val=""Shipping City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.City) + "</FL>"
						+ "<FL val=""ShippingState"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.State)) + "</FL>"
						+ "<FL val=""Shipping Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.ZIP) + "</FL>"
						+ "<FL val=""ShippingCountry"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.Country)) + "</FL>";
			EndIf;
	
			//dropshipto
			If Ref.DropshipShipTo <> Catalogs.Addresses.EmptyRef() Then
			
				idQuery = new Query("SELECT
								|	zoho_contactCodeMap.zoho_id
								|FROM
								|	Catalog.zoho_contactCodeMap AS zoho_contactCodeMap
								|WHERE
								|	zoho_contactCodeMap.address_ref = &address_ref");
						   
				idQuery.SetParameter("address_ref", Ref.DropshipShipTo.Ref);
				idQueryResult = idQuery.Execute();
				If idQueryResult.IsEmpty() Then
					contact_id = "";
				Else
					idContactResult = idQueryResult.Unload();
					contact_id = idContactResult[0].zoho_id;
				EndIf;
				
				QuoteXML = QuoteXML + "<FL val=""CONTACTID"">" + contact_id + "</FL>";
							
			EndIf;
			
			QuoteXML = QuoteXML + "</row></Quotes>";
			
			AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + zohoID;
				
			URLstring = PathDef + "updateRecords?" + AuthHeader + "&xmlData=" + QuoteXML;
			
			HeadersMap = New Map();			
			HTTPRequest = New HTTPRequest("", HeadersMap);	
			SSLConnection = New OpenSSLSecureConnection();
			HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
			Result = HTTPConnection.Post(HTTPRequest);
		Else
			// no quote to update in zoho;
			return;
		EndIf;
	
	EndIf;				
EndProcedure

Procedure ZohoThisInvoice(action, Ref) Export
	PathDef = "https://crm.zoho.com/crm/private/json/Invoices/";
	
	If action = "create" Then
						
		idQuery = new Query("SELECT
		                    |	zoho_accountCodeMap.zoho_id
		                    |FROM
		                    |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
		                    |WHERE
		                    |	zoho_accountCodeMap.company_ref = &company_ref");
					   
		idQuery.SetParameter("company_ref", Ref.Company.Ref);
		accountEx = idQuery.Execute();
		If accountEx.IsEmpty() Then
			Return;
		EndIf;
		idAccountResult = accountEx.Unload();
		
		////check if created from a so in zoho
		firstLineItem = Ref.LineItems.Get(0);
		soQuery = new Query("SELECT
		                    |	zoho_SOCodeMap.zoho_id
		                    |FROM
		                    |	Catalog.zoho_SOCodeMap AS zoho_SOCodeMap
		                    |WHERE
		                    |	zoho_SOCodeMap.salesorder_ref = &salesorder_ref");
					   
		soQuery.SetParameter("salesorder_ref", firstLineItem.Order.Ref);
		socheck = soQuery.Execute();
		If socheck.IsEmpty() Then
			soid = "";
		Else
			soResult = socheck.Unload();
			soid = soResult[0].zoho_id;
		EndIf;
		
		// check if Due date was empty
		EmptyDate = Date("00010101");
		If EmptyDate = Ref.DueDate Then
			Due_date = "";
		Else
			Due_date = Ref.DueDate;
		EndIf;
		
		// check if Due date was empty
		EmptyDate = Date("00010101");
		If EmptyDate = Ref.Date Then
			invoice_date = "";
		Else
			invoice_date = Ref.Date;
		EndIf;
		
		//SI information
		SIXML = "<Invoices>"
				+ "<row no=""1"">"
				+ "<FL val=""Subject"">" + "ACS_SI_" + zoho_Functions.Zoho_XMLEncoding(String(Ref.Number)) + "</FL>"
				+ "<FL val=""Description"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Memo) + "</FL>"
				+ "<FL val=""Terms and Conditions"">" + zoho_Functions.Zoho_XMLEncoding(Ref.EmailNote) + "</FL>"
				+ "<FL val=""Purchase Order"">" + zoho_Functions.Zoho_XMLEncoding(Ref.RefNum) + "</FL>"
				+ "<FL val=""Due Date"">" + zoho_Functions.Zoho_XMLEncoding(Due_date) + "</FL>"
				+ "<FL val=""Sub Total"">" + StrReplace(String(Ref.LineSubtotal),",","") + "</FL>"
				+ "<FL val=""Discount"">" + StrReplace(String(-Ref.Discount),",","") + "</FL>"
				+ "<FL val=""Tax"">" + StrReplace(String(Ref.SalesTax),",","") + "</FL>"
				+ "<FL val=""Adjustment"">" + StrReplace(String(Ref.Shipping),",","") + "</FL>"
				+ "<FL val=""Grand Total"">" + StrReplace(String(Ref.DocumentTotal),",","") + "</FL>"
				+ "<FL val=""ACCOUNTID"">" + idAccountResult[0].zoho_id + "</FL>"
				+ "<FL val=""Invoice Date"">" + zoho_Functions.Zoho_XMLEncoding(invoice_date) + "</FL>"
				+ "<FL val=""SALESORDERID"">" + soid + "</FL>"
				+ "<FL val=""Product Details"">";
								
		// product details		
		count = 1;
		tempsubtotal = 0;
		For Each Lineitem in Ref.LineItems Do
			
			idQuery = new Query("SELECT
			                    |	zoho_productCodeMap.zoho_id
			                    |FROM
			                    |	Catalog.zoho_productCodeMap AS zoho_productCodeMap
			                    |WHERE
			                    |	zoho_productCodeMap.product_ref = &product_ref");
					   
			idQuery.SetParameter("product_ref", Lineitem.Product.Ref);
			productEx = idQuery.Execute();
			If productEx.IsEmpty() Then
				Return;
			EndIf;
			idProductResult = productEx.Unload();
								
			SIXML =	SIXML + "<product no=""" + count + """>"
				+ "<FL val=""Product Id"">" + idProductResult[0].zoho_id + "</FL>"
				+ "<FL val=""Quantity"">" + Lineitem.QtyUnits + "</FL>"
				+ "<FL val=""List Price"">" + StrReplace(String(Lineitem.PriceUnits),",","") + "</FL>"
				+ "<FL val=""Total"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
				+ "<FL val=""Total After Discount"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
				+ "<FL val=""Net Total"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
				+ "</product>";
				tempsubtotal = tempsubtotal + Lineitem.LineTotal; 
					
			count = count + 1;
	
		EndDo;
		SIXML = SIXML + "</FL>" + "<FL val=""Sub Total"">" + StrReplace(String(tempsubtotal),",","") + "</FL>";
		
		If SessionParameters.TenantValue <> "1100674" Then //AND SessionParameters.TenantValue <> "10" Then 
			//address detail
			//billto
			SIXML = SIXML
					+ "<FL val=""Billing Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine1) + "</FL>"
					+ "<FL val=""Billing City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.City) + "</FL>"
					+ "<FL val=""Billing State"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.State)) + "</FL>"
					+ "<FL val=""Billing Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.ZIP) + "</FL>"
					+ "<FL val=""Billing Country"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.Country)) + "</FL>";
			//shipto
			SIXML = SIXML
					+ "<FL val=""Shipping Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine1) + "</FL>"
					+ "<FL val=""Shipping City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.City) + "</FL>"
					+ "<FL val=""Shipping State"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.State)) + "</FL>"
					+ "<FL val=""Shipping Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.ZIP) + "</FL>"
					+ "<FL val=""Shipping Country"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.Country)) + "</FL>";
					
		Else
			//ferguson customs
			//billto
			If Ref.BillTo.Ref.FirstName <> "" AND Ref.BillTo.Ref.LastName <> "" Then
				custName = Ref.BillTo.Ref.FirstName + " " + Ref.BillTo.Ref.LastName;
			Else
				custName = Ref.BillTo.Ref.Description;
			EndIf;
			
			SIXML = SIXML
					+ "<FL val=""Customer Name Billing"">" + zoho_Functions.Zoho_XMLEncoding(custName) + "</FL>"
					+ "<FL val=""Billing Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine1) + "</FL>"
					+ "<FL val=""Billing Street 2"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine2) + "</FL>"
					+ "<FL val=""Billing City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.City) + "</FL>"
					+ "<FL val=""BillingState"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.State)) + "</FL>"
					+ "<FL val=""Billing Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.ZIP) + "</FL>"
					+ "<FL val=""BillingCountry"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.Country)) + "</FL>";
			//shipto
			If Ref.ShipTo.Ref.FirstName <> "" AND Ref.ShipTo.Ref.LastName <> "" Then
				custName = Ref.ShipTo.Ref.FirstName + " " + Ref.ShipTo.Ref.LastName;
			Else
				custName = Ref.ShipTo.Ref.Description;
			EndIf;

			SIXML = SIXML
					+ "<FL val=""Customer Name Shipping"">" + zoho_Functions.Zoho_XMLEncoding(custName) + "</FL>"
					+ "<FL val=""Shipping Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine1) + "</FL>"
					+ "<FL val=""Shipping Street 2"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine2) + "</FL>"
					+ "<FL val=""Shipping City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.City) + "</FL>"
					+ "<FL val=""ShippingState"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.State)) + "</FL>"
					+ "<FL val=""Shipping Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.ZIP) + "</FL>"
					+ "<FL val=""ShippingCountry"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.Country)) + "</FL>";
					
		EndIf;
					
		//dropshipto
		If Ref.DropshipShipTo <> Catalogs.Addresses.EmptyRef() Then
			
			idQuery = new Query("SELECT
		                    |	zoho_contactCodeMap.zoho_id
		                    |FROM
		                    |	Catalog.zoho_contactCodeMap AS zoho_contactCodeMap
		                    |WHERE
		                    |	zoho_contactCodeMap.address_ref = &address_ref");
					   
			idQuery.SetParameter("address_ref", Ref.DropshipShipTo.Ref);
			idQueryResult = idQuery.Execute();
			If idQueryResult.IsEmpty() Then
				contact_id = "";
			Else
				idContactResult = idQueryResult.Unload();
				contact_id = idContactResult[0].zoho_id;
			EndIf;
			
			SIXML = SIXML + "<FL val=""CONTACTID"">" + contact_id + "</FL>";
			
		EndIf;	
		
		SIXML = SIXML + "</row></Invoices>";
				
		AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() +"&scope=crmapi&";
		
		URLstring = PathDef + "insertRecords?" + AuthHeader + "xmlData=" + SIXML;
		
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring, ConnectionSettings).Result;
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
		ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
			
		newRecord = Catalogs.zoho_SICodeMap.CreateItem();
		newRecord.invoice_ref = Ref.Ref;
		newRecord.zoho_id = ResultBodyJSON.response.result.recorddetail.FL[0].content;
		newRecord.Write();
		
	EndIf;
	
	If action = "update" Then
		
		// using http request si no need for https:// anymore
		PathDef = "crm.zoho.com/crm/private/xml/Invoices/";
		
		idQuery = new Query("SELECT
		                    |	zoho_SICodeMap.zoho_id
		                    |FROM
		                    |	Catalog.zoho_SICodeMap AS zoho_SICodeMap
		                    |WHERE
		                    |	zoho_SICodeMap.invoice_ref = &invoice_ref");
					   
		idQuery.SetParameter("invoice_ref", Ref.Ref);
		queryResult = idQuery.Execute();
		
		If NOT queryResult.IsEmpty() Then
			
			queryResultobj = queryResult.Unload();
					
			zohoID = queryResultobj[0].zoho_id;
			
			idQuery = new Query("SELECT
			                    |	zoho_accountCodeMap.zoho_id
			                    |FROM
			                    |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap
			                    |WHERE
			                    |	zoho_accountCodeMap.company_ref = &company_ref");
					   
			idQuery.SetParameter("company_ref", Ref.Company.Ref);
			accountEx = idQuery.Execute();
			If accountEx.IsEmpty() Then
				Return;
			EndIf;
			idAccountResult = accountEx.Unload();
			
				// check if Due date was empty
			EmptyDate = Date("00010101");
			If EmptyDate = Ref.DueDate Then
				Due_date = "";
			Else
				Due_date = Ref.DueDate;
			EndIf;
			
			EmptyDate = Date("00010101");
			If EmptyDate = Ref.Date Then
				invoice_date = "";
			Else
				invoice_date = Ref.Date;
			EndIf;
			
			//SO information
			SIXML = "<Invoices>"
					+ "<row no=""1"">"
					+ "<FL val=""Description"">" + zoho_Functions.Zoho_XMLEncoding(Ref.Memo) + "</FL>"
					+ "<FL val=""Terms and Conditions"">" + zoho_Functions.Zoho_XMLEncoding(Ref.EmailNote) + "</FL>"
					+ "<FL val=""Purchase Order"">" + zoho_Functions.Zoho_XMLEncoding(Ref.RefNum) + "</FL>"
					+ "<FL val=""Due Date"">" + zoho_Functions.Zoho_XMLEncoding(Due_date) + "</FL>"
					+ "<FL val=""Adjustment"">" + StrReplace(String(Ref.Shipping),",","") + "</FL>"
					+ "<FL val=""Discount"">" + StrReplace(String(Ref.Discount),",","") + "</FL>"
					+ "<FL val=""Grand Total"">" + StrReplace(String(Ref.DocumentTotal),",","") + "</FL>"
					+ "<FL val=""ACCOUNTID"">" + idAccountResult[0].zoho_id + "</FL>"
					+ "<FL val=""Invoice Date"">" + zoho_Functions.Zoho_XMLEncoding(invoice_date) + "</FL>"
					+ "<FL val=""Product Details"">";
					
					
				// product details		
			count = 1;
			tempsubtotal = 0;
			For Each Lineitem in Ref.LineItems Do
				
				idQuery = new Query("SELECT
				                    |	zoho_productCodeMap.zoho_id
				                    |FROM
				                    |	Catalog.zoho_productCodeMap AS zoho_productCodeMap
				                    |WHERE
				                    |	zoho_productCodeMap.product_ref = &product_ref");
						   
				idQuery.SetParameter("product_ref", Lineitem.Product.Ref);
				productEx = idQuery.Execute();
				If productEx.IsEmpty() Then
					Return;
				EndIf;
				idProductResult = productEx.Unload();
									
				SIXML =	SIXML + "<product no=""" + count + """>"
					+ "<FL val=""Product Id"">" + idProductResult[0].zoho_id + "</FL>"
					+ "<FL val=""Quantity"">" + Lineitem.QtyUnits + "</FL>"
					+ "<FL val=""List Price"">" + StrReplace(String(Lineitem.PriceUnits),",","") + "</FL>"
					+ "<FL val=""Total"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
					+ "<FL val=""Total After Discount"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
					+ "<FL val=""Net Total"">" + StrReplace(String(Lineitem.LineTotal),",","") + "</FL>"
					+ "</product>";
					tempsubtotal = tempsubtotal + Lineitem.LineTotal; 
						
				count = count + 1;
		
			EndDo;
			SIXML = SIXML + "</FL>" + "<FL val=""Sub Total"">" + StrReplace(String(tempsubtotal),",","") + "</FL>";
			
			If SessionParameters.TenantValue <> "1100674" Then //AND SessionParameters.TenantValue <> "10" Then 
				//address detail
				//billto
				SIXML = SIXML
						+ "<FL val=""Billing Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine1) + "</FL>"
						+ "<FL val=""Billing City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.City) + "</FL>"
						+ "<FL val=""Billing State"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.State)) + "</FL>"
						+ "<FL val=""Billing Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.ZIP) + "</FL>"
						+ "<FL val=""Billing Country"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.Country)) + "</FL>";
				//shipto
				SIXML = SIXML
						+ "<FL val=""Shipping Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine1) + "</FL>"
						+ "<FL val=""Shipping City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.City) + "</FL>"
						+ "<FL val=""Shipping State"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.State)) + "</FL>"
						+ "<FL val=""Shipping Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.ZIP) + "</FL>"
						+ "<FL val=""Shipping Country"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.Country)) + "</FL>";
						
			Else
				//ferguson customs
				//billto
				If Ref.BillTo.Ref.FirstName <> "" AND Ref.BillTo.Ref.LastName <> "" Then
					custName = Ref.BillTo.Ref.FirstName + " " + Ref.BillTo.Ref.LastName;
				Else
					custName = Ref.BillTo.Ref.Description;
				EndIf;
				
				SIXML = SIXML
						+ "<FL val=""Customer Name Billing"">" + zoho_Functions.Zoho_XMLEncoding(custName) + "</FL>"
						+ "<FL val=""Billing Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine1) + "</FL>"
						+ "<FL val=""Billing Street 2"">" + zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.AddressLine2) + "</FL>"
						+ "<FL val=""Billing City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.City) + "</FL>"
						+ "<FL val=""BillingState"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.State)) + "</FL>"
						+ "<FL val=""Billing Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.BillTo.Ref.ZIP) + "</FL>"
						+ "<FL val=""BillingCountry"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.BillTo.Ref.Country)) + "</FL>";
				//shipto
				If Ref.ShipTo.Ref.FirstName <> "" AND Ref.ShipTo.Ref.LastName <> "" Then
					custName = Ref.ShipTo.Ref.FirstName + " " + Ref.ShipTo.Ref.LastName;
				Else
					custName = Ref.ShipTo.Ref.Description;
				EndIf;

				SIXML = SIXML
						+ "<FL val=""Customer Name Shipping"">" + zoho_Functions.Zoho_XMLEncoding(custName) + "</FL>"
						+ "<FL val=""Shipping Street"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine1) + "</FL>"
						+ "<FL val=""Shipping Street 2"">" + zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.AddressLine2) + "</FL>"
						+ "<FL val=""Shipping City"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.City) + "</FL>"
						+ "<FL val=""ShippingState"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.State)) + "</FL>"
						+ "<FL val=""Shipping Code"">" +  zoho_Functions.Zoho_XMLEncoding(Ref.ShipTo.Ref.ZIP) + "</FL>"
						+ "<FL val=""ShippingCountry"">" +  zoho_Functions.Zoho_XMLEncoding(String(Ref.ShipTo.Ref.Country)) + "</FL>";
			EndIf;
	
			//dropshipto
			If Ref.DropshipShipTo <> Catalogs.Addresses.EmptyRef() Then
			
				idQuery = new Query("SELECT
				                    |	zoho_contactCodeMap.zoho_id
				                    |FROM
				                    |	Catalog.zoho_contactCodeMap AS zoho_contactCodeMap
				                    |WHERE
				                    |	zoho_contactCodeMap.address_ref = &address_ref");
						   
				idQuery.SetParameter("address_ref", Ref.DropshipShipTo.Ref);
				idQueryResult = idQuery.Execute();
				If idQueryResult.IsEmpty() Then
					contact_id = "";
				Else
					idContactResult = idQueryResult.Unload();
					contact_id = idContactResult[0].zoho_id;
				EndIf;
				
				SIXML = SIXML + "<FL val=""CONTACTID"">" + contact_id + "</FL>";
							
			EndIf;
			
			SIXML = SIXML + "</row></Invoices>";
			
			AuthHeader = "authtoken=" + Constants.zoho_auth_token.Get() + "&scope=crmapi" + "&id=" + zohoID;
				
			URLstring = PathDef + "updateRecords?" + AuthHeader + "&xmlData=" + SIXML;
			
			HeadersMap = New Map();			
			HTTPRequest = New HTTPRequest("", HeadersMap);	
			SSLConnection = New OpenSSLSecureConnection();
			HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
			Result = HTTPConnection.Post(HTTPRequest);
		Else
			// no sales INVOICE to update in zoho;
			return;
		EndIf;
	EndIf;		
EndProcedure

Function Zoho_XMLEncoding(item) Export
	str = string(item);
	
	//xml encode first
	str = StrReplace(str,"&","&amp;");
	str = StrReplace(str,"<","&lt;");
	str = StrReplace(str,">","&gt;");
	str = StrReplace(str,"'","&apos;");
	str = StrReplace(str,"""","&quot;");
	// then url encode 
	str = StrReplace(str,"%","%25");
	str = StrReplace(str,"&","%26");
	str = StrReplace(str,"#","%23");
	str = StrReplace(str,"$","%24");
	str = StrReplace(str,"+","%2B");
	str = StrReplace(str,"=","%3D");
	str = StrReplace(str,"@","%40");
	str = StrReplace(str,":","%3A");
	str = StrReplace(str,"?","%3F");
	str = StrReplace(str,"/","%2F");
	str = StrReplace(str,",","%2C");
	
	return str;
EndFunction

