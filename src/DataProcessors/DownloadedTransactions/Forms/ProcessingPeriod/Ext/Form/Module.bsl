
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ProcessingPeriod = Parameters.ProcessingPeriod;
EndProcedure

&AtClient
Procedure OK(Command)
	ReturnStructure = New Structure();
	ReturnStructure.Insert("ProcessingPeriod", ProcessingPeriod);
	Close(ReturnStructure);
EndProcedure

