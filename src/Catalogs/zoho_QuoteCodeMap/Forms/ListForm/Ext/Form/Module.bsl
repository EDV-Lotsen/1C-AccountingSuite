
&AtClient
Procedure getallref(Command)
	getallrefAtServer();
EndProcedure

&AtServer
Procedure getallrefAtServer()
	apiQuery = new Query("SELECT
	                     |	zoho_QuoteCodeMap.Ref,
	                     |	zoho_QuoteCodeMap.acs_api_code
	                     |FROM
	                     |	Catalog.zoho_QuoteCodeMap AS zoho_QuoteCodeMap");
					   
	queryResult = apiQuery.Execute().Unload();
	For each item in queryResult Do
		UpdatedQuote = Documents.Quote.GetRef(New UUID(item.acs_api_code));
		MapRef = item.Ref.GetObject();
		MapRef.quote_ref = UpdatedQuote;
		MapRef.Write();
	EndDo;
EndProcedure
