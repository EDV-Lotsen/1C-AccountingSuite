
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	Try
		PrintFormFunctions.ReportOnComposeResult(ResultDocument, DetailsData, StandardProcessing, ThisObject.Metadata().Name);
	Except
	EndTry
	
EndProcedure
