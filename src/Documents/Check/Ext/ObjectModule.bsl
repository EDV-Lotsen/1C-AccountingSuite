// Performs document posting
//
Procedure Posting(Cancel, PostingMode)
	
	RegisterRecords.GeneralJournal.Write = True;	
	
	VarDocumentTotal = 0;
	VarDocumentTotalRC = 0;
	For Each CurRowLineItems In LineItems Do			
		
		If CurRowLineItems.Amount >= 0 Then
			Record = RegisterRecords.GeneralJournal.AddDebit();
			Record.AmountRC = CurRowLineItems.Amount * ExchangeRate;
		Else
			Record = RegisterRecords.GeneralJournal.AddCredit();
			Record.AmountRC = -CurRowLineItems.Amount * ExchangeRate;
		EndIf;
		
		Record.Account = CurRowLineItems.Account;
		If CurRowLineItems.Account.AccountType = Enums.AccountTypes.AccountsPayable Then
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
			Record.Currency = Record.Account.Currency;
			Record.Amount = ?(CurRowLineItems.Amount > 0, CurRowLineItems.Amount, - CurRowLineItems.Amount);
		ElsIf CurRowLineItems.Account.AccountType = Enums.AccountTypes.AccountsReceivable Then
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Company] = Company;
			Record.ExtDimensions[ChartsOfCharacteristicTypes.Dimensions.Document] = Ref;
			Record.Currency = Record.Account.Currency;
			Record.Amount = ?(CurRowLineItems.Amount > 0, CurRowLineItems.Amount, - CurRowLineItems.Amount);
		ElsIf CurRowLineItems.Account.AccountType = Enums.AccountTypes.Bank Then	
			Record.Currency = Record.Account.Currency;
			Record.Amount = ?(CurRowLineItems.Amount > 0, CurRowLineItems.Amount, - CurRowLineItems.Amount);
		EndIf;
		
		Record.Period = Date;
		Record.Memo = CurRowLineItems.Memo;
		
		//--//GJ++
		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, CurRowLineItems.Class, CurRowLineItems.Project, Company);
		//--//GJ--
	
		VarDocumentTotal = VarDocumentTotal + CurRowLineItems.Amount;
		VarDocumentTotalRC = VarDocumentTotalRC + CurRowLineItems.Amount * ExchangeRate;
		
	EndDo;
	
	Record = RegisterRecords.GeneralJournal.AddCredit();
	Record.Account = BankAccount;
	Record.Memo = Memo;
	Record.Currency = BankAccount.Currency;
	Record.Period = Date;
	Record.Amount = VarDocumentTotal;
	Record.AmountRC = VarDocumentTotalRC;
	
	//--//GJ++
	ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Company);
	//--//GJ--
	
	// Writing bank reconciliation data
			
	ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, BankAccount, Date, -1 * DocumentTotalRC);
	
	LineItemsGroupped = LineItems.Unload(, "Account, Amount");
	LineItemsGroupped.GroupBy("Account", "Amount");
	For Each CheckRow In LineItemsGroupped Do
		If (CheckRow.Account.AccountType = Enums.AccountTypes.Bank) 
			OR (CheckRow.Account.AccountType = Enums.AccountTypes.OtherCurrentLiability And CheckRow.Account.CreditCard = True) Then
			ReconciledDocumentsServerCall.AddDocumentForReconciliation(RegisterRecords, Ref, CheckRow.Account, Date, CheckRow.Amount);
		EndIf;
	EndDo;

	
	RegisterRecords.ProjectData.Write = True;	
	RegisterRecords.ClassData.Write = True;
	For Each CurRowLineItems In LineItems Do
		Record = RegisterRecords.ProjectData.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Record.Account = CurRowLineItems.Account;
		Record.Project = CurRowLineItems.Project;
		Record.Amount = CurRowLineItems.Amount;
		
		Record = RegisterRecords.ClassData.Add();
		Record.RecordType = AccumulationRecordType.Expense;
		Record.Period = Date;
		Record.Account = CurRowLineItems.Account;
		Record.Class = CurRowLineItems.Class;
		Record.Amount = CurRowLineItems.Amount;
	EndDo;
	
	
	//CASH BASIS--------------------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	RegisterRecords.CashFlowData.Write = True;
	
	For Each CurrentTrans In RegisterRecords.GeneralJournalAnalyticsDimensions Do
		
		Record = RegisterRecords.CashFlowData.Add();
		Record.RecordType    = CurrentTrans.RecordType;
		Record.Period        = CurrentTrans.Period;
		Record.Account       = CurrentTrans.Account;
		Record.Company       = CurrentTrans.Company;
		Record.Document      = Ref;
		Record.SalesPerson   = Null;
		Record.Class         = CurrentTrans.Class;
		Record.Project       = CurrentTrans.Project;
		Record.AmountRC      = CurrentTrans.AmountRC;
		Record.PaymentMethod = PaymentMethod;
		
	EndDo;
	//------------------------------------------------------------------------------------------------------------
	//CASH BASIS (end)--------------------------------------------------------------------------------------------

	
	If (ExchangeRate <> 1) and Constants.MultiCurrency.Get() Then 	
		
		DocumentPosting.FixUnbalancedRegister(ThisObject,Cancel,Constants.ExchangeLoss.Get());
	Else 
		CheckedValueTable = RegisterRecords.GeneralJournal.Unload();
		UnbalancedAmount = 0;
		If Not DocumentPosting.IsValueTableBalanced(CheckedValueTable, UnbalancedAmount) Then 
			Cancel = True;
			// Generate error message.
			MessageText = NStr("en = 'The document %1 cannot be posted, because it''s transaction is unbalanced.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, Ref);
			CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
		EndIf;		
	EndIf;
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	//Remove physical num for checking
	PhysicalCheckNum = 0;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then // Skip some check ups.
		Return;
	EndIf;
	
	// Document date adjustment patch (tunes the date of drafts like for the new documents).
	If  WriteMode = DocumentWriteMode.Posting And Not Posted // Posting of new or draft (saved but unposted) document.
	And BegOfDay(Date) = BegOfDay(CurrentSessionDate()) Then // Operational posting (by the current date).
		// Shift document time to the time of posting.
		Date = CurrentSessionDate();
	EndIf;
	
	If (PaymentMethod = Catalogs.PaymentMethods.Check) And (WriteMode <> DocumentWriteMode.UndoPosting) Then	
		PhysicalCheckNum = Number;
		If ThisObject.AdditionalProperties.Property("AllowCheckNumber") Then
			If Not ThisObject.AdditionalProperties.AllowCheckNumber Then
				Cancel = True;
				//If Constants.DisableAuditLog.Get() = False Then
					//Cancel = True;
					Message("Check number already exists for this bank account");
				//EndIf;			
			EndIf;
		Else
			CheckNumberResult = CommonUseServerCall.CheckNumberAllowed(ThisObject.Number, ThisObject.Ref, ThisObject.BankAccount);
			If CheckNumberResult.DuplicatesFound Then
				If Not CheckNumberResult.Allow Then
					Cancel = True;
					//If Constants.DisableAuditLog.Get() = False Then
						//Cancel = True;
						Message("Check number already exists for this bank account");
					//EndIf;								
				Else
					Cancel = True;
					//If Constants.DisableAuditLog.Get() = False Then
						//Cancel = True;
						Message("Check number already exists for this bank account. Perform the operation interactively!");
					//EndIf;								
				EndIf;			
			Endif;
		EndIf;		
	EndIf;
	
EndProcedure
