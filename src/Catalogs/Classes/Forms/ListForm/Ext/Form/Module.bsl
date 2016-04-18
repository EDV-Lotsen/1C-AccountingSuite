
&AtClient
Procedure Transactions(Command)
	
	ParametersStructure = New Structure;	
	ParametersStructure.Insert("Filter", New Structure("Class", Items.List.CurrentRow)); 
	
	OpenForm("AccumulationRegister.GeneralJournalAnalyticsDimensions.ListForm", ParametersStructure, , True);
	
EndProcedure

&AtClient
Procedure TransactionsWithoutClass(Command)
	
	ParametersStructure = New Structure;	
	ParametersStructure.Insert("Filter", New Structure("Class", PredefinedValue("Catalog.Classes.EmptyRef"))); 
	
	OpenForm("AccumulationRegister.GeneralJournalAnalyticsDimensions.ListForm", ParametersStructure, , True);
	
EndProcedure

