
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	For Each Column In Parameters.ListForOutput Do
		ListForOutput.Add(Column.Value, Column.Presentation, True, Column.Picture);
	EndDo;
	SelectedItemsOnly = Parameters.SelectedItemsOnly;
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	ColumnsForOutput = new ValueList();
	For Each ListItem In ListForOutput Do
		If ListItem.Check Then
			ColumnsForOutput.Add(ListItem.Value, ListItem.Presentation, ListItem.Check, ListItem.Picture);
		EndIf;
	EndDo;
	Close(new Structure("ColumnsForOutput, SelectedItemsOnly", ColumnsForOutput, SelectedItemsOnly));
	
EndProcedure
