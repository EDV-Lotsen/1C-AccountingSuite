
////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If GeneralFunctionsReusable.DisplayAPICodesSetting() = False Then
		Items.api_code.Visible = False;
	EndIf;
	
	If NOT Object.Ref.IsEmpty() Then
		api_code = String(Object.Ref.UUID());
	EndIf;
	
	// custom fields
	
	CF1AType = Constants.CF1AType.Get();
	CF2AType = Constants.CF2AType.Get();
	CF3AType = Constants.CF3AType.Get();
	CF4AType = Constants.CF4AType.Get();
	CF5AType = Constants.CF5AType.Get();
	
	If CF1AType = "None" Then
		Items.CF1String.Visible = False;
	ElsIf CF1AType = "String" Then
		Items.CF1String.Visible = True;
		Items.CF1String.Title = Constants.CF1AName.Get();
	ElsIf CF1AType = "" Then
		Items.CF1String.Visible = False;
	EndIf;
	
	If CF2AType = "None" Then
		Items.CF2String.Visible = False;
	ElsIf CF2AType = "String" Then
		Items.CF2String.Visible = True;
		Items.CF2String.Title = Constants.CF2AName.Get();
	ElsIf CF2AType = "" Then
		Items.CF2String.Visible = False;
	EndIf;

	If CF3AType = "None" Then
		Items.CF3String.Visible = False;
	ElsIf CF3AType = "String" Then
		Items.CF3String.Visible = True;
		Items.CF3String.Title = Constants.CF3AName.Get();
	ElsIf CF3AType = "" Then
		Items.CF3String.Visible = False;
	EndIf;

	If CF4AType = "None" Then
		Items.CF4String.Visible = False;
	ElsIf CF4AType = "String" Then
		Items.CF4String.Visible = True;
		Items.CF4String.Title = Constants.CF4AName.Get();
	ElsIf CF4AType = "" Then
		Items.CF4String.Visible = False;
	EndIf;

	If CF5AType = "None" Then
		Items.CF5String.Visible = False;
	ElsIf CF5AType = "String" Then
		Items.CF5String.Visible = True;
		Items.CF5String.Title = Constants.CF5AName.Get();
	ElsIf CF5AType = "" Then
		Items.CF5String.Visible = False;
	EndIf;

	// end custom fields
	
	If NOT Object.Ref = Catalogs.Addresses.EmptyRef() Then
		Items.Owner.ReadOnly = True;
	EndIf;

	
	If Object.Owner.Vendor = True Then
		Items.RemitTo.Visible = True;
	Else
		Items.RemitTo.Visible = False;
	EndIf;
		
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ApplyAddressValidationStatus();

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If NOT Object.Ref = Catalogs.Addresses.EmptyRef() Then
		Items.Owner.ReadOnly = True;
	EndIf;
	
	//  create account in zoho and contact
	If Constants.zoho_auth_token.Get() <> "" AND Object.Owner.Customer = True Then				
		If Object.DefaultBilling = False AND Object.DefaultShipping = False Then
			If Object.NewObject = True Then
				ThisAction = "create";
			Else
				ThisAction = "update";
			EndIf;                            
			zoho_Functions.ZohoThisContact(ThisAction, Object.Ref);
		Else
			If Object.DefaultBilling = True Then
				zoho_Functions.SetZohoDefaultBilling(Object.Ref);
			EndIf;
			If Object.DefaultShipping = True Then
				zoho_Functions.SetZohoDefaultShipping(Object.Ref);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If NOT GeneralFunctions.EmailCheck(Object.Email) AND Object.Email <> "" Then
		 Message("The current email format is invalid");
		 Cancel = True;
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
Procedure DefaultBillingOnChange(Item)
	
	DefaultBillingOnChangeAtServer();
	
EndProcedure

&AtClient
Procedure DefaultShippingOnChange(Item)
	
	DefaultShippingOnChangeAtServer();
	
EndProcedure

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
Procedure DefaultBillingOnChangeAtServer()
	
	billQuery = New Query("SELECT
	         | Addresses.Ref
	         |FROM
	         | Catalog.Addresses AS Addresses
	         |WHERE
	         | Addresses.DefaultBilling = TRUE
	         | AND Addresses.Owner.Ref = &Ref");
	 billQuery.SetParameter("Ref", object.Owner.Ref);     
	 billResult = billQuery.Execute();
	 addr = billResult.Unload();
	 
	 If (NOT billResult.IsEmpty()) AND object.DefaultBilling = True AND addr[0].Ref <> object.Ref Then
	  Message("Another address is already set as the default billing address.");
	  object.DefaultBilling = False;
  EndIf;
  
EndProcedure

&AtServer
Procedure DefaultShippingOnChangeAtServer()
	
	shipQuery = New Query("SELECT
	         | Addresses.Ref
	         |FROM
	         | Catalog.Addresses AS Addresses
	         |WHERE
	         | Addresses.DefaultShipping = TRUE
	         | AND Addresses.Owner.Ref = &Ref");
	       
	 shipQuery.SetParameter("Ref", object.Owner.Ref);
	 shipResult = shipQuery.Execute();
	 addr = shipResult.Unload();
	 
	 If (NOT shipResult.IsEmpty()) AND object.DefaultShipping = True AND addr[0].Ref <> object.Ref Then
	  Message("Another address is already set as the default shipping address.");
	  object.DefaultShipping = False;
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
Procedure AvataxEditAddressAtServer()
	
	Object.AddressValidated = False;
	ThisForm.Modified		= True;
	ApplyAddressValidationStatus();
	
EndProcedure

#EndRegion



