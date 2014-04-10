
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If NOT Object.Ref = Catalogs.Addresses.EmptyRef() Then
		Items.Owner.ReadOnly = True;
	EndIf;

	
	If Object.Owner.Vendor = True Then
		Items.RemitTo.Visible = True;
	Else
		Items.RemitTo.Visible = False;
	EndIf;
	
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
	
EndProcedure

&AtClient
Procedure DefaultBillingOnChange(Item)
	DefaultBillingOnChangeAtServer();
EndProcedure

&AtServer
Procedure DefaultBillingOnChangeAtServer()
	
	billQuery = New Query("SELECT
	         | Addresses.Ref
	         |FROM
	         | Catalog.Addresses AS Addresses
	         |WHERE
	         | Addresses.DefaultBilling = TRUE
	         | AND Addresses.Owner.Ref = &Ref");
	 billQuery.SetParameter("Ref", object.Owner.Ref);     
	 billResult = billQuery.Execute();
	 addr = billResult.Unload();
	 
	 If (NOT billResult.IsEmpty()) AND object.DefaultBilling = True AND addr[0].Ref <> object.Ref Then
	  Message("Another address is already set as the default billing address.");
	  object.DefaultBilling = False;
  EndIf;
  
EndProcedure

&AtClient
Procedure DefaultShippingOnChange(Item)
	DefaultShippingOnChangeAtServer();
EndProcedure

&AtServer
Procedure DefaultShippingOnChangeAtServer()
	
	shipQuery = New Query("SELECT
	         | Addresses.Ref
	         |FROM
	         | Catalog.Addresses AS Addresses
	         |WHERE
	         | Addresses.DefaultShipping = TRUE
	         | AND Addresses.Owner.Ref = &Ref");
	       
	 shipQuery.SetParameter("Ref", object.Owner.Ref);
	 shipResult = shipQuery.Execute();
	 addr = shipResult.Unload();
	 
	 If (NOT shipResult.IsEmpty()) AND object.DefaultShipping = True AND addr[0].Ref <> object.Ref Then
	  Message("Another address is already set as the default shipping address.");
	  object.DefaultShipping = False;
  EndIf;
  
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If NOT Object.Ref = Catalogs.Addresses.EmptyRef() Then
		Items.Owner.ReadOnly = True;
	EndIf;

EndProcedure





