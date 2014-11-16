
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Request = New Query("SELECT
	                    |	AvalaraTransactions.RequestParameters
	                    |FROM
	                    |	InformationRegister.AvalaraTransactions AS AvalaraTransactions
	                    |WHERE
	                    |	AvalaraTransactions.ObjectRef = &ObjectRef
	                    |	AND AvalaraTransactions.Date = &Date
	                    |	AND AvalaraTransactions.TransactionID = &TransactionID
	                    |	AND AvalaraTransactions.RequestType = &RequestType");
	Request.SetParameter("ObjectRef", Record.ObjectRef);
	Request.SetParameter("Date", Record.Date);
	Request.SetParameter("TransactionID", Record.TransactionID);
	Request.SetParameter("RequestType", Record.RequestType);
	Res = Request.Execute();
	If Not Res.IsEmpty() Then
		Sel = Res.Select();
		Sel.Next();
		RequestBody = InternetConnectionClientServer.EncodeJSON(Sel.RequestParameters.Get());
	EndIf;
	
EndProcedure
