
&AtClient
Procedure ChangePaymentType(Command)
	
	ChangeTypeAtServer();
	Message("Ok!");

EndProcedure

&AtServerNoContext
Procedure ChangeTypeAtServer()
	
	Query = New Query("SELECT
	                  |	Check.Ref
	                  |FROM
	                  |	Document.Check AS Check
	                  |WHERE
	                  |	Check.PaymentMethod = VALUE(Catalog.PaymentMethods.Check)
	                  |	AND Check.Number <> Check.PhysicalCheckNum");
					  
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
	Else	
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			CheckObj = Selection.Ref.GetObject();
			CheckObj.AdditionalProperties.Insert("AllowCheckNumber",True);
			CheckObj.PhysicalCheckNum = CheckObj.Number;
			CheckObj.Write(DocumentWriteMode.Write);
			
		EndDo;	
	EndIf;
		
EndProcedure

