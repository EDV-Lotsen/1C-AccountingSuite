////////////////////////////////////////////////////////////////////////////////
// Bank transaction processing form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

&AtClient
Var FormIsModified, QuestionAsked;

////////////////////////////////////////////////////////////////////////////////
// FORM SERVER FUNCTIONS

&AtServer
Procedure UploadTransactionsFromDB(SelectUnaccepted = True, SelectAccepted = True)
	TransactionRequest = New Query("SELECT ALLOWED
	                               |	BankTransactions.TransactionDate AS TransactionDate,
	                               |	BankTransactions.BankAccount,
	                               |	BankTransactions.Company AS Company,
	                               |	BankTransactions.ID AS TransactionID,
	                               |	BankTransactions.Description AS Description,
	                               |	BankTransactions.Amount,
	                               |	BankTransactions.Category AS Category,
	                               |	BankTransactions.Document,
	                               |	BankTransactions.Accepted,
	                               |	BankTransactions.Hidden,
	                               |	CASE
	                               |		WHEN BankTransactions.Hidden
	                               |			THEN ""Show""
	                               |		ELSE ""Hide""
	                               |	END AS Hide,
	                               |	BankTransactions.Document.Presentation,
	                               |	BankTransactions.OriginalID,
	                               |	BankTransactions.YodleeTransactionID,
	                               |	BankTransactions.PostDate,
	                               |	BankTransactions.Price,
	                               |	BankTransactions.Quantity,
	                               |	BankTransactions.RunningBalance,
	                               |	BankTransactions.CurrencyCode,
	                               |	BankTransactions.CategoryName,
	                               |	BankTransactions.Type
	                               |FROM
	                               |	InformationRegister.BankTransactions AS BankTransactions
	                               |WHERE
	                               |	(BankTransactions.BankAccount = &BankAccount
	                               |			OR &BankAccount = VALUE(Catalog.BankAccounts.EmptyRef))
	                               |
	                               |ORDER BY
	                               |	TransactionDate DESC,
	                               |	Description,
	                               |	Company,
	                               |	Category");
	//TransactionRequest.SetParameter("BeginDate", Object.ProcessingPeriod.StartDate);
	//TransactionRequest.SetParameter("EndDate", Object.ProcessingPeriod.EndDate);
	//TransactionRequest.SetParameter("BankAccount", Object.BankAccount);
	TransactionRequest.SetParameter("BankAccount", AccountInBank);
	UploadedTransactions = TransactionRequest.Execute().Unload();
	If SelectUnaccepted then
		Unaccepted 		= UploadedTransactions.FindRows(New Structure("Accepted", False));
		VT_Unaccepted 	= UploadedTransactions.Copy(Unaccepted);
		Object.BankTransactionsUnaccepted.Load(VT_Unaccepted);
		For Each Tran In Object.BankTransactionsUnaccepted Do
			Tran.AssigningOption 	= GetAssigningOption(Tran.Document, Tran.DocumentPresentation);
			//If ValueIsFilled(Tran.Document) Then
			//	Tran.AssigningOption = "Assigned to " + Tran.DocumentPresentation; 
			//EndIf;
		EndDo;
		ThisForm.Modified = False;
	EndIf;
	If SelectAccepted then
		Accepted 		= UploadedTransactions.FindRows(New Structure("Accepted", True));
		VT_Accepted 	= UploadedTransactions.Copy(Accepted);
		Object.BankTransactionsAccepted.Load(VT_Accepted);
	EndIf;

EndProcedure

&AtServer
Procedure AcceptTransactionsAtServer()
	//Save current data in BankTransactionsUnaccepted for using in case of failure
	CurrentTransactionsUnaccepted = Object.BankTransactionsUnaccepted.Unload();
	Transactions = Object.BankTransactionsUnaccepted.FindRows(New Structure("Accept", True));
	Try
	BeginTransaction();
	i = 0;
	BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
	While i < Transactions.Count() Do
		Tran = Transactions[i];
		
		If Tran.Amount < 0 Then //Create Check
			Tran.Document				= Create_DocumentCheck(Tran);
		Else //Create Deposit
			Tran.Document				= Create_DocumentDeposit(Tran);
		EndIf;
		
		//Add (save) current row to a information register
		BTRecordset.Clear();
		BTRecordSet.Filter.Reset();
		If NOT ValueIsFilled(Tran.TransactionID) then
			Tran.TransactionID = New UUID();
		EndIf;
		//BTRecordset.Filter.ID.Set(New UUID("00000000-0000-0000-0000-000000000000"));
		BTRecordset.Filter.ID.Set(Tran.TransactionID);
		BTRecordset.Write(True);
		
		BTRecordset.Clear();
		BTRecordset.Filter.TransactionDate.Set(Tran.TransactionDate);
		BTRecordset.Filter.BankAccount.Set(Tran.BankAccount);
		BTRecordset.Filter.Company.Set(Tran.Company);
		BTRecordset.Filter.ID.Set(Tran.TransactionID);
		NewRecord = BTRecordset.Add();
		FillPropertyValues(NewRecord, Tran);
		NewRecord.Accepted 	= True;
		NewRecord.ID		= Tran.TransactionID;
		BTRecordset.Write(True);
		
		Object.BankTransactionsUnaccepted.Delete(Object.BankTransactionsUnaccepted.IndexOf(Tran));
		i = i + 1;
	EndDo;
		
	Except
	    ErrDesc	= ErrorDescription();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		Object.BankTransactionsUnaccepted.Load(CurrentTransactionsUnaccepted);
		CommonUseClientServer.MessageToUser(ErrDesc);
		Return;
	EndTry;		
	
	CommitTransaction();
	
	UploadTransactionsFromDB(False, True);
EndProcedure

&AtServer
Function Create_DocumentCheck(Tran)	
	If ValueIsFilled(Tran.Document) then
		If TypeOf(Tran.Document) = Type("DocumentRef.InvoicePayment") Then
			Return Tran.Document;
		EndIf;
		NewCheck		= Tran.Document.GetObject();
	Else
		NewCheck 		= Documents.Check.CreateDocument();
	EndIf;
	NewCheck.Date 	= Tran.TransactionDate;
	NewCheck.BankAccount 		= Tran.BankAccount.AccountingAccount;
	NewCheck.Memo 				= Tran.Description;
	NewCheck.Company 			= Tran.Company;
	NewCheck.DocumentTotal 		= -1*Tran.Amount;
	NewCheck.DocumentTotalRC 	= -1*Tran.Amount;
	NewCheck.ExchangeRate 		= 1;
	NewCheck.PaymentMethod		= Catalogs.PaymentMethods.DebitCard;
	
	NewCheck.LineItems.Clear();
	NewLine = NewCheck.LineItems.Add();
	NewLine.Account 			= Tran.Category;
	NewLine.AccountDescription 	= Tran.Category.Description;
	NewLine.Amount 				= -1*Tran.Amount;
	NewLine.Memo 				= Tran.Description;
	//Deletion mark
	If NewCheck.DeletionMark Then
		NewCheck.DeletionMark	= False;	
	EndIf;
	NewCheck.Write(DocumentWriteMode.Posting);
	
	Return NewCheck.Ref;
EndFunction

&AtServer
Function Create_DocumentDeposit(Tran)
	If ValueIsFilled(Tran.Document) then
		NewDeposit		= Tran.Document.GetObject();
		If TypeOf(Tran.Document) = Type("DocumentRef.CashReceipt") Then
			Return Tran.Document;
		EndIf;
	Else
		NewDeposit 		= Documents.Deposit.CreateDocument();
	EndIf;
	NewDeposit.Date 			= Tran.TransactionDate;
	NewDeposit.BankAccount 		= Tran.BankAccount.AccountingAccount;
	NewDeposit.Memo 			= Tran.Description;
	//NewCheck.Company 			= Tran.Company;
	NewDeposit.DocumentTotal 	= Tran.Amount;
	NewDeposit.DocumentTotalRC 	= Tran.Amount;
	NewDeposit.TotalDeposits	= Tran.Amount;
	NewDeposit.TotalDepositsRC	= Tran.Amount;
	
	NewDeposit.Accounts.Clear();
	NewLine = NewDeposit.Accounts.Add();
	NewLine.Account 			= Tran.BankAccount.AccountingAccount;
	NewLine.Amount 				= Tran.Amount;
	NewLine.Memo 				= Tran.Description;
	//Deletion mark
	If NewDeposit.DeletionMark Then
		NewDeposit.DeletionMark	= False;	
	EndIf;
	NewDeposit.Write(DocumentWriteMode.Posting);
	
	Return NewDeposit.Ref;
EndFunction

//Saves all unaccepted transactions being edited in database
//Assigns UUIDs to a new transactions
&AtServer
Procedure SaveUnacceptedAtServer()
	BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
	For Each Tran In Object.BankTransactionsUnaccepted Do
		//Add (save) current row to a information register
		BTRecordset.Clear();
		BTRecordSet.Filter.Reset();
		If NOT ValueIsFilled(Tran.TransactionID) then
			Tran.TransactionID = New UUID();
		EndIf;
		//BTRecordset.Filter.ID.Set(New UUID("00000000-0000-0000-0000-000000000000"));
		BTRecordset.Filter.ID.Set(Tran.TransactionID);
		BTRecordset.Write(True);
		
		BTRecordset.Clear();
		BTRecordset.Filter.TransactionDate.Set(Tran.TransactionDate);
		BTRecordset.Filter.BankAccount.Set(Tran.BankAccount);
		BTRecordset.Filter.Company.Set(Tran.Company);
		BTRecordset.Filter.ID.Set(Tran.TransactionID);
		NewRecord = BTRecordset.Add();
		FillPropertyValues(NewRecord, Tran);
		NewRecord.Accepted	= False;
		NewRecord.ID		= Tran.TransactionID;
		BTRecordset.Write(True);
	EndDo;
	ThisForm.Modified = False;
EndProcedure

//Saves current unaccepted transaction being edited in database
//Assigns UUIDs to a new transaction
&AtServerNoContext
Function SaveTransactionAtServer(Tran)
	BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
	//Add (save) current row to a information register
	If NOT ValueIsFilled(Tran.ID) then
		Tran.ID = New UUID();
	EndIf;
	BTRecordset.Filter.ID.Set(Tran.ID);
	BTRecordset.Write(True);
		
	BTRecordset.Clear();
	BTRecordset.Filter.TransactionDate.Set(Tran.TransactionDate);
	BTRecordset.Filter.BankAccount.Set(Tran.BankAccount);
	BTRecordset.Filter.Company.Set(Tran.Company);
	BTRecordset.Filter.ID.Set(Tran.ID);
	NewRecord = BTRecordset.Add();
	FillPropertyValues(NewRecord, Tran);
	BTRecordset.Write(True);
	Return Tran.ID;
EndFunction

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	//Variables initiation
	ShowHidden	= "Show";
	Object.ProcessingPeriod.Variant	=StandardPeriodVariant.ThisMonth;
	
	//Uploading transactions 
	UploadTransactionsFromDB();
	ApplyConditionalAppearance();
	
EndProcedure

&AtServer
Procedure ApplyConditionalAppearance()
	
	CA = ThisForm.ConditionalAppearance; 
 	CA.Items.Clear(); 
	
	//Highlighting hidden lines with light-grey color
 	ElementCA = CA.Items.Add(); 
	
	AddDataCompositionFields(ElementCA, Items.BankTransactionsUnaccepted.ChildItems);
	
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Hidden"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= True; 
	FilterElement.Use				= True;
    
 	ElementCA.Appearance.SetParameterValue("BackColor", WebColors.Gainsboro); 
	
	//Highlighting hidden lines with strikethrough font
	ElementCA = CA.Items.Add(); 
	
	AddDataCompositionFields(ElementCA, Items.BankTransactionsUnaccepted.ChildItems, "BankTransactionsUnacceptedHide");
	
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Hidden"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= True; 
	FilterElement.Use				= True;
	
	DefaultFont = ElementCA.Appearance.FindParameterValue(New DataCompositionParameter("Font")).Value;
	StrikeThroughFont	=New Font(DefaultFont,,,,,,); //Strikethrough font
	ElementCA.Appearance.SetParameterValue("Font", StrikeThroughFont); 
	
	//Highlighting show/hide column with green font
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedHide"); 
 	FieldAppearance.Use = True; 

	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Hidden"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= True; 
	FilterElement.Use				= True;
	
	DefaultFont = ElementCA.Appearance.FindParameterValue(New DataCompositionParameter("Font")).Value;
	ElementCA.Appearance.SetParameterValue("TextColor", WebColors.Crimson); 

EndProcedure

&AtServer
Procedure AddDataCompositionFields(ElementCA, ChildItems, ExceptingFields = "")
	For Each ChildItem IN ChildItems Do
		If TypeOf(ChildItem) = Type("FormField") Then
			If Find(ExceptingFields, ChildItem.Name) > 0 Then
				Continue;
			EndIf;
 			FieldAppearance = ElementCA.Fields.Items.Add(); // Fields of the table with CA 
			FieldAppearance.Field = New DataCompositionField(ChildItem.Name); 
 			FieldAppearance.Use = True; 
		ElsIf TypeOf(ChildItem) = Type("FormGroup") Then
			AddDataCompositionFields(ElementCA, ChildItem.ChildItems, ExceptingFields);
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure UndoTransactionAtServer()
	//Save current data in BankTransactionsUnaccepted for using in case of failure
	CurrentTransactionsAccepted = Object.BankTransactionsAccepted.Unload();
	Transactions = Object.BankTransactionsAccepted.FindRows(New Structure("Unaccept", True));
	Try
	BeginTransaction();
	i = 0;
	BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
	While i < Transactions.Count() Do
		Tran = Transactions[i];
		If ValueIsFilled(Tran.Document) then
			NewCheck		= Tran.Document.GetObject();
			NewCheck.Write(DocumentWriteMode.UndoPosting);
			NewCheck.SetDeletionMark(True);
		EndIf;
				
		Tran.Document				= Documents.Check.EmptyRef();
		
		//Add (save) current row to an information register
		BTRecordset.Clear();
		BTRecordset.Filter.TransactionDate.Set(Tran.TransactionDate);
		BTRecordset.Filter.BankAccount.Set(Tran.BankAccount);
		BTRecordset.Filter.Company.Set(Tran.Company);
		If NOT ValueIsFilled(Tran.TransactionID) then
			Tran.TransactionID = New UUID();
			BTRecordset.Filter.ID.Set(New UUID("00000000-0000-0000-0000-000000000000"));
			BTRecordset.Write(True);
		EndIf;
		BTRecordset.Filter.ID.Set(Tran.TransactionID);
		NewRecord = BTRecordset.Add();
		FillPropertyValues(NewRecord, Tran);
		NewRecord.Accepted 	= False;
		NewRecord.ID		= Tran.TransactionID;
		BTRecordset.Write(True);
		
		Object.BankTransactionsAccepted.Delete(Object.BankTransactionsAccepted.IndexOf(Tran));
		NewUnaccepted = Object.BankTransactionsUnaccepted.Add();
		FillPropertyValues(NewUnaccepted, NewRecord);
		NewUnaccepted.TransactionID = NewRecord.ID;
		NewUnaccepted.Hidden 		= False;
		NewUnaccepted.Hide 			= "Hide";
		NewUnaccepted.AssigningOption 	= GetAssigningOption(NewUnaccepted.Document, NewUnaccepted.DocumentPresentation);
		i = i + 1;
	EndDo;
		
	Except
	    ErrDesc	= ErrorDescription();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		Object.BankTransactionsAccepted.Load(CurrentTransactionsAccepted);
		CommonUseClientServer.MessageToUser(ErrDesc);
		Return;
	EndTry;		
	
	CommitTransaction();
	
	//UploadTransactionsFromDB(True, False);
	Object.BankTransactionsUnaccepted.Sort("TransactionDate DESC, Description, Company, Category, TransactionID");
EndProcedure

&AtServerNoContext
Procedure DeleteTransactionAtServer(TranID)
	BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
	BTRecordset.Filter.ID.Set(TranID);
	BTRecordset.Write(True);
EndProcedure

//Tries to find an existing document
//If description contains a keyword, 
//then compares document number and amount with the parameters
&AtServerNoContext
Function FindAnExistingDocument(Val Description, Val Amount)
	keywords = New Array;
	keywords.Add("CHECK");
	keyFound = False;
	UDescription = Upper(Description);
	For Each keyword In keywords Do
		If Find(UDescription, keyword) > 0 Then
			keyFound = True;
		EndIf;
	EndDo;
	If Not keyFound Then
		Return Undefined;
	EndIf;
	lexemes = StringFunctionsClientServer.SplitStringIntoSubstringArray(Description, " ");
	//delete 1- to 3- letter words
	i = 0;
	While i < lexemes.Count() Do
		If StrLen(lexemes[i]) < 4 Then
			lexemes.Delete(i);
		Else
			//Delete # and № symbols
			lexemes[i] = StrReplace(lexemes[i], "#", "");
			lexemes[i] = StrReplace(lexemes[i], "№", "");
			For Each keyword In keywords Do
				lexemes[i] = StrReplace(lexemes[i], keyword, "");
			EndDo;
			i = i + 1;
		EndIf;
	EndDo;
	
	ThisIsDeposit = False;
	If Amount >= 0 Then 
		ThisIsDeposit = True;
	Else
		Amount = -1 * Amount;
	EndIf;
	
	If Not ThisIsDeposit Then
		StartQuery = "SELECT
	            |	Check.Ref,
	            |	Check.Number AS Number,
	            |	Check.DocumentTotalRC
	            |INTO AvailableChecks
	            |FROM
	            |	Document.Check AS Check
	            |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	            |		ON (BankTransactions.Document = Check.Ref)
	            |WHERE
	            |	BankTransactions.Document IS NULL 
	            |
	            |UNION ALL
	            |
	            |SELECT
	            |	InvoicePayment.Ref,
	            |	InvoicePayment.Number,
	            |	InvoicePayment.DocumentTotalRC
	            |FROM
	            |	Document.InvoicePayment AS InvoicePayment
	            |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	            |		ON InvoicePayment.Ref = BankTransactions.Document
	            |WHERE
	            |	BankTransactions.Document IS NULL 
	            |
	            |INDEX BY
	            |	Number
	            |;
	            |
	            |////////////////////////////////////////////////////////////////////////////////
	            |SELECT TOP 1
	            |	PossibleChecks.Ref,
	            |	PossibleChecks.Number AS Number,
	            |	PossibleChecks.Priority AS Priority
	            |FROM
	            |	(";
		EndQuery = ") AS PossibleChecks
	            |
	            |GROUP BY
	            |	PossibleChecks.Ref,
	            |	PossibleChecks.Number,
	            |	PossibleChecks.Priority
	            |
	            |ORDER BY
	            |	Priority DESC,
	            |	Number";
	Else //Deposit
		StartQuery = "SELECT
	            |	CashReceipt.Ref,
	            |	CashReceipt.RefNum AS Number,
	            |	CashReceipt.DocumentTotalRC
	            |INTO AvailableChecks
	            |FROM
	            |	Document.CashReceipt AS CashReceipt
	            |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	            |		ON CashReceipt.Ref = BankTransactions.Document
	            |WHERE
	            |	BankTransactions.Document IS NULL 
	            |	AND CashReceipt.DepositType = ""1""
	            |
	            |INDEX BY
	            |	Number
	            |;
	            |
	            |////////////////////////////////////////////////////////////////////////////////
	            |SELECT TOP 1
	            |	PossibleChecks.Ref,
	            |	PossibleChecks.Number AS Number,
	            |	PossibleChecks.Priority AS Priority
	            |FROM
	            |	(";
		EndQuery = ") AS PossibleChecks
	            |
	            |GROUP BY
	            |	PossibleChecks.Ref,
	            |	PossibleChecks.Number,
	            |	PossibleChecks.Priority
	            |
	            |ORDER BY
	            |	Priority DESC,
	            |	Number";
	EndIf;
			
				
	QueryText = "SELECT
	            |	CashReceipt.Ref,
	            |	CashReceipt.RefNum AS Number,
	            |	CashReceipt.DocumentTotalRC
	            |INTO AvailableChecks
	            |FROM
	            |	Document.CashReceipt AS CashReceipt
	            |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	            |		ON CashReceipt.Ref = BankTransactions.Document
	            |WHERE
	            |	BankTransactions.Document IS NULL 
	            |	AND CashReceipt.DepositType = ""Undeposited""
	            |
	            |INDEX BY
	            |	Number
	            |;
	            |
	            |////////////////////////////////////////////////////////////////////////////////
	            |SELECT TOP 1
	            |	PossibleChecks.Ref,
	            |	PossibleChecks.Number AS Number,
	            |	PossibleChecks.Priority AS Priority
	            |FROM
	            |	(SELECT
	            |		AvailableChecks.Ref AS Ref,
	            |		AvailableChecks.Number AS Number,
	            |		1 AS Priority
	            |	FROM
	            |		AvailableChecks AS AvailableChecks
	            |	WHERE
	            |		AvailableChecks.Number LIKE &lexem1
	            |		AND AvailableChecks.DocumentTotalRC = &Amount
	            |	
	            |	UNION ALL
	            |	
	            |	SELECT
	            |		AvailableChecks.Ref,
	            |		AvailableChecks.Number,
	            |		2
	            |	FROM
	            |		AvailableChecks AS AvailableChecks
	            |	WHERE
	            |		AvailableChecks.Number LIKE &lexem2) AS PossibleChecks
	            |
	            |GROUP BY
	            |	PossibleChecks.Ref,
	            |	PossibleChecks.Number,
	            |	PossibleChecks.Priority
	            |
	            |ORDER BY
	            |	Priority DESC,
	            |	Number";
				
	QueryCheck	= New Query;
	QueryText = StartQuery;
	For i = 0 To lexemes.Count()-1 Do
		If i <> 0 Then			
			QueryText = QueryText + "
			|UNION ALL
			|";			
		EndIf;
		QueryText = QueryText + "
				|SELECT
	            |	AvailableChecks.Ref,
				|	AvailableChecks.Number AS Number,
	            |	" + String(StrLen(lexemes[i])) + " AS Priority
	            |FROM
	            |	AvailableChecks AS AvailableChecks
	            |WHERE
				|	AvailableChecks.DocumentTotalRC = &Amount
	            |	AND AvailableChecks.Number LIKE " + "&lexem" + String(i+1);	
		QueryCheck.SetParameter("lexem" + String(i+1), "%" + lexemes[i]);
	EndDo;
	
	QueryText = QueryText + EndQuery;
	QueryCheck.Text = QueryText;
	QueryCheck.SetParameter("Amount", Amount);
	Selection = QueryCheck.Execute().Choose();	
	If Selection.Next() Then
		Return Selection.Ref;
	Else
		Return Undefined;
	EndIf;
				
EndFunction

//Returns bank account reference and Yodlee attribute
//
//Parameters:
// Account - account from chart of accounts
// 
//Result:
// Structure
// BankAccount - bank account assigned to this account
// Yodlee - boolean. If True - then it is Yodlee-integrated bank account
//
//&AtServerNoContext
//Function CheckIfYodlee(Account)
//	ReturnStructure = New Structure("BankAccount, Yodlee");
//	
//	Request = New Query("SELECT ALLOWED
//						|	BankAccounts.Ref,
//						|	BankAccounts.YodleeAccount
//						|FROM
//						|	Catalog.BankAccounts AS BankAccounts
//						|WHERE
//						|	BankAccounts.AccountingAccount = &Account");
//	Request.SetParameter("Account", Account);
//	ReqSelection = Request.Execute().Choose();
//	If ReqSelection.Next() Then
//		ReturnStructure.BankAccount = ReqSelection.Ref;
//		ReturnStructure.Yodlee = ReqSelection.YodleeAccount;
//	Else
//		ReturnStructure.BankAccount = Catalogs.BankAccounts.EmptyRef();
//		ReturnStructure.Yodlee = false;
//	EndIf;
//	return ReturnStructure;
//EndFunction

////////////////////////////////////////////////////////////////////////////////
// FORM COMMAND HANDLERS

&AtClient
Procedure InvertUnaccepted()
	For Each Tran In Object.BankTransactionsUnaccepted Do
		Tran.Accept = ?(Tran.Accept, False, True);
	EndDo;
EndProcedure

&AtClient
Procedure UnmarkAllUnaccepted()
	For Each Tran In Object.BankTransactionsUnaccepted Do
		Tran.Accept = False;
	EndDo;
EndProcedure

&AtClient
Procedure MarkAllUnaccepted()
	For Each Tran In Object.BankTransactionsUnaccepted Do
		Tran.Accept = True;
	EndDo;
EndProcedure

&AtClient
Procedure AcceptTransactions(Command)
	If Not CheckDataFill() Then
		Return;
	EndIf;
	AcceptTransactionsAtServer();
EndProcedure

&AtClient
Procedure SaveUnaccepted(Command)
	SaveUnacceptedAtServer();
	SetModificationState(False);
EndProcedure

&AtClient
Procedure AskSave()
	If ThisForm.Modified then
		Mode = QuestionDialogMode.YesNo;
		Notify = New NotifyDescription("SaveOrNotResult", ThisObject);
		If QuestionAsked = Undefined then
			QuestionAsked = False;
		EndIf;
		If Not QuestionAsked then
			ShowQueryBox(Notify, "The list of transactions is modified. Do you want to save your work before the refresh?", Mode, 0);
			QuestionAsked = True;
		EndIf;
	Else
		UploadTransactionsFromDB();
		SetModificationState(False);
		ApplyHiddenTransactionsAppearance();
	EndIf;
EndProcedure

&AtClient
Procedure SaveOrNotResult(Result, Parameters) Export
	QuestionAsked = False;
   	If Result = DialogReturnCode.Yes Then
		SaveUnacceptedAtServer();        
    EndIf;
	UploadTransactionsFromDB();
	SetModificationState(False);
	ApplyHiddenTransactionsAppearance();
EndProcedure

&AtClient
Procedure RefreshAll(Command)
	AskSave();
EndProcedure

&AtClient
Procedure UndoTransaction(Command)
	UndoTransactionAtServer();
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// SERVER EVENT HANDLERS

////////////////////////////////////////////////////////////////////////////////
// FORM ITEMS HANDLERS

&AtClient
Procedure UploadFromCSVOnChange()
	If Object.UploadFromCSV then
		Items.CSV_Filename.Visible = True;
	Else
		Items.CSV_Filename.Visible = False;
	EndIf;
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	If Clone then
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure BankAccountOnChange(Item)
	Items.BankAccountRefreshedOn.Title = "";
	Object.BankAccount = CommonUse.GetAttributeValue(AccountInBank, "AccountingAccount");
	If Not ValueIsFilled(Object.BankAccount) Then
		AccountInBank = PredefinedValue("Catalog.BankAccounts.EmptyRef");
		ShowMessageBox(, "Selected account doesn't have corresponding accounting account. Please, fill it in on the accounting tab in bank account form",,"Downloaded transactions");
		return;
	EndIf;
	AccountLastUpdated = ToLocalTime(CommonUse.GetAttributeValue(AccountInBank, "LastUpdatedTimeUTC"));
	Items.BankAccountRefreshedOn.Title = "Refreshed on: " + Format(AccountLastUpdated, "DLF=DT");
	RestoreModificationState();
	AskSave();
	
	YodleeAccount	= CommonUse.GetAttributeValue(AccountInBank, "YodleeAccount");
	
	If YodleeAccount Then
		Items.CSV_Filename.Visible = False;
		Items.RefreshTransactions.Visible = True;
	EndIf;
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedOnChange(Item)
	//SetModificationState(True);
	RecordTransactionToTheDatabase(Items.BankTransactionsUnaccepted.CurrentData);
EndProcedure

&AtClient
Procedure RecordTransactionToTheDatabase(Transaction)
	Tran = New Structure;
	Tran.Insert("ID", Transaction.TransactionID);
	Tran.Insert("TransactionDate", Transaction.TransactionDate);
	Tran.Insert("BankAccount", Transaction.BankAccount);
	Tran.Insert("Company", Transaction.Company);
	Tran.Insert("Description", Transaction.Description);
	Tran.Insert("Amount", Transaction.Amount);
	Tran.Insert("Category", Transaction.Category);
	Tran.Insert("Document", Transaction.Document);
	Tran.Insert("Hidden", Transaction.Hidden);
	Tran.Insert("Accepted", False);
	Tran.Insert("OriginalID", Transaction.OriginalID);
	Tran.Insert("YodleeTransactionID", Transaction.YodleeTransactionID);
	Tran.Insert("PostDate", Transaction.PostDate);
	Tran.Insert("Price", Transaction.Price);
	Tran.Insert("Quantity", Transaction.Quantity);
	Tran.Insert("RunningBalance", Transaction.RunningBalance);
	Tran.Insert("CurrencyCode", Transaction.CurrencyCode);
	Tran.Insert("CategoryName", Transaction.CategoryName);
	Tran.Insert("Type", Transaction.Type);
	TransactionID = SaveTransactionAtServer(Tran);
	Transaction.TransactionID = TransactionID;
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedAssigningOpening(Item, StandardProcessing)
	StandardProcessing = False;
	CurrentDocument = Items.BankTransactionsUnaccepted.CurrentData.Document;
	If Not ValueIsFilled(CurrentDocument) Then
		Return;
	EndIf;
	ShowValue(,CurrentDocument);
EndProcedure

&AtClient
Procedure ShowHiddenOnChange(Item)
	ApplyHiddenTransactionsAppearance();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	ApplyHiddenTransactionsAppearance();
EndProcedure

&AtClient
Procedure DeleteTransaction(Command)
	TranID = Items.BankTransactionsUnaccepted.CurrentData.TransactionID;
	CurRow = Object.BankTransactionsUnaccepted.FindByID(Items.BankTransactionsUnaccepted.CurrentRow);
	If Not ValueIsFilled(TranID) Then
		Object.BankTransactionsUnaccepted.Delete(Object.BankTransactionsUnaccepted.IndexOf(CurRow));
	//Should ask the user whether to delete or not
	Else 
		Mode = QuestionDialogMode.YesNoCancel;
		Params = New Structure;
		Params.Insert("TranID", TranID);
		Params.Insert("RowID", Items.BankTransactionsUnaccepted.CurrentRow);
		Notify = New NotifyDescription("DeleteOrNotResult", ThisObject, Params);
		If QuestionAsked = Undefined then
			QuestionAsked = False;
		EndIf;
		If Not QuestionAsked then
			ShowQueryBox(Notify, "The current transaction will be removed from the database permanently. Continue?", Mode, 0, DialogReturnCode.Cancel, "Downloaded transactions");
			QuestionAsked = True;
		EndIf;
		//DeleteTransactionAtServer(TranID);
	EndIf;
EndProcedure

&AtClient
Procedure DeleteOrNotResult(Result, Parameters) Export
	QuestionAsked = False;
	If Result = DialogReturnCode.Yes Then
		If TypeOf(Parameters) = Type("Structure") Then
			DeleteTransactionAtServer(Parameters.TranID);
			CurRow = Object.BankTransactionsUnaccepted.FindByID(Parameters.RowID);
			Object.BankTransactionsUnaccepted.Delete(Object.BankTransactionsUnaccepted.IndexOf(CurRow));
		EndIf;
    EndIf;
	SetModificationState(False);
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	DeleteTransaction(Undefined);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// OTHER FUNCTIONS

&AtClient
Procedure SetModificationState(State)
	FormIsModified = State;
	ThisForm.Modified = FormIsModified;
EndProcedure

&AtClient
Procedure RestoreModificationState()
	If FormIsModified = Undefined then
		FormIsModified = False;
	EndIf;
	If Not FormIsModified Then
		ThisForm.Modified = False;
	EndIf;
EndProcedure

&AtClient
Procedure CSV_FilenameStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(AccountInBank) Then
		CommonUseClientServer.MessageToUser("Please, fill in bank account",, "AccountInBank");
		Return;
	ElsIf Not ValueIsFilled(Object.BankAccount) Then
		CommonUseClientServer.MessageToUser("Please, fill accounting account in on the accounting tab in bank account form",, "AccountInBank");
		Return;
	EndIf;
	
	//InstallFileSystemExtension();
	//If Not AttachFileSystemExtension() Then
	//	CommonUseClientServer.MessageToUser("File system extension is not installed");
	//	Return;
	//EndIf;
	If AttachFileSystemExtension() Then
		FileDialog = New FileDialog(FileDialogMode.Open);
	
		FileDialog.Filter								= NStr("en='CSV file (*.csv)|*.csv'");
		FileDialog.Title			                   	= "Select CSV file";
		FileDialog.Preview								= False;
		FileDialog.DefaultExt							= "csv";
		FileDialog.FilterIndex							= 0;
		FileDialog.FullFileName							= Item.EditText;
		FileDialog.CheckFileExist						= False;
	
		If FileDialog.Choose() Then
			CSV_Filename = FileDialog.FullFileName;
			Object.CSV_Filename = CSV_Filename;
		Else
			Return;
		EndIf;
	EndIf;

	If Not AttachFileSystemExtension() Then
		CSV_Filename = "";
		//CommonUseClientServer.MessageToUser("File system extension is not installed");
		//Return;
	Else
		UplFile = New File(CSV_Filename);
		If UplFile.Exist() = False Then
			TextMessage = NStr("en = 'File %CSV_Filename% does not exist!'");
			TextMessage = StrReplace(TextMessage, "%CSV_Filename%", CSV_Filename);
			CommonUseClientServer.MessageToUser(TextMessage);
			Return;
		EndIf;
	EndIf;
	
	Try
		SourceText.Read(CSV_Filename);
	Except
		TextMessage = NStr("en = 'Can not read the file.'");
		CommonUseClientServer.MessageToUser(TextMessage);
		Return;
	EndTry;

	LineCountTotal = SourceText.LineCount();
	
	For LineNumber = 1 To LineCountTotal Do
		
		CurrentLine 	= SourceText.GetLine(LineNumber);
		ValuesArray 	= StringFunctionsClientServer.SplitStringIntoSubstringArray(CurrentLine, ",");
		ColumnsCount 	= ValuesArray.Count();
		
		If ColumnsCount < 1 Or ColumnsCount > 3 Then
			Continue;
		EndIf;
		
		//Convert date
		TransactionDate = '00010101';
		DateParts = StringFunctionsClientServer.SplitStringIntoSubstringArray(ValuesArray[0], "/");
		If DateParts.Count() = 3 then
			Try
				TransactionDate 	= Date(DateParts[2], DateParts[0], DateParts[1]);
			Except
			EndTry;				
		EndIf;
		If (Not ValueIsFilled(TransactionDate)) OR (TransactionDate < Object.ProcessingPeriod.StartDate) OR (TransactionDate > Object.ProcessingPeriod.EndDate) Then
			TextMessage = "The following bank transaction: " + Format(TransactionDate, "DLF=D") + "; " + ValuesArray[1] + "; " + ValuesArray[2] + " does not belong to the processing period";
			CommonUseClientServer.MessageToUser(TextMessage);
			Continue;
		EndIf;
		NewRow = Object.BankTransactionsUnaccepted.Add();
		NewRow.TransactionDate 	= TransactionDate;
		NewRow.Description 		= ValuesArray[1];
		NewRow.Amount 			= ValuesArray[2];
		NewRow.BankAccount 		= AccountInBank;
		NewRow.Hide 			= "Hide";
		
		//Try to match an uploaded transaction with an existing document
		DocumentFound = FindAnExistingDocument(NewRow.Description, NewRow.Amount);
		If DocumentFound <> Undefined Then
			NewRow.Document 		= DocumentFound;
		EndIf;
		NewRow.AssigningOption 	= GetAssigningOption(NewRow.Document, String(DocumentFound));
		
		//Record new item to the database
		RecordTransactionToTheDatabase(NewRow);
		
	EndDo;
	
	Object.BankTransactionsUnaccepted.Sort("TransactionDate DESC, Description, Company, Category, TransactionID");
	
EndProcedure

&AtClient
Function CheckDataFill()
	Result = True;
	For Each CurTran In Object.BankTransactionsUnaccepted Do
		If Not CurTran.Accept Then
			Continue;
		EndIf;
		If Not ValueIsFilled(CurTran.TransactionDate) Then
			Result = False;
			MessageToTheUser("TransactionDate", "Date", CurTran.LineNumber);	
		EndIf;
		If Not ValueIsFilled(CurTran.BankAccount) Then
			Result = False;
			MessageToTheUser("BankAccount", "BankAccount", CurTran.LineNumber);	
		EndIf;
		If Not ValueIsFilled(CurTran.Description) Then
			Result = False;
			MessageToTheUser("Description", "Description", CurTran.LineNumber);	
		EndIf;
		If Not ValueIsFilled(CurTran.Amount) Then
			Result = False;
			MessageToTheUser("Amount", "Amount", CurTran.LineNumber);	
		EndIf;
		If Not ValueIsFilled(CurTran.Category) Then
			Result = False;
			MessageToTheUser("Category", "Category", CurTran.LineNumber);	
		EndIf;
	EndDo;
	Return Result;
EndFunction

&AtClient 
Procedure MessageToTheUser(FieldID, FieldRepresentation, RowNumber)
	MessOnError = New UserMessage();
	MessOnError.SetData(Object);
	MessOnError.Field = "Object.BankTransactionsUnaccepted[" + String(RowNumber-1) + "]." + FieldID;
	MessOnError.Text  = "Field """ + FieldRepresentation + """ in row №" + String(RowNumber) + " is not filled";
	MessOnError.Message();
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedAssigningChoiceProcessing(Item, SelectedValue, StandardProcessing)
	If SelectedValue = "Assign" Then
		Items.BankTransactionsUnaccepted.CurrentData.Document = Undefined;
		Return;
	ElsIf SelectedValue = "Match" Then
		SelectedValue = "Assign";
		If Items.BankTransactionsUnaccepted.CurrentData.Amount < 0 Then
			OpenForm("Document.Check.ChoiceForm", , Item);	
		Else
			CashReceiptFilter 	= New Structure("DepositType", "1");//Undeposited
			CashReceiptParams	= New Structure("Filter", CashReceiptFilter);
			OpenForm("Document.CashReceipt.ChoiceForm", CashReceiptParams, Item);	
		EndIf;
	ElsIf ValueIsFilled(SelectedValue) Then 
		StandardProcessing = True;
		Items.BankTransactionsUnaccepted.CurrentData.Document = SelectedValue;
		Items.BankTransactionsUnaccepted.CurrentData.AssigningOption 	= GetAssigningOption(SelectedValue, String(SelectedValue));
		Items.BankTransactionsUnacceptedAssigning.ChoiceList.Add(Items.BankTransactionsUnaccepted.CurrentData.AssigningOption);
		SelectedValue = Items.BankTransactionsUnaccepted.CurrentData.AssigningOption;
		RecordTransactionToTheDatabase(Items.BankTransactionsUnaccepted.CurrentData);
	EndIf;	
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedSelection(Item, SelectedRow, Field, StandardProcessing)
	If Field.Name = "BankTransactionsUnacceptedHide" Then
		If Item.CurrentData.Hide = "Hide" Then
			Item.CurrentData.Hide 	= "Show";
			Item.CurrentData.Hidden	= True;
			RecordTransactionToTheDatabase(Item.CurrentData);
			ApplyHiddenTransactionsAppearance();
		Else
			Item.CurrentData.Hide = "Hide";
			Item.CurrentData.Hidden	= False;
			RecordTransactionToTheDatabase(Item.CurrentData);
		EndIf;
	ElsIf Field.Name = "BankTransactionsUnacceptedAssigning" Then
		ChoiceList = Items.BankTransactionsUnacceptedAssigning.ChoiceList;
		ChoiceList.Clear();
		If ValueIsFilled(Items.BankTransactionsUnaccepted.CurrentData.Document) Then
			ChoiceList.Add(Items.BankTransactionsUnaccepted.CurrentData.AssigningOption);
		EndIf;
		ChoiceList.Add("Assign");
		ChoiceList.Add("Match");
	EndIf;
EndProcedure

&AtClient
Procedure ApplyHiddenTransactionsAppearance()
	i = 0;
	If ShowHidden = "Hide" Then
		While i < Object.BankTransactionsUnaccepted.Count() Do
			Tran 	= Object.BankTransactionsUnaccepted[i];
			If Not Tran.Hidden Then
				i = i + 1;
				Continue;
			EndIf;
			NewHiddenTran 	= Object.HiddenTransactionsUnaccepted.Add();
			FillPropertyValues(NewHiddenTran, Tran);
			Object.BankTransactionsUnaccepted.Delete(i);
		EndDo;
	ElsIf ShowHidden = "Show" Then
		While i < Object.HiddenTransactionsUnaccepted.Count() Do
			HiddenTran 		= Object.HiddenTransactionsUnaccepted[i];
			Tran 			= Object.BankTransactionsUnaccepted.Add();
			FillPropertyValues(Tran, HiddenTran);
			Tran.AssigningOption 	= GetAssigningOption(Tran.Document, String(Tran.Document));
			Tran.Hide 		= "Show";
			Object.HiddenTransactionsUnaccepted.Delete(i);
		EndDo;
		Object.BankTransactionsUnaccepted.Sort("TransactionDate DESC, Description, Company, Category, TransactionID");
	EndIf;		
EndProcedure

&AtClientAtServerNoContext
Function GetAssigningOption(Document, DocumentPresentation)
	If ValueIsFilled(Document) Then
		//Return "Assigned to " + DocumentPresentation;
		Return String(DocumentPresentation);
	Else
		Return "Assign";
	EndIf;
EndFunction

&AtClient
Procedure RefreshTransactions(Command)
	If Not YodleeAccount Then
		return;		
	EndIf;
	
	Notify = New NotifyDescription("OnComplete_RefreshTransactions", ThisObject);
	Params = New Structure("PerformRefreshingAccount, RefreshAccount", True, AccountInBank);
	OpenForm("DataProcessor.YodleeBankAccountsManagement.Form.Form", Params, ThisForm,,,, Notify, FormWindowOpeningMode.LockWholeInterface);
	return;
	ReturnStructure = RefreshTransactionsAtServer();
	If Not ReturnStructure.ReturnValue Then
		ShowMessageBox(, ReturnStructure.ErrorMessage,, "Refreshing transactions");
	EndIf;
EndProcedure

&AtClient
Procedure OnComplete_RefreshTransactions(ClosureResult, AdditionalParameters) Export
	AccountLastUpdated = ToLocalTime(CommonUse.GetAttributeValue(AccountInBank, "LastUpdatedTimeUTC"));
	Items.BankAccountRefreshedOn.Title = "Refreshed on: " + Format(AccountLastUpdated, "DLF=DT");	
	RefreshTransactionsAtServer();
EndProcedure

&AtServer
Function RefreshTransactionsAtServer()
	ReturnStructure = Yodlee.ViewTransactions(AccountInBank, Object.ProcessingPeriod.StartDate, Object.ProcessingPeriod.EndDate);
	If ReturnStructure.ReturnValue Then
		UploadTransactionsFromDB();
	EndIf;
	return ReturnStructure;
EndFunction
