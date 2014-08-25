////////////////////////////////////////////////////////////////////////////////
&AtClient
Var ThisIsNew;
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	//If object is new
	If Object.Ref.IsEmpty() Then
		//If copied
		If Parameters.Property("CopyingValue") And ValueIsFilled(Parameters.CopyingValue) Then
			StandardProcessing = False;
			Basis = Parameters.CopyingValue;
			FillPropertyValues(Object, Basis,,"Ref");
			If Object.CombinedTaxRate Then
				Object.Description = Basis.Description + "1";
				//Fill the CombinedRates tabular section
				FillInCombinedRates(Basis.Ref);
				For Each CombinedRate In CombinedRates Do
					CombinedRate.SalesTaxRate 	= Catalogs.SalesTaxRates.EmptyRef();
					CombinedRate.WasModified 	= True;
				EndDo;
			Else
				If ValueIsFilled(Object.SalesTaxComponent) Then
					Items.Agency.ReadOnly 	= True;
					Items.Rate.ReadOnly		= True;
				EndIf;
			EndIf;
		Else //If created empty
			Object.CombinedTaxRate = True;
			CombinedOrSingle = ?(Object.CombinedTaxRate, 1, 0);
			If ValueIsFilled(Object.Parent) Then
				Object.Parent = Catalogs.SalesTaxRates.EmptyRef();
			EndIf;
		EndIf;
		//Update the choice list of sales tax components
		UpdateSalesTaxComponentsChoiceList();
	//For existing object
	ElsIf Not Object.Ref.IsEmpty() Then
		Items.CombinedOrSingle.Visible 	= False;
		Items.Agency.ReadOnly 			= True;
		Items.Rate.ChoiceButton 		= False;
		If ValueIsFilled(Object.Parent) Then
			Items.Rate.ReadOnly = True;
		EndIf;
		If Not Object.CombinedTaxRate Then //Single tax rate
			Items.Description.ReadOnly = True;
		EndIf;
	EndIf;
	
	CombinedOrSingle = ?(Object.CombinedTaxRate, 1, 0);
	
	SetVisibilityAtServer();
	ApplyConditionalAppearance();
	TotalCombinedRate = Format(Object.Rate, "ND=4; NFD=2; NZ=") + "%";
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	If (ValueIsFilled(CurrentObject.Ref)) And (CurrentObject.CombinedTaxRate) Then
		FillInCombinedRates(CurrentObject.Ref);
	EndIf;
	//Update the choice list of sales tax components
	UpdateSalesTaxComponentsChoiceList();	
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
				//If sales tax component is empty then create sales tax component item
				If Not ValueIsFilled(CombinedRate.SalesTaxComponentRef) Then
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
					Request.SetParameter("Description", CombinedRate.Description);
					Result = Request.Execute();
					If Not Result.IsEmpty() Then
						Sel = Result.Select();
						Sel.Next();
						CombinedRate.Agency  = Sel.Agency;
						CombinedRate.Rate	= Sel.Rate;
						CombinedRate.SalesTaxComponentRef = Sel.Ref;
					Else
						SalesTaxComponentObject = Catalogs.SalesTaxComponents.CreateItem();
						SalesTaxComponentObject.Description = CombinedRate.Description;
						SalesTaxComponentObject.Agency		= CombinedRate.Agency;
						SalesTaxComponentObject.Rate		= CombinedRate.Rate;
						SalesTaxComponentObject.Write();
						CombinedRate.SalesTaxComponentRef	= SalesTaxComponentObject.Ref;
					EndIf;                                  				
				EndIf;
				
				SalesTaxRateObject.SalesTaxComponent = CombinedRate.SalesTaxComponentRef;
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
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	//Update the choice list of sales tax components
	UpdateSalesTaxComponentsChoiceList();
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

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	If Object.Ref.IsEmpty() Then 
		ThisIsNew = True;
	Else
		ThisIsNew = False;
	EndIf;
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	NotifyChanged(PredefinedValue("Catalog.SalesTaxComponents.EmptyRef"));
	If ThisIsNew Then
		Notify("SalesTaxRateAdded", Object.Ref);
	EndIf;
EndProcedure

#ENDREGION

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure CombinedOrSingleOnChange(Item)
	Object.CombinedTaxRate = ?(CombinedOrSingle = 1, True, False);
	If Object.CombinedTaxRate Then
		Items.Description.ChoiceList.Clear();
	Else
		Items.Description.ChoiceList.LoadValues(Items.CombinedRatesDescription.ChoiceList.UnloadValues());
	EndIf;
	SetVisibilityAtClient();
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	If Object.CombinedTaxRate Then
		return;
	EndIf;
	Details = GetSalesTaxComponentDetails(TrimAll(Object.Description));
	If Details <> Undefined Then
		Object.Agency = Details.Agency;
		Object.Rate = Details.Rate;
		Object.SalesTaxComponent = Details.SalesTaxComponentRef;
		Items.Agency.ReadOnly 	= True;
		Items.Rate.ReadOnly		= True;
		Items.Rate.ChoiceButton = False;
	Else
		Object.SalesTaxComponent = PredefinedValue("Catalog.SalesTaxComponents.EmptyRef");
		Items.Agency.ReadOnly 	= False;
		Items.Rate.ReadOnly		= False;
		Items.Rate.ChoiceButton = True;
	EndIf;
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
	TotalCombinedRate = Format(Object.Rate, "ND=4; NFD=2; NZ=") + "%";
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

&AtClient
Procedure CombinedRatesDescriptionOnChange(Item)
	Details = GetSalesTaxComponentDetails(TrimAll(Items.CombinedRates.CurrentData.Description));
	If Details <> Undefined Then
		FillPropertyValues(Items.CombinedRates.CurrentData, Details);
		Object.Rate = CombinedRates.Total("Rate");
		TotalCombinedRate = Format(Object.Rate, "ND=4; NFD=2; NZ=") + "%";
	Else
		Items.CombinedRates.CurrentData.SalesTaxComponentRef = PredefinedValue("Catalog.SalesTaxComponents.EmptyRef");
	EndIf;
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
	//Agency and rate can be edited until tax rate component is written. For combined tax rate.
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("CombinedRatesAgency"); 
 	FieldAppearance.Use = True; 
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("CombinedRatesRate"); 
 	FieldAppearance.Use = True; 
	
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("CombinedRates.SalesTaxComponentRef"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= Catalogs.SalesTaxComponents.EmptyRef(); 
	FilterElement.Use				= True;
	
	ElementCA.Appearance.SetParameterValue("ReadOnly", True);
	ElementCA.Appearance.SetParameterValue("BackColor", WebColors.WhiteSmoke);
	
	//Description is unavailable after the tax rate is saved
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("CombinedRatesDescription"); 
 	FieldAppearance.Use = True; 
		
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("CombinedRates.SalesTaxRate"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= Catalogs.SalesTaxRates.EmptyRef(); 
	FilterElement.Use				= True;
	
	ElementCA.Appearance.SetParameterValue("ReadOnly", True);
	ElementCA.Appearance.SetParameterValue("BackColor", WebColors.WhiteSmoke);
	
	//Agency and rate can be edited until tax rate component is written. For single tax rate.
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("Agency"); 
 	FieldAppearance.Use = True; 
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("Rate"); 
 	FieldAppearance.Use = True; 
	
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.SalesTaxComponent"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= Catalogs.SalesTaxComponents.EmptyRef(); 
	FilterElement.Use				= True;
	
	ElementCA.Appearance.SetParameterValue("ReadOnly", True);
	ElementCA.Appearance.SetParameterValue("BackColor", WebColors.WhiteSmoke);
EndProcedure

&AtServer
Procedure DeleteComponentOfTaxAtServer(SalesTaxRateToDelete)
	SalesTaxRateObject = SalesTaxRateToDelete.GetObject();
	SalesTaxRateObject.AdditionalProperties.Insert("DoNotProcessParentObject", True);
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
		TotalCombinedRate = Format(Object.Rate, "ND=4; NFD=2; NZ=") + "%";
		NotifyChanged(Object.Ref);
		NotifyChanged(Parameters.SalesTaxRateToDelete);
	Except
		ErrorInf = ErrorInfo();
		ShowMessageBox(, ErrorInf.Cause.Description,, "Sales tax rates:" + String(Parameters.SalesTaxRateToDelete));
	EndTry;
EndProcedure

&AtServer
Procedure UpdateSalesTaxComponentsChoiceList()
	Request = New Query("SELECT
	                    |	SalesTaxComponents.Description
	                    |FROM
	                    |	Catalog.SalesTaxComponents AS SalesTaxComponents");
	
	ArrayOfTaxComponents = Request.Execute().Unload().UnloadColumn("Description");
	If Not Object.CombinedTaxRate Then
		Items.Description.ChoiceList.LoadValues(ArrayOfTaxComponents);
	Else
		Items.Description.ChoiceList.Clear();
	EndIf;
	Items.CombinedRatesDescription.ChoiceList.LoadValues(ArrayOfTaxComponents);
EndProcedure
	
&AtServerNoContext
Function GetSalesTaxComponentDetails(SalesTaxComponentsDescription)
	Request = New Query("SELECT
	                    |	SalesTaxComponents.Description,
	                    |	SalesTaxComponents.Agency,
	                    |	SalesTaxComponents.Rate,
	                    |	SalesTaxComponents.Ref
	                    |FROM
	                    |	Catalog.SalesTaxComponents AS SalesTaxComponents
	                    |WHERE
	                    |	SalesTaxComponents.Description = &Description");
	Request.SetParameter("Description", SalesTaxComponentsDescription);
	ResTab = Request.Execute().Unload();
	
	If ResTab.Count() > 0 Then
		return New Structure("Description, Agency, Rate, SalesTaxComponentRef", ResTab[0].Description, ResTab[0].Agency, ResTab[0].Rate, ResTab[0].Ref);
	else
		return Undefined;
	EndIf;
EndFunction

&AtServer
Procedure FillInCombinedRates(ParentRef)
	Query = New Query("SELECT ALLOWED
		                  |	SalesTaxRates.Ref AS SalesTaxRate,
		                  |	SalesTaxRates.Description,
		                  |	SalesTaxRates.Agency,
		                  |	SalesTaxRates.Rate,
		                  |	SalesTaxRates.SalesTaxComponent AS SalesTaxComponentRef,
		                  |	FALSE AS WasModified
		                  |FROM
		                  |	Catalog.SalesTaxRates AS SalesTaxRates
		                  |WHERE
		                  |	SalesTaxRates.Parent = &CurrentRate");
	Query.SetParameter("CurrentRate", ParentRef);
	CombinedRates.Load(Query.Execute().Unload());	
EndProcedure

&AtClient
Procedure CombinedRatesBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	If Clone Then
		Cancel = True;
		NewRow = CombinedRates.Add();
		FillPropertyValues(NewRow, Item.CurrentData);
		NewRow.SalesTaxRate = PredefinedValue("Catalog.SalesTaxRates.EmptyRef");
		NewRow.WasModified = True;
		Item.CurrentRow = NewRow.GetID();
	EndIf;
EndProcedure

#EndRegion