
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Ref.IsEmpty() Then
		
		Cancel = True;
		
	Else
		
		Array = New Array();
		Array.Add(Object.Ref);
		
		Documents.Statement.Print(Result, Array);
		
	EndIf;
	
EndProcedure
