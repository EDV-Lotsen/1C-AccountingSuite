////////////////////////////////////////////////////////////////////////////////
// Yodlee Integration: Server
//------------------------------------------------------------------------------
// Available on:
// - Server
//

////////////////////////////////////////////////////////////////////////////////

#Region PUBLIC_INTERFACE

//Updates banks catalog
//Used in background scheduled job
//
Procedure YodleeUpdateBanks() Export
Try
	YodleeMain	= New ComObject("YodleeCom.YodleeMain"); 
	
	ContainerServices = YodleeMain.viewContainerServices("bank");
	
	longArray = New ComObject("YodleeCom.LongArray");
	i = 0;
	longArray.CreateArray(ContainerServices.Count());
	While i < ContainerServices.Count() Do
		ContainerService = ContainerServices.GetByID(i);
		longArray.InsertValue(i, ContainerService.contentServiceID);
		i= i + 1;
	EndDo;
	
	//get logotypes of banks
	csi = YodleeMain.viewSingleServiceDetails(longArray);
		
	i = 0;
	While i < ContainerServices.Count() Do
		ContainerService = ContainerServices.GetByID(i);
		BankQuery = New Query("SELECT
		                    |	Banks.Ref
		                    |FROM
		                    |	Catalog.Banks AS Banks
		                    |WHERE
		                    |	Banks.ServiceID = &ServiceID");
		BankQuery.SetParameter("ServiceID", ContainerService.contentServiceID);
		QueryRes = BankQuery.Execute();
		If Not QueryRes.IsEmpty() Then
			BankSel = QueryRes.Choose();
			BankSel.Next();
			BankRef = BankSel.Ref;
			CurBank = BankRef.GetObject();
		Else
			CurBank = Catalogs.Banks.CreateItem();
		EndIf;
		Try
			CurBank.ServiceID 	= ContainerService.contentServiceID;
			CurBank.Description = ContainerService.contentServiceDisplayName;
			CurBAnk.ServiceURL = ContainerService.homeUrl;
			Base64Image = csi.GetFaviconImage(i);
			If Base64Image <> "" Then
				bd = Base64Value(Base64Image);
				Picture = new Picture(bd);
				CurBank.Icon = New ValueStorage(Picture);
			EndIf;
			Base64BigImage = csi.GetIconImage(i);
			If Base64BigImage <> "" Then
				bd = Base64Value(Base64BigImage);
				Picture = new Picture(bd);
				CurBank.Logotype = New ValueStorage(Picture);
			EndIf;
			CurBank.DateUpdatedUTC = CurrentUniversalDate();
			CurBank.Write();
		Except
		EndTry;
	
		i = i + 1;
	EndDo;
Except
	WriteLogEvent("Yodlee.UpdateBanks", EventLogLevel.Error,,, ErrorDescription());
EndTry;

EndProcedure

//Updates BankAccounts catalog
//Used in background scheduled job
//
Procedure YodleeUpdateBankAccounts(YodleeMain = Undefined, DeleteUninitializedAccounts = False) Export
	Try
		If YodleeMain = Undefined Then
			YodleeMain	= New ComObject("YodleeCom.YodleeMain"); 
			If Not LoginUser(YodleeMain) Then
				return;
			EndIf;

		EndIf;
		YodleeAccounts = New ValueList();
		Result = YodleeMain.viewItems();
		i = 0;
		While i < Result.Count() Do
			j = 0;
			ItemSummary = Result.GetByID(i);
			Result.FillInItemDataAccounts(ItemSummary);
			
			If Result.AccountsCount() > 0 Then // If accounts refreshed
				While j < Result.AccountsCount() Do
					bankData				= Result.GetBankDataByID(j);
					//Find an existing account
					AccountQuery = New Query("SELECT
					                         |	BankAccounts.Ref,
					                         |	CASE
					                         |		WHEN BankAccounts.ItemAccountID = &ItemAccountID
					                         |			THEN 1
					                         |		ELSE 0
					                         |	END AS Priority
					                         |FROM
					                         |	Catalog.BankAccounts AS BankAccounts
					                         |WHERE
					                         |	BankAccounts.ItemID = &ItemID
					                         |	AND (BankAccounts.ItemAccountID = &ItemAccountID
					                         |			OR BankAccounts.ItemAccountID = 0)
					                         |	AND BankAccounts.Owner.ServiceID = &ServiceID
					                         |
					                         |ORDER BY
					                         |	Priority DESC");
					AccountQuery.SetParameter("ItemID", ItemSummary.itemID);
					AccountQuery.SetParameter("ItemAccountID", ?(bankData = Undefined, 0, bankData.itemAccountID));
					AccountQuery.SetParameter("ServiceID", ItemSummary.contentServiceId);
					QueryRes = AccountQuery.Execute();
					If Not QueryRes.IsEmpty() Then
						AccountSel = QueryRes.Choose();
						AccountSel.Next();
						AccountRef = AccountSel.Ref;
						CurAccount = AccountRef.GetObject();
						YodleeAccounts.Add(AccountRef);
					Else
						CurAccount = Catalogs.BankAccounts.CreateItem();
					EndIf;
					If CurAccount.IsNew() Then //Should find owner bank
						//Find Bank
						BankQuery = New Query("SELECT
						                      |	Banks.Ref
						                      |FROM
						                      |	Catalog.Banks AS Banks
						                      |WHERE
						                      |	Banks.ServiceID = &ServiceID");
						BankQuery.SetParameter("ServiceID", ItemSummary.contentServiceId);
						QueryRes = BankQuery.Execute();
						If Not QueryRes.IsEmpty() Then
							BankSel = QueryRes.Choose();
							BankSel.Next();
							BankRef = BankSel.Ref;
						Else
							WriteLogEvent("Yodlee.UpdateBankAccounts", EventLogLevel.Error,,, "Bank with the serviceID: " + String(ItemSummary.contentServiceId) + " of the account " + String(ItemSummary.itemID) + " is not found!");
							j = j + 1;
							Continue;
						EndIf;
						CurAccount.Owner = BankRef;
					EndIf;
					
					CurAccount.ItemID = ItemSummary.itemID;
					bankData				= Result.GetBankDataByID(j);
					If bankData <> Undefined Then
						CurAccount.ItemAccountID 		= bankData.itemAccountID;
						CurAccount.AvailableBalance 	= bankData.availableBalance.amount;
						CurAccount.CurrentBalance 		= bankData.currentBalance.amount;
						CurAccount.AccountType			= bankData.acctType;
					EndIf;
					CurAccount.Description 				= ItemSummary.itemDisplayName;
					UTCUpdatedSecs						= ItemSummary.refreshInfo.lastUpdatedTime;
					CurAccount.LastUpdatedTimeUTC		= ToLocalTime('19700101' + UTCUpdatedSecs);
					UTCUpdateAttemptSecs				= ItemSummary.refreshInfo.lastUpdateAttemptTime;
					CurAccount.LastUpdateAttemptTimeUTC = ToLocalTime('19700101' + UTCUpdateAttemptSecs);
					UTCNextUpdateSecs					= ItemSummary.refreshInfo.nextUpdateTime;
					CurAccount.NextUpdateTimeUTC 		= ToLocalTime('19700101' + UTCNextUpdateSecs);
					CurAccount.RefreshStatusCode 		= ItemSummary.refreshInfo.statusCode;
					CurAccount.YodleeAccount			= True;
					Try
						CurAccount.Write();
						YodleeAccounts.Add(CurAccount.Ref);
					Except
					EndTry;
					j = j + 1;

				EndDo;
			Else
				//Find an existing account
				AccountQuery = New Query("SELECT
				                         |	BankAccounts.Ref
				                         |FROM
				                         |	Catalog.BankAccounts AS BankAccounts
				                         |WHERE
				                         |	BankAccounts.ItemID = &ItemID
				                         |	AND BankAccounts.Owner.ServiceID = &ServiceID");
				AccountQuery.SetParameter("ItemID", ItemSummary.itemID);
				AccountQuery.SetParameter("ServiceID", ItemSummary.contentServiceId);
				QueryRes = AccountQuery.Execute();
				If Not QueryRes.IsEmpty() Then
					AccountSel = QueryRes.Choose();
					AccountSel.Next();
					AccountRef = AccountSel.Ref;
					CurAccount = AccountRef.GetObject();
					YodleeAccounts.Add(AccountRef);
				Else
					CurAccount = Catalogs.BankAccounts.CreateItem();
				EndIf;
				
				If CurAccount.IsNew() Then //Should find owner bank
					//Find Bank
					BankQuery = New Query("SELECT
					                      |	Banks.Ref
					                      |FROM
					                      |	Catalog.Banks AS Banks
					                      |WHERE
					                      |	Banks.ServiceID = &ServiceID");
					BankQuery.SetParameter("ServiceID", ItemSummary.contentServiceId);
					QueryRes = BankQuery.Execute();
					If Not QueryRes.IsEmpty() Then
						BankSel = QueryRes.Choose();
						BankSel.Next();
						BankRef = BankSel.Ref;
					Else
						WriteLogEvent("Yodlee.UpdateBankAccounts", EventLogLevel.Error,,, "Bank with the serviceID: " + String(ItemSummary.contentServiceId) + " of the account " + String(ItemSummary.itemID) + " is not found!");
						i = i + 1;
						Continue;
					EndIf;
					CurAccount.Owner = BankRef;
				EndIf;
					
				CurAccount.ItemID = ItemSummary.itemID;
				CurAccount.Description 				= ItemSummary.itemDisplayName;
				UTCUpdatedSecs						= ItemSummary.refreshInfo.lastUpdatedTime;
				CurAccount.LastUpdatedTimeUTC		= ToLocalTime('19700101' + UTCUpdatedSecs);
				UTCUpdateAttemptSecs				= ItemSummary.refreshInfo.lastUpdateAttemptTime;
				CurAccount.LastUpdateAttemptTimeUTC = ToLocalTime('19700101' + UTCUpdateAttemptSecs);
				UTCNextUpdateSecs					= ItemSummary.refreshInfo.nextUpdateTime;
				CurAccount.NextUpdateTimeUTC 		= ToLocalTime('19700101' + UTCNextUpdateSecs);
				CurAccount.RefreshStatusCode 		= ItemSummary.refreshInfo.statusCode;
				CurAccount.YodleeAccount			= True;
				Try
					CurAccount.Write();
					YodleeAccounts.Add(CurAccount.Ref);
				Except
				EndTry;

			EndIf;
			i = i + 1;
		EndDo;
		//Mark not processed Items as Non-Yodlee
		Request = New Query("SELECT
		                    |	BankAccounts.Ref
		                    |FROM
		                    |	Catalog.BankAccounts AS BankAccounts
		                    |WHERE
		                    |	BankAccounts.YodleeAccount = TRUE
		                    |	AND NOT BankAccounts.Ref IN (&YodleeAccounts)");
		Request.SetParameter("YodleeAccounts", YodleeAccounts);
		ReqSelect = Request.Execute().Choose();
		While ReqSelect.Next() Do
			Try
				AccObject = ReqSelect.Ref.GetObject();
				AccObject.YodleeAccount = False;
				AccObject.Write();
			Except
			EndTry;			
		EndDo;
		If DeleteUninitializedAccounts Then
			DeleteUninitializedAccounts();
		EndIf;
	Except
		WriteLogEvent("Yodlee.UpdateBankAccounts", EventLogLevel.Error,,, ErrorDescription());
	EndTry;
EndProcedure

//Updates a list of transactions
//Used in background jobs
//
//Parameters:
// BankAccount - the bank account 
// TransactionFromDate - the beginning of transactions period (included) (the beginning of the day)
// TransactionsToDate - the end of transactions period (included) (the beginning of the day)
//
//Result:
// Structure
// ReturnValue - success/fail - boolean
// ErrorMessage - in case of failure contains error description
//
Function ViewTransactions(BankAccount, TransactionsFromDate = Undefined, TransactionsToDate = Undefined, TempStorageAddress = Undefined, YodleeStorage = Undefined) Export
	Try
		WriteLogEvent("Yodlee.UpdateTransactions", EventLogLevel.Information,,, "Update of bank transactions started");
		
		ReturnStructure = New Structure("ReturnValue, ErrorMessage");
		ReturnStructure.ReturnValue = True;
		
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Started selecting transactions...", 6), TempStorageAddress);
		EndIf;
		If ValueIsFilled(YodleeStorage) Then 
			//Restore the YodleeMain state
			Try
				Serializer 	= New ComObject("YodleeCom.Serializer");
				Result 	= Serializer.Deserialize(YodleeStorage);
				If Result.returnValue Then
					YodleeMain = Result.yodleeMain;
				EndIf;
			Except
				WriteLogEvent("Yodlee.DeserializingComponent", EventLogLevel.Error,,, ErrorDescription());
				ReturnStructure.Insert("ReturnValue", False);
				
				If TempStorageAddress <> Undefined Then
					PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Internal error...Please, repeat the operation", 6), TempStorageAddress);
				EndIf;

				return ReturnStructure;
			EndTry;
		Else
			YodleeMain	= New ComObject("YodleeCom.YodleeMain"); 
			If Not LoginUser(YodleeMain) Then
				ReturnStructure.ReturnValue = False;
				ReturnStructure.ErrorMessage = "Couldn't login to the provider";
				return ReturnStructure;
			EndIf;
		EndIf;
		
		If ValueIsFilled(TransactionsFromDate) or ValueIsFilled(TransactionsToDate) Then
			TransactionSearchResults = YodleeMain.viewTransactionsForItemAccount(BankAccount.ItemID, BankAccount.ItemAccountID, "bank", BankAccount.CurrentBalance, TransactionsFromDate, TransactionsToDate);
		else
			TransactionSearchResults = YodleeMain.viewTransactionsForItemAccount(BankAccount.ItemID, BankAccount.ItemAccountID, "bank", BankAccount.CurrentBalance, Undefined, Undefined);
		EndIf;
		If Not TransactionSearchResults.searchResult.returnValue Then
			WriteLogEvent("Yodlee.UpdateTransactions", EventLogLevel.Error,,, "Error updating transactions for bank account with ItemAccountID:" + BankAccount.ItemAccountID + ". Description:" + TransactionSearchResults.searchResult.errorMessage);
		EndIf;
		TransactionsRS = InformationRegisters.BankTransactions.CreateRecordSet();
		Transactions = TransactionsRS.Unload();
		Transactions.Clear();
		For j = 0 To TransactionSearchResults.Count() - 1 Do
			TransactionSearchResult = TransactionSearchResults.GetByID(j);
			TransactionSearchResult.FillInTransactions();
			For i = 0 To TransactionSearchResult.Count()-1 Do
				YodleeTran 	= TransactionSearchResult.GetByID(i);
				NewTran 	= Transactions.Add();
				NewTran.TransactionDate = YodleeTran.transactionDate;
				NewTran.BankAccount 	= BankAccount;
				
				NewTran.Description 	= YodleeTran.description.description;
				If YodleeTran.transactionBaseType = "credit" Then
					NewTran.Amount 			= YodleeTran.amount.amount;
				ElsIf YodleeTran.transactionBaseType = "debit" Then
					NewTran.Amount 			= -1 * YodleeTran.amount.amount;
				EndIf;
				NewTran.YodleeTransactionID	= YodleeTran.viewKey.transactionId;
					
				NewTran.PostDate 		= YodleeTran.postDate;
				NewTRan.Price 			= YodleeTran.price.amount;
				NewTran.Quantity 		= YodleeTran.quantity;
				NewTran.RunningBalance	= YodleeTran.runningBalance;
				NewTran.CurrencyCode	= YodleeTran.amount.currencyCode;
				NewTran.CategoryName 	= YodleeTran.category.categoryName;
				NewTran.Type 			= YodleeTran.transactionBaseType;
					
				//NewTran.Status			= YodleeTran.status.description;				
			EndDo;
		EndDo;
		
		Transactions.Columns.TransactionDate.Name = "PostDate1";
		Transactions.Columns.PostDate.Name = "TransactionDate";
		Transactions.Columns.PostDate1.Name = "PostDate";
		//Record Transactions to database
		TransactionDates = Transactions.Copy(,"TransactionDate");
		TransactionDates.GroupBy("TransactionDate");
		//By dates
		For Each TranDate IN TransactionDates Do
			Try
				// Update the database in transaction.
				BeginTransaction(DataLockControlMode.Managed);
				// Lock the register records preventing reading old schedule data.
				Rows = New Array();
				Rows.Add(TranDate);
				DataSource = TransactionDates.Copy(Rows);
				DocumentPosting.LockDataSourceBeforeWrite("InformationRegister.BankTransactions", DataSource, DataLockMode.Exclusive);
				
				CurDate = TranDate.TransactionDate;
				TRS = InformationRegisters.BankTransactions.CreateRecordSet();
				TDFilter = TRS.Filter.TransactionDate;
				BAFilter = TRS.Filter.BankAccount;
				BAFilter.Use = True;
				BAFilter.ComparisonType = ComparisonType.Equal;
				BAFilter.Value = BankAccount;
				TDFilter.Use = True;
				TDFilter.ComparisonType = ComparisonType.Equal;
				TDFilter.Value = CurDate;
				TRS.Read();
				ValueTable_TRS = TRS.Unload();
			
				TransactionsPerDate = Transactions.FindRows(New Structure("TransactionDate", CurDate));
				For Each TranPerDate IN TransactionsPerDate Do
					FoundTransaction = ValueTable_TRS.FindRows(New Structure("YodleeTransactionID", TranPerDate.YodleeTransactionID));
					If FoundTransaction.Count() > 0 Then
						FillPropertyValues(FoundTransaction[0], TranPerDate);
					Else
						NewTRSRow = ValueTable_TRS.Add();
						FillPropertyValues(NewTRSRow, TranPerDate);
						//NewTRSRow.BankAccount = BankAccount.AccountingAccount;
						NewTRSRow.ID = New UUID();
					EndIf;
				EndDo;
				TRS.Load(ValueTable_TRS);
				TRS.Write(True);
				
				CommitTransaction();
			Except
				If TransactionActive() Then
					RollbackTransaction();
				EndIf;
				ReturnStructure.ReturnValue = false;
				Reason = ErrorDescription();
				ReturnStructure.ErrorMessage = "Not all bank transactions were successfully downloaded. Please repeat operation." + Chars.LF + "Reason: " + Reason;
			EndTry;
		EndDo;
		
		WriteLogEvent("Yodlee.UpdateTransactions", EventLogLevel.Information,,, "Bank transactions are successfully updated");
		
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Transactions successfully uploaded.", 7), TempStorageAddress);
		EndIf;
			
	Except
		ErrorReason = ErrorDescription();
		WriteLogEvent("Yodlee.UpdateTransactions", EventLogLevel.Error,,, ErrorReason);
		ReturnStructure.ReturnValue = False;
		ReturnStructure.ErrorMessage = "An error occured while downloading transactions: " + ErrorReason;
	EndTry;
	return ReturnStructure;
EndFunction

//Returns array of fields and values for MFA
//
//Parameters:
//ServiceID - the ID of a bank in Yodlee system
//
//Returns:
//Structure - returns the following properties:
//	ReturnValue - boolean - true if succeeded
//	ProgrammaticElements - array of structures, containing MFA fields description
//	ProgrammaticElementsValidValues - array of structures, containing predefined set of possible values
//	YodleeStorage - YodleeMain status
//
Function AddItem_GetFormFields(ServiceID, TempStorageAddress = Undefined) Export
	ReturnStructure = New Structure("ReturnValue, ProgrammaticElements, ProgrammaticElementsValidValues");
	Try
		WriteLogEvent("Yodlee.AddItem_GetFormFields", EventLogLevel.Information,,, "Started adding accounts for the bank with ServiceID: " + String(ServiceID));	
		YodleeMain	= New ComObject("YodleeCom.YodleeMain"); 
		If Not LoginUser(YodleeMain) Then
			ReturnStructure.Insert("ReturnValue", False);
			
			If TempStorageAddress <> Undefined Then
				PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Login failed...", 1), TempStorageAddress);
			EndIf;
			return ReturnStructure;			
		EndIf;
		
		FFQ = YodleeMain.addItem_GetFormFieldsQueue(ServiceID);
		ProgrammaticElements = New Array();
		ProgrammaticElementsValidValues = New Array();
		Visitor = FFQ.FFV;
		While Visitor.hasNext() Do
			If Visitor.needsBigOr() Then
				//Should start a new OR block
				//Message("------OR------");
			EndIf;
			fieldInfo = Visitor.getNextField();
			If FFQ.IsFieldInfoSingle(fieldInfo) Then
				dispValidValues = New Array();
				valValues 		= New Array();
				FieldInfoSingle 	= FFQ.GetFieldInfoSingle(fieldInfo);
				valueIdentifier 	= FieldInfoSingle.valueIdentifier;
				NewPE	= New Structure("ElementName, ElementOriginalName, BigOr, DisplayName, MaxLength, FieldType");
				ProgrammaticElements.Add(NewPE);
				//FoundRows = ProgrammaticElements.FindRows(New Structure("ElementOriginalName", valueIdentifier, True));
				FoundRows = FindRows(ProgrammaticElements, New Structure("ElementOriginalName", valueIdentifier));
				If FoundRows.Count()>0 Then
					Prefix = "Yodlee" + String(FoundRows.Count()) + "_";
				Else
					Prefix = "Yodlee_";
				EndIf;
				NewPE.ElementOriginalName = valueIdentifier;
				NewPE.ElementName = Prefix + valueIdentifier;
				If Visitor.needsBigOr() Then
					NewPE.BigOr = True;
				EndIf;
				NewPE.DisplayName 	= FieldInfoSingle.DisplayName; 
				If FieldInfoSingle.displayValidValues <> Undefined Then
					displayValidValues 	= FFQ.GetStringArray(FieldInfoSingle.displayValidValues);
					i = 0;
					While i < displayValidValues.Count() Do
						Message(displayValidValues.GetByID(i));
						newPEValVal = New Structure("ValidValue, DisplayValidValue, ElementName, Serial");
						ProgrammaticElementsValidValues.Add(newPEValVal);
						//newPEValVal	=	ProgrammaticElementsValidValues.Add();
						newPEValVal.DisplayValidValue 	= displayValidValues.GetByID(i);
						newPEValVal.ElementName 		= NewPE.ElementName;
						newPEValVal.Serial 				= i + 1;
						i = i + 1;
					EndDo;
				EndIf;
				If FieldInfoSingle.validValues <> Undefined Then
					validValues			= FFQ.GetStringArray(FieldInfoSingle.validValues);
					For i = 0 To validValues.Count()-1 Do
						//PEValValStr = ProgrammaticElementsValidValues.FindRows(New Structure("ElementName, Serial", NewPE.ElementName, i + 1));
						PEValValStr = FindRows(ProgrammaticElementsValidValues, New Structure("ElementName, Serial", NewPE.ElementName, i + 1));
						If PEValValStr.Count() > 0 Then
							PEValValStr[0].ValidValue = validValues.GetByID(i);
						EndIf;
					EndDo;
				EndIf;

				NewPE.MaxLength 			= FieldInfoSingle.maxlength;
				NewPE.FieldType 			= FieldInfoSingle.fieldType;
			
				FFQ.AddToArrayList(fieldInfo);
			ElsIf FFQ.IsFieldInfoMultiFixed(fieldInfo) Then
				//Message("========MultiFixed========");			
			EndIf;			
		EndDo;
		
		//Save the YodleeMain state
		Try
			Serializer 	= New ComObject("YodleeCom.Serializer");
			Result 	= Serializer.Serialize(YodleeMain);
			If Result.returnValue Then
				YodleeMainStorage = Result.returnMessage;
			EndIf;
		Except
			WriteLogEvent("Yodlee.SerializingComponent", EventLogLevel.Error,,, ErrorDescription());
			ReturnStructure.Insert("ReturnValue", False);
			If TempStorageAddress <> Undefined Then
				PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "An error occured...", 1), TempStorageAddress);
			EndIf;
			return ReturnStructure;
		EndTry;
		
		ReturnStructure.Insert("ReturnValue", True);
		ReturnStructure.Insert("ProgrammaticElements", ProgrammaticElements);
		ReturnStructure.Insert("ProgrammaticElementsValidValues", ProgrammaticElementsValidValues);
		ReturnStructure.Insert("YodleeStorage", YodleeMainStorage);
		
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Obtained MFA fields from server...", 1), TempStorageAddress);
		EndIf;
		return ReturnStructure;
		
	Except
		WriteLogEvent("Yodlee.AddItem_GetFormFields", EventLogLevel.Error,,, ErrorDescription());
		ReturnStructure.Insert("ReturnValue", False);
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "An error occured", 1), TempStorageAddress);
		EndIf;
		return ReturnStructure;
	EndTry;
EndFunction

//Returns array of fields and values for MFA
//
//Parameters:
//ServiceID - the ID of a bank
//ProgrammaticElems - array of structures with the filled MFA fields
//YodleeStorage - YodleeMain status
//TempStorageAddress - the address, where to put the result
//
//Returns:
//Structure - returns the following properties:
//	NewItemID - the ID of the added account. If - 0, then failed;
//	YodleeStorage - YodleeMain status;
//
Function AddItem_AddItem(ServiceID, ProgrammaticElems, YodleeStorage, TempStorageAddress = Undefined) Export
	ReturnStructure = new Structure("NewItemID, YodleeStorage");
	//Restore the YodleeMain state
	Try
		Serializer 	= New ComObject("YodleeCom.Serializer");
		Result 	= Serializer.Deserialize(YodleeStorage);
		If Result.returnValue Then
			YodleeMain = Result.yodleeMain;
		EndIf;
	Except
		WriteLogEvent("Yodlee.DeserializingComponent", EventLogLevel.Error,,, ErrorDescription());
		ReturnStructure.Insert("NewItemID", 0);
		
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Internal error occured...", 2), TempStorageAddress);
		EndIf;
		
		return ReturnStructure;
	EndTry;
	Try
		FFQ = YodleeMain.FFQ;
		ArrayList = FFQ.GetArrayList();
		For Each El IN ArrayList Do
			If FFQ.IsFieldInfoSingle(EL) Then
				FieldInfoSingle = FFQ.GetFieldInfoSingle(EL);
				FieldInfoSingle.value = GetFieldValue(ProgrammaticElems, "Yodlee_" + FieldInfoSingle.valueIdentifier);
			ElsIf FFQ.IsFieldInfoMultiFix() Then
			
			EndIf;		
		EndDo;
	Except
		WriteLogEvent("Yodlee.AddItem_ProcessingMFAFields", EventLogLevel.Error,,, ErrorDescription());
		ReturnStructure.Insert("NewItemID", 0);
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Internal error occured...", 2), TempStorageAddress);
		EndIf;
		return ReturnStructure;
	EndTry;
	Try
		newItemId = YodleeMain.addItem_addItem(ServiceID, ArrayList);
		ReturnStructure.Insert("NewItemID", newItemId);
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Bank account was added successfully...", 2), TempStorageAddress);
		EndIf;
		If newItemID <> 0 Then
			If TempStorageAddress <> Undefined Then
				PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Bank account was added successfully. Obtaining the new bank account details...", 2), TempStorageAddress);
			EndIf;
			YodleeUpdateBankAccounts(YodleeMain);
			If TempStorageAddress <> Undefined Then
				PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Bank account was added successfully...", 3), TempStorageAddress);
			EndIf;
		EndIf;
		return ReturnStructure;
	Except
		WriteLogEvent("Yodlee.AddItem_AddingItem", EventLogLevel.Error,,, ErrorDescription());
		ReturnStructure.Insert("NewItemID", 0);
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "An error occured...", 2), TempStorageAddress);
		EndIf;
		return ReturnStructure;
	EndTry;
EndFunction

//Refreshes a bank account
//If MFA then returns array of fields and values for MFA
//
//Parameters:
//ItemID - the ID of a bank account
//YodleeMain - YodleeMain object
//YodleeStorage - YodleeMain status
//TempStorageAddress - the address, where to put the result
//
//Returns:
//Structure - returns the following properties:
// In case of MFA - returns ProcessMFA result
// else
//	ReturnValue - Boolean. If - False, then failed;
//  Status - String. In case of failure returns text description for a user
//	IsMFA - boolean;
//
Function RefreshItem(ItemID, YodleeStorage = Undefined, YodleeMain = Undefined, TempStorageAddress = Undefined) Export
	Try
		ReturnStructure = New Structure("ReturnValue, Status, IsMFA");
		ReturnStructure.ReturnValue = True;
		WriteLogEvent("Yodlee.RefreshItem", EventLogLevel.Information,,, "Starting refresh for account with ID:" + String(ItemID));	
		If ValueIsFilled(YodleeStorage) Then 
			//Restore the YodleeMain state
			Try
				Serializer 	= New ComObject("YodleeCom.Serializer");
				Result 	= Serializer.Deserialize(YodleeStorage);
				If Result.returnValue Then
					YodleeMain = Result.yodleeMain;
				EndIf;
			Except
				WriteLogEvent("Yodlee.DeserializingComponent", EventLogLevel.Error,,, ErrorDescription());
				ReturnStructure.Insert("ReturnValue", False);
				
				If TempStorageAddress <> Undefined Then
					PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Internal error...Please, repeat the operation", 1), TempStorageAddress);
				EndIf;

				return ReturnStructure;
			EndTry;
		Else
			If YodleeMain = Undefined Then
				YodleeMain	= New ComObject("YodleeCom.YodleeMain");	
				If Not LoginUser(YodleeMain) Then
					ReturnStructure.Insert("ReturnValue", False);
					
					If TempStorageAddress <> Undefined Then
						PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Login failed...", 1), TempStorageAddress);
					EndIf;

					return ReturnStructure;
				EndIf;
			EndIf;		
		EndIf;

		RefreshProcess = YodleeMain.refreshItem_startRefresh(ItemID);
		If Not RefreshProcess.OK Then
			ReturnStructure.ReturnValue = False;
			ReturnStructure.Status = RefreshProcess.Status;
			WriteLogEvent("Yodlee.RefreshItem", EventLogLevel.Error,,, RefreshProcess.ExceptionDescription);
			
			If TempStorageAddress <> Undefined Then
				PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, RefreshProcess.Status, 1), TempStorageAddress);
			EndIf;
					
			return ReturnStructure;
		EndIf;
		If Not RefreshProcess.isMFA Then
			If TempStorageAddress <> Undefined Then
				PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Started the refresh...", 2), TempStorageAddress);
			EndIf;
			RefreshProcess = YodleeMain.refreshItem_pollRefreshStatus(ItemId, RefreshProcess);
			ReturnStructure.ReturnValue = RefreshProcess.OK;
			ReturnStructure.Status = RefreshProcess.Status;
			ReturnStructure.IsMFA = False;
			If Not RefreshProcess.OK Then
				WriteLogEvent("Yodlee.RefreshItem", EventLogLevel.Error,,, RefreshProcess.ExceptionDescription);
			EndIf;
			If TempStorageAddress <> Undefined Then
				PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "The refresh has finished...", 3), TempStorageAddress);
			EndIf;
			return ReturnStructure;
		EndIf;
		
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Obtaining fields for MFA...", 2), TempStorageAddress);
		EndIf;
		return ProcessMFA(ItemID, YodleeMain, TempStorageAddress);
		
	Except
		WriteLogEvent("Yodlee.RefreshItem", EventLogLevel.Error,,, ErrorDescription());	
		ReturnStructure.Insert("ReturnValue", False);
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "The refresh failed...", 2), TempStorageAddress);
		EndIf;
		return ReturnStructure;
	EndTry;
EndFunction

//Continues the refresh after a user filled in required MFA fields
//Parameters:
// ProgrammaticElems - structure. Contains answer from the user
// Params - returned from notify params:
//   ItemID - ID of the account being updated
//   YodleeStorage - YodleeMain status
//Return value:
// Structure - returns the following properties:
//	ReturnValue - boolean - true if succeeded
// 	Status - refresh status description
//	IsMFA - whether refresh requires MFA response or not
//	ProgrammaticElements - array of structures, containing MFA fields description
//	ProgrammaticElementsValidValues - array of structures, containing predefined set of possible values
//	YodleeStorage - YodleeMain status
//
Function ContinueMFARefresh(ProgrammaticElems, Params, TempStorageAddress = Undefined) Export
	Try
		ReturnStructure = New Structure("ReturnValue");
		//Restore the YodleeMain state
		Try
			Serializer 	= New ComObject("YodleeCom.Serializer");
			Result 	= Serializer.Deserialize(Params.YodleeStorage);
			If Result.returnValue Then
				YodleeMain = Result.yodleeMain;
			EndIf;
		Except
			WriteLogEvent("Yodlee.DeserializingComponent", EventLogLevel.Error,,, ErrorDescription());
			ReturnStructure.Insert("ReturnValue", False);
			If TempStorageAddress <> Undefined Then
				PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Internal error...Please, repeat the operation", 4), TempStorageAddress);
			EndIf;
			return ReturnStructure;
		EndTry;

		If TypeOf(ProgrammaticElems) <> Type("Array") Then
			WriteLogEvent("Yodlee.RefreshItem", EventLogLevel.Error,,, "Parameter ""ProgrammaticElems"" in the ContinueMFARefresh function is not of type ""Array""");	
			ReturnStructure.Insert("ReturnValue", False);
			ReturnStructure.Insert("Status", "User input is empty");
			If TempStorageAddress <> Undefined Then
				PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, ReturnStructure.Status, 4), TempStorageAddress);
			EndIf;
			return ReturnStructure;
		EndIf;
		
		RefreshProcess = YodleeMain.RefreshProcess;
		If RefreshProcess.fieldInfoType = "TokenIdFieldInfo" Then
			If ProgrammaticElems.Count() > 0 Then
				Elem = FindElementByName(ProgrammaticElems, "Token");
				If Elem <> Undefined Then
					RefreshProcess.currentAnswer = Elem.ElementValue;
				EndIf;
			EndIf;
		ElsIf RefreshProcess.fieldInfoType = "SecurityQuestionFieldInfo" Then
			For i = 0 To (RefreshProcess.totalNumberOfQuestions - 1) Do
				Elem = FindElementByName(ProgrammaticElems, "Question_" + String(i));
				If Elem <> Undefined Then
					RefreshProcess.AppendAnswer(i, Elem.ElementValue);
				EndIf;
			EndDo;
		EndIf;
	
		RefreshProcess = YodleeMain.refreshItem_putMFARequest(Params.ItemId, RefreshProcess);
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", , "Getting MFA response from the server", 4), TempStorageAddress);
		EndIf;
		ReturnStructure = ProcessMFA(Params.ItemId, YodleeMain, TempStorageAddress);
		//If TempStorageAddress <> Undefined Then
		//	PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Processed MFA response from the server", 4), TempStorageAddress);
		//EndIf;
		return ReturnStructure;
	Except
		WriteLogEvent("Yodlee.RefreshItem", EventLogLevel.Error,,, ErrorDescription());	
		ReturnStructure.Insert("ReturnValue", False);
		return ReturnStructure;
	EndTry;
EndFunction

Function RemoveItem(ItemID) Export
	Try
		WriteLogEvent("Yodlee.RemoveItem", EventLogLevel.Information,,, "Started removing account with ItemID: " + String(ItemID));	
		ReturnStructure = New Structure();
		YodleeMain	= New ComObject("YodleeCom.YodleeMain");	
		If Not LoginUser(YodleeMain) Then
			ReturnStructure.Insert("ReturnValue", False);
			return ReturnStructure;
		EndIf;
		ReturnStruct = YodleeMain.removeItem(ItemID);
		ReturnStructure.Insert("ReturnValue", ReturnStruct.ReturnValue);
		ReturnStructure.Insert("Status", ReturnStruct.ErrorMessage);
		If ReturnStruct.ReturnValue Then
			WriteLogEvent("Yodlee.RemoveItem", EventLogLevel.Information,,, "ItemID: " + String(ItemID) + ". " + ReturnStruct.ErrorMessage);	
		Else
			WriteLogEvent("Yodlee.RemoveItem", EventLogLevel.Error,,, "ItemID: " + String(ItemID) + ". " + ReturnStruct.ErrorMessage);		
		EndIf;
		return ReturnStructure;
	Except
		WriteLogEvent("Yodlee.RemoveItem", EventLogLevel.Error,,, "Error occured while removing account with ItemID: " + String(ItemID) + "Description: " + ErrorDescription());	
	EndTry;
EndFunction

//Login user to Yodlee system
Function LoginUser(YodleeMain = Undefined) Export
	Try
		If YodleeMain = Undefined Then
			YodleeMain	= New ComObject("YodleeCom.YodleeMain"); 
		EndIf;
		
		If Not CheckRegisterUser(YodleeMain) Then
			return false;
		EndIf;
		
		UserName = Constants.YodleeUserName.Get();
		UserPassword = Constants.YodleeUserPassword.Get();
		
		Result = YodleeMain.LoginUser(UserName, UserPassword);
		If Result.returnValue Then
			WriteLogEvent("Yodlee.LoginUser", EventLogLevel.Information,,, "User logged in successfully");
			return True;
		Else
			WriteLogEvent("Yodlee.LoginUser", EventLogLevel.Error,,, "User login failed. Error message:" + Result.errorMessage);
			return False;
		EndIf;
		
	Except
		WriteLogEvent("Yodlee.LoginUser", EventLogLevel.Error,,, ErrorDescription());
	EndTry;
	
	
EndFunction

#EndRegion

#Region PRIVATE_IMPLEMENTATION

//Returns array of fields and values for MFA
//
//Parameters:
//ServiceID - the ID of a bank in Yodlee system
//YodleeMain - Yodlee component
//
//Returns:
//Structure - returns the following properties:
//	ReturnValue - boolean - true if succeeded
// 	Status - refresh status description
//	IsMFA - whether refresh requires MFA response or not
//  ItemID - the ItemID of the account being updated
//	ProgrammaticElements - array of structures, containing MFA fields description
//	ProgrammaticElementsValidValues - array of structures, containing predefined set of possible values
//	YodleeStorage - YodleeMain status
//
Function ProcessMFA(ItemId, YodleeMain, TempStorageAddress = Undefined)
	Try
		ReturnStructure = New Structure("ReturnValue, Status, IsMFA, ItemID, ProgrammaticElements, ProgrammaticElementsValidValues, YodleeStorage");
		MFARefreshInfo = YodleeMain.refreshItem_getMFAResponse(ItemId);
		If MFARefreshInfo <> Undefined Then
		
			RefreshProcess = YodleeMain.refreshItem_parseMFAInfo(MFARefreshInfo, itemId, YodleeMain.RefreshProcess);
		
			If RefreshProcess.MFAErrorCode <> 0 Then
				ReturnStructure.ReturnValue = False;
				ReturnStructure.Status = RefreshProcess.Status;
				ReturnStructure.IsMFA = False;
				WriteLogEvent("Yodlee.RefreshItem_ProcessMFA", EventLogLevel.Error,,, "Error occured while processing MFA");
				If TempStorageAddress <> Undefined Then
					PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, RefreshProcess.Status, 4), TempStorageAddress);
				EndIf;
				YodleeUpdateBankAccounts(YodleeMain);
				return ReturnStructure;
			ElsIf RefreshProcess.MFARefreshSucceeded Then
				If TempStorageAddress <> Undefined Then
					ReturnStructure.ReturnValue = True;
					ReturnStructure.IsMFA = True;
					PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Refresh succeeded. Polling refresh status...", 5), TempStorageAddress);
				EndIf;
				RefreshProcess = YodleeMain.refreshItem_pollRefreshStatus(ItemId, RefreshProcess);
				If Not RefreshProcess.OK Then
					ReturnStructure.ReturnValue = RefreshProcess.OK;
					ReturnStructure.Status = RefreshProcess.Status;
					ReturnStructure.IsMFA = False;
					//If Not RefreshProcess.OK Then
					WriteLogEvent("Yodlee.RefreshItem_ProcessMFA", EventLogLevel.Error,,, RefreshProcess.ExceptionDescription);
					//EndIf;
					If TempStorageAddress <> Undefined Then
						PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, RefreshProcess.Status, 5), TempStorageAddress);
					EndIf;
					YodleeUpdateBankAccounts(YodleeMain);
				Else  //If successfully refreshed account
					ReturnStructure.ReturnValue = RefreshProcess.OK;
					ReturnStructure.Status = RefreshProcess.Status;
					ReturnStructure.IsMFA = True;
					If TempStorageAddress <> Undefined Then
						PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Updating bank account information...", 5), TempStorageAddress);
					EndIf;
					YodleeUpdateBankAccounts(YodleeMain);
					//Save the YodleeMain state
					YodleeMainStorage = "";
					Try
						Serializer 	= New ComObject("YodleeCom.Serializer");
						Result 	= Serializer.Serialize(YodleeMain);
						If Result.returnValue Then
							YodleeMainStorage = Result.returnMessage;
						EndIf;
					Except
						WriteLogEvent("Yodlee.SerializingComponent", EventLogLevel.Error,,, ErrorDescription());
						ReturnStructure.Insert("ReturnValue", False);
						return ReturnStructure;
					EndTry;
					ReturnStructure.IsMFA = False;
					If (TempStorageAddress <> Undefined) Then
						If ValueIsFilled(YodleeMainStorage) Then
							PutToTempStorage(New Structure("Params, CurrentStatus, Step, YodleeStorage", ReturnStructure, RefreshProcess.Status, 5, YodleeMainStorage), TempStorageAddress);
						Else
							PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, RefreshProcess.Status, 5), TempStorageAddress);
						EndIf;
					EndIf;
				EndIf;
				return ReturnStructure;
			EndIf;
		
			ArrOfElements = New Array();

			If RefreshProcess.fieldInfoType = "TokenIdFieldInfo" Then
				ArrOfElements = New Array();
				RowStruct = New Structure("ElementName, ElementOriginalName, BigOr, DisplayName, MaxLength, FieldType");
				RowStruct.ElementName = "Token";
				RowStruct.ElementOriginalName = "Token";
				RowStruct.BigOr = false;
				RowStruct.DisplayName = RefreshProcess.CurrentQuestion;
				RowStruct.MaxLength = 40;
				RowStruct.FieldType = 0; //Text
				ArrOfElements.Add(RowStruct);
					
			ElsIf RefreshProcess.fieldInfoType = "ImageFieldInfo" Then
				ReturnStructure.ReturnValue = False;
				ReturnStructure.Status = "CAPTCHA images are not supported";
				ReturnStructure.IsMFA = False;
				WriteLogEvent("Yodlee.RefreshItem_ProcessMFA", EventLogLevel.Error,,, "CAPTCHA images are not supported. ItemID:" + String(ItemID));
				return ReturnStructure;
			ElsIf RefreshProcess.fieldInfoType = "SecurityQuestionFieldInfo" Then
				ArrOfElements = New Array();
				For i = 0 To (RefreshProcess.totalNumberOfQuestions - 1) Do 
					RowStruct = New Structure("ElementName, ElementOriginalName, BigOr, DisplayName, MaxLength, FieldType");
					RowStruct.ElementName = "Question_" + String(i);
					RowStruct.ElementOriginalName = "Question_" + String(i);
					RowStruct.BigOr = false;
					RowStruct.DisplayName = RefreshProcess.GetQuestion(i);
					RowStruct.MaxLength = 40;
					RowStruct.FieldType = 0; //Text
					ArrOfElements.Add(RowStruct);
				EndDo;
			EndIf;			
			
			//Save the YodleeMain state
			Try
				Serializer 	= New ComObject("YodleeCom.Serializer");
				Result 	= Serializer.Serialize(YodleeMain);
				If Result.returnValue Then
					YodleeMainStorage = Result.returnMessage;
				EndIf;
			Except
				WriteLogEvent("Yodlee.SerializingComponent", EventLogLevel.Error,,, ErrorDescription());
				ReturnStructure.Insert("ReturnValue", False);
				return ReturnStructure;
			EndTry;

			
			ArrOfValidValues = New Array();
						
			ReturnStructure.Insert("ReturnValue", True);
			ReturnStructure.Insert("IsMFA", True);
			ReturnStructure.Insert("ItemID", ItemID);
			ReturnStructure.Insert("ProgrammaticElements", ArrOfElements);
			ReturnStructure.Insert("ProgrammaticElementsValidValues", ArrOfValidValues);
			ReturnStructure.Insert("AnswerTimeout", RefreshProcess.AnswerTimeout/1000);
			ReturnStructure.Insert("startTime", RefreshProcess.startTime);
			ReturnStructure.Insert("YodleeStorage", YodleeMainStorage);
			If TempStorageAddress <> Undefined Then
				PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Obtained MFA fields...", 4), TempStorageAddress);
			EndIf;
			return ReturnStructure;
		
		Else
			ReturnStructure.ReturnValue = False;
			ReturnStructure.Status = "Error while retrieving MFA Info";
			WriteLogEvent("Yodlee.RefreshItem_ProcessMFA", EventLogLevel.Error,,, "Error while retrieving MFA Info");
			If TempStorageAddress <> Undefined Then
				PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, ReturnStructure.Status, 4), TempStorageAddress);
			EndIf;
			return ReturnStructure;
		EndIf;
	Except
		WriteLogEvent("Yodlee.Refresh_ProcessMFA", EventLogLevel.Error,,, ErrorDescription());
		If TempStorageAddress <> Undefined Then
			ReturnStructure.ReturnValue = False;
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "An error occured while processing MFA...", 4), TempStorageAddress);
		EndIf;
	EndTry;
EndFunction

//Finds a structure with the corresponding key ElementName and returns its value
Function GetFieldValue(ProgrammaticElems, ElementName)
	For Each PE In ProgrammaticElems Do
		If PE.ElementName = ElementName Then
			return PE.ElementValue;
		EndIf;
	EndDo;
EndFunction

//Find structures in array
Function FindRows(PE, SearchStruct)
	FoundRows = New Array();
	For Each PEStr In PE Do
		FoundAll = True;
		For Each SearchElement In SearchStruct Do
			If PEStr[SearchElement.Key] <> SearchElement.Value Then
				FoundAll = False;
				Break;
			EndIf;
		EndDo;
		If FoundAll Then
			FoundRows.Add(PEStr);
		EndIf;
	EndDo;
	Return FoundRows;
EndFunction

//Check for a user registration
//If a user is not registered then register a user
Function CheckRegisterUser(YodleeMain)
	Try
		UserName = Constants.YodleeUserName.Get();
		UserPassword = Constants.YodleeUserPassword.Get();
		If Not ValueIsFilled(UserName) Then
			//First time use. Register a user
			Tenant = "";
			UserName = "User_" + TrimAll(Tenant);
			UserPassword = GeneratePassword(20);
			UserEmail = UserName + "@samplemail.com";
			Result = YodleeMain.RegisterUser(UserName, UserPassword, UserEmail);
			If Result.returnValue Then
				WriteLogEvent("Yodlee.RegisterUser", EventLogLevel.Information,,, "Successfully registered user """ + UserName + """ with tenant " + Tenant);
				Constants.YodleeUserName.Set(UserName);
				Constants.YodleeUserPassword.Set(UserPassword);
				return True;
			Else
				WriteLogEvent("Yodlee.RegisterUser", EventLogLevel.Error,,, "An error occured while registering a user """ + UserName + """ with tenant " + Tenant + ". Error message:" + Result.errorMessage);
				return False;
			EndIf;
		Else
			return True;
		EndIf;
	Except
		WriteLogEvent("Yodlee.RegisterUser", EventLogLevel.Error,,, ErrorDescription());
	EndTry;
EndFunction

Procedure DeleteUninitializedAccounts()
	WriteLogEvent("Yodlee.DeleteUninitializedAccounts", EventLogLevel.Information,,, "Deleting uninitialized accounts");
	Try
		BeginTransaction(DataLockControlMode.Managed);
		// Create new managed data lock
		DataLock = New DataLock;
	
		// Set data lock parameters
		BA_LockItem = DataLock.Add("Catalog.BankAccounts");
		BA_LockItem.Mode = DataLockMode.Exclusive;
		BA_LockItem.SetValue("ItemAccountID", 0);
		BA_LockItem.SetValue("YodleeAccount", True);
		// Set lock on the object
		DataLock.Lock();
		Request = New Query("SELECT
		                    |	BankAccounts.Ref AS BankAccount
		                    |FROM
		                    |	Catalog.BankAccounts AS BankAccounts
		                    |WHERE
		                    |	BankAccounts.ItemAccountID = 0
		                    |	AND BankAccounts.YodleeAccount = TRUE");
		RequestResult = Request.Execute();
		If NOT RequestResult.IsEmpty() Then
			DataSource = RequestResult.Unload();
			DocumentPosting.LockDataSourceBeforeWrite("InformationRegister.BankTransactions", DataSource, DataLockMode.Exclusive);
			
			EmptyBA_Request = New Query("SELECT DISTINCT
			                            |	UninitializedBA.Ref,
			                            |	UninitializedBA.ItemID
			                            |FROM
			                            |	(SELECT
			                            |		BankAccounts.Ref AS Ref,
			                            |		BankAccounts.ItemID AS ItemID
			                            |	FROM
			                            |		Catalog.BankAccounts AS BankAccounts
			                            |	WHERE
			                            |		BankAccounts.YodleeAccount = TRUE
			                            |		AND BankAccounts.ItemAccountID = 0) AS UninitializedBA
			                            |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
			                            |		ON UninitializedBA.Ref = BankTransactions.BankAccount
			                            |WHERE
			                            |	BankTransactions.BankAccount IS NULL ");
			EmptyBA_Result = EmptyBA_Request.Execute().Choose();
			While EmptyBA_Result.Next() Do
				//Remove from Yodlee server
				RemoveItem(EmptyBA_Result.ItemID);
				BA_Object = EmptyBA_Result.Ref.GetObject();
				BA_Object.Delete();
			EndDo;			
		EndIf;		
		CommitTransaction();
	Except
		WriteLogEvent("Yodlee.DeleteUninitializedAccounts", EventLogLevel.Error,,, ErrorDescription());
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	EndTry;
EndProcedure

Function GeneratePassword(PasswordLength)   
	SymbolString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; //62
	Password = "";
	RNG = New RandomNumberGenerator;	
	For i = 0 to PasswordLength-1 Do
		RN = RNG.RandomNumber(1, 62);
		Password = Password + Mid(SymbolString,RN,1);
	EndDo;
 	return Password; 
EndFunction

//Finds Element in ProgrammaticElems by ElementName
//
Function FindElementByName(ProgrammaticElems, ElementName)
	Elem = Undefined;
	For Each PE In ProgrammaticElems Do
		If PE.ElementName = ElementName Then
			Elem = PE;
			Break;
		EndIf;
	EndDo;
	return Elem;
EndFunction

#EndRegion