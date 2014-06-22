
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If object.Customer.IsEmpty() Then
		Message("Please choose a customer for your project");
		Cancel = true;
	Endif;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Customer = Catalogs.Companies.EmptyRef() Then
	Else	
		items.Customer.ReadOnly = True;
	Endif;

EndProcedure
