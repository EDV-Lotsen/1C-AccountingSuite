
&AtClient
Procedure getallref(Command)
	getallrefAtServer();
EndProcedure

&AtServer
Procedure getallrefAtServer()
	apiQuery = new Query("SELECT
	                     |	zoho_SICodeMap.Ref,
	                     |	zoho_SICodeMap.acs_api_code
	                     |FROM
	                     |	Catalog.zoho_SICodeMap AS zoho_SICodeMap");
					   
	queryResult = apiQuery.Execute().Unload();
	For each item in queryResult Do
		UpdatedSI = Documents.SalesInvoice.GetRef(New UUID(item.acs_api_code));
		MapRef = item.Ref.GetObject();
		MapRef.invoice_ref = UpdatedSI;
		MapRef.Write();
	EndDo;
EndProcedure
