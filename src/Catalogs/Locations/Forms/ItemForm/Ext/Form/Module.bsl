
////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ApplyAddressValidationStatus();

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	Query = New Query("SELECT
	                  |	Locations.Ref
	                  |FROM
	                  |	Catalog.Locations AS Locations
	                  |WHERE
	                  |	Locations.Description = &Description");
	Query.SetParameter("Description", Object.Description);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then		
	Else
		Dataset = QueryResult.Unload();
		If NOT Dataset[0][0] = Object.Ref Then
			Message = New UserMessage();
			Message.Text=NStr("en='Another location is already using this name. Please use a different name.'");
			//Message.Field = "Object.Description";
			Message.Message();
			Cancel = True;
			Return;
		EndIf;
	EndIf;
		
EndProcedure

&AtClient
Procedure ProcessUserResponseOnAddressValidation(Result, Parameters) Export
	
	If (TypeOf(Result) = Type("Structure")) Then
		FillValidatedAddressAtServer(Result.ValidatedAddress);
	ElsIf (TypeOf(Result) = Type("DialogReturnCode")) Then //Cancel
	EndIf;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure CountryOnChange(Item)
	
	ApplyAddressValidationStatus();

EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure AvataxValidateAddress(Command)
		
	OriginalAddress = New Structure("AddressLine1, AddressLine2, AddressLine3, City, State, Country, ZIP");
	FillPropertyValues(OriginalAddress, Object);
	Params = New Structure("OriginalAddress, AddressRef", OriginalAddress, Object.Ref);
	Notify = New NotifyDescription("ProcessUserResponseOnAddressValidation", ThisObject);
	OpenForm("Catalog.Addresses.Form.AddressValidation", Params, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow); 
	
EndProcedure

&AtClient
Procedure AvataxEditAddress(Command)
	
	AvataxEditAddressAtServer();

EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

&AtServer
Procedure AvataxEditAddressAtServer()
	
	Object.AddressValidated = False;
	ThisForm.Modified		= True;
	ApplyAddressValidationStatus();
	
EndProcedure

&AtServer
Procedure ApplyAddressValidationStatus()
	
	AvataxEnabled = Constants.AvataxEnabled.Get();
	AddressValidationForCountryEnabled = AvaTaxServer.AddressValidationForCountryEnabled(Object.Country);
	AddressValidationDisabled = Constants.AvataxDisableAddressValidation.Get();
	If AvataxEnabled And AddressValidationForCountryEnabled Then
		If Not Items.AddressValidation.Visible Then
			Items.AddressValidation.Visible = True;
		EndIf;
		If Object.AddressValidated Then
			Items.StatusPicture.Picture = PictureLib.TaskComplete;
			Items.StatusText.Title		= "Address validated";
			Items.StatusText.TextColor	= StyleColors.ColorGroupLabel;
			Items.StatusText.BorderColor = Items.StatusText.TextColor;
			Items.Address.ReadOnly		= True;
			Items.Decoration4.Visible 	= False;
			Items.AvataxEditAddress.Visible	= True;
		Else //Address not validated
			Items.StatusPicture.Picture = PictureLib.Questionnaire;
			Items.StatusText.Title		= "Not validated";
			Items.StatusText.TextColor	= StyleColors.ColorSecondaryLabel;
			Items.StatusText.BorderColor = Items.StatusText.TextColor;
			Items.Address.ReadOnly		= False;
			Items.Decoration4.Visible 	= True;
			Items.AvataxEditAddress.Visible	= False;
		EndIf;
		If Not AddressValidationDisabled Then
			Items.AvataxValidateAddress.Visible = True;
		Else
			Items.AvataxValidateAddress.Visible = False;
		EndIf;
	Else
		Items.AddressValidation.Visible = False;
		Items.Address.ReadOnly			= False;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillValidatedAddressAtServer(ValidatedAddress)
	
	FillPropertyValues(Object, ValidatedAddress);
	//Find Region and Country
	Request = New Query("SELECT
	                    |	Countries.Ref,
	                    |	""Country"" AS PartType
	                    |FROM
	                    |	Catalog.Countries AS Countries
	                    |WHERE
	                    |	Countries.Code = &CountryCode
	                    |	AND Countries.DeletionMark = FALSE
	                    |
	                    |UNION ALL
	                    |
	                    |SELECT
	                    |	States.Ref,
	                    |	""Region""
	                    |FROM
	                    |	Catalog.States AS States
	                    |WHERE
	                    |	States.Code = &RegionCode
	                    //|	AND States.Country.Code = &CountryCode
	                    |	AND States.DeletionMark = FALSE");
	Request.SetParameter("CountryCode", ValidatedAddress.CountryCode);
	Request.SetParameter("RegionCode", ValidatedAddress.RegionCode);
	Tab = Request.Execute().Unload();
	FoundCountryRows = Tab.FindRows(New Structure("PartType", "Country"));
	If FoundCountryRows.Count() > 0 Then
		Object.Country 	= FoundCountryRows[0].Ref; 
	ElsIf ValueIsFilled(ValidatedAddress.CountryCode) Then
		//Should create new country (though, normally it should not occur)
		NewCountry = Catalogs.Countries.CreateItem();
		NewCountry.Description 	= ValidatedAddress.CountryCode;
		NewCountry.Code			= ValidatedAddress.CountryCode;
		NewCountry.Write();
		Object.Country = NewCountry.Ref;
	Else
		Object.Country = Catalogs.Countries.EmptyRef();
	EndIf;
	FoundRegionRows = Tab.FindRows(New Structure("PartType", "Region"));
	If FoundRegionRows.Count() > 0 Then
		Object.State 	= FoundRegionRows[0].Ref;
	ElsIf ValueIsFilled(ValidatedAddress.RegionCode) Then
		//Should create new region to use in the address
		NewRegion = Catalogs.States.CreateItem();
		NewRegion.Description 	= ValidatedAddress.RegionCode;
		NewRegion.Code			= ValidatedAddress.RegionCode;
		NewRegion.Country		= Object.Country;
		NewRegion.Write();
		Object.State			= NewRegion.Ref;
	Else
		Object.State			= Catalogs.States.EmptyRef();
	EndIf;
	Object.AddressValidated = True;
	ThisForm.Modified = True;
	ApplyAddressValidationStatus();
	
EndProcedure

#EndRegion
