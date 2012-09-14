//////////////////////////////////////////////////////////////////////////////// 
// THIS MODULE CONTAINS FUNCTIONS AND PROCEDURES USED BY
// THE SOUTH AFRICA FINANCIAL LOCALIZATION FUNCTIONALITY
// 


// Returns a VAT amount for a document line.
//
// Parameters:
// Number.
// Catalog.VATCode.
// String - "Purchase" or "Sales".
//
// Returned value:
// Number.
//
Function VATLine(LineTotal, VATCode, Direction) Export
	
	VATAmount = 0;
	
	Query = New Query("SELECT
	|	VATCodes." + Direction + "Items.(
	|		Rate
	|	)
	|FROM
	|	Catalog.VATCodes AS VATCodes
	|WHERE
	|	VATCodes.Ref = &VATCode");
	
	Query.SetParameter("VATCode", VATCode);	
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then	
		Return 0;	
	Else
		Dataset = QueryResult.Unload();
		DataRow = Dataset[0]; 
		DataItem = DataRow[0];
		NoOfRows = DataItem.Count();
		For i = 0 To NoOfRows - 1 Do
			VATAmount = VATAmount + LineTotal * DataItem[i].Rate / 100;		
		EndDo;
		Return VATAmount;
	EndIf;	
	
EndFunction
