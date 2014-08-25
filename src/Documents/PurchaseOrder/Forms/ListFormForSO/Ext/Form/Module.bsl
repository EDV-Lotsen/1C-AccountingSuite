
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BaseDocument = Parameters.Filter.BaseDocument;
	
	List.Parameters.SetParameterValue("BaseDocument", BaseDocument);
	ThisForm.Title = "" + BaseDocument; 
	
EndProcedure
