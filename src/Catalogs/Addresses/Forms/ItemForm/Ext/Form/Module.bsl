
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Object.Owner.Customer = False Then
		Items.SalesTaxCode.Visible = False;	
	EndIf;
EndProcedure
