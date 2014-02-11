////////////////////////////////////////////////////////////////////////////////
// Bank transaction processing form
//------------------------------------------------------------------------------
// Available on:
// - Client (managed application)
// - Server
//

&AtClient
Var FormIsModified, QuestionAsked;

#REGION FORM_SERVER_FUNCTIONS
////////////////////////////////////////////////////////////////////////////////
// FORM SERVER FUNCTIONS

&AtServer
Procedure UploadTransactionsFromDB(SelectUnaccepted = True, SelectAccepted = True, MatchDepositDocuments = False, MatchCheckDocuments = False)
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
	                               |	BankTransactions.CategoryID,
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
		Object.HiddenTransactionsUnaccepted.Clear();
		//Fill array of IDs to use it later in matching with Deposit documents
		ArrayOfDepositIDs = New Array();
		ArrayOfCheckIDs = New Array();
		For Each Tran In Object.BankTransactionsUnaccepted Do
			
			//Match the existing documents
			If Not ValueIsFilled(Tran.Document) Then
				//Try to match an uploaded transaction with an existing check document (with payment method="Check") 
				DocumentFound = FindAnExistingDocument(Tran.Description, Tran.Amount);
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
		ApplyConditionalAppearance();
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
	AccountingBalance = GetAccountingSuiteAccountBalance(AccountInBank.AccountingAccount);
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
	NewDeposit.DocumentTotal 	= Tran.Amount;
	NewDeposit.DocumentTotalRC 	= Tran.Amount;
	NewDeposit.TotalDeposits	= 0;
	NewDeposit.TotalDepositsRC	= 0;
		
	NewDeposit.Accounts.Clear();
	NewLine = NewDeposit.Accounts.Add();
	NewLine.Account 			= Tran.Category;
	NewLine.Memo 				= Tran.Description;
	NewLine.Company				= Tran.Company;
	NewLine.Amount 				= Tran.Amount;
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
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	//Variables initiation
	ShowHidden	= "Hide";
	Object.ProcessingPeriod.Variant	=StandardPeriodVariant.ThisMonth;
	Items.DecorationProcessingPeriod.Title = Format(Object.ProcessingPeriod.StartDate, "DLF=DD") + " - " + Format(Object.ProcessingPeriod.EndDate, "DLF=DD");
	
	//Uploading transactions 
	//UploadTransactionsFromDB();
	//ApplyConditionalAppearance();
	
	Items.DiagramType.ChoiceList.Add(String(ChartType.Column));
	Items.DiagramType.ChoiceList.Add(String(ChartType.Column3D));
	Items.DiagramType.ChoiceList.Add(String(ChartType.PyramidGraph));
	DiagramType =  String(ChartType.Column3D);
	Diagram.ChartType = ChartType.Column;
		
	FillAvailableAccounts();		
EndProcedure

&AtServer
Procedure FillAvailableAccounts()
	//FormingDocument = True;
	////Fill in bank accounts list
	//Request = New Query("SELECT ALLOWED
	//					|	BankAccounts.Ref,
	//					|	BankAccounts.Description,
	//					|	BankAccounts.Owner.Icon AS Icon,
	//					|	BankAccounts.Owner.Logotype AS Logotype,
	//					|	BankAccounts.Owner.Description AS Bank,
	//					|	CASE
	//					|		WHEN BankAccounts.AvailableBalance = 0
	//					|			THEN BankAccounts.CurrentBalance
	//					|		ELSE BankAccounts.AvailableBalance
	//					|	END AS CurrentBalance
	//					|FROM
	//					|	Catalog.BankAccounts AS BankAccounts
	//					|WHERE
	//					|	BankAccounts.DeletionMark = FALSE");
	//Res = Request.Execute();
	//UserBankAccounts.Clear();
	//Sel = Res.Choose();
	//Template = FormAttributeToValue("Object").GetTemplate("Spreadsheet");
	//BankAccountArea = Template.GetArea("BankAccount|Column");
	//While Sel.Next() Do
	//	BankAccountArea.Parameters.BankAccount = Sel.Description;
	//	BankAccountArea.Area(1,0,1,0).RowHeight = 1;
	//	BankAccountArea.Area(1, 1, BankAccountArea.TableHeight, BankAccountArea.TableWidth).BackColor = WebColors.AliceBlue;
	//	UserBankAccounts.Put(BankAccountArea);
	//EndDo;
	//FormingDocument = True;
	//
	//return;
	//Fill in bank accounts list
	Request = New Query("SELECT ALLOWED
	                    |	BankAccounts.Ref,
	                    |	BankAccounts.Description,
	                    |	BankAccounts.Owner.Icon AS Icon,
	                    |	BankAccounts.Owner.Logotype AS Logotype
	                    |FROM
	                    |	Catalog.BankAccounts AS BankAccounts
	                    |WHERE
	                    |	BankAccounts.DeletionMark = FALSE");
	Res = Request.Execute();
	AvailableBankAccounts.Clear();
	If NOT Res.IsEmpty() Then
		Sel = Res.Choose();
		While Sel.Next() Do
			//Items.AccountInBank.ChoiceList.Add(Sel.Ref, Sel.Description, True);
			Icon = Sel.Icon.Get();
			Logotype = Sel.Logotype.Get();
			Pict = Undefined;
			If Icon <> Undefined Then
				Pict = Icon;
			ElsIf Logotype <> Undefined Then
				Pict = Logotype;
			EndIf;
			//If Pict <> Undefined Then
			//	AvailableBankAccounts.Add(Sel.Ref, Sel.Description,, Pict);
			//Else
				AvailableBankAccounts.Add(Sel.Ref, Sel.Description);
			//EndIf;
		EndDo;
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
	UsedCategoriesTable = Object.BankTransactionsUnaccepted.Unload(,"CategoryID, CategoryDescription");
	UsedCategoriesTable.GroupBy("CategoryID, CategoryDescription");
	i = 0;
	//While i < Object.BankTransactionsUnaccepted.Count() Do
	While i < UsedCategoriesTable.Count() Do
		//Show category description if category account is empty
		//CR = Object.BankTransactionsUnaccepted[i];
		CR = UsedCategoriesTable[i];
		ElementCA = CA.Items.Add(); 
	
		FieldAppearance = ElementCA.Fields.Items.Add(); 
		FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedCategory"); 
 		FieldAppearance.Use = True; 

		//FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
		//FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.IDPresentation"); 
		//FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
		//FilterElement.RightValue 		= CR.IDPresentation; 
		//FilterElement.Use				= True;
		
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

	
	//Get catagory account, category account description
	//UsedAccountsTable = Object.BankTransactionsUnaccepted.Unload(,"CategoryAccount, CategoryAccountDescription");
	//UsedUserAccountsTable = Object.BankTransactionsUnaccepted.Unload(,"Category, UserCategoryAccountDescription");
	//UsedUserAccountsTable.GroupBy("Category, UserCategoryAccountDescription");
	//For Each UserAccount In UsedUserAccountsTable Do
	//	NewRow = UsedAccountsTable.Add();
	//	NewRow.CategoryAccount = UserAccount.Category;
	//	NewRow.CategoryAccountDescription = UserAccount.UserCategoryAccountDescription;
	//EndDo;
	//UsedAccountsTable.GroupBy("CategoryAccount, CategoryAccountDescription");
	//FoundRows = UsedAccountsTable.FindRows(New Structure("CategoryAccount", ChartsOfAccounts.ChartOfAccounts.EmptyRef()));
	//If FoundRows.Count() > 0 Then
	//	UsedAccountsTable.Delete(FoundRows[0]);
	//EndIf;
	//i = 0;
	//While i < UsedAccountsTable.Count() Do
	//	//Use the following representation for accounts: Account_number (account_description)
	//	CR = UsedAccountsTable[i];
	//	ElementCA = CA.Items.Add(); 
	//
	//	FieldAppearance = ElementCA.Fields.Items.Add(); 
	//	FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedCategory"); 
	// 	FieldAppearance.Use = True; 

	//	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	//	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Category"); 
	//	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	//	FilterElement.RightValue 		= CR.CategoryAccount; 
	//	FilterElement.Use				= True;
	//	
	//	ElementCA.Appearance.SetParameterValue("Text", String(CR.CategoryAccount) + " (" + CR.CategoryAccountDescription + ")");
	//	
	//	ConditionalAppearanceAccounts.Add(CR.CategoryAccount);
	//	i = i + 1;
	//EndDo;

EndProcedure

//Adds an account to conditional appearance after a transaction is unaccepted
//
&AtServer
Procedure AddAccountToConditionalAppearance(SelectedValue)
	
	CA = ThisForm.ConditionalAppearance;
	ElementCA = CA.Items.Add(); 
	
	FieldAppearance = ElementCA.Fields.Items.Add(); 
	FieldAppearance.Field = New DataCompositionField("BankTransactionsUnacceptedCategory"); 
	FieldAppearance.Use = True; 

	FilterElement = ElementCA.Filter.Items.Add(Type("DataCompositionFilterItem")); // current row filter 
	FilterElement.LeftValue 		= New DataCompositionField("Object.BankTransactionsUnaccepted.Category"); 
	FilterElement.ComparisonType 	= DataCompositionComparisonType.Equal; 
	FilterElement.RightValue 		= SelectedValue; 
	FilterElement.Use				= True;
		
	ElementCA.Appearance.SetParameterValue("Text", String(SelectedValue.Code) + " (" + SelectedValue.Description + ")");
	
	ConditionalAppearanceAccounts.Add(SelectedValue);

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
				
		//Tran.Document				= Documents.Check.EmptyRef();
		
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
		
		//Check if an account is the first occurance
		//If (ConditionalAppearanceAccounts.FindByValue(NewUnaccepted.Category) = Undefined) Then		
		//	AddAccountToConditionalAppearance(NewUnaccepted.Category);
		//EndIf;

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
	AccountingBalance = GetAccountingSuiteAccountBalance(AccountInBank.AccountingAccount);
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
	                    |			AND (Deposit.BankAccount = &AccountingAccount)
	                    |WHERE
	                    |	BankTransactions.Document IS NULL 
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
	                    |			AND (Check.BankAccount = &AccountingAccount)
	                    |WHERE
	                    |	BankTransactions.Document IS NULL 
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
	                    |			AND (InvoicePayment.BankAccount = &AccountingAccount)
	                    |WHERE
	                    |	BankTransactions.Document IS NULL 
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

&AtServer
Procedure ShowBankAccountDetails(AccountInBank)
	//Fill in bank accounts list
	Request = New Query("SELECT ALLOWED
	                    |	BankAccounts.Ref,
	                    |	BankAccounts.Description,
	                    |	BankAccounts.Owner.Icon AS Icon,
	                    |	BankAccounts.Owner.Logotype AS Logotype,
	                    |	BankAccounts.Owner.Description AS Bank,
	                    |	CASE
	                    |		WHEN BankAccounts.AvailableBalance = 0
	                    |			THEN BankAccounts.CurrentBalance
	                    |		ELSE BankAccounts.AvailableBalance
	                    |	END AS CurrentBalance,
	                    |	BankAccounts.LastUpdatedTimeUTC
	                    |FROM
	                    |	Catalog.BankAccounts AS BankAccounts
	                    |WHERE
	                    |	BankAccounts.Ref = &CurrentBankAccount");
						
	Request.SetParameter("CurrentBankAccount", AccountInBank);
	Res = Request.Execute();
	CurrentBankAccountDescription.Clear();
	CurrentBankAvailableBalance.Clear();
	Sel = Res.Choose();
	Template = FormAttributeToValue("Object").GetTemplate("Spreadsheet");
	BankAccountArea = Template.GetArea("BankAccount|Column");
	BalanceArea		= Template.GetArea("BankAccount|CurrentBalance");
	
	While Sel.Next() Do
		//Show common details
		BankAccountArea.Parameters.BankAccount = Sel.Description;
		BankAccountArea.Parameters.Bank = Sel.Bank;
		//BankAccountArea.Area(1,0,1,0).RowHeight = 1;
		//BankAccountArea.Area(1, 1, BankAccountArea.TableHeight, BankAccountArea.TableWidth).BackColor = WebColors.AliceBlue;
		CurrentBankAccountDescription.Put(BankAccountArea);
		
		//Show current details
		BalanceArea.Parameters.CurrentBalance = Format(Sel.CurrentBalance, "NFD=2; NZ=");
		LastUpdated = ToLocalTime(Sel.LastUpdatedTimeUTC, SessionTimeZone());
		BalanceArea.Parameters.AccountLastUpdated = ?(ValueIsFilled(Sel.LastUpdatedTimeUTC),Format(LastUpdated, "DLF=DT"), "Not updated");
		CurrentBankAvailableBalance.Put(BalanceArea);
		
	EndDo;
	
	
	//CurrentBankAccountDescription.CurrentArea = Undefined;

EndProcedure

&AtServer
Procedure UpdateDiagram()
	Diagram.RefreshEnabled = False;
	Diagram.Clear();
	DepositsSeries = Diagram.SetSeries("Deposits");
	PaymentsSeries = Diagram.SetSeries("Payments");
	DepositsSeries.Color = Items.DepositsColor.BackColor;
	PaymentsSeries.Color = Items.PaymentsColor.BackColor;
	
	MonthData = GetDataForDiagram(AccountInBank);
	For Each Row In MonthData Do
		MonthRepresentation = Format(Row.Month, "DF=MMMM");
		MonthPoint = Diagram.SetPoint(MonthRepresentation);
		Diagram.SetValue(MonthPoint, DepositsSeries, Row.Deposits/1000,, "Deposits in " + MonthRepresentation + ": " + Format(Row.Deposits, "NFD=2; NZ="));
		Diagram.SetValue(MonthPoint, PaymentsSeries, -1 * Row.Payments/1000,, "Payments in " + MonthRepresentation + ": " + Format(Row.Payments, "NFD=2; NZ="));
	EndDo;
	Diagram.ShowLegend = False;
	Diagram.RefreshEnabled = True;
EndProcedure

&AtServerNoContext
Function GetDataForDiagram(BankAccount)
	Request = New Query("SELECT ALLOWED
	                    |	BEGINOFPERIOD(BankTransactions.TransactionDate, MONTH) AS Month,
	                    |	SUM(CASE
	                    |			WHEN BankTransactions.Amount >= 0
	                    |				THEN BankTransactions.Amount
	                    |			ELSE 0
	                    |		END) AS Deposits,
	                    |	SUM(CASE
	                    |			WHEN BankTransactions.Amount < 0
	                    |				THEN BankTransactions.Amount
	                    |			ELSE 0
	                    |		END) AS Payments
	                    |FROM
	                    |	InformationRegister.BankTransactions AS BankTransactions
	                    |WHERE
	                    |	BankTransactions.BankAccount = &BankAccount
	                    |	AND BankTransactions.TransactionDate >= &BeginOfPeriod
	                    |	AND BankTransactions.TransactionDate <= &EndOfPeriod
	                    |	AND (BankTransactions.ID = BankTransactions.OriginalID
	                    |			OR BankTransactions.OriginalID = &EmptyID)
	                    |
	                    |GROUP BY
	                    |	BEGINOFPERIOD(BankTransactions.TransactionDate, MONTH)
	                    |
	                    |ORDER BY
	                    |	Month");
	CurDate 			= CurrentUniversalDate();
	LocalDate 			= ToLocalTime(CurDate, SessionTimeZone());
	EndOfThisMonth		= EndOfMonth(LocalDate);
	BegOfThisMonth 		= BegOfMonth(LocalDate);
	BegOfPeriod			= AddMonth(BegOfThisMonth, -2);
	Request.SetParameter("BankAccount", BankAccount);
	Request.SetParameter("BeginOfPeriod", BegOfPeriod);
	Request.SetParameter("EndOfPeriod", EndOfThisMonth);
	Request.SetParameter("EmptyID", New UUID("00000000-0000-0000-0000-000000000000"));
	Sel = Request.Execute().Choose();
	Result = New Array();
	While Sel.Next() Do
		Result.Add(New Structure("Month, Deposits, Payments", Sel.Month, Sel.Deposits, Sel.Payments));
	EndDo;
	return Result;
	
EndFunction

&AtServerNoContext
Function GetAccountingSuiteAccountBalance(AccountingAccount)
	Request = New Query("SELECT
	                    |	GeneralJournalBalance.AmountBalance
	                    |FROM
	                    |	AccountingRegister.GeneralJournal.Balance(, Account = &Account, , ) AS GeneralJournalBalance");
	Request.SetParameter("Account", AccountingAccount);
	Res = Request.Execute().Choose();
	If Res.Next() Then
		return Res.AmountBalance;
	Else
		return 0;
	EndIf;
EndFunction

&AtServerNoContext
Function RemoveAccountAtServer(Item)
	return Yodlee.RemoveYodleeBankAccountAtServer(Item);
	//If Item.ItemID = 0 Then
	//	return Yodlee.RemoveBankAccountAtServer(Item);
	//Else
	//	//If we delete the last unmarked bank account then
	//	//we should remove these accounts from Yodlee
	//	//If not - just mark for deletion
	//	SetPrivilegedMode(True);
	//	ItemID = Item.ItemID;
	//	Request = New Query("SELECT
	//						|	COUNT(DISTINCT BankAccounts.Ref) AS UsedAccountsCount
	//						|FROM
	//						|	Catalog.BankAccounts AS BankAccounts
	//						|WHERE
	//						|	BankAccounts.ItemID = &ItemID
	//						|	AND BankAccounts.DeletionMark = FALSE");
	//	Request.SetParameter("ItemID",ItemID);
	//	Res = Request.Execute();
	//	Sel = Res.Choose();
	//	Sel.Next();
	//	SetPrivilegedMode(False);
	//	If (Sel.UsedAccountsCount = 1) Then
	//		return Yodlee.RemoveBankAccountAtServer(Item);
	//	Else
	//		ReturnStruct = New Structure("ReturnValue, Status, CountDeleted, DeletedAccounts", true, "", 0, New Array());
	//		DeletedAccounts = New Array();
	//		ItemDescription = Item.Description;
	//		DeletedAccounts.Add(Item);
	//		AccObject = Item.GetObject();
	//		AccObject.SetDeletionMark(True);
	//		ReturnStruct.Insert("CountDeleted", 1);
	//		ReturnStruct.Insert("DeletedAccounts", DeletedAccounts);
	//		ReturnStruct.Insert("Status", "Account " + ItemDescription + " was successfully deleted");
	//		return ReturnStruct;
	//	EndIf;
	//EndIf;
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
	AcceptCategories();
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
Procedure ProcessingPeriodOnChange(Item)
	//An Upload period influences only an uploading proccess
	//RestoreModificationState();
	//AskSave();
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedBeforeAddRow(Item, Cancel, Clone, Parent, Folder)
	If Clone then
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure BankAccountOnChange(Item)
	
	//Items.BankAccountRefreshedOn.Title = "";
	AttributeValues = CommonUse.GetAttributeValues(AccountInBank, "AccountingAccount, LastUpdatedTimeUTC, CurrentBalance, AvailableBalance, YodleeAccount");
	//Object.BankAccount = CommonUse.GetAttributeValue(AccountInBank, "AccountingAccount");
	Object.BankAccount = AttributeValues.AccountingAccount;
	
	If Not ValueIsFilled(Object.BankAccount) Then
		//AccountInBank = PredefinedValue("Catalog.BankAccounts.EmptyRef");
		AccountLastUpdated = "";
		ShowMessageBox(, "The selected bank account is not associated with a General Ledger Account." + Chars.LF + "Please enter the appropriate G/L Account on the bank account details form at Bank/Tools/Manage Bank Accounts",,"Downloaded transactions");
		return;
	EndIf;
	//LastUpdated 		= ToLocalTime(CommonUse.GetAttributeValue(AccountInBank, "LastUpdatedTimeUTC")); 
	LastUpdated 		= ToLocalTime(AttributeValues.LastUpdatedTimeUTC); 
	AccountLastUpdated 	= FormLastUpdatedString(LastUpdated); //?(ValueIsFilled(LastUpdated), Format(LastUpdated, "DLF=DT"), "");
	
	AccountAvailableBalance = ?(ValueIsFilled(AttributeValues.CurrentBalance), AttributeValues.CurrentBalance, AttributeValues.AvailableBalance);
	AccountingBalance = GetAccountingSuiteAccountBalance(AttributeValues.AccountingAccount);
		
	RestoreModificationState();
	AskSave();
	
	YodleeAccount = AttributeValues.YodleeAccount;
		
	UpdateDiagram();
EndProcedure

&AtClient
Function FormLastUpdatedString(LastUpdated)
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
	ApplyHiddenTransactionsAppearance();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	ApplyHiddenTransactionsAppearance();
	UpdateDiagram();
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
		ElsIf TypeOf(Parameters) = Type("Array") Then
			For Each CurParam In Parameters Do
				DeleteTransactionAtServer(CurParam.TranID);
				CurRow = Object.BankTransactionsUnaccepted.FindByID(CurParam.RowID);
				Object.BankTransactionsUnaccepted.Delete(Object.BankTransactionsUnaccepted.IndexOf(CurRow));				
			EndDo;
		EndIf;
    EndIf;
	SetModificationState(False);
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	DeleteTransaction(Undefined);
EndProcedure

&AtClient
Procedure EditAccount(Command)
	If Not YodleeAccount Then
		return;		
	EndIf;
	
	Notify = New NotifyDescription("OnComplete_RefreshTransactions", ThisObject);
	Params = New Structure("PerformEditAccount, RefreshAccount", True, AccountInBank);
	OpenForm("DataProcessor.YodleeBankAccountsManagement.Form.Form", Params, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
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
Procedure DeleteAccount(Command)
	//Disconnect from the Provider (Yodlee)
	//Then mark for deletion
	CurrentLine = Items.AvailableBankAccounts.CurrentData;
	CurrentRow 	= Items.AvailableBankAccounts.CurrentRow;
	If CurrentLine = Undefined Then
		return;
	EndIf;
	//Ask a user
	Mode = QuestionDialogMode.YesNoCancel;
	Notify = New NotifyDescription("DeleteAccountAfterQuery", ThisObject, New Structure("CurrentLine, CurrentRow", CurrentLine, CurrentRow));
	ShowQueryBox(Notify, "Bank account " + String(CurrentLine.Value) + " will be deleted. Are you sure?", Mode, 0, DialogReturnCode.Cancel, "Downloaded transactions"); 
	
EndProcedure

&AtClient
Procedure UploadFromCSV(Command)
	CSV_FilenameStartChoice(Undefined, Undefined, Undefined);
EndProcedure

#ENDREGION

#REGION OTHER_FUNCTIONS
////////////////////////////////////////////////////////////////////////////////
// OTHER FUNCTIONS

//Accepts suggested (default) categories
//If the user didn't fill it manually
&AtClient 
Procedure AcceptCategories()
	i = 0;
	While i < Object.BankTransactionsUnaccepted.Count() Do
		CurLine = Object.BankTransactionsUnaccepted[i];
		If Not CurLine.Accept Then
			i = i + 1;
			Continue;
		EndIf;
		If Not ValueIsFilled(CurLine.Category) Then
			If ValueIsFilled(CurLine.CategoryAccount) Then
				CurLine.Category = CurLine.CategoryAccount;
			EndIf;
		EndIf;
		i = i + 1;
	EndDo;
EndProcedure

&AtClient
Procedure SetModificationState(State)
	FormIsModified = State;
	ThisForm.Modified = FormIsModified;
EndProcedure

&AtClient
Function GetModificationState()
	Return ?(FormIsModified = Undefined, False, FormIsModified);
EndFunction

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
	i = 0;
	While i < Object.BankTransactionsUnaccepted.Count() Do
		CurTran = Object.BankTransactionsUnaccepted[i];
		If Not CurTran.Accept Then
			i = i + 1;
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
		If (Not ValueIsFilled(CurTran.Category)) And (Not ValueIsFilled(CurTran.Document)) Then
			Result = False;
			MessageToTheUser("Category", "Category", CurTran.LineNumber);	
		EndIf;
		i = i + 1;
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
		RecordTransactionToTheDatabase(Items.BankTransactionsUnaccepted.CurrentData);
		Return;
	ElsIf SelectedValue = "Match" Then
		SelectedValue = "Assign";
		//Open DocumentJournal
		DM = GetForm("DataProcessor.DownloadedTransactions.Form.DocumentMatching",,Item);
		FilterType = DM.DocumentList.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterType.LeftValue = New DataCompositionField("Type");
		FilterType.ComparisonType = DataCompositionComparisonType.InList;
		DocList = New ValueList();
		If Items.BankTransactionsUnaccepted.CurrentData.Amount < 0 Then
			DocList.Add(Type("DocumentRef.Check"));
			DocList.Add(Type("DocumentRef.InvoicePayment"));
			AmountFilterValue = -1*Items.BankTransactionsUnaccepted.CurrentData.Amount;
		Else
			DocList.Add(Type("DocumentRef.CashReceipt"));
			DocList.Add(Type("DocumentRef.Deposit"));
			AmountFilterValue = Items.BankTransactionsUnaccepted.CurrentData.Amount;
		EndIf;
		FilterType.RightValue = DocList;
		FilterType.Use = True;
		
		FilterTotal = DM.DocumentList.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterTotal.LeftValue = New DataCompositionField("Total");
		FilterTotal.ComparisonType = DataCompositionComparisonType.Equal;
		FilterTotal.RightValue = AmountFilterValue;
		FilterTotal.Use = True;
		
		DM.CloseOnChoice = True;
		DM.WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
		DM.Open();
		return;
		//If Items.BankTransactionsUnaccepted.CurrentData.Amount < 0 Then
		//	OpenForm("Document.Check.ChoiceForm", , Item);	
		//Else
		//	CashReceiptFilter 	= New Structure("DepositType", "1");//Undeposited
		//	CashReceiptParams	= New Structure("Filter", CashReceiptFilter);
		//	OpenForm("Document.CashReceipt.ChoiceForm", CashReceiptParams, Item);	
		//EndIf;
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
	Else
		Return "Assign";
	EndIf;
EndFunction

&AtClient
Procedure OnComplete_RefreshTransactions(ClosureResult, AdditionalParameters) Export
	AttributeValues = CommonUse.GetAttributeValues(AccountInBank, "LastUpdatedTimeUTC, CurrentBalance, AvailableBalance");
	LastUpdated = ToLocalTime(AttributeValues.LastUpdatedTimeUTC);
	AccountLastUpdated 	= FormLastUpdatedString(LastUpdated); //?(ValueIsFilled(LastUpdated), Format(LastUpdated, "DLF=DT"), "");
	AccountAvailableBalance = ?(ValueIsFilled(AttributeValues.CurrentBalance), AttributeValues.CurrentBalance, AttributeValues.AvailableBalance);
	UnlockYodleeConnection(ThisForm.UUID);
	//Items.BankAccountRefreshedOn.Title = "Refreshed on: " + Format(AccountLastUpdated, "DLF=DT");	
	UploadTransactionsFromDB(,,True);
	ApplyHiddenTransactionsAppearance();
EndProcedure

&AtClient
Procedure DiagramTypeOnChange(Item)
	CurType = Undefined;
	For Each ChType In ChartType Do
		If String(ChType) = DiagramType Then
			CurType = ChType; 
			Break;
		EndIf;
	EndDo;
	Diagram.ChartType = CurType;
EndProcedure

&AtClient
Procedure AvailableBankAccountsOnActivateRow(Item)
	If Item.CurrentData = Undefined Then
		return;
	EndIf;
	If AccountInBank = Item.CurrentData.Value Then
		return;
	EndIf;
	AccountInBank = Item.CurrentData.Value;
		
	AttachIdleHandler("ProcessBankAccountChange", 0.1, True);
	
EndProcedure

&AtClient
Procedure ProcessBankAccountChange() Export
	BankAccountOnChange(Items.BankAccount);
EndProcedure

&AtClient
Procedure OnComplete_AddAccount(ClosureResult, AdditionalParameters) Export
	If ClosureResult <> Undefined Then
		If TypeOf(ClosureResult) = Type("Array") Then
			i = 0;
			While i < ClosureResult.Count() Do
				NewAddedItem = ClosureResult[i];
				If TypeOf(NewAddedItem) = Type("CatalogRef.BankAccounts") Then
					NewAccountDescription = CommonUse.GetAttributeValue(NewAddedItem, "Description");
					AddedItem = AvailableBankAccounts.Add(NewAddedItem, NewAccountDescription);
					If i = ClosureResult.Count()-1 Then
						AddedItemID = AddedItem.GetID();
						Items.AvailableBankAccounts.CurrentRow = AddedItemID;
						AvailableBankAccountsOnActivateRow(Items.AvailableBankAccounts);
					EndIf;
					i = i + 1;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteAccountAfterQuery(Result, Parameters) Export
	If Result <> DialogReturnCode.Yes Then
		return;
	EndIf;
	
	//Disconnect from the Provider (Yodlee)
	//Then mark for deletion
	CurrentLine = Parameters.CurrentLine;
	CurrentRow	= Parameters.CurrentRow;
	If CurrentLine <> Undefined Then
		ReturnStruct = RemoveAccountAtServer(CurrentLine.Value);
		If ReturnStruct.returnValue Then
			ShowMessageBox(, ReturnStruct.Status,,"Removing bank account");
		Else
			If Find(ReturnStruct.Status, "InvalidItemExceptionFaultMessage") Then
				ShowMessageBox(, "Account not found.",,"Removing bank account");
			Else
				ShowMessageBox(, ReturnStruct.Status,,"Removing bank account");
			EndIf;
		EndIf;
		
		DeletedAccounts = ReturnStruct.DeletedAccounts;
		If ReturnStruct.CountDeleted > 0 Then
			cnt = 0;
			While cnt < AvailableBankAccounts.Count() Do
				AvAcc = AvailableBankAccounts[cnt];
				If DeletedAccounts.Find(AvAcc.Value) <> Undefined Then
					AvailableBankAccounts.Delete(AvAcc);
				Else
					cnt = cnt + 1;
				EndIf;	
			EndDo;
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure AvailableBankAccountsSelection(Item, SelectedRow, Field, StandardProcessing)
	ShowValue(,Item.CurrentData.Value);
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedOnActivateRow(Item)
	If Item.CurrentData = Undefined Then
		return;
	EndIf;
	// Fill category choice list
	ChoiceList = Items.BankTransactionsUnacceptedCategory.ChoiceList;
	ChoiceList.Clear();
	CategoryAccount = Item.CurrentData.CategoryAccount; 
	AccountDescription = CommonUse.GetAttributeValue(CategoryAccount, "Description");
	CategoryDescription = Item.CurrentData.CategoryDescription;
	CategoryID = Item.CurrentData.CategoryID;
	If ValueIsFilled(CategoryAccount) Then
		//ChoiceList.Add(CategoryAccount, "Accept: " + CategoryDescription + " (" + String(CategoryAccount) + "-" + AccountDescription + ")");
		ChoiceList.Add(CategoryAccount, "Accept: "  + CategoryDescription + " (" + String(CategoryAccount) + ")");
	ElsIf ValueIsFilled(CategoryID) Then
		ChoiceList.Add(PredefinedValue("ChartOfAccounts.ChartOfAccounts.EmptyRef"), "Assign account to: " + CategoryDescription);
	Else
	EndIf;
	If (ValueIsFilled(Item.CurrentData.Category)) And (Item.CurrentData.CategorizedCategoryNotAccepted) Then
		ChoiceList.Add(Item.CurrentData.Category, "Accept: " + String(Item.CurrentData.Category));
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
EndProcedure

&AtClient
Procedure BankTransactionsUnacceptedCategoryChoiceProcessing(Item, SelectedValue, StandardProcessing)
	//Message("Selected value:" + String(SelectedValue));
	If SelectedValue = PredefinedValue("ChartOfAccounts.ChartOfAccounts.EmptyRef") Then
		StandardProcessing = False;
		Notify = New NotifyDescription("AssignCategoryAccount", ThisObject, New Structure("CurrentRow", Items.BankTransactionsUnaccepted.CurrentRow));
		OpenForm("Catalog.BankTransactionCategories.ObjectForm", New Structure("Key", Items.BankTransactionsUnaccepted.CurrentData.CategoryRef), ThisForm,,,,Notify,FormWindowOpeningMode.LockOwnerWindow);
				
	Else //If a user changed the suggested category account - then add it to conditional appearance
		//Check if an account is the first occurance
		//If (ConditionalAppearanceAccounts.FindByValue(SelectedValue) = Undefined) Then
		//	AddAccountToConditionalAppearance(SelectedValue);
		//EndIf;
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
		//RecordTransactionToTheDatabase(Items.BankTransactionsUnaccepted.CurrentData);
	EndIf;
EndProcedure

&AtClient
Procedure DeleteSelectedTransactions(Command)
	SelRows = Items.BankTransactionsUnaccepted.SelectedRows;
	If SelRows.Count() = 0 Then
		return;
	EndIf;
	Params = New Array;
	For Each RowID In SelRows Do
		CurRow = Object.BankTransactionsUnaccepted.FindByID(RowID);		
		If Not ValueIsFilled(CurRow.TransactionID) Then
			Object.BankTransactionsUnaccepted.Delete(RowID);
		//Should ask the user whether to delete or not
		Else
			Params.Add(New Structure("TranID, RowID", CurRow.TransactionID, RowID));
		EndIf;
	EndDo;
	Mode = QuestionDialogMode.YesNoCancel;
	Notify = New NotifyDescription("DeleteOrNotResult", ThisObject, Params);
	If QuestionAsked = Undefined then
		QuestionAsked = False;
	EndIf;
	If Not QuestionAsked then
		If SelRows.Count() = 1 Then
			ShowQueryBox(Notify, "The current transaction will be removed from the database permanently. Continue?", Mode, 0, DialogReturnCode.Cancel, "Downloaded transactions");
		Else
			ShowQueryBox(Notify, "The selected transactions will be removed from the database permanently. Continue?", Mode, 0, DialogReturnCode.Cancel, "Downloaded transactions");
		EndIf;
		QuestionAsked = True;
	EndIf;
EndProcedure

&AtClient
Procedure DecorationProcessingPeriodClick(Item)
	Notify = New NotifyDescription("OnProcessingPeriodChange", ThisObject, New Structure());
	Params = New Structure("ProcessingPeriod", Object.ProcessingPeriod);
	OpenForm("DataProcessor.DownloadedTransactions.Form.ProcessingPeriod", Params, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
	//ShowInputValue(Notify,Object.ProcessingPeriod,, Type("StandardPeriod"));
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
	
	//UploadTransactionsFromDB(,,True);
	//ApplyHiddenTransactionsAppearance();
	
EndProcedure

&AtClient
Procedure CategorizeTransactions(Command)
	//Categorizing transactions asynchronously
	Notify = New NotifyDescription("OnComplete_CategorizeTransactions", ThisObject);
	Params = New Structure("BankAccount, PerformCategorization", AccountInBank, True);
	OpenForm("DataProcessor.DownloadedTransactions.Form.ProgressForm", Params, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
	
		
	//Show the ProgressGroup, Attach idle handler
		
	return;
		
	NewTransactions = New Array;
	i = 0;
	While i < Object.BankTransactionsUnaccepted.Count() Do
		CurTran = Object.BankTransactionsUnaccepted[i];
		NewTransactions.Add(New Structure("BankAccount, Description, ID, RowID", CurTran.BankAccount, CurTran.Description, CurTran.TransactionID, i));
		i = i + 1;
	EndDo;
	ReturnArray = CategorizeTransactionsAtServer(NewTransactions);
	ProcessedArray = New Array();
	For Each CategorizedTran IN ReturnArray Do
		CompanyFilled = False;
		CategoryFilled = False;
		ProcessedArray.Add(CategorizedTran.RowID);
		BTUnaccepted = Object.BankTransactionsUnaccepted[CategorizedTran.RowID];
		//Apply categorized company if it is not filled
		If (Not ValueIsFilled(BTUnaccepted.Company)) Or (BTUnaccepted.CategorizedCompanyNotAccepted) Then 
			//If ValueIsFilled(CategorizedTran.Customer) Then
				BTUnaccepted.Company = CategorizedTran.Customer;
				BTUnaccepted.CategorizedCompanyNotAccepted = True;
				CompanyFilled = True;
			//EndIf;
		EndIf;
		If (Not ValueIsFilled(BTUnaccepted.Category)) Or (BTUnaccepted.CategorizedCategoryNotAccepted) Then 
			//If ValueIsFilled(CategorizedTran.Category) Then
				If (BTUnaccepted.CategoryAccount <> CategorizedTran.Category) Then
					BTUnaccepted.Category = CategorizedTran.Category;
					BTUnaccepted.CategorizedCategoryNotAccepted = True;
					CategoryFilled = True;
				EndIf;
			//EndIf;
		EndIf;
		If CompanyFilled OR CategoryFilled Then
			RecordTransactionToTheDatabase(BTUnaccepted);
		EndIf;
	EndDo;
	//Clear previously categorized transactions, which are absent this time
	i = 0;
	EmptyCompany = PredefinedValue("Catalog.Companies.EmptyRef");
	EmptyCategory = PredefinedValue("ChartOfAccounts.ChartOfAccounts.EmptyRef");
	While i < Object.BankTransactionsUnaccepted.Count() Do
		If ProcessedArray.Find(i) <> Undefined Then
			i = i + 1;
			Continue;
		EndIf;
		CompanyWasCleared = False;
		CategoryWasCleared = False;
		BTUnaccepted = Object.BankTransactionsUnaccepted[i];
		If (ValueIsFilled(BTUnaccepted.Company)) And (BTUnaccepted.CategorizedCompanyNotAccepted) Then
			BTUnaccepted.Company = EmptyCompany;
			BTUnaccepted.CategorizedCompanyNotAccepted = False;
			CompanyWasCleared =True;
		EndIf;
		If (ValueIsFilled(BTUnaccepted.Category)) And (BTUnaccepted.CategorizedCategoryNotAccepted) Then
			BTUnaccepted.Category = EmptyCategory;
			BTUnaccepted.CategorizedCategoryNotAccepted = False;
			CategoryWasCleared = True;
		EndIf;
		i = i + 1;
		If CompanyWasCleared OR CategoryWasCleared Then
			RecordTransactionToTheDatabase(BTUnaccepted);
		EndIf;
	EndDo;
EndProcedure

&AtServerNoContext
Function CategorizeTransactionsAtServer(NewTransactions)
	ReturnArray = Categorization.CategorizeTransactions(NewTransactions);
	return ReturnArray;
EndFunction

&AtClient
Procedure BankTransactionsUnacceptedCompanyChoiceProcessing(Item, SelectedValue, StandardProcessing)
	Items.BankTransactionsUnaccepted.CurrentData.CategorizedCompanyNotAccepted = False;
EndProcedure

#ENDREGION
