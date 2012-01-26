
&AtServer
// Prefills default accounts, VAT codes, determines accounts descriptions, and sets field visibility
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If NOT Object.Type.IsEmpty() Then
		Items.Type.ReadOnly = True;
	EndIf;
	
	If NOT Object.CostingMethod.IsEmpty() Then
		Items.CostingMethod.ReadOnly = True;
	EndIf;
	
	If Object.Type = Enums.InventoryTypes.NonInventory Then
		Items.CostingMethod.ReadOnly = True;
	EndIf;
	
	If Object.IncomeAccount.IsEmpty() Then
		IncomeAcct = Constants.IncomeAccount.Get();
		Object.IncomeAccount = IncomeAcct;
		Items.IncomeAcctLabel.Title = IncomeAcct.Description;
	Else
		Items.IncomeAcctLabel.Title = Object.IncomeAccount.Description;
	EndIf;
	
	If Object.COGSAccount.IsEmpty() Then
		COGSAcct = Constants.COGSAccount.Get();
		Object.COGSAccount = COGSAcct;
		Items.COGSAcctLabel.Title = COGSAcct.Description;
	Else
		Items.COGSAcctLabel.Title = Object.COGSAccount.Description;
	EndIf;
	
	If NOT Object.InventoryOrExpenseAccount.IsEmpty() Then
		Items.InventoryAcctLabel.Title = Object.InventoryOrExpenseAccount.Description;
	EndIf;
	
	If Object.Type = Enums.InventoryTypes.NonInventory Then
		Items.COGSAccount.ReadOnly = True;
	EndIf;
	
	If Object.PurchaseVATCode.IsEmpty() Then
		Object.PurchaseVATCode = Constants.DefaultPurchaseVAT.Get();
	EndIf;
	
	If Object.SalesVATCode.IsEmpty() Then
		Object.SalesVATCode = Constants.DefaultSalesVAT.Get();
	EndIf;
	
EndProcedure

&AtClient
// Prefills default accounts, determines accounts descriptions, and sets accounts visibility
//
Procedure TypeOnChange(Item)
	
	If GeneralFunctions.InventoryType(Object.Type) Then
		Items.CostingMethod.ReadOnly = False;
	Else
		Items.CostingMethod.ReadOnly = True;
	EndIf;
	
	NewItemType = Object.Type; 
	Acct = GeneralFunctions.InventoryAcct(NewItemType);
	AccountDescription = GeneralFunctions.GetAttributeValue(Acct, "Description");
	Object.InventoryOrExpenseAccount = Acct;
	Items.InventoryAcctLabel.Title = AccountDescription;
	
	If NOT GeneralFunctions.InventoryType(NewItemType) Then
		Items.COGSAccount.ReadOnly = True;
	EndIf;
	
	If GeneralFunctions.InventoryType(NewItemType) Then
		Items.COGSAccount.ReadOnly = False;
	EndIf;
	
EndProcedure

&AtClient
// Determines an account description
//
Procedure InventoryOrExpenseAccountOnChange(Item)
	
	Items.InventoryAcctLabel.Title =
		GeneralFunctions.GetAttributeValue(Object.InventoryOrExpenseAccount, "Description");
		
EndProcedure

&AtClient
// Determines an account description
//
Procedure IncomeAccountOnChange(Item)
	
	Items.IncomeAcctLabel.Title =
		GeneralFunctions.GetAttributeValue(Object.IncomeAccount, "Description");
		
EndProcedure

&AtClient
// Determines an account description
//
Procedure COGSAccountOnChange(Item)
	
	Items.COGSAcctLabel.Title =
		GeneralFunctions.GetAttributeValue(Object.COGSAccount, "Description");	
		
	EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// Doesn't allow to save an item with more than one default sales unit of measure (U/M)

	x = 0;
	
	For Each TabularPartRow in Object.UnitsOfMeasure Do
		
		If TabularPartRow.DefaultSalesUM
			Then x = x + 1;
		EndIf;
		
	EndDo;
	
	If x > 1 Then
		Cancel = True;
		Message = New UserMessage();
		Message.Text=NStr("en='There can be only one default sales U/M per item'");
		Message.Field = "Object.UnitsOfMeasure";
		Message.Message();
		Return;
	EndIf;
	
	// Doesn't allow to save an item with more than one default purchase unit of measure (U/M) 
		
	y = 0;
	
	For Each TabularPartRow in Object.UnitsOfMeasure Do
		
		If TabularPartRow.DefaultPurchaseUM
			Then y = y + 1;
		EndIf;
		
	EndDo;
	
	If y > 1 Then
		Cancel = True;
		Message = New UserMessage();
		Message.Text=NStr("en='There can be only one default purchase U/M per item'");
		Message.Field = "Object.UnitsOfMeasure";
		Message.Message();
	EndIf;
	
	// Doesn't allow to save an inventory product type without a set costing type
	
	If Object.Type = Enums.InventoryTypes.Inventory Then
		If Object.CostingMethod.IsEmpty() Then
			Message = New UserMessage();
			Message.Text=NStr("en='Costing method field is empty'");
			Message.Field = "Object.CostingMethod";
			Message.Message();
			Cancel = True;
			Return;
		EndIf;
	EndIf;

	// Doesn't allow to save a LIFO costing item if the Disable LIFO setting is set
	
	If Object.Type = Enums.InventoryTypes.Inventory Then
		If Object.CostingMethod = Enums.InventoryCosting.LIFO Then
			If Constants.DisableLIFO.Get() = True Then
				Message = New UserMessage();
				Message.Text=NStr("en='The Disable LIFO (IFRS) setting is on'");
				Message.Field = "Object.CostingMethod";
				Message.Message();
				Cancel = True;
				Return;
            EndIf;
        EndIf;
	EndIf;
	
	// If the U/M functional option is turned on checks that at least one U/M is set
	
	If GetFunctionalOption("UnitsOfMeasure") Then
		
		If Object.UnitsOfMeasure.Count() = 0 Then
			Cancel = True;
			Message = New UserMessage();
			Message.Text=NStr("en='Select at least one unit of measure'");
			Message.Field = "Object.UnitsOfMeasure";
			Message.Message();
			Return;
		EndIf;
	
		If Object.UnitsOfMeasure.Count() = 1 Then
		Else
			
	       	For Each TabularPartRow in Object.UnitsOfMeasure Do
				
				// Checks if all U/Ms have the same parent U/M
				
				If TabularPartRow.UM.ParentUM.IsEmpty() Then
					Cancel = True;
					Message = New UserMessage();
					Message.Text =
						NStr("en='For more than one U/M per item all U/Ms need to have parent U/Ms'");
					Message.Field = "Object.UnitsOfMeasure";	
					Message.Message();
					Return;
				EndIf;
					
			EndDo;
			
			TrackingUM = Object.UnitsOfMeasure[0].UM.ParentUM;
			
			For Each TabularPartRow in Object.UnitsOfMeasure Do
					
				If NOT TabularPartRow.UM.ParentUM = TrackingUM Then
					Cancel = True;
					Message = New UserMessage();
					Message.Text =
						NStr("en='All U/Ms of the item need to have the same parent U/M'");
					Message.Field = "Object.UnitsOfMeasure";	
					Message.Message();
					Return;
				EndIf;
					
			EndDo;
			
		EndIf;
	
	EndIf;
	
EndProcedure