////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
// Selects cash receipts and cash sales to be deposited and fills in the document's
// line items.
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Ref.IsEmpty() Then
		FirstNumber = Object.Number;
	EndIf;
	
	If Parameters.Property("Company") Then
		
		NewLine = Object.Accounts.Add();
		NewLine.Company = Parameters.Company; 	
		
	EndIf;
	
	If Object.BankAccount.IsEmpty() Then
		Object.BankAccount = Constants.BankAccount.Get();
	Else
	EndIf; 
		
	If Object.Ref.IsEmpty() Then
			
		RefreshInvoicesAtServer();
		If Object.LineItems.Count() = 0 Then
			Items.Group2.CurrentPage = Items.GLAccounts;
		EndIf;
		
	Else
		
		UpdateTabTitles();
		If Object.LineItems.Count() = 0 And Object.Accounts.Count() > 0 Then
			Items.Group2.CurrentPage = Items.GLAccounts;
		EndIf;
		
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)		
	
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;

	//If Object.Ref.IsEmpty() Then
	//
	//	MatchVal = Increment(Constants.DepositLastNumber.Get());
	//	If Object.Number = MatchVal Then
	//		Constants.DepositLastNumber.Set(MatchVal);
	//	Else
	//		If Increment(Object.Number) = "" Then
	//		Else
	//			If StrLen(Increment(Object.Number)) > 20 Then
	//				 Constants.DepositLastNumber.Set("");
	//			Else
	//				Constants.DepositLastNumber.Set(Increment(Object.Number));
	//			Endif;

	//		Endif;
	//	Endif;
	//Endif;
	//
	//If Object.Number = "" Then
	//	Message("Deposit Number is empty");
	//	Cancel = True;
	//Endif;

EndProcedure

&AtClient
// Writes deposit data to the originating documents
//
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
	
	// preventing posting if already included in a bank rec
	If ReconciledDocumentsServerCall.DocumentRequiresExcludingFromBankReconciliation(Object, WriteParameters.WriteMode) Then
		Cancel = True;
		CommonUseClient.ShowCustomMessageBox(ThisForm, "Bank reconciliation", "The transaction you are editing has been reconciled. Saving your changes could put you out of balance the next time you try to reconcile. 
		|To modify it you should exclude it from the Bank rec. document.", PredefinedValue("Enum.MessageStatus.Warning"));
	EndIf;    
	
	//If Object.LineItems.Count() = 0 Then
	//	Message("Deposit can not have empty lines. The system automatically shows undeposited documents in the line items");
	//	Cancel = True;
	//	Return;
	//EndIf;	
	//
	//For Each DocumentLine in Object.LineItems Do
	//	If DocumentLine.Document = Undefined Then
	//		Message("Deposit can not have empty lines. The system automatically shows undeposited documents in the line items");
	//		Cancel = True;
	//		Return;
	//	EndIf;
	//EndDo;
							
	// deletes from this document lines that were not marked as deposited
	
	//Checked = False;
	//For Each DocLine In Object.LineItems Do
	//	
	//	If DocLine.Payment = True Then
	//		Checked = True;
	//	EndIf;
	//EndDo;
	//
	//If Checked = False  Then
	//	Message("Cannot post with no line items.");
	//	Cancel = True;
	//	Return;
	//EndIf;

	
	NumberOfLines = Object.LineItems.Count() - 1;
	
	While NumberOfLines >=0 Do
		
		If Object.LineItems[NumberOfLines].Payment = False Then
			Object.LineItems.Delete(NumberOfLines);
		Else
		EndIf;
		
		NumberOfLines = NumberOfLines - 1;
		
	EndDo;
	
	CheckARandAPAccounts(Cancel);
	
	If Not CompaniesFilledCorrectly() Then
		Message(NStr("en = 'Document cannot indicate a company in a line with an account that is NOT P&L, A/R or A/P.'"));
		Cancel = True;
		Return;		
	EndIf;
	
	For Each CurrenRow In Object.Accounts Do
		
		If ValueIsFilled(CurrenRow.Company)
			And CommonUse.GetAttributeValue(CurrenRow.Company, "Vendor1099")
			And (Not ValueIsFilled(CurrenRow.PaymentMethod))
			Then
			
			CancelEdit = True;
			UM = New UserMessage();
			UM.SetData(Object);
			UM.Field = "Object.Accounts[" + String(CurrenRow.LineNumber - 1) + "]." + "PaymentMethod";
			UM.Text  = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Please, choose payment method for row # %1.'"), CurrenRow.LineNumber);
			UM.Message();
			
			Cancel = True;
			Return;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("AfterOpen", 0.1, True);
	
EndProcedure

&AtClient
Procedure AfterOpen()
	
	ThisForm.Activate();
	
	If ThisForm.IsInputAvailable() Then
		///////////////////////////////////////////////
		DetachIdleHandler("AfterOpen");
		
		If  Object.Ref.IsEmpty() Then
			AccountsOnChange(Items.Accounts);	
		EndIf;	
		///////////////////////////////////////////////
	Else
		AttachIdleHandler("AfterOpen", 0.1, True);
	EndIf;		
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

&AtClient
Procedure LineItemsBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	Return;
EndProcedure

&AtClient
// Calculates document total
// 
Procedure LineItemsPaymentOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	
	If TabularPartRow.Payment Then
		Object.DocumentTotal = Object.DocumentTotal + TabularPartRow.DocumentTotal;
		Object.DocumentTotalRC = Object.DocumentTotalRC + TabularPartRow.DocumentTotalRC;
		
		Object.TotalDeposits = Object.TotalDeposits + TabularPartRow.DocumentTotal;
		Object.TotalDepositsRC = Object.TotalDepositsRC + TabularPartRow.DocumentTotalRC;
	EndIf;

    If TabularPartRow.Payment = False Then
		Object.DocumentTotal = Object.DocumentTotal - TabularPartRow.DocumentTotal;
		Object.DocumentTotalRC = Object.DocumentTotalRC - TabularPartRow.DocumentTotalRC;
		
		Object.TotalDeposits = Object.TotalDeposits - TabularPartRow.DocumentTotal;
		Object.TotalDepositsRC = Object.TotalDepositsRC - TabularPartRow.DocumentTotalRC;
	EndIf;

EndProcedure

&AtClient
Procedure LineItemsBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	Cancel = True;
	Return;
EndProcedure

&AtClient
Procedure AccountsOnChange(Item)
	
	Object.DocumentTotal = Object.TotalDeposits + Object.Accounts.Total("Amount");
	AccountCurrency = CommonUse.GetAttributeValue(Object.BankAccount, "Currency");
	ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, AccountCurrency);	
	Object.DocumentTotalRC = Object.TotalDepositsRC + Object.Accounts.Total("Amount")*ExchangeRate;
	
EndProcedure

&AtClient
Procedure AccountsAmountOnChange(Item)
	Object.DocumentTotal = Object.TotalDeposits + Object.Accounts.Total("Amount");
	AccountCurrency = CommonUse.GetAttributeValue(Object.BankAccount, "Currency");
	ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, AccountCurrency);	
	Object.DocumentTotalRC = Object.TotalDepositsRC + Object.Accounts.Total("Amount")*ExchangeRate;
EndProcedure

&AtClient
Procedure AccountsOnEditEnd(Item, NewRow, CancelEdit)
	
	CurrentData = Items.Accounts.CurrentData;
	If CurrentData <> Undefined
		And ValueIsFilled(CurrentData.Company)
		And CommonUse.GetAttributeValue(CurrentData.Company, "Vendor1099")
		And (Not ValueIsFilled(CurrentData.PaymentMethod))
		Then
		
		CancelEdit = True;
		UM = New UserMessage();
		UM.SetData(Object);
		UM.Field = "Object.Accounts[" + String(CurrentData.LineNumber - 1) + "]." + "PaymentMethod";
		UM.Text  = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Please, choose payment method for row # %1.'"), CurrentData.LineNumber);
		UM.Message();
		
	EndIf;
	
	UpdateTabTitles();
	
EndProcedure

&AtClient
Procedure AccountsAfterDeleteRow(Item)
	
	UpdateTabTitles();
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure RefreshInvoices(Command)
	RefreshInvoicesAtServer();
EndProcedure

&AtClient
Procedure AuditLogRecord(Command)
	
	FormParameters = New Structure();	
	FltrParameters = New Structure();
	FltrParameters.Insert("DocUUID", String(Object.Ref.UUID()));
	FormParameters.Insert("Filter", FltrParameters);
	OpenForm("CommonForm.AuditLogList",FormParameters, Object.Ref);

EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

&AtServer
Function Increment(NumberToInc)
	
	//Last = Constants.SalesInvoiceLastNumber.Get();
	Last = NumberToInc;
	//Last = "AAAAA";
	LastCount = StrLen(Last);
	Digits = new Array();
	For i = 1 to LastCount Do	
		Digits.Add(Mid(Last,i,1));

	EndDo;
	
	NumPos = 9999;
	lengthcount = 0;
	firstnum = false;
	j = 0;
	While j < LastCount Do
		If NumCheck(Digits[LastCount - 1 - j]) Then
			if firstnum = false then //first number encountered, remember position
				firstnum = true;
				NumPos = LastCount - 1 - j;
				lengthcount = lengthcount + 1;
			Else
				If firstnum = true Then
					If NumCheck(Digits[LastCount - j]) Then //if the previous char is a number
						lengthcount = lengthcount + 1;  //next numbers, add to length.
					Else
						break;
					Endif;
				Endif;
			Endif;
						
		Endif;
		j = j + 1;
	EndDo;
	
	NewString = "";
	
	If lengthcount > 0 Then //if there are numbers in the string
		changenumber = Mid(Last,(NumPos - lengthcount + 2),lengthcount);
		NumVal = Number(changenumber);
		NumVal = NumVal + 1;
		StringVal = String(NumVal);
		StringVal = StrReplace(StringVal,",","");
		
		StringValLen = StrLen(StringVal);
		changenumberlen = StrLen(changenumber);
		LeadingZeros = Left(changenumber,(changenumberlen - StringValLen));

		LeftSide = Left(Last,(NumPos - lengthcount + 1));
		RightSide = Right(Last,(LastCount - NumPos - 1));
		NewString = LeftSide + LeadingZeros + StringVal + RightSide; //left side + incremented number + right side
		
	Endif;
	
	Next = NewString;

	return NewString;
	
EndFunction

&AtServer
Function NumCheck(CheckValue)
	 
	For i = 0 to  9 Do
		If CheckValue = String(i) Then
			Return True;
		Endif;
	EndDo;
		
	Return False;
		
EndFunction

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
Procedure RefreshInvoicesAtServer()
	
	Request = New Query();
	Request.Text = "SELECT
	               |	DocumentLines.Document,
	               |	DocumentLines.Payment
	               |INTO DocumentLines
	               |FROM
	               |	&DocumentLines AS DocumentLines
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	UndepositedDocumentsBalance.Document,
	               |	UndepositedDocumentsBalance.Document.Currency,
	               |	UndepositedDocumentsBalance.Document.Date,
	               |	UndepositedDocumentsBalance.Document.Company AS Customer,
	               |	UndepositedDocumentsBalance.AmountBalance AS DocumentTotal,
	               |	UndepositedDocumentsBalance.AmountRCBalance AS DocumentTotalRC,
	               |	FALSE AS Payment
	               |INTO AvailableDocuments
	               |FROM
	               |	AccumulationRegister.UndepositedDocuments.Balance AS UndepositedDocumentsBalance
	               |WHERE
	               |	UndepositedDocumentsBalance.AmountBalance > 0
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	UndepositedDocuments.Document,
	               |	UndepositedDocuments.Document.Currency,
	               |	UndepositedDocuments.Document.Date,
	               |	UndepositedDocuments.Document.Company,
	               |	SUM(UndepositedDocuments.Amount),
	               |	SUM(UndepositedDocuments.AmountRC),
	               |	MAX(TRUE)
	               |FROM
	               |	AccumulationRegister.UndepositedDocuments AS UndepositedDocuments
	               |WHERE
	               |	UndepositedDocuments.Recorder = &ThisDocument
	               |
	               |GROUP BY
	               |	UndepositedDocuments.Document,
	               |	UndepositedDocuments.Document.Currency,
	               |	UndepositedDocuments.Document.Date,
	               |	UndepositedDocuments.Document.Company
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	AvailableDocuments.Document,
	               |	AvailableDocuments.DocumentCurrency As Currency,
	               |	AvailableDocuments.DocumentDate AS DocumentDate,
	               |	AvailableDocuments.Customer,
	               |	AvailableDocuments.DocumentTotal,
	               |	AvailableDocuments.DocumentTotalRC,
	               |	ISNULL(DocumentLines.Payment, AvailableDocuments.Payment) AS Payment
	               |FROM
	               |	AvailableDocuments AS AvailableDocuments
	               |		LEFT JOIN DocumentLines AS DocumentLines
	               |		ON AvailableDocuments.Document = DocumentLines.Document
				   |WHERE AvailableDocuments.DocumentCurrency = &BankCurrency	
	               |
	               |ORDER BY
	               |	DocumentDate";
				   
	Request.SetParameter("DocumentLines", Object.LineItems.Unload(, "Document, Payment"));
	Request.SetParameter("ThisDocument", Object.Ref);
	Request.SetParameter("BankCurrency", Object.BankAccount.Currency);
	Object.LineItems.Load(Request.Execute().Unload());
	UpdateTabTitles();
		
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If FirstNumber <> "" Then
		
		Numerator = Catalogs.DocumentNumbering.Deposit.GetObject();
		NextNumber = GeneralFunctions.Increment(Numerator.Number);
		If FirstNumber = NextNumber And NextNumber = Object.Number Then
			Numerator.Number = FirstNumber;
			Numerator.Write();
		EndIf;
		
		FirstNumber = "";
	EndIf;
	UpdateTabTitles();
	
EndProcedure

&AtClient
Procedure AccountsCompanyOnChange(Item)
	
	TableSectionRow = New Structure("LineNumber, Company, Account, Amount");
	FillPropertyValues(TableSectionRow, Items.Accounts.CurrentData);
	AccountsCompanyOnChangeAtServer(TableSectionRow);
	FillPropertyValues(Items.Accounts.CurrentData, TableSectionRow);
	
EndProcedure

&AtServer
Procedure AccountsCompanyOnChangeAtServer(TableSectionRow)
	
	RowCompany = TableSectionRow.Company;
	RowAccount = TableSectionRow.Account;
	RowAmount = TableSectionRow.Amount;
		
	If Object.BankAccount.AccountType = Enums.AccountTypes.OtherCurrentLiability and Object.BankAccount.CreditCard Then 
		If (RowCompany.DefaultCurrency <> Constants.DefaultCurrency.Get()) and (Not RowCompany.DefaultCurrency.IsEmpty()) Then 
			CommonUseClientServer.MessageToUser("Company currency must be equal to default currency when using Credit card account",,"Object.Accounts["+(TableSectionRow.LineNumber-1)+"].Company");
			TableSectionRow.Company = Catalogs.Companies.EmptyRef();
		EndIf;	
	ElsIf RowCompany.DefaultCurrency <> Object.BankAccount.Currency Then 
		CommonUseClientServer.MessageToUser("Company currency must be the same as the currency of Bank account",,"Object.Accounts["+(TableSectionRow.LineNumber-1)+"].Company");
		TableSectionRow.Company = Catalogs.Companies.EmptyRef();
		Return;
	EndIf;	
	
	If ValueIsFilled(RowCompany.IncomeAccount)Then 
		TableSectionRow.Account = RowCompany.IncomeAccount;
	EndIf;	
	
EndProcedure

&AtServer
Procedure UpdateTabTitles()
	
	ReceiptsCount  	= Object.LineItems.Count();
	AccountsCount 	= Object.Accounts.Count();
	Items.Documents.Title 	= StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Receipts [%1]'"),    ReceiptsCount);
	Items.GLAccounts.Title  = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'G/L Accounts [%1]'"), AccountsCount);	
	
EndProcedure

&AtServer
Function CompaniesFilledCorrectly()
	
	FilledCorrectly = True;
	
	For Each CurrentRow In Object.Accounts Do
		
		If ValueIsFilled(CurrentRow.Company)
			
			AND CurrentRow.Account.AccountType <> Enums.AccountTypes.AccountsPayable 
			AND CurrentRow.Account.AccountType <> Enums.AccountTypes.AccountsReceivable
			
			AND CurrentRow.Account.AccountType <> Enums.AccountTypes.Income
			AND CurrentRow.Account.AccountType <> Enums.AccountTypes.CostOfSales
			AND CurrentRow.Account.AccountType <> Enums.AccountTypes.Expense
			AND CurrentRow.Account.AccountType <> Enums.AccountTypes.OtherIncome
			AND CurrentRow.Account.AccountType <> Enums.AccountTypes.OtherExpense
			AND CurrentRow.Account.AccountType <> Enums.AccountTypes.IncomeTaxExpense Then
			
			FilledCorrectly = False;
			
		EndIf;
		
	EndDo;
	
	Return FilledCorrectly;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region AR_AP_PROCESSING

&AtServer
Procedure CheckARandAPAccounts(Cancel = False)
	
	ARAPCounter = 0;
	RowCounter = 0;
	
	For Each AccountRow In Object.Accounts Do 
		
		If AccountRow.Account.AccountType = Enums.AccountTypes.AccountsPayable Then 
			CompanyEmpty = AccountRow.Company.IsEmpty();
			ARAPCounter = ARAPCounter + 1;
			If CompanyEmpty Then 
				CommonUseClientServer.MessageToUser("AP Account is in tabular section. Vendor must be selected.",,"Object.Accounts["+RowCounter+"].Company");
				Cancel = True;
			ElsIf Not AccountRow.Company.Vendor Then 
				CommonUseClientServer.MessageToUser("To select AP account you must select Vendor first.",,"Object.Accounts["+RowCounter+"].Company");
				Cancel = True;
			EndIf;	
		ElsIf AccountRow.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then 	
			CompanyEmpty = AccountRow.Company.IsEmpty();
			ARAPCounter = ARAPCounter + 1;
			If CompanyEmpty Then 
				CommonUseClientServer.MessageToUser("AR Account is in tabular section. Customer must be selected.",,"Object.Accounts["+RowCounter+"].Company");
				Cancel = True;
			ElsIf Not AccountRow.Company.Customer Then 
				CommonUseClientServer.MessageToUser("To select AR account you must select Customer first.",,"Object.Accounts["+RowCounter+"].Company");
				Cancel = True;
			EndIf;	
		EndIf;
		RowCounter = RowCounter +1;
		
	EndDo;	
	
	If ARAPCounter > 1 Then 
		Message("Only one AP or AR Account is allowed in tabular section");
		Cancel = True;
	EndIf;	
		
EndProcedure

&AtClient
Procedure LineItemsAccountOnChange(Item)
	LineItemsAccountOnChangeAtServer(Items.Accounts.CurrentData.Account, Items.Accounts.CurrentData.LineNumber);
EndProcedure

&AtServer
Procedure LineItemsAccountOnChangeAtServer(CurrentAccount, LineNumber)
	
	IsAR = (CurrentAccount.AccountType = Enums.AccountTypes.AccountsReceivable);
	IsAP = (CurrentAccount.AccountType = Enums.AccountTypes.AccountsPayable);
	IsBank = (CurrentAccount.AccountType = Enums.AccountTypes.Bank);
	
	If IsAP or IsAR Or IsBank Then 
		If Object.BankAccount.AccountType = Enums.AccountTypes.OtherCurrentLiability and Object.BankAccount.CreditCard Then 
			If CurrentAccount.Currency <> Constants.DefaultCurrency.Get() Then 
				CommonUseClientServer.MessageToUser("Accounts currency must be equal to default currency when using Credit card account",,"Object.Accounts["+(LineNumber-1)+"].Account");
				CurrentAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef(); 	
			EndIf;	
		ElsIf CurrentAccount.Currency <> Object.BankAccount.Currency Then 
			CommonUseClientServer.MessageToUser("Account currency must be the same as the currency of Bank account",,"Object.Accounts["+(LineNumber-1)+"].Account");
			CurrentAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef(); 	
		EndIf;	
	EndIf;		
	
	If IsAR Or IsAP Then 
		ARAPCounter = 0;
		
		For Index = 0 to (Object.Accounts.Count()-1) Do 
			If Index = (LineNumber-1) Then 
				Continue;	
			EndIf;
			AccountRow = Object.Accounts[Index];
			If AccountRow.Account.AccountType = Enums.AccountTypes.AccountsPayable Then 
				ARAPCounter = ARAPCounter + 1;
			ElsIf AccountRow.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then 	
				ARAPCounter = ARAPCounter + 1;
			EndIf;
		EndDo;	
		
		If ARAPCounter > 0 Then 
			CommonUseClientServer.MessageToUser("Only one AP or AR Account is allowed in tabular section",,"Object.Accounts["+(LineNumber-1)+"].Account");
			Object.Accounts[LineNumber-1].Account = ChartsOfAccounts.ChartOfAccounts.EmptyRef(); 
		ElsIf Object.Accounts[LineNumber-1].Company.IsEmpty() And IsAP Then 
			CommonUseClientServer.MessageToUser("AP Account is in tabular section. Vendor must be selected.",,"Object.Accounts["+(LineNumber-1)+"].Company");
		ElsIf Object.Accounts[LineNumber-1].Company.IsEmpty() And IsAR Then 
			CommonUseClientServer.MessageToUser("AR Account is in tabular section. Customer must be selected.",,"Object.Accounts["+(LineNumber-1)+"].Company");	
		ElsIf (Not Object.Accounts[LineNumber-1].Company.Customer) And IsAR Then 
			CommonUseClientServer.MessageToUser("To select AR account you must select Customer first.",,"Object.Accounts["+(LineNumber-1)+"].Company");
		ElsIf (Not Object.Accounts[LineNumber-1].Company.Vendor) And IsAP Then 
			CommonUseClientServer.MessageToUser("To select AP account you must select Vendor first.",,"Object.Accounts["+(LineNumber-1)+"].Company");
		EndIf;
	Else 
		//ARAPCounter = 0;
		//For Each AccountRow in Object.LineItems Do
		//	If AccountRow.Account.AccountType = Enums.AccountTypes.AccountsPayable Then 
		//		ARAPCounter = ARAPCounter + 1;
		//	ElsIf AccountRow.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then 	
		//		ARAPCounter = ARAPCounter + 1;
		//	EndIf;
		//EndDo;	
	EndIf;	
EndProcedure

&AtClient
Procedure LineItemsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If Field.Name = "LineItemsDocument" Then
		ShowValue(, Items.LineItems.CurrentData.Document);
	ElsIf Field.Name = "LineItemsCustomer" Then
		ShowValue(, Items.LineItems.CurrentData.Customer);
	EndIf; 	
	
EndProcedure

&AtClient
Procedure BankAccountOnChange(Item)
	BankAccountOnChangeAtServer();
EndProcedure

&AtServer
Procedure BankAccountOnChangeAtServer()
	For Each AccountRow in Object.Accounts Do 
		BankAccountCurrency = Object.BankAccount.Currency;
		If GeneralFunctionsReusable.CurrencyUsedAccountType(AccountRow.Account.AccountType) Then 
			If Object.BankAccount.AccountType = Enums.AccountTypes.OtherCurrentLiability and Object.BankAccount.CreditCard Then 
				If AccountRow.Account.Currency <> Constants.DefaultCurrency.Get() Then 
					CommonUseClientServer.MessageToUser("Accounts currency must be equal to default currency when using Credit card account",,"Object.Accounts["+Object.Accounts.IndexOf(AccountRow)+"].Account");
					AccountRow.Account = ChartsOfAccounts.ChartOfAccounts.EmptyRef(); 	
				EndIf;	
			ElsIf AccountRow.Account.Currency <> BankAccountCurrency Then 
				CommonUseClientServer.MessageToUser("Account currency must be the same as the currency of Bank account",,"Object.Accounts["+Object.Accounts.IndexOf(AccountRow)+"].Account");
				AccountRow.Account = ChartsOfAccounts.ChartOfAccounts.EmptyRef(); 	
			EndIf;	
		EndIf;
		
		If Not AccountRow.Company.DefaultCurrency.IsEmpty() Then 
			If Object.BankAccount.AccountType = Enums.AccountTypes.OtherCurrentLiability and Object.BankAccount.CreditCard Then 
				If (AccountRow.Company.DefaultCurrency <> Constants.DefaultCurrency.Get()) Then 
					CommonUseClientServer.MessageToUser("Company currency must be equal to default currency when using Credit card account",,"Object.Accounts["+Object.Accounts.IndexOf(AccountRow)+"].Company");
					AccountRow.Company = Catalogs.Companies.EmptyRef();
				EndIf;	
			ElsIf AccountRow.Company.DefaultCurrency <> BankAccountCurrency Then 
				CommonUseClientServer.MessageToUser("Company currency must be the same as the currency of Bank account",,"Object.Accounts["+Object.Accounts.IndexOf(AccountRow)+"].Company");
				AccountRow.Company = Catalogs.Companies.EmptyRef();
			EndIf;
		EndIf;
	EndDo;
	
	RefreshInvoicesAtServer();
		
	//EndDo;	
EndProcedure

#EndRegion
