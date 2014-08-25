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
	UpdateFinancialInstitutions("bank");
	UpdateFinancialInstitutions("credits");
EndProcedure

Procedure UpdateFinancialInstitutions(ContainerType) Export
Try
	YodleeMain	= New ComObject("YodleeCom.YodleeMain"); 
	
	ContainerServices = YodleeMain.viewContainerServices(ContainerType);
	
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
			BankSel = QueryRes.Select();
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
			CurBank.DateUpdatedUTC 	= CurrentUniversalDate();
			CurBank.ContainerType	= GetYodleeContainerType(ContainerType);
			CurBank.Write();
		Except
			WriteLogEvent("Yodlee.UpdateBanks", EventLogLevel.Error,,, ErrorDescription());
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
Procedure YodleeUpdateBankAccounts(YodleeMain = Undefined, DeleteUninitializedAccounts = False, BankAccountToDelete = Undefined, TempStorageAddress = Undefined) Export
	Try
		ReturnStructure = New Structure("ReturnValue", True);
		If YodleeMain = Undefined Then
			YodleeMain	= New ComObject("YodleeCom.YodleeMain"); 
			If Not LoginUser(YodleeMain) Then
				ReturnStructure.ReturnValue = False;
				If TempStorageAddress <> Undefined Then
					PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Login failed...", 8), TempStorageAddress);
				EndIf;

				return;
			EndIf;

		EndIf;
		
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Started updating bank accounts...", 8), TempStorageAddress);
		EndIf;
		
		//Select disconnected accounts 
		Request = New Query("SELECT
		                    |	DisconnectedBankAccounts.ItemID,
		                    |	DisconnectedBankAccounts.ItemAccountID
		                    |FROM
		                    |	InformationRegister.DisconnectedBankAccounts AS DisconnectedBankAccounts");
		DisconnectedAccounts = Request.Execute().Unload();
		
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
					
					If bankData <> Undefined Then
						//Check if bank account is disconnected
						Disconnected = DisconnectedAccounts.FindRows(New Structure("ItemID, ItemAccountID", ItemSummary.itemID, bankData.itemAccountID));
						If Disconnected.Count() > 0 Then
							j = j + 1;
							Continue;
						EndIf;
					EndIf;
					
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
						AccountSel = QueryRes.Select();
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
							BankSel = QueryRes.Select();
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
						If Result.ContainerName = "bank" Then
							CurAccount.AvailableBalance 	= bankData.availableBalance.amount;
							CurAccount.CurrentBalance 		= bankData.currentBalance.amount;
						ElsIf Result.ContainerName = "credits" Then
							CurAccount.AvailableBalance		= bankData.availableCredit.amount;
							CurAccount.CurrentBalance		= bankData.runningBalance.amount;
							CurAccount.CreditCard_TotalCreditline	= bankData.totalCreditLine.amount;
							If bankData.amountDue <> Undefined Then
								CurAccount.CreditCard_AmountDue	= bankData.amountDue.amount;
							EndIf;
							If bankData.cardType <> Undefined Then
								CurAccount.CreditCard_Type	= bankData.cardType;
							EndIf;
						EndIf;
						CurAccount.AccountType			= bankData.acctType;
						CurAccount.Description 			= ItemSummary.itemDisplayName + ":" + bankData.accountNumber;
					Else
						CurAccount.Description 				= ItemSummary.itemDisplayName;
					EndIf;
					UTCUpdatedSecs						= ItemSummary.refreshInfo.lastUpdatedTime;
					CurAccount.LastUpdatedTimeUTC		= '19700101' + UTCUpdatedSecs;
					UTCUpdateAttemptSecs				= ItemSummary.refreshInfo.lastUpdateAttemptTime;
					CurAccount.LastUpdateAttemptTimeUTC = '19700101' + UTCUpdateAttemptSecs;
					UTCNextUpdateSecs					= ItemSummary.refreshInfo.nextUpdateTime;
					CurAccount.NextUpdateTimeUTC 		= '19700101' + UTCNextUpdateSecs;
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
					AccountSel = QueryRes.Select();
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
						BankSel = QueryRes.Select();
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
				CurAccount.LastUpdatedTimeUTC		= '19700101' + UTCUpdatedSecs;
				UTCUpdateAttemptSecs				= ItemSummary.refreshInfo.lastUpdateAttemptTime;
				CurAccount.LastUpdateAttemptTimeUTC = '19700101' + UTCUpdateAttemptSecs;
				UTCNextUpdateSecs					= ItemSummary.refreshInfo.nextUpdateTime;
				CurAccount.NextUpdateTimeUTC 		= '19700101' + UTCNextUpdateSecs;
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
		ReqSelect = Request.Execute().Select();
		While ReqSelect.Next() Do
			Try
				AccObject = ReqSelect.Ref.GetObject();
				AccObject.YodleeAccount = False;
				AccObject.Write();
			Except
			EndTry;			
		EndDo;
		If DeleteUninitializedAccounts Then
			DeleteUninitializedAccounts(BankAccountToDelete);
		EndIf;
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Bank accounts list successfully updated...", 9), TempStorageAddress);
		EndIf;

	Except
		WriteLogEvent("Yodlee.UpdateBankAccounts", EventLogLevel.Error,,, ErrorDescription());
		ReturnStructure.ReturnValue = False;
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "An error occured while refreshing accounts list...", 8), TempStorageAddress);
		EndIf;
	EndTry;
EndProcedure

Function RemoveBankAccountAtServer(Item) Export
	ReturnStruct = New Structure("ReturnValue, Status, CountDeleted, DeletedAccounts", true, "", 0, New Array());
	//Check if an item is not deleted
	AccObject = Item.GetObject();
	If AccObject = Undefined Then
		return ReturnStruct;
	EndIf;
	ItemID = Item.ItemID;
	ItemDescription = Item.Description;
	BeginTransaction(DataLockControlMode.Managed);
	Try
		// Create new managed data lock
		DataLock = New DataLock;

		// Set data lock parameters
		BA_LockItem = DataLock.Add("Catalog.BankAccounts");
		BA_LockItem.Mode = DataLockMode.Exclusive;
		BA_LockItem.SetValue("Ref", Item);
		// Set lock on the object
		DataLock.Lock();
		
		DeletedAccounts = New Array();
		If ItemID = 0 Then
			DeletedAccounts.Add(Item);
			
			AccObject = Item.GetObject();
			AccObject.Delete();
			ReturnStruct.Insert("CountDeleted", 1);
			ReturnStruct.Insert("DeletedAccounts", DeletedAccounts);
			ReturnStruct.Insert("Status", "Account " + ItemDescription + " was successfully deleted");
		Else
			ReturnStruct = Yodlee.RemoveItem(ItemID);
			//Remove records from DisconnectedBankAccounts register
			RecordSet = InformationRegisters.DisconnectedBankAccounts.CreateRecordSet();
			ItemIDFilter = RecordSet.Filter.ItemID;
			ItemIDFilter.Use = True;
			ItemIDFilter.ComparisonType = ComparisonType.Equal;
			ItemIDFilter.Value = Item.ItemID;
			RecordSet.Write(True);
			
			If (ReturnStruct.ReturnValue) OR (Find(ReturnStruct.Status, "InvalidItemExceptionFaultMessage")) Then
				//Mark bank account as non-Yodlee
				AccRequest = New Query("SELECT
				                       |	BankAccounts.Ref
				                       |FROM
				                       |	Catalog.BankAccounts AS BankAccounts
				                       |WHERE
				                       |	BankAccounts.ItemID = &ItemID");
				AccRequest.SetParameter("ItemID", ItemID);
				AccSelection = AccRequest.Execute().Select(); 
				cnt = 0;
				While AccSelection.Next() Do
					Try
					
						DeletedAccounts.Add(AccSelection.Ref);
						
						//Delete records in registers
						//BankTransactions
						BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
						BTRecordset.Filter.BankAccount.Set(AccSelection.Ref);
						BTRecordset.Write(True);
						//BankTransactionCategorization
						BTCRecordset = InformationRegisters.BankTransactionCategorization.CreateRecordSet();
						BTCRecordset.Filter.BankAccount.Set(AccSelection.Ref);
						BTCRecordset.Write(True);

					
						AccObject = AccSelection.Ref.GetObject();
						AccObject.Delete();
						cnt = cnt + 1;
					Except
					EndTry;				
				EndDo;
				ReturnStruct.Insert("CountDeleted", cnt);
				ReturnStruct.Insert("DeletedAccounts", DeletedAccounts);
				If cnt > 1 Then
					ReturnStruct.Insert("Status", "Accounts with Item ID:" + String(ItemID) + " were successfully deleted");
				Else
					ReturnStruct.Insert("Status", "Account with Item ID:" + String(ItemID) + " was successfully deleted");
				EndIf;
			EndIf;
		EndIf;
		CommitTransaction();
	Except
		Description = ErrorDescription();
		ReturnStruct.ReturnValue 	= False;
		ReturnStruct.Status 		= Description;
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
	EndTry;
	return ReturnStruct;
EndFunction

Function RemoveYodleeBankAccountAtServer(Item) Export
	If Item.ItemID = 0 Then
		return Yodlee.RemoveBankAccountAtServer(Item);
	Else
		//If we delete the last unmarked bank account then
		//we should remove these accounts from Yodlee
		//If not - just delete and make a record to DisconnectedAccounts register
		ItemID = Item.ItemID;
		Request = New Query("SELECT
		                    |	COUNT(DISTINCT BankAccounts.Ref) AS UsedAccountsCount
		                    |FROM
		                    |	Catalog.BankAccounts AS BankAccounts
		                    |WHERE
		                    |	BankAccounts.ItemID = &ItemID
		                    |	AND BankAccounts.DeletionMark = FALSE");
		Request.SetParameter("ItemID",ItemID);
		Res = Request.Execute();
		Sel = Res.Select();
		Sel.Next();
		If (Sel.UsedAccountsCount = 1) Then
			return Yodlee.RemoveBankAccountAtServer(Item);
		Else
			ReturnStruct = New Structure("ReturnValue, Status, CountDeleted, DeletedAccounts", true, "", 0, New Array());
			DeletedAccounts = New Array();
			ItemDescription = Item.Description;
			DeletedAccounts.Add(Item);
			BeginTransaction(DataLockControlMode.Managed);
			Try
				//Reflect this in Register
				RecordSet = InformationRegisters.DisconnectedBankAccounts.CreateRecordSet();
				ItemIDFilter = RecordSet.Filter.ItemID;
				ItemAccountIDFilter = RecordSet.Filter.ItemAccountID;
				ItemIDFilter.Use = True;
				ItemIDFilter.ComparisonType = ComparisonType.Equal;
				ItemIDFilter.Value = Item.ItemID;
				ItemAccountIDFilter.Use = True;
				ItemAccountIDFilter.ComparisonType = ComparisonType.Equal;
				ItemAccountIDFilter.Value = Item.ItemAccountID;
				NewRecord = RecordSet.Add();
				NewRecord.Active =  True;
				NewRecord.ItemID = Item.ItemID;
				NewRecord.ItemAccountID = Item.ItemAccountID;
				RecordSet.Write(True);
				
				AccObject = Item.GetObject();
				AccObject.Delete();
				ReturnStruct.Insert("CountDeleted", 1);
				ReturnStruct.Insert("DeletedAccounts", DeletedAccounts);
				ReturnStruct.Insert("Status", "Account " + ItemDescription + " was successfully deleted");

				CommitTransaction();
			Except
				ErrorDesc = ErrorDescription();
				If TransactionActive() Then
					RollbackTransaction();
				EndIf;
				ReturnStruct.Insert("ReturnValue", False);
				ReturnStruct.Insert("CountDeleted", 0);
				ReturnStruct.Insert("DeletedAccounts", New Array());
				ReturnStruct.Insert("Status", "Account " + ItemDescription + " was not deleted. Reason:" + ErrorDesc);
			EndTry;
			return ReturnStruct;
		EndIf;
	EndIf;
EndFunction

//Automatically updates bank transactions
//Used in a background job
//
Procedure YodleeRefreshTransactions() Export
	RefreshTransactionCategories();
	YodleeUpdateBankAccounts();
	Request = New Query("SELECT
	                    |	BankAccounts.Ref,
	                    |	BankAccounts.TransactionsRefreshTimeUTC
	                    |FROM
	                    |	Catalog.BankAccounts AS BankAccounts
	                    |WHERE
	                    |	BankAccounts.YodleeAccount = TRUE
	                    |	AND BankAccounts.DeletionMark = FALSE
	                    |	AND BankAccounts.TransactionsRefreshTimeUTC <= BankAccounts.LastUpdatedTimeUTC");
	Sel = Request.Execute().Select();
	While Sel.Next() Do
		Try
			BankAccount = Sel.Ref;
			BeginTransaction(DataLockControlMode.Managed);
			// Create new managed data lock
			DataLock = New DataLock;

			// Set data lock parameters
			BA_LockItem = DataLock.Add("Catalog.BankAccounts");
			BA_LockItem.Mode = DataLockMode.Exclusive;
			BA_LockItem.SetValue("Ref", BankAccount);
			// Set lock on the object
			DataLock.Lock();
			
			If ValueIsFilled(Sel.TransactionsRefreshTimeUTC) Then //regular refresh. Refresh for the last 7 days
				FromDate = CurrentDate() - 7*24*3600;
				FromDate = BegOfDay(FromDate);
			Else //first refresh. Try to select all possible transactions
				FromDate = Undefined;
			EndIf;
			
			ReturnStruct = ViewTransactions(BankAccount, FromDate);
			If ReturnStruct.ReturnValue Then
				BAObject = BankAccount.GetObject();
				BAObject.TransactionsRefreshTimeUTC = CurrentUniversalDate();
				BAObject.Write();
			EndIf;

			CommitTransaction();
		Except
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
		EndTry;
	EndDo;
EndProcedure

//Updates a list of transactions among all of the accounts with the same ItemID as BankAccount 
//Used in background jobs
//
//Parameters:
// BankAccount - the bank account 
// TempStorageAddress - string, the address of temporary storage
// YodleeStorage - value storage. Stores the status of Com-component
//
//Result:
// Structure
// ReturnValue - success/fail - boolean
// ErrorMessage - in case of failure contains error description
Function RefreshTransactionsOfGroupOfAccounts(BankAccount, TempStorageAddress = Undefined, YodleeStorage = Undefined, TransactionsFromDate = Undefined, TransactionsToDate = Undefined) Export
	ReturnStructure = New Structure("ReturnValue, ErrorMessage");
	ReturnStructure.ReturnValue = True;
		
	If TempStorageAddress <> Undefined Then
		PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Started selecting transactions...", 6), TempStorageAddress);
	EndIf;
	
	If YodleeStorage <> Undefined Then 
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

	
	YodleeUpdateBankAccounts(YodleeMain);
	
	If TypeOf(TransactionsFromDate) = Type("Date") Then
		TransactionsFromDate = BegOfDay(TransactionsFromDate);		
	EndIf;
	If TypeOf(TransactionsToDate) = Type("Date") Then
		TransactionsToDate = BegOfDay(TransactionsToDate);		
	EndIf;
	
	Request = New Query("SELECT
	                    |	BankAccounts.Ref
	                    |FROM
	                    |	Catalog.BankAccounts AS BankAccounts
	                    |WHERE
	                    |	BankAccounts.YodleeAccount = TRUE
	                    |	AND BankAccounts.ItemID = &ItemID");
	Request.SetParameter("ItemID", BankAccount.ItemID);
	Sel = Request.Execute().Select();
	While Sel.Next() Do
		Try
			BankAccount = Sel.Ref;
			BeginTransaction(DataLockControlMode.Managed);
			// Create new managed data lock
			DataLock = New DataLock;

			// Set data lock parameters
			BA_LockItem = DataLock.Add("Catalog.BankAccounts");
			BA_LockItem.Mode = DataLockMode.Exclusive;
			BA_LockItem.SetValue("Ref", BankAccount);
			// Set lock on the object
			DataLock.Lock();
			
			//ReturnStruct = ViewTransactions(BankAccount,,, YodleeStorage);
			ReturnStruct = ViewTransactions(BankAccount, TransactionsFromDate, TransactionsToDate, TempStorageAddress,, YodleeMain);
			If ReturnStruct.ReturnValue Then
				BAObject = BankAccount.GetObject();
				BAObject.TransactionsRefreshTimeUTC = CurrentUniversalDate();
				BAObject.Write();
			Else
				ReturnStructure.ReturnValue = False;
				ReturnStructure.ErrorMessage = ReturnStructure.ErrorMessage + ?(ValueIsFilled(ReturnStructure.ErrorMessage), "; ", "") + ReturnStruct.ErrorMessage;
			EndIf;

			CommitTransaction();
		Except
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
		EndTry;
	EndDo;
	If TempStorageAddress <> Undefined Then
		If ReturnStructure.ReturnValue Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Transactions successfully uploaded.", 7), TempStorageAddress);
		Else
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Not all transactions were successfully uploaded. Please, repeat the operation after a while...", 7), TempStorageAddress);
		EndIf;
	EndIf;
EndFunction

Procedure RefreshTransactionCategories() Export
	Try
		YodleeMain	= New ComObject("YodleeCom.YodleeMain"); 
		If Not LoginUser(YodleeMain) Then
			return;
		EndIf;
		tranCat = YodleeMain.getTransactionCategories(True);
		Request = New Query("SELECT
		                    |	BankTransactionCategories.Ref,
		                    |	BankTransactionCategories.Code
		                    |FROM
		                    |	Catalog.BankTransactionCategories AS BankTransactionCategories");
		CategoriesTable = Request.Execute().Unload();
		i = 0;
		While i < tranCat.Count() Do
			Category 	= tranCat.GetByID(i);
			
			CategoryID 	= Category.categoryID;			
			//Request = New Query("SELECT
			//					|	BankTransactionCategories.Ref
			//					|FROM
			//					|	Catalog.BankTransactionCategories AS BankTransactionCategories
			//					|WHERE
			//					|	BankTransactionCategories.Code = &ID");
			//Request.SetParameter("ID", CategoryID);
			FoundRows = CategoriesTable.FindRows(New Structure("Code", CategoryID));
			If FoundRows.Count() > 0 Then
				CategoryObject = FoundRows[0].Ref.GetObject();
			Else
				CategoryObject = Catalogs.BankTransactionCategories.CreateItem();
			EndIf;
			//Res = Request.Execute();
			//If Not Res.IsEmpty() Then
			//	Sel = Res.Select();
			//	Sel.Next();
			//	CategoryObject = Sel.Ref.GetObject();
			//Else
			//	CategoryObject = Catalogs.BankTransactionCategories.CreateItem();
			//EndIf;
			CategoryObject.Code = CategoryID;
			CategoryObject.Description = Category.categoryName;
			CategoryObject.FullDescription = Category.categoryDescription;
			CategoryTypeID = Category.TransactionCategoryTypeID;
			If ValueIsFilled(CategoryTypeID) Then
				If CategoryTypeID = 1 Then
					CategoryObject.CategoryType = "uncategorized";
				ElsIf CategoryTypeID = 2 Then
					CategoryObject.CategoryType = "income";
				ElsIf CategoryTypeID = 3 Then
					CategoryObject.CategoryType = "expense";
				ElsIf CategoryTypeID = 4 Then
					CategoryObject.CategoryType = "transfer";
				ElsIf CategoryTypeID = 5 Then
					CategoryObject.CategoryType = "DeferredCompensation";
				EndIf;					
			EndIf;
			Try
				CategoryObject.Write();
			Except 
			EndTry;			
			i = i + 1;
		EndDo;

	Except
		ErrorReason = ErrorDescription();
		WriteLogEvent("Yodlee.UpdateTransactionCategories", EventLogLevel.Error,,, ErrorReason);
	EndTry
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
Function ViewTransactions(BankAccount, TransactionsFromDate = Undefined, TransactionsToDate = Undefined, TempStorageAddress = Undefined, YodleeStorage = Undefined, YodleeMain = Undefined) Export
	Try
		WriteLogEvent("Yodlee.UpdateTransactions", EventLogLevel.Information,, BankAccount, "Update of bank transactions started");
		
		ReturnStructure = New Structure("ReturnValue, ErrorMessage");
		ReturnStructure.ReturnValue = True;
		
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Started selecting transactions...", 6), TempStorageAddress);
		EndIf;
		If YodleeStorage <> Undefined Then 
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
			If YodleeMain = Undefined Then 
				YodleeMain	= New ComObject("YodleeCom.YodleeMain"); 
				If Not LoginUser(YodleeMain) Then
					ReturnStructure.ReturnValue = False;
					ReturnStructure.ErrorMessage = "Couldn't login to the provider";
					return ReturnStructure;
				EndIf;
			EndIf;
		EndIf;
		
		Container = GetContainerFromYodleeContainerType(BankAccount.Owner.ContainerType);
		If ValueIsFilled(TransactionsFromDate) or ValueIsFilled(TransactionsToDate) Then
			TransactionSearchResults = YodleeMain.viewTransactionsForItemAccount(BankAccount.ItemID, BankAccount.ItemAccountID, Container, BankAccount.CurrentBalance, TransactionsFromDate, TransactionsToDate);
		else
			TransactionSearchResults = YodleeMain.viewTransactionsForItemAccount(BankAccount.ItemID, BankAccount.ItemAccountID, Container, BankAccount.CurrentBalance, Undefined, Undefined);
		EndIf;
		If Not TransactionSearchResults.searchResult.returnValue Then
			WriteLogEvent("Yodlee.UpdateTransactions", EventLogLevel.Error,, BankAccount, "Error updating transactions for bank account with ItemAccountID:" + BankAccount.ItemAccountID + ". Description:" + TransactionSearchResults.searchResult.errorMessage);
		EndIf;
		TransactionsRS = InformationRegisters.BankTransactions.CreateRecordSet();
		Transactions = TransactionsRS.Unload();
		Transactions.Clear();
		For j = 0 To TransactionSearchResults.Count() - 1 Do
			TransactionSearchResult = TransactionSearchResults.GetByID(j);
			TransactionSearchResult.FillInTransactions();
			For i = 0 To TransactionSearchResult.Count()-1 Do
				YodleeTran 	= TransactionSearchResult.GetByID(i);
				//Upload only Posted transactions
				If YodleeTran.status.statusId <> 1 Then
					Continue;
				EndIf;
					
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
				NewTran.CategoryID	 	= YodleeTran.category.categoryId;
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
						//Check if found transaction has been already accepted
						//In this case no changes are allowed, excepting the amount or the Currency code have changed
						If FoundTransaction[0].Accepted Then
							If (FoundTransaction[0].Amount <> TranPerDate.Amount) 
								OR (FoundTransaction[0].CurrencyCode <> TranPerDate.CurrencyCode) 
								OR (FoundTransaction[0].TransactionDate <> TranPerDate.TransactionDate) Then
								FillPropertyValues(FoundTransaction[0], TranPerDate, "TransactionDate, Description, Amount, CategoryID, PostDate, Price, Quantity, RunningBalance, CurrencyCode, Type");
							Else
								FillPropertyValues(FoundTransaction[0], TranPerDate, "CategoryID, PostDate, Price, Quantity, RunningBalance, Type");
							EndIf;
						Else
							FillPropertyValues(FoundTransaction[0], TranPerDate, "BankAccount, TransactionDate, Description, Amount, CategoryID, PostDate, Price, Quantity, RunningBalance, CurrencyCode, Type");
						EndIf;
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
				WriteLogEvent("Yodlee.UpdateTransactions", EventLogLevel.Error,, BankAccount, ReturnStructure.ErrorMessage);
			EndTry;
		EndDo;
		
		WriteLogEvent("Yodlee.UpdateTransactions", EventLogLevel.Information,, BankAccount, "Bank transactions are successfully updated");
		
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Transactions successfully uploaded.", 7), TempStorageAddress);
		EndIf;
			
	Except
		ErrorReason = ErrorDescription();
		WriteLogEvent("Yodlee.UpdateTransactions", EventLogLevel.Error,,, ErrorReason);
		ReturnStructure.ReturnValue = False;
		ReturnStructure.ErrorMessage = "An error occured while downloading transactions: " + ErrorReason;
		WriteLogEvent("Yodlee.UpdateTransactions", EventLogLevel.Error,, BankAccount, ReturnStructure.ErrorMessage);
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

//Returns array of fields and values for MFA
//
//Parameters:
//ItemID - the ID of a bank account in Yodlee system
//
//Returns:
//Structure - returns the following properties:
//	ReturnValue - boolean - true if succeeded
//	ProgrammaticElements - array of structures, containing MFA fields description
//	ProgrammaticElementsValidValues - array of structures, containing predefined set of possible values
//	YodleeStorage - YodleeMain status
//
Function EditItem_GetFormFields(ItemID, TempStorageAddress = Undefined) Export
	ReturnStructure = New Structure("ReturnValue, ProgrammaticElements, ProgrammaticElementsValidValues");
	Try
		WriteLogEvent("Yodlee.EditItem_GetFormFields", EventLogLevel.Information,,, "Started editing accounts for the bank account with ItemID: " + String(ItemID));	
		YodleeMain	= New ComObject("YodleeCom.YodleeMain"); 
		If Not LoginUser(YodleeMain) Then
			ReturnStructure.Insert("ReturnValue", False);
			
			If TempStorageAddress <> Undefined Then
				PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Login failed...", 1), TempStorageAddress);
			EndIf;
			return ReturnStructure;			
		EndIf;
		
		FFQ = YodleeMain.editItem_GetFormFieldsQueue(ItemID);
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
						newPEValVal.DisplayValidValue 	= displayValidValues.GetByID(i);
						newPEValVal.ElementName 		= NewPE.ElementName;
						newPEValVal.Serial 				= i + 1;
						i = i + 1;
					EndDo;
				EndIf;
				If FieldInfoSingle.validValues <> Undefined Then
					validValues			= FFQ.GetStringArray(FieldInfoSingle.validValues);
					For i = 0 To validValues.Count()-1 Do
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
		WriteLogEvent("Yodlee.EditItem_GetFormFields", EventLogLevel.Error,,, ErrorDescription());
		ReturnStructure.Insert("ReturnValue", False);
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "An error occured", 1), TempStorageAddress);
		EndIf;
		return ReturnStructure;
	EndTry;
EndFunction

//Updates bank account's credentials at Yodlee server
//
//Parameters:
//ItemID - the ID of a bank account
//ProgrammaticElems - array of structures with the filled MFA fields
//YodleeStorage - YodleeMain status
//TempStorageAddress - the address, where to put the result
//
//Returns:
//Structure - returns the following properties:
//	Result - boolean (success/fail). If - False, then failed;
//	YodleeStorage - YodleeMain status;
//
Function EditItem_UpdateEditedItem(ItemID, ProgrammaticElems, YodleeStorage, TempStorageAddress = Undefined) Export
	ReturnStructure = new Structure("Result, YodleeStorage, ItemID");
	ReturnStructure.Insert("Result", False);
	ReturnStructure.Insert("ItemID", ItemID);
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
		WriteLogEvent("Yodlee.EditItem_ProcessingMFAFields", EventLogLevel.Error,,, ErrorDescription());
		ReturnStructure.Insert("Result", False);
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Internal error occured...", 2), TempStorageAddress);
		EndIf;
		return ReturnStructure;
	EndTry;
	Try
		Success = YodleeMain.editItem_updateItem(ItemID, ArrayList);
		ReturnStructure.Insert("Result", Success);
		If TempStorageAddress <> Undefined Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Bank account credentials were updated successfully...", 2), TempStorageAddress);
		EndIf;
		return ReturnStructure;
	Except
		WriteLogEvent("Yodlee.EditItem_UpdateEditedItem", EventLogLevel.Error,,, ErrorDescription());
		ReturnStructure.Insert("Result", False);
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
		If YodleeStorage <> Undefined Then 
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
		
		If Not Constants.ServiceDB.Get() Then
			WriteLogEvent("Yodlee.LoginUser", EventLogLevel.Error,,, "User login failed. Login to Yodlee available only in the Service DB");
			return False;
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

//Yodlee connection lock mechanism

Function LockYodleeConnection(FormID) Export
	Try
		LockDataForEdit(Catalogs.BankAccounts.EmptyRef(),,FormID);
		return True;
	Except
		return False;
	EndTry;		
EndFunction

Function UnlockYodleeConnection(FormID) Export
	UnlockDataForEdit(Catalogs.BankAccounts.EmptyRef(),FormID);
	return True;
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
				YodleeUpdateBankAccounts(YodleeMain);
				If TempStorageAddress <> Undefined Then
					PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, RefreshProcess.Status, 4), TempStorageAddress);
				EndIf;
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
					//ReturnStructure.Status = RefreshProcess.Status;
					ReturnStructure.Status = RefreshProcess.ExceptionDescription;
					ReturnStructure.IsMFA = False;
					//If Not RefreshProcess.OK Then
					WriteLogEvent("Yodlee.RefreshItem_ProcessMFA", EventLogLevel.Error,,, RefreshProcess.ExceptionDescription);
					//EndIf;
					YodleeUpdateBankAccounts(YodleeMain);
					If TempStorageAddress <> Undefined Then
						PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, RefreshProcess.Status, 5), TempStorageAddress);
					EndIf;
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
				If TempStorageAddress <> Undefined Then
					PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Error on obtaining MFA fields...", 4), TempStorageAddress);
				EndIf;
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
			Tenant = SessionParameters.TenantValue;
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

Procedure DeleteUninitializedAccounts(BankAccountToDelete = Undefined)
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
			                            |		AND BankAccounts.ItemAccountID = 0
			                            |		AND (BankAccounts.Ref = &BankAccountToDelete
			                            |				OR BankAccounts.Ref = VALUE(Catalog.BankAccounts.EmptyRef))) AS UninitializedBA
			                            |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
			                            |		ON UninitializedBA.Ref = BankTransactions.BankAccount
			                            |WHERE
			                            |	BankTransactions.BankAccount IS NULL ");
										
			If BankAccountToDelete = Undefined Then
				EmptyBA_Request.SetParameter("BankAccountToDelete", Catalogs.BankAccounts.EmptyRef());
			Else
				EmptyBA_Request.SetParameter("BankAccountToDelete", BankAccountToDelete);
			EndIf;								
			EmptyBA_Result = EmptyBA_Request.Execute().Select();
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

Function GetYodleeContainerType(ContainerType)
	If Upper(ContainerType) = "BANK" Then
		return Enums.YodleeContainerTypes.Bank;
	ElsIf Upper(ContainerType) = "CREDITS" Then
		return Enums.YodleeContainerTypes.Credit_Card;
	Else
		Raise "Illegal FI container type";
	EndIf;
EndFunction

Function GetContainerFromYodleeContainerType(ContainerType)
	If ContainerType = Enums.YodleeContainerTypes.Bank Then
		return "bank";
	ElsIf ContainerType = Enums.YodleeContainerTypes.Credit_Card Then
		return "credits";
	Else
		Raise "Illegal FI container type";
	EndIf;
EndFunction
#EndRegion
