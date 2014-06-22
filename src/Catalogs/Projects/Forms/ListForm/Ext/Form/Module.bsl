
&AtClient
Procedure Transactions(Command)
	
	ParametersStructure = New Structure;	
	ParametersStructure.Insert("Filter", New Structure("Project", Items.List.CurrentRow)); 
	
	OpenForm("AccumulationRegister.ProjectData.ListForm", ParametersStructure, , True);
	
EndProcedure

&AtClient
Procedure TransactionsWithoutProject(Command)
	
	ParametersStructure = New Structure;	
	ParametersStructure.Insert("Filter", New Structure("Project", PredefinedValue("Catalog.Projects.EmptyRef"))); 
	
	OpenForm("AccumulationRegister.ProjectData.ListForm", ParametersStructure, , True);
	
EndProcedure
