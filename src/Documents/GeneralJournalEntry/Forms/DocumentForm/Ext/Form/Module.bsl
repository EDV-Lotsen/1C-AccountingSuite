﻿
Function SetType()
	
	CompaniesPresent = False;
	For Each CurRowLineItems In Object.LineItems Do
		If CurRowLineItems.Company <> Catalogs.Companies.EmptyRef() Then
			CompaniesPresent = True;	
		EndIf;
	EndDo;

	If CompaniesPresent = True Then
		For Each CurRowLineItems In Object.LineItems Do
			If CurRowLineItems.Account.AccountType = Enums.AccountTypes.AccountsPayable Then
				  Object.ARorAP = Enums.GJEntryType.AP;
			ElsIf CurRowLineItems.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
				  Object.ARorAP = Enums.GJEntryType.AR;
			EndIf;
		EndDo;
	EndIf;	
	
EndFunction

&AtClient
// The procedure calculates TotalDr and TotalCr for the transaction, and prevents
// saving an unbalanced transaction.
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

	SetType();

	Object.DueDate = Object.Date;
	
	TotalDr = Object.LineItems.Total("AmountDr");
	TotalCr = Object.LineItems.Total("AmountCr"); 
	
	Object.DocumentTotal = TotalDr;
	Object.DocumentTotalRC = TotalDr * Object.ExchangeRate;	
		
	If TotalDr <> TotalCr Then
		Message = New UserMessage();
		Message.Text = NStr("en='Balance The Transaction'");
		Message.Message();
		Cancel = True;
        Return;
	EndIf;
	
	If checkMixture() = True Then
		Message("Cannot have both A/R and A/P accounts in a single transaction.");
		Cancel = True;
        Return;
	EndIf;
	
	If linkedCorrectly() = 1 Then
		Message("Cannot indicate a company in a line with an account that is NOT P&L, A/R or A/P.");
		Cancel = True;
        Return;
	EndIf;
	
	If linkedCorrectly() = 2 Then
		Message("For Accounts Payable, the company indicated must be a vendor.");
		Cancel = True;
        Return;
	EndIf;

	If linkedCorrectly() = 3 Then
		Message("For Accounts Receivable, the company indicated must be a customer.");
		Cancel = True;
        Return;
	EndIf;

	If linkedCorrectly() = 4 Then
		Message("Lines with an A/P account must have a vendor indicated.");
		Cancel = True;
        Return;
	EndIf;

	If linkedCorrectly() = 5 Then
		Message("Lines with an A/R account must have a customer indicated.");
		Cancel = True;
        Return;
	EndIf;

	
EndProcedure

&AtClient
// LineItemsAmountDrOnChange UI event handler.
// The procedure clears Cr amount in the line if Dr amount is entered. A transaction can only have
// either Dr or Cr amount in one line (but not both).
// 
Procedure LineItemsAmountDrOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.AmountCr = 0;
	
EndProcedure

&AtClient
// LineItemsAmountCrOnChange UI event handler.
// The procedure clears Dr amount in the line if Cr amount is entered. A transaction can only have
// either Dr or Cr amount in one line (but not both).
// 
Procedure LineItemsAmountCrOnChange(Item)
	
	TabularPartRow = Items.LineItems.CurrentData;
	TabularPartRow.AmountDr = 0;
		
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Ref.IsEmpty() Then
		FirstNumber = Object.Number;
	EndIf;
	
	If Parameters.Property("Company") Then
		
		NewLine = Object.LineItems.Add();
		NewLine.Company = Parameters.Company; 	
		
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		Items.ReverseButton.Visible = False;
	Endif;
	
	// checking if Reverse journal entry button was clicked
	If Parameters.Property("ReverseStuff") Then
		PreviousRef = Parameters.ReverseStuff;
		ReverseJournalEntry(PreviousRef);
		Items.ReverseButton.Visible = False;
	EndIf;
	
	//Displays voiding info if entry voids a document (after written)
	Voided();
	
	// If voiding from Check
	If Parameters.Property("CheckRef") Then
		
		PreviousRef = Parameters.CheckRef;
		//PreviousRef = Documents.Check.FindByNumber(PreviousRef);
		
		For Each LineItem In PreviousRef.LineItems Do
			NewEntry = Object.LineItems.Add();
			NewEntry.Account = LineItem.Account;
			NewEntry.AmountCr = LineItem.Amount;
			NewEntry.VoidedEntry = PreviousRef;			
		EndDo;
		
		NewEntry = Object.LineItems.Add();
		NewEntry.Account = PreviousRef.BankAccount;
		NewEntry.AmountDr = PreviousRef.DocumentTotalRC;
		NewEntry.VoidedEntry = PreviousRef;

		Object.Memo = "Voiding entry for " + PreviousRef;
		Object.Date = Parameters.VoidDate;
		Object.VoidingEntry = PreviousRef;

	EndIf;
	
	// If voiding from invoice payment
	If Parameters.Property("InvoicePayRef") Then
		
		PreviousRef = Parameters.InvoicePayRef;
				
		For Each LineItem In PreviousRef.LineItems Do
			
			//A/P or A/R account
			NewEntry = Object.LineItems.Add();
			If TypeOf(LineItem.Document) = Type("DocumentRef.PurchaseInvoice") Then
				NewEntry.Account = LineItem.Document.APAccount;
			ElsIf TypeOf(LineItem.Document) = Type("DocumentRef.SalesReturn") Then
				NewEntry.Account = LineItem.Document.ARAccount;
			EndIf;
			NewEntry.AmountCr    = LineItem.Payment + LineItem.Discount;
			NewEntry.Company     = PreviousRef.Company;
			NewEntry.VoidedEntry = LineItem.Document;
			
			//Bank account
			NewEntry = Object.LineItems.Add();
			NewEntry.Account     = PreviousRef.BankAccount;
			NewEntry.AmountDr    = LineItem.Payment;
			NewEntry.VoidedEntry = LineItem.Document;
			
			//Discount account
			If LineItem.Discount <> 0 Then
				NewEntry = Object.LineItems.Add();
				NewEntry.Account     = Constants.DiscountsReceived.Get();
				NewEntry.AmountDr    = LineItem.Discount;
				NewEntry.VoidedEntry = LineItem.Document;
			EndIf;
			
			//???FXGainLoss???
			//???UNAPPLIED PAYMENTS???
			
		EndDo;
				
		Object.Memo = "Voiding entry for " + PreviousRef;
		Object.Date = Parameters.VoidDate;
		Object.VoidingEntry = PreviousRef;
	EndIf;

	
	If Object.Currency.IsEmpty() Then
		Object.Currency = Constants.DefaultCurrency.Get();
		Object.ExchangeRate = 1;
	Else
	EndIf;
	
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + Object.Currency.Symbol;
		
	ApplyConditionalAppearance();
EndProcedure

&AtServer
Procedure ApplyConditionalAppearance()
	
	CA = ThisForm.ConditionalAppearance; 
 	CA.Items.Clear(); 
	
	//If Class analytics is not applicable for an account then make Class column invisible
	ElementCA = CA.Items.Add();
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("LineItemsClass"); 
 	FieldAppearance.Use = True;
	
	Request = New Query("SELECT ALLOWED
	                    |	ChartOfAccounts.Ref
	                    |FROM
	                    |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                    |WHERE
	                    |	ChartOfAccounts.AccountType IN(&AccountTypes)");
	
	AvailableAccountTypes = New ValueList();
	AvailableAccountTypes.Add(Enums.AccountTypes.Expense);
	AvailableAccountTypes.Add(Enums.AccountTypes.OtherExpense);
	AvailableAccountTypes.Add(Enums.AccountTypes.CostOfSales);
	AvailableAccountTypes.Add(Enums.AccountTypes.IncomeTaxExpense);
	AvailableAccountTypes.Add(Enums.AccountTypes.Income);
	AvailableAccountTypes.Add(Enums.AccountTypes.OtherIncome);
	Request.SetParameter("AccountTypes", AvailableAccountTypes);
	
	ResTab = Request.Execute().Unload();
	AccArray = ResTab.UnloadColumn("Ref");
	AvailableAccounts = New ValueList();
	AvailableAccounts.LoadValues(AccArray);
	
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.LineItems.Account"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotInList; 
	FilterElement.RightValue 		= AvailableAccounts; 
	FilterElement.Use				= True;
	
	ElementCA.Appearance.SetParameterValue("Readonly", True); 
	ElementCA.Appearance.SetParameterValue("BackColor", WebColors.WhiteSmoke); 

EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
    Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(Object.Currency, "Symbol");
	
	For Each Line in Object.LineItems Do 
		LocalAccount = Line.Account;
		If Not CheckCurrencyUsedAccountType(LocalAccount, Object.LineItems.IndexOf(Line)) Then 
			Cancel = True;
		EndIf;	
	EndDo;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;
	
	For Each Line in Object.LineItems Do 
		LocalAccount = Line.Account;
		If Not CheckCurrencyUsedAccountType(LocalAccount, Object.LineItems.IndexOf(Line)) Then 
			Cancel = True;
		EndIf;	
	EndDo;	

EndProcedure

//Closing period
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
Procedure ReverseJournalEntry(Old)
	
	Object.Adjusting = Old.Adjusting;
	
//Date Manipulation to get first day of the next month
	DateString = StringFunctionsClientServer.SplitStringIntoSubstringArray(String(Old.Date)," ");
	Object.Memo = "REVERSE of GJ entry " + Old.Number + " from " + DateString[0];
	SplitDate = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateString[0],"/");
	Month = Number(SplitDate[0]) + 1;
	Year = Number(SplitDate[2]);
					// Check to wrap over the month
	If Month > 12 Then
		Month = 1;
		Year = Year + 1;
	EndIf;
					// make sure month string is of length 2
	If Month < 10 Then
		SMonth = "0" + String(Month);
	Else
		SMonth = String(Month);
	EndIf;
					//Combine strings to get actual date string
	SDay = "01";
	SYear = StringFunctionsClientServer.SplitStringIntoSubstringArray(String(Year),",");
	SDate = SYear[0]+SYear[1] + SMonth + SDay;
	
	Object.Date = Date(SDate);
	
	For Each CurRowLineItems In Old.LineItems Do
		newLineItem = Object.LineItems.Add();
		newLineItem.Account = CurRowLineItems.Account;
		//newLineItem.AccountDescription = CurRowLineItems.AccountDescription;
		newLineItem.AmountDr = CurRowLineItems.AmountCr;
		newLineItem.AmountCr = CurRowLineItems.AmountDr;
		newLineItem.Company = CurRowLineItems.Company;
	EndDo;
	
	Object.Currency = Old.Currency;
	Object.ExchangeRate = Old.ExchangeRate;
	Object.DocumentTotal = Object.LineItems.Total("AmountDR");
	Object.DocumentTotalRC = Object.LineItems.Total("AmountDR") * Object.ExchangeRate;
	
EndProcedure

Function checkMixture()
	
	containsAP = False;
	containsAR = False;
	
	For Each CurRowLineItems In Object.LineItems Do
		
		If CurRowLineItems.Account.AccountType = Enums.AccountTypes.AccountsPayable Then
			containsAP = True;
		EndIf;
		
		If CurRowLineItems.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
			containsAR = True;
		EndIf;
		
	EndDo;
	
	If containsAR = True AND containsAP = True Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function linkedCorrectly()
	
	For Each CurRowLineItems In Object.LineItems Do
		
		If CurRowLineItems.Company <> Catalogs.Companies.EmptyRef() Then
			
			If CurRowLineItems.Account.AccountType <> Enums.AccountTypes.AccountsPayable 
				AND CurRowLineItems.Account.AccountType <> Enums.AccountTypes.AccountsReceivable
				
				AND CurRowLineItems.Account.AccountType <> Enums.AccountTypes.Income
				AND CurRowLineItems.Account.AccountType <> Enums.AccountTypes.CostOfSales
				AND CurRowLineItems.Account.AccountType <> Enums.AccountTypes.Expense
				AND CurRowLineItems.Account.AccountType <> Enums.AccountTypes.OtherIncome
				AND CurRowLineItems.Account.AccountType <> Enums.AccountTypes.OtherExpense
				AND CurRowLineItems.Account.AccountType <> Enums.AccountTypes.IncomeTaxExpense Then
				Return 1; // error - other account with company
			EndIf;
			
			If CurRowLineItems.Account.AccountType = Enums.AccountTypes.AccountsPayable Then
				If CurRowLineItems.Company.Vendor <> True Then
					Return 2; // error - ap with wrong company type
				EndIf;
			EndIf;
				
			If CurRowLineItems.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
				If CurRowLineItems.Company.Customer <> True Then
					Return 3; // error - ar with wrong company type
				EndIf;
			EndIf;
			
		Else
			
			If CurRowLineItems.Account.AccountType = Enums.AccountTypes.AccountsPayable Then
				Return 4; // must have vendor
			EndIf;
				
			If CurRowLineItems.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
				Return 5;  // must have customer
			EndIf
			
		EndIf;
		
	EndDo
	
EndFunction

&AtClient
Procedure LineItemsAccountOnChange(Item)
	
	TotalDr = Object.LineItems.Total("AmountDr");
	TotalCr = Object.LineItems.Total("AmountCr");
	TabularPartRow = Items.LineItems.CurrentData;
	
	If Not CheckCurrencyUsedAccountType(TabularPartRow.Account) Then 
		Return;
	EndIf;	
	
	If TotalDr > TotalCr Then
		Difference = TotalDr - TotalCr;
		//TabularPartRow = Items.LineItems.CurrentData;
		If TabularPartRow.AmountCr = 0 AND TabularPartRow.AmountDr = 0 Then
			TabularPartRow.AmountCr = Difference;
			TabularPartRow.AmountDr = 0;
		EndIf;
	Elsif TotalCr > TotalDr Then
		Difference = TotalCr - TotalDr;
		//TabularPartRow = Items.LineItems.CurrentData;
		If TabularPartRow.AmountCr = 0 AND TabularPartRow.AmountDr = 0 Then
			TabularPartRow.AmountDr = Difference;
			TabularPartRow.AmountCr = 0;
		EndIf;
	Else
		
	EndIf;
	
	
	
EndProcedure

&AtServer
Function CheckCurrencyUsedAccountType(Account,LineIndex = Undefined)
	
	If false Then Account = ChartsOfAccounts.ChartOfAccounts.EmptyRef() EndIf;
	
	If GeneralFunctionsReusable.CurrencyUsedAccountType(Account.AccountType) Then 
		DefCurrency = Constants.DefaultCurrency.Get();
		If Object.Currency.IsEmpty() Then 
			Object.Currency = DefCurrency;
		EndIf;
		
		If Account.Currency.IsEmpty() and Object.Currency = DefCurrency Then 
			Return True;
		ElsIf Account.Currency = Object.Currency Then 
			Return True;
		Else 	
			If Constants.MultiCurrency.Get() Then 
				MessageText = "Currency of account must be the same as in document header.";
			Else 	
				MessageText = "Currency of account must be the same as in document header. Please contact support team.";
			EndIf;	
			If LineIndex = Undefined Then 
				CommonUseClientServer.MessageToUser(MessageText, Object);
			Else 	
				CommonUseClientServer.MessageToUser(MessageText, Object, "Object.LineItems["+Format(LineIndex, "NG=")+"].Account");
			EndIf;	
			Account = ChartsOfAccounts.ChartOfAccounts.EmptyRef();
			Return False;
		EndIf;	
	Else 	
		Return True;
	EndIf;	
EndFunction

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If Object.VoidingEntry <> Undefined Then
		Voided();
		Notify("UpdateVoid",Object.VoidingEntry);
	EndIf;
	
EndProcedure

&AtServer
Procedure Voided()
	If Object.VoidingEntry <> Undefined Then
		Items.VoidMessage.Title = "This entry is voiding";
		Items.VoidInfo.Visible = True;
	Else
		Items.VoidInfo.Visible = False;
	EndIf;
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If FirstNumber <> "" Then
		
		Numerator = Catalogs.DocumentNumbering.JournalEntry.GetObject();
		NextNumber = GeneralFunctions.Increment(Numerator.Number);
		If FirstNumber = NextNumber And NextNumber = Object.Number Then
			Numerator.Number = FirstNumber;
			Numerator.Write();
		EndIf;
		
		FirstNumber = "";
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure ReverseCommand(Command)
	
	Str = New Structure;
	Str.Insert("ReverseStuff", Object.Ref);
	OpenForm("Document.GeneralJournalEntry.Form.DocumentForm",Str);

EndProcedure

#EndRegion
