
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Try
		obj = Parameters.FormOwner;
		FilterItem = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterItem.LeftValue = New DataCompositionField("Object");
		FilterItem.ComparisonType = DataCompositionComparisonType.Equal;
		FilterItem.Use = True;
		FilterItem.RightValue = obj;
		Items.Object.Visible = False;
	Except
		
	EndTry;	
EndProcedure


