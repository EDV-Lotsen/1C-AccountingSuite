
Procedure BeforeDelete(Cancel)
	If DataExchange.Load Then
		return;
	EndIf;
	// If the current SalesTaxRate is a component of the combined tax rate then
	// refresh the rate of the combined sales tax rate item.
	If Not ThisObject.AdditionalProperties.Property("DoNotProcessParentObject") Then
		If ValueIsFilled(ThisObject.Parent) Then
			ParentObject = ThisObject.Parent.GetObject();
			ParentObject.Rate = ParentObject.Rate - ThisObject.Rate;
			ParentObject.Write();
		EndIf;
	EndIf;
EndProcedure

Procedure BeforeWrite(Cancel)
	If DataExchange.Load Then
		return;
	EndIf;
	If ThisObject.IsNew() Then
		If (Not CombinedTaxRate) And (Not ValueIsFilled(Parent)) Then
			//Check the uniqueness of the tax name
			STCLock = New DataLock();
			STCLockItem = STCLock.Add("Catalog.SalesTaxRates");
			STCLockItem.Mode = DataLockMode.Exclusive;
			STCLock.Lock();
			Request = New Query("SELECT
			                    |	SalesTaxRates.Ref
			                    |FROM
			                    |	Catalog.SalesTaxRates AS SalesTaxRates
			                    |WHERE
			                    |	SalesTaxRates.Description = &Description
			                    |	AND SalesTaxRates.Ref <> &ThisRef
			                    |	AND SalesTaxRates.Parent = VALUE(Catalog.SalesTaxRates.EmptyRef)");
			Request.SetParameter("Description", Description);
			Request.SetParameter("ThisRef", Ref);
			// Duplicates found
			If Not Request.Execute().IsEmpty() Then
				Cancel = True;
				Message = New UserMessage();
				Message.SetData(ThisObject);
				Message.Text=NStr("en = 'Tax name is not unique!'");
				Message.Field = "Description";
				Message.Message();
			EndIf;
		ElsIf CombinedTaxRate Then //If CombinedRate
			Agency 				= Catalogs.SalesTaxAgencies.EmptyRef();
			SalesTaxComponent 	= Catalogs.SalesTaxComponents.EmptyRef(); 
			//Check the uniqueness of the tax name
			STCLock = New DataLock();
			STCLockItem = STCLock.Add("Catalog.SalesTaxRates");
			STCLockItem.Mode = DataLockMode.Exclusive;
			STCLock.Lock();
			Request = New Query("SELECT
			                    |	SalesTaxRates.Ref
			                    |FROM
			                    |	Catalog.SalesTaxRates AS SalesTaxRates
			                    |WHERE
			                    |	SalesTaxRates.Description = &Description
			                    |	AND SalesTaxRates.Ref <> &ThisRef");
			Request.SetParameter("Description", Description);
			Request.SetParameter("ThisRef", Ref);
			// Duplicates found
			If Not Request.Execute().IsEmpty() Then
				Cancel = True;
				Message = New UserMessage();
				Message.SetData(ThisObject);
				Message.Text=NStr("en = 'Tax name is not unique!'");
				Message.Field = "Description";
				Message.Message();
			EndIf;
		EndIf;	
	EndIf;
	// If sales tax component is new - then create a new sales tax component
	If ValueIsFilled(SalesTaxComponent) And (Not CombinedTaxRate) Then
		Description = SalesTaxComponent.Description;
		Agency		= SalesTaxComponent.Agency;
		Rate		= SalesTaxComponent.Rate; 		
		return;
	ElsIf (CombinedTaxRate) Then
		return;
	EndIf;
	
	If Cancel = True Then
		return;
	EndIf;
	
	STCLock = New DataLock();
	STCLockItem = STCLock.Add("Catalog.SalesTaxComponents");
	STCLockItem.Mode = DataLockMode.Exclusive;
	STCLock.Lock();
	
	Request = New Query("SELECT
	                    |	SalesTaxComponents.Ref,
	                    |	SalesTaxComponents.Description,
	                    |	SalesTaxComponents.Agency,
	                    |	SalesTaxComponents.Rate
	                    |FROM
	                    |	Catalog.SalesTaxComponents AS SalesTaxComponents
	                    |WHERE
	                    |	SalesTaxComponents.Description = &Description");
	Request.SetParameter("Description", Description);
	Result = Request.Execute();
	If Not Result.IsEmpty() Then
		Sel = Result.Select();
		Sel.Next();
		Agency  = Sel.Agency;
		Rate	= Sel.Rate;
		SalesTaxComponent = Sel.Ref;
	Else
		SalesTaxComponentObject = Catalogs.SalesTaxComponents.CreateItem();
		SalesTaxComponentObject.Description = Description;
		SalesTaxComponentObject.Agency		= Agency;
		SalesTaxComponentObject.Rate		= Rate;
		SalesTaxComponentObject.Write();
		SalesTaxComponent					= SalesTaxComponentObject.Ref;
	EndIf;
	
EndProcedure
