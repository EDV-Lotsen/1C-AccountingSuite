////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Object.Ref.IsEmpty() Then
		Object.CombinedTaxRate = True;
		CombinedOrSingle = ?(Object.CombinedTaxRate, 1, 0);
		If ValueIsFilled(Object.Parent) Then
			Object.Parent = Catalogs.SalesTaxRates.EmptyRef();
		EndIf;
	ElsIf Not Object.Ref.IsEmpty() Then
		Items.CombinedOrSingle.Visible = False;
		Items.Agency.ReadOnly = True;
		If ValueIsFilled(Object.Parent) Then
			Items.Rate.ReadOnly = True;
		EndIf;
	EndIf;
	SetVisibilityAtServer();
	ApplyConditionalAppearance();
	TotalCombinedRate = Format(Object.Rate, "ND=4; NFD=2") + "%";
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	If (ValueIsFilled(CurrentObject.Ref)) And (CurrentObject.CombinedTaxRate) Then
		Query = New Query("SELECT ALLOWED
		                  |	SalesTaxRates.Ref AS SalesTaxRate,
		                  |	SalesTaxRates.Description,
		                  |	SalesTaxRates.Agency,
		                  |	SalesTaxRates.Rate,
		                  |	FALSE AS WasModified
		                  |FROM
		                  |	Catalog.SalesTaxRates AS SalesTaxRates
		                  |WHERE
		                  |	SalesTaxRates.Parent = &CurrentRate");
		Query.SetParameter("CurrentRate", CurrentObject.Ref);
		CombinedRates.Load(Query.Execute().Unload());
	EndIf;
	CombinedOrSingle = ?(Object.CombinedTaxRate, 1, 0);
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	Try
		For Each CombinedRate In CombinedRates Do
			NewCombinedRate = False;
			If CombinedRate.WasModified Then
				If ValueIsFilled(CombinedRate.SalesTaxRate) Then
					SalesTaxRateObject = CombinedRate.SalesTaxRate.GetObject();
				Else
					SalesTaxRateObject = Catalogs.SalesTaxRates.CreateItem();
					NewCombinedRate = True;
				EndIf;
				SalesTaxRateObject.Parent = CurrentObject.Ref;
				SalesTaxRateObject.Description = CombinedRate.Description;
				SalesTaxRateObject.Agency = CombinedRate.Agency;
				SalesTaxRateObject.Rate = CombinedRate.Rate;
				SalesTaxRateObject.Write();
				If Not ValueIsFilled(CombinedRate.SalesTaxRate) Then
					CombinedRate.SalesTaxRate = SalesTaxRateObject.Ref;
					ThisForm.Modified = False;
				EndIf;
				If NewCombinedRate Then
					LockCombinedRateAtServer(SalesTaxRateObject.Ref);
				EndIf;
			EndIf;
		EndDo;
	Except
		Raise ErrorDescription();
		Cancel = True;
	EndTry;
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If Not (ValueIsFilled(Object.Agency)) And (Not Object.CombinedTaxRate) Then
		Cancel = True;
		Message = New UserMessage();
		Message.SetData(Object);
		Message.Field = "Object.Agency";
		Message.Text = NStr("en = 'Agency is not filled'");
		Message.Message();
	EndIf;
	If Object.CombinedTaxRate Then
		For Each CombinedRate In CombinedRates Do
			If Not ValueIsFilled(CombinedRate.Agency) Then
				Cancel = True; 
				Message = New UserMessage();
				Message.Text=NStr("en = 'Agency is not filled!'");
				Message.Field = "CombinedRates[" + String(CombinedRates.IndexOf(CombinedRate)) + "].Agency";
				Message.Message();
			EndIf;
		EndDo;
	EndIf;
EndProcedure

#ENDREGION

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure CombinedOrSingleOnChange(Item)
	Object.CombinedTaxRate = ?(CombinedOrSingle = 1, True, False);
	SetVisibilityAtClient();
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region TABULAR_SECTION_EVENTS_HANDLERS

&AtClient
Procedure CombinedRatesSelection(Item, SelectedRow, Field, StandardProcessing)
	If ValueIsFilled(Item.CurrentData.SalesTaxRate) Then
		Try
			LockCombinedRateAtServer(Item.CurrentData.SalesTaxRate);			
		Except
			ErrorInf = ErrorInfo();
			ShowMessageBox(, ErrorInf.Cause.Description,, "Sales tax rates:" + String(Item.CurrentData.SalesTaxRate));
		EndTry;
		If Not Item.CurrentData.WasModified Then
			CurrentSTR = CommonUse.GetAttributeValues(Item.CurrentData.SalesTaxRate, "Description, Agency, Rate");
			Item.CurrentData.Description = CurrentSTR.Description;
			Item.CurrentData.Agency = CurrentSTR.Agency;
			Item.CurrentData.Rate = CurrentSTR.Rate;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure CombinedRatesOnStartEdit(Item, NewRow, Clone)
	If NewRow Then
		Item.CurrentData.WasModified = True;
		If Clone Then
			Item.CurrentData.SalesTaxRate = PredefinedValue("Catalog.SalesTaxRates.EmptyRef");
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure CombinedRatesOnChange(Item)
	Item.CurrentData.WasModified = True;
EndProcedure

&AtClient
Procedure CombinedRatesRateOnChange(Item)
	Object.Rate = CombinedRates.Total("Rate");
	TotalCombinedRate = Format(Object.Rate, "ND=4; NFD=2") + "%";
EndProcedure

&AtClient
Procedure CombinedRatesBeforeDeleteRow(Item, Cancel)
	If Not ValueIsFilled(Item.CurrentData.SalesTaxRate) Then
		return;
	EndIf;
	//If the current component of sales tax is already written to the database
	Cancel = True;
	Notify = New NotifyDescription("DeleteComponentOfTax", ThisObject, New Structure("SalesTaxRateToDelete", Item.CurrentData.SalesTaxRate));
	ShowQueryBox(Notify, "The component of tax """ + Item.CurrentData.Description + """ will be deleted permanently. Continue?", QuestionDialogMode.YesNoCancel,, DialogReturnCode.Cancel, "Sales tax rate"); 
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

&AtServer
Procedure SetVisibilityAtServer()
	If Object.CombinedTaxRate Then
		Items.CombinedTaxRateGroup.Visible = True;
		Items.CaptionSpace.Visible = True;
		Items.Agency.Visible = False;
		Items.Rate.Visible = False;
	Else
		Items.CombinedTaxRateGroup.Visible = False;
		Items.CaptionSpace.Visible = False;
		Items.Agency.Visible = True;
		Items.Rate.Visible = True;
	EndIf;
EndProcedure

&AtServer
Procedure LockCombinedRateAtServer(SalesTaxRateRef)
	LockDataForEdit(SalesTaxRateRef,, ThisForm.UUID);	
EndProcedure

&AtServer
Procedure ApplyConditionalAppearance()
	CA = ThisForm.ConditionalAppearance;
	CA.Items.Clear();
	//Auto-categorized categories highlight with Italic font
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("CombinedRatesAgency"); 
 	FieldAppearance.Use = True; 
	
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("CombinedRates.SalesTaxRate"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= Catalogs.SalesTaxRates.EmptyRef(); 
	FilterElement.Use				= True;
	
	ElementCA.Appearance.SetParameterValue("ReadOnly", True);
	ElementCA.Appearance.SetParameterValue("BackColor", WebColors.WhiteSmoke);
EndProcedure

&AtServer
Procedure DeleteComponentOfTaxAtServer(SalesTaxRateToDelete)
	SalesTaxRateObject = SalesTaxRateToDelete.GetObject();
	SalesTaxRateObject.Delete();
EndProcedure

&AtClient
Procedure SetVisibilityAtClient()
	If Object.CombinedTaxRate Then
		Items.CombinedTaxRateGroup.Visible = True;
		Items.CaptionSpace.Visible = True;
		Items.Agency.Visible = False;
		Items.Rate.Visible = False;
	Else
		Items.CombinedTaxRateGroup.Visible = False;
		Items.CaptionSpace.Visible = False;
		Items.Agency.Visible = True;
		Items.Rate.Visible = True;
	EndIf;
EndProcedure

&AtClient 
Procedure DeleteComponentOfTax(Answer, Parameters) Export
	If Answer <> DialogReturnCode.Yes Then
		return;
	EndIf;
	Try
		DeleteComponentOfTaxAtServer(Parameters.SalesTaxRateToDelete);
		//Delete current row
		FoundRows = CombinedRates.FindRows(New Structure("SalesTaxRate", Parameters.SalesTaxRateToDelete));
		For Each FoundRow In FoundRows Do
			CombinedRates.Delete(CombinedRates.IndexOf(FoundRow));
		EndDo;
		Object.Rate = CombinedRates.Total("Rate");
		ThisForm.Write();
		TotalCombinedRate = Format(Object.Rate, "ND=4; NFD=2") + "%";
		NotifyChanged(Object.Ref);
		NotifyChanged(Parameters.SalesTaxRateToDelete);
	Except
		ErrorInf = ErrorInfo();
		ShowMessageBox(, ErrorInf.Cause.Description,, "Sales tax rates:" + String(Parameters.SalesTaxRateToDelete));
	EndTry;
EndProcedure

#EndRegion