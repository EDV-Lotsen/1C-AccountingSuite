
Procedure BeforeWrite(Cancel)
	
	// for webhooks
	If NewObject = True Then
		NewObject = False
	Else
		If Ref = Catalogs.Companies.EmptyRef() Then
			NewObject = True;
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	//companies_url = Constants.companies_webhook.Get();
	//
	//If NOT companies_url = "" Then
	//	
	//	WebhookMap = GeneralFunctions.ReturnCompanyObjectMap(Ref);
	//	WebhookMap.Insert("resource","companies");
	//	If NewObject = True Then
	//		WebhookMap.Insert("action","create");
	//	Else
	//		WebhookMap.Insert("action","update");
	//	EndIf;
	//	WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
	//	
	//	WebhookParams = New Array();
	//	WebhookParams.Add(companies_url);
	//	WebhookParams.Add(WebhookMap);
	//	LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	//
	//EndIf;
	//
	//email_companies_webhook = Constants.companies_webhook_email.Get();
	//
	//If NOT email_companies_webhook = "" Then
	////If true then			
	//	WebhookMap2 = GeneralFunctions.ReturnCompanyObjectMap(Ref);
	//	WebhookMap2.Insert("resource","companies");
	//	If NewObject = True Then
	//		WebhookMap2.Insert("action","create");
	//	Else
	//		WebhookMap2.Insert("action","update");
	//	EndIf;
	//	WebhookMap2.Insert("apisecretkey",Constants.APISecretKey.Get());
	//	
	//	WebhookParams2 = New Array();
	//	WebhookParams2.Add(email_companies_webhook);
	//	WebhookParams2.Add(WebhookMap2);
	//	LongActions.ExecuteInBackground("GeneralFunctions.EmailWebhook", WebhookParams2);
	//	
	//EndIf;
	
	// zapier webhooks
	
	Query = New Query("SELECT
	                  |	ZapierWebhooks.Description
	                  |FROM
	                  |	Catalog.ZapierWebhooks AS ZapierWebhooks
	                  |WHERE
	                  |	ZapierWebhooks.Code = ""new_customer_webhook""");
					  
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then		
	Else
		
		WebhookMap = New Map(); 
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		WebhookMap.Insert("resource","companies");
		If NewObject = True Then
			WebhookMap.Insert("action","create");
		Else
			WebhookMap.Insert("action","update");
		EndIf;
		WebhookMap.Insert("company_code",Ref.Code);
		WebhookMap.Insert("company_name",Ref.Description);

		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			WebhookParams = New Array();
			WebhookParams.Add(Selection.Description);
			WebhookParams.Add(WebhookMap);
			LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
			
		EndDo;						
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	companies_webhook = Constants.companies_webhook.Get();
	
	If NOT companies_webhook = "" Then
		
		//double_slash = Find(companies_webhook, "//");
		//
		//companies_webhook = Right(companies_webhook,StrLen(companies_webhook) - double_slash - 1);
		//
		//first_slash = Find(companies_webhook, "/");
		//webhook_address = Left(companies_webhook,first_slash - 1);
		//webhook_resource = Right(companies_webhook,StrLen(companies_webhook) - first_slash + 1); 		
		
		WebhookMap = New Map(); 
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		WebhookMap.Insert("resource","companies");
		WebhookMap.Insert("action","delete");
		WebhookMap.Insert("api_code",String(Ref.UUID()));
		
		WebhookParams = New Array();
		WebhookParams.Add(Constants.companies_webhook.Get());
		WebhookParams.Add(WebhookMap);
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	
	EndIf;

EndProcedure

