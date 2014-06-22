
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ExceptionCode = Parameters.StatusCode;
	//Prepare error details
	Template = DataProcessors.DownloadedTransactions.GetTemplate("DetailedErrorMessages");
	ColumnArea = Template.Area(0,1,0,1);
	FoundRange = Template.FindText(ExceptionCode,,ColumnArea);
	If FoundRange = Undefined Then
		ErrorDescription = "Error description not found.";
	Else
		TypeOfError 		= Template.Area(FoundRange.Bottom, 3, FoundRange.Bottom, 3).Text;
		ErrorDescription 	= Template.Area(FoundRange.Bottom, 6, FoundRange.Bottom, 6).Text;
		PossibleWorkarounds = Template.Area(FoundRange.Bottom, 7, FoundRange.Bottom, 7).Text;
	EndIf;
EndProcedure
