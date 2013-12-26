
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CF1AName = Constants.CF1AName.Get();
	If CF1AName <> "" Then
		Items.CF1String.Title = CF1AName;
	EndIf;
	
	CF2AName = Constants.CF2AName.Get();
	If CF2AName <> "" Then
		Items.CF2String.Title = CF2AName;
	EndIf;

	CF3AName = Constants.CF3AName.Get();
	If CF3AName <> "" Then
		Items.CF3String.Title = CF3AName;
	EndIf;

	
	CF4AName = Constants.CF4AName.Get();
	If CF4AName <> "" Then
		Items.CF4String.Title = CF4AName;
	EndIf;

	CF5AName = Constants.CF5AName.Get();
	If CF5AName <> "" Then
		Items.CF5String.Title = CF5AName;
	EndIf;
	
	If Object.Owner.Customer = False Then
		Items.SalesTaxCode.Visible = False;	
	EndIf;

	
	If Object.Owner.Customer = False Then
		Items.SalesTaxCode.Visible = False;	
	EndIf;
EndProcedure
