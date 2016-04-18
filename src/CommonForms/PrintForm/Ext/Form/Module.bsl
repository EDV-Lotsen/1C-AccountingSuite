
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("SpreadsheetDocument") Then
		Result			= Parameters.SpreadsheetDocument;
	Else
		Cancel = True;	
	EndIf;
	
	ThisForm.Title	= Parameters.TitleOfForm;
	If ValueIsFilled(Parameters.PrintFormID) Then
		PrintFormID = Parameters.PrintFormID.Metadata().FullName();
	EndIf;
	
	PrintFormID = PrintFormID + " (" + Parameters.TitleOfForm + ")";
	
	PrintFormSettings = PrintFormFunctions.GetPrintFormSettings(PrintFormID);
	FillPropertyValues(Result, PrintFormSettings);
	Result.PageOrientation = ?(PrintFormSettings.PrintPageOrientation = 0, PageOrientation.Portrait, PageOrientation.Landscape);
	
EndProcedure

&AtClient
Procedure Excel(Command)
	
	Structure = GeneralFunctions.GetExcelFile(ThisForm.Title, Result);
	
	GetFile(Structure.Address, Structure.FileName, True); 
	
EndProcedure
