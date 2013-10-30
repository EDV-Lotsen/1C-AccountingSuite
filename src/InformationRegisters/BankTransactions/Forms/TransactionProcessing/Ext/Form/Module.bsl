////////////////////////////////////////////////////////////////////////////////
// Banking transactions view and processing
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// 
//------------------------------------------------------------------------------
// The form can be used in web client only.
//

////////////////////////////////////////////////////////////////////////////////
// FORM SERVER FUNCTIONS

////////////////////////////////////////////////////////////////////////////////
// FORM COMMAND HANDLERS

&AtClient
Procedure AcceptTransactions(Command)
	AcceptTransactionsAtServer();
EndProcedure

&AtServer
Procedure AcceptTransactionsAtServer()
	Try
	BeginTransaction();
	For Each Tran In Transactions Do
		If Not Tran.Accept then
			Continue;
		EndIf;
		If ValueIsFilled(Tran.Document) then
			NewCheck		= Tran.Document.GetObject();
		Else
			NewCheck 		= Documents.Check.CreateDocument();
		EndIf;
		NewCheck.Date 	= Tran.TransactionDate;
		NewCheck.BankAccount 		= Tran.BankAccount;
		NewCheck.Memo 				= Tran.Description;
		NewCheck.Company 			= Tran.Company;
		NewCheck.DocumentTotal 		= Tran.Amount;
		NewCheck.DocumentTotalRC 	= Tran.Amount;
		NewCheck.ExchangeRate 		= 1;
		
		NewLine = NewCheck.LineItems.Add();
		NewLine.Account 			= Tran.Category;
		NewLine.AccountDescription 	= Tran.Category.Description;
		NewLine.Amount 				= Tran.Amount;
		NewLine.Memo 				= Tran.Description;
		If NewCheck.IsNew() then
			NewCheck.SetNewNumber();
		EndIf;
		NewCheck.Write(DocumentWriteMode.Posting);
				
		Tran.Document				= NewCheck.Ref;
				
	EndDo;
	RecordSet = FormAttributeToValue("Transactions");
	RecordSet.Write(True);
	Except
	    ErrDesc	= ErrorDescription();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		CommonUseClientServer.MessageToUser(ErrDesc);
		Return;
	EndTry;		
	
	CommitTransaction();
EndProcedure

&AtClient
Procedure MarkAll(Command)
	For Each Tran In Transactions Do
		Tran.Accept = True;
	EndDo;
EndProcedure

&AtClient
Procedure UnmarkAll(Command)
	For Each Tran In Transactions Do
		Tran.Accept = False;
	EndDo;
EndProcedure

&AtClient
Procedure InvertAll(Command)
	For Each Tran In Transactions Do
		Tran.Accept = ?(Tran.Accept, False, True);
	EndDo;
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SERVER EVENT HANDLERS

////////////////////////////////////////////////////////////////////////////////
// FORM ITEMS HANDLERS

&AtClient
Procedure ProcessingPeriodOnChange(Item)
	ProcessingPeriodOnChangeAtServer();
	RefreshDataRepresentation();
EndProcedure

&AtServer
Procedure ProcessingPeriodOnChangeAtServer()
	BankTrans 						= FormAttributeToValue("Transactions");
	TranDateFilter 					= BankTrans.Filter.TransactionDate;
	TranDateFilter.ComparisonType 	= ComparisonType.Equal;
	TranDateFilter.Value			= ProcessingPeriod;
	TranDateFilter.Use				= ?(ValueIsFilled(ProcessingPeriod), True, False);
	BankTrans.Read();
	ValueToFormAttribute(BankTrans, "Transactions");
EndProcedure

&AtClient
Procedure CaptionBankAccountOnChange(Item)
	CaptionBankAccountOnChangeAtServer();
EndProcedure

&AtServer
Procedure CaptionBankAccountOnChangeAtServer()
	BankTrans 							= FormAttributeToValue("Transactions");
	BankAccountFilter					= BankTrans.Filter.BankAccount;
	BankAccountFilter.ComparisonType 	= ComparisonType.Equal;
	BankAccountFilter.Value				= BankAccount;
	BankAccountFilter.Use				= ?(ValueIsFilled(BankAccount), True, False);;
	BankTrans.Read();
	ValueToFormAttribute(BankTrans, "Transactions");
EndProcedure

&AtClient
Procedure RecordSetBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	If Clone then
		Cancel = True;
	EndIf;
EndProcedure
