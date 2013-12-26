
&AtClient
Procedure MultiLocationOnChange(Item)
	Message("After enabling the multi-location feature can not be disabled.");
	//RefreshInterface();
EndProcedure

&AtClient
Procedure MultiCurrencyOnChange(Item)
	Message("After enabling the multi-currency feature can not be disabled.");
	//RefreshInterface();
EndProcedure

&AtClient
Procedure USFinLocalizationOnChange(Item)
	//Message("Restart the program for the setting to take effect");
	//RefreshInterface();
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BinaryLogo = GeneralFunctions.GetLogo();
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	ImageAddress = TempStorageAddress;
	Items.image.PictureSize = PictureSize.AutoSize;
	
	//Closing the books
	ChoiceList = Items.PeriodClosingOption.ChoiceList;
	ChoiceList.Add(Enums.PeriodClosingOptions.OnlyWarn);
	ChoiceList.Add(Enums.PeriodClosingOptions.WarnAndRequirePassword);
	PeriodClosingPasswordConfirm = ConstantsSet.PeriodClosingPassword;
	
	If Not ValueIsFilled(ConstantsSet.PeriodClosingOption) Then
		ConstantsSet.PeriodClosingOption = Enums.PeriodClosingOptions.WarnAndRequirePassword
	EndIf;
	
	If ConstantsSet.PeriodClosingOption = Enums.PeriodClosingOptions.WarnAndRequirePassword Then
		Items.PeriodClosingPassword.Visible = True;
		Items.PeriodClosingPasswordConfirm.Visible = True;
	Else
		Items.PeriodClosingPassword.Visible = False;
		Items.PeriodClosingPasswordConfirm.Visible = False;
	EndIf;
		
	If NOT Constants.APISecretKey.Get() = "" Then
		Items.APISecretKey.ReadOnly = True;		
	EndIf;
	
	If Constants.USFinLocalization.Get() = True Then
		Items.USFinLocalization.ReadOnly = True;
		Items.VATFinLocalization.ReadOnly = True;
	EndIf;
	
	If Constants.MultiCurrency.Get() = True Then
		Items.MultiCurrency.ReadOnly = True;
	EndIf;
	
	If Constants.MultiLocation.Get() = True Then
		Items.MultiLocation.ReadOnly = True;
	EndIf;
	
	Items.DefaultCurrency.ReadOnly = True;
			
EndProcedure

&AtClient
Procedure DefaultCurrencyOnChange(Item)
	Message("Restart the program for the setting to take effect");
EndProcedure

&AtClient
Procedure VATFinLocalizationOnChange(Item)
	
	//GeneralFunctions.VATSetup();
	//Message("Restart the program for the setting to take effect");
	//RefreshInterface();

EndProcedure

&AtClient
Procedure VendorNameOnChange(Item)
	
	//Message("Restart the program for the setting to take effect");
	//RefreshInterface();
	
EndProcedure

&AtClient
Procedure CustomerNameOnChange(Item)
	
	//Message("Restart the program for the setting to take effect");
	//RefreshInterface();
	
EndProcedure

&AtClient
Procedure PriceIncludesVATOnChange(Item)
	
	//Message("Restart the program for the setting to take effect");
	//RefreshInterface();

EndProcedure

&AtClient
Procedure UploadLogo(Command)
	
	Var SelectedName;
	ImageAddress = "";
	
	NotifyDescription = New NotifyDescription("FileUpload",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	//BinaryLogo = GeneralFunctions.GetLogo();
	//TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	//ImageAddress = TempStorageAddress;
	
EndProcedure

&AtClient
Procedure FileUpload(a,b,c,d) Export
	
	PlaceImageFile(b);
	
EndProcedure

&AtServer
Procedure PlaceImageFile(TempStorageName)
	
	If NOT TempStorageName = Undefined Then
	
		BinaryData = GetFromTempStorage(TempStorageName);
		
		///
		
		HeadersMap = New Map();
		HeadersMap.Insert("Authorization", "Client-ID " + ServiceParameters.ImgurClientID());
		
		HTTPRequest = New HTTPRequest("/3/image", HeadersMap);
		HTTPRequest.SetBodyFromBinaryData(BinaryData);
		
		SSLConnection = New OpenSSLSecureConnection();
		
		HTTPConnection = New HTTPConnection("api.imgur.com",,,,,,SSLConnection); //imgur-apiv3.p.mashape.com
		Result = HTTPConnection.Post(HTTPRequest);
		ResponseBody = Result.GetBodyAsString(TextEncoding.UTF8);
		ResponseJSON = InternetConnectionClientServer.DecodeJSON(ResponseBody);
		image_url = ResponseJSON.data.link;
		// Ctrl + _
		ConstantsSet.logoURL = image_url;
		
	    ///
		
		NewRow = InformationRegisters.CustomPrintForms.CreateRecordManager();
		NewRow.ObjectName = "logo";
		NewRow.TemplateName = "logo";
		NewRow.Template = New ValueStorage(BinaryData, New Deflation(9));
		NewRow.Write();	
		DeleteFromTempStorage(TempStorageName);
		
	EndIf;
	
	BinaryLogo = GeneralFunctions.GetLogo();
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	ImageAddress = TempStorageAddress;
  	
EndProcedure

 
&AtClient
Procedure StripeConnect(Command)
	
	statestring = GetAPISecretKeyF();
	GotoURL("https://addcard.accountingsuite.com/connect?state=" + statestring);

EndProcedure

&AtServer
Function GetAPISecretKeyF()
	
	Return Constants.APISecretKey.Get();
	
EndFunction


&AtClient
Procedure OnOpen(Cancel)
 
	 If SettingAccessCheck() = false Then

	    Items.Common.ChildItems.Logo.ChildItems.UploadLogo.Enabled = false;
		Items.Common.ChildItems.Integrations.ChildItems.Stripe.ChildItems.StripeConnect.Enabled = false;

	 Else
		Items.Common.ChildItems.Logo.ChildItems.UploadLogo.Enabled = true;
		Items.Common.ChildItems.Integrations.ChildItems.Stripe.ChildItems.StripeConnect.Enabled = true;

	 Endif;
	
EndProcedure

&AtServer
Function SettingAccessCheck()
	CurUser = InfoBaseUsers.FindByName(SessionParameters.ACSUser);
	If CurUser.Roles.Contains(Metadata.Roles.FullAccess1) = true Or CurUser.Roles.Contains(Metadata.Roles.FullAccess) = true Then
		Return true;
	Else
		Return false;
	Endif
EndFunction


//&AtClient
//Procedure VerifyEmail(Command)
//	VerifyEmailAtServer();
//EndProcedure


//&AtServer
//Procedure VerifyEmailAtServer()
//		HeadersMap = New Map();
//	
//		HTTPRequest = New HTTPRequest("/ses_email_verify",HeadersMap);
//		HTTPRequest.SetBodyFromString(Constants.Email.Get(),TextEncoding.ANSI);

//	
//		SSLConnection = New OpenSSLSecureConnection();
//	
//		HTTPConnection = New HTTPConnection("intacs.accountingsuite.com",,,,,,SSLConnection);
//		Result = HTTPConnection.Post(HTTPRequest);
//		
//		Message("You will receive a verification email to " + Constants.Email.Get());

//EndProcedure


&AtClient
Procedure DwollaConnect(Command)
	
	statestring = GetAPISecretKeyF();	
	GoToURL("https://www.dwolla.com/oauth/v2/authenticate?client_id=" + ServiceParameters.DwollaClientID() + "&response_type=code&redirect_uri=https://pay.accountingsuite.com/dwolla_oauth?state=" + GetTenantValue() + "&scope=send%7Ctransactions%7Cfunding%7Cbalance");
	
EndProcedure

&AtServer
Function GetTenantValue()
	
	Return SessionParameters.TenantValue;
	
EndFunction


&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If Constants.MultiCurrency.Get() = True Then
		Items.MultiCurrency.ReadOnly = True;
	EndIf;
	
	If Constants.MultiLocation.Get() = True Then
		Items.MultiLocation.ReadOnly = True;
	EndIf;
	
	Constants.Email.Set(Constants.CurrentUserEmail.Get().Description);	
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	RefreshInterface();
EndProcedure                 

&AtClient
Procedure PeriodClosingOptionOnChange(Item)
	
	If ConstantsSet.PeriodClosingOption = PredefinedValue("Enum.PeriodClosingOptions.WarnAndRequirePassword") Then
		Items.PeriodClosingPassword.Visible = True;
		Items.PeriodClosingPasswordConfirm.Visible = True;
	Else
		Items.PeriodClosingPassword.Visible = False;
		Items.PeriodClosingPasswordConfirm.Visible = False;
	EndIf;

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If ConstantsSet.PeriodClosingOption = PredefinedValue("Enum.PeriodClosingOptions.WarnAndRequirePassword") Then
		If (ConstantsSet.PeriodClosingPassword <> PeriodClosingPasswordConfirm) Then
			
			MessOnError = New UserMessage();
			MessOnError.Field = "ConstantsSet.PeriodClosingPassword";
			MessOnError.Text  = "Different values in ""Password"" and ""Confirm password"". Re-enter ""Password""";
			MessOnError.Message();
			
			Cancel = True;
		EndIf;
	EndIf;
EndProcedure

//&AtServer
//Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
//	If EmailChange = True Then
//		Constants.Email.Set(Constants.CurrentUserEmail.Get().Description);
//	EndIf;

//EndProcedure

//&AtClient
//Procedure CurrentUserEmailOnChange(Item)
//	EmailChange = True;
//EndProcedure



