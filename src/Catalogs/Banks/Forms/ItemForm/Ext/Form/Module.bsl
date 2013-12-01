
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	CatalogObj = FormAttributeToValue("Object");
	If CatalogObj.IsNew() Then
		If ValueIsFilled(CatalogObj.Description) Then
			ThisForm.Title = CatalogObj.Description;
		EndIf;
	EndIf;
	If ValueIsFilled(Object.ServiceID) Then
		Items.Description.Visible = False;		
	Else
		Items.Description.Visible = True;		
	EndIf;
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	DateUpdatedLocalTime = ToLOcalTime(Object.DateUpdatedUTC);
	CatalogObject = FormAttributeToValue("Object");
	If ValueIsFilled(CatalogObject.Logotype.Get()) Then
		LogotypeAddress = GetURL(CatalogObject, "Logotype");
		Items.Logotype.PictureSize = PictureSize.Proportionally;
		Items.Logotype.Width = 12;
		Items.Logotype.Height = 4;
	ElsIf ValueIsFilled(CatalogObject.Icon.Get()) Then
		LogotypeAddress = GetURL(CatalogObject, "Icon");
		Items.Logotype.PictureSize = PictureSize.RealSize;
		Items.Logotype.Width = 6;
		Items.Logotype.Height = 2;
	Else		
		LogotypeAddress = "";
	EndIf;
	If Not ValueIsFilled(LogotypeAddress) Then
		Items.Logotype.Visible = False;
	EndIf;
EndProcedure

&AtClient
Procedure ServiceURLClick(Item, StandardProcessing)
	StandardProcessing = false;
	If ValueIsFilled(Object.ServiceURL) Then
		GotoUrl(Object.ServiceURL);
	EndIf;
EndProcedure

&AtClient
Procedure DescriptionTextEditEnd(Item, Text, ChoiceData, Parameters, StandardProcessing)
	ThisForm.Title = Text;
EndProcedure



