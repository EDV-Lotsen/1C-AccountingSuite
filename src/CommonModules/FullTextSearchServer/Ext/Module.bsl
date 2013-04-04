
////////////////////////////////////////////////////////////////////////////////
// MODULE OF FULL-TEXT SEARCH INDEX CONTROL

// Updates full-text search index
Procedure UpdateFullTextSearchIndex() Export
	
	AllowFullTextSearch = FullTextSearch.GetFullTextSearchMode() = FullTextMode.Enable;
	If AllowFullTextSearch = False Then
		Return;
	EndIf;	
	
	Try
		WriteLogEvent(NStr("en = 'Full Text Indexing'"),
			EventLogLevel.Information, , ,
			NStr("en = 'Scheduled portion indexing started.'"));
		
		FullTextSearch.UpdateIndex(False, True);
		
		WriteLogEvent(NStr("en = 'Full Text Indexing'"),
			EventLogLevel.Information, , ,
			NStr("en = 'Scheduled portion indexing finished.'"));
	Except
		ErrorMessageText = StringFunctionsClientServer.SubstitureParametersInString(
		  NStr("en = 'An unknown error %1 occurred during scheduled index update.'"), ErrorDescription());
		WriteLogEvent(NStr("en = 'Full Text Indexing'"),
			EventLogLevel.Error, , ,
			ErrorMessageText);
	EndTry;
	
EndProcedure

// Merges full-text search indexes
Procedure MergeFullTextSearchIndex() Export
	
	AllowFullTextSearch = FullTextSearch.GetFullTextSearchMode() = FullTextMode.Enable;
	If AllowFullTextSearch = False Then
		Return;
	EndIf;	
	
	Try
		WriteLogEvent(NStr("en = 'Full Text Indexing'"),
			EventLogLevel.Information, , ,
			NStr("en = 'Scheduled merge of indexes started'"));
		
		FullTextSearch.UpdateIndex(True);
		
		WriteLogEvent(NStr("en = 'Full Text Indexing'"),
			EventLogLevel.Information, , ,
			NStr("en = 'Scheduled merge of indexes finished.'"));
	Except
		ErrorMessageText =
		  	StringFunctionsClientServer.SubstitureParametersInString(
		    	NStr("en = 'An unknown error %1 occurred during scheduled index merge.'"), ErrorDescription());
		WriteLogEvent(NStr("en = 'Full Text Indexing'"),
			EventLogLevel.Error, , ,
			ErrorMessageText);
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Infobase update.

// Sync constant UseFullTextSearch with FullTextSearch.GetFullTextMode()
Procedure InitializeFunctionalOptionFullTextSearch() Export
	If FullTextSearch.GetFullTextSearchMode() = FullTextMode.Enable Then
		Constants.UseFullTextSearch.Set(True);
	Else
		Constants.UseFullTextSearch.Set(False);
	EndIf;	
EndProcedure

