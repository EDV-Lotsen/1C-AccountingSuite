
Procedure OnWrite(Cancel)
	
	If Not Cancel Then
		
		WriteHierarchy(Ref);
		
		ChartOfAccountsSelection = ChartsOfAccounts.ChartOfAccounts.SelectHierarchically(Ref);
		While ChartOfAccountsSelection.Next() Do
			WriteHierarchy(ChartOfAccountsSelection.Ref);
		EndDo;
		
	EndIf;
	
	//For bank account types (bank, other current liability + credit card) create bank account
	If AccountType = Enums.AccountTypes.Bank 
		Or ((AccountType = Enums.AccountTypes.OtherCurrentLiability) And CreditCard) Then
		//Bank account not found. Need to create the new one
		Block = New DataLock();
		LockItem = Block.Add("Catalog.BankAccounts");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		Request = New Query("SELECT
		                    |	BankAccounts.Ref
		                    |FROM
		                    |	Catalog.BankAccounts AS BankAccounts
		                    |WHERE
		                    |	BankAccounts.AccountingAccount = &AccountingAccount");
		Request.SetParameter("AccountingAccount", Ref);
		Res = Request.Execute();
		If Res.IsEmpty() Then
			Bank = Catalogs.Banks.EmptyRef();
			//Select Offline bank
			//Try to find the Offline bank, if not found then create the new one
			Request = New Query("SELECT
			                    |	Banks.Ref
			                    |FROM
			                    |	Catalog.Banks AS Banks
			                    |WHERE
			                    |	Banks.Code = ""000000000""");
			Res = Request.Execute();
			If Res.IsEmpty() Then
				SetPrivilegedMode(True);
				OfflineBank = Catalogs.Banks.CreateItem();
				OfflineBank.Code 		= "000000000";
				OfflineBank.Description = "Offline bank";
				OfflineBank.Write();
				SetPrivilegedMode(False);
				Bank = OfflineBank.Ref;
			Else
				Sel = Res.Select();
				Sel.Next();
				Bank = Sel.Ref;
			EndIf;
			NewAccount = Catalogs.BankAccounts.CreateItem();
			NewAccount.Owner = Bank;
			NewAccount.Description = Description;
			NewAccount.AccountingAccount = Ref;
			NewAccount.Write();
		EndIf;	
		
	EndIf;
	//If Not Parent.IsEmpty() And AccountType <> Parent.AccountType Then 
	//	Message("The account type must be the same as the parent account",MessageStatus.Attention);
	//	Cancel = True;
	//EndIf;
	
EndProcedure

Function GetHierarchy(Item, Route)
	
	Route = Route + Item.Code + "/";
	
	If ValueIsFilled(Item.Parent) Then
		GetHierarchy(Item.Parent, Route)	
	EndIf;	
	
	Return Route;	
	
EndFunction	

Procedure WriteHierarchy(Item)
	
	IR = InformationRegisters.HierarchyChartOfAccounts.CreateRecordSet();
	IR.Filter.Account.Set(Item);
	
	NewIRecord = IR.Add();
	NewIRecord.Account = Item;
	NewIRecord.Route = GetHierarchy(Item, "/");
	
	IR.Write();
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If Not Parent.IsEmpty() And AccountType <> Parent.AccountType Then 
		Message("The account type must be the same as the parent account",MessageStatus.Attention);
		Cancel = True;
		return;
	EndIf;

	If AdditionalProperties.Property("IsNew") AND AdditionalProperties.Property("StartCode")
		AND AdditionalProperties.Property("EndCode") AND AdditionalProperties.Property("AccountType") Then
		//Set DataLock on ChartOfAccounts
		GLLock = New DataLock();
		LockItem = GLLock.Add("ChartOfAccounts.ChartOfAccounts");
		LockItem.Mode = DataLockMode.Exclusive;
		GLLock.Lock();
		NewCode = GeneralFunctions.FindVacantCode(AdditionalProperties.StartCode, AdditionalProperties.EndCode, AdditionalProperties.AccountType);
		If Not ValueIsFilled(NewCode) Then
			NewCode = GeneralFunctions.FindVacantCode("9000", "9999", AdditionalProperties.AccountType);
		EndIf;
		Code = NewCode;
		Order = Code;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	Code = "";
EndProcedure

Procedure BeforeDelete(Cancel)
	
	//For bank account types (bank, other current liability + credit card) delete bank account
	If AccountType = Enums.AccountTypes.Bank 
		Or ((AccountType = Enums.AccountTypes.OtherCurrentLiability) And CreditCard) Then
		Request = New Query("SELECT
		                    |	BankAccounts.Ref
		                    |FROM
		                    |	Catalog.BankAccounts AS BankAccounts
		                    |WHERE
		                    |	BankAccounts.AccountingAccount = &AccountingAccount");
		Request.SetParameter("AccountingAccount", Ref);
		Res = Request.Execute();
		If Not Res.IsEmpty() Then //Bank account not found. Need to create the new one
			Sel = Res.Select();
			Sel.Next();
			BankAccount = Sel.Ref;
			BankAccountObject = BankAccount.GetObject();
			BankAccountObject.AccountingAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef();
			BankAccountObject.Write();
			BankAccountObject.Delete();
		EndIf;
	EndIf;
	
	//Clear Bank Transaction Categorization
	SetPrivilegedMode(True);
	Request = New Query("SELECT
	                    |	BankTransactionCategorization.TransactionID
	                    |FROM
	                    |	InformationRegister.BankTransactionCategorization AS BankTransactionCategorization
	                    |WHERE
	                    |	BankTransactionCategorization.Category = &Category
	                    |
	                    |GROUP BY
	                    |	BankTransactionCategorization.TransactionID");
	Request.SetParameter("Category", Ref);
	IdsTable = Request.Execute().Unload();
	For Each IDRow In IdsTable Do
		BTCRecordset = InformationRegisters.BankTransactionCategorization.CreateRecordSet();
		BTCRecordset.Filter.TransactionID.Set(IDRow.TransactionID);
		BTCRecordset.Write(True);
	EndDo;
	SetPrivilegedMode(False);

EndProcedure
