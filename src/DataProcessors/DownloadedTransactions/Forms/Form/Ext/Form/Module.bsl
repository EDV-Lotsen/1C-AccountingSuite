////////////////////////////////////////////////////////////////////////////////
// Bank transaction processing form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

&AtClient
Var QuestionAsked, BankingGLAccounts;

#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// control visibility of the 'upload period' group
	If Constants.show_yodlee_upload_period.Get() = True Then
		Items.Group2.Visible = True
	Else
		Items.Group2.Visible = False
	EndIf;

	//Variables initiation
	ShowHidden	= "Hide";
	Object.ProcessingPeriod.Variant	=StandardPeriodVariant.Month;
	Items.DecorationProcessingPeriod.Title = Format(Object.ProcessingPeriod.StartDate, "DLF=DD") + " - " + Format(Object.ProcessingPeriod.EndDate, "DLF=DD");
	
	//Filling AccountInBank field.
	If ValueIsFilled(Parameters.BankAccount) Then
		AccountInBank = Parameters.BankAccount;
	Else
		FillAvailableAccount();	
	EndIf;
	If ValueIsFilled(AccountInBank) Then
		//Fill in bank transactions
		BankAccountOnChangeAtServer();
	EndIf;
	
	ApplyConditionalAppearance();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	//Not necessary, but otherwise an error occures on Hide/Show hidden rows
	AttachIdleHandler("ApplyHiddenTransactionsAppearance", 0.1, True);
	//ApplyHiddenTransactionsAppearance();
	
	//If bank transactions of the current bank account are being edited from a different session, inform the user about it.
	If ValueIsFilled(AccountInBank) Then
		If Not BankTransactionsLocked Then
			ArrayOfMessages = New Array();
			ArrayOfMessages.Add(PictureLib.Warning32);
			ArrayOfMessages.Add("    Bank transactions of the current bank account are being edited in a different session. Data is available for viewing only.");
			ShowMessageBox(, New FormattedString(ArrayOfMessages),,"Cloud banking");
		Else
			PreviousAccountInBank = AccountInBank;
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure OnClose()
	OnCloseAtServer();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "DeletedBankAccount" Then //Deleted online bank account
		DeletedAccount = Parameter;
		If AccountInBank = DeletedAccount Then
			Object.BankTransactionsUnaccepted.Clear();
			Object.BankTransactionsAccepted.Clear();
			Object.HiddenTransactionsUnaccepted.Clear();
			AccountInBank = PredefinedValue("Catalog.BankAccounts.EmptyRef");
			AccountLastUpdated = "";
			AccountingBalance = 0;
			AccountAvailableBalance = 0;
			FillAvailableAccount();
			BankAccountOnChange();
		EndIf;
	ElsIf EventName = "BankTransactionsMerge" Then
		BankAccountOnChange();
	EndIf;
EndProcedure
#EndRegion

#REGION FORM_SERVER_FUNCTIONS
////////////////////////////////////////////////////////////////////////////////
// FORM SERVER FUNCTIONS

&AtServer
Procedure UploadTransactionsFromDB(SelectUnaccepted = True, SelectAccepted = True, MatchDepositDocuments = True, MatchCheckDocuments = True)
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
	                               |	BankTransactions.YodleeTransactionID AS YodleeTransactionID,
	                               |	BankTransactions.PostDate,
	                               |	BankTransactions.Price,
	                               |	BankTransactions.Quantity,
	                               |	BankTransactions.RunningBalance,
	                               |	BankTransactions.CurrencyCode,
	                               |	BankTransactions.CategoryID,
	                               |	BankTransactions.Class,
	                               |	BankTransactions.Project,
	                               |	BankTransactions.Type,
	                               |	ISNULL(BankTransactionCategories.Description, ""Uncategorized"") AS CategoryDescription,
	                               |	ISNULL(BankTransactionCategories.Account, VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef)) AS CategoryAccount,
	                               |	ISNULL(BankTransactionCategories.Ref, VALUE(Catalog.BankTransactionCategories.EmptyRef)) AS CategoryRef,
	                               |	BankTransactions.CategorizedCompanyNotAccepted,
	                               |	BankTransactions.CategorizedCategoryNotAccepted
	                               |FROM
	                               |	InformationRegister.BankTransactions AS BankTransactions
	                               |		LEFT JOIN Catalog.BankTransactionCategories AS BankTransactionCategories
	                               |		ON BankTransactions.CategoryID = BankTransactionCategories.Code
	                               |WHERE
	                               |	(BankTransactions.BankAccount = &BankAccount
	                               |			OR &BankAccount = VALUE(Catalog.BankAccounts.EmptyRef))
	                               |
	                               |ORDER BY
	                               |	TransactionDate DESC,
	                               |	YodleeTransactionID DESC,
	                               |	Description,
	                               |	Company,
	                               |	Category");
	TransactionRequest.SetParameter("BankAccount", AccountInBank);
	UploadedTransactions = TransactionRequest.Execute().Unload();
	If SelectUnaccepted then
		Unaccepted 		= UploadedTransactions.FindRows(New Structure("Accepted", False));
		VT_Unaccepted 	= UploadedTransactions.Copy(Unaccepted);
		Object.BankTransactionsUnaccepted.Load(VT_Unaccepted);
		Object.HiddenTransactionsUnaccepted.Clear();
		//Match transfer documents
		FoundTransfers = MatchTransferDocuments(AccountInBank, Object.BankAccount);
		For Each FoundTransfer In FoundTransfers Do
			FoundRows = Object.BankTransactionsUnaccepted.FindRows(New Structure("TransactionID", FoundTransfer.TransactionID));
			For Each FoundRow In FoundRows Do
				FoundRow.Document = FoundTransfer.FoundDocument;
				FoundRow.DocumentPresentation = FoundTransfer.FoundDocumentPresentation;
				FoundRow.AssigningOption 	= GetAssigningOption(FoundRow.Document, FoundRow.DocumentPresentation);
			EndDo;
		EndDo;
		//Fill array of IDs to use it later in matching with Deposit documents
		ArrayOfDepositIDs = New Array();
		ArrayOfCheckIDs = New Array();
		For Each Tran In Object.BankTransactionsUnaccepted Do
			
			//Match the existing documents
			If Not ValueIsFilled(Tran.Document) Then
				//Try to match an uploaded transaction with an existing check document (with payment method="Check") 
				DocumentFound = FindAnExistingDocument(Tran.Description, Tran.Amount, Object.BankAccount);
				If DocumentFound <> Undefined Then
					Tran.Document 		= DocumentFound;
					RecordTransactionToTheDatabaseAtServer(Tran);
				Else
					If Tran.Amount > 0 Then
						ArrayOfDepositIDs.Add(Tran.TransactionID);
					ElsIf Tran.Amount < 0 Then
						ArrayOfCheckIDs.Add(Tran.TransactionID);
					EndIf;						
				EndIf;
				Tran.AssigningOption 	= GetAssigningOption(Tran.Document, String(DocumentFound));
			Else           
				Tran.AssigningOption 	= GetAssigningOption(Tran.Document, Tran.DocumentPresentation);
			EndIf;
		EndDo;
		//Matching with the Deposit documents
		If MatchDepositDocuments Then
			FoundDeposits = MatchDepositDocuments(AccountInBank, Object.BankAccount, ArrayOfDepositIDs);
			For Each FoundDeposit In FoundDeposits Do
				FoundRows = Object.BankTransactionsUnaccepted.FindRows(New Structure("TransactionID", FoundDeposit.TransactionID));
				For Each FoundRow In FoundRows Do
					FoundRow.Document = FoundDeposit.FoundDocument;
					FoundRow.AssigningOption 	= GetAssigningOption(FoundRow.Document, String(FoundRow.Document));
				EndDo;
			EndDo;
		EndIf;
		//Matching with the Invoice payment (Check) and Payment (Check) (with payment method other than "Check")
		If MatchCheckDocuments Then
			FoundChecks = MatchCheckDocuments(AccountInBank, Object.BankAccount, ArrayOfCheckIDs);
			For Each FoundCheck In FoundChecks Do
				FoundRows = Object.BankTransactionsUnaccepted.FindRows(New Structure("TransactionID", FoundCheck.TransactionID));
				For Each FoundRow In FoundRows Do
					FoundRow.Document = FoundCheck.FoundDocument;
					FoundRow.AssigningOption 	= GetAssigningOption(FoundRow.Document, String(FoundRow.Document));
				EndDo;
			EndDo;
		EndIf;
		ThisForm.Modified = False;
		//ApplyConditionalAppearance();
	EndIf;
	If SelectAccepted then
		Accepted 		= UploadedTransactions.FindRows(New Structure("Accepted", True));
		VT_Accepted 	= UploadedTransactions.Copy(Accepted);
		Object.BankTransactionsAccepted.Load(VT_Accepted);
	EndIf;

EndProcedure

&AtServer
Procedure AcceptTransactionsAtServer(Transactions = Undefined, ErrorOccured = Undefined)
	//Save current data in BankTransactionsUnaccepted for using in case of failure
	CurrentTransactionsUnaccepted = Object.BankTransactionsUnaccepted.Unload();
	If Transactions = Undefined Then
		Transactions = Object.BankTransactionsUnaccepted.FindRows(New Structure("Accept", True));
	EndIf;
	Try
	BeginTransaction();
	i = 0;
	BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
	While i < Transactions.Count() Do
		Tran = Transactions[i];
		
		If TypeOf(Tran.Document) = Type("DocumentRef.BankTransfer") Then //Create Bank Transfer
			Tran.Document				= Create_DocumentBankTransfer(Tran);
		ElsIf TypeOf(Tran.Document) = Type("DocumentRef.SalesInvoice") Then
			Tran.Document				= Create_DocumentCashReceipt(Tran);
		ElsIf TypeOf(Tran.Document) = Type("DocumentRef.PurchaseInvoice") Then
			Tran.Document				= Create_DocumentInvoicePayment(Tran);
		ElsIf Tran.Amount < 0 Then //Create Check
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
		BTRecordset.Read();
		If BTRecordset.Count() > 0 Then
			If BTRecordset[0].Accepted Then
				Object.BankTransactionsUnaccepted.Delete(Tran);
				i = i + 1;
				Continue;
			EndIf;
		EndIf;
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
		If ErrorOccured <> Undefined Then
			ErrorOccured = True;
		EndIf;
		Return;
	EndTry;		
	
	CommitTransaction();
	
	UploadTransactionsFromDB(False, True);
	AccountingBalance = GetAccountingSuiteAccountBalance(AccountInBank.AccountingAccount);
EndProcedure

&AtServer
Function Create_DocumentInvoicePayment(Tran)
	PurchaseInvoice = Tran.Document;
	
	NewInvoicePayment 				= Documents.InvoicePayment.CreateDocument();	                                                             
	NewInvoicePayment.Date 			= Tran.TransactionDate;
	NewInvoicePayment.Company 			= PurchaseInvoice.Company;
	NewInvoicePayment.DocumentTotal 	= Tran.Amount;
	NewInvoicePayment.DocumentTotalRC 	= Tran.Amount;
	NewInvoicePayment.BankAccount		= Object.BankAccount;
	NewInvoicePayment.Currency			= Catalogs.Currencies.USD;
	NewInvoicePayment.PaymentMethod		= Catalogs.PaymentMethods.DebitCard;
	NewInvoicePayment.Memo 				= Tran.Description;
	NewInvoicePayment.AutoGenerated		= True;
	
	LineItem = NewInvoicePayment.LineItems.Add();
	LineItem.Document 	= PurchaseInvoice;
	LineItem.Payment 	= -1 * Tran.Amount;
	LineItem.Check 		= True;
	LineItem.Currency	= Catalogs.Currencies.USD;
	
	NewInvoicePayment.Write(DocumentWriteMode.Posting);
	
	Return NewInvoicePayment.Ref;
EndFunction

&AtServer
Function Create_DocumentCashReceipt(Tran)
	SalesInvoice = Tran.Document;
	
	NewCashReceipt 		= Documents.CashReceipt.CreateDocument();	                                                             
	NewCashReceipt.Date 			= Tran.TransactionDate;
	NewCashReceipt.Company 			= SalesInvoice.Company;
	NewCashReceipt.DocumentTotal 	= Tran.Amount;
	NewCashReceipt.CashPayment 		= Tran.Amount;
	NewCashReceipt.DepositType		= "2";
	NewCashReceipt.DocumentTotalRC 	= Tran.Amount;
	NewCashReceipt.BankAccount		= Object.BankAccount;
	NewCashReceipt.Currency			= Catalogs.Currencies.USD;
	NewCashReceipt.ARAccount		= SalesInvoice.ARAccount;
	NewCashReceipt.Memo 				= Tran.Description;
	NewCashReceipt.AutoGenerated		= True;
	
	LineItem = NewCashReceipt.LineItems.Add();
	LineItem.Document 	= SalesInvoice;
	LineItem.Payment 	= Tran.Amount;
	LineItem.Currency	= Catalogs.Currencies.USD;
	
	NewCashReceipt.Write(DocumentWriteMode.Posting);
	
	Return NewCashReceipt.Ref;
EndFunction

&AtServer
Function Create_DocumentBankTransfer(Tran)
	If ValueIsFilled(Tran.Document) then
		return Tran.Document;
	Else
		NewBankTransfer 		= Documents.BankTransfer.CreateDocument();
	EndIf;
	                                                             
	NewBankTransfer.Date 		= Tran.TransactionDate;
	If Tran.Amount < 0 Then
		NewBankTransfer.AccountFrom = Tran.BankAccount.AccountingAccount;
		NewBankTransfer.AccountTo 	= Tran.Category;
		NewBankTransfer.Amount		= -1 * Tran.Amount;
	Else
		NewBankTransfer.AccountFrom = Tran.Category;
		NewBankTransfer.AccountTo 	= Tran.BankAccount.AccountingAccount;
		NewBankTransfer.Amount 		= Tran.Amount;
	EndIf;
	NewBankTransfer.Memo 				= Tran.Description;
	NewBankTransfer.AutoGenerated		= True;
	
	NewBankTransfer.Write(DocumentWriteMode.Posting);
	
	Return NewBankTransfer.Ref;
EndFunction

&AtServer
Function Create_DocumentCheck(Tran)	
	If ValueIsFilled(Tran.Document) then
		If TypeOf(Tran.Document) = Type("DocumentRef.InvoicePayment") Then
			return Tran.Document;
		EndIf;
		If Not DocumentIsAutoGenerated(Tran.Document) Then
			return Tran.Document;
		EndIf;
		
		//Refill only auto-generated documents
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
	NewCheck.Project			= Tran.Project;
	NewCheck.AutoGenerated		= True;
	
	NewCheck.LineItems.Clear();
	NewLine = NewCheck.LineItems.Add();
	NewLine.Account 			= Tran.Category;
	NewLine.Amount 				= -1*Tran.Amount;
	NewLine.Memo 				= Tran.Description;
	NewLine.Class				= Tran.Class;
	NewLine.Project 			= Tran.Project;
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
		If TypeOf(Tran.Document) = Type("DocumentRef.CashReceipt") Then
			return Tran.Document;
		EndIf;
		If Not DocumentIsAutoGenerated(Tran.Document) Then
			return Tran.Document;
		EndIf;
		
		//Refill only auto-generated documents
		NewDeposit		= Tran.Document.GetObject();
	Else
		NewDeposit 		= Documents.Deposit.CreateDocument();
	EndIf;
	NewDeposit.Date 			= Tran.TransactionDate;
	NewDeposit.BankAccount 		= Tran.BankAccount.AccountingAccount;
	NewDeposit.Memo 			= Tran.Description;
	NewDeposit.DocumentTotal 	= Tran.Amount;
	NewDeposit.DocumentTotalRC 	= Tran.Amount;
	NewDeposit.TotalDeposits	= 0;
	NewDeposit.TotalDepositsRC	= 0;
	NewDeposit.AutoGenerated	= True;
		
	NewDeposit.Accounts.Clear();
	NewLine = NewDeposit.Accounts.Add();
	NewLine.Account 			= Tran.Category;
	NewLine.Memo 				= Tran.Description;
	NewLine.Company				= Tran.Company;
	NewLine.Amount 				= Tran.Amount;
	NewLine.Class 				= Tran.Class;
	NewLine.Project 			= Tran.Project;
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
	Try
		BeginTransaction();
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
	Except
		ErrDesc = ErrorDescription();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		CommonUseClientServer.MessageToUser(ErrDesc);
		Return;
	EndTry;
	CommitTransaction();
	ThisForm.Modified = False;
EndProcedure

//Saves current unaccepted transaction being edited in database
//Assigns UUIDs to a new transaction
&AtServerNoContext
Function SaveTransactionAtServer(Tran)
	Try
		BeginTransaction();
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
		CommitTransaction();
	Except
		ErrDesc = ErrorDescription();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		CommonUseClientServer.MessageToUser(ErrDesc);
	EndTry;
		
	Return Tran.ID;
EndFunction

&AtServer
Procedure FillAvailableAccount()
	Request = New Query("SELECT ALLOWED TOP 1
	                    |	BankAccounts.Ref,
	                    |	BankAccounts.Description
	                    |FROM
	                    |	Catalog.BankAccounts AS BankAccounts
	                    |WHERE
	                    |	BankAccounts.DeletionMark = FALSE");
	Res = Request.Execute();
	If NOT Res.IsEmpty() Then
		Sel = Res.Select();
		Sel.Next();
		AccountInBank = Sel.Ref;
	Else
		AccountInBank = Catalogs.BankAccounts.EmptyRef();
	EndIf;
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
	
	//Get catagoryIDs, used category accounts
	
	SetPrivilegedMode(True);
	Request = New Query("SELECT
	                    |	BankTransactionCategories.Code AS CategoryID,
	                    |	BankTransactionCategories.Description AS CategoryDescription
	                    |FROM
	                    |	Catalog.BankTransactionCategories AS BankTransactionCategories");
	UsedCategoriesTable = Request.Execute().Unload();
	SetPrivilegedMode(False);
	i = 0;
	While i < UsedCategoriesTable.Count() Do
		//Show category description if category account is empty
		CR = UsedCategoriesTable[i];
		ElementCA = CA.Items.Add(); 
	
		FieldAppearance = ElementCA.Fields.Items.Add(); 
		FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedCategory"); 
 		FieldAppearance.Use = True; 

		FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
		FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.CategoryID"); 
		FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
		FilterElement.RightValue 		= CR.CategoryID; 
		FilterElement.Use				= True;
		
		FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
		FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Category"); 
		FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
		FilterElement.RightValue 		= ChartsOfAccounts.ChartOfAccounts.EmptyRef(); 
		FilterElement.Use				= True;
		
		ElementCA.Appearance.SetParameterValue("Text", CR.CategoryDescription);
		
		DefaultFont = ElementCA.Appearance.FindParameterValue(New DataCompositionParameter("Font")).Value;
		ItalicFont	=New Font(DefaultFont,,,,True,,); //Italic font
		ElementCA.Appearance.SetParameterValue("Font", ItalicFont); 

		
		i = i + 1;
	EndDo;
	
	//Auto-categorized customers highlight with Italic font
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedCompany"); 
 	FieldAppearance.Use = True; 
	
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.CategorizedCompanyNotAccepted"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= True; 
	FilterElement.Use				= True;
	
	DefaultFont = ElementCA.Appearance.FindParameterValue(New DataCompositionParameter("Font")).Value;
	ItalicFont	=New Font(DefaultFont,,,,True,,); //Italic font
	ElementCA.Appearance.SetParameterValue("Font", ItalicFont); 
	
	//Auto-categorized categories highlight with Italic font
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedCategory"); 
 	FieldAppearance.Use = True; 
	
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.CategorizedCategoryNotAccepted"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= True; 
	FilterElement.Use				= True;
	
	DefaultFont = ElementCA.Appearance.FindParameterValue(New DataCompositionParameter("Font")).Value;
	ItalicFont	=New Font(DefaultFont,,,,True,,); //Italic font
	ElementCA.Appearance.SetParameterValue("Font", ItalicFont); 
	
	//If there are 2 suggested categories highlight category with red color
	//If Yodlee category differs from auto-categorized category highlight with red color
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedCategory"); 
 	FieldAppearance.Use = True; 
	
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Category"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.CategoryAccount"); 
	FilterElement.Use				= True;
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.CategorizedCategoryNotAccepted"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= True; 
	FilterElement.Use				= True;
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Category"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= ChartsOfAccounts.ChartOfAccounts.EmptyRef(); 
	FilterElement.Use				= True;
	
	ElementCA.Appearance.SetParameterValue("TextColor", WebColors.Crimson); 
	
	//If transaction is matched to a document or is a transfer, then make Company, Class and Project columns inavailable
	ElementCA = CA.Items.Add();
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedCompany"); 
 	FieldAppearance.Use = True;
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedClass"); 
 	FieldAppearance.Use = True;	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedProject"); 
 	FieldAppearance.Use = True;
	
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Document"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= Undefined; 
	FilterElement.Use				= True;
			
	ElementCA.Appearance.SetParameterValue("Readonly", True); 
	ElementCA.Appearance.SetParameterValue("BackColor", WebColors.WhiteSmoke); 
	ElementCA.Appearance.SetParameterValue("TextColor", StyleColors.ColorDisabledLabel); 
	
	//If transaction is matched to a document, then make Category column inavailable
	ElementCA = CA.Items.Add();
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedCategory"); 
	FieldAppearance.Use = True;
		
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Document"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= Undefined; 
	FilterElement.Use				= True;
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Document"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= Documents.BankTransfer.EmptyRef(); 
	FilterElement.Use				= True;
			
	ElementCA.Appearance.SetParameterValue("Readonly", True); 
	ElementCA.Appearance.SetParameterValue("BackColor", WebColors.WhiteSmoke); 
	ElementCA.Appearance.SetParameterValue("TextColor", StyleColors.ColorDisabledLabel); 
	
	//If transaction is matched to a document, then display in the Action column "Match" otherwise "Add"
	ElementCA = CA.Items.Add();
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedAction"); 
 	FieldAppearance.Use = True;
	
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Document"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= Undefined; 
	FilterElement.Use				= True;
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Document"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.NotEqual; 
	FilterElement.RightValue 		= Documents.BankTransfer.EmptyRef(); 
	FilterElement.Use				= True;
			
	ElementCA.Appearance.SetParameterValue("Text", "Match"); 
	
	ElementCA = CA.Items.Add();
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedAction"); 
 	FieldAppearance.Use = True;
	
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Document"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= Undefined; 
	FilterElement.Use				= True;
			
	ElementCA.Appearance.SetParameterValue("Text", "Add"); 
	
	ElementCA = CA.Items.Add();
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedAction"); 
 	FieldAppearance.Use = True;
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Document"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= Documents.BankTransfer.EmptyRef(); 
	FilterElement.Use				= True;
			
	ElementCA.Appearance.SetParameterValue("Text", "Transfer"); 
	
	//If bank transactions for the current bank account are locked then make BankTransactionsUnaccepted readonly
	ElementCA = CA.Items.Add();
	
	AddDataCompositionFields(ElementCA, Items.BankTransactionsUnaccepted.ChildItems);
				
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("BankTransactionsLocked"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= False; 
	FilterElement.Use				= True;

	ElementCA.Appearance.SetParameterValue("Readonly", True); 
	ElementCA.Appearance.SetParameterValue("Enabled", False); 
	
	//Make Class and Project columns available only for the current column
	ElementCA = CA.Items.Add();
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedClass"); 
	FieldAppearance.Use = True;
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedProject"); 
	FieldAppearance.Use = True;
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.IsCurrentRow"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= False; 
	FilterElement.Use				= True;
			
	ElementCA.Appearance.SetParameterValue("Visible", False); 
	
	//If transaction is not  matched to a document and not a transfer, display for a Class "Select Class"
	ElementCA = CA.Items.Add();
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedClass"); 
 	FieldAppearance.Use = True;	
		
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Document"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= Undefined; 
	FilterElement.Use				= True;
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Class"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= Catalogs.Classes.EmptyRef(); 
	FilterElement.Use				= True;
	
	ElementCA.Appearance.SetParameterValue("Text", "Select class"); 
	ElementCA.Appearance.SetParameterValue("TextColor", StyleColors.ColorDisabledLabel); 
	
	//If transaction is not  matched to a document and not a transfer, display for a Class "Select Class"
	ElementCA = CA.Items.Add();
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedProject"); 
 	FieldAppearance.Use = True;	
		
 	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Document"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= Undefined; 
	FilterElement.Use				= True;
	
	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
 	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Project"); 
 	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= Catalogs.Projects.EmptyRef(); 
	FilterElement.Use				= True;
	
	ElementCA.Appearance.SetParameterValue("Text", "Select project"); 
	ElementCA.Appearance.SetParameterValue("TextColor", StyleColors.ColorDisabledLabel); 

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
			If DocumentIsAutoGenerated(Tran.Document) Then
				If TypeOf(Tran.Document) = Type("DocumentRef.BankTransfer") Then
					//Transfer documents participate in two transactions
					//Deletion is possible after both of the transactions are unaccepted
					If DeletionOfBankTransferPossible(Tran.Document) Then
						//If this is the last unaccepted transaction
						//then we should remove the document from unaccepted transactions
						RemoveBankTransferFromUnacceptedTransactions(Tran.Document);
						DocumentForDeletion = Tran.Document;
						Tran.Document	= Documents.BankTransfer.EmptyRef();
					EndIf;
				Else
					DocumentForDeletion = Tran.Document;
					If TypeOf(DocumentForDeletion) = Type("DocumentRef.CashReceipt") Then
						Request = New Query("SELECT TOP 1
						                    |	CashReceiptLineItems.Document
						                    |FROM
						                    |	Document.CashReceipt.LineItems AS CashReceiptLineItems
						                    |WHERE
						                    |	CashReceiptLineItems.Payment > 0
						                    |	AND CashReceiptLineItems.Ref = &CashReceipt");
						Request.SetParameter("CashReceipt", DocumentForDeletion);
						Res = Request.Execute();
						If Not Res.IsEmpty() Then
							Sel = Res.Select();
							Sel.Next();
							Tran.Document = Sel.Document;
						Else
							Tran.Document = Undefined;
						EndIf;
					ElsIf TypeOf(DocumentForDeletion) = Type("DocumentRef.InvoicePayment") Then
						Request = New Query("SELECT TOP 1
						                    |	InvoicePaymentLineItems.Document
						                    |FROM
						                    |	Document.InvoicePayment.LineItems AS InvoicePaymentLineItems
						                    |WHERE
						                    |	InvoicePaymentLineItems.Payment > 0
						                    |	AND InvoicePaymentLineItems.Ref = &PurchaseInvoice");
						Request.SetParameter("PurchaseInvoice", DocumentForDeletion);
						Res = Request.Execute();
						If Not Res.IsEmpty() Then
							Sel = Res.Select();
							Sel.Next();
							Tran.Document = Sel.Document;
						Else
							Tran.Document = Undefined;
						EndIf;
					Else
						Tran.Document	= Undefined;
					EndIf;
				EndIf;
			EndIf;
		EndIf;
						
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
		NewUnaccepted.AssigningOption 	= GetAssigningOption(NewUnaccepted.Document, String(NewUnaccepted.Document));
		
		If DocumentIsAutoGenerated(DocumentForDeletion) Then
			CurDocument		= DocumentForDeletion.GetObject();
			CurDocument.Delete();
		EndIf;
		
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
	
	Object.BankTransactionsUnaccepted.Sort("TransactionDate DESC, Description, Company, Category, TransactionID");
	AccountingBalance = GetAccountingSuiteAccountBalance(AccountInBank.AccountingAccount);
EndProcedure

&AtServerNoContext
Function DocumentIsAutoGenerated(Document)
	If (TypeOf(Document) = Type("DocumentRef.Deposit")) 
		Or (TypeOf(Document) = Type("DocumentRef.Check"))
		Or (TypeOf(Document) = Type("DocumentRef.BankTransfer"))
		Or (TypeOf(Document) = Type("DocumentRef.CashReceipt")) 
		Or (TypeOf(Document) = Type("DocumentRef.InvoicePayment")) Then
		return Document.AutoGenerated;
	Else
		return False;
	EndIf;
EndFunction

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
Function FindAnExistingDocument(Val Description, Val Amount, Val AccountingAccount)
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
	            |   AND Check.BankAccount = &AccountingAccount
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
	            |   AND InvoicePayment.BankAccount = &AccountingAccount
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
	            |	AND CashReceipt.BankAccount = &AccountingAccount
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
	QueryCheck.SetParameter("AccountingAccount", AccountingAccount);
	Selection = QueryCheck.Execute().Select();	
	If Selection.Next() Then
		Return Selection.Ref;
	Else
		Return Undefined;
	EndIf;
				
EndFunction

&AtServerNoContext
Function MatchDepositDocuments(Val AccountInBank, Val AccountingAccount, Val ArrayOfIDs)
	
	VT = New ValueTable();
	VT.Columns.Add("ID", New TypeDescription("UUID"));
	
	For Each ItemID In ArrayOfIDs Do
		NewRow = VT.Add();
		NewRow.ID = ItemID;
	EndDo;
	
	BeginTransaction(DataLockControlMode.Managed);
	
	// Create new managed data lock
	DataLock = New DataLock;

	// Set data lock parameters
	// Set shared lock to get consisitent data
	BA_LockItem = DataLock.Add("InformationRegister.BankTransactions");
	BA_LockItem.Mode = DataLockMode.Shared;
	BA_LockItem.SetValue("BankAccount", AccountInBank);
	
	// Set exclusive lock on potentially modifiable records 
	BA_LockItem = DataLock.Add("InformationRegister.BankTransactions");
	BA_LockItem.Mode = DataLockMode.Exclusive;
	BA_LockItem.SetValue("BankAccount", AccountInBank);	
	BA_LockItem.DataSource = VT;
	BA_LockItem.UseFromDataSource("ID", "ID");
	// Set lock on the object
	DataLock.Lock();

	Request = New Query("SELECT ALLOWED
	                    |	BankTransactions.TransactionDate,
	                    |	BankTransactions.ID,
	                    |	BankTransactions.Amount
	                    |INTO UnacceptedTransactionsWithoutDocuments
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |WHERE
	                    |	BankTransactions.BankAccount = &BankAccount
	                    |	AND BankTransactions.Document = UNDEFINED
	                    |	AND BankTransactions.Accepted = FALSE
	                    |	AND BankTransactions.Amount > 0
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	Deposit.Ref,
	                    |	Deposit.Date,
	                    |	Deposit.DocumentTotalRC,
	                    |	Deposit.PointInTime
	                    |INTO AvailableDepositDocuments
	                    |FROM
	                    |	Document.Deposit AS Deposit
	                    |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	                    |		ON Deposit.Ref = BankTransactions.Document
	                    |WHERE
	                    |	BankTransactions.Document IS NULL 
	                    |	AND Deposit.BankAccount = &AccountingAccount
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	UnacceptedTransactionsWithoutDocuments.TransactionDate,
	                    |	UnacceptedTransactionsWithoutDocuments.ID,
	                    |	UnacceptedTransactionsWithoutDocuments.Amount,
	                    |	AvailableDepositDocuments.Ref AS FoundDocument,
	                    |	AvailableDepositDocuments.Date AS DocumentDate,
	                    |	AvailableDepositDocuments.PointInTime AS DocumentPointInTime
	                    |INTO FoundDocuments
	                    |FROM
	                    |	UnacceptedTransactionsWithoutDocuments AS UnacceptedTransactionsWithoutDocuments
	                    |		INNER JOIN AvailableDepositDocuments AS AvailableDepositDocuments
	                    |		ON UnacceptedTransactionsWithoutDocuments.Amount = AvailableDepositDocuments.DocumentTotalRC
	                    |			AND (AvailableDepositDocuments.Date < DATEADD(UnacceptedTransactionsWithoutDocuments.TransactionDate, DAY, 7))
	                    |			AND (AvailableDepositDocuments.Date > DATEADD(UnacceptedTransactionsWithoutDocuments.TransactionDate, DAY, -7))
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	FoundDocuments.TransactionDate AS TransactionDate,
	                    |	FoundDocuments.ID AS TransactionID,
	                    |	FoundDocuments.FoundDocument,
	                    |	FoundDocuments.DocumentPointInTime AS DocumentPointInTime
	                    |FROM
	                    |	FoundDocuments AS FoundDocuments
	                    |
	                    |ORDER BY
	                    |	TransactionDate,
	                    |	FoundDocuments.ID,
	                    |	DocumentPointInTime
	                    |TOTALS BY
	                    |	TransactionID");
	Request.SetParameter("BankAccount", AccountInBank);
	Request.SetParameter("AccountingAccount", AccountingAccount);
	Res = Request.Execute();
	
	If Res.IsEmpty() Then
		return New Array();
	EndIf;
	TransactionSelect = Res.Select(QueryResultIteration.ByGroups);
	UsedDocuments = New Array();
	ReturnArray = New Array();
	While TransactionSelect.Next() Do
		DocumentsSelect = TransactionSelect.Select();
		DocumentFound = False;
		DepositDocument = Documents.Deposit.EmptyRef();
		While (Not DocumentFound) And (DocumentsSelect.Next()) Do
			DepositDocument = DocumentsSelect.FoundDocument;
			If UsedDocuments.Find(DepositDocument) = Undefined Then
				DocumentFound = True;
				UsedDocuments.Add(DepositDocument);
				Break;
			Else
				Continue;	
			EndIf;
		EndDo;
		If DocumentFound Then
			ReturnStructure = New Structure("TransactionID, TransactionDate, FoundDocument");
			ReturnStructure.TransactionID = TransactionSelect.TransactionID;
			ReturnStructure.TransactionDate = TransactionSelect.TransactionDate;
			ReturnStructure.FoundDocument = DepositDocument;
			ReturnArray.Add(ReturnStructure);	
			//Record result into database
			RS = InformationRegisters.BankTransactions.CreateRecordSet();
			IDFilter = RS.Filter.ID;
			IDFilter.Use = True;
			IDFilter.ComparisonType = ComparisonType.Equal;
			IDFilter.Value = TransactionSelect.TransactionID;
			RS.Read();
			For Each Rec In RS Do
				Rec.Document = DepositDocument;
			EndDo;
			RS.Write(True);
		EndIf;
	EndDo;
	CommitTransaction();
	return ReturnArray;
EndFunction

&AtServerNoContext
Function MatchCheckDocuments(Val AccountInBank, Val AccountingAccount, Val ArrayOfIDs)
	
	VT = New ValueTable();
	VT.Columns.Add("ID", New TypeDescription("UUID"));
	
	For Each ItemID In ArrayOfIDs Do
		NewRow = VT.Add();
		NewRow.ID = ItemID;
	EndDo;
	
	BeginTransaction(DataLockControlMode.Managed);
	
	// Create new managed data lock
	DataLock = New DataLock;

	// Set data lock parameters
	// Set shared lock to get consisitent data
	BA_LockItem = DataLock.Add("InformationRegister.BankTransactions");
	BA_LockItem.Mode = DataLockMode.Shared;
	BA_LockItem.SetValue("BankAccount", AccountInBank);
	
	// Set exclusive lock on potentially modifiable records 
	BA_LockItem = DataLock.Add("InformationRegister.BankTransactions");
	BA_LockItem.Mode = DataLockMode.Exclusive;
	BA_LockItem.SetValue("BankAccount", AccountInBank);	
	BA_LockItem.DataSource = VT;
	BA_LockItem.UseFromDataSource("ID", "ID");
	// Set lock on the object
	DataLock.Lock();

	Request = New Query("SELECT ALLOWED
	                    |	BankTransactions.TransactionDate,
	                    |	BankTransactions.ID,
	                    |	BankTransactions.Amount
	                    |INTO UnacceptedTransactionsWithoutDocuments
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |WHERE
	                    |	BankTransactions.BankAccount = &BankAccount
	                    |	AND BankTransactions.Document = UNDEFINED
	                    |	AND BankTransactions.Accepted = FALSE
	                    |	AND BankTransactions.Amount < 0
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	Check.Ref,
	                    |	Check.Date,
	                    |	Check.DocumentTotalRC,
	                    |	Check.PointInTime
	                    |INTO AvailableCheckDocuments
	                    |FROM
	                    |	Document.Check AS Check
	                    |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	                    |		ON Check.Ref = BankTransactions.Document
	                    |WHERE
	                    |	BankTransactions.Document IS NULL 
	                    |	AND Check.BankAccount = &AccountingAccount
	                    |
	                    |UNION ALL
	                    |
	                    |SELECT
	                    |	InvoicePayment.Ref,
	                    |	InvoicePayment.Date,
	                    |	InvoicePayment.DocumentTotalRC,
	                    |	InvoicePayment.PointInTime
	                    |FROM
	                    |	Document.InvoicePayment AS InvoicePayment
	                    |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	                    |		ON InvoicePayment.Ref = BankTransactions.Document
	                    |WHERE
	                    |	BankTransactions.Document IS NULL 
	                    |	AND InvoicePayment.BankAccount = &AccountingAccount
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	UnacceptedTransactionsWithoutDocuments.TransactionDate,
	                    |	UnacceptedTransactionsWithoutDocuments.ID,
	                    |	UnacceptedTransactionsWithoutDocuments.Amount,
	                    |	AvailableCheckDocuments.Ref AS FoundDocument,
	                    |	AvailableCheckDocuments.Date AS DocumentDate,
	                    |	AvailableCheckDocuments.PointInTime AS DocumentPointInTime
	                    |INTO FoundDocuments
	                    |FROM
	                    |	UnacceptedTransactionsWithoutDocuments AS UnacceptedTransactionsWithoutDocuments
	                    |		INNER JOIN AvailableCheckDocuments AS AvailableCheckDocuments
	                    |		ON (-1 * UnacceptedTransactionsWithoutDocuments.Amount = AvailableCheckDocuments.DocumentTotalRC)
	                    |			AND (AvailableCheckDocuments.Date < DATEADD(UnacceptedTransactionsWithoutDocuments.TransactionDate, DAY, 7))
	                    |			AND (AvailableCheckDocuments.Date > DATEADD(UnacceptedTransactionsWithoutDocuments.TransactionDate, DAY, -7))
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	FoundDocuments.TransactionDate AS TransactionDate,
	                    |	FoundDocuments.ID AS TransactionID,
	                    |	FoundDocuments.FoundDocument,
	                    |	FoundDocuments.DocumentPointInTime AS DocumentPointInTime
	                    |FROM
	                    |	FoundDocuments AS FoundDocuments
	                    |
	                    |ORDER BY
	                    |	TransactionDate,
	                    |	FoundDocuments.ID,
	                    |	DocumentPointInTime
	                    |TOTALS BY
	                    |	TransactionID");
	Request.SetParameter("BankAccount", AccountInBank);
	Request.SetParameter("AccountingAccount", AccountingAccount);
	Res = Request.Execute();
	
	If Res.IsEmpty() Then
		return New Array();
	EndIf;
	TransactionSelect = Res.Select(QueryResultIteration.ByGroups);
	UsedDocuments = New Array();
	ReturnArray = New Array();
	While TransactionSelect.Next() Do
		DocumentsSelect = TransactionSelect.Select();
		DocumentFound = False;
		CheckDocument = Documents.Check.EmptyRef();
		While (Not DocumentFound) And (DocumentsSelect.Next()) Do
			CheckDocument = DocumentsSelect.FoundDocument;
			If UsedDocuments.Find(CheckDocument) = Undefined Then
				DocumentFound = True;
				UsedDocuments.Add(CheckDocument);
				Break;
			Else
				Continue;	
			EndIf;
		EndDo;
		If DocumentFound Then
			ReturnStructure = New Structure("TransactionID, TransactionDate, FoundDocument");
			ReturnStructure.TransactionID = TransactionSelect.TransactionID;
			ReturnStructure.TransactionDate = TransactionSelect.TransactionDate;
			ReturnStructure.FoundDocument = CheckDocument;
			ReturnArray.Add(ReturnStructure);	
			//Record result into database
			RS = InformationRegisters.BankTransactions.CreateRecordSet();
			IDFilter = RS.Filter.ID;
			IDFilter.Use = True;
			IDFilter.ComparisonType = ComparisonType.Equal;
			IDFilter.Value = TransactionSelect.TransactionID;
			RS.Read();
			For Each Rec In RS Do
				Rec.Document = CheckDocument;
			EndDo;
			RS.Write(True);
		EndIf;
	EndDo;
	CommitTransaction();
	return ReturnArray;
EndFunction

&AtServerNoContext
Function MatchTransferDocuments(Val AccountInBank, Val AccountingAccount)
		
	BeginTransaction(DataLockControlMode.Managed);
	
	// Create new managed data lock
	DataLock = New DataLock;

	// Set data lock parameters
	// Set shared lock to get consisitent data
	BA_LockItem = DataLock.Add("InformationRegister.BankTransactions");
	BA_LockItem.Mode = DataLockMode.Exclusive;
	BA_LockItem.SetValue("BankAccount", AccountInBank);
	DataLock.Lock();
	
	Request = New Query("SELECT ALLOWED
	                    |	BankTransfer.Ref,
	                    |	BankTransfer.AccountFrom,
	                    |	BankTransfer.AccountTo,
	                    |	BankTransfer.Amount,
	                    |	BankTransfer.Date
	                    |INTO Transfers
	                    |FROM
	                    |	Document.BankTransfer AS BankTransfer
	                    |WHERE
	                    |	(BankTransfer.AccountFrom = &AccountingAccount
	                    |			OR BankTransfer.AccountTo = &AccountingAccount)
	                    |	AND BankTransfer.Posted = TRUE
	                    |	AND BankTransfer.DeletionMark = FALSE
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	BankTransactions.TransactionDate,
	                    |	BankTransactions.BankAccount,
	                    |	BankTransactions.ID,
	                    |	BankTransactions.BankAccount.AccountingAccount,
	                    |	BankTransactions.Amount,
	                    |	BankTransactions.Document,
	                    |	CASE
	                    |		WHEN BankTransactions.Amount < 0
	                    |			THEN -1 * BankTransactions.Amount
	                    |		ELSE BankTransactions.Amount
	                    |	END AS AbsoluteAmount
	                    |INTO AvailableTransactions
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |WHERE
	                    |	BankTransactions.BankAccount = &AccountInBank
	                    |	AND BankTransactions.Accepted = FALSE
	                    |	AND (BankTransactions.Document = UNDEFINED
	                    |			OR BankTransactions.Document = VALUE(Document.BankTransfer.EmptyRef))
	                    |	AND BankTransactions.Description LIKE ""%transfer%""
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	Transfers.Ref,
	                    |	Transfers.AccountFrom,
	                    |	Transfers.AccountTo,
	                    |	Transfers.Amount,
	                    |	Transfers.Date,
	                    |	CASE
	                    |		WHEN Transfers.Amount < 0
	                    |			THEN -1 * Transfers.Amount
	                    |		ELSE Transfers.Amount
	                    |	END AS AbsoluteAmount
	                    |INTO AvailableTransfers
	                    |FROM
	                    |	Transfers AS Transfers
	                    |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	                    |		ON Transfers.Ref = BankTransactions.Document
	                    |			AND (BankTransactions.BankAccount = &AccountInBank)
	                    |WHERE
	                    |	BankTransactions.Document IS NULL 
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	AvailableTransactions.TransactionDate,
	                    |	AvailableTransactions.ID,
	                    |	AvailableTransactions.Amount AS TransactionAmount,
	                    |	AvailableTransfers.Ref,
	                    |	AvailableTransfers.Date,
	                    |	CASE
	                    |		WHEN DATEDIFF(AvailableTransactions.TransactionDate, AvailableTransfers.Date, DAY) < 0
	                    |			THEN -1 * DATEDIFF(AvailableTransactions.TransactionDate, AvailableTransfers.Date, DAY)
	                    |		ELSE DATEDIFF(AvailableTransactions.TransactionDate, AvailableTransfers.Date, DAY)
	                    |	END AS AbsoluteDayDiff
	                    |INTO AllMatched
	                    |FROM
	                    |	AvailableTransactions AS AvailableTransactions
	                    |		INNER JOIN AvailableTransfers AS AvailableTransfers
	                    |		ON AvailableTransactions.AbsoluteAmount = AvailableTransfers.AbsoluteAmount
	                    |			AND (CASE
	                    |				WHEN AvailableTransactions.Amount < 0
	                    |					THEN AvailableTransactions.TransactionDate <= AvailableTransfers.Date
	                    |							AND AvailableTransactions.TransactionDate >= DATEADD(AvailableTransfers.Date, DAY, -3)
	                    |				ELSE AvailableTransactions.TransactionDate >= AvailableTransfers.Date
	                    |						AND AvailableTransactions.TransactionDate <= DATEADD(AvailableTransfers.Date, DAY, 3)
	                    |			END)
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	AllMatched.TransactionDate,
	                    |	AllMatched.ID AS TransactionID,
	                    |	AllMatched.TransactionAmount,
	                    |	AllMatched.Ref AS FoundDocument,
	                    |	AllMatched.AbsoluteDayDiff AS AbsoluteDayDiff,
	                    |	AllMatched.Ref.Presentation AS FoundDocumentPresentation
	                    |FROM
	                    |	AllMatched AS AllMatched
	                    |
	                    |ORDER BY
	                    |	AbsoluteDayDiff
	                    |TOTALS BY
	                    |	TransactionID");
	Request.SetParameter("AccountingAccount", AccountingAccount);
	Request.SetParameter("AccountInBank", AccountInBank);
			
	Res = Request.Execute();
	
	If Res.IsEmpty() Then
		return New Array();
	EndIf;
	TransactionSelect = Res.Select(QueryResultIteration.ByGroups);
	UsedDocuments = New Array();
	ReturnArray = New Array();
	While TransactionSelect.Next() Do
		DocumentsSelect = TransactionSelect.Select();
		DocumentFound = False;
		BankTransferDocument = Documents.BankTransfer.EmptyRef();
		While (Not DocumentFound) And (DocumentsSelect.Next()) Do
			BankTransferDocument = DocumentsSelect.FoundDocument;
			If UsedDocuments.Find(BankTransferDocument) = Undefined Then
				DocumentFound = True;
				UsedDocuments.Add(BankTransferDocument);
				Break;
			Else
				Continue;	
			EndIf;
		EndDo;
		If DocumentFound Then
			ReturnStructure = New Structure("TransactionID, TransactionDate, FoundDocument, FoundDocumentPresentation");
			ReturnStructure.TransactionID = TransactionSelect.TransactionID;
			ReturnStructure.TransactionDate = DocumentsSelect.TransactionDate;
			ReturnStructure.FoundDocument = BankTransferDocument;
			ReturnStructure.FoundDocumentPresentation = DocumentsSelect.FoundDocumentPresentation;
			ReturnArray.Add(ReturnStructure);	
			//Record result into database
			RS = InformationRegisters.BankTransactions.CreateRecordSet();
			IDFilter = RS.Filter.ID;
			IDFilter.Use = True;
			IDFilter.ComparisonType = ComparisonType.Equal;
			IDFilter.Value = TransactionSelect.TransactionID;
			RS.Read();
			For Each Rec In RS Do
				Rec.Document = BankTransferDocument;
			EndDo;
			RS.Write(True);
		EndIf;
	EndDo;
	
	CommitTransaction();
	return ReturnArray;
EndFunction

&AtServerNoContext
Function GetAccountingSuiteAccountBalance(AccountingAccount)
	Request = New Query("SELECT
	                    |	GeneralJournalBalance.AmountBalance
	                    |FROM
	                    |	AccountingRegister.GeneralJournal.Balance(, Account = &Account, , ) AS GeneralJournalBalance");
	Request.SetParameter("Account", AccountingAccount);
	Res = Request.Execute().Select();
	If Res.Next() Then
		return Res.AmountBalance;
	Else
		return 0;
	EndIf;
EndFunction

&AtServerNoContext
Procedure RecordTransactionToTheDatabaseAtServer(Transaction)
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
	Tran.Insert("Class", Transaction.Class);
	Tran.Insert("Project", Transaction.Project);
	Tran.Insert("CategoryID", Transaction.CategoryID);
	Tran.Insert("Type", Transaction.Type);
	Tran.Insert("CategorizedCompanyNotAccepted", Transaction.CategorizedCompanyNotAccepted);
	Tran.Insert("CategorizedCategoryNotAccepted", Transaction.CategorizedCategoryNotAccepted);
	TransactionID = SaveTransactionAtServer(Tran);
	Transaction.TransactionID = TransactionID;
EndProcedure

&AtServerNoContext
Function LockYodleeConnection(FormID)
	return Yodlee.LockYodleeConnection(FormID);
EndFunction

&AtServerNoContext
Function UnlockYodleeConnection(FormID)
	return Yodlee.UnlockYodleeConnection(FormID);
EndFunction
#ENDREGION

#REGION FORM_COMMAND_HANDLERS
////////////////////////////////////////////////////////////////////////////////
// FORM COMMAND HANDLERS

&AtClient
Procedure UnmarkAllUnaccepted()
	If Not BankTransactionsLocked Then
		return;
	EndIf;
	For Each Tran In Object.BankTransactionsUnaccepted Do
		Tran.Accept = False;
	EndDo;
EndProcedure

&AtClient
Procedure MarkAllUnaccepted()
	If Not BankTransactionsLocked Then
		return;
	EndIf;
	For Each Tran In Object.BankTransactionsUnaccepted Do
		Tran.Accept = True;
	EndDo;
EndProcedure

&AtClient
Procedure AcceptTransactions(Command)
	If Not BankTransactionsLocked Then
		return;
	EndIf;
	AcceptSelectedTransactionsAtServer();
EndProcedure

&AtClient
Procedure SaveUnaccepted(Command)
	SaveUnacceptedAtServer();
EndProcedure

&AtClient
Procedure UndoTransaction(Command)
	UndoTransactionAtServer();
EndProcedure

#ENDREGION

#REGION SERVER_EVENT_HANDLERS
////////////////////////////////////////////////////////////////////////////////
// SERVER EVENT HANDLERS

#ENDREGION

#REGION FORM_ITEMS_HANDLERS
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
Procedure BankAccountOnChange()
	
	AttachIdleHandler("ProcessBankAccountChange", 0.1, True);
	
EndProcedure

&AtClientAtServerNoContext
Function GetLastUpdatedString(LastUpdated)
	If (Not ValueIsFilled(LastUpdated)) Or (LastUpdated < '19800101') Then
		return "Not updated";
	EndIf;
	LocalTime = CurrentDate();
	If ((LocalTime - LastUpdated) < 3600) Then //Recently within 1 hour
		return Format(Int((LocalTime - LastUpdated)/60), "NFD=0; NZ=") + " minutes ago"; ;
	ElsIf ((LocalTime - LastUpdated) < 24*3600) Then //Within 24 hours ago
		HourDiff = Int((LocalTime - LastUpdated)/3600);
		return Format(HourDiff, "NFD=0; NZ=") + ?(HourDiff = 1, " hour", " hours") +" ago";
	ElsIf BegOfDay(LocalTime - 24*3600) = BegOfDay(LastUpdated) Then //Yesterday
		return "Yesterday";
	Else
		return Format(LastUpdated, "DLF=DD");
	EndIf;		 
EndFunction

&AtClient
Procedure BankTransactionsUnacceptedOnChange(Item)
	RecordTransactionToTheDatabase(Items.BankTransactionsUnaccepted.CurrentData);
	
	//Set filter for the Project on the Customer
	FilterAvailableProjects();
EndProcedure

&AtClient 
Procedure FilterAvailableProjects()
	ChosenCompany = Items.BankTransactionsUnaccepted.CurrentData.Company;
	If ValueIsFilled(ChosenCompany) Then
		CV = CommonUse.GetAttributeValues(ChosenCompany, "Customer, Vendor");
		If (CV.Customer) AND (Not CV.Vendor) Then
			Company = ChosenCompany;
		Else
			Company = PredefinedValue("Catalog.Companies.EmptyRef");
		EndIf;
	Else
		Company = ChosenCompany;
	EndIf;
	NewArray = New Array();
	If ValueIsFilled(Company) Then
		NewParameter = New ChoiceParameter("Filter.Customer", Company);
    	NewArray.Add(NewParameter);
	EndIf;
    NewParameters = New FixedArray(NewArray);
    Items.BankTransactionsUnacceptedProject.ChoiceParameters = NewParameters;  
	//Clear project value if it doesn't match filter
	Project = Items.BankTransactionsUnaccepted.CurrentData.Project;
	If ValueIsFilled(Project) And ValueIsFilled(Company) Then
		If (CommonUse.GetAttributeValue(Project, "Customer") <> Company) Then
			Items.BankTransactionsUnaccepted.CurrentData.Project = PredefinedValue("Catalog.Projects.EmptyRef");
		EndIf;
	EndIf;
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
	Tran.Insert("Class", Transaction.Class);
	Tran.Insert("Project", Transaction.Project);
	Tran.Insert("CategoryID", Transaction.CategoryID);
	Tran.Insert("Type", Transaction.Type);
	Tran.Insert("CategorizedCompanyNotAccepted", Transaction.CategorizedCompanyNotAccepted);
	Tran.Insert("CategorizedCategoryNotAccepted", Transaction.CategorizedCategoryNotAccepted);
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
	ApplyHiddenTransactionsAppearanceAtServer();
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
			ShowQueryBox(Notify, "The current transaction will be removed from the database permanently. Continue?", Mode, 0, DialogReturnCode.Cancel, "Cloud banking");
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
		ElsIf TypeOf(Parameters) = Type("Array") Then
			For Each CurParam In Parameters Do
				DeleteTransactionAtServer(CurParam.TranID);
				CurRow = Object.BankTransactionsUnaccepted.FindByID(CurParam.RowID);
				Object.BankTransactionsUnaccepted.Delete(Object.BankTransactionsUnaccepted.IndexOf(CurRow));				
			EndDo;
		EndIf;
    EndIf;
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	DeleteTransaction(Undefined);
EndProcedure

&AtClient
Procedure RefreshTransactions(Command)
	If Not YodleeAccount Then
		return;		
	EndIf;
	//Lock Yodlee connection
	LockYodleeConnection(ThisForm.UUID);
	Notify = New NotifyDescription("OnComplete_RefreshTransactions", ThisObject);
	Params = New Structure("PerformRefreshingAccount, RefreshAccount, UploadTransactionsFrom, UploadTransactionsTo", True, AccountInBank, Object.ProcessingPeriod.StartDate, Object.ProcessingPeriod.EndDate);
	OpenForm("DataProcessor.YodleeBankAccountsManagement.Form.Form", Params, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure AddAccount(Command)
	
	Notify = New NotifyDescription("OnComplete_AddAccount", ThisObject);
	Params = New Structure("PerformAddAccount", True);
	OpenForm("DataProcessor.YodleeBankAccountsManagement.Form.Form", Params, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure UploadFromCSV(Command)
	CSV_FilenameStartChoice(Undefined, Undefined, Undefined);
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedSelection(Item, SelectedRow, Field, StandardProcessing)
	If Field.Name = "BankTransactionsUnacceptedAction" Then
		Description = Item.CurrentData.Description;
		Amount = Item.CurrentData.Amount;
		Success = AcceptSelectedTransactionAtServer(Item.CurrentData.GetID());
		If Success Then
			ShowUserNotification("Accepted transaction. Amount:" + Format(Amount, "NFD=2; NZ=; NG=3,0"),, Description);
		EndIf;
	ElsIf Field.Name = "BankTransactionsUnacceptedHide" Then
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
		ChoiceList.Add("New");
		ChoiceList.Add("Match");
		ChoiceList.Add("Transfer");
	EndIf;
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedOnActivateRow(Item)
	If Item.CurrentData = Undefined Then
		return;
	EndIf;
	// Set the current row attribute
	Try
		PreviousRow = Object.BankTransactionsUnaccepted.FindByID(CurrentRowID);
		PreviousRow.IsCurrentRow = False;
	Except
	EndTry;
	
	Item.CurrentData.IsCurrentRow = True;
	CurrentRowID = Item.CurrentData.GetID();
	// Fill category choice list
	ChoiceList = Items.BankTransactionsUnacceptedCategory.ChoiceList;
	ChoiceList.Clear();
	//For the Add choice - one choice list, for transfers - another
	If Item.CurrentData.Document = PredefinedValue("Document.BankTransfer.EmptyRef") Then
		If BankingGLAccounts = Undefined Then
			BankingGLAccounts = GetBankingGLAccounts();
		EndIf;
		For Each BankGLAccount In BankingGLAccounts Do
			If BankGLAccount.AccountingAccount = Object.BankAccount Then
				Continue;
			EndIf;
			ChoiceList.Add(BankGLAccount.AccountingAccount, "Accept: "  + BankGLAccount.AccountingAccountPresentation);
		EndDo;
	ElsIf Item.CurrentData.Document = Undefined Then
		CategoryAccount = Item.CurrentData.CategoryAccount; 
		AccountDescription = CommonUse.GetAttributeValue(CategoryAccount, "Description");
		CategoryDescription = Item.CurrentData.CategoryDescription;
		CategoryID = Item.CurrentData.CategoryID;
		If ValueIsFilled(CategoryAccount) Then
			ChoiceList.Add(CategoryAccount, "Accept: "  + CategoryDescription + " (" + String(CategoryAccount) + ")");
		ElsIf ValueIsFilled(CategoryID) Then
			ChoiceList.Add(PredefinedValue("ChartOfAccounts.ChartOfAccounts.EmptyRef"), "Assign account to: " + CategoryDescription);
		Else
		EndIf;
		If (ValueIsFilled(Item.CurrentData.Category)) And (Item.CurrentData.CategorizedCategoryNotAccepted) Then
			ChoiceList.Add(Item.CurrentData.Category, "Accept: " + String(Item.CurrentData.Category));
		EndIf;
	EndIf;
	//Fill company choice list
	ChoiceList = Items.BankTransactionsUnacceptedCompany.ChoiceList;
	ChoiceList.Clear();
	If Item.CurrentData.CategorizedCompanyNotAccepted Then
		ChoiceList = Items.BankTransactionsUnacceptedCompany.ChoiceList;
		ChoiceList.Clear();
		Company = Item.CurrentData.Company;
		ChoiceList.Add(Company, "Accept: " + String(Company));
	EndIf;
	//Set filter on the Project by Customer
	FilterAvailableProjects();
	
EndProcedure

#ENDREGION

#REGION OTHER_FUNCTIONS
////////////////////////////////////////////////////////////////////////////////
// OTHER FUNCTIONS

//Accepts suggested (default) categories
//If the user didn't fill it manually
&AtServer 
Procedure AcceptCategoriesAtServer(Transactions = Undefined)
	If Transactions = Undefined Then
		Transactions = Object.BankTransactionsUnaccepted.FindRows(New Structure("Accept", True));
	EndIf;

	For Each Transaction In Transactions Do
		If Not ValueIsFilled(Transaction.Category) Then
			If ValueIsFilled(Transaction.CategoryAccount) Then
				Transaction.Category = Transaction.CategoryAccount;
			EndIf;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure CSV_FilenameStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	If Not ValueIsFilled(AccountInBank) Then
		CommonUseClientServer.MessageToUser("Please, fill in bank account",, "AccountInBank");
		Return;
	ElsIf Not ValueIsFilled(Object.BankAccount) Then
		CommonUseClientServer.MessageToUser("Please, fill G/L account in on the accounting tab in bank account form",, "AccountInBank");
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
		
		If Item <> Undefined Then
			FileDialog.FullFileName							= Item.EditText;
		EndIf;
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
		DocumentFound = FindAnExistingDocument(NewRow.Description, NewRow.Amount, Object.BankAccount);
		If DocumentFound <> Undefined Then
			NewRow.Document 		= DocumentFound;
		EndIf;
		NewRow.AssigningOption 	= GetAssigningOption(NewRow.Document, String(DocumentFound));
		
		//Record new item to the database
		RecordTransactionToTheDatabase(NewRow);
		
	EndDo;
	
	Object.BankTransactionsUnaccepted.Sort("TransactionDate DESC, Description, Company, Category, TransactionID");
	
EndProcedure

&AtServer
Function CheckDataFillAtServer(Transactions = Undefined)
	Result = True;
	If Transactions = Undefined Then
		Transactions = Object.BankTransactionsUnaccepted.FindRows(New Structure("Accept", True));
	EndIf;
	For Each CurTran In Transactions Do
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
		If Not ValueIsFilled(CurTran.Document) Then
			If Not ValueIsFilled(CurTran.Category) Then
				Result = False;
				MessageToTheUser("Category", "Category", CurTran.LineNumber);	
			EndIf;
			If ValueIsFilled(CurTran.Company) And ValueIsFilled(CurTran.Project) Then
				If CurTran.Company <> CommonUse.GetAttributeValue(CurTran.Project, "Customer") Then
					Result = False;
					MessOnError = New UserMessage();
					MessOnError.SetData(Object);
					MessOnError.Field = "Object.BankTransactionsUnaccepted[" + String(CurTran.LineNumber-1) + "]." + "Project";
					MessOnError.Text  = "Project's customer does not correspond to the customer of the transaction";
					MessOnError.Message();
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	Return Result;
EndFunction

&AtServer 
Procedure MessageToTheUser(FieldID, FieldRepresentation, RowNumber)
	MessOnError = New UserMessage();
	MessOnError.SetData(Object);
	MessOnError.Field = "Object.BankTransactionsUnaccepted[" + String(RowNumber-1) + "]." + FieldID;
	MessOnError.Text  = "Field """ + FieldRepresentation + """ in row №" + String(RowNumber) + " is not filled";
	MessOnError.Message();
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedAssigningChoiceProcessing(Item, SelectedValue, StandardProcessing)
	If SelectedValue = "New" Then
		Items.BankTransactionsUnaccepted.CurrentData.Document = Undefined;
		ChoiceList = Items.BankTransactionsUnacceptedAssigning.ChoiceList;
		ChoiceList.Clear();
		ChoiceList.Add("New");
		ChoiceList.Add("Match");
		ChoiceList.Add("Transfer");
		RecordTransactionToTheDatabase(Items.BankTransactionsUnaccepted.CurrentData);
		Return;
	ElsIf SelectedValue = "Match" Then
		AO = Items.BankTransactionsUnaccepted.CurrentData.AssigningOption;
		If AO <> "New" Then
			SelectedValue = AO;
		Else
			SelectedValue = "New";
			Items.BankTransactionsUnaccepted.CurrentData.Document = Undefined;
		EndIf;
		//Open DocumentJournal
		ParametersStructure = New Structure();
		ParametersStructure.Insert("TransactionDate", Items.BankTransactionsUnaccepted.CurrentData.TransactionDate);
		ParametersStructure.Insert("BankAccount", Object.BankAccount);
		DocList = New ValueList();
		If Items.BankTransactionsUnaccepted.CurrentData.Amount < 0 Then
			DocList.Add(Type("DocumentRef.Check"));
			DocList.Add(Type("DocumentRef.InvoicePayment"));
			DocList.Add(Type("DocumentRef.BankTransfer"));
			DocList.Add(Type("DocumentRef.GeneralJournalEntry"));
			DocList.Add(Type("DocumentRef.PurchaseInvoice"));
			AmountFilterValue = -1*Items.BankTransactionsUnaccepted.CurrentData.Amount;
		Else
			DocList.Add(Type("DocumentRef.CashReceipt"));
			DocList.Add(Type("DocumentRef.Deposit"));
			DocList.Add(Type("DocumentRef.BankTransfer"));
			DocList.Add(Type("DocumentRef.GeneralJournalEntry"));
			DocList.Add(Type("DocumentRef.SalesInvoice"));
			AmountFilterValue = Items.BankTransactionsUnaccepted.CurrentData.Amount;
		EndIf;
		ParametersStructure.Insert("Amount", AmountFilterValue);
		ParametersStructure.Insert("ListOfDocumentTypes", DocList);
		ParametersStructure.Insert("AccountInBank", AccountInBank);
		ParametersStructure.Insert("IncomingPayment", ?(Items.BankTransactionsUnaccepted.CurrentData.Amount >= 0, True, False));
		ParametersStructure.Insert("TransactionID", Items.BankTransactionsUnaccepted.CurrentData.TransactionID);
		OpenForm("DataProcessor.DownloadedTransactions.Form.DocumentMatching", ParametersStructure, Item);
		//DM = GetForm("DataProcessor.DownloadedTransactions.Form.DocumentMatching",,Item);
		//FilterType = DM.DocumentList.Filter.Items.Add(Type("DataCompositionFilterItem"));
		//FilterType.LeftValue = New DataCompositionField("Type");
		//FilterType.ComparisonType = DataCompositionComparisonType.InList;
		//DocList = New ValueList();
		//If Items.BankTransactionsUnaccepted.CurrentData.Amount < 0 Then
		//	DocList.Add(Type("DocumentRef.Check"));
		//	DocList.Add(Type("DocumentRef.InvoicePayment"));
		//	DocList.Add(Type("DocumentRef.BankTransfer"));
		//	DocList.Add(Type("DocumentRef.GeneralJournalEntry"));
		//	AmountFilterValue = -1*Items.BankTransactionsUnaccepted.CurrentData.Amount;
		//Else
		//	DocList.Add(Type("DocumentRef.CashReceipt"));
		//	DocList.Add(Type("DocumentRef.Deposit"));
		//	DocList.Add(Type("DocumentRef.BankTransfer"));
		//	DocList.Add(Type("DocumentRef.GeneralJournalEntry"));
		//	AmountFilterValue = Items.BankTransactionsUnaccepted.CurrentData.Amount;
		//EndIf;
		//FilterType.RightValue = DocList;
		//FilterType.Use = True;
		//
		//FilterTotal = DM.DocumentList.Filter.Items.Add(Type("DataCompositionFilterItem"));
		//FilterTotal.LeftValue = New DataCompositionField("Total");
		//FilterTotal.ComparisonType = DataCompositionComparisonType.Equal;
		//FilterTotal.RightValue = AmountFilterValue;
		//FilterTotal.Use = True;
		//
		//DM.CloseOnChoice = True;
		//DM.WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		//DM.Open();
		return;
	ElsIf SelectedValue = "Transfer" Then
		Items.BankTransactionsUnaccepted.CurrentData.Document = PredefinedValue("Document.BankTransfer.EmptyRef");
		ChoiceList = Items.BankTransactionsUnacceptedAssigning.ChoiceList;
		ChoiceList.Clear();
		ChoiceList.Add("New");
		ChoiceList.Add("Match");
		ChoiceList.Add("Transfer");
		CurTran = Items.BankTransactionsUnaccepted.CurrentData;
		TransferGLAccount = OnTransferSetAtServer(CurTran.TransactionDate, CurTran.Amount, AccountInBank, Object.BankAccount);
		Items.BankTransactionsUnaccepted.CurrentData.Category = TransferGLAccount;
		RecordTransactionToTheDatabase(Items.BankTransactionsUnaccepted.CurrentData);
		
		// Fill category choice list
		ChoiceList = Items.BankTransactionsUnacceptedCategory.ChoiceList;
		ChoiceList.Clear();
		If BankingGLAccounts = Undefined Then
			BankingGLAccounts = GetBankingGLAccounts();
		EndIf;
		For Each BankGLAccount In BankingGLAccounts Do
			If BankGLAccount.AccountingAccount = Object.BankAccount Then
				Continue;
			EndIf;
			ChoiceList.Add(BankGLAccount.AccountingAccount, "Accept: "  + BankGLAccount.AccountingAccountPresentation);
		EndDo;
		Return;
	ElsIf ValueIsFilled(SelectedValue) Then 
		StandardProcessing = True;
		//If selected a document 
		If TypeOf(SelectedValue) <> Type("String") Then
			Items.BankTransactionsUnaccepted.CurrentData.Document = SelectedValue;
			Items.BankTransactionsUnaccepted.CurrentData.AssigningOption 	= GetAssigningOption(SelectedValue, String(SelectedValue));
			
			ChoiceList = Items.BankTransactionsUnacceptedAssigning.ChoiceList;
			ChoiceList.Clear();
			Items.BankTransactionsUnacceptedAssigning.ChoiceList.Add(Items.BankTransactionsUnaccepted.CurrentData.AssigningOption);
			ChoiceList.Add("New");
			ChoiceList.Add("Match");
			ChoiceList.Add("Transfer");
			
			SelectedValue = Items.BankTransactionsUnaccepted.CurrentData.AssigningOption;
			RecordTransactionToTheDatabase(Items.BankTransactionsUnaccepted.CurrentData);
		EndIf;
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
		RequireSort = ?(Object.HiddenTransactionsUnaccepted.Count()>0, True, False);
		While i < Object.HiddenTransactionsUnaccepted.Count() Do
			HiddenTran 		= Object.HiddenTransactionsUnaccepted[i];
			Tran 			= Object.BankTransactionsUnaccepted.Add();
			FillPropertyValues(Tran, HiddenTran);
			Tran.AssigningOption 	= GetAssigningOption(Tran.Document, String(Tran.Document));
			Tran.Hide 		= "Show";
			Object.HiddenTransactionsUnaccepted.Delete(i);
		EndDo;
		If RequireSort Then
			Object.BankTransactionsUnaccepted.Sort("TransactionDate DESC, Description, Company, Category, TransactionID");
		EndIf;
	EndIf;		
EndProcedure

&AtClientAtServerNoContext
Function GetAssigningOption(Document, DocumentPresentation)
	If ValueIsFilled(Document) Then
		//Return "Assigned to " + DocumentPresentation;
		Return String(DocumentPresentation);
	ElsIf Document = PredefinedValue("Document.BankTransfer.EmptyRef") Then
		Return "Transfer";
	Else
		Return "New";
	EndIf;
EndFunction

&AtClient
Procedure OnComplete_RefreshTransactions(ClosureResult, AdditionalParameters) Export
	OnComplete_RefreshTransactionsAtServer(ClosureResult, AdditionalParameters);
EndProcedure

&AtServer
Procedure OnComplete_RefreshTransactionsAtServer(ClosureResult, AdditionalParameters)
	LastUpdated = ToLocalTime(AccountInBank.LastUpdatedTimeUTC);
	AccountLastUpdated 	= FormLastUpdatedStringAtServer(LastUpdated);
	DecoratePresentationIfError(AccountInBank.RefreshStatusCode);
	AccountAvailableBalance = ?(ValueIsFilled(AccountInBank.CurrentBalance), AccountInBank.CurrentBalance, AccountInBank.AvailableBalance);
	UnlockYodleeConnection(ThisForm.UUID);
	UploadTransactionsFromDB(,,True, True);
	ApplyHiddenTransactionsAppearanceAtServer();
EndProcedure

&AtClient
Procedure ProcessBankAccountChange() Export
	BankAccountOnChangeAtServer();
	
	//If bank transactions of the current bank account are being edited from a different session, inform the user about it.
	If Not BankTransactionsLocked Then
		ArrayOfMessages = New Array();
		ArrayOfMessages.Add(PictureLib.Warning32);
		ArrayOfMessages.Add("    Bank transactions of the current bank account are being edited in a different session. Data is available for viewing only.");
		ShowMessageBox(, New FormattedString(ArrayOfMessages),,"Cloud banking");
	Else
		PreviousAccountInBank = AccountInBank;
	EndIf;

EndProcedure

&AtClient
Procedure OnComplete_AddAccount(ClosureResult, AdditionalParameters) Export
	If ClosureResult <> Undefined Then
		If TypeOf(ClosureResult) = Type("Array") Then
			i = 0;
			While i < ClosureResult.Count() Do
				NewAddedItem = ClosureResult[i];
				If TypeOf(NewAddedItem) = Type("CatalogRef.BankAccounts") Then
					If i = ClosureResult.Count()-1 Then
						AccountInBank = NewAddedItem;
						BankAccountOnChange();
					EndIf;
					i = i + 1;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedCategoryChoiceProcessing(Item, SelectedValue, StandardProcessing)
	If SelectedValue = PredefinedValue("ChartOfAccounts.ChartOfAccounts.EmptyRef") Then
		StandardProcessing = False;
		Notify = New NotifyDescription("AssignCategoryAccount", ThisObject, New Structure("CurrentRow", Items.BankTransactionsUnaccepted.CurrentRow));
		OpenForm("Catalog.BankTransactionCategories.ObjectForm", New Structure("Key", Items.BankTransactionsUnaccepted.CurrentData.CategoryRef), ThisForm,,,,Notify,FormWindowOpeningMode.LockOwnerWindow);
				
	Else 
		Items.BankTransactionsUnaccepted.CurrentData.CategorizedCategoryNotAccepted = False;
	EndIf;
EndProcedure

&AtClient
Procedure AssignCategoryAccount(NewAccount, Parameters) Export
	If Parameters.Property("CurrentRow") Then
		Items.BankTransactionsUnaccepted.CurrentRow = Parameters.CurrentRow;
		CategoryRef = Items.BankTransactionsUnaccepted.CurrentData.CategoryRef;
		Items.BankTransactionsUnaccepted.CurrentData.Category = CommonUse.GetAttributeValue(CategoryRef, "Account"); 
		Items.BankTransactionsUnaccepted.CurrentData.CategorizedCategoryNotAccepted = False;
	EndIf;
EndProcedure

&AtClient
Procedure DeleteSelectedTransactions(Command)
	If Not BankTransactionsLocked Then
		return;
	EndIf;
	Params = New Array;
	Transactions = Object.BankTransactionsUnaccepted.FindRows(New Structure("Accept", True));
	If Transactions.Count() = 0 Then
		return;
	EndIf;
	For Each Transaction In Transactions Do
		If Not ValueIsFilled(Transaction.TransactionID) Then
			Object.BankTransactionsUnaccepted.Delete(Transaction);
		//Should ask the user whether to delete or not
		Else
			Params.Add(New Structure("TranID, RowID", Transaction.TransactionID, Transaction.GetID()));
		EndIf;
	EndDo;	
	
	Mode = QuestionDialogMode.YesNoCancel;
	Notify = New NotifyDescription("DeleteOrNotResult", ThisObject, Params);
	If QuestionAsked = Undefined then
		QuestionAsked = False;
	EndIf;
	If Not QuestionAsked then
		If Transactions.Count() = 1 Then
			ShowQueryBox(Notify, "The current transaction will be removed from the database permanently. Continue?", Mode, 0, DialogReturnCode.Cancel, "Cloud banking");
		Else
			ShowQueryBox(Notify, "The selected transactions will be removed from the database permanently. Continue?", Mode, 0, DialogReturnCode.Cancel, "Cloud banking");
		EndIf;
		QuestionAsked = True;
	EndIf;
EndProcedure

&AtClient
Procedure DecorationProcessingPeriodClick(Item)
	Notify = New NotifyDescription("OnProcessingPeriodChange", ThisObject, New Structure());
	Params = New Structure("ProcessingPeriod", Object.ProcessingPeriod);
	OpenForm("DataProcessor.DownloadedTransactions.Form.ProcessingPeriod", Params, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure OnProcessingPeriodChange(Result, Parameters) Export
	If TypeOf(Result) = Type("Structure") Then
		Object.ProcessingPeriod = Result.ProcessingPeriod;
		Items.DecorationProcessingPeriod.Title = Format(Object.ProcessingPeriod.StartDate, "DLF=DD") + " - " + Format(Object.ProcessingPeriod.EndDate, "DLF=DD");
	EndIf;

EndProcedure

&AtClient
Procedure OnComplete_CategorizeTransactions(ClosureResult, AdditionalParameters) Export
	
	If TypeOf(ClosureResult) = Type("Array") Then
		//Refill affected rows
		For Each AffectedRow In ClosureResult Do
			FoundRows = Object.BankTransactionsUnaccepted.FindRows(New Structure("TransactionID", AffectedRow.ID));
			If FoundRows.Count() > 0 Then
				FillPropertyValues(FoundRows[0], AffectedRow, "Company, CategorizedCompanyNotAccepted, Category, CategorizedCategoryNotAccepted");
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure CategorizeTransactions(Command)
	If Not BankTransactionsLocked Then
		return;
	EndIf;
	//Categorizing transactions asynchronously
	Notify = New NotifyDescription("OnComplete_CategorizeTransactions", ThisObject);
	Params = New Structure("BankAccount, PerformCategorization", AccountInBank, True);
	OpenForm("DataProcessor.DownloadedTransactions.Form.ProgressForm", Params, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedCompanyChoiceProcessing(Item, SelectedValue, StandardProcessing)
	Items.BankTransactionsUnaccepted.CurrentData.CategorizedCompanyNotAccepted = False;
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedProjectOnChange(Item)
	RecordTransactionToTheDatabase(Items.BankTransactionsUnaccepted.CurrentData);
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedClassOnChange(Item)
	RecordTransactionToTheDatabase(Items.BankTransactionsUnaccepted.CurrentData);
EndProcedure

&AtServer
Procedure DecoratePresentationIfError(RefreshStatusCode)
	If RefreshStatusCode = 0 Then //Refresh succeded
		Items.AccountInBankLastUpdatedTimeUTC.ToolTip = "";
	Else  //An error occured
		CurrentTitle = AccountLastUpdated;		
		CurrentTitleFormatted = New FormattedString(CurrentTitle, , Items.AccountInBankLastUpdatedTimeUTC.TextColor);
		ErrorTitle = New FormattedString("(An error occured. View details)", New Font(Items.AccountInBankLastUpdatedTimeUTC.Font,,,False,,,,90), New Color(255,0,0),, String(RefreshStatusCode));
		StrArray = New Array();
		StrArray.Add(CurrentTitleFormatted);
		StrArray.Add(" ");
		StrArray.Add(ErrorTitle);
		AccountLastUpdated = New FormattedString(StrArray);
	EndIf;	
EndProcedure

&AtClient
Procedure AccountInBankLastUpdatedTimeUTCURLProcessing(Item, URL, StandardProcessing)
	StandardProcessing = False;
	OpenForm("DataProcessor.DownloadedTransactions.Form.DetailedErrorMessage", New Structure("StatusCode", URL), ThisForm,,,,,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure HideTransactions(Command)
	If Not BankTransactionsLocked Then
		return;
	EndIf;
	HideTransactionsAtServer();
EndProcedure

&AtServer
Procedure HideTransactionsAtServer()
	Transactions = Object.BankTransactionsUnaccepted.FindRows(New Structure("Accept", True));
	For Each Transaction In Transactions Do
		Transaction.Hidden	= True;
		Transaction.Accept 	= False;
		RecordTransactionToTheDatabaseAtServer(Transaction);
		If ShowHidden = "Hide" Then
			NewHiddenTran 	= Object.HiddenTransactionsUnaccepted.Add();
			FillPropertyValues(NewHiddenTran, Transaction);
			Object.BankTransactionsUnaccepted.Delete(Transaction);
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure ShowTransactions(Command)
	If Not BankTransactionsLocked Then
		return;
	EndIf;
	ShowTransactionsAtServer();
EndProcedure

&AtServer
Procedure ShowTransactionsAtServer()
	Transactions = Object.BankTransactionsUnaccepted.FindRows(New Structure("Accept", True));
	For Each Transaction In Transactions Do
		Transaction.Hidden	= False;
		Transaction.Accept 	= False;
		RecordTransactionToTheDatabaseAtServer(Transaction);
	EndDo;
EndProcedure

&AtServer
Procedure AcceptSelectedTransactionsAtServer()
	AcceptCategoriesAtServer();
	If Not CheckDataFillAtServer() Then
		Return;
	EndIf;
	AcceptTransactionsAtServer();
EndProcedure

&AtServer
Function AcceptSelectedTransactionAtServer(RowID)
	Transaction = Object.BankTransactionsUnaccepted.FindByID(RowID);
	ArrayOfTransactions = New Array();
	ArrayOfTransactions.Add(Transaction);
	
	AcceptCategoriesAtServer(ArrayOfTransactions);
	If Not CheckDataFillAtServer(ArrayOfTransactions) Then
		Return False;
	EndIf;
	ErrorOccured = False;
	AcceptTransactionsAtServer(ArrayOfTransactions, ErrorOccured);
	return (Not ErrorOccured);
EndFunction

&AtServer
Function LockCurrentBankAccountForEdit()
	IRRC = InformationRegisters.BankTransactions.CreateRecordKey(New Structure("TransactionDate, BankAccount, Company, ID", Date(1,1,1), AccountInBank, Catalogs.Companies.EmptyRef(), New UUID("00000000-0000-0000-0000-000000000000")));
	Try
		LockDataForEdit(IRRC,, ThisForm.UUID);
		return True;
	Except
		return False;
	EndTry;
EndFunction

&AtServerNoContext
Procedure UnlockCurrentBankAccountForEdit(BankAccount, FormUUID)
	IRRC = InformationRegisters.BankTransactions.CreateRecordKey(New Structure("TransactionDate, BankAccount, Company, ID", Date(1,1,1), BankAccount, Catalogs.Companies.EmptyRef(), New UUID("00000000-0000-0000-0000-000000000000")));
	UnlockDataForEdit(IRRC, FormUUID);
EndProcedure

&AtServer 
Procedure ProcessLockingOfBankAccount()
	If BankTransactionsLocked Then
		UnlockCurrentBankAccountForEdit(PreviousAccountInBank, ThisForm.UUID); 
	EndIf;
	BankTransactionsLocked = LockCurrentBankAccountForEdit(); 
EndProcedure

&AtServer
Procedure BankAccountOnChangeAtServer()
	
	Object.BankAccount = AccountInBank.AccountingAccount;
	
	If Not ValueIsFilled(Object.BankAccount) Then
		AccountLastUpdated = "";
		UM = New UserMessage();
		UM.Field = "AccountInBank";
		UM.Text  = "The selected bank account is not associated with a General Ledger Account." + Chars.LF + "Please enter the appropriate G/L Account on the bank account details form at Bank/Tools/Manage Bank Accounts";
		UM.Message();
	EndIf;
	
	ProcessLockingOfBankAccount();
	
	LastUpdated 		= ToLocalTime(AccountInBank.LastUpdatedTimeUTC); 
	AccountLastUpdated 	= FormLastUpdatedStringAtServer(LastUpdated); //?(ValueIsFilled(LastUpdated), Format(LastUpdated, "DLF=DT"), "");
	DecoratePresentationIfError(AccountInBank.RefreshStatusCode);
	
	AccountAvailableBalance = ?(ValueIsFilled(AccountInBank.CurrentBalance), AccountInBank.CurrentBalance, AccountInBank.AvailableBalance);
	AccountingBalance = GetAccountingSuiteAccountBalance(AccountInBank.AccountingAccount);
		
	UploadTransactionsFromDB();		
	
	ApplyHiddenTransactionsAppearanceAtServer();
	
	YodleeAccount = AccountInBank.YodleeAccount;
		
EndProcedure

&AtServer
Procedure ApplyHiddenTransactionsAppearanceAtServer()
	i = 0;
	If ShowHidden = "Hide" Then
		Transactions = Object.BankTransactionsUnaccepted.FindRows(New Structure("Hidden", True));
		For Each Tran In Transactions Do
			NewHiddenTran 	= Object.HiddenTransactionsUnaccepted.Add();
			FillPropertyValues(NewHiddenTran, Tran);
			Object.BankTransactionsUnaccepted.Delete(Tran);
		EndDo;
	ElsIf ShowHidden = "Show" Then
		RequireSort = ?(Object.HiddenTransactionsUnaccepted.Count()>0, True, False);
		While i < Object.HiddenTransactionsUnaccepted.Count() Do
			HiddenTran 		= Object.HiddenTransactionsUnaccepted[i];
			Tran 			= Object.BankTransactionsUnaccepted.Add();
			FillPropertyValues(Tran, HiddenTran);
			Tran.AssigningOption 	= GetAssigningOption(Tran.Document, String(Tran.Document));
			Tran.Hide 		= "Show";
			Object.HiddenTransactionsUnaccepted.Delete(i);
		EndDo;
		If RequireSort Then
			Object.BankTransactionsUnaccepted.Sort("TransactionDate DESC, Description, Company, Category, TransactionID");
		EndIf;
	EndIf;		
EndProcedure

&AtServer
Function FormLastUpdatedStringAtServer(LastUpdated)
	LastUpdatedString = GetLastUpdatedString(LastUpdated);
	return New FormattedString(LastUpdatedString, , Items.AccountInBankLastUpdatedTimeUTC.TextColor);
EndFunction

&AtServerNoContext 
Function OnTransferSetAtServer(Val TransactionDate, Val TransferAmount, Val AccountInBank, Val AccountingAccount)
	SetPrivilegedMode(True);
	//Substitute suitable bank account
	Request = New Query("SELECT
	                    |	BankTransactions.BankAccount.AccountingAccount,
	                    |	CASE
	                    |		WHEN DATEDIFF(BankTransactions.TransactionDate, &TransferDate, DAY) < 0
	                    |			THEN -1 * DATEDIFF(BankTransactions.TransactionDate, &TransferDate, DAY)
	                    |		ELSE DATEDIFF(BankTransactions.TransactionDate, &TransferDate, DAY)
	                    |	END AS AbsoluteDayDiff
	                    |INTO PossibleTransfers
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |WHERE
	                    |	BankTransactions.TransactionDate >= &StartOfSearch
	                    |	AND BankTransactions.TransactionDate <= &EndOfSearch
	                    |	AND BankTransactions.Accepted = FALSE
	                    |	AND BankTransactions.Amount = &TransferAmount
	                    |	AND BankTransactions.BankAccount <> &CurrentAccountInBank
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT TOP 1
	                    |	PossibleTransfers.BankAccountAccountingAccount,
	                    |	TRUE AS BestMatch
	                    |INTO BestMatchedAccount
	                    |FROM
	                    |	(SELECT
	                    |		MIN(PossibleTransfers.AbsoluteDayDiff) AS MinimumDayDiff
	                    |	FROM
	                    |		PossibleTransfers AS PossibleTransfers) AS NestedSelect
	                    |		INNER JOIN PossibleTransfers AS PossibleTransfers
	                    |		ON NestedSelect.MinimumDayDiff = PossibleTransfers.AbsoluteDayDiff
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	NestedSelect.BankAccountAccountingAccount AS AccountingAccount,
	                    |	NestedSelect.BankAccountAccountingAccount.Presentation AS AccountingAccountPresentation,
	                    |	MAX(NestedSelect.BestMatch) AS BestMatch
	                    |FROM
	                    |	(SELECT
	                    |		BestMatchedAccount.BankAccountAccountingAccount AS BankAccountAccountingAccount,
	                    |		BestMatchedAccount.BestMatch AS BestMatch
	                    |	FROM
	                    |		BestMatchedAccount AS BestMatchedAccount
	                    |	
	                    |	UNION ALL
	                    |	
	                    |	SELECT
	                    |		BankAccounts.AccountingAccount,
	                    |		FALSE
	                    |	FROM
	                    |		Catalog.BankAccounts AS BankAccounts) AS NestedSelect
	                    |
	                    |GROUP BY
	                    |	NestedSelect.BankAccountAccountingAccount,
	                    |	NestedSelect.BankAccountAccountingAccount.Presentation
	                    |
	                    |ORDER BY
	                    |	BestMatch DESC");
	Request.SetParameter("TransferDate", TransactionDate);
	Request.SetParameter("StartOfSearch", ?(TransferAmount < 0, TransactionDate, TransactionDate - 3*24*3600)); 
	Request.SetParameter("EndOfSearch", ?(TransferAmount < 0 , TransactionDate + 3*24*3600, TransactionDate)); 
	Request.SetParameter("TransferAmount", -1*TransferAmount);
	Request.SetParameter("CurrentAccountInBank", AccountInBank);
	SuitableAccounts = Request.Execute().Unload();
	If SuitableAccounts.Count() > 0 Then
		If SuitableAccounts[0].AccountingAccount <> AccountingAccount Then
			return SuitableAccounts[0].AccountingAccount;
		Else
			return Constants.UndepositedFundsAccount.Get();
		EndIf;
	Else  		
		return Constants.UndepositedFundsAccount.Get();
	EndIf;

	//If SuitableAccounts.Count() > 0 Then
	//	If SuitableAccounts[0].AccountingAccount <> Object.BankAccount Then
	//		CurrentTransaction.Category = SuitableAccounts[0].AccountingAccount;
	//	Else
	//		CurrentTransaction.Category = PredefinedValue("ChartOfAccounts.ChartOfAccounts.UndepositedFunds");
	//	EndIf;
	//Else  		
	//	CurrentTransaction.Category = PredefinedValue("ChartOfAccounts.ChartOfAccounts.UndepositedFunds");
	//EndIf;
	//Fill in category choice list
	//ChoiceList = Items.BankTransactionsUnacceptedCategory.ChoiceList;
	//ChoiceList.Clear();
	//For Each SuitableAccount In SuitableAccounts Do
	//	If SuitableAccount.AccountingAccount = Object.BankAccount Then
	//		Continue;
	//	EndIf;
	//	ChoiceList.Add(SuitableAccount.AccountingAccount, "Accept: " + SuitableAccount.AccountingAccountPresentation);
	//EndDo;

	//Save transaction at server
	//RecordTransactionToTheDatabaseAtServer(CurrentTransaction);

EndFunction

&AtServerNoContext
Function GetBankingGLAccounts()
	//Fill banking G/L accounts
	Request = New Query("SELECT DISTINCT
	                    |	BankAccounts.AccountingAccount,
	                    |	BankAccounts.AccountingAccount.Presentation 
	                    |FROM
	                    |	Catalog.BankAccounts AS BankAccounts");
	BankingGLAccounts = Request.Execute().Unload();
	ReturnArray = New Array();
	For Each BankingGLAccount IN BankingGLAccounts Do
		ReturnArray.Add(New Structure("AccountingAccount, AccountingAccountPresentation", BankingGLAccount.AccountingAccount, BankingGLAccount.AccountingAccountPresentation));
	EndDo;
	
	return ReturnArray;
	
EndFunction

&AtServer
Function DeletionOfBankTransferPossible(TransferDocument)
	Request = New Query("SELECT
	                    |	COUNT(BankTransactions.Document) AS DocumentCount
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |WHERE
	                    |	BankTransactions.Accepted = TRUE
	                    |	AND BankTransactions.Document = &TranDocument");
	Request.SetParameter("TranDocument", TransferDocument);
	Res = Request.Execute();
	If Res.IsEmpty() Then
		return True;
	Else
		Sel = Res.Select();
		Sel.Next();
		If Sel.DocumentCount > 1 Then
			return False;
		Else
			return True;
		EndIf;
	EndIf;
EndFunction

&AtServer
Procedure RemoveBankTransferFromUnacceptedTransactions(TransferDocument)
	Request = New Query("SELECT
	                    |	BankTransactions.ID AS TransactionID
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |WHERE
	                    |	BankTransactions.Document = &TranDocument
	                    |	AND BankTransactions.Accepted = FALSE");
	Request.SetParameter("TranDocument", TransferDocument);
	Sel = Request.Execute().Select();
	While Sel.Next() Do
		RS = InformationRegisters.BankTransactions.CreateRecordSet();
		IDFilter = RS.Filter.ID;
		IDFilter.Use = True;
		IDFilter.ComparisonType = ComparisonType.Equal;
		IDFilter.Value = Sel.TransactionID;
		RS.Read();
		For Each Rec In RS Do
			Rec.Document = Documents.BankTransfer.EmptyRef();
		EndDo;
		RS.Write(True);
	EndDo;
EndProcedure

&AtServer
Procedure OnCloseAtServer()
	If BankTransactionsLocked Then
		UnlockCurrentBankAccountForEdit(AccountInBank, ThisForm.UUID); 
	EndIf;
EndProcedure

#ENDREGION
