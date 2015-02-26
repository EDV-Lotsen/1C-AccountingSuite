
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Set parameters of List.
	List.Parameters.SetParameterValue("UseShipment", Parameters.UseShipment);
	List.Parameters.SetParameterValue("Company", Parameters.Company);
	
	ThisForm.Title = Parameters.Company;
	
EndProcedure

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;

	NewValue = New Array;
	
	For each Row In Value Do
		
		Items.List.CurrentRow = Row;
		
		NewValue.Add(Items.List.CurrentData.Ref);
		
	EndDo;
	
	Close(NewValue); 

EndProcedure