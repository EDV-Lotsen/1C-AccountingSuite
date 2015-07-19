
&AtServer
Procedure AddZerosToCodeAtServer()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Catalog.Ref,
	|	Catalog.Code
	|FROM
	|	Catalog.Companies AS Catalog";
	
	MaxLengthOfCode = NumberLength;
	
	AddLeadZeroes = True;

	
	If ObjectType = "ChartOfAccounts" Then 
		AddLeadZeroes = False;
		Query.Text = StrReplace(Query.Text, "Catalog.Companies", "ChartOfAccounts.ChartOfAccounts");
		MaxLengthOfCode = Metadata.ChartsOfAccounts.ChartOfAccounts.CodeLength;
		If MaxLengthOfCode < NumberLength Then 
			Message("Max allowed code lengths is: "+MaxLengthOfCode);
			Return;
		EndIf;	
	Else 	
		MaxLengthOfCode = Metadata.Catalogs.Companies.CodeLength;
		If MaxLengthOfCode < NumberLength Then 
			Message("Max allowed code lengths is: "+MaxLengthOfCode);
			Return;
		EndIf;	
	EndIf;	
	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	BaseBlankStr = "00000000000000000000000000000000000000000000"; // Just in case create big String
	
	While SelectionDetailRecords.Next() Do
		Dif = NumberLength - StrLen(TrimAll(SelectionDetailRecords.code));
		If Dif > 0 Then 
			If AddLeadZeroes Then 
				NewCode = Left(BaseBlankStr,Dif)+TrimAll(SelectionDetailRecords.code);
			Else 
				NewCode = "" + TrimAll(SelectionDetailRecords.code) + Left(BaseBlankStr,Dif);
			EndIf;	
			Obj = SelectionDetailRecords.Ref.GetObject();
			Obj.Code = NewCode;
			Obj.Write();
		EndIf;	
	EndDo;
	

EndProcedure

&AtClient
Procedure AddZerosToCode(Command)
	AddZerosToCodeAtServer();
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ObjectType = "ChartOfAccounts";
	ObjectTypeOnChangeAtServer();
EndProcedure

&AtClient
Procedure ObjectTypeOnChange(Item)
	ObjectTypeOnChangeAtServer();
EndProcedure

&AtServer
Procedure ObjectTypeOnChangeAtServer()
	
	NumberLength = 0;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Catalog.Ref,
	|	Catalog.Code
	|FROM
	|	Catalog.Companies AS Catalog";
	
	
	If ObjectType = "ChartOfAccounts" Then 
		Query.Text = StrReplace(Query.Text, "Catalog.Companies", "ChartOfAccounts.ChartOfAccounts");
	Else
		
	EndIf;	
	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		If StrLen(TrimAll(SelectionDetailRecords.code)) > NumberLength Then 
			NumberLength = StrLen(TrimAll(SelectionDetailRecords.code));
		EndIf;	
	EndDo;

EndProcedure
