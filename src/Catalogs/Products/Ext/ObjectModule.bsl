


Procedure OnWrite(Cancel)
	
	//companies_webhook = Constants.items_webhook.Get();
	//
	//If NOT companies_webhook = "" Then
	//	
	//	//double_slash = Find(companies_webhook, "//");
	//	//
	//	//companies_webhook = Right(companies_webhook,StrLen(companies_webhook) - double_slash - 1);
	//	//
	//	//first_slash = Find(companies_webhook, "/");
	//	//webhook_address = Left(companies_webhook,first_slash - 1);
	//	//webhook_resource = Right(companies_webhook,StrLen(companies_webhook) - first_slash + 1); 		
	//			
	//	//WebhookMap = New Map(); 
	//	//WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
	//	//WebhookMap.Insert("resource","items");
	//	//If NewObject = True Then
	//	//	WebhookMap.Insert("action","create");
	//	//Else
	//	//	WebhookMap.Insert("action","update");
	//	//EndIf;
	//	//WebhookMap.Insert("api_code",String(Ref.UUID()));
	//	//WebhookMap.Insert("item_code",Ref.Code);
	//	//WebhookMap.Insert("item_description",Ref.Description);
	//	
	//	WebhookMap = GeneralFunctions.ReturnProductObjectMap(Ref);
	//	WebhookMap.Insert("resource","items");
	//	If NewObject = True Then
	//		WebhookMap.Insert("action","create");
	//	Else
	//		WebhookMap.Insert("action","update");
	//	EndIf;
	//	WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
	//	WebhookParams = New Array();
	//	WebhookParams.Add(Constants.items_webhook.Get());
	//	WebhookParams.Add(WebhookMap);
	//	LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	//
	//EndIf;
	//
	//// Insert handler code.
	//
	////HeadersMap = New Map();
	////HeadersMap.Insert("Authorization", "Basic " + ServiceParameters.BigCommerceAuth());
	////
	////HTTPRequest = New HTTPRequest("products/78.json", HeadersMap);
	//////HTTPRequest.SetBodyFromString("product=" + ThisObject.Description,TextEncoding.ANSI);
	////
	////SSLConnection = New OpenSSLSecureConnection();
	////
	////HTTPConnection = New HTTPConnection("store-dshn8.mybigcommerce.com/api/v2/",,,,,,SSLConnection);
	////Result = HTTPConnection.Get(HTTPRequest);
	////ResponseBody = Result.GetBodyAsString(TextEncoding.UTF8);
	////			
	////Message("Sent /bigcomproduct request");
	//
	//// zapier webhooks
	//
	//Query = New Query("SELECT
	//				  |	ZapierWebhooks.Description
	//				  |FROM
	//				  |	Catalog.ZapierWebhooks AS ZapierWebhooks
	//				  |WHERE
	//				  |	ZapierWebhooks.Code = ""new_item_webhook""");
	//				  
	//QueryResult = Query.Execute();
	//If QueryResult.IsEmpty() Then		
	//Else
	//	
	//	WebhookMap = New Map(); 
	//	WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
	//	WebhookMap.Insert("resource","items");
	//	If NewObject = True Then
	//		WebhookMap.Insert("action","create");
	//	Else
	//		WebhookMap.Insert("action","update");
	//	EndIf;
	//	WebhookMap.Insert("api_code",Ref.api_code);
	//	WebhookMap.Insert("item_code",Ref.Code);
	//	WebhookMap.Insert("item_description",Ref.Description);
	//	
	//	Selection = QueryResult.Choose();
	//	While Selection.Next() Do
	//		
	//		WebhookParams = New Array();
	//		WebhookParams.Add(Selection.Description);
	//		WebhookParams.Add(WebhookMap);
	//		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	//		
	//	EndDo;						
	//EndIf;
	

EndProcedure

Procedure BeforeWrite(Cancel)
	
	// for webhooks
	If NewObject = True Then
		NewObject = False
	Else
		If Ref = Catalogs.Products.EmptyRef() Then
			NewObject = True;
		EndIf;
	EndIf;

EndProcedure

Procedure BeforeDelete(Cancel)
	
	companies_webhook = Constants.items_webhook.Get();
	
	If NOT companies_webhook = "" Then
		
		//double_slash = Find(companies_webhook, "//");
		//
		//companies_webhook = Right(companies_webhook,StrLen(companies_webhook) - double_slash - 1);
		//
		//first_slash = Find(companies_webhook, "/");
		//webhook_address = Left(companies_webhook,first_slash - 1);
		//webhook_resource = Right(companies_webhook,StrLen(companies_webhook) - first_slash + 1); 		
		
		WebhookMap = GeneralFunctions.ReturnProductObjectMap(Ref);
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		WebhookMap.Insert("resource","items");
		WebhookMap.Insert("action","delete");
		WebhookParams = New Array();
		WebhookParams.Add(Constants.items_webhook.Get());
		WebhookParams.Add(WebhookMap);
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);

		
		//WebhookMap = New Map(); 
		//WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		//WebhookMap.Insert("resource","items");
		//WebhookMap.Insert("action","delete");
		//WebhookMap.Insert("api_code",String(Ref.UUID()));
		//
		//WebhookParams = New Array();
		//WebhookParams.Add(Constants.items_webhook.Get());
		//WebhookParams.Add(WebhookMap);
		//LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	
	EndIf;

EndProcedure


