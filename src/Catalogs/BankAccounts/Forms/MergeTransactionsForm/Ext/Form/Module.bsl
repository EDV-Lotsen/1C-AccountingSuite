
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Not Constants.ServiceDB.Get() Then
		Cancel = True;
		return;
	EndIf;

	BankAccount = Parameters.BankAccount;
	ThisForm.Title = String(BankAccount);
	//Obtain list of available offline accounts
	Request = New Query("SELECT
	                    |	BankAccounts.Ref,
	                    |	BankAccounts.Presentation
	                    |FROM
	                    |	Catalog.BankAccounts AS BankAccounts
	                    |WHERE
	                    |	BankAccounts.YodleeAccount = FALSE
	                    |	AND BankAccounts.Ref <> &CurrentBankAccount");
	Request.SetParameter("CurrentBankAccount", BankAccount);
	ChoiceList = Items.SourceBankAccount.ChoiceList;
	ChoiceList.Clear();
	Sel = Request.Execute().Select();
	While Sel.Next() Do
		ChoiceList.Add(Sel.Ref, Sel.Presentation);
		If TrimAll(Sel.Presentation) = TrimAll(String(BankAccount)) Then
			SourceBankAccount = Sel.Ref;
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure Merge(Command)
	Result = MergeAtServer();
	If Result Then
		CommonUseClient.ShowCustomMessageBox(ThisForm, "Merge", "Merge succeeded", PredefinedValue("Enum.MessageStatus.Information"));
		Notify("BankTransactionsMerge");
	Else
		CommonUseClient.ShowCustomMessageBox(ThisForm, "Merge", "Merge failed. Please, repeat the operation!", PredefinedValue("Enum.MessageStatus.Warning"));
	EndIf;
EndProcedure

&AtServer
Function MergeAtServer()
	ErrorOccured = False;
	BeginTransaction(DataLockControlMode.Managed);
	Try
		DL = New DataLock();
		LockItem = DL.Add("InformationRegister.BankTransactions");
		LockItem.Mode = DataLockMode.Exclusive;
		LockSource = New ValueTable();
		LockSource.Columns.Add("BankAccount", New TypeDescription("CatalogRef.BankAccounts"));
		NewRow = LockSource.Add();
		NewRow.BankAccount = BankAccount;
		NewRow = LockSource.Add();
		NewRow.BankAccount = SourceBankAccount;
		LockItem.DataSource = LockSource;
		LockItem.UseFromDataSource("BankAccount", "BankAccount");
		DL.Lock();
		//Remove transactions of the current bank account
		If RemoveTransactionsOfTheAccountBeforeMerge Then
			DataSet = InformationRegisters.BankTransactions.CreateRecordSet();
			DataSet.Filter.BankAccount.Set(BankAccount);
			DataSet.Write = True;
			DataSet.Write(True);
		EndIf;
		
		//Moving bank transactions from the source account to the current bank account
		DestinationSet = InformationRegisters.BankTransactions.CreateRecordSet();
		DestinationSet.Filter.BankAccount.Set(BankAccount);
		DestinationSet.Read();
		
		SourceDataSet = InformationRegisters.BankTransactions.CreateRecordSet();
		SourceDataSet.Filter.BankAccount.Set(SourceBankAccount);
		SourceDataSet.Read();
		For Each SourceRecord In SourceDataSet Do
			NewRec = DestinationSet.Add();
			FillPropertyValues(NewRec, SourceRecord);
			NewRec.BankAccount = BankAccount;
		EndDo;
		SourceDataSet.Clear();
		SourceDataSet.Write = True;
		SourceDataSet.Write(True);
		
		DestinationSet.Write = True;
		DestinationSet.Write(True);
		
		CommitTransaction();
	Except
		Error = ErrorDescription();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		Message(Error, MessageStatus.Important);
		ErrorOccured = True;
	EndTry;
	return Not ErrorOccured;
EndFunction
