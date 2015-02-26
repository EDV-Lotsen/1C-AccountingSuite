
////////////////////////////////////////////////////////////////////////////////
// Assembly: Document form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//------------------------------------------------------------------------------
	// 1. Form attributes initialization.
	
	// Set LineItems editing flag.
	IsNewRow = False;
	
	// Fill object attributes cache.
	Product  = Object.Product;
	Location = Object.Location;
	Project  = Object.Project;
	Class    = Object.Class;
	
	// Define point in time for requesting the balances.
	If Object.Ref.IsEmpty() Then
		// The new document.
		If ValueIsFilled(Object.Date) And BegOfDay(Object.Date) < BegOfDay(CurrentSessionDate()) Then
			// New document in back-date.
			PointInTime = New Boundary(EndOfDay(Object.Date), BoundaryType.Including);
		Else
			// New actual document.
			PointInTime = Undefined;
		EndIf;
	Else
		// Document was already saved (but date can actually be changed).
		PointInTime = New Boundary(New PointInTime(Object.Date, Object.Ref), BoundaryType.Including);
	EndIf;
	
	// Define color constants.
	NegativeTextColor     = StyleColors.NegativeTextColor;
	ColorInformationLabel = StyleColors.ColorInformationLabel;
	
	//------------------------------------------------------------------------------
	// 2. Calculate values of form object attributes.
	
	// Request and fill invoice status.
	FillAssemblyStatusAtServer();
	
	//------------------------------------------------------------------------------
	// 3. Set custom controls presentation.
	
	// Set residuals & services visibility.
	Items.ResidualsSection.Visible = Object.Product.HasResiduals;
	Items.ServicesSection.Visible  = Object.Product.HasServices;
	
	// Update quantities presentation.
	QuantityPrecision = GeneralFunctionsReusable.DefaultQuantityPrecision();
	QuantityFormat    = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.LineItemsQuantityItem.EditFormat  = QuantityFormat;
	Items.LineItemsQuantityItem.Format      = QuantityFormat;
	Items.LineItemsQuantity.EditFormat      = QuantityFormat;
	Items.LineItemsQuantity.Format          = QuantityFormat;
	Items.LineItemsWasteQuantity.EditFormat = QuantityFormat;
	Items.LineItemsWasteQuantity.Format     = QuantityFormat;
	Items.ResidualsQuantityItem.EditFormat  = QuantityFormat;
	Items.ResidualsQuantityItem.Format      = QuantityFormat;
	Items.ResidualsQuantity.EditFormat      = QuantityFormat;
	Items.ResidualsQuantity.Format          = QuantityFormat;
	Items.ServicesQuantityItem.EditFormat   = QuantityFormat;
	Items.ServicesQuantityItem.Format       = QuantityFormat;
	Items.ServicesQuantity.EditFormat       = QuantityFormat;
	Items.ServicesQuantity.Format           = QuantityFormat;
	Items.Quantity.EditFormat               = QuantityFormat;
	Items.Quantity.Format                   = QuantityFormat;
	
	// Update prices presentation.
	PriceFormat = GeneralFunctionsReusable.DefaultPriceFormat();
	Items.LineItemsPrice.EditFormat         = PriceFormat;
	Items.LineItemsPrice.Format             = PriceFormat;
	Items.ResidualsPrice.EditFormat         = PriceFormat;
	Items.ResidualsPrice.Format             = PriceFormat;
	Items.ServicesPrice.EditFormat          = PriceFormat;
	Items.ServicesPrice.Format              = PriceFormat;
	
	// Set currency titles.
	DefaultCurrencySymbol            = GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.LineSubtotalCurrency.Title = DefaultCurrencySymbol;
	Items.WasteCurrency.Title        = DefaultCurrencySymbol;
	Items.ResidualsCurrency.Title    = DefaultCurrencySymbol;
	Items.ServicesCurrency.Title     = DefaultCurrencySymbol;
	Items.FCYCurrency.Title          = DefaultCurrencySymbol;
	
	// Calculate total percents.
	DisplayPercentIndicators(Object, ThisForm);
	
EndProcedure

// -> CODE REVIEW

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	//Closing period
	If PeriodClosingServerCall.DocumentPeriodIsClosed(Object.Ref, Object.Date) Then
		Cancel = Not PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		If Cancel Then
			If WriteParameters.Property("PeriodClosingPassword") And WriteParameters.Property("Password") Then
				If WriteParameters.Password = TRUE Then //Writing the document requires a password
					ShowMessageBox(, "Invalid password!",, "Closed period notification");
				EndIf;
			Else
				Notify = New NotifyDescription("ProcessUserResponseOnDocumentPeriodClosed", ThisObject, WriteParameters);
				Password = "";
				OpenForm("CommonForm.ClosedPeriodNotification", New Structure, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
			EndIf;
			return;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessUserResponseOnDocumentPeriodClosed(Result, Parameters) Export
	
	If (TypeOf(Result) = Type("String")) Then //Inserted password
		Parameters.Insert("PeriodClosingPassword", Result);
		Parameters.Insert("Password", TRUE);
		Write(Parameters);
		
	ElsIf (TypeOf(Result) = Type("DialogReturnCode")) Then //Yes, No or Cancel
		If Result = DialogReturnCode.Yes Then
			Parameters.Insert("PeriodClosingPassword", "Yes");
			Parameters.Insert("Password", FALSE);
			Write(Parameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// -> CODE REVIEW
	
	// Check empty lines.
	If Object.LineItems.Count() = 0 Then
		Message("Cannot post/save with no line items.");
		Cancel = True;
	EndIf;
	
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);
	EndIf;
	
	// <- CODE REVIEW
	
EndProcedure

// <- CODE REVIEW

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Update point in time for requesting the balances.
	If Object.Ref.IsEmpty() Then
		// The new document.
		If BegOfDay(Object.Date) < BegOfDay(CurrentSessionDate()) Then
			// New document in back-date.
			PointInTime = New Boundary(EndOfDay(Object.Date), BoundaryType.Including);
		Else
			// New actual document.
			PointInTime = Undefined;
		EndIf;
	Else
		// Document was already saved (but date can actually be changed).
		PointInTime = New Boundary(New PointInTime(Object.Date, Object.Ref), BoundaryType.Including);
	EndIf;
	
	//------------------------------------------------------------------------------
	// Recalculate values of form object attributes.
	
	// Request and fill invoice status from database.
	FillAssemblyStatusAtServer();
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure ProductOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, "assembly contents", NStr("en = 'line items, residuals and services'"));
	
EndProcedure

&AtServer
Procedure ProductOnChangeAtServer()
	
	// Request product properties.
	ProductProperties = CommonUse.GetAttributeValues(Object.Product, New Structure("Description, UnitSet, WasteAccount"));
	Object.ProductDescription = ProductProperties.Description;
	Object.UnitSet            = ProductProperties.UnitSet;
	Object.Unit               = ProductProperties.UnitSet.DefaultPurchaseUnit;
	Object.WasteAccount       = ProductProperties.WasteAccount;
	
	// Set residuals visibility.
	Items.ResidualsSection.Visible = Object.Product.HasResiduals;
	If Not Object.Product.HasResiduals Then
		Object.Residuals.Clear();
	EndIf;
	
	// Set services visibility.
	Items.ServicesSection.Visible = Object.Product.HasServices;
	If Not Object.Product.HasServices Then
		Object.Services.Clear();
	EndIf;
	
	// Process settings changes.
	UnitOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure UnitOnChange(Item)
	
	// Request server operation.
	UnitOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure UnitOnChangeAtServer()
	
	// Do process quantity change (and assembly contents recalculating).
	QuantityOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure QuantityOnChange(Item)
	
	// Request server operation.
	QuantityOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure QuantityOnChangeAtServer()
	
	// Recalculate assembly's base quantity.
	Object.QtyUM = Round(Round(Object.QtyUnits, QuantityPrecision) *
	               ?(Object.Unit.Factor > 0, Object.Unit.Factor, 1), QuantityPrecision);
	
	// Recalculate line items quantity.
	For Each Row In Object.LineItems Do
		CommonQuantityItemOnChangeAtServer(Row);
	EndDo;
	
	// Update common totals.
	RecalculateTotalsAtServer();
	
	// Recalculate residuals quantity.
	For Each Row In Object.Residuals Do
		CommonQuantityItemOnChangeAtServer(Row);
	EndDo;
	
	// Recalculate services quantity.
	For Each Row In Object.Services Do
		CommonQuantityItemOnChangeAtServer(Row);
	EndDo;
	
	// Recalculate document totals.
	RecalculateTotalsAtServer();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, "cost", NStr("en = 'line items, residuals and services'"));
	
EndProcedure

&AtServer
Procedure DateOnChangeAtServer()
	
	// Update point in time for requesting the balances.
	If Object.Ref.IsEmpty() Then
		// The new document.
		If BegOfDay(Object.Date) < BegOfDay(CurrentSessionDate()) Then
			// New document in back-date.
			PointInTime = New Boundary(EndOfDay(Object.Date), BoundaryType.Including);
		Else
			// New actual document.
			PointInTime = Undefined;
		EndIf;
	Else
		// Document was already saved (but date can actually be changed).
		PointInTime = New Boundary(New PointInTime(Object.Date, Object.Ref), BoundaryType.Including);
	EndIf;
	
EndProcedure

&AtClient
Procedure LocationOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, Lower(Item.Name), NStr("en = 'line items and residuals'"));
	
EndProcedure

&AtClient
Procedure ProjectOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, Lower(Item.Name), NStr("en = 'line items and services'"));
	
EndProcedure

&AtClient
Procedure ClassOnChange(Item)
	
	// Ask user about updating the setting and update the line items accordingly.
	CommonDefaultSettingOnChange(Item, Lower(Item.Name), NStr("en = 'line items and services'"));
	
EndProcedure

//------------------------------------------------------------------------------
// Utils for request user confirmation and propagate header settings to line items.

&AtClient
Procedure CommonDefaultSettingOnChange(Item, ItemPresentation, Destination)
	
	// Request user confirmation changing the setting for all LineItems.
	DefaultSetting = Item.Name;
	If Object.LineItems.Count() > 0 Then
		QuestionText  = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Reset the %1 for %2?'"), ItemPresentation, Destination);
		QuestionTitle = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Reset %1'"), ItemPresentation);
		ChoiceParameters = New Structure("DefaultSetting", DefaultSetting);
		ChoiceProcessing = New NotifyDescription("DefaultSettingOnChangeChoiceProcessing", ThisForm, ChoiceParameters);
		ShowQueryBox(ChoiceProcessing, QuestionText, QuestionDialogMode.YesNoCancel,, DialogReturnCode.Cancel, QuestionTitle);
	Else
		// Keep new setting.
		ThisForm[DefaultSetting] = Object[DefaultSetting];
		
		// Custom field processing.
		If DefaultSetting = "Product" Then
			// Fill BOM contents.
			DefaultSettingOnChangeAtServer(DefaultSetting, True);
		Else
			// Standard processing without recalculating of table part (it's empty).
			DefaultSettingOnChangeAtServer(DefaultSetting, False);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure DefaultSettingOnChangeChoiceProcessing(ChoiceResult, ChoiceParameters) Export
	
	// Get current processing item.
	DefaultSetting = ChoiceParameters.DefaultSetting;
	
	// Process user choice.
	If ChoiceResult = DialogReturnCode.Yes Then
		// Set new setting for all line items and residuals.
		ThisForm[DefaultSetting] = Object[DefaultSetting];
		DefaultSettingOnChangeAtServer(DefaultSetting, True);
		
	ElsIf ChoiceResult = DialogReturnCode.No Then
		// Keep new setting, do not update line items and residuals.
		ThisForm[DefaultSetting] = Object[DefaultSetting];
		DefaultSettingOnChangeAtServer(DefaultSetting, False);
		
	Else
		// Restore previously entered setting.
		Object[DefaultSetting] = ThisForm[DefaultSetting];
	EndIf;
	
EndProcedure

&AtServer
Procedure DefaultSettingOnChangeAtServer(DefaultSetting, RecalculateLineItems)
	
	// Process attribute change.
	If DefaultSetting = "Product" Then
		// Process line items change.
		If RecalculateLineItems Then
			// Fill document on the base of item's BOM.
			FillDocumentWithLineItemsResidualsAndServices(Object.Product);
		EndIf;
		
		// Process product change.
		ProductOnChangeAtServer();
		
	ElsIf Object.Ref.Metadata().TabularSections.LineItems.Attributes.Find(DefaultSetting) <> Undefined
	   Or Object.Ref.Metadata().TabularSections.Residuals.Attributes.Find(DefaultSetting) <> Undefined
	   Or Object.Ref.Metadata().TabularSections.Services.Attributes.Find(DefaultSetting)  <> Undefined Then
		// Process attributes by the matching name to the header's default values.
		
		// Process line items change.
		If RecalculateLineItems Then
			
			// Apply default to all of the items.
			If Object.Ref.Metadata().TabularSections.LineItems.Attributes.Find(DefaultSetting) <> Undefined Then
				For Each Row In Object.LineItems Do
					Row[DefaultSetting] = Object[DefaultSetting];
				EndDo;
			EndIf;
			
			// Apply default to all of the residuals.
			If Object.Ref.Metadata().TabularSections.Residuals.Attributes.Find(DefaultSetting) <> Undefined Then
				For Each Row In Object.Residuals Do
					Row[DefaultSetting] = Object[DefaultSetting];
				EndDo;
			EndIf;
			
			// Apply default to all of the services.
			If Object.Ref.Metadata().TabularSections.Services.Attributes.Find(DefaultSetting) <> Undefined Then
				For Each Row In Object.Services Do
					Row[DefaultSetting] = Object[DefaultSetting];
				EndDo;
			EndIf;
		EndIf;
		
	// Process attributes by the name.
	ElsIf DefaultSetting = "Date" Then
		
		// Process the attribute change in any case.
		DateOnChangeAtServer();
		
		// Process line items change.
		If RecalculateLineItems Then
			
			// Recalculate items cost.
			For Each Row In Object.LineItems Do
				Row.PriceUnits = Round(GeneralFunctions.ProductLastCost(Row.Product, PointInTime) *
				                 ?(Row.Unit.Factor > 0, Row.Unit.Factor, 1),
				                 GeneralFunctionsReusable.PricePrecisionForOneItem(Row.Product));
				CommonPriceOnChangeAtServer(Row);
			EndDo;
			
			// Update common totals.
			RecalculateTotalsAtServer();
			
			// Recalculate residuals cost.
			For Each Row In Object.Residuals Do
				If Object.LineSubtotal <= Object.WasteSubtotal Then
					Row.Percent    = 0;
				EndIf;
				Row.LineTotal  = ?(Round(Row.QtyUnits, QuantityPrecision) > 0,
				                   Round((Object.LineSubtotal - Object.WasteSubtotal) * Row.Percent / 100, 2), 0);
				Row.PriceUnits = ?(Round(Row.QtyUnits, QuantityPrecision) > 0,
				                   Round(Row.LineTotal / Round(Row.QtyUnits, QuantityPrecision),
				                   GeneralFunctionsReusable.PricePrecisionForOneItem(Row.Product)), 0);
			EndDo;
			
			// Recalculate services cost.
			For Each Row In Object.Services Do
				Row.PriceUnits = Round(GeneralFunctions.ProductLastCost(Row.Product, PointInTime) *
				                 ?(Row.Unit.Factor > 0, Row.Unit.Factor, 1),
				                 GeneralFunctionsReusable.PricePrecisionForOneItem(Row.Product));
				CommonPriceOnChangeAtServer(Row);
			EndDo;
			
			// Update common totals.
			RecalculateTotalsAtServer();
		EndIf;
		
	Else
		// Process other attributes.
	EndIf;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region TABULAR_SECTION_EVENTS_HANDLERS

//------------------------------------------------------------------------------
// Tabular section LineItems event handlers.

&AtClient
Procedure LineItemsOnChange(Item)
	
	// Row was just added and became edited.
	If IsNewRow Then
		
		// Clear used flag.
		IsNewRow = False;
		
		// Fill new row with default values.
		ObjectData  = New Structure("Location, Project, Class");
		FillPropertyValues(ObjectData, Object);
		For Each ObjectField In ObjectData Do
			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
				Item.CurrentData[ObjectField.Key] = ObjectField.Value;
			EndIf;
		EndDo;
		
		// Clear order data on duplicate row.
		ClearFields  = New Structure("");
		For Each ClearField In ClearFields Do
			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
				Item.CurrentData[ObjectField.Key] = Undefined;
			EndIf;
		EndDo;
		
		// Refresh totals cache.
		RecalculateResidualsAndTotals();
	EndIf;
	
EndProcedure

&AtClient
Procedure LineItemsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	// Set new row flag.
	If Not Cancel Then
		IsNewRow = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure LineItemsOnEditEnd(Item, NewRow, CancelEdit)
	
	// Recalculation common document totals.
	RecalculateResidualsAndTotals();
	
EndProcedure

&AtClient
Procedure LineItemsAfterDeleteRow(Item)
	
	// Recalculation common document totals.
	RecalculateResidualsAndTotals();
	
EndProcedure

//------------------------------------------------------------------------------
// Tabular section Residuals event handlers.

&AtClient
Procedure ResidualsOnChange(Item)
	
	// Row was just added and became edited.
	If IsNewRow Then
		
		// Clear used flag.
		IsNewRow = False;
		
		// Fill new row with default values.
		ObjectData  = New Structure("Location");
		FillPropertyValues(ObjectData, Object);
		For Each ObjectField In ObjectData Do
			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
				Item.CurrentData[ObjectField.Key] = ObjectField.Value;
			EndIf;
		EndDo;
		
		// Clear order data on duplicate row.
		ClearFields  = New Structure("");
		For Each ClearField In ClearFields Do
			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
				Item.CurrentData[ObjectField.Key] = Undefined;
			EndIf;
		EndDo;
		
		// Refresh totals cache.
		RecalculateTotals();
	EndIf;
	
EndProcedure

&AtClient
Procedure ResidualsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	
	// Set new row flag.
	If Not Cancel Then
		IsNewRow = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ResidualsOnEditEnd(Item, NewRow, CancelEdit)
	
	// Recalculation common document totals.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure ResidualsAfterDeleteRow(Item)
	
	// Recalculation common document totals.
	RecalculateTotals();
	
EndProcedure

//------------------------------------------------------------------------------
// Tabular section Services event handlers.

&AtClient
Procedure ServicesOnChange(Item)
	
	// Row was just added and became edited.
	If IsNewRow Then
		
		// Clear used flag.
		IsNewRow = False;
		
		// Fill new row with default values.
		ObjectData  = New Structure("Project, Class");
		FillPropertyValues(ObjectData, Object);
		For Each ObjectField In ObjectData Do
			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
				Item.CurrentData[ObjectField.Key] = ObjectField.Value;
			EndIf;
		EndDo;
		
		// Clear order data on duplicate row.
		ClearFields  = New Structure("");
		For Each ClearField In ClearFields Do
			If Not ValueIsFilled(Item.CurrentData[ObjectField.Key]) Then
				Item.CurrentData[ObjectField.Key] = Undefined;
			EndIf;
		EndDo;
		
		// Refresh totals cache.
		RecalculateResidualsAndTotals();
	EndIf;
	
EndProcedure

&AtClient
Procedure ServicesBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	// Set new row flag.
	If Not Cancel Then
		IsNewRow = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure ServicesOnEditEnd(Item, NewRow, CancelEdit)
	
	// Recalculation common document totals.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure ServicesAfterDeleteRow(Item)
	
	// Recalculation common document totals.
	RecalculateTotals();
	
EndProcedure

//------------------------------------------------------------------------------
// Tabular sections LineItems, Residuals and Services columns controls event handlers.

&AtClient
Procedure LineItemsProductOnChange(Item)
	Var MessageText;
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Check added item.
	If CommonProductCheckItem(TableSectionRow, MessageText) Then
		// Item was checked successfully and all server filling accomplished.
		
		// Load processed data back.
		FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
		
		// Refresh totals cache.
		RecalculateResidualsAndTotals();
	Else
		// Inform user about wrong item.
		CommonUseClientServer.MessageToUser(MessageText, Object, "Object.LineItems["+Format(TableSectionRow.LineNumber-1, "NG=")+"].Product");
		
		// Clear selected item.
		Items.LineItems.CurrentData.Product = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure ResidualsProductOnChange(Item)
	Var MessageText;
	
	// Fill line data for editing.
	TableSectionRow = GetResidualsRowStructure();
	FillPropertyValues(TableSectionRow, Items.Residuals.CurrentData);
	
	// Check added item.
	If CommonProductCheckItem(TableSectionRow, MessageText) Then
		// Item was checked successfully and all server filling accomplished.
		
		// Load processed data back.
		FillPropertyValues(Items.Residuals.CurrentData, TableSectionRow);
		
		// Refresh totals cache.
		RecalculateTotals();
	Else
		// Inform user about wrong item.
		CommonUseClientServer.MessageToUser(MessageText, Object, "Object.Residuals["+Format(TableSectionRow.LineNumber-1, "NG=")+"].Product");
		
		// Clear selected item.
		Items.Residuals.CurrentData.Product = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure ServicesProductOnChange(Item)
	Var MessageText;
	
	// Fill line data for editing.
	TableSectionRow = GetServicesRowStructure();
	FillPropertyValues(TableSectionRow, Items.Services.CurrentData);
	
	// Check added item.
	If CommonProductCheckItem(TableSectionRow, MessageText) Then
		// Item was checked successfully and all server filling accomplished.
		
		// Load processed data back.
		FillPropertyValues(Items.Services.CurrentData, TableSectionRow);
		
		// Refresh totals cache.
		RecalculateTotals();
	Else
		// Inform user about wrong item.
		CommonUseClientServer.MessageToUser(MessageText, Object, "Object.Services["+Format(TableSectionRow.LineNumber-1, "NG=")+"].Product");
		
		// Clear selected item.
		Items.Services.CurrentData.Product = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Function CommonProductCheckItem(TableSectionRow, MessageText)
	
	// Check possibility of adding assembly to the items list.
	If TableSectionRow.Product.Assembly Then
		// Check whether it is item itself.
		If TableSectionRow.Product = Object.Product Then
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(
			              NStr("en = 'Cannot add the assembly %1 to its own contents.'"),
			              TableSectionRow.Product.Description);
			Return False;
		EndIf;
		
		// Check possible parent of current item.
		Child = Catalogs.Products.ItemIsParentAssembly(TableSectionRow.Product, Object.Product);
		If Child <> Undefined Then
			// Assembly already added to the another subassembly.
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(
			              NStr("en = 'Cannot add the assembly %1 to the contents of %2 because %3 already added to %1.'"),
			              TableSectionRow.Product.Description, Object.Product.Description, Child.Description);
			Return False;
		EndIf;
	EndIf;
	
	// Request server operation.
	CommonProductOnChangeAtServer(TableSectionRow);
	
	// Operation successfully completed.
	Return True;
	
EndFunction

&AtServer
Procedure CommonProductOnChangeAtServer(TableSectionRow)
	
	// Request product properties.
	ProductProperties = CommonUse.GetAttributeValues(TableSectionRow.Product, New Structure("Description, UnitSet"));
	TableSectionRow.ProductDescription = ProductProperties.Description;
	TableSectionRow.UnitSet            = ProductProperties.UnitSet;
	TableSectionRow.Unit               = ProductProperties.UnitSet.DefaultPurchaseUnit;
	TableSectionRow.PriceUnits         = Round(GeneralFunctions.ProductLastCost(TableSectionRow.Product) *
	                                     ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1),
	                                     GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
	
	// Assign default quantities.
	TableSectionRow.QtyItem       = 0;
	TableSectionRow.QtyUnits      = 0;
	TableSectionRow.QtyUM         = 0;
	
	// Calculate totals by line.
	TableSectionRow.LineTotal     = 0;
	
	// Fill optional location.
	If TableSectionRow.Property("Location") Then
		TableSectionRow.Location = Object.Location;
	EndIf;
	
	// Fill optional financial properties.
	If TableSectionRow.Property("Project") Then
		TableSectionRow.Project = Object.Project;
		TableSectionRow.Class   = Object.Class;
	EndIf;
	
	// Fill optional wastes.
	If TableSectionRow.Property("WastePercent") Then
		TableSectionRow.WastePercent  = 0;
		TableSectionRow.WasteQtyUnits = 0;
		TableSectionRow.WasteQtyUM    = 0;
		TableSectionRow.WasteTotal    = 0;
	EndIf;
	
	// Fill optional residuals.
	If TableSectionRow.Property("Percent") Then
		TableSectionRow.Percent = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure LineItemsQuantityItemOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	CommonQuantityItemOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateResidualsAndTotals();
	
EndProcedure

&AtClient
Procedure ResidualsQuantityItemOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetResidualsRowStructure();
	FillPropertyValues(TableSectionRow, Items.Residuals.CurrentData);
	
	// Request server operation.
	CommonQuantityItemOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.Residuals.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure ServicesQuantityItemOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetServicesRowStructure();
	FillPropertyValues(TableSectionRow, Items.Services.CurrentData);
	
	// Request server operation.
	CommonQuantityItemOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.Services.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure CommonQuantityItemOnChangeAtServer(TableSectionRow)
	
	// Calculate total by line.
	TableSectionRow.QtyUnits  = Round(Round(TableSectionRow.QtyItem, QuantityPrecision) *
	                                  Round(Object.QtyUnits, QuantityPrecision) *
	                                      ?(Object.Unit.Factor > 0, Object.Unit.Factor, 1), QuantityPrecision);
	
	// Process settings changes.
	CommonQuantityOnChangeAtServer(TableSectionRow);
	
EndProcedure

&AtClient
Procedure LineItemsUnitOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	CommonUnitOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateResidualsAndTotals();
	
EndProcedure

&AtClient
Procedure ResidualsUnitOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetResidualsRowStructure();
	FillPropertyValues(TableSectionRow, Items.Residuals.CurrentData);
	
	// Request server operation.
	CommonUnitOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.Residuals.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure ServicesUnitOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetServicesRowStructure();
	FillPropertyValues(TableSectionRow, Items.Services.CurrentData);
	
	// Request server operation.
	CommonUnitOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.Services.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure CommonUnitOnChangeAtServer(TableSectionRow)
	
	// Calculate new unit price.
	If TableSectionRow.Property("Percent") Then
		// Residuals
		If Object.LineSubtotal <= Object.WasteSubtotal Then
			TableSectionRow.Percent    = 0;
			TableSectionRow.PriceUnits = 0;
		Else
			TableSectionRow.PriceUnits = Round(GeneralFunctions.ProductLastCost(TableSectionRow.Product) *
			                             ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1),
			                             GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
		EndIf;
	Else
		// LineItems
		TableSectionRow.PriceUnits = Round(GeneralFunctions.ProductLastCost(TableSectionRow.Product) *
		                             ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1),
		                             GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
	EndIf;
	
	// Process settings changes.
	CommonQuantityOnChangeAtServer(TableSectionRow);
	
EndProcedure

&AtClient
Procedure LineItemsQuantityOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	CommonQuantityOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateResidualsAndTotals();
	
EndProcedure

&AtClient
Procedure ResidualsQuantityOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetResidualsRowStructure();
	FillPropertyValues(TableSectionRow, Items.Residuals.CurrentData);
	
	// Request server operation.
	CommonQuantityOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.Residuals.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure ServicesQuantityOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetServicesRowStructure();
	FillPropertyValues(TableSectionRow, Items.Services.CurrentData);
	
	// Request server operation.
	CommonQuantityOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.Services.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure CommonQuantityOnChangeAtServer(TableSectionRow)
	
	// Calculate total by line.
	TableSectionRow.LineTotal = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) *
	                            Round(TableSectionRow.PriceUnits,
	                            GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 2);
	
	// Process settings changes.
	CommonLineTotalOnChangeAtServer(TableSectionRow);
	
EndProcedure

&AtClient
Procedure LineItemsPriceOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	CommonPriceOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateResidualsAndTotals();
	
EndProcedure

&AtClient
Procedure ResidualsPriceOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetResidualsRowStructure();
	FillPropertyValues(TableSectionRow, Items.Residuals.CurrentData);
	
	// Request server operation.
	CommonPriceOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.Residuals.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure ServicesPriceOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetServicesRowStructure();
	FillPropertyValues(TableSectionRow, Items.Services.CurrentData);
	
	// Request server operation.
	CommonPriceOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.Services.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure CommonPriceOnChangeAtServer(TableSectionRow)
	
	// Rounds price of product.
	TableSectionRow.PriceUnits = Round(TableSectionRow.PriceUnits, GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product));
	
	// Calculate total by line.
	TableSectionRow.LineTotal  = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) *
	                             TableSectionRow.PriceUnits, 2);
	
	// Process settings changes.
	CommonLineTotalOnChangeAtServer(TableSectionRow);
	
EndProcedure

&AtClient
Procedure LineItemsLineTotalOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	CommonLineTotalOnChangeAtServer(TableSectionRow);
	
	// Back-step price calculation with totals priority (interactive change only).
	TableSectionRow.PriceUnits = ?(Round(TableSectionRow.QtyUnits, QuantityPrecision) > 0,
	                               Round(TableSectionRow.LineTotal / Round(TableSectionRow.QtyUnits, QuantityPrecision),
	                               GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 0);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateResidualsAndTotals();
	
EndProcedure

&AtClient
Procedure ResidualsLineTotalOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetResidualsRowStructure();
	FillPropertyValues(TableSectionRow, Items.Residuals.CurrentData);
	
	// Request server operation.
	CommonLineTotalOnChangeAtServer(TableSectionRow);
	
	// Back-step price calculation with totals priority (interactive change only).
	TableSectionRow.PriceUnits = ?(Round(TableSectionRow.QtyUnits, QuantityPrecision) > 0,
	                               Round(TableSectionRow.LineTotal / Round(TableSectionRow.QtyUnits, QuantityPrecision),
	                               GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 0);
	
	// Load processed data back.
	FillPropertyValues(Items.Residuals.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure ServicesLineTotalOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetServicesRowStructure();
	FillPropertyValues(TableSectionRow, Items.Services.CurrentData);
	
	// Request server operation.
	CommonLineTotalOnChangeAtServer(TableSectionRow);
	
	// Back-step price calculation with totals priority (interactive change only).
	TableSectionRow.PriceUnits = ?(Round(TableSectionRow.QtyUnits, QuantityPrecision) > 0,
	                               Round(TableSectionRow.LineTotal / Round(TableSectionRow.QtyUnits, QuantityPrecision),
	                               GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 0);
	
	// Load processed data back.
	FillPropertyValues(Items.Services.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtServer
Procedure CommonLineTotalOnChangeAtServer(TableSectionRow)
	
	// Back-calculation of quantity in base units.
	TableSectionRow.QtyUM = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) *
	                        ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1), QuantityPrecision);
	
	// Calculation of residuals percent.
	If TableSectionRow.Property("Percent") Then
		TableSectionRow.Percent = ?((Object.LineSubtotal - Object.WasteSubtotal) > 0,
		                          Round(TableSectionRow.LineTotal * 100 / (Object.LineSubtotal - Object.WasteSubtotal), 2), 0);
		
		// Update total cost if residuals took 0% of final assembly cost.
		If TableSectionRow.Percent = 0 Then
			TableSectionRow.PriceUnits = 0;
			TableSectionRow.LineTotal  = 0;
		EndIf;
	EndIf;
	
	// Process settings changes.
	If TableSectionRow.Property("WastePercent") Then
		LineItemsWastePercentOnChangeAtServer(TableSectionRow);
	EndIf;
	
EndProcedure

&AtClient
Procedure LineItemsWastePercentOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Request server operation.
	LineItemsWastePercentOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateResidualsAndTotals();
	
EndProcedure

&AtServer
Procedure LineItemsWastePercentOnChangeAtServer(TableSectionRow)
	
	// Calculate waste qty by line.
	TableSectionRow.WasteQtyUnits = Round(Round(TableSectionRow.QtyUnits, QuantityPrecision) *
	                                TableSectionRow.WastePercent / 100, QuantityPrecision);
	
	// Process settings changes.
	LineItemsWasteQuantityOnChangeAtServer(TableSectionRow);
	
EndProcedure

&AtClient
Procedure ResidualsPercentOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetResidualsRowStructure();
	FillPropertyValues(TableSectionRow, Items.Residuals.CurrentData);
	
	// Drop residuals percent if assembly cost is zero.
	If Object.LineSubtotal <= Object.WasteSubtotal Then
		TableSectionRow.Percent = 0;
	EndIf;
	
	// Back calculation of product cost and total.
	TableSectionRow.LineTotal  = ?(Round(TableSectionRow.QtyUnits, QuantityPrecision) > 0,
	                               Round((Object.LineSubtotal - Object.WasteSubtotal) * TableSectionRow.Percent / 100, 2), 0);
	TableSectionRow.PriceUnits = ?(Round(TableSectionRow.QtyUnits, QuantityPrecision) > 0,
	                               Round(TableSectionRow.LineTotal / Round(TableSectionRow.QtyUnits, QuantityPrecision),
	                               GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 0);
	
	// Load processed data back.
	FillPropertyValues(Items.Residuals.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateTotals();
	
EndProcedure

&AtClient
Procedure LineItemsWasteQuantityOnChange(Item)
	
	// Fill line data for editing.
	TableSectionRow = GetLineItemsRowStructure();
	FillPropertyValues(TableSectionRow, Items.LineItems.CurrentData);
	
	// Back-step percent calculation with quantity priority (interactive change only).
	If TableSectionRow.QtyUnits = 0 Then
		// Base quantity is zeroed.
		TableSectionRow.WasteQtyUnits = 0;
		TableSectionRow.WastePercent  = 0;
		
	ElsIf TableSectionRow.WasteQtyUnits < TableSectionRow.QtyUnits Then
		// Normal percent calculation.
		TableSectionRow.WastePercent =  Round(TableSectionRow.WasteQtyUnits * 100 /
		                                Round(TableSectionRow.QtyUnits, QuantityPrecision), QuantityPrecision);
	Else
		// Wastes are 100%.
		TableSectionRow.WasteQtyUnits = TableSectionRow.QtyUnits;
		TableSectionRow.WastePercent  = 100;
	EndIf;
	
	// Request server operation.
	LineItemsWasteQuantityOnChangeAtServer(TableSectionRow);
	
	// Load processed data back.
	FillPropertyValues(Items.LineItems.CurrentData, TableSectionRow);
	
	// Refresh totals cache.
	RecalculateResidualsAndTotals();
	
EndProcedure

&AtServer
Procedure LineItemsWasteQuantityOnChangeAtServer(TableSectionRow)
	
	// Calculate waste total by line.
	TableSectionRow.WasteTotal = Round(Round(TableSectionRow.WasteQtyUnits, QuantityPrecision) *
	                             Round(TableSectionRow.PriceUnits,
	                             GeneralFunctionsReusable.PricePrecisionForOneItem(TableSectionRow.Product)), 2);
	
	// Back-calculation of quantity in base units.
	TableSectionRow.WasteQtyUM = Round(Round(TableSectionRow.WasteQtyUnits, QuantityPrecision) *
	                             ?(TableSectionRow.Unit.Factor > 0, TableSectionRow.Unit.Factor, 1), QuantityPrecision);
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

//------------------------------------------------------------------------------
// Calculate values of form object attributes.

&AtServer
// Request assembly status from database.
Procedure FillAssemblyStatusAtServer()
	
	// Request assembly status.
	If (Not ValueIsFilled(Object.Ref)) Or (Object.DeletionMark) Or (Not Object.Posted) Then
		// The assembly has pending status.
		AssemblyStatus = Enums.AssemblyStatuses.Pending;
	Else
		// The assembly has been completed.
		AssemblyStatus = Enums.AssemblyStatuses.Completed;
	EndIf;
	
	// Fill extended assembly status presentation (depending of document state).
	If Not ValueIsFilled(Object.Ref) Then
		AssemblyStatusPresentation = String(Enums.AssemblyStatuses.New);
		Items.AssemblyStatusPresentation.TextColor = WebColors.DarkGray;
		
	ElsIf Object.DeletionMark Then
		AssemblyStatusPresentation = String(Enums.AssemblyStatuses.Deleted);
		Items.AssemblyStatusPresentation.TextColor = WebColors.DarkGray;
		
	// Reserved for future use.
	// Currently the draft status assumes that assembly is pending.
	//ElsIf Not Object.Posted Then
	//	AssemblyStatusPresentation = String(Enums.AssemblyStatuses.Draft);
	//	Items.AssemblyStatusPresentation.TextColor = WebColors.DarkGray;
		
	Else
		AssemblyStatusPresentation = String(AssemblyStatus);
		If AssemblyStatus = Enums.AssemblyStatuses.Pending Then 
			ThisForm.Items.AssemblyStatusPresentation.TextColor = WebColors.DarkGoldenRod;
		ElsIf AssemblyStatus = Enums.AssemblyStatuses.Completed Then 
			ThisForm.Items.AssemblyStatusPresentation.TextColor = WebColors.DarkGreen;
		Else
			ThisForm.Items.AssemblyStatusPresentation.TextColor = WebColors.DarkGray;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
// Fills document on the base of passed assembly item.
// Returns flag of successfull filing.
Function FillDocumentWithLineItemsResidualsAndServices(Assembly)
	
	// Clear existing dataset.
	Object.LineItems.Clear();
	Object.Residuals.Clear();
	Object.Services.Clear();
	
	// Fill table on the base of selected orders.
	If Assembly <> Undefined Then
		
		// Fill object by orders.
		DocObject = FormAttributeToValue("Object");
		DocObject.Fill(Assembly);
		
		// Return filled object to form.
		ValueToFormAttribute(DocObject, "Object");
		
		// Return filling success.
		Return True;
	Else
		// Return fail (selection cancelled).
		Return False;
	EndIf;
	
EndFunction

//------------------------------------------------------------------------------
// Calculate totals and fill object attributes.

&AtClient
// The procedure recalculates the document's totals.
Procedure RecalculateTotals()
	
	// Calculate document totals.
	Object.LineSubtotal      = Object.LineItems.Total("LineTotal");
	Object.WasteSubtotal     = Object.LineItems.Total("WasteTotal");
	Object.ResidualsSubtotal = Object.Residuals.Total("LineTotal");
	Object.ServicesSubtotal  = Object.Services.Total("LineTotal");
	Object.DocumentTotal     = Object.LineSubtotal - Object.WasteSubtotal - Object.ResidualsSubtotal + Object.ServicesSubtotal;
	
	// Update percent indicators.
	DisplayPercentIndicators(Object, ThisForm);
	
EndProcedure

&AtServer
// The procedure recalculates the document's totals.
Procedure RecalculateTotalsAtServer()
	
	// Calculate document totals.
	Object.LineSubtotal      = Object.LineItems.Total("LineTotal");
	Object.WasteSubtotal     = Object.LineItems.Total("WasteTotal");
	Object.ResidualsSubtotal = Object.Residuals.Total("LineTotal");
	Object.ServicesSubtotal  = Object.Services.Total("LineTotal");
	Object.DocumentTotal     = Object.LineSubtotal - Object.WasteSubtotal - Object.ResidualsSubtotal + Object.ServicesSubtotal;
	
	// Update percent indicators.
	DisplayPercentIndicators(Object, ThisForm);
	
EndProcedure

&AtClient
// The procedure recalculates the document's totals.
Procedure RecalculateResidualsAndTotals()
	
	// Calculate document totals.
	Object.LineSubtotal      = Object.LineItems.Total("LineTotal");
	Object.WasteSubtotal     = Object.LineItems.Total("WasteTotal");
	
	// Recalculate residuals cost basing on changed assembly cost.
	For Each Row In Object.Residuals Do
		If Object.LineSubtotal <= Object.WasteSubtotal Then
			Row.Percent    = 0;
		EndIf;
		Row.LineTotal  = ?(Round(Row.QtyUnits, QuantityPrecision) > 0,
		                   Round((Object.LineSubtotal - Object.WasteSubtotal) * Row.Percent / 100, 2), 0);
		Row.PriceUnits = ?(Round(Row.QtyUnits, QuantityPrecision) > 0,
		                   Round(Row.LineTotal / Round(Row.QtyUnits, QuantityPrecision),
		                   GeneralFunctionsReusable.PricePrecisionForOneItem(Row.Product)), 0);
	EndDo;
	
	// Recalculate document totals.
	Object.ResidualsSubtotal = Object.Residuals.Total("LineTotal");
	Object.ServicesSubtotal  = Object.Services.Total("LineTotal");
	Object.DocumentTotal     = Object.LineSubtotal - Object.WasteSubtotal - Object.ResidualsSubtotal + Object.ServicesSubtotal;
	
	// Update percent indicators.
	DisplayPercentIndicators(Object, ThisForm);
	
EndProcedure

&AtClientAtServerNoContext
Procedure DisplayPercentIndicators(Object, Form)
	
	// Waste percent calculation.
	If Object.LineSubtotal = 0 Then
		// Base amount is zeroed.
		ProcessedMaterials = 0;
		WastePercent = 0;
		
	ElsIf Object.WasteSubtotal < Object.LineSubtotal Then
		// Normal percent calculation.
		ProcessedMaterials = Object.LineSubtotal - Object.WasteSubtotal;
		WastePercent = Round(Object.WasteSubtotal * 100 / Object.LineSubtotal, 2);
		
	Else
		// Wastes are 100%.
		ProcessedMaterials = 0;
		WastePercent = 100;
	EndIf;
	
	// Fill indicator with wastes percent.
	Form.Items.WastePercent.Title = StringFunctionsClientServer.SubstituteParametersInString(
	                                NStr("en = 'Waste percent: %1%%'"),
	                                Format(WastePercent, "NZ=0"));
	
	// Residuals percent calculation.
	If ProcessedMaterials = 0 Then
		// Base amount is zeroed.
		ResidualsPercent = 0;
	Else
		// Normal percent calculation.
		ResidualsPercent = Round(Object.ResidualsSubtotal * 100 / ProcessedMaterials, 2);
	EndIf;
	
	// Fill indicator with residuals percent.
	Form.Items.CommonResidualsPercent.Title = StringFunctionsClientServer.SubstituteParametersInString(
	                                          NStr("en = 'Residuals percent: %1%%'"),
	                                          Format(ResidualsPercent, "NZ=0"));
	
	// Set appropriate font color.
	If ResidualsPercent > 100 Then
		Form.Items.CommonResidualsPercent.TextColor = Form.NegativeTextColor;
	Else
		Form.Items.CommonResidualsPercent.TextColor = Form.ColorInformationLabel;
	EndIf;
	
EndProcedure

//------------------------------------------------------------------------------
// Replacemant for metadata properties on client.

&AtClient
// Returns fields structure of LineItems form control.
Function GetLineItemsRowStructure()
	
	// Define control row fields.
	Return New Structure("LineNumber, Product, ProductDescription, UnitSet, QtyItem, QtyUnits, Unit, QtyUM, PriceUnits, LineTotal, WastePercent, WasteQtyUnits, WasteQtyUM, WasteTotal, Location, Project, Class");
	
EndFunction

&AtClient
// Returns fields structure of Services form control.
Function GetServicesRowStructure()
	
	// Define control row fields.
	Return New Structure("LineNumber, Product, ProductDescription, UnitSet, QtyItem, QtyUnits, Unit, QtyUM, PriceUnits, LineTotal, Project, Class");
	
EndFunction

&AtClient
// Returns fields structure of Residuals form control.
Function GetResidualsRowStructure()
	
	// Define control row fields.
	Return New Structure("LineNumber, Product, ProductDescription, UnitSet, QtyItem, QtyUnits, Unit, QtyUM, Percent, PriceUnits, LineTotal, Location");
	
EndFunction

#EndRegion
