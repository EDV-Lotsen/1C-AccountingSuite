
//////////////////////////////////////////////////////////////////////////////
// Block of service procedures

&AtClient
Procedure SetFormItems()
	
	If ChangeInTransaction Then
		Items.GroupInterruptOnError.Enabled = False;
	Else
		Items.GroupInterruptOnError.Enabled = True;
	EndIf;
	
EndProcedure

//////////////////////////////////////////////////////////////////////////////
// Block of procedures - form command handlers

&AtClient
Procedure OK(Command)
	
	Settings = New Structure;
	Settings.Insert("ChangeInTransaction",		 ChangeInTransaction);
	Settings.Insert("ProcessRecursively",		 ProcessRecursively);
	Settings.Insert("PortionSetting",			 PortionSetting);
	Settings.Insert("ObjectPercentageInPortion", ObjectPercentageInPortion);
	Settings.Insert("NumberOfObjectsInPortion",	 NumberOfObjectsInPortion);
	Settings.Insert("AbortOnError",				 AbortOnError);
	
	Close(Settings);
	
EndProcedure

//////////////////////////////////////////////////////////////////////////////
// Block of procedures - event handlers of form and form items

&AtClient
Procedure OnOpen(Cancellation)
	
	SetFormItems();
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	ChangeInTransaction			= Parameters.ChangeInTransaction;
	ProcessRecursively			= Parameters.ProcessRecursively;
	PortionSetting				= Parameters.PortionSetting;
	ObjectPercentageInPortion	= Parameters.ObjectPercentageInPortion;
	NumberOfObjectsInPortion	= Parameters.NumberOfObjectsInPortion;
	AbortOnError				= Parameters.AbortOnError;
	
EndProcedure

&AtClient
Procedure ChangeInTransactionOnChange(Item)
	
	SetFormItems();
	
EndProcedure

&AtClient
Procedure ChangeByPortionsOnChange(Item)
	
	SetFormItems();
	
EndProcedure
