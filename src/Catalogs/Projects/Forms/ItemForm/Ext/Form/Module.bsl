
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	DetailedDesc();
	
EndProcedure

&AtServer
Procedure DetailedDesc()
	
	OriginalString = StrReplace(Object.Description,Object.Owner.Description + ": ", "");
	Object.Description = Object.Owner.Description + ": " + OriginalString;
			     
EndProcedure