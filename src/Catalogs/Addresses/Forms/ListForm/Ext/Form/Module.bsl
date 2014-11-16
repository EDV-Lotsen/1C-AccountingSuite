
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// custom fields
	
	CF1AType = Constants.CF1AType.Get();
	CF2AType = Constants.CF2AType.Get();
	CF3AType = Constants.CF3AType.Get();
	CF4AType = Constants.CF4AType.Get();
	CF5AType = Constants.CF5AType.Get();
	
	If CF1AType = "None" Then
		Items.CF1String.Visible = False;
	ElsIf CF1AType = "String" Then
		Items.CF1String.Visible = True;
		Items.CF1String.Title = Constants.CF1AName.Get();
	ElsIf CF1AType = "" Then
		Items.CF1String.Visible = False;
	EndIf;
	
	If CF2AType = "None" Then
		Items.CF2String.Visible = False;
	ElsIf CF2AType = "String" Then
		Items.CF2String.Visible = True;
		Items.CF2String.Title = Constants.CF2AName.Get();
	ElsIf CF2AType = "" Then
		Items.CF2String.Visible = False;
	EndIf;

	If CF3AType = "None" Then
		Items.CF3String.Visible = False;
	ElsIf CF3AType = "String" Then
		Items.CF3String.Visible = True;
		Items.CF3String.Title = Constants.CF3AName.Get();
	ElsIf CF3AType = "" Then
		Items.CF3String.Visible = False;
	EndIf;

	If CF4AType = "None" Then
		Items.CF4String.Visible = False;
	ElsIf CF4AType = "String" Then
		Items.CF4String.Visible = True;
		Items.CF4String.Title = Constants.CF4AName.Get();
	ElsIf CF4AType = "" Then
		Items.CF4String.Visible = False;
	EndIf;

	If CF5AType = "None" Then
		Items.CF5String.Visible = False;
	ElsIf CF5AType = "String" Then
		Items.CF5String.Visible = True;
		Items.CF5String.Title = Constants.CF5AName.Get();
	ElsIf CF5AType = "" Then
		Items.CF5String.Visible = False;
	EndIf;

	// end custom fields

EndProcedure



//&AtClient
//Procedure BeforeClose(Cancel, StandardProcessing)
//	BeforeCloseAtServer(Cancel);
//EndProcedure

//&AtServer
//Procedure BeforeCloseAtServer(Cancel)
//	
//	oneShipping = False;
//	 oneBilling = False;
//	 
//	 query = New Query("SELECT
//					   | Addresses.Ref,
//					   | Addresses.DefaultBilling,
//					   | Addresses.DefaultShipping
//					   |FROM
//					   | Catalog.Addresses AS Addresses
//					   |WHERE
//					   | Addresses.Owner.Ref = &owner");
//	 query.SetParameter("owner",List.Filter.Items[0].RightValue );
//	 addrQuery = query.Execute();
//	 allAddr = addrQuery.Unload();
//	 
//	 If NOT addrQuery.IsEmpty() Then
//	 
//		 For Each addr in allAddr Do
//		  If addr.DefaultBilling = True Then
//		   oneBilling = True;
//		  EndIf;
//		  If addr.DefaultShipping = True Then
//		   oneShipping = True;
//		  EndIf;
//		 EndDo;
//		 
//		 If oneBilling = False Then
//		  Message("Must have a default billing address");
//		  Cancel = True;
//		 EndIf;
//		 If oneShipping = False Then
//		  Message("Must have a default shipping address");
//		  Cancel = True;
//	  	 EndIf;
//		 
//	 EndIf;

//EndProcedure
