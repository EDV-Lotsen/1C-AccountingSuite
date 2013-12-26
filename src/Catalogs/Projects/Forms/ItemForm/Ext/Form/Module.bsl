
&AtServer
Procedure DetailedDesc()
	
	If Object.Customer.Description = "" Then
		//Object.Owner = Catalogs.Companies.FindByDescription(Constants.SystemTitle.Get());
		//Object.Customer = Attribute1;
	Endif;
	
	//OriginalString = StrReplace(Object.Description,Object.Owner.Description + ": ", "");
	//Object.Description = Object.Owner.Description + ": " + OriginalString;
			     
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	///
	
	If Object.Customer = Catalogs.Companies.EmptyRef() Then
		//items.Attribute1.Visible = true;
	Else
		
		items.Customer.ReadOnly = True;
	Endif;


EndProcedure


&AtClient
Procedure OnOpen(Cancel)
	
	//Still In Test
	//
	//Test2 = ThisForm;
	//test = 4;
	//Test = ThisForm.FormOwner.Name;
	//
	//If Test = "LineItemsProject" Then
	//	Object.Customer = ThisForm.FormOwner.Parent.Parent.Parent.Object.Company;
	//EndIf;
	//
	//If Test = "AccountsProject" And ThisForm.FormOwner.Parent.Name = "Accounts" Then// Test = "LineItemsProject" Then
	//	Object.Customer = ThisForm.FormOwner.Parent.Parent.Parent.Parent.Object.Company;	
	//EndIf;

	////Still in test
	//
	//Milestones.Parameters.SetParameterValue("Project", Object.Ref);
	//Transactions.Parameters.SetParameterValue("Project", Object.Ref);
		
		
EndProcedure

//&AtClient
//Procedure MilestonesNewWriteProcessing(NewObject, Source, StandardProcessing)
//		MilestonesNewWriteProcessingAtServer(NewObject);
//EndProcedure

//&AtServer
//Procedure MilestonesNewWriteProcessingAtServer(NewObject)
//	
//	Milestone = NewObject.GetObject();
//	
//	Milestone.Project = Object.Ref;
//	Milestone.Write();	
//	// Insert handler contents.
//EndProcedure
