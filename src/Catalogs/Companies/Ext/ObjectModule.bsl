
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
	
	//Clear Bank Transaction Categorization
	SetPrivilegedMode(True);
	Request = New Query("SELECT
	                    |	BankTransactionCategorization.TransactionID
	                    |FROM
	                    |	InformationRegister.BankTransactionCategorization AS BankTransactionCategorization
	                    |WHERE
	                    |	BankTransactionCategorization.Customer = &Customer
	                    |
	                    |GROUP BY
	                    |	BankTransactionCategorization.TransactionID");
	Request.SetParameter("Customer", Ref);
	IdsTable = Request.Execute().Unload();
	For Each IDRow In IdsTable Do
		BTCRecordset = InformationRegisters.BankTransactionCategorization.CreateRecordSet();
		BTCRecordset.Filter.TransactionID.Set(IDRow.TransactionID);
		BTCRecordset.Write(True);
	EndDo;
	SetPrivilegedMode(False);
	
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

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If ThisObject.IsNew() And Not ValueIsFilled(ThisObject.Code) Then ThisObject.SetNewCode(); EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If ThisObject.IsNew() Then ThisObject.SetNewCode(); EndIf;
	
EndProcedure

Procedure OnSetNewCode(StandardProcessing, Prefix)
	
	StandardProcessing = False;
	
	Numerator = Catalogs.DocumentNumbering.Companies;
	NextNumber = GeneralFunctions.Increment(Numerator.Number);
	
	While Catalogs.Companies.FindByCode(NextNumber) <> Catalogs.Companies.EmptyRef() And NextNumber <> "" Do
		ObjectNumerator = Numerator.GetObject();
		ObjectNumerator.Number = NextNumber;
		ObjectNumerator.Write();
		
		NextNumber = GeneralFunctions.Increment(NextNumber);
	EndDo;
	
	ThisObject.Code = NextNumber; 
	
EndProcedure