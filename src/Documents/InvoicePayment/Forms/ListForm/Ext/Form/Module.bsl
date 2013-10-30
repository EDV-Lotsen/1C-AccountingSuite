

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
	
	currentButton = Items.Add("Button1", Type("FormButton"), Items.ListContextMenu);
	currentButton.CommandName = "MarkVoid";

EndProcedure

&AtClient
Procedure MarkAsVoid(Command)
		  MarkVoid();
EndProcedure

&AtServer
Procedure MarkVoid()

	
	//Message("Check has been voided. Please refresh the list");
	Test = Items.List.CurrentRow;
	//Test.Voided = true;
	Selection = Documents.InvoicePayment.Select();	
	While Selection.Next() Do 
		Object = Selection.GetObject();
		If Object.Ref = Test.Ref Then
			Object.Voided = Not Object.Voided;
			If Object.Voided = False Then
				Object.Write(DocumentWriteMode.Posting);
			Else
				Object.Write(DocumentWriteMode.UndoPosting);
			Endif;
				
		Endif;

	EndDo;

	Items.List.Refresh();

EndProcedure