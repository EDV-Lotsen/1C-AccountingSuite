
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
		If NewObject = True Then
			WebhookMap.Insert("action","create");
		Else
			WebhookMap.Insert("action","update");
		EndIf;
		WebhookMap.Insert("company_code",Ref.Code);
		WebhookMap.Insert("company_name",Ref.Description);
		
		WebhookParams = New Array();
		WebhookParams.Add(Constants.companies_webhook.Get());
		//WebhookParams.Add(webhook_resource);
		WebhookParams.Add(WebhookMap);
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	companies_webhook = Constants.companies_webhook.Get();
	
	If NOT companies_webhook = "" Then
		
		double_slash = Find(companies_webhook, "//");
		
		companies_webhook = Right(companies_webhook,StrLen(companies_webhook) - double_slash - 1);
		
		first_slash = Find(companies_webhook, "/");
		webhook_address = Left(companies_webhook,first_slash - 1);
		webhook_resource = Right(companies_webhook,StrLen(companies_webhook) - first_slash + 1); 		
		
		WebhookMap = New Map(); 
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		WebhookMap.Insert("resource","companies");
		WebhookMap.Insert("action","delete");
		WebhookMap.Insert("company_code",Ref.Code);
		
		WebhookParams = New Array();
		WebhookParams.Add(webhook_address);
		WebhookParams.Add(webhook_resource);
		WebhookParams.Add(WebhookMap);
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	
	EndIf;

EndProcedure




