
Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	// Forced assign the new catalog number.
	//If ThisObject.IsNew() And Not ValueIsFilled(ThisObject.Number) Then ThisObject.SetNewNumber(); EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	// zapier webhooks
	Query = New Query("SELECT
					  |	ZapierWebhooks.Description
					  |FROM
					  |	Catalog.ZapierWebhooks AS ZapierWebhooks
					  |WHERE
					  |	ZapierWebhooks.Code = ""new_item_webhook""");
					  
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then		
	Else
		
		WebhookMap = New Map(); 
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		WebhookMap.Insert("resource","items");
		If NewObject = True Then
			WebhookMap.Insert("action","create");
		Else
			WebhookMap.Insert("action","update");
		EndIf;
		//WebhookMap.Insert("api_code",Ref.api_code);
		WebhookMap.Insert("item_code",Ref.Code);
		WebhookMap.Insert("item_description",Ref.Description);
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			WebhookParams = New Array();
			WebhookParams.Add(Selection.Description);
			WebhookParams.Add(WebhookMap);
			LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
			
		EndDo;						
	EndIf;
	
	items_url = Constants.items_webhook.Get();
	
	If NOT items_url = "" Then
		
		WebhookMap = GeneralFunctions.ReturnProductObjectMap(Ref);
		WebhookMap.Insert("resource","items");
		If NewObject = True Then
			WebhookMap.Insert("action","create");
		Else
			WebhookMap.Insert("action","update");
		EndIf;
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		
		WebhookParams = New Array();
		WebhookParams.Add(items_url);
		WebhookParams.Add(WebhookMap);
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
	
	EndIf;
	
	email_items_webhook = Constants.items_webhook_email.Get();
	
	If NOT email_items_webhook = "" Then
	//If true then			
		WebhookMap2 = GeneralFunctions.ReturnProductObjectMap(Ref);
		WebhookMap2.Insert("resource","items");
		If NewObject = True Then
			WebhookMap2.Insert("action","create");
		Else
			WebhookMap2.Insert("action","update");
		EndIf;
		WebhookMap2.Insert("apisecretkey",Constants.APISecretKey.Get());
		
		WebhookParams2 = New Array();
		WebhookParams2.Add(email_items_webhook);
		WebhookParams2.Add(WebhookMap2);
		LongActions.ExecuteInBackground("GeneralFunctions.EmailWebhook", WebhookParams2);
		
	EndIf;
	
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
