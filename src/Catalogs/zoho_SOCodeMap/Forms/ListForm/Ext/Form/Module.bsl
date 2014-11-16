
&AtClient
Procedure getallref(Command)
	getallrefAtServer();
EndProcedure

&AtServer
Procedure getallrefAtServer()
	apiQuery = new Query("SELECT
	                     |	zoho_SOCodeMap.Ref,
	                     |	zoho_SOCodeMap.acs_api_code
	                     |FROM
	                     |	Catalog.zoho_SOCodeMap AS zoho_SOCodeMap");
					   
	queryResult = apiQuery.Execute().Unload();
	For each item in queryResult Do
		UpdatedSO = Documents.SalesOrder.GetRef(New UUID(item.acs_api_code));
		MapRef = item.Ref.GetObject();
		MapRef.salesorder_ref = UpdatedSO;
		MapRef.Write();
	EndDo;
EndProcedure
