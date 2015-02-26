
&AtClient
Procedure getallref(Command)
	getallrefAtServer();
EndProcedure

&AtServer
Procedure getallrefAtServer()
	apiQuery = new Query("SELECT
	                     |	zoho_productCodeMap.Ref,
	                     |	zoho_productCodeMap.acs_api_code
	                     |FROM
	                     |	Catalog.zoho_productCodeMap AS zoho_productCodeMap");
					   
	queryResult = apiQuery.Execute().Unload();
	For each item in queryResult Do
		UpdatedProduct = Catalogs.Products.GetRef(New UUID(item.acs_api_code));
		MapRef = item.Ref.GetObject();
		MapRef.product_ref = UpdatedProduct;
		MapRef.Write();
	EndDo;
		
EndProcedure
