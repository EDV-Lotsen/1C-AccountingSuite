
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ProcessingPeriod = Parameters.ProcessingPeriod;
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	//StandardProcessing = False;
	//ReturnStructure = New Structure();
	//ReturnStructure.Insert("ProcessingPeriod", ProcessingPeriod);
	//Close(ReturnStructure);
EndProcedure


&AtClient
Procedure OK(Command)
	ReturnStructure = New Structure();
	ReturnStructure.Insert("ProcessingPeriod", ProcessingPeriod);
	Close(ReturnStructure);
EndProcedure

