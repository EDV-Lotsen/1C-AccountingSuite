
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
	If DocumentPosting.DocumentPeriodIsClosed(Object.Ref, Object.Date) Then
		Cancel = Not DocumentPosting.DocumentWritePermitted(WriteParameters);
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
	
	SetType();

	Object.DueDate = Object.Date;
	
	TotalDr = Object.LineItems.Total("AmountDr");
	TotalCr = Object.LineItems.Total("AmountCr"); 
	
	Object.DocumentTotal = TotalDr;
	Object.DocumentTotalRC = TotalDr * Object.ExchangeRate;
	
	If Not GeneralFunctions.FunctionalOptionValue("UnbalancedGJEntryPosting") Then
		
		If TotalDr <> TotalCr Then
			Message = New UserMessage();
			Message.Text = NStr("en='Balance The Transaction'");
			Message.Message();
			Cancel = True;
            Return;
		EndIf;
	
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
		Items.ReverseButton.Visible = False;
	Endif;
	
	// checking if Reverse journal entry button was clicked
	If Parameters.Property("ReverseStuff") Then
		PreviousRef = Parameters.ReverseStuff;
		ReverseJournalEntry(PreviousRef);
		Items.ReverseButton.Visible = False;
	EndIf;
	
	//Title = "GL entry " + Object.Number + " " + Format(Object.Date, "DLF=D");
	
	If Object.Currency.IsEmpty() Then
		Object.Currency = Constants.DefaultCurrency.Get();
		Object.ExchangeRate = 1;
	Else
	EndIf;
	
	Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + Object.Currency.Symbol;
	
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
    Items.ExchangeRate.Title = GeneralFunctionsReusable.DefaultCurrencySymbol() + "/1" + CommonUse.GetAttributeValue(Object.Currency, "Symbol");

EndProcedure

&AtClient
Procedure DateOnChange(Item)
	
	Object.ExchangeRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
	
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
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	//Period closing
	If DocumentPosting.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = DocumentPosting.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;

EndProcedure


&AtClient
Procedure ReverseCommand(Command)	
	
	Str = New Structure;
	Str.Insert("ReverseStuff", Object.Ref);
	OpenForm("Document.GeneralJournalEntry.Form.DocumentForm",Str);
	
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
		newLineItem.AccountDescription = CurRowLineItems.AccountDescription;
		newLineItem.AmountDr = CurRowLineItems.AmountCr;
		newLineItem.AmountCr = CurRowLineItems.AmountDr;
		newLineItem.Company = CurRowLineItems.Company;
	EndDo;
	
	Object.Currency = Old.Currency;
	Object.ExchangeRate = Old.ExchangeRate;
	Object.DocumentTotal = Object.LineItems.Total("AmountDR");
	Object.DocumentTotalRC = Object.LineItems.Total("AmountDR") * Object.ExchangeRate;
	
EndProcedure
