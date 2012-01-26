
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.ARAccountLabel.Title = GeneralFunctions.GetAttributeValue(Object.DefaultARAccount, "Description");
	Items.APAccountLabel.Title = GeneralFunctions.GetAttributeValue(Object.DefaultAPAccount, "Description");
	Items.AccruedPurchasesLabel.Title = GeneralFunctions.GetAttributeValue(Object.DefaultAccruedPurchasesAccount, "Description");

	
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
	DoMessageBox("Fill in default A/R, A/P, and Accrued Purchases accounts after adding a new currency");
EndProcedure

&AtClient
Procedure DefaultAccruedPurchasesAccountOnChange(Item)
		Items.AccruedPurchasesLabel.Title = GeneralFunctions.GetAttributeValue(Object.DefaultAccruedPurchasesAccount, "Description");
EndProcedure
