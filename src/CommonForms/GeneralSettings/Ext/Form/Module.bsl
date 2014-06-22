
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

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	old_key = Constants.APISecretKey.Get();
	
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
		
	If Constants.MultiCurrency.Get() = True Then
		Items.MultiCurrency.ReadOnly = True;
	EndIf;
	
	If Constants.MultiLocation.Get() = True Then
		Items.MultiLocation.ReadOnly = True;
	EndIf;
	
	Items.DefaultCurrency.ReadOnly = True;
	
	//Sales tax
	ChargingSalesTax = ?(ConstantsSet.SalesTaxCharging, 1, 2);
	If ConstantsSet.SalesTaxCharging Then
		Items.SalesTaxDefaults.Enabled = True;
	Else
		Items.SalesTaxDefaults.Enabled = False;
	EndIf;
EndProcedure

&AtClient
Procedure DefaultCurrencyOnChange(Item)
	Message("Restart the program for the setting to take effect");
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
		Items.ClosingTheBooks.ChildItems.PeriodClosingDate.ReadOnly = True;
		Items.ClosingTheBooks.ChildItems.PeriodClosingOption.ReadOnly = True;
		Items.ClosingTheBooks.ChildItems.PeriodClosingPassword.ReadOnly = True;
		Items.ClosingTheBooks.ChildItems.PeriodClosingPasswordConfirm.ReadOnly = True;
		
		Items.CompanyContact.ChildItems.Group1.ChildItems.Cell.ReadOnly = True;
		Items.CompanyContact.ChildItems.Group1.ChildItems.Fax.ReadOnly = True;
		Items.CompanyContact.ChildItems.Group1.ChildItems.FederalTaxID.ReadOnly = True;
		Items.CompanyContact.ChildItems.Group2.ChildItems.CurrentUserEmail.ReadOnly = True;
		Items.GeneralSettings.ReadOnly = True;
		Items.PostingAccounts.ReadOnly = True;
		Items.Development.ChildItems.APISecretKey.Visible = False;
		Message("You are viewing settings with limited rights(Non-Admin).");

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
	RefreshReusableValues();
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
		Items.PeriodClosingPassword.Visible = True;
		Items.PeriodClosingPasswordConfirm.Visible = True;
	Else
		Items.PeriodClosingPassword.Visible = False;
		Items.PeriodClosingPasswordConfirm.Visible = False;
	EndIf;

EndProcedure

&AtClient
Procedure ApiLogConnect(Command)
	GoToURL("https://apilog.accountingsuite.com");
EndProcedure

&AtClient
Procedure DocConnect(Command)
	GoToURL("http://developer.accountingsuite.com");
EndProcedure

&AtClient
Procedure ChargingSalesTaxOnChange(Item)
	ConstantsSet.SalesTaxCharging = ?(ChargingSalesTax = 1, True, False);
	If ConstantsSet.SalesTaxCharging Then
		Items.SalesTaxDefaults.Enabled = True;
	Else
		Items.SalesTaxDefaults.Enabled = False;
	EndIf;
EndProcedure

&AtClient
Procedure AddressesContacts(Command)
	OpenForm("Catalog.Addresses.ListForm", , , , , );
EndProcedure

&AtClient
Procedure Countries(Command)
	OpenForm("Catalog.Countries.ListForm", , , , , );
EndProcedure

&AtClient
Procedure States(Command)
	OpenForm("Catalog.States.ListForm", , , , , );
EndProcedure

&AtClient
Procedure Currencies(Command)
	OpenForm("Catalog.Currencies.ListForm", , , , , );
EndProcedure

&AtClient
Procedure ExchangeRates(Command)
	OpenForm("InformationRegister.ExchangeRates.ListForm",,,,,,,);
EndProcedure

&AtClient
Procedure PaymentTerms(Command)
	OpenForm("Catalog.PaymentTerms.ListForm", , , , , );
EndProcedure

&AtClient
Procedure UnitsOfMeasure(Command)
	OpenForm("Catalog.UM.ListForm", , , , , );
EndProcedure

&AtClient
Procedure ShippingCarriers(Command)
	OpenForm("Catalog.ShippingCarriers.ListForm", , , , , );
EndProcedure

&AtClient
Procedure DocumentNumbering(Command)
	OpenForm("Catalog.DocumentNumbering.ListForm", , , , , );
EndProcedure

&AtClient
Procedure ItemCategories(Command)
	OpenForm("Catalog.ProductCategories.ListForm", , , , , );
EndProcedure

&AtClient
Procedure ActiveUserList(Command)
	OpenForm("DataProcessor.ActiveUserList.Form.ActiveUserListForm",,,,,,,);
EndProcedure

&AtClient
Procedure SalesPeople(Command)
	OpenForm("Catalog.SalesPeople.ListForm", , , , , );
EndProcedure

&AtClient
Procedure PriceLevels(Command)
	OpenForm("Catalog.PriceLevels.ListForm", , , , , );
EndProcedure

&AtClient
Procedure ExpensifyCategories(Command)
	OpenForm("Catalog.ExpensifyCategories.ListForm", , , , , );
EndProcedure

&AtClient
Procedure PaymentMethods(Command)
	OpenForm("Catalog.PaymentMethods.ListForm", , , , , );
EndProcedure

&AtClient
Procedure Locations(Command)
	OpenForm("Catalog.Locations.ListForm", , , , , );
EndProcedure

&AtClient
Procedure Classes(Command)
	OpenForm("Catalog.Classes.ListForm", , , , , );
EndProcedure

&AtClient
Procedure StripeDisconnect(Command)
	StripeDisconnectServer();
EndProcedure

&AtServer
Procedure StripeDisconnectServer();
	
	Constants.spk.Set("");
	Constants.spk2.Set("");
	Constants.spk3.Set("");
	Constants.secret_temp.Set("");
	Constants.publishable_temp.Set("");
	Constants.StripeUser.Set("");
	Constants.stripe_live_status.Set("");
	Constants.stripe_display_name.Set("");
	// add user name and live/test status
	
	//SetPrivilegedMode(True);
		 
	HeadersMap = New Map();
	HeadersMap.Insert("apisecretkey", Constants.APISecretKey.Get());
	
	HTTPRequest = New HTTPRequest("/deletestripeauth", HeadersMap);
	
	SSLConnection = New OpenSSLSecureConnection();
	
	HTTPConnection = New HTTPConnection("intacs.accountingsuite.com",,,,,,SSLConnection);
	Result = HTTPConnection.Post(HTTPRequest);
		
	//SetPrivilegedMode(False);

	Message("Your Stripe account has been disconnected from AccountingSuite");	
	
	
EndProcedure

&AtClient
Procedure DwollaDisconnect(Command)
	DwollaDisconnectServer();
EndProcedure

&AtServer
Procedure DwollaDisconnectServer();
	
	Constants.dwolla_access_token.Set("");
	Message("Your Dwolla account has been disconnected from AccountingSuite");
	
EndProcedure

&AtClient
Procedure RollAPI(Command)
	RollAPIAtServer();
EndProcedure

&AtServer
Procedure RollAPIAtServer()
	
	SymbolString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; //62
	RandomString20 = "";
	RNG = New RandomNumberGenerator;	
	For i = 0 to 19 Do
		RN = RNG.RandomNumber(1, 62);
		RandomString20 = RandomString20 + Mid(SymbolString,RN,1);
	EndDo;
	ConstantsSet.APISecretKey = RandomString20;
	ThisForm.Modified = True;
	ThisForm.Write();
	
	new_key = Constants.APISecretKey.get();
	
	HeadersMap = New Map();
	HeadersMap.Insert("oldkey", old_key );
	HeadersMap.Insert("newkey", new_key);	
	HTTPRequest = New HTTPRequest("/rollapi", HeadersMap);
	SSLConnection = New OpenSSLSecureConnection();
	HTTPConnection = New HTTPConnection("intacs.accountingsuite.com",,,,,,SSLConnection);
	Result = HTTPConnection.Post(HTTPRequest);
	
	SetPrivilegedMode(True);
	ChangeUser = InfoBaseUsers.FindByName("api");
	ChangeUser.Password = new_key;
	ChangeUser.Write();
	SetPrivilegedMode(False);
	
EndProcedure

&AtClient
Procedure OpenSalesOrder(Command)
	OpenForm("DataProcessor.PrintFormSetup.Form.SOFormSetup" );
EndProcedure

&AtClient
Procedure OpenInvoice(Command)
	OpenForm("DataProcessor.PrintFormSetup.Form.SIFormSetup" );
EndProcedure

&AtClient
Procedure OpenPO(Command)
	OpenForm("DataProcessor.PrintFormSetup.Form.POFormSetup" );
EndProcedure

&AtClient
Procedure OpenCashReceipt(Command)
	OpenForm("DataProcessor.PrintFormSetup.Form.CRFormSetup" );
EndProcedure

&AtClient
Procedure OpenQuote(Command)
	OpenForm("DataProcessor.PrintFormSetup.Form.QuoteFormSetup" );
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





