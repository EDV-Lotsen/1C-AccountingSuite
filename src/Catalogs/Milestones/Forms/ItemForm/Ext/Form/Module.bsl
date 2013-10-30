
&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	CompleteCount = 0;
	RowCount = 0;
	For Each LineItem In Object.Tasks Do
		RowCount = RowCount + 1;
		If LineItem.Completed = True Then
			CompleteCount = CompleteCount + 1;
		Endif;
	EndDo;
	CurrentObject.TasksComplete = "("+ CompleteCount + "/" + RowCount + ")";

EndProcedure


&AtClient
Procedure OnOpen(Cancel)
	OnOpenAtServer();
EndProcedure


&AtServer
Procedure OnOpenAtServer()

EndProcedure

