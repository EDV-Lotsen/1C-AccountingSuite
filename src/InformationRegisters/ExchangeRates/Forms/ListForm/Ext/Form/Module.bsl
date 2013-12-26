
&AtClient
Procedure UpdateRates(Command)
	
	UpdateRatesServer();
		
EndProcedure
				  
Procedure UpdateRatesServer()
	
	HeadersMap = New Map();
	
	HTTPRequest = New HTTPRequest("/api/latest.json?app_id=" + ServiceParameters.OpenExchangeRatesAppID());
	
	HTTPConnection = New HTTPConnection("openexchangerates.org",,,,,,);
	Result = HTTPConnection.Post(HTTPRequest);
	ResponseBody = Result.GetBodyAsString(TextEncoding.UTF8);
	ResponseJSON = InternetConnectionClientServer.DecodeJSON(ResponseBody);
	Rates = ResponseJSON.rates;
	
	DefaultCurrency = Constants.DefaultCurrency.Get();
	
	Query = New Query("SELECT
	                  |	Currencies.Ref,
	                  |	Currencies.Description
	                  |FROM
	                  |	Catalog.Currencies AS Currencies
	                  |WHERE
	                  |	Currencies.Ref <> &DefaultCurrency");
					  
	Query.Parameters.Insert("DefaultCurrency", DefaultCurrency);

	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then		
	Else
		Selection = QueryResult.Choose();
		While Selection.Next() Do
			
			Rate = 1;
			CurrencyCode = Selection.Description;
			
			If Constants.DefaultCurrency.Get() = Catalogs.Currencies.USD Then
			
				Try
					Rates.Property(CurrencyCode,Rate);
					RateInverse = 1 / Rate;
					
					RecordManager = InformationRegisters.ExchangeRates.CreateRecordManager();
					RecordManager.Period = CurrentDate();
					RecordManager.Currency = Catalogs.Currencies.FindByDescription(CurrencyCode); 
					RecordManager.Rate = RateInverse; 
					RecordManager.Write();
				Except
				EndTry
				
			Else
				
				Try
				
					Rates.Property(DefaultCurrency.Description,Rate);
					DefaultCurrencyRate = Rate;
					Rates.Property(CurrencyCode,Rate);
					RowCurrencyRate = Rate;
					
					RateInverse = DefaultCurrencyRate / RowCurrencyRate;
					
					RecordManager = InformationRegisters.ExchangeRates.CreateRecordManager();
					RecordManager.Period = CurrentDate();
					RecordManager.Currency = Catalogs.Currencies.FindByDescription(CurrencyCode); 
					RecordManager.Rate = RateInverse; 
					RecordManager.Write();
				Except
				EndTry
				
			EndIf;
			
		EndDo;						
	EndIf;

	Items.List.Refresh();
					  
EndProcedure
