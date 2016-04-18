
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//Setup visibility of the View bank transactions hyperlink
	If Object.Ref.IsEmpty() Then
		Items.BankTransaction1Decoration.Visible = False;
		Items.BankTransaction1Unavailable.Visible = False;
		Items.BankTransaction2Decoration.Visible = False;
		Items.BankTransaction2Unavailable.Visible = False;
	EndIf;
	
	MultiCurrencyVisibilitySetup();
	ImportantNoticeVisibilityAtServer();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)

	If Object.AccountFrom = Object.AccountTo Then
		
		Message = New UserMessage();
		Message.Text=NStr("en='Account from and Account to can not be the same'");
		Message.Message();
		Cancel = True;
		Return;

		
	EndIf;
	
EndProcedure

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


&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;

	
	//
	//If Object.Ref.IsEmpty() Then
	//
	//	MatchVal = Increment(Constants.BankTransferLastNumber.Get());
	//	If Object.Number = MatchVal Then
	//		Constants.BankTransferLastNumber.Set(MatchVal);
	//	Else
	//		If Increment(Object.Number) = "" Then
	//		Else
	//			If StrLen(Increment(Object.Number)) > 20 Then
	//				 Constants.BankTransferLastNumber.Set("");
	//			Else
	//				Constants.BankTransferLastNumber.Set(Increment(Object.Number));
	//			Endif;

	//		Endif;
	//	Endif;
	//Endif;
	//
	//If Object.Number = "" Then
	//	Message("BankTransfer Number is empty");
	//	Cancel = True;
	//Endif;
	
EndProcedure


&AtClient
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

&AtClient
Procedure AmountOnChange(Item)
	AmountOnChangeAtServer();
EndProcedure

&AtServer
Procedure AmountOnChangeAtServer()
	RecalculateAmountTo();
EndProcedure

&AtServer
Procedure RecalculateAmountTo()
	If GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then	
		If Object.ExchangeRate = 0 Then 
			Object.ExchangeRate = 1;
		EndIf;	
		Object.AmountTo = Object.Amount * Object.ExchangeRate;
	Else 
		Object.AmountTo = Object.Amount;
	EndIf;
EndProcedure

&AtServer
Procedure RecalculateExchangeRate()
	If GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then	
		AccountFromCurrency = Object.Currency;
		AccountToCurrency = Object.AccountTo.Currency;
		DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
		// Using Default currency to recalc rate
		
		If AccountFromCurrency = DefaultCurrency Then 
			TodayRate = GeneralFunctions.GetExchangeRate(Object.Date, AccountToCurrency);
			Object.ExchangeRate = 1/TodayRate;
		ElsIf AccountToCurrency = AccountFromCurrency Then 
			Object.ExchangeRate = 1;
		Else // Need to calc cross-rate
			TodayRateFrom = GeneralFunctions.GetExchangeRate(Object.Date, AccountFromCurrency);
			TodayRateTo = GeneralFunctions.GetExchangeRate(Object.Date, AccountToCurrency);
			CrossRate = (TodayRateFrom/TodayRateTo);
			Object.ExchangeRate = CrossRate;
		EndIf;
	Else 
		Object.ExchangeRate = 1;
	EndIf;	
EndProcedure

&AtServer
Procedure MultiCurrencyVisibilitySetup()
	If GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then	
		Items.MulticurrencyGroup.Visible = True;
		Items.Amount.Title = "Amount "+ Object.Currency.Description;
		If Object.ManuallyEditedAmountTo Then 
			Items.AmountTo.Enabled = True;
		Else 
			Items.AmountTo.Enabled = False;
		EndIf;	
	Else 
		Items.MulticurrencyGroup.Visible = False;
		Items.Amount.Title = "Amount";
	EndIf;
	
EndProcedure

&AtClient
Procedure AccountFromOnChange(Item)
	AccountFromOnChangeAtServer();
EndProcedure

&AtServer
Procedure AccountFromOnChangeAtServer()
	Object.Currency = Object.AccountFrom.Currency;
	Items.Amount.Title = "Amount "+ Object.Currency.Description;
	RecalculateExchangeRate();
	ExchangeRateOnChangeAtServer();
	ImportantNoticeVisibilityAtServer();
EndProcedure

&AtClient
Procedure ExchangeRateOnChange(Item)
	ExchangeRateOnChangeAtServer();
EndProcedure

&AtServer
Procedure ExchangeRateOnChangeAtServer()
	RecalculateAmountTo();
EndProcedure

&AtClient
Procedure AccountToOnChange(Item)
	AccountToOnChangeAtServer();
EndProcedure

&AtServer
Procedure AccountToOnChangeAtServer()
	RecalculateExchangeRate();
	ExchangeRateOnChangeAtServer();
	ImportantNoticeVisibilityAtServer();	
EndProcedure

&AtServer
Procedure ImportantNoticeVisibilityAtServer()
	If GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then	
		If Object.AccountFrom.IsEmpty() Or Object.AccountTo.IsEmpty() Then 
			Items.ImportantNotice.Visible = False;
		Else	
			DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
			If 	Object.AccountFrom.Currency <> DefaultCurrency And Object.AccountTo.Currency <> DefaultCurrency Then 
				
				TodayDefaultRate = GeneralFunctions.GetExchangeRate(Object.Date, Object.Currency);
				
				Items.ImportantNotice.Visible = True;
				Items.ImportantNotice.Title = 
				"WARNING!!! Both accounts are not in default currency. " +Chars.LF + 
				""+DefaultCurrency+" Amount in records will be: "+Object.Amount*TodayDefaultRate +Chars.LF +
				"Default exchange rate: "+TodayDefaultRate;//+DefaultCurrency+" amount: " 
				
			Else 	
				Items.ImportantNotice.Visible = False;
			EndIf;	
		EndIf;	
	Else 
		Items.ImportantNotice.Visible = False;
	EndIf;
EndProcedure

&AtClient
Procedure ManuallyEditedAmountToOnChange(Item)
	ManuallyEditedAmountToOnChangeAtServer();
EndProcedure

&AtServer
Procedure ManuallyEditedAmountToOnChangeAtServer()
	RecalculateAmountTo();
	MultiCurrencyVisibilitySetup();
EndProcedure

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure AuditLogRecord(Command)
	
	FormParameters = New Structure();	
	FltrParameters = New Structure();
	FltrParameters.Insert("DocUUID", String(Object.Ref.UUID()));
	FormParameters.Insert("Filter", FltrParameters);
	OpenForm("CommonForm.AuditLogList",FormParameters, Object.Ref);

EndProcedure

#EndRegion

