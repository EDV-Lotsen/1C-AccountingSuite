
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.ARAccountLabel.Title = GeneralFunctions.GetAttributeValue(Object.DefaultARAccount, "Description");
	Items.APAccountLabel.Title = GeneralFunctions.GetAttributeValue(Object.DefaultAPAccount, "Description");
	
EndProcedure

&AtClient
Procedure DefaultARAccountOnChange(Item)
	
		Items.ARAccountLabel.Title = GeneralFunctions.GetAttributeValue(Object.DefaultARAccount, "Description");

EndProcedure

&AtClient
Procedure DefaultAPAccountOnChange(Item)
	
		Items.APAccountLabel.Title = GeneralFunctions.GetAttributeValue(Object.DefaultAPAccount, "Description");

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	DoMessageBox("Fill in default A/R and A/P accounts after adding a new currency");
EndProcedure
