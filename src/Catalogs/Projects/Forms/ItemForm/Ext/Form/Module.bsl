
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If object.Customer.IsEmpty() Then
		Message("Please choose a customer for your project");
		Cancel = true;
	Endif;
	
	DetailedDesc();
	
EndProcedure

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

	If Object.Ref.IsEmpty() Then
		items.Milestones.Visible = false;
		items.Page1.visible = false;
	Else
		items.Page1.visible = true;
		items.Milestones.Visible = true;
	Endif;

EndProcedure


&AtClient
Procedure OnOpen(Cancel)
	Milestones.Parameters.SetParameterValue("Project", Object.Ref);
	Transactions.Parameters.SetParameterValue("Project", Object.Ref);
		
EndProcedure

&AtClient
Procedure MilestonesNewWriteProcessing(NewObject, Source, StandardProcessing)
		MilestonesNewWriteProcessingAtServer(NewObject);
EndProcedure

&AtServer
Procedure MilestonesNewWriteProcessingAtServer(NewObject)
	
	Milestone = NewObject.GetObject();
	
	Milestone.Project = Object.Ref;
	Milestone.Write();	
	// Insert handler contents.
EndProcedure
