//////////////////////////////////////////////////////////////////////////////// 
// THIS MODULE CONTAINS FUNCTIONS AND PROCEDURES USED BY
// THE VAT LOCALIZATION FUNCTIONALITY
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
Function VATLine(LineTotal, VATCode, Direction, PriceIncludesVAT) Export
	
	VATAmount = 0;
	
	Query = New Query("SELECT
	|	VATCodes." + Direction + "Items.(
	|		InclRate, ExclRate
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
			
			LineRate = 0;
			If PriceIncludesVAT Then
				LineRate = DataItem[i].InclRate;
			Else
				LineRate = DataItem[i].ExclRate;
			EndIf;
			
			VATAmount = VATAmount + LineTotal * LineRate / 100;		
		EndDo;
		Return VATAmount;
	EndIf;	
	
EndFunction


// needs to be updated!!! returns only one accounts - needs to return an array
Function VATAccount(VATCode, Direction) Export
	
	Query = New Query("SELECT
	|	VATCodes." + Direction + "Items.(
	|		Account
	|	)
	|FROM
	|	Catalog.VATCodes AS VATCodes
	|WHERE
	|	VATCodes.Ref = &VATCode");
	
	Query.SetParameter("VATCode", VATCode);	
	QueryResult = Query.Execute();

	Dataset = QueryResult.Unload();
	DataRow = Dataset[0]; 
	DataItem = DataRow[0];
	
	Return DataItem[0].Account;
	
EndFunction


