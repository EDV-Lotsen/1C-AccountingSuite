
////////////////////////////////////////////////////////////////////////////////
// Unit sets: Item form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Set filter for units in set.
	CommonUseClientServer.SetFilterItem(Units.Filter, "Owner",    Object.Ref, DataCompositionComparisonType.Equal,    "Owner",     True, DataCompositionSettingsItemViewMode.Auto);
	CommonUseClientServer.SetFilterItem(Units.Filter, "BaseUnit", True,       DataCompositionComparisonType.NotEqual, "Base unit", True, DataCompositionSettingsItemViewMode.Auto);
	
	// Update owned items accessibility.
	ObjSaved = Not Object.Ref.IsEmpty();
	Items.RelatedUnits.Enabled = ObjSaved;
	Items.DefaultUnits.Enabled = ObjSaved;
	
	UpdateInformationBaseUnit();
	
	// Update quantities presentation.
	QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.UnitsFactor.Format = QuantityFormat;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Add new object flag.
	WriteParameters.Insert("IsNew", CurrentObject.IsNew());
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Create new unit and assign it as default unit for the set.
	If WriteParameters.IsNew Then
		
		// Update units list filter.
		CommonUseClientServer.SetFilterItem(Units.Filter, "Owner", CurrentObject.Ref, DataCompositionComparisonType.Equal, "Owner", True, DataCompositionSettingsItemViewMode.Auto);
		
		// Update owned items accessibility.
		Items.RelatedUnits.Enabled = True;
		Items.DefaultUnits.Enabled = True;
		
		// Create default unit.
		DefaultUnit = Catalogs.Units.CreateItem();
		DefaultUnit.Owner       = CurrentObject.Ref;   // Set name
		DefaultUnit.Code        = BaseUnitAbbreviation;// Abbreviation
		DefaultUnit.Description = BaseUnitName;        // Unit name
		DefaultUnit.BaseUnit    = True;                // Base ref of set
		DefaultUnit.Factor      = 1;
		DefaultUnit.Write();
		
		// Update item with new units.
		CurrentObject.DefaultReportUnit = DefaultUnit.Ref;
		If  CurrentObject.DefaultSaleUnit.IsEmpty() Then
			CurrentObject.DefaultSaleUnit = DefaultUnit.Ref;
		EndIf;
		If  CurrentObject.DefaultPurchaseUnit.IsEmpty() Then
			CurrentObject.DefaultPurchaseUnit = DefaultUnit.Ref;
		EndIf;
		CurrentObject.Write();
		
		// Reread filled object to form
		ValueToFormAttribute(CurrentObject, "Object");
		
		UpdateInformationBaseUnit();
		
	Else
		//// Check base unit update.
		//QueryText = "
		//|SELECT
		//|	Ref
		//|FROM
		//|	Catalog.Units
		//|WHERE
		//|	       Owner = &Ref
		//|AND    BaseUnit = True
		//|AND      Factor = 1";
		//
		//// Get default set unit which corresponds to the base unit.
		//Query = New Query(QueryText);
		//Query.SetParameter("Ref", CurrentObject.Ref);
		//Result = Query.Execute().Unload();
		//If Result.Count() > 0 Then
		//	FoundUnit = Result[0].Ref;
		//	If TrimR(FoundUnit.Description) <> String(CurrentObject.UM)
		//		OR TrimR(FoundUnit.Code) <> CurrentObject.UM.Code Then
		//		
		//		// Base U/M was updated - update default unit also.
		//		DefaultUnit = FoundUnit.GetObject();
		//		DefaultUnit.Code        = CurrentObject.UM.Code;// Abbreviation
		//		DefaultUnit.Description = CurrentObject.UM;     // Unit name
		//		DefaultUnit.Write();
		//		
		//		// Add notification about changed item.
		//		WriteParameters.Insert("Notify", FoundUnit);
		//	EndIf;
		//EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	//// Check updated items.
	//NotifyRef = Undefined;
	//If WriteParameters.Property("Notify", NotifyRef) And (NotifyRef <> Undefined) Then
	//	// Refresh item presentation.
	//	NotifyChanged(NotifyRef);
	//EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not ValueIsFilled(BaseUnitName) And Object.Ref.IsEmpty() Then
		Cancel = True;
		MessOnError = New UserMessage();
		MessOnError.Field = "BaseUnitName";
		MessOnError.Text  = "Field ""Base unit Name"" not filled";
		MessOnError.Message();
	EndIf;
	
	If Not ValueIsFilled(BaseUnitAbbreviation) And Object.Ref.IsEmpty() Then
		Cancel = True;
		MessOnError = New UserMessage();
		MessOnError.Field = "BaseUnitAbbreviation";
		MessOnError.Text  = "Field ""Base unit Abbreviation"" not filled";
		MessOnError.Message();
	EndIf;
	
EndProcedure

#EndRegion

#Region PRIVATE_IMPLEMENTATION

&AtServer
Procedure UpdateInformationBaseUnit() 
	
	If Object.Ref.IsEmpty() Then
		//Object.UM = Catalogs.UM.each;
		
		Items.BaseUnitName.Visible         = True;
		Items.BaseUnitAbbreviation.Visible = True;
		Items.BaseUnit.Visible             = False;
	Else
		BaseUnit = GeneralFunctions.GetBaseUnit(Object.Ref);
		
		Items.BaseUnitName.Visible         = False;
		Items.BaseUnitAbbreviation.Visible = False;
		Items.BaseUnit.Visible             = True;
	EndIf;
	
EndProcedure

#EndRegion