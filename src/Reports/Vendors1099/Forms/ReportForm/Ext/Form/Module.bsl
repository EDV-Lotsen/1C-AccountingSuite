
&AtClient
Procedure Create(Command)
	
	ComposeResult();
	
EndProcedure

&AtClient
Procedure Excel(Command)
	
	Structure = GeneralFunctions.GetExcelFile("Vendors 1099", Result);
	
	GetFile(Structure.Address, Structure.FileName, True); 

EndProcedure
