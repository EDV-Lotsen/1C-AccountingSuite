
&AtClient
Procedure DocumentListSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	NotifyChoice(SelectedRow);
EndProcedure

&AtClient
Procedure SelectCommand(Command)
	NotifyChoice(Items.DocumentList.CurrentRow);
EndProcedure
