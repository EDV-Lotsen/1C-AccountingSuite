
&AtClient
Procedure getallref(Command)
	getallrefAtServer();
EndProcedure

&AtServer
Procedure getallrefAtServer()
	apiQuery = new Query("SELECT
	                     |	zoho_pricebookCodeMap.Ref,
	                     |	zoho_pricebookCodeMap.acs_api_code
	                     |FROM
	                     |	Catalog.zoho_pricebookCodeMap AS zoho_pricebookCodeMap");
					   
	queryResult = apiQuery.Execute().Unload();
	For each item in queryResult Do
		UpdatedPL = Catalogs.PriceLevels.GetRef(New UUID(item.acs_api_code));
		MapRef = item.Ref.GetObject();
		MapRef.pricelevel_ref = UpdatedPL;
		MapRef.Write();
	EndDo;
EndProcedure
