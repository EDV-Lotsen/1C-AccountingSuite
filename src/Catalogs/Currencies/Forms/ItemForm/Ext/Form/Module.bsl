
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.ARAccountLabel.Title = CommonUse.GetAttributeValue(Object.DefaultARAccount, "Description");
	Items.APAccountLabel.Title = CommonUse.GetAttributeValue(Object.DefaultAPAccount, "Description");
	
EndProcedure

&AtClient
Procedure DefaultARAccountOnChange(Item)
	
		Items.ARAccountLabel.Title = CommonUse.GetAttributeValue(Object.DefaultARAccount, "Description");

EndProcedure

&AtClient
Procedure DefaultAPAccountOnChange(Item)
	
		Items.APAccountLabel.Title = CommonUse.GetAttributeValue(Object.DefaultAPAccount, "Description");

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Object.DefaultAPAccount.IsEmpty() OR
		Object.DefaultARAccount.IsEmpty() Then
	
			DoMessageBox("Fill in default A/R, and A/P accounts after adding a new currency");
	
	EndIf;
		
EndProcedure
