
&AtClient
Procedure MultiLocationOnChange(Item)
	Message("After enabling the multi-location feature can not be disabled.");
	//RefreshInterface();
EndProcedure

&AtClient
Procedure MultiCurrencyOnChange(Item)
	
	Message("After enabling the multi-currency feature can not be disabled.");
	SetEnabledExchangeLoss();

	//RefreshInterface();
EndProcedure

&AtClient
Procedure SetEnabledExchangeLoss()
	
	If ConstantsSet.MultiCurrency Then
		Items.ExchangeLoss.Visible = True;
	Else
		Items.ExchangeLoss.Visible = False;
	EndIf;
	
EndProcedure


&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IsInternalUser = Find(SessionParameters.ACSUser,"@accountingsuite.com");
	If IsInternalUser = 0 Then
		Items.DataImport.Visible = False;
	EndIf;
	
		
	old_key = Constants.APISecretKey.Get();
	OldCompanyName = Constants.SystemTitle.Get();
	OldZohoAuthToken = ConstantsSet.zoho_auth_token;
	
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
		ConstantsSet.PeriodClosingOption = Enums.PeriodClosingOptions.OnlyWarn;
	EndIf;
	
	If ConstantsSet.PeriodClosingOption = Enums.PeriodClosingOptions.WarnAndRequirePassword Then
		Items.PeriodClosingPassword.Visible = True;
		Items.PeriodClosingPasswordConfirm.Visible = True;
	Else
		Items.PeriodClosingPassword.Visible = False;
		Items.PeriodClosingPasswordConfirm.Visible = False;
	EndIf;
	
	If ConstantsSet.PeriodClosingByModule Then
		Items.ClosingDateByModule.Visible = True;
		Items.FillClosingDate.Visible = True;
	Else
		Items.ClosingDateByModule.Visible = False;
		Items.FillClosingDate.Visible = False;
	EndIf;
	
	FillClosingDateByModule();
		
	If NOT Constants.APISecretKey.Get() = "" Then
		Items.APISecretKey.ReadOnly = True;		
	EndIf;
		
	If Constants.MultiCurrency.Get() Then
		Items.MultiCurrency.ReadOnly = True;
	EndIf;
	
	If Constants.MultiLocation.Get() Then
		Items.MultiLocation.ReadOnly = True;
	EndIf;
	
	If Constants.EnhancedInventoryShipping.Get() Then
		Items.EnhancedInventoryShipping.ReadOnly = True;
	EndIf;
	
	If Constants.EnhancedInventoryReceiving.Get() Then
		Items.EnhancedInventoryReceiving.ReadOnly = True;
	EndIf;
		
	If Constants.UsePricePrecision.Get() Then
		Items.UsePricePrecision.ReadOnly = True;
	EndIf;
	
	Items.DefaultCurrency.ReadOnly = True;
	
	//Sales tax
	ChargingSalesTax = ?(ConstantsSet.SalesTaxCharging, 1, 2);
	If ConstantsSet.SalesTaxCharging Then
		Items.SalesTaxSettingsGroup.Enabled = True;
	Else
		Items.SalesTaxSettingsGroup.Enabled = False;
	EndIf;
	SalesTaxEngine = ?(ConstantsSet.AvataxEnabled, 1, 2); 
	If SalesTaxEngine = 1 Then
		Items.SalesTaxBySources.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
		Items.ByAvaTaxPage.Visible = True;
	ElsIf SalesTaxEngine = 2 Then
		Items.SalesTaxBySources.PagesRepresentation = FormPagesRepresentation.None;
		Items.ByAvaTaxPage.Visible = False;
		Items.SalesTaxBySources.CurrentPage = Items.ByAccountingSuitePage;
	EndIf;
	
	//If IsInRole("BankAccounting") Then 
	//	// Cont Info 				// Leave
	//	// Lists 					// Leave
	//	// Features					// Part. Hide
	//	For Each ItemL In Items.GeneralSettings.ChildItems Do 
	//		ItemL.Visible = False;
	//	EndDo;
	//	Items.CheckHorizontalAdj.Visible = True;
	//	Items.CheckVerticalAdj.Visible = True;
	//	Items.show_yodlee_upload_period.Visible = True;
	//	Items.DisplayExtendedAccountInfo.Visible = True;
	//	Items.Group28.Visible = True;
	//	Items.SetCompactUIMode.Visible = True;
	//	Items.SetStandardUIMode.Visible = True;
	//	Items.AllowDuplicateCheckNumbers.Visible = True;
	//	Items.FirstMonthOfFiscalYear.Visible = True;
	//	Items.CFO_ProcessingMonth.Visible = True;

	//	
	//	// Post Accnts				// Leave
	//	// Closing books			// Part. Hide
	//	Items.PeriodClosingByModule.Visible = False;
	//	
	//	// Sales Tax				// Hide
	//	Items.SalesTax.Visible = False;
	//	// Custom Fields			// Hide
	//	Items.CompanyCustomFields.Visible = False;
	//	// adres custom Fields		// Hide
	//	Items.AddressCustomFields.Visible = False;
	//	// Items custom Fields		// Hide
	//	Items.ItemCustomFields.Visible = False;
	//	
	//	// Logo						// Leave
	//	// Integration				// Hide
	//	Items.Integrations.Visible = False;
	//	// Development				// Hide
	//	Items.Development.Visible = False;
	//	// Print form setup			// Hide
	//	Items.SetupPrintForms.Visible = False;
	//	
	//EndIf;	

EndProcedure

&AtServer
Procedure FillClosingDateByModule()
	SetPrivilegedMode(True);
	DocumentsTable = ClosingDateByModule.Unload();
	DocumentsTable.Clear();
	For Each MetaDocument In Metadata.Documents Do
		NewRow = DocumentsTable.Add();
		NewRow.DocumentName = MetaDocument.Name;
		NewRow.DocumentPresentation = MetaDocument.Synonym;
	EndDo;
	Request = New Query("SELECT
	                    |	DocumentTypes.DocumentName,
	                    |	DocumentTypes.DocumentPresentation
	                    |INTO DocumentTypes
	                    |FROM
	                    |	&DocumentTypes AS DocumentTypes
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	DocumentTypes.DocumentName,
	                    |	DocumentTypes.DocumentPresentation,
	                    |	ISNULL(PeriodClosingByModule.PeriodClosingDate, &CommonClosingDate) AS ClosingDate
	                    |FROM
	                    |	DocumentTypes AS DocumentTypes
	                    |		LEFT JOIN InformationRegister.PeriodClosingByModule AS PeriodClosingByModule
	                    |		ON DocumentTypes.DocumentName = PeriodClosingByModule.Document");
	Request.SetParameter("DocumentTypes", DocumentsTable);
	Request.SetParameter("CommonClosingDate", ConstantsSet.PeriodClosingDate);
	ClosingDateByModule.Load(Request.Execute().Unload());
	SetPrivilegedMode(False);
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
	
	If ImageFormatCheck(c) Then	
		PlaceImageFile(b);
	Else
		Message("Please upload a valid image type(.jpg, .jpeg, .png, .gif)");
	EndIf;
	
EndProcedure

// Checks if image is a valid image type
&AtClient
Function ImageFormatCheck(Filename)
	
	If StrOccurenceCount((Right(Filename, 5)),".jpg") <> 0 
		OR StrOccurenceCount((Right(Filename, 5)),".jpeg") <> 0
		OR StrOccurenceCount((Right(Filename, 5)),".png") <> 0
		OR StrOccurenceCount((Right(Filename, 5)),".gif") <> 0 Then
		Return True;
	EndIf;
	
	Return False;

EndFunction

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

 


&AtServer
Function GetAPISecretKeyF()
	
	Return Constants.APISecretKey.Get();
	
EndFunction




&AtClient
Procedure OnOpen(Cancel)
 
	 If SettingAccessCheck() = false Then

	    Items.Common.ChildItems.Logo.ChildItems.UploadLogo.Enabled = false;
		//Items.Common.ChildItems.Integrations.ChildItems.Stripe.ChildItems.StripeConnect.Enabled = false;
		Items.PeriodClosingDate.ReadOnly = True;
		Items.PeriodClosingOption.ReadOnly = True;
		Items.PeriodClosingPassword.ReadOnly = True;
		Items.PeriodClosingPasswordConfirm.ReadOnly = True;
		Items.PeriodClosingByModule.ReadOnly = True;
		Items.ClosingDateByModule.ReadOnly = True;
		
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
		//Items.Common.ChildItems.Integrations.ChildItems.Stripe.ChildItems.StripeConnect.Enabled = true;

	Endif;
	
	SetEnabledPricePrecision();
	SetEnabledOCLAccount();
	SetEnabledTaxPayableAccount();
	SetEnabledExchangeLoss();
	
EndProcedure

&AtServer
Function SettingAccessCheck()
	return True;
	CurUser = InfoBaseUsers.FindByName(SessionParameters.ACSUser);
	If CurUser.Roles.Contains(Metadata.Roles.FullAccess1) = true Or CurUser.Roles.Contains(Metadata.Roles.FullAccess) = true Then
		Return true;
	Else
		Return false;
	Endif
EndFunction

&AtServer
Function GetTenantValue()
	
	Return SessionParameters.TenantValue;
	
EndFunction


&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If Constants.MultiCurrency.Get() Then
		Items.MultiCurrency.ReadOnly = True;
	EndIf;
	
	If Constants.MultiLocation.Get() Then
		Items.MultiLocation.ReadOnly = True;
	EndIf;
	
	If Constants.EnhancedInventoryShipping.Get() Then
		Items.EnhancedInventoryShipping.ReadOnly = True;
	EndIf;
	
	If Constants.EnhancedInventoryReceiving.Get() Then
		Items.EnhancedInventoryReceiving.ReadOnly = True;
	EndIf;
	
	If Constants.UsePricePrecision.Get() Then
		Items.UsePricePrecision.ReadOnly = True;
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
	
	//If ConstantsSet.PeriodClosingOption = PredefinedValue("Enum.PeriodClosingOptions.WarnAndRequirePassword") Then
	//	Items.PeriodClosingPassword.Visible = True;
	//	Items.PeriodClosingPasswordConfirm.Visible = True;
	//Else
	//	Items.PeriodClosingPassword.Visible = False;
	//	Items.PeriodClosingPasswordConfirm.Visible = False;
	//EndIf;
	If ConstantsSet.PeriodClosingOption = PredefinedValue("Enum.PeriodClosingOptions.WarnAndRequirePassword") Then
		If Not ValueIsFilled(ConstantsSet.PeriodClosingPassword) Then
			Cancel = True;
			MessOnError = New UserMessage();
			MessOnError.Field = "ConstantsSet.PeriodClosingPassword";
			MessOnError.Text  = "Field ""Password"" not filled";
			MessOnError.Message();
		EndIf;
		If PeriodClosingPasswordConfirm <> ConstantsSet.PeriodClosingPassword Then
			Cancel = True;
			MessOnError = New UserMessage();
			MessOnError.Field = "PeriodClosingPasswordConfirm";
			MessOnError.Text  = "Password confirmation failed. Re-enter password.";
			MessOnError.Message();
		EndIf;
	EndIf;
	
	If ConstantsSet.EnhancedInventoryReceiving And ConstantsSet.OCLAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
		
		Cancel = True;
		
		Message = New UserMessage();
		Message.Text = NStr("en = 'Field ""OCL account"" is empty'");
		Message.Field = "ConstantsSet.OCLAccount";
		Message.DataPath = "ConstantsSet";
		Message.SetData(ConstantsSet);
		Message.Message();
		
	EndIf;
	
	If ConstantsSet.SalesTaxCharging And ConstantsSet.TaxPayableAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
		
		Cancel = True;
		
		Message = New UserMessage();
		Message.Text = NStr("en = 'Field ""Tax payable"" is empty'");
		Message.Field = "ConstantsSet.TaxPayableAccount";
		Message.DataPath = "ConstantsSet";
		Message.SetData(ConstantsSet);
		Message.Message();
		
	EndIf;
	
	If ConstantsSet.MultiCurrency And ConstantsSet.ExchangeLoss = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
		
		Cancel = True;
		
		Message = New UserMessage();
		Message.Text = NStr("en = 'Field ""Exchange gain or loss"" is empty'");
		Message.Field = "ConstantsSet.ExchangeLoss";
		Message.DataPath = "ConstantsSet";
		Message.SetData(ConstantsSet);
		Message.Message();
		
	EndIf;
	
	If OldZohoAuthToken <> ConstantsSet.zoho_auth_token AND ConstantsSet.zoho_auth_token <> "" Then
		PathDef = "crm.zoho.com/crm/private/json/Leads/";
				
		AuthHeader = "authtoken=" + ConstantsSet.zoho_auth_token + "&scope=crmapi";
			
		URLstring = PathDef + "getMyRecords?" + AuthHeader;
		
		HeadersMap = New Map();			
		HTTPRequest = New HTTPRequest("", HeadersMap);	
		SSLConnection = New OpenSSLSecureConnection();
		HTTPConnection = New HTTPConnection(URLstring,,,,,,SSLConnection);
		Result = HTTPConnection.Post(HTTPRequest);
		ResultBody = Result.GetBodyAsString();
		ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody);
		Try errorCode = ResultBodyJSON.response.error.code Except errorCode = Undefined EndTry;
		If errorCode = "4834" Then
			Cancel = True;
			Message = New UserMessage();
			Message.Text = "The Zoho Authentication Token is invalid. Please enter a valid token or delete the code.";
			Message.Message();
		EndIf;
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
		Items.SalesTaxSettingsGroup.Enabled = True;
	Else
		Items.SalesTaxSettingsGroup.Enabled = False;
		ConstantsSet.AvataxEnabled = False;
		SalesTaxEngine = 2; //Avatax disabled
		SalesTaxEngineOnChange(Undefined);
	EndIf;
	
	SetEnabledTaxPayableAccount();

EndProcedure

&AtClient
Procedure SetEnabledTaxPayableAccount()
	
	If ConstantsSet.SalesTaxCharging Then
		Items.TaxPayableAccount.Visible = True;
	Else
		Items.TaxPayableAccount.Visible = False;
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

//&AtClient
//Procedure UnitsOfMeasure(Command)
//	OpenForm("Catalog.UM.ListForm", , , , , );
//EndProcedure

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
Procedure Classes(Command)
	OpenForm("Catalog.Classes.ListForm", , , , , );
EndProcedure


&AtClient
Procedure OpenSalesOrder(Command)
	OpenForm("DataProcessor.PrintFormSetup.Form.SOFormSetup" );
EndProcedure

&AtClient
Procedure OpenShipment(Command)
	OpenForm("DataProcessor.PrintFormSetup.Form.ShipmentFormSetup" );
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
Procedure OpenHeadersAndFooters(Command)
	OpenForm("InformationRegister.HeadersAndFooters.ListForm" );
EndProcedure


&AtClient
Procedure OpenCashReceipt(Command)
	OpenForm("DataProcessor.PrintFormSetup.Form.CRFormSetup" );
EndProcedure

&AtClient
Procedure OpenQuote(Command)
	OpenForm("DataProcessor.PrintFormSetup.Form.QuoteFormSetup" );
EndProcedure

&AtClient
Procedure OpenCreditMemo(Command)
	OpenForm("DataProcessor.PrintFormSetup.Form.CMFormSetup" );
EndProcedure

&AtClient
Procedure zoho_productmapping(Command)
	OpenForm("Catalog.zoho_productCodeMap.ListForm" );
EndProcedure

&AtClient
Procedure PeriodClosingByModuleOnChange(Item)
	If ConstantsSet.PeriodClosingByModule Then
		Items.ClosingDateByModule.Visible = True;
		Items.FillClosingDate.Visible = True;
	Else
		Items.ClosingDateByModule.Visible = False;
		Items.FillClosingDate.Visible = False;
	EndIf;
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	RecordSet = InformationRegisters.PeriodClosingByModule.CreateRecordSet();
	For Each ClosingDatePerDocument In ClosingDateByModule Do
		NewRecord = RecordSet.Add();
		NewRecord.Document = ClosingDatePerDocument.DocumentName;
		NewRecord.PeriodClosingDate = ClosingDatePerDocument.ClosingDate;
	EndDo;
	RecordSet.Write = True;
	RecordSet.Write(True);
EndProcedure

&AtClient
Procedure OpenCashSale(Command)
	OpenForm("DataProcessor.PrintFormSetup.Form.CSFormSetup" );
EndProcedure

&AtClient
Procedure FillClosingDate(Command)
	For Each ClosingDatePerModule In ClosingDateByModule Do
		ClosingDatePerModule.ClosingDate = ConstantsSet.PeriodClosingDate;
	EndDo;
EndProcedure

&AtClient
Procedure SalesTaxEngineOnChange(Item)
	ConstantsSet.AvataxEnabled = ?(SalesTaxEngine = 1, TRUE, FALSE);
	If SalesTaxEngine = 1 Then
		Items.SalesTaxBySources.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
		Items.ByAvaTaxPage.Visible = True;
		If NOT ValueIsFilled(ConstantsSet.AvataxServiceURL) Then
			If Modified Then
				ConstantsSet.AvataxServiceURL = "https://avatax.avalara.net/";
			Else
				ConstantsSet.AvataxServiceURL = "https://avatax.avalara.net/";
				Modified = False;
			EndIf;
		EndIf;
	ElsIf SalesTaxEngine = 2 Then
		Items.SalesTaxBySources.PagesRepresentation = FormPagesRepresentation.None;
		Items.ByAvaTaxPage.Visible = False;
		Items.SalesTaxBySources.CurrentPage = Items.ByAccountingSuitePage;
	EndIf;
EndProcedure

&AtClient
Procedure AvataxTestConnection(Command)
	
	//Testing can be done after the modifications are written
	//If ThisForm.Modified Then
	//	Notify = New NotifyDescription("TestConnectionAfterWrite", ThisForm); 
	//	ShowQueryBox(Notify, "Data has been changed. To proceed you need to save changes. Save?", QuestionDialogMode.OKCancel);
	//Else
		AvataxTestConnectionAtClient();
	//EndIf;		
	
EndProcedure
	
//&AtClient
//Procedure TestConnectionAfterWrite(Result, Parameters) Export
//	
//	If Result <> DialogReturnCode.OK Then
//		return;
//	EndIf;
//	If Write() Then
//		AvataxTestConnectionAtClient();
//	EndIf;
//	
//EndProcedure

&AtClient
Procedure AvataxTestConnectionAtClient()
	
	DecodedResult = AvataxTestConnectionAtServer();
	If DecodedResult.Successful Then
		CommonUseClient.ShowCustomMessageBox(ThisForm, "AvaTax connection test", "Connection tested successfully!", PredefinedValue("Enum.MessageStatus.Information"));
	Else
		CommonUseClient.ShowCustomMessageBox(ThisForm, "AvaTax connection test", "Configuration validation failed! " + DecodedResult.ErrorMessage, PredefinedValue("Enum.MessageStatus.Warning"));
	EndIf;
	
EndProcedure

&AtServer
Function AvataxTestConnectionAtServer()
	
	// Set request parameters.
	RequestParameters = New Structure;
	RequestParameters.Insert("saleamount", 10);
	
	DecodedResultBody = AvaTaxServer.SendRequestToAvalara(Enums.AvalaraRequestTypes.ConnectionTest, RequestParameters, Undefined, New Structure("AvataxServiceURL, AvataxAuthorizationString", ConstantsSet.AvataxServiceURL, ConstantsSet.AvataxAuthorizationString));
	return DecodedResultBody;
	
EndFunction

&AtClient
Procedure AvataxAdminConsoleClick(Item)
	GotoURL(Item.Title);
EndProcedure

&AtClient
Procedure AvataxLicenseKeyOnChange(Item)
	GenerateAvataxAuthorizationString();
EndProcedure

&AtClient
Procedure AvataxAccountNumberOnChange(Item)
	GenerateAvataxAuthorizationString();
EndProcedure

&AtServer
Procedure GenerateAvataxAuthorizationString()
	TextDoc = New TextDocument();
	TextDoc.SetText(TrimAll(ConstantsSet.AvataxAccountNumber) + ":" + TrimAll(ConstantsSet.AvataxLicenseKey));
	TempFN = GetTempFileName(".txt");
	TextDoc.Write(TempFN, TextEncoding.UTF8);
	Binary = New BinaryData(TempFN);
	// Convert binary data to Base64 string.
	Base64 = Base64String(Binary);
	Base64 = Right(Base64, StrLen(Base64)-4);
	
	ConstantsSet.AvataxAuthorizationString = "Basic " + Base64;
	
	DeleteFiles(TempFN);               
EndProcedure

&AtClient
Procedure QtyPrecisionOnChange(Item)
	
	QtyPrecision = GetConstant("QtyPrecision");
	
	If ConstantsSet.QtyPrecision < QtyPrecision Then
		
		ConstantsSet.QtyPrecision = QtyPrecision;
		
		Message = New UserMessage();
		Message.Text = NStr("en = 'The new value of ""Quantity field decimals"" must be greater than or equal to the current value!'");
		Message.Field = "ConstantsSet.QtyPrecision";
		Message.Message();
		
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

&AtClient
Procedure UsePricePrecisionOnChange(Item)
		
	ConstantsSet.PricePrecision = 2;	
	
	Message(NStr("en = 'After enabling the ""Use price precision"" feature can not be disabled!'"), MessageStatus.Important);
	
	SetEnabledPricePrecision();

EndProcedure

&AtClient
Procedure SetEnabledPricePrecision()
	
	If ConstantsSet.UsePricePrecision Then
		Items.PricePrecision.Visible = True;
	Else
		Items.PricePrecision.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure PricePrecisionOnChange(Item)
	
	PricePrecision = GetConstant("PricePrecision");
	
	If ConstantsSet.PricePrecision < PricePrecision Then
		
		ConstantsSet.PricePrecision = PricePrecision;
		
		Message = New UserMessage();
		Message.Text = NStr("en = 'The new value of ""Price field decimals"" must be greater than or equal to the current value!'");
		Message.Field = "ConstantsSet.PricePrecision";
		Message.Message();
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GetConstant(ConstantName)
	Return Constants[ConstantName].Get();
EndFunction

&AtClient
Procedure zoho_pricebookmapping(Command)
	OpenForm("Catalog.zoho_pricebookCodeMap.ListForm" );
EndProcedure


&AtClient
Procedure zoho_accountmapping(Command)
	OpenForm("Catalog.zoho_accountCodeMap.ListForm" );	
EndProcedure


&AtClient
Procedure zoho_contactmapping(Command)
	OpenForm("Catalog.zoho_contactCodeMap.ListForm" );	
EndProcedure


&AtClient
Procedure OnClose()
	//DetachIdleHandler("UpdateStripeFields");
EndProcedure


&AtClient
Procedure zoho_quotemapping(Command)
	OpenForm("Catalog.zoho_QuoteCodeMap.ListForm" );
EndProcedure


&AtClient
Procedure zoho_salesordermapping(Command)
	OpenForm("Catalog.zoho_SOCodeMap.ListForm" );
EndProcedure

&AtClient
Procedure EnhancedInventoryShippingOnChange(Item)
	
	Message(NStr("en = 'After enabling the Enhanced Inventory Shipping feature can not be disabled!'"), MessageStatus.Important);
	
EndProcedure

&AtClient
Procedure EnhancedInventoryReceivingOnChange(Item)
	
	Message(NStr("en = 'After enabling the Enhanced Inventory Receiving feature can not be disabled!'"), MessageStatus.Important);
	
	SetEnabledOCLAccount();
	
EndProcedure

&AtClient
Procedure SetEnabledOCLAccount()
	
	If ConstantsSet.EnhancedInventoryReceiving Then
		Items.OCLAccount.Visible = True;
	Else
		Items.OCLAccount.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure zoho_invoicemapping(Command)
	OpenForm("Catalog.zoho_SICodeMap.ListForm" );
EndProcedure

   
&AtServer
Function SubscribeVersion()
	   Return Constants.VersionNumber.Get();
EndFunction
   


&AtClient
Procedure SetCompactUIMode(Command)
	Message("Restart the application for the change to take effect");
	SetCompactModeAtServer();
EndProcedure

&AtServer
Procedure SetCompactModeAtServer()
	
		UIMode = ClientApplicationFormScaleVariant.Compact; 
		User = InfobaseUsers.CurrentUser();
	    
	    If Not User = Undefined Then
	        
	        Setting = SystemSettingsStorage.Load("Common/ClientSettings", "",, User.Name);
			
			If Not TypeOf(Setting) = Type("ClientSettings") Then
	            Setting = New ClientSettings;
	        EndIf;
	        
	        Setting.ClientApplicationFormScaleVariant = UIMode;
	        SystemSettingsStorage.Save("Common/ClientSettings", "", Setting,, User.Name);
	        
	    EndIf;
	
EndProcedure

&AtClient
Procedure SetStandardUIMode(Command)
	Message("Restart the application for the change to take effect");
	SetStandardModeAtServer();
EndProcedure

&AtServer
Procedure SetStandardModeAtServer()
	
		UIMode = ClientApplicationFormScaleVariant.Normal; 
		User = InfobaseUsers.CurrentUser();
	    
	    If Not User = Undefined Then
	        
	        Setting = SystemSettingsStorage.Load("Common/ClientSettings", "",, User.Name);
			
			If Not TypeOf(Setting) = Type("ClientSettings") Then
	            Setting = New ClientSettings;
	        EndIf;
	        
	        Setting.ClientApplicationFormScaleVariant = UIMode;
	        SystemSettingsStorage.Save("Common/ClientSettings", "", Setting,, User.Name);
	        
	    EndIf;
	
EndProcedure

&AtClient
Procedure CFO_ProcessingMonthOnChange(Item)
	ConstantsSet.CFO_ProcessingMonth = EndOfMonth(ConstantsSet.CFO_ProcessingMonth);	
EndProcedure


&AtClient
Procedure DataImport(Command)
	OpenForm("DataProcessor.DataImport.Form.Form");
EndProcedure

