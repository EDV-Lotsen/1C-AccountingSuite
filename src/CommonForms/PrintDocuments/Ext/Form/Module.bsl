
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	Var PrintFormsCollection, OutputParameters;
	
	PrintManagerName = Parameters.PrintManagerName;
	TemplateNames       = Parameters.TemplateNames;
	CommandParameter    = Parameters.CommandParameter;
	PrintParameters    = Parameters.PrintParameters;
		
	PrintManagement.GeneratePrintForms(PrintManagerName, TemplateNames, CommandParameter, PrintParameters,
		PrintFormsCollection, PrintObjects, OutputParameters);
			
	KitPrintingEnabled = OutputParameters.KitPrintingEnabled;
	
	TemplatePage = PrintFormsCollection[0];
	
	ThisForm["Tab1"] = TemplatePage.SpreadsheetDocument;
	Items["Group1"].Visible = True;
	Items["Group1"].Title = TemplatePage.TemplateSynonym;
	
	If NOT IsBlankString(TemplatePage.TemplateFullPath) Then
		PrintFormTemplates.Add(TemplatePage.TemplateFullPath);
	EndIf;
	
EndProcedure
