
Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	// Forced assign the new catalog number.
	//If ThisObject.IsNew() And Not ValueIsFilled(ThisObject.Number) Then ThisObject.SetNewNumber(); EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	// Check possibility of adding assembly to the items list.
	If Ref <> Catalogs.Products.EmptyRef() Then
		
		// Create an array of subassemblies.
		CheckItems = LineItems.UnloadColumn("Product");
		I = CheckItems.Count() - 1;
		While I >= 0 Do
			If Not CheckItems[I].Assembly Then
				CheckItems.Delete(I);
			EndIf;
			I = I - 1;
		EndDo;
		
		// Perform check of all subassemblies.
		If CheckItems.Count() > 0 Then
			// Check possible parent of current item.
			Childs = Catalogs.Products.ItemIsParentAssembly(CheckItems, Ref);
			If Childs <> Undefined Then
				
				// Inform user about the errors.
				Errors = 0;
				For Each Child In Childs Do
					Errors = Errors + 1;
					If Errors <= 10 Then
						// Assembly already added to the another subassembly.
						MessageText = NStr("en = 'Cannot add the assembly %1 to the contents of %2 because %3 already added to %1.'");
						MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText,
						              Child.Key.Description, Description, Child.Value.Description);
					EndIf;
					CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
				EndDo;
				
				// Inform user about remaining errors.
				If Errors > 10 Then
					MessageText = NStr("en = 'There are also %1 error(s) found'");
					MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, Format(Errors-10, "NFD=0; NG=0"));
					CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
				EndIf;
				
				// Stop writing.
				Return;
			EndIf;
		EndIf;
	EndIf;
	
	If NewObject = True Then
		NewObject = False
	Else
		If Ref = Catalogs.Products.EmptyRef() Then
			NewObject = True;
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	// Clear vendor data.
	ThisObject.PreferredVendor    = Catalogs.Companies.EmptyRef();
	ThisObject.vendor_code        = "";
	ThisObject.vendor_description = "";
	
EndProcedure