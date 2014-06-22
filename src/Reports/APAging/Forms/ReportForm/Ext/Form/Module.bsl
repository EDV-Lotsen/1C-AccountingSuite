//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////

&AtClient
Procedure Excel(Command)
	
	//Result.Write("" + GetSystemTitle() + " - Income statement" , SpreadsheetDocumentFileType.XLSX); 
	
	FileName = "" + GetSystemTitle() + " - AP aging (due date).xlsx"; 
	GetFile(GetFileName(), FileName, True); 

EndProcedure

&AtServer
Function GetFileName()
	
	TemporaryFileName = GetTempFileName(".xlsx");
	
	Result.Write(TemporaryFileName, SpreadsheetDocumentFileType.XLSX);
	BinaryData = New BinaryData(TemporaryFileName);
	
	DeleteFiles(TemporaryFileName);
	
	Return PutToTempStorage(BinaryData);
	
EndFunction

&AtServerNoContext
Function GetSystemTitle()
	
	SystemTitle = Constants.SystemTitle.Get();
	
	NewSystemTitle = "";
	
	For i = 1 To StrLen(SystemTitle) Do
		
		Char = Mid(SystemTitle, i, 1);
		
		If Find("#&\/:*?""<>|.", Char) > 0 Then
			NewSystemTitle = NewSystemTitle + " ";	
		Else
			NewSystemTitle = NewSystemTitle + Char;	
		EndIf;
		
	EndDo;	
	
	Return NewSystemTitle;
	
EndFunction

//////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////

&AtClient
Procedure OnOpen(Cancel)
	Variant = CurrentVariantDescription;
EndProcedure

&AtClient
Procedure VariantOnChange(Item)
	
	CurrentVariantDescription = Variant;
	SetCurrentVariant(CurrentVariantDescription);
	
	ModifiedStatePresentation();
		
EndProcedure

&AtServer
Procedure ModifiedStatePresentation()
	
	Items.Result.StatePresentation.Visible = True;
	Items.Result.StatePresentation.Text = "Report not generated. Click ""Create Report"" to obtain a report.";
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	
EndProcedure

&AtClient
Procedure Create(Command)
	ComposeResult();
EndProcedure

