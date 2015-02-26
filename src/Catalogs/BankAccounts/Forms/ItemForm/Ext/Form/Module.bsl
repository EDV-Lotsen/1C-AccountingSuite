
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//If Constants.DisplayExtendedAccountInfo.Get() = True Then
	//	Items.Online.Visible = True;
	//	Items.FormMergeTransactions.Visible 	= True;
	//	Items.FormUploadTransactions.Visible 	= True;
	//Else
	//	Items.Online.Visible = False;
	//	Items.FormMergeTransactions.Visible 	= False;
	//	Items.FormUploadTransactions.Visible 	= False;
	//EndIf;
	
	DefaultCurrencySymbol    				= GeneralFunctionsReusable.DefaultCurrencySymbol();
	Items.CurrentBalanceCurrency.Title 		= DefaultCurrencySymbol;
	Items.AvailableBalanceCurrency.Title 	= DefaultCurrencySymbol;
	Items.RunningBalanceCurrency.Title		= DefaultCurrencySymbol;
	Items.AvailableCreditCurrency.Title		= DefaultCurrencySymbol;
	Items.TotalCreditLineCurrency.Title		= DefaultCurrencySymbol;
	Items.AmountDueCurrency.Title			= DefaultCurrencySymbol;
	
	If ValueIsFilled(Object.ItemID) Then //If online account
		
		Items.Online.Visible = True;
		
		If Object.RefreshStatusCode <> 0 Then
			Items.StatusCodeDescriptionDecoration.Visible = True;
		Else
			Items.StatusCodeDescriptionDecoration.Visible = False;
		EndIf;
		
	Else //If offline account
		
		Items.Online.Visible = False;
			
	EndIf;
	
	If Object.Owner.ContainerType = Enums.YodleeContainerTypes.Credit_Card Then
		Items.BankAccountGroup.Visible = False;
		Items.CreditCardAccountGroup.Visible = True;
		Items.BalanceGroup.Visible = False;
		Items.CreditCardBalanceGroup.Visible = True;
	Else
		Items.BankAccountGroup.Visible = True;
		Items.CreditCardAccountGroup.Visible = False;
		Items.BalanceGroup.Visible = True;
		Items.CreditCardBalanceGroup.Visible = False;
	EndIf;
	
	ATArray = New Array();
	ATArray.Add(Enums.AccountTypes.Bank);
	ATArray.Add(Enums.AccountTypes.OtherCurrentAsset);
	ATArray.Add(Enums.AccountTypes.OtherCurrentLiability);
	NewParameter = New ChoiceParameter("Filter.AccountType", ATArray);
	NewArray = New Array();
	NewArray.Add(NewParameter);
	NewParameters = New FixedArray(NewArray);
	Items.AccountingAccount.ChoiceParameters = NewParameters;	
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	LastUpdatedTime = ?(ValueIsFilled(Object.LastUpdatedTimeUTC), ToLocalTime(Object.LastUpdatedTimeUTC), Object.LastUpdatedTimeUTC);
	TransactionsRefreshedTime = ?(ValueIsFilled(Object.TransactionsRefreshTimeUTC), ToLocalTime(Object.TransactionsRefreshTimeUTC), Object.TransactionsRefreshTimeUTC);
	LastUpdateAttemptTime = ?(ValueIsFilled(Object.LastUpdateAttemptTimeUTC), ToLocalTime(Object.LastUpdateAttemptTimeUTC), Object.LastUpdateAttemptTimeUTC);
	NextUpdateTime = ?(ValueIsFilled(Object.NextUpdateTimeUTC), ToLocalTime(Object.NextUpdateTimeUTC), Object.NextUpdateTimeUTC);

EndProcedure

#ENDREGION

#REGION FORM_COMMAND_HANDLERS

&AtClient
Procedure EditSignInInfo(Command)
	If Not Object.YodleeAccount Then
		return;		
	EndIf;
	
	Notify = New NotifyDescription("OnComplete_RefreshTransactions", ThisObject);
	Params = New Structure("PerformEditAccount, RefreshAccount", True, Object.Ref);
	OpenForm("DataProcessor.YodleeBankAccountsManagement.Form.Form", Params, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure DeleteAccount(Command)
	//Ask a user
	Mode = QuestionDialogMode.YesNoCancel;
	Notify = New NotifyDescription("DeleteAccountAfterQuery", ThisObject);
	ShowQueryBox(Notify, "Bank account " + String(Object.Ref) + " will be deleted. Are you sure?", Mode, 0, DialogReturnCode.Cancel, "Cloud banking"); 
EndProcedure

&AtClient
Procedure StatusCodeDescriptionDecorationClick(Item)
	OpenForm("DataProcessor.DownloadedTransactions.Form.DetailedErrorMessage", New Structure("StatusCode", String(Object.RefreshStatusCode)), ThisForm,,,,,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure UploadTransactions(Command)
	
	ImageAddress = "";
	
	Notify = New NotifyDescription("FileUpload", ThisForm);

	BeginPutFile(Notify, "", "*.qif; *.qbo; *.qfx; *.ofx; *.csv; *.iif", True, ThisForm.UUID);
	
EndProcedure

&AtClient
Procedure FileUpload(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	Extension = Lower(Right(SelectedFileName, 4));
	
	If Extension <> ".qif"
		And Extension <> ".qbo"
		And Extension <> ".qfx"
		And Extension <> ".ofx"
		And Extension <> ".csv"
		And Extension <> ".iif"
		And Extension <> ".txt"
		Then
		
		ShowMessageBox(, NStr("en = 'Please upload a valid file:
                               |.qif
                               |.qbo
                               |.qfx
                               |.ofx
                               |.csv
                               |.iif
                               |.txt'"));
		Return;
		
	EndIf;
	
	If ValueIsFilled(Address) And Extension = ".qif" Then
		QIF_UploadTransactionsAtServer(Address);
	ElsIf ValueIsFilled(Address) And (Extension = ".qbo" Or Extension = ".qfx" Or Extension = ".ofx") Then
		QBO_QFX_OFX_UploadTransactionsAtServer(Address);
	ElsIf ValueIsFilled(Address) And (Extension = ".csv" Or Extension = ".txt") Then
		CSV_TXT_UploadTransactionsAtServer(Address);
	ElsIf ValueIsFilled(Address) And Extension = ".iif" Then
		IIF_UploadTransactionsAtServer(Address);
	EndIf;
	
EndProcedure

&AtClient
Procedure MergeTransactions(Command)
	OpenForm("Catalog.BankAccounts.Form.MergeTransactionsForm",New Structure("BankAccount", Object.Ref), ThisForm,,,,,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

#ENDREGION

#REGION OTHER_FUNCTIONS

&AtClient
Procedure OnComplete_RefreshTransactions(ClosureResult, AdditionalParameters) Export
	Read();
EndProcedure

&AtServerNoContext
Function RemoveAccountAtServer(Item)
	If (Not Constants.ServiceDB.Get()) And (Item.YodleeAccount) Then //For online accounts
		return New Structure("returnValue, Status", False, "Bank accounts removal is available only in the Service DB");
	EndIf;
	return Yodlee.RemoveYodleeBankAccountAtServer(Item);
EndFunction

&AtClient
Procedure DeleteAccountAfterQuery(Result, Parameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		return;
	EndIf;
	
	//Disconnect from the Provider (Yodlee)
	//Then mark for deletion
	ReturnStruct = RemoveAccountAtServer(Object.Ref);
	If ReturnStruct.returnValue Then
		Notify("DeletedBankAccount", Object.Ref);
		NotifyChanged(Object.Ref);
		Close();
		ShowMessageBox(, ReturnStruct.Status,,"Removing bank account");
	Else
		If Find(ReturnStruct.Status, "InvalidItemExceptionFaultMessage") Then
			ShowMessageBox(, "Account not found.",,"Removing bank account");
		Else
			ShowMessageBox(, ReturnStruct.Status,,"Removing bank account");
		EndIf;
	EndIf;
EndProcedure

&AtServer 
Function GetBankTransactionsVT()
	
	Request = New Query("SELECT TOP 1
	                    |	*
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions");
	BankTransactions = Request.Execute().Unload();
	BankTransactions.Clear();
	return BankTransactions;
	
EndFunction

&AtServer
Procedure QIF_UploadTransactionsAtServer(TempStorageAddress) 
	
	BinaryData = GetFromTempStorage(TempStorageAddress);
	TempFileName = GetTempFileName("qif");
	BinaryData.Write(TempFileName);
	
	Try
		SourceText.Read(TempFileName);
	Except
		TextMessage = NStr("en = 'Can not read the file.'");
		CommonUseClientServer.MessageToUser(TextMessage);
		Return;
	EndTry;
	
	//Obtain ValueTable with register structure
	BankTransactions = GetBankTransactionsVT();

	LineCountTotal = SourceText.LineCount();
	
	NewTransaction = True;
	NumberTransaction = 0;
	
	For LineNumber = 1 To LineCountTotal Do
		
		CurrentLine = SourceText.GetLine(LineNumber);
		CurrentLine = TrimAll(CurrentLine);
		
		//begin ^
		If NewTransaction Then	
			NumberTransaction = NumberTransaction + 1;
			NewTransaction = False;
			NewRow = BankTransactions.Add();
		EndIf;
		
		//D
		If Left(CurrentLine, 1) = "D" Then
			DataOfRow = Mid(CurrentLine, 2, StrLen(CurrentLine) - 1);
			
			TransactionDate = '00010101';
			DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DataOfRow, "/");
			If DateParts.Count() = 3 then
				Try
					TransactionDate = Date(CommonUse.CSV_GetYear(DateParts[2]), DateParts[0], DateParts[1]);
				Except
				EndTry;				
			EndIf;
			
			If Not ValueIsFilled(TransactionDate) Then
				TextMessage = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'The bank transaction #%1 does not have a valid transaction date (%2)!'"), NumberTransaction, Format(TransactionDate, "DLF=D"));
				CommonUseClientServer.MessageToUser(TextMessage);
			EndIf;
			
			NewRow.TransactionDate = TransactionDate;
		EndIf;
		
		//T
		If Left(CurrentLine, 1) = "T" Then
			DataOfRow = Mid(CurrentLine, 2, StrLen(CurrentLine) - 1);
			
			NewRow.Amount = CommonUse.CSV_GetNumber(DataOfRow);
		EndIf;
		
		//N
		If Left(CurrentLine, 1) = "N" Then
			DataOfRow = Mid(CurrentLine, 2, StrLen(CurrentLine) - 1);
			
			NewRow.CheckNumber = DataOfRow;
		EndIf;
		
		//P
		If Left(CurrentLine, 1) = "P" Then
			DataOfRow = Mid(CurrentLine, 2, StrLen(CurrentLine) - 1);
			
			NewRow.Description = DataOfRow;
		EndIf;
		
		//end ^
		If Left(CurrentLine, 1) = "^" Then
			
			NewRow.BankAccount = Object.Ref;
			NewRow.ID		   = New UUID();
			
			BTCopy = BankTransactions.Copy();
			BTCopy.Delete(BankTransactions.IndexOf(NewRow));
			
			If DataProcessors.DownloadedTransactions.TransactionIsDuplicate(NewRow.BankAccount, NewRow.TransactionDate, NewRow.Amount, NewRow.CheckNumber, NewRow.Description, BTCopy) Then
				BankTransactions.Delete(NewRow);	
			EndIf;
			
			NewTransaction = True;
		
		EndIf;
				
	EndDo;
	
	BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
	BTRecordset.Load(BankTransactions);
	BTRecordset.Write(False);
	
	CommonUseClientServer.MessageToUser(NStr("en = 'The uploading of bank transactions is complete!'"));
	
EndProcedure

&AtServer
Procedure QBO_QFX_OFX_UploadTransactionsAtServer(TempStorageAddress) 
	
	BinaryData = GetFromTempStorage(TempStorageAddress);
	TempFileName = GetTempFileName("ofx");
	BinaryData.Write(TempFileName);
	
	Try
		SourceText.Read(TempFileName);
	Except
		TextMessage = NStr("en = 'Can not read the file.'");
		CommonUseClientServer.MessageToUser(TextMessage);
		Return;
	EndTry;
	
	//Obtain ValueTable with register structure
	BankTransactions = GetBankTransactionsVT();

	LineCountTotal = SourceText.LineCount();
	
	NewSTMTTRN = False;
	
	For LineNumber = 1 To LineCountTotal Do
		
		CurrentLine = SourceText.GetLine(LineNumber);
		CurrentLine = TrimAll(CurrentLine);
		
		//<STMTTRN>
		If Not NewSTMTTRN And Find(CurrentLine, "<STMTTRN>") > 0 Then
			NewSTMTTRN = True;
			
			NewRow = BankTransactions.Add();
		EndIf;
		
		//<DTPOSTED>
		If NewSTMTTRN And Find(CurrentLine, "<DTPOSTED>") > 0 Then
			StartPosition = Find(CurrentLine, "<DTPOSTED>") + 10;
			Year  = Mid(CurrentLine, StartPosition, 4);
			Month = Mid(CurrentLine, StartPosition + 4, 2);
			Day   = Mid(CurrentLine, StartPosition + 4+ 2, 2);
			
			NewRow.TransactionDate = Date(Year, Month, Day);
		EndIf;
		
		//<TRNAMT>
		If NewSTMTTRN And Find(CurrentLine, "<TRNAMT>") > 0 Then
			StartPosition = Find(CurrentLine, "<TRNAMT>") + 8;
			CountOfCharacters = StrLen(CurrentLine) - StartPosition + 1;
			
			NewRow.Amount = Number(Mid(CurrentLine, StartPosition, CountOfCharacters));
		EndIf;
		
		//<CHECKNUM>
		If NewSTMTTRN And Find(CurrentLine, "<CHECKNUM>") > 0 Then
			StartPosition = Find(CurrentLine, "<CHECKNUM>") + 10;
			CountOfCharacters = StrLen(CurrentLine) - StartPosition + 1;
			
			NewRow.CheckNumber = Mid(CurrentLine, StartPosition, CountOfCharacters);
		EndIf;
		
		//<NAME>
		If NewSTMTTRN And Find(CurrentLine, "<NAME>") > 0 Then
			StartPosition = Find(CurrentLine, "<NAME>") + 6;
			CountOfCharacters = StrLen(CurrentLine) - StartPosition + 1;
			
			NewRow.Description = Mid(CurrentLine, StartPosition, CountOfCharacters);
		EndIf;
		
		//</STMTTRN>
		If NewSTMTTRN And Find(CurrentLine, "</STMTTRN>") > 0 Then
			NewSTMTTRN = False;
			
			NewRow.BankAccount = Object.Ref;
			NewRow.ID		   = New UUID();
			
			BTCopy = BankTransactions.Copy();
			BTCopy.Delete(BankTransactions.IndexOf(NewRow));
			
			If DataProcessors.DownloadedTransactions.TransactionIsDuplicate(NewRow.BankAccount, NewRow.TransactionDate, NewRow.Amount, NewRow.CheckNumber, NewRow.Description, BTCopy) Then
				BankTransactions.Delete(NewRow);	
			EndIf;
		
		EndIf;
				
	EndDo;
	
	BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
	BTRecordset.Load(BankTransactions);
	BTRecordset.Write(False);
	
	CommonUseClientServer.MessageToUser(NStr("en = 'The uploading of bank transactions is complete!'"));
	
EndProcedure

&AtServer
Procedure CSV_TXT_UploadTransactionsAtServer(TempStorageAddress)
	
	BinaryData = GetFromTempStorage(TempStorageAddress);
	TempFileName = GetTempFileName("csv");
	BinaryData.Write(TempFileName);
	
	Try
		SourceText.Read(TempFileName);
		CSV_Text = SourceText.GetText();
	Except
		TextMessage = NStr("en = 'Can not read the file.'");
		CommonUseClientServer.MessageToUser(TextMessage);
		Return;
	EndTry;
	
	//Obtain ValueTable with register structure
	BankTransactions = GetBankTransactionsVT();

	VT = CommonUse.CSV_GetValueTable(CSV_Text, Object.CSV_Separator);
	
	//Check settings
	If Not CommonUse.CSV_CheckBankAccountSettings(Object, VT.Columns.Count()) Then
		Return;
	EndIf;
	
	For each CurrentLine In VT Do
		
		If VT.IndexOf(CurrentLine) = 0 And Object.CSV_HasHeaderRow Then
			Continue;
		EndIf;
		
		Try
			
			DateRow            = CurrentLine[Object.CSV_DateColumn - 1];
			If Object.CSV_CheckNumberColumn > 0 Then
				CheckNumberRow = CurrentLine[Object.CSV_CheckNumberColumn - 1];
			Else
				CheckNumberRow = "";
			EndIf;
			DescriptionRow     = CurrentLine[Object.CSV_DescriptionColumn - 1];
			MoneyInRow         = CurrentLine[Object.CSV_MoneyInColumn - 1];
			MoneyOutRow        = CurrentLine[Object.CSV_MoneyOutColumn - 1];
			
			MoneyInRow         = CommonUse.CSV_GetNumber(MoneyInRow);
			MoneyOutRow        = CommonUse.CSV_GetNumber(MoneyOutRow);

			If MoneyInRow <> 0 Then
				AmountRow      = MoneyInRow * ?(Object.CSV_MoneyInColumnChangeSymbol, -1, 1);
			Else
				AmountRow      = MoneyOutRow * ?(Object.CSV_MoneyOutColumnChangeSymbol, -1, 1);
			EndIf;
			
		Except
			
			TextMessage = NStr("en = 'Check format of file or settings CSV!'");
			CommonUseClientServer.MessageToUser(TextMessage);
			
		EndTry;
		
		//Convert date
		TransactionDate = '00010101';
		DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DateRow, "/");
		If DateParts.Count() = 3 then
			Try
				TransactionDate = Date(CommonUse.CSV_GetYear(DateParts[2]), DateParts[0], DateParts[1]);
			Except
			EndTry;				
		EndIf;
		If Not ValueIsFilled(TransactionDate) Then
			TextMessage = "The following bank transaction: " + Format(TransactionDate, "DLF=D") + "; " + DescriptionRow + "; " + AmountRow + " does not have a valid transaction date!";
			CommonUseClientServer.MessageToUser(TextMessage);
			Continue;
		EndIf;
		NewRow = BankTransactions.Add();
		NewRow.TransactionDate 	= TransactionDate;
		NewRow.CheckNumber 		= CheckNumberRow;
		NewRow.Description 		= DescriptionRow;
		NewRow.Amount 			= AmountRow;
		NewRow.BankAccount 		= Object.Ref;
		NewRow.ID				= New UUID();
		
		BTCopy = BankTransactions.Copy();
		BTCopy.Delete(BankTransactions.IndexOf(NewRow));
		
		If DataProcessors.DownloadedTransactions.TransactionIsDuplicate(NewRow.BankAccount, NewRow.TransactionDate, NewRow.Amount, NewRow.CheckNumber, NewRow.Description, BTCopy) Then
			BankTransactions.Delete(NewRow);	
		EndIf;
		
	EndDo;
	
	BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
	BTRecordset.Load(BankTransactions);
	BTRecordset.Write(False);
	
	CommonUseClientServer.MessageToUser(NStr("en = 'The uploading of bank transactions is complete!'"));
	
EndProcedure

&AtServer
Procedure IIF_UploadTransactionsAtServer(TempStorageAddress) 
	
	BinaryData = GetFromTempStorage(TempStorageAddress);
	TempFileName = GetTempFileName("iif");
	BinaryData.Write(TempFileName);
	
	Try
		SourceText.Read(TempFileName);
	Except
		TextMessage = NStr("en = 'Can not read the file.'");
		CommonUseClientServer.MessageToUser(TextMessage);
		Return;
	EndTry;
	
	//Obtain ValueTable with register structure
	BankTransactions = GetBankTransactionsVT();

	LineCountTotal = SourceText.LineCount();
	
	StructureOfTransaction = New Structure("DATE, AMOUNT, DOCNUM, NAME");
	HeaderFound            = False;
	NumberTransaction      = 0;
	
	For LineNumber = 1 To LineCountTotal Do
		
		CurrentLine = SourceText.GetLine(LineNumber);
		
		If Left(CurrentLine, 5) = "!TRNS" Then
			
			HeaderFound = True;
			HeaderParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(CurrentLine, Chars.Tab);
			
			For Each RowParts In HeaderParts Do
				
				If Find("DATE", RowParts) Then
					StructureOfTransaction.Insert("DATE", HeaderParts.Find(RowParts));
				ElsIf Find("AMOUNT", RowParts) Then
					StructureOfTransaction.Insert("AMOUNT", HeaderParts.Find(RowParts));
				ElsIf Find("DOCNUM", RowParts) Then
					StructureOfTransaction.Insert("DOCNUM", HeaderParts.Find(RowParts));
				ElsIf Find("NAME", RowParts) Then
					StructureOfTransaction.Insert("NAME", HeaderParts.Find(RowParts));
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If HeaderFound And Left(CurrentLine, 4) = "TRNS" Then
			
			NumberTransaction = NumberTransaction + 1;
			NewRow = BankTransactions.Add();
			NewRow.BankAccount = Object.Ref;
			NewRow.ID		   = New UUID();
			
			//1.
			StructureOfLine  = New Array;
			NumberCharacters = StrLen(CurrentLine);
			UseDoubleQuotes  = False;
			ValueField       = "";
			
			For i = 1 To NumberCharacters Do
				
				CurrentSymbol = Mid(CurrentLine, i, 1);
				
				If CurrentSymbol = Chars.Tab And (Not UseDoubleQuotes) Then
					StructureOfLine.Add(CommonUse.CSV_ChangeValue(ValueField));
					ValueField = "";
				ElsIf CurrentSymbol = """" Then
					UseDoubleQuotes = Not UseDoubleQuotes; 
					ValueField = ValueField + CurrentSymbol;
				Else
					ValueField = ValueField + CurrentSymbol;
				EndIf;
				
				If i = NumberCharacters Then
					StructureOfLine.Add(CommonUse.CSV_ChangeValue(ValueField));
					ValueField = "";
				EndIf;
				
			EndDo;
			
			//2.
			//DATE
			If StructureOfTransaction.DATE <> Undefined Then
				DataOfRow = StructureOfLine[StructureOfTransaction.DATE];	
				
				TransactionDate = '00010101';
				DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(DataOfRow, "/");
				If DateParts.Count() = 3 then
					Try
						TransactionDate = Date(CommonUse.CSV_GetYear(DateParts[2]), DateParts[0], DateParts[1]);
					Except
					EndTry;				
				EndIf;
				
				If Not ValueIsFilled(TransactionDate) Then
					TextMessage = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'The bank transaction #%1 does not have a valid transaction date (%2)!'"), NumberTransaction, Format(TransactionDate, "DLF=D"));
					CommonUseClientServer.MessageToUser(TextMessage);
				EndIf;
				
				NewRow.TransactionDate = TransactionDate;
			EndIf;
			
			//AMOUNT
			If StructureOfTransaction.AMOUNT <> Undefined Then
				DataOfRow = StructureOfLine[StructureOfTransaction.AMOUNT];
				
				NewRow.Amount = CommonUse.CSV_GetNumber(DataOfRow);
			EndIf;
			
			//DOCNUM
			If StructureOfTransaction.DOCNUM <> Undefined Then
				DataOfRow = StructureOfLine[StructureOfTransaction.DOCNUM];
				
				NewRow.CheckNumber = DataOfRow;
			EndIf;
			
			//NAME
			If StructureOfTransaction.NAME <> Undefined Then
				DataOfRow = StructureOfLine[StructureOfTransaction.NAME];
				
				NewRow.Description = DataOfRow;
			EndIf;
			
			BTCopy = BankTransactions.Copy();
			BTCopy.Delete(BankTransactions.IndexOf(NewRow));
			
			If DataProcessors.DownloadedTransactions.TransactionIsDuplicate(NewRow.BankAccount, NewRow.TransactionDate, NewRow.Amount, NewRow.CheckNumber, NewRow.Description, BTCopy) Then
				BankTransactions.Delete(NewRow);	
			EndIf;
						
		EndIf;
		
	EndDo;
	
	BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
	BTRecordset.Load(BankTransactions);
	BTRecordset.Write(False);
	
	CommonUseClientServer.MessageToUser(NStr("en = 'The uploading of bank transactions is complete!'"));
	
EndProcedure

#ENDREGION