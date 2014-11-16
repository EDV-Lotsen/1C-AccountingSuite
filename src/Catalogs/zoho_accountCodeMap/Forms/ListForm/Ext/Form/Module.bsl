
&AtClient
Procedure getallref(Command)
	getallrefAtServer();
EndProcedure

&AtServer
Procedure getallrefAtServer()
	apiQuery = new Query("SELECT
	                     |	zoho_accountCodeMap.Ref,
	                     |	zoho_accountCodeMap.acs_api_code
	                     |FROM
	                     |	Catalog.zoho_accountCodeMap AS zoho_accountCodeMap");
					   
	queryResult = apiQuery.Execute().Unload();
	For each item in queryResult Do
		UpdatedCompany = Catalogs.Companies.GetRef(New UUID(item.acs_api_code));
		MapRef = item.Ref.GetObject();
		MapRef.company_ref = UpdatedCompany;
		MapRef.Write();
	EndDo;
EndProcedure
