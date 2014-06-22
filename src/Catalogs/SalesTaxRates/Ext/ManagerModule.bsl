
Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	StandardProcessing = False;
	Fields.Add("Description");
	Fields.Add("Rate");
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	StandardProcessing = False;
	Presentation = Data.Description + " (" + Format(Data.Rate, "NZ=") + "%)";
EndProcedure
