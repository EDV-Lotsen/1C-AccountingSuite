
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
		
EndProcedure

Procedure BeforeWrite(Cancel)
	
	// Check possibility of adding assembly to the items list.
	If Ref <> Catalogs.Products.EmptyRef() Then
		
		// Create an array of subassemblies.
		CheckItems = LineItems.UnloadColumn("Product");
		I = CheckItems.Count() - 1;
		While I >= 0 Do
			If Not CheckItems[I].Assembly Then
				CheckItems.Delete(I);
			EndIf;
			I = I - 1;
		EndDo;
		
		// Perform check of all subassemblies.
		If CheckItems.Count() > 0 Then
			// Check possible parent of current item.
			Childs = Catalogs.Products.ItemIsParentAssembly(CheckItems, Ref);
			If Childs <> Undefined Then
				
				// Inform user about the errors.
				Errors = 0;
				For Each Child In Childs Do
					Errors = Errors + 1;
					If Errors <= 10 Then
						// Assembly already added to the another subassembly.
						MessageText = NStr("en = 'Cannot add the assembly %1 to the contents of %2 because %3 already added to %1.'");
						MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText,
						              Child.Key.Description, Description, Child.Value.Description);
					EndIf;
					CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
				EndDo;
				
				// Inform user about remaining errors.
				If Errors > 10 Then
					MessageText = NStr("en = 'There are also %1 error(s) found'");
					MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, Format(Errors-10, "NFD=0; NG=0"));
					CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
				EndIf;
				
				// Stop writing.
				Return;
			EndIf;
		EndIf;
	EndIf;
	
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
