

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	FillTableOfAvailableSections(Parameters.DataProcessorKind);
	
	For Each SectionItem In Parameters.Sections Do
		SectionName = SectionItem.Value;
		StringFound = Sections.FindRows(New Structure("SectionName", SectionName));
		If StringFound.Count() = 1 Then
			StringFound[0].InUse = True;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure FillTableOfAvailableSections(DataProcessorKind)
	
	If DataProcessorKind = Enums.AdditionalReportAndDataProcessorTypes.AdditionalDataProcessor Then
		CommandsTable = AdditionalReportsAndDataProcessorsOverrided.GetAdditionalDataProcessorCommonCommands();
	Else
		CommandsTable = AdditionalReportsAndDataProcessorsOverrided.GetAdditionalReportCommonCommands();
	EndIf;
	
	For Each CommandDescription In CommandsTable Do
		NewRow = Sections.Add();
		NewRow.SectionName = CommandDescription.CommandName;
		NewRow.Presentation = CommandDescription.WorkspaceName;
	EndDo;
	
	Sections.Sort("Presentation Asc");
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	Result = New ValueList;
	
	For Each SectionItem In Sections Do
		If SectionItem.InUse Then
			Result.Add(SectionItem.SectionName);
		EndIf;
	EndDo;
	
	Close(Result);
	
EndProcedure
