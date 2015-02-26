
&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If object.Customer.IsEmpty() Then
		Message("Please choose a customer for your project");
		Cancel = true;
	Endif;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// If customer filling value is defined, set the customer field
	Try
		Object.Customer = Parameters.FillingValues.Customer;
	Except
		// A customer was not defined from a previous form
	EndTry;
	If Object.Customer = Catalogs.Companies.EmptyRef() Then
	Else	
		Items.Customer.ReadOnly = True;
	Endif;

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	Query = New Query("SELECT
	                  |	Projects.Ref
	                  |FROM
	                  |	Catalog.Projects AS Projects
	                  |WHERE
	                  |	Projects.Description = &Description");
	Query.SetParameter("Description", Object.Description);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then		
	Else
		Dataset = QueryResult.Unload();
		If NOT Dataset[0][0] = Object.Ref Then
			Message = New UserMessage();
			Message.Text=NStr("en='Another project is already using this name. Please use a different name.'");
			//Message.Field = "Object.Description";
			Message.Message();
			Cancel = True;
			Return;
		EndIf;
	EndIf;
EndProcedure