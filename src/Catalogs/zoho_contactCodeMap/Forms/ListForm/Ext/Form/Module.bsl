
&AtClient
Procedure getallref(Command)
	getallrefAtServer();
EndProcedure

&AtServer
Procedure getallrefAtServer()
	apiQuery = new Query("SELECT
	                     |	zoho_contactCodeMap.Ref,
	                     |	zoho_contactCodeMap.acs_api_code
	                     |FROM
	                     |	Catalog.zoho_contactCodeMap AS zoho_contactCodeMap");
					   
	queryResult = apiQuery.Execute().Unload();
	For each item in queryResult Do
		UpdatedAddr = Catalogs.Addresses.GetRef(New UUID(item.acs_api_code));
		MapRef = item.Ref.GetObject();
		MapRef.address_ref = UpdatedAddr;
		MapRef.Write();
	EndDo;
EndProcedure
