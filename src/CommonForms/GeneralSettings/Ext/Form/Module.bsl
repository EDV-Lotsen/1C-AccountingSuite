
&AtClient
Procedure MultiLocationOnChange(Item)
	
	Message("After enabling the multi-location feature can not be disabled.");
	
EndProcedure

&AtClient
Procedure MultiCurrencyOnChange(Item)
	
	Message("After enabling the multi-currency feature can not be disabled.");
	
EndProcedure

&AtClient
Procedure UseSOPrepaymentOnChange(Item)
	
	If ConstantsSet.UseSOPrepayment And (Not EachCurrencyHasPrepaymentAR()) Then
		
		ConstantsSet.UseSOPrepayment = False;
		
		Title            = NStr("en = 'Information'");
		Status           = PredefinedValue("Enum.MessageStatus.Information");
		Link             = New FormattedString(NStr("en = 'indicate a default ""Customer Prepayments"" for each currency'"),,,,"e1cib/list/Catalog.Currencies");
		FormattedMessage = New FormattedString(NStr("en = 'In order to use the Sales Order Pre-payment feature you must
		                                                 |'"), Link, NStr("en = ' that is used in AccountingSuite.'"));
		
		Params = New Structure("Title, FormattedMessage, MessageStatus", Title, FormattedMessage, Status);
		OpenForm("CommonForm.MessageBox", Params, ThisObject,,,,, FormWindowOpeningMode.LockWholeInterface); 
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function EachCurrencyHasPrepaymentAR()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Currencies.Ref
		|FROM
		|	Catalog.Currencies AS Currencies
		|WHERE
		|	Currencies.DefaultPrepaymentAR = VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)";
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("ActiveTabs") Then
		ThisForm.Items.Common.CurrentPage = ThisForm.Items[Parameters.ActiveTabs];
		Message(Parameters.Message);
	EndIf;
	
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
	
	If Constants.MultiCurrency.Get() Then
		Items.MultiCurrency.ReadOnly = True;
	EndIf;
	
	If Constants.MultiLocation.Get() Then
		Items.MultiLocation.ReadOnly = True;
	EndIf;
	
	If Constants.EnableAssembly.Get() Then
		Items.EnableAssembly.ReadOnly = True;
	EndIf;
	
	If Constants.EnableLots.Get() Then
		Items.EnableLots.ReadOnly = True;
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
		Items.SalesTaxDefaults.Enabled = True;
	Else
		Items.SalesTaxDefaults.Enabled = False;
	EndIf;
	
	DisplayDataImport = True;
	Items.DataImportv2.Visible = DisplayDataImport;
	Items.Renumbering.Visible  = DisplayDataImport;
	
	Items.ItemActivityReport.Visible = False;
	
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
Procedure CommonFileStorage(Command)
	FormAttribute = New Structure;
	FormAttribute.Insert("FormOwner",  "Commom Values");
	
	OpenForm("InformationRegister.FileStorage.Form.ListForm", 
	FormAttribute, 
	ThisForm);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
 
	 If SettingAccessCheck() = false Then

	    Items.Common.ChildItems.Logo.ChildItems.UploadLogo.Enabled = false;
		Items.PeriodClosingDate.ReadOnly = True;
		Items.PeriodClosingOption.ReadOnly = True;
		Items.PeriodClosingPassword.ReadOnly = True;
		Items.PeriodClosingPasswordConfirm.ReadOnly = True;
		Items.PeriodClosingByModule.ReadOnly = True;
		Items.ClosingDateByModule.ReadOnly = True;
		
		Items.CompanyContact.ChildItems.Group1.ChildItems.Cell.ReadOnly = True;
		Items.CompanyContact.ChildItems.Group1.ChildItems.Fax.ReadOnly = True;
		Items.CompanyContact.ChildItems.Group1.ChildItems.FederalTaxID.ReadOnly = True;
		Items.GeneralSettings.ReadOnly = True;
		Items.PostingAccounts.ReadOnly = True;
		Message("You are viewing settings with limited rights(Non-Admin).");

	 Else
		Items.Common.ChildItems.Logo.ChildItems.UploadLogo.Enabled = true;

	Endif;
	
	SetEnabledPricePrecision();
	SetEnabledOCLAccount();
	
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
	
	If ConstantsSet.SalesTaxCharging Then 
		
		If ConstantsSet.TaxPayableAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
		
			Cancel = True;
			
			Message = New UserMessage();
			Message.Text = NStr("en = 'Field ""Tax payable"" is empty'");
			Message.Field = "ConstantsSet.TaxPayableAccount";
			Message.DataPath = "ConstantsSet";
			Message.SetData(ConstantsSet);
			Message.Message();
			
		EndIf;
		
		If ConstantsSet.SalesTaxDefault = Catalogs.SalesTaxRates.EmptyRef() Then
		
			Cancel = True;
			
			Message = New UserMessage();
			Message.Text = NStr("en = 'Field ""Default sales tax"" is empty'");
			Message.Field = "ConstantsSet.SalesTaxDefault";
			Message.DataPath = "ConstantsSet";
			Message.SetData(ConstantsSet);
			Message.Message();
			
		EndIf;
		
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
	
EndProcedure

&AtClient
Procedure ChargingSalesTaxOnChange(Item)
	
	ConstantsSet.SalesTaxCharging = ?(ChargingSalesTax = 1, True, False);
	If ConstantsSet.SalesTaxCharging Then
		Items.SalesTaxDefaults.Enabled = True;
		ConstantsSet.SalesTaxMarkNewCustomersTaxable = True;
		ConstantsSet.SalesTaxMarkNewProductsTaxable  = True;
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
Procedure SalesPeople(Command)
	OpenForm("Catalog.SalesPeople.ListForm", , , , , );
EndProcedure

&AtClient
Procedure PriceLevels(Command)
	OpenForm("Catalog.PriceLevels.ListForm", , , , , );
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
Procedure OpenStatement(Command)
	
	OpenSettingsPrintedForm(PredefinedValue("Enum.PrintedForms.StatementMainForm"));	
	
EndProcedure

&AtClient
Procedure OpenAssembly(Command)
	
	OpenSettingsPrintedForm(PredefinedValue("Enum.PrintedForms.AssemblyMainForm"));	
	
EndProcedure

&AtClient
Procedure OpenSettingsPrintedForm(NameOfPrintedForm)
	
	If PrintFormFunctions.GetSettingsPrintedForm(NameOfPrintedForm).SettingIsExists Then
		
		KeyOfRecord = New Structure("PrintedForm", NameOfPrintedForm);
		
		Array = New Array();
		Array.Add(KeyOfRecord);
		
		InformationRegisterRecordKey = New(Type("InformationRegisterRecordKey.SettingsPrintedForms"), Array);
		
		ParametersOfForm = New Structure("Key", InformationRegisterRecordKey); 
		OpenForm("InformationRegister.SettingsPrintedForms.RecordForm", ParametersOfForm);
		
	Else
		
		ParametersOfForm = New Structure("PrintedForm", NameOfPrintedForm); 
		OpenForm("InformationRegister.SettingsPrintedForms.RecordForm", ParametersOfForm);
		
	EndIf;
	
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
Procedure EnhancedInventoryShippingOnChange(Item)
	
	Message(NStr("en = 'After enabling the Shipment feature can not be disabled!'"), MessageStatus.Important);
	
EndProcedure

&AtClient
Procedure EnhancedInventoryReceivingOnChange(Item)
	
	Message(NStr("en = 'After enabling the Item Receipt feature can not be disabled!'"), MessageStatus.Important);
	
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

&AtServer
Function GetEmail()
	EmailStr = SessionParameters.ACSUser;
	
	InputParameters = New Structure();
	InputParameters.Insert("email", EmailStr);
	Return InternetConnectionClientServer.EncodeQueryData(InputParameters);
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
Procedure DataImportv2(Command)
	OpenForm("DataProcessor.DataImportV20.Form.Form");
EndProcedure

&AtClient
Procedure EnableAssemblyOnChange(Item)
	Message(NStr("en = 'After enabling the Assembly feature can not be disabled!'"), MessageStatus.Important);
EndProcedure

&AtClient
Procedure EnableLotsOnChange(Item)
	Message(NStr("en = 'After enabling the Lots and Serial Numbers feature can not be disabled!'"), MessageStatus.Important);
EndProcedure

&AtClient
Procedure Renumbering(Command)
	OpenForm("DataProcessor.RenumberingUtility.Form.Form");
EndProcedure

&AtClient
Procedure Wizard(Command)
	OpenForm("DataProcessor.Wizard.Form.Form");
EndProcedure

&AtClient
Procedure ItemActivityReport(Command)
	OpenForm("Report.ItemActivityReport.Form");
EndProcedure
