
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// custom fields
	
	CF1Type = Constants.CF1Type.Get();
	CF2Type = Constants.CF2Type.Get();
	CF3Type = Constants.CF3Type.Get();
	CF4Type = Constants.CF4Type.Get();
	CF5Type = Constants.CF5Type.Get();
	
	If CF1Type = "None" Then
		Items.CF1Num.Visible = False;
		Items.CF1String.Visible = False;
	ElsIf CF1Type = "Number" Then
		Items.CF1Num.Visible = True;
		Items.CF1String.Visible = False;
		Items.CF1Num.Title = Constants.CF1Name.Get();
	ElsIf CF1Type = "String" Then
	    Items.CF1Num.Visible = False;
		Items.CF1String.Visible = True;
		Items.CF1String.Title = Constants.CF1Name.Get();
	ElsIf CF1Type = "" Then
		Items.CF1Num.Visible = False;
		Items.CF1String.Visible = False;
	EndIf;
	
	If CF2Type = "None" Then
		Items.CF2Num.Visible = False;
		Items.CF2String.Visible = False;
	ElsIf CF2Type = "Number" Then
		Items.CF2Num.Visible = True;
		Items.CF2String.Visible = False;
		Items.CF2Num.Title = Constants.CF2Name.Get();
	ElsIf CF2Type = "String" Then
	    Items.CF2Num.Visible = False;
		Items.CF2String.Visible = True;
		Items.CF2String.Title = Constants.CF2Name.Get();
	ElsIf CF2Type = "" Then
		Items.CF2Num.Visible = False;
		Items.CF2String.Visible = False;
	EndIf;
	
	If CF3Type = "None" Then
		Items.CF3Num.Visible = False;
		Items.CF3String.Visible = False;
	ElsIf CF3Type = "Number" Then
		Items.CF3Num.Visible = True;
		Items.CF3String.Visible = False;
		Items.CF3Num.Title = Constants.CF3Name.Get();
	ElsIf CF3Type = "String" Then
	    Items.CF3Num.Visible = False;
		Items.CF3String.Visible = True;
		Items.CF3String.Title = Constants.CF3Name.Get();
	ElsIf CF3Type = "" Then
		Items.CF3Num.Visible = False;
		Items.CF3String.Visible = False;
	EndIf;
	
	If CF4Type = "None" Then
		Items.CF4Num.Visible = False;
		Items.CF4String.Visible = False;
	ElsIf CF4Type = "Number" Then
		Items.CF4Num.Visible = True;
		Items.CF4String.Visible = False;
		Items.CF4Num.Title = Constants.CF4Name.Get();
	ElsIf CF4Type = "String" Then
	    Items.CF4Num.Visible = False;
		Items.CF4String.Visible = True;
		Items.CF4String.Title = Constants.CF4Name.Get();
	ElsIf CF4Type = "" Then
		Items.CF4Num.Visible = False;
		Items.CF4String.Visible = False;
	EndIf;

	If CF5Type = "None" Then
		Items.CF5Num.Visible = False;
		Items.CF5String.Visible = False;
	ElsIf CF5Type = "Number" Then
		Items.CF5Num.Visible = True;
		Items.CF5String.Visible = False;
		Items.CF5Num.Title = Constants.CF5Name.Get();
	ElsIf CF5Type = "String" Then
	    Items.CF5Num.Visible = False;
		Items.CF5String.Visible = True;
		Items.CF5String.Title = Constants.CF5Name.Get();
	ElsIf CF5Type = "" Then
		Items.CF5Num.Visible = False;
		Items.CF5String.Visible = False;
	EndIf;	
	
	// end custom fields

	QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
	Items.QtyOnPO.Format               = QuantityFormat; 
	Items.QtyOnSO.Format               = QuantityFormat; 
	Items.QtyOnHand.Format             = QuantityFormat; 
	Items.QtyAvailableToPromise.Format = QuantityFormat; 
	
EndProcedure
