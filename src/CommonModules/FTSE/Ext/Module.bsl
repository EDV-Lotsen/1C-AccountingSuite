Procedure UpdateFTSE() Export
	
	//WriteLogEvent(NStr("en = '8.3 FTS indexing'"),
	//EventLogLevel.Information, , ,
	//NStr("en = '8.3 FTS indexing'"));
	
	FullTextSearch.UpdateIndex(False, True);

	
EndProcedure

Procedure MergeFTSE() Export
	
	FullTextSearch.UpdateIndex(True);
	
EndProcedure 


