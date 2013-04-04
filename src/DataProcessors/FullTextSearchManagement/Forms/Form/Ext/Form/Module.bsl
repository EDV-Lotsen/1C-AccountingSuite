

// Refresh search index
//
&AtClient
Procedure UpdateIndexExecute()
	
	Status(NStr("en = 'Updating fullsearch index..."
				"Please wait.'"));
	UpdateIndexServer();
	RefreshStatus();
	Status(NStr("en = 'Updates of the full text index has been completed'"));
	
EndProcedure

&AtServer
Procedure UpdateIndexServer()
	FullTextSearch.UpdateIndex(False, False);
EndProcedure

// Clear index
//
&AtServer
Procedure ClearIndexServer() Export
	FullTextSearch.ClearIndex();
EndProcedure	

// Clear index
&AtClient
Procedure ClearIndexExecute()
	ClearIndexServer();	
	RefreshStatus();
EndProcedure

// Refresh status - accessibility of buttons, index actuality date.
&AtServer
Procedure RefreshStatus()
	AllowFullTextSearch = (FullTextSearch.GetFullTextSearchMode() = FullTextMode.Enable);
	If AllowFullTextSearch Then
		DateActualityIndex = FullTextSearch.UpdateDate();
		IndexTrue = FullTextSearch.IndexTrue();
	EndIf;	
	
	IndexStatus = "";
	
	If AllowFullTextSearch Then
		If IndexTrue Then
			IndexStatus = NStr("en = 'Index update is not required.'");
		Else
			IndexStatus = NStr("en = 'Index update required.'");
		EndIf;
	EndIf;
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	RefreshStatus();
EndProcedure

