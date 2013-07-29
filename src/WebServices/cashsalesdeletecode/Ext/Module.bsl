
Function inout(jsonin)
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	CashSaleCode = ParsedJSON.object_code;
	
	CashSale = Documents.CashSale.FindByNumber(CashSaleCode);
	
	CashSaleObj = CashSale.GetObject();
	CashSaleObj.DeletionMark = True;
	
	Output = New Map();	
	
	Try
		CashSaleObj.Write(DocumentWriteMode.UndoPosting);
		Output.Insert("status", "success");
	Except
		//ErrorMessage = DetailErrorDescription(ErrorInfo());
		Output.Insert("error", "cash sale can not be deleted");
	EndTry;
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output,,True,True);                    
	
	Return jsonout;

EndFunction
