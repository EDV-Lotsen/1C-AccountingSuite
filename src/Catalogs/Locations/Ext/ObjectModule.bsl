
Procedure BeforeWrite(Cancel)
	//// only have one default at a time
	If Default = True Then
		Query = New Query("SELECT
						  |	Locations.Ref
						  |FROM
						  |	Catalog.Locations AS Locations
						  |WHERE
						  |	Locations.Default = &Default");
		Query.SetParameter("Default", True);
		QueryResult = Query.Execute();
		Dataset = QueryResult.Unload();
		For i = 0 to Dataset.Count()-1 Do
			LocationRef = Dataset[i].Ref;
			If LocationRef <> Ref Then
				LocationObj = LocationRef.GetObject();
				LocationObj.Default = False;
				LocationObj.Write();
			EndIf;
		EndDo;
	EndIf;

EndProcedure

