////////////////////////////////////////////////////////////////////////////////
//  Methods, implementing tax calculation at Avalara
//  
////////////////////////////////////////////////////////////////////////////////

Procedure ShowQueryToTheUserOnAvataxCalculation(DocumentType, Object, FormModule, WriteParameters, Cancel) Export
	
	If Not GeneralFunctionsReusable.FunctionalOptionValue("AvataxEnabled") Then
		return;
	EndIf;
	
	If Object.UseAvatax Then
		//Set Avatax DocCode
		DocumentNumberChanged = False;
		LastAvataxStatus 			= AvataxServerCall.GetLastAvataxDocCode(Object.Ref); 
		PreviousAvataxDocCode 		= LastAvataxStatus.LastAvataxDocCode;
		DocumentIsPresentAtAvatax 	= LastAvataxStatus.DocumentIsPresentAtAvatax;
		LastAvataxDocumentStatus	= LastAvataxStatus.LastAvataxDocumentStatus;
		
		SalesInvoicePrefix 	= "Inv - ";
		SalesOrderPrefix 	= "Order - ";
		SalesReturnPrefix	= "Return - ";
		DocumentPrefix = "";
		If DocumentType = "SalesInvoice" Then
			DocumentPrefix = SalesInvoicePrefix;
		ElsIf DocumentType = "SalesOrder" Then
			DocumentPrefix = SalesOrderPrefix;
		ElsIf DocumentType = "SalesReturn" Then
			DocumentPrefix = SalesReturnPrefix;
		Else
			Return;
		EndIf;
		//If DocumentType <> "SalesOrder" Then //For Sales Order we perform only temporary calculations
			AvataxNumber	= Object.Number;
			NBSP			= Char(160);
			AvataxNumber	= StrReplace(AvataxNumber, NBSP, " ");
			If Object.AvataxDocCode <> (DocumentPrefix + AvataxNumber) Then
				Object.AvataxDocCode = DocumentPrefix + AvataxNumber;
			EndIf;
		
			If (PreviousAvataxDocCode <> Undefined) And (PreviousAvataxDocCode <> Object.AvataxDocCode) Then
				DocumentNumberChanged = True;					
			EndIf;
		//EndIf;
				
		If DocumentIsPresentAtAvatax Then //Document is saved at Avatax
			If LastAvataxDocumentStatus = PredefinedValue("Enum.AvataxStatus.Committed") Then
				If Not WriteParameters.Property("CancelAndCalculateTaxAtAvalara") Then
					Cancel = True;
					WriteParameters.Insert("CheckCancelAndCalculateTaxAtAvalara");
					WriteParameters.Insert("ManagedForm", FormModule);
					Notify = New NotifyDescription("ProcessUserResponseOnAvataxCalculation", ThisObject, WriteParameters);
					ShowQueryBox(Notify, "The document is committed at Avalara. Performing operation will result in removing the current document from Avalara and creating the new one. Do you want to continue?", QuestionDialogMode.YesNoCancel,, DialogReturnCode.Yes, "Avatax"); //Extra charge may apply.			
				EndIf;
			ElsIf DocumentNumberChanged Then
				If Not WriteParameters.Property("CancelAndCalculateTaxAtAvalara") Then
					Cancel = True;
					WriteParameters.Insert("CheckCancelAndCalculateTaxAtAvalara");
					WriteParameters.Insert("ManagedForm", FormModule);
					Notify = New NotifyDescription("ProcessUserResponseOnAvataxCalculation", ThisObject, WriteParameters);
					ShowQueryBox(Notify, "The document number has changed. Performing operation will result in removing the current document from Avalara and creating the new one. Do you want to continue?", QuestionDialogMode.YesNoCancel,, DialogReturnCode.Yes, "Avatax");			
				EndIf;
			Else
				If Not WriteParameters.Property("CalculateTaxAtAvalara") Then
					Cancel = True;
					WriteParameters.Insert("CheckCalculateTaxAtAvalara");
					WriteParameters.Insert("ManagedForm", FormModule);
					Notify = New NotifyDescription("ProcessUserResponseOnAvataxCalculation", ThisObject, WriteParameters);
					ShowQueryBox(Notify, "The document tax will be calculated at Avalara. Do you want to continue?", QuestionDialogMode.YesNoCancel,, DialogReturnCode.Yes, "Avatax");		
				EndIf;
	     	EndIf;
		Else //When the document is being sent to Avalara for the first time
			If Not WriteParameters.Property("CalculateTaxAtAvalara") Then
				Cancel = True;
				WriteParameters.Insert("CheckCalculateTaxAtAvalara");
				WriteParameters.Insert("ManagedForm", FormModule);
				Notify = New NotifyDescription("ProcessUserResponseOnAvataxCalculation", ThisObject, WriteParameters);
				ShowQueryBox(Notify, "The document tax will be calculated at Avalara. Do you want to continue?", QuestionDialogMode.YesNoCancel,, DialogReturnCode.Yes, "Avatax");		
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Procedure ProcessUserResponseOnAvataxCalculation(Result, Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		If Parameters.Property("CheckCalculateTaxAtAvalara") Then
			Parameters.Insert("CalculateTaxAtAvalara", True);
			ManagedForm = Parameters.ManagedForm;
			Parameters.Delete("ManagedForm");
			ManagedForm.Write(Parameters);
		ElsIf Parameters.Property("CheckCancelAndCalculateTaxAtAvalara") Then
			Parameters.Insert("CancelAndCalculateTaxAtAvalara", True);
			ManagedForm = Parameters.ManagedForm;
			Parameters.Delete("ManagedForm");
			ManagedForm.Write(Parameters);
		EndIf;
	EndIf;
		
EndProcedure