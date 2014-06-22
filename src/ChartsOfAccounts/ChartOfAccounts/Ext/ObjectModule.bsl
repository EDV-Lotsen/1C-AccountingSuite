
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