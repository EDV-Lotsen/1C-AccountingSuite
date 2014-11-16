
Procedure OnWrite(Cancel)
	
	If Not Cancel Then
		
		WriteHierarchy(Ref);
		
		ChartOfAccountsSelection = ChartsOfAccounts.ChartOfAccounts.SelectHierarchically(Ref);
		While ChartOfAccountsSelection.Next() Do
			WriteHierarchy(ChartOfAccountsSelection.Ref);
		EndDo;
		
	EndIf;
	
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
