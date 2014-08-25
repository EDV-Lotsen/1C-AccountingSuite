
&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	Query = New Query("SELECT
	                  |	ProductCategories.Ref
					  |FROM
	                  |	Catalog.ProductCategories AS ProductCategories
	                  |WHERE
	                  |	ProductCategories.Description = &Description");
	Query.SetParameter("Description", Object.Description);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then		
	Else
		Dataset = QueryResult.Unload();
		If NOT Dataset[0][0] = Object.Ref Then
			Message = New UserMessage();
			Message.Text=NStr("en='Another item category is already using this name. Please use a different name.'");
			//Message.Field = "Object.Description";
			Message.Message();
			Cancel = True;
			Return;
		EndIf;
	EndIf;
EndProcedure
