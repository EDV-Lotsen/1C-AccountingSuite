
////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Query = New Query("SELECT
	                  |	Locations.Ref
	                  |FROM
	                  |	Catalog.Locations AS Locations
	                  |WHERE
	                  |	Locations.Description = &Description");
	Query.SetParameter("Description", Object.Description);
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		Dataset = QueryResult.Unload();
		If Not Dataset[0][0] = Object.Ref Then
			Message = New UserMessage();
			Message.Text = NStr("en = 'Another location is already using this name. Please use a different name.'");
			//Message.Field = "Object.Description";
			Message.Message();
			Cancel = True;
			Return;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

#EndRegion
