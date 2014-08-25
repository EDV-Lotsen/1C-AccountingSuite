// for when a product in zoho is created and a webhook gets sent to ACS
Function zoho_product(jsonin)
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);

	//Create a product in ACS
	NewProduct = Catalogs.Products.CreateItem();
	Try
		NewProduct.Code = ParsedJSON.product_code;
	Except
		Return "Fail: No product_code";
	EndTry;
	Try
		NewProduct.Description = ParsedJSON.product_name;
	Except
		Return "Fail: No product_name";
	EndTry;
	
	//make type product and follow it up with needed product settings
	NewProduct.Type = Enums.InventoryTypes.Inventory;
	NewProduct.CostingMethod = Enums.InventoryCosting.WeightedAverage;
	NewProduct.InventoryOrExpenseAccount = Constants.InventoryAccount.Get();
	
	//Start of optional fields
	Try // check for product category
		If ParsedJSON.product_category <> "" Then
			CatQuery = new Query("SELECT
			                     |	ProductCategories.Ref
			                     |FROM
			                     |	Catalog.ProductCategories AS ProductCategories
			                     |WHERE
			                     |	ProductCategories.Description = &Description");
							   
			CatQuery.SetParameter("Description", ParsedJSON.product_category);
			CatResult = CatQuery.Execute();
			If CatResult.IsEmpty() Then
				// Category is new
				NewCategory = Catalogs.ProductCategories.CreateItem();
				NewCategory.Description = ParsedJSON.product_category;
				NewCategory.Write();
				NewProduct.Category = NewCategory.Ref;
			Else
				// category exists
				item_cat = CatResult.Unload();
				NewProduct.Category = item_cat[0].Ref;
			EndIf;
		EndIf;
	Except
	EndTry;
		
	Try // check for taxable field
		If ParsedJSON.taxable = "false" Then
			NewProduct.Taxable = False;
		Else
			NewProduct.Taxable = True;
		EndIf;
	Except
	EndTry;
	
	Try // add unit price as object.price
		If ParsedJSON.unit_price <> "0.0" Then
			NewProduct.Price = Number(ParsedJSON.unit_price);
		EndIf;
	Except
	EndTry;
	
	Try // check for unit of measure
		If ParsedJSON.usage_unit <> "" Then
			UMQuery = new Query("SELECT
			                    |	UnitSets.Ref
			                    |FROM
			                    |	Catalog.UnitSets AS UnitSets
			                    |WHERE
			                    |	UnitSets.DefaultReportUnit.Description = &Description");
							   
			UMQuery.SetParameter("Description", ParsedJSON.usage_unit);
			UMResult = UMQuery.Execute();
			If UMResult.IsEmpty() Then
				// UM is new
				NewUMset = Catalogs.UnitSets.CreateItem();
				NewUMset.Description = ParsedJSON.usage_unit;
				//newUM = Catalogs.Units.CreateItem();
				//newUM.Description = ParsedJSON.usage_unit;
				//newUM.Write();
				//NewUMset.DefaultReportUnit = newUM.Ref;	
				NewUMset.Write();
				NewProduct.UnitSet = NewUMset.Ref;
			Else
				// category exists
				item_um = UMResult.Unload();
				NewProduct.UnitSet = item_um[0].Ref;
			EndIf;
		EndIf;
	Except
	EndTry;
		
	newProduct.Write();
	
	//create a record of the acs_apicode to zoho id mapping
	newRecord = Catalogs.zoho_productCodeMap.CreateItem();
	newRecord.acs_api_code = newProduct.Ref.UUID();
	Try 
		newRecord.zoho_id = ParsedJSON.product_id;
	Except
		Return "Fail: No zoho id";
	EndTry;
	newRecord.Write();
	
	Return "Success";
		
EndFunction

// for when a product in zoho gets updated
Function zoho_product_update(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	//get item uuid to update in acs
	apiQuery = new Query("SELECT
	                     |	zoho_productCodeMap.acs_api_code
	                     |FROM
	                     |	Catalog.zoho_productCodeMap AS zoho_productCodeMap
	                     |WHERE
	                     |	zoho_productCodeMap.zoho_id = &zoho_id");
					   
	apiQuery.SetParameter("zoho_id", ParsedJSON.product_id);
	queryResult = apiQuery.Execute();
	
	If NOT queryResult.IsEmpty() Then
		queryResultobj = queryResult.Unload();
		UpdatedProduct = Catalogs.Products.GetRef(New UUID(queryResultobj[0].acs_api_code));
		UpdatedProductObj = UpdatedProduct.GetObject();
		Try  // possible might break because of uniqueness problems or no update fields passed
			Try UpdatedProductObj.Code = ParsedJSON.product_code; Except EndTry;
			Try UpdatedProductObj.Description = ParsedJSON.product_name; Except EndTry; 
		Except
			Return "Failed to update";
		EndTry;
		//Start of optional fields
		Try // check for product category
			If ParsedJSON.product_category <> "" Then
				CatQuery = new Query("SELECT
				                     |	ProductCategories.Ref
				                     |FROM
				                     |	Catalog.ProductCategories AS ProductCategories
				                     |WHERE
				                     |	ProductCategories.Description = &Description");
								   
				CatQuery.SetParameter("Description", ParsedJSON.product_category);
				CatResult = CatQuery.Execute();
				If CatResult.IsEmpty() Then
					// Category is new
					NewCategory = Catalogs.ProductCategories.CreateItem();
					NewCategory.Description = ParsedJSON.product_category;
					NewCategory.Write();
					UpdatedProductObj.Category = NewCategory.Ref;
				Else
					// category exists
					item_cat = CatResult.Unload();
					UpdatedProductObj.Category = item_cat[0].Ref;
				EndIf;
			Else
				UpdatedProductObj.Category = Catalogs.ProductCategories.EmptyRef();
			EndIf;
		Except
		EndTry;
		
		Try // check for taxable field
			If ParsedJSON.taxable = "false" Then
				UpdatedProductObj.Taxable = False;
			Else
				UpdatedProductObj.Taxable = True;
			EndIf;
		
		Except
		EndTry;
	
		Try // add unit price as object.price
			If ParsedJSON.unit_price <> "0.0" Then
				UpdatedProductObj.Price = Number(ParsedJSON.unit_price);
			EndIf;
		Except
		EndTry;
		
		Try // check for unit of measure
			If ParsedJSON.usage_unit <> "" Then
				UMQuery = new Query("SELECT
				                    |	UnitSets.Ref
				                    |FROM
				                    |	Catalog.UnitSets AS UnitSets
				                    |WHERE
				                    |	UnitSets.DefaultReportUnit.Description = &Description");
								   
				UMQuery.SetParameter("Description", ParsedJSON.usage_unit);
				UMResult = UMQuery.Execute();
				If UMResult.IsEmpty() Then
					// UM is new
					NewUMset = Catalogs.UnitSets.CreateItem();
					NewUMset.Description = ParsedJSON.usage_unit;
					newUM = Catalogs.Units.CreateItem();
					newUM.Description = ParsedJSON.usage_unit;
					newUM.Write();
					NewUMset.DefaultReportUnit = newUM.Ref;	
					NewUMset.Write();
					UpdatedProductObj.UnitSet = NewUMset.Ref;
				Else
					// um exists
					item_um = UMResult.Unload();
					UpdatedProductObj.UnitSet = item_um[0].Ref;
				EndIf;
			EndIf;
		Except
		EndTry;

	Else
		Return "couldnt find item to update.";
	EndIf;
	
	UpdatedProductObj.Write();
	Return "Success";

EndFunction
